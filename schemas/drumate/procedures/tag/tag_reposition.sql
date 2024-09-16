DELIMITER $


DROP PROCEDURE IF EXISTS `tag_reposition`$
CREATE PROCEDURE `tag_reposition`(
  IN _tags MEDIUMTEXT
)
BEGIN
  DECLARE _i INTEGER DEFAULT 0;
  DROP TABLE IF EXISTS __tmp_position;
  CREATE TEMPORARY TABLE __tmp_position(
    `position` INTEGER,
    `id` varchar(16) DEFAULT NULL
  ); 

  WHILE _i < JSON_LENGTH(_tags) DO 
    INSERT INTO __tmp_position 
      SELECT _i, JSON_UNQUOTE(JSON_EXTRACT(_tags, CONCAT("$[", _i, "]")));
    SELECT _i + 1 INTO _i;
  END WHILE;
  UPDATE tag m INNER JOIN __tmp_position t ON m.tag_id=t.id SET m.position = t.position ;
  SELECT * FROM __tmp_position;
END $


DELIMITER ;
