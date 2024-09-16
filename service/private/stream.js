
// ================================  *
//   Copyright Xialia.com  2013-2017 *
//   FILE  : src/service/private/drumate
//   TYPE  : module
// ================================  *

const { Attr } = require("@drumee/server-essentials");
const Media     = require('../media');

//########################################
class __private_stream extends Media {

  constructor(...args) {
    super(...args);
    this.create = this.create.bind(this);
  }

  /**
   * 
   * @returns 
   */
  async create() {
    const pid  = this.input.need(Attr.nid);
    const filename = this.input.need(Attr.name);
    if(_.isEmpty(filename)){
      this.exception.user('REQUIRE_NAME');
      return;
    }
    let args ={
      owner_id: this.uid,
      filename,
      pid,
      category: Attr.stream,
      ext: Attr.stream,
      mimetype: Attr.stream,
      filesize: 0,
      showResults :1
    };
    let results = { isOutput: 1 };
    await this.db.await_proc("mfs_create_node", args, {}, results);

  }

  /**
   * 
   */
  async open() {
    const pid     = this.source_granted().id || this.home_id;
    let filename = this.input.need(Attr.filename);
    let args ={
      owner_id: this.uid,
      filename,
      pid,
      category: Attr.stream,
      ext: Attr.stream,
      mimetype: Attr.stream,
      filesize: 0,
      showResults :1
    };
    let results = { isOutput: 1 };
    await this.db.await_proc("mfs_create_node", args, {}, results);
  }

}


module.exports = __private_stream;
