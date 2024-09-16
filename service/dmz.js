
const { Attr, Constants, Messenger, Cache } = require("@drumee/server-essentials");
const { Mfs } = require('@drumee/server-core');
const { isEmpty } = require('lodash');
const {
  ID_NOBODY
} = Constants;


//########################################
class __dmz extends Mfs {


  /**
   * 
   */
  async signup() {
    const token = this.input.need(Attr.token);
    let sid = this.input.sid();
    let res = await this.yp.await_proc('dmz_info_next', token);

    if (isEmpty(res)) {
      res.status = 'WRONG_TICKET'
      return this.output.data(res);
    }
    let is_verified = 0

    if (sid) {
      let cookie = await this.yp.await_proc('cookie_check_guest',
        sid, this.input.get(Attr.socket_id)
      );
      if (cookie && cookie.session_id == sid) {
        is_verified = 1
      }
    }

    if (!is_verified) {
      res.status = 'REQUIRED_PASSWORD'
      return this.output.data(res);
    }

    let user = await this.yp.await_proc('drumate_get', res.email);
    if (!isEmpty(user)) {
      res.status = 'EMAIL_EXIST'
      return this.output.data(res);
    }
    const lang = this.input.ua_language();
    const pathname = this.input.basepath();
    const link = `https://${process.env.domain_name}${pathname}#/welcome/signup/${token}`;
    const subject = Cache.message("_signup_activation", lang);
    const method = 'signup';
    let email = res.email;
    let name = email;
    await this.yp.await_proc('token_generate_next', email, name, token, method, '');
    let pass = await this.yp.await_proc('token_get_next', token);
    if (isEmpty(pass)) {
      res.status = 'FACTORY_FAILED'
      return this.output.data(res);
    }

    if (res.privilege >= 0) {
      await this.yp.await_proc('dmz_update_sync', token, 1);
    }
    const msg = new Messenger({
      template: "butler/signup",
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


    let metadata = {}
    metadata = this.parseJSON(pass.metadata)
    metadata.sharebox = res.hub_id;
    await this.yp.await_proc('token_update', token, metadata);
    await msg.send();
    res = {};
    res.link = link;
    return this.output.data(res);
  }



  /**
 * 
 */
  async info() {
    let res = await this.yp.await_proc('dmz_info_next', this.input.need(Attr.token));
    if (isEmpty(res)) {
      res.status = 'WRONG_TICKET'
    } else if (res.require_password) {
      res.status = 'REQUIRED_PASSWORD'
    }
    this.output.data(res);
  }


  /**
   * 
   */
  async login() {
    let token = this.input.need(Attr.token);
    let password = this.input.get(Attr.password);
    let info = await this.yp.await_proc('dmz_info_next', token);
    if (!info) {
      this.output.data({ status: "TICKET_INVALID" });
      return;
    }

    let user = this.user.toJSON();
    let { regsid } = this.input.get(Attr.cookie);
    if (regsid) {
      /** Side user */
      let u = await this.yp.await_proc("cookie_retrieve_user", regsid);
      if (u && u.id != ID_NOBODY) {
        if (u.profile) {
          user.profile = u.profile;
          user.uid = u.id;
          user.id = u.id;
        }
      }
    }
    //this.debug("AAAA:133", this.user.toJSON(), this.hub.get(Attr.home_id), this.uid, { info }, this.input.authorization())
    let rows = await this.yp.await_proc('forward_proc', info.hub_id, 'dmz_settings', ``);
    if (rows[0] && rows[0].hours !== null) {
      info.hours = rows[0].hours;
      info.days = rows[0].days;
      info.dmz_expiry = rows[0].dmz_expiry;
    }
    info.require_pwd = info.require_password;
    let node = await this.db.await_proc('mfs_access_node', this.uid, info.nid) || {};
    if (info.require_pwd && !node.privilege) {
      info.status = 'REQUIRED_PASSWORD';
      //this.debug('AAA:148', this.uid, info.nid, { node });
      if (!password) {
        return this.output.data(info);
      }
      let res = await this.session.dmz_login(token, password);
      if (res.is_verified) {
        res.require_pwd = 0;
        info.status = 'TICKET_OK';
        this.output.data(res);
        return;
      }

      if (res.failed) {
        info.status = 'WRONG_PASSWORD';
        res.validity = res.error;
        this.output.data(res);
        return;
      }
    }

    if (info.validity == 'TICKET_OK' && info.uid) {
      await this.yp.await_proc('cookie_touch', {
        sid: this.input.sid(), uid: info.uid
      });
    }

    if (info.is_public && !user.guest_name) {
      user.require_name = 1;
    }
    user.uid = user.id;
    let area = this.hub.get(Attr.area);
    let out = { ...user, ...info, guest_id: info.uid, area };
    this.output.data(out);
  }

  /**
   * 
   */
  logout() {
    this.session.dmz_logout();
  }

  /**
   * 
   */
  async reset_sessions() {
    let members = await this.db.await_proc('dmz_notify_list', `all`) || [];
    for (let m of members) {
      await this.yp.await_proc('session_logout_by_admin', m.recipient_id);
    }
    this.output.data(members);
  }

  /**
   * 
   */
  notification_list() {
    this.output.data([]);
  }

}


module.exports = __dmz;