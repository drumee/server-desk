DELIMITER $


DROP PROCEDURE IF EXISTS `mfs_attachment_remove`$
CREATE PROCEDURE `mfs_attachment_remove`(
  IN _nid VARCHAR(16) 
)
BEGIN
  SELECT * FROM media WHERE file_path  REGEXP '^/__chat__' AND  id = _nid; 
  DELETE FROM media WHERE file_path  REGEXP '^/__chat__' AND id = _nid; 
END $



DELIMITER ;

