// ================================  *
//   Copyright Xialia.com  2013-2017 *
//   FILE  : src/service/private/contact
//   TYPE  : module
// ================================  *
const { Attr, Constants } = require("@drumee/server-essentials");

const Tag = require("../tag");
const { isEmpty } = require("lodash");


class __private_tag extends Tag {

  /**
   * 
   * @returns 
   */
  store() {
    const sys_id = this.input.use(Attr.serial, 0);
    let id = this.input.use(Attr.hashtag);
    if (isEmpty(id)) {
      id = this.input.need(Attr.id);
    }
    const lang = this.input.use(Attr.lang_code, "[]");
    const type = this.input.need(Attr.type);
    const name = this.input.need(Attr.name);
    const cb = function (data) {
      if (!isEmpty(data) && data.error === undefined) {
        this.output.data(data);
      } else if (!isEmpty(data) && data.error === Constants.ID_NOT_FOUND) {
        this.exception.user(Constants.INVALID_DATA);
      } else {
        this.exception.server(Constants.INTERNAL_ERROR);
      }
    }.bind(this);
    return this.db.call_proc("tag_save", sys_id, id, lang, type, name, cb);
  }

  /**
   * 
   * @returns 
   */
  delete() {
    const sys_id = this.input.need(Attr.serial);
    return this.db.call_proc("tag_delete", sys_id, this.output.data);
  }
}

module.exports = __private_tag;
