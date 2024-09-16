// ================================  *
//   Copyright Xialia.com  2013-2023 *
//   FILE  : src/service/private/chat
//   TYPE  : module
// ================================  *
const { Attr, RedisStore } = require("@drumee/server-essentials");
const { Entity, MfsTools } = require("@drumee/server-core");
const { remove_node, move_node, copy_node } = MfsTools;

const { stringify } = JSON;
const { isEmpty, isArray, map, includes } = require("lodash");


class privateChat extends Entity {

  constructor(...args) {
    super(...args);
    this.post = this.post.bind(this);
    this.acknowledge = this.acknowledge.bind(this);
    this.forward = this.forward.bind(this);
    this.contact_rooms = this.contact_rooms.bind(this);
    this.chat_rooms = this.chat_rooms.bind(this);
    this.chat_room_info = this.chat_room_info.bind(this);
    this.share_rooms = this.share_rooms.bind(this);
    this.pages_to_read = this.pages_to_read.bind(this);
    this.pages_to_read = this.pages_to_read.bind(this);
    this.delete = this.delete.bind(this);
    this.messages = this.messages.bind(this);
    this.remove_attachment = this.remove_attachment.bind(this);
    this.count_all = this.count_all.bind(this);
    this.attachment = this.attachment.bind(this);
    this.change_status = this.change_status.bind(this);
  }

  /**
   * 
   */
  async attachment() {
    let message_id = this.input.use(Attr.message_id);
    let page = this.input.use(Attr.page) || 1;
    let attach = {};
    let data = await this.db.await_proc("channel_get", message_id);

    if (!isEmpty(data.attachment)) {
      data.attachment = this.parseJSON(data.attachment);
      attach = data.attachment.slice((page - 1) * 5, page * 5);
      if (!isEmpty(attach)) {
        attach = await this._getAttachmentsInfo(attach, this.uid, page);
      }
    }
    this.output.data(attach);
  }

  /**
   *
   */
  async acknowledge() {
    const message_id = this.input.need(Attr.message_id);
    let ack = {};
    let message = await this.db.await_proc("channel_get", message_id);
    ack.message_id = message.message_id;
    ack.entity_id = message.entity_id;
    ack.uid = this.uid;
    let db_name = this.user.get(Attr.db_name);
    await this.yp.await_proc(`${db_name}.acknowledge_message`, ack);
    message = await this.db.await_proc("channel_get", message_id);
    if (message.author_id != this.uid) {
      let dest = await this.yp.await_proc("user_sockets", [message.author_id]);
      await RedisStore.sendData(this.payload(message), dest);
    }
    this.output.data(message);
  }

  /**
   *
   */
  contact_rooms() {
    const tag_id = this.input.use(Attr.tag_id, "");
    const page = this.input.use(Attr.page) || 1;
    const key = this.input.use(Attr.key) || "";
    this.db.call_proc(
      "contact_chat_rooms",
      key,
      tag_id,
      page,
      this.output.list
    );
  }

  /**
   *
   */
  chat_rooms() {
    const tag_id = this.input.use(Attr.tag_id, "");
    const page = this.input.use(Attr.page) || 1;
    const key = this.input.use(Attr.key) || "";
    const flag = this.input.use(Attr.flag) || "";
    const option = this.input.use(Attr.option) || "active";
    this.db.call_proc(
      "chat_rooms",
      key,
      tag_id,
      flag,
      option,
      page,
      this.output.list
    );
  }

  /**
   *
   */
  async chat_room_info() {
    const key = this.input.need(Attr.key);
    this.db.call_proc("chat_room_info", key, this.output.data);
  }

  /**
   *
   */
  tag_chat_count() {
    const tag_id = this.input.need(Attr.tag_id, "");
    this.db.call_proc("tag_chat_count", tag_id, this.output.list);
  }

  /**
   *
   */
  share_rooms() {
    const page = this.input.use(Attr.page) || 1;
    const key = this.input.use(Attr.key) || "";
    this.db.call_proc("group_chat_rooms", key, page, this.output.list);
  }

