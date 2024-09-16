DELIMITER $
-- =========================================================
-- set_env
-- DEPRECATED
-- =========================================================
DROP FUNCTION IF EXISTS `set_env`$
CREATE FUNCTION `set_env`(
  _home_root VARCHAR(512),
  _date_format VARCHAR(512),
  _lc_time VARCHAR(512),
  _rows_per_page tinyint(4)
)
RETURNS VARCHAR(80) DETERMINISTIC
BEGIN
  SET @home_root = _home_root;
  SET @dformat = _date_format;
  SET lc_time_names = _lc_time;
  SET @rows_per_page = _rows_per_page;
  -- SELECT get_ident() INTO @home_node;
  SELECT area, area_id from yp.entity where db_name=database() INTO @area, @area_id;
  RETURN @home_root;
END$

-- =========================================================
-- init_env
--
-- =========================================================
DROP FUNCTION IF EXISTS `init_env`$
CREATE FUNCTION `init_env`(
  _lc_time VARCHAR(512),
  _rows_per_page tinyint(4)
)
RETURNS VARCHAR(80) DETERMINISTIC
BEGIN
  SET lc_time_names = _lc_time;
  SET @rows_per_page = _rows_per_page;
  RETURN  @rows_per_page;
END$

-- =========================================================
-- DEPRECATED
-- =========================================================

DROP FUNCTION IF EXISTS `get_ident`$
CREATE FUNCTION `get_ident`(
)
RETURNS VARCHAR(80) DETERMINISTIC
BEGIN
  DECLARE _ident VARCHAR(120);
  SELECT ident FROM yp.entity WHERE db_name=database() INTO _ident;
  RETURN _ident;
END$

-- =========================================================
-- Get id, based on database name
-- =========================================================

DROP FUNCTION IF EXISTS `get_id`$
CREATE FUNCTION `get_id`(
)
RETURNS VARCHAR(80) DETERMINISTIC
BEGIN
  DECLARE _id VARCHAR(120);
  SELECT id FROM yp.entity WHERE db_name=database() INTO _id;
  RETURN _id;
END$

-- =========================================================
-- Get id, based on database name
-- =========================================================

DROP FUNCTION IF EXISTS `get_area_id`$
CREATE FUNCTION `get_area_id`(
)
RETURNS VARCHAR(80) DETERMINISTIC
BEGIN
  DECLARE _id VARCHAR(120);
  SELECT area_id FROM yp.entity WHERE db_name=database() INTO _id;
  RETURN _id;
END$


-- =========================================================================
-- get_home_id - Server Side Usage
-- 
-- =========================================================================
DROP FUNCTION IF EXISTS `get_home_id`$
CREATE FUNCTION `get_home_id`(
)
RETURNS VARCHAR(16) DETERMINISTIC
BEGIN
  DECLARE _id VARCHAR(16);
  SELECT  id FROM media WHERE parent_id='0' INTO _id;
  RETURN _id;
END$


-- =========================================================
-- Get
-- =========================================================
DROP FUNCTION IF EXISTS `get_privilege`$
CREATE FUNCTION `get_privilege`(
  _uid VARBINARY(16),
  _area VARCHAR(12)
)
RETURNS TINYINT(2) DETERMINISTIC
BEGIN
  DECLARE _id VARBINARY(16);
  DECLARE _res TINYINT(2);
  DECLARE _priv TINYINT(2);

  SELECT privilege FROM huber WHERE id=_uid INTO _priv;
  IF _priv IS NULL OR _priv='' THEN
    IF _area = 'public' THEN
      SET _res=1;
    ELSE
      SET _res=0;
    END IF;
  ELSE
    SET _res=_priv;
  END IF;
  RETURN _res;
END$

-- =========================================================
-- return number of attachments linked to a drum, if any
-- =========================================================

-- DROP FUNCTION IF EXISTS `has_attachment`$
-- CREATE FUNCTION `has_attachment`(
--   _did VARCHAR(16)
-- )
-- RETURNS INT
-- BEGIN
--   DECLARE _a INT;
--   SELECT  count(*) FROM attachments WHERE drum_id=_did INTO _a;
--   RETURN _a;
-- END$


-- =========================================================
-- msg_visible
-- =========================================================


