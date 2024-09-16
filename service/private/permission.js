// ================================  *
//   Copyright Xialia.com  2013-2017 *
//   FILE  : src/service/private/permission
//   TYPE  : module
// ================================  *
const { Attr } = require("@drumee/server-essentials");

const { isArray, after } = require("lodash");
const { Mfs } = require("@drumee/server-core");

class __private_permission extends Mfs {
  constructor(...args) {
    super(...args);
    this.add_users = this.add_users.bind(this);
    this.grant = this.grant.bind(this);
    this.revoke = this.revoke.bind(this);
    this.show_users = this.show_users.bind(this);
  }

  /**
   * 
   * @param {*} session 
   * @param {*} permission 
   * @param {*} opt 
   * @returns 
   */
  initialize(session, permission, opt) {
    this.before_granting = "check_sanity";
    this._start_with = "mfs_home";
    return super.initialize(session, permission);
  }

  /**
   * 
   * @returns 
   */
  add_users() {
    const expiry = this.input.use(Attr.expiry) || 0;
    const msg = this.input.use(Attr.messgae) || "";
    let users = this.input.need(Attr.users);
    const permission =
      this.input.use(Attr.permission) ||
      this.hub.get(Attr.settings).default_privilage;
    if (users != null && !isArray(users)) {
      users = [users];
    }

    const _count = after(users.length, () => {
      return this.output.data({ users });
    });

    return users.map((uid) =>
      this.db.call_proc(
        "permission_grant",
        "*",
        uid,
        expiry,
        PRIVILEGE.owner,
        "share",
        msg,
        _count
      )
    );
  }

  /**
   * 
   * @returns 
   */
  grant() {
    const expiry = this.input.use(Attr.expiry) || 0;
    const msg = this.input.use(Attr.messgae) || "";
    let users = this.input.need(Attr.users);

    const permission = this.input.need(Attr.permission);
    const nid = this.input.use(Attr.nid) || "*";
    const _count = after(users.length, () => {
      return this.db.call_proc("acl_show_users", nid, this.output.data);
    });

    if (users != null && !isArray(users)) {
      users = [users];
    }
    return (() => {
      const result = [];
      for (let uid of users) {
        this.debug(`GRANTING  on ${nid} TO ${uid} WITH p=${permission}`);
        result.push(
          this.db.call_proc(
            "permission_grant",
            nid,
            uid,
            expiry,
            permission,
            "share",
            msg,
            _count
          )
        );
      }
      return result;
    })();
  }

  /**
   * 
   * @returns 
   */
  revoke() {
    const expiry = this.input.use(Attr.expiry) || 0;
    const msg = this.input.use(Attr.messgae) || "";
    let users = this.input.need(Attr.users);
    const nid = this.input.need(Attr.nid);
    if (users != null && !isArray(users)) {
      users = [users];
    }

    const _count = after(users.length, () => {
      return this.output.data({ users });
    });

    return users.map((uid) =>
      this.db.call_proc("permission_revoke", nid, uid, _count)
    );
  }

  /**
   * 
   * @returns 
   */
  show_users() {
    const nid = this.input.need(Attr.nid);
    this.db.call_proc("acl_show_users", nid, this.output.data);
  }
}

module.exports = __private_permission;
