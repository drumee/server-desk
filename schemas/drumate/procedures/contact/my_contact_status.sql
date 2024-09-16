DELIMITER $


DROP PROCEDURE IF EXISTS `my_contact_status`$
CREATE PROCEDURE `my_contact_status`(
)
BEGIN

  SELECT d.id uid,
    d.id user_id,
    d.connected `status`,
    IFNULL(c.firstname, d.firstname) firstname,
    IFNULL(c.lastname, d.lastname) lastname
    FROM yp.drumate d 
    INNER JOIN contact c on c.uid=d.id
    INNER JOIN yp.socket s ON s.uid=c.uid  
    WHERE s.state = 'active' GROUP BY d.id;
END$
DELIMITER ;