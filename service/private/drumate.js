
const { existsSync } = require('fs');
const { isEmpty, isArray } = require('lodash');
const { 
  Attr, toArray, Remit, Constants, sendSms,
  Messenger, DrumeeCache, RedisStore 
} = require("@drumee/server-essentials")

const { 
  INVALID_EMAIL_FORMAT, 
  EMAIL_ALREADY_EXIST, 
  WRONG_PASSWORD 
} = Constants;

const { Entity, Generator, MfsTools } = require("@drumee/server-core");
const { get_node_content } = MfsTools;

//########################################
class __private_drumate extends Entity {

  /**
   * 
   * @returns 
   */
  async hub_to_pro() {
    const self = this;
    let ident = this.input.need(Attr.ident);
    ident = ident.toLowerCase();
    let name = this.input.need(Attr.name)
    let metadata = {}
    let res = {};
    let chk;
    if (this.user.domain_id() > 1) {
      return this.output.data({ status: 'PRO_USER' });
    }

    let org = await this.yp.await_proc('organisation_get', name);
    if (!isEmpty(org)) {
      return this.output.data({ status: 'NAME_NOT_AVAILABLE' });
    }
    let domain = `${ident}.${process.env.domain_name}`;
    chk = await this.yp.await_proc('vhost_exists', domain);
    let dom = await this.yp.await_proc('domain_exists', domain);
    if (!isEmpty(chk) || !isEmpty(dom)) {
      return this.output.data({ status: 'URL_NOT_AVAILABLE' });
    }

    domain = await this.yp.await_proc('domain_create', ident);

    metadata.step = 'hub_to_pro'
    metadata.org_name = name
    metadata.org_ident = ident
    metadata.domain_id = domain.id;
    metadata.domain_name = domain.name;
    metadata.link = domain.name
    metadata.mode = 'hub_to_pro'

    await this.yp.await_proc('domain_grant', metadata.domain_id, Remit.dom_owner, this.uid, 1);
    await this.yp.await_proc('organisation_add', this.uid, metadata.org_name, metadata.link, metadata.org_ident, metadata.domain_id, metadata);
    await this.yp.await_proc('drumate_hub_to_pro', this.uid, domain.id, Remit.dom_owner);
    await this.yp.await_proc('ticket_grant_permission', this.uid);


    let profile = {}
    profile.email_verified = 'yes';
    profile.connected = '1';
    profile.profile_type = 'pro',
      profile.quota = DrumeeCache.getSysConf('quota')
    await this.yp.await_proc('drumate_update_profile', this.uid, JSON.stringify(profile));
    let sockets = await this.yp.await_proc('user_sockets', this.uid);
    await RedisStore.sendData(this.payload(domain), sockets);

    this.output.data(domain);
  }

  /**
   * 
   * @returns 
   */
  async challenge_pw() {
    const password = this.input.use(Attr.password) || this.input.use(Attr.old_password);
    let data = await this.yp.await_proc('check_password_next', this.uid, password);
    if (isEmpty(data)) {
      this.trigger(_e.denied);
      return
    }
  }

  /**
   * 
   * @returns 
   */
  async change_email() {
    const email = this.input.need(Attr.email);
    if (!email.isEmail()) {
      this.exception.user(INVALID_EMAIL_FORMAT);
      return;
    }
    let row = await this.yp.await_proc('email_exists', email);
    if (!isEmpty(row) && row.email) {
      this.exception.user(EMAIL_ALREADY_EXIST);
      return;
    }
    let data = await this.yp.await_proc('drumate_change_email', this.uid, email);
    this.output.data(data);
  }

  /**
   * 
   */
  check_password() {
    this.yp.call_proc('check_password_next', this.uid, password, this.output.data);
  }

  /**
   * 
   */
  change_mobile() {
    const user_id = this.user_id();
    const mobile = this.input.need(Attr.mobile);
    this.yp.call_proc('drumate_change_mobile', user_id, mobile, this.output.data);
  }


  /**
   * 
   * @returns 
   */
  async change_password() {
    const old_password = this.input.need(Attr.old_password);
    const new_password = this.input.need(Attr.new_password);
    let r = await this.yp.await_proc('check_password_next', this.uid, old_password);
    if (isEmpty(r)) {
      this.exception.forbiden('wrong_password');
      return
    }
    if (!new_password.match(/(.+){8,}/)) { //(/(.+){2,} +(.+){4,}/)
      this.exception.reject('uncompliant_password');
    } else {
      r = await this.yp.await_proc('set_password', this.uid, new_password);
      this.output.data(r)
    }
  }

