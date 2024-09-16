DELIMITER $


DROP PROCEDURE IF EXISTS `my_tag_get`$
CREATE PROCEDURE `my_tag_get`(
  IN  _entity_id VARCHAR(16)
)
BEGIN

  SELECT t.* FROM 
  tag t 
  INNER JOIN map_tag mt ON t.tag_id = mt.tag_id 
  WHERE mt.id =  _entity_id;  
END$

DELIMITER ;
