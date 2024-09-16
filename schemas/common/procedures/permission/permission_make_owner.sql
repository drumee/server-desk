
DELIMITER $

DROP PROCEDURE IF EXISTS `permission_make_owner`$
CREATE PROCEDURE `permission_make_owner`(
  IN _key VARCHAR(80)
)
BEGIN
  DECLARE _uid VARCHAR(16) DEFAULT NULL;

  SELECT id FROM yp.entity WHERE id=_key INTO _uid;
  IF _uid IS NOT NULL THEN
    DELETE FROM permission WHERE permission=63 AND resource_id='*';
    CALL permission_grant('*', _uid, 0, 63, 'system', 'permission_make_owner');
  ELSE 
    SELECT 1 failed, CONCAT("Invalid user id : ",  _uid, " from key ", _key) reason;
  END IF;

END $

DELIMITER ;

