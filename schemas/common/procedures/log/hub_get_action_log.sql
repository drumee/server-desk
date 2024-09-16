DELIMITER $
DROP PROCEDURE IF EXISTS `hub_get_action_log`$
CREATE PROCEDURE `hub_get_action_log`(
 IN _uid VARCHAR(16),
 IN _page TINYINT(4)
)
BEGIN

  DECLARE _is_admin int(10);
  DECLARE _range bigint;
  DECLARE _offset bigint;
    
  CALL pageToLimits(_page, _offset, _range);
  SELECT 0 INTO _is_admin; 

  SELECT 1 FROM permission p WHERE  resource_id='*'  and  p.entity_id= _uid  and permission&16 > 0 INTO _is_admin;

  SELECT 
    a.category,
    CASE WHEN a.category = 'media' THEN  CONCAT( a.log ,' by ',  d.firstname, ' ', d.lastname)  ELSE a.log END log,
    a.ctime
  FROM (
    SELECT * FROM action_log 
    WHERE notify_to ='member' AND entity_id = _uid
      UNION 
    SELECT * FROM action_log WHERE notify_to = 'all' 
      UNION 
    SELECT * FROM action_log WHERE notify_to ='admin' 
      AND _is_admin =1 
  ) a
  INNER JOIN yp.drumate d ON a.uid=d.id 
    ORDER BY ctime desc LIMIT _offset, _range;  

END$


DELIMITER ;