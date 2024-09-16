// ================================  *
//   Copyright Xialia.com  2013-2017 *
//   FILE  : src/service/private/chat
//   TYPE  : module
// ================================  *

const { Attr, nullValue } = require("@drumee/server-essentials");
const {keys} = require("lodash");


/**
 *
 */
const { Entity } = require("@drumee/server-core");
class __private_notification extends Entity {
  constructor(...args) {
    super(...args);
    this.clear_all = this.clear_all.bind(this);
  }

  /**
   * To clear notifications
   * @params {array} nodes    - list of mfs nodes to be reset
   * @params {array} messages - list of mfs nodes to be reset
   */
  async clear_all() {
    const nodes = this.input.need(Attr.nodes) || [];
    const messages = this.input.need(Attr.messages) || [];
    let hubs;
    hubs = keys(nodes);
    for (let n of hubs) {
      if (nullValue(n)) continue;
      let hub = await this.yp.await_proc("get_hub", n);
      let json = JSON.stringify(nodes[n]);
      if (hub.db_name) {
        await this.yp.await_proc(
          `${hub.db_name}.mfs_clear_notifications`,
          json,
          this.uid
        );
      }
    }
    hubs = keys(messages);
    for (let n of hubs) {
      if (nullValue(n)) continue;
      let hub = await this.yp.await_proc("get_hub", n);
      if (hub.db_name) {
        await this.yp.await_proc(
          `${hub.db_name}.channel_clear_notifications`,
          this.uid
        );
      }
    }
    this.output.list(nodes);
  }
}

module.exports = __private_notification;
