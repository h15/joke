CREATE TABLE IF NOT EXISTS `joke__jokes` (
  `name` varchar(11) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `state` int(2) NOT NULL,
  `config` tinytext NOT NULL,
  UNIQUE KEY `id` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `joker`.`joke__users` (
    `id` INT( 11 ) UNSIGNED NOT NULL AUTO_INCREMENT ,
    `groups` TINYTEXT NOT NULL ,
    `name` VARCHAR( 32 ) CHARACTER SET utf8 COLLATE utf8_bin NULL ,
    `mail` VARCHAR( 64 ) CHARACTER SET ascii COLLATE ascii_bin NOT NULL ,
    `regdate` INT( 11 ) UNSIGNED NOT NULL ,
    `password` VARCHAR( 32 ) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT '0',
    `ban_reason` INT( 2 ) UNSIGNED NOT NULL DEFAULT '0',
    `ban_time` INT( 11 ) UNSIGNED NOT NULL DEFAULT '0',
    `confirm_key` VARCHAR( 32 ) CHARACTER SET ascii COLLATE ascii_bin NOT NULL ,
    `confirm_time` INT( 11 ) UNSIGNED NOT NULL ,
    PRIMARY KEY ( `id` ) ,
    INDEX ( `id` ) ,
    UNIQUE (
        `name` ,
        `mail`
    )
) ENGINE = MYISAM ;

INSERT INTO `joke__users` (`id`, `groups`, `name`, `mail`, `regdate`, `password`, `ban_reason`, `ban_time`, `confirm_key`, `confirm_time`) VALUES(1, '', 'anonymous', 'anonymous@lorcode.org', 0, '0', 0, 0, '', 0);

CREATE TABLE `joker`.`joke__posts` (
    `id` INT( 11 ) UNSIGNED NOT NULL AUTO_INCREMENT ,
    `thread_id` INT( 11 ) UNSIGNED NOT NULL ,
    `parent_id` INT( 11 ) UNSIGNED NOT NULL ,
    `post_time` INT( 11 ) UNSIGNED NOT NULL ,
    `author` INT( 11 ) UNSIGNED NOT NULL ,
    `text` TEXT CHARACTER SET utf8 COLLATE utf8_bin NOT NULL ,
    PRIMARY KEY ( `id` ) ,
    INDEX ( `id` )
) ENGINE = MYISAM ;

CREATE TABLE `joker`.`joke__threads` (
    `id` INT( 11 ) UNSIGNED NOT NULL AUTO_INCREMENT ,
    `parent_id` INT( 11 ) UNSIGNED NOT NULL ,
    `post_id` INT( 11 ) UNSIGNED NOT NULL,
    PRIMARY KEY ( `id` ) ,
    INDEX ( `id` )
) ENGINE = MYISAM ;

CREATE TABLE `joker`.`joke__wiki_article` (
    `id` INT( 11 ) UNSIGNED NOT NULL AUTO_INCREMENT ,
    `revision_id` INT( 11 ) UNSIGNED NOT NULL DEFAULT '0',
    `title` VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL ,
    `status` INT( 1 ) UNSIGNED NOT NULL DEFAULT '0',
    PRIMARY KEY ( `id` ) ,
    INDEX ( `id` )
) ENGINE = MYISAM ;

CREATE TABLE `joker`.`joke__wiki_revision` (
    `id` INT( 11 ) UNSIGNED NOT NULL AUTO_INCREMENT ,
    `article_id` INT( 11 ) UNSIGNED NOT NULL ,
    `user` INT( 11 ) UNSIGNED NOT NULL ,
    `text` TEXT CHARACTER SET utf8 COLLATE utf8_bin NOT NULL ,
    `datetime` INT( 11 ) UNSIGNED NOT NULL ,
    PRIMARY KEY ( `id` ) ,
    INDEX ( `id` )
) ENGINE = MYISAM ;
