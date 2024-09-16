// ================================  *
//   Copyright Xialia.com  2013-2017 *
//   FILE  : src/service/private/hub
//   TYPE  : module
// ================================  *

const {
  isEmpty, filter, isArray, difference, map
} = require("lodash");
const {
  utils, RedisStore, Cache, Constants, Attr, Privilege, sysEnv
} = require("@drumee/server-essentials");
const {
  INTERNAL_ERROR,
  PERMISSION_DENIED,
  INVALID_EMAIL_FORMAT,
  EMAIL_NOT_FOUND,
  ID_NOT_FOUND,
} = Constants;
const { resolve } = require("path");
const { MfsTools } = require("@drumee/server-core");
const { remove_dir } = MfsTools;
const { toArray } = utils;
const { stringify } = JSON;
const { server_location } = sysEnv();

const Hub = require("../hub");
class __private_hub extends Hub {
  constructor(...args) {
    super(...args);
    this.get_members_by_type = this.get_members_by_type.bind(this);
    this.change_status = this.change_status.bind(this);
    this.change_history = this.change_history.bind(this);
    this.update_name = this.update_name.bind(this);
    this.update_title = this.update_title.bind(this);
    this.update_settings = this.update_settings.bind(this);
    this.update_favicon = this.update_favicon.bind(this);
    this.get_statistics = this.get_statistics.bind(this);
    this.update_ident = this.update_ident.bind(this);
    this.update_visibility = this.update_visibility.bind(this);
    this.get_contributors = this.get_contributors.bind(this);
    this.show_contributors = this.show_contributors.bind(this);
    this.get_settings = this.get_settings.bind(this);
    this.show_privilege = this.show_privilege.bind(this);
    this.add_contributors = this.add_contributors.bind(this);
    this.delete_contributor = this.delete_contributor.bind(this);
    this.get_space_usage = this.get_space_usage.bind(this);
    this.set_privilege = this.set_privilege.bind(this);
    this.set_members_privilege = this.set_members_privilege.bind(this);
    this.change_owner = this.change_owner.bind(this);
    this.lookup_hubers = this.lookup_hubers.bind(this);
    this.add_font_link = this.add_font_link.bind(this);
    this.get_pr_node_attr = this.get_pr_node_attr.bind(this);
    this.set_node_permission = this.set_node_permission.bind(this);
    this.get_action_log = this.get_action_log.bind(this);
  }

  /**
   *
   */
  get_attributes() {
    this.output.data(this.hub.toJSON());
  }

  /**
   * 
   */
  get_action_log() {
    const user_id = this.user_id();
    const page = this.input.use(Attr.page, 1);
    this.db.call_proc("hub_get_action_log", user_id, page, this.output.list);
  }

  /**
   * 
   */
  get_members_by_type() {
    const type = this.input.need(Attr.type);
    const page = this.input.use(Attr.page, 1);
    this.db.call_proc(
      "hub_get_members_by_type",
      this.uid,
      type,
      page,
      this.output.list
    );
  }

  /**
   * 
   */
  change_status() {
    const user_id = this.user_id();
    const hub_id = this.hub.get(Attr.id);
    const status = this.input.need(Attr.status);
    const cb = function (data) {
      if (isEmpty(data)) {
        this.excetion.user(INTERNAL_ERROR);
      }
      if (data.valid_user === "0") {
        return this.excetion.user(PERMISSION_DENIED);
      } else {
        delete data.valid_user;
        data = { status };
        this.output.data(data);
      }
    }.bind(this);
    this.yp.call_proc(
      "yp_change_hub_status",
      user_id,
      hub_id,
      this.permission,
      status,
      cb
    );
  }

  /**
  * Gets disk space availability.
  * @param {*} id 
  * @returns 
  */
  get_occupied_drumate_space(id) {
    const total_size = this.user.get('quota').disk;
    return { total: total_size, user_data: this.user.get('disk_usage') };
  }

  /**
   * 
   */
  _getShareLink(token) {
    let keysel = this.hub.get(Attr.hubname);
    const pathname = this.input.basepath(`/?keysel=${keysel}#/dmz/share/`);
    let link = `https://${this.hub.get(Attr.vhost)}${pathname}`;
    if (token) return link + token;
    return link;
  }

