
// ================================  *
//   Copyright Xialia.com  2013-2017 *
//   FILE  : src/service/private/chat
//   TYPE  : module
// ================================  *

const {
  Attr, RedisStore, toArray
} = require("@drumee/server-essentials");
const { Entity, MfsTools } = require('@drumee/server-core');
const { remove_node, move_node, copy_node, } = MfsTools;

const { stringify } = JSON;
const { isEmpty } = require('lodash');
const Crypto = require("crypto");

/** ========================================== */
class __private_channel extends Entity {
  constructor(...args) {
    super(...args);
    this.messages = this.messages.bind(this);
    this.post = this.post.bind(this);
    this.read = this.read.bind(this);
    this.notify_chat = this.notify_chat.bind(this);
    this.acknowledge = this.acknowledge.bind(this);
    this.send_ticket = this.send_ticket.bind(this);
    this.post_ticket = this.post_ticket.bind(this);
    this.show_ticket = this.show_ticket.bind(this);
    this.list_tickets = this.list_tickets.bind(this);
    this.update_ticket = this.update_ticket.bind(this);

  }

  /**
   * 
   */
  notify_chat() {
    this.db.call_proc('channel_notify_messages', this.uid, this.output.data);
  }

  /**
   * 
   */
  async messages() {
    const order = this.input.use(Attr.order, 'asc');
    const page = this.input.use(Attr.page) || 1;
    let data = await this.db.await_proc('channel_list_messages', this.uid, 'date', order, page);

    data = toArray(data);
    let messages = [];

    let cache = {};
    let hub_id = this.hub.get(Attr.id);
    for (let message of data) {

      message.entity = { id: this.uid }
      if (message.author_id != this.uid) {
        let key = message.author_id;

        if (cache[key]) {
          message.entity = cache[key];
        }
        else {
          message.entity = await this.yp.await_proc('forward_proc', this.uid, 'shareroom_contact_get', `'${message.author_id}'`)
          cache[key] = message.entity;

        }
      }
      if (!isEmpty(message.thread_id)) {
        message.thread = await this.threadInfo(message.thread_id, hub_id)
      }
      messages.push(message)
    }
    let dest = await this.yp.await_proc('entity_sockets', hub_id);
    dest = toArray(dest).filter((e) => {
      return e.uid != this.uid;
    })
    await RedisStore.sendData(this.payload(messages, { service: "channel.acknowledge" }), dest);

    dest = await this.yp.await_proc('user_sockets', this.uid);
    let db_name = this.user.get(Attr.db_name);
    let model = await this.yp.await_proc(`${db_name}.notification_center_next`);
    await RedisStore.sendData(this.payload(model, { service: "messages.read" }), dest);

    this.output.list(messages);

  }

  /**
   * To get the  Attachments or media details for a array of ids 
   * @params {string[]} attachments - array of the media ids (nid)
   * @params {string} uid - hubid of the media
   * @todo Need to add to globle function 
   */
  async _getAttachmentsInfo(attachments, uid) {
    let files = [];
    attachments = toArray(attachments);
    for (let media of attachments) {
      let file = await this._getAttachmentInfo(uid, media);
      files.push(file)
    }
    return files;
  }

  /**
   * To get the  Attachment or media details for a  ids 
   * @params {string} uid - hubid of the media
   * @params {string} mediaId - id of a media (nid)
   * @todo Need to add to globle function 
   */
  async _getAttachmentInfo(uid, media) {
    let attr
    if (typeof media.hub_id !== 'undefined') {
      attr = await this.yp.await_proc('forward_proc', media.hub_id, 'mfs_access_node', `'${uid}', '${media.nid}'`)
    } else {
      attr = await this.db.await_proc('mfs_access_node', uid, media);
    }
    return this.output.sanitize(attr);
  }


