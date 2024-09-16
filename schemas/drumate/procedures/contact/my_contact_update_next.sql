DELIMITER $

DROP PROCEDURE IF EXISTS `my_contact_update_next`$
CREATE PROCEDURE `my_contact_update_next`(
  IN  _id VARCHAR(16),  
  IN _surname   VARCHAR(255),
  IN _firstname VARCHAR(255),
  IN _lastname  VARCHAR(255),
  IN _comment  MEDIUMTEXT,
  IN _message  MEDIUMTEXT,
  IN _entity   VARCHAR(1000),
  IN _metadata JSON    

)
BEGIN

 
  DECLARE _old_status  VARCHAR(255) ; 
  DECLARE _old_entity  VARCHAR(255) ; 
  DECLARE _uid VARCHAR(16);
  DECLARE _entitydb VARCHAR(255);
 
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

 
  SELECT entity,status FROM contact  WHERE id = _id INTO _old_entity, _old_status;

  SELECT id FROM yp.entity WHERE db_name=database() INTO  _uid;

  IF (_old_status NOT IN ('informed','received','active') AND _entity <> _old_entity) THEN
     SELECT _old_entity INTO _old_entity;
     DELETE FROM  yp.token WHERE email = _old_entity AND inviter_id = _uid;
     SELECT db_name FROM yp.entity WHERE id=_old_entity  INTO _entitydb;

    
    IF _entitydb IS NOT NULL THEN
      SET @st = CONCAT("DELETE FROM  " , _entitydb ,".contact WHERE  status ='received' AND entity = ? ");
      PREPARE stamt FROM @st;
      EXECUTE stamt USING _uid;
      DEALLOCATE PREPARE stamt;
    ELSE  
      SELECT NULL INTO _old_entity;
    END IF;  
    UPDATE contact SET status =  'memory'    WHERE id = _id;
  ELSE 
      SELECT NULL INTO _old_entity;
  END IF ; 

  UPDATE contact 
  SET  metadata= _metadata, surname=  _surname , firstname = _firstname, lastname=_lastname , comment = _comment ,message= _message ,entity = _entity,mtime =UNIX_TIMESTAMP()
  WHERE id = _id;

  CALL contact_block_update(_id);
  SELECT c.* , _old_entity old_entity  FROM contact c WHERE id= _id; 

END$


DELIMITER ;