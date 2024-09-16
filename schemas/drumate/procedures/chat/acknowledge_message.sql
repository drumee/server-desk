DELIMITER $
/*

  Status : active 

*/
DROP PROCEDURE IF EXISTS `acknowledge_message`$
CREATE PROCEDURE `acknowledge_message`(
IN _in JSON
)
BEGIN

  DECLARE _entity_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _author_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _message_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _ref_sys_id int(11) unsigned default 0 ;
  DECLARE _old_ref_sys_id int(11) unsigned default 0 ;
  DECLARE _entity_db VARCHAR(255); 
 

  -- SELECT id FROM yp.entity where db_name= DATABASE() INTO _uid;

  SELECT JSON_UNQUOTE(JSON_EXTRACT(_in, "$.message_id")) INTO _message_id;
  SELECT JSON_UNQUOTE(JSON_EXTRACT(_in, "$.uid")) INTO _uid;
  SELECT JSON_UNQUOTE(JSON_EXTRACT(_in, "$.entity_id")) INTO _entity_id;
  
  
  SELECT sys_id FROM channel c WHERE message_id = _message_id INTO _ref_sys_id ;


  SELECT ref_sys_id FROM read_channel WHERE entity_id = _entity_id AND uid = _uid INTO _old_ref_sys_id;


  SELECT CASE WHEN _ref_sys_id < _old_ref_sys_id THEN _old_ref_sys_id ELSE _ref_sys_id END INTO _ref_sys_id;


  -- SELECT  _ref_sys_id,_author_id, _entity_id, _old_ref_sys_id;

  -- UPDATE channel SET  metadata = JSON_SET(metadata,CONCAT("$._seen_.", _uid), UNIX_TIMESTAMP())
  -- WHERE sys_id <= _ref_sys_id   AND 
  -- JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid))= 0;
  
  INSERT INTO read_channel(entity_id,uid,ref_sys_id,ctime) SELECT _entity_id,_uid,_ref_sys_id,UNIX_TIMESTAMP() 
  ON DUPLICATE KEY UPDATE ref_sys_id= _ref_sys_id , ctime =UNIX_TIMESTAMP() ;


  SELECT NULL INTO _old_ref_sys_id;
  SELECT ref_sys_id FROM read_channel WHERE entity_id = _entity_id AND uid = _entity_id INTO _old_ref_sys_id;

  INSERT INTO read_channel(entity_id,uid,ref_sys_id,ctime) SELECT _entity_id,_entity_id,0,UNIX_TIMESTAMP() 
  WHERE _old_ref_sys_id IS NULL;


  SELECT db_name FROM yp.entity WHERE id=_entity_id AND status <> 'deleted' INTO _entity_db;
  IF _entity_db  IS  NOT NULL THEN 
      SET @st = CONCAT('CALL ', _entity_db ,'.post_acknowledge_message(?)');
      PREPARE stamt FROM @st;
      EXECUTE stamt USING JSON_MERGE( JSON_OBJECT('message_id',_message_id ) , JSON_OBJECT('entity_id', _entity_id  ) ,JSON_OBJECT('uid',_uid )) ;
      DEALLOCATE PREPARE stamt; 
 END IF;
END$  
DELIMITER ;