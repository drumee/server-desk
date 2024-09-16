DELIMITER $
DROP PROCEDURE IF EXISTS `my_contact_exists`$
CREATE PROCEDURE `my_contact_exists`(
  IN  _key  VARCHAR(255),
  IN  _value1  VARCHAR(255),
  IN  _value2  VARCHAR(255),
  IN _contact_id VARCHAR(16)  
)
BEGIN

  IF _contact_id IN ('',  '0') THEN 
   SELECT NULL INTO  _contact_id;
  END IF;

   IF _value1 IN ('',  '0') THEN 
   SELECT NULL INTO  _value1;
  END IF;
	
   IF _value2 IN ('', '0') THEN 
   SELECT NULL INTO  _value2;
  END IF;


  IF _contact_id IS NULL THEN 
  
    IF (_key = 'name') THEN
     SELECT * FROM contact
     WHERE NULLIF(firstname,-99) = NULLIF(_value1,-99)  AND NULLIF(lastname,-99) = NULLIF(_value2,-99) AND _value1 IS NOT NULL AND 
     _value2 IS NOT     NULL     LIMIT 1;
    END IF ; 

    IF (_key = 'entity') THEN
     SELECT * FROM contact
     WHERE NULLIF(entity,-99) = NULLIF(_value1,-99)  
     LIMIT 1;
    END IF ; 
  
  ELSE 
    IF (_key = 'name') THEN
    SELECT * FROM contact
     WHERE NULLIF(firstname,-99) = NULLIF(_value1,-99)  AND 
     NULLIF(lastname,-99) = NULLIF(_value2,-99) AND 
     _value1 IS NOT NULL AND 
     _value2 IS NOT  NULL AND 
     id <> _contact_id
      LIMIT 1;
    END IF ; 

    IF (_key = 'entity') THEN
     SELECT * FROM contact
     WHERE NULLIF(entity,-99) = NULLIF(_value1,-99)  AND 
     id <> _contact_id
     LIMIT 1;
    END IF ; 

  END IF;


END$

DELIMITER ;