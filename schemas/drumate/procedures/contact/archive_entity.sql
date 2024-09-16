DELIMITER $
DROP PROCEDURE IF EXISTS `archive_entity`$
CREATE PROCEDURE `archive_entity`(
 _entity_id VARCHAR(16)
)
BEGIN
  REPLACE INTO archive_entity(entity_id) SELECT _entity_id;
  SELECT * FROM archive_entity WHERE entity_id = _entity_id;
END$
DELIMITER ;