
const { isArray, after, union, filter, isEmpty } = require('lodash');
const Media = require('../media');

const {
  Attr, Privilege, toArray,
  RedisStore, uniqueId, sysEnv
} = require("@drumee/server-essentials");

class __private_desk extends Media {

  /**
   * 
   * @param  {...any} args 
   */
  constructor(...args) {
    super(...args);
    this.pre_create = this.pre_create.bind(this);
    this.pre_copy = this.pre_copy.bind(this);
    this.get_env = this.get_env.bind(this);
    this.home = this.home.bind(this);
    this.create_hub = this.create_hub.bind(this);
    this.create_website = this.create_website.bind(this);
    this.leave_hub = this.leave_hub.bind(this);
    this.create_account = this.create_account.bind(this);
    this.get_workers = this.get_workers.bind(this);
    this.get_alternate_account = this.get_alternate_account.bind(this);
    this.reorder = this.reorder.bind(this);
  }

  /**
   * 
   * @param {*} opt 
   */
  initialize(opt) {
    const self = this;
    opt.session.hub = opt.session.user;
    super.initialize(opt);
  }


  /**
   * 
   */
  async limit() {
    let { mfs_dir } = sysEnv();
    let limit = await this.yp.await_proc('my_disk_limit', this.uid);
    if (global.myDrumee.arch == "pod" || limit.watermark == Infinity) {
      const diskSpace = require('check-disk-space').default;
      let df = await diskSpace(mfs_dir);
      limit.real = df.free;
      limit.quota_disk = df.free;
    }
    this.output.data(limit)
  }

  /**
   * 
   * @param {*} args 
   * @param {*} opt 
   */
  async _createHub(args, opt = {}) {
    const domain = this.user.get(Attr.domain);
    const owner_id = this.uid;
    let { hubname, area, filename } = args;
    if (!domain || !area) {
      this.warn("MAL_FORMED_DATA", { args }, { domain,  area });
      return this.exception.user("MAL_FORMED_DATA");
    }

    hubname = hubname || uniqueId();
    filename = filename || hubname;

    opt.lang = this.input.use(Attr.lang) || "en";
    const rows = await this.db.await_proc(
      `desk_create_hub`,
      { hubname, area, filename, owner_id, domain }, opt,
    );
    let hub_id, hub_db, home_id;
    for (let r of rows) {
      if (r && r.failed) {
        this.debug("Rows returned", rows)
        this.warn("Failed to create hub", { args, opt, rows });
        return {};
      }
      if (r.db_name && r.filesize && r.actual_home_id) {
        hub_db = r.db_name;
        home_id = r.actual_home_id;
      }
      if (r.db_name && r.home_dir) {
        hub_id = r.id;
      }
    }
    return { hub_id, hub_db, home_id }

  }

  /**
   * 
   * @returns 
   */
  async pre_create() {
    const { main_domain } = sysEnv();
    const domain = this.user.get(Attr.domain) || main_domain;
    const hubname = this.input.use(Attr.hubname) || uniqueId();
    const area = this.input.need(Attr.area, Attr.private);
    const folders = [];
    if (isArray(this.input.use('folders'))) {
      for (let path of this.input.use('folders')) {
        folders.push({ path });
      }
    }

    let limit = 0
    let hub_limit = await this.yp.await_proc('hub_limit', this.uid);
    let message = '_private_hub_limit_reached'
    if (area == 'private') {
      limit = hub_limit.available_private_hub - 1
    }
    if (area == 'share') {
      message = '_share_hub_limit_reached'
      limit = hub_limit.avaialable_share_hub - 1
    }

    let data = await this.yp.await_proc('hubname_exists', hubname, domain);
    if (limit < 0) {
      this.warn("HUB LIMIT REACHED", data);
      this.exception.user(message);
      return;
    }


    if (!isEmpty(data)) {
      this.warn("IDENT UNVAVAILABLE", data);
      this.exception.user('_ident_already_exists');
      return;
    }
    this._done();
  }

