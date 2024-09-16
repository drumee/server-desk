DELIMITER $

DROP PROCEDURE IF EXISTS `my_contact_address_delete`$
CREATE PROCEDURE `my_contact_address_delete`(
  IN  _contact_id VARCHAR(16), 
  IN  _id VARCHAR(16)  
)
BEGIN

  IF _id IN ('',  '0') THEN 
   SELECT NULL INTO  _id;
  END IF;
 
  IF _id IS NULL THEN
    DELETE FROM contact_address WHERE contact_id = _contact_id;
  ELSE 
    DELETE FROM contact_address WHERE id =_id AND  contact_id = _contact_id;
  END IF; 

END$


DELIMITER ;