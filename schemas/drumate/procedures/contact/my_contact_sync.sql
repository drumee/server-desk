DELIMITER $
DROP PROCEDURE IF EXISTS `my_contact_sync`$
CREATE PROCEDURE `my_contact_sync`(
  IN _owner_id VARCHAR(16)
)
BEGIN

  DELETE FROM contact_phone WHERE contact_id IN(
  SELECT uid FROM yp.contact_sync WHERE status <>'ok' AND owner_id =_owner_id);
  
  DELETE FROM contact_address WHERE contact_id IN(
  SELECT uid FROM yp.contact_sync WHERE status <>'ok' AND owner_id =_owner_id);

  DELETE FROM contact_email WHERE contact_id IN(
  SELECT uid FROM yp.contact_sync  WHERE status <>'ok' AND owner_id =_owner_id);

  DELETE FROM contact WHERE entity IN(
  SELECT uid FROM yp.contact_sync WHERE status <>'ok' AND owner_id =_owner_id);

  DELETE FROM contact WHERE id IN(
  SELECT uid FROM yp.contact_sync WHERE status ='delete' AND owner_id =_owner_id);
 
  DELETE FROM yp.contact_sync WHERE status ='delete' AND owner_id =_owner_id;

  INSERT INTO contact (id,firstname,lastname,category,entity,uid,status,metadata,ctime,mtime) 
  SELECT id, firstname,lastname,'drumate',id,id,'active',JSON_OBJECT("source",email), UNIX_TIMESTAMP(),UNIX_TIMESTAMP() FROM yp.drumate t
  WHERE id IN (SELECT uid FROM yp.contact_sync WHERE  status <>'ok' AND owner_id =_owner_id)
  ON DUPLICATE KEY UPDATE id = t.id,entity=t.id,uid=t.id,
  firstname =t.firstname ,lastname=t.lastname,  metadata = JSON_OBJECT("source",t.email),
  surname = surname , comment=comment, message =message ,ctime=ctime,mtime =UNIX_TIMESTAMP();

  INSERT INTO contact_email (id,email,category,ctime,mtime ,contact_id ,is_default )
  SELECT id, email,'prof', UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),id,1 FROM yp.drumate t
  WHERE id IN (SELECT uid FROM yp.contact_sync WHERE status <>'ok' AND owner_id =_owner_id)
  ON DUPLICATE KEY UPDATE email=t.email, ctime=ctime,mtime =UNIX_TIMESTAMP();


  INSERT INTO contact_phone (id,areacode,phone,category,ctime,mtime,contact_id)
  SELECT id, read_json_object(profile, "areacode"),read_json_object(profile, "mobile"),'prof', UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),id FROM yp.drumate 
  WHERE id IN (SELECT uid FROM yp.contact_sync WHERE status<>'ok' AND owner_id =_owner_id);
    
  INSERT INTO contact_address (id,address,category,ctime,mtime,contact_id)
  SELECT id, read_json_object(profile, "address"),'prof', UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),id FROM yp.drumate 
  WHERE id IN (SELECT uid FROM yp.contact_sync WHERE status <>'ok' AND owner_id =_owner_id);
      
 
  UPDATE yp.contact_sync SET status='ok' WHERE status<>'ok' AND owner_id =_owner_id; 

END$



DELIMITER ;