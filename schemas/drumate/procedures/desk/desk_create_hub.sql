DELIMITER $


-- =========================================================
-- desk_create_hub
-- hubs are actually pre created by the hubs factory
-- =========================================================

-- DROP PROCEDURE IF EXISTS `desk_create_hub_next`$
DROP PROCEDURE IF EXISTS `desk_create_hub`$
CREATE PROCEDURE `desk_create_hub`(
  IN _args JSON,
  IN _profile JSON
)
BEGIN
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _hub_db VARCHAR(50) CHARACTER SET ascii;
  DECLARE _is_wicket BOOLEAN DEFAULT 0;
  DECLARE _default_privilege TINYINT(4);
  DECLARE _dmail VARCHAR(500);
  DECLARE _userFilename VARCHAR(500);
  DECLARE _domain_id INTEGER;
  DECLARE _domain VARCHAR(500)  CHARACTER SET ascii;
  DECLARE _reason VARCHAR(500);
  DECLARE _icon VARCHAR(500) DEFAULT "/-/images/logo/desk.jpg";
  DECLARE _folders JSON;
  DECLARE _fqdn VARCHAR(1024);  /* Fully Qualified Domain Name*/
  DECLARE _rollback BOOLEAN DEFAULT 0;   
  DECLARE  _serial INT DEFAULT 1;
  DECLARE _hubname VARCHAR(80);
  DECLARE _area VARCHAR(16);
  DECLARE _owner_id  VARCHAR(16);
  DECLARE _description varchar(2000) DEFAULT NULL;
  DECLARE _keywords varchar(2000) DEFAULT NULL;
 
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  BEGIN
    SET _rollback = 1;  
    GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
    @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
    SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
  END;

  -- get domain name
  SELECT IFNULL(JSON_VALUE(_args, "$.area"), "private") INTO _area;
  SELECT JSON_VALUE(_args, "$.owner_id") INTO _owner_id;
  SELECT IFNULL(JSON_VALUE(_args, "$.hubname"), uniqueId()) INTO _hubname;
  SELECT IFNULL(JSON_VALUE(_args, "$.filename"), _hubname) INTO _userFilename;
  SELECT IFNULL(JSON_VALUE(_args, "$.description"), "") INTO _description;
  SELECT IFNULL(JSON_VALUE(_args, "$.keywords"), "") INTO _keywords;
  SELECT IFNULL(JSON_VALUE(_args, "$.domain"), "") INTO _domain;

  SELECT JSON_VALUE(_profile, "$.folders") INTO _folders;
  SELECT JSON_VALUE(_profile, "$.is_wicket") INTO _is_wicket;

  IF JSON_VALUE(_args, "$.domain_id") IS NOT NULL THEN
    SELECT JSON_VALUE(_args, "$.domain_id") INTO _domain_id;
    SELECT id, `name` FROM yp.domain WHERE id=_domain_id 
    INTO _domain_id, _domain;
  ELSE
    SELECT id, `name` FROM yp.domain WHERE `name`=_domain 
      INTO _domain_id, _domain;
  END IF;
  
  IF _domain_id IS NULL OR _domain IS NULL THEN
    SELECT d.id, d.name FROM yp.domain d INNER JOIN yp.entity e ON d.id=e.dom_id 
      WHERE e.db_name = DATABASE() INTO _domain_id, _domain;
  END IF;

  SELECT JSON_REMOVE(_profile, "$.folders") INTO _profile;

  START TRANSACTION;
  -- pick one prebuilt by hubs factory
  CALL yp.pickupEntity('hub', _hub_id, _hub_db);

  SELECT yp.unique_hubname(_hubname, _domain_id) INTO _hubname;
  SELECT yp.unique_hubname(_hubname, 1) INTO _hubname;

  IF yp.main_domain() = _domain THEN
    SELECT CONCAT(_hubname, '.', _domain) INTO _fqdn;
  ELSE
    SELECT CONCAT(_hubname, '-', _domain) INTO _fqdn;
  END IF;
  SELECT REGEXP_REPLACE(_fqdn, "^\\.", '') INTO _fqdn;

  SELECT CASE _area
    WHEN 'public' THEN 3
    WHEN 'dmz' THEN 3
    WHEN 'share' THEN 3
    WHEN 'private' THEN 7 
    ELSE 0 
  END INTO _default_privilege;

  IF _hub_db IS NULL OR _hub_id IS NULL THEN 
    SELECT 1 INTO _rollback;
    SELECT CONCAT("Pool ", _area, " is empty. Considerer runing factory") INTO _reason;
  END IF;

  IF _default_privilege = 0 THEN 
    SELECT 1 INTO _rollback;
    SELECT CONCAT("Area ", _area, " is not allowed") INTO _reason;
  END IF;

  SELECT conf_value FROM yp.sys_conf WHERE conf_key='icon' INTO _icon;
  UPDATE yp.entity SET 
    area=_area, 
    status='active', 
    dom_id =_domain_id,
    icon=_icon,
    settings=json_set(settings, "$.default_privilege", _default_privilege)
  WHERE id=_hub_id;

  INSERT INTO yp.vhost VALUES (null, _fqdn, _hub_id, _domain_id);

  -- SELECT _fqdn, _serial, _hub_id, _hubname;
  SELECT sys_id FROM yp.vhost WHERE fqdn=_fqdn INTO _serial;
  SELECT JSON_SET(_profile, "$.name", _userFilename) INTO _profile;
  INSERT INTO yp.hub (
    `id`, `owner_id`, `origin_id`, 
    `name`, `serial`, `description`, `keywords`,
    `hubname`, `domain_id`, `profile`)
  VALUES (
    _hub_id, _owner_id, _owner_id, 
    _userFilename, _serial, _description, _keywords,
    _hubname, _domain_id, _profile);

  CALL join_hub(_hub_id);
  CALL permission_grant(_hub_id, _owner_id, 0, 63, 'system', '');
  SET @s = CONCAT("CALL `", _hub_db, "`.permission_grant('*', ?, 0, 63, 'system', '')");
  PREPARE stmt FROM @s;
  EXECUTE stmt USING _owner_id;
  DEALLOCATE PREPARE stmt;

  -- Must be unique by owner, Cardinal(0,1)
  IF _is_wicket AND _area = 'dmz' THEN 
    UPDATE IGNORE yp.hub SET serial = 0 WHERE id = _hub_id;
    SET @s = CONCAT("UPDATE media SET status='hidden' WHERE id=", QUOTE(_hub_id));
    PREPARE stmt2 FROM @s;
    EXECUTE stmt2;
    DEALLOCATE PREPARE stmt2;
  END IF; 


  SELECT IF(_area='public', 3, 0) INTO @permission;

  SET @s = CONCAT("CALL `", 
    _hub_db, 
    "`.permission_grant('*', '*', 0, ", @permission, ", 'system', '')"
  );

  PREPARE stmt FROM @s;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
  
  IF _folders IS NOT NULL THEN 
    SET @s = CONCAT("CALL `", _hub_db,"`.mfs_init_folders(?, 0)");
    PREPARE stmt FROM @s;
    EXECUTE stmt USING _folders;
    DEALLOCATE PREPARE stmt;
  END IF;

  SET @s = CONCAT("CALL `", _hub_db,"`.mfs_hub_chat_init();");
  PREPARE stmt FROM @s;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  SET @s = CONCAT("CALL `", _hub_db,"`.mfs_trash_init();");
  PREPARE stmt FROM @s;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;


  SELECT *, 0 as failed, _default_privilege default_privilege 
    FROM yp.entity WHERE db_name=_hub_db;

  IF _rollback THEN
    ROLLBACK;
    SELECT 1 as failed, IFNULL(_reason, @full_error) AS reason;
  ELSE
    COMMIT;
  END IF;
END$


DELIMITER ;
