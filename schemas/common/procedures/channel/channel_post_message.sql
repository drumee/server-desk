DELIMITER $

DROP PROCEDURE IF EXISTS `channel_post_message_next`$
CREATE PROCEDURE `channel_post_message_next`(
  IN _in JSON ,
  IN _message text
)
BEGIN
 DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;  
 DECLARE _thread_id  VARCHAR(16) CHARACTER SET ascii;
 DECLARE _forward_message_id VARCHAR(16) CHARACTER SET ascii;
 DECLARE _attachment JSON;
 DECLARE _metadata JSON;
 DECLARE _author_id VARCHAR(16) CHARACTER SET ascii;
 DECLARE _entity_id VARCHAR(16) CHARACTER SET ascii;
-- DECLARE _message  TEXT;
 DECLARE _message_id VARCHAR(16) CHARACTER SET ascii;
 DECLARE _ctime int(11) unsigned;
 DECLARE _ref_sys_id int(11) unsigned;
 DECLARE _type VARCHAR(16);
 DECLARE _nid  VARCHAR(16) CHARACTER SET ascii;
 DECLARE _finished  INTEGER DEFAULT 0; 
 DECLARE _ticket_id  INTEGER DEFAULT NULL; 

DECLARE _is_duplicate INTEGER DEFAULT 0; 



