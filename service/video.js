// ================================  *
//   Copyright Xialia.com  2013-2017 *
//   FILE  : src/service/media
//   TYPE  : module
// ================================  *

const { Attr, utils } = require("@drumee/server-essentials");
const { isEmpty } = require('lodash');
const { toArray } = utils;
const Spawn = require("child_process").spawn;
const SPAWN_OPT = { detached: true, stdio: ["ignore", "ignore", "ignore"] };

const {
  Generator,
  FileIo,
  Mfs,
} = require("@drumee/server-core");
const {
  existsSync,
  createReadStream,
  statSync,
} = require("fs");
const { readdir } = require("fs/promises");

const { createInterface } = require("readline");
const events = require("events");
const { resolve } = require("path");

/**
 *
 */
async function walkDir(dirname, filterPattern) {
  let items = [];

  const walk = async (dir) => {
    try {
      const files = await readdir(dir);
      for (const file of files) {
        let realpath = resolve(dir, file);
        let stat = statSync(realpath);
        if (stat.isDirectory()) {
          await walk(realpath);
        } else {
          if (filterPattern && filterPattern.test(file)) {
            items.push(file);
          }
        }
      }
    } catch (err) {
      console.trace();
      console.error(err);
    }
  };
  await walk(dirname);
  return items;
}

class Video extends Mfs {

  /**
   * 
   * @returns 
   */
  waitForFile(path) {
    let count = 0;
    return new Promise((resolve, reject) => {
      if (existsSync(path)) {
        return resolve(path);
      }
      let timer = setInterval(async () => {
        count++;
        if (existsSync(path)) {
          clearInterval(timer);
          resolve(path);
          return;
        }
        if (count > 30) {
          clearInterval(timer);
          this.debug("FILE_WAIT_TIMEOUT", path)
          resolve(null);
        }
      }, 1000);
    });

  }

  /**
   * 
   */
  async sendContent(opt) {
    let { path, mimetype, filename, cwd } = opt;
    this.debug("AAAA:60 -- waitForFile", { path });
    path = await this.waitForFile(path);
    if (!path) {
      const fileio = new FileIo(this);
      return fileio.not_found(path);
    }

    const rl = createInterface({
      input: createReadStream(path),
      crlfDelay: Infinity,
    });

    let output = [];
    let { keysel } = this.input.authorization();
    rl.on("line", (line) => {
      if (/^(stream|segment)/.test(line)) {
        if (keysel) {
          line = `${line}?keysel=${keysel}`
        }
      }
      output.push(line);
    });
    await events.once(rl, "close");

    let str = output.join('\n');
    let streamFiles = await walkDir(cwd, /^.+\.ts$/);
    let count = 0;
    while (isEmpty(streamFiles) && count < 10) {
      streamFiles = await walkDir(cwd, /^.+\.ts$/);
      this.debug("AAAA:85", { streamFiles });
      count++;
      if(count > 10){
        this.debug("AAAA:124 -- too much attempts", { streamFiles });
        break;
      }
    }
    this.debug("AAAA:128", { streamFiles });

    this.output.response.setHeader("Content-Disposition", `attachment; filename="${filename}"`);
    this.output.response.setHeader("Content-Length", str.length);
    this.output.write(str, mimetype);
  }

  /**
   * 
   * @returns 
   */
  async master() {
    const node = this.granted_node();
    const cwd = resolve(node.mfs_root, node.id);
    let type = "master.m3u8";
    let path = resolve(cwd, type);
    if (!existsSync(path)) {
      let args = Generator.create_hls_args(node);
      this.debug("AAA:1447", { cwd }, args.join(' '));
      let child = Spawn("nice -n 10 /usr/bin/ffmpeg", args, {
        cwd,
        shell: true,
        detached: true,
        stdio: ["ignore", "ignore", "ignore"],
      });
      child.unref();
    }

    let opt = {
      filename: `${node.filename}-${type}`,
      path,
      cwd,
      mimetype: "application/x-mpegURL"
    }

    await this.sendContent(opt);
  }

  /**
   * Serve video stream
   * @returns  
   */
  async stream() {
    const node = this.granted_node();
    const serial = this.input.need("serial");
    const cwd = resolve(node.mfs_root, node.id);
    let path = resolve(cwd, `stream-${serial}`, "playlist.m3u8");
    let opt = {
      filename: `${node.filename}-stream-${serial}.m3u8`,
      path,
      cwd,
      mimetype: "application/x-mpegURL"
    }
    await this.sendContent(opt);
  }

  /**
   * 
   * @returns 
   */
  async segment() {
    const node = this.granted_node();
    const serial = this.input.need("serial");
    const seg = this.input.need("segment");
    const cwd = resolve(node.mfs_root, node.id);
    let filename = `${node.filename}-stream-${serial}-segment-${seg}.ts`;
    let segment = resolve(cwd, `stream-${serial}`, `segment-${seg}.ts`);
    const file = {
      name: filename,
      path: segment,
      mimetype: "video/MP2T",
      code: 200,
    };
    const fileio = new FileIo(this);
    if (existsSync(segment)) {
      return fileio.static(file);
    }
    fileio.not_found(segment);

  }

}


module.exports = Video;
