DELIMITER $

DROP PROCEDURE IF EXISTS `my_contact_phone_add`$
CREATE PROCEDURE `my_contact_phone_add`(
  IN  _contact_id VARCHAR(16),  
  IN _phones  MEDIUMTEXT
)
BEGIN
 
 DECLARE _idx INTEGER DEFAULT 0;
 DECLARE _category VARCHAR(255);
 DECLARE _phone VARCHAR(255);
 DECLARE _id VARCHAR(16);
 DECLARE _areacode VARCHAR(255); 
  
  WHILE _idx < JSON_LENGTH(_phones) DO 
    
    SELECT JSON_UNQUOTE(JSON_EXTRACT(_phones, CONCAT("$[", _idx, "]"))) INTO @_node;
    SELECT JSON_UNQUOTE(JSON_EXTRACT(@_node, "$.phone")) INTO _phone;
    SELECT JSON_UNQUOTE(JSON_EXTRACT(@_node, "$.areacode")) INTO _areacode;
    SELECT JSON_UNQUOTE(JSON_EXTRACT(@_node, "$.category")) INTO _category;
    SELECT  yp.uniqueId() INTO _id ; 
    
    INSERT INTO contact_phone (id,phone,areacode,category,ctime,mtime,contact_id)
    SELECT _id,_phone,_areacode,_category, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(),_contact_id;
    
    SELECT _idx + 1 INTO _idx;
  END WHILE;

  SELECT * FROM contact_phone WHERE id= _contact_id;

END$



DELIMITER ;