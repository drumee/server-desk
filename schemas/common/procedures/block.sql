DELIMITER $

-- #########################################################
--
-- BLOCKS SECTION
--
-- #########################################################

-- Get user's home (top) directory
-- =========================================================
DROP PROCEDURE IF EXISTS `block_home`$
CREATE PROCEDURE `block_home`(
)
BEGIN
  DECLARE _languages VARCHAR(512);
  SELECT
    area, concat(TRIM(TRAILING '/' FROM home_dir), '/Block/'), id from yp.entity where db_name=database()
  INTO @area, @root, @entity_id;
  SELECT GROUP_CONCAT(DISTINCT `base` SEPARATOR ':' ) FROM `language` WHERE `state`='active'
    INTO _languages;

  SELECT 
    @area as area, 
    @entity_id as eid, 
    @root AS block_root,
   _languages AS languages;
END $

-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `block_exists`$
CREATE PROCEDURE `block_exists`(
  IN _hashtag        VARCHAR(512)
)
BEGIN
  SELECT id FROM block WHERE hashtag = _hashtag;
END $

-- =========================================================
-- Next Version
-- =========================================================
DROP PROCEDURE IF EXISTS `block_rename_new`$
CREATE PROCEDURE `block_rename_new`(
   IN _id             VARCHAR(16),
   IN _hashtag        VARCHAR(512)
)
BEGIN
   DECLARE _hash_exist INT(4) DEFAULT 0;
   DECLARE _eid VARCHAR (16);

   SELECT EXISTS (SELECT id FROM block WHERE id <> _id AND hashtag = _hashtag) INTO _hash_exist;

   IF _hash_exist = 0 THEN
    UPDATE block SET hashtag=_hashtag WHERE id=_id;
    UPDATE block_history SET meta=_hashtag WHERE master_id=_id;
   END IF;
  
  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _eid;
  -- CALL yp.set_homepage(_eid);   


   SELECT
      *,
      _hash_exist AS hash_exist
   FROM block WHERE id=_id;

END $

-- =========================================================
-- Next Version
-- =========================================================

DROP PROCEDURE IF EXISTS `block_copy_new`$
CREATE PROCEDURE `block_copy_new`(
   IN _history_id     VARCHAR(16),
   IN _author         VARCHAR(160),
   IN _to_lang        VARCHAR(20),
   IN _hashtag        VARCHAR(512),
   IN _new_page       VARCHAR(10)
)
BEGIN
   DECLARE _id VARBINARY(16) DEFAULT '';
   DECLARE _new_id VARBINARY(16) DEFAULT '';
   DECLARE _version TINYINT(4);
   DECLARE _tag VARCHAR(512);
   DECLARE _ident VARCHAR(512);
   DECLARE _lang varchar(10);
   DECLARE _device varchar(100);
   DECLARE _ts INT(11) DEFAULT 0;
   DECLARE _last INT(11) DEFAULT 0;
   DECLARE _block_exist INT(4) DEFAULT 0;

   SELECT UNIX_TIMESTAMP() INTO _ts;

   START TRANSACTION;
   SELECT master_id, lang, device FROM block_history WHERE serial = _history_id INTO _id, _lang, _device;
   
   SELECT EXISTS (SELECT serial FROM block_history WHERE master_id = _id AND lang = _to_lang AND device = _device) INTO _block_exist;
   IF _lang <> _to_lang AND _block_exist = 1 AND _new_page = "0" THEN
      SELECT 1 AS confirm_copy;
   ELSE
      IF _lang = _to_lang OR (_block_exist = 1 AND _lang <> _to_lang AND _new_page = "1") THEN
        SELECT UNIQUEID() INTO _new_id;
        IF IFNULL(_hashtag, '') = "" THEN
          SELECT hashtag FROM block WHERE id = _id INTO _hashtag;
          -- SELECT COUNT(*) FROM block WHERE hashtag LIKE concat(_hashtag, '-v%') INTO _version;
          -- SET _hashtag = CONCAT(_hashtag, '-v', _version);
          -- SELECT COUNT(*) FROM block WHERE hashtag = _hashtag INTO _version;
          -- WHILE _version > 0 DO
          --     SET _version = _version + 1;
          --     SET _hashtag = CONCAT(_hashtag, '-v', _version);
          --     SELECT COUNT(*) FROM block WHERE hashtag = _hashtag INTO _version;
          -- END WHILE;
          SELECT IFNULL(MAX(SUBSTRING_INDEX(hashtag, '-v', -1)),-1) as d FROM block
            WHERE hashtag REGEXP CONCAT(_hashtag, '-v[0-9]*$') INTO _version;
          SET _hashtag = CONCAT(_hashtag, '-v', _version + 1);

        END IF;
      ELSE
          SELECT _id INTO _new_id;
      END IF;

      UPDATE block_history SET status = 'history' WHERE master_id = _new_id AND lang = _to_lang AND device = _device;
      INSERT INTO block_history (`author_id`, `master_id`, `lang`, `device`, `status`, `isonline`, `meta`, `ctime`)
          VALUES(_author, _new_id, _to_lang, _device, 'draft', 0, _hashtag, _ts);
      SELECT LAST_INSERT_ID() INTO _last;

      IF _lang = _to_lang OR (_block_exist = 1 AND _lang <> _to_lang AND _new_page = "1") THEN
          INSERT INTO block (sys_id, id, serial, active, author_id, hashtag, `type`, editor, status, ctime, mtime, version)
              SELECT null, _new_id, _last, _last, _author, _hashtag, `type`, editor, status, _ts, _ts, version
              FROM block WHERE id=_id;
      END IF;
      COMMIT;
      SELECT *, _hashtag AS hashtag, _id as src_id, 0 AS confirm_copy FROM block_history WHERE serial=_last;
   END IF;
