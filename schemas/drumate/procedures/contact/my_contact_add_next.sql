DELIMITER $

DROP PROCEDURE IF EXISTS `my_contact_add_next`$
CREATE PROCEDURE `my_contact_add_next`(
  IN _entity    VARCHAR(1000),
  IN _surname   VARCHAR(255),
  IN _firstname VARCHAR(255),
  IN _lastname  VARCHAR(255),
  IN _category  VARCHAR(255),
  IN _comment  MEDIUMTEXT,
  IN _message  MEDIUMTEXT,
  IN _metadata JSON 
)
BEGIN

  DECLARE _id VARCHAR(16);
  SELECT id FROM (SELECT  yp.uniqueId() id ) a  WHERE _id IS NULL INTO _id ; 

  IF _firstname IN ('') THEN 
   SELECT NULL INTO  _firstname;
  END IF;

  IF _lastname IN ('') THEN 
   SELECT NULL INTO  _lastname;
  END IF;

  IF _surname IN ('') THEN 
   SELECT NULL INTO  _surname;
  END IF;

 IF _comment IN ('') THEN 
   SELECT NULL INTO  _comment;
  END IF;

 IF _message IN ('') THEN 
   SELECT NULL INTO  _message;
  END IF;

  INSERT INTO contact 
  (id,surname,firstname,lastname,category,entity,comment,message,status,ctime,mtime) 
  values( _id, _surname,_firstname,_lastname ,_category ,_entity, _comment,_message,'memory', UNIX_TIMESTAMP(), UNIX_TIMESTAMP());
  

  UPDATE contact 
    SET metadata =  _metadata
  WHERE id =  _id; 

  SELECT * FROM contact WHERE id= _id; 

END$

DELIMITER ;