  /**
   * 
   */
  async move_attachemnt(sbox, desdir, attachment, message_id) {
    let src = [];

    message_id = [message_id];
    for (let media of attachment) {
      src.push({ nid: media, hub_id: this.uid });
    }

    let data = await this.db.call_proc(
      "mfs_move_all",
      src,
      this.uid,
      desdir.id,
      sbox.hub_id
    );

    attachment = [];
    for (let node of data) {
      let dest = {};
      switch (node.action) {
        case "move":
          src = { nid: node.nid, mfs_root: node.src_mfs_root };
          dest = {
            nid: node.des_id,
            hub_id: sbox.hub_id,
            mfs_root: node.des_mfs_root,
          };
          attachment.push({ hub_id: sbox.hub_id, nid: node.des_id });
          await move_node(src, dest);
          break;
        case "copy":
          src = { nid: node.nid, mfs_root: node.src_mfs_root };
          dest = {
            nid: node.des_id,
            hub_id: sbox.hub_id,
            mfs_root: node.des_mfs_root,
          };
          attachment.push({ hub_id: sbox.hub_id, nid: node.des_id });
          await copy_node(src, dest);
      }
    }

    for (let node of data) {
      switch (node.action) {
        case "delete":
          src = {
            nid: node.nid,
            hub_id: sbox.hub_id,
            mfs_root: node.src_mfs_root,
          };
          await remove_node(src);
      }
    }

    return attachment;
  }

  /**
   *
   */
  async threadInfo(thread_id, uid) {
    let thread = {};
    let data = await this.yp.await_proc(
      "forward_proc",
      uid,
      "channel_get",
      `'${thread_id}'`
    );

    if (isEmpty(data)) {
      thread.message = "DELETED";
      thread.message_id = data.message_id;
      return thread;
    }

    thread.message = data.message;
    thread.message_id = data.message_id;
    thread.is_attachment = 0;
    if (!isEmpty(data.attachment)) {
      thread.is_attachment = 1;
      //thread.attachment = await this._getAttachmentsInfo(data.attachment, uid);
    }
    thread.author_id = data.author_id;
    thread.entity = await this.yp.await_proc(
      "forward_proc",
      uid,
      "shareroom_contact_get",
      `'${data.author_id}'`
    );
    return thread;
  }

  /**
   *
   * @param {*} uid
   * @param {*} entity_id
   * @returns
   */
  async entityInfo(uid, entity_id) {
    let entity = {};
    entity = await this.yp.await_proc(
      "forward_proc",
      uid,
      "shareroom_contact_get",
      `'${entity_id}'`
    );
    if (!isEmpty(entity.contact_id)) {
      let tag = await this.yp.await_proc(
        "forward_proc",
        uid,
        "my_tag_get",
        `'${entity.contact_id}'`
      );
      if (!isArray(tag)) {
        tag = [tag];
      }
      entity.tag = map(tag, "tag_id");
    }
    return entity;
  }

  /**
   *
   */
  async _checkPostSanity(entity_id, thread_id, attachment) {
    let res = {};
    let contact = await this.db.await_proc(
      "my_contact_exists",
      "entity",
      entity_id,
      null,
      null
    );
    if (isEmpty(contact)) {
      res.status = "INVALID_CONTACT";
      return res;
    }
    if (contact.uid != entity_id) {
      res.status = "INVALID_CONTACT";
      return res;
    }

    let invalid_attachment = 0;
    if (!isEmpty(attachment)) {
      for (let _file of attachment) {
        let file = await this.db.await_proc("mfs_access_node", this.uid, _file);
        if (isEmpty(file)) {
          invalid_attachment = invalid_attachment + 1;
        }
      }
    }
    if (invalid_attachment > 0) {
      res.status = "INVALID_ATTACHMENT";
      return res;
    }

    if (!isEmpty(thread_id)) {
      let data_thread = await this.db.await_proc("channel_get", thread_id);
      if (isEmpty(data_thread)) {
        res.status = "INVALID_THREAD";
        return res;
      }
    }
    return { ok: true };
  }

