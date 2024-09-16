-- MariaDB dump 10.17  Distrib 10.4.8-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: template_common
-- ------------------------------------------------------
-- Server version	10.4.8-MariaDB-1:10.4.8+maria~buster-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `acl`
--

DROP TABLE IF EXISTS `acl`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `acl` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `pkey` varbinary(32) NOT NULL,
  `resource_id` varbinary(16) NOT NULL,
  `resource_type` enum('media','comment','link','layout','all','*') NOT NULL DEFAULT '*',
  `entity_id` varbinary(16) NOT NULL,
  `permission` tinyint(4) unsigned NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `pkey` (`pkey`),
  UNIQUE KEY `pkey_2` (`pkey`),
  KEY `resource_id` (`resource_id`),
  KEY `resource_type` (`resource_type`),
  KEY `entity_id` (`entity_id`),
  KEY `permission` (`permission`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `block`
--

DROP TABLE IF EXISTS `block`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `block` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varbinary(16) NOT NULL,
  `serial` int(11) DEFAULT 0,
  `active` int(11) DEFAULT NULL,
  `author_id` varbinary(16) NOT NULL,
  `hashtag` varchar(500) CHARACTER SET ascii NOT NULL,
  `type` enum('page','block','menu','header','footer') NOT NULL DEFAULT 'block',
  `editor` enum('creator','designer') CHARACTER SET ascii NOT NULL DEFAULT 'creator',
  `status` enum('online','offline','locked','readonly') CHARACTER SET ascii NOT NULL DEFAULT 'online',
  `ctime` int(11) NOT NULL,
  `mtime` int(11) NOT NULL,
  `version` varchar(10) NOT NULL DEFAULT '1.0.0',
  `owner_id` varchar(16) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `hashtag` (`hashtag`) USING BTREE,
  KEY `ctime` (`ctime`),
  KEY `mtime` (`mtime`),
  KEY `version` (`version`),
  KEY `author_id` (`author_id`),
  KEY `editor` (`editor`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `block_history`
--

DROP TABLE IF EXISTS `block_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `block_history` (
  `serial` int(11) NOT NULL DEFAULT 0,
  `author_id` varbinary(16) NOT NULL,
  `master_id` varbinary(16) NOT NULL,
  `lang` varchar(10) CHARACTER SET ascii NOT NULL DEFAULT 'en',
  `device` enum('desktop','tablet','mobile') CHARACTER SET ascii NOT NULL DEFAULT 'desktop',
  `status` enum('draft','history') NOT NULL DEFAULT 'history',
  `isonline` int(4) DEFAULT 0,
  `meta` mediumtext NOT NULL,
  `ctime` int(11) unsigned NOT NULL,
  PRIMARY KEY (`serial`),
  KEY `lang` (`lang`),
  KEY `device` (`device`),
  FULLTEXT KEY `meta` (`meta`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `chat`
--

DROP TABLE IF EXISTS `chat`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `chat` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `chat_id` varchar(16) NOT NULL,
  `parent_chat_id` varchar(16) DEFAULT NULL,
  `bound` enum('out','in') NOT NULL DEFAULT 'out',
  `status` enum('draft','active','trashed') NOT NULL DEFAULT 'active',
  `is_read` tinyint(1) DEFAULT 0,
  `tag_id` varchar(16) DEFAULT NULL,
  `entity_id` varchar(16) NOT NULL,
  `category` enum('group','contact') NOT NULL,
  `message` text DEFAULT NULL,
  `is_forward` tinyint(1) DEFAULT 0,
  `media_id` varchar(16) DEFAULT NULL,
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `chat_id` (`chat_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `content_tag`
--

DROP TABLE IF EXISTS `content_tag`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `content_tag` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) CHARACTER SET ascii NOT NULL,
  `language` varchar(50) NOT NULL,
  `type` enum('block','folder','link','video','image','audio','document','stylesheet','other') NOT NULL,
  `status` enum('online','offline') DEFAULT NULL,
  `name` varchar(500) NOT NULL,
  `description` varchar(1024) NOT NULL,
  `ctime` int(11) NOT NULL,
  `rank` int(8) NOT NULL,
  `group_rank` int(8) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `font`
--

DROP TABLE IF EXISTS `font`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `font` (
  `sys_id` int(11) NOT NULL AUTO_INCREMENT,
  `family` varchar(256) DEFAULT NULL,
  `name` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `variant` varchar(128) DEFAULT NULL,
  `url` varchar(1024) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `status` enum('active','frozen') CHARACTER SET ascii NOT NULL DEFAULT 'active',
  `ctime` int(11) NOT NULL,
  `mtime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `family` (`family`),
  KEY `url` (`url`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `font_face`
--

DROP TABLE IF EXISTS `font_face`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `font_face` (
  `sys_id` int(6) NOT NULL AUTO_INCREMENT,
  `family` varchar(80) NOT NULL,
  `style` varchar(30) NOT NULL,
  `weight` int(2) NOT NULL DEFAULT 400,
  `local1` varchar(80) NOT NULL,
  `local2` varchar(80) NOT NULL,
  `url` varchar(1024) NOT NULL,
  `format` varchar(16) CHARACTER SET ascii NOT NULL,
  `unicode_range` varchar(20) CHARACTER SET ascii NOT NULL,
  `comment` varchar(160) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `family` (`family`),
  KEY `format` (`format`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `font_link`
--

DROP TABLE IF EXISTS `font_link`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `font_link` (
  `sys_id` int(11) NOT NULL AUTO_INCREMENT,
  `family` varchar(256) DEFAULT NULL,
  `name` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `variant` varchar(128) DEFAULT NULL,
  `url` varchar(1024) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `status` enum('active','frozen') CHARACTER SET ascii NOT NULL DEFAULT 'active',
  `ctime` int(11) NOT NULL,
  `mtime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `family` (`family`),
  KEY `url` (`url`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `huber`
--

DROP TABLE IF EXISTS `huber`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `huber` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varbinary(16) NOT NULL,
  `privilege` tinyint(2) NOT NULL DEFAULT 0,
  `expiry_time` int(11) NOT NULL DEFAULT 0,
  `ctime` int(11) NOT NULL,
  `utime` int(11) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  KEY `ctime` (`ctime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `language`
--

DROP TABLE IF EXISTS `language`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `language` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `base` varchar(10) NOT NULL,
  `name` varchar(100) NOT NULL,
  `locale` varchar(100) NOT NULL,
  `state` enum('deleted','active','frozen','replaced') NOT NULL,
  `ctime` int(11) NOT NULL,
  `mtime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `locale` (`locale`),
  KEY `base` (`base`),
  KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `layout`
--

DROP TABLE IF EXISTS `layout`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `layout` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varbinary(16) NOT NULL,
  `author_id` varbinary(16) NOT NULL,
  `hashtag` varchar(500) NOT NULL,
  `type` enum('page','block','menu','header','footer','slider','gallery') NOT NULL DEFAULT 'block',
  `context` enum('page','slider','slideshow','menu','creator','designer') NOT NULL DEFAULT 'creator',
  `editor` enum('designer','creator') CHARACTER SET ascii NOT NULL DEFAULT 'creator',
  `tag` varchar(400) NOT NULL,
  `hash` varchar(500) DEFAULT NULL,
  `device` varchar(2000) DEFAULT NULL,
  `lang` varchar(2000) DEFAULT NULL,
  `author` varchar(80) DEFAULT NULL,
  `comment` varchar(1024) DEFAULT NULL,
  `content` mediumtext DEFAULT NULL,
  `footnote` mediumtext DEFAULT NULL,
  `backup` mediumtext DEFAULT NULL,
  `newbie` mediumtext DEFAULT NULL,
  `expert` mediumtext DEFAULT NULL,
  `status` enum('active','deleted','locked','backup','readonly','draft','exported') DEFAULT NULL,
  `ctime` int(11) NOT NULL,
  `mtime` int(11) NOT NULL,
  `version` varchar(10) NOT NULL DEFAULT '1.0.0',
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `id_2` (`id`),
  UNIQUE KEY `id_3` (`id`),
  UNIQUE KEY `id_4` (`id`),
  UNIQUE KEY `hashtag` (`hashtag`),
  UNIQUE KEY `hash` (`hash`) USING BTREE,
  KEY `author` (`author`),
  KEY `ctime` (`ctime`),
  KEY `mtime` (`mtime`),
  KEY `version` (`version`),
  KEY `ltype` (`context`),
  KEY `tag` (`tag`),
  KEY `author_id` (`author_id`),
  KEY `editor` (`editor`),
  FULLTEXT KEY `content` (`content`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `media`
--

DROP TABLE IF EXISTS `media`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `media` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) DEFAULT NULL,
  `origin_id` varchar(16) DEFAULT NULL,
  `owner_id` varchar(16) DEFAULT '',
  `host_id` varchar(16) DEFAULT '',
  `file_path` varchar(1000) DEFAULT NULL,
  `user_filename` varchar(128) DEFAULT NULL,
  `parent_id` varchar(16) NOT NULL DEFAULT '',
  `parent_path` varchar(1024) NOT NULL,
  `extension` varchar(100) NOT NULL DEFAULT '',
  `mimetype` varchar(100) NOT NULL,
  `category` enum('hub','folder','link','video','image','audio','document','stylesheet','script','vector','web','other') NOT NULL DEFAULT 'other',
  `isalink` tinyint(2) unsigned NOT NULL DEFAULT 0,
  `filesize` int(20) unsigned NOT NULL DEFAULT 0,
  `geometry` varchar(200) NOT NULL DEFAULT '0x0',
  `publish_time` int(11) unsigned NOT NULL DEFAULT 0,
  `upload_time` int(11) unsigned NOT NULL DEFAULT 0,
  `last_download` int(11) unsigned NOT NULL DEFAULT 0,
  `download_count` mediumint(8) unsigned NOT NULL DEFAULT 0,
  `metadata` mediumtext DEFAULT NULL,
  `caption` varchar(1024) DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'active',
  `approval` enum('submitted','verified','validated') NOT NULL,
  `rank` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `filepath` (`file_path`),
  KEY `approval` (`approval`),
  KEY `geometry` (`geometry`),
  KEY `parent_id` (`parent_id`),
  KEY `origin_id` (`origin_id`),
  KEY `user_filename` (`user_filename`),
  KEY `category` (`category`),
  FULLTEXT KEY `content` (`caption`,`user_filename`,`file_path`,`metadata`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `message`
--

DROP TABLE IF EXISTS `message`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `message` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `pkey` varchar(32) DEFAULT NULL,
  `resource_id` varchar(16) NOT NULL,
  `resource_type` enum('media','comment','link','page','all','*') NOT NULL DEFAULT '*',
  `entity_id` varchar(16) NOT NULL,
  `content` text DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `message_pkey` (`pkey`),
  KEY `resource_id` (`resource_id`),
  KEY `resource_type` (`resource_type`),
  KEY `entity_id` (`entity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `notification`
--

DROP TABLE IF EXISTS `notification`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `notification` (
  `sys_id` int(11) NOT NULL AUTO_INCREMENT,
  `id` varbinary(16) NOT NULL,
  `type` enum('chat','message','invitation','event') CHARACTER SET ascii NOT NULL DEFAULT 'message',
  `text` varchar(256) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `permission`
--

DROP TABLE IF EXISTS `permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `permission` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `resource_id` varchar(16) NOT NULL,
  `entity_id` varchar(512) NOT NULL,
  `message` mediumtext DEFAULT NULL,
  `expiry_time` int(11) NOT NULL DEFAULT 0,
  `ctime` int(11) DEFAULT NULL,
  `utime` int(11) DEFAULT NULL,
  `permission` tinyint(4) unsigned NOT NULL,
  `assign_via` enum('system','link','share') DEFAULT 'system',
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `pkey` (`resource_id`,`entity_id`),
  KEY `entity_id` (`entity_id`),
  KEY `permission` (`permission`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `seo`
--

DROP TABLE IF EXISTS `seo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `seo` (
  `sys_id` int(11) NOT NULL AUTO_INCREMENT,
  `key` varchar(25) CHARACTER SET ascii NOT NULL,
  `hashtag` varchar(256) CHARACTER SET ascii NOT NULL,
  `lang` varchar(6) NOT NULL,
  `content` mediumtext NOT NULL,
  `link_data` mediumtext NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `key` (`key`),
  KEY `lang` (`lang`),
  FULLTEXT KEY `content` (`content`),
  FULLTEXT KEY `hashtag` (`hashtag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `style`
--

DROP TABLE IF EXISTS `style`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `style` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `name` varchar(80) NOT NULL DEFAULT 'My Style',
  `class_name` varchar(100) DEFAULT NULL,
  `selector` varchar(255) NOT NULL,
  `declaration` varchar(12000) CHARACTER SET ascii DEFAULT NULL,
  `comment` varchar(255) NOT NULL DEFAULT 'xxx',
  `status` enum('active','frozen') CHARACTER SET ascii NOT NULL DEFAULT 'active',
  PRIMARY KEY (`id`),
  KEY `className` (`selector`),
  KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2019-11-05 20:40:27
