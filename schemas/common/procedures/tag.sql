DELIMITER $

-- =========================================================
--
-- =========================================================
DROP PROCEDURE IF EXISTS `tag_save`$
CREATE PROCEDURE `tag_save`(
  IN _sys_id        INT(11) UNSIGNED,
  IN _tag           VARCHAR(500),
  IN _lang          MEDIUMTEXT,
  IN _type          VARCHAR(50),
  IN _name          VARCHAR(500)
)
BEGIN
  DECLARE _row_count INT(11) UNSIGNED;
  DECLARE _id VARBINARY(16);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION, SQLWARNING
  BEGIN
    SELECT "INTERNAL_ERROR" AS error;
  END;
  IF _type = 'block' THEN
    SELECT id FROM block WHERE id=_tag OR hashtag=_tag INTO _id;
  ELSE
    SELECT _tag INTO _id;
  END IF;
  IF IFNULL(_sys_id, 0) = 0 THEN
    SET _sys_id = NULL;
    INSERT INTO content_tag (sys_id, id, `language`, `type`, `status`, `name`, ctime) VALUES
      (_sys_id, _id, _lang, _type, 'online', _name, UNIX_TIMESTAMP())
      ON DUPLICATE KEY UPDATE id = _id, `language`=_lang, `type` = _type, `status` = 'online', `name`=_name;
    SELECT LAST_INSERT_ID() INTO _sys_id;
    SELECT sys_id AS `serial`, id, `language`, `type`, `status`, `name` FROM content_tag WHERE sys_id = _sys_id;
  ELSE
    SELECT COUNT(sys_id) FROM content_tag WHERE sys_id = _sys_id AND id = _id INTO _row_count;
    IF IFNULL(_row_count, 0) = 0 THEN
      SELECT "ID_NOT_FOUND" AS error;
    ELSE
      UPDATE content_tag SET id = _id, `language`=_lang, `type` = _type,
        `status` = 'online', `name`=_name WHERE sys_id = _sys_id;
      SELECT sys_id AS `serial`, id, `language`, `type`, `status`, `name`
        FROM content_tag WHERE sys_id = _sys_id;
    END IF;
  END IF;
END $

-- =========================================================
--
-- =========================================================
DROP PROCEDURE IF EXISTS `tag_delete`$
CREATE PROCEDURE `tag_delete`(
  IN _sys_id        INT(11) UNSIGNED
)
BEGIN
  DELETE FROM content_tag WHERE sys_id = _sys_id;
  SELECT sys_id AS `serial`, id, `language`, `type`, `status`, `name` 
  FROM content_tag ORDER BY sys_id ASC;
END $

-- =========================================================
--
-- =========================================================
-- DROP PROCEDURE IF EXISTS `tag_get_list`$
DROP PROCEDURE IF EXISTS `tag_list`$
CREATE PROCEDURE `tag_list`(
  IN _page         INT(6)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);
  SELECT 
    `name`, 
    GROUP_CONCAT( `hashtag` SEPARATOR ' ' ) as ids,
    `description` as content,
    _page as `page`
    FROM content_tag
    INNER JOIN `block` USING(id) 
    WHERE content_tag.`status`='online' 
    GROUP BY `name`,`description` ASC LIMIT _offset, _range;
END $

-- =========================================================
--
-- =========================================================
DROP PROCEDURE IF EXISTS `tag_get_by_name`$
CREATE PROCEDURE `tag_get_by_name`(
  IN _name         VARCHAR(100),
  IN _page         INT(6)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);
  SELECT 
    `id`,
    `name`, 
    `hashtag`,
    `language`,
    `description` as content,
    _page as `page`
    FROM content_tag c
    INNER JOIN `block` USING(id) 
    WHERE c.`status`='online' AND `name`=_name 
    ORDER BY c.rank ASC LIMIT _offset, _range;
END $

-- =========================================================
--
-- =========================================================

DROP PROCEDURE IF EXISTS `tag_list_by_lang`$
CREATE PROCEDURE `tag_list_by_lang`(
  IN _lang         VARCHAR(100),
  IN _page         INT(6)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);
  SELECT 
--    block.id,
    `name`, 
--    `hashtag`,
    GROUP_CONCAT( `hashtag` SEPARATOR ' ' ) as ids,
    -- `lang`,
    -- content,
    (
      SELECT content FROM yp.translate 
      WHERE translate.key_code=`name` AND translate.lang=_lang
    ) as content,
    _page as `page`,
    (
      SELECT group_rank FROM content_tag c1
      WHERE c1.name=c2.name limit 1
    ) AS `rank`
    FROM content_tag c2
    INNER JOIN `block` USING(id) 
    WHERE c2.`status`='online' 
    GROUP BY `name`,`description` ASC ORDER by `rank` LIMIT _offset, _range;
END $
DELIMITER ;
