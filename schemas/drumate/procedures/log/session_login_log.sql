DELIMITER $

DROP PROCEDURE IF EXISTS `session_login_log`$
CREATE PROCEDURE `session_login_log`(
  IN  _option VARCHAR(64),
  IN  _cookie_id VARCHAR(64),
  IN  _metadata JSON
)
BEGIN
  IF (_option = 'in') THEN
    INSERT INTO login_log ( cookie_id, metadata, intime ) 
    SELECT  _cookie_id, _metadata , UNIX_TIMESTAMP();
  ELSE
    INSERT INTO login_log ( cookie_id, metadata, outtime ) 
    SELECT  _cookie_id, _metadata , UNIX_TIMESTAMP();
  END IF;

END$

DELIMITER ;