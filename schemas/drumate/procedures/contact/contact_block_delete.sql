DELIMITER $
DROP PROCEDURE IF EXISTS `contact_block_delete`$
CREATE PROCEDURE `contact_block_delete`(
  _contact_id  VARCHAR(1024)
)
BEGIN
  DELETE FROM yp.contact_block WHERE contact_id = _contact_id;
END $
DELIMITER ;