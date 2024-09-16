DELIMITER $
/*

  Status : active 

*/

DROP PROCEDURE IF EXISTS `post_acknowledge_message`$
CREATE PROCEDURE `post_acknowledge_message`(
IN _in JSON
)
BEGIN

  DECLARE _entity_id VARCHAR(16);
  DECLARE _message_id VARCHAR(16);
  DECLARE _uid VARCHAR(16);
  DECLARE _ref_sys_id int(11) unsigned default 0 ;
  DECLARE _old_ref_sys_id int(11) unsigned default 0 ;
  DECLARE _entity_db VARCHAR(255); 
 
  
  SELECT JSON_UNQUOTE(JSON_EXTRACT(_in, "$.message_id")) INTO _message_id;
  SELECT JSON_UNQUOTE(JSON_EXTRACT(_in, "$.uid")) INTO _uid;
  SELECT JSON_UNQUOTE(JSON_EXTRACT(_in, "$.entity_id")) INTO _entity_id;

 
  SELECT sys_id FROM channel c WHERE message_id = _message_id  INTO _ref_sys_id;
  SELECT ref_sys_id FROM read_channel WHERE entity_id =_uid  AND uid = _uid INTO _old_ref_sys_id;


  SELECT CASE WHEN _ref_sys_id < _old_ref_sys_id THEN _old_ref_sys_id ELSE _ref_sys_id END INTO _ref_sys_id;

  -- UPDATE channel SET  metadata = JSON_SET(metadata,CONCAT("$._seen_.", _uid), UNIX_TIMESTAMP())
  -- WHERE sys_id <= _ref_sys_id   AND 
  -- JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid))= 0;
  
  INSERT INTO read_channel(entity_id,uid,ref_sys_id,ctime) SELECT _uid,_uid,_ref_sys_id,UNIX_TIMESTAMP() 
  ON DUPLICATE KEY UPDATE ref_sys_id= _ref_sys_id , ctime =UNIX_TIMESTAMP();


  SELECT NULL INTO _old_ref_sys_id;
  SELECT ref_sys_id FROM read_channel WHERE entity_id = _uid AND uid = _entity_id INTO _old_ref_sys_id;

  INSERT INTO read_channel(entity_id,uid,ref_sys_id,ctime) SELECT _uid,_entity_id,0,UNIX_TIMESTAMP() 
  WHERE _old_ref_sys_id IS NULL;

  
END$  

DELIMITER ;