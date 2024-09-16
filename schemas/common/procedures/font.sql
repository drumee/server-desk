DELIMITER $

-- #########################################################
--
-- CCS  SECTION
--
-- #########################################################

-- =========================================================
-- TO BE REVIEWED
-- =========================================================
DROP PROCEDURE IF EXISTS `font_list`$
CREATE PROCEDURE `font_list`(
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);

  SELECT * FROM `font` ORDER BY `name` ASC LIMIT _offset, _range;
END $


-- =========================================================
-- TO BE DEPRACTED
-- =========================================================
DROP PROCEDURE IF EXISTS `font_list_all`$
CREATE PROCEDURE `font_list_all`(
)
BEGIN
  SELECT * FROM `font` where status='active';
END $

-- =========================================================
--
-- =========================================================
DROP PROCEDURE IF EXISTS `get_fonts_links`$
CREATE PROCEDURE `get_fonts_links`(
)
BEGIN
  SELECT * FROM `font_link` where status='active';
END $

-- =========================================================
--
-- =========================================================
DROP PROCEDURE IF EXISTS `get_fonts_faces`$
CREATE PROCEDURE `get_fonts_faces`(
)
BEGIN
  DECLARE _hub_id VARCHAR(16) DEFAULT 'george';
  DECLARE _hub_db VARCHAR(40);
  SELECT conf_value FROM yp.sys_conf WHERE conf_key='entry_host' INTO _hub_id;
  SELECT db_name FROM yp.entity WHERE id = _hub_id INTO _hub_db; 

    SET @sql = CONCAT("  SELECT * FROM ",_hub_db,".font_face" );
      PREPARE stmt FROM @sql;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
END $


-- =========================================================
-- TO BE DEPRECATED ??
-- =========================================================

DROP PROCEDURE IF EXISTS `font_add`$
CREATE PROCEDURE `font_add`(
  IN _name VARCHAR(128),
  IN _variant VARCHAR(128),
  IN _url VARCHAR(1024)
)
BEGIN
  INSERT INTO font(`family`, `name`, `variant`, `url`, `ctime`, `mtime`)
            values(concat(`name`, ", ", `variant`), _name, _variant, _url, UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
  ON DUPLICATE KEY UPDATE `family`=concat(`name`, ", ", `variant`),
            `name`=_name, `variant`=_variant, `url`=_url, mtime=UNIX_TIMESTAMP();
  SELECT * FROM font WHERE `name`=_name;
END $

-- =========================================================
--
-- =========================================================

DROP PROCEDURE IF EXISTS `hub_add_font_link`$
CREATE PROCEDURE `hub_add_font_link`(
  IN _name VARCHAR(128),
  IN _variant VARCHAR(128),
  IN _url VARCHAR(1024)
)
BEGIN
  INSERT INTO font(`family`, `name`, `variant`, `url`, `ctime`, `mtime`)
            values(concat(`name`, ", ", `variant`), _name, _variant, _url, UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
  ON DUPLICATE KEY UPDATE `family`=concat(`name`, ", ", `variant`),
            `name`=_name, `variant`=_variant, `url`=_url, mtime=UNIX_TIMESTAMP();
  SELECT * FROM font WHERE `name`=_name;
END $


DELIMITER ;



call get_fonts_faces()