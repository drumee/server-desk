// ================================  *
//   Copyright Xialia.com  2013-2023 *
//   FILE  : src/service/yp
//   TYPE  : module
// ================================  **
const {
  Attr, Constants, uniqueId, Messenger, Cache, Remit, sysEnv
} = require("@drumee/server-essentials");

const _ = require("lodash");
const {
  PASS_CHECKER,
  ID_NOBODY,
  FORGOT_PASSWORD,
  INVALID_EMAIL_FORMAT,
} = Constants;
const { dom_owner } = Remit;
const { Mfs, MfsTools } = require("@drumee/server-core");
const { remove_node } = MfsTools;

const Sms = require("../vendor/smsfactor");
const { google } = require("googleapis");
const oauth2 = google.oauth2("v2");
const { stringify } = JSON;

class __butler extends Mfs {
  constructor(...args) {
    super(...args);
    this.signup = this.signup.bind(this);
    this.complete_signup = this.complete_signup.bind(this);
    this.check_token = this.check_token.bind(this);
    this.get_reset_token = this.get_reset_token.bind(this);
    this.set_pass_phrase = this.set_pass_phrase.bind(this);
    this.hello = this.hello.bind(this);
    this.ping = this.ping.bind(this);

    this.b2b_signup_otpverify = this.b2b_signup_otpverify.bind(this);
    this.b2b_signup_otpresend = this.b2b_signup_otpresend.bind(this);
    this.b2b_signup_personaldata = this.b2b_signup_personaldata.bind(this);
    this.b2b_signup_password = this.b2b_signup_password.bind(this);
    this.b2b_signup_company = this.b2b_signup_company.bind(this);

    this.b2c_signup_password = this.b2c_signup_password.bind(this);
    this.b2c_signup_otpverify = this.b2c_signup_otpverify.bind(this);
    this.b2c_signup_otpresend = this.b2c_signup_otpresend.bind(this);
    this.b2c_signup_skip_otpverify = this.b2c_signup_skip_otpverify.bind(this);

    this.set_password = this.set_password.bind(this);
    this.password_otpverify = this.password_otpverify.bind(this);
    this.password_otpresend = this.password_otpresend.bind(this);

    this.google_auth = this.google_auth.bind(this);
    this.google_callback = this.google_callback.bind(this);

    this.authclient = this.authclient.bind(this);
    this.auth_Url = this.auth_Url.bind(this);
    this.get_me = this.get_me.bind(this);
    this.get_people = this.get_people.bind(this);
  }

  /**
   * 
   * @param {*} callback 
   * @param {*} code 
   * @returns 
   */
  async authclient(callback, code) {
    const client_secret = Cache.getSysConf("google_client_secret");
    const client_id = Cache.getSysConf("google_client_id");
    const redirect_uris = this.input.servicepath({
      service: "butler.google_callback",
    });
    const oAuth2Client = new google.auth.OAuth2(
      client_id,
      client_secret,
      redirect_uris
    );
    return callback(oAuth2Client, code);
  }

  /**
   *
   */
  async auth_Url(oAuth2Client) {
    const SCOPES = [
      "https://www.googleapis.com/auth/userinfo.profile",
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/contacts.readonly",
    ].join(" ");

    const state = await this.yp.await_func("uniqueId");
    const statejson = {
      source: "login",
      sid: this.session.sid(),
      host: this.input.host(),
      uid: this.uid,
    };
    await this.yp.await_proc("set_redirect_state", state, stringify(statejson));
    const authUrl = oAuth2Client.generateAuthUrl({
      access_type: "offline",
      scope: SCOPES,
      state: state,
    });

    return authUrl;
  }

  /**
   *
   * @param {*} oAuth2Client
   * @param {*} code
   * @returns
   */
  async get_me(oAuth2Client, code) {
    const { tokens } = await oAuth2Client.getToken(code);
    const accessToken = tokens.access_token;
    oAuth2Client.setCredentials({ access_token: accessToken });
    const googleUser = await oauth2.userinfo.get({ auth: oAuth2Client });
    return googleUser;
  }

  /**
   * 
   * @param {*} oAuth2Client 
   * @param {*} code 
   * @returns 
   */
  async get_people(oAuth2Client, code) {
    const { tokens } = await oAuth2Client.getToken(code);
    oAuth2Client.setCredentials(tokens);
    const list = google.people({ version: "v1", auth: oAuth2Client });
    return list;
  }

  /**
   *
   */
  async google_auth() {
    let res = await this.authclient(this.auth_Url);
    this.debug("auth url ", res);
    this.output.data(res);
  }

  /**
   *
   */
  async google_callback() {
    let state = this.input.need("state");
    let statejson = await this.yp.await_proc("get_redirect_state", state);
    try {
      statejson = JSON.parse(statejson.metadata);
    } catch (e) {
      statejson = statejson.metadata;
    }
    if (statejson.source == "login") {
      await this.google_login(statejson);
    } else {
      await this.google_contact(statejson);
    }
  }

  /**
   *
   * @param {*} state
   */
  async google_login(state) {
    let domain;
    let res = [];
    const code = this.input.need(Attr.code);
    let googleUser = await this.authclient(this.get_me, code);
    const email = googleUser.data.email;
    let newuser = await this.yp.await_proc("drumate_get", email);

    if (_.isEmpty(newuser)) {
      domain = await this.yp.await_func("utils.domain_name");

      let a = email.split("@");
      a = a[0].split(/[\.-_]/);
      let base = a[0] || "a";
      base = base.toLowerCase();
      base = base.replace(/ /g, "");
      let username = await this.yp.await_func(
        "unique_username",
        base,
        domain
      );

      a = email.split("@");
      a[1] = a[0];
      if (a[0].indexOf(".") !== -1) {
        a = a[0].split(".");
      }
      let firstname = googleUser.data.given_name || a[0];
      let lastname = googleUser.data.family_name || a[1];

      let profile = {
        email: email,
        lang: this.input.ua_language(),
        username,
        sharebox: uniqueId(),
        otp: "0",
        firstname,
        lastname,
        connected: "1",
      };

      let rows = await this.yp.await_proc(
        "drumate_create",
        uniqueId(),
        stringify(profile)
      );
      if (!_.isArray(rows)) {
        rows = [rows];
      }
      if (_.isEmpty(rows)) {
        return this.output.data({ status: "FACTORY_EMPTY" });
      }
      for (let r of rows) {
        if (r && r.failed) {
          return this.output.data({ status: "FACTORY_FAILED" });
        }
      }
      for (let r of rows) {
        if (typeof r.drumate !== "undefined") {
          newuser = this.parseJSON(r.drumate);
        }
      }
      await this.setDefaultContent(newuser.id, "hub");

      await this.yp.await_proc("ticket_grant_permission", newuser.id);
      profile.email_verified = "yes";
      profile.connected = "1";
      await this.yp.call_proc(
        "drumate_update_profile",
        newuser.id,
        stringify(profile)
      );
      await this.setDefaultWallpaper(newuser.id, "b2c");

      const quota = Cache.getSysConf("advanced_quota");
      await this.yp.await_proc(
        "drumate_update_profile",
        newuser.id,
        stringify({ quota: quota })
      );
    }

    domain = await this.yp.await_func("domain_name", newuser.id);
    const s = await this.yp.await_proc(
      "google_login",
      newuser.id,
      state.sid,
      domain
    );
    //await this.log_connection(newuser.id)
    if (s && !s.failed) {
      this.session.refresh_tokens(s);
    }
    this.output.html(
      `<script>  window.location.href = '${this.input.homepath()}' </script>`
    )
  }

