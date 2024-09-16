DELIMITER $

DROP PROCEDURE IF EXISTS `tag_chat_count`$
CREATE PROCEDURE `tag_chat_count`(
  IN _tag_id  VARCHAR(16)
)
BEGIN

  DECLARE _this_hub_id VARCHAR(16);
  DECLARE _nid VARCHAR(16);
  DECLARE _db_name VARCHAR(500);
  DECLARE _temp_result JSON;
  DECLARE _read_cnt INT ;
  DECLARE _ctime INT(11) unsigned;
  DECLARE _message mediumtext;
  DECLARE _temp_nid VARCHAR(16);

   SELECT id FROM yp.entity WHERE db_name=DATABASE() INTO  _this_hub_id ;
    
    DROP TABLE IF EXISTS _show_node;
    CREATE TEMPORARY TABLE _show_node (
      entity_id  VARCHAR(16) NOT NULL,  
      hub_id VARCHAR(16) NOT null,
      room_count INT DEFAULT 0,
      flag VARCHAR(500),
      db_name   VARCHAR(500)  NULL,
      PRIMARY KEY `entity_id`(`entity_id`)
    ); 

    INSERT INTO _show_node
    SELECT
      c.uid  entity_id, 
      _this_hub_id   hub_id,  
      IFNULL(( 
              SELECT 
                COUNT(1)
              FROM 
                channel ch 
              INNER JOIN  read_channel rc ON ch.entity_id= rc.entity_id 
              WHERE
                ch.entity_id = ch.author_id AND 
                rc.entity_id <> rc.uid  AND 
                ch.sys_id > rc.ref_sys_id AND 
                ch.entity_id = c.uid), 0),
       'contact' ,null
    FROM
      contact c
    LEFT JOIN time_channel tc ON tc.entity_id = c.uid
    LEFT JOIN contact_email ce ON ce.contact_id = c.id  AND ce.is_default = 1  
    INNER JOIN yp.drumate du ON du.id = c.uid
    WHERE CASE WHEN _tag_id IS NOT NULL AND  _tag_id <> ''  THEN  c.id IN ( SELECT id FROM map_tag mt WHERE mt.tag_id = _tag_id) ELSE c.id =c.id END 
    AND c.uid IS NOT NULL;




    INSERT INTO _show_node(entity_id,hub_id,flag,db_name)
    SELECT 
      m.id ,m.id , 'share', db_name    
    FROM 
    media m
    INNER JOIN yp.hub h on  h.id = m.id 
    INNER  JOIN yp.entity he ON m.id = he.id
    WHERE category = 'hub'
    AND CASE WHEN _tag_id IS NOT NULL AND  _tag_id <> ''  THEN  m.id IN ( SELECT id FROM map_tag mt WHERE mt.tag_id = _tag_id) ELSE m.id =m.id END;
 
    ALTER TABLE _show_node ADD `is_checked` boolean default 0 ;
    UPDATE   _show_node SET is_checked = 1 WHERE flag='contact';

    
    SELECT entity_id ,db_name FROM _show_node WHERE is_checked =0  LIMIT 1 INTO _nid, _db_name; 
    WHILE _nid IS NOT NULL DO
 
          SET @st = CONCAT('CALL ', _db_name ,'.room_detail(?,?)');
          PREPARE stamt FROM @st;
          EXECUTE stamt USING  JSON_OBJECT('uid',_this_hub_id ) , _temp_result ;
          DEALLOCATE PREPARE stamt; 
        
          SELECT JSON_UNQUOTE(JSON_EXTRACT(_temp_result, "$.read_cnt")) INTO _read_cnt;  
 
          UPDATE _show_node SET  
            room_count =  _read_cnt
          WHERE entity_id = _nid ;

        UPDATE _show_node SET is_checked = 1 WHERE entity_id = _nid ;
        SELECT NULL , NULL  INTO _read_cnt,_nid;
        SELECT entity_id ,db_name FROM _show_node WHERE is_checked =0  LIMIT 1 INTO _nid, _db_name; 
     END WHILE;


    SELECT  SUM(room_count)  room_count FROM _show_node;

  
END $
DELIMITER ;