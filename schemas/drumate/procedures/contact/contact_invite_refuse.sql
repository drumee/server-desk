DELIMITER $

DROP PROCEDURE IF EXISTS `contact_invite_refuse`$
CREATE PROCEDURE `contact_invite_refuse`(
  IN _to_drumate_id     VARCHAR(16)
)
BEGIN

   SELECT 
    d.id drumate_id,
    d.email,
    IFNULL(ci.firstname, '') AS firstname,
    IFNULL(ci.lastname, '') AS lastname,
    CONCAT(IFNULL(ci.firstname, ''), ' ', IFNULL(ci.lastname, '')) as fullname,
    ci.comment message,
    'deleted' status
    FROM 
    contact ci 
    INNER JOIN yp.drumate d ON d.id = ci.entity
    WHERE ci.entity = _to_drumate_id AND status IN ( 'received', "invitation") ;

   DELETE FROM contact  WHERE entity = _to_drumate_id AND status = 'received';
   UPDATE contact  SET status = 'memory'  WHERE entity = _to_drumate_id AND status = 'invitation';
    
END$


DELIMITER ;