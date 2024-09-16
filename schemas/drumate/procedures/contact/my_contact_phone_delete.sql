DELIMITER $

DROP PROCEDURE IF EXISTS `my_contact_phone_delete`$
CREATE PROCEDURE `my_contact_phone_delete`(
  IN  _contact_id VARCHAR(16), 
  IN  _id VARCHAR(16)
)
BEGIN
 
  IF _id IN ('',  '0') THEN 
   SELECT NULL INTO  _id;
  END IF;

  IF _id IS NULL THEN
    DELETE FROM contact_phone WHERE contact_id = _contact_id;
  ELSE 
    DELETE FROM contact_phone WHERE id =_id AND  contact_id = _contact_id;
  END IF; 

END$

DELIMITER ;