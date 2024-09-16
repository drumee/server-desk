DELIMITER $
DROP PROCEDURE IF EXISTS `blacklist_add`$
CREATE PROCEDURE `blacklist_add`(
  IN _emails    MEDIUMTEXT
)
BEGIN
  DECLARE _i INTEGER DEFAULT 0;
  WHILE _i < JSON_LENGTH(_emails) DO 
    INSERT IGNORE INTO blacklist VALUES(
      null, 
      JSON_VALUE(_emails, CONCAT("$[", _i, "]")), 
      UNIX_TIMESTAMP()
    );
    SELECT _i + 1 INTO _i;
  END WHILE;
END$


DELIMITER ;
