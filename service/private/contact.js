
const { Attr, Constants, Messenger, utils, RedisStore, Cache } = require("@drumee/server-essentials");
const { EMAIL_CHECKER } = Constants;

const { readFileSync } = require('fs');
const vCard = require("vcf");
const { stringify } = JSON;
const { isEmpty, isArray } = require('lodash');
const { google } = require("googleapis");

const { toArray } = utils;

/** ==============================================  */
const Contact = require('../contact');
class __private_contact extends Contact {

  /**
   * 
   * @param  {...any} args 
   */
  constructor(...args) {
    super(...args);
    this.google_auth = this.google_auth.bind(this);
    this.send_mail = this.send_mail.bind(this);
    this.add = this.add.bind(this);
    this.update = this.update.bind(this);
    this.show_contact = this.show_contact.bind(this);
    this.delete_contact = this.delete_contact.bind(this);
    this.delete_contact_address = this.delete_contact_address.bind(this);
    this.delete_contact_email = this.delete_contact_email.bind(this);
    this.delete_contact_phone = this.delete_contact_phone.bind(this);
    this.get_contact = this.get_contact.bind(this);

    this.invite_refuse = this.invite_refuse.bind(this);
    this.invite_accept = this.invite_accept.bind(this);
    this.invite_get = this.invite_get.bind(this);
    this.invite_count = this.invite_count.bind(this);
    this.accept_informed = this.accept_informed.bind(this);

    this.show = this.show.bind(this);
    this.seek = this.seek.bind(this);

    this.delete = this.delete.bind(this);

    this.search = this.search.bind(this);

    this.join = this.join.bind(this);
    this.block = this.block.bind(this);
    this.unblock = this.unblock.bind(this);

    this.change_status = this.change_status.bind(this);

    this.authclient = this.authclient.bind(this);
    this.auth_Url = this.auth_Url.bind(this);

  }

  /**
   * 
   * @param {*} socket 
   */
  async _updateProgres(socket) {
    let socket_id = this.input.get(Attr.socket_id);
    if (!socket_id) {
      this.warn("No socket_id was provided");
      return;
    }
    if (!this._loadResult) {
      this.warn("No pending result");
      return;
    }
    if (!this._pendingLoad || !this._pendingLoad.model) {
      this.warn("No pending load");
      return;
    }
    let result = this._loadResult;
    result.loaded++;

    let progress = Math.ceil(result.loaded * 100 / result.total);
    if (this._pendingLoad.model.progress == progress) return;
    this._pendingLoad.model.progress = progres;
    this.debug("AAA:220", progress, progress % 5, result.loaded);
    await RedisStore.sendData(this._pendingLoad, socket_id);
  }

  /**
   * 
   * @param {*} filename 
   * @param {*} socket 
   */
  async parseVcfTest(filename, socket) {
    var vCard = require('vcard');
    var card = new vCard();
    /* Use readFile() if the file is on disk. */
    card.readFile(filename, (err, item) => {
      this.debug("parseVcfTest  -- ", item);
      for (var k in item) {
      }
    });
    return {};
  }

  /**
   * 
   */
  async parseVcf(filename, socket) {
    var data = readFileSync(filename);
    let result = this._loadResult;
    let res = {};


    try {
      var cards = vCard.parse(data);
      result.total = cards.length
      result.loaded = 0
      for (let i = 0; i < cards.length; i++) {
        var card = new vCard().parse(cards[i].toString())
        res = JSON.parse(JSON.stringify(card.data))
        if (!isEmpty(res.email)) {
          let metadata = {};

          let tempemail;
          if (!isArray(res.email[0])) {
            tempemail = [res.email];
          } else { tempemail = res.email }
          let email = [];
          let default_email;
          for (let i = 0; i < tempemail.length; i++) {
            if (i == 0) { default_email = (tempemail[i])[3] }
            let tempjson = {
              email: (tempemail[i])[3],
              is_default: (i == 0 ? 1 : 0),
              category: 'prof'
            }
            email.push(tempjson)
          }

          let entity = email[0].email;
          let drumate = await this.yp.await_proc('drumate_exists', entity);
          //metadata.source = entity;
          metadata = { source: entity, imported: this.session.timestamp };
          entity = drumate.id || entity;

          let mycontact = await this.db.await_proc('my_contact_exists', 'entity', entity, null, null);

          if (isEmpty(mycontact)) {

            let a = default_email.split('@');
            a[1] = a[0]
            if (a[0].indexOf('.') !== -1) {
              a = a[0].split('.');
            }
            let firstname = a[0]
            let lastname = a[1]
            let name;

            if (!isEmpty(res.n)) {
              name = res.n[3]
              firstname = name[1]
              lastname = name[0]
            }

            let tempmobile;
            let mobile = [];
            if (!isEmpty(res.tel)) {
              if (!isArray(res.tel[0])) {
                tempmobile = [res.tel];
              } else { tempmobile = res.tel }

              for (let i = 0; i < tempmobile.length; i++) {
                let tempjson = {
                  areacode: '',
                  phone: (tempmobile[i])[3],
                  category: 'prof'
                }
                mobile.push(tempjson)
              }
            }

            let tempaddr;
            let address = [];
            if (!isEmpty(res.adr)) {
              if (!isArray(res.adr[0])) {
                tempaddr = [res.adr];
              } else { tempaddr = res.adr }

              for (let i = 0; i < tempaddr.length; i++) {
                let tempjson = {
                  street: ((tempaddr[i])[3])[2],
                  city: ((tempaddr[i])[3])[3] + ' ' + ((tempaddr[i])[3])[4],
                  country: ((tempaddr[i])[3])[6],
                  category: 'prof'
                }
                address.push(tempjson)
              }
            }
            let contact = await this.db.await_proc('my_contact_add_next', entity, null, firstname, lastname, 'independant', null, null, metadata);
            await this._add(contact.id, email, mobile, address, []);
            result.loaded = result.loaded + 1
          } else {
            result.alreadyincontact++;
          }
        } else {
          result.noemail++;
        }
        this._updateProgres(socket);
      }
      this.output.data(result);
    } catch (e) {
      this.exception.user('Invlid_data', result);
    }
    return null;
  }

