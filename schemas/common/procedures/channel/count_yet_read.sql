DELIMITER $


DROP PROCEDURE IF EXISTS `count_yet_read_next`$
CREATE PROCEDURE `count_yet_read_next`(
  IN _uid VARCHAR(16),
  IN _entity_id VARCHAR(16)
)
BEGIN
   
DECLARE _entity_id VARCHAR(16);
DECLARE _uid VARCHAR(16);
DECLARE _total_cnt int(11) unsigned;
DECLARE _room_cnt int(11) unsigned;
DECLARE _type VARCHAR(16);

  SELECT type FROM yp.entity WHERE db_name = DATABASE() INTO _type;
 IF _type != 'hub' THEN
 
    SELECT  
      COUNT(1)
    FROM 
      channel c 
    INNER JOIN read_channel rc ON rc.entity_id = c.entity_id  AND c.entity_id = c.author_id
    WHERE c.sys_id > rc.ref_sys_id  AND _uid = rc.uid 
    INTO  _total_cnt;

    SELECT  
      COUNT(1)
    FROM 
      channel c 
    INNER JOIN read_channel rc ON rc.entity_id = c.entity_id AND c.entity_id = c.author_id
    WHERE 
    rc.entity_id = _entity_id AND _uid = rc.uid AND
    c.sys_id > rc.ref_sys_id  INTO  _room_cnt;

  ELSE 
    SELECT  
      COUNT(1)
    FROM 
      channel c 
    INNER JOIN read_channel rc ON  c.author_id <> rc.uid
    WHERE c.sys_id > rc.ref_sys_id  AND _uid = rc.uid 
    INTO  _room_cnt;

 
  END IF; 
  
  SELECT _total_cnt total , _room_cnt room; 
 
END$  

DELIMITER ;

