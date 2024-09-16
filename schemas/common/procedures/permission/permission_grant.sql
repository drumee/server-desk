
DELIMITER $

DROP PROCEDURE IF EXISTS `permission_grant`$
CREATE PROCEDURE `permission_grant`(
  IN _rid VARCHAR(16),
  IN _uid VARCHAR(16),
  IN _expiry_time INT(11),
  IN _permission TINYINT(4),
  IN _assign_via VARCHAR(50),
  IN _msg mediumtext
)
BEGIN

  DECLARE _ts INT(11) DEFAULT 0;
  DECLARE _tx INT(11) DEFAULT 0;
  DECLARE _owner_count TINYINT(4) DEFAULT 0;

  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT cast(_permission as unsigned) INTO @perm;

  SELECT IF(IFNULL(_expiry_time, 0) = 0, 0,
    UNIX_TIMESTAMP(TIMESTAMPADD(HOUR,_expiry_time, FROM_UNIXTIME(_ts)))) INTO _tx;
  START TRANSACTION;
    REPLACE INTO permission
      VALUES(null, _rid, _uid, _msg, _tx, _ts, _ts, @perm,_assign_via );
      -- ON DUPLICATE KEY UPDATE permission=@perm, utime=_ts, 
      --   expiry_time = _tx , message=_msg, assign_via=_assign_via;

  SELECT count(*) FROM permission WHERE permission=63 AND resource_id='*' INTO _owner_count;
  IF _owner_count < 1 THEN 
    ROLLBACK;
    SELECT 1 failed, "New granting would create orphaned hub" reason;
  ELSE 
    COMMIT;
    SELECT 0 failed, @perm AS permission, sys_id AS id FROM permission 
      WHERE resource_id=_rid AND entity_id=_uid;
  END IF; 
END $

DELIMITER ;

