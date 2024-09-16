
DELIMITER $

DROP PROCEDURE IF EXISTS `font_last`$
CREATE PROCEDURE `font_last`()
BEGIN
  SELECT sys_id AS font_id, name, ctime FROM used_fonts
    WHERE sys_id IN (SELECT MAX(sys_id) FROM used_fonts GROUP BY name)
    ORDER BY sys_id DESC LIMIT 3;
END$

DELIMITER ;