  /**
   * 
   */
  get_profile() {
    this.yp.call_proc('get_user', this.user.get(Attr.id), this.output.data);
  }
  /** 
   * 
  */
  async show_login_log() {
    const uaParser = require('ua-parser-js');
    let page = this.input.use(Attr.page, 1);
    let data = await this.yp.await_proc('show_login_log', this.uid, page);
    let res = [];
    let device = {};
    let md;
    data = toArray(data) || [];
    for (let row of data) {
      try {
        let d = uaParser(row.ua);
        if (d.type) {
          device.family = `${d.device.vendor}/${d.device.model}/${d.device.type}`;
        } else {
          device.family = `${d.os.name}/${d.browser.name}/${d.browser.version}`;
        }
        //this.debug("AAAA:148", device);
      } catch (e) {
        this.warn("GOT ERROR", row.metadata, e);
      }
      res.push({
        city: row.city,
        ip: row.ip,
        intime: row.intime,
        outtime: row.outtime,
        status: row.status,
        device,
      });
    }
    this.output.list(res);
  }

  /** Get One Time Password
   * If no phone, send by email
   *  @params {object} cur_profile -- as extracted from yp
   *  @params {object} args -- extra data to be sent back to frontend
   */
  async get_otp() {
    const Sms = require('../../vendor/smsfactor');
    let profile = this.user.get(Attr.profile);
    if (isEmpty(profile)) {
      let user = await this.yp.await_proc('get_visitor', this.uid);
      profile = this.parseJSON(user.profile);
    }
    const token = this.randomString();
    const lang = this.client_language();
    let otp = await this.yp.await_proc('otp_create', this.uid, token);
    let message = DrumeeCache.message('_otp_code', lang);
    const Moment = require('moment');
    Moment.locale(lang);
    const expiry = Moment(otp.expiry, 'X').format("hh:mm");
    let phone = null;
    let email = null;
    let tips = null;
    try {
      phone = profile.mobile.phoneNumber()
    } catch {
      email = profile.email;
    }
    message = `${message.format(otp.code, expiry)}`;

    email = profile.email;
    if (phone) {
      let opt = {
        message,
        receivers: [phone]
      }
      let sms = new Sms(opt);
      sms.send().then((result) => {
        if (!isEmpty(result.invalidReceivers)) {
          let msg = `${DrumeeCache.message('_invalid_recipient', lang)}`
          this.output.data({ error: `${msg} : ${result.invalidReceivers[0]}` });
          return;
        }
      })
      tips = phone.match(/(^.+)([0-9]{4,4})$/)[3];
      tips = tips;
    } else if (email) {
      const lang = this.client_language();
      const subject = DrumeeCache.message("_your_otp", lang);
      const fullname = this.user.get(Attr.fullname);
      const msg = new Messenger({
        template: "butler/otp",
        subject,
        recipient: email,
        lex: DrumeeCache.lex(lang),
        data: {
          subject,
          message,
          code: otp.code,
          firstname: this.user.get(Attr.firstname),
          fullname: fullname,
          recipient: fullname,
        },
        handler: this.exception.email
      });
      tips = email.match(/(^.+)(@)(.+)$/)
      tips = tips[3];
      await msg.send();
    } else {
      this.exception.user("Invalid profile");
      return;
    }
    otp.code = null;
    otp.tips = tips;
    this.output.data(otp);
  }


  /** check_otp
   *  Check if there pending OTP
   */
  async check_otp() {
    let secret = this.input.use(Attr.secret);
    let code = this.input.use(Attr.code);
    if (secret && code) {
      let otp = await this.yp.await_proc('otp_check', this.uid, secret, code);
      if (isEmpty(otp)) {
        this.exception.user(WRONG_PASSWORD);
      } else {
        await this.yp.await_proc('otp_delete', this.uid, secret, code);
        await this.do_update_profile();
      }
      return true;
    }
    return false;
  }

  /** do_update_profile
   * 
   */
  async do_update_profile() {
    let profile = this.input.need(Attr.profile);
    const profile_str = JSON.stringify(profile);
    let data = await this.yp.await_proc(
      'drumate_update_profile',
      this.uid,
      profile_str
    );
    try {
      profile = this.parseJSON(data.profile);
      if (!isEmpty(profile.address)) {
        profile.address = this.parseJSON(profile.address);
      }

    } catch (e) {
      this.warn("GOT ERROR", e);
    }
    await this.yp.call_proc('contact_sync_update', this.uid);
    this.output.data(profile);
  }


