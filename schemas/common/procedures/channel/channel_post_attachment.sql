DELIMITER $


--  common
DROP PROCEDURE IF EXISTS `channel_post_attachment`$
CREATE PROCEDURE `channel_post_attachment`(
  IN _message_id VARCHAR(16),
  IN _entity_id VARCHAR(16),
  IN _attachment json
)
BEGIN
  DECLARE _sbx_id VARCHAR(16); 

  DECLARE _nid VARCHAR(16); 
  DECLARE _sbx_db_name VARCHAR(255);
  DECLARE _idx_attachment INT(4) DEFAULT 0; 
  DECLARE _node JSON;
  DECLARE _type VARCHAR(16);
  DECLARE _hub_db_name VARCHAR(255);
  DECLARE _uid VARCHAR(255);

    DROP TABLE IF EXISTS _show_node;
    CREATE TEMPORARY TABLE _show_node (uid VARCHAR(16));
    ALTER TABLE _show_node ADD `is_checked` boolean default 0 ;

    SELECT type,db_name FROM yp.entity WHERE id= _entity_id INTO _type,_hub_db_name;

    IF _type = 'hub' THEN
      
      SET @s = CONCAT(" INSERT INTO _show_node (uid) SELECT  d.id FROM ",_hub_db_name , 
       ".permission p 
        INNER JOIN yp.drumate d on p.entity_id=d.id 
        WHERE 
        p.resource_id='*'");
      PREPARE stmt FROM @s;
      EXECUTE stmt ;
      DEALLOCATE PREPARE stmt;      
    ELSE  
       INSERT INTO _show_node (uid) SELECT _entity_id;
    END IF;

    WHILE _idx_attachment < JSON_LENGTH(_attachment) DO 
      SELECT JSON_QUERY(_attachment, CONCAT("$[", _idx_attachment, "]") ) INTO _node;
      SELECT JSON_VALUE(_node, '$.hub_id') INTO _sbx_id;
      SELECT JSON_VALUE(_node, '$.nid') INTO _nid;
      SELECT db_name FROM yp.entity WHERE id=_sbx_id INTO _sbx_db_name;


      UPDATE _show_node SET is_checked = 0;
      SELECT uid FROM _show_node WHERE is_checked =0  LIMIT 1 INTO _uid;
      WHILE _uid IS NOT NULL DO

        SET @s = CONCAT(" CALL ",_sbx_db_name , ".permission_grant(?,?,?,?,?,?)");
        PREPARE stmt FROM @s;
        EXECUTE stmt USING _nid,_uid,0,15,'system','chatpermission';
        DEALLOCATE PREPARE stmt;


        SET @s = CONCAT(" INSERT INTO  ",_sbx_db_name , ".attachment (message_id,hub_id,rid,uid) select ?,?,?,?");
        PREPARE stmt FROM @s;
        EXECUTE stmt USING _message_id,_entity_id,_nid,_uid;
        DEALLOCATE PREPARE stmt;


        UPDATE _show_node SET is_checked = 1 WHERE uid = _uid ;
        SELECT NULL INTO _uid;
        SELECT uid FROM _show_node WHERE is_checked =0  LIMIT 1 INTO _uid;
        
      END WHILE;

      SELECT _idx_attachment + 1 INTO _idx_attachment;
    END WHILE;

END $

DELIMITER ;

