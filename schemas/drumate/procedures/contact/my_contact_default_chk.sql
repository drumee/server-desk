DELIMITER $

DROP PROCEDURE IF EXISTS `my_contact_default_chk`$
CREATE PROCEDURE `my_contact_default_chk`(
    IN _email_id  VARCHAR(16),
    IN _contact_id VARCHAR(16)  
)
BEGIN

  DECLARE _email VARCHAR(255);

    SELECT email FROM contact_email WHERE id = _email_id INTO _email;

        SELECT email FROM contact 
        WHERE contact_id = _contact_id 
        AND email = _email LIMIT 1;
  

END$

DELIMITER ;