  /**
   *
   * @param {*} state
   */
  async google_contact(state) {
    const code = this.input.need(Attr.code);

    const domain = await this.yp.await_func("domain_name", state.uid);
    const s = await this.yp.await_proc(
      "google_login",
      state.uid,
      state.sid,
      domain
    );
    //await this.log_connection(newuser.id)
    if (s && !s.failed) {
      this.session.refresh_tokens(s);
    }

    let service = await this.authclient(this.get_people, code);
    const res = await service.people.connections.list({
      resourceName: "people/me",
      pageSize: 2000,
      personFields: "names,emailAddresses,addresses",
    });

    const connections = res.data.connections;
    if (connections) {
      console.log("Connections:");

      for (let person of connections) {
        if (person.emailAddresses && person.emailAddresses.length > 0) {
          // console.log(person);
          let email = [];
          let address = [];
          let default_email = person.emailAddresses[0];

          // console.log(" have secondary  : ", person.emailAddresses[1])
          let firstname;
          let lastname;
          let name;
          if (person.names && person.names.length > 0) {
            firstname = person.names[0].middleName;
            lastname = person.names[0].familyName;
          }
          // console.log('wsewewewewexxx', firstname, lastname)
          // if (person.addresses && person.addresses.length > 0) {
          //   person.addresses.forEach(async (adr) => {
          //     let tempjson = {
          //       street:  (adr[0].streetAddress ? adr[0].streetAddress : '')  ,
          //       city: adr[0].city,
          //       country: adr[0].country,
          //       category: 'prof'
          //     }
          //     address.push(tempjson)
          //   });
          // }
          await person.emailAddresses.forEach((res) => {
            //console.log(" res ", res.metadata.primary, res.value)
            if (res.metadata.primary) {
              default_email = res.value;
            }
            let tempjson = {
              email: res.value,
              is_default: res.metadata.primary ? 1 : 0,
              category: "prof",
            };
            email.push(tempjson);
          });
          let entity = default_email;

          let drumate = await this.yp.await_proc("drumate_exists", entity);
          entity = drumate.id || entity;
          let mycontact = await this.yp.await_proc(
            "forward_proc",
            state.uid,
            "my_contact_exists",
            `'entity','${entity}',null,null`
          );
          if (_.isEmpty(mycontact)) {
            if (_.isEmpty(firstname)) {
              let a = default_email.split("@");
              a[1] = a[0];
              if (a[0].indexOf(".") !== -1) {
                a = a[0].split(".");
              }
              firstname = a[0];
              lastname = a[1];
            }
            let metadata = {
              source: default_email,
              imported: this.session.timestamp,
              from: "google",
            };
            let contact = await this.yp.await_proc(
              "forward_proc",
              state.uid,
              "my_contact_add_next",
              `'${entity}',null,'${firstname}' ,'${lastname}','independant', null,null ,'${stringify(
                metadata
              )}'`
            );
            await this.yp.await_proc(
              "forward_proc",
              state.uid,
              "my_contact_mail_add",
              `'${contact.id}','${stringify(email)}'`
            );
            //await this.yp.await_proc('forward_proc', state.uid, 'my_contact_phone_add', `'${contact.id}','${stringify(mobile)}'`)
            //console.log('wsewewewewe', firstname, lastname, default_email, address, email, contact.id, metadata)
          }
        }
      }
    } else {
      this.warn("No connections found.");
    }
    this.output.html(`<script>  window.close() </script>`);
  }

  /**
   *
   */
  async transferbox_files_send() {
    let secret = this.input.need(Attr.secret);
    const nodes = this.input.use(Attr.nodes, []);
    const butler_sharebox = Cache.getSysConf("butler_sharebox");
    let res = {};
    let node = await this.yp.await_proc(
      "forward_proc",
      butler_sharebox,
      "dmz_show_link_content",
      `'${secret}'`
    );
    if (_.isEmpty(node)) {
      return this.output.data({ status: "INVALID_TOKEN" });

    }
    res = await this.yp.await_proc(
      "forward_proc",
      butler_sharebox,
      "transferbox_files_send",
      `'${secret}',${stringify(nodes)}`
    );
    this.output.data(res);
  }

  /**
   *
   */
  async transferbox_files_delete() {
    let secret = this.input.need(Attr.secret);
    const nodes = this.input.use(Attr.nodes, []);
    const butler_sharebox = Cache.getSysConf("butler_sharebox");
    let res = {};
    let node = await this.yp.await_proc(
      "forward_proc",
      butler_sharebox,
      "dmz_show_link_content",
      `'${secret}'`
    );
    if (_.isEmpty(node)) {
      return this.output.data({ status: "INVALID_TOKEN" });

    }
    let rows = await this.yp.await_proc(
      "forward_proc",
      butler_sharebox,
      "transferbox_files_delete",
      `'${secret}',${stringify(nodes)}`
    );
    let butler_bx = await this.yp.await_proc(
      "forward_proc",
      butler_sharebox,
      "mfs_home",
      ``
    );

    if (!_.isArray(rows)) {
      rows = [rows];
    }

    for (let r of rows) {
      let target = {
        nid: r.id,
        hub_id: butler_sharebox,
        mfs_root: butler_bx.home_dir,
      };
      if (r.category != "folder" && r.category != "hub") {
        await remove_node(target);
      }
    }
    this.output.data(rows);
  }


