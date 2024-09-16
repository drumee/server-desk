DELIMITER $
/*

  Status : active 

*/

/*  
   Status : active 
   SP "list_message" is to list the  chat between two drumates      
   SP "channel_list_messages" is to list the  chat with in the team room 
 */
DROP PROCEDURE IF EXISTS `list_message`$
CREATE PROCEDURE `list_message`(
  IN _in JSON
)
BEGIN

  DECLARE _entity_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _page    TINYINT(4);

  DECLARE _entity_db VARCHAR(255);
  DECLARE _msg_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _timestamp int(11) unsigned;
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _flag VARCHAR(255);

  DECLARE _message_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;
  
  DECLARE _ref_sys_id int(11) unsigned default 0 ;
  DECLARE _old_ref_sys_id int(11) unsigned default 0 ;
  DECLARE _max_sys_id  int(11) unsigned   ; 

    SELECT id FROM yp.entity where db_name= DATABASE() INTO _uid;
    SELECT JSON_UNQUOTE(JSON_EXTRACT(_in, "$.entity_id")) INTO _entity_id;
    SELECT JSON_UNQUOTE(JSON_EXTRACT(_in, "$.page")) INTO _page;

    CALL pageToLimits(_page, _offset, _range);

    SELECT ref_sys_id FROM read_channel WHERE entity_id = _entity_id AND  uid = _uid INTO _ref_sys_id;
    
    SELECT c.sys_id  FROM channel c INNER JOIN ( SELECT sys_id  FROM channel WHERE entity_id= _entity_id 
    ORDER BY sys_id DESC  LIMIT  _offset, 1) l ON l.sys_id =c.sys_id INTO _max_sys_id; 
    SELECT message_id FROM channel WHERE sys_id =_max_sys_id INTO _message_id;
    
    CALL acknowledge_message( JSON_MERGE( JSON_OBJECT('message_id',_message_id ) , JSON_OBJECT('entity_id',_entity_id ) ,JSON_OBJECT('uid',_uid ))  );

    SELECT _page as `page`,
        ch.sys_id,
        ch.author_id,
        ch.entity_id,
        ch.message,
        ch.message_id,
        ch.thread_id,
        ch.is_forward, 
        -- ch.attachment,
        get_json_array(ch.attachment, 0) attachment_first,
        JSON_LENGTH(ch.attachment)  attachment_count,
        CASE WHEN LTRIM(RTRIM(ch.attachment))='' OR  ch.attachment IS NULL THEN 0 ELSE 1 END is_attachment, 
        ch.status,
        ch.ctime,
        ch.metadata,
        CASE WHEN _ref_sys_id  <  ch.sys_id THEN 1 ELSE 0 END is_notify,  
        CASE WHEN my_read.ref_sys_id  >=  ch.sys_id THEN 1 ELSE 0 END is_readed,
        CASE WHEN his_read.ref_sys_id  >=  ch.sys_id THEN 1 ELSE 0 END is_seen,
        IFNULL(JSON_VALUE(ch.metadata, "$.message_type"), 'chat') message_type,  
        JSON_VALUE(ch.metadata, "$.call_status") call_status,
        JSON_VALUE(ch.metadata, "$.duration") call_duration      
      FROM 
      (SELECT sys_id FROM channel c  WHERE entity_id = _entity_id 
        ORDER BY c.sys_id  DESC LIMIT _offset, _range) s
      INNER JOIN  channel ch ON ch.sys_id = s.sys_id
      INNER JOIN  read_channel my_read  ON my_read.entity_id =ch.entity_id  AND   my_read.entity_id <> my_read.uid
      INNER JOIN  read_channel his_read  ON his_read.entity_id =ch.entity_id  AND   his_read.entity_id = his_read.uid
      ORDER BY ch.sys_id  DESC;
      
END$  

DELIMITER ;
