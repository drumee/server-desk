DELIMITER $
DROP PROCEDURE IF EXISTS `notification_center_next`$
CREATE PROCEDURE `notification_center_next`()
BEGIN

DECLARE _uid VARCHAR(16) CHARACTER SET ascii;
DECLARE _db_name VARCHAR(500);
DECLARE _nid VARCHAR(16) CHARACTER SET ascii;
DECLARE _domain_id INT;
DECLARE _is_support INT DEFAULT 0 ;
DECLARE _area VARCHAR(500);
DECLARE _wicket_db_name VARCHAR(255);
DECLARE _wicket_id VARCHAR(16);

  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;

  DROP TABLE IF EXISTS _show_node;
  CREATE TEMPORARY TABLE _show_node (
      resource_id  VARCHAR(16) CHARACTER SET ascii,
      entity_id VARCHAR(16) CHARACTER SET ascii,
      hub_id VARCHAR(16) CHARACTER SET ascii,
      ctime  INT(11) ,
      area  VARCHAR(16),
      category VARCHAR(16)

   );

   --  contact invite
   INSERT INTO _show_node
   SELECT 
      ci.id  ,d.id ,_uid , mtime,'personal' ,'contact'
   FROM 
   contact ci 
   INNER JOIN yp.drumate d ON d.id = ci.entity
   WHERE (ci.status="received") OR (ci.status="informed") OR (ci.status="invitation");

   --  individual chat
   INSERT INTO _show_node
   SELECT   
      ch.message_id, ch.author_id , _uid ,ch.ctime , 'personal' , 'chat'   
   FROM    
      channel ch    
   INNER JOIN read_channel rc ON ch.entity_id= rc.entity_id    
   INNER JOIN contact c ON c.uid = ch.entity_id   
   WHERE ch.entity_id = ch.author_id  AND  rc.entity_id <> rc.uid  AND  ch.sys_id > rc.ref_sys_id;

   --  team chat  & hub media
   DROP TABLE IF EXISTS _my_hubs;
   CREATE TEMPORARY TABLE _my_hubs  AS 
   SELECT m.sys_id , he.id , db_name , he.area
   FROM
   media m
   INNER JOIN yp.entity he ON m.id = he.id
   INNER JOIN yp.hub h ON m.id = h.id
   WHERE category = 'hub' AND extension <> 'dmz'  AND m.status <> 'hidden' ;

   ALTER TABLE _my_hubs ADD `is_checked` boolean default 0 ;

   SELECT id, db_name,area FROM _my_hubs WHERE is_checked =0  LIMIT 1 
   INTO _nid, _db_name,_area; 
  
   WHILE _nid IS NOT NULL DO

      SET @sql=  CONCAT(
         "INSERT INTO _show_node
         SELECT c.message_id,'", _nid ,"','",_nid, "' As hub_id ,c.ctime,'", _area, "','teamchat'  FROM ", _db_name ,".channel c WHERE
         c.sys_id > (SELECT  ref_sys_id FROM ", _db_name ,".read_channel WHERE uid ='", _uid ,"')" ) ;
      EXECUTE IMMEDIATE @sql;   

      SET @s = CONCAT(
          " INSERT INTO _show_node
            SELECT id, '",_nid,"', '" , _nid , "', m.upload_time,'", _area ,"','media' FROM ", _db_name ,
          ".media m WHERE file_path not REGEXP '^/__(chat|trash)__'  AND category != 'root' AND 
            IFNULL((is_new(metadata, owner_id, ?)), 0) =1 "
        );
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _uid;
      DEALLOCATE PREPARE stmt;

      UPDATE _my_hubs SET is_checked = 1 WHERE id = _nid ;
      SELECT  NULL INTO  _nid;
      SELECT id, db_name,area FROM _my_hubs WHERE is_checked =0  LIMIT 1 INTO _nid, _db_name,_area; 
   END WHILE;

 
   --  ticket chat
   SELECT domain_id FROM yp.privilege WHERE uid = _uid INTO _domain_id;
   SELECT 1  FROM yp.sys_conf WHERE  conf_key = 'support_domain' 
   AND conf_value =_domain_id INTO _is_support;


   IF _is_support <> 1 THEN 

      SELECT h.id FROM 
      yp.hub h INNER JOIN yp.entity e on e.id=h.id
      WHERE h.owner_id=_uid AND `serial`=0
      INTO _wicket_id;

      SELECT db_name FROM yp.entity WHERE id=_wicket_id INTO _wicket_db_name;

      SET @s = CONCAT("
            INSERT INTO _show_node
            SELECT 
               t.ticket_id  , t.ticket_id , 'Support Ticket', c.ctime ,'personal','ticket'
            FROM 
               yp.ticket t  
            INNER JOIN ", _wicket_db_name ,". map_ticket mt  ON  mt.ticket_id = t.ticket_id 
            INNER JOIN ", _wicket_db_name ,".channel c ON mt.message_id = c.message_id
            LEFT JOIN yp.read_ticket_channel rtc on rtc.ticket_id = mt.ticket_id AND rtc.uid =?
            WHERE t.uid =? AND c.sys_id > IFNULL(rtc.ref_sys_id,0)"

      );
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _uid,_uid;
      DEALLOCATE PREPARE stmt;

   ELSE 

      INSERT INTO _show_node
      SELECT
         t.ticket_id,  t.ticket_id ,'Support Ticket', c.ctime ,'personal','ticket'
      FROM 
         yp.ticket t 
      LEFT JOIN yp.read_ticket_channel rtc on rtc.ticket_id = t.ticket_id AND rtc.uid = _uid
      WHERE 
         t.last_sys_id > IFNULL(rtc.ref_sys_id,0) 
         AND CASE WHEN _is_support = 1 THEN t.uid ELSE _uid END = t.uid;

   END IF;


   SELECT  
      c.id contact_id,
      d.id drumate_id,
      dmu.id guest_id,
      coalesce(c.id,  d.id,dmu.id,  CASE WHEN hub_id = 'Support Ticket' THEN entity_id ELSE hub_id END  ) key_id,
      coalesce(c.firstname, d.lastname, dmu.email) firstname,  
      coalesce(c.lastname, d.lastname, dmu.email) lastname,
      IF ( hub_id <>'Support Ticket' , (coalesce( IFNULL(c.surname,IF(coalesce(c.firstname, c.lastname) IS NULL,coalesce(ce.email,d.email,dmu.email),
      CONCAT( IFNULL(c.firstname, '') ,' ',  IFNULL(c.lastname, '')))) ,  h.name )), entity_id  )surname,
      coalesce(ce.email,d.email,dmu.email) email,
      c.status status,
      b.hub_id hub_id,
      -- m.user_filename,
      b.ctime,
      b.category,
      b.cnt,
      b.area,
            
      (SELECT GROUP_CONCAT(t.tag_id) FROM 
      tag t INNER JOIN map_tag mt ON t.tag_id = mt.tag_id 
      WHERE mt.id = coalesce(c.id,  d.id,dmu.id,  CASE WHEN hub_id = 'Support Ticket' THEN entity_id ELSE hub_id END  )) as tag_id
   FROM 
   (SELECT 
      count(1) cnt ,entity_id,hub_id,category,max(ctime) ctime ,area  
   FROM  _show_node 
   GROUP BY entity_id,hub_id,category,area ) b 
   --  LEFT JOIN yp.hub h on h.id = b.hub_id
   LEFT JOIN yp.hub h ON h.id = b.hub_id   
   LEFT JOIN yp.dmz_user dmu ON b.entity_id = dmu.id
   LEFT JOIN yp.drumate d ON b.entity_id = d.id 
   LEFT JOIN contact c ON  b.entity_id = c.uid  OR  b.entity_id = c.entity
   LEFT JOIN contact_email ce ON ce.contact_id = c.id   AND ce.is_default = 1
   ORDER BY b.ctime DESC;


END$
DELIMITER ;
