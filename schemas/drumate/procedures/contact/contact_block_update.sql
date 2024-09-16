DELIMITER $
DROP PROCEDURE IF EXISTS `contact_block_update`$
CREATE PROCEDURE `contact_block_update`(
  _contact_id  VARCHAR(1024)
)
BEGIN
  DECLARE _owner_id VARCHAR(16);
  DECLARE _check_id VARCHAR(16);
  SELECT id from yp.entity WHERE db_name = DATABASE() INTO _owner_id ;

  SELECT contact_id FROM yp.contact_block WHERE contact_id = _contact_id INTO _check_id; 
  IF _check_id = _contact_id THEN 
    INSERT INTO yp.contact_block (owner_id,contact_id,entity,uid)
    SELECT _owner_id , id , entity, uid FROM contact c WHERE id = _contact_id  ON DUPLICATE KEY UPDATE uid =c.uid  , entity = c.entity;
  END IF ;
END $
DELIMITER ;