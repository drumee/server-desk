
DELIMITER $

DROP PROCEDURE IF EXISTS `font_add`$
CREATE PROCEDURE `font_add`(
   IN _name         VARCHAR(200)
)
BEGIN
  DECLARE _last INT(11) DEFAULT 0;
  INSERT INTO used_fonts VALUES (NULL, _name, UNIX_TIMESTAMP());
  SELECT LAST_INSERT_ID() INTO _last;
  SELECT sys_id AS font_id, `name`, ctime 
    FROM used_fonts WHERE sys_id = _last;
END$

DELIMITER ;