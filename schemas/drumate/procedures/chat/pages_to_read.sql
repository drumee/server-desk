DELIMITER $
DROP PROCEDURE IF EXISTS `pages_to_read`$
CREATE PROCEDURE `pages_to_read`(
  _entity_id  VARCHAR(16),
  _uid VARCHAR(16)
)
BEGIN
  DECLARE _page int(11);
  DECLARE _entity_id VARCHAR(16);  
  DECLARE _uid VARCHAR(16);
  DECLARE _ref_sys_id int(11) unsigned default 0 ;
  DECLARE _pos_cnt int(11) unsigned default 0 ;
  DECLARE _all_cnt int(11) unsigned default 0 ;

  DECLARE _range bigint;
  DECLARE _offset bigint;

  CALL pageToLimits(_page, _offset, _range);  
  
  SELECT ref_sys_id FROM read_channel WHERE entity_id = _entity_id AND  uid = _uid INTO _ref_sys_id;
  SELECT COUNT(sys_id) FROM channel WHERE  sys_id <=_ref_sys_id  INTO _pos_cnt ;
  SELECT COUNT(sys_id) FROM channel  INTO  _all_cnt ;

  SELECT  FLOOR( (IFNULL(_all_cnt,0)  - IFNULL(_pos_cnt,0))  /_range)+1  page;

END$  

DELIMITER ;