  /**
   * 
   * @param {*} filename 
   * @returns 
   */
  async parseCsv(filename, socket) {
    const Csv = require('csvtojson');
    const data = await Csv().fromFile(filename);
    this._loadResult.total = data.length;
    let k, v;
    let result = this._loadResult;
    for (var item of data) {
      let address = {};
      let directory = null;
      let cur_addr_key = '';
      let r = {
        email: [],
        address: [],
        phone: [],
      };
      for (k in item) {
        v = item[k];
        if (/^.+ type$/i.test(k)) continue;
        if (isEmpty(v)) continue;
        if (/^e[-]*mail/i.test(k)) {
          this.debug(`AAA:264 k="${k}" v="${v}"`);
          if (!isEmpty(v) && v.isEmail()) {
            let e = {
              email: v,
              category: 'prof'
            };
            if (isEmpty(r.email)) {
              e.is_default = 1;
            } else {
              e.is_default = 0;
              e.category = 'priv';
            }
            r.email.push(e);
          }
          continue;
        }
        if (/^(directory)/i.test(k)) {
          directory = v;
          continue;
        }
        if (/^(address|location)/i.test(k)) {
          //this.debug(`AAA:280 k="${k}" v="${v}"`);
          if (isEmpty(v)) continue;
          if (!address[k]) {
            address[k] = [v];
          } else {
            address[k].push(v);
          }
          continue;
        }
        if (/^(phone|mobile)/i.test(k)) {
          let p = {
            phone: v,
            areacode: '',
            category: 'prof'
          };
          if (/^ *\+/.test(v)) {
            v = v.split(/[ -.:;_]+/);
            if (isEmpty(v[0])) v.shift();
            p.areacode = `+${v[0]}`;
            v.shift();
            p.phone = v.join(' ');
          }
          if (isEmpty(r.phone)) {
            p.is_default = 1;
          } else {
            p.is_default = 0;
            p.category = 'priv';
          }
          r.phone.push(p);
          continue;
        }
        if (/^(first|given) *name/i.test(k)) {
          r.firstname = v;
          continue;
        }
        if (/^(last|family) *name/i.test(k)) {
          r.lastname = (v);
          continue;
        }
        if (/^(additionnal|middle) *name/i.test(k)) {
          r.surname = (v);
          continue;
        }
      }
      for (k in address) {
        v = address[k];
        if (isEmpty(v)) continue;
        let a = {
          street: v.join(),
          city: '',
          category: 'priv',
          country: '',
        };
        if (v.length == 1) {
          if (/,/.test(v[0])) {
            let x = v[0].split(',');
            a.country = x.pop();
            a.city = x.pop()
            if (x != null) a.street = x.join();
          }
        } else {
          a.country = v.pop();
          a.city = v.pop()
          if (v != null) a.street = v.join();
        }
        if (isEmpty(r.address)) {
          a.is_default = 1;
        } else {
          a.is_default = 0;
          a.category = 'priv';
        }
        r.address.push(a);
      }
      if (isEmpty(r) || isEmpty(r.email)) {
        result.noemail++;
      } else {
        this.debug("RES:", r);
        let entity = r.email[0].email;
        let drumate = await this.yp.await_proc('drumate_exists', entity);
        let metadata = { source: entity, imported: this.session.timestamp };
        if (directory) metadata.photo = directory;
        //metadata.source = entity;
        entity = drumate.id || entity;

        let mycontact = await this.db.await_proc('my_contact_exists', 'entity', entity, null, null);
        if (isEmpty(mycontact)) {
          let contact = await this.db.await_proc('my_contact_add_next',
            entity, r.surname, r.firstname, r.lastname, 'independant', null, null, metadata);
          await this._add(contact.id, r.email, r.phone, r.address, []);
        } else {
          result.alreadyincontact++;
        }
      }
      this._updateProgres(socket);
    }
    return result;
  }

  /**
   * 
   */
  async load() {
    let filename;
    let socket_id = this.input.need(Attr.socket_id);
    let service = this.input.get(Attr.service);
    this._loadResult = {
      total: 0,
      loaded: 0,
      noemail: 0,
      alreadyincontact: 0,
    }

    let uploaded_file_id = this.input.get(Attr.uploaded_id);
    let file_id = this.input.get(Attr.secret);
    if (isEmpty(file_id) && isEmpty(uploaded_file_id)) {
      result.error = 'NO_FILE';
      return this.exception.user('NO_FILE');
    }

    if (!isEmpty(file_id) && !isEmpty(uploaded_file_id)) {
      result.error = 'INVALID_INPUT';
      return this.exception.user('NO_FILE');
    }


    if (!isEmpty(uploaded_file_id)) {
      file_id = uploaded_file_id
    }

    filename = `${process.env.DRUMEE_TMP_DIR}/${file_id}`;
    let options = {
      tag: service,
      service,
      message: 'PREPARE_CONTACT'
    }
    this._pendingLoad = this.payload({ phase: "prepare", progress: 0 }, options);
    await RedisStore.sendData(this._pendingLoad, socket_id);

    let data;
    if (/\.csv$/i.test(filename)) {
      data = await this.parseCsv(filename, opt.socket);
    } else if (/\.vcf$/i.test(filename)) {
      data = await this.parseVcf(filename, opt.socket);
    } else {
      this.exception.user('WRONG_FORMAT');
      return;
    }

    this.output.data(data);
  }


