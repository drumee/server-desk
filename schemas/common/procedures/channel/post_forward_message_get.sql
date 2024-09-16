DELIMITER $


/*
PURPOSE      : To get the individual message text and the attachement for the forwarded message id. (Post Procedure) 
NAME         : post_forward_message_get
INPUT FORMAT : {  "message_id" :"xxxxx" }
OUTPUT FORMAT: { "forward_message_id":"xxxx", "attachment":["xxxxxx","xxxxxx"] }
*/
DROP PROCEDURE IF EXISTS `post_forward_message_get`$
CREATE PROCEDURE `post_forward_message_get`(IN _in JSON,OUT _out JSON)
BEGIN
  DECLARE _message_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _message JSON;
  DECLARE _attachment  JSON;
 
    SELECT JSON_UNQUOTE(JSON_EXTRACT(_in, "$.message_id")) INTO _message_id;

    SELECT  attachment FROM channel WHERE message_id = _message_id  AND  attachment  <> '[]' AND  attachment IS NOT NULL INTO  _attachment ;

    SELECT  message FROM channel WHERE message_id = _message_id  AND message IS NOT NULL INTO _message  ;

    SELECT  JSON_OBJECT('forward_message_id', message_id) FROM channel WHERE message_id = _message_id  INTO  _out;

    SELECT JSON_MERGE ( _out, JSON_OBJECT( 'message', _message )) INTO _out WHERE _message IS NOT NULL;
    SELECT JSON_MERGE ( _out, JSON_OBJECT( 'attachment', _attachment )) INTO _out WHERE  _attachment IS NOT NULL;

END$ 


DELIMITER ;

