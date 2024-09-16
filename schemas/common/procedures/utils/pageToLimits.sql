DELIMITER $


DROP PROCEDURE IF EXISTS `pageToLimits`$
CREATE PROCEDURE `pageToLimits`(
  IN _page VARCHAR(32),
  OUT _offset BIGINT,
  OUT _range BIGINT
)
BEGIN
  SELECT (_page - 1)*45, 45 INTO _offset,_range;
END $


DELIMITER ;