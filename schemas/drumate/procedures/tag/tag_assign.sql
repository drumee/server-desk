DELIMITER $



DROP PROCEDURE IF EXISTS `tag_assign`$
CREATE PROCEDURE `tag_assign`(
    _tag_id VARCHAR(50),
    _parent_id VARCHAR(16)
)
BEGIN
	UPDATE tag SET parent_tag_id = _parent_id WHERE tag_id = _tag_id;  
	CALL tag_get_next(_parent_id, '', 'asc');
END$

DELIMITER ;
