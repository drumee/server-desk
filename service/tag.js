
// ================================  *
//   Copyright Xialia.com  2013-2017 *
//   FILE  : src/service/tag
//   TYPE  : module
// ================================  *

const { Attr } = require("@drumee/server-essentials");

/** =============================================== ** */
const { Entity } = require('@drumee/server-core');
class __tag extends Entity {

  initialize(opt) {
    this._start_with = 'block_home';
    super.initialize(opt);
  }


  /**
   * 
   * @returns 
   */
  list() {
    const page = this.input.use(Attr.page, 1);
    let lang = this.input.use('Xlang') || this.lang();
    if (['zh', 'fr', 'en'].includes(lang)) {
      lang = lang;
    } else {
      lang = 'en';
    }
    return this.db.call_proc('tag_list_by_lang', lang, page, this.output.data);
  }

  /**
   * 
   * @returns 
   */
  get_by_name() {
    const page = this.input.use(Attr.page, 1);
    const name = this.input.need(Attr.name);
    return this.db.call_proc('tag_get_by_name', name, page, this.output.data);
  }
}

module.exports = __tag;