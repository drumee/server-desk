DELIMITER $
-- =========================================================
-- Convert all the email contact invitation to  contact notification.
-- =========================================================

DROP PROCEDURE IF EXISTS `contact_invite_to_notify`$
CREATE PROCEDURE `contact_invite_to_notify`(
  IN _email     VARCHAR(500)
)
BEGIN
  DECLARE _lvl INT(4); 
  DECLARE _inviter_id  VARCHAR(16);

  DECLARE _firstname   VARCHAR(255);
  DECLARE _lastname   VARCHAR(255);
  DECLARE _id VARCHAR(16);
  DECLARE _my_status VARCHAR(16); 
  DECLARE _inviter_db VARCHAR(255);  

  
  DROP TABLE IF EXISTS _inviter;
  CREATE TEMPORARY TABLE _inviter(
              inviter_id varchar(16) NOT NULL,
              is_checked boolean default 0
      );
  INSERT INTO _inviter(inviter_id)    
  
  SELECT DISTINCT inviter_id FROM yp.token WHERE email = _email AND inviter_id  IS NOT NULL AND status = 'active' and method = 'signup';  

  WHILE (IFNULL((SELECT 1 FROM _inviter  WHERE  is_checked = 0 LIMIT 1 ),0)  = 1 ) AND IFNULL(_lvl,0) < 1000 DO

    SELECT inviter_id  FROM _inviter WHERE is_checked = 0 LIMIT 1  INTO _inviter_id;
    
    SELECT NULL,NULL,NULL INTO _my_status, _id,_inviter_db;
   
    
    SELECT db_name FROM yp.entity WHERE id=_inviter_id INTO _inviter_db;
    
    
    
    IF _inviter_db IS NOT NULL THEN
        SET @st = CONCAT("UPDATE " , _inviter_db ,".contact SET entity=?  WHERE entity = ? ");
          PREPARE stamt FROM @st;
          EXECUTE stamt USING _inviter_id,_email;
        DEALLOCATE PREPARE stamt;
        
        
        SELECT status FROM  contact WHERE entity = _inviter_id INTO _my_status;

        SELECT id FROM (SELECT  yp.uniqueId() id ) a  WHERE _id IS NULL INTO _id ; 
        SELECT firstname,lastname  INTO _firstname,_lastname FROM yp.drumate d  WHERE d.id = _inviter_id; 
        
        INSERT INTO contact (id,firstname,lastname,category,status,entity,ctime,mtime) 
        SELECT _id , _firstname,_lastname,'drumate', 'received', _inviter_id, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()
        WHERE _my_status IS NULL ;
    END IF ; 
    
    UPDATE yp.token SET status ='passive'  WHERE email = _email AND inviter_id  IS NOT NULL AND status = 'active' and method = 'signup';  
    UPDATE _inviter SET is_checked =  1 WHERE inviter_id =_inviter_id; 
    SELECT IFNULL(_lvl,0) + 1 INTO _lvl;
  END WHILE; 


END $

DELIMITER ;