-- MySQL dump 10.13  Distrib 8.0.41, for Win64 (x86_64)
--
-- Host: localhost    Database: bdhospital
-- ------------------------------------------------------
-- Server version	8.0.41

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
INSERT INTO `agenda` VALUES (1,1,91,49,'2025-07-02','08:00:00','17:30:00'),(2,1,91,11,'2025-07-02','05:00:00','17:30:00'),(3,1,91,49,'2025-07-04','13:30:00','16:00:00'),(4,1,30,8,'2025-07-04','14:57:00','17:30:00');
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
) ENGINE=InnoDB AUTO_INCREMENT=89 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_permission`
--

LOCK TABLES `auth_permission` WRITE;
/*!40000 ALTER TABLE `auth_permission` DISABLE KEYS */;
INSERT INTO `auth_permission` VALUES (1,'Can add log entry',1,'add_logentry'),(2,'Can change log entry',1,'change_logentry'),(3,'Can delete log entry',1,'delete_logentry'),(4,'Can view log entry',1,'view_logentry'),(5,'Can add permission',2,'add_permission'),(6,'Can change permission',2,'change_permission'),(7,'Can delete permission',2,'delete_permission'),(8,'Can view permission',2,'view_permission'),(9,'Can add group',3,'add_group'),(10,'Can change group',3,'change_group'),(11,'Can delete group',3,'delete_group'),(12,'Can view group',3,'view_group'),(13,'Can add user',4,'add_user'),(14,'Can change user',4,'change_user'),(15,'Can delete user',4,'delete_user'),(16,'Can view user',4,'view_user'),(17,'Can add content type',5,'add_contenttype'),(18,'Can change content type',5,'change_contenttype'),(19,'Can delete content type',5,'delete_contenttype'),(20,'Can view content type',5,'view_contenttype'),(21,'Can add session',6,'add_session'),(22,'Can change session',6,'change_session'),(23,'Can delete session',6,'delete_session'),(24,'Can view session',6,'view_session'),(25,'Can add agenda',7,'add_agenda'),(26,'Can change agenda',7,'change_agenda'),(27,'Can delete agenda',7,'delete_agenda'),(28,'Can view agenda',7,'view_agenda'),(29,'Can add auth group',8,'add_authgroup'),(30,'Can change auth group',8,'change_authgroup'),(31,'Can delete auth group',8,'delete_authgroup'),(32,'Can view auth group',8,'view_authgroup'),(33,'Can add auth group permissions',9,'add_authgrouppermissions'),(34,'Can change auth group permissions',9,'change_authgrouppermissions'),(35,'Can delete auth group permissions',9,'delete_authgrouppermissions'),(36,'Can view auth group permissions',9,'view_authgrouppermissions'),(37,'Can add auth permission',10,'add_authpermission'),(38,'Can change auth permission',10,'change_authpermission'),(39,'Can delete auth permission',10,'delete_authpermission'),(40,'Can view auth permission',10,'view_authpermission'),(41,'Can add auth user',11,'add_authuser'),(42,'Can change auth user',11,'change_authuser'),(43,'Can delete auth user',11,'delete_authuser'),(44,'Can view auth user',11,'view_authuser'),(45,'Can add auth user groups',12,'add_authusergroups'),(46,'Can change auth user groups',12,'change_authusergroups'),(47,'Can delete auth user groups',12,'delete_authusergroups'),(48,'Can view auth user groups',12,'view_authusergroups'),(49,'Can add auth user user permissions',13,'add_authuseruserpermissions'),(50,'Can change auth user user permissions',13,'change_authuseruserpermissions'),(51,'Can delete auth user user permissions',13,'delete_authuseruserpermissions'),(52,'Can view auth user user permissions',13,'view_authuseruserpermissions'),(53,'Can add box',14,'add_box'),(54,'Can change box',14,'change_box'),(55,'Can delete box',14,'delete_box'),(56,'Can view box',14,'view_box'),(57,'Can add django admin log',15,'add_djangoadminlog'),(58,'Can change django admin log',15,'change_djangoadminlog'),(59,'Can delete django admin log',15,'delete_djangoadminlog'),(60,'Can view django admin log',15,'view_djangoadminlog'),(61,'Can add django content type',16,'add_djangocontenttype'),(62,'Can change django content type',16,'change_djangocontenttype'),(63,'Can delete django content type',16,'delete_djangocontenttype'),(64,'Can view django content type',16,'view_djangocontenttype'),(65,'Can add django migrations',17,'add_djangomigrations'),(66,'Can change django migrations',17,'change_djangomigrations'),(67,'Can delete django migrations',17,'delete_djangomigrations'),(68,'Can view django migrations',17,'view_djangomigrations'),(69,'Can add django session',18,'add_djangosession'),(70,'Can change django session',18,'change_djangosession'),(71,'Can delete django session',18,'delete_djangosession'),(72,'Can view django session',18,'view_djangosession'),(73,'Can add especialidad',19,'add_especialidad'),(74,'Can change especialidad',19,'change_especialidad'),(75,'Can delete especialidad',19,'delete_especialidad'),(76,'Can view especialidad',19,'view_especialidad'),(77,'Can add pasillo',20,'add_pasillo'),(78,'Can change pasillo',20,'change_pasillo'),(79,'Can delete pasillo',20,'delete_pasillo'),(80,'Can view pasillo',20,'view_pasillo'),(81,'Can add profesional',21,'add_profesional'),(82,'Can change profesional',21,'change_profesional'),(83,'Can delete profesional',21,'delete_profesional'),(84,'Can view profesional',21,'view_profesional'),(85,'Can add tipoagenda',22,'add_tipoagenda'),(86,'Can change tipoagenda',22,'change_tipoagenda'),(87,'Can delete tipoagenda',22,'delete_tipoagenda'),(88,'Can view tipoagenda',22,'view_tipoagenda');
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_user`
--

