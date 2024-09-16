DELIMITER $
DROP PROCEDURE IF EXISTS `show_hubs`$
CREATE PROCEDURE `show_hubs`( 
)
BEGIN

  SELECT 
    m.id, 
    COALESCE(h.name, m.user_filename) AS `name`,
    e.db_name,
    h.owner_id,
    p.permission AS privilege, 
    home_dir, 
    e.area,
    h.serial
  FROM media m 
  INNER JOIN(permission p, yp.entity e, yp.hub h) 
  ON m.id = p.resource_id AND e.id = m.id AND e.id = h.id
  WHERE m.category='hub' AND e.area <> 'dmz' GROUP BY(m.id);

END $

-- =========================================================
-- Get all communities the user belong to  -- DEPRACTED 
-- Replaced by desk/desk_home
-- =========================================================

DROP PROCEDURE IF EXISTS `drumate_hubs`$
CREATE PROCEDURE `drumate_hubs`( 
  IN _page INT(4)
)
BEGIN
  DECLARE _id VARCHAR(16);
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _vhost VARCHAR(255);
  DECLARE _holder_id VARCHAR(16);
  DECLARE _owner_id VARCHAR(16);
  DECLARE _host_id VARCHAR(16);
  DECLARE _area VARCHAR(50);
  SELECT vhost, entity.id, owner_id, area  
    FROM yp.entity LEFT JOIN yp.hub USING(id) WHERE db_name=DATABASE()
    INTO _vhost, _host_id, _owner_id, _area;

  CALL pageToLimits(_page, _offset, _range);
  SELECT 
    m.id  AS nid,
    parent_id AS pid,
    parent_id AS parent_id,
    _host_id AS holder_id,
    IF(m.category='hub', 
      (SELECT id FROM yp.entity WHERE entity.id=m.id), _owner_id
    ) AS owner_id,    
    IF(m.category='hub', 
      (SELECT id FROM yp.entity WHERE entity.id=m.id), _host_id
    ) AS hub_id,    
    IF(m.category='hub', (
      SELECT vhost FROM yp.entity WHERE entity.id=m.id), _vhost
    ) AS vhost,    
    IF(m.category='hub', (
      SELECT status FROM yp.entity WHERE entity.id=m.id), status
    ) AS status,
    IF(m.category='hub', (
      SELECT `name` FROM yp.hub WHERE hub.id=m.id), user_filename
    ) AS filename,
    IF(m.category='hub', (
      SELECT space FROM yp.entity WHERE entity.id=m.id), filesize
    ) AS filesize,
    IF(m.category='hub', m.extension, _area) AS area,
    _page as page,
    rank
  FROM media m LEFT JOIN (yp.hub) USING(id)
  WHERE status='active'
  ORDER BY rank DESC, filename DESC LIMIT _offset, _range;
  
END $

-- =========================================================
-- Get all communities the user belong to
-- =========================================================

DROP PROCEDURE IF EXISTS `check_hub_access`$
CREATE PROCEDURE `check_hub_access`( 
  IN _hub_id VARCHAR(16),
  IN _drumate_id VARCHAR(16)
)
BEGIN
  DECLARE _hub_db VARCHAR(255);
  DECLARE _script MEDIUMTEXT DEFAULT "";
  SELECT db_name from yp.entity where id = _hub_id INTO _hub_db;
  SET _script = CONCAT("SELECT id, privilege FROM `", _hub_db , "`.huber WHERE id = '", _drumate_id, "'");
  SET @s = _script;
  PREPARE stmt1 FROM @s;
  EXECUTE stmt1;
  DEALLOCATE PREPARE stmt1; 
END $


-- =========================================================
-- 
-- =========================================================

