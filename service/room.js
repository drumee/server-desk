
// ================================  *
//   Copyright Xialia.com  2013-2017 *
//   FILE  : src/lib/room
//   TYPE  : module
// ================================  *

const { isArray } = require('lodash');
const { Attr } = require('@drumee/server-essentials');
const { RedisStore, toArray, Cache } = require('@drumee/server-essentials');


/* ======================================= */
const __yp = require('./yp');
class __room extends __yp {

  /**
   * @param {*} uid 
   * @param {*} socket_id 
   * 
   */
  async get_or_create() {
    let id = this.input.use(Attr.id);
    let device_id = this.input.need(Attr.device_id);
    let socket_id = this.input.need(Attr.socket_id);
    let room_type = this.input.need('room_type');
    let data = await this.db.await_proc('room_get',
      device_id, socket_id, this.uid, id, room_type
    );
    this.output.data(data);
  }


  /**
   * @param {*} uid 
   * @param {*} socket_id 
   * 
   */
  async join() {
    let id = this.input.need(Attr.id);
    let sid = this.session.sid();
    let socket_id = this.input.need(Attr.socket_id);
    let device_id = this.input.need(Attr.device_id);
    let type = this.input.need(Attr.room_type);
    let server = this.input.get(Attr.endpointAddress) || Cache.getEnv(Attr.endpointAddress);
    let location = this.input.get(Attr.endpointRoute) || Cache.getEnv(Attr.endpointRoute);
    let data = await this.db.await_proc('room_get',
      device_id, socket_id, this.uid, id, type
    );
    data.wicket_id = this.hub.get(Attr.owner_id);
    let details = await this.db.await_proc('mfs_node_attr', id);
    data.area = this.hub.get(Attr.area);
    data.details = this.sanitize(details);
    let keys = 'wicket_id';

    let recipients = await this.yp.await_proc('user_sockets', this.hub.get(Attr.owner_id));
    await RedisStore.sendData(this.payload(data, { keys }), recipients);

    let attendees = await this.db.await_proc('room_attendees', id);
    data.attendees = attendees;
    this.output.data(data);
  }



  /**
* @param {*} uid 
* @param {*} socket_id 
* 
*/
  // async request_screen_access() {
  //   let parent_id = this.input.need(Attr.parent_id);
  //   let type = this.input.need(Attr.parent_type);
  //   let socket_id = this.input.need(Attr.socket_id);
  //   let device_id = this.input.need(Attr.device_id);
  //   let screen_id = this.input.need(Attr.screen_id);
  //   let data = await this.db.await_proc('room_get',
  //     device_id, socket_id, this.uid, parent_id, type
  //   );
  //   this.debug("AAA:90", data);
  //   if (this.hub.get(Attr.area) != Attr.private && data.permission & Permission.read) {
  //     data.type = 'screen';
  //     data.room_id = screen_id;
  //     data.role = Attr.listener;
  //     await this.db.await_proc('room_invite_next', JSON.stringify(data));
  //   }
  //   this.output.data(data);
  // }

  /**
 * @param {*} uid 
 * @param {*} socket_id 
 * 
 */
  async get_screen() {
    let parent_id = this.input.need(Attr.parent_id);
    let parent_type = this.input.need(Attr.parent_type);
    let socket_id = this.input.need(Attr.socket_id);
    let device_id = this.input.need(Attr.device_id);
    let screen_id = await this.yp.await_func('uniqueId');
    if (this.hub.get(Attr.area) != Attr.private) {
      await this.db.await_proc('permission_grant',
        screen_id, this.uid, 24, 15, 'no_traversal', socket_id
      );
      let peers = await this.db.await_proc('room_attendees', parent_id);
      if (!isArray(peers)) {
        peers = [peers];
      }
      this.debug("AAA:74 -- PEERS", peers);

      for (let r of peers) {
        r.type = 'screen';
        r.room_id = screen_id;
        r.socket_id = socket_id;
        if (r.user_id == this.uid) {
          r.role = Attr.presenter;
          await this.db.await_proc('room_invite_next', JSON.stringify(r));
        } else {
          r.role = Attr.listener;
          await this.db.await_proc('room_invite_next', JSON.stringify(r));
        }
      }
    }
    let data = await this.db.await_proc('room_get',
      device_id, socket_id, this.uid, screen_id, 'screen'
    );
    this.output.data(data);
  }

  /**
   * 
   */
  async hello() {
    this.debug("AAA:71", this.input.use(Attr.nid));
    await this.yp.await_proc('cookie_bind_guest',
      this.input.sid(),
      this.input.need(Attr.name)
    );
    this.output.data();
  }

