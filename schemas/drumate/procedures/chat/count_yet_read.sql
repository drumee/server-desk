DELIMITER $
/*

  Status : active 

*/

DROP PROCEDURE IF EXISTS `count_yet_read`$
CREATE PROCEDURE `count_yet_read`(
IN _in JSON,
OUT _out JSON
)
BEGIN
   
DECLARE _entity_id VARCHAR(16);
DECLARE _uid VARCHAR(16);
DECLARE _total_cnt int(11) unsigned;
DECLARE _room_cnt int(11) unsigned;

  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;
  SELECT JSON_UNQUOTE(JSON_EXTRACT(_in, "$.entity_id")) INTO _entity_id;
  

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

  SELECT  JSON_MERGE(IFNULL(_out,'{}'), JSON_OBJECT('total',_total_cnt ),   JSON_OBJECT('room',_room_cnt)) INTO  _out;
  
 
END$  

DELIMITER ;