  /**
   * 
   */
  async intro_acknowledged() {
    let profile = '{"intro":"no"}';
    let data = await this.yp.await_proc('drumate_update_profile', this.uid, profile);
    this.output.data(data);
  }


  /**
   * 
   * @returns 
   */
  async update_profile() {
    let user = this.user.toJSON();
    let { profile } = user;
    if (await this.check_otp()) return;
    if (/^(sms|email|passkey|1)$/.test(profile.otp)) {
      await this.session.send_otp(user);
      return;
    }
    await this.do_update_profile();
  }

  /**
   * 
   */
  async get_settings() {
    const user_id = this.input.need(Attr.user_id);
    let data = await this.yp.await_proc('get_entity_settings', user_id);
    let settings;
    if (isEmpty(data) || isEmpty(data.settings)) {
      settings = {};
    } else {
      settings = this.parseJSON(data.settings);
    }
    this.output.data(settings);
  }

  /**
   * 
   */
  async update_settings() {
    const settings = this.input.need(Attr.settings);
    let old_settings = this.user.get(Attr.settings) || {};
    const settings_str = JSON.stringify({ ...old_settings, ...settings });
    this.debug(`:::::${settings_str}:::::::: update_settings`);
    let res = await this.yp.await_proc('entity_update_settings', this.uid, settings_str);
    this.output.data(res);
  }

  /**
   * 
   */
  async disk_space() {
    let data = await this.db.await_proc('mfs_manifest', this.home_id, this.uid, 0);
    this.output.list(data);
  }

  /**
   * 
   */
  my_hubs() {
    const page = this.input.use('page', 1);
    this.db.call_proc("my_hubs", page, this.output.list);
  }

  /**
   * 
   * @returns 
   */
  contacts() {
    const page = this.input.use('page', 1);
    const only_drumate = this.input.use('only_drumate', 0);
    const key = this.input.use('value', "");
    if (isEmpty(key)) {
      this.output.data([]);
      return;
    }
    if (only_drumate) {
      this.db.call_proc("my_contact", key, page, JSON.stringify([]), 'active', this.output.list);
    }
    else {
      this.db.call_proc("contact_search_next", key, page, this.output.list);
    }
  }

  /**
   * Gets list of hubs that an user own or belongs to.
   */
  hubs() {
    const page = this.input.use('page', 1);
    this.db.call_proc("drumate_hubs", page, this.output.data);
  }

  /**
   * 
   */
  async helpdesk() {
    let temp_result = [];
    const ulang = this.input.get('Xlang') || this.user.language();
    const page = this.input.use('page', 1);
    let data = await this.yp.await_proc('helpdesk', ulang, page);
    if (isArray(data)) {
      data = [data]
    }
    for (let message of data) {
      message.metadata = this.parseJSON(message.metadata)
      temp_result.push(message);
    }
    this.output.data(temp_result);
  }

  /**
   * Adds a font to drumate's font table.
   * Not used yet
   */
  font_add() {
    const fontname = this.input.need(Attr.fontname);
    this.db.call_proc("font_add", fontname, this.output.data);
  }

  /**
   * 
   */
  font_last() {
    this.db.call_proc("font_last", this.output.data);
  }

  /**
   * Adds a color to drumate's color table.
   */
  color_add() {
    const rgba = this.input.need(Attr.rgba);
    const hexacode = this.input.need(Attr.hexacode);
    this.db.call_proc("color_add", rgba, hexacode, this.output.data);
  }

  /**
   * Gets last used colors.
   */
  color_last() {
    this.db.call_proc("color_last", this.output.data);
  }

  /**
   * 
   */
  async data_usage() {
    let disk = await this.yp.await_proc('my_disk_limit', this.uid);
    var r = await this.db.await_proc("mfs_manifest", this.home_id, this.uid, 0);
    this.output.data({
      total: r[0],
      details: toArray(r[2]),
      usage: r[3],
      disk
    });
  }

  /**
   * 
   */
  async show_backup_log() {
    const page = this.input.use(Attr.page, 1);
    var r = await this.db.await_proc("log_show_backup", page);
    this.output.list(r);
  }


