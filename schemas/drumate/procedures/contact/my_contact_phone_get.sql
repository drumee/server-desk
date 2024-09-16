DELIMITER $
DROP PROCEDURE IF EXISTS `my_contact_phone_get`$
CREATE PROCEDURE `my_contact_phone_get`(
  IN  _contact_id VARCHAR(16)
)
BEGIN

  SELECT id as phone_id ,areacode, phone, category  FROM  contact_phone WHERE contact_id = _contact_id
  ORDER BY sys_id ASC;
  
END$

DELIMITER ;