  /**
   * 
   * @param {*} sbox 
   * @param {*} desdir 
   * @param {*} attachment 
   * @param {*} message_id 
   * @returns 
   */
  async move_attachemnt(sbox, desdir, attachment, message_id) {
    let src = []
    message_id = [message_id]
    for (let media of attachment) {
      src.push({ nid: media, hub_id: this.hub.get(Attr.id) })
    }

    let data = await this.db.call_proc('mfs_move_all', stringify(src), this.hub.get(Attr.id), desdir.id, sbox.hub_id);
    data = toArray(data);

    let tempattachment = []
    for (let node of data) {
      let dest = {}
      switch (node.action) {
        case 'move':
          src = { nid: node.nid, mfs_root: node.src_mfs_root };
          dest = { nid: node.des_id, hub_id: sbox.hub_id, mfs_root: node.des_mfs_root };
          tempattachment.push({ hub_id: sbox.hub_id, nid: node.des_id })
          await move_node(src, dest);
          break;
        case 'copy':
          src = { nid: node.nid, mfs_root: node.src_mfs_root };
          dest = { nid: node.des_id, hub_id: sbox.hub_id, mfs_root: node.des_mfs_root };
          tempattachment.push({ hub_id: sbox.hub_id, nid: node.des_id })
          await copy_node(src, dest, 1);
      }
    }

    for (let node of data) {
      switch (node.action) {
        case 'delete':
          src = { nid: node.nid, hub_id: sbox.hub_id, mfs_root: node.src_mfs_root };
          await remove_node(src, 1);
      }
    }
    if (this.hub.get(Attr.id) != this.uid) {
      for (let media of attachment) {
        tempattachment.push({ nid: media, hub_id: this.hub.get(Attr.id) })
      }
    }
    return tempattachment;
  }

  /**
   * 
   * @param {*} thread_id 
   * @param {*} uid 
   * @returns 
   */
  async threadInfo(thread_id, uid) {
    let thread = {}
    let data = await this.yp.await_proc('forward_proc', uid, 'channel_get', `'${thread_id}'`)

    if (isEmpty(data)) {
      thread.message = 'DELETED'
      thread.message_id = data.message_id
      return thread;
    }

    thread.message = data.message
    thread.message_id = data.message_id
    thread.is_attachment = 0
    if (!isEmpty(data.attachment)) {
      thread.is_attachment = 1
    }
    thread.author_id = data.author_id
    thread.entity = await this.yp.await_proc('forward_proc', this.uid, 'shareroom_contact_get', `'${data.author_id}'`)

    return thread;
  }

  /**
   * 
   */
  async list_tickets() {
    let status = this.input.use(Attr.status) || ['new'];
    const page = this.input.use(Attr.page) || 1;
    const search_ticket_id = this.input.use(Attr.ticket_id);

    let filter = {};
    let tickets = [];
    filter.status = status
    if (!isEmpty(search_ticket_id)) {
      filter.search_ticket_id = search_ticket_id
    }
    let sbox = await this.db.call_proc('mfs_wicket_home', this.uid);
    let data = await this.yp.await_proc('forward_proc', sbox.hub_id, 'ticket_list', `'${this.uid}','${stringify(filter)}','${page}'`)

    data = toArray(data);

    for (let ticket of data) {
      ticket.metadata = this.parseJSON(ticket.metadata)
      tickets.push(ticket)
    }
    this.output.data(tickets)
  }

  /**
   * 
   * @returns 
   */
  async update_ticket() {
    const ticket_id = this.input.need(Attr.ticket_id);
    let status = this.input.use(Attr.status);
    let res = {};
    let metadata = {};
    let support_domain_id = Cache.getSysConf('support_domain');
    let my_org = await this.yp.await_proc('my_organisation', this.uid)

    if (my_org.domain_id != support_domain_id) {
      res.status = 'INVALID_DOMAIN'
      return this.output.data(res);
    }

    if (!isEmpty(status)) { metadata.status = status }
    let ticket = await this.yp.await_proc('ticket_detail', ticket_id);
    if (isEmpty(ticket)) {
      res.status = 'INVALID_TICKET'
      return this.output.data(res);
    }
    ticket = await this.yp.call_proc('ticket_update_metadata', ticket_id, metadata);
    ticket.metadata = this.parseJSON(ticket.metadata)

    let recipients = await this.yp.await_proc('user_sockets', ticket.uid);
    await RedisStore.sendData(this.payload(ticket), recipients);

    let support = await this.yp.call_proc('member_list_all', 'all', Cache.getSysConf('support_domain'));
    support = toArray(support);

    for (let member of support) {
      let recipients = await this.yp.await_proc('user_sockets', member.drumate_id);
      await RedisStore.sendData(this.payload(ticket), recipients);
    }
    this.output.data(ticket);
  }

