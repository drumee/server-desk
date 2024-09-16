
const { Attr } = require("@drumee/server-essentials");
const { Entity } = require('@drumee/server-core');

class __dmz extends Entity {


  /**
   * 
   */
  async live_message() {
    let message = this.input.get(Attr.message) || '';
    this.output({ message })
  }

  /**
   * 
   */
  async enter() {
    let message = this.input.get(Attr.message) || '';
    this.output({ message })
  }


}


module.exports = __dmz;