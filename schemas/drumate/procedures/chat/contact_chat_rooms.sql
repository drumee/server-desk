DELIMITER $


-- =========================================================
--
-- =========================================================
DROP PROCEDURE IF EXISTS `contact_chat_rooms`$
CREATE PROCEDURE `contact_chat_rooms`(
  IN _key VARCHAR(500), 
  IN _tag_id  VARCHAR(16), 
  IN _page INT(6)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
    DECLARE _lvl INT(4);
    CALL pageToLimits(_page, _offset, _range); 

   IF _key IN ('', '0') THEN 
    SELECT NULL INTO  _key;
   END IF;

    DROP TABLE IF EXISTS _tag;
      CREATE TEMPORARY TABLE _tag(
        `tag_id` varchar(16) NOT NULL,
        `is_checked` boolean default 0
      );

    DROP TABLE IF EXISTS _map_tag;
      CREATE TEMPORARY TABLE _map_tag(
        `tag_id` varchar(16) NOT NULL,
        `id`     varchar(16) NOT NULL
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
      c.id contact_id, 
      c.uid id,
      IFNULL(c.firstname, d.firstname) firstname,
      IFNULL(c.lastname, d.lastname) lastname,
      tc.message,
      tc.ctime, 
      IFNULL(c.surname, IFNULL(c.firstname, d.firstname)) surname,
      IF(socket.uid IS NULL, 0, 1) `online`,
      IFNULL(( 
        SELECT 
          COUNT(1)
        FROM 
          channel ch 
        INNER JOIN  read_channel rc ON ch.entity_id= rc.entity_id 
        WHERE
          ch.entity_id = ch.author_id AND 
          rc.entity_id <> rc.uid  AND 
          ch.sys_id > rc.ref_sys_id AND 
          ch.entity_id = c.uid), 0) room_count 
    FROM
      contact c
      INNER JOIN yp.entity e ON e.id = c.uid
      INNER JOIN yp.drumate d ON d.id = c.entity
      LEFT JOIN time_channel tc ON tc.entity_id = c.uid
      LEFT JOIN yp.socket ON socket.uid = c.uid  AND socket.state='active'
    WHERE 
     CASE WHEN _tag_id IS NOT NULL AND  _tag_id <> ''  THEN  c.id IN ( SELECT id FROM _map_tag) ELSE c.id =c.id END 
     AND c.status <> 'received' 
     AND 
        (c.firstname LIKE CONCAT(TRIM(IFNULL(_key,c.firstname)), '%') OR 
        c.lastname LIKE CONCAT(TRIM(IFNULL(_key, c.lastname)), '%') OR 
        c.surname LIKE CONCAT(TRIM(IFNULL(_key,c.surname)), '%') OR 
        c.entity LIKE CONCAT(TRIM(IFNULL(_key, c.entity)), '%') )
    ORDER BY 
      IFNULL(tc.ctime,0) DESC,  c.uid  ASC
      LIMIT _offset, _range;

END$


DELIMITER $