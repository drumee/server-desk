DELIMITER $
DROP FUNCTION IF EXISTS `user_expiry`$
CREATE FUNCTION `user_expiry`(
  _uid VARCHAR(16) CHARACTER SET ascii,
  _rid VARCHAR(16) CHARACTER SET ascii
)
RETURNS INT(11) DETERMINISTIC
BEGIN
  DECLARE _expiry INT(11);
  DECLARE _db_name VARCHAR(60);
  DECLARE _category VARCHAR(60);
  DECLARE _file_path VARCHAR(1024);
  
  SET _expiry = NULL;
  SELECT category FROM media WHERE id=_rid INTO _category;
  SELECT IF(_uid IN ('nobody', 'ffffffffffffffff', '*'), '*', _uid) INTO _uid;
  SELECT expiry_time FROM media LEFT JOIN permission ON 
      resource_id=media.id WHERE entity_id=_uid AND media.id=_rid INTO _expiry;

  IF _expiry IS NULL THEN -- SEARCH FROM WILDCARD ON resource_id
      SELECT expiry_time FROM permission WHERE (entity_id=_uid AND resource_id='*') 
      INTO _expiry;
  END IF;
  IF _expiry IS NULL THEN -- SEARCH IN PARENT 
      SELECT file_path FROM media WHERE id=_rid INTO _file_path;
      SELECT IFNULL(expiry_time, 0) FROM media LEFT JOIN permission ON 
        resource_id=media.id AND entity_id= _uid WHERE  REPLACE(_file_path, '(',')')  REGEXP  REPLACE(user_filename, '(',')')  AND permission 
        IS NOT NULL
        ORDER BY (LENGTH(parent_path)-LENGTH(REPLACE(parent_path, '/', '')))  DESC LIMIT 1 
        INTO _expiry;
  END IF;
  
  SELECT IFNULL(_expiry, 0) INTO _expiry;
  RETURN _expiry;
END$

DELIMITER ;