  /**
   * 
   * @param {*} callback 
   * @param {*} code 
   * @returns 
   */
  async authclient(callback, code) {
    const client_secret = Cache.getSysConf('google_client_secret');
    const client_id = Cache.getSysConf('google_client_id');
    let host = (await this.user.organization()).link || process.env.domain_name;
    const redirect_uris = this.input.servicepath({ service: 'butler.google_callback' });
    const oAuth2Client = new google.auth.OAuth2(client_id, client_secret, redirect_uris)
    return callback(oAuth2Client, code);
  }

  /**
   * 
   * @param {*} oAuth2Client 
   * @returns 
   */
  async auth_Url(oAuth2Client) {
    const SCOPES = [
      "https://www.googleapis.com/auth/contacts.readonly",
    ].join(" ")
    const state = await this.yp.await_func("uniqueId");
    const statejson = {
      source: 'contact', sid: this.session.sid(), host: this.input.host(), uid: this.uid
    }
    await this.yp.await_proc('set_redirect_state', state, JSON.stringify(statejson));
    const authUrl = oAuth2Client.generateAuthUrl({
      access_type: 'offline', scope: SCOPES,
      state: state
    });
    return (authUrl)
  }


  /**
   * 
   */
  async google_auth() {
    let url = await this.authclient(this.auth_Url);
    console.log("AAA:490", url);
    this.output.data({ url });
  }

  /**
   * 
   * @param {*} email 
   * @param {*} message 
   * @param {*} token 
   * @returns 
   */
  async send_mail(email, message, token) {

    const username = this.user.get(Attr.fullname);
    message = this.input.use(Attr.message) || '';

    let recipient_name = this.input.use(Attr.firstname) || email.replace(/@.+$/, '');
    const lang = this.user.language() || this.input.app_language();
    const subject = `${Cache.message('_network_non_drumate_subject', lang).format(username)}`;

    const link = `${this.input.homepath()}#/welcome/invitation/${token}`;
    const loginlink = `${this.input.homepath()}#/welcome`;
    const msg = new Messenger({
      template: "butler/invite-non-drumate",
      subject,
      recipient: email,
      lex: Cache.lex(lang),
      data: {
        //username   : username
        firstname: this.user.get('firstname'),
        sender: this.user.get('fullname'),
        recipient: recipient_name,
        link: link,
        redirect_link: loginlink,
        message,
      },
      handler: this.exception.email
    });
    return msg.send();
  }



  /**
   * 
   * @param {*} email 
   * @param {*} message 
   */
  async send_drumate_mail(email, message, vhost) {

    const username = this.user.get(Attr.fullname);
    message = this.input.use(Attr.message) || '';

    let recipient_name = this.input.use(Attr.firstname) || email.replace(/@.+$/, '');
    const lang = this.user.language() || this.input.app_language();
    const subject = `${Cache.message('_network_message', lang)
      .format(username)}`;

    const link = `${this.input.homepath(vhost)}#`;
    const msg = new Messenger({
      template: "butler/invite-drumate",
      subject,
      recipient: email,
      lex: Cache.lex(lang),
      data: {
        firstname: this.user.get('firstname'),
        sender: this.user.get('fullname'),
        recipient: recipient_name,
        link: link,
        redirect_link: link,
        message: message,
      },
      handler: this.exception.email
    });
    return msg.send();
  }


  /**
   * 
   */
  show_contact() {
    const tag_id = this.input.use(Attr.tag_id, '');
    const name = this.input.use(Attr.name, Attr.name);
    const order = this.input.use(Attr.order, 'asc');
    const page = this.input.use(Attr.page) || 1;
    const option = this.input.use(Attr.option) || 'active';
    this.db.call_proc('my_contact_show_next',
      tag_id, name, order, option, page, this.output.list
    );
  }

  /**
   * 
   */
  async delete_contact() {
    const contact_id = this.input.need(Attr.contact_id);
    let res = {};
    let mycontact = await this.db.await_proc('my_contact_get_next', contact_id, null)
    mycontact.contact_id = mycontact.id
    res = await this.db.await_proc('my_contact_delete', contact_id);
    if (!isEmpty(res)) {
      let sockets = await this.yp.await_proc('user_sockets', res.his_id);
      await RedisStore.sendData(this.payload(res), sockets);
    }
    let sockets = await this.yp.await_proc('user_sockets', this.uid);
    await RedisStore.sendData(this.payload(mycontact), sockets);
    this.output.data(res);
  }


  /**
   * 
   */
  delete_contact_address() {
    const contact_id = this.input.need(Attr.contact_id);
    const address_id = this.input.need(Attr.address_id);
    this.db.call_proc('my_contact_address_delete', contact_id, address_id, this.output.data);
  }

  /**
   * 
   */
  delete_contact_email() {
    const contact_id = this.input.need(Attr.contact_id);
    const email_id = this.input.need(Attr.email_id);

    this.db.call_proc('my_contact_default_chk', email_id, this.heap.contact_id, function (data) {
      if (!isEmpty(data)) {
        this.exception.user("Default email");
        return;
      } else {
        this.db.call_proc('my_contact_mail_delete', contact_id, email_id, this.output.data);
      }
    }.bind(this));
  }

  /**
   * 
   */
  delete_contact_phone() {
    const contact_id = this.input.need(Attr.contact_id);
    const phone_id = this.input.need(Attr.phone_id);
    this.db.call_proc('my_contact_phone_delete', contact_id, phone_id, this.output.data);
  }

