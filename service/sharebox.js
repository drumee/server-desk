const { isArray } = require("lodash");
const { Attr } = require("@drumee/server-essentials");
const { Mfs } = require("@drumee/server-core");

//########################################
class __sharebox extends Mfs {
  // ========================
  // Notification count
  // ========================
  constructor(...args) {
    super(...args);
    this.notification_count = this.notification_count.bind(this);
    this.notification_list = this.notification_list.bind(this);
    this.download = this.download.bind(this);
  }

  /**
   *
   */
  notification_count() {
    return this.output.data({});
  }


  /**
   *
   */
  notification_list() {
    return this.output.data({});
  }

  /**
   *
   */
  async download() {
    const nid = this.input.need(Attr.nid);
    const share_id = this.input.need(Attr.share_id);
    if (isArray(nid)) {
      return nid.map((id) => this.debug("zzzzzz", id));
    } else {
      const page = this.input.use(Attr.page) || 0;
      let r = await this.send_media(nid, Attr.folder);
      return r;
    }
  }
}

module.exports = __sharebox;
