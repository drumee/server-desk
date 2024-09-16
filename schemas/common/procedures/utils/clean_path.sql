DELIMITER $


-- =========================================================
-- Return clean relative filepath (without heading or trailing /)
-- =========================================================

DROP FUNCTION IF EXISTS `clean_path`$
CREATE FUNCTION `clean_path`(
  _path VARCHAR(1024)
)
RETURNS VARCHAR(1024) DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(1024);
  SELECT REGEXP_REPLACE(_path, '/+', '/') INTO _r;
  SELECT REGEXP_REPLACE(_r, '\<.*\>', '') INTO _r;
  RETURN _r;
END$

DELIMITER ;