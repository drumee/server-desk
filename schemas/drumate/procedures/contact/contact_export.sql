DELIMITER $


-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `contact_export`$
CREATE PROCEDURE `contact_export`(
)
BEGIN

  SELECT GROUP_CONCAT(p.phone , '---', IF(p.category = 'prof', 'WORK', 'HOME') SEPARATOR ':::') AS phone, c.id,
    e.email, is_default, 
    IFNULL(c.firstname, m.firstname) AS firstname, 
    IFNULL(c.lastname, c.lastname) AS lastname,
    c.surname, 
    CONCAT('https://', d.name, '/avatar/', m.id) AS avatar,
    CONCAT(IFNULL(IFNULL(c.firstname, m.firstname), ''), ' ', IFNULL(IFNULL(c.lastname, c.lastname), '')) as fullname,
    GROUP_CONCAT(a.address, '---', IF(a.category = 'prof', 'WORK', 'HOME') SEPARATOR ':::') AS address
  FROM contact c 
  LEFT JOIN contact_address a ON c.id=a.contact_id 
  LEFT JOIN contact_email e ON e.contact_id = c.id 
  LEFT JOIN contact_phone p ON c.id=p.contact_id 
  LEFT JOIN yp.drumate m ON (m.id = c.id OR m.email = e.email)
  LEFT JOIN yp.domain d ON d.id = m.domain_id WHERE e.email IS NOT NULL
  GROUP BY e.email;

END$

DELIMITER ;