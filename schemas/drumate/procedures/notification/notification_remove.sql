DELIMITER $

DROP PROCEDURE IF EXISTS `notification_remove_next`$
CREATE PROCEDURE `notification_remove_next`(
 _entity_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN

DECLARE _nid VARCHAR(16) CHARACTER SET ascii;
DECLARE _area VARCHAR(500) ;
DECLARE _db_name VARCHAR(500);
DECLARE _uid VARCHAR(16) CHARACTER SET ascii;
DECLARE _drumate_id VARCHAR(16) CHARACTER SET ascii;

SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;
SELECT id FROM yp.drumate WHERE id = _entity_id  INTO _drumate_id;

  IF _entity_id IN ('') THEN 
     SELECT NULL INTO  _entity_id;
  END IF;


  DROP TABLE IF EXISTS _my_hubs;
  CREATE TEMPORARY TABLE _my_hubs  AS 
  SELECT  he.id , db_name , he.area
  FROM
  media m
  INNER JOIN yp.entity he ON m.id = he.id
  INNER JOIN yp.hub h ON m.id = h.id
  WHERE category = 'hub' AND extension <> 'dmz' 
  AND  m.id = IFNULL(_entity_id , m.id) ;

  INSERT INTO _my_hubs  
  SELECT id , db_name , area
  FROM yp.entity  WHERE id = _uid 
  AND (_drumate_id IS NOT NULL  OR _entity_id IS NULL );

  ALTER TABLE _my_hubs ADD `is_checked` boolean default 0 ;

  SELECT id, db_name,area FROM _my_hubs 
    WHERE is_checked =0  LIMIT 1 
    INTO _nid, _db_name,_area; 
 
  WHILE _nid IS NOT NULL DO
    IF _area  in ('private', 'share', 'public') THEN
      SET @s = CONCAT(
        "REPLACE INTO ", _db_name ,".read_channel(uid,ref_sys_id,ctime) 
        SELECT ?,IF(max(ref_sys_id) is NULL , 0,max(ref_sys_id) ), UNIX_TIMESTAMP() FROM ", _db_name ,".read_channel  "
          );
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _uid;
      DEALLOCATE PREPARE stmt;

      SET @s = CONCAT(
        "UPDATE ", _db_name ,".media 
        SET metadata=JSON_MERGE(metadata, JSON_OBJECT('_seen_', JSON_OBJECT(?, UNIX_TIMESTAMP())))
        WHERE file_path not REGEXP '^/__(chat|trash)__'  AND 
        IFNULL((is_new(metadata, owner_id, ?)), 0) =1 "
      );
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _uid, _uid;
      DEALLOCATE PREPARE stmt;
    END IF;
    
    IF _area ='personal'  THEN
      SET @s = CONCAT(
        "REPLACE INTO ", _db_name ,".read_channel(entity_id,uid,ref_sys_id,ctime) 
        SELECT entity_id,?,ref_sys_id,UNIX_TIMESTAMP() FROM ", _db_name ,".read_channel
        WHERE uid<>? AND entity_id  = IFNULL(?,entity_id)"
      );
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _uid,_uid,_drumate_id;
      DEALLOCATE PREPARE stmt;
    END IF;

    UPDATE _my_hubs SET is_checked = 1 WHERE id = _nid ;
    SELECT  NULL INTO  _nid;
    SELECT id, db_name,area 
      FROM _my_hubs WHERE is_checked=0  LIMIT 1 
      INTO _nid, _db_name,_area; 
  END WHILE;

  REPLACE INTO yp.read_ticket_channel 
    (`uid`,ticket_id,ref_sys_id,ctime)

  SELECT t.uid, t.ticket_id, MAX(ref_sys_id), UNIX_TIMESTAMP() 
    FROM yp.read_ticket_channel tc 

  INNER JOIN yp.ticket t 
    ON t.ticket_id = tc.ticket_id
    WHERE t.uid =_uid AND 
    (_entity_id IS NULL OR _entity_id=cast(t.ticket_id AS CHAR) OR
    _entity_id = 'Support Ticket' )
  GROUP BY tc.ticket_id; 

  SELECT * FROM _my_hubs;
 
END$
DELIMITER ;

