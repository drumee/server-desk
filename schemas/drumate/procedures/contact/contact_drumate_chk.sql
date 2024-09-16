DELIMITER $

DROP PROCEDURE IF EXISTS `contact_drumate_chk`$
CREATE PROCEDURE `contact_drumate_chk`(
  IN _to_drumate_id  VARCHAR(16),
  IN _bound  VARCHAR(16)
)
BEGIN
    SELECT uid , status  FROM contact WHERE  uid=_to_drumate_id ; 
END$


DELIMITER ;