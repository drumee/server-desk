
DELIMITER $


-- =======================================================================
--
-- =======================================================================

DROP PROCEDURE IF EXISTS `permission_set`$
CREATE PROCEDURE `permission_set`(
  IN _uid VARCHAR(16),
  IN _privilege INT(4)
)
BEGIN
  DECLARE _db_name VARCHAR(30);
  DECLARE _hub_id VARCHAR(16);

  UPDATE permission SET permission=_privilege, utime = UNIX_TIMESTAMP()
    WHERE entity_id=_uid AND resource_id='*';
  SELECT db_name FROM yp.entity WHERE id=_uid INTO _db_name;
  SELECT id FROM yp.entity WHERE db_name=DATABASE() INTO _hub_id;
  SET @s = CONCAT(
    "UPDATE `" ,_db_name,"`.permission SET permission=",_privilege, 
    ", utime = UNIX_TIMESTAMP() WHERE resource_id=", QUOTE(_hub_id));
  PREPARE stmt FROM @s;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
 
END $

DELIMITER ;

