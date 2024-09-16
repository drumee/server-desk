DELIMITER $

DROP PROCEDURE IF EXISTS `contact_status_get`$
CREATE PROCEDURE `contact_status_get`(
  IN _entity     VARCHAR(500)
)
BEGIN
DECLARE _email VARCHAR(500);
SELECT email FROM yp.drumate WHERE id = _entity OR email = _entity INTO _email;
SELECT * FROM contact WHERE  entity= _entity OR uid = _entity OR entity= _email OR uid =  _email;  

END $


DELIMITER ;