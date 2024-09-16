DELIMITER $

-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `join_hub`$
CREATE PROCEDURE `join_hub`(
  IN _hid VARCHAR(16)
)
BEGIN
  DECLARE _root_id VARCHAR(16);
  DECLARE _owner_id VARCHAR(16);
  DECLARE _domain_id INTEGER;
  DECLARE _fname VARCHAR(100);
  DECLARE _extension VARCHAR(100);

  SELECT id FROM media WHERE parent_id='0' INTO _root_id;

  SELECT id, dom_id FROM yp.entity WHERE db_name=database() 
    INTO _owner_id, _domain_id;

  SELECT username FROM yp.drumate WHERE id=_owner_id AND domain_id=_domain_id
    INTO _extension;  

  SELECT COALESCE(h.name, JSON_VALUE(h.profile, "$.name"), h.hubname) FROM yp.entity e
    LEFT JOIN yp.hub h USING(id) WHERE id=_hid  INTO _fname;

  SELECT REGEXP_REPLACE(
    unique_filename(_root_id, _fname, ''),
    '(/+)|(\<.*\>)|<+|>+', '-'
  )  INTO _fname;

  SELECT COUNT(*) FROM media WHERE parent_id = _root_id INTO @_count;
  -- DECLARE _rank INT(8);
  -- SELECT count(*) FROM media INTO _rank;
  -- INSERT IGNORE INTO hubs VALUES(null, _hid, _rank);
  REPLACE INTO `media` (
    id, 
    origin_id, 

    file_path, 
    user_filename, 
    parent_id, 
    parent_path,

    extension, 
    mimetype, 
    category,
    isalink,

    filesize, 
    `geometry`, 
    publish_time, 
    upload_time, 

    `status`,
    rank
  ) VALUES (
    _hid, 
    _owner_id, 

    CONCAT('/', _fname),
    _fname,
    _root_id, 
    '/',

    '', 
    'hub', 
    'hub', 
    1,

    0,
    '0x0', 
    UNIX_TIMESTAMP() , 
    UNIX_TIMESTAMP(), 

    'active',
    @_count
  );

  UPDATE media SET metadata=JSON_MERGE(
    IFNULL(metadata, '{}'), JSON_OBJECT('seen', _owner_id)
  )
  WHERE id=_hid;

END $

DELIMITER ;
