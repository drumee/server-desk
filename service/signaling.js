
// ================================  *
//   Copyright Xialia.com  2013-2017 *
//   FILE  : src/service/private/chat
//   TYPE  : module
// ================================  *


const { isEmpty, isArray, map } = require('lodash');
const { Attr, RedisStore, utils } = require("@drumee/server-essentials");
const { toArray } = utils;

const { stringify } = JSON;

const { Entity } = require('@drumee/server-core');
class __service_signaling extends Entity {

  /**
   * 
   * @param {*} opt 
   */
  initialize(opt) {
    super.initialize(opt);
    const p = this.user.get(Attr.profile);
    let origin = this.input.use(Attr.origin) || {};

    this.origin = {
      ...origin,
      uid: this.uid,
      firstname: p.firstname,
      lastname: p.lastname,
      fullname: p.fullname,
      email: p.email
    }
    this.target = this.input.use(Attr.target) || {};
    let target = this.target;
    let input = this.input.data() || {};
    let scope = input.scope;
    if (target.socket_id || target.stream_id) {
      scope = Attr.socket;
    } else if (target.hub_id) {
      scope = scope || Attr.hub;
    } else if (target.uid) {
      scope = Attr.user;
    }
    this.scope = scope;
  }



  /**
   * To send notifications to online clients
   *
   * @params 
   * 
  */
  async notify_peers(data) {
    let origin = this.origin;
    let target = this.target;
    let input = this.input.data();
    let exclude = [];
    let recipients;
    if (isEmpty(target)) {
      let msg = "No target to send to the same!!!";
      this.warn(msg);
      return
    }
    switch (this.scope) {
      case Attr.hub:
      case 'online-members':
        this.warn(`AAA:121 -- SCOPE ${this.scope} DEPRECATED ???`, data);
        if (origin && origin.socket_id) exclude = [origin.socket_id];
        recipients = await this.yp.await_proc('entity_sockets', { hub_id: input.hub_id, exclude });
        await RedisStore.sendData(this.payload(data), recipients);
        break;
      case Attr.user:
        recipients = await this.yp.await_proc('user_sockets', target.uid);
        await RedisStore.sendData(this.payload(data), recipients);

        break;

      default:
        if (target.socket_id != origin.socket_id) {
          await RedisStore.sendData(this.payload(data), target.socket_id);
        } else {
          let msg = "Origin and target are the same!!!";
          this.warn(msg, target.socket_id, origin.socket_id);
        }
    }

  }

  /**
   * To send dial notifications to all sockets bound to uid 
   * 
   */
  async dial() {
    let uid = this.target.uid;
    let room_id = this.input.need('room_id');
    let room_type = this.input.need("room_type");
    let device_id = this.input.get("device_id");
    if (uid == this.uid || uid == this.user.ident()) {
      this.exception.user("Self calling is not allowed");
      return;
    }
    let output = this.input.data() || {};
    output.origin = this.origin;
    output.target = this.target || {};
    this.debug("AAA:2000", this.user.toJSON());
    let data = {
      message: 'INCOMING_CALL',
      hub_id: this.uid,
      name: this.user.get(Attr.firstname),
      nid: this.home_id,
      room_id,
      nid: room_id,
      room_type
    };

    let recipients = await this.yp.await_proc('user_sockets', this.target.uid);

    if (isEmpty(recipients)) {
      this.output.data({ offline: 1 })
      return;
    }

    let clients = toArray(recipients);
    for (let dest of clients) {
      let opt = {
        user_id: dest.uid,
        type: room_type,
        room_id,
        role: Attr.listener,
        device_id,
        socket_id: dest.socket_id
      }
      await this.db.await_proc('room_invite_next', JSON.stringify(opt));
    }

    await RedisStore.sendData(this.payload(data), recipients);
    this.output.data(output);

  }

  /**
   * To send hello message to peers specified by target
   * 
   */
  async hello() {
    const data = {
      type: 'answer',
      answer,
    }
    await this.notify_peers(data);
    this.output.data(data);
  }


