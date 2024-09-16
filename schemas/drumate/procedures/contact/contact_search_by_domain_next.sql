DELIMITER $
DROP PROCEDURE IF EXISTS `contact_search_by_domain_next`$
CREATE PROCEDURE `contact_search_by_domain_next`(
  IN _key          VARCHAR(100),
  IN _page         TINYINT(11)
)
BEGIN
  DECLARE _range INT(6);
  DECLARE _offset INT(6);
  DECLARE _uid VARCHAR(16);
  DECLARE _domain VARCHAR(512);
  DECLARE _mail  VARCHAR(500);

  SELECT domain, id FROM yp.entity WHERE db_name=database() INTO _domain, _uid;
  SELECT email FROM yp.drumate WHERE id = _uid INTO _mail;

  CALL pageToLimits(_page, _offset, _range);

  SELECT 
    _page as `page`,
    1 as is_mycontact,
    'my_contact' as type,
    c.id as id,
    IF(coalesce(c.firstname, c.lastname ) IS NULL,IFNULL(ce.email,de.email) , NULL) email,
    IFNULL(c.surname,  IF(coalesce(c.firstname, c.lastname) IS NULL, IFNULL(ce.email,de.email) , CONCAT( IFNULL(c.firstname, '') ,' ',  IFNULL(c.lastname, '')))) as surname,
    c.surname given_surname,
    c.firstname,
    c.lastname,
    CONCAT(IFNULL(c.firstname, ''), ' ', IFNULL(c.lastname, '')) as fullname,
    CASE WHEN c.uid IS NULL THEN 0 ELSE 1 END   is_drumate ,
    NULL ident, null username,
    -- CASE WHEN du.id IS NULL THEN 1 ELSE 0 END is_need_email,
    1 is_need_email,
    c.status ,
    CASE WHEN mycb.sys_id IS NOT NULL THEN 1 ELSE 0 END is_blocked,
    CASE WHEN hiscb.sys_id IS NOT NULL THEN 1 ELSE 0 END is_blocked_me 
    FROM contact c
    LEFT JOIN contact_email ce ON ce.contact_id = c.id  AND ce.is_default = 1  
    LEFT JOIN yp.entity e ON e.id = c.uid
    LEFT JOIN yp.drumate de on de.id=c.entity
    LEFT JOIN yp.drumate du ON du.id = c.uid 
    
    LEFT JOIN yp.contact_block mycb ON c.id = mycb.contact_id
    LEFT JOIN yp.drumate dm ON dm.email = ce.email
    LEFT JOIN yp.contact_block hiscb ON (hiscb.owner_id =  c.entity OR hiscb.owner_id = dm.id) 
            AND( hiscb.uid = _uid OR hiscb.entity = _uid OR hiscb.entity = _mail ) 
    WHERE 
       (c.firstname LIKE CONCAT(TRIM(_key), '%') OR 
        c.lastname LIKE CONCAT(TRIM(_key), '%') OR 
        c.surname LIKE CONCAT(TRIM(_key), '%') OR 
        COALESCE(c.firstname, c.lastname, c.source) LIKE CONCAT(TRIM(_key), '%') ) AND c.status <> 'received'
  -- UNION 
  -- SELECT 
  --   _page as `page`,
  --   0 as is_mycontact,
  --   'same_domain' as type,
  --   NULL AS id, 
  --   CASE WHEN d.email = TRIM(_key) THEN  d.email  ELSE NULL END AS email, 
  --   d.fullname AS surname,
  --   NULL AS given_surname,
  --   d.firstname AS firstname,
  --   d.lastname AS lastname,
  --   d.fullname as fullname,
  --   1   is_drumate , 
  --   CASE WHEN e.ident = TRIM(_key) THEN  e.ident  ELSE NULL END ,
  --   CASE WHEN d.id IS NULL THEN 1 ELSE 0 END is_need_email ,
  --   null status,
  --   CASE WHEN mycb.sys_id IS NOT NULL THEN 1 ELSE 0 END is_blocked,
  --   CASE WHEN hiscb.sys_id IS NOT NULL THEN 1 ELSE 0 END is_blocked_me 
  --   FROM yp.drumate d INNER JOIN yp.entity e using(id)
  --   INNER JOIN yp.privilege md ON md.uid = _uid
  --   INNER JOIN yp.privilege hd ON md.domain_id= hd.domain_id AND hd.uid <> _uid

  --   LEFT JOIN yp.contact_block mycb ON mycb.owner_id = _uid AND 
  --   (mycb.uid =d.id OR mycb.entity =d.id OR mycb.entity = d.email)
  --   LEFT JOIN yp.contact_block hiscb ON (hiscb.owner_id = d.id) 
  --           AND( hiscb.uid = _uid OR hiscb.entity = _uid OR hiscb.entity = _mail ) 
  --   WHERE
  --     d.id != _uid AND
  --     d.id  NOT IN (SELECT entity FROM contact WHERE status <> 'received') AND
  --     e.domain = _domain AND 
  --     ( e.ident =TRIM(_key) OR d.email = TRIM(_key)) 
    
  ORDER BY is_mycontact desc ,fullname ASC LIMIT _offset, _range;
END$

DELIMITER ;