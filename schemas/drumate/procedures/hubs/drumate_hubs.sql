DELIMITER $

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

DELIMITER ;


