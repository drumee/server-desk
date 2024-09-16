DELIMITER $

DROP FUNCTION IF EXISTS `is_new`$
CREATE FUNCTION `is_new`(
  _metadata JSON,
  _oid VARCHAR(16),
  _uid VARCHAR(16)
)
RETURNS BOOLEAN DETERMINISTIC
BEGIN
  RETURN IF(
    NOT json_valid(_metadata) OR 
    _metadata IS NULL OR _metadata IN('{}', '') OR _oid = _uid OR
    JSON_VALUE(_metadata, "$._seen_") IS NULL OR 
    JSON_VALUE(_metadata, CONCAT("$._seen_.", _uid)) IS NOT NULL, 
    0, 1
  );
END$

DELIMITER ;
