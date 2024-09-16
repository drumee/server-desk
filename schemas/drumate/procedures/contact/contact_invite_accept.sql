DELIMITER $

DROP PROCEDURE IF EXISTS `contact_invite_accept`$
CREATE PROCEDURE `contact_invite_accept`(
  IN _to_drumate_id     VARCHAR(16)
)
BEGIN

      
    DECLARE _to_drumate_db VARCHAR(255);
    DECLARE _frm_drumate_id VARCHAR(16);
    DECLARE _contact_id VARCHAR(16);
    DECLARE _firstname   VARCHAR(255);
    DECLARE _lastname   VARCHAR(255);
    
    SELECT db_name FROM yp.entity WHERE id=_to_drumate_id INTO _to_drumate_db;
    SELECT id FROM yp.entity WHERE db_name=database() INTO _frm_drumate_id;
   
    SELECT firstname,lastname FROM yp.drumate WHERE id=_frm_drumate_id INTO _firstname,_lastname;
    

    SELECT id FROM contact WHERE entity = _to_drumate_id AND status IN ( 'received', "invitation") INTO _contact_id;
    UPDATE contact set status = 'active' , uid = entity , category='drumate'  WHERE entity = _to_drumate_id AND status IN ( 'received', "invitation") ;
    CALL contact_block_update(_contact_id);


    SET @st = CONCAT('SELECT  id,firstname,lastname FROM ', _to_drumate_db ,'.contact WHERE entity = ? INTO @contact_id,@firstname,@lastname');
    PREPARE stamt FROM @st;
    EXECUTE stamt USING _frm_drumate_id ;
    DEALLOCATE PREPARE stamt;   
    
    IF rtrim(ltrim(@firstname)) IN ('',  '0') THEN 
      SELECT NULL INTO  @firstname;
    END IF;

    IF rtrim(ltrim(@lastname)) IN ('',  '0') THEN 
      SELECT NULL INTO  @lastname;
    END IF;

    SELECT IFNULL(@firstname,_firstname) INTO _firstname ;
    SELECT IFNULL(@lastname, _lastname)  INTO _lastname;

    SET @st = CONCAT('CALL ', _to_drumate_db ,'.contact_block_update(?)');
    PREPARE stamt FROM @st;
    EXECUTE stamt USING  @contact_id ;
    DEALLOCATE PREPARE stamt; 


    SET @st = CONCAT('UPDATE  ', _to_drumate_db ,'.contact SET firstname=?,  lastname=? , status = "informed" ,  category="drumate" , uid= ? WHERE entity = ?');
    PREPARE stamt FROM @st;
    EXECUTE stamt USING _firstname , _lastname,_frm_drumate_id ,_frm_drumate_id ;
    DEALLOCATE PREPARE stamt; 
   
    SELECT _to_drumate_id drumate_id, status , id contact_id from contact WHERE entity = _to_drumate_id ;

END$



DELIMITER ;