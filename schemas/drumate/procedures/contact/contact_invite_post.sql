DELIMITER $

DROP PROCEDURE IF EXISTS `contact_invite_post`$
CREATE PROCEDURE `contact_invite_post`(
  IN _inviter_id     VARCHAR(16),
  IN  _message VARCHAR(2000),
  OUT _invitee_status VARCHAR(16)
)
BEGIN

   DECLARE _firstname   VARCHAR(255);
   DECLARE _lastname   VARCHAR(255);
   DECLARE _id VARCHAR(16);
   DECLARE _my_status VARCHAR(16); 
   DECLARE _email VARCHAR(500);
   DECLARE _contact_id VARCHAR(16);
   
  SELECT email FROM yp.drumate WHERE id = _inviter_id OR email = _inviter_id INTO _email;

  SELECT id FROM (SELECT  yp.uniqueId() id ) a  WHERE _id IS NULL INTO _id ; 
  SELECT status from contact WHERE entity = _inviter_id OR  entity = _email INTO _my_status;
  SELECT firstname,lastname 
  INTO _firstname,_lastname FROM yp.drumate d  WHERE d.id = _inviter_id; 

 
 INSERT INTO contact (id,firstname,lastname,category,status,entity,ctime,mtime) 
 SELECT _id , _firstname,_lastname,'drumate', 'received', _inviter_id, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()
 WHERE _my_status IS NULL ;

 -- UPDATE contact SET status ='active', category ='drumate',  uid= _inviter_id  WHERE ( entity= _inviter_id OR  entity = _email) and _my_status = 'memory';
  
 UPDATE contact SET status ='invitation', category ='drumate', mtime = UNIX_TIMESTAMP()  WHERE ( entity= _inviter_id OR  entity = _email) and _my_status IN ('memory' ,'invitation' );
 UPDATE contact SET status ='received', category ='drumate' , mtime = UNIX_TIMESTAMP() WHERE ( entity= _inviter_id OR  entity = _email ) and _my_status = 'received';
 UPDATE contact SET status ='informed' , category ='drumate' , mtime = UNIX_TIMESTAMP() WHERE ( entity= _inviter_id OR  entity = _email ) and _my_status in( 'informed','sent');
 SELECT id FROM contact WHERE ( entity= _inviter_id OR  entity = _email) INTO  _contact_id;
 CALL  contact_block_update(_contact_id);
 UPDATE contact SET message= _message  WHERE ( entity= _inviter_id OR  entity = _email );
 SELECT status FROM contact WHERE entity= _inviter_id INTO _invitee_status; 

END$

DELIMITER ;