-- DROP FUNCTION IF EXISTS `msg_visible`$
-- CREATE FUNCTION `msg_visible`(
--   _status VARCHAR(32)
-- )
-- RETURNS INT
-- BEGIN
--   DECLARE _a BOOLEAN;
--   SELECT  IF (_status='new' OR _status='seen' OR _status='important',
--     TRUE, FALSE) INTO _a;
--   RETURN _a;
-- END$


-- =========================================================
-- uniqueId
-- =========================================================
DROP FUNCTION IF EXISTS `uniqueId`$
CREATE FUNCTION `uniqueId`(

)
RETURNS VARCHAR(16) DETERMINISTIC
BEGIN
  DECLARE _res VARCHAR(16);
  SELECT CONCAT(
    SUBSTRING_INDEX(UUID(), '-', 1),
    SUBSTRING_INDEX(UUID(), '-', 1)
  ) INTO _res;
  RETURN _res;
END$

-- =========================================================
-- strToBits
-- =========================================================
DROP FUNCTION IF EXISTS `strToBits`$
-- CREATE FUNCTION `strToBits`(
--   _str VARCHAR(8)

-- )
-- RETURNS BIT(8) DETERMINISTIC
-- BEGIN
--   DECLARE _bits BIT(8) DEFAULT NULL;
--   SELECT CAST(_str AS UNSIGNED) INTO _bits;
--   RETURN _bits;
-- END$

-- =========================================================
-- strToBits
-- =========================================================
DROP FUNCTION IF EXISTS `layoutMatching`$
-- CREATE FUNCTION `layoutMatching`(
--    _hashtag VARCHAR(512),
--    _key VARCHAR(512),
--    _screen  VARCHAR(16),
--    _lang  VARCHAR(16)
-- )
-- RETURNS INT(8) DETERMINISTIC
-- BEGIN
--   DECLARE res INT(8) DEFAULT 0;
--   SELECT IF(_hashtag=concat(_key, '.', _lang, '.', _screen), 6, 0)
--      + IF(_hashtag=concat(_key, '.', _screen, '.', _lang), 6, 0)
--      + IF(_hashtag=concat(_key, '.', _lang), 4, 0)
--      + IF(_hashtag=concat(_key, '.', _screen), 5, 0)
--      + IF(_hashtag=_key , 1, 0) INTO res;
--   RETURN res;
-- END$

-- =========================================================
-- layout_score
-- =========================================================
DROP FUNCTION IF EXISTS `layout_score`$
-- CREATE FUNCTION `layout_score`(
--    _hash VARCHAR(512),
--    _tag VARCHAR(512),
--    _lang  VARCHAR(16),
--    _device  VARCHAR(16)
-- )
-- RETURNS INT(8) DETERMINISTIC
-- BEGIN
--   DECLARE res INT(8) DEFAULT 0;
--   SELECT IF(_hash=layout_ident(_tag, _lang, _device), 6, 0)
--      + IF(_hash LIKE concat(_tag, '!', _lang, '!%'), 5, 0)
--      + IF(_hash LIKE concat(_tag, '!%', _lang), 3, 0) INTO res;
--   RETURN res;
-- END$

-- =========================================================
-- layout_score
-- =========================================================
DROP FUNCTION IF EXISTS `layout_ident`$
-- CREATE FUNCTION `layout_ident`(
--    _tag VARCHAR(512),
--    _lang  VARCHAR(16),
--    _device  VARCHAR(16)
-- )
-- RETURNS VARCHAR(512) DETERMINISTIC
-- BEGIN
--   RETURN concat(_tag, '!', _lang, '!', _device);
-- END$

-- =========================================================
-- block_score
-- =========================================================
DROP FUNCTION IF EXISTS `block_score`$
-- CREATE FUNCTION `block_score`(
--    _hash VARCHAR(512),
--    _tag VARCHAR(512),
--    _lang  VARCHAR(16),
--    _device  VARCHAR(16)
-- )
-- RETURNS INT(8) DETERMINISTIC
-- BEGIN
--   DECLARE res INT(8) DEFAULT 0;
--   SELECT IF(_hash=block_ident(_tag, _lang, _device), 6, 0)
--      + IF(_hash LIKE concat(_tag, '!', _lang, '!%'), 5, 0)
--      + IF(_hash LIKE concat(_tag, '!%', _lang), 3, 0) INTO res;
--   RETURN res;
-- END$

