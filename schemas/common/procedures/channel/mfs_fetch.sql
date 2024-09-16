DELIMITER $


/*------------------------------------------------------
PURPOSE      :  Use to fetch the media info for the given nid (ie attachment id )  
NAME         :  mfs_fetch
INPUT FORMAT :  { "nid":"xxxxx" }
OUTPUT FORMAT:
   { "origin_id":"xxxxx", user_filename: "xxxx", "category" :"xxxxx", extension:"xxxx", mimetype:"xxxx", filesize:"xxxxxx"}
               
*/
DROP PROCEDURE IF EXISTS `mfs_fetch`$
CREATE PROCEDURE `mfs_fetch`(
  IN _in JSON , 
  OUT _out JSON
)
BEGIN
DECLARE _nid VARCHAR(16) ; 
  SELECT get_json_object(_in, "nid") INTO _nid;
  SELECT 
  JSON_MERGE( 
    JSON_OBJECT('origin_id',origin_id),
    JSON_OBJECT('user_filename',user_filename),
    JSON_OBJECT('category',category),
    JSON_OBJECT('extension',extension),
    JSON_OBJECT('mimetype',mimetype),
    JSON_OBJECT('filesize',filesize)    
  )
  FROM media WHERE id= _nid  INTO _out; 

END$ 

DELIMITER ;

