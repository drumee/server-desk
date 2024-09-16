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

DELIMITER ;


