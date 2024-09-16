DELIMITER $

DROP PROCEDURE IF EXISTS `entity_assign`$
CREATE PROCEDURE `entity_assign`(
    _tag_id VARCHAR(50),
    _entity_id VARCHAR(16),
    _category  VARCHAR(16)
   
)
BEGIN
   
    DECLARE _tag_time int(11) unsigned;
    SELECT UNIX_TIMESTAMP() INTO _tag_time; 
  
    INSERT INTO map_tag(tag_id,id, category,ctime) 
    SELECT _tag_id,_entity_id,_category,_tag_time ON DUPLICATE KEY UPDATE ctime =_tag_time , tag_id=_tag_id;

    SELECT * FROM map_tag WHERE tag_id = _tag_id;

END$

DELIMITER ;