END $

-- =========================================================
-- Next version
-- =========================================================
DROP PROCEDURE IF EXISTS `block_update_new`$
CREATE PROCEDURE `block_update_new`(
   IN _id           VARCHAR(512),
   IN _history_id   INT(11),
   IN _lang         VARCHAR(20),
   IN _isonline     INT(4)
)
BEGIN
   DECLARE _ts INT(11) DEFAULT 0;
   SELECT UNIX_TIMESTAMP() INTO _ts;
   UPDATE block_history SET status = 'history' WHERE master_id=_id AND lang = _lang;
   UPDATE block_history SET status = 'draft' WHERE master_id=_id AND lang = _lang AND serial=_history_id;

   IF _isonline = 1 THEN
      UPDATE block_history SET isonline = 0 WHERE master_id=_id AND lang = _lang;
      UPDATE block_history SET isonline = 1 WHERE master_id=_id AND lang = _lang AND serial=_history_id;
   END IF;
   
   UPDATE block SET serial=_history_id, active=_history_id,mtime=_ts WHERE id=_id;
   SELECT id, active, hashtag FROM block WHERE id=_id;
END $


-- =========================================================
-- Next version
-- =========================================================
DROP PROCEDURE IF EXISTS `block_save_int`$
CREATE PROCEDURE `block_save_int`(
   IN _inId      VARCHAR(16),
   IN _hashtag   VARCHAR(512),
   IN _editor    VARCHAR(16),
   IN _type      VARCHAR(20),
   IN _device    VARCHAR(16),
   IN _lang      VARCHAR(20),
   IN _isonline  INT(4),
   IN _author_id VARBINARY(16),
   IN _vesrion   VARCHAR(16)
)
BEGIN
   DECLARE _id   VARBINARY(16) DEFAULT '';
   DECLARE _ts   INT(11) DEFAULT 0;
   DECLARE _last INT(11) DEFAULT 0;
   DECLARE _hash_exist INT(4) DEFAULT 0;
   DECLARE _eid VARCHAR (16);

   SELECT UNIX_TIMESTAMP() INTO _ts;

   IF CAST(_inId as CHAR(16))='0' OR _inId='0' THEN
     SELECT yp.uniqueId() INTO _id;
   ELSE
     SELECT _inId INTO _id;
   END IF;

   SELECT EXISTS (SELECT id FROM block WHERE id <> _id AND hashtag = _hashtag) INTO _hash_exist;
   SELECT IFNULL(max(serial) + 1,1) FROM block_history INTO _last;
   IF _hash_exist = 0 THEN
    START TRANSACTION;

    INSERT INTO block_history (`serial`, `author_id`, `master_id`, `lang`, `device`, `meta`, `ctime`)
        VALUES(_last, _author_id, _id, _lang, _device, _hashtag, _ts);
    

    UPDATE block_history SET status = 'history' WHERE master_id=_id AND lang = _lang;
    UPDATE block_history SET status = 'draft' WHERE master_id=_id AND lang = _lang AND serial=_last;

    IF _isonline = 1 THEN
        UPDATE block_history SET isonline = 0 WHERE master_id=_id AND lang = _lang;
        UPDATE block_history SET isonline = 1 WHERE master_id=_id AND lang = _lang AND serial=_last;
    END IF;
    INSERT INTO block
      (`id`, `hashtag`, `author_id`, `editor`, `type`, `serial`, `active`, `status`, `ctime`, `mtime`, `version`)
      VALUES(_id, _hashtag, _author_id, _editor, _type, _last, _last, 'offline', _ts, _ts, _vesrion)
      ON DUPLICATE KEY UPDATE serial=_last, active=_last, mtime=_ts;
    
    SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _eid;
    CALL yp.set_default_homepage(_eid);
   
    
    COMMIT;

    SELECT _id as id, _last as active, _hashtag as hashtag, _hash_exist AS hash_exist;
   ELSE
    SELECT _id as id, _hashtag as hashtag, _hash_exist AS hash_exist;
   END IF;

END $
-- =========================================================
-- Gets list of draft or published pages in a language.
-- =========================================================
DROP PROCEDURE IF EXISTS `block_info`$
CREATE PROCEDURE `block_info`(
  IN _hashtag      VARCHAR(500)
)
BEGIN
  SELECT * FROM block WHERE hashtag=_hashtag;
END$

-- =========================================================
-- Gets list of draft or published pages in a language.
-- =========================================================
DROP PROCEDURE IF EXISTS `block_get_draft_publish`$
CREATE PROCEDURE `block_get_draft_publish`(
   IN _locale       VARCHAR(100),
   IN _published    INT(4),
   IN _hashtag      VARCHAR(500),
   IN _sort_by      VARCHAR(100),
   IN _sort         VARCHAR(100),
   IN _page         INT(11)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);
  SELECT bh.serial AS history_id, id AS block_id, lang, device, bh.status,
    isonline, hashtag  FROM block b INNER JOIN block_history bh ON b.id = bh.master_id
    WHERE lang = _locale AND hashtag LIKE CONCAT('%', TRIM(IFNULL(_hashtag,'')), '%')
    AND CASE WHEN _published = 1 OR _published = 2 THEN 
      CASE WHEN _published = 2 THEN (bh.status = 'draft' OR isonline=1)
      ELSE isonline = 1 END
    ELSE bh.status = 'draft' END
    ORDER BY
    CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_sort) = 'asc' THEN b.mtime END ASC,
    CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_sort) = 'desc' THEN b.mtime END DESC,
    CASE WHEN LCASE(_sort) = 'desc' THEN hashtag END DESC,
    CASE WHEN LCASE(_sort) <> 'desc' THEN hashtag END ASC
    LIMIT _offset, _range;
