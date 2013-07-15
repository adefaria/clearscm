-- MySQL dump 10.13  Distrib 5.1.41, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: clearadm
-- ------------------------------------------------------
-- Server version	5.1.41-3ubuntu12.8

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `view`
--

DROP TABLE IF EXISTS `view`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `view` (
  `system` varchar(255) NOT NULL,
  `region` varchar(255) NOT NULL,
  `tag` varchar(255) NOT NULL,
  `owner` tinytext,
  `ownerName` tinytext,
  `email` tinytext,
  `type` enum('dynamic','snapshot','web') DEFAULT 'dynamic',
  `gpath` tinytext,
  `modified` datetime DEFAULT NULL,
  `timestamp` datetime DEFAULT NULL,
  `age` tinytext,
  `ageSuffix` tinytext,
  PRIMARY KEY (`region`,`tag`),
  KEY `systemIndex` (`system`),
  KEY `regionIndex` (`region`),
  CONSTRAINT `view_ibfk_1` FOREIGN KEY (`system`) REFERENCES `system` (`name`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `view`
--

LOCK TABLES `view` WRITE;
/*!40000 ALTER TABLE `view` DISABLE KEYS */;
INSERT INTO `view` VALUES ('jupiter','home','tomsview1','defaria','Tom Connor','TomHillConnor@yahoo.com','web','/views/tconnor/tomsview1.vws','2010-12-25 00:00:00','2011-01-01 10:10:10','30','days'),('jupiter','home','tomsview2','defaria','Tom Connor','TomHillConnor@yahoo.com','snapshot','/views/tconnor/tomsview2.vws','2010-12-25 00:00:00','2011-01-01 10:10:10','45','days'),('jupiter','home','view1','defaria','Andrew DeFaria','Andrew@DeFaria.com','dynamic','/views/defaria/view1.vws','2010-01-01 00:00:00','2011-01-01 10:10:10','350','days'),('earth','home','view2','defaria','Andrew DeFaria','Andrew@DeFaria.com','snapshot','/views/defaria/view2.vws','2010-06-28 00:00:00','2011-01-01 10:10:10','210','days'),('jupiter','home','view3','defaria','Andrew DeFaria','Andrew@DeFaria.com','snapshot','/views/defaria/view3.vws','2010-12-25 00:00:00','2011-01-01 10:10:10','30','days');
/*!40000 ALTER TABLE `view` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2011-01-13 18:37:26
