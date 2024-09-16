DELIMITER $

DROP PROCEDURE IF EXISTS `desk_env`$
CREATE PROCEDURE `desk_env`(
)
BEGIN
  DECLARE _vhost VARCHAR(255);
  DECLARE _holder_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _area VARCHAR(50);
  DECLARE _home_dir VARCHAR(512);
  DECLARE _home_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _db_name VARCHAR(512);
  DECLARE _wicket_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _drumate_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _wicket_db VARCHAR(80) DEFAULT NULL;

  SELECT id FROM yp.entity WHERE db_name = database() INTO _drumate_id;
  SELECT h.id FROM 
    yp.hub h INNER JOIN yp.entity e on e.id=h.id
  WHERE h.owner_id=_drumate_id AND `serial`=0
  INTO _wicket_id;
  -- SELECT db_name FROM yp.entity WHERE id=_wicket_id INTO _wicket_db;

  SELECT m.id AS nid,
    m.id AS home_id,
    e.id AS hub_id,
    fqdn AS vhost,
    _wicket_id AS wicket_id,
    e.area   
    FROM media m     
    INNER JOIN yp.entity e on db_name=database()     
    INNER JOIN yp.vhost v on v.id = e.id 
  WHERE parent_id='0';
END $


DELIMITER ;