  /**
   *
   */
  async b2c_signup_skip_otpverify() {
    let secret = this.input.need(Attr.secret);

    let res = {};
    let chk;
    let profile = {};
    let metadata = {};
    let signup = {};

    signup = await this.yp.await_proc("token_get_next", secret);
    if (_.isEmpty(signup)) {
      return this.output.data({ status: "INVALID_SECRET" });

    }
    if (signup.status != "active") {
      return this.output.data({ status: "INVALID_SECRET" });

    }

    if (signup.method != "signup") {
      return this.output.data({ status: "INVALID_METHOD" });

    }

    metadata = this.parseJSON(signup.metadata);
    if (metadata.step != "otpverify") {
      return this.output.data({ status: "INVALID_STEP" });

    }
    profile.otp = "0";
    profile.email_verified = "yes";
    profile.connected = "1";
    await this.yp.call_proc(
      "drumate_update_profile",
      metadata.uid,
      stringify(profile)
    );

    await this.yp.await_proc("update_member_status", metadata.uid, "active");
    await this.yp.await_proc(
      "signup_login",
      metadata.uid,
      secret,
      this.session.sid()
    );
    //await this.log_connection(metadata.uid)
    metadata.step = "complete";
    await this.setDefaultWallpaper(metadata.uid, "b2c");
    await this.yp.await_proc("token_update", secret, metadata);
    res = await this.yp.await_proc("token_get_next", secret);
    await this.yp.await_proc("token_delete", secret);

    if (!_.isEmpty(res)) {
      if (res.metadata != null) {
        res.metadata = this.parseJSON(res.metadata);
      }
      delete res["status"];
    }
    this.output.data(res);
  }

  /**
   * 
   */
  async b2c_signup_otpverify() {
    let secret = this.input.use(Attr.secret);
    let code = this.input.use(Attr.code);
    let res = {};
    let chk;
    let profile = {};
    let metadata = {};
    let signup = {};

    signup = await this.yp.await_proc("token_get_next", secret);
    if (_.isEmpty(signup)) {
      return this.output.data({ status: "INVALID_SECRET" });

    }
    if (signup.status != "active") {
      return this.output.data({ status: "INVALID_SECRET" });

    }

    if (signup.method != "signup") {
      return this.output.data({ status: "INVALID_METHOD" });

    }

    metadata = this.parseJSON(signup.metadata);
    if (metadata.step != "otpverify") {
      return this.output.data({ status: "INVALID_STEP" });

    }
    let otp = await this.yp.await_proc(
      "otp_check",
      metadata.uid,
      metadata.otp_secret,
      code
    );
    if (!_.isEmpty(otp)) {
      metadata.step = "complete";
      await this.setDefaultWallpaper(metadata.uid, "b2c");
      await this.yp.await_proc(
        "update_member_status",
        metadata.uid,
        "active"
      );
      await this.yp.await_proc("token_update", secret, metadata);
      res = await this.yp.await_proc("token_get_next", secret);
      await this.yp.await_proc(
        "session_login_otp",
        metadata.uid,
        code,
        metadata.otp_secret,
        this.input.sid()
      );

      profile.email_verified = "yes";
      profile.mobile_verified = "yes";
      profile.connected = "1";
      await this.yp.call_proc(
        "drumate_update_profile",
        metadata.uid,
        stringify(profile)
      );

      //await this.log_connection(metadata.uid)
      await this.yp.await_proc("token_delete", secret);
      await this.yp.await_proc(
        "otp_delete",
        metadata.uid,
        metadata.otp_secret,
        code
      );
    } else {
      metadata.step = "otpresend";
      await this.yp.await_proc("token_update", secret, metadata);
      res = await this.yp.await_proc("token_get_next", secret);
    }
    if (!_.isEmpty(res)) {
      if (res.metadata != null) {
        res.metadata = this.parseJSON(res.metadata);
      }
      delete res["status"];
    }
    this.output.data(res);
  }

  /**
   * 
   */
  async b2c_signup_otpresend() {
    const secret = this.input.need(Attr.secret);
    let mobile = this.input.need(Attr.mobile);
    let areacode = this.input.need(Attr.areacode);
    let res = {};
    let chk;
    let profile = {};
    let metadata = {};
    let signup = {};

    signup = await this.yp.await_proc("token_get_next", secret);
    if (_.isEmpty(signup)) {
      return this.output.data({ status: "INVALID_SECRET" });
    }
    if (signup.status != "active") {
      return this.output.data({ status: "INVALID_SECRET" });
    }

    if (signup.method != "signup") {
      return this.output.data({ status: "INVALID_METHOD" });
    }

    metadata = this.parseJSON(signup.metadata);
    if (metadata.step != "otpresend" && metadata.step != "otpverify") {
      return this.output.data({ status: "INVALID_STEP" });
    }

    if (!_.isEmpty(mobile) && mobile != "") {
      profile.mobile = mobile;
      metadata.mobile = mobile;
      profile.areacode = areacode;
      metadata.areacode = areacode;
      await this.yp.call_proc(
        "drumate_update_profile",
        metadata.uid,
        stringify(profile)
      );
    }
    let data = await this.send_otp(
      `${metadata.areacode}${metadata.mobile}`,
      metadata.uid
    );

    delete metadata["otp_secret"];
    if (!_.isEmpty(data)) {
      metadata.otp_secret = data.secret;
    }
    metadata.step = "otpverify";
    await this.yp.await_proc("token_update", secret, metadata);
    res = await this.yp.await_proc("token_get_next", secret);
    if (!_.isEmpty(res)) {
      if (res.metadata != null) {
        res.metadata = this.parseJSON(res.metadata);
      }
      delete res["status"];
    }
    this.output.data(res);
  }

