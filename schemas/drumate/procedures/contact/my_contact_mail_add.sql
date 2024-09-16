DELIMITER $

DROP PROCEDURE IF EXISTS `my_contact_mail_add`$
CREATE PROCEDURE `my_contact_mail_add`(
  IN  _contact_id VARCHAR(16), 
  IN  _emails  MEDIUMTEXT
)
BEGIN
 
 DECLARE _idx INTEGER DEFAULT 0;
 DECLARE _category VARCHAR(255);
 DECLARE _email VARCHAR(255);
 DECLARE _id VARCHAR(16);
 DECLARE _uid VARCHAR(16);
 DECLARE  _contact_category   VARCHAR(255); 
 DECLARE _is_default INTEGER DEFAULT 0;
 DECLARE _length INTEGER DEFAULT 0;
 

  SELECT category FROM contact WHERE id = _contact_id INTO _contact_category;
  SELECT  JSON_LENGTH(_emails)  INTO _length;

  WHILE _idx < _length  DO 

    SELECT JSON_UNQUOTE(JSON_EXTRACT(_emails, CONCAT("$[", _idx, "]"))) INTO @_node;
    SELECT JSON_UNQUOTE(JSON_EXTRACT(@_node, "$.email")) INTO _email;
    SELECT JSON_UNQUOTE(JSON_EXTRACT(@_node, "$.category")) INTO _category;
    SELECT JSON_UNQUOTE(JSON_EXTRACT(@_node, "$.is_default")) INTO _is_default;
    
    SELECT NULL INTO _uid;
    SELECT  yp.uniqueId() INTO _id ; 

   
    REPLACE  INTO contact_email (id,email,category,ctime,mtime ,contact_id ,is_default )
    SELECT _id,_email,_category, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(),_contact_id,_is_default;
    


    SELECT _idx + 1 INTO _idx;
  END WHILE;

  SELECT * FROM contact_email WHERE id= _contact_id;

END$


DELIMITER ;