  /**
   * 
   */
  async get_contact() {
    const contact_id = this.input.need(Attr.contact_id);
    let r = await this._show(contact_id);
    this.output.data(r);
  }

  /**
   * 
   * @param {*} contact_id 
   * @returns 
   */
  async _show(contact_id) {
    let res = {};
    let data = await this.db.await_proc('my_contact_get_next', contact_id, null)
    if (!isEmpty(data)) {
      res = data;
    }
    data = await this.db.await_proc('my_contact_mail_get', contact_id)
    data = toArray(data);
    if (data) {
      res.email = data;
    }

    data = await this.db.await_proc('my_contact_address_get', contact_id)
    data = toArray(data);
    if (data) {
      res.address = data;
    }

    data = await this.db.await_proc('my_contact_phone_get', contact_id)
    data = toArray(data);
    if (data) {
      res.mobile = data;
    }
    data = await this.db.await_proc('my_tag_get', contact_id)
    data = toArray(data);
    if (data) {
      res.tag = data;
    }

    return res;

  };

  /**
   * 
   * @param {*} contact_id 
   * @param {*} email 
   * @param {*} mobile 
   * @param {*} address 
   * @param {*} tag 
   */
  async _add(contact_id, email, mobile, address, tag) {
    await this.db.await_proc('my_contact_mail_add', contact_id, stringify(email))
    await this.db.await_proc('my_contact_phone_add', contact_id, stringify(mobile))
    await this.db.await_proc('my_contact_address_add', contact_id, stringify(address))
    await this.db.await_proc('my_tag_add', contact_id, stringify(tag))
  }

  /**
   * 
   * @param {*} contact_id 
   */
  async _delete(contact_id) {
    await this.db.await_proc('my_contact_mail_delete', contact_id, null)
    await this.db.await_proc('my_contact_phone_delete', contact_id, null);
    await this.db.await_proc('my_contact_address_delete', contact_id, null);
    await this.db.await_proc('my_tag_delete', contact_id, null);
  }


  /**
   * 
   */
  async block() {
    let contact_id = this.input.need(Attr.contact_id);
    let res = {};
    res = await this.db.await_proc('contact_block_add', contact_id)

    res = await this._show(res.contact_id);
    let entity = await this.yp.await_proc('forward_proc',
      this.uid, 'shareroom_contact_get', `'${res.uid}'`
    );
    let sockets = await this.yp.await_proc('user_sockets', this.uid);
    await RedisStore.sendData(this.payload(entity), sockets);

    if (!isEmpty(res.uid)) {
      entity = await this.yp.await_proc('forward_proc', res.uid, 'shareroom_contact_get', `'${this.uid}'`)
      sockets = await this.yp.await_proc('user_sockets', res.uid);
      await RedisStore.sendData(this.payload(entity), sockets);
    }
    this.output.data(res);
  }

  /**
   * 
   */
  async change_status() {
    let contact_id = this.input.need(Attr.contact_id);
    let status = this.input.need(Attr.status)
    let res = {};

    if (!['archived', 'active'].includes(status)) {
      return this.output.data({ status: 'INVALID_STATUS0' });
    }

    let contact = await this.db.await_proc('my_contact_get_next', contact_id, null)
    if (isEmpty(contact)) {
      return this.output.data({ status: 'CONACT_NOT_EXIST' });
    }
    if (status == 'archived') {
      res = await this.db.await_proc('archive_entity', contact_id);
    }
    else {
      res = await this.db.await_proc('unarchive_entity', contact_id);
    }

    let sockets = await this.yp.await_proc('user_sockets', this.uid);
    await RedisStore.sendData(this.payload(res), sockets);

    this.output.data(res);
  }


  async unblock() {
    let contact_id = this.input.need(Attr.contact_id);
    let res = {};
    await this.db.await_proc('contact_block_delete', contact_id)
    res = await this._show(contact_id);
    let entity = await this.yp.await_proc('forward_proc', this.uid, 'shareroom_contact_get', `'${res.uid}'`)
    let sockets = await this.yp.await_proc('user_sockets', this.uid);
    await RedisStore.sendData(this.payload(entity), sockets);

    if (!isEmpty(res.uid)) {
      entity = await this.yp.await_proc('forward_proc', res.uid, 'shareroom_contact_get', `'${this.uid}'`)
      let sockets = await this.yp.await_proc('user_sockets', res.uid);
      await RedisStore.sendData(this.payload(entity), sockets);
    }
    this.output.data(res);

  }

