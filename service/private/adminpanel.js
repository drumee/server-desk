
// ================================  *
//   Copyright Xialia.com  2013-2017 *
//   FILE  : src/service/private/chat
//   TYPE  : module
// ================================  *
const { Attr, Constants, Remit, sysEnv } = require("@drumee/server-essentials");
const { utils, Messenger, RedisStore, Cache } = require('@drumee/server-essentials');
const { toArray } = utils;
const { main_domain } = sysEnv();

const { stringify } = JSON;
const { isEmpty, isArray, isString, uniqueId } = require('lodash');
const Crypto = require("crypto");
const xlsxj = require("xlsx-to-json");
const Uniqid = require('uniqid');
const { Mfs, MfsTools } = require('@drumee/server-core');
const { remove_dir } = MfsTools;
class __private_adminpanel extends Mfs {

  // ========================
  // initialize
  // ========================
  constructor(...args) {
    super(...args);

    this.my_subscription = this.my_subscription.bind(this);
    this.my_organisation = this.my_organisation.bind(this);
    this.my_privilege = this.my_privilege.bind(this);

    this.organisation_add = this.organisation_add.bind(this);
    this.organisation_update = this.organisation_update.bind(this);
    this.organisation_update_password_level = this.organisation_update_password_level.bind(this);
    this.organisation_update_double_auth = this.organisation_update_double_auth.bind(this);
    this.organisation_update_dir_visiblity = this.organisation_update_dir_visiblity.bind(this);
    this.organisation_update_dir_info = this.organisation_update_dir_info.bind(this);

    this.role_add = this.role_add.bind(this);
    this.role_rename = this.role_rename.bind(this);
    this.role_delete = this.role_delete.bind(this);
    this.role_show = this.role_show.bind(this);
    this.role_assigned = this.role_assigned.bind(this);
    this.role_assign = this.role_assign.bind(this);
    this.role_reposition = this.role_reposition.bind(this);


    this.member_add = this.member_add.bind(this);
    this.member_update = this.member_update.bind(this);
    this.member_delete = this.member_delete.bind(this);
    this.member_disconnect = this.member_disconnect.bind(this);
    this.member_show = this.member_show.bind(this);
    this.member_list = this.member_list.bind(this);
    this.member_loginlog = this.member_loginlog.bind(this);

    this.member_admin_add = this.member_admin_add.bind(this);
    this.member_admin_remove = this.member_admin_remove.bind(this);
    this.member_admin_list = this.member_admin_list.bind(this);

    this.send_password_link = this.send_password_link.bind(this);
    this.password_link = this.password_link.bind(this);


    this.import_validate = this.import_validate.bind(this);
    this.import_process = this.import_process.bind(this);
    this.import_load = this.import_load.bind(this);

    this.member_change_status = this.member_change_status.bind(this)
    this.member_block = this.member_block.bind(this);
    this.member_unblock = this.member_unblock.bind(this);
    this.member_authentification = this.member_authentification.bind(this);

    this.members_import = this.members_import.bind(this);

    this.members_whocansee = this.members_whocansee.bind(this);
    this.members_whocansee_update = this.members_whocansee_update.bind(this);

    this.mimic_new = this.mimic_new.bind(this);
    this.mimic_reject = this.mimic_reject.bind(this);
    this.mimic_active = this.mimic_active.bind(this);
    this.mimic_end_bytime = this.mimic_end_bytime.bind(this);
    this.mimic_end_byuser = this.mimic_end_byuser.bind(this);
    this.mimic_end_bymimic = this.mimic_end_bymimic.bind(this);

  }


  /**
   * 
   * @returns 
   */
  async members_whocansee() {
    let user_id = this.input.need(Attr.user_id);
    let orgid // = this.input.need(Attr.orgid);
    let res = {};

    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');

    let my_org = await this.yp.await_proc('my_organisation', user_id)
    if (isEmpty(my_org)) return this.output.status('NO_ORG');

    if (my_org.id != org.id) return this.output.status('INVALID_ORG');
    res.member = [];
    let contacts = await this.yp.await_proc('contact_assignment_get', user_id);
    if (!isEmpty(contacts)) {
      if (!isArray(contacts)) {
        contacts = [contacts]
      }
      for (let contact of contacts) {
        res.member.push(contact.uid)
      }
    }
    this.output.list(res);
  }


  /**
   * 
   * @returns 
   */
  async members_whocansee_update() {
    let user_id = this.input.need(Attr.user_id);
    let users = this.input.need(Attr.users) || [];
    let orgid //= this.input.need(Attr.orgid);
    let res = {};
    let contacts = {}

    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');

    let my_org = await this.yp.await_proc('my_organisation', user_id)
    if (isEmpty(my_org)) return this.output.status('NO_ORG');

    if (my_org.id != org.id) return this.output.status('INVALID_ORG');

    let isinvaliddrumate = 0;
    let isinvalidorg = 0;
    for (let entity_id of users) {
      let drumate = await this.yp.await_proc('drumate_exists', entity_id);
      if (user_id == entity_id) { isinvaliddrumate = isinvaliddrumate + 1 }
      if (isEmpty(drumate)) {
        isinvaliddrumate = isinvaliddrumate + 1
      }
      if (!isEmpty(drumate)) {
        let his_org = await this.yp.await_proc('my_organisation', drumate.id)
        if (!isEmpty(his_org)) {
          if (his_org.id != org.id) {
            isinvalidorg = isinvalidorg + 1
          }
        }
      }
    }

    if (isinvaliddrumate > 0) return this.output.status('NOT_VALID_DRUMATE');

    if (isinvalidorg > 0) return this.output.status('NOT_VALID_ORG');

    contacts = await this.yp.await_proc('contact_assignment_update', user_id, stringify(users));
    res.member = []
    if (!isEmpty(contacts)) {
      if (!isArray(contacts)) {
        contacts = [contacts]
      }
      for (let contact of contacts) {
        res.member.push(contact.uid)
      }
    }
    this.output.list(res);
  }

  /**
   * 
   * @returns 
   */
  async mimic_end_bytime() {
    // let orgid = this.input.need(Attr.orgid);
    const mimic_id = this.input.need(Attr.mimic_id);
    let res = {};
    await new Promise(resolve => setTimeout(resolve, 5000));
    let mimic = await this.yp.await_proc('mimic_get', mimic_id)

    if (isEmpty(mimic)) return this.output.status('NO_MIMIC');
    if (mimic.mimicker != this.mimicker) return this.output.status('INVALID_MIMIC');
    if (mimic.status != 'active') return this.output.status('INVALID_STATUS');
    if (mimic.remaining_time > 0) return this.output.status('INVALID_TIME');

    res.status = 'INVALID_STATUS';
    let final = await this.yp.await_proc('mimic_set_by_status', mimic_id, 'endbytime')
    if (final.status != 'active') {
      await this.yp.await_proc('uncast_user', mimic.mimicker, mimic.uid)
      res = await this.yp.await_proc('mimic_get', mimic_id)
      let recipients = await this.yp.await_proc('user_sockets', [mimic.uid, mimic.mimicker]);
      await RedisStore.sendData(this.payload(res), recipients);
    }
    this.output.list(res);
  }

  /**
   * 
   */
  async mimic_end_bymimic() {
    //const orgid = this.input.need(Attr.orgid);
    const mimic_id = this.input.need(Attr.mimic_id);

    let mimic = await this.yp.await_proc('mimic_get', mimic_id)
    if (isEmpty(mimic)) return this.output.status('NO_MIMIC');

    if (mimic.mimicker != this.mimicker) return this.output.status('INVALID_MIMIC');

    if (mimic.status != 'active') return this.output.status('INVALID_STATUS');
    res.status = 'INVALID_STATUS';
    let final = await this.yp.await_proc('mimic_set_by_status', mimic_id, 'endbymimic')
    if (final.status != 'active') {
      await this.yp.await_proc('uncast_user', mimic.mimicker, mimic.uid)
      res = await this.yp.await_proc('mimic_get', mimic_id)
      let recipients = await this.yp.await_proc('user_sockets', [mimic.uid, mimic.mimicker]);
      await RedisStore.sendData(this.payload(res), recipients);
    }
    this.output.list(res);
  }

