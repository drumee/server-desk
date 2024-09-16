DELIMITER $

DROP PROCEDURE IF EXISTS `tag_add`$
CREATE PROCEDURE `tag_add`(
    _name VARCHAR(255),
    _parent_id VARCHAR(16)
)
BEGIN
    
    DECLARE _tag_id VARCHAR(16);
    DECLARE _tag_time int(11) unsigned;
    DECLARE _position int(11) unsigned;
    
    SELECT UNIX_TIMESTAMP() INTO _tag_time; 
    SELECT  yp.uniqueId() INTO _tag_id; 
    SELECT MAX(position) FROM tag INTO _position;

    SELECT IFNULL(_position,0) +1 INTO _position;

    IF _parent_id = '' THEN 
      SELECT NULL INTO _parent_id;
    END IF;  
    
    SELECT unique_tagname(_name,NULL) INTO _name;

    INSERT INTO tag(tag_id,parent_tag_id,name,ctime,position) 
    SELECT _tag_id,_parent_id,_name,_tag_time,_position;

    SELECT * FROM tag WHERE tag_id = _tag_id;

END$

DELIMITER ;