-- =========================================================
-- block_score
-- =========================================================
DROP FUNCTION IF EXISTS `block_ident`$
-- CREATE FUNCTION `block_ident`(
--    _tag VARCHAR(512),
--    _lang  VARCHAR(16),
--    _device  VARCHAR(16)
-- )
-- RETURNS VARCHAR(512) DETERMINISTIC
-- BEGIN
--   RETURN concat(_tag, '!', _lang, '!', _device);
-- END$

-- =========================================================
-- get user (uid) permission on resource id from acl
-- =========================================================
-- DROP FUNCTION IF EXISTS `get_permission`$


-- =========================================================
-- user_expiry
-- =========================================================
DROP FUNCTION IF EXISTS `user_expiry`$
CREATE FUNCTION `user_expiry`(
  _uid VARCHAR(16) CHARACTER SET ascii,
  _rid VARCHAR(16) CHARACTER SET ascii
)
RETURNS INT(11) DETERMINISTIC
BEGIN
  DECLARE _expiry INT(11);
  DECLARE _db_name VARCHAR(60);
  DECLARE _category VARCHAR(60);
  DECLARE _file_path VARCHAR(1024);
  
  SET _expiry = NULL;
  SELECT category FROM media WHERE id=_rid INTO _category;
  SELECT IF(_uid IN ('nobody', 'ffffffffffffffff', '*'), '*', _uid) INTO _uid;
  SELECT expiry_time FROM media LEFT JOIN permission ON 
      resource_id=media.id WHERE entity_id=_uid AND media.id=_rid INTO _expiry;

  IF _expiry IS NULL THEN -- SEARCH FROM WILDCARD ON resource_id
      SELECT expiry_time FROM permission WHERE (entity_id=_uid AND resource_id='*') 
      INTO _expiry;
  END IF;
  IF _expiry IS NULL THEN -- SEARCH IN PARENT 
      SELECT file_path FROM media WHERE id=_rid INTO _file_path;
      SELECT IFNULL(expiry_time, 0) FROM media LEFT JOIN permission ON 
        resource_id=media.id AND entity_id= _uid WHERE  REPLACE(_file_path, '(',')')  REGEXP  REPLACE(user_filename, '(',')')  AND permission 
        IS NOT NULL
        ORDER BY (LENGTH(parent_path)-LENGTH(REPLACE(parent_path, '/', '')))  DESC LIMIT 1 
        INTO _expiry;
  END IF;
  
  SELECT IFNULL(_expiry, 0) INTO _expiry;
  RETURN _expiry;
END$

-- =========================================================
-- media_ttl
-- =========================================================
DROP FUNCTION IF EXISTS `media_ttl`$
CREATE FUNCTION `media_ttl`(
  _uid VARCHAR(16),
  _rid VARCHAR(16)
)
RETURNS INT(11) DETERMINISTIC
BEGIN
  DECLARE _expiry INT(11);
  DECLARE _db_name VARCHAR(60);
  DECLARE _category VARCHAR(60);
  DECLARE _file_path VARCHAR(1024);
  
  SET _expiry = NULL;
  SELECT category FROM media WHERE id=_rid INTO _category;

  SELECT expiry_time FROM media LEFT JOIN permission ON 
      resource_id=media.id WHERE entity_id=_uid AND media.id=_rid INTO _expiry;

  IF _expiry IS NULL THEN -- SEARCH FROM WILDCARD ON resource_id
      SELECT expiry_time FROM permission WHERE (entity_id=_uid AND resource_id='*') INTO _expiry;
  END IF;
  IF _expiry IS NULL THEN -- SEARCH IN PARENT 
      SELECT file_path FROM media WHERE id=_rid INTO _file_path;
      SELECT IFNULL(expiry_time, 0) FROM media LEFT JOIN permission ON 
        resource_id=media.id AND entity_id= _uid WHERE  REPLACE(_file_path  , '(',')')  REGEXP  REPLACE(user_filename , '(',')')  AND permission 
        IS NOT NULL
        ORDER BY (LENGTH(parent_path)-LENGTH(REPLACE(parent_path, '/', '')))  DESC LIMIT 1 
        INTO _expiry;
  END IF;
  
  SELECT IFNULL(_expiry, 0) INTO _expiry;
  SELECT IF(_expiry=0, 0, _expiry - UNIX_TIMESTAMP()) INTO _expiry;
  RETURN _expiry;
END$


-- =========================================================
-- user_perm_msg
-- =========================================================

