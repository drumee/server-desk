
// ================================  *
//   Copyright Xialia.com  2013-2017 *
//   FILE  : src/service/private/contact
//   TYPE  : module
// ================================  *

const { Attr } = require("@drumee/server-essentials");
const { Entity } = require('@drumee/server-core');
const { isEmpty } = require('lodash');

//########################################
class __private_addressbok extends Entity {

  /**
   * 
   * @returns 
   */
  add() {
    let phone;
    const email = this.input.need(Attr.email);
    const name = this.input.need(Attr.name);
    phone = this.input.use(Attr.phone);
  }

  /**
   * 
   * @returns 
   */
  delete() {
    const id = this.input.use(Attr.id) || this.input.need(Attr.email);
    this.db.call_proc('drumate_delete_contact', id, this.output.data);
  }

  /**
   * 
   * @returns 
   */
  search() {
    const name = this.input.use(Attr.name, "");
    const page = this.input.use('page', 1);
    if (isEmpty(name)) {
      this.output.data([]);
      return;
    }
    this.db.call_proc('search_my_contacts', name, page, this.output.data);
  }

  /**
   * 
   * @returns 
   */
  search_personal_contacts() {
    const name = this.input.use(Attr.name, "");
    const page = this.input.use('page', 1);
    if (isEmpty(name)) {
      this.output.data([]);
      return;
    }
    this.db.call_proc('search_personal_contacts', name, page, this.output.data);
  }

  /**
   * 
   * @returns 
   */
  search_all_contacts() {
    const name = this.input.use(Attr.name, "");
    const page = this.input.use('page', 1);
    if (isEmpty(name)) {
      this.output.data([]);
      return;
    }
    this.db.call_proc('search_all_contacts', name, page, this.output.data);
  }
}


module.exports = __private_addressbok;