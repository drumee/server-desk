DELIMITER $

-- =========================================================
--
-- UTILS SECTION
--
-- =========================================================

-- ===============================================================
-- test_limit
-- ===============================================================

DROP PROCEDURE IF EXISTS `test_limit`$
CREATE PROCEDURE `test_limit`(
  IN _page int
)
BEGIN
  DECLARE total bigint;
  DECLARE _offset bigint;
  DECLARE perpage INT DEFAULT 20;
  SELECT count(*) FROM media into total;

  SELECT FLOOR(total/perpage)*_page INTO _offset;

END $

-- ===============================================================
-- set_page_length
-- ===============================================================

DROP PROCEDURE IF EXISTS `set_page_length`$
CREATE PROCEDURE `set_page_length`(
  IN _start int,
  IN _end int
)
BEGIN
  DECLARE _length INT DEFAULT 20;
  DECLARE _perpage INT DEFAULT 20;

  IF @rows_per_page IS NULL THEN
    SET @rows_per_page=15;
  END IF;

  SELECT (_end - _start)*@rows_per_page INTO _length;
  SET @rows_per_page=_length;

END $



-- =========================================================
--
-- =========================================================
DROP PROCEDURE IF EXISTS `get_privilege`$
CREATE PROCEDURE `get_privilege`(
  IN _uid VARBINARY(16),
  IN _area VARCHAR(12),
  OUT _priv TINYINT(2),
  OUT _hubers INT(8)
)
BEGIN
  DECLARE _tmp TINYINT(2);

  SELECT privilege FROM huber WHERE id=_uid INTO _tmp;
  SELECT count(*) FROM huber INTO _hubers;

  IF _tmp IS NULL OR _tmp='' THEN
    IF _area = 'public' THEN
      SET _priv=1;
    ELSE
      SELECT IF(_uid='ffffffffffffffff' OR _uid='nobody' OR _uid='' OR _uid IS NULL, -1, 0) INTO _priv;
    END IF;
  ELSE
    SET _priv=_tmp;
  END IF;

END$

-- =========================================================
-- mediaEnv
-- =========================================================
DROP PROCEDURE IF EXISTS `mediaEnv`$
CREATE PROCEDURE `mediaEnv`(
  OUT _vhost VARCHAR(255),
  OUT _hub_id VARCHAR(16), 
  OUT _area VARCHAR(25),
  OUT _home_dir VARCHAR(512),
  OUT _home_id VARCHAR(16),
  OUT _db_name VARCHAR(50),
  OUT _accessibility VARCHAR(16)
)
BEGIN
  DECLARE _domain VARCHAR(512);
  
  SELECT d.name FROM yp.domain d INNER JOIN 
    yp.entity e ON e.dom_id=d.id WHERE db_name=database() INTO _domain;
  SELECT IFNULL(fqdn, _domain), e.id, area, home_dir, db_name, accessibility, home_id
  FROM yp.entity e INNER JOIN yp.vhost v ON e.id=v.id WHERE db_name=database() LIMIT 1
  INTO _vhost, _hub_id, _area, _home_dir, _db_name, _accessibility, _home_id;
END $


-- =========================================================
-- mediaEnv
-- =========================================================
DROP PROCEDURE IF EXISTS `mediaAccess`$
-- CREATE PROCEDURE `mediaAccess`(
--   IN _uid VARCHAR(255),
--   IN _nid VARCHAR(16), 
--   OUT _permission TINYINT(2),
--   OUT _expiry INT(11),
--   OUT _home_id VARCHAR(16)
-- )
-- BEGIN
--   SELECT user_permission(_uid, _nid), user_expiry(_uid, _nid), parent_id
--     FROM media WHERE parent_id='0' INTO 
--     _permission, _expiry, _home_id;
-- END $




DELIMITER ;