  /**
   * 
   */
  async b2c_signup_password() {
    const secret = this.input.need(Attr.secret);
    const pw = this.input.need(Attr.password);
    let mobile = this.input.use(Attr.mobile);
    let areacode = this.input.use(Attr.areacode);
    let firstname = this.input.need(Attr.firstname);
    let lastname = this.input.need(Attr.lastname);

    let res = {};
    let chk;
    let newuser;
    let metadata = {};
    let signup = {};

    signup = await this.yp.await_proc("token_get_next", secret);
    if (_.isEmpty(signup)) {
      return this.output.data({ status: "INVALID_SECRET" });

    }
    if (signup.status != "active") {
      return this.output.data({ status: "INVALID_SECRET" });

    }
    if (signup.method != "signup") {
      return this.output.data({ status: "INVALID_METHOD" });
    }

    metadata = this.parseJSON(signup.metadata);
    if (metadata.step != "password") {
      return this.output.data({ status: "INVALID_STEP" });
    }

    if (!_.isEmpty(mobile) && mobile != "") {
      if (!PHONE_CHECKER.test(mobile)) {
        return this.output.data({ status: "INVALID_PHONE_FORMAT" });
      }
    }

    if (!_.isEmpty(mobile) && !/^[0 _-]+$/.test(mobile)) {
      if (_.isEmpty(areacode)) {
        return this.output.data({ status: "EMPTY_AREACODE" });
      }
    }

    let domain = await this.yp.await_func("utils.domain_name");
    let drumate = this.yp.await_proc(
      "get_user_in_domain",
      signup.email,
      domain
    );
    if (drumate.exists) {
      return this.exception.user(`email ${signup.email} already exists`);
    }
    let a = signup.email.split("@");
    a = a[0].split(/[\.-_]/);
    let base = a[0] || "a";
    base = base.toLowerCase();
    base = base.replace(/ /g, "");
    let username = await this.yp.await_func("unique_username", base, domain);
    let profile = {
      email: signup.email,
      lang: this.input.ua_language(),
      username,
      sharebox: uniqueId(),
      otp: "0",
    };

    if (!_.isEmpty(mobile) && mobile != "") {
      profile.mobile = mobile;
      profile.areacode = areacode;
      profile.otp = "sms";
    }
    if (!_.isEmpty(firstname)) {
      profile.firstname = firstname;
    }
    if (!_.isEmpty(lastname)) {
      profile.lastname = lastname;
    }
    profile.connected = "1";
    let rows = await this.yp.await_proc(
      "drumate_create",
      pw,
      stringify(profile)
    );
    if (!_.isArray(rows)) {
      rows = [rows];
    }
    metadata.step = "Password : Failed to create user";
    if (_.isEmpty(rows)) {
      await this.yp.await_proc("token_update", secret, metadata);
      this.exception.server("Failed to create account -- Factory Empty");
      return this.output.data({ status: "FACTORY_EMPTY" });
    }

    for (let r of rows) {
      if (r && r.failed) {
        await this.yp.await_proc("token_update", secret, metadata);
        return this.output.data({ status: "FACTORY_FAILED", ...r });
      }
    }

    for (let r of rows) {
      if (typeof r.drumate !== "undefined") {
        newuser = this.parseJSON(r.drumate);
      }
    }

    await this.setDefaultContent(newuser.id, "hub");

    const quota = Cache.getSysConf("advanced_quota");
    await this.yp.await_proc(
      "drumate_update_profile",
      newuser.id,
      stringify({ quota: quota })
    );

    //await this.join_contact(secret, newuser.id, signup.inviter_id)
    await this.yp.await_proc("ticket_grant_permission", newuser.id);
    if (!_.isEmpty(mobile) && mobile != "") {
      await this.yp.await_proc("update_member_status", newuser.id, "offline");
      let data = await this.send_otp(`${areacode}${mobile}`, newuser.id);
      delete metadata["otp_secret"];
      if (!_.isEmpty(data)) {
        metadata.otp_secret = data.secret;
      }
      metadata.step = "otpverify";
      metadata.mobile = mobile;
      metadata.areacode = areacode;
      (metadata.uid = newuser.id),
        await this.yp.await_proc("token_update", secret, metadata);
      res = await this.yp.await_proc("token_get_next", secret);
    } else {
      profile.email_verified = "yes";
      profile.connected = "1";
      await this.yp.call_proc(
        "drumate_update_profile",
        metadata.uid,
        stringify(profile)
      );

      //this.debug("EEEE 402", newuser.id, pw, this.session.sid(), domain);
      const s = await this.yp.await_proc(
        "session_login",
        newuser.id,
        pw,
        this.input.sid(),
        domain
      );
      // await this.log_connection(newuser.id)
      metadata.step = "complete";
      await this.setDefaultWallpaper(newuser.id, "b2c");
      await this.yp.await_proc("token_update", secret, metadata);
      res = await this.yp.await_proc("token_get_next", secret);
      await this.yp.await_proc("token_delete", secret);
      if (s && !s.failed) {
        this.session.refresh_tokens(s);
      }
    }

    if (!_.isEmpty(res)) {
      if (res.metadata != null) {
        res.metadata = this.parseJSON(res.metadata);
      }
      delete res["status"];
    }
    this.output.data(res);
  }

  /**
   * 
   */
  async b2b_signup_otpverify() {
    let secret = this.input.use(Attr.secret);
    let code = this.input.use(Attr.code);
    let res = {};
    let profile = {};
    let metadata = {};
    let signup = {};

    signup = await this.yp.await_proc("token_get_next", secret);
    if (_.isEmpty(signup)) {
      return this.output.data({ status: "INVALID_SECRET" });

    }
    if (signup.status != "active") {
      return this.output.data({ status: "INVALID_SECRET" });

    }

    if (signup.method != "b2bsignup") {
      return this.output.data({ status: "INVALID_METHOD" });

    }

    metadata = this.parseJSON(signup.metadata);
    if (metadata.step != "otpverify") {
      return this.output.data({ status: "INVALID_STEP" });

    }
    let otp = await this.yp.await_proc(
      "otp_check",
      metadata.uid,
      metadata.otp_secret,
      code
    );
    if (!_.isEmpty(otp)) {
      metadata.step = "complete";
      metadata.mode = "b2bsignup";
      await this.setDefaultWallpaper(metadata.uid, "b2b");
      await this.yp.await_proc(
        "update_member_status",
        metadata.uid,
        "active"
      );
      await this.yp.await_proc("token_update", secret, metadata);
      res = await this.yp.await_proc("token_get_next", secret);
      await this.yp.await_proc(
        "session_login_otp",
        metadata.uid,
        code,
        metadata.otp_secret,
        this.input.sid()
      );
      profile.email_verified = "yes";
      profile.mobile_verified = "yes";
      profile.connected = "1";
      profile.otp = "0";
      await this.yp.call_proc(
        "drumate_update_profile",
        metadata.uid,
        stringify(profile)
      );

      //await this.log_connection(metadata.uid);
      await this.yp.await_proc("token_delete", secret);
      await this.yp.await_proc(
        "otp_delete",
        metadata.uid,
        metadata.otp_secret,
        code
      );
    } else {
      metadata.step = "otpresend";
      metadata.mode = "b2bsignup";
      await this.yp.await_proc("token_update", secret, metadata);
      res = await this.yp.await_proc("token_get_next", secret);
    }
    if (!_.isEmpty(res)) {
      if (res.metadata != null) {
        res.metadata = this.parseJSON(res.metadata);
      }
      delete res["status"];
    }
    this.output.data(res);
  }

