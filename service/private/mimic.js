
// ================================  *
//   Copyright Xialia.com  2013-2017 *
//   FILE  : src/service/private/chat
//   TYPE  : module
// ================================  *

const { Attr } = require("@drumee/server-essentials");
const {isEmpty} = require('lodash');
const {Entity} = require('@drumee/server-core');
class __private_adminpanel extends Entity {

  // ========================
  // initialize
  // ========================
  constructor(...args) {
    super(...args);
    this.mimic_new = this.mimic_new.bind(this);
    this.mimic_reject = this.mimic_reject.bind(this);
    this.mimic_active = this.mimic_active.bind(this);
    this.end_bytime = this.end_bytime.bind(this);
    this.end_byuser = this.end_byuser.bind(this);
    this.end_bymimic = this.end_bymimic.bind(this);

  }

 

 
  /**
   * 
   * @returns 
   */
  async end_bytime() {
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
      await redisStore.sendData(this.payload(res), recipients);
    }
    this.output.list(res);
  }

  /**
   * 
   */
  async end_bymimic() {
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
      await redisStore.sendData(this.payload(res), recipients);
    }
    this.output.list(res);
  }

  /**
   * 
   * @returns 
   */
  async end_byuser() {
    const mimic_id = this.input.need(Attr.mimic_id);

    let mimic = await this.yp.await_proc('mimic_get', mimic_id)
    if (isEmpty(mimic)) return this.output.status('NO_MIMIC');

    if (mimic.uid != this.uid) return this.output.status('INVALID_MIMIC');

    if (mimic.status != 'active') return this.output.status('INVALID_STATUS');

    await this.yp.await_proc('mimic_set_by_status', mimic_id, 'endbyuser')
    await this.yp.await_proc('uncast_user', mimic.mimicker, mimic.uid)
    res = await this.yp.await_proc('mimic_get', mimic_id)
    let recipients = await this.yp.await_proc('user_sockets', [mimic.uid, mimic.mimicker]);
    await redisStore.sendData(this.payload(res), recipients);
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
    await redisStore.sendData(this.payload(res), recipients);
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
    await redisStore.sendData(this.payload(res), recipients);
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
    await redisStore.sendData(this.payload(res), recipients);
    this.output.data(res);
  }



}


module.exports = __private_adminpanel;
