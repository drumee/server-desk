DELIMITER $

-- #########################################################
--
-- LANGUAGE
--
-- #########################################################

-- =========================================================
-- Adds a new language.
-- =========================================================
DROP PROCEDURE IF EXISTS `language_add_next`$
CREATE PROCEDURE `language_add_next`(
   IN _locale       VARCHAR(100)
)
BEGIN
  DECLARE _ts   INT(11) DEFAULT 0;
  DECLARE _base VARCHAR(10);
  DECLARE _name VARCHAR(100);
  DECLARE _db_name   VARCHAR(100);
  DECLARE _job_id   VARCHAR(100);
  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT DATABASE() INTO _db_name;
  SELECT code, locale_en FROM yp.language WHERE lcid = _locale AND `state` = 'active' 
    INTO _base, _name;

  IF _base IS NULL OR _name IS NULL THEN
    REPLACE INTO `language` SELECT null, "en", "English", "en", "active", _ts,_ts; 
  ELSE
    REPLACE INTO `language` SELECT null, _base, _name, _locale, "active", _ts,_ts;
  END IF;
  SELECT sys_id AS language_id, base, name, locale, state 
    FROM language WHERE locale = _locale;
END$

-- =========================================================
-- Adds a new language.
-- =========================================================
DROP PROCEDURE IF EXISTS `language_add`$
CREATE PROCEDURE `language_add`(
   IN _user_id      VARCHAR(100),
   IN _hub_id       VARCHAR(255),
   IN _hub_root     VARCHAR(500),
   IN _locale       VARCHAR(100),
   IN _state        VARCHAR(100)
)
BEGIN
  DECLARE _ts   INT(11) DEFAULT 0;
  DECLARE _base VARCHAR(10);
  DECLARE _name VARCHAR(100);
  DECLARE _db_name   VARCHAR(100);
  DECLARE _job_id   VARCHAR(100);
  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT DATABASE() INTO _db_name;
  SELECT code, locale_en FROM yp.language WHERE lcid = _locale AND `state` = 'active' INTO _base, _name;

  IF IFNULL(_base, '') = "" OR IFNULL(_name, '') = "" THEN
    SELECT 1 AS invalid;
  ELSE
    INSERT INTO language (`base`, `name`, `locale`, `state`, `ctime`, `mtime`)
      VALUES(IFNULL(_base, ''), IFNULL(_name, ''), _locale, _state, _ts, _ts)
      ON DUPLICATE KEY UPDATE state=_state, mtime=_ts;
    
    IF LCASE(_state) = 'frozen' THEN
      SELECT SHA1(UUID()) INTO _job_id;
      INSERT IGNORE INTO yp.job_credential (`app_key`, `customer_key`, `job_id`, `user_id`, `ctime`)
        SELECT "language_management", id, _job_id, _user_id, _ts FROM yp.entity WHERE ident='admin';
      INSERT IGNORE INTO yp.frozen_language (`hub_id`, `dbase_name`, `root_path`, `job_id`, `lang`, `ctime`)
        VALUES(_hub_id, _db_name, _hub_root, _job_id, _locale, _ts);
    ELSEIF LCASE(_state) = 'active' OR LCASE(_state) = 'replaced' or LCASE(_state) = 'deleted' THEN
      DELETE FROM yp.frozen_language WHERE hub_id = _hub_id AND dbase_name = _db_name AND lang = _locale;
    END IF;
    
    SELECT sys_id AS language_id, base, name, locale, state FROM language WHERE locale = _locale;
  END IF;
END$


-- =========================================================
-- Updates state of a language.
-- =========================================================
DROP PROCEDURE IF EXISTS `language_change_state`$
CREATE PROCEDURE `language_change_state`(
   IN _user_id      VARCHAR(100),
   IN _hub_id       VARCHAR(255),
   IN _hub_root     VARCHAR(500),
   IN _locale       VARCHAR(100),
   IN _state        VARCHAR(20)
)
BEGIN
  DECLARE _ts   INT(11) DEFAULT 0;
  DECLARE _language_count INT(11) DEFAULT 0;
  DECLARE _db_name   VARCHAR(100);
  DECLARE _job_id   VARCHAR(100);
  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT DATABASE() INTO _db_name;
  SELECT COUNT(*) FROM language WHERE state = 'active' INTO _language_count;
  IF _language_count <= 1 AND (LCASE(_state) = 'frozen' OR LCASE(_state) = 'deleted') THEN
    SELECT 0 AS updated;
  ELSE
    UPDATE language SET state = _state, mtime = _ts WHERE locale = _locale;
    IF LCASE(_state) = 'frozen' THEN
      SELECT SHA1(UUID()) INTO _job_id;
      INSERT IGNORE INTO yp.job_credential (`app_key`, `customer_key`, `job_id`, `user_id`, `ctime`)
        SELECT "language_management", id, _job_id, _user_id, _ts FROM yp.entity WHERE ident='admin';
      INSERT IGNORE INTO yp.frozen_language (`hub_id`, `dbase_name`, `root_path`, `job_id`, `lang`, `ctime`)
        VALUES(_hub_id, _db_name, _hub_root, _job_id, _locale, _ts);
      SELECT 1 AS updated;
    ELSEIF LCASE(_state) = 'active' OR LCASE(_state) = 'replaced' OR LCASE(_state) = 'deleted' THEN
      DELETE FROM yp.frozen_language WHERE hub_id = _hub_id AND dbase_name = _db_name AND lang = _locale;
      SELECT 1 AS updated;
    END IF;
  END IF;
END$

-- =========================================================
-- Gets base language of a hub.
-- =========================================================
DROP PROCEDURE IF EXISTS `language_find_base`$
CREATE PROCEDURE `language_find_base`()
BEGIN
  SELECT sys_id AS language_id, base, name, locale, state FROM language WHERE state = 'active' OR state = 'replaced' ORDER BY sys_id ASC LIMIT 1;
END$

-- =========================================================
-- Gets list of languages in a hub.
-- =========================================================
DROP PROCEDURE IF EXISTS `language_get_list`$
CREATE PROCEDURE `language_get_list`(
  IN _page         INT(11)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);
  SELECT sys_id AS language_id, 
    base, 
    name, 
    yl.code,
    yl.locale_en,
    yl.lcid,
    name locale, 
    flag_image, 
    l.state 
    FROM `language` l
    JOIN yp.language yl ON yl.lcid = l.locale
    WHERE l.state = 'active' OR l.state = 'replaced' ORDER BY name ASC
    LIMIT _offset, _range;
END$

-- =========================================================
-- Gets list of available languages from yellow page.
-- =========================================================
DROP PROCEDURE IF EXISTS `language_available_list`$
CREATE PROCEDURE `language_available_list`(
  IN _name         VARCHAR(200),
  IN _page         INT(11)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);
  SELECT code, lcid, locale_en, locale, flag_image FROM yp.language WHERE `state` = 'active'
    AND code NOT IN (SELECT locale FROM language WHERE state = 'active' OR state = 'replaced')
    AND locale_en LIKE CONCAT(TRIM(IFNULL(_name, '')), '%')
    ORDER BY locale_en ASC LIMIT _offset, _range;
END$

-- =========================================================
-- Gets hub language by locale.
-- =========================================================
DROP PROCEDURE IF EXISTS `language_get_by_locale`$
CREATE PROCEDURE `language_get_by_locale`(
   IN _locale       VARCHAR(100)
)
BEGIN
  SELECT sys_id AS language_id, base, name, locale, state FROM language WHERE locale = _locale;
END$

DELIMITER ;