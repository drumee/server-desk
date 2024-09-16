DELIMITER $

-- #########################################################
--
-- CCS  SECTION
--
-- #########################################################

DROP PROCEDURE IF EXISTS `style_list`$
CREATE PROCEDURE `style_list`(
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);

  SELECT * FROM `style` ORDER BY selector ASC LIMIT _offset, _range;
END $

-- =========================================================
--
-- =========================================================
DROP PROCEDURE IF EXISTS `style_get`$
CREATE PROCEDURE `style_get`(
  IN _id VARCHAR(16)
)
BEGIN
  SELECT * FROM `style` where id=_id;
END $

-- =========================================================
--
-- =========================================================
-- DROP PROCEDURE IF EXISTS `get_style`$
-- DROP PROCEDURE IF EXISTS `style_get_all`$
DROP PROCEDURE IF EXISTS `style_get_classes`$
CREATE PROCEDURE `style_get_classes`(
)
BEGIN
  SELECT * FROM `style`;
END $

-- ===============================================================
-- style_get_files
--
-- ===============================================================

DROP PROCEDURE IF EXISTS `style_get_files`$
CREATE PROCEDURE `style_get_files`(
)
BEGIN
  SELECT id as nid FROM media  WHERE category='stylesheet' AND status='active';
END $

-- ===============================================================
-- style_get_files
--
-- ===============================================================
DROP PROCEDURE IF EXISTS `style_sheets`$
CREATE PROCEDURE `style_sheets`(
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);

  SELECT id AS nid, user_filename AS `filename`,  caption, metadata as outerClass
  FROM media  WHERE category='stylesheet' AND status='active' 
  ORDER BY upload_time DESC LIMIT _offset, _range;
END $

-- =========================================================
--
-- =========================================================
-- DROP PROCEDURE IF EXISTS `get_style`$
DROP PROCEDURE IF EXISTS `style_search`$
CREATE PROCEDURE `style_search`(
  IN _str VARCHAR(100)
)
BEGIN
  SELECT * FROM `style` where selector like concat("%", _str, "%");
END $

-- =========================================================
-- old version, should be deprecated
-- =========================================================

DROP PROCEDURE IF EXISTS `style_add`$
CREATE PROCEDURE `style_add`(
  IN _selector VARCHAR(255),
  IN _style VARCHAR(12000),
  IN _comment VARCHAR(255)
)
BEGIN
  insert into style(`selector`, `declaration`, `comment`) values(_selector, _style, _comment)
  ON DUPLICATE KEY UPDATE `selector`=_selector, `declaration`=_style, `comment`=_comment;
  SELECT * FROM style WHERE id=LAST_INSERT_ID();
END $

-- =========================================================
--
-- =========================================================

DROP PROCEDURE IF EXISTS `style_create`$
CREATE PROCEDURE `style_create`(
  IN _name VARCHAR(255),
  IN _sel VARCHAR(255),
  IN _style VARCHAR(12000),
  IN _comment VARCHAR(255)
)
BEGIN

  DECLARE _className  VARCHAR(100) DEFAULT '';
  DECLARE _selector   VARCHAR(200) DEFAULT '';
  SELECT concat('cc-', yp.uniqueId()) INTO _className;
  SELECT IF(_sel IS NULL OR _sel = '', concat('.', _className), concat('.', _className, ' ', _sel))
    INTO _selector;
  INSERT INTO `style`(`name`, `class_name`, `selector`, `declaration`, `comment`)
               VALUES(_name, _className, _selector, _style, _comment)
  ON DUPLICATE KEY UPDATE `name`=_name, `selector`=_selector, `declaration`=_style, `comment`=_comment;
  SELECT * FROM `style` WHERE id=LAST_INSERT_ID();
END $


-- =========================================================
--
-- =========================================================

DROP PROCEDURE IF EXISTS `style_save`$
CREATE PROCEDURE `style_save`(
  IN _id VARCHAR(16),
  IN _style VARCHAR(12000)
)
BEGIN
  UPDATE style SET declaration=_style WHERE id=_id;
  SELECT * FROM style WHERE id=_id;
END $

-- =========================================================
--
-- =========================================================

DROP PROCEDURE IF EXISTS `style_remove`$
CREATE PROCEDURE `style_remove`(
  IN _id VARCHAR(16)
)
BEGIN
  DELETE FROM style WHERE id=_id;
  SELECT _id as id;
END $

-- =========================================================
--
-- =========================================================

DROP PROCEDURE IF EXISTS `style_rename`$
CREATE PROCEDURE `style_rename`(
  IN _id VARCHAR(16),
  IN _name VARCHAR(255)
)
BEGIN
  UPDATE style SET `name`=_name WHERE id=_id;
  SELECT * FROM style WHERE id=_id;
END $


DELIMITER ;
