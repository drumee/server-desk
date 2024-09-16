DELIMITER $
DROP FUNCTION IF EXISTS `count_unread`$
CREATE FUNCTION `count_unread`(
  _cid VARBINARY(16)
)
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE _count INT;

  IF _cid IS NOT NULL THEN
    SELECT COUNT(*) FROM mark WHERE msg_status='new' AND cid=_cid INTO _count;
  ELSE
    SELECT COUNT(*) FROM mark WHERE msg_status='new' INTO _count;
  END IF;

  RETURN _count;
END$

DELIMITER ;