-- Error handler
 DECLARE _db_err JSON;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
    GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE,@errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
    SELECT JSON_OBJECT('MSG',@text,'STATE',@sqlstate ) INTO _db_err;
    SELECT JSON_OBJECT( 'SUCCESS' ,0 , 'ERROR' , _db_err) INTO _db_err;
    SELECT _db_err;
  END;


  SELECT type FROM yp.entity WHERE db_name=DATABASE() INTO _type;
 
  SELECT JSON_VALUE(_in, "$.author_id") INTO _author_id;
  SELECT JSON_VALUE(_in, "$.entity_id") INTO _entity_id;
  SELECT JSON_VALUE(_in, "$.ticket_id") INTO _ticket_id; 

  SELECT JSON_VALUE(_in, "$.thread_id") INTO _thread_id; 
  SELECT JSON_VALUE(_in, "$.forward_message_id") INTO _forward_message_id; 
  SELECT JSON_QUERY(_in, "$.attachment") INTO _attachment; 
  SELECT JSON_VALUE(_in, "$.message_id") INTO _message_id;
  SELECT JSON_QUERY(_in, "$.metadata") INTO _metadata; 

  SELECT  1  FROM channel WHERE message_id =_message_id INTO _is_duplicate;

  SELECT UNIX_TIMESTAMP() INTO _ctime; 
  IF _message = '' THEN 
    SELECT NULL INTO _message;
  END IF ;
  
  IF _type = 'hub' THEN
    INSERT INTO channel (message_id,author_id,message,thread_id,ctime,attachment, metadata)
    SELECT _message_id,_author_id,_message,_thread_id,_ctime,_attachment,_metadata
      ON DUPLICATE KEY UPDATE  message_id =_message_id;
  ELSE 
    INSERT INTO channel (message_id,author_id,entity_id,message,thread_id,ctime,attachment,metadata)
    SELECT _message_id,_author_id,_entity_id,_message,_thread_id,_ctime,_attachment,_metadata
     ON DUPLICATE KEY UPDATE  message_id =_message_id;
  END IF ;


  UPDATE channel SET metadata=JSON_MERGE(
    IFNULL(metadata, '{}'), 
    JSON_OBJECT('_seen_', JSON_OBJECT(_author_id, 1)) ,    
    JSON_OBJECT('_delivered_',   JSON_OBJECT(_author_id,_ctime))
  )
  WHERE message_id=_message_id AND _is_duplicate = 0;

  UPDATE channel SET 
  is_forward =1, 
  metadata=JSON_MERGE(
    IFNULL(metadata, '{}'), 
    JSON_OBJECT('forward_message_id',   _forward_message_id),
    JSON_OBJECT('forward_hub_id',   JSON_UNQUOTE(JSON_EXTRACT(_in, "$.hub_id")))
    )
  WHERE message_id=_message_id AND _forward_message_id is NOT NULL AND _is_duplicate = 0;


  IF _entity_id <> _author_id THEN 
    UPDATE channel SET metadata=JSON_MERGE(IFNULL(metadata, '{}'), JSON_OBJECT('_delivered_',   JSON_OBJECT(_entity_id,_ctime)))
    WHERE message_id=_message_id AND _is_duplicate = 0 ;
  END IF;

  SELECT sys_id FROM channel WHERE message_id = _message_id   INTO _ref_sys_id;
  
  IF _type = 'hub' THEN
  
    SET _finished = 0;
      BEGIN
        DECLARE db_cursor CURSOR FOR SELECT  d.id 
          FROM permission p 
          INNER JOIN yp.drumate d on p.entity_id=d.id 
          WHERE 
            p.resource_id='*' AND d.id <> _author_id ;

        DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 
        OPEN db_cursor;
          WHILE NOT _finished DO FETCH db_cursor INTO _nid;
          
            UPDATE channel SET  metadata = JSON_SET(metadata,CONCAT("$._delivered_.", _nid), _ctime)
            WHERE message_id = _message_id  AND _nid IS NOT NULL AND _is_duplicate = 0;

          END WHILE;
        CLOSE db_cursor;
      END; 
 
    INSERT INTO read_channel(uid,ref_sys_id,ctime) 
    SELECT _author_id,_ref_sys_id,_ctime
    ON DUPLICATE KEY UPDATE ref_sys_id= _ref_sys_id , ctime =_ctime;

    SELECT ticket_id FROM map_ticket WHERE message_id = _message_id INTO _ticket_id; 
    IF  _ticket_id IS NOT NULL THEN 

      UPDATE channel c INNER JOIN map_ticket mt ON mt.message_id = c.message_id
      SET  c.metadata = JSON_SET(metadata,CONCAT("$._seen_.", _author_id), UNIX_TIMESTAMP())
      WHERE c.sys_id <= _ref_sys_id   AND mt.ticket_id = _ticket_id AND
      JSON_EXISTS(metadata, CONCAT("$._seen_.", _author_id))= 0 AND _is_duplicate = 0;

      INSERT INTO yp.read_ticket_channel(uid,ticket_id , ref_sys_id,ctime) SELECT _author_id,_ticket_id,_ref_sys_id,UNIX_TIMESTAMP() 
      ON DUPLICATE KEY UPDATE ref_sys_id= _ref_sys_id , ctime =UNIX_TIMESTAMP() ;

      UPDATE yp.ticket SET last_sys_id =  _ref_sys_id WHERE  ticket_id =_ticket_id AND _is_duplicate = 0;
    ELSE 
      UPDATE channel SET  metadata = JSON_SET(metadata,CONCAT("$._seen_.", _author_id), _ctime)
      WHERE sys_id <= _ref_sys_id  AND 
      JSON_EXISTS(metadata, CONCAT("$._seen_.", _author_id))= 0 AND _is_duplicate = 0;  
    END IF;

    SELECT id FROM yp.entity WHERE db_name= DATABASE() INTO _hub_id; 
    SELECT 
      c.sys_id,     
      c.author_id,  
      c.message,   
      c.message_id, 
      c.thread_id,  
      c.is_forward,
      c.attachment, 
      c.status,     
      c.ctime,      
      c.metadata,  
      CASE WHEN JSON_EXISTS(c.metadata, CONCAT("$._seen_.", _author_id))= 1 THEN 1 ELSE 0 END is_readed,
      CASE WHEN JSON_LENGTH(c.metadata , '$._seen_')  >=  JSON_LENGTH(c.metadata , '$._delivered_') 
      THEN  1 ELSE 0 END is_seen,
      IFNULL(read_json_object(c.metadata, "message_type"),'chat')   message_type,
      CASE WHEN  t.message_id IS NOT NULL THEN 1 ELSE 0 END is_ticket,
      _hub_id hub_id,
      read_json_object(c.metadata, "call_status") call_status  
    FROM channel c 
    LEFT JOIN map_ticket mt ON mt.message_id= c.message_id
    LEFT JOIN yp.ticket t ON t.message_id= c.message_id
    WHERE c.message_id = _message_id ;

  ELSE 
    INSERT INTO time_channel(entity_id, ref_sys_id,message,ctime)
    SELECT _entity_id, _ref_sys_id,_message, _ctime ON DUPLICATE KEY UPDATE ref_sys_id= _ref_sys_id, ctime =_ctime ,message=_message;
  
    SELECT 
      sys_id,     
      author_id, 
      entity_id,  
      message,   
      message_id, 
      thread_id,  
      is_forward,
      attachment, 
      status,     
      ctime,      
      metadata,  
      CASE WHEN JSON_EXISTS(metadata, CONCAT("$._seen_.", _author_id))= 1 THEN 1 ELSE 0 END is_readed,
      CASE WHEN JSON_LENGTH(metadata , '$._seen_')  >=  JSON_LENGTH(metadata , '$._delivered_') 
      THEN  1 ELSE 0 END is_seen,
      IFNULL(read_json_object(metadata, "message_type"),'chat')   message_type, 
      0 is_ticket ,
      read_json_object(metadata, "call_status") call_status,
      read_json_object(metadata, "duration") call_duration  
      FROM channel WHERE message_id = _message_id;
  END IF ;
END $

DELIMITER ;

