DELIMITER $
DROP PROCEDURE IF EXISTS `my_tag_add`$
CREATE PROCEDURE `my_tag_add`(
  IN  _entity_id VARCHAR(16), 
  IN  _tags  MEDIUMTEXT
)
BEGIN
 DECLARE _idx INTEGER DEFAULT 0;
 DECLARE _tag_id VARCHAR(16);
 DECLARE _length INTEGER DEFAULT 0;
 DECLARE _tag_time int(11) unsigned;
 DECLARE _category VARCHAR(50) DEFAULT 'contact';
 
 SELECT 'group' FROM media where id = _entity_id INTO  _category;

 SELECT UNIX_TIMESTAMP() INTO _tag_time; 
 
 SELECT  JSON_LENGTH(_tags)  INTO _length;

 WHILE _idx < _length  DO 
   SELECT JSON_UNQUOTE(JSON_EXTRACT(_tags, CONCAT("$[", _idx, "]"))) INTO _tag_id;
    INSERT INTO map_tag(tag_id,id, category,ctime) 
    SELECT _tag_id,_entity_id,_category ,_tag_time ON DUPLICATE KEY UPDATE ctime =_tag_time , tag_id=_tag_id;
    SELECT _idx + 1 INTO _idx;
  END WHILE;
  CALL my_tag_get (_entity_id);

END$

DELIMITER ;
