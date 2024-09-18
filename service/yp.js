// ================================  *
//   Copyright Xialia.com  2013-2017 *
//   FILE  : src/service/yp
//   TYPE  : module
// ================================  *
const {
  Attr, Constants, Cache, toArray, RedisStore, sysEnv
} = require("@drumee/server-essentials");

const {
  INVALID_DATA,
  VIGNETTE,
  ID_NOBODY
} = Constants;
const { Entity, FileIo } = require("@drumee/server-core");
const { existsSync, readFileSync } = require("fs");
const { isEmpty, isString, isArray } = require("lodash");

const { getPlugins } = require("../router/rest");
const { resolve } = require("path");
const { credential_dir } = sysEnv();
let file = resolve(credential_dir, `crypto/public.pem`);
let publicKey = readFileSync(file);

//########################################
class __yp extends Entity {

  /**
   *
   */
  async get_env() {
    const yp = this.yp;
    let data = {
      platform: {},
    };
    let _def_fonts = await yp.await_query(
      "SELECT * FROM font WHERE family='Roboto' ORDER BY `name` ASC"
    );
    data.platform.fonts = [];
    data.platform.description = Cache.getSysConf('platform_intro_popup_title');
    if (data.platform.description) {
      data.platform.description = JSON.parse(data.platform.description);
    }
    data.platform.setup = await yp.await_query(
      "SELECT count(*) as ok FROM privilege where privilege>=63 AND domain_id=1"
    );

    let wp = Cache.getSysConf("wallpaper");
    if (isString(wp)) {
      data.platform.wallpaper = JSON.parse(wp);
    } else {
      data.platform.wallpaper = wp;
    }
    const hub = this.hub.toJSON();
    hub.stylesheets = await this.db.await_proc("style_get_files");
    hub.fonts_links = await this.db.await_proc("get_fonts_links");
    hub.fonts_faces = await this.db.await_proc("get_fonts_faces");
    if (!isEmpty(hub.fonts_faces)) {
      hub.fonts_faces = hub.fonts_faces.concat(_def_fonts);
    }
    if (!hub.exists) {
      this.exception.not_found("HUB_NOT_FOUND");
      return;
    }
    data.hub = { ...data.hub, ...hub };
    this.user.set(Attr.quota, {});
    data.user = await this.yp.await_proc("get_user", this.uid);
    data.user.quota = {};
    data.user.otp_key = this.session.get('secret');
    try {
      data.user.quota = this.parseJSON(data.user.quota);
    } catch (e) { }
    data.disk = await this.yp.await_proc("my_disk_limit", this.uid);

    data.organization = await this.yp.await_proc("my_organisation", this.uid);
    const { main_domain } = sysEnv();
    if (isEmpty(data.organization)) {
      let host = main_domain;
      if (this.uid == ID_NOBODY) {
        host = this.input.host();
      }
      data.organization = await this.yp.await_proc(
        "organisation_get",
        host
      );
    }
    if (isArray(data.organization)) {
      data.organization = data.organization[0] || {};
    }
    data.organization.useEmail = global.myDrumee.useEmail || 0;
    data.user.is_reseller = 0;
    if (data.organization.metadata) {
      data.user.is_reseller = data.organization.metadata.is_reseller || 0;
    } else {
      data.organization.metadata = {};
    }
    data.user.main_domain = main_domain;
    if (this.user.get("signed_in")) {
      data.user.signed_in = 1;
      data.user.connection = "online";
    } else {
      data.user.signed_in = 0;
      data.user.connection = "offline";
    }
    data.user.privilege = data.organization.privilege; // To be use from withon origanization
    data.main_domain = main_domain;
    data.hub = hub;
    data.platform.intl = this.supportedLanguage();
    data.platform.arch = global.myDrumee.arch || "pod";
    data.platform.cdnHost = global.myDrumee.cdnHost;
    data.platform.version = global.VERSION;
    data.platform.licence = {
      signature: await this.yp.await_func("sys_conf_get", "licence_signature"),
      content: await this.yp.await_func("sys_conf_get", "licence_content"),
    };
    if (
      global.myDrumee.isPublic &&
      global.myDrumee.useEmail &&
      global.myDrumee.arch == "cloud"
    ) {
      data.platform.isPublic = 1;
    }
    let plugins = getPlugins();
    if (plugins) {
      data.platform.plugins = plugins;
    }
    data.plateform = data.platform; // tmp
    this.output.data(data);
  }

