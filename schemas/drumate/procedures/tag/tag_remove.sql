DELIMITER $

DROP PROCEDURE IF EXISTS `tag_remove`$
CREATE PROCEDURE `tag_remove`(
    _tag_id VARCHAR(50)   
)
BEGIN
    
    DECLARE _lvl INT(4);

        DROP TABLE IF EXISTS _tag;
        CREATE TEMPORARY TABLE _tag(
            `tag_id` varchar(16) NOT NULL,
            `is_checked` boolean default 0
        );
        INSERT INTO _tag (tag_id) SELECT _tag_id;
        WHILE (IFNULL((SELECT 1 FROM _tag  WHERE  is_checked = 0 LIMIT 1 ),0)  = 1 ) AND IFNULL(_lvl,0) < 1000 DO
            SELECT tag_id  FROM _tag WHERE is_checked = 0 LIMIT 1  INTO _tag_id;
            INSERT INTO _tag (tag_id) SELECT tag_id FROM tag WHERE  parent_tag_id = _tag_id;
            UPDATE _tag SET is_checked =  1 WHERE tag_id =_tag_id; 
            SELECT IFNULL(_lvl,0) + 1 INTO _lvl;
        END WHILE; 

        DELETE FROM map_tag WHERE tag_id IN (SELECT tag_id FROM _tag);
        DELETE FROM tag WHERE tag_id IN (SELECT tag_id FROM _tag);

END$
DELIMITER ;
