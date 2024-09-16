const Media    = require('./private/media');

//########################################
class __sharebox extends Media {

// ========================
// 
// ========================  
  constructor(...args) {
    super(...args);
    this.get_share_box = this.get_share_box.bind(this);
  }

  get_share_box() {
    return this.output.data({});
  }
}

module.exports = __sharebox;