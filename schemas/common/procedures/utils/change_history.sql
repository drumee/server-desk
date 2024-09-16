DELIMITER $

DROP PROCEDURE IF EXISTS `change_history`$
CREATE PROCEDURE `change_history`(
  IN _drumate_id  VARBINARY(16),
  IN _key         VARBINARY(80),
  IN _from        INT(11) UNSIGNED,
  IN _to          INT(11) UNSIGNED,
  IN _page        TINYINT(8)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);
  set @type = '';
  set @num  = 1;
  SELECT 
    bh.serial AS history_id, 
    master_id AS item_id, 
    drumate.email, 
    lang, 
    device, 
    bh.status,
    isonline, 
    meta AS hashtag, 
    bh.ctime, 
    'block' AS `type`, 
    remit, 
    firstname, 
    lastname,
    "saved" AS modification, 
    bh.author_id AS `user_id`, 
    CONCAT('v', bh2.version) AS `version`
  FROM block_history bh JOIN block b ON b.id = bh.master_id
    JOIN (SELECT serial, @num := if(@type = master_id, @num + 1, 1) as `version`,
    @type := master_id as page FROM block_history 
  ORDER BY master_id) AS bh2
    ON bh.serial = bh2.serial
    JOIN yp.drumate ON bh.author_id=drumate.id AND drumate.email LIKE CONCAT(IFNULL(_key,""), "%")
  WHERE ((bh.author_id=drumate.id AND IFNULL(_drumate_id,"") = "")
    OR (bh.author_id = _drumate_id AND IFNULL(_drumate_id,"") <> ""))
    AND CASE WHEN _from > 0 THEN bh.ctime >= _from  ELSE true END
    AND CASE WHEN _to > 0 THEN bh.ctime <= _to  ELSE true END
  UNION ALL
  SELECT 
    m.sys_id AS history_id, 
    m.id AS item_id, 
    drumate.email, '', '', '', 0, user_filename AS hashtag,
    upload_time AS ctime, 
    m.category AS `type`, 
    remit, 
    firstname, 
    lastname,
    "uploaded" AS modification, 
    origin_id AS `user_id`, 
    "v1" AS `version`
    FROM media m JOIN yp.drumate 
      ON origin_id=drumate.id AND drumate.email LIKE CONCAT(IFNULL(_key,""), "%")
    WHERE ((origin_id=drumate.id AND IFNULL(_drumate_id,"") = "")
    OR (origin_id = _drumate_id AND IFNULL(_drumate_id,"") <> ""))
    AND CASE WHEN _from > 0 THEN upload_time >= _from  ELSE true END
    AND CASE WHEN _to > 0 THEN upload_time <= _to  ELSE true END
  ORDER BY ctime DESC LIMIT _offset, _range;
END $

DELIMITER ;