DELIMITER $

DROP PROCEDURE IF EXISTS `all_read_count`$
CREATE PROCEDURE `all_read_count`()
BEGIN

  DECLARE _db_name VARCHAR(500);
  DECLARE _temp_result JSON;
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _nid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _read_cnt INT ;
  DECLARE _is_archive INT ;  
  DECLARE _contact_chat_cnt INT DEFAULT 0;  
  DECLARE _share_chat_cnt INT DEFAULT 0 ;  
  DECLARE _archive_chat_cnt INT DEFAULT 0 ; 
  DECLARE _support_chat_cnt INT DEFAULT 0 ; 
  DECLARE _head_chat_cnt INT DEFAULT 0 ; 
  DECLARE _archive_head_chat_cnt INT DEFAULT 0 ; 

  DECLARE _domain_id INT;
  DECLARE _is_support INT DEFAULT 0 ;

  SELECT 
    COUNT(1) , COUNT( DISTINCT ch.entity_id )
  FROM 
  channel ch 
  INNER JOIN  read_channel rc ON ch.entity_id= rc.entity_id 
  INNER JOIN  contact c ON c.uid = ch.entity_id
  WHERE
    ch.entity_id = ch.author_id AND 
    rc.entity_id <> rc.uid  AND 
    ch.sys_id > rc.ref_sys_id INTO _contact_chat_cnt,_head_chat_cnt; 


  SELECT 
    COUNT(1) , COUNT( DISTINCT ch.entity_id )
  FROM 
  channel ch 
  INNER JOIN  read_channel rc ON ch.entity_id= rc.entity_id 
  INNER JOIN  contact c ON c.uid = ch.entity_id
  INNER JOIN  archive_entity ae ON c.id = ae.entity_id
  WHERE
    ch.entity_id = ch.author_id AND 
    rc.entity_id <> rc.uid  AND 
    ch.sys_id > rc.ref_sys_id INTO _archive_chat_cnt,_archive_head_chat_cnt ; 

  SELECT _contact_chat_cnt -  _archive_chat_cnt INTO _contact_chat_cnt;
  SELECT _head_chat_cnt -  _archive_head_chat_cnt INTO _head_chat_cnt;

  DROP TABLE IF EXISTS _show_node;
  CREATE TEMPORARY TABLE _show_node  AS  
    SELECT 
      m.id, db_name,  CASE WHEN ae.entity_id = m.id THEN 1 ELSE 0 END is_archive
    FROM 
    media m
    INNER JOIN yp.hub h on  h.id = m.id 
    INNER  JOIN yp.entity he ON m.id = he.id
    LEFT JOIN  archive_entity ae ON m.id = ae.entity_id
    WHERE category = 'hub' ;

  ALTER TABLE _show_node ADD `is_checked` boolean default 0 ;

  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;
  SELECT id, db_name, is_archive FROM _show_node WHERE is_checked =0  LIMIT 1 
    INTO _nid, _db_name,_is_archive; 

  WHILE _nid IS NOT NULL DO

    SET @st = CONCAT('CALL ', _db_name ,'.room_detail(?,?)');
    PREPARE stamt FROM @st;
    EXECUTE stamt USING  JSON_OBJECT('uid',_uid ), _temp_result ;
    DEALLOCATE PREPARE stamt; 
      
    SELECT JSON_VALUE(_temp_result, "$.read_cnt") INTO _read_cnt;  

    IF _is_archive = 0 THEN  
      SELECT IFNULL(_read_cnt, 0) +  _share_chat_cnt INTO _share_chat_cnt; 
      SELECT _head_chat_cnt + 1 INTO _head_chat_cnt  WHERE IFNULL(_read_cnt, 0) > 0; 
                 
    ELSE
      SELECT IFNULL(_read_cnt, 0) +  _archive_chat_cnt INTO _archive_chat_cnt; 
    END IF ; 

    UPDATE _show_node SET is_checked = 1 WHERE id = _nid ;
    SELECT 0, NULL INTO _read_cnt, _nid;
    SELECT id, db_name FROM _show_node WHERE is_checked =0  LIMIT 1 INTO _nid, _db_name; 
  END WHILE;


    SELECT domain_id FROM yp.privilege WHERE uid = _uid INTO _domain_id;
    SELECT 1  FROM yp.sys_conf WHERE  conf_key = 'support_domain' AND conf_value =_domain_id INTO _is_support;

  IF _is_support = 1 THEN
      SELECT 
        COUNT(1)
      FROM 
      yp.ticket t 
      LEFT JOIN yp.read_ticket_channel rtc on rtc.ticket_id = t.ticket_id AND rtc.uid = _uid
      WHERE 
        t.last_sys_id > IFNULL(rtc.ref_sys_id,0)  
      INTO _support_chat_cnt;
  ELSE 
      SELECT 
        COUNT(1)
      FROM 
      yp.ticket t 
      INNER JOIN yp.read_ticket_channel rtc on rtc.ticket_id = t.ticket_id AND rtc.uid = _uid
      WHERE 
        t.last_sys_id > rtc.ref_sys_id AND t.uid = _uid
      INTO _support_chat_cnt;
  END  IF; 
  
    SELECT _share_chat_cnt  share_chat_cnt , _contact_chat_cnt  contact_chat_cnt, _archive_chat_cnt archive_chat_cnt, _support_chat_cnt support_cnt,
          _head_chat_cnt head_chat_cnt, (_share_chat_cnt + _contact_chat_cnt + _archive_chat_cnt +_support_chat_cnt ) total_cnt; 


END $

DELIMITER ;
