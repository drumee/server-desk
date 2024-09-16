DELIMITER $



/*------------------------------------------------------
PURPOSE      :   Use to create new media record based in the media info   
NAME         :   mfs_post_chatfile
INPUT FORMAT :  { "origin_id":"xxxxx", user_filename: "xxxx", "category" :"xxxxx", extension:"xxxx", mimetype:"xxxx", filesize:"xxxxxx"}
OUTPUT FORMAT:  id (string)
*/

DROP PROCEDURE IF EXISTS `mfs_post_chatfile`$
CREATE PROCEDURE `mfs_post_chatfile`(
  IN _in JSON , 
  OUT _out JSON
)
BEGIN
  DECLARE _message_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _author_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _origin_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _pid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _file_name VARCHAR(1024);
  DECLARE _category VARCHAR(100) CHARACTER SET ascii;
  DECLARE _mimetype VARCHAR(100) CHARACTER SET ascii;
  DECLARE _geometry VARCHAR(100) CHARACTER SET ascii;
  DECLARE _ext VARCHAR(16) CHARACTER SET ascii ;
  DECLARE _filesize BIGINT UNSIGNED;
  DECLARE _isalink TINYINT(2) UNSIGNED DEFAULT 0;

  SELECT JSON_VALUE(_attributes, "$.message_id") INTO _message_id;
  SELECT JSON_VALUE(_attributes, "$.author_id") INTO _author_id;
  SELECT JSON_VALUE(_attributes, "$.origin_id") INTO _origin_id;
  SELECT JSON_VALUE(_attributes, "$.user_filename") INTO _file_name;
  SELECT JSON_VALUE(_attributes, "$.category") INTO _category;
  SELECT JSON_VALUE(_attributes, "$.extension") INTO _ext;
  SELECT JSON_VALUE(_attributes, "$.mimetype") INTO _mimetype;
  SELECT JSON_VALUE(_attributes, "$.geometry") INTO _geometry;
  SELECT JSON_VALUE(_attributes, "$.filesize") INTO _filesize;
  SELECT JSON_VALUE(_attributes, "$.isalink") INTO _isalink;

  CALL mfs_make_dir(node_id_from_path('/__chat__'), JSON_ARRAY(_message_id),0);
  SELECT node_id_from_path( CONCAT('/__chat__/',_message_id)) INTO _message_id;

  SET @args = JSON_OBJECT(
    "owner_id", _author_id,
    "origin_id", _origin_id,
    "filename",_file_name,
    "pid", _message_id,
    "category", _category,
    "ext", _ext,
    "mimetype", _mimetype,
    "filesize", _filesize,
    "geometry", _geometry,
    "isalink", 1
  );

  CALL mfs_create_node(@args, JSON_OBJECT(), _out);

END $

DELIMITER ;

