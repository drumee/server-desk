
DELIMITER $
DROP PROCEDURE IF EXISTS `blacklist_show`$
CREATE PROCEDURE `blacklist_show`(
  _page INT(6)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);

  SELECT d.id AS id, d.email AS email,
  JSON_VALUE(d.profile, '$.firstname') AS firstname,
  JSON_VALUE(d.profile, '$.lastname') AS lastname,
  JSON_VALUE(d.profile, '$.mobile') AS mobile,
  _page AS page
  FROM yp.drumate d JOIN blacklist b ON d.email = b.email
  ORDER BY 
    CONCAT(firstname, ' ', lastname) ASC, 
    email ASC 
  LIMIT _offset, _range;
END$


DELIMITER ;
