
// ================================  *
//   Copyright Xialia.com  2013-2017 *
//   FILE  : src/service/contact
//   TYPE  : module
// ================================  *

const { Entity } = require('@drumee/server-core');
const { Attr } = require("@drumee/server-essentials");

//########################################
class __contact extends Entity {

  constructor(...args) {
    super(...args);
    this.invite_status = this.invitation_status.bind(this);
  }

  /**
   * 
   */
  invitation_status() {
    let token = this.input.need(Attr.token);
    let uid = this.input.use(Attr.uid);
    this.yp.call_proc('contact_invitation_status', token, uid, this.output.data);
  }

}



module.exports = __contact;