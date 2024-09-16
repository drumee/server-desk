
// ================================  *
//   Copyright Xialia.com  2013-2017 *
//   FILE  : src/service/private/poll
//   TYPE  : module
// ================================  *

const { Attr } = require("@drumee/server-essentials");
const Form = require('../form');

//########################################
class __private_form extends Form {

  /**
   * 
   * @param {*}  
   */
  async browse() {
    let page = this.input.get(Attr.page) || 1;
    let node = this.source_granted().node;
    let range = 20;
    let offset = range * (page - 1) ;
    let table = `form_${node.id}`;
    let sql = `SELECT * FROM ${table} ORDER BY ctime DESC LIMIT ${offset}, ${range}`;
    let data = await this.db.await_run(sql);
    this.output.data(data);
  }

}

module.exports = __private_form;