DROP FUNCTION IF EXISTS `user_perm_msg`$
CREATE FUNCTION `user_perm_msg`(
  _uid VARCHAR(16),
  _rid VARCHAR(16)
)
RETURNS TEXT DETERMINISTIC
BEGIN
  DECLARE _msg MEDIUMTEXT;
  DECLARE _db_name VARCHAR(60);
  DECLARE _category VARCHAR(60);
  DECLARE _file_path VARCHAR(1024);
  
  SET _msg = NULL;
  SELECT category FROM media WHERE id=_rid INTO _category;

  SELECT IFNULL(message, '') FROM media LEFT JOIN permission ON 
      resource_id=media.id WHERE entity_id=_uid AND media.id=_rid INTO _msg;

  IF _msg IS NULL THEN -- SEARCH FROM WILDCARD ON resource_id
      SELECT message FROM permission WHERE (entity_id=_uid AND resource_id='*') INTO _msg;
  END IF;
  IF _msg IS NULL THEN -- SEARCH IN PARENT 
    SELECT file_path FROM media WHERE id=_rid INTO _file_path;
    SELECT IFNULL(message, '') FROM media LEFT JOIN permission ON 
      resource_id=media.id AND entity_id= _uid WHERE  REPLACE(_file_path  , '(',')')  REGEXP  REPLACE(user_filename  , '(',')')  AND permission 
      IS NOT NULL 
      ORDER BY (LENGTH(parent_path)-LENGTH(REPLACE(parent_path, '/', '')))  DESC LIMIT 1 
      INTO _msg;
  END IF;
  
  SELECT IFNULL(_msg, '') INTO _msg;
  RETURN _msg;
END$

-- =========================================================
-- ensure_path
-- =========================================================
-- DROP FUNCTION IF EXISTS `unique_filename`$
-- CREATE FUNCTION `unique_filename`(
--   _pid VARCHAR(16),
--   _fname VARCHAR(1024)
-- )
-- RETURNS VARCHAR(512) DETERMINISTIC
-- BEGIN
--   DECLARE _r VARCHAR(512);
--   DECLARE _n INT(6) DEFAULT 0;
--   DECLARE _seek INT(6) DEFAULT 1;
--   SET @uf = '';
--   SET @rn = 0;
--   SET @prev = '';
--   IF _pid IS NULL OR _pid='' OR _pid='0' OR _pid=0 THEN 
--     SELECT id FROM media WHERE parent_id='0' INTO _pid;
--   END IF;

--   SELECT count(*) FROM media WHERE parent_id=_pid AND user_filename=_fname INTO _n;

--   IF _n = 0 THEN
--     SELECT _fname INTO _r;
--   ELSE 
--     WHILE _n != 0  AND _n < 10 DO 
--       SET @rn := @rn + 1;
--       IF  _fname REGEXP '([0-9])' THEN
--         SELECT REPLACE(_fname, _fname REGEXP '([0-9+])', @rn) INTO _r;
--         IF @prev = _r THEN 
--           SELECT CONCAT(_fname, "(", @rn + 1, ")") INTO _r;
--         END IF;
--         SELECT count(*) FROM media WHERE parent_id=_pid AND user_filename= _r INTO _n;
--         SET @prev = _r;
--       ELSE
--         SELECT CONCAT(_fname, "(", @rn,")") INTO _r;
--         SET _n = 0;
--       END IF;
--     END WHILE;
--   END IF;
--   RETURN _r;
-- END$


-- =========================================================
-- Return clean relative filepath (without heading or trailing /)
-- =========================================================
-- DROP FUNCTION IF EXISTS `unique_filename`$
-- CREATE FUNCTION `unique_filename`(
--   _pid VARCHAR(16),
--   _file_name VARCHAR(200)
-- )
-- RETURNS VARCHAR(1024) DETERMINISTIC
-- BEGIN
--   DECLARE _r VARCHAR(1024);
--   DECLARE _fname VARCHAR(1024);
--   DECLARE _count INT(8) DEFAULT 0;
--   DECLARE _depth SMALLINT DEFAULT 0;

--   SELECT TRIM('/' FROM _file_name) INTO _fname;
  