  /**
   *
   */
  async _distributeMessage(input, message, thread_id, entities) {
    let temp_result = [];
    let mydata = {};
    let hisdata = {};
    let myinput = { ...input };
    let hisinput = { ...input };
    let acknowledge = {};

    for (let entity_id of entities) {
      let drumate = await this.yp.await_proc("drumate_exists", entity_id);
      //if(!message_id) message_id = await this.db.await_proc('message_id');
      let message_id = await this.yp.await_func("uniqueId");
      if (!isEmpty(drumate)) {
        myinput.entity_id = entity_id;
        mydata = await this.yp.await_proc(
          "forward_proc",
          this.uid,
          "channel_post_message_next",
          `'${stringify(myinput)}','${message}'`
        );

        hisinput.entity_id = this.uid;
        hisdata = await this.yp.await_proc(
          "forward_proc",
          entity_id,
          "channel_post_message_next",
          `'${stringify(hisinput)}','${message}'`
        );
        mydata.is_attachment = 0;
        hisdata.is_attachment = 0;
        if (!isEmpty(input.attachment)) {
          await this.yp.await_proc(
            "forward_proc",
            this.uid,
            "channel_post_attachment",
            `'${message_id}','${this.uid}','${stringify(input.attachment)}'`
          );
          await this.yp.await_proc(
            "forward_proc",
            entity_id,
            "channel_post_attachment",
            `'${message_id}','${entity_id}','${stringify(input.attachment)}'`
          );
          mydata.is_attachment = 1;
          hisdata.is_attachment = 1;
          //mydata.attachment = await this._getAttachmentsInfo(stringify(input.attachment), this.uid);
          //hisdata.attachment = await this._getAttachmentsInfo(stringify(input.attachment), entity_id);
        }

        acknowledge.message_id = message_id;
        acknowledge.entity_id = entity_id;
        acknowledge.uid = this.uid;
        await this.yp.await_proc(
          "forward_proc",
          this.uid,
          "acknowledge_message",
          `'${stringify(acknowledge)}'`
        );

        mydata.entity = await this.entityInfo(this.uid, entity_id);
        hisdata.entity = await this.entityInfo(entity_id, this.uid);
        if (!isEmpty(thread_id)) {
          mydata.thread = await this.threadInfo(thread_id, this.uid);
          hisdata.thread = await this.threadInfo(thread_id, entity_id);
        }
        let mycount = await this.yp.await_proc(
          "forward_proc",
          this.uid,
          "count_yet_read_next",
          `'${this.uid}','${entity_id}'`
        );
        mydata.room = mycount.room;
        mydata.total = mycount.total;

        mydata.to_id = this.uid;
        mydata.echoId = this.input.get("echoId");
        hisdata.to_id = entity_id;

        let myDest = await this.yp.await_proc("user_sockets", this.uid);
        await RedisStore.sendData(this.payload(mydata), myDest);
        temp_result.push(mydata);

        let hiscount = await this.yp.await_proc(
          "forward_proc",
          entity_id,
          "count_yet_read_next",
          `'${entity_id}','${this.uid}'`
        );
        hisdata.room = hiscount.room;
        hisdata.total = hiscount.total;

        let hisDest = await this.yp.await_proc("user_sockets", entity_id);
        await RedisStore.sendData(this.payload(hisdata), hisDest);
        temp_result.push(hisdata);
      } else {
        let data = await this.yp.await_proc(
          "forward_proc",
          entity_id,
          "channel_post_message_next",
          `'${stringify(input)}','${msg.message}'`
        );
        await this.yp.await_proc(
          "forward_proc",
          entity_id,
          "channel_post_attachment",
          `'${message_id}','${entity_id}','${stringify(input.attachment)}'`
        );
        data.is_attachment = 0;
        if (!isEmpty(input.attachment)) {
          data.is_attachment = 1;
        }
        let profile = this.user.get("profile") || {};
        data.firstname = this.user.get(Attr.firstname);
        data.lastname = profile.lastname;
        data.hub_id = entity_id;
        let recipients = await this.yp.await_proc("entity_sockets", entity_id);
        await RedisStore.sendData(this.payload(data), recipients);
        temp_result.push(data);
      }
    }

    return temp_result;
  }

