DELIMITER $



DROP PROCEDURE IF EXISTS `channel_get_last`$
CREATE PROCEDURE `channel_get_last`(
  IN _uid VARCHAR(16)  CHARACTER SET ascii
)
BEGIN
  DECLARE _type VARCHAR(16);
  DECLARE _sys_id int(11);
  
    SELECT type FROM yp.entity WHERE db_name=DATABASE() INTO _type;
    IF _type = 'hub' THEN
      SELECT max(ref_sys_id) FROM read_channel INTO _sys_id; 
    ELSE 
      SELECT ref_sys_id FROM read_channel WHERE uid = _uid INTO _sys_id; 
    END IF ;

    SELECT * ,1 is_seen FROM channel ch
    WHERE sys_id = _sys_id;

END $

DELIMITER ;