--   SELECT count(*) FROM media WHERE 
--     parent_id=_pid AND (TRIM('/' FROM user_filename) = _fname)
--     INTO _count;
--   IF _count = 0 THEN 
--     SELECT _fname INTO _r;
--   ELSEIF _fname regexp '\\\([0-9]+\\\)$' THEN 
--     WHILE _depth  < 1000 AND _count > 0 DO 
--       SELECT _depth + 1 INTO _depth;
--       -- SELECT SUBSTRING_INDEX(_file_path, '(', -1) INTO @nb;
--       -- SELECT SUBSTRING_INDEX(@nb, ')', 1) + 1 INTO @nb;
--       SELECT SUBSTRING_INDEX(_fname, '(', 1) INTO @base;
--       SELECT SUBSTRING_INDEX(_fname, ')', -1) INTO @ext;
--       SELECT CONCAT(@base, "(", _depth, ")", @ext) INTO _r;
--       SELECT count(*) FROM media WHERE 
--         parent_id=_pid AND TRIM('/' FROM user_filename) = _r
--         INTO _count;
--     END WHILE;
--   ELSE 
--     SELECT CONCAT(_fname, "(1)") INTO _r;
--     SELECT count(*) FROM media WHERE 
--       parent_id=_pid AND TRIM('/' FROM user_filename) = _r
--       INTO _count;
--     WHILE _depth  < 1000 AND _count > 0 DO 
--       SELECT _depth + 1 INTO _depth;
--       -- SELECT SUBSTRING_INDEX(_file_path, '(', -1) INTO @nb;
--       -- SELECT SUBSTRING_INDEX(@nb, ')', 1) + 1 INTO @nb;
--       SELECT SUBSTRING_INDEX(_r, '(', 1) INTO @base;
--       SELECT SUBSTRING_INDEX(_r, ')', -1) INTO @ext;
--       SELECT CONCAT(@base, "(", _depth, ")", @ext) INTO _r;
--       SELECT count(*) FROM media WHERE 
--         parent_id=_pid AND TRIM('/' FROM user_filename) = _r
--         INTO _count;
--     END WHILE;
--   END IF;
--   SELECT SUBSTRING_INDEX(_r, '/', -1) INTO _r;
--   RETURN _r;
--   -- -- RETURN CONCAT(_depth, ":", _count, " -- ", _r);
-- END$

-- DROP FUNCTION IF EXISTS `unique_filename_next`$

-- MOVED TO utils/

-- DROP FUNCTION IF EXISTS `unique_filename`$
-- CREATE FUNCTION `unique_filename`(
--   _pid VARCHAR(16),
--   _file_name VARCHAR(200),
--   _ext VARCHAR(20)
-- )
-- RETURNS VARCHAR(1024) DETERMINISTIC
-- BEGIN
--   DECLARE _r VARCHAR(1024);
--   DECLARE _fname VARCHAR(1024);
--   DECLARE _path VARCHAR(1024);
--   DECLARE _count INT(8) DEFAULT 0;
--   DECLARE _depth TINYINT(4) DEFAULT 0;

--   SELECT REGEXP_REPLACE(_file_name, '^/', '') INTO _fname;
--   SELECT REGEXP_REPLACE(_fname, '/+', '-') INTO _r;

--   SELECT REGEXP_REPLACE(
--     CONCAT(parent_path(id), '/', user_filename, '/', _file_name, '.', _ext), 
--     '/+', '/'
--   )FROM media WHERE id = _pid INTO _path;

--   SELECT count(*) FROM media WHERE 
--     file_path=_path OR (
--       parent_id=_pid AND 
--       (TRIM('/' FROM user_filename) = _fname) AND 
--       extension=_ext
--     ) INTO _count;
--   IF _count = 0 THEN 
--     SELECT _fname INTO _r;
--   ELSEIF _fname regexp '\\\([0-9]+\\\)$' THEN 
--     WHILE _depth  < 1000 AND _count > 0 DO 
--       SELECT _depth + 1 INTO _depth;
--       SELECT SUBSTRING_INDEX(_fname, '(', 1) INTO @base;
--       SELECT SUBSTRING_INDEX(_fname, ')', -1) INTO @ext;
--       SELECT CONCAT(@base, "(", _depth, ")", @ext) INTO _r;
--       SELECT count(*) FROM media WHERE 
--         parent_id=_pid AND TRIM('/' FROM user_filename) = _r
--         INTO _count;
--     END WHILE;
--   ELSE 
--     SELECT CONCAT(_fname, "(1)") INTO _r;
--     SELECT count(*) FROM media WHERE 
--       parent_id=_pid AND TRIM('/' FROM user_filename) = _r
--       INTO _count;
--     WHILE _depth  < 1000 AND _count > 0 DO 
--       SELECT _depth + 1 INTO _depth;
--       SELECT SUBSTRING_INDEX(_r, '(', 1) INTO @base;
--       SELECT SUBSTRING_INDEX(_r, ')', -1) INTO @ext;
--       SELECT CONCAT(@base, "(", _depth, ")", @ext) INTO _r;
--       SELECT count(*) FROM media WHERE 
--         parent_id=_pid AND TRIM('/' FROM user_filename) = _r
--         INTO _count;
--     END WHILE;
--   END IF;
--   SELECT SUBSTRING_INDEX(_r, '/', -1) INTO _r;
--   RETURN _r;
--   -- -- RETURN CONCAT(_depth, ":", _count, " -- ", _r);
-- END$

