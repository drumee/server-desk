// ================================  *
//   Copyright Xialia.com  2013-2017 *
//   FILE  : src/service/private/contact
//   TYPE  : module
// ================================  *


const { Attr } = require("@drumee/server-essentials");
const { stringify } = JSON;
const { isArray } = require("lodash");

/**  ============================== */
const Contact = require("../contact");
class __private_blacklist extends Contact {

  /**
   * 
   * @returns 
   */
  add() {
    let email = this.input.need(Attr.email);
    if (!isArray(email)) {
      email = [email];
    }
    const json = stringify(email);
    return this.db.call_proc("blacklist_add", json, this.output.data);
  }

  /**
   * 
   * @returns 
   */
  delete() {
    let email = this.input.need(Attr.email);
    if (!isArray(email)) {
      email = [email];
    }
    this.db.call_proc("blacklist_delete", email, this.output.data);
  }

  /**
   * 
   * @returns 
   */
  show() {
    const page = this.input.use(Attr.page) || 1;
    this.db.call_proc("blacklist_show", page, this.output.data);
  }
}

module.exports = __private_blacklist;
