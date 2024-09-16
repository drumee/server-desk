
const { Attr } = require("@drumee/server-essentials");

/** =======================================  */
const Signaling = require('../signaling');
class __private_conference extends Signaling {


  async create() {
    let id = this.input.use(Attr.id);
    let device_id = this.input.need(Attr.device_id);
    let socket_id = this.input.need(Attr.socket_id);
    let room_type = this.input.need('room_type');
    let data = await this.db.await_proc('room_get', device_id, socket_id, this.uid, id, room_type);
    this.output.data(data);
  }
}




module.exports = __private_conference;
