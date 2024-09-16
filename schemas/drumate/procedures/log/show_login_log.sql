DELIMITER $

DROP PROCEDURE IF EXISTS `show_login_log`$
CREATE PROCEDURE `show_login_log`(
  IN _page INT(6)
)
BEGIN
  DECLARE _uid VARCHAR(16);
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);
  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;
 
  SELECT  
    _page as `page`,
    cookie_id ,
    intime,
    outtime,
    read_json_object(l.metadata, "timezone") timezone,
    read_json_object(l.metadata, "city") city,
    read_json_object(l.metadata, "ip") ip,
    metadata,
    CASE WHEN c.id IS NULL THEN 'inactive' ELSE 'active' END  status 
  FROM 
  login_log l
  LEFT JOIN yp.cookie  c ON c.id=l.cookie_id AND c.uid = _uid
  WHERE l.intime IS NOT NULL
  ORDER BY l.sys_id DESC  LIMIT _offset, _range; 
END$


DELIMITER ;