END$

-- =========================================================
-- Gets list of block ids by language locale.
-- =========================================================
DROP PROCEDURE IF EXISTS `block_id_get_by_lang`$
CREATE PROCEDURE `block_id_get_by_lang`(
   IN _locale       VARCHAR(100)
)
BEGIN
  SELECT master_id as block_id FROM block_history WHERE lang=_locale GROUP BY master_id;
END$

-- =========================================================
-- Deletes list of blocks by language locale.
-- =========================================================
DROP PROCEDURE IF EXISTS `block_delete_by_lang`$
CREATE PROCEDURE `block_delete_by_lang`(
   IN _locale       VARCHAR(100)
)
BEGIN
  DELETE FROM block_history WHERE lang=_locale;
  DELETE block FROM block WHERE id NOT IN (SELECT master_id FROM block_history);
END$

-- =========================================================
-- Gets list of draft and published blocks in a language.
-- =========================================================
DROP PROCEDURE IF EXISTS `block_get_base_by_lang`$
CREATE PROCEDURE `block_get_base_by_lang`(
   IN _base_lang       VARCHAR(100)
)
BEGIN
  SELECT serial AS history_id, master_id AS block_id, lang, device, status, isonline, meta
    FROM block_history WHERE (lang = _base_lang AND isonline=1)
    OR (lang = _base_lang AND status='draft' AND isonline=0);
END$

-- =========================================================
-- Gets list of draft and published blocks in a language.
-- =========================================================
DROP PROCEDURE IF EXISTS `block_add_history`$
CREATE PROCEDURE `block_add_history`(
   IN _id        VARCHAR(512),
   IN _hashtag   VARCHAR(512),
   IN _device    VARCHAR(16),
   IN _lang      VARCHAR(20),
   IN _status    VARCHAR(20),
   IN _isonline  INT(4),
   IN _author_id VARBINARY(16)
)
BEGIN
    DECLARE _ts   INT(11) DEFAULT 0;
    SELECT UNIX_TIMESTAMP() INTO _ts;
    INSERT INTO block_history (`author_id`, `master_id`, `lang`, `device`, `meta`, `status`, `isonline`, `ctime`)
      VALUES(_author_id, _id, _lang, _device, _hashtag, _status, _isonline, _ts);
    SELECT LAST_INSERT_ID() as history_id;
END$

-- =========================================================
-- Gets list of published pages in a language.
-- =========================================================
DROP PROCEDURE IF EXISTS `block_history_check_published`$
CREATE PROCEDURE `block_history_check_published`(
   IN _id           VARCHAR(512),
   IN _locale       VARCHAR(100),
   IN _device       VARCHAR(16)
)
BEGIN
  SELECT EXISTS (SELECT serial FROM block_history WHERE master_id = _id AND isonline = 1
    AND lang = _locale AND device = _device) AS IS_PUBLISHED;
END$

-- =========================================================
-- Deletes a blocks by block id and language locale.
-- =========================================================
DROP PROCEDURE IF EXISTS `block_delete_by_id_lang`$
CREATE PROCEDURE `block_delete_by_id_lang`(
   IN _id           VARCHAR(512),
   IN _locale       VARCHAR(100),
   IN _device       VARCHAR(16)
)
BEGIN
  
  DECLARE _eid VARCHAR (16);

  DELETE FROM block_history WHERE master_id = _id AND lang = _locale AND device = _device;
  DELETE block FROM block WHERE id = _id AND id NOT IN (SELECT master_id
    FROM block_history WHERE master_id = _id);
  
  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _eid;
  -- CALL yp.set_homepage(_eid);


END$


-- =========================================================
-- Next version
-- =========================================================
DROP PROCEDURE IF EXISTS `block_unpublish`$
CREATE PROCEDURE `block_unpublish`(
   IN _id           VARCHAR(512),
   IN _locale       VARCHAR(100),
   IN _device       VARCHAR(16)
)
BEGIN
   DECLARE _history_id   INT(11) DEFAULT 0;
   DECLARE _ts INT(11) DEFAULT 0;
   SELECT serial INTO _history_id FROM block_history WHERE master_id = _id AND isonline = 1 AND lang = _locale AND device = _device;
   SELECT UNIX_TIMESTAMP() INTO _ts;
   UPDATE block_history SET status = 'history', isonline = 0 WHERE master_id=_id AND lang = _locale AND device = _device;
   UPDATE block_history SET status = 'draft' WHERE serial=_history_id;
   UPDATE block SET serial=_history_id, active=_history_id,mtime=_ts WHERE id=_id;
   SELECT id, active, hashtag, _history_id AS history_id FROM block WHERE id=_id;
END $

