

DELIMITER $

DROP PROCEDURE IF EXISTS `hub_add_action_log` $
CREATE PROCEDURE `hub_add_action_log`(
  
  IN _uid VARCHAR(16),
  IN _action VARCHAR(16),
  IN _category VARCHAR(16),
  IN _notify_to VARCHAR(16),
  IN _entity_id VARCHAR(16),
  IN  _log  VARCHAR(1000)
)
BEGIN

INSERT INTO action_log (uid, category,action,notify_to,entity_id,log,ctime )
SELECT _uid, _category,_action,_notify_to,_entity_id,_log,UNIX_TIMESTAMP();

END $


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
    FROM 
       (
        SELECT * FROM action_log where notify_to ='member' and entity_id = _uid
            UNION 
        SELECT * FROM action_log where notify_to = 'all' 
            UNION 
        SELECT * FROM action_log where notify_to ='admin'  and _is_admin =1 
       ) a
  INNER JOIN yp.drumate d ON a.uid=d.id 
   ORDER BY ctime desc LIMIT _offset, _range;  

END$

-- ================================================

DROP PROCEDURE IF EXISTS `log_show_backup`$
CREATE PROCEDURE `log_show_backup`(
 IN _page TINYINT(4)
)
BEGIN

  DECLARE _is_admin int(10);
  DECLARE _range bigint;
  DECLARE _offset bigint;
    
  CALL pageToLimits(_page, _offset, _range);


   SELECT * FROM action_log WHERE action='backup'
   ORDER BY ctime ASC LIMIT _offset, _range;  

END$

DELIMITER ;