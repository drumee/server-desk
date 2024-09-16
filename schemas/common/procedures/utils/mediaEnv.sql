DELIMITER $
DROP PROCEDURE IF EXISTS `mediaEnv`$
CREATE PROCEDURE `mediaEnv`(
  OUT _vhost VARCHAR(255),
  OUT _hub_id VARCHAR(16), 
  OUT _area VARCHAR(25),
  OUT _home_dir VARCHAR(512),
  OUT _home_id VARCHAR(16),
  OUT _db_name VARCHAR(50),
  OUT _accessibility VARCHAR(16)
)
BEGIN
  DECLARE _domain VARCHAR(512);
  
  SELECT d.name FROM yp.domain d INNER JOIN 
    yp.entity e ON e.dom_id=d.id WHERE db_name=database() INTO _domain;
  SELECT IFNULL(fqdn, _domain), e.id, area, home_dir, db_name, accessibility, home_id
  FROM yp.entity e INNER JOIN yp.vhost v ON e.id=v.id WHERE db_name=database() LIMIT 1
  INTO _vhost, _hub_id, _area, _home_dir, _db_name, _accessibility, _home_id;
END $
DELIMITER ;