-- =========================================================
-- block_new
-- =========================================================
DROP PROCEDURE IF EXISTS `block_save`$
CREATE PROCEDURE `block_save`(
   IN _inId      VARCHAR(16),
   IN _hashtag   VARCHAR(512),
   IN _editor    VARCHAR(16),
   IN _type      VARCHAR(20),
   IN _device    VARCHAR(16),
   IN _lang      VARCHAR(20),
   IN _author_id VARBINARY(16),
   IN _vesrion   VARCHAR(16)
)
BEGIN
   DECLARE _id   VARBINARY(16) DEFAULT '';
   DECLARE _ts   INT(11) DEFAULT 0;
   DECLARE _last INT(11) DEFAULT 0;

   SELECT UNIX_TIMESTAMP() INTO _ts;

   IF CAST(_inId as CHAR(16))='0' OR _inId='0' THEN
     SELECT yp.uniqueId() INTO _id;
   ELSE
     SELECT _inId INTO _id;
   END IF;

   START TRANSACTION;

   INSERT INTO block_history (`author_id`, `master_id`, `lang`, `device`, `meta`, `ctime`)
         VALUES(_author_id, _id, _lang, _device, _hashtag, _ts);
   SELECT LAST_INSERT_ID() INTO _last;

   INSERT INTO block
     (`id`, `hashtag`, `author_id`, `editor`, `type`, `serial`, `active`, `status`, `ctime`, `mtime`, `version`)
     VALUES(_id, _hashtag, _author_id, _editor, _type, _last, _last, 'offline', _ts, _ts, _vesrion)
     ON DUPLICATE KEY UPDATE serial=_last, active=_last, mtime=_ts;

   COMMIT;

   SELECT _id as id, _last as active, _hashtag as hashtag;

END $


-- DROP PROCEDURE IF EXISTS `block_get`$
-- CREATE PROCEDURE `block_get`(
--    IN _tag VARCHAR(512),
--    IN _device  VARCHAR(16),
--    IN _lang  VARCHAR(16)
-- )
-- BEGIN
--    DECLARE _id VARBINARY(16) DEFAULT '';
--    SELECT block.id, active, hashtag, `type`, editor, status, firstname, lastname ctime, mtime, version
--          FROM block LEFT JOIN yp.drumate ON author_id=drumate.id WHERE block.id=_tag OR hashtag=_tag;

-- END $

-- =========================================================
-- block_get
-- returns :
--   everything when exists with wanted language and device
--   only id when exists with other languages and/or device
--   nothing when it doesn't exists at all
-- =========================================================
DROP PROCEDURE IF EXISTS `block_get`$
CREATE PROCEDURE `block_get`(
   IN _tag VARCHAR(512),
   IN _device  VARCHAR(16),
   IN _lang  VARCHAR(16)
)
BEGIN
   DECLARE _existence INT(4);
   SELECT EXISTS (
    SELECT master_id FROM block LEFT JOIN block_history 
      ON master_id = block.id 
      WHERE block.id=_tag OR hashtag=_tag
      AND lang = _lang AND device = _device
   ) INTO _existence;
          
  IF _existence THEN
   SELECT 
    block.id, 
    active, 
    hashtag, 
    `type`, 
    editor, 
    block.status, 
    firstname, 
    lastname,
    ctime, 
    mtime, 
    version
      FROM block LEFT JOIN yp.drumate ON block.author_id=drumate.id
      WHERE (block.id=_tag OR hashtag=_tag);
      -- AND EXISTS (
      --   SELECT master_id FROM block_history WHERE master_id = block.id 
      --     AND lang = _lang AND device = _device
      -- );
  ELSE
    SELECT id, status FROM block WHERE id=_tag OR hashtag=_tag;
  END IF;
END $


-- =========================================================
-- block_get
-- =========================================================
-- DROP PROCEDURE IF EXISTS `block_get`$
-- CREATE PROCEDURE `block_get`(
--    IN _tag VARCHAR(512),
--    IN _device  VARCHAR(16),
--    IN _lang  VARCHAR(16)
-- )
-- BEGIN
--   SELECT 
--   block.id, 
--   active, 
--   hashtag, 
--   `type`, 
--   editor, 
--   block.status, 
--   firstname, 
--   lastname,
--   ctime, 
--   mtime, 
--   version
--     FROM block LEFT JOIN yp.drumate ON block.author_id=drumate.id
--     WHERE (block.id=_tag OR hashtag=_tag)
--     AND EXISTS (
--       SELECT master_id FROM block_history WHERE master_id = block.id 
--         AND lang = _lang AND device = _device
--     );
-- END $

-- =========================================================
-- block_get
-- =========================================================
DROP PROCEDURE IF EXISTS `block_get_by_type`$
CREATE PROCEDURE `block_get_by_type`(
   IN _tag VARCHAR(512),
   IN _device  VARCHAR(16),
   IN _lang  VARCHAR(16),
   IN _type  VARCHAR(16)

)
BEGIN
   SELECT block.id, active, hashtag, `type`, editor, status, firstname, lastname ctime, mtime, version
         FROM block LEFT JOIN yp.drumate ON author_id=drumate.id WHERE `type`=_type;
END $

-- =========================================================
-- block_get_by_id
-- =========================================================
DROP PROCEDURE IF EXISTS `block_get_by_id`$
CREATE PROCEDURE `block_get_by_id`(
   IN _key VARCHAR(512)
)
BEGIN
  SELECT block.id, active, hashtag, `type`, editor, status, firstname, lastname ctime, mtime, version
    FROM block LEFT JOIN yp.drumate ON author_id=drumate.id WHERE block.id = _key OR hashtag= _key;
END $

-- =========================================================
-- block_get
-- =========================================================
DROP PROCEDURE IF EXISTS `block_save_menu`$
CREATE PROCEDURE `block_save_menu`(
   IN _device  VARCHAR(16),
   IN _lang  VARCHAR(16)
)
BEGIN
   SELECT block.id, active, hashtag, `type`, editor, status, firstname, lastname ctime, mtime, version
         FROM block LEFT JOIN yp.drumate ON author_id=drumate.id WHERE `type`=_type;
