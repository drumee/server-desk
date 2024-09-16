DELIMITER $

DROP PROCEDURE IF EXISTS `contact_notification_count`$
CREATE PROCEDURE `contact_notification_count`()
BEGIN
  SELECT 
      count(ci.id) count
  FROM 
  contact ci 
  INNER JOIN yp.drumate d ON d.id = ci.entity
  WHERE (ci.status="received") OR (ci.status="informed") OR (ci.status="invitation");
END$

DELIMITER ;