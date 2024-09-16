DELIMITER $


--- common
DROP PROCEDURE IF EXISTS `message_id`$
CREATE PROCEDURE `message_id`()
BEGIN
    SELECT  yp.uniqueId() as id;
END$ 



DELIMITER ;

