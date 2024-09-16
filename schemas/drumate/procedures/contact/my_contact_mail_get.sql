DELIMITER $
DROP PROCEDURE IF EXISTS `my_contact_mail_get`$
CREATE PROCEDURE `my_contact_mail_get`(
  IN  _contact_id VARCHAR(16)
)
BEGIN

  DECLARE _contact_category  VARCHAR(255); 
 
  SELECT category FROM contact WHERE id = _contact_id INTO _contact_category;
    SELECT 
      ce.id as email_id, ce.email, ce.category, is_default
    FROM  
    contact_email ce 
    WHERE ce.contact_id = _contact_id
    ORDER BY ce.sys_id ASC;

END$

DELIMITER ;