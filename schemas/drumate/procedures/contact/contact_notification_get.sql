DELIMITER $

DROP PROCEDURE IF EXISTS `contact_notification_get`$
CREATE PROCEDURE `contact_notification_get`()
BEGIN
   SELECT 
    d.id drumate_id,
    d.email,
    IFNULL(ci.firstname, '') AS firstname,
    IFNULL(ci.lastname, '') AS lastname,
   --  RTRIM(LTRIM(CONCAT(IFNULL(ci.firstname, ''), ' ', IFNULL(ci.lastname, '')))) as fullname,
    ci.message message,
    ci.status ,
    CASE WHEN json_value(`metadata`,'$.is_auto') =1 THEN d. fullname 
    ELSE RTRIM(LTRIM(CONCAT(IFNULL(ci.firstname, ''), ' ', IFNULL(ci.lastname, '')))) END  fullname
  FROM 
  contact ci 
  INNER JOIN yp.drumate d ON d.id = ci.entity
  WHERE (ci.status="received") OR (ci.status="informed") OR (ci.status="invitation");
END$


DELIMITER ;