  /**
   * 
   */
  pre_copy() {
    const id = this.input.need(Attr.nid);
    const count = after(2, this._done);

    this.yp.call_proc('get_hub_owner', id, function (data) {
      if ((data == null) || (data.owner_id !== this.uid)) {
        this.exception.forbiden('Must be owner to make a copy');
        return;
      }
      if ([Attr.private, Attr.public].includes(data.area)) {
        this.heap.area = data.area;
        this.heap.hubname = this.input.use(Attr.hubname) || uniqueId();
        count();
      } else {
        this.exception.user(`Copying area ${data.area} is not allowed`);
        return;
      }

      this.yp.call_proc('get_hub', data.id, function (row) {
        this.heap.profile = row.profile;
        this.heap.profile.name = this.heap.profile.name + '-copy';
        return count();
      }.bind(this));
    }.bind(this));
  }


  /**
   * 
   */
  async get_env() {
    let data = await this.db.await_proc("desk_env");
    data.filenames = await this.db.await_proc('mfs_get_filenames', this.home_id);
    let disk = await this.yp.await_proc('my_disk_limit', this.uid);
    data.privilege = Privilege.OWNER;
    data.disk = disk;
    this.output.data(data);
  }

  /**
   * 
   */
  home() {
    const page = this.input.use(Attr.page, 1);
    const self = this;
    this.db.call_proc("mfs_show_node_by",
      self.home_id, this.uid, 'rank', 'asc', page,
      this.output.list
    );
  }

  /**
   * 
   */
  async export_vcf() {
    const self = this;
    function xlate(s, phones, addresses) {
      let lines = [
        `BEGIN:VCARD\n`,
        `VERSION:4.0\n`,
        `N:${s.firstname};${s.lastname};${s.surname};.;\n`,
        `FN:${s.fullname}\n`,
        `ORG:${s.organization}\n`,
        `TITLE:${s.title}\n`,
        `PHOTO;MEDIATYPE=image/gif:${s.avatar}\n`,
        `TEL;`,
        `ADR;`,
        `EMAIL:${s.email}\n`,
        `END:VCARD\n`,
      ];
      let r = [];
      let number, type, addr;
      for (let line of lines) {
        if (/^TEL/.test(line)) {
          for (let p of phones) {
            [number, type] = p.split('---');
            r.push(`TEL;TYPE=${type},voice;VALUE=uri:tel:${number}\n`);
          }
        } else if (/^ADR/.test(line)) {
          for (let a of addresses) {
            [addr, type] = a.split('---');
            try {
              let l = self.parseJSON(addr)
              r.push(`ADR;TYPE=${type};LABEL="${l.street}\n${l.city}\n${l.country}";;${l.street};${l.city};${l.country}\n`)
            } catch (e) {
              r.push(`ADR;TYPE=${type};LABEL=${addr}\n`)
            }
          }
        } else {
          r.push(line);
        }
      }
      r = union(r);
      return (filter(r, function (e) { return (!/undefined|null/.test(e)) }));
    }
    let rows = await this.db.await_proc('contact_export');
    rows = toArray(rows);
    let data = [];
    for (let row of rows) {
      let phones = [];
      if (row.phone) {
        phones = row.phone.split(/(:::)/);
      }
      let addresses = [];
      if (row.address) {
        addresses = row.address.split(/(:::)/);
      }
      data.push(xlate(row, phones, addresses));
    }
    return data;
  }

  /**
   * 
   */
  async backup() {
    this.export_vcf().then((vcf) => {
      this.download(this.home_id, vcf);
    })
  }