-- =========================================================
-- Ensure to get file_path ()
-- =========================================================
-- DROP FUNCTION IF EXISTS `relative_path`$
-- DROP FUNCTION IF EXISTS `get_clean_path`$
-- CREATE FUNCTION `get_clean_path`(
--   _id VARCHAR(16)
-- )
-- RETURNS VARCHAR(1024) DETERMINISTIC
-- BEGIN
--   DECLARE _r VARCHAR(1024);
--   SELECT 
--     CONCAT(parent_path, '/', TRIM('/' FROM user_filename))
--   FROM media WHERE id=_id INTO _r;
--   RETURN _r;
-- END$



-- =========================================================
-- Return clean relative filepath (without heading or trailing /)
-- =========================================================
DROP FUNCTION IF EXISTS `normalize_path`$
-- CREATE FUNCTION `normalize_path`(
--   _id VARCHAR(16)
-- )
-- RETURNS VARCHAR(1024) DETERMINISTIC
-- BEGIN
--   DECLARE _r VARCHAR(1024);

--   SELECT CONCAT('/', parent_path) FROM media WHERE id=_id  INTO @path ;
--   WHILE @path regexp '\/\/' DO 
--     SELECT REPLACE(@path, '//', '/') INTO @path;
--   END WHILE;
--   UPDATE media SET parent_path=TRIM(TRAILING '/' FROM @path) WHERE id=_id;

--   SELECT file_path FROM media WHERE id=_id INTO @path ;
--   WHILE @path regexp '\/\/' DO 
--     SELECT REPLACE(@path, '//', '/') INTO @path;
--   END WHILE;

--   UPDATE media SET file_path=TRIM(TRAILING '/' FROM @path) WHERE id=_id;

--   UPDATE media SET user_filename=TRIM('/' FROM user_filename) WHERE id=_id;

--   SELECT CONCAT(parent_path, '/', TRIM('/' FROM user_filename)) 
--     FROM media WHERE id=_id INTO _r;
--   RETURN _r;

-- END$


-- =========================================================
-- 
-- =========================================================
DROP FUNCTION IF EXISTS `logical_path`$
-- CREATE FUNCTION `logical_path`(
--   _id VARCHAR(16)
-- )


-- RETURNS JSON DETERMINISTIC
-- BEGIN
--   DECLARE _r VARCHAR(1024);
--   DECLARE _pid VARCHAR(16);
--   DECLARE _home_id VARCHAR(16);
--   DECLARE _max INTEGER DEFAULT 0;
--   DECLARE _res JSON;

--   IF _pid IN('0', NULL) THEN 
--     SELECT JSON_ARRAY(id) FROM media WHERE parent_id='0' INTO _res;
--     RETURN _res;
--   END IF;

--   SELECT parent_id, JSON_ARRAY(id) FROM media WHERE id=_id INTO _pid, _res;
--   WHILE _pid != '0' AND _max < 100 DO 
--     SELECT _max + 1 INTO _max;
--     SELECT parent_id, JSON_MERGE(JSON_ARRAY(_pid), _res) FROM media WHERE id = _pid INTO _pid, _res;
--   END WHILE;
--   RETURN _res;
-- END$