  /**
   * Confirm account deletion
   * @param {string} token - secret string required to validate account deletion
   */
  async confirm_delete_account() {
    let secret = this.input.need(Attr.secret);
    const data = await this.yp.await_proc('token_get', secret);
    if (isEmpty(data)) {
      this.output.data({
        rejected: 1,
        reason: '_invalid_secret'
      });
      return;
    }
    let hubs = await this.db.await_proc('show_hubs');
    hubs = toArray(hubs) || [];
    for (let hub of hubs) {
      if (hub.owner_id == this.uid) {
        await this.notify_hub(hub.id, { service: "desk.leave_hub", id: hub.id });
        await this.yp.await_proc(`${hub.db_name}.remove_all_members`, 0);
      } else {
        await this.db.await_proc('leave_hub', hub.id);
      }
    }
    await this.yp.await_proc(`drumate_freeze`, this.uid);
    await this.yp.await_proc("token_delete", secret);
    secret = this.randomString();
    const fullname = this.user.get(Attr.fullname);
    let recipient = this.user.get(Attr.profile).email;
    await this.yp.await_proc('token_generate',
      recipient, fullname, secret, 'delete_account', this.uid);
    const lang = this.client_language();
    const subject = DrumeeCache.message("_account_reactivation_link", lang);
    const message = DrumeeCache.message("_account_deletion_email", lang);
    // const pathname = this.input.pathname().replace(/(svc|service).*$/, '');
    const link = `${this.input.homepath()}#/welcome/back=${secret}`;
    const Moment = require('moment');
    let date = Moment(this.input.timestamp / 1000 + 30 * 60 * 60 * 24, 'X')
      .format('dddd Do MMMM YYYY à hh:mm');
    const msg = new Messenger({
      template: "butler/deletion-revert-link",
      subject,
      recipient,
      lex: DrumeeCache.lex(lang),
      data: {
        subject,
        message,
        link,
        date,
        secret,
        firstname: this.user.get(Attr.firstname),
        fullname: fullname,
        recipient: fullname,
      },
      handler: this.exception.email
    });
    await msg.send();
    this.session.logout({ redirect: "#/welcome/checkout" });
  }

  /**
   * Prepare account deletion
   * Shall send secret link containing a token that will be used to confirm deletion
   * @constructor
   */
  async delete_account() {
    let secret = this.input.use(Attr.secret);
    let code = this.input.use(Attr.code);
    let otp = await this.yp.await_proc('otp_check', this.uid, secret, code);
    if (isEmpty(otp)) {
      this.exception.user('_invalid_key');
      return;
    }

    secret = this.randomString();
    const fullname = this.user.get(Attr.fullname);
    let recipient = this.user.get(Attr.profile).email;
    await this.yp.await_proc('token_generate',
      recipient, fullname, secret, 'delete_account', this.uid);
    this.output.data({ secret });
  }

  /**
   * Set user avatar using a media available in MFS
   * @param {string} reference - media id from MFS
   */
  async set_avatar() {
    const nid = this.input.use('reference');
    let node = await this.db.await_proc("mfs_node_attr", nid);
    if (isEmpty(node)) {
      this.exception.not_found("no_avatar");
      return;
    }
    const orig = get_node_content(node);
    if (!existsSync(orig)) {
      this.exception.not_found("no_avatar");
      return;
    }

    Generator.create_avatar(nid, node.ext, this.user.get(Attr.home_dir), orig);
    await this.yp.await_proc('entity_touch', this.uid);
    let data = await this.yp.await_proc('get_visitor', this.uid);
    this.output.data(data);
  }

  /**
   * 
   */
  async remove_avatar() {
    const root = this.user.get(Attr.home_dir)
    const { join } = require('path');
    const png = join(root, '__config__/icons/avatar*.png')
    const svg = join(root, '__config__/icons/avatar*.svg');
    const orig = join(root, '__config__/icons/tmp.*');
    const { rm } = require('shelljs');
    try {
      rm('-f', png);
    } catch (e) {
      this.debug("REMOVE AVATAR", e);
    };
    try {
      rm('-f', svg);
    } catch (e) {
      this.debug("REMOVE AVATAR", e);
    };

    try {
      rm('-f', orig);
    } catch (e) {
      this.debug("REMOVE AVATAR", e);
    };

    await this.yp.await_proc('entity_touch', this.uid);
    let data = await this.yp.await_proc('get_visitor', this.uid);
    this.output.data(data);
  }

  /**
   * 
   */
  set_lang() {
    let lang = this.supportedLanguage(this.input.get('Xlang')); // Don't use Attr.lang, because it's superset by core/io
    this.debug(`ZEZEZEZEZE lang=${lang}`, this.user_id());
    this.yp.call_proc('drumate_set_lang', this.user_id(), lang, this.output.data);
  }