  //========================
  // Pending  : 
  // Validation record format chk for  email,address & phone records    
  // add ( to remove old invite logic) in sp my_contact_update 
  //========================
  async update() {
    let contact_id = this.input.need(Attr.contact_id);
    let surname = this.input.use(Attr.surname);
    let firstname = this.input.use(Attr.firstname);
    let lastname = this.input.use(Attr.lastname);
    let email = this.input.use(Attr.email) || this.input.use(Attr.list) || [];
    let mobile = this.input.use(Attr.mobile) || this.input.use(Attr.list) || [];
    let address = this.input.use(Attr.address) || this.input.use(Attr.list) || [];
    let tag = this.input.use(Attr.tag) || this.input.use(Attr.list) || [];
    let comment = this.input.use(Attr.comment);
    let message = this.input.use(Attr.message);
    let invite = this.input.use(Attr.invite, "0") + "";

    if (!isArray(email)) {
      email = [email];
    }
    if (!isArray(mobile)) {
      mobile = [mobile];
    }
    if (!isArray(address)) {
      address = [address];
    }

    let fullname;
    if (!isEmpty(firstname)) {
      if (!isEmpty(lastname)) {
        fullname = firstname + ' ' + lastname
      } else {
        fullname = lastname
      }
    } else {
      if (!isEmpty(lastname)) {
        fullname = lastname
      }
    }

    let res = {};
    let entity;
    let contact;
    let status
    let drumate
    let default_email;
    let is_entity_changable = "yes";
    let manydefault;
    let data;
    let before;
    let after;
    let is_need_email;
    let meta_data = {};

    contact = await this.db.await_proc('my_contact_get_next', contact_id, null)
    if (isEmpty(contact)) {
      res.status = 'CONACT_NOT_EXIST';
      return this.output.data(res);
    }
    entity = contact.entity;
    status = contact.status;
    meta_data.source = contact.source;
    is_need_email = contact.is_need_email;

    if (!isEmpty(contact.uid) && isEmpty(firstname)) {
      res.status = 'EMPTY_FIRSTNAME';
      return this.output.data(res);
    }

    if (!isEmpty(contact.uid) && isEmpty(lastname)) {
      res.status = 'EMPTY_LASTNAME';
      return this.output.data(res);
    }

    if (status == "received" || status == "informed" || status === "active") {
      is_entity_changable = "no";
    }

    if (!isEmpty(email)) {

      for (let node of email) {
        if (node.is_default != null) {
          if (node.is_default == '1') {
            default_email = node.email;
            manydefault = manydefault + 1;
          }
        }
      }
      if (manydefault > 1) {
        res.status = 'MANY_DEFAULT_EMAIL';
        return this.output.data(res);
      }
      if (is_need_email) {
        if (isEmpty(default_email)) {
          res.status = 'NO_DEFAULT_MAIL';
          return this.output.data(res);
        }
      }
      if (is_entity_changable === "yes") {
        entity = default_email;
        meta_data.source = default_email;
      }

    }

    drumate = await this.yp.await_proc('drumate_exists', entity);
    entity = drumate.id || entity;

    if (drumate.id == this.uid) {
      res.status = 'SELF_CONTACT';
      return this.output.data(res);
    }

    if (!isEmpty(drumate)) {
      let my_drumate = await this.yp.await_proc('drumate_exists', this.uid)
      if ((drumate.domain_id == my_drumate.domain_id) && (my_drumate.domain_id > 1)) {
        res.status = 'SAME_DOMAIN';
        return this.output.data(res);
      }
    }

    data = await this.db.await_proc('my_contact_exists', 'entity', entity, null, contact_id);
    if (!isEmpty(data)) {
      res.status = 'ALREADY_IN_CONTACT';
      return this.output.data(res);
    }
    meta_data.is_auto = 0

    let updata_data = await this.db.await_proc('my_contact_update_next', contact_id, surname, firstname, lastname, comment, message, entity, meta_data);
    if (!isEmpty(updata_data.old_entity)) {
      data.drumate_id = this.uid;
      data.status = 'removed';
      let sockets = await this.yp.await_proc('user_sockets', updata_data.old_entity);
      await RedisStore.sendData(this.payload(data), sockets);

      // this.pushLiveUpdate({
      //   dest: {
      //     area: Attr.personal,
      //     type: Attr.drumate,
      //     hub_id: updata_data.old_entity
      //   },
      //   model: data
      // });

    }

    let sent = {};
    if (is_entity_changable == "yes") {

      if (invite == "1") {
        if (!isEmpty(drumate)) {
          before = await this.yp.await_proc('forward_proc', drumate.id, 'contact_status_get', `'${this.uid}'`)
          if (isEmpty(before)) { before.status = 'no' }
        }

        data = await this.db.await_proc('contact_invite', entity);

        if (!isEmpty(drumate)) {
          after = await this.yp.await_proc('forward_proc', drumate.id, 'contact_status_get', `'${this.uid}'`)

          if ((after.status != before.status) && (after.status == 'invitation' || after.status == 'received' || after.status == 'informed')) {
            data = await this.yp.await_proc('forward_proc', drumate.id, 'contact_notification_by_entity', `'${this.uid}'`)
            //this.notify_user(drumate.id, data);
            data.service = 'invitation.accepted';
            let service = data.service;
            let sockets = await this.yp.await_proc('user_sockets', drumate.id);
            await RedisStore.sendData(this.payload(data, { service }), sockets);

            // this.pushLiveUpdate({
            //   dest: {
            //     area: Attr.personal,
            //     type: Attr.drumate,
            //     hub_id: drumate.id
            //   },
            //   model: data
            // });

          }
        }
      }

      if (invite == "1") {
        if (isEmpty(drumate)) {
          fullname = fullname || entity
          const token = this.randomString();
          let i = this.yp.await_proc('token_generate_next', entity, fullname, token, 'signup', this.uid);
          sent = await this.send_mail(default_email, message, token);
        }
        else {
          let vhost = await this.yp.await_proc('domain_exists', drumate.domain_id);
          sent = await this.send_drumate_mail(default_email, message, vhost.name);
        }
      }
    }

    await this._delete(contact_id);
    await this._add(contact_id, email, mobile, address, tag);
    res = await this._show(contact_id);
    if (sent.error) {
      res.status = 'EMAIL_NOT_SENT';
      res.failed = sent.error;
    }
    this.output.data(res);

  }

  //========================
  // Pending  : 
  // Validation record format chk for  email,address & phone records    
  //========================

