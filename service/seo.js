// ================================  *
//   Copyright Xialia.com  2013-2017 *
//   FILE  : src/service/media
//   TYPE  : module
// ================================  *

const { Attr, utils } = require("@drumee/server-essentials");
const { isEmpty } = require('lodash');
const { toArray } = utils;


const { Mfs } = require('@drumee/server-core');

class __public_seo extends Mfs {

  async create() {
    const { node } = this.source_granted();
    if ([Attr.document, Attr.image].includes(node.filetype)) {
      const Document = require('@drumee/server-core/utils/document')();
      Document.buildIndex({ ...node, uid: this.uid });
      this.output.data(node);
    } else {
      this.output.data({});
    }
  }


  /**
   * 
   * @param {*} id 
   * @param {*} vcf 
   * @returns 
   */
  async find(id, vcf) {
    let nid = this.source_granted().id;
    const string = this.input.get(Attr.string) || '';
    const page = this.input.get(Attr.page) || 1;
    let words = string.split(/[ ,.;:!%@\/=\+-_\#]/).filter((e) => { return e.length });
    if (isEmpty(string)) {
      this.output.data([]);
      return;
    }
    let res = await this.db.await_proc('seo_search', JSON.stringify(words), page);
    let nodes = [];
    this.debug(' AAA', res);

    for (var r of toArray(res, 1)) {
      nodes.push(JSON.parse(r.node));
    }
    this.output.list(nodes);
  }
}


module.exports = __public_seo;