  /**
   * 
   * @returns 
   */
  async create_external_room() {
    let emails = this.input.need(Attr.email);
    const filename = this.input.need(Attr.filename);
    const permission = this.input.get(Attr.permission) || Privilege.UPLOAD;
    const pw = this.input.get(Attr.password) || '';
    const days = this.input.get(Attr.days) || 10;
    const hours = this.input.get(Attr.hours) || 0;
    const expiry = days * 24 + hours;

    let drumate;
    let email;
    let guest;
    let res = {};
    let share_id
    let home

    const hubname = uniqueId();
    share_id = this.randomString();

    if (!isArray(emails)) {
      emails = [emails];
    }

    for (email of emails) {
      drumate = await this.yp.await_proc('drumate_exists', email);
      if (!isEmpty(drumate)) {
        res.status = 'DRUMATE_EMAIL';
        return this.output.data(res)
      }
    }

    const args = { hubname, area: 'dmz', filename };
    let { home_id, hub_id } = await this._createHub(args);
    if (!hub_id) {
      res.status = 'CREATION_FAILED';
      return this.output.data(res)
    }

    const hub = await this.yp.await_proc("get_hub", hub_id);

    if (isEmpty(hub)) {
      res.status = 'CORRUPTED_HUB';
      return this.output.data(res);
    }

    await this.db.await_proc("mfs_move", hub.id, this.get(Attr.home_id))
    home = await this.yp.await_proc('forward_proc', hub.id, 'mfs_home', ``)

    let p = await this.yp.await_proc('forward_proc', hub.id, 'permission_grant',
      `'${home.home_id}','*' ,${expiry},${permission},'link','${share_id}'`);

    res = await this.yp.await_proc('forward_proc', hub.id, 'dmz_add_share',
      `'${share_id}', '${p.id}','${this.uid}','${hub.id}','${pw}'`);

    for (email of emails) {
      guest = await this.yp.await_proc('yp_add_guest', email, '', '', 0);
      await this.yp.await_proc('forward_proc', hub.id, 'dmz_add_map_share',
        `'${hub.id}', '${guest.id}'`);
    }
    let media = await this.db.await_proc("mfs_access_node", this.uid, hub.id);
    media.hub_id = media.id;
    media.privilege = media.permission;
    media.actual_home_id = home_id;
    await this.notify_user(this.uid, media);
    res.link = `${this.input.homepath(hub.vhost)}#/dmz/inbound/token=${share_id}`;
    this.output.data(res)
  }


  // ========================
  // Wicket is used to handle external meeting
  // It must be unique per drumate
  // ========================
  async create_wicket() {
    let media;
    let data = await this.db.await_proc("desk_env");
    if (data.wicket_id) {
      let hub = await this.yp.await_proc('get_entity', data.wicket_id);
      media = await this.db.await_proc(`${hub.db_name}.mfs_access_node`, this.uid, hub.home_id);
      this.output.data({ ...media, wicket_id: data.wicket_id });
      return;
    }
    const args = { area: 'dmz', filename: "wicket" };
    const options = { is_wicket: 1 };

    let { home_id, hub_id, hub_db } = await this._createHub(args, options);
    if (!hub_db) {
      return this.output.data({ status: 'CREATION_FAILED' })
    }
    media = await this.db.await_proc(`${hub_db}.mfs_access_node`, this.uid, home_id);
    this.output.data({ ...media, wicket_id: hub_id });
  }

  /**
   * 
   * @returns 
   */
  async create_website() {
    const { main_domain } = sysEnv();
    const pid = this.input.use(Attr.pid) || this.home_id;
    const hubname = this.input.need(Attr.hubname);
    const filename = this.input.need(Attr.filename);
    let fqdn = `${hubname}.${main_domain}`;
    let vhost = await this.yp.await_proc("vhost_exists", fqdn);
    if (!isEmpty(vhost)) {
      this.warn("AAA:512 -- ALREADY_EXIST", vhost, fqdn);
      this.exception.user(`ALREADY_EXIST`);
      return;
    }

    const args = { hubname, area: Attr.public, filename };
    let { home_id, hub_id } = await this._createHub(args);
    if (!hub_id) {
      return this.output.data({ status: 'CREATION_FAILED' })
    }

    const hub = await this.yp.await_proc("get_hub", hub_id);
    if (isEmpty(hub)) {
      this.exception.server("Corrupted hub");
      return;
    }

    if (pid && pid != this.get(Attr.home_id)) {
      await this.db.await_proc("mfs_move", hub.id, pid)
    }
    await this.yp.await_proc('hub_update_name', hub.id, filename);
    await this.yp.await_proc('change_vhost', hub.id, hubname);
    let media = await this.db.await_proc("mfs_access_node", this.uid, hub.id);
    media.hub_id = media.id;
    media.hubname = hubname;
    media.filename = filename;
    media.privilege = media.permission;
    media.actual_home_id = home_id;
    media.isalink = 1;
    let service = "media.new";
    let keys = { pid: Attr.nid, vhost: 'vhost' };
    let sockets = await this.yp.await_proc('entity_sockets', media.hub_id);
    await RedisStore.sendData(this.payload(media, { service, keys }), sockets);
    this.output.data(media);
  }


