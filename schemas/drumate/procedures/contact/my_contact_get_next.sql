DELIMITER $
DROP PROCEDURE IF EXISTS `my_contact_get_next`$
CREATE PROCEDURE `my_contact_get_next`(
  IN  _key  VARCHAR(255),
  IN _contact_id VARCHAR(16)  
)
BEGIN
  DECLARE _uid VARCHAR(120);
  DECLARE _mail  VARCHAR(500);
  DECLARE _domain_id INT ;
  
    SELECT id FROM yp.entity WHERE db_name=DATABASE() INTO _uid;
    SELECT email FROM yp.drumate WHERE id = _uid INTO _mail;
    SELECT 1 INTO _domain_id;
    SELECT domain_id FROM yp.privilege p WHERE  p.domain_id <> 1 AND p.uid = _uid INTO _domain_id; 
 
  IF _contact_id IN ('', '0') THEN 
   SELECT NULL INTO  _contact_id;
  END IF; 

  IF _contact_id IS NULL THEN 
    
    SELECT c.id as id,
      c.entity,	 
      c.firstname,
      c.lastname,
      c.comment, 
      c.ctime, 
      c.invitetime,
      c.mtime, 
      c.category, 
      c.uid, 
      c.status,
      c.source,
      c.metadata,
      IFNULL(du.connected,-1) connected,
      du.username ident, du.username,
      e.dom_id domain_id,
      CASE WHEN  yp.user_exists( c.entity)=1 THEN 1 ELSE 0 END is_drumate ,
      CASE WHEN _domain_id <> 1 AND _domain_id = e.dom_id THEN 1 ELSE 0 END is_same_domain,
      IFNULL(c.surname,  IF(coalesce(c.firstname, c.lastname) IS NULL, IFNULL(ce.email,de.email) , CONCAT( IFNULL(c.firstname, '') ,' ',  IFNULL(c.lastname, '')))) as surname,
      c.surname given_surname,
      -- CASE WHEN du.id IS NULL THEN 1 ELSE 0 END is_need_email , 
      1 is_need_email , 
      CASE WHEN mycb.sys_id IS NOT NULL THEN 1 ELSE 0 END is_blocked,
      CASE WHEN hiscb.sys_id IS NOT NULL THEN 1 ELSE 0 END is_blocked_me ,
      CASE WHEN ae.entity_id IS NOT NULL THEN 1 ELSE 0 END is_archived  
    FROM contact c 
    LEFT JOIN contact_email ce ON ce.contact_id = c.id  AND ce.is_default = 1  
    LEFT JOIN yp.entity e on e.id=c.uid
    LEFT JOIN yp.drumate de on de.id=c.entity
    LEFT JOIN yp.drumate du ON du.id = c.uid 
    LEFT JOIN archive_entity ae ON ae.entity_id = c.id
    LEFT JOIN yp.contact_block mycb ON c.id = mycb.contact_id
    LEFT JOIN yp.drumate dm ON dm.email = ce.email
    LEFT JOIN yp.contact_block hiscb ON (hiscb.owner_id =  c.entity OR hiscb.owner_id = dm.id) 
      AND( hiscb.uid = _uid OR hiscb.entity = _uid OR hiscb.entity = _mail ) 
    WHERE c.id= _key ; 
  ELSE

    SELECT id as contact_id ,surname,firstname,lastname,comment,ctime,mtime,category,uid, _uid ident,
    CASE WHEN  yp.user_exists( entity)=1 THEN 1 ELSE 0 END is_drumate 
    FROM contact 
    WHERE id <> _contact_id AND CONCAT(firstname, ' ', lastname)  = _key LIMIT 1;
  
  END IF;

END$

DELIMITER ;