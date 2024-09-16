-- DELIMITER $


-- ==============================================================
-- desk_home
-- List files + directories under directory identified by node_id
-- owner_id is the id of the hub on which media are stored
-- host_id is the same when media is not a link ( which may be a pointer to another hub)
-- host_id is the id of the hub that actually host the media 
-- ==============================================================


-- DROP PROCEDURE IF EXISTS `desk_home`$ 
-- CREATE PROCEDURE `desk_home`(
--   IN _page TINYINT(4)      /* DEPRECATED ???? ------------ */
-- )
-- BEGIN

--   DECLARE _range bigint;
--   DECLARE _offset bigint;
--   DECLARE _vhost VARCHAR(255);
--   DECLARE _holder_id VARCHAR(16);
--   DECLARE _area VARCHAR(50);
--   DECLARE _home_dir VARCHAR(512);
--   DECLARE _home_id VARCHAR(16);
--   DECLARE _db_name VARCHAR(512);
--   DECLARE _accessibility VARCHAR(16);

--   CALL pageToLimits(_page, _offset, _range);
--   CALL mediaEnv(_vhost, _holder_id, _area, _home_dir, _home_id, _db_name, _accessibility);

--   SELECT
--     media.id  AS nid,
--     parent_id AS pid,
--     parent_id AS parent_id,
--     _holder_id AS holder_id,
--     _home_id AS home_id,
--     IF(media.category='hub', 
--       (SELECT id FROM yp.entity WHERE entity.id=media.id), _holder_id
--     ) AS oid,    
-- --    media.owner_id AS oid,
--     caption,
--     capability,
--     IF(media.category='hub', (
--       SELECT accessibility FROM yp.entity WHERE entity.id=media.id), _accessibility
--     ) AS accessibility,
--     IF(media.category='hub', (
--       SELECT status FROM yp.entity WHERE entity.id=media.id), status
--     ) AS status,
--     media.extension AS ext,
--     media.category AS ftype,
--     media.category AS filetype,
--     media.mimetype,
--     download_count AS view_count,
--     geometry,
--     upload_time AS ctime,
--     publish_time AS ptime,
--     parent_path,
--     IF(parent_path='' or parent_path is NULL , '/', parent_path) AS user_path,
--     IF(media.category='hub', (
--       SELECT `name` FROM yp.hub WHERE hub.id=media.id), user_filename
--     ) AS filename,
--     IF(media.category='hub', (
--       SELECT space FROM yp.entity WHERE entity.id=media.id), filesize
--     ) AS filesize,
--     firstname,
--     lastname,
--     remit,
--     IF(media.category='hub', (
--       SELECT vhost FROM yp.entity WHERE entity.id=media.id), _vhost
--     ) AS vhost,    
--     -- IF(media.category='hub', (
--     --   SELECT id FROM yp.entity WHERE entity.id=media.id), _holder_id
--     -- ) AS host_id,    
--     _page as page,
--     IF(media.category='hub', (
--       SELECT area FROM yp.entity WHERE entity.id=media.id), _area
--     ) AS area,
--     rank,
--     'desk' AS context
--   FROM  media LEFT JOIN (yp.filecap, yp.drumate) ON 
--   media.extension=filecap.extension AND origin_id=yp.drumate.id 
--   WHERE parent_id=_home_id AND status='active'
--   ORDER BY rank ASC, ctime DESC LIMIT _offset, _range;
-- END $


-- DELIMITER ;
