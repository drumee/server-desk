// ================================  *
//   Copyright Xialia.com  2013-2017 *
//   FILE  : src/service/private/drumate
//   TYPE  : module
// ================================  *

const Media = require("../media");
const { Attr } = require("@drumee/server-essentials");


class __private_wicket extends Media {
  /**
   *
   */
  async create_external_meeting() {
    let lang = this.user.get(Attr.profile).lang || "en";
    const Moment = require("moment");
    Moment.locale(lang);
    let emails = this.input.need(Attr.emails);
    let title =
      this.input.use("title") ||
      Moment(Moment.now() / 1000, "X").format("LLLL");
    if (title.length > 100) {
      title = title.slice(0, 100);
    }
    let message = this.input.need(Attr.message);
    let args = {
      owner_id: this.uid,
      filename: title,
      pid: this.home_id,
      category: "schedule",
      ext: "",
      mimetype: "application/json",
      filesischeduleze: 0,
    };

    let results = { show: 1 };
    let node = await this.db.await_proc("mfs_create_node", args, {}, results);

    let r = await this.db.await_proc(
      "mfs_set_metadata",
      node.id,
      { content: { emails, title, message, room_id: node.id } },
      1
    );
    await this.db.await_proc("room_book", this.uid, node.id, "meeting");
    this.output.data(r);
  }
}

module.exports = __private_wicket;
