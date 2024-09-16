
// ================================  *
//   Copyright Xialia.com  2013-2017 *
//   FILE  : src/service/hub
//   TYPE  : module
// ================================  *
const { Attr, sysEnv } = require("@drumee/server-essentials");
const { main_domain } = sysEnv()
const { Entity } = require('@drumee/server-core');


//########################################
class __history extends Entity {
  /**
   * 
   */
  logo() {
    let icon = this.hub.get(Attr.icon) || '';
    let vhost = this.hub.get(Attr.vhost) || main_domain;
    let url = icon;
    if (/^\//.test(icon)) {
      url = `https://${vhost}${icon}`
    } else if (!/^http/.test(icon)) {
      url = `https://${icon}`;
    }
    this.output.data({ url });
  }

  /**
   * 
   */
  login_image() {
    this.db.call_proc('hub_get_login_image', user_id, page, this.output.list);
  }

}


module.exports = __history;
