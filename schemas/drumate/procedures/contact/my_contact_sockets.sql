DELIMITER $
-- TO BE REMOVED DROP PROCEDURE IF EXISTS `my_contact_online`$
DROP PROCEDURE IF EXISTS `my_contact_sockets`$
CREATE PROCEDURE `my_contact_sockets`(
)
BEGIN

  SELECT s.uid, 
    c.firstname, 
    c.lastname, 
    s.id, s.server 
    FROM yp.socket s INNER JOIN contact c ON s.uid=c.uid  
    WHERE s.state = 'active';
END$

DELIMITER ;