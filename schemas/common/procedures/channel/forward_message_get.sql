DELIMITER $

/*------------------------------------------------------
PURPOSE      : To get the collection of  message text and the attachement for the forwarded message[s]  
NAME         : forward_message_get
INPUT FORMAT : {  "hub_id" :"xxxxx" , messages["xxxxxx","xxxxxx"] }
OUTPUT FORMAT: [ 
                 {"hub_id" :"xxxxx", forward_message_id:"xxxx", attachment:["xxxxxx","xxxxxx"] }, 
                 {"hub_id" :"xxxxx", forward_message_id:"xxxx", attachment:["xxxxxx","xxxxxx"] }, 
               ]   
SAMPLE :
call forward_message_get('{"hub_id":"46fb4fc946fb4fce", messages:["7b79ab2e7b79ab44","aae9dec4aae9ded8"]}')               
*/
DROP PROCEDURE IF EXISTS `forward_message_get`$
CREATE PROCEDURE `forward_message_get`(IN _in JSON)
BEGIN
 DECLARE _out JSON;
 DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
 DECLARE _message_id VARCHAR(16) CHARACTER SET ascii;
 DECLARE _hub_db VARCHAR(255);
 DECLARE _messages JSON;
 DECLARE _idx_node INT(4) DEFAULT 0; 
 DECLARE _temp_result JSON;
 DECLARE _new_nodes JSON;
 
    SELECT '[]' INTO _new_nodes ;

    SELECT get_json_object(_in, "hub_id") INTO _hub_id;
    SELECT get_json_object(_in, "messages") INTO _messages;

    SELECT db_name FROM yp.entity WHERE id=_hub_id INTO _hub_db;
    
    WHILE _idx_node < JSON_LENGTH(_messages) DO 
      
      SELECT get_json_array(_messages, _idx_node) INTO _message_id;
      
      SET @st = CONCAT('CALL ', _hub_db ,'.post_forward_message_get(?,?)');
      PREPARE stamt FROM @st;
      EXECUTE stamt USING  JSON_OBJECT('message_id', _message_id  ) , _temp_result ;
      DEALLOCATE PREPARE stamt; 
      
      SELECT JSON_MERGE ( _temp_result, JSON_OBJECT( 'hub_id', _hub_id )) INTO _temp_result ;
      SELECT JSON_ARRAY_INSERT(_new_nodes , '$[0]', _temp_result ) INTO _new_nodes;
      
      SELECT NULL INTO _temp_result ;
      SELECT _idx_node + 1 INTO _idx_node;
    END WHILE;

  SELECT JSON_UNQUOTE(_new_nodes) result;
END$ 

DELIMITER ;

