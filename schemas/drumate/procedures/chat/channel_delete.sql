DELIMITER $


DROP PROCEDURE IF EXISTS `channel_delete_drumate_me`$
CREATE PROCEDURE `channel_delete_drumate_me`(
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _option VARCHAR(16),
  IN _messages JSON
)
BEGIN
  DECLARE _hub_id  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _memeber_cnt INT ;

  DECLARE _message_id VARCHAR(16) CHARACTER SET ascii; 
  DECLARE _ref_sys_id BIGINT default 0;
  DECLARE _attachment  JSON;
  DECLARE _idx_node INT(4) DEFAULT 0;
  DECLARE _cnt INT ;
  DECLARE _idx_attachment INT(4) DEFAULT 0;
  DECLARE _node json;
  DECLARE _nid  VARCHAR(16) CHARACTER SET ascii;

  DECLARE _drumate_hub_id  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _drumate_id  VARCHAR(16) CHARACTER SET ascii;

  DECLARE _max_sys_id BIGINT;
  DECLARE _max_ref_sys_id BIGINT;
  DECLARE _read_cnt INT ;
  DECLARE _read_sys_id BIGINT default 0;

 DECLARE _entity_id VARCHAR(16) CHARACTER SET ascii;
 DECLARE _entity_db VARCHAR(255); 

  SELECT get_json_array(_messages, 0) INTO _message_id;
      SELECT entity_id FROM channel WHERE 
      message_id = _message_id INTO _entity_id;
  SELECT db_name FROM yp.entity WHERE id = _entity_id INTO _entity_db; 



  DROP TABLE IF EXISTS _show_node;
  CREATE TEMPORARY TABLE _show_node AS SELECT * FROM channel WHERE 1=2;
  ALTER TABLE _show_node ADD `delete_attachment` JSON;

 DROP TABLE IF EXISTS `_last_node`;
  CREATE TEMPORARY TABLE `_last_node` (
      `uid` VARCHAR(16) CHARACTER SET ascii NOT NULL,  
      `entity_id` VARCHAR(16) CHARACTER SET ascii NOT NULL,
      `message`     VARCHAR(100) ,
      `attachment`  longtext,  
      `room_count` INT DEFAULT 0,
      `ctime` int(11)  NULL,
      UNIQUE KEY `id` (`uid`)
  ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 ;

  WHILE _idx_node < JSON_LENGTH(_messages) DO 
    SELECT get_json_array(_messages, _idx_node) INTO _message_id;
    INSERT INTO _show_node SELECT  *, NULL FROM channel WHERE message_id = _message_id;
    SELECT attachment,sys_id,entity_id FROM channel WHERE message_id = _message_id INTO _attachment,_ref_sys_id , _entity_id;

    DELETE FROM channel WHERE message_id = _message_id;

    SELECT 0  INTO @_othersidemsg;
    
    IF _entity_db IS NOT NULL THEN
      SET @st = CONCAT('SELECT 1 FROM ', _entity_db ,'.channel WHERE message_id= ? INTO @_othersidemsg');
      PREPARE stamt FROM @st;
      EXECUTE stamt USING _message_id ;
      DEALLOCATE PREPARE stamt;
    END IF;
    
    IF (@_othersidemsg = 0) THEN 
      WHILE _idx_attachment < JSON_LENGTH(_attachment) DO 
        SELECT JSON_QUERY(_attachment, CONCAT("$[", _idx_attachment, "]") ) INTO _node;
        SELECT JSON_VALUE(_node, '$.hub_id') INTO _hub_id;
        SELECT JSON_VALUE(_node, '$.nid') INTO _nid;
     
        SELECT db_name FROM yp.entity  WHERE id = _hub_id  INTO @hub_db_name;

        SET @st = CONCAT("UPDATE yp.disk_usage SET size = IFNULL(size,0) - (SELECT IFNULL(SUM(filesize),0) FROM "
                ,@hub_db_name, ".media  WHERE id =", QUOTE(_nid) ,") WHERE hub_id =",QUOTE( _hub_id),";");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt; 

        SET @st = CONCAT("DELETE  FROM "
                ,@hub_db_name, ".media  WHERE id =", QUOTE(_nid) ,";");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt;

        SELECT _idx_attachment + 1 INTO _idx_attachment;
      END WHILE;

      UPDATE _show_node SET delete_attachment = _attachment WHERE message_id = _message_id; 
    END IF;
    

    SELECT _idx_node + 1 INTO _idx_node;
  END WHILE;

  SELECT max(sys_id) FROM channel  WHERE entity_id = _entity_id INTO _max_sys_id;
  DELETE FROM  time_channel WHERE entity_id = _entity_id;
  INSERT INTO time_channel(entity_id, ref_sys_id,message,ctime)
  SELECT c.entity_id, c.sys_id,c.message, c.ctime FROM channel c WHERE sys_id = _max_sys_id;
  INSERT INTO _last_node
  SELECT _uid, _entity_id, LEFT(message, 100)  , attachment ,0, ctime FROM channel  WHERE sys_id = _max_sys_id ;


  SELECT * FROM _show_node;
  SELECT * FROM _last_node;
END$






DROP PROCEDURE IF EXISTS `channel_delete_drumate_all`$
CREATE PROCEDURE `channel_delete_drumate_all`(
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _option VARCHAR(16),
  IN _messages JSON
)
BEGIN
  DECLARE _hub_id  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _memeber_cnt INT ;

  DECLARE _message_id VARCHAR(16) CHARACTER SET ascii; 
  DECLARE _ref_sys_id BIGINT default 0;
  DECLARE _attachment  JSON;
  DECLARE _idx_node INT(4) DEFAULT 0;
  DECLARE _cnt INT ;
  DECLARE _idx_attachment INT(4) DEFAULT 0;
  DECLARE _node json;
  DECLARE _nid  VARCHAR(16) CHARACTER SET ascii;

  DECLARE _drumate_hub_id  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _drumate_id  VARCHAR(16) CHARACTER SET ascii;

  DECLARE _max_sys_id BIGINT;
  DECLARE _max_ref_sys_id BIGINT;
  DECLARE _read_cnt INT ;
  DECLARE _read_sys_id BIGINT default 0;

 DECLARE _entity_id VARCHAR(16) CHARACTER SET ascii;
 DECLARE _entity_db VARCHAR(255); 



  SELECT get_json_array(_messages, 0) INTO _message_id;
      SELECT entity_id FROM channel WHERE 
      message_id = _message_id INTO _entity_id;
  SELECT db_name FROM yp.entity WHERE id = _entity_id INTO _entity_db; 


  DROP TABLE IF EXISTS _show_node;
  CREATE TEMPORARY TABLE _show_node AS SELECT * FROM channel WHERE 1=2;
  ALTER TABLE _show_node ADD `delete_attachment` JSON;

 DROP TABLE IF EXISTS `_last_node`;
  CREATE TEMPORARY TABLE `_last_node` (
      `uid` VARCHAR(16) CHARACTER SET ascii NOT NULL,  
      `entity_id` VARCHAR(16) CHARACTER SET ascii NOT NULL,
      `message`     VARCHAR(100) ,
      `attachment`  longtext,  
      `room_count` INT DEFAULT 0,
      `ctime` int(11)  NULL,
      UNIQUE KEY `id` (`uid`)
  ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 ;

  WHILE _idx_node < JSON_LENGTH(_messages) DO 
    SELECT get_json_array(_messages, _idx_node) INTO _message_id;
    INSERT INTO _show_node SELECT  *, NULL FROM channel WHERE message_id = _message_id;
    SELECT attachment,sys_id FROM channel WHERE message_id = _message_id INTO _attachment,_ref_sys_id ;

    DELETE FROM channel WHERE message_id = _message_id;

    IF _entity_db IS NOT NULL THEN
      SET @st = CONCAT('DELETE FROM ', _entity_db ,'.channel WHERE message_id= ?');
      PREPARE stamt FROM @st;
      EXECUTE stamt USING _message_id ;
      DEALLOCATE PREPARE stamt;
    END IF;
      WHILE _idx_attachment < JSON_LENGTH(_attachment) DO 
        SELECT JSON_QUERY(_attachment, CONCAT("$[", _idx_attachment, "]") ) INTO _node;
        SELECT JSON_VALUE(_node, '$.hub_id') INTO _hub_id;
        SELECT JSON_VALUE(_node, '$.nid') INTO _nid;
     
        SELECT db_name FROM yp.entity  WHERE id = _hub_id  INTO @hub_db_name;

        SET @st = CONCAT("UPDATE yp.disk_usage SET size = IFNULL(size,0) - (SELECT IFNULL(SUM(filesize),0) FROM "
                ,@hub_db_name, ".media  WHERE id =", QUOTE(_nid) ,") WHERE hub_id =",QUOTE( _hub_id),";");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt; 

        SET @st = CONCAT("DELETE  FROM "
                ,@hub_db_name, ".media  WHERE id =", QUOTE(_nid) ,";");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt;

        SELECT _idx_attachment + 1 INTO _idx_attachment;
      END WHILE;

    UPDATE _show_node SET delete_attachment = _attachment WHERE message_id = _message_id; 

    SELECT _idx_node + 1 INTO _idx_node;
  END WHILE;

  SELECT max(sys_id) FROM channel  WHERE entity_id = _entity_id INTO _max_sys_id;
  DELETE FROM  time_channel WHERE entity_id = _entity_id;
  INSERT INTO time_channel(entity_id, ref_sys_id,message,ctime)
  SELECT c.entity_id, c.sys_id,c.message, c.ctime FROM channel c WHERE sys_id = _max_sys_id;
  INSERT INTO _last_node
  SELECT _uid, _entity_id, LEFT(message, 100)  , attachment ,0, ctime FROM channel  WHERE sys_id = _max_sys_id ;

  IF _entity_db IS NOT NULL THEN
    SET @st = CONCAT('
      DELETE FROM ', _entity_db ,'.time_channel WHERE entity_id = ?');
      PREPARE stamt FROM @st;
      EXECUTE stamt USING  _uid;
      DEALLOCATE PREPARE stamt;

    SET @st = CONCAT('SELECT max(sys_id) FROM ', _entity_db ,'.channel  
      WHERE entity_id = ? INTO @_max_sys_id;');
      PREPARE stamt FROM @st;
      EXECUTE stamt USING  _uid;
      DEALLOCATE PREPARE stamt;

    SET @st = CONCAT('  INSERT INTO  ', _entity_db ,'.time_channel(entity_id, ref_sys_id,message,ctime)
      SELECT c.entity_id, c.sys_id,c.message, c.ctime FROM  ', _entity_db ,'.channel c WHERE sys_id =  @_max_sys_id;');
      PREPARE stamt FROM @st;
      EXECUTE stamt ;
      DEALLOCATE PREPARE stamt;

    SET @st = CONCAT('  INSERT INTO _last_node
      SELECT ?, ?, LEFT(message, 100)  , attachment ,0, ctime FROM ', _entity_db ,'.channel  WHERE sys_id = @_max_sys_id ;
      ');
      PREPARE stamt FROM @st;
      EXECUTE stamt USING _entity_id,  _uid;
      DEALLOCATE PREPARE stamt;
  END IF;
  SELECT * FROM _show_node;
  SELECT * FROM _last_node;
END$


DELIMITER ;
