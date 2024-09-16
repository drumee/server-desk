DELIMITER $
DROP PROCEDURE IF EXISTS `tag_get_next`$
CREATE PROCEDURE `tag_get_next`(
  IN _key  VARCHAR(50),
  IN _search VARCHAR(255), 
  IN _order   VARCHAR(20),
  IN  _page INT(6)
)
BEGIN
  DECLARE _tag_id VARCHAR(16);
    
  DECLARE _range bigint;
  DECLARE _offset bigint;
    -- DECLARE _order   VARCHAR(20) default 'asc';

  CALL pageToLimits(_page, _offset, _range);

  SELECT 
    _page as `page`,
    tag_id,
    parent_tag_id,
    name,
    IFNULL((SELECT  1  FROM tag c WHERE c.parent_tag_id = p.tag_id LIMIT 1),0) is_any_child,
    position,
    IFNULL(( 
      SELECT 
        COUNT(1)
      FROM 
        channel ch 
      INNER JOIN  read_channel rc ON ch.entity_id= rc.entity_id 
      INNER JOIN  contact c ON c.entity = ch.entity_id
      INNER JOIN  map_tag mt ON  c.id = mt.id
      WHERE
        ch.entity_id = ch.author_id AND 
        rc.entity_id <> rc.uid  AND 
        ch.sys_id > rc.ref_sys_id AND 
        mt.tag_id = p.tag_id), 0) room_count   
  FROM 
    tag p
  WHERE parent_tag_id IS NULL
  ORDER BY 
    CASE WHEN  LCASE(_order) = 'asc' THEN position END ASC,
    CASE WHEN  LCASE(_order) = 'desc' THEN position END DESC LIMIT _offset, _range;

END$


DELIMITER ;
