DELIMITER $


-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `my_contact`$
CREATE PROCEDURE `my_contact`(
  IN _key          VARCHAR(100),
  IN _page         TINYINT(11),
  IN _filter_email  JSON,
  IN _status      VARCHAR(100)
)
BEGIN
  DECLARE _range INT(6);
  DECLARE _offset INT(6);
  DECLARE _uid VARCHAR(16);
  DECLARE _domain VARCHAR(512);
  DECLARE _mail  VARCHAR(500);


  DECLARE _length INTEGER DEFAULT 0;
  DECLARE _idx INTEGER DEFAULT 0;
  
  IF _status IN ('') THEN 
     SELECT NULL INTO  _status;
  END IF;

  SELECT  JSON_LENGTH(_filter_email)  INTO _length;
   
  DROP TABLE IF EXISTS  _temp_mail;
  CREATE TEMPORARY TABLE `_temp_mail` (  `email` varchar(5000) NOT NULL); 
  
  WHILE _idx < _length  DO 
     SELECT JSON_UNQUOTE(JSON_EXTRACT(_filter_email, CONCAT("$[", _idx, "]"))) INTO @_node;
     INSERT INTO _temp_mail SELECT  @_node;
     SELECT _idx + 1 INTO _idx;
  END WHILE;



  SELECT id FROM yp.entity WHERE db_name=database() INTO  _uid;
  SELECT email FROM yp.drumate WHERE id = _uid INTO _mail;


  CALL pageToLimits(_page, _offset, _range);

  SELECT 
    _page as `page`,
    1 as is_mycontact,
    coalesce( du.id,de.id, c.entity) as id,
    coalesce (du.email,de.email,ce.email) email,
    c.firstname,
    c.lastname,
    CONCAT(IFNULL(c.firstname, ''), ' ', IFNULL(c.lastname, '')) as fullname,
    IFNULL(c.surname,  IF(coalesce(c.firstname, c.lastname) IS NULL, IFNULL(ce.email,de.email) , CONCAT( IFNULL(c.firstname, '') ,' ',  IFNULL(c.lastname, '')))) as surname,
    CASE WHEN c.uid IS NULL THEN 0 ELSE 1 END   is_drumate ,
    NULL ident,
    CASE WHEN du.id IS NULL THEN 1 ELSE 0 END is_need_email,
    c.status,
    CASE WHEN mycb.sys_id IS NOT NULL THEN 1 ELSE 0 END is_blocked,
    CASE WHEN hiscb.sys_id IS NOT NULL THEN 1 ELSE 0 END is_blocked_me 
    FROM contact c
    LEFT JOIN contact_email ce on ce.contact_id = c.id AND ce.is_default = 1
    LEFT JOIN yp.drumate de ON de.id = c.entity
    LEFT JOIN yp.drumate du ON du.id = c.uid
    LEFT JOIN yp.contact_block mycb ON c.id = mycb.contact_id
    LEFT JOIN yp.drumate dm ON dm.email = ce.email
    LEFT JOIN yp.contact_block hiscb ON (hiscb.owner_id =  c.entity OR hiscb.owner_id = dm.id) 
            AND( hiscb.uid = _uid OR hiscb.entity = _uid OR hiscb.entity = _mail ) 
    WHERE 
      (c.firstname LIKE CONCAT(TRIM(_key), '%') OR 
        c.lastname LIKE CONCAT(TRIM(_key), '%') OR 
        c.surname LIKE CONCAT(TRIM(_key), '%') OR 
        c.source LIKE CONCAT(TRIM(_key), '%') ) AND c.status <> 'received'
        AND  _status = CASE WHEN c.status = 'active' THEN 'active' ELSE 'paper' END 
        AND coalesce (du.email,de.email,ce.email)  not in  (SELECT email FROM _temp_mail)
    ORDER BY surname ASC, c.id ASC  LIMIT _offset, _range;



  -- SELECT 
  --   _page as `page`,
  --   1 as is_mycontact,
  --   '' as domain,
  --   c.id as id,
  --   c.entity email,
  --   c.firstname,
  --   c.lastname,
  --   IFNULL(CONCAT(IFNULL(c.firstname, ''), ' ', IFNULL(c.lastname, '')), c.entity) as fullname
  --   FROM contact c
  --   LEFT JOIN yp.entity e ON e.id = c.uid
  --   WHERE 
  --     (c.firstname LIKE CONCAT(TRIM(_key), '%') OR 
  --     c.lastname LIKE CONCAT(TRIM(_key), '%') OR 
  --     c.entity LIKE CONCAT(TRIM(_key), '%') ) AND c.status <> 'received'
  -- UNION 
  -- SELECT 
  --   _page as `page`,
  --   0 as is_mycontact,
  --   d.name AS domain,
  --   u.id AS id, 
  --   u.email, 
  --   firstname,
  --   lastname,
  --   fullname
  --   FROM yp.drumate u INNER JOIN yp.domain d ON d.id = u.domain_id
  --   WHERE
  --     (u.id != _uid AND allow_search AND 
  --     u.id NOT IN (SELECT entity FROM contact WHERE status <> 'received') AND
  --     d.name = _domain AND 
  --     (
  --       u.firstname LIKE CONCAT(TRIM(_key), '%') OR u.lastname LIKE CONCAT(TRIM(_key), '%')
  --       OR u.email LIKE CONCAT(TRIM(_key), '%') 
  --     )) OR u.email = _key
  -- ORDER BY is_mycontact desc ,fullname ASC LIMIT _offset, _range;
END$

DELIMITER ;
