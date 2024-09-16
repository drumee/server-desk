const { Attr, Constants } = require("@drumee/server-essentials");
const {
  PID,
  RECIPIENT_ID,
} = Constants;

const { Mfs } = require("@drumee/server-core");

const { isString } = require("lodash");
const { resolve } = require("path");
const SPAWN_OPT = { detached: true, stdio: ["ignore", "ignore", "ignore"] };
const Spawn = require("child_process").spawn;


class Exchange extends Mfs {

  /**
   * 
   */
  async server_import() {
    const self = this;
    async function f() {
      let socket_id = self.input.need(Attr.socket_id);
      let source_list = self.input.get("source_list") || ["/data/sample-1/"];
      let transactionid = self.input.need("transactionid");
      let pid = self.input.use(PID);
      if (pid == null) {
        pid = "0";
      }
      let recipient_id = self.input.use(RECIPIENT_ID) || self.hub.get(Attr.id);
      let args = {
        pid,
        recipient_id,
        source_list,
        uid: self.uid,
        socket_id,
        transactionid,
      };
      let cmd = resolve(
        process.env.server_home,
        "offline",
        "media",
        "serverimport.js"
      );
      console.log(`gopi cmd=${JSON.stringify(args)}`);
      let child = Spawn(cmd, [JSON.stringify(args)], SPAWN_OPT);
      child.unref();
      return args;
    }
    f()
      .then(function (r) {
        self.output.data(r);
      })
      .catch(self.fallback);
  }

  /**
   * 
   */
  async server_export() {
    const self = this;
    async function f() {
      let socket_id = self.input.need(Attr.socket_id);
      let dest_path = self.input.need("destination");
      let transactionid = self.input.need("transactionid");
      self.heap.nodes = self.heap.nodes || self.source_nodes(); //JSON.parse(this.src.args);
      self.heap.srcgrantlst = [];
      let granted = [];
      let node;
      for (var hub of self.heap.nodes) {
        if (isString(hub.nid)) {
          node = { nid: hub.nid, hub_id: hub.hub_id };
          granted.push(node);
        } else {
          for (let id of hub.nid) {
            node = { nid: id, hub_id: hub.hub_id };
            granted.push(node);
          }
        }
      }

      let args = {
        granted,
        dest_path,
        uid: self.uid,
        socket_id,
        transactionid,
      };
      let cmd = resolve(
        process.env.server_home,
        "offline",
        "media",
        "serverexport.js"
      );
      console.log(`gopi cmd=${JSON.stringify(args)}`);
      let child = Spawn(cmd, [JSON.stringify(args)], SPAWN_OPT);
      child.unref();
      return args;
    }
    f()
      .then(function (r) {
        self.output.data(r);
      })
      .catch(self.fallback);
  }
}

module.exports = Exchange;
