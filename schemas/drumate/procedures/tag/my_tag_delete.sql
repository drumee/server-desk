DELIMITER $


DROP PROCEDURE IF EXISTS `my_tag_delete`$
CREATE PROCEDURE `my_tag_delete`(
  IN  _entity_id VARCHAR(16), 
  IN  _tag_id VARCHAR(16)  
)
BEGIN
 
  IF _tag_id IN ('',  '0') THEN 
   SELECT NULL INTO  _tag_id;
  END IF;
  
  IF _tag_id IS NULL THEN
    DELETE FROM map_tag WHERE id = _entity_id;
  ELSE 
    DELETE FROM map_tag WHERE tag_id =_tag_id AND  id = _entity_id;
  END IF;  

END$


DELIMITER ;