  async add() {
    let invitee_id = this.input.use(Attr.invitee_id);
    let surname = this.input.use(Attr.surname);
    let firstname = this.input.use(Attr.firstname);
    let lastname = this.input.use(Attr.lastname);
    let email = this.input.use(Attr.email) || this.input.use(Attr.list) || [];
    let mobile = this.input.use(Attr.mobile) || this.input.use(Attr.list) || [];
    let address = this.input.use(Attr.address) || this.input.use(Attr.list) || [];
    let tag = this.input.use(Attr.tag) || this.input.use(Attr.list) || [];
    let comment = this.input.use(Attr.comment);
    let message = this.input.use(Attr.message);
    let invite = this.input.use(Attr.invite, "0") + "";

    if (!isArray(email)) {
      email = [email];
    }
    if (!isArray(mobile)) {
      mobile = [mobile];
    }
    if (!isArray(address)) {
      address = [address];
    }
    if (!isArray(tag)) {
      tag = [tag];
    }

    let fullname;
    if (!isEmpty(firstname)) {
      if (!isEmpty(lastname)) {
        fullname = firstname + ' ' + lastname
      } else {

        fullname = lastname
      }
    } else {
      if (!isEmpty(lastname)) {
        fullname = lastname
      }
    }

    let res = {};
    let drumate;
    let entity;
    let manydefault = 0;
    let data;
    let issue;
    let before;
    let after;
    let metadata = {};
    let default_email;

    if (!isEmpty(invitee_id) && !isEmpty(email)) {
      res.status = 'INVALID_DATA';
      return this.output.data(res);
    }

    if (isEmpty(invitee_id) && isEmpty(email)) {
      res.status = 'INVALID_DATA';
      return re1s;
    }

    if (!isEmpty(invitee_id)) {
      drumate = await this.yp.await_proc('drumate_exists', invitee_id);
      if (isEmpty(drumate)) {
        res.status = 'INVALID_INVITEE_ID';
        return this.output.data(res);
      }

      if (!isEmpty(drumate)) {
        let my_drumate = await this.yp.await_proc('drumate_exists', this.uid)
        if ((drumate.domain_id == my_drumate.domain_id) && (my_drumate.domain_id > 1)) {
          res.status = 'SAME_DOMAIN';
          return this.output.data(res);
        }
      }
      entity = drumate.id;
    }

    if (!isEmpty(email)) {

      for (let node of email) {
        if (node.is_default != null) {
          if (node.is_default == '1') {
            entity = node.email;
            default_email = node.email;
            manydefault = manydefault + 1;
          }
        }
      }
      if (manydefault > 1) {
        res.status = 'MANY_DEFAULT_EMAIL';
        return this.output.data(res);
      }
      if (isEmpty(entity)) {
        res.status = 'NO_DEFAULT_MAIL';
        return this.output.data(res);
      }
      drumate = await this.yp.await_proc('drumate_exists', entity);

      if (drumate.id == this.uid) {
        res.status = 'SELF_CONTACT';
        return this.output.data(res);
      }
      metadata.source = entity
      entity = drumate.id || entity

    }


    data = await this.db.await_proc('my_contact_exists', 'entity', entity, null, null);
    if (!isEmpty(data)) {
      res.status = 'ALREADY_IN_CONTACT';
      return this.output.data(res);
    }

    let contact = await this.db.await_proc('my_contact_add_next', entity, surname, firstname, lastname, 'independant', comment, message, metadata);

    if (invite == "1") {

      if (!isEmpty(drumate)) {
        before = await this.yp.await_proc('forward_proc', drumate.id, 'contact_status_get', `'${this.uid}'`)
        if (isEmpty(before)) { before.status = 'no' }
      }

      data = await this.db.await_proc('contact_invite', entity);

      if (!isEmpty(drumate)) {
        after = await this.yp.await_proc('forward_proc', drumate.id, 'contact_status_get', `'${this.uid}'`)

        if ((after.status != before.status) && (after.status == 'invitation' || after.status == 'received' || after.status == 'informed')) {
          data = await this.yp.await_proc('forward_proc', drumate.id, 'contact_notification_by_entity', `'${this.uid}'`)
          //this.notify_user(drumate.id, data);
          let sockets = await this.yp.await_proc('user_sockets', drumate.id);
          await RedisStore.sendData(this.payload(data), sockets);
        }
      }
    }
    let sent = {};
    if (invite == "1") {
      if (isEmpty(drumate)) {
        fullname = fullname || entity
        const token = this.randomString();
        let i = this.yp.await_proc('token_generate_next', entity, fullname, token, 'signup', this.uid);
        sent = await this.send_mail(default_email, message, token);
      }
      else {
        let vhost = await this.yp.await_proc('domain_exists', drumate.domain_id);
        send = await this.send_drumate_mail(default_email, message, vhost.name);
      }
    }


    await this._delete(contact.id);
    await this._add(contact.id, email, mobile, address, tag);
    res = await this._show(contact.id);
    if (sent.error) {
      res.status = 'EMAIL_NOT_SENT';
      res.failed = sent.error;
    }
    this.output.data(res);
  }

  //========================
  //
  //========================