  /**
   * 
   */
  async b2b_signup_otpresend() {
    const secret = this.input.need(Attr.secret);
    let mobile = this.input.use(Attr.mobile);
    let areacode = this.input.use(Attr.areacode);
    let res = {};
    let chk;
    let profile = {};
    let metadata = {};
    let signup = {};

    signup = await this.yp.await_proc("token_get_next", secret);
    if (_.isEmpty(signup)) {
      return this.output.data({ status: "INVALID_SECRET" });
    }
    if (signup.status != "active") {
      return this.output.data({ status: "INVALID_SECRET" });
    }

    if (signup.method != "b2bsignup") {
      return this.output.data({ status: "INVALID_METHOD" });
    }

    metadata = this.parseJSON(signup.metadata);
    if (metadata.step != "otpresend" && metadata.step != "otpverify") {
      return this.output.data({ status: "INVALID_STEP" });
    }

    if (!_.isEmpty(mobile) && mobile != "") {
      if (_.isEmpty(areacode)) {
        return this.output.data({ status: "EMPTY_AREACODE" });
      }
    }

    metadata.mobile = mobile || metadata.mobile;
    metadata.areacode = areacode || metadata.areacode;
    if (!_.isEmpty(mobile) && mobile != "") {
      profile.mobile = mobile;
      profile.areacode = areacode;
      await this.yp.call_proc(
        "drumate_update_profile",
        metadata.uid,
        stringify(profile)
      );
    }
    let data = await this.send_otp(
      `${metadata.areacode}${metadata.mobile}`,
      metadata.uid
    );

    delete metadata["otp_secret"];
    if (!_.isEmpty(data)) {
      metadata.otp_secret = data.secret;
    }
    metadata.step = "otpverify";
    metadata.mode = "b2bsignup";
    await this.yp.await_proc("token_update", secret, metadata);
    res = await this.yp.await_proc("token_get_next", secret);
    if (!_.isEmpty(res)) {
      if (res.metadata != null) {
        res.metadata = this.parseJSON(res.metadata);
      }
      delete res["status"];
    }
    this.output.data(res);
  }

  /**
   * 
   * @returns 
   */
  async b2b_signup_personaldata() {
    const secret = this.input.need(Attr.secret);
    let firstname = this.input.need(Attr.firstname);
    let lastname = this.input.need(Attr.lastname);
    let mobile = this.input.need(Attr.mobile);
    let areacode = this.input.need(Attr.areacode);
    let city = this.input.use(Attr.city);

    let res = {};
    let chk;
    let profile = {};
    let metadata = {};
    let signup = {};

    signup = await this.yp.await_proc("token_get_next", secret);
    if (_.isEmpty(signup)) {
      return this.output.data({ status: "INVALID_SECRET" });
    }
    if (signup.status != "active") {
      return this.output.data({ status: "INVALID_SECRET" });
    }

    if (signup.method != "b2bsignup") {
      return this.output.data({ status: "INVALID_METHOD" });
    }
    metadata = this.parseJSON(signup.metadata);
    if (metadata.step != "personaldata") {
      return this.output.data({ status: "INVALID_STEP" });
    }
    if (!_.isEmpty(firstname)) {
      profile.firstname = firstname;
    }
    if (!_.isEmpty(lastname)) {
      profile.lastname = lastname;
    }
    if (!_.isEmpty(city)) {
      profile.address = { city: city };
    }
    if (!_.isEmpty(mobile) && mobile != "") {
      profile.mobile = mobile;
    }
    if (!_.isEmpty(areacode) && areacode != "") {
      profile.areacode = areacode;
    }
    await this.yp.call_proc(
      "drumate_update_profile",
      metadata.uid,
      stringify(profile)
    );


    metadata.step = "complete";
    metadata.mode = "b2bsignup";
    await this.yp.await_proc("token_update", secret, metadata);
    res = await this.yp.await_proc("token_get_next", secret);

    await this.setDefaultWallpaper(metadata.uid, "b2b");
    await this.yp.await_proc("update_member_status", metadata.uid, "active");

    await this.yp.await_proc(
      "session_login_b2b",
      metadata.uid,
      secret,
      this.input.sid()
    );
    profile.email_verified = "yes";
    profile.mobile_verified = "yes";
    profile.connected = "1";
    profile.otp = "0";
    await this.yp.call_proc(
      "drumate_update_profile",
      metadata.uid,
      stringify(profile)
    );

    await this.yp.await_proc("token_delete", secret);
    //await this.yp.await_proc('otp_delete', metadata.uid, metadata.otp_secret, code);

    if (!_.isEmpty(res)) {
      if (res.metadata != null) {
        res.metadata = this.parseJSON(res.metadata);
      }
      delete res["status"];
    }
    return this.output.data(res);
  }

  /**
   * 
   */
  async join_contact(secret, user_id, inviter_id) {
    let { db_name } = await this.yp.await_proc('get_entity', user_id);
    let data = await this.yp.await_proc(
      `${db_name}.contact_join`, secret
    );
    if (!_.isEmpty(data)) {
      data = await this.yp.await_proc(
        `${db_name}.contact_notification_by_entity`,
        inviter_id
      );
      data.service = "contact.invite_accept";
      this.notify_user(inviter_id, data);
    }
  }

  /**
   * 
   */
  async send_otp(mobile, uid) {
    const token = this.randomString();
    const lang = this.user.language() || this.input.app_language();
    let otp = await this.yp.await_proc("otp_create", uid, token);
    const message = Cache.message("_otp_update_profile", lang);
    const Moment = require("moment");
    Moment.locale(lang);
    const expiry = Moment(otp.expiry, "X").format("hh:mm");
    let opt = {
      message: `${message.format(otp.code, expiry)}`,
      receivers: [mobile],
    };
    let sms = new Sms(opt);
    let data = await sms.send().then((result) => {
      if (!_.isEmpty(result.invalidReceivers)) {
        return 0;
      }
      return 1;
    });

    if (data == 1) {
      return otp;
    }
    return null;
  }