  /**
   * 
   * @returns 
   */
  async mimic_end_byuser() {
    const mimic_id = this.input.need(Attr.mimic_id);

    let mimic = await this.yp.await_proc('mimic_get', mimic_id)
    if (isEmpty(mimic)) return this.output.status('NO_MIMIC');

    if (mimic.uid != this.uid) return this.output.status('INVALID_MIMIC');

    if (mimic.status != 'active') return this.output.status('INVALID_STATUS');

    await this.yp.await_proc('mimic_set_by_status', mimic_id, 'endbyuser')
    await this.yp.await_proc('uncast_user', mimic.mimicker, mimic.uid)
    res = await this.yp.await_proc('mimic_get', mimic_id)
    let recipients = await this.yp.await_proc('user_sockets', [mimic.uid, mimic.mimicker]);
    await RedisStore.sendData(this.payload(res), recipients);
    this.output.list(res);
  }

  /**
   * 
   * @returns 
   */
  async mimic_active() {
    let orgid //= this.input.need(Attr.orgid);
    const mimic_id = this.input.need(Attr.mimic_id);
    let res = {};

    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');

    let mimic = await this.yp.await_proc('mimic_get', mimic_id)
    if (isEmpty(mimic)) return this.output.status('NO_MIMIC');
    if (mimic.uid != this.uid) return this.output.status('INVALID_MIMIC');
    if (mimic.status != 'new') return this.output.status('INVALID_STATUS');

    let online = await this.yp.await_proc('socket_user_connections', mimic.mimicker)
    if (isEmpty(online)) {
      await this.yp.await_proc('mimic_set_by_status', mimic_id, 'noonline')
      res.member = await this.yp.await_proc('show_member_detail', mimic.mimicker, orgid);
      return this.output.status('NOT_ONLINE');
    }

    await this.yp.await_proc('mimic_set_by_status', mimic_id, 'active')
    await this.yp.await_proc('cast_user', mimic.mimicker, mimic.uid)
    res = await this.yp.await_proc('mimic_get', mimic_id)
    let recipients = await this.yp.await_proc('user_sockets', [mimic.uid, mimic.mimicker]);
    await RedisStore.sendData(this.payload(res), recipients);
    this.output.list(res);
  }

  /**
   * 
   * @returns 
   */
  async mimic_reject() {
    const mimic_id = this.input.need(Attr.mimic_id);

    let mimic = await this.yp.await_proc('mimic_get', mimic_id)
    if (isEmpty(mimic)) return this.output.status('NO_MIMIC');
    if (mimic.uid != this.uid) return this.output.status('INVALID_MIMIC');
    if (mimic.status != 'new') return this.output.status('INVALID_STATUS');

    await this.yp.await_proc('mimic_set_by_status', mimic_id, 'reject')
    res = await this.yp.await_proc('mimic_get', mimic_id)
    let recipients = await this.yp.await_proc('user_sockets', [mimic.uid, mimic.mimicker]);
    await RedisStore.sendData(this.payload(res), recipients);
    this.output.list(res);
  }

  /**
   * 
   */
  async mimic_new() {
    let user_id = this.input.need(Attr.user_id);

    if (this.uid == user_id) return this.output.status('INVALID_USER');

    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');

    let hismimic = await this.yp.await_proc('mimic_get_by_status', user_id, 'new')
    if (!isEmpty(hismimic)) return this.output.status('MIMIC_ALREADY');
    hismimic = await this.yp.await_proc('mimic_get_by_status', user_id, 'active')
    if (!isEmpty(hismimic)) return this.output.status('MIMIC_ALREADY');
    let mymimic = await this.yp.await_proc('mimic_get_by_status', this.uid, 'new')
    if (!isEmpty(mymimic)) return this.output.status('MIMIC_ALREADY');
    mymimic = await this.yp.await_proc('mimic_get_by_status', this.uid, 'active')
    if (!isEmpty(mymimic)) return this.output.status('MIMIC_ALREADY');

    let member = await this.yp.await_proc('show_member_detail', user_id, orgid);

    let online = await this.yp.await_proc('socket_user_connections', user_id)
    if (isEmpty(online) && ['active'].includes(member.status)) {
      res.member = member
      return this.output.status('NOT_ONLINE');
    }

    if (['locked', 'archived'].includes(member.status)) {
      mymimic = await this.yp.await_proc('mimic_new', user_id, this.uid)
      await this.yp.await_proc('mimic_set_by_status', mymimic.mimic_id, 'active')
      await this.yp.await_proc('cast_user', mymimic.mimicker, mymimic.uid)
      res = await this.yp.await_proc('mimic_get', mymimic.mimic_id)
    }
    else {
      res = await this.yp.await_proc('mimic_new', user_id, this.uid)
    }
    let recipients = await this.yp.await_proc('user_sockets', [user_id, this.uid]);
    await RedisStore.sendData(this.payload(res), recipients);
    this.output.data(res);
  }

