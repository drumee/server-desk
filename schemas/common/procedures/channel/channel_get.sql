DELIMITER $

DROP PROCEDURE IF EXISTS `channel_get`$
CREATE PROCEDURE `channel_get`(
  IN _message_id VARCHAR(16)  CHARACTER SET ascii
)
BEGIN
DECLARE _type VARCHAR(16);
 
 SELECT type FROM yp.entity WHERE db_name=DATABASE() INTO _type;
  IF _type = 'hub' THEN
    SELECT *, 
   CASE WHEN JSON_LENGTH(metadata , '$._seen_')  >=  JSON_LENGTH(metadata , '$._delivered_') 
   THEN  1 ELSE 0 END is_seen 
   FROM channel WHERE message_id = _message_id;
  ELSE 
    SELECT * , 1 is_seen  FROM channel ch
    WHERE message_id = _message_id;
  END IF ;
END $

DELIMITER ;

