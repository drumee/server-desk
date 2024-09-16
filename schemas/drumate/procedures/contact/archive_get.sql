DELIMITER $
DROP PROCEDURE IF EXISTS `archive_get`$
CREATE PROCEDURE `archive_get`(
 _entity_id VARCHAR(16)
)
BEGIN
  SELECT * FROM archive_entity WHERE entity_id = _en;
END$
DELIMITER ;