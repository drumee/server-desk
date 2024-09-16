DELIMITER $
/*

  Status : active 

*/

DROP PROCEDURE IF EXISTS `mfs_chat_init`$
CREATE PROCEDURE `mfs_chat_init`()
BEGIN
  SELECT node_id_from_path('/__chat__') INTO @temp_chat_id;

  IF @temp_chat_id IS NULL THEN 
    SELECT id FROM media WHERE parent_id='0' INTO @home_id;
    CALL mfs_make_dir(@home_id, JSON_ARRAY('__chat__'), 0);
    UPDATE media SET status='hidden' where file_path='/__chat__';
  END IF;
  
  SELECT node_id_from_path('/__chat__') INTO @temp_chat_id;
  SELECT node_id_from_path('/__chat__/__send__') INTO @temp_send_id;
  SELECT node_id_from_path('/__chat__/__receive__') INTO @temp_receive_id;
  SELECT node_id_from_path('/__chat__/__upload__') INTO @temp_upload_id;

  IF @temp_send_id IS NULL THEN 
    CALL mfs_make_dir(@temp_chat_id, JSON_ARRAY('__send__'), 0);
    UPDATE media set status='hidden' where file_path='/__chat__/__send__';
  END IF;
  
  IF @temp_receive_id IS NULL THEN 
    CALL mfs_make_dir(@temp_chat_id, JSON_ARRAY("__receive__"), 0);
    UPDATE media set status='hidden' where file_path='/__chat__/__receive__';
  END IF;

  IF @temp_upload_id IS NULL THEN 
    CALL mfs_make_dir(@temp_chat_id, JSON_ARRAY("__upload__"), 0);
    UPDATE media set status='hidden' where file_path='/__chat__/__upload__';
  END IF;

END$

DELIMITER ;