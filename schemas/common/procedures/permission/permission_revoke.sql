
DELIMITER $


-- =======================================================================
--
-- =======================================================================

DROP PROCEDURE IF EXISTS `permission_revoke`$
CREATE PROCEDURE `permission_revoke`(
  IN _rid VARCHAR(16),
  IN _eid VARCHAR(16)
)
BEGIN
  DECLARE _filetype VARCHAR(160) DEFAULT NULL;
  IF _eid != '' THEN
    DELETE FROM permission WHERE resource_id=_rid AND entity_id=_eid;
    IF _eid = 'nobody' or _eid ='*' THEN
      DELETE FROM permission WHERE resource_id=_rid and assign_via= 'link';
    END IF;
    SELECT category FROM media WHERE id=_rid INTO _filetype;
    IF _filetype='schedule' THEN 
      DELETE FROM permission WHERE resource_id=_rid;
      DELETE FROM media WHERE id=_rid;
    END IF;
  ELSE
    DELETE FROM permission WHERE resource_id=_rid;
  END IF;
END $

DELIMITER ;

