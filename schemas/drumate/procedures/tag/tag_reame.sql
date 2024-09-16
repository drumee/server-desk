DELIMITER $



DROP PROCEDURE IF EXISTS `tag_rename`$
CREATE PROCEDURE `tag_rename`(
    _tag_id VARCHAR(50),
    _name VARCHAR(255)   
)
BEGIN
    
	SELECT unique_tagname(_name,_tag_id) INTO _name;
	UPDATE tag SET name = _name WHERE tag_id = _tag_id;
	CAll tag_get (_tag_id,null);

END$

DELIMITER ;
