DELIMITER $
DROP PROCEDURE IF EXISTS `mfs_memberload_init`$
CREATE PROCEDURE `mfs_memberload_init`()
BEGIN

 SELECT node_id_from_path('/__memberload__') INTO @temp_chat_id;
 IF @temp_chat_id IS NULL THEN 
    call mfs_make_dir("0", JSON_ARRAY('__memberload__'), 0);
    UPDATE media SET status='hidden' where file_path='/__memberload__.folder';
 END IF;

END$
DELIMITER ;
