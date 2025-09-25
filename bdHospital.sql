-- MySQL dump 10.13  Distrib 8.0.43, for Win64 (x86_64)
--
-- Host: localhost    Database: bdhospital
-- ------------------------------------------------------
-- Server version	8.0.43

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `account_emailaddress`
--

DROP TABLE IF EXISTS `account_emailaddress`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `account_emailaddress` (
  `id` int NOT NULL AUTO_INCREMENT,
  `email` varchar(254) NOT NULL,
  `verified` tinyint(1) NOT NULL,
  `primary` tinyint(1) NOT NULL,
  `user_id` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `account_emailaddress_user_id_email_987c8728_uniq` (`user_id`,`email`),
  KEY `account_emailaddress_email_03be32b2` (`email`),
  CONSTRAINT `account_emailaddress_user_id_2c513194_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `account_emailaddress`
--

LOCK TABLES `account_emailaddress` WRITE;
/*!40000 ALTER TABLE `account_emailaddress` DISABLE KEYS */;
INSERT INTO `account_emailaddress` VALUES (1,'c.toledoi@udd.cl',0,1,1),(2,'m.kurtec@udd.cl',0,1,3);
/*!40000 ALTER TABLE `account_emailaddress` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `account_emailconfirmation`
--

DROP TABLE IF EXISTS `account_emailconfirmation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `account_emailconfirmation` (
  `id` int NOT NULL AUTO_INCREMENT,
  `created` datetime(6) NOT NULL,
  `sent` datetime(6) DEFAULT NULL,
  `key` varchar(64) NOT NULL,
  `email_address_id` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `key` (`key`),
  KEY `account_emailconfirm_email_address_id_5b7f8c58_fk_account_e` (`email_address_id`),
  CONSTRAINT `account_emailconfirm_email_address_id_5b7f8c58_fk_account_e` FOREIGN KEY (`email_address_id`) REFERENCES `account_emailaddress` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `account_emailconfirmation`
--

LOCK TABLES `account_emailconfirmation` WRITE;
/*!40000 ALTER TABLE `account_emailconfirmation` DISABLE KEYS */;
/*!40000 ALTER TABLE `account_emailconfirmation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `agenda`
--

DROP TABLE IF EXISTS `agenda`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `agenda` (
  `idAgenda` int NOT NULL AUTO_INCREMENT,
  `idTipoAgenda` int NOT NULL,
  `idProfesional` int NOT NULL,
  `idBox` int NOT NULL,
  `fecha` date NOT NULL,
  `horaInicio` time NOT NULL,
  `horaFin` time NOT NULL,
  `observaciones` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`idAgenda`),
  KEY `idTipoAgenda` (`idTipoAgenda`),
  KEY `idProfesional` (`idProfesional`),
  KEY `idBox` (`idBox`),
  CONSTRAINT `agenda_ibfk_1` FOREIGN KEY (`idTipoAgenda`) REFERENCES `tipoagenda` (`idTipoAgenda`),
  CONSTRAINT `agenda_ibfk_2` FOREIGN KEY (`idProfesional`) REFERENCES `profesional` (`idProfesional`),
  CONSTRAINT `agenda_ibfk_3` FOREIGN KEY (`idBox`) REFERENCES `box` (`idBox`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `agenda`
--

LOCK TABLES `agenda` WRITE;
/*!40000 ALTER TABLE `agenda` DISABLE KEYS */;
INSERT INTO `agenda` VALUES (1,1,91,49,'2025-07-02','08:00:00','17:30:00',NULL),(2,1,91,11,'2025-07-02','05:00:00','17:30:00',NULL),(3,1,91,49,'2025-07-04','13:30:00','16:00:00',NULL),(4,1,30,8,'2025-07-04','14:57:00','17:30:00',NULL);
/*!40000 ALTER TABLE `agenda` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auth_group`
--

DROP TABLE IF EXISTS `auth_group`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_group` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(150) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_group`
--

LOCK TABLES `auth_group` WRITE;
/*!40000 ALTER TABLE `auth_group` DISABLE KEYS */;
/*!40000 ALTER TABLE `auth_group` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auth_group_permissions`
--

DROP TABLE IF EXISTS `auth_group_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_group_permissions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `group_id` int NOT NULL,
  `permission_id` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_group_permissions_group_id_permission_id_0cd325b0_uniq` (`group_id`,`permission_id`),
  KEY `auth_group_permissio_permission_id_84c5c92e_fk_auth_perm` (`permission_id`),
  CONSTRAINT `auth_group_permissio_permission_id_84c5c92e_fk_auth_perm` FOREIGN KEY (`permission_id`) REFERENCES `auth_permission` (`id`),
  CONSTRAINT `auth_group_permissions_group_id_b120cbf9_fk_auth_group_id` FOREIGN KEY (`group_id`) REFERENCES `auth_group` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_group_permissions`
--

LOCK TABLES `auth_group_permissions` WRITE;
/*!40000 ALTER TABLE `auth_group_permissions` DISABLE KEYS */;
/*!40000 ALTER TABLE `auth_group_permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auth_permission`
--

DROP TABLE IF EXISTS `auth_permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_permission` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `content_type_id` int NOT NULL,
  `codename` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_permission_content_type_id_codename_01ab375a_uniq` (`content_type_id`,`codename`),
  CONSTRAINT `auth_permission_content_type_id_2f476e4b_fk_django_co` FOREIGN KEY (`content_type_id`) REFERENCES `django_content_type` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=121 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_permission`
--

LOCK TABLES `auth_permission` WRITE;
/*!40000 ALTER TABLE `auth_permission` DISABLE KEYS */;
INSERT INTO `auth_permission` VALUES (1,'Can add log entry',1,'add_logentry'),(2,'Can change log entry',1,'change_logentry'),(3,'Can delete log entry',1,'delete_logentry'),(4,'Can view log entry',1,'view_logentry'),(5,'Can add permission',2,'add_permission'),(6,'Can change permission',2,'change_permission'),(7,'Can delete permission',2,'delete_permission'),(8,'Can view permission',2,'view_permission'),(9,'Can add group',3,'add_group'),(10,'Can change group',3,'change_group'),(11,'Can delete group',3,'delete_group'),(12,'Can view group',3,'view_group'),(13,'Can add user',4,'add_user'),(14,'Can change user',4,'change_user'),(15,'Can delete user',4,'delete_user'),(16,'Can view user',4,'view_user'),(17,'Can add content type',5,'add_contenttype'),(18,'Can change content type',5,'change_contenttype'),(19,'Can delete content type',5,'delete_contenttype'),(20,'Can view content type',5,'view_contenttype'),(21,'Can add session',6,'add_session'),(22,'Can change session',6,'change_session'),(23,'Can delete session',6,'delete_session'),(24,'Can view session',6,'view_session'),(25,'Can add agenda',7,'add_agenda'),(26,'Can change agenda',7,'change_agenda'),(27,'Can delete agenda',7,'delete_agenda'),(28,'Can view agenda',7,'view_agenda'),(29,'Can add auth group',8,'add_authgroup'),(30,'Can change auth group',8,'change_authgroup'),(31,'Can delete auth group',8,'delete_authgroup'),(32,'Can view auth group',8,'view_authgroup'),(33,'Can add auth group permissions',9,'add_authgrouppermissions'),(34,'Can change auth group permissions',9,'change_authgrouppermissions'),(35,'Can delete auth group permissions',9,'delete_authgrouppermissions'),(36,'Can view auth group permissions',9,'view_authgrouppermissions'),(37,'Can add auth permission',10,'add_authpermission'),(38,'Can change auth permission',10,'change_authpermission'),(39,'Can delete auth permission',10,'delete_authpermission'),(40,'Can view auth permission',10,'view_authpermission'),(41,'Can add auth user',11,'add_authuser'),(42,'Can change auth user',11,'change_authuser'),(43,'Can delete auth user',11,'delete_authuser'),(44,'Can view auth user',11,'view_authuser'),(45,'Can add auth user groups',12,'add_authusergroups'),(46,'Can change auth user groups',12,'change_authusergroups'),(47,'Can delete auth user groups',12,'delete_authusergroups'),(48,'Can view auth user groups',12,'view_authusergroups'),(49,'Can add auth user user permissions',13,'add_authuseruserpermissions'),(50,'Can change auth user user permissions',13,'change_authuseruserpermissions'),(51,'Can delete auth user user permissions',13,'delete_authuseruserpermissions'),(52,'Can view auth user user permissions',13,'view_authuseruserpermissions'),(53,'Can add box',14,'add_box'),(54,'Can change box',14,'change_box'),(55,'Can delete box',14,'delete_box'),(56,'Can view box',14,'view_box'),(57,'Can add django admin log',15,'add_djangoadminlog'),(58,'Can change django admin log',15,'change_djangoadminlog'),(59,'Can delete django admin log',15,'delete_djangoadminlog'),(60,'Can view django admin log',15,'view_djangoadminlog'),(61,'Can add django content type',16,'add_djangocontenttype'),(62,'Can change django content type',16,'change_djangocontenttype'),(63,'Can delete django content type',16,'delete_djangocontenttype'),(64,'Can view django content type',16,'view_djangocontenttype'),(65,'Can add django migrations',17,'add_djangomigrations'),(66,'Can change django migrations',17,'change_djangomigrations'),(67,'Can delete django migrations',17,'delete_djangomigrations'),(68,'Can view django migrations',17,'view_djangomigrations'),(69,'Can add django session',18,'add_djangosession'),(70,'Can change django session',18,'change_djangosession'),(71,'Can delete django session',18,'delete_djangosession'),(72,'Can view django session',18,'view_djangosession'),(73,'Can add especialidad',19,'add_especialidad'),(74,'Can change especialidad',19,'change_especialidad'),(75,'Can delete especialidad',19,'delete_especialidad'),(76,'Can view especialidad',19,'view_especialidad'),(77,'Can add pasillo',20,'add_pasillo'),(78,'Can change pasillo',20,'change_pasillo'),(79,'Can delete pasillo',20,'delete_pasillo'),(80,'Can view pasillo',20,'view_pasillo'),(81,'Can add profesional',21,'add_profesional'),(82,'Can change profesional',21,'change_profesional'),(83,'Can delete profesional',21,'delete_profesional'),(84,'Can view profesional',21,'view_profesional'),(85,'Can add tipoagenda',22,'add_tipoagenda'),(86,'Can change tipoagenda',22,'change_tipoagenda'),(87,'Can delete tipoagenda',22,'delete_tipoagenda'),(88,'Can view tipoagenda',22,'view_tipoagenda'),(89,'Can add site',23,'add_site'),(90,'Can change site',23,'change_site'),(91,'Can delete site',23,'delete_site'),(92,'Can view site',23,'view_site'),(93,'Can add Tipo de Usuario',24,'add_tipousuario'),(94,'Can change Tipo de Usuario',24,'change_tipousuario'),(95,'Can delete Tipo de Usuario',24,'delete_tipousuario'),(96,'Can view Tipo de Usuario',24,'view_tipousuario'),(97,'Can add Perfil de Usuario',25,'add_perfilusuario'),(98,'Can change Perfil de Usuario',25,'change_perfilusuario'),(99,'Can delete Perfil de Usuario',25,'delete_perfilusuario'),(100,'Can view Perfil de Usuario',25,'view_perfilusuario'),(101,'Can add email address',26,'add_emailaddress'),(102,'Can change email address',26,'change_emailaddress'),(103,'Can delete email address',26,'delete_emailaddress'),(104,'Can view email address',26,'view_emailaddress'),(105,'Can add email confirmation',27,'add_emailconfirmation'),(106,'Can change email confirmation',27,'change_emailconfirmation'),(107,'Can delete email confirmation',27,'delete_emailconfirmation'),(108,'Can view email confirmation',27,'view_emailconfirmation'),(109,'Can add social account',28,'add_socialaccount'),(110,'Can change social account',28,'change_socialaccount'),(111,'Can delete social account',28,'delete_socialaccount'),(112,'Can view social account',28,'view_socialaccount'),(113,'Can add social application',29,'add_socialapp'),(114,'Can change social application',29,'change_socialapp'),(115,'Can delete social application',29,'delete_socialapp'),(116,'Can view social application',29,'view_socialapp'),(117,'Can add social application token',30,'add_socialtoken'),(118,'Can change social application token',30,'change_socialtoken'),(119,'Can delete social application token',30,'delete_socialtoken'),(120,'Can view social application token',30,'view_socialtoken');
/*!40000 ALTER TABLE `auth_permission` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auth_user`
--

DROP TABLE IF EXISTS `auth_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_user` (
  `id` int NOT NULL AUTO_INCREMENT,
  `password` varchar(128) NOT NULL,
  `last_login` datetime(6) DEFAULT NULL,
  `is_superuser` tinyint(1) NOT NULL,
  `username` varchar(150) NOT NULL,
  `first_name` varchar(150) NOT NULL,
  `last_name` varchar(150) NOT NULL,
  `email` varchar(254) NOT NULL,
  `is_staff` tinyint(1) NOT NULL,
  `is_active` tinyint(1) NOT NULL,
  `date_joined` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_user`
--

LOCK TABLES `auth_user` WRITE;
/*!40000 ALTER TABLE `auth_user` DISABLE KEYS */;
INSERT INTO `auth_user` VALUES (1,'pbkdf2_sha256$600000$zXsifvOukIWzbSOLjqZrK0$iBsjv4D7WnSkHhMmbMZ7QMPcPU9hjVlQpXDr8sv0N54=','2025-09-24 18:56:25.000000',0,'user_d8ec8c04','','','c.toledoi@udd.cl',0,1,'2025-09-24 17:59:38.000000'),(2,'pbkdf2_sha256$600000$BuM8h7kAGtMkpWR8Xa1Iqm$ng/wsQwfW24uPqDQEzqr41R8aHo4glEYMDk/KmPfJl4=','2025-09-24 19:20:17.114595',1,'milan','','','milankurte@gmail.com',1,1,'2025-09-24 19:04:39.426731'),(3,'pbkdf2_sha256$600000$6QvvdhaYQvvuirI2CYAcFr$vOW3QQP2T97O8GnSEuwigPxE6wRHCe4pH3nEUszD+Cs=','2025-09-24 19:20:07.015328',0,'user_0be003d1','','','m.kurtec@udd.cl',0,1,'2025-09-24 19:19:54.296708');
/*!40000 ALTER TABLE `auth_user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auth_user_groups`
--

DROP TABLE IF EXISTS `auth_user_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_user_groups` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `group_id` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_user_groups_user_id_group_id_94350c0c_uniq` (`user_id`,`group_id`),
  KEY `auth_user_groups_group_id_97559544_fk_auth_group_id` (`group_id`),
  CONSTRAINT `auth_user_groups_group_id_97559544_fk_auth_group_id` FOREIGN KEY (`group_id`) REFERENCES `auth_group` (`id`),
  CONSTRAINT `auth_user_groups_user_id_6a12ed8b_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_user_groups`
--

LOCK TABLES `auth_user_groups` WRITE;
/*!40000 ALTER TABLE `auth_user_groups` DISABLE KEYS */;
/*!40000 ALTER TABLE `auth_user_groups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auth_user_user_permissions`
--

DROP TABLE IF EXISTS `auth_user_user_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_user_user_permissions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `permission_id` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_user_user_permissions_user_id_permission_id_14a6b632_uniq` (`user_id`,`permission_id`),
  KEY `auth_user_user_permi_permission_id_1fbb5f2c_fk_auth_perm` (`permission_id`),
  CONSTRAINT `auth_user_user_permi_permission_id_1fbb5f2c_fk_auth_perm` FOREIGN KEY (`permission_id`) REFERENCES `auth_permission` (`id`),
  CONSTRAINT `auth_user_user_permissions_user_id_a95ead1b_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_user_user_permissions`
--

LOCK TABLES `auth_user_user_permissions` WRITE;
/*!40000 ALTER TABLE `auth_user_user_permissions` DISABLE KEYS */;
/*!40000 ALTER TABLE `auth_user_user_permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `box`
--

DROP TABLE IF EXISTS `box`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `box` (
  `idBox` int NOT NULL AUTO_INCREMENT,
  `idPasillo` int NOT NULL,
  `capacidad` int DEFAULT NULL,
  PRIMARY KEY (`idBox`),
  KEY `idPasillo` (`idPasillo`),
  CONSTRAINT `box_ibfk_1` FOREIGN KEY (`idPasillo`) REFERENCES `pasillo` (`idPasillo`)
) ENGINE=InnoDB AUTO_INCREMENT=181 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `box`
--

LOCK TABLES `box` WRITE;
/*!40000 ALTER TABLE `box` DISABLE KEYS */;
INSERT INTO `box` VALUES (1,30,1),(2,45,3),(3,38,1),(4,3,2),(5,10,3),(6,24,3),(7,4,1),(8,32,1),(9,38,2),(10,15,2),(11,48,1),(12,3,3),(13,1,3),(14,14,2),(15,5,1),(16,14,1),(17,24,2),(18,44,3),(19,17,2),(20,41,3),(21,6,2),(22,19,3),(23,26,2),(24,25,3),(25,7,3),(26,35,3),(27,20,1),(28,36,3),(29,44,1),(30,38,3),(31,24,1),(32,40,3),(33,45,2),(34,18,2),(35,7,1),(36,4,2),(37,8,2),(38,8,1),(39,47,2),(40,21,3),(41,16,2),(42,29,2),(43,44,1),(44,10,2),(45,25,1),(46,8,3),(47,45,2),(48,28,2),(49,18,1),(50,48,2),(51,7,1),(52,36,2),(53,40,2),(54,42,2),(55,42,1),(56,36,1),(57,30,2),(58,26,2),(59,15,3),(60,48,2),(61,25,3),(62,29,3),(63,47,2),(64,13,1),(65,33,1),(66,29,2),(67,41,1),(68,35,2),(69,20,2),(70,31,1),(71,41,1),(72,30,3),(73,44,3),(74,35,2),(75,32,3),(76,47,1),(77,42,3),(78,32,3),(79,28,1),(80,19,2),(81,48,2),(82,16,1),(83,45,3),(84,27,1),(85,3,2),(86,4,3),(87,27,2),(88,22,1),(89,2,2),(90,46,1),(91,19,1),(92,15,2),(93,11,1),(94,19,1),(95,41,1),(96,24,2),(97,26,3),(98,46,2),(99,7,1),(100,27,2),(101,45,1),(102,26,3),(103,21,2),(104,9,3),(105,10,1),(106,8,2),(107,36,2),(108,38,3),(109,1,2),(110,15,1),(111,21,3),(112,25,2),(113,20,3),(114,45,3),(115,4,1),(116,34,3),(117,34,3),(118,6,3),(119,24,2),(120,33,3),(121,41,1),(122,16,3),(123,27,1),(124,37,2),(125,2,3),(126,37,1),(127,21,1),(128,35,1),(129,40,2),(130,41,3),(131,36,2),(132,22,2),(133,21,2),(134,4,2),(135,45,3),(136,33,3),(137,25,3),(138,5,3),(139,2,2),(140,32,1),(141,3,1),(142,31,2),(143,34,2),(144,45,3),(145,12,3),(146,7,2),(147,31,3),(148,46,3),(149,35,3),(150,29,3),(151,44,3),(152,46,2),(153,44,1),(154,33,1),(155,39,1),(156,41,3),(157,25,1),(158,38,1),(159,37,3),(160,18,3),(161,11,3),(162,11,3),(163,3,2),(164,43,3),(165,2,1),(166,25,1),(167,30,1),(168,13,1),(169,33,3),(170,34,3),(171,35,1),(172,14,1),(173,5,3),(174,27,3),(175,10,2),(176,6,3),(177,11,1),(178,6,2),(179,4,1),(180,37,2);
/*!40000 ALTER TABLE `box` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `django_admin_log`
--

DROP TABLE IF EXISTS `django_admin_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `django_admin_log` (
  `id` int NOT NULL AUTO_INCREMENT,
  `action_time` datetime(6) NOT NULL,
  `object_id` longtext,
  `object_repr` varchar(200) NOT NULL,
  `action_flag` smallint unsigned NOT NULL,
  `change_message` longtext NOT NULL,
  `content_type_id` int DEFAULT NULL,
  `user_id` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `django_admin_log_content_type_id_c4bce8eb_fk_django_co` (`content_type_id`),
  KEY `django_admin_log_user_id_c564eba6_fk_auth_user_id` (`user_id`),
  CONSTRAINT `django_admin_log_content_type_id_c4bce8eb_fk_django_co` FOREIGN KEY (`content_type_id`) REFERENCES `django_content_type` (`id`),
  CONSTRAINT `django_admin_log_user_id_c564eba6_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`),
  CONSTRAINT `django_admin_log_chk_1` CHECK ((`action_flag` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `django_admin_log`
--

LOCK TABLES `django_admin_log` WRITE;
/*!40000 ALTER TABLE `django_admin_log` DISABLE KEYS */;
INSERT INTO `django_admin_log` VALUES (1,'2025-09-24 19:07:06.003304','1','user_d8ec8c04',2,'[{\"changed\": {\"name\": \"Perfil de Usuario\", \"object\": \"user_d8ec8c04 (Visitante)\", \"fields\": [\"Pasillo asignado\"]}}]',4,2),(2,'2025-09-24 19:18:00.704464','1','user_d8ec8c04 (Visitante)',2,'[{\"changed\": {\"fields\": [\"Tipo usuario\"]}}]',25,2),(3,'2025-09-24 19:20:24.974594','2','user_0be003d1 (Administrador)',2,'[{\"changed\": {\"fields\": [\"Tipo usuario\"]}}]',25,2);
/*!40000 ALTER TABLE `django_admin_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `django_content_type`
--

DROP TABLE IF EXISTS `django_content_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `django_content_type` (
  `id` int NOT NULL AUTO_INCREMENT,
  `app_label` varchar(100) NOT NULL,
  `model` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `django_content_type_app_label_model_76bd3d3b_uniq` (`app_label`,`model`)
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `django_content_type`
--

LOCK TABLES `django_content_type` WRITE;
/*!40000 ALTER TABLE `django_content_type` DISABLE KEYS */;
INSERT INTO `django_content_type` VALUES (26,'account','emailaddress'),(27,'account','emailconfirmation'),(1,'admin','logentry'),(3,'auth','group'),(2,'auth','permission'),(4,'auth','user'),(5,'contenttypes','contenttype'),(6,'sessions','session'),(23,'sites','site'),(28,'socialaccount','socialaccount'),(29,'socialaccount','socialapp'),(30,'socialaccount','socialtoken'),(7,'visualizacionBoxes','agenda'),(8,'visualizacionBoxes','authgroup'),(9,'visualizacionBoxes','authgrouppermissions'),(10,'visualizacionBoxes','authpermission'),(11,'visualizacionBoxes','authuser'),(12,'visualizacionBoxes','authusergroups'),(13,'visualizacionBoxes','authuseruserpermissions'),(14,'visualizacionBoxes','box'),(15,'visualizacionBoxes','djangoadminlog'),(16,'visualizacionBoxes','djangocontenttype'),(17,'visualizacionBoxes','djangomigrations'),(18,'visualizacionBoxes','djangosession'),(19,'visualizacionBoxes','especialidad'),(20,'visualizacionBoxes','pasillo'),(25,'visualizacionBoxes','perfilusuario'),(21,'visualizacionBoxes','profesional'),(22,'visualizacionBoxes','tipoagenda'),(24,'visualizacionBoxes','tipousuario');
/*!40000 ALTER TABLE `django_content_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `django_migrations`
--

DROP TABLE IF EXISTS `django_migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `django_migrations` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `app` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `applied` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `django_migrations`
--

LOCK TABLES `django_migrations` WRITE;
/*!40000 ALTER TABLE `django_migrations` DISABLE KEYS */;
INSERT INTO `django_migrations` VALUES (1,'contenttypes','0001_initial','2025-07-02 04:50:59.245168'),(2,'auth','0001_initial','2025-07-02 04:50:59.781858'),(3,'admin','0001_initial','2025-07-02 04:50:59.904997'),(4,'admin','0002_logentry_remove_auto_add','2025-07-02 04:50:59.911711'),(5,'admin','0003_logentry_add_action_flag_choices','2025-07-02 04:50:59.918711'),(6,'contenttypes','0002_remove_content_type_name','2025-07-02 04:51:00.028669'),(7,'auth','0002_alter_permission_name_max_length','2025-07-02 04:51:00.082497'),(8,'auth','0003_alter_user_email_max_length','2025-07-02 04:51:00.104852'),(9,'auth','0004_alter_user_username_opts','2025-07-02 04:51:00.112277'),(10,'auth','0005_alter_user_last_login_null','2025-07-02 04:51:00.158993'),(11,'auth','0006_require_contenttypes_0002','2025-07-02 04:51:00.165714'),(12,'auth','0007_alter_validators_add_error_messages','2025-07-02 04:51:00.173028'),(13,'auth','0008_alter_user_username_max_length','2025-07-02 04:51:00.235059'),(14,'auth','0009_alter_user_last_name_max_length','2025-07-02 04:51:00.296437'),(15,'auth','0010_alter_group_name_max_length','2025-07-02 04:51:00.313336'),(16,'auth','0011_update_proxy_permissions','2025-07-02 04:51:00.319299'),(17,'auth','0012_alter_user_first_name_max_length','2025-07-02 04:51:00.384952'),(18,'sessions','0001_initial','2025-07-02 04:51:00.416513'),(19,'account','0001_initial','2025-09-24 17:52:19.457546'),(20,'account','0002_email_max_length','2025-09-24 17:52:19.500706'),(21,'account','0003_alter_emailaddress_create_unique_verified_email','2025-09-24 17:52:19.569205'),(22,'account','0004_alter_emailaddress_drop_unique_email','2025-09-24 17:52:19.635519'),(23,'account','0005_emailaddress_idx_upper_email','2025-09-24 17:52:19.687084'),(24,'account','0006_emailaddress_lower','2025-09-24 17:52:19.710505'),(25,'account','0007_emailaddress_idx_email','2025-09-24 17:52:19.799257'),(26,'account','0008_emailaddress_unique_primary_email_fixup','2025-09-24 17:52:19.821272'),(27,'account','0009_emailaddress_unique_primary_email','2025-09-24 17:52:19.836605'),(28,'sites','0001_initial','2025-09-24 17:52:19.868358'),(29,'sites','0002_alter_domain_unique','2025-09-24 17:52:19.906813'),(30,'socialaccount','0001_initial','2025-09-24 17:52:20.568878'),(31,'socialaccount','0002_token_max_lengths','2025-09-24 17:52:20.667725'),(32,'socialaccount','0003_extra_data_default_dict','2025-09-24 17:52:20.694427'),(33,'socialaccount','0004_app_provider_id_settings','2025-09-24 17:52:20.978302'),(34,'socialaccount','0005_socialtoken_nullable_app','2025-09-24 17:52:21.204774'),(35,'socialaccount','0006_alter_socialaccount_extra_data','2025-09-24 17:52:21.312282'),(36,'visualizacionBoxes','0001_initial','2025-09-24 17:52:21.686303'),(37,'visualizacionBoxes','0002_perfilusuario_pasillo_asignado','2025-09-24 17:52:21.816515');
/*!40000 ALTER TABLE `django_migrations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `django_session`
--

DROP TABLE IF EXISTS `django_session`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `django_session` (
  `session_key` varchar(40) NOT NULL,
  `session_data` longtext NOT NULL,
  `expire_date` datetime(6) NOT NULL,
  PRIMARY KEY (`session_key`),
  KEY `django_session_expire_date_a5c62663` (`expire_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `django_session`
--

LOCK TABLES `django_session` WRITE;
/*!40000 ALTER TABLE `django_session` DISABLE KEYS */;
INSERT INTO `django_session` VALUES ('ctvst7dcln14a9g57ezc85tua8pwrs7b','.eJxVkE1uhDAMhe_iNYqSkJCEVdtrVCNkEiPQ8DMiiTrVaO5eoGzYWX7Pn5_9AvR-yXNqMKee5jR4TMMyNxOlfgkR6u8X_NdQwwNj_FnWAAVggloYbY0SFTeMC6G4sgXQhMO4WSd2z2si_5FDYH6E962AY0eTI63NsONKuPRa9HeadwHHcW-zMxs7PKcc2ecl6dc5dUH1GPuNU-k2SBvQhNL6SratI1dW1mipte1s0EIZYRx1AbnqnOZyu0J3VgWvtHQHNFKM-0Po-RjWX6j5-w9MDGYr:1v1V27:Dj3te8fZYLTkbBbHpJ1hUKBibvgWj6aDXcQxpxqOnkE','2025-10-08 19:20:07.017719'),('j9h9ltxolu2m4dwnkg2p4k0fugy9d79t','.eJxVkM1qxDAMhN9F52D8Gzs5dfsapQTZFsQ0Gy-xQ1uWffeut7nkJmZGnwbdAUPI-1on3OtMa00Ba8rrdKU651hg_LjD_wwj3LCU77xF6AArjMIaZzUXzjCtjVWD6YCumJZnNLCaF4o5ve0xsrDA47OD15FpL7RNqfEEnDSP4YvWZuCyNJkd5dgrc9iFXU5V34-tE2rGMj852vQ9N2IgzYcolBTKCW9sL80Q0XHlvO11tFJbQsUDoXekhA9CCiulMw1aqJT2Efq5pe0XRv74A3jDZag:1v1UfB:cx0OAjgOP8DYkkJwe9yDNCxymBE_JN85c6lEe3nNirI','2025-10-08 18:56:25.453733');
/*!40000 ALTER TABLE `django_session` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `django_site`
--

DROP TABLE IF EXISTS `django_site`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `django_site` (
  `id` int NOT NULL AUTO_INCREMENT,
  `domain` varchar(100) NOT NULL,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `django_site_domain_a2e37b91_uniq` (`domain`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `django_site`
--

LOCK TABLES `django_site` WRITE;
/*!40000 ALTER TABLE `django_site` DISABLE KEYS */;
INSERT INTO `django_site` VALUES (1,'example.com','example.com');
/*!40000 ALTER TABLE `django_site` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `especialidad`
--

DROP TABLE IF EXISTS `especialidad`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `especialidad` (
  `idEspecialidad` int NOT NULL AUTO_INCREMENT,
  `especialidad` varchar(100) NOT NULL,
  PRIMARY KEY (`idEspecialidad`)
) ENGINE=InnoDB AUTO_INCREMENT=49 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `especialidad`
--

LOCK TABLES `especialidad` WRITE;
/*!40000 ALTER TABLE `especialidad` DISABLE KEYS */;
INSERT INTO `especialidad` VALUES (1,'Cardiología'),(2,'Dermatología'),(3,'Endocrinología'),(4,'Gastroenterología'),(5,'Geriatría'),(6,'Hematología'),(7,'Infectología'),(8,'Medicina interna'),(9,'Nefrología'),(10,'Neumología'),(11,'Neurología'),(12,'Oncología'),(13,'Pediatría'),(14,'Reumatología'),(15,'Alergología'),(16,'Anestesiología'),(17,'Angiología'),(18,'Cirugía general'),(19,'Cirugía plástica'),(20,'Cirugía cardiovascular'),(21,'Cirugía pediátrica'),(22,'Cirugía torácica'),(23,'Neurocirugía'),(24,'Oftalmología'),(25,'Otorrinolaringología'),(26,'Traumatología'),(27,'Urología'),(28,'Ginecología'),(29,'Obstetricia'),(30,'Psiquiatría'),(31,'Radiología'),(32,'Medicina nuclear'),(33,'Patología'),(34,'Medicina familiar'),(35,'Medicina de emergencia'),(36,'Medicina del deporte'),(37,'Medicina física'),(38,'Rehabilitación'),(39,'Toxicología'),(40,'Genética médica'),(41,'Inmunología'),(42,'Nutriología'),(43,'Oncología radioterápica'),(44,'Dolor y cuidados paliativos'),(45,'Medicina del trabajo'),(46,'Medicina intensiva'),(47,'Foniatría'),(48,'Homeopatía');
/*!40000 ALTER TABLE `especialidad` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pasillo`
--

DROP TABLE IF EXISTS `pasillo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pasillo` (
  `idPasillo` int NOT NULL AUTO_INCREMENT,
  `pasillo` varchar(100) NOT NULL,
  PRIMARY KEY (`idPasillo`)
) ENGINE=InnoDB AUTO_INCREMENT=49 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pasillo`
--

LOCK TABLES `pasillo` WRITE;
/*!40000 ALTER TABLE `pasillo` DISABLE KEYS */;
INSERT INTO `pasillo` VALUES (1,'Cardiología'),(2,'Dermatología'),(3,'Endocrinología'),(4,'Gastroenterología'),(5,'Geriatría'),(6,'Hematología'),(7,'Infectología'),(8,'Medicina interna'),(9,'Nefrología'),(10,'Neumología'),(11,'Neurología'),(12,'Oncología'),(13,'Pediatría'),(14,'Reumatología'),(15,'Alergología'),(16,'Anestesiología'),(17,'Angiología'),(18,'Cirugía general'),(19,'Cirugía plástica'),(20,'Cirugía cardiovascular'),(21,'Cirugía pediátrica'),(22,'Cirugía torácica'),(23,'Neurocirugía'),(24,'Oftalmología'),(25,'Otorrinolaringología'),(26,'Traumatología'),(27,'Urología'),(28,'Ginecología'),(29,'Obstetricia'),(30,'Psiquiatría'),(31,'Radiología'),(32,'Medicina nuclear'),(33,'Patología'),(34,'Medicina familiar'),(35,'Medicina de emergencia'),(36,'Medicina del deporte'),(37,'Medicina física'),(38,'Rehabilitación'),(39,'Toxicología'),(40,'Genética médica'),(41,'Inmunología'),(42,'Nutriología'),(43,'Oncología radioterápica'),(44,'Dolor y cuidados paliativos'),(45,'Medicina del trabajo'),(46,'Medicina intensiva'),(47,'Foniatría'),(48,'Homeopatía');
/*!40000 ALTER TABLE `pasillo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `perfil_usuario`
--

DROP TABLE IF EXISTS `perfil_usuario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `perfil_usuario` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `activo` tinyint(1) NOT NULL,
  `telefono` varchar(20) NOT NULL,
  `fecha_creacion` datetime(6) NOT NULL,
  `fecha_modificacion` datetime(6) NOT NULL,
  `ultimo_acceso` datetime(6) DEFAULT NULL,
  `tipo_usuario_id` bigint NOT NULL,
  `usuario_id` int NOT NULL,
  `pasillo_asignado_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `usuario_id` (`usuario_id`),
  KEY `perfil_usuario_tipo_usuario_id_c28862e9_fk_tipo_usuario_id` (`tipo_usuario_id`),
  KEY `perfil_usuario_pasillo_asignado_id_2237e58b_fk_pasillo_idPasillo` (`pasillo_asignado_id`),
  CONSTRAINT `perfil_usuario_pasillo_asignado_id_2237e58b_fk_pasillo_idPasillo` FOREIGN KEY (`pasillo_asignado_id`) REFERENCES `pasillo` (`idPasillo`),
  CONSTRAINT `perfil_usuario_tipo_usuario_id_c28862e9_fk_tipo_usuario_id` FOREIGN KEY (`tipo_usuario_id`) REFERENCES `tipo_usuario` (`id`),
  CONSTRAINT `perfil_usuario_usuario_id_7abe8fbf_fk_auth_user_id` FOREIGN KEY (`usuario_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `perfil_usuario`
--

LOCK TABLES `perfil_usuario` WRITE;
/*!40000 ALTER TABLE `perfil_usuario` DISABLE KEYS */;
INSERT INTO `perfil_usuario` VALUES (1,1,'','2025-09-24 17:59:39.242499','2025-09-24 19:18:00.703534',NULL,4,1,18),(2,1,'','2025-09-24 19:19:54.539244','2025-09-24 19:20:24.973735',NULL,1,3,NULL);
/*!40000 ALTER TABLE `perfil_usuario` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `profesional`
--

DROP TABLE IF EXISTS `profesional`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `profesional` (
  `idProfesional` int NOT NULL AUTO_INCREMENT,
  `idEspecialidad` int NOT NULL,
  `nombre` varchar(100) NOT NULL,
  PRIMARY KEY (`idProfesional`),
  KEY `idEspecialidad` (`idEspecialidad`),
  CONSTRAINT `profesional_ibfk_1` FOREIGN KEY (`idEspecialidad`) REFERENCES `especialidad` (`idEspecialidad`)
) ENGINE=InnoDB AUTO_INCREMENT=301 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `profesional`
--

LOCK TABLES `profesional` WRITE;
/*!40000 ALTER TABLE `profesional` DISABLE KEYS */;
INSERT INTO `profesional` VALUES (1,2,'Lauren Meyer'),(2,14,'Leonard Hill'),(3,44,'Lauren Mann'),(4,26,'Scott Ritter'),(5,46,'Anthony Gonzalez'),(6,41,'Sara Robinson'),(7,23,'Bethany Greene'),(8,27,'James Davis'),(9,11,'Michele Hawkins'),(10,25,'Gerald Gomez'),(11,18,'Rachel Khan'),(12,41,'April Flores'),(13,35,'Christopher Carroll'),(14,29,'Brianna Case'),(15,29,'Pamela Melendez'),(16,20,'Jonathan Vincent'),(17,14,'Tyler Hoffman'),(18,25,'Edward Robbins'),(19,32,'Mark Wallace'),(20,24,'Kathleen Swanson'),(21,30,'Steven Middleton'),(22,42,'Keith Carter'),(23,33,'David Murphy'),(24,23,'Jamie Velez'),(25,16,'Earl Lyons'),(26,15,'Rebecca Carter'),(27,9,'Alec Blackburn'),(28,34,'Desiree Ellis'),(29,13,'Ashley Greer'),(30,18,'William Cox'),(31,11,'Annette Mccullough'),(32,38,'Michael Martinez'),(33,28,'Kathryn Wilkins'),(34,47,'Christopher White'),(35,45,'Kelly Sweeney'),(36,27,'Curtis Navarro'),(37,38,'Cheryl Copeland'),(38,7,'Tammie Rivers'),(39,47,'Stacey Smith'),(40,45,'Kathryn Camacho'),(41,32,'James Smith'),(42,28,'Deanna Stephens'),(43,35,'Michael Flowers'),(44,28,'Christina Li'),(45,21,'April Scott'),(46,36,'Mr. Steven Hatfield'),(47,27,'Logan Heath'),(48,8,'Christopher Johnson'),(49,46,'Heather Diaz'),(50,21,'Kevin Smith'),(51,27,'Christopher Knight'),(52,26,'Daniel Davis'),(53,34,'Jeffrey May'),(54,12,'Angela Johnson'),(55,17,'Dr. Christopher Walker Jr.'),(56,7,'Katherine Nguyen'),(57,13,'Robert Oconnell'),(58,47,'Charlene Tucker'),(59,32,'Zachary Scott'),(60,45,'Andrew Cantu'),(61,31,'Jennifer Rose'),(62,3,'Glen Mccann'),(63,29,'Ronald Gonzales'),(64,21,'Claire Clark'),(65,29,'Christopher Butler'),(66,20,'Haley Roberts'),(67,19,'Jessica Williams'),(68,40,'James Simpson'),(69,7,'Danielle Nunez'),(70,42,'Kevin Whitehead'),(71,16,'William Clark'),(72,39,'Jeremiah Tucker'),(73,30,'Mark Crawford'),(74,41,'Robert Coleman'),(75,25,'Jacqueline Lopez'),(76,30,'Ariana Bates'),(77,15,'Miranda Barrett'),(78,39,'Joseph Allen'),(79,14,'Karen Rivera'),(80,32,'Joshua Lopez'),(81,29,'Kevin Pace'),(82,43,'Jennifer Lopez'),(83,29,'Carrie Gillespie'),(84,5,'Laura Bell'),(85,41,'Natasha Thompson'),(86,42,'Johnny Parker'),(87,16,'Matthew Wells'),(88,9,'Christopher Richards'),(89,2,'Justin Mcclure'),(90,37,'John Bell'),(91,23,'Tony Brown'),(92,22,'Kristen Howe'),(93,34,'Megan Taylor'),(94,15,'Shannon Scott'),(95,7,'Courtney Martinez'),(96,29,'Joseph Evans'),(97,42,'Mr. Nicholas Murphy'),(98,1,'Taylor Wells'),(99,32,'Tanya Wright'),(100,10,'Christina Johnson'),(101,38,'Jessica Shepherd'),(102,47,'Christina Stone'),(103,40,'Deanna Barron MD'),(104,27,'Jamie Ferguson'),(105,23,'Lee Stone'),(106,27,'Cynthia Bowman'),(107,12,'Robert Jones'),(108,39,'Grace James'),(109,20,'Theresa Adams MD'),(110,4,'Monica Miller'),(111,12,'Andrew Castro'),(112,15,'Anita Bush'),(113,42,'Christopher Campbell'),(114,23,'Brett Barnes'),(115,24,'Jonathan Rodriguez'),(116,1,'Deanna Scott'),(117,34,'Madison Martin'),(118,8,'Richard Mcclure'),(119,44,'Joshua Hansen'),(120,12,'Brad Kim'),(121,41,'Pamela Vaughn'),(122,12,'Lisa Lopez'),(123,12,'Hayden Hughes'),(124,10,'Brian Clark'),(125,27,'Charles Jones'),(126,41,'Ronald Sanchez'),(127,35,'Ashley Tyler'),(128,20,'Donald Hicks'),(129,22,'Brandon Montgomery'),(130,6,'Matthew Snyder'),(131,18,'Kenneth Buck'),(132,2,'Paul Ferrell'),(133,22,'Thomas Hensley'),(134,15,'Juan Bates'),(135,27,'Keith Thompson'),(136,37,'Megan Smith'),(137,8,'Rhonda Little'),(138,2,'Gene Knight'),(139,10,'Luis Gillespie'),(140,25,'Sarah White'),(141,42,'David Thomas'),(142,39,'James Daniel'),(143,13,'Samuel Thompson'),(144,34,'William House'),(145,39,'Lisa Davidson'),(146,29,'Lisa Molina'),(147,20,'Dr. Andrew Collier DDS'),(148,39,'Maria Campbell'),(149,43,'James Griffin'),(150,5,'Drew Thomas'),(151,34,'Joseph Lawrence'),(152,44,'Michelle Ferguson'),(153,8,'Stephanie Jordan'),(154,45,'Christopher Mccall'),(155,15,'Matthew Patton'),(156,15,'Roberto Hill'),(157,24,'David Brown'),(158,38,'Emily Walker'),(159,41,'Andrew Thomas'),(160,15,'Catherine Zavala'),(161,19,'Eric Johnson'),(162,9,'Cory Boone'),(163,16,'Carl Benitez'),(164,31,'Morgan Dickson'),(165,2,'Chris Jones'),(166,16,'Michelle Santos'),(167,14,'Nancy Gross'),(168,40,'Richard Ortiz'),(169,31,'Randall Roberts'),(170,41,'Julia Henry'),(171,4,'Michael Stein'),(172,35,'Larry Smith'),(173,14,'Samantha Russell'),(174,20,'Brian Gutierrez'),(175,16,'Ryan Malone'),(176,34,'James Williams'),(177,17,'Brenda Bennett'),(178,34,'Sarah Torres'),(179,10,'Karen Bowers'),(180,44,'Calvin Mcdonald'),(181,47,'Brittany Griffith'),(182,27,'Brenda Manning'),(183,29,'Jeff Werner'),(184,33,'Brenda Fisher'),(185,24,'Jesus Wright'),(186,43,'Rebecca Jackson'),(187,11,'Stephen Faulkner'),(188,8,'Wendy Burns'),(189,7,'Andrea Aguilar'),(190,19,'Andre Willis'),(191,19,'Robert Rodgers'),(192,20,'Nancy Jones'),(193,9,'Steven Mack'),(194,13,'James Harmon'),(195,37,'Lisa Torres'),(196,8,'Amanda Smith'),(197,44,'Kristi Bender'),(198,47,'Andrea Spencer'),(199,19,'Veronica Jackson'),(200,48,'Miguel Bailey'),(201,14,'Bryan Bryant'),(202,15,'Timothy Williams'),(203,31,'Debra Vang'),(204,32,'Timothy Gray'),(205,6,'Kelly Petersen'),(206,16,'Jennifer Brown'),(207,25,'Nicholas Mccall'),(208,10,'Jennifer Gordon'),(209,19,'Latasha Bruce'),(210,16,'Brittany Lopez'),(211,4,'Lindsey Wall'),(212,23,'Nicole Mitchell'),(213,25,'Patty Montgomery'),(214,20,'Carol Collins'),(215,40,'Tanya Jackson'),(216,25,'Denise Murphy'),(217,46,'David Long'),(218,19,'Christina Lewis'),(219,12,'Scott Brown'),(220,20,'Lisa Patel'),(221,13,'Mark Fisher'),(222,34,'Jerry Smith'),(223,29,'Stephen Fisher'),(224,20,'Lindsey Williamson'),(225,41,'Jessica Winters'),(226,24,'Donna Thompson'),(227,3,'Amber Ray'),(228,18,'Andres Wheeler'),(229,41,'Michelle Hernandez'),(230,13,'Sandra Williams'),(231,33,'Robert Johnson'),(232,20,'Susan Simmons'),(233,15,'Ronald Cantu'),(234,9,'Joshua Adams'),(235,17,'Jacqueline Tran'),(236,40,'Anne Cochran'),(237,7,'Matthew Neal'),(238,46,'Ryan Gardner'),(239,47,'Cathy Davis'),(240,35,'Tracy Wade'),(241,7,'William Yates'),(242,13,'Dan Weaver'),(243,35,'Jeremy Munoz'),(244,8,'Barbara Brooks'),(245,19,'Sarah Hill'),(246,10,'Michael Carter'),(247,35,'Thomas Esparza'),(248,25,'Mr. Glenn Johns'),(249,41,'Jennifer Rodriguez'),(250,12,'Stephanie Skinner'),(251,44,'Anthony Rollins'),(252,17,'Daniel Williams'),(253,36,'Gregory Chan'),(254,32,'Anthony Ruiz'),(255,9,'Michael Moore'),(256,30,'Jose Johnson'),(257,35,'Sarah Lewis'),(258,44,'Michael Miller'),(259,20,'Tabitha Kirk'),(260,20,'Selena Ruiz'),(261,18,'Laura Rivas'),(262,22,'Daniel Grant'),(263,40,'John Lucas Jr.'),(264,27,'Jessica Nelson'),(265,28,'Brian Barnes'),(266,40,'Kevin Mcclain'),(267,1,'Chad Potts'),(268,13,'Anthony Powers'),(269,42,'Tyrone Warren'),(270,42,'Peter Cook'),(271,44,'Daniel Dawson'),(272,27,'Julie Smith'),(273,17,'Michael Thompson'),(274,33,'John Lee'),(275,29,'Jessica Davis'),(276,5,'Troy Cohen'),(277,21,'Virginia English'),(278,47,'Patricia Thomas'),(279,43,'Jessica Bowman'),(280,16,'Andrea Johnson'),(281,4,'Lori Hernandez'),(282,17,'Matthew Walker'),(283,10,'Matthew Medina'),(284,43,'Amy Wall'),(285,47,'Randy Anderson'),(286,11,'Nicole Mills'),(287,29,'Jeremy Gonzalez'),(288,7,'Dennis Solis'),(289,43,'Donald Walker'),(290,34,'Benjamin Davis'),(291,25,'Andrea Swanson'),(292,40,'Dustin Lopez'),(293,44,'Mrs. Megan Wilson'),(294,7,'Jamie Lawrence'),(295,27,'William Wallace'),(296,34,'Danielle Lee'),(297,4,'Brittany Jarvis'),(298,21,'Diana Rivera'),(299,19,'Anne Anderson'),(300,45,'Justin Harmon');
/*!40000 ALTER TABLE `profesional` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `socialaccount_socialaccount`
--

DROP TABLE IF EXISTS `socialaccount_socialaccount`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `socialaccount_socialaccount` (
  `id` int NOT NULL AUTO_INCREMENT,
  `provider` varchar(200) NOT NULL,
  `uid` varchar(191) NOT NULL,
  `last_login` datetime(6) NOT NULL,
  `date_joined` datetime(6) NOT NULL,
  `extra_data` json NOT NULL,
  `user_id` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `socialaccount_socialaccount_provider_uid_fc810c6e_uniq` (`provider`,`uid`),
  KEY `socialaccount_socialaccount_user_id_8146e70c_fk_auth_user_id` (`user_id`),
  CONSTRAINT `socialaccount_socialaccount_user_id_8146e70c_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `socialaccount_socialaccount`
--

LOCK TABLES `socialaccount_socialaccount` WRITE;
/*!40000 ALTER TABLE `socialaccount_socialaccount` DISABLE KEYS */;
/*!40000 ALTER TABLE `socialaccount_socialaccount` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `socialaccount_socialapp`
--

DROP TABLE IF EXISTS `socialaccount_socialapp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `socialaccount_socialapp` (
  `id` int NOT NULL AUTO_INCREMENT,
  `provider` varchar(30) NOT NULL,
  `name` varchar(40) NOT NULL,
  `client_id` varchar(191) NOT NULL,
  `secret` varchar(191) NOT NULL,
  `key` varchar(191) NOT NULL,
  `provider_id` varchar(200) NOT NULL,
  `settings` json NOT NULL DEFAULT (_utf8mb4'{}'),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `socialaccount_socialapp`
--

LOCK TABLES `socialaccount_socialapp` WRITE;
/*!40000 ALTER TABLE `socialaccount_socialapp` DISABLE KEYS */;
/*!40000 ALTER TABLE `socialaccount_socialapp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `socialaccount_socialapp_sites`
--

DROP TABLE IF EXISTS `socialaccount_socialapp_sites`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `socialaccount_socialapp_sites` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `socialapp_id` int NOT NULL,
  `site_id` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `socialaccount_socialapp_sites_socialapp_id_site_id_71a9a768_uniq` (`socialapp_id`,`site_id`),
  KEY `socialaccount_socialapp_sites_site_id_2579dee5_fk_django_site_id` (`site_id`),
  CONSTRAINT `socialaccount_social_socialapp_id_97fb6e7d_fk_socialacc` FOREIGN KEY (`socialapp_id`) REFERENCES `socialaccount_socialapp` (`id`),
  CONSTRAINT `socialaccount_socialapp_sites_site_id_2579dee5_fk_django_site_id` FOREIGN KEY (`site_id`) REFERENCES `django_site` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `socialaccount_socialapp_sites`
--

LOCK TABLES `socialaccount_socialapp_sites` WRITE;
/*!40000 ALTER TABLE `socialaccount_socialapp_sites` DISABLE KEYS */;
/*!40000 ALTER TABLE `socialaccount_socialapp_sites` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `socialaccount_socialtoken`
--

DROP TABLE IF EXISTS `socialaccount_socialtoken`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `socialaccount_socialtoken` (
  `id` int NOT NULL AUTO_INCREMENT,
  `token` longtext NOT NULL,
  `token_secret` longtext NOT NULL,
  `expires_at` datetime(6) DEFAULT NULL,
  `account_id` int NOT NULL,
  `app_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `socialaccount_socialtoken_app_id_account_id_fca4e0ac_uniq` (`app_id`,`account_id`),
  KEY `socialaccount_social_account_id_951f210e_fk_socialacc` (`account_id`),
  CONSTRAINT `socialaccount_social_account_id_951f210e_fk_socialacc` FOREIGN KEY (`account_id`) REFERENCES `socialaccount_socialaccount` (`id`),
  CONSTRAINT `socialaccount_social_app_id_636a42d7_fk_socialacc` FOREIGN KEY (`app_id`) REFERENCES `socialaccount_socialapp` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `socialaccount_socialtoken`
--

LOCK TABLES `socialaccount_socialtoken` WRITE;
/*!40000 ALTER TABLE `socialaccount_socialtoken` DISABLE KEYS */;
/*!40000 ALTER TABLE `socialaccount_socialtoken` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tipo_usuario`
--

DROP TABLE IF EXISTS `tipo_usuario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tipo_usuario` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `nombre` varchar(50) NOT NULL,
  `descripcion` longtext NOT NULL,
  `activo` tinyint(1) NOT NULL,
  `fecha_creacion` datetime(6) NOT NULL,
  `fecha_modificacion` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `nombre` (`nombre`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tipo_usuario`
--

LOCK TABLES `tipo_usuario` WRITE;
/*!40000 ALTER TABLE `tipo_usuario` DISABLE KEYS */;
INSERT INTO `tipo_usuario` VALUES (1,'Administrador','Acceso completo al sistema. Puede gestionar usuarios, configurar sistema, ver todos los pasillos, administrar agendas y generar reportes de todos los datos.',1,'2025-08-17 06:19:28.697000','2025-08-17 07:25:42.319000'),(2,'Personal Médico','Acceso médico limitado a su pasillo asignado. Puede ver visualizaciones y generar reportes solo de su pasillo. Puede consultar agendas pero no administrarlas.',1,'2025-08-17 06:19:28.707000','2025-08-17 07:25:42.329000'),(3,'Personal Administrativo','Acceso administrativo completo. Puede ver todos los pasillos, administrar todas las agendas y generar reportes de todos los datos. No puede gestionar usuarios ni configurar sistema.',1,'2025-08-17 06:19:28.710000','2025-08-17 07:25:42.326000'),(4,'Visitante','Acceso limitado de solo lectura. Puede visualizar información básica de boxes.',1,'2025-08-17 06:19:28.711000','2025-08-17 06:19:28.711000');
/*!40000 ALTER TABLE `tipo_usuario` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tipoagenda`
--

DROP TABLE IF EXISTS `tipoagenda`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tipoagenda` (
  `idTipoAgenda` int NOT NULL AUTO_INCREMENT,
  `tipoAgenda` varchar(100) NOT NULL,
  PRIMARY KEY (`idTipoAgenda`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tipoagenda`
--

LOCK TABLES `tipoagenda` WRITE;
/*!40000 ALTER TABLE `tipoagenda` DISABLE KEYS */;
INSERT INTO `tipoagenda` VALUES (1,'Hora médica'),(2,'Hora no médica'),(3,'Limpieza'),(4,'Deshabilitado'),(5,'Mantención técnica'),(6,'Capacitación'),(7,'Reunión clínica'),(8,'Bloqueado por gestión'),(9,'Bloqueo administrativo'),(10,'Reservado para urgencias');
/*!40000 ALTER TABLE `tipoagenda` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping events for database 'bdhospital'
--

--
-- Dumping routines for database 'bdhospital'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-09-24 21:34:48
