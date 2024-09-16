DELIMITER $

DROP PROCEDURE IF EXISTS `seo_search`$
CREATE PROCEDURE `seo_search`(
	IN _data  JSON,
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _finished       INTEGER DEFAULT 0; 
  DECLARE _nid VARCHAR(16);   
  DECLARE _uid VARCHAR(16);
  DECLARE _db_name VARCHAR(50);
  DECLARE _sys_id INT;
  DECLARE _temp_sys_id INT;
  DECLARE _db VARCHAR(400);
  DECLARE _i INTEGER DEFAULT 0;

  CALL pageToLimits(_page, _offset, _range);

  DROP TABLE IF EXISTS _found_items;
  CREATE TEMPORARY TABLE _found_items (
    `sys_id`  int NOT NULL AUTO_INCREMENT,
    `word` varchar(300) NOT NULL,
    `nid` varchar(16) CHARACTER SET ascii DEFAULT NULL,
    `hub_id` varchar(16) CHARACTER SET ascii DEFAULT NULL,
    `node` JSON,
    `score` int DEFAULT 0,
    PRIMARY KEY `sys_id`(`sys_id`)  
  ) ENGINE=InnoDB;

  WHILE _i < JSON_LENGTH(_data) DO 
    SELECT read_json_array(_data, _i) INTO @_word;
      INSERT INTO _found_items (`word`, `nid`, `hub_id`, `node`, `score` ) SELECT 
        word,
        o.nid, 
        o.hub_id, 
        o.node,
        IF(word REGEXP CONCAT('^ *', @_word, ' *$'), 100, 0) + 
        IF(word REGEXP CONCAT('^ *', @_word), 10*LENGTH(@_word), 0) AS score 
        FROM seo s INNER JOIN seo_object o ON s.hub_id=o.hub_id AND s.nid=o.nid
        HAVING  score > 25 
        LIMIT _offset, _range;
     SELECT _i + 1 INTO _i;
  END WHILE;

  SELECT * FROM _found_items 
    GROUP BY nid, hub_id
    ORDER BY score
    DESC LIMIT _offset, _range;
END$

DELIMITER ;