  /**
   * 
   * @returns 
   */
  async b2b_signup_password() {
    const secret = this.input.need(Attr.secret);
    const pw = this.input.need(Attr.password);
    let res = {};
    let newuser;
    let metadata = {};
    let signup = {};

    signup = await this.yp.await_proc("token_get_next", secret);
    if (_.isEmpty(signup)) {
      return this.output.data({ status: "INVALID_SECRET" });

    }
    if (signup.status != "active") {
      return this.output.data({ status: "INVALID_SECRET" });

    }
    if (signup.method != "b2bsignup") {
      return this.output.data({ status: "INVALID_METHOD" });

    }

    metadata = this.parseJSON(signup.metadata);
    if (metadata.step != "password") {
      return this.output.data({ status: "INVALID_STEP" });

    }

    // let domain = await this.yp.await_proc('domain_exists', chk.metadata.domain_id);

    let a = signup.email.split("@");
    a = a[0].split(/[\.-_]/);
    let base = a[0] || "a";
    base = base.toLowerCase();
    let username = await this.yp.await_func(
      "unique_username",
      base,
      metadata.domain_name
    );

    const profile = {
      email: signup.email.trim(),
      firstname: a[0],
      lastname: a[1],
      lang: this.input.ua_language(),
      privilege: dom_owner,
      domain: metadata.domain_name,
      username,
      sharebox: uniqueId(),
      otp: "sms",
    };
    profile.sharebox = uniqueId();
    profile.connected = "1";
    let rows = await this.yp.await_proc(
      "drumate_create",
      pw,
      stringify(profile)
    );
    metadata.step = "Password : Failed to create user";
    if (!_.isArray(rows)) {
      rows = [rows];
    }
    if (_.isEmpty(rows)) {
      await this.yp.await_proc("token_update", secret, metadata);
      this.exception.server("Failed to create account -- Factory Empty");
      return this.output.data({ status: "FACTORY_EMPTY" });

    }

    for (let r of rows) {
      if (r && r.failed) {
        await this.yp.await_proc("token_update", secret, metadata);
        this.exception.server("Failed to create account -- Factory Failed");
        return this.output.data({ status: "FACTORY_FAILED" });

      }
    }

    for (let r of rows) {
      if (typeof r.drumate !== "undefined") {
        newuser = this.parseJSON(r.drumate);
      }
    }

    const quota = Cache.getSysConf("company_owner_quota");
    await this.yp.await_proc(
      "drumate_update_profile",
      newuser.id,
      stringify({ quota: quota })
    );

    await this.yp.await_proc("ticket_grant_permission", newuser.id);
    await this.yp.await_proc("update_member_status", newuser.id, "offline");
    // await this.yp.await_proc('forward_proc', newuser.id, 'mfs_init_folders', `'$stringify(folders)}', '${1}'`)
    await this.setDefaultContent(newuser.id, "pro");
    await this.yp.await_proc(
      "domain_grant",
      metadata.domain_id,
      dom_owner,
      newuser.id,
      1
    );
    await this.yp.await_proc(
      "organisation_add",
      newuser.id,
      metadata.org_name,
      metadata.link,
      metadata.org_ident,
      metadata.domain_id,
      metadata
    );

    metadata = {};
    metadata.step = "personaldata";
    metadata.mode = "b2bsignup";
    (metadata.uid = newuser.id),
      await this.yp.await_proc("token_update", secret, metadata);
    res = await this.yp.await_proc("token_get_next", secret);
    if (!_.isEmpty(res)) {
      if (res.metadata != null) {
        res.metadata = this.parseJSON(res.metadata);
      }
      delete res["status"];
    }
    this.output.data(res);
  }

  /**
   * 
   */
  async b2b_signup_company() {
    const secret = this.input.need(Attr.secret);
    let ident = this.input.need(Attr.ident);
    ident = ident.toLowerCase();
    let res = {};
    let chk;
    let signup = {};
    let metadata = {};

    signup = await this.yp.await_proc("token_get_next", secret);
    if (_.isEmpty(signup)) {
      return this.output.data({ status: "INVALID_SECRET" });

    }
    if (signup.status != "active") {
      return this.output.data({ status: "INVALID_SECRET" });
    }

    if (signup.method != "b2bsignup") {
      return this.output.data({ status: "INVALID_METHOD" });

    }

    metadata = this.parseJSON(signup.metadata);
    if (metadata.step != "company") {
      return this.output.data({ status: "INVALID_STEP" });
    }

    let domain = `${ident}.${process.env.domain_name}`;
    chk = await this.yp.await_proc("vhost_exists", domain);
    let dom = await this.yp.await_proc("domain_exists", domain);
    if (!_.isEmpty(chk) || !_.isEmpty(dom)) {
      return this.output.data({ status: "IDENT_NOT_AVAILABLE" });
    }

    if (!/^[0-9a-zA-Z\-_]+$/.test(ident)) {
      return this.output.data({ status: "INVALID_IDENT" });
    }

    domain = await this.yp.await_proc("domain_create", ident);

    metadata.step = "password";
    metadata.org_name = signup.name;
    metadata.org_ident = ident;
    metadata.domain_id = domain.id;
    metadata.domain_name = domain.name;
    metadata.link = domain.name;
    metadata.mode = "b2bsignup";
    await this.yp.await_proc("token_update", secret, metadata);
    res = await this.yp.await_proc("token_get_next", secret);
    if (!_.isEmpty(res)) {
      if (res.metadata != null) {
        res.metadata = this.parseJSON(res.metadata);
      }
      delete res["status"];
    }
    this.output.data(res);
  }

  /**
   * Online registering
   * @param {string} email - user email
   */
  async signup() {
    const email = this.input.need(Attr.email).trim();
    const method = this.input.use(Attr.method) || "signup";
    let name = this.input.use(Attr.name);
    const lang = this.input.ua_language();
    let user = await this.yp.await_proc("drumate_get", email);
    if (user != null && user.id) {
      this.output.data({
        rejected: 1,
        reason: "email_exists",
        email,
      });
      return;
    }

    if (!["b2bsignup", "signup"].includes(method)) {
      this.output.data({
        rejected: 1,
        reason: "invalid_method",
        name,
      });
      return;
    }
    const token = this.randomString();
    if (method == "b2bsignup") {
      if (_.isEmpty(name)) {
        this.output.data({
          rejected: 1,
          reason: "empty_name",
          name,
        });
        return;
      }
    }

    if (method == "b2bsignup") {
      let org = await this.yp.await_proc("organisation_get", name);
      if (!_.isEmpty(org)) {
        this.output.data({
          rejected: 1,
          reason: "name_exist",
          name,
        });
        return;
      }
    }

    name = name || email;
    await this.yp.await_proc(
      "token_generate_next",
      email,
      name,
      token,
      method,
      ""
    );

    //const pathname = this.input.use(Attr.location).pathname.replace(/service.*$/, '');
    const link = `${this.input.homepath()}#/welcome/signup/${token}`;
    const subject = Cache.message("_signup_activation", lang);
    let template = "butler/signup";
    if (/b2b/.test(method)) template = "butler/signup-b2b";
    const msg = new Messenger({
      template,
      subject,
      recipient: email,
      lex: Cache.lex(lang),
      data: {
        recipient: email.replace(/@.+$/, ''),
        link,
        home: process.env.domain_name,
      },
      handler: this.exception.email
    });
    //this.debug("ZZZZ:1017 RRRRRRRRRRRRRRRRRRRRRRRRRRRRR")
    await msg.send();
    this.notify_by_email({
      lang,
      link,
      subject,
      template,
      title: subject,
      recipient: email,
    });

    this.output.data({ email });
  }

  /**
   * Initialize user MFS top folders
   * @param {object} user - drumate data
   */
  async _init_top_folders(user) {
    let folders = [];
    for (let dir of ["_photos", "_documents", "_videos", "_musics"]) {
      folders.push({ path: Cache.message(dir) });
    }
    this.debug("INIT FOLDERS ", folders);
    await this.yp.await_proc(
      `${user.db_name}.mfs_init_folders`,
      Stringify(folders),
      1
    );
    this.output.data(user);
  }