LOCK TABLES `auth_user` WRITE;
/*!40000 ALTER TABLE `auth_user` DISABLE KEYS */;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `django_admin_log`
--

LOCK TABLES `django_admin_log` WRITE;
/*!40000 ALTER TABLE `django_admin_log` DISABLE KEYS */;
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
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `django_content_type`
--

LOCK TABLES `django_content_type` WRITE;
/*!40000 ALTER TABLE `django_content_type` DISABLE KEYS */;
INSERT INTO `django_content_type` VALUES (1,'admin','logentry'),(3,'auth','group'),(2,'auth','permission'),(4,'auth','user'),(5,'contenttypes','contenttype'),(6,'sessions','session'),(7,'visualizacionBoxes','agenda'),(8,'visualizacionBoxes','authgroup'),(9,'visualizacionBoxes','authgrouppermissions'),(10,'visualizacionBoxes','authpermission'),(11,'visualizacionBoxes','authuser'),(12,'visualizacionBoxes','authusergroups'),(13,'visualizacionBoxes','authuseruserpermissions'),(14,'visualizacionBoxes','box'),(15,'visualizacionBoxes','djangoadminlog'),(16,'visualizacionBoxes','djangocontenttype'),(17,'visualizacionBoxes','djangomigrations'),(18,'visualizacionBoxes','djangosession'),(19,'visualizacionBoxes','especialidad'),(20,'visualizacionBoxes','pasillo'),(21,'visualizacionBoxes','profesional'),(22,'visualizacionBoxes','tipoagenda');
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
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `django_migrations`
--

LOCK TABLES `django_migrations` WRITE;
/*!40000 ALTER TABLE `django_migrations` DISABLE KEYS */;
INSERT INTO `django_migrations` VALUES (1,'contenttypes','0001_initial','2025-07-02 04:50:59.245168'),(2,'auth','0001_initial','2025-07-02 04:50:59.781858'),(3,'admin','0001_initial','2025-07-02 04:50:59.904997'),(4,'admin','0002_logentry_remove_auto_add','2025-07-02 04:50:59.911711'),(5,'admin','0003_logentry_add_action_flag_choices','2025-07-02 04:50:59.918711'),(6,'contenttypes','0002_remove_content_type_name','2025-07-02 04:51:00.028669'),(7,'auth','0002_alter_permission_name_max_length','2025-07-02 04:51:00.082497'),(8,'auth','0003_alter_user_email_max_length','2025-07-02 04:51:00.104852'),(9,'auth','0004_alter_user_username_opts','2025-07-02 04:51:00.112277'),(10,'auth','0005_alter_user_last_login_null','2025-07-02 04:51:00.158993'),(11,'auth','0006_require_contenttypes_0002','2025-07-02 04:51:00.165714'),(12,'auth','0007_alter_validators_add_error_messages','2025-07-02 04:51:00.173028'),(13,'auth','0008_alter_user_username_max_length','2025-07-02 04:51:00.235059'),(14,'auth','0009_alter_user_last_name_max_length','2025-07-02 04:51:00.296437'),(15,'auth','0010_alter_group_name_max_length','2025-07-02 04:51:00.313336'),(16,'auth','0011_update_proxy_permissions','2025-07-02 04:51:00.319299'),(17,'auth','0012_alter_user_first_name_max_length','2025-07-02 04:51:00.384952'),(18,'sessions','0001_initial','2025-07-02 04:51:00.416513');
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
/*!40000 ALTER TABLE `django_session` ENABLE KEYS */;
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
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-07-23  0:26:15
