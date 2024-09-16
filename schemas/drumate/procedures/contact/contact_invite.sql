DELIMITER $

DROP PROCEDURE IF EXISTS `contact_invite`$
CREATE PROCEDURE `contact_invite`(
  IN _entity     VARCHAR(255)
)
BEGIN
  DECLARE _invitee_db VARCHAR(255);
  DECLARE _inviter_id VARCHAR(16);
  DECLARE _invitee_status VARCHAR(16);  
  DECLARE _contact_id VARCHAR(16);
  DECLARE _message VARCHAR(2000); 

 
  SELECT id FROM yp.entity WHERE db_name=database() INTO _inviter_id;
  SELECT db_name FROM yp.entity WHERE id=_entity INTO _invitee_db;
  SELECT message FROM  contact  WHERE  entity = _entity INTO _message; 

  IF _invitee_db IS NOT NULL THEN
    SET @st = CONCAT("CALL  " , _invitee_db ,".contact_invite_post (?,?,?)");
    PREPARE stamt FROM @st;
    EXECUTE stamt USING _inviter_id,_message,_invitee_status;
    DEALLOCATE PREPARE stamt;
  END IF;	  

  UPDATE contact SET invitetime = UNIX_TIMESTAMP()  WHERE  entity = _entity; 
  
  UPDATE contact SET status = 'informed', uid= _entity 
  WHERE  entity = _entity  AND _invitee_status = 'active' AND _invitee_db IS NOT  NULL  ;

  UPDATE contact SET status = 'active',uid= _entity  
  WHERE entity = _entity AND _invitee_status = 'informed'  AND _invitee_db IS NOT  NULL;
    
  UPDATE contact SET status = 'sent' 
  WHERE entity = _entity  AND _invitee_status in ('received' , 'invitation') AND _invitee_db IS NOT  NULL;

  UPDATE contact SET status = 'sent'   WHERE  entity = _entity  AND _invitee_db IS NULL ;

 SELECT id FROM contact WHERE ( entity= _entity) INTO  _contact_id;
 CALL  contact_block_update(_contact_id);


  SELECT status FROM contact WHERE entity=  _entity; 
  
END$

DELIMITER ;
