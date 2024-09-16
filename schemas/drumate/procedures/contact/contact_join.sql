DELIMITER $
DROP PROCEDURE IF EXISTS `contact_join`$
CREATE PROCEDURE `contact_join`(
   IN _source_secret  varchar(255) 
)
BEGIN
 
  DECLARE _secret VARCHAR(255);
  DECLARE _source_id VARCHAR(16);
  DECLARE _email VARCHAR(1024);
  DECLARE _lvl INT(4); 
  DECLARE _inviter_id  VARCHAR(16);
  DECLARE _invitee_id  VARCHAR(16);


  DECLARE _firstname   VARCHAR(255);
  DECLARE _lastname   VARCHAR(255);
  DECLARE _id VARCHAR(16);
  DECLARE _my_status VARCHAR(16); 
  DECLARE _inviter_db VARCHAR(255);

  


  DROP TABLE IF EXISTS _inviter;
  CREATE TEMPORARY TABLE _inviter(
              inviter_id varchar(16) NOT NULL,
              secret  varchar(255) NOT NULL,
              is_checked boolean default 0
            
      );

  DROP TABLE IF EXISTS _show;
  CREATE TEMPORARY TABLE _show(
              inviter_id varchar(16) NOT NULL    
            
      );

  SELECT email,inviter_id FROM yp.token 
  WHERE secret = _source_secret AND inviter_id  IS NOT NULL AND status = 'active' and method = 'signup' INTO _email ,_source_id ;  

  SELECT id FROM yp.entity WHERE db_name=database() INTO _invitee_id;
  INSERT INTO _inviter(inviter_id,secret)    
  SELECT inviter_id ,secret  FROM yp.token WHERE email = _email AND inviter_id  IS NOT NULL AND status = 'active' and method = 'signup';  

     
  WHILE (IFNULL((SELECT 1 FROM _inviter  WHERE  is_checked = 0 LIMIT 1 ),0)  = 1 ) AND IFNULL(_lvl,0) < 1000 DO

    SELECT inviter_id ,secret  FROM _inviter WHERE is_checked = 0 LIMIT 1  INTO _inviter_id, _secret;
    SELECT NULL,NULL,NULL INTO _my_status, _id,_inviter_db;

    SELECT db_name FROM yp.entity WHERE id=_inviter_id INTO _inviter_db;


    IF _inviter_db IS NOT NULL THEN

      SELECT  NULL INTO @entity ; 
      SET @st = CONCAT('SELECT  entity  FROM ', _inviter_db ,'.contact WHERE   entity =? or entity =? INTO @entity');
      PREPARE stamt FROM @st;
      EXECUTE stamt USING _email,_invitee_id ;
      DEALLOCATE PREPARE stamt;

      IF @entity IS NOT NULL THEN 

        IF _secret = _source_secret THEN 
          SET @st = CONCAT('UPDATE ', _inviter_db ,'.contact SET category ="drumate", status="active", uid = ?, entity=? WHERE  entity =? or entity =?');
          PREPARE stamt FROM @st;
          EXECUTE stamt USING _invitee_id,_invitee_id,_email,_invitee_id;
          DEALLOCATE PREPARE stamt;

          DELETE FROM contact WHERE uid = _inviter_id;
          DELETE FROM contact WHERE entity = _inviter_id;
          INSERT INTO contact (id,firstname,lastname,category,entity,uid,status,metadata,ctime,mtime) 
          SELECT yp.uniqueId(), firstname,lastname,'drumate',id,id,'active',null, UNIX_TIMESTAMP(),UNIX_TIMESTAMP() FROM yp.drumate t
          WHERE id = _inviter_id;

          INSERT INTO _show SELECT  _source_id WHERE _secret = _source_secret ;

        ELSE 

          SET @st = CONCAT('UPDATE ', _inviter_db ,'.contact SET category ="drumate", entity=? WHERE  entity =? or entity =?');
          PREPARE stamt FROM @st;
          EXECUTE stamt USING _invitee_id,_email,_invitee_id;
          DEALLOCATE PREPARE stamt;

          DELETE FROM contact WHERE uid = _inviter_id;
          DELETE FROM contact WHERE entity = _inviter_id;
          INSERT INTO contact (id,firstname,lastname,category,entity,uid,status,metadata,ctime,mtime) 
          SELECT yp.uniqueId(), firstname,lastname,'drumate',id,null,'received',null, UNIX_TIMESTAMP(),UNIX_TIMESTAMP() FROM yp.drumate t
          WHERE id = _inviter_id;

        END IF;  
      
      END IF ;

    END IF ; 
    UPDATE _inviter SET is_checked =  1 WHERE inviter_id =_inviter_id; 
    SELECT IFNULL(_lvl,0) + 1 INTO _lvl;

  END WHILE; 
 

  DELETE FROM yp.token where secret IN (SELECT secret From _inviter WHERE secret <>  _source_secret ); 
  -- DELETE FROM _inviter where secret IN (SELECT secret FROM _inviter WHERE secret <>  _source_secret ); 
  SELECT * from _show;

END$

DELIMITER ;