  /**
   * 
   */
  privacy() {
    let lang = this.supportedLanguage(this.input.get('Xlang')); // Don't use Attr.lang, because it's superset by core/io
    this.yp.call_proc('drumate_set_privacy', this.user_id(), lang, this.output.data);
  }

  /**
   * 
   */
  async logout() {
    let data = {
      session_id: this.input.sid()
    }
    let device_id = this.input.get("device_id");
    if (device_id)
      await this.yp.await_proc('unregister_user_with_device',
        device_id
      );

    let sockets = await this.yp.await_proc('user_sockets', this.uid);
    sockets = toArray(sockets).filter((e) => { return e.cookie == data.session_id })

    await RedisStore.sendData(this.payload(data), sockets);

    this.session.logout();
  }


  /**
   * 
   */
  async notification_remove() {
    let r = { ok: 1 };
    const entity_id = this.input.use(Attr.entity_id) || '';
    let message;
    let tickets;
    let entity = 'hub';
    if (isEmpty(entity_id)) {
      entity = 'empty';
    } else if (entity_id == 'Support Ticket') {
      entity = 'Support Ticket';
      let sbox = await this.db.await_proc("mfs_wicket_home", this.uid);

      tickets = await this.yp.await_proc('forward_proc', sbox.hub_id, 'ticket_unreaded', `'${this.uid}'`);
    } else {
      let drumate = await this.yp.await_proc('drumate_exists', entity_id);
      if (!isEmpty(drumate)) { entity = 'drumate' }
    }

    let data = await this.db.await_proc("notification_remove_next", entity_id);

    switch (entity) {
      case 'hub':
        message = await this.yp.await_proc('forward_proc', entity_id, 'channel_get_last', `'${this.uid}'`);
        break;
      case 'drumate':
        message = await this.db.await_proc("channel_get_last", entity_id);
        await this.db.await_proc('list_message', { page: 1, entity_id });
        this.debug("AAA:896", message);
        break;
    }

    let sockets = await this.yp.await_proc('user_sockets', this.uid);
    await RedisStore.sendData(this.payload({ ok: 1 }), sockets);

    let service = "chat.acknowledge";
    if (!isEmpty(message)) {
      switch (entity) {
        case 'drumate':
          sockets = await this.yp.await_proc('user_sockets', [message.author_id, this.uid]);
          break;
        case 'hub':
          message.hub_id = entity_id
          sockets = await this.yp.await_proc('user_sockets', this.uid);
      }
      await RedisStore.sendData(this.payload(message, { service }), sockets);
    }


    if (!isEmpty(tickets) && entity == 'Support Ticket') {
      for (let msg of toArray(tickets)) {
        msg.is_seen = 1
        sockets = await this.yp.await_proc('user_sockets', this.uid);
        await RedisStore.sendData(this.payload(msg, { service }), sockets);

        let support = await this.yp.call_proc('member_list_all', this.uid,
          DrumeeCache.getSysConf('support_domain')
        );
        let dest = [];
        for (let member of toArray(support)) {
          if (this.uid == member.drumate_id) continue;
          dest.push(member.drumate_id);
        }
        sockets = await this.yp.await_proc('user_sockets', dest);
        await RedisStore.sendData(this.payload(msg, { service }), sockets);
      }
    }

    this.output.data(r);
  }

  /**
   * 
   */
  async notification_center() {
    var r = await this.db.await_proc("notification_center_next");
    this.output.list(r);
  }

  /**
   * 
   */
  get_drumate_detail() {
    const id = this.input.need(Attr.id);
    this.yp.call_proc('drumate_exist', id, this.output.data);
  }

  /**
   * 
   * @returns 
   */
  async update_ident() {
    const ident = this.input.need(Attr.ident);
    const id = this.input.need(Attr.id);
    let chk;
    let my_org = await this.yp.await_proc('my_organisation', id)
    if (isEmpty(my_org)) {
      chk = await this.yp.await_proc('get_user_in_domain', ident, 1)
    }
    else {
      chk = await this.yp.await_proc('get_user_in_domain', ident, my_org.domain_id)
    }

    if (chk.exists == 1) {
      this.exception.user('_ident_already_exists');
      return
    }

    let profile = {};
    if (!isEmpty(ident)) {
      profile.ident = ident
      profile.username = ident
    }
    await this.yp.call_proc('drumate_update_profile', id, JSON.stringify(profile));
    await this.yp.await_proc('drumate_change_username', id, ident);
    let res = await this.yp.await_proc('get_visitor', id);
    this.output.data(res);
  }
}


module.exports = __private_drumate;