  /**
 * 
 * @param {*} hub_id 
 * @param {*} message 
 * @param {*} flag 
 * @param {*} opt 
 * @returns 
 */
  async notify_external(hub_id, message, flag, opt = {}) {
    const link = this._getShareLink();
    const icon = this.hub.get(Attr.icon)

    // Offline File path
    let cmd = resolve(server_location, 'offline', 'notification', 'sharebox-notification.js');

    let members = await this.yp.await_proc('forward_proc', hub_id, 'dmz_notify_list', `'${flag}'`);
    if (isEmpty(members)) { return }
    if (!isArray(members)) { members = [members]; }

    // initiated the child process
    const username = this.user_id.get(Attr.firstname) || this.user_id.get(Attr.username);
    const lang = this.input.language();
    let args = [JSON.stringify({ hub_id, message, flag, lang, username, link, icon, options: opt })];
    const { spawn } = require('child_process');
    spawn(cmd, args, { detached: true });

    return members;

  }


  /**
   * 
   */
  change_history() {
    const id = this.input.use(Attr.id, "");
    const key = this.input.use(Attr.key, "");
    const from_date = this.input.use(Attr.from, 0);
    const to_date = this.input.use(Attr.to, 0);
    const page = this.input.use(Attr.page, 1);
    this.db.call_proc(
      "change_history",
      id,
      key,
      from_date,
      to_date,
      page,
      this.output.data
    );
  }

  /**
   * 
   */
  async update_name() {
    let tag = this.randomString();
    const hub_id = this.hub.get(Attr.id);
    const name = this.input.need(Attr.name);
    const data = await this.yp.await_proc("hub_update_name", hub_id, name);
    this.output.data({ ...data, name });
  }

  /**
   * 
   */
  update_title() {
    const hub_id = this.hub.get(Attr.id);
    const hub_title = this.input.need(Attr.hub_title);
    this.yp.call_proc("hub_update_title", hub_id, hub_title, this.output.data);
  }

  /**
   * 
   */
  update_settings() {
    const vars = this.input.need(Attr.vars);
    const hub_id = this.hub.get(Attr.id);
    async function f() {
      let v;
      for (let k in vars) {
        v = vars[k];
        await this.yp.await_proc("hub_change_settings", hub_id, k, v);
      }
      return null;
    }
    f()
      .then(function () {
        this.yp.call_proc("get_settings", hub_id, this.output.data);
      })
      .catch(this.fallback);
  }

  /**
   * 
   */
  update_favicon() {
    const hub_id = this.get(Attr.id);
    const favicon = this.input.need(Attr.favicon);
    this.yp.call_proc("hub_update_favicon", hub_id, favicon, this.output.data);
  }

  /**
   * 
   * @returns 
   */
  get_statistics() {
    return this.db.call_proc("get_statistics", this.output.data);
  }

  /**
   * 
   */
  update_ident() {
    const ident = this.input.need(Attr.ident);
    const id = this.input.use(Attr.id);
    this.debug("AAAA 112", ident);
    this.yp.call_proc(
      "ident_exists",
      ident,
      function (row) {
        if (isEmpty(row)) {
          return this.yp.call_proc("update_ident", id, ident, () => {
            return this.yp.call_proc("get_hub", ident, this.output.data);
          });
        } else {
          return this.exception.user("_ident_already_exists");
        }
      }.bind(this)
    );
  }

  /**
   * 
   * @returns 
   */
  update_visibility() {
    const hub_id = this.hub.get(Attr.id);
    const visibility = this.input.need(Attr.value);
    return this.yp.call_proc(
      "hub_update_visibility",
      hub_id,
      visibility,
      this.output.data
    );
  }

  /**
   * 
   * @returns 
   */
  get_contributors() {
    const page = this.input.use(Attr.page, 1);
    const privilege = this.input.use(Attr.privilege) || 0;
    return this.db.call_proc("show_contributors", page, this.output.data);
  }

  /**
   * 
   */
  show_contributors() {
    const page = this.input.use(Attr.page, 1);
    this.db.call_proc("show_contributors", page, this.output.data);
  }

