CREATE TABLE `idgeneration` (
	`id` VARCHAR(128) NOT NULL,
	`realm` VARCHAR(128) NULL DEFAULT NULL,
	`laststoredid` BIGINT(20) NULL DEFAULT NULL,
	`resultingfromshutdown` TINYINT(1) NULL DEFAULT NULL,
	`binding` INT(11) NULL DEFAULT NULL,
	PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB;


INSERT IGNORE INTO `idgeneration` (`id`, `realm`, `laststoredid`, `resultingfromshutdown`, `binding`) VALUES ('objectversion', 'objectversion', 100000, 1, 0);
INSERT IGNORE INTO `idgeneration` (`id`, `realm`, `laststoredid`, `resultingfromshutdown`, `binding`) VALUES ('XMOMPersistenceManagement', 'XMOMPersistenceManagement', 100000, 1, 0);
INSERT IGNORE INTO `idgeneration` (`id`, `realm`, `laststoredid`, `resultingfromshutdown`, `binding`) VALUES ('xmomrepository', 'xmomrepository', 10000, 1, 0);
INSERT IGNORE INTO `idgeneration` (`id`, `realm`, `laststoredid`, `resultingfromshutdown`, `binding`) VALUES ('XynaFactory', 'default', 10000, 1, 0);