END $



-- =========================================================
-- block_delete purge by
-- =========================================================

DROP PROCEDURE IF EXISTS `block_purge`$
CREATE PROCEDURE `block_purge`(
   IN _tag      varchar(400)
)
BEGIN
   DECLARE _id   VARBINARY(16) DEFAULT '';
   DECLARE _hashtag   varchar(400);

   SELECT id, hashtag FROM block WHERE id=_tag OR hashtag=_tag INTO _id, _hashtag;

   DELETE FROM block_history WHERE master_id=_id;
   DELETE FROM block WHERE id=_id;
   SELECT _id as id, _hashtag as hashtag;

END $


-- =========================================================
-- block_list
-- =========================================================

DROP PROCEDURE IF EXISTS `block_list`$
CREATE PROCEDURE `block_list`(
  IN _page TINYINT(4),
  IN _editor VARCHAR(10),
  IN _criteria VARCHAR(16)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);

  IF _criteria LIKE "D%" THEN
    SELECT
      block.id, serial, active, hashtag, `type`, `status`, `ctime`, `mtime`, `version`,
      remit, firstname, lastname
    FROM block LEFT JOIN yp.drumate on author_id=drumate.id
      WHERE editor=_editor AND (`type`='page' OR `type`= 'block')
      ORDER BY mtime DESC LIMIT _offset, _range;
  ELSE
    SELECT
      block.id, serial, active, hashtag, `type`, `status`, `ctime`, `mtime`, `version`,
      remit, firstname, lastname
    FROM block LEFT JOIN yp.drumate on author_id=drumate.id
      WHERE editor=_editor AND (`type`='page' OR `type`= 'block')
      ORDER BY mtime ASC LIMIT _offset, _range;
  END IF;
END $

-- =========================================================
-- block_log
-- =========================================================