  /**
   * 
   */
  async get_settings() {
    let data = await this.yp.await_proc("get_hub_owner", this.hub.get(Attr.id));
    const opt = this.hub.get(Attr.settings);
    opt.default_privilege = opt.default_privilege || Privilege.DOWNLOAD;
    opt.owner = data;
    opt.hubname = this.hub.get(Attr.name);
    let visitor = await this.db.await_proc("member_show_privilege", this.uid);
    opt.visitor = visitor;
    //@output.data opt
    let users = await this.db.await_proc(
      "hub_get_members_by_type",
      this.uid,
      "all",
      1
    );
    // opt.users = users;
    users = toArray(users);
    opt.users = filter(users, (el) => {
      return (el.privilege & 32) == 0;
    });

    this.output.data(opt);
  }

  /**
   * 
   * @returns 
   */
  show_privilege() {
    return this.db.call_proc(
      "member_show_privilege",
      this.uid,
      this.output.data
    );
  }

  /**
   * 
   * @returns 
   */
  async add_contributors() {
    let users = this.input.need(Attr.users);
    const username = this.user.get("fullname");
    const hubname = this.hub.get(Attr.name);
    const privilege =
      this.input.use(Attr.privilege) ||
      this.hub.get(Attr.settings).default_privilege;
    const expiry = this.input.use(Attr.expiry) || 0;
    const type = this.input.use(Attr.type) || Attr.all;
    const lang = this.user.language() || this.input.app_language();
    let mfs_home = await this.db.await_proc("mfs_home");
    let msg = Cache.message("_x_add_you_to_team", lang).format(
      username,
      hubname
    );
    let message = this.input.use(Attr.message) || msg;
    if (!isArray(users)) {
      users = [users];
    }

    let res = {};
    let members = [];
    let rows = [];
    if (isEmpty(users)) {
      res = [];
      return res;
    }
    for (let entity of users) {
      let contact = await this.yp.await_proc(
        "forward_proc",
        this.uid,
        "my_contact_exists",
        `'entity','${entity}', null, null`
      );
      if (!isEmpty(contact)) {
        if (contact.status == "active") {
          members.push(contact.uid);
        } else {
          await this.yp.await_proc(
            "yp_add_share_guest",
            this.hub.get(Attr.id),
            privilege,
            expiry,
            entity
          );
        }
      }
    }
    for (let uid of members) {
      let r = await this.db.await_proc("add_member", uid, privilege, expiry);
      if (!r || !r.db_name) continue;
      rows.push(r);
      await this.db.await_proc(
        "permission_grant",
        "*",
        uid,
        expiry,
        privilege,
        "system",
        message
      );
      await this.db.await_proc(
        "permission_grant",
        mfs_home.chat_upload_id,
        uid,
        0,
        4,
        "no_traversal",
        "chat upload permission"
      );
    }
    if (!isEmpty(rows)) {
      for (let recipient of rows) {
        let hub = await this.yp.await_proc(
          `${recipient.db_name}.mfs_access_node`,
          recipient.id,
          this.hub.get(Attr.id)
        );
        hub.message = message;
        hub.ownpath = '/';
        let sockets = await this.yp.await_proc("user_sockets", recipient.id);
        await RedisStore.sendData(this.payload(hub), sockets);
      }
    }

    message = this.input.use(Attr.message);
    if (!isEmpty(message)) {
      let input = {};
      let message_id = await this.db.await_proc("message_id");
      message_id = message_id.id;
      input.author_id = this.uid;
      input.uid = this.uid;
      input.message_id = message_id;
      message = message.replace(/'/gi, "''");
      let data = await this.yp.await_proc(
        "forward_proc",
        this.hub.get(Attr.id),
        "channel_post_message_next",
        `'${stringify(input)}','${message}'`
      );
      data.is_attachment = 0;
      let profile = this.user.get("profile") || {};
      data.firstname = this.user.attributes.firstname;
      data.lastname = profile.lastname;
      data.hub_id = this.hub.get(Attr.id);

      let sockets = await this.yp.await_proc(
        "entity_sockets",
        this.hub.get(Attr.id)
      );
      await RedisStore.sendData(this.payload(data), sockets);
    }

    res = await this.db.await_proc(
      "hub_get_members_by_type",
      this.uid,
      type,
      1
    );
    res = toArray(res);
    res = filter(res, (el) => {
      return (el.privilege & 32) == 0;
    });
    this.output.data(res);
  }

  /**
   * 
   */
  async delete_hub() {
    const hub_id = this.input.need(Attr.hub_id);
    let data = this.hub.toJSON();
    data.nid = data.id;
    let sockets = await this.yp.await_proc("entity_sockets", hub_id);
    await RedisStore.sendData(this.payload(data), sockets);

    this.debug(`SSSSSSSSS ::::hub_id==${hub_id}:::::157`, Attr.nid, data, hub_id);
    await this.db.await_proc(`remove_all_members`, 0);
    let entity = await this.yp.await_proc("entity_delete", hub_id);
    remove_dir(entity.home_dir, 1);
    this.output.data({ uid: this.uid, id: hub_id, hub_id });
  }

  /**
   *
   */
  async get_external_room_attr() {
    let rows = (await this.db.await_proc("dmz_settings")) || [];
    let res = rows.shift();
    res.details = rows;
    res.members = [];

    let members = await this.db.await_proc("dmz_get_members", this.uid);
    if (!isEmpty(members)) {
      if (!isArray(members)) {
        members = [members];
      }
    }
    res.members = members;
    res.link = this._getShareLink(res.link);
    this.output.data(res);
  }

  /**
   *
   */
  async external_notification() {
    let message = this.input.use(Attr.message) || "";
    let members = await this.notify_external(
      this.hub.get(Attr.id),
      message,
      "all"
    );
    this.output.data({ members });
  }

  /**
   *
   */
  async delete_external_member() {
    let emails = this.input.need(Attr.email);
    let nid = this.home_id;
    let email;
    let hub_id = this.hub.get(Attr.id);
    const data = { id: this.hub.get(Attr.id) };

    if (!isEmpty(emails)) {
      if (!isArray(emails)) {
        emails = [emails];
      }
      for (email of emails) {
        let g = await this.yp.await_proc("dmz_add_user", email, null);
        await this.db.await_proc("dmz_remove_member", g.id, hub_id, nid);
      }
    }

    this.output.data({ emails });
  }

  /**
   *
   */
  async update_external_settings() {
    const permission = this.input.use(Attr.permission) || Privilege.GUEST;
    const pw = this.input.get(Attr.password) || "";
    const days = this.input.get(Attr.days) || 0;
    const hours = this.input.get(Attr.hours) || 0;
    const flag = this.input.need(Attr.flag);
    const validityMode = this.input.get("validity_mode") || "infinity";
    const expiry = hours * 1 + days * 24;

    let res = {};
    let nid = this.home_id;
    let hub_id = this.hub.get(Attr.id);

    if (flag == Attr.password) {
      await this.yp.await_proc("dmz_update_password", hub_id, nid, pw);
      res.password = pw;
    }

    if (flag == Attr.permission) {
      await this.yp.await_proc(
        "dmz_update_permission_next",
        hub_id,
        nid,
        permission
      );
      res.permission = permission;
    }

    if (flag == Attr.expiry) {
      await this.yp.await_proc(
        "dmz_update_expiry_new",
        hub_id,
        nid,
        validityMode,
        expiry
      );
      res.hours = hours;
      res.days = days;
      res.dmz_expiry = "active";
      if (expiry == 0) {
        res.dmz_expiry = "expired";
      }
      if (validityMode == "infinity") {
        res.dmz_expiry = "infinity";
      }
    }

    this.output.data(res);
  }

  async update_external_members() {
    let emails = this.input.use(Attr.emails) || this.input.use(Attr.email) || [];
    if (!isArray(emails)) {
      emails = [emails];
    }
    let members = await this.db.await_proc("dmz_get_members", this.uid);
    if (!isEmpty(members)) {
      if (!isArray(members)) {
        members = [members];
      }
    }
    let members_mail = map(members, "email");
    let delete_mails = difference(members_mail, emails);
    let new_mails = difference(emails, members_mail);

    let nid = this.home_id;
    let hub_id = this.hub.get(Attr.id);
    for (email of delete_mails) {
      let g = await this.yp.await_proc("dmz_add_user", email, null);
      await this.db.await_proc("dmz_remove_member", g.id, hub_id, nid);
    }

    for (var email of new_mails) {
      await this.add_contact(email);
      let g = await this.yp.await_proc("dmz_add_user", email, null);
      await this.yp.await_proc(
        "dmz_grant_next",
        hub_id,
        nid,
        g.id,
        this.randomString(),
        null
      );
      await this.db.await_proc("permission_grant", nid, g.id, 0, 1, "link", "");
    }

    let rows = (await this.db.await_proc("dmz_settings")) || [];
    let settings = rows.shift();

    const permission = settings.permission || 1;
    const expiry = settings.expiry_time || 0;
    const fingerprint = settings.fingerprint || "";
    await this.yp.await_proc(
      "dmz_update_settings",
      hub_id,
      nid,
      fingerprint,
      expiry,
      permission
    );

    this.output.data({ emails });
  }

  /**
   *
   */
  async copy_link() {
    let res = {};
    let nid = this.input.need(Attr.nid);
    let hub_id = this.hub.get(Attr.id);
    let home_id = this.home_id;

    let rows = (await this.db.await_proc("dmz_settings")) || [];
    let settings = rows.shift();
    const permission = settings.permission || 1;
    const expiry = settings.expiry_time || 0;
    const fingerprint = settings.fingerprint || "";

    await this.yp.await_proc("dmz_add_media", nid, hub_id);

    let node = await this.db.await_proc("mfs_access_node", this.uid, nid);

    if (node.ftype == "folder") {
      res = await this.yp.await_proc(
        "dmz_grant_next",
        hub_id,
        nid,
        nid,
        this.randomString(),
        fingerprint
      );
    } else {
      res = await this.yp.await_proc(
        "dmz_grant_next",
        hub_id,
        node.parent_id,
        nid,
        this.randomString(),
        fingerprint
      );

      await this.db.await_proc(
        "permission_grant",
        node.parent_id,
        nid,
        0,
        1,
        "root",
        ""
      );
    }

    await this.db.await_proc("permission_grant", nid, nid, 0, 1, "link", "");
    await this.yp.await_proc(
      "dmz_update_settings",
      hub_id,
      nid,
      fingerprint,
      expiry,
      permission
    );
    res.link = this._getShareLink(res.link);
    this.output.data(res);
  }

  /**
   *
   */
  async add_external_member() {
    let emails = this.input.use(Attr.emails) || this.input.use(Attr.email) || [];
    let nid = this.home_id;
    let hub_id = this.hub.get(Attr.id);

    let rows = (await this.db.await_proc("dmz_settings")) || [];
    let settings = rows.shift();

    const permission = settings.permission || 1;
    const expiry = settings.expiry_time || 0;
    const fingerprint = settings.fingerprint || "";

    if (!isArray(emails)) {
      emails = [emails];
    }

    for (var email of emails) {
      let g = await this.yp.await_proc("dmz_add_user", email, null);
      await this.yp.await_proc(
        "dmz_grant_next",
        hub_id,
        nid,
        g.id,
        this.randomString(),
        null
      );
      await this.db.await_proc("permission_grant", nid, g.id, 0, 1, "link", "");
    }

    await this.yp.await_proc(
      "dmz_update_settings",
      hub_id,
      nid,
      fingerprint,
      expiry,
      permission
    );
    //await this.notify_external(hub_id, '', 'new');
    this.output.data({ emails });
  }

  /**
   *
   */
  async update_external_room() {
    let emails = this.input.use(Attr.emails) || this.input.use(Attr.email) || [];
    let permission = this.input.use(Attr.permission) || Privilege.GUEST;
    const pw = this.input.get(Attr.password);
    const validityMode = this.input.get("validity_mode") || "infinity";
    const days = this.input.get(Attr.days) || 0;
    const hours = this.input.get(Attr.hours) || 0;
    let expiry = hours * 1 + days * 24;

    if (validityMode == "infinity") expiry = 0;

    if (permission > Privilege.WRITE) permission = Privilege.WRITE;

    let nid = this.home_id;
    let hub_id = this.hub.get(Attr.id);
    let public_id = Cache.getSysConf("public_id");

    let g = await this.yp.await_proc(
      "dmz_grant_next",
      hub_id,
      nid,
      public_id,
      this.randomString(),
      pw
    );
    this.debug("ZEZEZEZEZE GRANT", public_id, g);
    await this.db.await_proc(
      "permission_grant",
      nid,
      public_id,
      expiry,
      permission,
      "link",
      ""
    );

    if (!isArray(emails)) {
      emails = [emails];
    }
    for (var email of emails) {
      await this.add_contact(email);
      g = await this.yp.await_proc("dmz_add_user", email, null);
      await this.yp.await_proc(
        "dmz_grant_next",
        hub_id,
        nid,
        g.id,
        this.randomString(),
        pw
      );
      await this.db.await_proc(
        "permission_grant",
        nid,
        g.id,
        expiry,
        permission,
        "link",
        ""
      );
    }

    this.output.data({ emails });
  }

  async add_contact(email) {
    let entity = email;
    let firstname;
    let lastname;
    let drumate = await this.yp.await_proc("drumate_exists", entity);
    entity = drumate.id || entity;
    let mycontact = await this.yp.await_proc(
      "forward_proc",
      this.uid,
      "my_contact_exists",
      `'entity','${entity}',null,null`
    );
    if (isEmpty(mycontact)) {
      let a = email.split("@");
      a[1] = a[0];
      if (a[0].indexOf(".") !== -1) {
        a = a[0].split(".");
      }
      firstname = a[0];
      lastname = a[1];
      let metadata = {
        source: email,
        imported: this.session.timestamp,
        from: "exroom",
      };
      let contact = await this.yp.await_proc(
        "forward_proc",
        this.uid,
        "my_contact_add_next",
        `'${entity}',null,'${firstname}' ,'${lastname}','independant', null,null ,'${JSON.stringify(
          metadata
        )}'`
      );

      let node = {};
      node.email = email;
      node.category = "priv";
      node.is_default = "1";
      await this.yp.await_proc(
        "forward_proc",
        this.uid,
        "my_contact_mail_add",
        `'${contact.id}','${JSON.stringify([node])}'`
      );
    }
  }

  /**
   * 
   */
  async delete_contributor() {
    let users = this.input.need(Attr.users);
    if (!isArray(users)) {
      users = [users];
    }

    let members = [];
    for (let uid of users) {
      if (uid != this.uid) {
        members.push(uid);
      }
    }

    let service = "media.remove";
    for (let uid of members) {
      await this.db.await_proc("remove_member", uid);
      let node = this.granted_node();
      node.nid = node.id = this.hub.get(Attr.id);
      let sockets = await this.yp.await_proc("user_sockets", uid);
      await RedisStore.sendData(this.payload(node, { service }), sockets);
    }
    this.output.list(members);
  }

  /**
   * 
   * @returns 
   */
  get_space_usage() {
    const data = this.get_occupied_hubs_space(
      this.hub("owner_id"),
      this.get(Attr.id)
    );
    const drumate_space = this.get_occupied_drumate_space(this.hub("owner_id"));
    data.total = drumate_space.total;
    data.others = data.others + drumate_space.user_data;
    data.free = data.total - data.others - data.selected;
    return this.output.data(data);
  }

  /**
   * 
   */
  async set_privilege() {
    let users = this.input.need(Attr.users);
    const privilege =
      this.input.use(Attr.privilege) ||
      this.input.use(Attr.permission) ||
      this.hub.get(Attr.settings).default_privilege ||
      1;

    let mfs_home = await this.db.await_proc("mfs_home");

    if (!isArray(users)) {
      users = [users];
    }
    let hub;

    for (let uid of users) {
      await this.db.await_proc("permission_set", uid, privilege);

      await this.db.await_proc(
        "permission_grant",
        mfs_home.chat_upload_id,
        uid,
        0,
        4,
        "no_traversal",
        "chat upload permission"
      );

      hub = {};
      hub.privilege = privilege;
      hub.hub_id = this.hub.get(Attr.hub_id);
      hub.area = this.hub.get(Attr.area);
      let sockets = await this.yp.await_proc("user_sockets", uid);
      await RedisStore.sendData(this.payload(hub), sockets);
    }
    this.output.data(users);
  }

  /**
   * 
   * @returns 
   */
  set_members_privilege() {
    const privilege =
      this.input.use(Attr.privilege) ||
      this.hub.get(Attr.settings).default_privilege ||
      2;
    return this.db.call_proc(
      "members_set_privilege",
      privilege,
      this.output.data
    );
  }

  /**
   * 
   */
  change_owner() {
    const new_owner = this.input.need(Attr.id);
    this.db.call_proc("change_owner", new_owner, this.output.data);
  }

  /**
   * 
   */
  lookup_hubers() {
    const name = this.input.use(Attr.name, "");
    const page = this.input.use(Attr.page, 1);
    const exclude = this.input.use(Attr.exclude);
    this.db.call_proc(
      "lookup_hubers",
      name,
      page,
      function (data) {
        data = toArray(data);
        if (data && exclude != null) {
          data = data.filter((x) => x.id !== exclude);
        }
        this.output.data(data);
      }.bind(this)
    );
  }

  /**
   * 
   * @returns 
   */
  add_font_link() {
    const name = this.input.need(Attr.name);
    const variant = this.input.need(Attr.variant);
    const url = this.input.need(Attr.url);
    return this.db.call_proc(
      "hub_add_font_link",
      name,
      variant,
      url,
      this.output.data
    );
  }

  /**
   * 
   */
  get_pr_node_attr() {
    const nid = this.input.need(Attr.nid);
    this.db.call_proc("get_pr_node_attr", nid, this.output.data);
  }

  /**
   *
   */
  async poke() {
    const uid = this.input.need(Attr.uid);
    let service = "user.poke";
    let data = {
      uid,
      name: this.hub.get(Attr.name) || "",
      sender: this.user.get(Attr.firstname),
      hub_id: this.hub.get(Attr.id),
      nid: this.input.need(Attr.nid),
      kind: this.input.need(Attr.kind),
    };
    let sockets = await this.yp.await_proc("user_sockets", uid);
    await RedisStore.sendData(this.payload(data, { service }), sockets);
    //this.pushLiveUpdate(content);
    this.output.data({ sender: this.uid, recipient: uid });
  }

  /**
   * 
   * @returns 
   */
  set_node_permission() {
    let cnt_valid;
    const nid = this.input.need(Attr.nid);
    const email = this.input.need(Attr.email);
    const permission = this.input.use(Attr.permission, 1);
    message = this.input.use(Attr.message, "");
    const days = this.input.use(Attr.days, 0);
    const hours = this.input.use(Attr.hours, 0);
    const expiry = hours * 1 + days * 24;

    let invalid_email = 0;
    if (email == null || !email.isEmail()) {
      invalid_email = 1;
    }

    let uid = "";
    this.yp.call_proc(
      "drumate_exists",
      email,
      function (row) {
        if (!isEmpty(row)) {
          uid = row.id;
        }
        return cnt_valid();
      }.bind(this)
    );

    let node = "";
    this.db.call_proc(
      "mfs_access_node",
      this.uid,
      nid,
      function (row) {
        if (!isEmpty(row)) {
          node = row.nid;
        }
        return cnt_valid();
      }.bind(this)
    );

    const fn_valid = () => {
      if (invalid_email == 1) {
        return this.exception.user(INVALID_EMAIL_FORMAT);
      } else if (uid === "") {
        return this.exception.user(EMAIL_NOT_FOUND);
      } else if (node === "") {
        return this.exception.user(ID_NOT_FOUND);
      } else {
        this.db.call_proc(
          "permission_grant",
          node,
          uid,
          expiry,
          permission,
          "system",
          message,
          this.output.data
        );
      }
    };

    return (cnt_valid = _.after(2, fn_valid));
  }
}

module.exports = __private_hub;
