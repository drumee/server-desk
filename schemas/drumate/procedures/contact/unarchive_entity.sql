DELIMITER $
DROP PROCEDURE IF EXISTS `unarchive_entity`$
CREATE PROCEDURE `unarchive_entity`(
 _entity_id VARCHAR(16)
)
BEGIN
  DELETE FROM  archive_entity WHERE entity_id= _entity_id;
  SELECT * FROM archive_entity WHERE entity_id = _entity_id;
END$
DELIMITER ;