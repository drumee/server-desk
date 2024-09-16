DELIMITER $
-- =======================================================================
--
-- =======================================================================
DROP PROCEDURE IF EXISTS `data_usage`$
CREATE PROCEDURE `data_usage`(
)
BEGIN 
  DECLARE _personal_size FLOAT;
  DECLARE _hubs_size FLOAT;
  DECLARE _hubs_count INT(8) DEFAULT 0;
  DECLARE _uid VARCHAR(16);       

  SELECT id FROM yp.entity WHERE db_name = database() INTO _uid;
  SELECT sum(filesize) FROM media INTO _personal_size;
  SELECT IFNULL(yp.disk_usage(_uid),0) INTO _hubs_size;

  SELECT IFNULL(SUM(du.size),0)
  FROM yp.disk_usage du LEFT JOIN(yp.entity e, yp.hub h) ON hub_id=e.id AND h.id = e.id 
  WHERE h.owner_id=_uid INTO _hubs_size;
  SELECT _hubs_size as hub, _personal_size as personal;

END$

DELIMITER ;
