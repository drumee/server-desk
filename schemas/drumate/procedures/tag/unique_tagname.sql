DELIMITER $

DROP FUNCTION IF EXISTS `unique_tagname`$
CREATE FUNCTION `unique_tagname`(
  _tag_name VARCHAR(255),
  _chk_tag_id VARCHAR(50)
)
RETURNS VARCHAR(1024) DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(1024);
  DECLARE _count INT(8) DEFAULT 0;
  DECLARE _depth INT(4) DEFAULT 0;

  IF _chk_tag_id IN ('',  '0') THEN 
   SELECT NULL INTO  _chk_tag_id;
  END IF;

  SELECT count(*) FROM tag WHERE name = _tag_name   AND tag_id <> IFNULL(_chk_tag_id,'xxxxxx')
  INTO _count;
 
  IF _count = 0 THEN 
    SELECT _tag_name INTO _r;
  ELSE 
    WHILE _depth  < 1000 AND _count > 0 DO 
      SELECT _depth + 1 INTO _depth;
      SELECT CONCAT(_tag_name, " (", _depth, ")") INTO _r;
      SELECT count(*) FROM tag WHERE name = _r  AND tag_id <> IFNULL(_chk_tag_id,'xxxxxx')
      INTO _count;
    END WHILE;  
  END IF;   
  RETURN _r;
END$


DELIMITER ;
