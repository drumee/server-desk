DELIMITER $

DROP PROCEDURE IF EXISTS `contact_invite_drumate`$
CREATE PROCEDURE `contact_invite_drumate`(
  IN _to_drumate_id     VARCHAR(16)
)
BEGIN
  DECLARE _to_drumate_db VARCHAR(255);
  DECLARE _frm_drumate_id VARCHAR(16);
  DECLARE _time int(11) unsigned; 

  SELECT UNIX_TIMESTAMP() INTO _time;  
  
  SELECT id FROM yp.entity WHERE db_name=database() INTO _frm_drumate_id;
  SELECT db_name FROM yp.entity WHERE id=_to_drumate_id INTO _to_drumate_db;


  UPDATE contact 
  SET status = 'sent' 
  WHERE temp_uid = _to_drumate_id AND status in ('memory','sent');

  SELECT NULL INTO @_status; 
  SELECT status FROM contact WHERE temp_uid = _to_drumate_id  INTO @_status;

  -- IF @_status IS NULL

  
END$

DELIMITER ;