  /**
   * 
   */
  async member_change_status() {

    let orgid
    let res = {};
    let user_id = this.input.need(Attr.user_id);
    let status = this.input.need(Attr.status)
    if (this.uid == user_id) return this.output.status('INVALID_USER');

    if (!['archived', 'active', 'locked'].includes(status)) return this.output.status('INVALID_STATUS0');

    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');

    let my_org = await this.user.organization();
    if (isEmpty(my_org)) return this.output.status('NO_ORG');

    if (my_org.id != org.id) return this.output.status('INVALID_ORG');

    let his_org = await this.yp.await_proc('my_organisation', user_id)
    if (isEmpty(his_org)) return this.output.status('NO_ORG');

    if (his_org.id != org.id) return this.output.status('INVALID_ORG');

    let my_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, this.uid);
    if (my_privilege.privilege < Remit.dom_admin) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    let his_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, user_id);
    if (isEmpty(his_privilege)) return this.output.status('INCORRECT_DOMAIN');

    if (my_privilege.privilege < his_privilege.privilege) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    let member = await this.yp.await_proc('show_member_detail', user_id, orgid);

    if (isEmpty(member)) return this.output.status('NO_MEMBER');

    if (status == 'locked') {
      if (!['active', 'archived'].includes(member.status)) {
        return this.output.status('INVALID_STATUS1');
      }
    }

    if (status == 'archived') {
      if (member.status != 'locked') {
        return this.output.status('INVALID_STATUS2');
      }
    }

    if (status == 'active') {
      if (member.status != 'locked') {
        return this.output.status('INVALID_STATUS3');
      }
    }

    res = await this.yp.await_proc('update_member_status', user_id, status)
    if (status == 'archived') {
      let users = [];
      await this.yp.await_proc('contact_assignment_update', user_id, stringify(users));
      await this.yp.await_proc('forward_proc', user_id, 'my_contact_sync', `'${user_id}'`)
    }
    let data = await this.yp.await_proc('show_member_detail', user_id, orgid);
    if (!isEmpty(data)) {
      res = data;
    }
    this.output.list(res);
  }


  /**
   * 
   */
  async member_loginlog() {
    let orgid //= this.input.need(Attr.orgid);
    let user_id = this.input.need(Attr.user_id);
    const page = this.input.use(Attr.page) || 1;
    let res = [];

    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');

    let my_org = await this.user.organization();
    if (isEmpty(my_org)) return this.output.status('NO_ORG');

    if (my_org.id != org.id) return this.output.status('INVALID_ORG');

    let his_org = await this.yp.await_proc('my_organisation', user_id)
    if (isEmpty(his_org)) return this.output.status('NO_ORG');

    if (his_org.id != org.id) return this.output.status('INVALID_ORG');


    let my_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, this.uid);
    if (my_privilege.privilege < Remit.dom_admin_view) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    let his_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, user_id);
    if (isEmpty(his_privilege)) return this.output.status('INCORRECT_DOMAIN');
    if (my_privilege.privilege < his_privilege.privilege) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    let data = await this.yp.await_proc('forward_proc', user_id, 'show_login_log', `${page}`)
    if (!isArray(data)) {
      data = [data];
    }
    for (let rec of data) {
      rec.metadata = this.parseJSON(rec.metadata)
      res.push(rec);
    }
    this.output.list(res);
  }

  /**
   * 
   */
  async member_authentification() {
    let orgid //= this.input.need(Attr.orgid);
    let user_id = this.input.need(Attr.user_id);
    let option = this.input.use(Attr.option) || '0';  // 'double' 

    let res = {};
    let profile = {};

    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');

    let my_org = await this.user.organization();
    if (isEmpty(my_org)) return this.output.status('NO_ORG');

    if (my_org.id != org.id) return this.output.status('INVALID_ORG');

    let his_org = await this.yp.await_proc('my_organisation', user_id)
    if (isEmpty(his_org)) return this.output.status('NO_ORG');

    if (his_org.id != org.id) return this.output.status('INVALID_ORG');

    let my_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, this.uid);
    if (my_privilege.privilege < Remit.dom_admin) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    let his_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, user_id);
    if (isEmpty(his_privilege)) return this.output.status('INCORRECT_DOMAIN');

    if (my_privilege.privilege < his_privilege.privilege) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    let phone = await this.yp.await_proc('show_member_detail', user_id, orgid);
    if (isEmpty(phone)) return this.output.status('NO_USER');
    if (isEmpty(phone.mobile) && (option == 'sms')) return this.output.status('NO_PHOME');

    profile.otp = option;
    res = await this.yp.await_proc('drumate_update_profile', user_id, profile);
    let recipients = await this.yp.await_proc('user_sockets', res.id);
    await RedisStore.sendData(this.payload(res), recipients);

    this.output.list(res);
  }


  /* Need to delete */
  async member_block() {
    let orgid //= this.input.need(Attr.orgid);
    let user_id = this.input.need(Attr.user_id);
    let res = {};
    let profile = {};

    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');

    let my_org = await this.user.organization();
    if (isEmpty(my_org)) return this.output.status('NO_ORG');

    if (my_org.id != org.id) return this.output.status('INVALID_ORG');

    let his_org = await this.yp.await_proc('my_organisation', user_id)
    if (isEmpty(his_org)) return this.output.status('NO_ORG');

    if (his_org.id != org.id) return this.output.status('INVALID_ORG');

    let my_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, this.uid);
    if (my_privilege.privilege < Remit.dom_admin) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    let his_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, user_id);
    if (isEmpty(his_privilege)) return this.output.status('INCORRECT_DOMAIN');

    if (my_privilege.privilege < his_privilege.privilege) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    profile.blocked = 'yes'
    res = await this.yp.await_proc('drumate_update_profile', user_id, profile);
    let recipients = await this.yp.await_proc('user_sockets', res.id);
    await RedisStore.sendData(this.payload(res), recipients);
    this.output.list(res);
  }

  /* Need to delete */
  async member_unblock() {
    let orgid //= this.input.need(Attr.orgid);
    let user_id = this.input.need(Attr.user_id);
    let res = {};
    let profile = {};

    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');

    let my_org = await this.user.organization();
    if (isEmpty(my_org)) return this.output.status('NO_ORG');

    if (my_org.id != org.id) return this.output.status('INVALID_ORG');

    let his_org = await this.yp.await_proc('my_organisation', user_id)
    if (isEmpty(his_org)) return this.output.status('NO_ORG');

    if (his_org.id != org.id) return this.output.status('INVALID_ORG');

    let my_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, this.uid);
    if (my_privilege.privilege < Remit.dom_admin) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    let his_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, user_id);
    if (isEmpty(his_privilege)) return this.output.status('INCORRECT_DOMAIN');

    if (my_privilege.privilege < his_privilege.privilege) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    profile.blocked = 'no'
    res = await this.yp.await_proc('drumate_update_profile', user_id, profile);
    let recipients = await this.yp.await_proc('user_sockets', res.id);
    await RedisStore.sendData(this.payload(res), recipients);
    this.output.list(res);
  }

  /**
   * 
   * @param {*} result 
   * @param {*} option 
   * @param {*} domain_name 
   * @param {*} this 
   * @returns 
   */
  async import_validate(result, option, domain_name) {
    let member = {}
    let importdata = {}
    importdata.members = []
    importdata.valid = true
    let skip;
    let valid;
    let status = [];
    let idx = 0;
    let chk
    for (var e of result) {
      skip = false;
      member = e;
      status = [];
      if (isEmpty(e.firstname)) {
        if (isEmpty(e.lastname)) {
          status.push("EMPTY_NAMES")
          skip = true;
        }
      }

      if (isEmpty(e.email)) {
        status.push("EMPTY_EMAIL")
        skip = true;
      }

      if (isEmpty(e.mobile)) {
        status.push("EMPTY_MOBLIE")
        skip = true;
      }

      if (isEmpty(e.areacode)) {
        status.push("EMPTY_AREACODE")
        skip = true;
      }

      if (!isEmpty(e.email)) {
        if (!Constants.EMAIL_CHECKER.test(e.email)) {
          status.push("INVALID_EMAIL_FORMAT")
          skip = true;
        }
      }

      if (!isEmpty(e.mobile)) {
        if (!Constants.PHONE_CHECKER.test(e.mobile)) {
          status.push("INVALID_PHONE_FORMAT")
          skip = true;
        }
      }
      if (isEmpty(e.ident)) {
        status.push("EMPTY_IDENT")
        skip = true;
      }
      if (!isEmpty(e.email)) {
        chk = await this.yp.await_proc('email_exists', e.email)
        if (!isEmpty(chk)) {
          status.push("EMAIL_NOT_AVAILABLE")
          skip = true;
        }
      }

      if (!isEmpty(e.ident)) {
        chk = await this.yp.await_proc('get_user_in_domain', e.ident, domain_name)
        if (chk.exists == 1) {
          status.push("IDENT_NOT_AVAILABLE")
          skip = true;
        }
      }
      for (var m of importdata.members) {
        if (m.ident == e.ident && (!isEmpty(e.ident))) {
          skip = true;
          status.push('IDENT_DUPLICATE (' + m.index + ')')
        }

        if (m.email == e.email && (!isEmpty(e.email))) {
          skip = true;
          status.push('EMAIL_DUPLICATE  (' + m.index + ')')
        }
      }
      member.error = skip;
      if (!isEmpty(status)) { member.errorstatus = status; }
      member.index = idx;
      importdata.valid = importdata.valid && (!skip)
      importdata.members.push(member)
      idx++;
    }
    return importdata
  }


  /**
   * 
   * @param {*} result 
   * @param {*} option 
   * @param {*} domain_name 
   * @param {*} this 
   * @param {*} orgid 
   * @returns 
   */
  async import_load(result, option, domain_name, orgid) {
    let importdata = {};
    let members = [];
    importdata.valid = true
    for (let member of result) {
      let user = await this.createMember(member);
      if (user.error) {
        member.errorstatus = user.error;
        members.push(member);
        continue;
      }

      members.push(member);
      await this.invite_link(member.email);
      let list = await this.yp.await_proc('member_list_all', user.id, orgid);
      if (!list) continue;
      if (!isArray(list)) {
        list = [list]
      }
      let users = [];
      for (let entity of list) {
        users.push(entity.drumate_id)
      }
      await this.yp.await_proc('contact_assignment_update', user.id, users);
    }
    importdata.members = members;
    return importdata
  }

  /**
   * 
   * @param {*} result 
   * @param {*} option 
   * @param {*} domain_name 
   * @param {*} file_id 
   * @param {*} this 
   * @param {*} orgid 
   * @returns 
   */
  async import_process(result, option, domain_name, file_id, orgid) {
    let res = {}

    let idx = 0;
    for (var e of result) {
      result[idx].firstname = e["First Name"]
      result[idx].lastname = e["Last Name"]
      result[idx].email = e["Mail"]
      result[idx].ident = e["Ident"].toLowerCase();
      result[idx].mobile = e["Phone Number"]
      result[idx].areacode = e["Area Code"]
      idx++;
    }

    res = await this.import_validate(result, option, domain_name)
    res.secret = file_id;
    if (option == 'load' && !res.valid) return this.output.status('INVAILD_DATA');

    if (option == 'load' && res.valid) {
      res = await this.import_load(res.members, option, domain_name, orgid)
    }
    if (option == 'load_valid') {
      res = await this.import_load(res.members, option, domain_name, orgid)
    }
    this.output.data(res)
  }

  /**
   * 
   * @returns 
   */
  async members_import() {
    let res = {}
    let uploaded_file_id = this.input.get(Attr.uploaded_id)
    let file_id = this.input.get(Attr.secret);

    if (isEmpty(file_id) && isEmpty(uploaded_file_id)) return this.output.status('NO_FILE');

    if (!isEmpty(file_id) && !isEmpty(uploaded_file_id)) return this.output.status('INVALID_INPUT');

    if (!isEmpty(file_id) && isEmpty(uploaded_file_id)) {
      option = 'load'
    }

    if (!isEmpty(uploaded_file_id)) {
      file_id = uploaded_file_id
    }


    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');

    let my_org = await this.user.organization();
    if (isEmpty(my_org)) return this.output.status('NO_ORG');

    if (my_org.id != org.id) return this.output.status('INVALID_ORG');

    let my_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, this.uid);
    if (my_privilege.privilege < Remit.dom_admin_memeber) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    let domain = await this.yp.await_proc('domain_exists', my_org.domain_id);

    try {
      let input = Path.resolve(process.env.DRUMEE_TMP_DIR, file_id);
      xlsxj({ input, output: null }, function (err, result) {
        if (err) {
          res = err;
          return this.output.status('XLTOJSON_ERR')
        }
        let count = 0;
        let idx = 0;
        let finalresult = []
        for (var e of result) {
          count = 0;
          if (isEmpty(e["First Name"])) { count++ }
          if (isEmpty(e["Last Name"])) { count++ }
          if (isEmpty(e["Mail"])) { count++ }
          if (isEmpty(e["Ident"])) { count++ }
          if (isEmpty(e["Phone Number"])) { count++ }
          if (isEmpty(e["Area Code"])) { count++ }
          idx++;
          if (count < 6) {
            finalresult.push(e)
          }
        }
        this.import_process(finalresult, option, domain.name, file_id, orgid)
      });
    } catch (e) {
      res = e;
      this.output.status('FILE_ERR')
    }
  }


  /* Need to delete */
  async members_import1() {
    let file_id = this.input.get(Attr.uploaded_id);
    let input = Path.resolve(process.env.DRUMEE_TMP_DIR, file_id);
    xlsxj({ input, output: null }, function (err, result) {
      if (err) {
        res = err;
        this.output.status('XLTOJSON_ERR')
      } else {
        this.output.data(result);
      }
    });

  }

  /**
   * 
   * @returns 
   */
  async send_password_link() {
    let orgid //= this.input.need(Attr.orgid);
    let users = this.input.need(Attr.users);
    let password = Crypto.randomBytes(20).toString('hex');
    if (!isArray(users)) {
      users = [users];
    }
    let res = {};

    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');


    let my_org = await this.user.organization();
    if (isEmpty(my_org)) return this.output.status('NO_ORG');
    if (my_org.id != org.id) return this.output.status('INVALID_ORG');


    let my_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, this.uid);
    if (my_privilege.privilege < Remit.dom_admin_security) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    res.isinvaliddrumate = 0
    for (let entity_id of users) {
      let drumate = await this.yp.await_proc('drumate_exists', entity_id);
      if (isEmpty(drumate)) {
        res.isinvaliddrumate = res.isinvaliddrumate + 1
      }
    }

    if (res.isinvaliddrumate > 0) return this.output.status('NOT_VALID_DRUMATE');

    res.isinvalidorg = 0
    for (let entity_id of users) {
      let drumate = await this.yp.await_proc('drumate_exists', entity_id);
      if (!isEmpty(drumate)) {
        let his_org = await this.yp.await_proc('my_organisation', drumate.id)
        if (isEmpty(his_org)) {
          res.isinvalidorg = res.isinvalidorg + 1
        }
      }
    }

    if (res.isinvalidorg > 0) return this.output.status('NOT_VALID_ORG');

    res.isinvalidorg = 0
    for (let entity_id of users) {
      let drumate = await this.yp.await_proc('drumate_exists', entity_id);
      if (!isEmpty(drumate)) {
        let his_org = await this.yp.await_proc('my_organisation', drumate.id)
        if (!isEmpty(his_org)) {
          if (his_org.id != org.id) {
            res.isinvalidorg = res.isinvalidorg + 1
          }
        }
      }
    }

    if (res.isinvalidorg > 0) return this.output.status('NOT_VALID_ORG');

    res = []
    for (let entity_id of users) {
      let member = await this.yp.await_proc('show_member_detail', entity_id, orgid);
      await this.yp.await_proc('set_password', entity_id, password);
      let email;
      if (member.connected == '1') {
        await this.password_link(member.email);
      } else {
        email = await this.invite_link(member.email);
      }

      let recipients = await this.yp.await_proc('user_sockets', entity_id);
      await RedisStore.sendData(this.payload(member), recipients);
      await this.yp.await_proc('socket_user_connections', entity_id);
      await this.yp.await_proc('session_logout_by_admin', entity_id);
      member.email = email;
      res.push(member)
    }

    this.output.list(res);
  }

  /**
   * 
   */
  async member_admin_remove() {

    let orgid //= this.input.need(Attr.orgid);
    let users = this.input.need(Attr.users);
    if (!isArray(users)) {
      users = [users];
    }

    let res = {};
    let result = [];

    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');

    let my_org = await this.user.organization();
    if (isEmpty(my_org)) return this.output.status('NO_ORG');
    if (my_org.id != org.id) return this.output.status('INVALID_ORG');

    let my_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, this.uid);
    if (my_privilege.privilege < Remit.dom_admin_memeber) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    res.isinvaliddrumate = 0
    for (let entity_id of users) {
      let drumate = await this.yp.await_proc('drumate_exists', entity_id);
      if (isEmpty(drumate)) {
        res.isinvaliddrumate = res.isinvaliddrumate + 1
      }
    }

    if (res.isinvaliddrumate > 0) return this.output.status('NOT_VALID_DRUMATE');
    res.isinvalidorg = 0
    for (let entity_id of users) {
      let drumate = await this.yp.await_proc('drumate_exists', entity_id);
      if (!isEmpty(drumate)) {
        let his_org = await this.yp.await_proc('my_organisation', drumate.id)
        if (isEmpty(his_org)) {
          res.isinvalidorg = res.isinvalidorg + 1
        }
      }
    }

    if (res.isinvalidorg > 0) return this.output.status('NOT_VALID_ORG');
    res.isinvalidorg = 0
    for (let entity_id of users) {
      let drumate = await this.yp.await_proc('drumate_exists', entity_id);
      if (!isEmpty(drumate)) {
        let his_org = await this.yp.await_proc('my_organisation', drumate.id)
        if (!isEmpty(his_org)) {
          if (his_org.id != org.id) {
            res.isinvalidorg = res.isinvalidorg + 1
          }
        }
      }
    }

    if (res.isinvalidorg > 0) return this.output.status('NOT_VALID_ORG');
    for (let entity_id of users) {
      let drumate = await this.yp.await_proc('drumate_exists', entity_id);
      if (!isEmpty(drumate)) {
        let his_org = await this.yp.await_proc('my_organisation', drumate.id)
        if (!isEmpty(his_org)) {
          if (his_org.id == org.id) {
            await this.yp.await_proc('domain_grant', his_org.domain_id, Remit.dom_member, drumate.id, 1);
            let member = await this.yp.await_proc('show_member_detail', drumate.id, orgid);
            result.push(member)
          }
        }
      }
    }
    this.output.data(result);
  }

  async member_admin_add() {
    let orgid //= this.input.need(Attr.orgid);
    let users = this.input.need(Attr.users);
    const privilege = this.input.need(Attr.privilege)
    if (!isArray(users)) {
      users = [users];
    }

    let res = {};
    let result = [];
    let profile = {};
    if (privilege > Remit.dom_admin) return this.output.status('INVALID_PRIVILEGE ');

    if (privilege < Remit.dom_admin_view) return this.output.status('INVALID_PRIVILEGE ');


    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');
    let my_org = await this.user.organization();
    if (isEmpty(my_org)) return this.output.status('NO_ORG');
    if (my_org.id != org.id) return this.output.status('INVALID_ORG');

    let my_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, this.uid);
    if (my_privilege.privilege < Remit.dom_admin_security) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    res.isinvaliddrumate = 0
    for (let entity_id of users) {
      let drumate = await this.yp.await_proc('drumate_exists', entity_id);
      if (isEmpty(drumate)) {
        res.isinvaliddrumate = res.isinvaliddrumate + 1
      }
    }

    if (res.isinvaliddrumate > 0) return this.output.status('NOT_VALID_DRUMATE');
    res.isinvalidorg = 0
    for (let entity_id of users) {
      let drumate = await this.yp.await_proc('drumate_exists', entity_id);
      if (!isEmpty(drumate)) {
        let his_org = await this.yp.await_proc('my_organisation', drumate.id)
        if (isEmpty(his_org)) {
          res.isinvalidorg = res.isinvalidorg + 1
        }
      }
    }

    if (res.isinvalidorg > 0) return this.output.status('NOT_VALID_ORG');
    res.isinvalidorg = 0
    for (let entity_id of users) {
      let drumate = await this.yp.await_proc('drumate_exists', entity_id);
      if (!isEmpty(drumate)) {
        let his_org = await this.yp.await_proc('my_organisation', drumate.id)
        if (!isEmpty(his_org)) {
          if (his_org.id != org.id) {
            res.isinvalidorg = res.isinvalidorg + 1
          }
        }
      }
    }

    if (res.isinvalidorg > 0) return this.output.status('NOT_VALID_ORG');
    res.isinvalidmobile = 0
    for (let entity_id of users) {
      let chk = await this.yp.await_proc('show_member_detail', entity_id, orgid);
      if (chk.mobile == '') {
        res.isinvalidmobile = res.isinvalidmobile + 1
      }
      if (isEmpty(chk.mobile)) {
        res.isinvalidmobile = res.isinvalidmobile + 1
      }
    }

    if (res.isinvalidmobile > 0) return this.output.status('EMPTY_MOBILE');
    for (let entity_id of users) {
      let drumate = await this.yp.await_proc('drumate_exists', entity_id);
      if (!isEmpty(drumate)) {
        let his_org = await this.yp.await_proc('my_organisation', drumate.id)
        if (!isEmpty(his_org)) {
          if (his_org.id == org.id) {
            await this.yp.await_proc('domain_grant', his_org.domain_id, privilege, drumate.id, 1);
            profile.otp = 'sms';
            await this.yp.await_proc('drumate_update_profile', drumate.id, profile);
            let member = await this.yp.await_proc('show_member_detail', drumate.id, orgid);
            result.push(member)
          }
        }
      }
    }
    this.output.data(result);
  }


  /* Need to delete */
  async member_admin_list() {
    let orgid //= this.input.need(Attr.orgid);
    const page = this.input.use(Attr.page) || 1;

    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    if (isEmpty(org)) return this.output.status('NO_ORG');
    orgid = org.id;

    res = await this.yp.await_proc('member_admin_list', orgid, page);
    this.output.data(res);

  }

  /**
   * 
   * @returns 
   */
  async member_list() {
    let role_id = this.input.use(Attr.role_id) || 0;
    let orgid //= this.input.need(Attr.orgid);
    const key = this.input.use(Attr.key);
    const page = this.input.use(Attr.page) || 1;
    const option = this.input.use(Attr.option) || 'member';

    let res = {};
    let result = [];

    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');
    res = await this.yp.await_proc('member_list', this.uid, role_id, orgid, key, option, page);
    if (!isArray(res)) {
      res = [res];
    }
    for (let row of res) {
      if (!isEmpty(row.address)) {
        row.address = this.parseJSON(row.address);
      }
      result.push(row)
    }
    this.output.list(result);
  }

  /**
   * 
   * @returns 
   */
  async member_show() {
    let orgid //= this.input.need(Attr.orgid);
    let user_id = this.input.need(Attr.user_id);
    let res = {};

    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');

    let data = await this.yp.await_proc('show_member_detail', user_id, orgid);
    if (!isEmpty(data)) {
      res = data;
    }
    data = await this.yp.await_proc('org_user_role', user_id, orgid);
    data = toArray(data);
    if (data) {
      res.role = data;
    }
    if (!isEmpty(res.address)) res.address = this.parseJSON(res.address);
    this.output.data(res);
  }

  /***
* 
*/
  async createMember(opt) {
    let {
      domain, firstname, lastname, email, ident, areacode
    } = opt;
    email = email.trim();
    if (isEmpty(email)) {
      return { error: "EMAIL_NOT_AVAILABLE" }
    }
    let entry = await this.yp.await_proc('email_exists', email)
    if (!isEmpty(entry)) {
      return { error: "EMAIL_NOT_AVAILABLE" }
    }

    let username = ident || email.split('@')[0];

    if (!domain) {
      domain = main_domain;
    }
    let { exists } = await this.yp.await_proc('get_user_in_domain', username, domain)
    if (exists == 1) {
      username = uniqueId(username);
      ({ exists } = await this.yp.await_proc('get_user_in_domain', username, domain));
      if (exists == 1) {
        return { error: "IDENT_NOT_AVAILABLE" }
      }
    }

    let password = uniqueId();
    firstname = firstname.trim();
    lastname = lastname.trim();
    if (!/^\+/.test(areacode)) {
      areacode = `+${areacode}`;
    }

    const profile = {
      email,
      firstname,
      lastname,
      lang: this.input.ua_language(),
      privilege: Remit.dom_member,
      domain,
      username,
      sharebox: uniqueId(),
      otp: 0,
      areacode,
      category: "regular",
      profile_type: "standard",
    };
    this.set({ email });
    let rows = await this.yp.await_proc("drumate_create", password, profile);
    let drumate = null;
    for (let r of rows) {
      if (r && r.failed) {
        return { error: r }
      }
      if (r.drumate) {
        drumate = r.drumate;
      }
    }

    drumate.firstname = firstname;
    drumate.lastname = lastname;
    let quota = Cache.getSysConf('quota') || {};
    if (isString(quota)) {
      try { quota = JSON.parse(quota) } catch (e) { quota = {} };
    }
    quota.watermark = global.myQuota.watermark || 'Infinity';

    await this.yp.await_proc("drumate_update_profile", drumate.id, { quota });
    await this.set_wallpaper(drumate.id);
    return drumate;
  }

  /**
   * 
   * @param {*} uid 
   * @param {*} option 
   */
  async set_wallpaper(uid) {
    let entity = await this.yp.await_proc('entity_touch', uid);
    let old_settings;
    if (isEmpty(entity) || isEmpty(entity.settings)) {
      old_settings = {};
    } else {
      old_settings = this.parseJSON(entity.settings);
    }
    let settings = {};

    settings.wallpaper = Cache.getSysConf('wallpaper');
    if (!settings.wallpaper) return;
    const merged_settings = { ...old_settings, ...settings };
    const settings_str = stringify(merged_settings);
    this.yp.call_proc('drumate_update_settings', uid, settings_str);
  }

  /**
   * 
   * @param {*} email 
   * @returns 
   */
  async invite_link(email) {
    const token = this.randomString();
    const username = this.user.get(Attr.fullname);
    await this.yp.await_proc('token_generate_next', email, email, token, Constants.FORGOT_PASSWORD, '');
    let user = await this.yp.await_proc('get_visitor', email);
    const ulang = this.input.ua_language();
    //const pathname = this.input.use(Attr.location).pathname.replace(/service.*$/, '');
    let host = (await this.user.organization()).link;// || process.env.domain_name;
    const link = `${this.input.homepath(host)}#/welcome/reset/${user.id}/${token}/reason=new-account`;
    const subject = `${Cache.message('_admin_network_subject', ulang)}`;
    const msg = new Messenger({
      template: "butler/admin-invitation",
      subject: subject,
      recipient: email,
      lex: Cache.lex(ulang),
      data: {
        sender: username,
        link: link,
        recipient: user.fullname
      },
      handler: this.exception.email
    });
    let body = msg.send();
    if (isString(body)) {
      return {
        subject,
        email,
        body,
        link
      }
    }
  }


  /**
   * 
   */
  async setPassword() {
    let id = this.input.need(Attr.id);
    let password = this.input.need(Attr.password);
    await this.yp.await_proc('set_password', id, password);
    this.output.data({});
  }


  /**
   * 
   * @param {*} email 
   */
  async password_link(email) {
    const token = this.randomString();
    await this.yp.await_proc('token_generate_next', email, email, token, Constants.FORGOT_PASSWORD, '');
    let user = await this.yp.await_proc('get_visitor', email);
    const ulang = this.input.ua_language();
    //const pathname = this.input.use(Attr.location).pathname.replace(/service.*$/, '');
    const link = `${this.input.homepath()}#/welcome/reset/${user.id}/${token}`;
    const subject = Cache.message("_admin_password_reset_link", ulang);
    const msg = new Messenger({
      template: "butler/password-change",
      subject,
      recipient: email,
      lex: Cache.lex(ulang),
      data: {
        icon: this.hub.get(Attr.icon),
        recipient: user.fullname,
        link,
        home: process.env.domain_name,
      },
      handler: this.exception.email
    });
    let body = msg.send();
    if (isString(body)) {
      return {
        subject,
        email,
        body,
        link
      }
    }
  }



  /**
   * 
   * @param {*} email 
   */
  async email_change_link(email) {
    const token = this.randomString();
    await this.yp.await_proc('token_generate_next', email, email, token, Constants.FORGOT_PASSWORD, '');
    let user = await this.yp.await_proc('get_visitor', email);
    const ulang = this.input.ua_language();
    //const pathname = this.input.use(Attr.location).pathname.replace(/service.*$/, '');
    const link = `${this.input.homepath()}#/welcome/reset/${user.id}/${token}`;
    const subject = Cache.message("_admin_email_reset_link", ulang);
    const msg = new Messenger({
      template: "butler/email-change",
      subject,
      recipient: email,
      lex: Cache.lex(ulang),
      data: {
        icon: this.hub.get(Attr.icon),
        recipient: user.fullname,
        link,
        home: process.env.domain_name,
      },
      handler: this.exception.email
    });
    let body = msg.send();
    if (isString(body)) {
      return {
        subject,
        email,
        body,
        link
      }
    }
  }


  /**
   * 
   * @param {*} profile 
   */
  checkProfileSanity(profile) {
    let mobile = this.input.use(Attr.mobile)
    let firstname = this.input.need(Attr.firstname);
    let lastname = this.input.need(Attr.lastname);
    let address = this.input.use(Attr.address)
    let areacode = this.input.use(Attr.areacode)
    let email = this.input.need(Attr.email)
    let otp = this.input.get('otp') || 0;
    if (![1, 0, '1', '0'].includes(otp)) {
      otp = 0;
    }

    profile.email_verified = 'no';
    profile.otp = otp;
    profile.connected = '0';
    profile.sharebox = Uniqid();

    if (!isEmpty(mobile)) {
      profile.mobile_verified = 'no'
      profile.mobile = mobile
    }

    if (!isEmpty(firstname)) { profile.firstname = firstname }
    if (!isEmpty(lastname)) { profile.lastname = lastname }
    if (!isEmpty(address)) { profile.address = address }
    if (!isEmpty(email)) { profile.email = email }

    if (isEmpty(profile.mobile) && (otp == 'sms')) {
      this.output.status('MOBILE_EMPTY');
      return false;
    }

    if (!isEmpty(mobile)) {
      profile.mobile = profile.mobile.trim()
    }

    if ((profile.mobile == "") && (otp == 'sms')) {
      this.output.status('MOBILE_EMPTY');
      return false;
    }

    if (!isEmpty(profile.areacode)) {
      profile.areacode = areacode.trim()
    }

    if (isEmpty(profile.areacode) && (otp == 'sms')) {
      this.output.status('AREACODE_EMPTY');
      return false;
    }
    if ((profile.areacode == "") && (otp == 'sms')) {
      this.output.status('AREACODE_EMPTY');
      return false;
    }
    return true;

  }

  /**
   * 
   * @returns 
   */
  async member_add() {
    let orgid //= this.input.need(Attr.orgid);
    let email = this.input.need(Attr.email)
    let ident = this.input.use(Attr.ident);
    if (!isEmpty(ident)) {
      ident = ident.toLowerCase().trim();
    }
    let users = this.input.need(Attr.users) || [];
    let role = this.input.use(Attr.role) || this.input.use(Attr.list) || [];
    let res = {};
    let profile = {};
    let list = []
    if (!this.checkProfileSanity(profile)) {
      return
    }

    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) {
      return this.output.status('NO_ORG')
    };

    let my_org = await this.user.organization();
    if (isEmpty(my_org)) {
      return this.output.status('NO_ORG')
    };

    if (my_org.id != org.id) {
      return this.output.status('INVALID_ORG');
    }

    let my_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, this.uid);
    if (my_privilege.privilege < Remit.dom_admin_memeber) {
      return this.output.status('NOT_ENOUGH_PRIVILEGE')
    };

    let domain = await this.yp.await_proc('domain_exists', my_org.domain_id);
    profile.domain = domain.name;

    if (!isEmpty(role)) {
      for (let id of role) {
        let data = await this.yp.await_proc('role_exists', id, orgid);
        if (isEmpty(data)) {
          return this.output.status('ROLE_NOT_EXISTS');
        }
      }
    }

    let isinvaliddrumate = 0;
    let isinvalidorg = 0;
    for (let entity_id of users) {
      let drumate = await this.yp.await_proc('drumate_exists', entity_id);

      if (isEmpty(drumate)) {
        isinvaliddrumate = isinvaliddrumate + 1
      }
      if (!isEmpty(drumate)) {
        let his_org = await this.yp.await_proc('my_organisation', drumate.id)
        if (!isEmpty(his_org)) {
          if (his_org.id != org.id) {
            isinvalidorg = isinvalidorg + 1
          }
        }
      }
    }

    if (isinvaliddrumate > 0) {
      return this.output.status('NOT_VALID_DRUMATE')
    };

    if (isinvalidorg > 0) {
      return this.output.status('NOT_VALID_ORG');
    }

    let user = await this.createMember(profile);
    this.debug("AAA:1515", { user, profile })
    if (!user || user.error) {
      return this.output.status(user.error || "INTERNAL_ERROR")
    }

    let message = await this.invite_link(email);
    if (isEmpty(users)) {

      list = await this.yp.await_proc('member_list_all', user.id, orgid);
      if (!isArray(list)) {
        list = [list]
      }
      for (let entity of list) { users.push(entity.drumate_id) }
    }
    await this.yp.await_proc('contact_assignment_update', user.id, stringify(users));
    await this.yp.await_proc('ticket_grant_permission', user.id);

    let data = await this.yp.await_proc('show_member_detail', user.id, orgid);
    if (!isEmpty(data)) {
      res = data;
    }
    data = await this.yp.await_proc('org_user_role', user.id, orgid);
    data = toArray(data);
    if (data.length) {
      res.role = data;
    }
    if (message) res.email = message;
    if (!isEmpty(res.address)) res.address = this.parseJSON(res.address);
    this.output.data(res);
  }



  /**
   * 
   */
  async member_update() {
    let orgid //= this.input.need(Attr.orgid);
    let user_id = this.input.need(Attr.user_id);
    let firstname = this.input.need(Attr.firstname);
    let lastname = this.input.need(Attr.lastname);
    let address = this.input.use(Attr.address)
    let email = this.input.need(Attr.email)
    let mobile = this.input.use(Attr.mobile)
    let areacode = this.input.use(Attr.areacode)
    let ident = this.input.need(Attr.ident);
    ident = ident.toLowerCase();
    let users = [];
    let role = this.input.use(Attr.role) || this.input.use(Attr.list) || [];
    let option = this.input.need(Attr.option) || '0';
    this.debug("ZZZ:1999*********************************");
    let otp = this.input.get('otp') || 0;
    if (![1, 0, '1', '0'].includes(otp)) {
      otp = 0;
    }

    let res = {};
    let chk = {};
    let profile = {};
    let notify = 0;
    let email_change = 0

    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');


    let my_org = await this.user.organization();
    if (isEmpty(my_org)) return this.output.status('NO_ORG');
    if (my_org.id != org.id) return this.output.status('INVALID_ORG');

    let his_org = await this.yp.await_proc('my_organisation', user_id)
    if (isEmpty(his_org)) return this.output.status('NO_ORG');
    if (his_org.id != org.id) return this.output.status('INVALID_ORG');

    let my_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, this.uid);
    if (my_privilege.privilege < Remit.dom_admin_memeber) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    let drumate = await this.yp.await_proc('drumate_exists', user_id);

    if (isEmpty(drumate)) return this.output.status('DRUMATE_NOT_EXISTS');

    let domain = await this.yp.await_proc('domain_exists', my_org.domain_id);
    if (drumate.ident != ident) {
      chk = await this.yp.await_proc('get_user_in_domain', ident, domain.name)
      if (chk.exists == 1) return this.output.status('IDENT_NOT_AVAILABLE');
    }

    if (drumate.email != email) {
      chk = await this.yp.await_proc('email_exists', email)
      if (!isEmpty(chk)) return this.output.status('EMAIL_NOT_AVAILABLE');
    }

    let his_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, user_id);
    if (isEmpty(his_privilege)) return this.output.status('INCORRECT_DOMAIN');

    if (my_privilege.privilege < his_privilege.privilege) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    if (!isEmpty(role)) {
      for (let id of role) {
        let data = await this.yp.await_proc('role_exists', id, orgid);
        if (isEmpty(data)) return this.output.status('ROLE_NOT_EXISTS');
      }
    }

    let member = await this.yp.await_proc('show_member_detail', user_id, orgid);

    if (isEmpty(member)) return this.output.status('NO_MEMBER');
    if (isEmpty(mobile) && otp) return this.output.status('MOBILE_EMPTY');
    if (isEmpty(areacode) && otp) return this.output.status('AREACODE_EMPTY');
    if (!email || !email.isEmail()) return this.output.status("INVALID_EMAIL_FORMAT")
    if (!isEmpty(mobile)) {
      if (!mobile || !mobile.phoneNumber()) {
        return this.output.status('INVALID_PHONE_FORMAT');
      }
    }

    if (!isEmpty(mobile) && !isEmpty(member.mobile) && (mobile != '')) {
      if (member.mobile != mobile) {
        profile.mobile_verified = 'no'
        if (otp) { notify = 1; }
      }
    }

    if (!isEmpty(areacode) && !isEmpty(member.areacode) && (areacode != '')) {
      if (member.areacode != areacode) {
        profile.mobile_verified = 'no'
        if (otp) { notify = 1; }
      }
    }

    if (!isEmpty(email) && !isEmpty(member.email) && (email != '')) {
      if (member.email != email) {
        profile.email_verified = 'no'
        notify = 1;
        email_change = 1;
      }
    }

    let contacts = await this.yp.await_proc('contact_assignment_get', user_id);
    if (!isEmpty(contacts)) {
      if (!isArray(contacts)) {
        contacts = [contacts]
      }
      for (let contact of contacts) {
        users.push(contact.uid)
      }
    }

    profile.firstname = firstname || '';
    profile.lastname = lastname || '';
    profile.address = address || '';
    profile.email = email || '';
    profile.mobile = mobile || '';
    profile.areacode = areacode || '';

    if (!isEmpty(ident)) {
      profile.ident = ident
      profile.username = ident
    }
    profile.otp = otp;

    if (!isEmpty(role)) {
      await this.yp.await_proc('role_map', user_id, stringify(role), orgid);
    }
    if (drumate.ident != ident) {
      await this.yp.await_proc('drumate_change_username', user_id, ident);
    }
    await this.yp.call_proc('drumate_update_profile', user_id, stringify(profile));
    await this.yp.call_proc('contact_sync_update', user_id);
    await this.yp.await_proc('contact_assignment_update', user_id, stringify(users));

    let need_otp = 1;
    if (isEmpty(mobile) || /(^0+$)|^( *)$/.test(mobile)) {
      await this.yp.call_proc('drumate_remove_profile', user_id, 'mobile');
      need_otp = 0;
    }

    if (isEmpty(areacode) || /(^0+$)|^( *)$/.test(areacode)) {
      await this.yp.call_proc('drumate_remove_profile', user_id, 'areacode');
      need_otp = 0;
    }

    if (need_otp == 0) {
      await this.yp.call_proc('drumate_remove_profile', user_id, 'otp');
    }

    let data = await this.yp.await_proc('show_member_detail', user_id, orgid);
    let connected = data.connected;
    if (!isEmpty(data)) {
      res = data;
    }
    data = await this.yp.await_proc('org_user_role', user_id, orgid);
    data = toArray(data);
    if (data) {
      res.role = data;
    }
    let message;
    if (notify == 1) {
      let recipients = await this.yp.await_proc('user_sockets', user_id);
      await RedisStore.sendData(this.payload(res), recipients);
      if (connected == '1') {
        if (email_change == 1) {
          message = await this.email_change_link(email);
        } else {
          message = await this.password_link(email);
        }
      } else {
        message = await this.invite_link(email);
      }
      await this.yp.await_proc('socket_user_connections', user_id)
      await this.yp.await_proc('session_logout_by_admin', user_id)
    }
    if (message) res.email = message;
    if (!isEmpty(res.address)) {
      res.address = this.parseJSON(res.address);
    }
    this.output.data(res);;
  }

  /**
   * 
   */
  async member_delete() {
    let orgid //= this.input.need(Attr.orgid);
    let user_id = this.input.need(Attr.user_id);

    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');

    let member = await this.yp.await_proc('show_member_detail', user_id, orgid);

    if (isEmpty(member)) return this.output.status('NO_MEMBER');

    if ('archived' != member.status) return this.output.status('INVALID_STATUS');


    if (member.is_able_delete != 'yes') return this.output.status('INVALID_TIME');


    let my_org = await this.user.organization();
    if (isEmpty(my_org)) return this.output.status('NO_ORG');

    if (my_org.id != org.id) return this.output.status('INVALID_ORG');

    let his_org = await this.yp.await_proc('my_organisation', user_id)
    if (isEmpty(his_org)) return this.output.status('NO_ORG');

    if (his_org.id != org.id) return this.output.status('INVALID_ORG');

    let my_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, this.uid);
    if (my_privilege.privilege < Remit.dom_admin) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    let his_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, user_id);
    if (isEmpty(his_privilege)) return this.output.status('INCORRECT_DOMAIN');

    if (my_privilege.privilege < his_privilege.privilege) return this.output.status('NOT_ENOUGH_PRIVILEGE');
    let hubs = await this.yp.await_proc('forward_proc', user_id, 'show_hubs', '')
    hubs = toArray(hubs) || [];

    for (let hub of hubs) {
      await this.yp.await_proc('forward_proc', user_id, 'leave_hub', `'${hub.id}'`)
      if (hub.owner_id == user_id) {
        let huber = await this.yp.await_proc('forward_proc', hub.id, 'hub_get_members_by_type', `'${this.uid}','owner',1`)
        if (isEmpty(huber)) {
          huber = await this.yp.await_proc('forward_proc', hub.id, 'hub_get_members_by_type', `'${this.uid}','admin',1`)
        }
        if (isEmpty(huber)) {
          huber = await this.yp.await_proc('forward_proc', hub.id, 'hub_get_members_by_type', `'${this.uid}','all',1`)
        }
        if (!isEmpty(huber)) {
          huber = toArray(huber) || [];
          await this.yp.await_proc('forward_proc', hub.id, 'permission_grant', `'*','${huber[0].id}',0,63,'system',0`)
        }
        else {
          await this.yp.await_proc(`entity_delete`, hub.id);
          remove_dir(hub.home_dir)
        }
      }
    }
    let user = await this.yp.await_proc(`drumate_delete`, user_id);
    remove_dir(user.home_dir);
    this.output.data(user);
  }


  async member_disconnect() {
    let orgid //= this.input.need(Attr.orgid);
    let user_id = this.input.need(Attr.user_id);
    let res = {};
    let chk = {};
    let profile = {};


    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');

    let member = await this.yp.await_proc('show_member_detail', user_id, orgid);

    if (isEmpty(member)) return this.output.status('NO_MEMBER');

    if ('1' == member.connected) return this.output.status('INVALID_STATUS');

    let my_org = await this.user.organization();
    if (isEmpty(my_org)) return this.output.status('NO_ORG');
    if (my_org.id != org.id) return this.output.status('INVALID_ORG');

    let his_org = await this.yp.await_proc('my_organisation', user_id)
    if (isEmpty(his_org)) return this.output.status('NO_ORG');
    if (his_org.id != org.id) return this.output.status('INVALID_ORG');

    let my_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, this.uid);
    if (my_privilege.privilege < Remit.dom_admin) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    let his_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, user_id);
    if (isEmpty(his_privilege)) return this.output.status('INCORRECT_DOMAIN');

    if (my_privilege.privilege < his_privilege.privilege) return this.output.status('NOT_ENOUGH_PRIVILEGE');
    let hubs = await this.yp.await_proc('forward_proc', user_id, 'show_hubs', '')
    hubs = toArray(hubs) || [];

    for (let hub of hubs) {
      await this.yp.await_proc('forward_proc', user_id, 'leave_hub', `'${hub.id}'`)
      if (hub.owner_id == user_id) {
        let huber = await this.yp.await_proc('forward_proc', hub.id, 'hub_get_members_by_type', `'${this.uid}','owner',1`)
        if (isEmpty(huber)) {
          huber = await this.yp.await_proc('forward_proc', hub.id, 'hub_get_members_by_type', `'${this.uid}','admin',1`)
        }
        if (isEmpty(huber)) {
          huber = await this.yp.await_proc('forward_proc', hub.id, 'hub_get_members_by_type', `'${this.uid}','all',1`)
        }
        if (!isEmpty(huber)) {
          huber = toArray(huber) || [];
          await this.yp.await_proc('forward_proc', hub.id, 'permission_grant', `'*','${huber[0].id}',0,63,'system',0`)
        }
        else {
          await this.yp.await_proc(`entity_delete`, hub.id);
          remove_dir(hub.home_dir)
        }
      }
    }
    let user = await this.yp.await_proc(`drumate_vanish`, user_id);
    remove_dir(user.home_dir);
    this.output.data(user);
  }


  /**
   * 
   */
  async role_assigned() {
    let user_id = this.input.need(Attr.user_id);
    let orgid //= this.input.need(Attr.orgid);

    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');

    let tag = await this.yp.await_proc('role_assigned', user_id, orgid)
    this.output.list(tag);
  }

  /**
   * 
   * @returns 
   */
  async role_assign() {
    let user_id = this.input.need(Attr.user_id);
    let orgid //= this.input.need(Attr.orgid);
    let role = this.input.need(Attr.role) || this.input.use(Attr.list) || [];
    let res = {};
    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');

    let my_org = await this.user.organization();
    if (isEmpty(my_org)) return this.output.status('NO_ORG');

    if (my_org.id != org.id) return this.output.status('INVALID_ORG');


    for (let id of role) {
      let data = await this.yp.await_proc('role_exists', id, orgid);
      if (isEmpty(data)) {
        return this.output.status('ROLE_NOT_EXISTS');
      }
    }
    await this.yp.await_proc('role_map', user_id, stringify(role), orgid);
    res = await this.yp.await_proc('role_assigned', user_id, orgid)
    this.output.list(res);
  }

  /**
   * 
   */
  async role_delete() {
    let role_id = this.input.need(Attr.role_id);
    let orgid //= this.input.need(Attr.orgid);
    let res = {};

    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');

    let my_privilege = await this.yp.await_proc('domain_privilege', org.domain_id, this.uid);
    if (my_privilege.privilege < Remit.dom_admin_memeber) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    let data = await this.yp.await_proc('role_exists', role_id, orgid);
    if (isEmpty(data)) return this.output.status('ROLE_NOT_EXISTS');
    res = this.yp.await_proc('role_delete', role_id, orgid);
    this.output.data(res);
  }


  /* List the role for a domain */
  async role_show() {
    let orgid //= this.input.need(Attr.orgid);
    const page = this.input.use(Attr.page) || 1;
    let res = {};

    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');

    let my_privilege = await this.yp.await_proc('domain_privilege', org.domain_id, this.uid);
    if (my_privilege.privilege < Remit.dom_admin_view) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    res = this.yp.await_proc('role_get', orgid, page);
    this.output.list(res);
  }


  /**
   * 
   */
  role_reposition() {
    const list = this.input.use(Attr.content);
    this.db.call_proc('role_reposition', stringify(list), this.output.list);
  }


  /* adding a role to a domain */
  async role_rename() {
    let name = this.input.need(Attr.name);
    let orgid //= this.input.need(Attr.orgid);
    let role_id = this.input.need(Attr.role_id);

    let res = {};

    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) {
      return this.output.status('NO_ORG');
    }

    let my_privilege = await this.yp.await_proc('domain_privilege', org.domain_id, this.uid);
    if (my_privilege.privilege < Remit.dom_admin_memeber) {
      return this.output.status('NOT_ENOUGH_PRIVILEGE');
    }

    let data = await this.yp.await_proc('role_exists', role_id, orgid);
    if (isEmpty(data)) {
      return this.output.status('ROLE_NOT_EXISTS');
    }
    if (data.name != name) {
      res = this.yp.await_proc('role_rename', role_id, orgid, name);
    } else {
      res = data
    }

    this.output.data(res);

  }



  /* adding a role to a domain */
  async role_add() {
    let name = this.input.need(Attr.name);
    let orgid //= this.input.need(Attr.orgid);

    let res = {};

    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) {
      return this.output.status('NO_ORG');
    }

    let my_privilege = await this.yp.await_proc('domain_privilege', org.domain_id, this.uid);
    if (my_privilege.privilege < Remit.dom_admin_memeber) {
      return this.output.status('NOT_ENOUGH_PRIVILEGE');
    }
    res = this.yp.await_proc('role_add', name, orgid);
    this.output.data(res);
  }


  /**
   * 
   */
  async my_privilege() {
    let res = {};
    res.privilege = 0
    let chk = await this.yp.await_proc('my_subscription', this.uid)
    if (!isEmpty(chk)) {
      res.privilege = Remit.dom_owner
    }
    else {
      // chk = await this.yp.await_proc('my_organisation', this.uid)
      chk = await this.user.organization();
      if (!isEmpty(chk)) {
        res.privilege = chk.privilege
      }
    }
    this.output.data(res);
  }

  /**
   * 
   */
  async my_subscription() {
    let res = await this.yp.await_proc('my_subscription', this.uid)
    this.output.data(res);
  }


  /**
   * 
   */
  async my_organisation() {
    let data = await this.user.organization();
    this.output.data(data);
  }

  /**
   * 
   */
  async organisation_add() {
    let name = this.input.need(Attr.name);
    let ident = this.input.need(Attr.ident);
    ident = ident.toLowerCase();
    let recds = {};
    let org;
    if (!isEmpty(name)) { recds.name = name }
    if (!isEmpty(ident)) { recds.ident = ident }

    let chk = await this.yp.await_proc('my_subscription', this.uid)
    if (isEmpty(chk)) return this.output.status('INVALID_SUBSCRIPTION');

    // chk = await this.yp.await_proc('my_organisation', this.uid)
    chk = await this.user.organization();
    if (!isEmpty(chk)) return this.output.status('ORGANISATION_ALREADY_EXITS');


    chk = await this.yp.await_proc('ident_exists', ident)
    if (!isEmpty(chk)) return this.output.status('IDENT_NOT_AVAILABLE');

    let domain = await this.yp.await_proc('domain_create', ident);
    await this.yp.await_proc('domain_grant', domain.id, Remit.dom_owner, this.uid, 1);
    recds.domain_id = domain.id;
    recds.owner_id = this.id;
    let link = `https://${domain.name}`
    recds.link = link
    org = await this.yp.await_proc('organisation_add', this.uid, name, link, ident, domain.id, stringify(recds));
    this.output.data(org);
  }


  /**
   * 
   * @returns 
   */
  async organisation_update() {
    let name = this.input.need(Attr.name);
    let orgid //= this.input.need(Attr.orgid);

    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');

    // let my_org = await this.yp.await_proc('my_organisation', this.uid)
    let my_org = await this.user.organization();
    if (isEmpty(my_org)) return this.output.status('NO_ORG_TO_UPDATE');
    if (my_org.id != org.id) return this.output.status('INVALID_ORG');

    let my_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, this.uid);
    if (my_privilege.privilege < Remit.dom_admin) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    let domain = await this.yp.await_proc('domain_update', org.ident, org.domain_id);
    let link = domain.name.replace(/^http.*:\/\//, '');// `https://${domain.name}`;

    org = await this.yp.await_proc('organisation_update', this.uid, orgid, name, link, org.ident);
    this.output.data(org);
  }

  /**
   * 
   * @returns 
   */
  async organisation_update_password_level() {
    let option = this.input.need(Attr.option);
    let orgid //= this.input.need(Attr.orgid);
    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');

    // let my_org = await this.yp.await_proc('my_organisation', this.uid)
    let my_org = await this.user.organization();
    if (isEmpty(my_org)) return this.output.status('NO_ORG_TO_UPDATE');

    if (my_org.id != org.id) return this.output.status('INVALID_ORG');

    let my_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, this.uid);
    if (my_privilege.privilege < Remit.dom_admin_security) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    org = await this.yp.await_proc('organisation_update_password_level', this.uid, orgid, option);
    this.output.data(org);
  }

  /**
   * 
   * @returns 
   */
  async organisation_update_double_auth() {
    let option = this.input.need(Attr.option);
    let orgid //= this.input.need(Attr.orgid);
    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');

    let my_org = await this.user.organization();
    if (isEmpty(my_org)) return this.output.status('NO_ORG_TO_UPDATE');

    if (my_org.id != org.id) return this.output.status('INVALID_ORG');

    let my_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, this.uid);
    if (my_privilege.privilege < Remit.dom_admin_security) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    org = await this.yp.await_proc('organisation_update_double_auth', this.uid, orgid, option);
    this.output.data(org);
  }


  /**
   * 
   * @returns 
   */
  async organisation_update_dir_visiblity() {
    let option = this.input.need(Attr.option);
    let orgid //= this.input.need(Attr.orgid);
    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');

    let my_org = await this.user.organization();
    if (isEmpty(my_org)) return this.output.status('NO_ORG_TO_UPDATE');

    if (my_org.id != org.id) return this.output.status('INVALID_ORG');

    let my_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, this.uid);
    if (my_privilege.privilege < Remit.dom_admin_security) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    org = await this.yp.await_proc('organisation_update_dir_visiblity', this.uid, orgid, option);
    this.output.data(org);
  }


  /**
   * 
   * @returns 
   */
  async organisation_update_dir_info() {
    let option = this.input.need(Attr.option);
    let orgid //= this.input.need(Attr.orgid);

    let org = await this.yp.await_proc('organisation_get', this.user.domain_id())
    orgid = org.id;
    if (isEmpty(org)) return this.output.status('NO_ORG');

    let my_org = await this.user.organization();
    if (isEmpty(my_org)) return this.output.status('NO_ORG_TO_UPDATE');

    if (my_org.id != org.id) return this.output.status('INVALID_ORG');

    let my_privilege = await this.yp.await_proc('domain_privilege', my_org.domain_id, this.uid);
    if (my_privilege.privilege < Remit.dom_admin_security) return this.output.status('NOT_ENOUGH_PRIVILEGE');

    org = await this.yp.await_proc('organisation_update_dir_info', this.uid, orgid, option);
    this.output.data(org);
  }


}


module.exports = __private_adminpanel;