  /**
   * 
   * @returns 
   */
  async create_hub() {
    const pid = this.input.use(Attr.pid);
    const filename = this.input.need(Attr.filename);
    const area = this.input.need(Attr.area, Attr.private);
    let hubname = this.input.get(Attr.hubname) || uniqueId();
    const args = { hubname, area, filename };
    let { home_id, hub_id } = await this._createHub(args);
    if (!hub_id) {
      return this.output.data({ status: 'CREATION_FAILED' })
    }
    const hub = await this.yp.await_proc("get_hub", hub_id);
    if (isEmpty(hub)) {
      this.exception.server("Corrupted hub");
      return;
    }
    if (pid && pid != this.get(Attr.home_id)) {
      await this.db.await_proc("mfs_move", hub.id, pid)
    }
    await this.yp.await_proc('hub_update_name', hub.id, filename);
    let media = await this.db.await_proc("mfs_access_node", this.uid, hub.id);
    media.hub_id = media.id;
    media.filename = filename;
    media.hubname = hubname;
    media.privilege = media.permission;
    media.actual_home_id = home_id;
    media.isalink = 1;
    media.ownpath = '/';
    let sockets = await this.yp.await_proc('entity_sockets', media.hub_id);
    await RedisStore.sendData(this.payload(media), sockets);
    this.output.data(media);
  }

  /**
   * 
   * @param {*} s 
   * @param {*} status 
   * @returns 
   */
  async set_online_status() {
    let r = await this.pushUserOnlineStatus();
    let status = 0;
    if (r && r[0]) status = r[0].my_state;
    this.output.data({ hub_id: this.uid, user_id: this.uid, status });

  }


  /**
   * 
   */
  async leave_hub() {
    const hub_id = this.input.use(Attr.nid);
    let sockets = await this.yp.await_proc('user_sockets', this.uid);
    let payload = { ...this.granted_node(), reason: 'leave', uid: this.uid };
    payload = this.payload(payload, { loopback: 1 });
    await RedisStore.sendData(payload, sockets);
    await this.db.await_proc('leave_hub', hub_id);
    this.output.data({ uid: this.uid, hub_id });
  }


  /**
   * The account schema is picked from the pool of hubs that are already created by offline process 
   */
  create_account() {
    const h = this.heap;
    const pw = this.input.need(Attr.password);

    this.yp.call_proc("drumate_create", pw, h.profile, (e, d, f) => {
      let error = 0;
      for (let r of d) {
        if (r[0] != null ? r[0].failed : undefined) {
          error = ~~(r[0] != null ? r[0].failed : undefined);
        }
      }
      if (error) {
        this.exception.user("Failed to create account", "desk_create_drumate failed");
      } else {
        this.yp.call_proc("get_visitor", h.ident, this.output.data);
      }
    });
  }

  /**
   * 
   */
  get_workers() {
    this.yp.call_proc("get_workers", this.uid, this.output.data);
  }



  /**
   * 
   */
  get_alternate_account() {
    this.yp.call_proc("get_alternate_account", this.uid, this.output.data);
  }

  /**
   * 
   * @returns 
   */
  reorder() {
    const list = this.input.use(Attr.list);
    const cb = () => {
      this.output.data(list);
    };

    const count = after(list.length, cb);

    return (() => {
      const result = [];
      for (let item of list) {
        this.db.call_proc('mfs_update_rank', item.nid, item.index);
        result.push(count());
      }
      return result;
    })();
  }
}

module.exports = __private_desk;