DROP PROCEDURE IF EXISTS `block_log`$
DROP PROCEDURE IF EXISTS `block_history_log`$
CREATE PROCEDURE `block_history_log`(
  IN _tag VARCHAR(400),
  IN _device VARCHAR(16),
  IN _lang VARCHAR(16),
  IN _page TINYINT(4),
  IN _month INT(4),
  IN _year INT(4),
  IN _criteria VARCHAR(16)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  DECLARE _active int(8);
  DECLARE _id   VARBINARY(16) DEFAULT '';
  DECLARE _hashtag   varchar(400);

  SELECT id, hashtag, active FROM block WHERE id=_tag OR hashtag=_tag INTO _id, _hashtag, _active;
  CALL pageToLimits(_page, _offset, _range);

  IF _criteria LIKE "D%" THEN
    SELECT _hashtag AS hashtag, author_id, _id AS id,
       serial, ctime, firstname, lastname,lang, device, IF(serial=_active, 1, 0) AS active,
       FROM_UNIXTIME(ctime) AS created_date, status, isonline
       FROM block_history LEFT JOIN (yp.drumate)
       ON author_id=drumate.id
       WHERE master_id=_id AND lang=_lang AND device=_device
       AND CASE WHEN IFNULL(_month,0) <> 0 AND IFNULL(_year,0) <> 0 THEN
       MONTH(FROM_UNIXTIME(ctime)) = _month ELSE true END
       AND CASE WHEN IFNULL(_year,0) <> 0 THEN
       YEAR(FROM_UNIXTIME(ctime)) = _year ELSE true END
       ORDER BY ctime DESC LIMIT _offset, _range;
  ELSE
    SELECT _hashtag AS hashtag, author_id, _id AS id,
       serial, ctime, firstname, lastname,lang, device, IF(serial=_active, 1, 0) AS active,
       FROM_UNIXTIME(ctime) AS created_date, status, isonline
       FROM block_history LEFT JOIN (yp.drumate)
       ON author_id=drumate.id
       WHERE master_id=_id AND lang=_lang AND device=_device
       AND CASE WHEN IFNULL(_month,0) <> 0 AND IFNULL(_year,0) <> 0 THEN
       MONTH(FROM_UNIXTIME(ctime)) = _month ELSE true END
       AND CASE WHEN IFNULL(_year,0) <> 0 THEN
       YEAR(FROM_UNIXTIME(ctime)) = _year ELSE true END
       ORDER BY ctime ASC LIMIT _offset, _range;
  END IF;
END $


-- ------------------- TO BE REVIEWED --------------------------
-- =========================================================
-- remove_item
-- =========================================================


-- =========================================================
-- remove_thread
-- =========================================================

DROP PROCEDURE IF EXISTS `block_remove_thread`$
CREATE PROCEDURE `block_remove_thread`(
   IN _id      VARBINARY(16)
)
BEGIN
   DELETE FROM block WHERE id=_id;
   DELETE FROM thread WHERE mester_id=_id;
END $


-- =========================================================
-- block_get_thread
-- =========================================================
DROP PROCEDURE IF EXISTS `block_get_thread`$
CREATE PROCEDURE `block_get_thread`(
  IN _key VARCHAR(500),
  IN _criteria VARCHAR(16),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  DECLARE _head int(6);
  DECLARE _hashtag VARCHAR(500);
  DECLARE _id VARBINARY(16);
  DECLARE _status VARCHAR(16);

  CALL pageToLimits(_page, _offset, _range);

  SELECT id, status, active, hashtag FROM block WHERE id=_key OR hashtag=_key
     INTO _id, _status, _head, _hashtag;

  IF _criteria LIKE "D%" THEN
    SELECT serial, author_id, master_id, lang, device, _hashtag as hashtag,
          master_id as id, firstname, lastname, ctime, _head as head
    FROM block_history LEFT JOIN yp.drumate on author_id=drumate.id
      WHERE master_id=_id ORDER BY ctime DESC LIMIT _offset, _range;
  ELSE
    SELECT serial, author_id, master_id, lang, device, _hashtag as hashtag,
          master_id as id, firstname, lastname, ctime, _head as head
    FROM block_history LEFT JOIN yp.drumate on author_id=drumate.id
      WHERE master_id=_id ORDER BY ctime ASC LIMIT _offset, _range;
  END IF;
END $


-- =========================================================
-- remove_item
-- =========================================================

DROP PROCEDURE IF EXISTS `block_remove_item`$
CREATE PROCEDURE `block_remove_item`(
   IN _id      VARBINARY(16)
)
BEGIN
   DELETE FROM block WHERE id=_id;
END $




-- =========================================================
-- block_find
-- =========================================================
DROP PROCEDURE IF EXISTS `block_search`$
CREATE PROCEDURE `block_search`(
  IN _pattern VARCHAR(84),
  IN _page TINYINT(4)
)
BEGIN

  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);

  SELECT
    content as text,
    SUBSTRING(`key`, 1, 16) as id,
    hashtag,
    hashtag as `name`,
    MATCH(content) against(_pattern IN NATURAL LANGUAGE MODE WITH QUERY EXPANSION) as s1,
    MATCH(hashtag) against(concat('*', _pattern, '*') IN BOOLEAN MODE) as s2
  FROM seo HAVING s1 > 0 or s2 > 0 ORDER BY s2 DESC, s1 DESC LIMIT _offset, _range;
END $


-- -- =========================================================
-- -- block_search
-- -- =========================================================
-- DROP PROCEDURE IF EXISTS `block_search`$
-- CREATE PROCEDURE `block_search`(
--   IN _pattern VARCHAR(84),
--   IN _page TINYINT(4)
-- )
-- BEGIN
--
--   DECLARE _range int(6);
--   DECLARE _offset int(6);
--   CALL pageToLimits(_page, _offset, _range);
--
--   SELECT   id,
--     context,
--     get_ident() AS owner,
--     tag as hashtag,
--     author,
--     comment,
--     status,
--     ctime,
--     mtime,
--     version,
--     @vhost AS vhost,
--     MATCH(`content`)
--       against(_pattern IN NATURAL LANGUAGE MODE WITH QUERY EXPANSION) AS nat,
--     MATCH(`content`)
--       against(concat(_pattern, '*') IN BOOLEAN MODE) AS bool
--     FROM block HAVING nat > 1 OR bool > 0 OR hashtag LIKE concat("%", _pattern, "%")
--     ORDER BY nat DESC, mtime ASC LIMIT _offset, _range;
-- END $

-- =========================================================
-- block_search
-- =========================================================
-- DROP PROCEDURE IF EXISTS `block_search`$
-- CREATE PROCEDURE `block_search`(
--   IN _pattern VARCHAR(84),
--   IN _page TINYINT(4)
-- )
-- BEGIN
--
--   DECLARE _range int(6);
--   DECLARE _offset int(6);
--   CALL pageToLimits(_page, _offset, _range);
--
--   SELECT
--     *,
--     @vhost AS vhost,
--     tag as hashtag,
--     + IF(tag = _pattern, 100, 0)
--     + IF(tag LIKE concat(_pattern, "%"), 50, 0)
--     + IF(tag LIKE concat("%", _pattern, "%"), 50, 0) AS score
--     FROM block HAVING  score > 30
--     ORDER BY score DESC, mtime ASC LIMIT _offset, _range;
-- END $


-- =========================================================
-- block_update
-- =========================================================
DROP PROCEDURE IF EXISTS `block_update`$
CREATE PROCEDURE `block_update`(
   IN _id      VARCHAR(16),
   IN _tag     VARCHAR(512),
   IN _author  VARCHAR(160),
   IN _lang    VARCHAR(20),
   IN _device  VARCHAR(20),
   IN _comment TEXT
)
BEGIN
   DECLARE _mtime INT(11) DEFAULT 0;
   DECLARE _url_key   VARCHAR(1000) DEFAULT '';
   SELECT UNIX_TIMESTAMP() INTO _mtime;
   UPDATE block SET hash=block_ident(_tag, _lang, _device),  tag=_tag,
     author=_author, comment=_comment, mtime=_mtime WHERE id=_id;
   SELECT
     *,
     tag as hashtag
   FROM block WHERE id=_id;
END $

-- =========================================================
-- block_rename
-- =========================================================
DROP PROCEDURE IF EXISTS `block_rename`$
CREATE PROCEDURE `block_rename`(
   IN _key     VARCHAR(512),
   IN _hashtag VARCHAR(512)
)
BEGIN

   UPDATE block SET hashtag=_hashtag WHERE (id=_key OR hashtag=_key);
   SELECT
     *
   FROM block WHERE hashtag=_hashtag;

END $

-- =========================================================
-- block_copy
-- =========================================================

DROP PROCEDURE IF EXISTS `block_copy`$
CREATE PROCEDURE `block_copy`(
   IN _key    VARCHAR(16),
   IN _author  VARCHAR(160)
)
BEGIN
   DECLARE _id VARBINARY(16) DEFAULT '';
   DECLARE _hashtag VARCHAR(512);
   DECLARE _version TINYINT(4);
   DECLARE _tag VARCHAR(512);
   DECLARE _ident VARCHAR(512);

   SELECT id, hashtag FROM block WHERE (id=_key OR hashtag=_key) INTO _id, _hashtag;
   SELECT COUNT(*) FROM block WHERE hashtag LIKE concat(_hashtag, '-v%') INTO _version;
   SET _hashtag = CONCAT(_hashtag, '-v', _version);
   SELECT COUNT(*) FROM block WHERE hashtag = _hashtag INTO _version;
   WHILE _version > 0 DO
      SET _version = _version + 1;
      SET _hashtag = CONCAT(_hashtag, '-v', _version);
      SELECT COUNT(*) FROM block WHERE hashtag = _hashtag INTO _version;
   END WHILE;
   INSERT INTO block
      SELECT null, uniqueId(), serial, active, _author, _hashtag, `type`, editor, status, ctime, mtime, version
      FROM block WHERE id=_id;
   SELECT *, _id as src_id FROM block WHERE hashtag=_hashtag;
END $

-- =========================================================
-- block_backup
-- =========================================================
DROP PROCEDURE IF EXISTS `block_backup`$
-- CREATE PROCEDURE `block_backup`(
--    IN _id           VARBINARY(16),
--    IN _letc  MEDIUMTEXT
-- )
-- BEGIN
--    UPDATE block SET backup=_letc, mtime=UNIX_TIMESTAMP() WHERE id=_id;
--    SELECT backup, id FROM block WHERE id=_id;
-- END $




-- =========================================================
-- block_store
-- =========================================================
DROP PROCEDURE IF EXISTS `block_store`$
CREATE PROCEDURE `block_store`(
   IN _inId      VARCHAR(16),
   IN _hashtag   VARCHAR(512),
   IN _editor    VARCHAR(16),
   IN _type      VARCHAR(20),
   IN _device    VARCHAR(16),
   IN _lang      VARCHAR(20),
   IN _author_id VARBINARY(16),
   IN _vesrion   VARCHAR(16)
)
BEGIN
   DECLARE _id   VARBINARY(16) DEFAULT '';
   DECLARE _ts   INT(11) DEFAULT 0;
   DECLARE _last INT(11) DEFAULT 0;

   SELECT UNIX_TIMESTAMP() INTO _ts;

   IF CAST(_inId as CHAR(16))='0' OR _inId='0' OR _inId='' THEN
     SELECT yp.uniqueId() INTO _id;
   ELSE
     SELECT _inId INTO _id;
   END IF;

   START TRANSACTION;

   INSERT INTO block_history (`author_id`, `master_id`, `lang`, `device`, `meta`, `ctime`)
         VALUES(_author_id, _id, _lang, _device, _hashtag, _ts);
   SELECT LAST_INSERT_ID() INTO _last;

   REPLACE INTO block
     (`id`, `hashtag`, `author_id`, `editor`, `type`, `serial`, `active`, `status`, `ctime`, `mtime`, `version`)
     VALUES(_id, _hashtag, _author_id, _editor, _type, _last, _last, 'offline', _ts, _ts, _vesrion);
     -- ON DUPLICATE KEY UPDATE serial=_last, active=_last, mtime=_ts;

   COMMIT;

   SELECT _id as id, _last as active, _hashtag as hashtag;

END $


-- =========================================================
-- block_add
-- =========================================================
DROP PROCEDURE IF EXISTS `block_add`$
-- CREATE PROCEDURE `block_add`(
--    IN _tag    VARCHAR(512),
--    IN _author     VARBINARY(16),
--    IN _lang      VARCHAR(20),
--    IN _comment    TEXT,
--    IN _editor    VARCHAR(16),
--    IN _content       MEDIUMTEXT,
--    IN _device     VARCHAR(16),
--    IN _vesrion    VARCHAR(16)
-- )
-- BEGIN
--    DECLARE _new_id VARCHAR(16) DEFAULT '';
--    DECLARE _hash VARCHAR(512) DEFAULT '';
--    DECLARE _ts    INT(11) DEFAULT 0;
--    SELECT yp.uniqueId(), UNIX_TIMESTAMP(), block_ident(_tag, _lang, _device) INTO _new_id, _ts, _hash;
--
--    INSERT INTO block (`id`, `editor`, `hashtag`, `hash`, `tag`, `device`, `lang`, `author`, `author_id`,
--    	  `comment`, `content`, `status`, `ctime`, `mtime`, `version`)
--    VALUES(_new_id, _editor, _tag, _hash, _tag, _device, _lang, _author, _author,
--           _comment, _content, 'active', _ts, _ts, _vesrion);
--
--    SELECT *, tag as hashtag FROM block WHERE id=_new_id;
-- END $


-- =========================================================
-- block_status
-- =========================================================
DROP PROCEDURE IF EXISTS `block_status`$
CREATE PROCEDURE `block_status`(
   IN _id      VARBINARY(16),
   IN _status  VARCHAR(16)
)
BEGIN
   UPDATE block SET status=_status WHERE id=_id;
   SELECT *, tag as hashtag FROM block WHERE id=_id;
END $

-- =========================================================
-- block_index
-- =========================================================
DROP PROCEDURE IF EXISTS `block_index`$
CREATE PROCEDURE `block_index`(
   IN _hashtag  varchar(256),
   IN _lang  VARCHAR(6),
   IN _content  MEDIUMTEXT
)
BEGIN
   DECLARE _key  VARCHAR(25);
   SELECT CONCAT(id, '-', _lang) FROM block WHERE hashtag=_hashtag INTO _key;
   REPLACE INTO seo
     (`key`, `hashtag`, `lang`, `content`)
     VALUES(_key, _hashtag, _lang, _content);
END $


-- =========================================================
-- block_push
-- =========================================================
DROP PROCEDURE IF EXISTS `block_get_used_languages`$
CREATE PROCEDURE `block_get_used_languages`(
  IN _hashtag  varchar(256)
)
BEGIN
  SELECT lang FROM block LEFT JOIN block_history ON block.id=master_id 
  WHERE hashtag=_hashtag or master_id=_hashtag GROUP BY lang;
END $

-- =========================================================
-- block_push
-- =========================================================

-- DROP PROCEDURE IF EXISTS `block_push`$
-- CREATE PROCEDURE `block_push`(
--    IN _dbname     VARCHAR(80),
--    IN _tag    VARCHAR(512)
-- )
-- BEGIN
--    DECLARE _new_id VARBINARY(16) DEFAULT '';
--    DECLARE _new_tag VARCHAR(512);
--    DECLARE _ts    INT(11) DEFAULT 0;
--
--    DROP TABLE IF EXISTS `_tmp_block`;
--    CREATE TEMPORARY TABLE _tmp_block AS (SELECT * FROM block WHERE tag=_tag);
--    UPDATE _tmp_block SET status='readonly', mtime=UNIX_TIMESTAMP(), id=yp.uniqueId() WHERE tag=_tag;
--
--    SET @s = CONCAT("INSERT IGNORE INTO `", _dbname, "`.`block` SELECT * FROM _tmp_block");
--    SELECT @s;
-- --   PREPARE stmt FROM @s;
-- --   EXECUTE stmt;
-- --   DEALLOCATE PREPARE stmt;
--    SELECT * FROM _tmp_block WHERE tag=_tag;
--    DROP TABLE IF EXISTS `_tmp_block`;
-- END $


-- =========================================================
-- Added default pages on language add
-- =========================================================
DROP PROCEDURE IF EXISTS `block_save_int_default_page`$
CREATE PROCEDURE `block_save_int_default_page`(
   IN _inId      VARCHAR(16),
   IN _hashtag   VARCHAR(512),
   IN _editor    VARCHAR(16),
   IN _type      VARCHAR(20),
   IN _device    VARCHAR(16),
   IN _lang      VARCHAR(20),
   IN _isonline  INT(4),
   IN _author_id VARBINARY(16),
   IN _vesrion   VARCHAR(16)
)
BEGIN
  DECLARE _id   VARCHAR(16) DEFAULT '';
  DECLARE _ts   INT(11) DEFAULT 0;
  DECLARE _last INT(11) DEFAULT 0;
  DECLARE _hash_exist INT(4) DEFAULT 0;
  DECLARE _src_path VARCHAR(512);

  SELECT UNIX_TIMESTAMP() INTO _ts;

  CALL yp.default_page(_hashtag, _lang, _src_path);

  IF CAST(_inId as CHAR(16))='0' OR _inId='0' THEN
    SELECT yp.uniqueId() INTO _id;
  ELSE
    SELECT _inId INTO _id;
  END IF;

  -- SELECT EXISTS (
  --   SELECT id FROM block LEFT JOIN block_history ON block_history.serial = block.serial  
  --   WHERE hashtag = _hashtag AND block_history.lang = _lang
  -- ) INTO _hash_exist;

  SELECT active FROM `block` LEFT JOIN block_history ON block_history.`serial` = `block`.`serial`  
  WHERE `hashtag` = _hashtag AND block_history.lang = _lang INTO _last;


  -- IF _hash_exist = 0 THEN
  IF _last IS NULL THEN
    START TRANSACTION;

    INSERT INTO block_history (`author_id`, `master_id`, `lang`, `device`, `meta`, `ctime`)
        VALUES(_author_id, _id, _lang, _device, _hashtag, _ts);
    

    -- SELECT LAST_INSERT_ID() INTO _last;
    SELECT MAX(`serial`)+1 FROM block_history INTO _last;
    UPDATE block_history SET status = 'history' WHERE master_id=_id AND lang = _lang;
    UPDATE block_history SET status = 'draft' 
      WHERE master_id=_id AND lang = _lang AND serial=_last;

    IF _isonline = 1 THEN
      UPDATE block_history SET isonline = 0 WHERE master_id=_id AND lang = _lang;
      UPDATE block_history SET isonline = 1 WHERE master_id=_id AND lang = _lang AND serial=_last;
    END IF;
    
    -- SELECT id FROM yp.entity WHERE vhost=(
    --   SELECT conf_value FROM yp.sys_conf WHERE conf_key='blocks_repo'
    -- ) INTO _owner_id;

    REPLACE INTO block
      (`id`, `hashtag`, `author_id`, `editor`, `type`, `serial`, 
      `active`, `status`, `ctime`, `mtime`, `version`)
      VALUES(_id, _hashtag, _author_id, _editor, _type, _last, 
      _last, 'offline', _ts, _ts, _vesrion);

    COMMIT;

    SELECT _id as id, _lang AS lang, _last as active, 
      _hashtag as hashtag, _hash_exist AS hash_exist, _src_path AS src_path;
  ELSE
    SELECT _id as id, _lang AS lang, _hashtag as hashtag, _last AS active,
      _hash_exist AS hash_exist, _src_path AS src_path;
  END IF;

END $
