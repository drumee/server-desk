DELIMITER $
DROP FUNCTION IF EXISTS `get_finger_print`$
CREATE FUNCTION `get_finger_print`(
)
RETURNS VARCHAR(80) DETERMINISTIC
BEGIN
  DECLARE _fp VARCHAR(120);
  SELECT `value` FROM params WHERE pkey='password-master' INTO _fp;
  RETURN _fp;
END$

DELIMITER ;