  /**
   *
   */
  async get_hub() {
    const hub = this.hub.toJSON();
    hub.stylesheets = await this.db.await_proc("style_get_files");
    hub.fonts_links = await this.db.await_proc("get_fonts_links");
    hub.fonts_faces = await this.db.await_proc("get_fonts_faces");
    if (hub.hostname == null) {
      this.exception.not_found("HUB_NOT_FOUND");
      return;
    }
    this.output.data(hub);
  }

  /**
   *
   */
  tutorial() {
    this.yp.call_proc(
      "get_tutorial",
      this.input.get(Attr.name),
      this.output.data
    );
  }

  /**
   *
   */
  async tutorials() {
    let data = await this.yp.await_query("SELECT * FROM tutorial");
    this.output.data(data);
  }

  /**
   *  Device Registration
   */
  async device_registration() {
    let device_id = this.input.need("device_id");
    let device_type = this.input.need("device_type");
    let push_token = this.input.need("push_token");
    let data = await this.yp.await_proc(
      "device_registration",
      device_id,
      device_type,
      push_token,
      this.uid,
      "active"
    );
    this.output.data(data);
  }

  /**
   *
   */
  files_formats() {
    const yp = this.yp;
    // const hub = this.hub.toJSON();
    this.yp.query(
      "select extension, category, mimetype, capability from filecap",
      this.output.list
    );
  }


  /**
   *
   */
  async sys_var() {
    let name = this.input.need(Attr.name);
    let r = await this.yp.await_run(
      "SELECT * FROM sys_var WHERE `name`=? ",
      name
    );
    this.output.data(r);
  }


  /**
   *
   */
  async authenticate() {
    let secret = this.input.need(Attr.secret);
    let code = this.input.need(Attr.code);
    const { ident } = this.input.use("vars") || {};
    if (this.session.isAnonymous()) {
      await this.session.authenticate(secret, code);
    } else {
      let user_id = this.user.get(Attr.id);
      let { uid } = (await this.yp.await_proc("otp_get", secret, code)) || {};
      if (uid) {
        if (uid == user_id) {
          this.output.data({ status: "ALREADY_SIGNED_IN" });
        } else {
          this.output.data({
            status: "CROSS_SIGNED_IN",
            current: profile.email,
            uid: this.user.get(Attr.id),
            input: ident,
          });
        }
      } else {
        this.output.data({ status: "ALREADY_ONLINE" });
      }
    }
  }

  /**
   *
   */
  async login() {
    await this.session.login(this.input.use("vars"), this.input.use("resent"));
  }

  /**
   *
   */
  async guest_login() {
    let token = this.input.need(Attr.token);

    let res = await this.session.dmz_login(token, this.input.get(Attr.password));

    if (res.failed) {
      //res.status = res.error;
      res.validity = res.error;
    }
    let info = await this.yp.await_proc("dmz_info_next", token);

    let rows = await this.yp.await_proc(
      "forward_proc",
      info.hub_id,
      "dmz_settings",
      ``
    );
    info.hours = rows[0].hours;
    info.days = rows[0].days;
    if (info.is_public && !res.guest_name) {
      res.require_name = 1;
    }
    if (res.is_verified) info.require_password = 0;
    if (info.require_password) {
      info.validity = "REQUIRED_PASSWORD";
    }

    let metadata = {};

    if (!res.failed) {
      let r = await this.db.await_proc("mfs_access_node", "*", res.id);
      metadata = this.parseJSON(r.metadata);

      if (!isEmpty(metadata)) {
        metadata.branch = this.parseJSON(metadata.branch);
        if (!isArray(metadata.branch)) {
          metadata.branch = [metadata.branch];
        }
        if (!isEmpty(metadata.session)) {
          delete metadata["session"];
        }

        if (!isEmpty(metadata.fingerprint)) {
          delete metadata["fingerprint"];
        }
        res = {};
        info = {};
        res = metadata;
      }
    }
    this.output.data({ ...res, ...info });
  }

  /**
   *
   */
  async hello() {
    let user = await this.yp.await_proc("get_user", this.uid);
    user.plan_detail = await this.yp.await_proc(
      "renewal_get_next",
      this.uid,
      0
    );
    if (this.user.get("signed_in")) {
      user.signed_in = 1;
      user.connection = "online";
    } else {
      user.signed_in = 0;
      user.connection = "offline";
    }
    this.output.data(user);
  }

  /**
   *
   */
  guest_logout() {
    this.session.dmz_logout();
  }