-- =========================================================
-- 
-- =========================================================
-- DROP FUNCTION IF EXISTS `node_id_from_path`$
-- CREATE FUNCTION `node_id_from_path`(
--   _path VARCHAR(1024)
-- )
-- RETURNS VARCHAR(16) DETERMINISTIC
-- BEGIN
--   DECLARE _r VARCHAR(16);
--   DECLARE _node_id VARCHAR(16);
--   IF _path regexp  '^\/.+' THEN 
--     SELECT id FROM media 
--       WHERE REPLACE(file_path, '/', '') = 
--       REPLACE(IF(category='folder' OR category ='hub', CONCAT(_path, '.', extension), _path), '/','')
--       INTO _node_id;
--   ELSE 
--     SELECT _key INTO _node_id;
--   END IF;
--   SELECT id FROM media WHERE id = _node_id INTO _r;
--   RETURN _r;
-- END$



-- =========================================================
-- 
-- =========================================================

-- DROP FUNCTION IF EXISTS `filepath`$
-- CREATE FUNCTION `filepath`(
--   _id VARCHAR(1024)
-- )
-- RETURNS VARCHAR(1024) DETERMINISTIC
-- BEGIN
--   DECLARE _r VARCHAR(1024);

--   SELECT CONCAT(
--     parent_path(id), 
--     user_filename, 
--     IF(category IN ('hub'), concat('.', id), concat('.', extension)) 
    
--   ) FROM media WHERE id=_id INTO _r;

--   RETURN clean_path(_r);
-- END$


-- =======================================================================
--
-- =======================================================================

DROP FUNCTION IF EXISTS `permission_tree`$
CREATE FUNCTION `permission_tree`(
  _id VARCHAR(16)
)
RETURNS VARCHAR(16) DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(16) DEFAULT '*';
  DECLARE _pid VARCHAR(16);
  DECLARE _count INTEGER;
  DECLARE _max INTEGER DEFAULT 0;

  SELECT COUNT(*) FROM permission WHERE resource_id = _id INTO _count;
  IF  _count > 0 THEN
    SELECT _id INTO _r;
    SELECT 'O'  INTO _pid;
  ELSE
    SELECT parent_id FROM media WHERE id = _id INTO _pid;
  END IF;

  WHILE _pid != '0' AND _count = 0 AND _max < 100 DO 
    SELECT _max + 1 INTO _max;
    SET @prev = _pid;
    SELECT parent_id FROM media WHERE id = _pid INTO _pid;
    SELECT count(*) FROM permission WHERE resource_id = _pid INTO _count;
    IF _count > 0 THEN
      SELECT _pid INTO _r;
    END IF;
  END WHILE;
  RETURN _r;
END$

-- =======================================================================
--
-- =======================================================================

DROP FUNCTION IF EXISTS `media_notified`$
CREATE FUNCTION `media_notified`(
  _metadata JSON,
  _uid VARCHAR(16)
)
RETURNS INTEGER DETERMINISTIC
BEGIN
  DECLARE _res INTEGER DEFAULT 0;
  SELECT 
    JSON_QUERY(_metadata, "$.acknowledge") IS NOT NULL AND 
    IF(JSON_SEARCH(JSON_QUERY(_metadata,"$.acknowledge"), "one", _uid) IS NULL, 1, 0) INTO _res;
  RETURN _res;
END$


-- DROP FUNCTION IF EXISTS `media_unseen`$
DROP FUNCTION IF EXISTS `count_unseen`$
-- CREATE FUNCTION `count_unseen`(
--   _metadata JSON,
--   _uid VARCHAR(16)
-- )
-- RETURNS INTEGER DETERMINISTIC
-- BEGIN
--   DECLARE _res INTEGER DEFAULT 0;
--   SELECT 
--     IF(
--       JSON_EXISTS(_metadata, "$._seen_") AND 
--       JSON_UNQUOTE(JSON_EXTRACT(_metadata, CONCAT("$._seen_.", _uid))) IS NOT NULL, 
--       1, 0
--     ) INTO _res;
--   RETURN _res;
-- END$

DROP FUNCTION IF EXISTS `is_new`$
CREATE FUNCTION `is_new`(
  _metadata JSON,
  _oid VARCHAR(16),
  _uid VARCHAR(16)
)
RETURNS BOOLEAN DETERMINISTIC
BEGIN
  RETURN IF(
      NOT json_valid(_metadata) OR 
      _metadata IS NULL OR _metadata IN('{}', '') OR _oid = _uid OR
      JSON_EXTRACT(_metadata, "$._seen_") IS NULL OR 
      JSON_UNQUOTE(JSON_EXTRACT(_metadata, CONCAT("$._seen_.", _uid))) IS NOT NULL, 
      0, 1
    );
END$


DELIMITER ;
