DELIMITER $

-- #########################################################
--
-- CCS  SECTION
--
-- #########################################################

-- =========================================================
-- TO BE REVIEWED
-- =========================================================
DROP PROCEDURE IF EXISTS `seo_get`$
CREATE PROCEDURE `seo_get`(
  IN _hashtag VARCHAR(128),
  IN _lang VARCHAR(128)
)
BEGIN
  DECLARE h VARCHAR(128);
  IF _hashtag is NULL OR _hashtag='' THEN
    SELECT home_layout FROM yp.entity WHERE db_name=database() INTO h;
  ELSE
    SELECT _hashtag INTO h;
  END IF;

  SELECT * FROM `seo` WHERE lang=_lang and hashtag=h;
END $



DELIMITER ;