DROP PROCEDURE IF EXISTS `leave_hubs`$
CREATE PROCEDURE `leave_hubs`(
)
BEGIN

  DECLARE _done INT DEFAULT 0;
  DECLARE _hdb VARCHAR(20);
  DECLARE _uid VARCHAR(16);
  DECLARE _hid VARCHAR(16);
  DECLARE _hubs CURSOR FOR SELECT id FROM media WHERE category ='hub';
  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET _done = 1;


  SELECT id FROM yp.entity WHERE db_name=database() INTO _uid;

  OPEN _hubs;

  REPEAT
    FETCH _hubs INTO _hid;
    IF IFNULL(_hid, 0) <> 0 THEN
      SELECT db_name FROM yp.entity WHERE id=_hid INTO _hdb;
      SET @s = CONCAT("DELETE FROM `", _hdb, "`.huber WHERE id=", quote(_uid) );
      PREPARE stmt FROM @s;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
    END IF;
  UNTIL _done END REPEAT;

  CLOSE _hubs;
  DELETE FROM media WHERE category ='hub';
END $



-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `leave_hub`$
CREATE PROCEDURE `leave_hub`(
  IN _hub_id VARCHAR(16)
)
BEGIN
  DECLARE _hub_db VARCHAR(20);
  DECLARE _uid VARCHAR(16);

  SELECT id FROM yp.entity WHERE db_name=database() INTO _uid;
  SELECT db_name FROM yp.entity WHERE id=_hub_id INTO _hub_db;

  DELETE FROM media WHERE id =_hub_id;
  DELETE FROM permission WHERE resource_id =_hub_id;

  IF _hub_db IS NOT NULL THEN 
    -- SET @s1 = CONCAT("DELETE FROM `", _hub_db, "`.share WHERE recipient_id=", quote(_uid) );
    -- PREPARE stmt FROM @s1;
    -- EXECUTE stmt;
    -- DEALLOCATE PREPARE stmt;

    SET @s2 = CONCAT("DELETE FROM `", _hub_db, "`.permission WHERE entity_id=", quote(_uid) );
    PREPARE stmt FROM @s2;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;

END $


-- =========================================================
-- Removes given hub from my hub list.
-- =========================================================
DROP PROCEDURE IF EXISTS `remove_from_my_hub`$
CREATE PROCEDURE `remove_from_my_hub`(
  IN _key  VARCHAR(80)
)
BEGIN
  DECLARE _db VARCHAR(30);
  DECLARE _uid VARCHAR(16);
  SELECT db_name, id FROM yp.entity WHERE id=_key INTO _db, _uid;
  DELETE FROM media WHERE id= _uid AND category ='hub';
  DELETE FROM permission WHERE entity_id= _uid;
END $


-- =========================================================
--
-- =========================================================

DROP PROCEDURE IF EXISTS `add_huber`$
CREATE PROCEDURE `add_huber`(
  IN _uid  VARCHAR(16),
  IN _privilege INT(8),
  IN _expiry_time INT(11)
)
BEGIN
  DECLARE _ts INT(11) DEFAULT 0;
  SELECT UNIX_TIMESTAMP() INTO _ts;
  INSERT into huber values(null, _uid, _privilege, IF(IFNULL(_expiry_time, 0) = 0, 0,
      UNIX_TIMESTAMP(TIMESTAMPADD(HOUR,_expiry_time, FROM_UNIXTIME(_ts)))), _ts, NULL)
      ON DUPLICATE KEY UPDATE privilege=_privilege,
      expiry_time = IF(IFNULL(_expiry_time, 0) = 0, 0,
      UNIX_TIMESTAMP(TIMESTAMPADD(HOUR,_expiry_time, FROM_UNIXTIME(_ts)))),
      utime = _ts;
  SELECT
    entity.id,
    entity.ident,
    entity.area,
    entity.vhost,
    drumate.dmail,
    drumate.email,
    drumate.firstname,
    drumate.lastname,
    drumate.remit,
    CONCAT(firstname, ' ', lastname) as `fullname`,
    privilege
  FROM yp.entity INNER JOIN (yp.drumate, huber) ON (drumate.id=entity.id AND huber.id=entity.id)
    WHERE drumate.id=_uid;

END $

DELIMITER ;