  /**
   * 
   */
  async show_ticket() {
    const page = this.input.use(Attr.page) || 1;
    const ticket_id = this.input.need(Attr.ticket_id);

    let ticket = await this.yp.await_proc('ticket_detail', ticket_id);
    let sbox = await this.yp.await_proc('forward_proc', ticket.uid, 'mfs_wicket_home', `'${ticket.uid}'`);
    let data = await this.yp.await_proc('forward_proc', sbox.hub_id, 'ticket_show', `${ticket_id},'${this.uid}','${page}'`)
    data = toArray(data);

    let messages = [];
    for (let message of data) {
      if (message.is_seen == 1 && message.is_notify == 1) {
        let support = await this.yp.call_proc('member_list_all', this.uid, Cache.getSysConf('support_domain'));
        support = toArray(support);
        for (let member of support) {
          message.service = "channel.acknowledge";
          let recipients = await this.yp.await_proc('user_sockets', member.drumate_id);
          await RedisStore.sendData(this.payload(message), recipients);
        }

        let recipients = await this.yp.await_proc('user_sockets', this.uid);
        await RedisStore.sendData(this.payload(message), recipients);
      }
      message.entity = { id: this.uid }
      if (message.author_id != this.uid) {
        message.entity = await this.yp.await_proc('forward_proc', this.uid, 'shareroom_contact_get', `'${message.author_id}'`)
      }
      message.metadata = this.parseJSON(message.metadata)
      if (message.is_ticket == 1) {
        message.metadata.category_display = []
        for (let category of message.metadata.category) {
          switch (category) {
            case "tech":
              message.metadata.category_display.push("Tech Bug")
              break;
            case "design":
              message.metadata.category_display.push("Design Bug")
              break;
            case "notunderstand":
              message.metadata.category_display.push("Could't Understand")
              break;
            case "enhancement":
              message.metadata.category_display.push("Enhancement")
              break;
          }
        }
        message.metadata.where_display = []
        for (let where of message.metadata.where) {
          switch (where) {
            case "desktop":
              message.metadata.where_display.push("Desktop")
              break;
            case "chat":
              message.metadata.where_display.push("Chat")
              break;
            case "contactmanager":
              message.metadata.where_display.push("Contact Manager")
              break;
            case "teamroom":
              message.metadata.where_display.push("Team Room")
              break;
            case "sharebox":
              message.metadata.where_display.push("Share Box")
              break;
            case "profile":
              message.metadata.where_display.push("Profile")
              break;
            case "others":
              message.metadata.where_display.push("Others")
              break;
          }
        }
      }
      if (!isEmpty(message.thread_id)) {
        message.thread = await this.threadInfo(message.thread_id, sbox.hub_id)
      }
      messages.push(message)
    }
    this.output.list(messages);
  }

  /**
   * 
   * @param {*} hub_id 
   * @param {*} ticket_id 
   * @returns 
   */
  async autoreply(hub_id, ticket_id) {
    let reply = {}
    let input = {};
    let metadata = {};
    let message_id = await this.yp.await_func("uniqueId");
    await this.yp.await_proc('forward_proc', hub_id, 'map_ticket_add', `'${message_id}','${ticket_id}'`)
    input.author_id = 'autoreply'
    input.uid = 'autoreply'
    input.message_id = message_id
    input.metadata = metadata
    input.metadata.message_type = 'ticket_auto_reply'
    let message = Cache.message("_ticket_auto_reply", this.client_language());
    let data = await this.yp.await_proc('forward_proc', hub_id, 'channel_post_message_next', `'${stringify(input)}','${message}'`)
    return this.output.sanitize(data);
  }


