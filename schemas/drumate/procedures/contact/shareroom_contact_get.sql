DELIMITER $
DROP PROCEDURE IF EXISTS `shareroom_contact_get`$
CREATE PROCEDURE `shareroom_contact_get`(
  IN _uid     VARCHAR(16)
)
BEGIN
  DECLARE _owner_id VARCHAR(16);
   DECLARE _mail  VARCHAR(500);
    SELECT id FROM yp.entity WHERE db_name=DATABASE() INTO _owner_id;
    SELECT email FROM yp.drumate WHERE id = _owner_id INTO _mail;
    
    SELECT
      du.id ,
      c.id contact_id, 
      c.firstname,
      c.lastname, 
      c.entity entity,
      IFNULL(c.surname,  IF(coalesce(c.firstname, c.lastname) IS NULL, coalesce(ce.email,de.email,du.email) , CONCAT( IFNULL(c.firstname, '') ,' ',  IFNULL(c.lastname, '')))) as surname,
      CASE WHEN mycb.sys_id IS NOT NULL THEN 1 ELSE 0 END is_blocked,
      CASE WHEN hiscb.sys_id IS NOT NULL THEN 1 ELSE 0 END is_blocked_me
    FROM
      yp.drumate du 
      LEFT JOIN contact c ON du.id = c.entity
      LEFT JOIN contact_email ce ON ce.contact_id = c.id  AND ce.is_default = 1 
      LEFT JOIN yp.drumate de on de.id=c.entity
      LEFT JOIN yp.contact_block mycb ON  c.id = mycb.contact_id
      LEFT JOIN yp.contact_block hiscb ON 
      (hiscb.owner_id =  c.entity OR hiscb.owner_id =c.uid) 
       AND( hiscb.uid =  _owner_id OR hiscb.entity = _owner_id ) 
     --  LEFT JOIN yp.socket ON socket.uid = c.uid
    WHERE du.id = _uid;

END$
DELIMITER ;