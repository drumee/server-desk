DELIMITER $
DROP PROCEDURE IF EXISTS `leave_hub`$
CREATE PROCEDURE `leave_hub`(
  IN _hub_id VARCHAR(16)
)
BEGIN
  DECLARE _hub_db VARCHAR(20);
  DECLARE _uid VARCHAR(16);

  SELECT id FROM yp.entity WHERE db_name=database() INTO _uid;
  SELECT db_name FROM yp.entity WHERE id=_hub_id INTO _hub_db;

  DELETE FROM media WHERE id =_hub_id;
  DELETE FROM permission WHERE resource_id =_hub_id;

  IF _hub_db IS NOT NULL THEN 

    SET @s2 = CONCAT("DELETE FROM `", _hub_db, "`.permission WHERE entity_id=", quote(_uid) );
    PREPARE stmt FROM @s2;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;

END $


DELIMITER ;


