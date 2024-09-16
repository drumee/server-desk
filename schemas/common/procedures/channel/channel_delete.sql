DELIMITER $




DROP PROCEDURE IF EXISTS `channel_delete`$
CREATE PROCEDURE `channel_delete`(
  IN _uid VARCHAR(16),
  IN _option VARCHAR(16),
  IN _messages JSON
)
BEGIN
  DECLARE _message_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _hub_id  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _drumate_hub_id  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _drumate_id  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _nid  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _node json;
  DECLARE _attachment  JSON;
  DECLARE _cnt INT(6) DEFAULT 0;
  DECLARE _idx_node INT(4) DEFAULT 0; 
  DECLARE _idx_attachment INT(4) DEFAULT 0; 
  DECLARE _sbx_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _sbx_db_name VARCHAR(255);
  DECLARE _type VARCHAR(16);
  DECLARE _entity_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _entity_db VARCHAR(255);  
  DECLARE _delete_nid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _delete_attachment  JSON;
  DECLARE _ref_sys_id INT;
  DECLARE _read_cnt INT ;
  DECLARE _read_sys_id BIGINT default 0;  

    SELECT id, type FROM yp.entity WHERE db_name=DATABASE() INTO _hub_id,_type;

    DROP TABLE IF EXISTS _show_node;
    CREATE TEMPORARY TABLE _show_node AS SELECT * FROM channel WHERE 1=2;
    ALTER TABLE _show_node ADD `delete_attachment` JSON;

    DROP TABLE IF EXISTS _list_uid;

    CREATE TEMPORARY TABLE _list_uid (
      id VARCHAR(16) CHARACTER SET ascii , 
      hub_id VARCHAR(16) CHARACTER SET ascii
      );

    ALTER TABLE _list_uid ADD `is_checked` boolean default 0 ;
    INSERT INTO _list_uid (id,hub_id) SELECT _uid,_hub_id;

    IF _type <> 'hub' THEN
      SELECT get_json_array(_messages, 0) INTO _message_id;
      SELECT entity_id FROM channel WHERE 
      message_id = _message_id INTO _entity_id;
    END IF;
   
    
    IF _type = 'hub' AND _option = 'all'  THEN
      INSERT INTO _list_uid (id, hub_id) SELECT  d.id, _hub_id FROM .permission p 
      INNER JOIN yp.drumate d on p.entity_id=d.id 
      WHERE p.resource_id='*' AND  d.id <> _uid;
    END IF;
    
    IF _type <> 'hub' AND _option = 'all'  THEN
      SELECT db_name FROM yp.entity WHERE id = _entity_id INTO _entity_db; 
      INSERT INTO _list_uid (id,hub_id) SELECT _entity_id,_entity_id;
    END IF; 



    WHILE _idx_node < JSON_LENGTH(_messages) DO 
      SELECT get_json_array(_messages, _idx_node) INTO _message_id;
    
      INSERT INTO _show_node SELECT  *, NULL FROM channel WHERE message_id = _message_id;
      SELECT attachment,sys_id FROM channel WHERE message_id = _message_id INTO _attachment,_ref_sys_id;
      
 
      IF _entity_db IS NOT NULL THEN

        SET @st = CONCAT('
        DELETE FROM ', _entity_db ,'.time_channel WHERE entity_id = ?');
        PREPARE stamt FROM @st;
        EXECUTE stamt USING  _uid;
        DEALLOCATE PREPARE stamt;


        SET @st = CONCAT('
        INSERT INTO ', _entity_db ,'.time_channel(entity_id, ref_sys_id,message,ctime)
        SELECT c.entity_id, c.sys_id,c.message, c.ctime FROM ', _entity_db ,'.channel c
        WHERE c.entity_id = ( SELECT  entity_id FROM ', _entity_db ,'.channel WHERE message_id = ?)  
        AND message_id <> ?
        ORDER BY c.sys_id DESC LIMIT 1
        ON DUPLICATE KEY UPDATE ref_sys_id= c.sys_id, ctime =c.ctime ,message=c.message');
        PREPARE stamt FROM @st;
        EXECUTE stamt USING _message_id,_message_id ;
        DEALLOCATE PREPARE stamt;


        SET @st = CONCAT('DELETE FROM ', _entity_db ,'.channel WHERE message_id= ?');
        PREPARE stamt FROM @st;
        EXECUTE stamt USING _message_id ;
        DEALLOCATE PREPARE stamt;
      END IF;

      IF _type <> 'hub' THEN
        DELETE FROM time_channel WHERE entity_id = _entity_id;
        INSERT INTO time_channel(entity_id, ref_sys_id,message,ctime)
        SELECT c.entity_id, c.sys_id,c.message, c.ctime FROM channel c
        WHERE c.entity_id = ( SELECT  entity_id FROM channel WHERE message_id = _message_id)  
        AND message_id <> _message_id
        ORDER BY c.sys_id DESC LIMIT 1
        ON DUPLICATE KEY UPDATE ref_sys_id= c.sys_id, ctime =c.ctime ,message=c.message;
        DELETE FROM channel WHERE message_id = _message_id;

      END IF;

      IF _type = 'hub' THEN
        INSERT INTO  delete_channel (uid,ref_sys_id,ctime)  
        SELECT id ,_ref_sys_id,UNIX_TIMESTAMP()  FROM _list_uid  ON DUPLICATE KEY UPDATE  ctime =UNIX_TIMESTAMP();
        SELECT 0 INTO _cnt;
        SELECT count(id)
        FROM permission p 
        INNER JOIN yp.drumate d ON  p.entity_id=d.id 
        WHERE p.resource_id='*'
        AND NOT EXISTS( SELECT 1 FROM delete_channel WHERE uid = d.id AND ref_sys_id = _ref_sys_id) INTO _cnt;

        DELETE FROM delete_channel WHERE ref_sys_id = _ref_sys_id AND  _cnt= 0 ; 
        DELETE FROM channel WHERE message_id = _message_id AND  _cnt= 0; 

      END IF;

      SELECT _idx_node + 1 INTO _idx_node;
    END WHILE;

    

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

    IF _type = 'hub' THEN
      SELECT id , hub_id FROM _list_uid WHERE is_checked =0  LIMIT 1 INTO _drumate_id , _drumate_hub_id;
        WHILE _drumate_id IS NOT NULL DO
      
          SELECT NULL INTO _ref_sys_id; 
          SELECT 0 INTO _read_cnt;
          SELECT NULL INTO _read_sys_id;

          SELECT max(sys_id) 
          FROM  channel c 
          LEFT JOIN delete_channel dc  
              ON dc.ref_sys_id = sys_id AND uid = _drumate_id
          WHERE  ref_sys_id IS NULL INTO _ref_sys_id;

          SELECT  ref_sys_id FROM read_channel WHERE uid = _drumate_id INTO _read_sys_id; 

          SELECT 
            COUNT(sys_id)
          FROM 
            channel c  WHERE  c.sys_id > _read_sys_id INTO _read_cnt ;

          INSERT INTO _last_node
          SELECT _drumate_id, _drumate_hub_id, LEFT(message, 100)  , attachment ,_read_cnt, ctime FROM channel  WHERE sys_id = _ref_sys_id ;

          INSERT INTO _last_node
          SELECT _drumate_id, _drumate_hub_id, NULL , NULL ,_read_cnt, NULL  WHERE  _ref_sys_id IS NULL;

          UPDATE _list_uid SET is_checked = 1 WHERE id = _drumate_id ;
          SELECT NULL,NULL INTO _drumate_id,_drumate_hub_id;
          SELECT id , hub_id FROM _list_uid WHERE is_checked =0  LIMIT 1 INTO _drumate_id , _drumate_hub_id;
        END WHILE;
    END IF;

    IF _type <> 'hub' THEN

     SELECT NULL INTO _ref_sys_id; 
     SELECT ref_sys_id FROM  time_channel WHERE  entity_id = _entity_id INTO  _ref_sys_id;
     INSERT INTO _last_node
     SELECT _uid, _entity_id, LEFT(message, 100)  , attachment ,0, ctime FROM channel  WHERE sys_id = _ref_sys_id ;

     INSERT INTO _last_node
     SELECT _uid, _entity_id, NULL , NULL ,0, NULL  WHERE  _ref_sys_id IS NULL;


    END IF;

    IF _entity_db IS NOT NULL THEN

      SELECT NULL INTO @ref_sys_id;

      SET @s = CONCAT(" SELECT ref_sys_id  FROM ",_entity_db , ".time_channel WHERE entity_id =? INTO @ref_sys_id");
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _uid;
      DEALLOCATE PREPARE stmt;


      SET @s = CONCAT(" SELECT ref_sys_id  FROM ",_entity_db , ".read_channel WHERE  entity_id =? AND uid =? INTO @read_sys_id");
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _uid , _entity_id;
      DEALLOCATE PREPARE stmt;


      SELECT 0 INTO @room_count ;
      SET @s = CONCAT(" SELECT  COUNT(sys_id)  FROM ",_entity_db , ".channel c WHERE c.entity_id = ? AND  c.sys_id > ? INTO @room_count");
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _uid, @read_sys_id; 
      DEALLOCATE PREPARE stmt;

      INSERT INTO _last_node
      SELECT _entity_id,_uid, NULL , NULL ,@room_count , NULL  WHERE  @ref_sys_id IS NULL;

      SET @s = CONCAT(" INSERT INTO _last_node  
      SELECT ?,?, LEFT(message, 100)  , attachment ,?, ctime  FROM ",_entity_db , ".channel WHERE sys_id =? ");
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _entity_id,_uid,@room_count, @ref_sys_id;
      DEALLOCATE PREPARE stmt;

    END IF;
    
    SELECT * FROM _show_node;
    SELECT * FROM _last_node;

END$

DELIMITER ;