  /**
   * Complete signup process
   * @constructor
   * @param {string} secret - secret string required to validate signup
   * @param {string} password - user credential
   * @param {string} socket_id - client socket_id
   */
  async complete_signup() {
    const secret = this.input.need(Attr.secret);
    const pw = this.input.need(Attr.password);
    const socket_id = this.input.need(Attr.socket_id);

    const data = await this.yp.await_proc("token_get", secret);
    if (_.isEmpty(data)) {
      this.output.data({
        rejected: 1,
        reason: "_invalid_secret",
      });
      return;
    }

    if (data.status != "active") {
      this.output.data({
        rejected: 1,
        reason: "_invalid_secret",
      });
      return;
    }
    // no socket means likely a bot
    const socket = await this.yp.await_proc("socket_get", socket_id);
    if (_.isEmpty(socket)) {
      this.output.data({
        rejected: 1,
        reason: "_invalid_handshake",
      });
      return;
    }
    let email = data.email.trim();
    this.debug("complete_signup::::::::::", data);
    let a = email.split("@");
    a = a[0].split(/[\.-_]/);
    const profile = {
      email,
      firstname: a[0],
      lastname: a[1],
      lang: this.input.ua_language(),
    };

    await this._create_account(pw, profile, secret);
  }

  /**
   * Check tocken
   * @param {string} secret - token to be cheked
   */
  async check_token() {
    const secret = this.input.need(Attr.secret);
    let data = await this.yp.await_proc("token_get_next", secret);
    let a;
    if (data && _.isString(data.metadata)) {
      let md = {};
      try {
        md = this.parseJSON(data.metadata);
      } catch (e) { }
      if (md.mobile && data.method == "forgot_password") {
        let mobile = md.mobile;
        md.mobile = mobile.substr(mobile.length - 4);
      }
      data.metadata = md;
    }

    try {
      a = data.email.split("@");
    } catch (e) {
      this.exception.user("invalid_token");
      return;
    }

    if (data.status != "active") {
      this.exception.user("invalid_token");
      return;
    }

    a = a[0].split(/[\.-_]/);
    const base = a[0] || "a";
    let i = await this.yp.await_proc("unique_ident", base);
    data.ident = i.ident;
    this.output.data(data);
  }

  /**
   * Generate a secret and send by email
   * @param {string} email - email required to send the secret token to
   */
  async get_reset_token() {
    const email = this.input.need(Attr.email).trim();
    if (!email.isEmail()) {
      this.output.data({
        rejected: INVALID_EMAIL_FORMAT,
      });
      return;
    }

    let user = await this.yp.await_proc("get_visitor", email);
    if (_.isEmpty(user) || user.id === ID_NOBODY) {
      this.output.data({});
      return null;
    }
    const token = this.randomString();
    await this.yp.await_proc(
      "token_generate_next",
      email,
      email,
      token,
      FORGOT_PASSWORD,
      user.id
    );

    if (token == null) {
      this.exception("Failed to create link");
      return;
    }
    const ulang = this.input.ua_language();
    // const pathname = this.input.use(Attr.location).pathname.replace(/service.*$/, '');
    const link = `${this.input.homepath()}#/welcome/reset/${user.id}/${token}`;
    const subject = Cache.message("_password_reset_link", ulang);

    const msg = new Messenger({
      template: "butler/password-forgot",
      subject,
      recipient: email,
      lex: Cache.lex(ulang),
      data: {
        icon: this.hub.get(Attr.icon),
        recipient: user.fullname,
        link,
        home: process.env.domain_name,
      },
      handler: this.exception.email,
    });
    await msg.send();
    this.output.data({ email });
  }

  /**
   *
   * @returns
   */
  async set_password() {
    const secret = this.input.need(Attr.secret);
    // const socket_id = this.input.need(Attr.socket_id);
    const pw = this.input.need(Attr.password);
    const id = this.input.need(Attr.id);
    let res = {};
    let metadata = {};
    let pass = {};
    let drumate;

    if (!PASS_CHECKER.test(pw)) {
      return this.output.data({ status: "BAD_PASSWORD" });
    }

    drumate = await this.yp.await_proc("drumate_exists", id);
    if (_.isEmpty(drumate)) {
      return this.output.data({ status: "DRUMATE_NOT_EXISTS" });
    }

    pass = await this.yp.await_proc("token_get_next", secret);

    if (_.isEmpty(pass)) {
      return this.output.data({ status: "INVALID_SECRET" });
    }
    if (pass.status != "active") {
      return this.output.data({ status: "INVALID_SECRET" });
    }
    if (pass.method != "forgot_password") {
      return this.output.data({ status: "INVALID_METHOD" });
    }

    metadata = this.parseJSON(pass.metadata);
    if (metadata.step != "password") {
      return this.output.data({ status: "INVALID_STEP" });
    }

    drumate = await this.yp.await_proc("drumate_exists", pass.email);
    if (_.isEmpty(drumate)) {
      return this.output.data({ status: "DRUMATE_NOT_EXISTS" });
    }
    drumate = await this.yp.await_proc("set_password", id, pw);
    let connection = "offline";
    //this.debug("AAA:1586", drumate);
    if ([1, "1", "sms"].includes(drumate.otp)) {
      metadata.step = "otpverify";
      metadata.uid = id;
      metadata.mobile = drumate.mobile;
      metadata.areacode = drumate.areacode;

      let data = await this.send_otp(
        `${metadata.areacode}${metadata.mobile}`,
        metadata.uid
      );
      delete metadata["otp_secret"];
      if (!_.isEmpty(data)) {
        metadata.otp_secret = data.secret;
      }
      await this.yp.await_proc("token_update", secret, metadata);
      res = await this.yp.await_proc("token_get_next", secret);
      connection = "otp";
    } else {
      let profile = {};
      profile.email_verified = "yes";
      profile.connected = "1";
      await this.yp.call_proc("drumate_update_profile", id, stringify(profile));
      //let domain = await this.yp.await_func("domain_name", sid);
      await this.yp.await_proc(
        "session_login_next",
        id,
        pw,
        this.input.sid(),
        drumate.domain
      );
      metadata.step = "complete";
      //await this.log_connection(id)
      await this.yp.await_proc("token_update", secret, metadata);
      res = await this.yp.await_proc("token_get_next", secret);
      await this.yp.await_proc("token_delete", secret);
      connection = "online";
    }
    if (!_.isEmpty(res)) {
      if (res.metadata != null) {
        res.metadata = {};
        res.metadata.step = metadata.step;
        if (!_.isEmpty(metadata.mobile)) {
          res.metadata.mobile = metadata.mobile.substr(
            metadata.mobile.length - 4
          );
        }
      }
    }
    let user = await this.yp.await_proc("get_user", drumate.id);
    this.output.data({ ...user, ...res, connection });
  }

