
// ================================  *
//   Copyright Xialia.com  2013-2017 *
//   FILE  : src/service/private/yp
//   TYPE  : module
// ================================  *

const { Attr } = require("@drumee/server-essentials");

const {Mfs} = require('@drumee/server-core');

//########################################
class __private_reminder extends Mfs {


  /**
   * 
   */
  async create() {
    let task = this.input.need('task');
    let data = await this.yp.await_proc('reminder_create', this.uid, task);
    this.output.data(data);
  }

  /**
   * 
   */
  async update() {
    const id = this.input.need(Attr.id);
    const task = this.input.need('task');
    let data = await this.yp.await_proc('reminder_update', id, task);
    this.output.data(data);
  }

  /**
   * 
   */
  async remove() {
    const id = this.input.need(Attr.id);
    await this.yp.await_proc('reminder_remove', { id });
    this.output.data({ id });
  }

  /**
   * 
   */
  async list() {
    let data = await this.yp.await_proc('reminder_list', this.uid);
    this.debug("AAA:66", data);
    this.output.list(data);
  }

  /**
   * 
   */
  async read() {
    let task = {
      id: this.input.get('reminder_id'),
      nid: this.input.get(Attr.nid),
      hub_id: this.input.get(Attr.hub_id),
      uid: this.uid,
    };

    task = await this.yp.await_proc('reminder_get', task);
    this.output.data(task);
  }

}

module.exports = __private_reminder;
