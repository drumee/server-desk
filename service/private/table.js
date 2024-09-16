// ================================  *
//   Copyright Xialia.com  2013-2017 *
//   FILE  : src/service/private/admin
//   TYPE  : module
// ================================  *

const { Attr, Events } = require("@drumee/server-essentials");

const { isEmpty, isArray, isString } = require("lodash");
const { Entity } = require("@drumee/server-core");


/**
 * Experimental. 
 * Create tables attached to the hub
 */
class __custom extends Entity {

  /**
   * 
   * @param {*} row 
   * @returns 
   */
  _makeColumn(row) {
    let deft;
    let s = "";
    const type = row.type.toLocaleLowerCase();
    const attr = row.attribute || "";
    if (!isEmpty(row.default)) {
      switch (type) {
        case "mediumtext":
        case "enum":
          deft = `default \"${row.default}\"`;
          break;
        case "int":
        case "integer":
        case "float":
          deft = `default ${row.default}`;
          break;
        default:
          deft = `default ${row.default}`;
      }
      if (row.default.toLocaleLowerCase() === "null") {
        deft = "default null";
      }
    } else {
      deft = "";
    }
    //@debug "DDDDDDDDDDDDDD", type, deft
    switch (type) {
      case "mediumtext":
        s = `${type} ${attr} ${deft}`;
        break;
      case "enum":
        var a = [];
        for (let i of row.value) {
          a.push(`\"${i}\"`);
        }
        s = `${type}(${a.join(",")}) ${attr} ${deft}`;
        break;
      case "int":
      case "integer":
      case "float":
        s = `${type}(${row.value}) ${attr} ${deft}`;
        break;
      default:
        s = `${type}(${row.value}) ${attr} ${deft}`;
    }
    return s;
  }

  // ========================
  //
  //
  // ========================
  _makeKey(row) {
    let s;
    if (isEmpty(row.value)) {
      s = `\`${row.name}\`(\`${row.name}\`)`;
      return s;
    }
    const columns = row.value;
    let c = columns.shift();
    if (isEmpty(columns)) {
      s = `\`${row.name}\`(\`${c}\`)`;
      return s;
    }
    const k = [];
    for (c of columns) {
      k.push(`\`${c}\``);
    }
    s = `\`${row.name}\`(${k.join(",")})`;
    return s;
  }

  // ========================
  //
  //
  // ========================
  create_table() {
    const name = this.input.need(Attr.name);
    const columns = this.input.need(Attr.columns);
    const keys = this.input.need(Attr.keys);
    const opt = {
      name,
      columns,
      keys,
    };
    this.debug("OOOOOO 37:::::", opt);
    const rows = [];
    for (let c of columns) {
      rows.push(`\`${c.name}\` ${this._makeColumn(c)}`);
    }
    if (keys != null) {
      for (let k of keys) {
        const type = k.type || "";
        rows.push(`${type} KEY ${this._makeKey(k)}`);
      }
    }
    this.db.call_proc(
      "custom_table_register",
      name,
      this.uid,
      function (row) {
        if (isEmpty(row)) {
          this.output.data(row);
          return;
        }
        const query = `CREATE TABLE \`${row.table_name}\`(${rows.join(",")})`;
        //@debug "qqqqqqqqqqq=#{query}====qqqqq"
        return this.query(query, (e, d, f) => {
          if (e != null) {
            this.exception.server(`QUERY ERROR : ${query}`, e);
            return;
          }
          this.output.data(row);
        });
      }.bind(this)
    );
  }

  // ========================
  //
  //
  // ========================
  delete_table() {
    const name = this.input.need(Attr.name);
    return this.db.call_proc("custom_table_delete", name, this.output.data);
  }

  // ========================
  //
  //
  // ========================
  insert_row() {
    const name = this.input.use(Attr.name) || this.input.need(Attr.id);
    const values = this.input.use(Attr.values) || this.input.use(Attr.value);
    if (!isArray(values)) {
      this.reject("_values_must_be_array");
      return;
    }
    return this.db.call_proc(
      "custom_row_insert",
      name,
      JSON.stringify(values),
      this.output.data
    );
  }

  // ========================
  //
  //
  // ========================
  _sanitizeColumn(columns = ["*"]) {
    const k = [];
    for (let c of columns) {
      k.push(c.replace(/[,; ]/, ""));
    }
    return k.join(",");
  }

  // ========================
  //
  //
  // ========================
  _sanitizeFilter(filter = []) {
    const k = [];
    for (let token of filter) {
      if (isString(token)) {
        k.push(token.replace(/[,; ]/, ""));
      }
    }
    return k.join(" ");
  }

  // ========================
  //
  //
  // ========================
  _sanitizeOrder(order = []) {
    const k = [];
    for (let token of order) {
      if (isString(token)) {
        k.push(token.replace(/[,; ]/, " "));
      }
    }
    return k.join(" ");
  }

  // ========================
  //
  //
  // ========================
  fetch() {
    const name = this.input.use(Attr.name) || this.input.need(Attr.id);
    if (isEmpty(name)) {
      this.exception.precondition("name is required");
      return;
    }
    const c = this._sanitizeColumn(
      this.input.use(Attr.columns) || this.input.use(Attr.select)
    );
    let f = this._sanitizeFilter(
      this.input.use(Attr.filter) || this.input.use(Attr.where)
    );
    let o = this._sanitizeOrder(this.input.use(Attr.order));
    let page = this.input.use(Attr.page);
    const page_length = this.input.use(Attr.page_length) || 15;
    let l = "";
    if (page != null) {
      if (page <= 0) {
        page = 1;
      }
      l = `LIMIT ${(page - 1) * page_length}, ${page_length}`;
    } else if (this.input.use(Attr.limit) != null) {
      l = `LIMIT ${this.input.use(Attr.limit)}`;
    }
    if (!isEmpty(f)) {
      f = `WHERE ${f}`;
    }
    if (!isEmpty(o)) {
      o = `ORDER BY ${o}`;
    }
    return this.db.call_proc(
      "custom_table_get",
      name,
      function (row) {
        if (isEmpty(row)) {
          this.output.data(row);
          return;
        }
        const query = `SELECT ${c} FROM \`${row.table_name}\` ${f} ${o} ${l}`;
        return this.query(query, (e, d, f) => {
          if (e != null) {
            this.exception.server(`QUERY ERROR : ${query}`, e);
            return;
          }
          this.debug(`QQQQQQQQQQQ =${query} =p=${page}==========`, d);
          return this.output.data(d);
        });
      }.bind(this)
    );
  }
}

module.exports = __custom;
