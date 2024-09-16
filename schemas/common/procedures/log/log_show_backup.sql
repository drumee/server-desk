DELIMITER $

DROP PROCEDURE IF EXISTS `log_show_backup`$
CREATE PROCEDURE `log_show_backup`(
 IN _page TINYINT(4)
)
BEGIN

  DECLARE _is_admin int(10);
  DECLARE _range bigint;
  DECLARE _offset bigint;
    
  CALL pageToLimits(_page, _offset, _range);
  SELECT * FROM action_log WHERE action='backup'
    ORDER BY ctime ASC LIMIT _offset, _range;  

END$

DELIMITER ;