  /**
   *
   */
  async password_otpresend() {
    const secret = this.input.need(Attr.secret);
    // let mobile = this.input.use(Attr.mobile)
    let res = {};
    let metadata = {};
    let pass = {};

    pass = await this.yp.await_proc("token_get_next", secret);
    if (_.isEmpty(pass)) {
      return this.output.data({ status: "INVALID_SECRET" });
    }
    if (pass.status != "active") {
      return this.output.data({ status: "INVALID_SECRET" });
    }

    if (pass.method != "forgot_password") {
      return this.output.data({ status: "INVALID_METHOD" });
    }

    metadata = this.parseJSON(pass.metadata);
    if (metadata.step != "otpresend" && metadata.step != "otpverify") {
      return this.output.data({ status: "INVALID_STEP" });
    }

    let data = await this.send_otp(
      `${metadata.areacode}${metadata.mobile}`,
      metadata.uid
    );

    delete metadata["otp_secret"];
    if (!_.isEmpty(data)) {
      metadata.otp_secret = data.secret;
    }
    metadata.step = "otpverify";
    await this.yp.await_proc("token_update", secret, metadata);
    res = await this.yp.await_proc("token_get_next", secret);
    if (!_.isEmpty(res)) {
      if (res.metadata != null) {
        res.metadata = {}; // this.parseJSON(res.metadata)
        res.metadata.step = metadata.step;
        if (!_.isEmpty(metadata.mobile)) {
          res.metadata.mobile = metadata.mobile.substr(
            metadata.mobile.length - 4
          );
        }
      }
    }
    this.output.data(res);
  }

  /**
   *
   * @returns
   */
  async password_otpverify() {
    let secret = this.input.use(Attr.secret);
    let code = this.input.use(Attr.code);
    let res = {};
    let profile = {};
    let metadata = {};
    let pass = {};

    pass = await this.yp.await_proc("token_get_next", secret);
    if (_.isEmpty(pass)) {
      return this.output.data({ status: "INVALID_SECRET" });
    }
    if (pass.status != "active") {
      return this.output.data({ status: "INVALID_SECRET" });
    }

    if (pass.method != "forgot_password") {
      return this.output.data({ status: "INVALID_METHOD" });
    }

    metadata = this.parseJSON(pass.metadata);
    if (metadata.step != "otpverify") {
      return this.output.data({ status: "INVALID_STEP" });
    }
    let otp = await this.yp.await_proc(
      "otp_check",
      metadata.uid,
      metadata.otp_secret,
      code
    );
    if (!_.isEmpty(otp)) {
      metadata.step = "complete";

      profile.email_verified = "yes";
      profile.mobile_verified = "yes";
      profile.connected = "1";
      await this.yp.call_proc(
        "drumate_update_profile",
        metadata.uid,
        stringify(profile)
      );

      await this.yp.await_proc("token_update", secret, metadata);
      res = await this.yp.await_proc("token_get_next", secret);
      await this.yp.await_proc(
        "session_login_otp",
        metadata.uid,
        code,
        metadata.otp_secret,
        this.input.sid()
      );
      //await this.log_connection(metadata.uid)
      await this.yp.await_proc("token_delete", secret);
      await this.yp.await_proc(
        "otp_delete",
        metadata.uid,
        metadata.otp_secret,
        code
      );
    } else {
      metadata.step = "otpresend";
      await this.yp.await_proc("token_update", secret, metadata);
      res = await this.yp.await_proc("token_get_next", secret);
    }
    if (!_.isEmpty(res)) {
      if (res.metadata != null) {
        res.metadata = {}; // this.parseJSON(res.metadata)
        res.metadata.step = metadata.step;
        if (!_.isEmpty(metadata.mobile)) {
          res.metadata.mobile = metadata.mobile.substr(
            metadata.mobile.length - 4
          );
        }
      }
    }
    this.output.data(res);
  }


  /**
   *
   */
  async check_domain() {
    let url = this.input.get(Attr.domain) || this.input.host();
    let res = {};
    let domain = url;

    try {
      domain = new URL(url).hostname;
    } catch (err) { }
    res.isvalid = 0;
    domain = domain.replace(/^(.*\/\/)/, "").replace(/\/.*$/, "");
    let org = await this.yp.await_proc("organisation_get", domain);
    if (_.isEmpty(org)) {
      res.url = domain;
      return this.output.data(res);
    }
    res.isvalid = 1;
    let user = await this.yp.await_proc("get_user", this.uid);
    res.user = { ...this.user.toJSON(), ...user };
    res.organization = {
      url: org.link,
      name: org.name,
      domain_id: user.domain_id,
      username: user.username,
      uid: user.id,
      ...org,
    };
    const { main_domain } = sysEnv();
    res.main_domain = main_domain;
    res.user.main_domain = main_domain;
    this.session.refreshAuthorization();
    this.output.data({ ...org, ...res });
  }

  /**
   * Set new password through reset link
   * @param {string} secret - secret sent by email
   * @param {string} id - sdrumate id
   * @param {string} password - new password
   */
  async set_pass_phrase() {
    const secret = this.input.need(Attr.secret);
    const id = this.input.need(Attr.id);
    const pw = this.input.need(Attr.password);
    if (!PASS_CHECKER.test(pw)) {
      this.output.data({
        rejected: 1,
        reason: "bad_pass",
      });
      return;
    }
    let user = await this.yp.await_proc("drumate_get", id);
    if (_.isEmpty(user) || user.id === ID_NOBODY) {
      this.output.data({
        rejected: 1,
        reason: "not_found",
      });
      return;
    }
    let data = await this.yp.await_proc(
      "token_check",
      user.email,
      secret,
      FORGOT_PASSWORD
    );
    if (_.isEmpty(data)) {
      this.output.data({
        rejected: 1,
        reason: "not_found",
      });
      return;
    }
    if (data.age / 3600 > 12) {
      await this.yp.await_proc("token_delete", secret);
      this.output.data({
        rejected: 1,
        reason: "expired",
      });
      return;
    }

    await this.yp.await_proc("set_password", user.id, pw);
    await this.yp.await_proc("token_delete", secret);
    this.output.data(user);
  }

  /**
   * 
   */
  hello() {
    const geoip = require("geoip-lite");
    const ip = this.input.ip();
    //this.debug("HELLO", this.user.get(Attr.domain));
    const data = geoip.lookup(ip) || {};
    data.ip = ip;
    this.output.data(data);
  }

  /**
   * 
   */
  ping() {
    const id = this.user.uid();
    this.yp.call_proc("get_visitor", id, this.output.data);
    this.output.list([
      { mfs_rooo: ["db_name", 2] },
      [{ db_name: "data" }],
      { domain_name: process.env.domain_name },
      ["1/1/1", 2],
      "/data",
    ]);
  }
}

module.exports = __butler;
