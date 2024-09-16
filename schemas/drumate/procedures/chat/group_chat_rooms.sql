DELIMITER $


DROP PROCEDURE IF EXISTS `group_chat_rooms`$
CREATE PROCEDURE `group_chat_rooms`(
  IN _key VARCHAR(500), 
  IN _page INT(6)
)
BEGIN


DECLARE _range bigint;
DECLARE _offset bigint;
DECLARE _finished  INTEGER DEFAULT 0; 
DECLARE _db_name VARCHAR(500);
DECLARE _temp_result JSON;
DECLARE _uid VARCHAR(16);
DECLARE _nid VARCHAR(16);
DECLARE _read_cnt INT ;

DECLARE _attachment  VARCHAR(6000) ;
DECLARE _ctime INT(11) unsigned;
DECLARE _message mediumtext;
DECLARE _temp_nid VARCHAR(16);

  IF _key IN ('', '0') THEN 
    SELECT NULL INTO  _key;
  END IF;


CALL pageToLimits(_page, _offset, _range); 


SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;
 DROP TABLE IF EXISTS _show_node;
 CREATE TEMPORARY TABLE _show_node  AS  
    SELECT 
      m.id ,  
      IFNULL(h.name, user_filename)  group_name, 
      0 room_count,
      db_name    
    FROM 
    media m
    INNER JOIN yp.hub h on  h.id = m.id 
    INNER  JOIN yp.entity he ON m.id = he.id
    WHERE category = 'hub'
    AND ( IFNULL(h.name, user_filename) LIKE CONCAT(TRIM(IFNULL(_key,IFNULL(h.name, user_filename) )), '%') ); -- AND db_name = '5_871bff3e871bff43'
   
    ALTER TABLE _show_node ADD message mediumtext;
    ALTER TABLE _show_node ADD ctime INT(11) unsigned;
    ALTER TABLE _show_node ADD `is_checked` boolean default 0 ;


    SELECT id ,db_name FROM _show_node WHERE is_checked =0  LIMIT 1 INTO _nid, _db_name; 
    WHILE _nid IS NOT NULL DO
 
          SET @st = CONCAT('CALL ', _db_name ,'.room_detail(?,?)');
          PREPARE stamt FROM @st;
          EXECUTE stamt USING  JSON_OBJECT('uid',_uid ) , _temp_result ;
          DEALLOCATE PREPARE stamt; 
        
          SELECT JSON_UNQUOTE(JSON_EXTRACT(_temp_result, "$.read_cnt")) INTO _read_cnt;  
          SELECT JSON_UNQUOTE(JSON_EXTRACT(_temp_result, "$.message")) INTO _message;  
          SELECT JSON_UNQUOTE(JSON_EXTRACT(_temp_result, "$.ctime")) INTO _ctime;  
          UPDATE _show_node SET  
            room_count =  _read_cnt,
            `message` =  _message,  
            ctime =  _ctime  
          WHERE id = _nid ;

        UPDATE _show_node SET is_checked = 1 WHERE id = _nid ;
        SELECT NULL , NULL ,NULL,NULL INTO _read_cnt,_message,_ctime ,_nid;
        SELECT id ,db_name FROM _show_node WHERE is_checked =0  LIMIT 1 INTO _nid, _db_name; 
     END WHILE;



    SELECT  _page as `page`, id,group_name,room_count,message,ctime  FROM  _show_node  
    ORDER BY IFNULL(ctime,0) DESC, id ASC 
    LIMIT _offset, _range;
     
END$


DELIMITER ;