  /**
   * 
   * @param {*} uid 
   * @param {*} entity_id 
   * @returns 
   */
  async entityInfo(uid, entity_id) {
    const self = this;
    let entity = {}
    entity = await self.yp.await_proc('forward_proc', uid, 'shareroom_contact_get', `'${entity_id}'`)
    if (!isEmpty(entity.contact_id)) {
      let tag = await self.yp.await_proc('forward_proc', uid, 'my_tag_get', `'${entity.contact_id}'`)
      if (!isArray(tag)) {
        tag = [tag]
      }
      entity.tag = map(tag, 'tag_id');

    }
    return entity;

  }

  /**
   * 
   * @param {*} input 
   * @param {*} my_id 
   * @param {*} hid_id 
   */
  async _logEvent() {
    let author_id
    let entity_id;
    let input = this.input.data() || {};
    let scope = input.scope;
    let target = input.target;
    let type = input.type;
    let role = input.role;
    let duration = input.duration || 0;
    let my;
    let his;
    let msg_type = 'call';
    let recipients;

    //this.debug("AAAAA:333", input, scope, type);
    if (!role || role != 'caller') return;
    if (!/^(cancel|leave|reject)$/.test(type)) return;

    let message_id = await this.yp.await_func('uniqueId');
    author_id = this.uid;
    entity_id = target.uid;

    my = author_id;
    his = entity_id;

    let acknowledge = {};
    acknowledge.message_id = message_id
    acknowledge.entity_id = entity_id
    acknowledge.uid = my


    let myinput = {
      message_id: message_id,
      author_id: author_id,
      entity_id: entity_id,
      metadata: {
        message_type: msg_type,
        call_status: type,
        duration: duration,
        role: 'caller'
      }
    };

    let mydata = await this.yp.await_proc('forward_proc', my,
      'channel_post_message_next',
      `'${stringify(myinput)}','${msg_type}'`
    );


    let hisinput = {
      message_id: message_id,
      author_id: author_id,
      entity_id: author_id,
      metadata: {
        message_type: msg_type,
        call_status: type,
        duration: duration,
        role: 'callee'
      }
    };
    //this.debug("AAAAA:383", hisinput);
    let hisdata = await this.yp.await_proc('forward_proc', his,
      'channel_post_message_next',
      `'${stringify(hisinput)}','${msg_type}'`
    );


    await this.yp.await_proc('forward_proc', my, 'acknowledge_message',
      `'${stringify(acknowledge)}'`
    );

    if (!isEmpty(mydata)) {
      mydata.entity = await this.entityInfo(my, entity_id);
      let mycount = await this.yp.await_proc('forward_proc', my,
        'count_yet_read_next', `'${my}','${his}'`
      );
      mydata.room = mycount.room
      mydata.total = mycount.total

      mydata.service = "chat.post";
      mydata.to_id = my;

      recipients = await this.yp.await_proc('user_sockets', mydata.to_id);
      await RedisStore.sendData(this.payload(mydata), recipients);
    }


    if (!isEmpty(hisdata)) {
      let hiscount = await this.yp.await_proc('forward_proc',
        his, 'count_yet_read_next', `'${his}','${my}'`
      );
      hisdata.entity = await this.entityInfo(entity_id, my);
      hisdata.service = "chat.post";
      hisdata.room = hiscount.room
      hisdata.total = hiscount.total
      hisdata.to_id = his;
      recipients = await this.yp.await_proc('user_sockets', hisdata.to_id);
      await RedisStore.sendData(this.payload(hisdata), recipients);
    }
  }

  /**
   * To broadcast signaling data to peers
   */
  async message() {
    let data = this.input.data();
    await this.notify_peers(data);
    try {
      await this._logEvent();
    } catch (e) {

    }
    this.output.data(data);
  }

  /**
   * To broadcast signaling data to peers
   * Same as message, but differently used by frontend
   */
  async notify() {
    let recipients = toArray(this.input.need(Attr.recipients), 1);
    let exclude = [this.input.need(Attr.socket_id)];
    let data = this.input.data();
    for (var i of recipients) {
      let recipients = await this.yp.await_proc('entity_sockets', { hub_id: i, exclude });
      await RedisStore.sendData(this.payload(data), recipients);
    }
    this.output.data(data);
  }
}


module.exports = __service_signaling;
