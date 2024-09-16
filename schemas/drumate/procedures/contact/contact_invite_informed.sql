DELIMITER $


DROP PROCEDURE IF EXISTS `contact_invite_informed`$
CREATE PROCEDURE `contact_invite_informed`(
  IN _to_drumate_id     VARCHAR(16)
)
BEGIN
  DECLARE _contact_id VARCHAR(16);
  DECLARE _firstname   VARCHAR(255);
  DECLARE _lastname   VARCHAR(255);
    SELECT firstname,lastname FROM yp.drumate WHERE id=_to_drumate_id INTO _firstname,_lastname;

    SELECT id FROM contact WHERE entity = _to_drumate_id AND status = 'informed' INTO _contact_id;    
    CALL contact_block_update(_contact_id);

    UPDATE contact set 
      status = 'active' , uid = entity , 
      category='drumate' ,
      firstname = CASE  WHEN json_value(`metadata`,'$.is_auto') =1  THEN _firstname ELSE firstname END, 
      lastname = CASE  WHEN json_value(`metadata`,'$.is_auto') =1  THEN _lastname ELSE lastname END , 
      metadata = JSON_SET(metadata, "$.is_auto", 0)
    WHERE entity = _to_drumate_id AND status = 'informed';
    SELECT _to_drumate_id drumate_id, status from contact WHERE entity = _to_drumate_id ;

END$


DELIMITER ;