  async invite() {
    let email = this.input.need(Attr.email);
    let message = this.input.use(Attr.message);
    let firstname = this.input.use(Attr.firstname);
    let lastname = this.input.use(Attr.lastname);
    let surname = this.input.use(Attr.surname);

    let fullname;

    if (!isEmpty(firstname)) {
      if (!isEmpty(lastname)) {
        fullname = firstname + ' ' + lastname
      } else {
        let contact = {};
        fullname = lastname
      }
    } else {
      if (!isEmpty(lastname)) {
        fullname = lastname
      }
    }

    let res = {};
    let drumate;
    let entity;
    let data;
    let id;
    let before;
    let after;
    let metadata = {}
    let newcontact

    if (!EMAIL_CHECKER.test(email)) {
      res.status = 'INVALID_DATA';
      return this.output.data(res);
    }

    let a = email.split('@');
    a[1] = a[0]
    if (a[0].indexOf('.') !== -1) {
      a = a[0].split('.');
    }
    firstname = a[0]
    lastname = a[1]

    drumate = await this.yp.await_proc('drumate_exists', email);
    if (isEmpty(drumate)) {
      entity = email;
      metadata.source = email
      metadata.is_auto = 1
    } else {
      entity = drumate.id
      metadata.source = email
      metadata.is_auto = 1
    }


    let contact = await this.db.await_proc('my_contact_exists', 'entity', entity, null, null);

    if (!isEmpty(contact)) {
      if (contact.status == 'active' || contact.status == 'informed') {
        res.status = 'ALREADY_IN_CONTACT';
        return this.output.data(res);
      }
      if (contact.status == 'received') {
        res.status = 'INVITE_RECEIVED';
        return this.output.data(res);
      }
    }
    let sent = {};
    if (isEmpty(drumate)) {
      const token = this.randomString();
      fullname = fullname || entity
      let i = this.yp.await_proc('token_generate_next', entity, fullname, token, 'signup', this.uid);
      sent = await this.send_mail(email, message, token);
    } else {

      let my_drumate = await this.yp.await_proc('drumate_exists', this.uid)
      if ((drumate.domain_id == my_drumate.domain_id) && (my_drumate.domain_id > 1)) {
        res.status = 'SAME_DOMAIN';
        return this.output.data(res);
      }
      let vhost = await this.yp.await_proc('domain_exists', drumate.domain_id);
      sent = await this.send_drumate_mail(email, message, vhost.name);
    }

    if (isEmpty(contact)) {
      newcontact = await this.db.await_proc('my_contact_add_next',
        entity, surname, firstname, lastname, 'independant', null, message, metadata
      );
    } else {
      newcontact = await this.db.await_proc('my_contact_update_next',
        contact.id, contact.surname, contact.firstname, contact.lastname,
        contact.comment, message, contact.entity, contact.metadata
      );
    }

    if (!isEmpty(drumate)) {
      before = await this.yp.await_proc('forward_proc', drumate.id, 'contact_status_get', `'${this.uid}'`)
      if (isEmpty(before)) { before.status = 'no' }

      await this.db.await_proc('contact_invite', entity);
      after = await this.yp.await_proc('forward_proc', drumate.id, 'contact_status_get', `'${this.uid}'`)

      if ((after.status != before.status) && (after.status == 'invitation' || after.status == 'received' || after.status == 'informed')) {
        data = await this.yp.await_proc('forward_proc', drumate.id, 'contact_notification_by_entity', `'${this.uid}'`)
        let sockets = await this.yp.await_proc('user_sockets', drumate.id);
        await RedisStore.sendData(this.payload(data), sockets);
      }
    }

    if (isEmpty(drumate)) {
      await this.db.await_proc('contact_invite', entity);
    }

    if (isEmpty(contact)) {
      if (isEmpty(drumate)) {
        let node = {}
        node.email = entity;
        node.category = 'priv';
        node.is_default = '1';
        await this.db.await_proc('my_contact_mail_add', newcontact.id, stringify([node]))
      } else {
        if (EMAIL_CHECKER.test(email)) {
          let node = {}
          node.email = email;
          node.category = 'priv';
          node.is_default = '1';
          await this.db.await_proc('my_contact_mail_add', newcontact.id, stringify([node]))
        }
      }
    }
    res = await this._show(newcontact.id);
    res.input = email;
    if (sent.error) {
      res.status = 'EMAIL_NOT_SENT';
      res.failed = sent.error;
    }
    this.output.data(res);
  }

  /**
   * 
   */
  async join() {
    let token = this.input.need(Attr.token);
    let res = {};
    let data = await this.yp.await_proc('token_get', token);
    if (isEmpty(data)) {
      res.status = 'INVALID_TOKEN';
      return this.output.data(res);
    }
    if (data.status != 'active') {
      res.status = 'EXPIRIED_TOKEN';
      return this.output.data(res);
    }

    let contact = await this.db.await_proc('contact_join', token);

    data = await this.db.await_proc('my_contact_get_next', contact.id, null)
    if (!isEmpty(data)) {
      res = data;
      res.email = [];
      res.address = [];
      res.phone = [];
    }
    data = await this.db.await_proc('my_contact_mail_get', contact.id)
    data = toArray(data);
    if (data) {
      res.email = data;
    }

    this.output.data(res);

  }


  //========================
  //
  //========================

  async invite_refuse() {
    let email = this.input.need(Attr.email);
    let res = {};
    let drumate = await this.yp.await_proc('drumate_exists', email);
    if (isEmpty(drumate)) {
      return this.output.data({ status: 'NOT_A_DRUMATE' });
      // res.status = 'NOT_A_DRUMATE';
      // return this.output.data(res);
    }

    let received = await this.db.await_proc('contact_invite_chk', drumate.id, "received");
    let invitation = await this.db.await_proc('contact_invite_chk', drumate.id, "invitation");
    if (isEmpty(received)) {
      if (isEmpty(invitation)) {
        return this.output.data({ status: 'NO_INVITE' });
        // res.status = 'NO_INVITE';
        // return this.output.data(res);
      }
    }

    let data = await this.db.await_proc('contact_invite_refuse', drumate.id);
    _.merge(res, data);
    res = { ...res, ...data };
    let sockets = await this.yp.await_proc('user_sockets', drumate.id);
    await RedisStore.sendData(this.payload(res), sockets);

    this.output.data(r);

  }


