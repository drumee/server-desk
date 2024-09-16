DELIMITER $

DROP PROCEDURE IF EXISTS `contact_notification_by_entity`$
CREATE PROCEDURE `contact_notification_by_entity`(
  IN _entity     VARCHAR(500)
)
BEGIN
  SELECT 
    d.id drumate_id,
    d.email,
    ci.id contact_id,
    IFNULL(ci.firstname, '') AS firstname,
    IFNULL(ci.lastname, '') AS lastname,
    CONCAT(IFNULL(ci.firstname, ''), ' ', IFNULL(ci.lastname, '')) as fullname,
    ci.comment message,
    ci.status 
  FROM 
  contact ci 
  INNER JOIN yp.drumate d ON d.id = ci.entity
  WHERE ((ci.status="received") OR (ci.status="informed") OR (ci.status="invitation")) 
  AND (entity = _entity OR uid = _entity);
END$

DELIMITER ;