  /**
   * 
   */
  async send_ticket() {
    let attachment = this.input.use(Attr.attachment, []);
    let message = this.input.need(Attr.message);
    let category = this.input.need(Attr.category, []);
    let alltime = this.input.use(Attr.alltime, 0);
    let where = this.input.use(Attr.where, []);
    const f = async () => {
      let metadata = {};
      let input = {};
      let message_id = await this.yp.await_func("uniqueId");
      let sbox = await this.db.call_proc('mfs_wicket_home', this.uid);
      if (!isEmpty(attachment)) {
        let desdir = await this.yp.await_proc('forward_proc', sbox.hub_id, 'mfs_make_dir', `'${sbox.ticket_id}','${stringify(message_id)}',1`)
        attachment = await this.move_attachemnt(sbox, desdir, attachment, message_id)
      }
      metadata.status = 'new'
      if (!isEmpty(attachment)) { metadata.attachment = attachment }
      if (!isEmpty(category)) { metadata.category = category }
      if (!isEmpty(category)) { metadata.alltime = alltime }
      if (!isEmpty(where)) { metadata.where = where }
      if (!isEmpty(message)) { message = message.replace(/'/gi, "''"); }
      metadata.message = message;

      let ticket = await this.yp.await_proc('ticket_add', message_id, this.uid, metadata);
      metadata.ticket_id = ticket.ticket_id;


      await this.yp.await_proc('forward_proc', sbox.hub_id, 'map_ticket_add', `'${message_id}','${ticket.ticket_id}'`)
      input.author_id = this.uid
      input.uid = this.uid
      input.message_id = message_id
      input.metadata = metadata
      input.metadata.message_type = 'ticket'
      input.ticket_id = ticket.ticket_id;
      if (!isEmpty(attachment)) { input.attachment = attachment }
      let data = await this.yp.await_proc('forward_proc', sbox.hub_id, 'channel_post_message_next', `'${stringify(input)}','${message}'`)
      data.is_attachment = 0
      if (!isEmpty(input.attachment)) {
        await this.yp.await_proc('forward_proc', sbox.hub_id, 'channel_post_attachment', `'${message_id}','${sbox.hub_id}','${stringify(input.attachment)}'`)
        data.is_attachment = 1
      }
      data.ticket_id = ticket.ticket_id;
      let profile = this.user.get('profile') || {};
      data.lastname = profile.lastname;
      data.firstname = profile.firstname;
      let my_org = await this.yp.await_proc('my_organisation', this.uid)
      data.org_name = my_org.name
      data.metadata = metadata;

      let auto = await this.autoreply(sbox.hub_id, ticket.ticket_id)
      auto.service = "channel.post"

      auto.echoId = this.input.get('echoId');
      data.echoId = this.input.get('echoId');
      let keys = { entity_id: Attr.hub_id };
      let recipients = await this.yp.await_proc('user_sockets', ticket.uid);
      await RedisStore.sendData(this.payload(data, { keys }), recipients);
      await RedisStore.sendData(this.payload(auto, { keys }), recipients);
      let support = await this.yp.call_proc('member_list_all', this.uid, Cache.getSysConf('support_domain'));
      support = toArray(support);

      for (let member of support) {
        let recipients = await this.yp.await_proc('user_sockets', member.drumate_id);
        await RedisStore.sendData(this.payload(data, { keys }), recipients);
        await RedisStore.sendData(this.payload(auto, { keys }), recipients);
      }

      return data;
    }
    f().then((data = {}) => {
      this.output.data(data);
    }).catch(this.fallback);
  }



  async post_ticket() {
    let message = this.input.use(Attr.message, '');
    const thread_id = this.input.use(Attr.thread_id);
    let attachment = this.input.use(Attr.attachment, []);
    const ticket_id = this.input.need(Attr.ticket_id);
    const f = async () => {
      let input = {};
      let res = {};
      let ticket = await this.yp.await_proc('ticket_detail', ticket_id);

      if (isEmpty(ticket)) {
        res.status = 'INVALID_TICKET'
        return this.output.data(res);
      }
      let message_id = await this.yp.await_func("uniqueId");
      let sbox = await this.db.call_proc('mfs_wicket_home', ticket.uid);

      if (!isEmpty(attachment)) {
        let desdir = await this.yp.await_proc('forward_proc', sbox.hub_id, 'mfs_make_dir', `'${sbox.ticket_id}','${stringify(message_id)}',1`)
        attachment = await this.move_attachemnt(sbox, desdir, attachment, message_id)
      }

      await this.yp.await_proc('forward_proc', sbox.hub_id, 'map_ticket_add', `'${message_id}','${ticket.ticket_id}'`)
      input.author_id = this.uid
      input.uid = this.uid
      input.message_id = message_id
      input.ticket_id = ticket.ticket_id;
      input.metadata = {}
      input.metadata.message_type = 'ticket'
      if (!isEmpty(attachment)) { input.attachment = attachment }
      if (!isEmpty(message)) { message = message.replace(/'/gi, "''"); }
      if (!isEmpty(thread_id)) { input.thread_id = thread_id }
      let data = await this.yp.await_proc('forward_proc', sbox.hub_id, 'channel_post_message_next', `'${stringify(input)}','${message}'`)
      data.is_attachment = 0
      if (!isEmpty(input.attachment)) {
        await this.yp.await_proc('forward_proc', sbox.hub_id, 'channel_post_attachment', `'${message_id}','${sbox.hub_id}','${stringify(input.attachment)}'`)
        data.is_attachment = 1
        // data.attachment = await this._getAttachmentsInfo(data.attachment, this.hub.get(Attr.id));
      }

      if (!isEmpty(thread_id)) {
        data.thread = await this.threadInfo(thread_id, sbox.hub_id)
      }

      data.ticket_id = ticket.ticket_id;
      data.echoId = this.input.get('echoId');
      //await this.notify_user(ticket.uid, data);
      let keys = { entity_id: Attr.hub_id };
      let recipients = await this.yp.await_proc('user_sockets', ticket.uid);
      await RedisStore.sendData(this.payload(data, { keys }), recipients);


      let support = await this.yp.call_proc('member_list_all', 'xxxxxxx', Cache.getSysConf('support_domain'));
      support = toArray(support);

      for (let member of support) {
        let recipients = await this.yp.await_proc('user_sockets', member.drumate_id);
        await RedisStore.sendData(this.payload(data, { keys }), recipients);

      }

      return data;

    }
    f().then((data = {}) => {
      this.output.data(data);
    }).catch(this.fallback);
  }


  /**
   * 
   */
  async post() {
    let message = this.input.use(Attr.message, '');
    const thread_id = this.input.use(Attr.thread_id);
    let attachment = this.input.use(Attr.attachment, []);
    let temp_result = {};
    let input = {};
    let message_id = await this.db.await_proc('message_id');
    let sbox;
    message_id = message_id.id

    if (this.hub.get(Attr.id) == this.uid) {
      sbox = await this.db.call_proc('mfs_wicket_home', this.uid);
    }
    else {
      sbox = await this.db.call_proc('mfs_home')
    }
    if (!isEmpty(attachment)) {
      let desdir = await this.yp.await_proc('forward_proc', sbox.hub_id, 'mfs_make_dir', `'${sbox.chat_id}','${stringify(message_id)}',1`)
      attachment = await this.move_attachemnt(sbox, desdir, attachment, message_id)
    }
    input.author_id = this.uid
    input.uid = this.uid

    if (!isEmpty(attachment)) { input.attachment = attachment }
    if (!isEmpty(message)) { message = message.replace(/'/gi, "''"); }
    if (!isEmpty(thread_id)) { input.thread_id = thread_id }
    input.message_id = message_id
    let data = await this.yp.await_proc('forward_proc', this.hub.get(Attr.id),
      'channel_post_message_next', `'${stringify(input)}','${message}'`
    );
    data.is_attachment = 0
    if (!isEmpty(input.attachment)) {
      await this.yp.await_proc('forward_proc', this.hub.get(Attr.id),
        'channel_post_attachment', `'${message_id}','${this.hub.get(Attr.id)}','${stringify(input.attachment)}'`
      );
      data.is_attachment = 1
    }

    if (!isEmpty(thread_id)) {
      data.thread = await this.threadInfo(thread_id, this.hub.get(Attr.id))
    }


    let profile = this.user.get('profile') || {};
    data.firstname = this.user.attributes.firstname;
    data.lastname = profile.lastname;
    data.hub_id = this.hub.get(Attr.id);

    //await this.notify_hub(this.hub.get(Attr.id), data);
    data.echoId = this.input.get('echoId');
    let hub_id = this.hub.get(Attr.id);
    let recipients = await this.yp.await_proc('entity_sockets', hub_id);
    await RedisStore.sendData(this.payload(data), recipients);

    this.output.data(data)
  }


  // ========================
  // 
  // ========================
  read() {
    const id = this.input.use(Attr.id);
    this.db.call_proc('channel_read_messages', id, this.uid, this.output.data);
  }


  pages_to_read() {
    this.db.call_proc('pages_to_read', this.uid, this.output.data);
  }

  /**
   * 
   */
  async acknowledge() {
    const message_id = this.input.use(Attr.message_id);
    let res = {};
    res = await this.db.await_proc('acknowledge_message', message_id, this.uid);
    let message = await this.db.await_proc('channel_get', message_id);
    let recipients = await this.yp.await_proc('entity_sockets', this.hub.get(Attr.id));
    message.key_id = this.hub.get(Attr.id);
    await RedisStore.sendData(this.payload(message), recipients);
    this.output.data(res);
  }



  /**
   * 
   */
  async acknowledge_ticket() {
    const message_id = this.input.use(Attr.message_id);
    const ticket_id = this.input.need(Attr.ticket_id);
    const f = async () => {
      let ticket = await this.yp.await_proc('ticket_detail', ticket_id);
      let sbox = await this.yp.await_proc('forward_proc', ticket.uid, 'mfs_wicket_home', `'${ticket.uid}'`);

      let res = {};
      res = await this.yp.await_proc('forward_proc', sbox.hub_id, 'acknowledge_message', `'${message_id}','${this.uid}'`);
      let message = await this.yp.await_proc('forward_proc', sbox.hub_id, 'channel_get', `'${message_id}'`);

      let support = await this.yp.call_proc('member_list_all', this.uid, Cache.getSysConf('support_domain'));
      support = toArray(support)
      for (let member of support) {
        message.service = "channel.acknowledge";
        let service = message.service;
        let recipients = await this.yp.await_proc('user_sockets', member.drumate_id);
        await RedisStore.sendData(this.payload(message, { service }), recipients);
      }

      let recipients = await this.yp.await_proc('user_sockets', this.uid);
      await RedisStore.sendData(this.payload(message), recipients);
      return this.output.data(res)

    }
    f().then((r) => {
      this.output.data(r);
    }).catch(this.fallback);
  }


  // ========================
  // 
  // ========================
  async clear_notifications() {
    //await this.notify_user(this.uid, {});
    let recipients = await this.yp.await_proc('user_sockets', this.uid);
    await RedisStore.sendData(this.payload({}), recipients);
    let data = await this.db.await_proc('channel_clear_notifications', this.uid);
    this.output.data(data);
  }

  /**
   * To create a RTC session Offer 
   * see : https://webrtc.org/getting-started/firebase-rtc-codelab
   * @params {object} as specified by https://www.w3.org/TR/webrtc/#rtcpeerconnection-interface
   */
  async createRTCOffer() {
    const offer = this.input.need('offer');
    const data = {
      callerId: this.uid,
      roomId: Crypto.randomBytes(32).toString("base64")
    }
    let recipients = await this.yp.await_proc('user_sockets', this.uid);
    await RedisStore.sendData(this.payload(data), recipients);
    this.output.data(data);
  }

  /**
   * 
   */
  async delete() {
    let option = this.input.need(Attr.option)
    let messages = this.input.need(Attr.messages)


    let res = {};
    let data = {};
    let temp_result = [];

    if (option != 'me' && option != 'all') {
      res.status = 'INVALID_OPTION'
      return this.output.data(res);
    }
    let invalid_messageid = 0;
    let invalid_option = 0;
    for (let message_id of messages) {
      data = await this.db.await_proc('channel_get', message_id);
      if (isEmpty(data)) {
        invalid_messageid = invalid_messageid + 1;
      }
      if (!isEmpty(data)) {
        if (option == 'all' && data.author_id != this.uid) {
          invalid_option = invalid_option + 1;
        }
      }
    }

    if (invalid_messageid > 0) {
      res.status = 'INVALID_MESSAGES'
      return this.output.data(res);
    }

    if (invalid_option > 0) {
      res.status = 'INVALID_OPTION'
      return this.output.data(res);
    }
    let result
    if (option == 'all') {
      result = await this.db.await_proc('channel_delete_hub_all', this.uid, option, stringify(messages));
    } else {
      result = await this.db.await_proc('channel_delete_hub_me', this.uid, option, stringify(messages));
    }
    data = result.shift() || [];
    data = toArray(data);
    for (let message of data) {

      if (!isEmpty(message.delete_attachment)) {
        message.delete_attachment = this.parseJSON(message.delete_attachment)

        for (let tempattach of message.delete_attachment) {
          tempattach = this.parseJSON(tempattach)
          let sbox = await this.yp.await_proc('forward_proc', tempattach.hub_id, 'mfs_home', ``)
          let src = { nid: tempattach.nid, hub_id: tempattach.hub_id, mfs_root: sbox.home_dir + '/__storage__/' };
          await remove_node(src);

        }
      }

      temp_result.push(message);

      if (option == 'all') {
        let recipients = await this.yp.await_proc('entity_sockets', this.hub.get(Attr.id));
        await RedisStore.sendData(this.payload(message), recipients);
      }
    }
    data = result.shift()
    data = toArray(data);
    let service = "channel.roominfo";
    for (let msg of data) {
      let recipients = await this.yp.await_proc('user_sockets', msg.uid);
      await RedisStore.sendData(this.payload(msg, { service }), recipients);
    }
    this.output.list(temp_result);

  }

}




module.exports = __private_channel;