  /**
   * 
   * @param {*} message 
   * @param {*} uid 
   * @param {*} entity_id 
   */
  async handshake(message, uid, entity_id) {
    let input = {};
    let myinput = {};

    let hisinput = {};
    let mydata = {};
    let hisdata = {};
    let acknowledge = {};
    let message_id = await this.db.await_proc('message_id');
    message_id = message_id.id
    input.author_id = uid
    input.uid = uid
    input.message_id = message_id
    hisinput = input
    myinput = input

    myinput.entity_id = entity_id
    mydata = await this.yp.await_proc('forward_proc', uid, 'channel_post_message_next', `'${stringify(myinput)}','${message}'`)
    hisinput.entity_id = uid
    hisdata = await this.yp.await_proc('forward_proc', entity_id, 'channel_post_message_next', `'${stringify(hisinput)}','${message}'`)

    acknowledge.message_id = message_id
    acknowledge.entity_id = entity_id
    acknowledge.uid = uid
    await this.yp.await_proc('forward_proc', uid, 'acknowledge_message', `'${stringify(acknowledge)}'`)

    mydata.to_id = uid;
    mydata.echoId = this.input.get('echoId');
    hisdata.to_id = entity_id
    let service = "chat.post";
    let sockets = await this.yp.await_proc('user_sockets', entity_id);
    await RedisStore.sendData(this.payload(hisdata, { service }), sockets);
    sockets = await this.yp.await_proc('user_sockets', uid);
    await RedisStore.sendData(this.payload(mydata, { service }), sockets);
  }

  /**
   * 
   * @returns 
   */
  async invite_accept() {
    let email = this.input.need(Attr.email);

    let res = {};
    let drumate = await this.yp.await_proc('drumate_exists', email);
    if (isEmpty(drumate)) {
      return this.output.data({ status: 'NOT_A_DRUMATE' });
    }

    let received = await this.db.await_proc('contact_invite_chk', drumate.id, "received");
    let invitation = await this.db.await_proc('contact_invite_chk', drumate.id, "invitation");
    if (isEmpty(received)) {
      if (isEmpty(invitation)) {
        return this.output.data({ status: 'NO_INVITE' });
      }
    }

    let data = await this.db.await_proc('contact_invite_accept', drumate.id);

    let node = {}
    node.email = drumate.email;
    node.category = 'priv';
    node.is_default = '1';
    await this.db.await_proc('my_contact_mail_add', data.contact_id, stringify([node]))

    res = { ...res, ...data };
    data = await this.yp.await_proc('forward_proc', drumate.id, 'contact_notification_by_entity', `'${this.uid}'`)
    data.service = this.input.get(Attr.service)

    const lang = this.user.language() || this.input.app_language();
    let msg_from = Cache.message('_contact_invite_chat_msg', lang)
    let msg_to = Cache.message('_contact_accept_chat_msg', lang)
    await this.handshake(msg_from, drumate.id, this.uid)
    await this.handshake(msg_to, this.uid, drumate.id)

    let sockets = await this.yp.await_proc('user_sockets', drumate.id);
    await RedisStore.sendData(this.payload(data), sockets);
    this.output.data(res);
    this.output.data(res);
  }


  /**
   * 
   */
  invite_get() {
    this.db.call_proc('contact_notification_get', this.output.list);
  }

  /**
   * 
   */
  async connection_status() {
    let recipients = await this.yp.await_proc(`drumate_online_state`, this.uid);
    this.output.list(recipients);
  }

  /**
   * 
   */
  invite_count() {
    this.db.call_proc('contact_notification_count', this.output.data);
  }

  /**
   * 
   */
  async accept_informed() {
    let email = this.input.need(Attr.email);
    let res = {};
    let drumate = await this.yp.await_proc('drumate_exists', email);
    if (isEmpty(drumate)) {
      return this.output.data({ status: 'NOT_A_DRUMATE' });
    }

    let data = await this.db.await_proc('contact_invite_chk', drumate.id, "informed");
    if (isEmpty(data)) {
      return this.output.data({ status: 'NO_INVITE' });
    }

    data = await this.db.await_proc('contact_invite_informed', drumate.id);
    let sockets = await this.yp.await_proc('user_sockets', [drumate.id, this.uid]);
    await RedisStore.sendData(this.payload(data), sockets);
    res = { ...res, ...data };
    this.output.data(res);
  }


  /**
   * 
   */
  show() {
    const page = this.input.use(Attr.page) || 1;
    this.exception.reject("SERVICE DEPRECATED");
  }

  /**
   * 
   */
  seek() {
    const key = this.input.use(Attr.id) || this.input.use(Attr.email);
    this.db.call_proc('contact_get', key, this.output.data);
  }

  /**
   * 
   */
  delete() {
    const email = this.input.need(Attr.email);
    this.db.call_proc('contact_delete', email, this.output.data);
  }


  /**
   * 
   * @returns 
   */
  search() {
    const key = this.input.use(Attr.key) || this.input.use(Attr.string);
    const page = this.input.use(Attr.page, 1);
    if (isEmpty(key)) {
      this.output.data([]);
      return;
    }
    this.db.call_proc('contact_search_by_domain_next', key, page, this.output.list);
  }

  /**
   * 
   */
  async my_contacts() {
    const page = this.input.use(Attr.page, 1);
    const only_drumate = this.input.use('only_drumate', 0);
    const key = this.input.use('value', "");
    let filter = this.input.use(Attr.filter) || []
    const status = this.input.use(Attr.status) || ''
    const f = async () => {
      let res = [];
      if (isEmpty(key)) {
        //  this.output.data([]);
        return this.output.data(res);
      }
      filter = toArray(filter) || [];
      res = await this.db.await_proc('my_contact', key, page, stringify(filter), status);
      return this.output.data(res);
    }
    f().then((r) => {

      this.output.list(r);
    }).catch(this.fallback);
  }

}


module.exports = __private_contact;
