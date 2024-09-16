-- common tables
create table `language` like template_common.language;
create table `acl` like template_common.acl;
create table `block` like template_common.block;
create table `block_history` like template_common.block_history;
create table `chat` like template_common.chat;
create table `content_tag` like template_common.content_tag;
create table `font` like template_common.font;
create table `font_face` like template_common.font_face;
create table `font_link` like template_common.font_link;
create table `huber` like template_common.huber;  -- SHALL BE DEPRECATED
create table `layout` like template_common.layout; -- SHALL BE DEPRECATED
create table `media` like template_common.media;
create table `media_stats` like template_common.media_stats;
create table `message` like template_common.message;
create table `notification` like template_common.notification;
create table `permission` like template_common.permission;
create table `seo` like template_common.seo;
create table `style` like template_common.style;
create table `action_log` like template_common.action_log;
