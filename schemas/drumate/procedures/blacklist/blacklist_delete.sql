DELIMITER $
DROP PROCEDURE IF EXISTS `blacklist_delete`$
CREATE PROCEDURE `blacklist_delete`(
  IN _emails    MEDIUMTEXT
)
BEGIN
  DECLARE _i INTEGER DEFAULT 0;
  WHILE _i < JSON_LENGTH(_emails) DO 
    DELETE FROM blacklist 
      WHERE email = JSON_VALUE(_emails, CONCAT("$[", _i, "]"));
    SELECT _i + 1 INTO _i;
  END WHILE;
END$

DELIMITER ;
