DELIMITER $

DROP PROCEDURE IF EXISTS `contact_invite_chk`$
CREATE PROCEDURE `contact_invite_chk`(
  IN _to_drumate_id  VARCHAR(16),
  IN _status VARCHAR(16) 
)
BEGIN

  SELECT entity , status  FROM contact  
  WHERE  
  status = IFNULL(_status,status) AND
  entity = _to_drumate_id ; 

END$


DELIMITER ;