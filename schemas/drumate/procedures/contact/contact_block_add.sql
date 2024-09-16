DELIMITER $
DROP PROCEDURE IF EXISTS `contact_block_add`$
CREATE PROCEDURE `contact_block_add`(
  _contact_id  VARCHAR(1024)
)
BEGIN
  DECLARE _owner_id VARCHAR(16);
  SELECT id from yp.entity WHERE db_name = DATABASE() INTO _owner_id ;
  INSERT INTO yp.contact_block (owner_id,contact_id,entity,uid)
  SELECT _owner_id , c.id , c.entity, c.uid FROM contact c WHERE id = _contact_id  ON DUPLICATE KEY UPDATE uid =c.uid  , entity = c.entity;
  SELECT * FROM yp.contact_block WHERE contact_id =_contact_id;

END $
DELIMITER ;