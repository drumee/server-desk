DELIMITER $
DROP PROCEDURE IF EXISTS `my_contact_server_online`$
CREATE PROCEDURE `my_contact_server_online`(
  IN _server varchar(256)
)
BEGIN

  SELECT s.uid, c.firstname, s.id, s.server 
    FROM yp.socket s INNER JOIN contact c ON s.uid=c.uid
    WHERE s.server = _server  AND s.state='active';
END$

DELIMITER ;