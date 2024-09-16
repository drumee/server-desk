DELIMITER $

DROP FUNCTION IF EXISTS `unique_filename`$
CREATE FUNCTION `unique_filename`(
  _pid VARCHAR(16),
  _file_name VARCHAR(200),
  _ext VARCHAR(20)
)
RETURNS VARCHAR(2000) DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(2000);
  DECLARE _fname VARCHAR(1024);
  DECLARE _base VARCHAR(1024);
  DECLARE _exten VARCHAR(1024);
  
    SELECT _file_name INTO _fname;
    SELECT _fname INTO _base;
    SELECT '' INTO   _exten;

    IF _fname regexp '\\\([0-9]+\\\)$'  THEN 
      SELECT SUBSTRING_INDEX(_fname, '(', 1) INTO _base;
      SELECT  SUBSTRING_INDEX(_fname, ')', -1) INTO _exten;
    END IF;

    WITH RECURSIVE chk as
      (
        SELECT @de:=0 as n ,  _fname fname,
        (SELECT COUNT(1) FROM media WHERE parent_id = _pid 
          AND user_filename = _fname AND extension=IFNULL(_ext, '')
        ) cnt
      UNION ALL 
        SELECT @de:= n+1 n , CONCAT(_base, "(", n+1, ")", _exten) fname ,
        (SELECT COUNT(1) FROM media WHERE parent_id = _pid 
          AND user_filename = CONCAT(_base, "(", n+1, ")", _exten)
          AND extension=IFNULL(_ext, '') 
        ) cnt
        FROM chk c 
        WHERE n<1000 AND cnt >=1
      )
    SELECT fname FROM chk WHERE n =@de  INTO _r ;
  RETURN _r;
END$

-- BEGIN
--   DECLARE _r VARCHAR(2000);
--   DECLARE _fname VARCHAR(1024);
--   DECLARE _path VARCHAR(2000);
--   DECLARE _parent_path VARCHAR(2000);
--   DECLARE _count INT(8) DEFAULT 0;
--   DECLARE _depth TINYINT(4) DEFAULT 0;

--   -- Sanitizing
--   SELECT REGEXP_REPLACE(_file_name, '^/| +$', '') INTO _fname;
--   SELECT REGEXP_REPLACE(_fname, '/+', '-') INTO _r;

--   -- Get parent path 
--   SELECT CONCAT(parent_path(id), user_filename) FROM media 
--     WHERE id=_pid INTO _parent_path;

--   SELECT REGEXP_REPLACE(_parent_path, '/+', '/') INTO _parent_path;
--   SELECT REGEXP_REPLACE(_parent_path, '\<.*\>|/+$', '') INTO _parent_path;

--   IF(_ext IS NULL OR _ext IN('', 'folder')) THEN
--     SELECT CONCAT(_parent_path, '/', _file_name) INTO _path;
--   ELSE
--     SELECT CONCAT(_parent_path, '/', _file_name, '.', _ext) INTO _path;
--   END IF;

--   SELECT count(*) FROM media WHERE file_path = _path INTO _count;
--   SELECT _count + count(*) FROM media WHERE 
--     parent_id=_pid AND user_filename=_file_name AND extension=_ext INTO _count;

--   IF _count < 1 THEN 
--     SELECT _fname INTO _r;
--   ELSEIF _fname regexp '\\\([0-9]+\\\)$' THEN 
--     WHILE _depth  < 1000 AND _count > 0 DO 
--       SELECT _depth + 1 INTO _depth;
--       SELECT SUBSTRING_INDEX(_fname, '(', 1) INTO @base;
--       SELECT SUBSTRING_INDEX(_fname, ')', -1) INTO @ext;
--       SELECT CONCAT(@base, "(", _depth, ")", @ext) INTO _r;
--       SELECT count(*) FROM media WHERE 
--         parent_id=_pid AND TRIM('/' FROM user_filename) = _r
--         INTO _count;
--     END WHILE;
--   ELSE 
--     SELECT CONCAT(_fname, "(1)") INTO _r;
--     SELECT count(*) FROM media WHERE 
--       parent_id=_pid AND TRIM('/' FROM user_filename) = _r
--       INTO _count;
--     WHILE _depth  < 1000 AND _count > 0 DO 
--       SELECT _depth + 1 INTO _depth;
--       SELECT SUBSTRING_INDEX(_r, '(', 1) INTO @base;
--       SELECT SUBSTRING_INDEX(_r, ')', -1) INTO @ext;
--       SELECT CONCAT(@base, "(", _depth, ")", @ext) INTO _r;
--       SELECT count(*) FROM media WHERE 
--         parent_id=_pid AND TRIM('/' FROM user_filename) = _r
--         INTO _count;
--     END WHILE;
--   END IF;
--   SELECT SUBSTRING_INDEX(_r, '/', -1) INTO _r;
--   RETURN _r;
--   -- -- RETURN CONCAT(_depth, ":", _count, " -- ", _r);
-- END$

DELIMITER ;
