DELIMITER $

DROP PROCEDURE IF EXISTS `my_contact_default_exist`$
CREATE PROCEDURE `my_contact_default_exist`(
    IN _email  VARCHAR(255),
    IN _contact_id VARCHAR(16)  
)
BEGIN

  IF _contact_id IN ('',  '0') THEN 
   SELECT NULL INTO  _contact_id;
  END IF;

    IF _contact_id IS NOT NULL THEN 
        SELECT email FROM contact 
        WHERE id <> _contact_id 
        AND email = _email  AND email IS NOT NULL LIMIT 1;
    ELSE 
        SELECT email FROM contact 
        WHERE  email = _email AND email IS NOT NULL LIMIT 1;         
    END IF;    


END$

DELIMITER ;