DELIMITER $
DROP FUNCTION IF EXISTS `permission_tree`$
CREATE FUNCTION `permission_tree`(
  _id VARCHAR(16)
)
RETURNS VARCHAR(16) DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(16) DEFAULT '*';
  DECLARE _pid VARCHAR(16);
  DECLARE _count INTEGER;
  DECLARE _max INTEGER DEFAULT 0;

  SELECT COUNT(*) FROM permission WHERE resource_id = _id INTO _count;
  IF  _count > 0 THEN
    SELECT _id INTO _r;
    SELECT 'O'  INTO _pid;
  ELSE
    SELECT parent_id FROM media WHERE id = _id INTO _pid;
  END IF;

  WHILE _pid != '0' AND _count = 0 AND _max < 100 DO 
    SELECT _max + 1 INTO _max;
    SET @prev = _pid;
    SELECT parent_id FROM media WHERE id = _pid INTO _pid;
    SELECT count(*) FROM permission WHERE resource_id = _pid INTO _count;
    IF _count > 0 THEN
      SELECT _pid INTO _r;
    END IF;
  END WHILE;
  RETURN _r;
END$
DELIMITER ;