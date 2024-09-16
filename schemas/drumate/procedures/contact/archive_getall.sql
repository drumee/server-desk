DELIMITER $
DROP PROCEDURE IF EXISTS `archive_getall`$
CREATE PROCEDURE `archive_getall`()
BEGIN
  SELECT * FROM archive_entity ;
END$
DELIMITER ;