  /**
   *
   */
  async reset_session() {
    let socket_id = this.input.need(Attr.socket_id);
    let sid = this.input.sid();
    if (!sid || [null, "null", undefined, "undefined"].includes(sid)) {
      return this.excetion.user(INVALID_DATA);
    }
    await this.yp.await_proc("session_reset", sid, this.uid, socket_id);
    this.output.data({ sid, uid: this.uid });
  }

  /**
   *
   */
  get_external_share() {
    const share_id = this.input.need(Attr.share_id);
    this.yp.call_proc("get_external_share", share_id, this.output.data);
  }

  /**
   *
   */
  notification_count() {
    this.yp.call_proc("yp_notification_count", this.uid, this.output.data);
  }

  /**
   * 
   */
  notification_list() {
    this.yp.call_proc(
      "yp_notification_receive_list",
      this.uid,
      this.output.data
    );
  }

  /**
   * 
   */
  get_ident_availablility() {
    const ident = this.input.need(Attr.ident);
    this.yp.call_proc("available_ident", ident, this.output.data);
  }

  /**
   * 
   */
  username_exists() {
    const value = this.input.use(Attr.value);
    this.yp.call_proc(
      "get_user_in_domain",
      value,
      this.input.host(),
      this.output.data
    );
  }

  /**
   * 
   */
  ident_exists() {
    const value = this.input.use(Attr.value);
    this.yp.call_proc("ident_exists", value, this.output.data);
  }

  /**
   * 
   */
  email_exists() {
    const value = this.input.use(Attr.value);
    this.yp.call_proc("email_exists", value, this.output.data);
  }

  /**
   * 
   */
  get_laguages() {
    const name = this.input.use(Attr.value, "") || this.input.use(Attr.name, "");
    const page = this.input.use(Attr.page) || 1;
    this.yp.call_proc("get_laguages", name, page, this.output.data);
  }

  /**
   * 
   */
  public_key() {
    this.output.text(publicKey);
  }

  /**
   * 
   * @returns 
   */
  async avatar() {
    const { resolve } = require("path");
    const type = this.input.get(Attr.type) || VIGNETTE;
    const id = this.input.get(Attr.id) || this.user.get(Attr.id);

    let row = await this.yp.await_proc("get_user", id);
    if (isEmpty(row)) {
      this.output.data({});
      return;
    }
    const png = resolve(row.home_dir, `__config__/icons/avatar-${type}.png`);
    const svg = resolve(row.home_dir, `__config__/icons/avatar-${type}.svg`);
    let filename;
    const file = new FileIo(this);
    if (existsSync(png)) {
      filename = png;
    } else if (existsSync(svg)) {
      filename = svg;
    } else {
      this.output.data({});
      return;
    }
    file.content(filename);
  }

  /**
   * 
   */
  verify_email() {
    const user_id = this.input.use(Attr.uid) || this.user_id();
    const email_hash = this.input.need(Attr.email);
    const token = this.input.need(Attr.token);
    const cb = function (data) {
      if (!isEmpty(data)) {
        this.output.data();
      } else {
        this.excetion.user(INVALID_DATA);
      }
    }.bind(this);
    this.yp.call_proc("drumate_verify_email", user_id, email_hash, token, cb);
  }

  /**
   * Accept id or email
   */
  check_drumate_exist() {
    const id = this.input.need(Attr.id);
    this.yp.call_proc("drumate_exists", id, this.output.data);
  }

  /**
   *
   * @param {*} s
   * @returns
   */
  async broadcastStatus(s) {
    let rows = await this.yp.await_proc("drumate_online_state", this.uid);
    rows = toArray(rows);
    let payload = {
      options: {
        service: "user.connection_status",
        keys: ["user_id"],
      },
    };
    for (var s of rows) {
      payload.socket_id = s.id;
      payload.model = { user_id: s.my_id, status: s.my_state };
      //console.log("AAA:530:", { payload, s });
      await RedisStore.sendData(payload, s.id);
    }
  }

  /**
   *
   */
  async ping() {
    let data = this.input.get("data");
    if (!data || !data.socket_id) {
      this.output.data({ verbosity: global.verbosity, modules: global.debug });
      return;
    }
    redisStore.sendData(data);
    this.output.data({ verbosity: global.verbosity, modules: global.debug });
  }

  /**
   *
   */
  clear_share() {
    this.output.output({});
  }
}

module.exports = __yp;
