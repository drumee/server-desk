DELIMITER $
DROP PROCEDURE IF EXISTS `my_contact_address_get`$
CREATE PROCEDURE `my_contact_address_get`(
  IN  _contact_id VARCHAR(16)
)
BEGIN

  SELECT 
    id as address_id ,    
    JSON_UNQUOTE(JSON_EXTRACT(address, '$.street')) AS street,
    JSON_UNQUOTE(JSON_EXTRACT(address, '$.city')) AS city,
    JSON_UNQUOTE(JSON_EXTRACT(address, '$.country')) AS country, 
    category  
    FROM  contact_address WHERE contact_id = _contact_id
  ORDER BY sys_id ASC;
  
END$

DELIMITER ;