  /**
   *
   */
  async post() {
    let entity_id = this.input.need(Attr.entity_id);
    let message = this.input.use(Attr.message) || "";
    let thread_id = this.input.use(Attr.thread_id);
    let attachment = this.input.use(Attr.attachment) || [];
    let sanity = await this._checkPostSanity(entity_id, thread_id, attachment);
    if (!sanity.ok) {
      this.output.data(sanity);
      return;
    }
    let input = {};
    let message_id = await this.yp.await_func("uniqueId");
    let sbox = await this.db.call_proc("mfs_wicket_home", this.uid);
    if (!isEmpty(attachment)) {
      let desdir = await this.yp.await_proc(
        "forward_proc",
        sbox.hub_id,
        "mfs_make_dir",
        `'${sbox.chat_id}','${stringify(message_id)}',1`
      );
      attachment = await this.move_attachemnt(
        sbox,
        desdir,
        attachment,
        message_id
      );
    }
    input.author_id = this.uid;
    input.uid = this.uid;
    if (!isEmpty(attachment)) {
      input.attachment = attachment;
    }
    if (!isEmpty(message)) {
      message = message.replace(/'/gi, "''");
    }
    if (!isEmpty(thread_id)) {
      input.thread_id = thread_id;
    }
    if (!isEmpty(message_id)) {
      input.message_id = message_id;
    }
    let res = await this._distributeMessage(input, message, thread_id, [
      entity_id,
    ]);
    this.output.data(res);
  }

  /**
   *
   */
  async forward() {
    let entities = this.input.need(Attr.entities) || [];
    let nodes = this.input.need(Attr.nodes) || {};
    let forwards = [];

    let temp_result = [];

    let forward_data = await this.db.await_proc("forward_message_get", nodes);
    forward_data = this.parseJSON(forward_data.result);
    for (let node of forward_data) {
      node = this.parseJSON(node);
      if (!isEmpty(node.attachment)) {
        node.attachment = this.parseJSON(node.attachment);
      }
      forwards.push(node);
    }
    for (let msg of forwards) {
      let input = {
        author_id: this.uid,
        uid: this.uid,
        message: "",
      };
      if (!isEmpty(msg.attachment)) {
        input.attachment = msg.attachment;
      }
      if (isEmpty(msg.message)) {
        msg.message = "";
      }
      if (!isEmpty(msg.forward_message_id)) {
        input.forward_message_id = msg.forward_message_id;
      }
      if (!isEmpty(msg.message)) {
        msg.message = msg.message.replace(/'/gi, "''");
      }

      let r = await this._distributeMessage(input, msg.message, null, entities);
      temp_result = temp_result.concat(r);
    }
    this.output.data(temp_result);
  }

  /**
   *
   */
  async pages_to_read() {
    let entity_id = this.input.need(Attr.entity_id);
    let res = {};

    data = await this.db.await_proc(
      "my_contact_exists",
      "entity",
      entity_id,
      null,
      null
    );
    if (isEmpty(data)) {
      res.status = "INVALID_CONTACT";
      return this.output.data(res);
    }

    if (data.uid != entity_id) {
      res.status = "INVALID_CONTACT";
      return this.output.data(res);
    }

    res = await this.db.await_proc("pages_to_read", entity_id, this.uid);
    this.output.data(res);
  }

  /**
   *
   */
  async change_status() {
    let entity_id = this.input.need(Attr.entity_id);
    let status = this.input.need(Attr.status);
    let res = {};

    if (!["archived", "active"].includes(status)) {
      res.status = "INVALID_STATUS0";
      return this.output.data(res);
    }

    if (status == "archived") {
      res = await this.db.await_proc("archive_entity", entity_id);
    } else {
      res = await this.db.await_proc("unarchive_entity", entity_id);
    }
    //await this.notify_user(this.uid, res);
    let dest = await this.yp.await_proc("user_sockets", this.uid);
    await RedisStore.sendData(
      this.payload(res, { keys: { entity_id: Attr.hub_id } }),
      dest
    );
    // this.pushLiveUpdate({
    //   service: this.input.get(Attr.service),
    //   dest: {
    //     area: Attr.personal,
    //     type: Attr.drumate,
    //     hub_id: this.uid
    //   },
    //   model: res,
    //   keys: { entity_id: Attr.hub_id }

    //});

    this.output.data(res);
  }

  /**
   *
   */
  async messages() {
    let entity_id = this.input.need(Attr.entity_id);
    let page = this.input.use(Attr.page) || 1;
    let nodes = {};
    let db_name = this.user.get(Attr.db_name);
    let entity = await this.yp.await_proc(
      `${db_name}.shareroom_contact_get`,
      entity_id
    );
    nodes = {
      page: page,
      entity_id: entity_id,
    };

    let data = await this.db.await_proc("list_message", nodes);

    if (!isArray(data)) {
      data = [data];
    }
    let messages = [];
    let recipients = [];
    for (let message of data) {
      message.entity = { id: this.uid };
      if (message.entity_id != this.uid) {
        message.entity = entity;
      }

      if (message.is_notify == 1) {
        recipients.push(message.author_id);
      }
      if (!isEmpty(message.thread_id)) {
        message.thread = await this.threadInfo(message.thread_id, this.uid);
      }
      messages.push(message);
    }
    let dest = await this.yp.await_proc("user_sockets", recipients);
    await RedisStore.sendData(
      this.payload(messages, { service: "chat.acknowledge" }),
      dest
    );

    dest = await this.yp.await_proc("user_sockets", this.uid);
    let model = await this.db.await_proc("notification_center_next");
    await RedisStore.sendData(
      this.payload(model, { service: "messages.read" }),
      dest
    );

    this.output.list(messages);
  }

  async _getAttachmentsInfo(attachments, uid, page) {
    let files = [];

    for (let media of attachments) {
      let file = await this._getAttachmentInfo(uid, media);
      file.page = page;
      files.push(file);
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
    let attr;
    if (typeof media.hub_id !== "undefined") {
      attr = await this.yp.await_proc(
        "forward_proc",
        media.hub_id,
        "mfs_access_node",
        `'${uid}', '${media.nid}'`
      );
    } else {
      attr = await this.yp.await_proc(
        "forward_proc",
        uid,
        "mfs_access_node",
        `'${uid}', '${media}'`
      );
    }
    attr.privilege = attr.permission;
    delete attr["permission"];
    return this.output.sanitize(attr);
  }

  /**
   *
   */
  async delete() {
    let option = this.input.need(Attr.option);
    let messages = this.input.need(Attr.messages);
    let res = {};
    let data = {};
    let temp_result = [];
    if (option != "me" && option != "all") {
      res.status = "INVALID_OPTION";
      return this.output.data(res);
    }
    let invalid_messageid = 0;
    let invalid_option = 0;
    for (let message_id of messages) {
      data = await this.db.await_proc("channel_get", message_id);
      if (isEmpty(data)) {
        invalid_messageid = invalid_messageid + 1;
      }
      if (!isEmpty(data)) {
        if (option == "all" && data.author_id != this.uid) {
          invalid_option = invalid_option + 1;
        }
      }
    }

    if (invalid_messageid > 0) {
      res.status = "INVALID_MESSAGES";
      return this.output.data(res);
    }

    if (invalid_option > 0) {
      res.status = "INVALID_OPTION";
      return this.output.data(res);
    }
    let result;
    if (option == "all") {
      result = await this.db.await_proc(
        "channel_delete_drumate_all",
        this.uid,
        option,
        stringify(messages)
      );
    } else {
      result = await this.db.await_proc(
        "channel_delete_drumate_me",
        this.uid,
        option,
        stringify(messages)
      );
    }
    data = result.shift() || [];
    if (!isArray(data)) {
      data = [data];
    }
    for (let message of data) {
      if (!isEmpty(message.delete_attachment)) {
        message.delete_attachment = this.parseJSON(message.delete_attachment);

        for (let tempattach of message.delete_attachment) {
          tempattach = this.parseJSON(tempattach);
          let sbox = await this.yp.await_proc(
            "forward_proc",
            tempattach.hub_id,
            "mfs_home",
            ``
          );
          let src = {
            nid: tempattach.nid,
            hub_id: tempattach.hub_id,
            mfs_root: sbox.home_dir + "/__storage__/",
          };
          await remove_node(src);
        }
      }

      temp_result.push(message);
      if (option == "all") {
        let dest = await this.yp.await_proc("user_sockets", message.entity_id);
        await RedisStore.sendData(
          this.payload(message, { keys: ["message_id"] }),
          dest
        );
      }
    }
    data = result.shift();
    if (!isArray(data)) {
      data = [data];
    }
    for (let msg of data) {
      let dest = await this.yp.await_proc("user_sockets", msg.uid);
      await RedisStore.sendData(
        this.payload(msg, { service: "chat.roominfo" }),
        dest
      );
    }
    this.output.list(temp_result);
  }

  /**
   *
   */
  async remove_attachment() {
    let nid = this.input.need(Attr.nid);
    let res = {};
    let file = await this.db.await_proc("mfs_access_node", this.uid, nid);
    if (isEmpty(file)) {
      res.status = "INVALID_ATTACHMENT";
      return this.output.data(res);
    }
    if (!includes(file.file_path, "/__chat__/__upload__/")) {
      res.status = "INVALID_ATTACHMENT";
      return this.output.data(res);
    }
    if (file.ftype == "folder" || file.ftype == "hub") {
      res.status = "INVALID_ATTACHMENT";
      return this.output.data(res);
    }

    await this.db.await_proc("mfs_attachment_remove", nid);
    let mfs_home = await this.db.await_proc("mfs_home");
    let src = {
      nid: nid,
      hub_id: this.hub.get(Attr.id),
      mfs_root: mfs_home.home_dir + "/__storage__/",
    };
    await remove_node(src);
    this.output.data(file)
  }

  /**
   *
   */
  count_all() {
    this.db.call_proc("all_read_count", this.output.data);
  }
}

module.exports = privateChat;
