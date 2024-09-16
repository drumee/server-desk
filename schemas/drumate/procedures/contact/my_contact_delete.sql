DELIMITER $
DROP PROCEDURE IF EXISTS `my_contact_delete`$
CREATE PROCEDURE `my_contact_delete`(
  IN  _contact_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  DECLARE _category VARCHAR(255);
  DECLARE _id VARCHAR(255) CHARACTER SET ascii;
  DECLARE _drumate_db VARCHAR(255);
  DECLARE _email VARCHAR(1000);
  DECLARE _his_id VARCHAR(255) CHARACTER SET ascii;

  SELECT IFNULL(uid,entity) FROM contact WHERE (id = _contact_id OR  uid =_contact_id) INTO _his_id; 
  SELECT db_name FROM yp.entity WHERE id=_his_id INTO _drumate_db;
  
  SELECT id FROM yp.entity WHERE db_name=DATABASE() INTO _id;  
  SELECT email FROM yp.drumate WHERE id = _id  INTO _email;
  DROP TABLE IF EXISTS _show;
  CREATE TEMPORARY TABLE _show  AS SELECT 1 AS Temp WHERE 1=2 ;  
  IF _drumate_db IS NOT NULL THEN

    SET @st = CONCAT('DELETE FROM ', _drumate_db ,'.contact WHERE (uid =? or entity = ? or uid = ? or entity =?) AND status="received"');
    PREPARE stamt FROM @st;
    EXECUTE stamt USING _id,_id,_email,_email;
    DEALLOCATE PREPARE stamt; 


    SET @st = CONCAT('UPDATE ', _drumate_db ,'.contact SET status = "memory"  WHERE (uid =? or entity = ? or uid = ? or entity =?) AND status="invitation"');
    PREPARE stamt FROM @st;
    EXECUTE stamt USING _id,_id,_email,_email;
    DEALLOCATE PREPARE stamt; 


    SET @st = CONCAT('UPDATE ', _drumate_db ,'.contact_email SET  is_default = 0 WHERE   is_default = 1 AND contact_id  = (SELECT id FROM ', _drumate_db ,'.contact WHERE uid =? or entity = ? or uid = ? or entity =? )');
    PREPARE stamt FROM @st;
    EXECUTE stamt USING _id,_id,_email,_email;
    DEALLOCATE PREPARE stamt;

    SET @st = CONCAT('UPDATE ', _drumate_db ,'.contact_email SET  is_default = 0 WHERE   is_default = 1 AND contact_id  = (SELECT id FROM ', _drumate_db ,'.contact WHERE uid =? or entity = ? or uid = ? or entity =? )');
    PREPARE stamt FROM @st;
    EXECUTE stamt USING _id,_id,_email,_email;
    DEALLOCATE PREPARE stamt;

    SET @st = CONCAT('DELETE FROM ', _drumate_db ,'.contact_email WHERE  email =? AND contact_id  = (SELECT id FROM ', _drumate_db ,'.contact WHERE uid =? or entity = ? or uid = ? or entity =? )');
    PREPARE stamt FROM @st;
    EXECUTE stamt USING _email,_id,_id,_email,_email;
    DEALLOCATE PREPARE stamt;


    SET @st = CONCAT('INSERT INTO ', _drumate_db ,'.contact_email (id,email,category,ctime,mtime ,contact_id ,is_default )
    SELECT  yp.uniqueId(),?,"priv",UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),id,1 FROM ', _drumate_db ,'.contact WHERE uid =? or entity = ? or uid = ? or entity =? 
    ON DUPLICATE KEY UPDATE is_default =1');
    PREPARE stamt FROM @st;
    EXECUTE stamt USING _email,_id,_id,_email,_email;
    DEALLOCATE PREPARE stamt;


    SET @st = CONCAT('UPDATE ', _drumate_db ,'.contact SET category ="independant", metadata = JSON_OBJECT("source",? ), status="memory", uid = null, entity=? WHERE uid =? or entity =? or uid = ? or entity =?');
    PREPARE stamt FROM @st;
    EXECUTE stamt USING  _email,_id,_id,_id,_id,_email;
    DEALLOCATE PREPARE stamt;


   SELECT NULL INTO  @_contact_id; 
   SET @st = CONCAT('SELECT id FROM ', _drumate_db ,'.contact WHERE (uid =? or entity = ? or uid = ? or entity =?)  INTO @_contact_id');
   PREPARE stamt FROM @st;
   EXECUTE stamt USING _id,_id,_email,_email;
   DEALLOCATE PREPARE stamt; 


   SET @st = CONCAT(' CALL ', _drumate_db ,'.contact_block_update(?)');
   PREPARE stamt FROM @st;
   EXECUTE stamt USING @_contact_id;
   DEALLOCATE PREPARE stamt; 

    DROP TABLE IF EXISTS _show;
    SET @st = CONCAT('CREATE TEMPORARY TABLE _show as  SELECT 
    ci.id contact_id,  d.id drumate_id,"', _his_id ,'" as his_id,
    d.email, IFNULL(ci.firstname, "") AS firstname,
    IFNULL(ci.lastname, "") AS lastname,
    CONCAT(IFNULL(ci.firstname,""), " ", IFNULL(ci.lastname, " ")) as fullname,
    status
    FROM  ', _drumate_db ,'.contact ci 
    LEFT JOIN yp.drumate d ON d.id = ci.entity
    WHERE (ci.uid =? or ci.entity = ? or ci.uid = ? or ci.entity =?)');
    PREPARE stamt FROM @st;
    EXECUTE stamt USING _id,_id,_email,_email;
    DEALLOCATE PREPARE stamt;



  END  IF ;
    DELETE FROM map_tag WHERE id = _contact_id;   
    DELETE FROM contact WHERE id = _contact_id; 
    DELETE FROM contact_email WHERE contact_id = _contact_id;
    DELETE FROM contact_phone WHERE contact_id = _contact_id;
    DELETE FROM contact_address WHERE contact_id = _contact_id;
    CALL contact_block_delete(_contact_id);
    SELECT * FROM _show;
    
END$
DELIMITER ;