  /**
   * @param {*} uid 
   * @param {*} socket_id 
   * 
   */
  async unified_room() {
    let flag = this.input.need(Attr.flag)
    let id = this.input.need(Attr.id)
    let uid = this.input.use(Attr.uid) || '';

    let is_mic_enabled;
    let is_video_enabled;
    let is_share_enabled;
    let is_write_enabled;
    let metadata = {}
    let data = []

    switch (flag) {
      case 'get':
        data = await this.yp.await_proc('get_unified_room', id, uid)
        break;
      case 'remove':
        data = await this.yp.await_proc('remove_unified_room', uid)
        break;
      case 'add':
        is_mic_enabled = this.input.get('is_mic_enabled') || 1
        is_video_enabled = this.input.get('is_video_enabled') || 0
        is_share_enabled = this.input.get('is_share_enabled') || 0
        is_write_enabled = this.input.get('is_write_enabled') || 0
        metadata = this.input.get('metadata') || {}
        data = await this.yp.await_proc('add_unified_room', id, uid, is_mic_enabled, is_video_enabled, is_share_enabled, is_write_enabled, metadata);
        break;
      case 'update':
        is_mic_enabled = this.input.need('is_mic_enabled')
        is_video_enabled = this.input.need('is_video_enabled')
        is_share_enabled = this.input.need('is_share_enabled')
        is_write_enabled = this.input.need('is_write_enabled')
        metadata = this.input.get('metadata') || {}
        data = await this.yp.await_proc('add_unified_room', id, uid, is_mic_enabled, is_video_enabled, is_share_enabled, is_write_enabled, metadata);
        break;
    }

    // if (!isArray(data)) {
    //   data = [data];
    // }

    this.output.list(data);
  }

  /**
   * 
   */
  async requestAccess() {
    let socket_id = this.input.need(Attr.socket_id);
    let room_id = this.input.need(Attr.room_id);
    let hub_id = this.input.need(Attr.hub_id);

    let r = await this.db.await_proc(`room_access`,
      socket_id, this.uid, room_id
    );
    if (!r || !r.permission) {
      this.debug("AAA:221", r.permission);
      this.exception.user("WEAK_PRIVILEGE OOOP");
      return;
    }

    let user = {
      avatar_id: r.avatar_id,
      deviceId: r.device_id,
      role: r.role,
      room_id: r.room_id,
      ssid: r.socket_id,
      uid: r.user_id,
      uname: r.username,
      username: r.username,
    }
    let presenter = await this.yp.await_proc('room_get_presenter', hub_id);
    let peers = await this.db.await_proc('room_attendees', room_id);
    peers = toArray(peers).filter(function (e) { return e.socket_id != socket_id });
    let presenter_id = null;
    if (presenter) presenter_id = presenter.presenter_id;
    //this.debug("AAA:219", hub_id, room_id, r, peers);
    let data = {
      presenter,
      peers,
      presenter_id,
      room_id: r.room_id,
      user,
      ssid: r.socket_id,
      status: r.status,
      peer: user
    }
    await this.pushUserOnlineStatus(2);
    if (r.role == 'presenter' && r.user_id == this.uid) {

      // let message = {
      //   content: {
      //     service: 'live.update',
      //     model: user,
      //     options: {
      //       keys: "*",
      //       service: 'meeting.start',
      //     }
      //   },
      // };
      let model = { ...user, type: "room.start" };
      await RedisStore.sendData(this.payload(model, { service: 'meeting.start' }), peers);

      // for (var p of peers) {
      //   message.dest = {
      //     service: 'live.update',
      //     type: Attr.socket,
      //     server: p.endpointAddress,
      //     socket_id: p.socket_id
      //   }

      //   let model = { ...p, type: "room.start" }
      //   this.debug("AAA:267", message);

      //   await RedisStore.notifySocket('notify_socket', message);
      // }

    }
    this.output.data(data);
  }

  /**
   * 
   */
  async shutdown() {
    let room_id = this.input.need(Attr.room_id);
    //this.debug("AAAA:285", this.hub.get(Attr.area));
    // if(/^(dmz)$/.test(this.hub.get(Attr.area))){
    //   await this.yp.await_proc('room_shutdown', room_id, this.uid);
    // }
    this.output.data({});
  }

  /**
   * 
   */
  async leave() {
    let socket_id = this.input.need(Attr.socket_id);
    let room_id = this.input.need(Attr.room_id);
    let hub_id = this.input.need(Attr.hub_id);
    let peers = await this.db.await_proc('room_leave_next', room_id, socket_id) || [];

    let data = await this.yp.await_proc('get_unified_room', room_id, this.uid);
    //this.debug("AAAA:291", data);
    let user = {
      avatar_id: this.uid,
      ssid: socket_id,
      socket_id,
      uid: this.uid,
    }

    let message = {
      content: {
        service: 'signaling.message',
        model: user,
        options: {
          keys: [Attr.room_id],
          service: 'signaling.message',
        }
      },
    };

    await this.pushUserOnlineStatus(1);

    peers = toArray(peers).filter(function (e) { return e.socket_id != socket_id });
    let model = { ...user, service: 'signaling.message', type: "room.leave" };
    let options = {
      keys: [Attr.room_id],
      service: 'signaling.message',
    };
    await RedisStore.sendData(this.payload(model, options), peers);

    this.output.data(data);
  }

}

module.exports = __room;

