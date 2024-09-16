DELIMITER $
DROP PROCEDURE IF EXISTS `my_contact_show_next`$
CREATE PROCEDURE `my_contact_show_next`(
  IN _tag_id  VARCHAR(16) CHARACTER SET ascii, 
  IN _sort_by VARCHAR(20),
  IN _order   VARCHAR(20),
  IN _option VARCHAR(20),
  IN _page INT(6)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _lvl INT(4);
  DECLARE _online INT(4) DEFAULT 0;
  DECLARE _uid  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _mail  VARCHAR(500);
  CALL pageToLimits(_page, _offset, _range); 

    
    SELECT id, email FROM yp.entity INNER JOIN yp.drumate USING(id)
      WHERE db_name=DATABASE() INTO _uid, _mail;

    -- SELECT email FROM yp.drumate WHERE id = _uid INTO _mail;

    DROP TABLE IF EXISTS _tag;
      CREATE TEMPORARY TABLE _tag(
        `tag_id` varchar(16) CHARACTER SET ascii NOT NULL,
        `is_checked` boolean default 0
      );

    DROP TABLE IF EXISTS _map_tag;
      CREATE TEMPORARY TABLE _map_tag(
        `tag_id` varchar(16) CHARACTER SET ascii  NOT NULL,
        `id`     varchar(16) CHARACTER SET ascii NOT NULL
      );

   
    IF _tag_id IS  NULL OR (ltrim(_tag_id) = '') THEN
      INSERT INTO _tag (tag_id) SELECT tag_id from  tag ; 
    ELSE 
       
      INSERT INTO _tag (tag_id) SELECT _tag_id;
      WHILE (IFNULL((SELECT 1 FROM _tag  WHERE  is_checked = 0 LIMIT 1 ),0)  = 1 ) AND IFNULL(_lvl,0) < 1000 DO
        SELECT tag_id  FROM _tag WHERE is_checked = 0 LIMIT 1  INTO _tag_id;
        INSERT INTO _tag (tag_id) SELECT tag_id FROM tag WHERE  parent_tag_id = _tag_id;
        UPDATE _tag SET is_checked =  1 WHERE tag_id =_tag_id; 
        SELECT IFNULL(_lvl,0) + 1 INTO _lvl;
      END WHILE; 
    END IF;


    INSERT INTO _map_tag (tag_id,id) SELECT tag_id ,id FROM  map_tag WHERE tag_id in (SELECT tag_id FROM _tag); 

    SELECT 
      _page as `page`, 
      c.id, 
      1 as is_mycontact, 
      'my_contact' as type,
      c.firstname,
      c.lastname, 
      c.comment,
      c.ctime,
      c.entity entity,
      IFNULL(c.surname,  IF(coalesce(c.firstname, c.lastname) IS NULL, IFNULL(ce.email,de.email) , CONCAT( IFNULL(c.firstname, '') ,' ',  IFNULL(c.lastname, '')))) as surname,
      c.surname given_surname,
      IF(socket.uid IS NULL, 0, du.connected) online,
      CASE WHEN  yp.user_exists( c.entity)=1 THEN 1 ELSE 0 END is_drumate ,
      du.username ident, du.username,c.status,
      -- CASE WHEN du.id IS NULL THEN 1 ELSE 0 END is_need_email , 
      1 is_need_email ,
      CASE WHEN mycb.sys_id IS NOT NULL THEN 1 ELSE 0 END is_blocked,
      CASE WHEN hiscb.sys_id IS NOT NULL THEN 1 ELSE 0 END is_blocked_me ,
      CASE WHEN ae.entity_id IS NOT NULL THEN 1 ELSE 0 END is_archived
    FROM
      contact c
      LEFT JOIN contact_email ce ON ce.contact_id = c.id  AND ce.is_default = 1  
      LEFT JOIN yp.drumate de ON de.id = c.entity
      LEFT JOIN yp.drumate du ON du.id = c.uid 
      LEFT JOIN (SELECT distinct uid FROM yp.socket WHERE state='active') socket ON socket.uid = c.entity
      LEFT JOIN yp.entity e ON e.id = c.uid 
      LEFT JOIN yp.contact_block mycb ON c.id = mycb.contact_id
      LEFT JOIN yp.drumate dm ON dm.email = ce.email
      LEFT JOIN yp.contact_block hiscb ON (hiscb.owner_id =  c.entity OR hiscb.owner_id = dm.id) 
            AND( hiscb.uid = _uid OR hiscb.entity = _uid OR hiscb.entity = _mail ) 
      LEFT JOIN archive_entity ae ON ae.entity_id = c.id
    WHERE 
     CASE WHEN _tag_id IS NOT NULL AND  _tag_id <> ''  THEN  c.id IN ( SELECT id FROM _map_tag) ELSE c.id =c.id END 
     AND c.status <> 'received' 
     AND  CASE WHEN  _option = 'sent' THEN c.status
          ELSE (CASE WHEN  entity_id  IS NOT NULL THEN 'archived' ELSE 'active'  END) END = _option       
    ORDER BY 
      CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_order) = 'asc' THEN c.ctime END ASC,
      CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_order) = 'desc' THEN c.ctime END DESC,
      CASE WHEN LCASE(_sort_by) = 'name' and LCASE(_order) = 'asc' THEN
      IFNULL(c.surname,  IF(coalesce(c.firstname, c.lastname) IS NULL, IFNULL(ce.email,de.email) , CONCAT( IFNULL(c.firstname, '') ,' ',  IFNULL(c.lastname, '')))) 
      END ASC,
      CASE WHEN LCASE(_sort_by) = 'name' and LCASE(_order) = 'desc' THEN 
      IFNULL(c.surname,  IF(coalesce(c.firstname, c.lastname) IS NULL, IFNULL(ce.email,de.email) , CONCAT( IFNULL(c.firstname, '') ,' ',  IFNULL(c.lastname, '')))) 
      END DESC ,  c.sys_id ASC
  LIMIT _offset, _range;

END$


DELIMITER ;




