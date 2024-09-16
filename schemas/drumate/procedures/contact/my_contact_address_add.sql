DELIMITER $

DROP PROCEDURE IF EXISTS `my_contact_address_add`$
CREATE PROCEDURE `my_contact_address_add`(
  IN  _contact_id VARCHAR(16),  
  IN _addresses  MEDIUMTEXT
)
BEGIN
 
 DECLARE _idx INTEGER DEFAULT 0;
 DECLARE _category VARCHAR(255);
 DECLARE _street VARCHAR(255);
 DECLARE _city VARCHAR(255);
 DECLARE _country VARCHAR(255);
 DECLARE _address VARCHAR(255);
 DECLARE _id VARCHAR(16);

  
  WHILE _idx < JSON_LENGTH(_addresses) DO 
    
    SELECT JSON_UNQUOTE(JSON_EXTRACT(_addresses, CONCAT("$[", _idx, "]"))) INTO @_node;
    SELECT JSON_UNQUOTE(JSON_EXTRACT(@_node, "$.street")) INTO _street;
    SELECT JSON_UNQUOTE(JSON_EXTRACT(@_node, "$.city")) INTO _city;
    SELECT JSON_UNQUOTE(JSON_EXTRACT(@_node, "$.country")) INTO _country;
    SELECT JSON_UNQUOTE(JSON_EXTRACT(@_node, "$.category")) INTO _category;

    SET _address ='{}';
    
    IF _street IS NOT NULL THEN 
      SELECT JSON_insert(_address , '$.street' , _street) INTO _address ;
    END IF ;
    IF _city IS NOT NULL THEN  
      SELECT JSON_insert(_address , '$.city' , _city) INTO  _address ; 
    END IF; 
    IF _country IS NOT NULL THEN  
      SELECT JSON_insert(_address , '$.country' , _country) INTO  _address ;  
    END IF ;
    SELECT  yp.uniqueId() INTO _id ; 

    INSERT INTO contact_address (id,address,category,ctime,mtime ,contact_id )
    SELECT _id,_address,_category, UNIX_TIMESTAMP(), UNIX_TIMESTAMP() ,_contact_id ;
    
    SELECT _idx + 1 INTO _idx;
  END WHILE;

  SELECT id, 
   JSON_UNQUOTE(JSON_EXTRACT(address, '$.street')) AS street,
   JSON_UNQUOTE(JSON_EXTRACT(address, '$.city')) AS city,
   JSON_UNQUOTE(JSON_EXTRACT(address, '$.country')) AS country
  FROM contact_address WHERE id= _contact_id;

END$


DELIMITER ;