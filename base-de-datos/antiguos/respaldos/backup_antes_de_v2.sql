-- MariaDB dump 10.19  Distrib 10.4.32-MariaDB, for Win64 (AMD64)
--
-- Host: localhost    Database: elecciones_unp
-- ------------------------------------------------------
-- Server version	10.4.32-MariaDB

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
-- Table structure for table `acta_electoral`
--

DROP TABLE IF EXISTS `acta_electoral`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `acta_electoral` (
  `id_acta` int(11) NOT NULL AUTO_INCREMENT,
  `id_mesa` int(11) NOT NULL,
  `tipo` enum('INSTALACION','SUFRAGIO','ESCRUTINIO') NOT NULL,
  `contenido_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`contenido_json`)),
  `hash_integridad` char(64) NOT NULL,
  `token_qr_hash` char(64) NOT NULL,
  `fecha_emision` datetime NOT NULL DEFAULT current_timestamp(),
  `estado` enum('VIGENTE','ANULADA') NOT NULL DEFAULT 'VIGENTE',
  PRIMARY KEY (`id_acta`),
  UNIQUE KEY `token_qr_hash` (`token_qr_hash`),
  UNIQUE KEY `uq_acta_mesa_tipo` (`id_mesa`,`tipo`),
  CONSTRAINT `fk_acta_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `acta_electoral`
--

LOCK TABLES `acta_electoral` WRITE;
/*!40000 ALTER TABLE `acta_electoral` DISABLE KEYS */;
/*!40000 ALTER TABLE `acta_electoral` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `candidato`
--

DROP TABLE IF EXISTS `candidato`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `candidato` (
  `id_candidato` int(11) NOT NULL AUTO_INCREMENT,
  `id_lista` int(11) NOT NULL,
  `id_docente` int(11) NOT NULL,
  `rol_en_lista` varchar(100) NOT NULL,
  `estado_validacion` enum('PENDIENTE','APROBADO','OBSERVADO','EXCLUIDO') NOT NULL DEFAULT 'PENDIENTE',
  `fecha_inscripcion` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_candidato`),
  UNIQUE KEY `uq_candidato_lista_docente` (`id_lista`,`id_docente`),
  KEY `fk_candidato_docente` (`id_docente`),
  CONSTRAINT `fk_candidato_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`),
  CONSTRAINT `fk_candidato_lista` FOREIGN KEY (`id_lista`) REFERENCES `lista_electoral` (`id_lista`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `candidato`
--

LOCK TABLES `candidato` WRITE;
/*!40000 ALTER TABLE `candidato` DISABLE KEYS */;
/*!40000 ALTER TABLE `candidato` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cargo_admin`
--

DROP TABLE IF EXISTS `cargo_admin`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cargo_admin` (
  `id_cargo_admin` int(11) NOT NULL AUTO_INCREMENT,
  `id_docente` int(11) NOT NULL,
  `nombre_cargo` varchar(150) NOT NULL,
  `nivel` varchar(80) NOT NULL,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date DEFAULT NULL,
  `vigente` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id_cargo_admin`),
  KEY `fk_cargo_admin_docente` (`id_docente`),
  CONSTRAINT `fk_cargo_admin_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cargo_admin`
--

LOCK TABLES `cargo_admin` WRITE;
/*!40000 ALTER TABLE `cargo_admin` DISABLE KEYS */;
/*!40000 ALTER TABLE `cargo_admin` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cargo_categoria_permitida`
--

DROP TABLE IF EXISTS `cargo_categoria_permitida`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cargo_categoria_permitida` (
  `id_cargo` int(11) NOT NULL,
  `categoria` enum('PRINCIPAL','ASOCIADO','AUXILIAR') NOT NULL,
  PRIMARY KEY (`id_cargo`,`categoria`),
  CONSTRAINT `fk_categoria_cargo` FOREIGN KEY (`id_cargo`) REFERENCES `cargo_electoral` (`id_cargo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cargo_categoria_permitida`
--

LOCK TABLES `cargo_categoria_permitida` WRITE;
/*!40000 ALTER TABLE `cargo_categoria_permitida` DISABLE KEYS */;
/*!40000 ALTER TABLE `cargo_categoria_permitida` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cargo_electoral`
--

DROP TABLE IF EXISTS `cargo_electoral`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cargo_electoral` (
  `id_cargo` int(11) NOT NULL AUTO_INCREMENT,
  `id_proceso` int(11) NOT NULL,
  `nombre` varchar(150) NOT NULL,
  `nivel_jurisdiccion` enum('UNIVERSIDAD','FACULTAD','DEPARTAMENTO') NOT NULL,
  `id_jurisdiccion` int(11) DEFAULT NULL,
  PRIMARY KEY (`id_cargo`),
  KEY `fk_cargo_proceso` (`id_proceso`),
  CONSTRAINT `fk_cargo_proceso` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cargo_electoral`
--

LOCK TABLES `cargo_electoral` WRITE;
/*!40000 ALTER TABLE `cargo_electoral` DISABLE KEYS */;
/*!40000 ALTER TABLE `cargo_electoral` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cargo_excluido_sorteo`
--

DROP TABLE IF EXISTS `cargo_excluido_sorteo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cargo_excluido_sorteo` (
  `id_cargo_excluido` int(11) NOT NULL AUTO_INCREMENT,
  `nombre_cargo` varchar(150) NOT NULL,
  `nivel` varchar(80) NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id_cargo_excluido`),
  UNIQUE KEY `nombre_cargo` (`nombre_cargo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cargo_excluido_sorteo`
--

LOCK TABLES `cargo_excluido_sorteo` WRITE;
/*!40000 ALTER TABLE `cargo_excluido_sorteo` DISABLE KEYS */;
/*!40000 ALTER TABLE `cargo_excluido_sorteo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `constancia_voto`
--

DROP TABLE IF EXISTS `constancia_voto`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `constancia_voto` (
  `id_constancia` bigint(20) NOT NULL AUTO_INCREMENT,
  `id_proceso` int(11) NOT NULL,
  `id_docente` int(11) NOT NULL,
  `id_cargo` int(11) NOT NULL,
  `token_qr_hash` char(64) NOT NULL,
  `fecha_emision` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_expiracion` datetime DEFAULT NULL,
  `estado` enum('VIGENTE','REVOCADA') NOT NULL DEFAULT 'VIGENTE',
  PRIMARY KEY (`id_constancia`),
  UNIQUE KEY `token_qr_hash` (`token_qr_hash`),
  UNIQUE KEY `uq_constancia_participacion` (`id_proceso`,`id_docente`,`id_cargo`),
  KEY `fk_constancia_docente` (`id_docente`),
  KEY `fk_constancia_cargo` (`id_cargo`),
  CONSTRAINT `fk_constancia_cargo` FOREIGN KEY (`id_cargo`) REFERENCES `cargo_electoral` (`id_cargo`),
  CONSTRAINT `fk_constancia_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`),
  CONSTRAINT `fk_constancia_proceso` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `constancia_voto`
--

LOCK TABLES `constancia_voto` WRITE;
/*!40000 ALTER TABLE `constancia_voto` DISABLE KEYS */;
/*!40000 ALTER TABLE `constancia_voto` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `departamento`
--

DROP TABLE IF EXISTS `departamento`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `departamento` (
  `id_departamento` int(11) NOT NULL AUTO_INCREMENT,
  `id_facultad` int(11) NOT NULL,
  `nombre` varchar(255) NOT NULL,
  PRIMARY KEY (`id_departamento`),
  UNIQUE KEY `uq_departamento_facultad` (`id_facultad`,`nombre`),
  CONSTRAINT `fk_departamento_facultad` FOREIGN KEY (`id_facultad`) REFERENCES `facultad` (`id_facultad`)
) ENGINE=InnoDB AUTO_INCREMENT=55 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `departamento`
--

LOCK TABLES `departamento` WRITE;
/*!40000 ALTER TABLE `departamento` DISABLE KEYS */;
INSERT INTO `departamento` VALUES (1,1,'Agronomía y Fitotecnia'),(2,1,'Ingeniería Agrícola'),(5,1,'Morfofisiología Vegetal'),(3,1,'Sanidad Vegetal'),(4,1,'Suelos'),(6,2,'Arquitectura y Urbanismo'),(46,3,'Administración Aplicada'),(42,3,'Administración General'),(10,3,'Ciencias Biológicas'),(49,3,'Ciencias de la Comunicación'),(44,3,'Clínico Quirúrgico'),(50,3,'Contabilidad Aplicada'),(43,3,'Contabilidad General'),(45,3,'Educación'),(51,3,'Enfermería'),(9,3,'Estadística'),(47,3,'Finanzas, Tributación y Auditoría'),(8,3,'Física'),(52,3,'Humanidades'),(11,3,'Ingeniería Electrónica y Telecomunicaciones'),(7,3,'Matemática'),(54,3,'Materno Infantil'),(53,3,'Morfofisiología Humana'),(48,3,'Salud Pública'),(13,4,'Administración Aplicada'),(12,4,'Administración General'),(15,5,'Contabilidad Aplicada'),(14,5,'Contabilidad General'),(16,5,'Finanzas, Tributación y Auditoría'),(19,6,'Clínico Quirúrgico'),(21,6,'Enfermería'),(17,6,'Materno Infantil'),(18,6,'Morfofisiología Humana'),(20,6,'Salud Pública'),(23,7,'Ciencias de la Comunicación'),(22,7,'Educación'),(24,7,'Humanidades'),(26,8,'Ciencias Políticas'),(25,8,'Derecho'),(27,9,'Economía'),(28,10,'Ingeniería Civil'),(33,11,'Ingeniería Ambiental y Seguridad Industrial'),(29,11,'Ingeniería de Minas'),(30,11,'Ingeniería de Petróleo'),(31,11,'Ingeniería Geológica'),(32,11,'Ingeniería Química'),(36,12,'Agroindustria e Industrias Alimentarias'),(34,12,'Ingeniería Industrial'),(35,12,'Ingeniería Informática'),(38,12,'Ingeniería Mecatrónica'),(37,12,'Investigación de Operaciones'),(39,13,'Ingeniería Pesquera'),(40,14,'Producción Animal'),(41,14,'Salud Animal');
/*!40000 ALTER TABLE `departamento` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `docente`
--

DROP TABLE IF EXISTS `docente`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `docente` (
  `id_docente` int(11) NOT NULL AUTO_INCREMENT,
  `dni` varchar(8) NOT NULL,
  `nombres` varchar(100) NOT NULL,
  `apellidos` varchar(150) NOT NULL,
  `categoria` enum('PRINCIPAL','ASOCIADO','AUXILIAR') NOT NULL,
  `dedicacion` varchar(80) NOT NULL,
  `estado` enum('ACTIVO','LICENCIA','SUSPENDIDO') NOT NULL DEFAULT 'ACTIVO',
  `id_facultad` int(11) NOT NULL,
  `id_departamento` int(11) NOT NULL,
  `habilitado_para_votar` bit(1) NOT NULL,
  PRIMARY KEY (`id_docente`),
  UNIQUE KEY `dni` (`dni`),
  KEY `fk_docente_facultad` (`id_facultad`),
  KEY `fk_docente_departamento` (`id_departamento`),
  CONSTRAINT `fk_docente_departamento` FOREIGN KEY (`id_departamento`) REFERENCES `departamento` (`id_departamento`),
  CONSTRAINT `fk_docente_facultad` FOREIGN KEY (`id_facultad`) REFERENCES `facultad` (`id_facultad`)
) ENGINE=InnoDB AUTO_INCREMENT=293 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `docente`
--

LOCK TABLES `docente` WRITE;
/*!40000 ALTER TABLE `docente` DISABLE KEYS */;
INSERT INTO `docente` VALUES (191,'03681001','Juan Carlos','Mendoza Pérez','PRINCIPAL','DE','ACTIVO',12,35,'\0'),(192,'03681002','María Elena','Ruiz Delgado','ASOCIADO','TC','LICENCIA',3,7,'\0'),(193,'03681003','Jorge Luis','Ramos Flores','AUXILIAR','TP','ACTIVO',3,42,'\0'),(194,'03681004','Ana Patricia','Castro Silva','PRINCIPAL','DE','ACTIVO',3,43,'\0'),(195,'03681005','Carlos Alberto','Benítes Juárez','PRINCIPAL','DE','ACTIVO',1,1,'\0'),(196,'03681006','Rosa María','Salazar Vega','ASOCIADO','TC','ACTIVO',3,44,'\0'),(197,'03681007','Pedro José','Morales Prado','AUXILIAR','TP','SUSPENDIDO',11,30,'\0'),(198,'03681008','Luis Fernando','Farfán Zapata','PRINCIPAL','DE','ACTIVO',8,25,'\0'),(199,'03681009','Carmen Rosa','Albán Peña','ASOCIADO','TC','ACTIVO',9,27,'\0'),(200,'03681010','Miguel Ángel','Guerrero Neira','AUXILIAR','TP','ACTIVO',2,6,'\0'),(201,'03681011','Silvia Elizabeth','Vilela Yamunaqué','PRINCIPAL','DE','ACTIVO',10,28,'\0'),(202,'03681012','Ricardo Manuel','Ojeda Dioses','ASOCIADO','TC','ACTIVO',14,40,'\0'),(203,'03681013','Diana Marcela','Calle Calle','AUXILIAR','TP','ACTIVO',13,39,'\0'),(204,'03681014','Victor Hugo','Navarro Sullón','PRINCIPAL','DE','LICENCIA',3,45,'\0'),(205,'03681015','Patricia Janet','Yarlequé Medina','ASOCIADO','TC','ACTIVO',12,34,'\0'),(206,'03681016','Cesar Augusto','Coronado Talledo','AUXILIAR','TP','ACTIVO',3,8,'\0'),(207,'03681017','Gladys Noemí','Ipanaqué Chero','PRINCIPAL','DE','ACTIVO',3,46,'\0'),(208,'03681018','Manuel Jesús','Timaná Vilchez','ASOCIADO','TC','ACTIVO',3,47,'\0'),(209,'03681019','Mónica Isabel','Valladolid Cherres','AUXILIAR','TP','ACTIVO',1,3,'\0'),(210,'03681020','Francisco Javier','Seminario Pasapera','PRINCIPAL','DE','ACTIVO',3,48,'\0'),(211,'03681021','Sofia Beatriz','Chunga Purizaca','ASOCIADO','TC','SUSPENDIDO',11,32,'\0'),(212,'03681022','Gabriel Antonio','Reto Silva','AUXILIAR','TP','ACTIVO',8,26,'\0'),(213,'03681023','Veronica Lucia','Pazos Lazo','PRINCIPAL','DE','ACTIVO',9,27,'\0'),(214,'03681024','Hector Raul','Pulache Cordova','ASOCIADO','TC','ACTIVO',2,6,'\0'),(215,'03681025','Nancy Yolanda','Carhuapoma Yovera','AUXILIAR','TP','ACTIVO',10,28,'\0'),(216,'03681026','Walter Enrique','Zevallos Ramos','PRINCIPAL','DE','ACTIVO',14,41,'\0'),(217,'03681027','Claudia Maria','Palacios Tavara','ASOCIADO','TC','LICENCIA',13,39,'\0'),(218,'03681028','Oscar Eduardo','Saavedra Nole','AUXILIAR','TP','ACTIVO',3,49,'\0'),(219,'03681029','Teresa de Jesus','Gomez Sandoval','PRINCIPAL','DE','ACTIVO',12,37,'\0'),(220,'03681030','Roberto Carlos','Agurto Iman','ASOCIADO','TC','ACTIVO',3,9,'\0'),(221,'03681031','Isabel Cristina','Montero Riofrio','AUXILIAR','TP','ACTIVO',3,42,'\0'),(222,'03681032','Julio Cesar','Fiestas Chunga','PRINCIPAL','DE','ACTIVO',3,50,'\0'),(223,'03681033','Karen Lisseth','Zapata Vilchez','ASOCIADO','TC','ACTIVO',1,4,'\0'),(224,'03681034','Alex Alexander','Sullon Yovera','AUXILIAR','TP','SUSPENDIDO',3,51,'\0'),(225,'03681035','Rosa Elvira','Espinoza Garcia','PRINCIPAL','DE','ACTIVO',11,29,'\0'),(226,'03681036','Marcos Aurelio','Neyra Cruz','ASOCIADO','TC','ACTIVO',8,25,'\0'),(227,'03681037','Lourdes del Pilar','Dioses Morales','AUXILIAR','TP','ACTIVO',9,27,'\0'),(228,'03681038','Aldo Martin','Castillo Cherres','PRINCIPAL','DE','ACTIVO',2,6,'\0'),(229,'03681039','Brenda Vanessa','Rivas Vite','ASOCIADO','TC','ACTIVO',10,28,'\0'),(230,'03681040','Christian Joel','Benites Yarleque','AUXILIAR','TP','LICENCIA',14,40,'\0'),(231,'03681041','Katia Paola','Roman Silva','PRINCIPAL','DE','ACTIVO',13,39,'\0'),(232,'03681042','Daniel Omar','Vilchez Chero','ASOCIADO','TC','ACTIVO',3,52,'\0'),(233,'03681043','Andrea Fabiana','Pacherres Nole','AUXILIAR','TP','ACTIVO',12,36,'\0'),(234,'03681044','Gonzalo Nicolas','Requena Tavara','PRINCIPAL','DE','ACTIVO',3,10,'\0'),(235,'03681045','Yessica Yanet','Sandoval Ipanaque','ASOCIADO','TC','ACTIVO',3,46,'\0'),(236,'03681046','Ruben Dario','Cordova Purizaca','AUXILIAR','TP','ACTIVO',3,43,'\0'),(237,'03681047','Cecilia Ines','Prado Valladares','PRINCIPAL','DE','ACTIVO',1,2,'\0'),(238,'03681048','Edwin David','Garcia Palacios','ASOCIADO','TC','SUSPENDIDO',3,53,'\0'),(239,'03681049','Giannina Maria','Talledo Saavedra','AUXILIAR','TP','ACTIVO',11,31,'\0'),(240,'03681050','Raul Enrique','Vilela Chunga','PRINCIPAL','DE','ACTIVO',8,25,'\0'),(241,'03681051','Fiorella Lizbeth','Cruz Ramos','ASOCIADO','TC','ACTIVO',9,27,'\0'),(242,'03681052','Hernan Alonso','Morales Yovera','AUXILIAR','TP','ACTIVO',2,6,'\0'),(243,'03681053','Giuliana Mercedes','Alba Chunga','PRINCIPAL','DE','LICENCIA',10,28,'\0'),(244,'03681054','Guillermo Andres','Nole Farfan','ASOCIADO','TC','ACTIVO',14,41,'\0'),(245,'03681055','Wendy Katherine','Purizaca Cherres','AUXILIAR','TP','ACTIVO',13,39,'\0'),(246,'03681056','Renato Stephano','Yamunaque Silva','PRINCIPAL','DE','ACTIVO',3,45,'\0'),(247,'03681057','Roxana Elizabeth','Tavara Pasapera','ASOCIADO','TC','ACTIVO',12,38,'\0'),(248,'03681058','Sergio Mateo','Chero Ipanaque','AUXILIAR','TP','ACTIVO',3,11,'\0'),(249,'03681059','Tatiana Soledad','Purizaca Sullon','PRINCIPAL','DE','ACTIVO',3,42,'\0'),(250,'03681060','Williams Steve','Vilchez Yarleque','ASOCIADO','TC','ACTIVO',3,47,'\0'),(251,'03681061','Zoila Marina','Chunga Dioses','AUXILIAR','TP','ACTIVO',1,5,'\0'),(252,'03681062','Alvaro Rodrigo','Morales Sullon','PRINCIPAL','DE','SUSPENDIDO',3,54,'\0'),(253,'03681063','Beatriz Alexandra','Farfan Nole','ASOCIADO','TC','ACTIVO',11,33,'\0'),(254,'03681064','Claudio Fernando','Yovera Purizaca','AUXILIAR','TP','ACTIVO',8,26,'\0'),(255,'03681065','Dora Alicia','Cherres Silva','PRINCIPAL','DE','ACTIVO',9,27,'\0'),(256,'03681066','Eduardo Felipe','Silva Yamunaque','ASOCIADO','TC','ACTIVO',2,6,'\0'),(257,'03681067','Fanny del Socorro','Sullon Chero','AUXILIAR','TP','ACTIVO',10,28,'\0'),(258,'03681068','Gustavo Adolfo','Ipanaque Yarleque','PRINCIPAL','DE','LICENCIA',14,40,'\0'),(259,'03681069','Helga Mariela','Pasapera Tavara','ASOCIADO','TC','ACTIVO',13,39,'\0'),(260,'03681070','Ivan Danelgi','Iman Agurto','PRINCIPAL','DE','ACTIVO',12,35,'\0'),(261,'03681071','Jean Carlos','Lucano Zurita','ASOCIADO','TC','ACTIVO',12,35,'\0'),(262,'03681072','Jeremy Aaron','Suárez Taboada','AUXILIAR','TP','ACTIVO',12,35,'\0'),(263,'03681073','Leandro Emmanuel','Peña Ávila','AUXILIAR','TP','ACTIVO',12,35,'\0'),(264,'03681074','Karina Elizabeth','Dioses Purizaca','PRINCIPAL','DE','ACTIVO',3,7,'\0'),(265,'03681075','Luis Alberto','Yarleque Sullon','ASOCIADO','TC','ACTIVO',3,8,'\0'),(266,'03681076','Martha Elena','Chero Yovera','AUXILIAR','TP','ACTIVO',3,9,'\0'),(267,'03681077','Nestor Daniel','Silva Cherres','PRINCIPAL','DE','ACTIVO',3,10,'\0'),(268,'03681078','Olga Lidia','Yamunaque Pasapera','ASOCIADO','TC','SUSPENDIDO',3,11,'\0'),(269,'03681079','Pablo Antonio','Tavara Chero','AUXILIAR','TP','ACTIVO',3,42,'\0'),(270,'03681080','Rosa Isabel','Sullon Ipanaque','PRINCIPAL','DE','ACTIVO',3,46,'\0'),(271,'03681081','Samuel Eduardo','Yovera Silva','ASOCIADO','TC','ACTIVO',3,43,'\0'),(272,'03681082','Tania Maria','Cherres Yamunaque','AUXILIAR','TP','ACTIVO',3,50,'\0'),(273,'03681083','Ulises Omar','Pasapera Tavara','PRINCIPAL','DE','ACTIVO',3,47,'\0'),(274,'03681084','Vanessa Lisset','Chero Sullon','ASOCIADO','TC','LICENCIA',1,1,'\0'),(275,'03681085','Walter Javier','Ipanaque Yovera','AUXILIAR','TP','ACTIVO',1,2,'\0'),(276,'03681086','Xavier Hernan','Silva Cherres','PRINCIPAL','DE','ACTIVO',1,3,'\0'),(277,'03681087','Yenny Patricia','Yamunaque Tavara','ASOCIADO','TC','ACTIVO',1,4,'\0'),(278,'03681088','Zoraida Beatri','Tavara Sullon','AUXILIAR','TP','ACTIVO',1,5,'\0'),(279,'03681089','Armando Jose','Chero Pasapera','PRINCIPAL','DE','ACTIVO',3,54,'\0'),(280,'03681090','Blanca Rosa','Ipanaque Tavara','ASOCIADO','TC','ACTIVO',3,53,'\0'),(281,'03681091','Carlos Enrique','Yovera Chero','AUXILIAR','TP','ACTIVO',3,44,'\0'),(282,'03681092','Doris Maria','Cherres Ipanaque','PRINCIPAL','DE','SUSPENDIDO',3,48,'\0'),(283,'03681093','Ernesto Luis','Silva Yovera','ASOCIADO','TC','ACTIVO',3,51,'\0'),(284,'03681094','Fatima Soledad','Yamunaque Cherres','AUXILIAR','TP','ACTIVO',11,29,'\0'),(285,'03681095','Guillermo Jose','Tavara Silva','PRINCIPAL','DE','ACTIVO',11,30,'\0'),(286,'03681096','Hilda Elizabeth','Sullon Yamunaque','ASOCIADO','TC','ACTIVO',11,31,'\0'),(287,'03681097','Ivan Marcelino','Pasapera Chero','AUXILIAR','TP','ACTIVO',11,32,'\0'),(288,'03681098','Judith Noemi','Chero Ipanaque','PRINCIPAL','DE','LICENCIA',11,33,'\0'),(289,'03681099','Kevin Joel','Yovera Tavara','ASOCIADO','TC','ACTIVO',8,25,'\0'),(290,'03681100','Laura Beatri','Silva Sullon','AUXILIAR','TP','ACTIVO',8,26,'\0'),(291,'03681111','Laura Beatri','Silva Sullon','AUXILIAR','TP','ACTIVO',8,26,'\0'),(292,'74631812','Pedro Enrique','Sandoval Peña','ASOCIADO','TC','ACTIVO',12,35,'\0');
/*!40000 ALTER TABLE `docente` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `facultad`
--

DROP TABLE IF EXISTS `facultad`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `facultad` (
  `id_facultad` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) NOT NULL,
  PRIMARY KEY (`id_facultad`),
  UNIQUE KEY `nombre` (`nombre`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `facultad`
--

LOCK TABLES `facultad` WRITE;
/*!40000 ALTER TABLE `facultad` DISABLE KEYS */;
INSERT INTO `facultad` VALUES (1,'Facultad de Agronomía'),(2,'Facultad de Arquitectura y Urbanismo'),(3,'Facultad de Ciencias'),(4,'Facultad de Ciencias Administrativas'),(5,'Facultad de Ciencias Contables y Financieras'),(6,'Facultad de Ciencias de la Salud'),(7,'Facultad de Ciencias Sociales y Educación'),(8,'Facultad de Derecho y Ciencias Políticas'),(9,'Facultad de Economía'),(10,'Facultad de Ingeniería Civil'),(11,'Facultad de Ingeniería de Minas'),(12,'Facultad de Ingeniería Industrial'),(13,'Facultad de Ingeniería Pesquera'),(14,'Facultad de Zootecnia');
/*!40000 ALTER TABLE `facultad` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `firma_acta`
--

DROP TABLE IF EXISTS `firma_acta`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `firma_acta` (
  `id_firma` int(11) NOT NULL AUTO_INCREMENT,
  `id_acta` int(11) NOT NULL,
  `id_docente` int(11) NOT NULL,
  `rol` varchar(80) NOT NULL,
  `firma_digital` text DEFAULT NULL,
  `fecha_firma` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_firma`),
  UNIQUE KEY `uq_firma_acta_docente` (`id_acta`,`id_docente`),
  KEY `fk_firma_docente` (`id_docente`),
  CONSTRAINT `fk_firma_acta` FOREIGN KEY (`id_acta`) REFERENCES `acta_electoral` (`id_acta`),
  CONSTRAINT `fk_firma_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `firma_acta`
--

LOCK TABLES `firma_acta` WRITE;
/*!40000 ALTER TABLE `firma_acta` DISABLE KEYS */;
/*!40000 ALTER TABLE `firma_acta` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `impugnacion_electoral`
--

DROP TABLE IF EXISTS `impugnacion_electoral`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `impugnacion_electoral` (
  `id_impugnacion` bigint(20) NOT NULL AUTO_INCREMENT,
  `id_personero` int(11) NOT NULL,
  `id_proceso` int(11) NOT NULL,
  `id_mesa` int(11) NOT NULL,
  `id_acta` int(11) DEFAULT NULL,
  `motivo` text NOT NULL,
  `decision_mesa` enum('PENDIENTE','ACEPTADA','RECHAZADA') NOT NULL DEFAULT 'PENDIENTE',
  `decision_ceunp` enum('PENDIENTE','CONFIRMADA','MODIFICADA') NOT NULL DEFAULT 'PENDIENTE',
  `estado` enum('PRESENTADA','RESUELTA','APELADA') NOT NULL DEFAULT 'PRESENTADA',
  `fecha_presentacion` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_resolucion` datetime DEFAULT NULL,
  PRIMARY KEY (`id_impugnacion`),
  KEY `fk_impugnacion_personero` (`id_personero`),
  KEY `fk_impugnacion_proceso` (`id_proceso`),
  KEY `fk_impugnacion_mesa` (`id_mesa`),
  KEY `fk_impugnacion_acta` (`id_acta`),
  CONSTRAINT `fk_impugnacion_acta` FOREIGN KEY (`id_acta`) REFERENCES `acta_electoral` (`id_acta`),
  CONSTRAINT `fk_impugnacion_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`),
  CONSTRAINT `fk_impugnacion_personero` FOREIGN KEY (`id_personero`) REFERENCES `personero` (`id_personero`),
  CONSTRAINT `fk_impugnacion_proceso` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `impugnacion_electoral`
--

LOCK TABLES `impugnacion_electoral` WRITE;
/*!40000 ALTER TABLE `impugnacion_electoral` DISABLE KEYS */;
/*!40000 ALTER TABLE `impugnacion_electoral` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lista_electoral`
--

DROP TABLE IF EXISTS `lista_electoral`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lista_electoral` (
  `id_lista` int(11) NOT NULL AUTO_INCREMENT,
  `id_cargo` int(11) NOT NULL,
  `nombre` varchar(150) NOT NULL,
  `simbolo` varchar(100) DEFAULT NULL,
  `orden_cedula` int(11) DEFAULT NULL,
  `estado` enum('INSCRITA','ADMITIDA','TACHADA','EXCLUIDA') NOT NULL DEFAULT 'INSCRITA',
  `fecha_inscripcion` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_lista`),
  KEY `fk_lista_cargo` (`id_cargo`),
  CONSTRAINT `fk_lista_cargo` FOREIGN KEY (`id_cargo`) REFERENCES `cargo_electoral` (`id_cargo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lista_electoral`
--

LOCK TABLES `lista_electoral` WRITE;
/*!40000 ALTER TABLE `lista_electoral` DISABLE KEYS */;
/*!40000 ALTER TABLE `lista_electoral` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `log_auditoria`
--

DROP TABLE IF EXISTS `log_auditoria`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `log_auditoria` (
  `id_log` bigint(20) NOT NULL AUTO_INCREMENT,
  `id_usuario` int(11) DEFAULT NULL,
  `id_docente` int(11) DEFAULT NULL,
  `id_proceso` int(11) DEFAULT NULL,
  `accion` varchar(100) NOT NULL,
  `ip_origen` varchar(45) DEFAULT NULL,
  `user_agent` varchar(500) DEFAULT NULL,
  `fecha_hora` datetime NOT NULL DEFAULT current_timestamp(),
  `detalle_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`detalle_json`)),
  PRIMARY KEY (`id_log`),
  KEY `fk_log_usuario` (`id_usuario`),
  KEY `fk_log_docente` (`id_docente`),
  KEY `fk_log_proceso` (`id_proceso`),
  CONSTRAINT `fk_log_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`),
  CONSTRAINT `fk_log_proceso` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`),
  CONSTRAINT `fk_log_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `log_auditoria`
--

LOCK TABLES `log_auditoria` WRITE;
/*!40000 ALTER TABLE `log_auditoria` DISABLE KEYS */;
INSERT INTO `log_auditoria` VALUES (1,5,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36','2026-10-07 22:43:57',NULL),(2,1,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36','2026-10-08 17:29:29',NULL),(3,5,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36','2026-10-08 17:30:14',NULL),(4,1,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36','2026-10-08 17:37:57',NULL),(5,1,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36','2026-10-14 15:15:54',NULL),(6,5,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36','2026-10-14 15:16:56',NULL),(7,1,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36','2026-10-14 15:44:10',NULL),(8,5,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36','2026-10-14 15:55:33',NULL),(9,1,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36','2026-10-14 15:56:15',NULL),(10,5,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36','2026-10-14 15:57:04',NULL),(11,5,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36','2026-10-15 09:15:50',NULL);
/*!40000 ALTER TABLE `log_auditoria` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mesa_electoral`
--

DROP TABLE IF EXISTS `mesa_electoral`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mesa_electoral` (
  `id_mesa` int(11) NOT NULL AUTO_INCREMENT,
  `id_proceso` int(11) NOT NULL,
  `numero_mesa` varchar(30) NOT NULL,
  `ubicacion` varchar(200) NOT NULL,
  `semilla_sorteo` varchar(128) NOT NULL,
  `fecha_sorteo` datetime DEFAULT NULL,
  PRIMARY KEY (`id_mesa`),
  UNIQUE KEY `uq_mesa_proceso_numero` (`id_proceso`,`numero_mesa`),
  CONSTRAINT `fk_mesa_proceso` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mesa_electoral`
--

LOCK TABLES `mesa_electoral` WRITE;
/*!40000 ALTER TABLE `mesa_electoral` DISABLE KEYS */;
/*!40000 ALTER TABLE `mesa_electoral` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mesa_sufragio`
--

DROP TABLE IF EXISTS `mesa_sufragio`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mesa_sufragio` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `estado` enum('ANULADA','CERRADA','INSTALADA','PENDIENTE') NOT NULL,
  `hora_cierre` datetime(6) DEFAULT NULL,
  `hora_instalacion` datetime(6) DEFAULT NULL,
  `numero` varchar(10) NOT NULL,
  `total_electores` int(11) DEFAULT NULL,
  `proceso_id` int(11) NOT NULL,
  `id_proceso` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UK61ir5q4u153ms5p6sctn5kv7o` (`numero`),
  KEY `FK1bf6etm8bi8sxes9s2k6k49y1` (`proceso_id`),
  KEY `FKeun7mw7vyp6j7mlf69rki318c` (`id_proceso`),
  CONSTRAINT `FK1bf6etm8bi8sxes9s2k6k49y1` FOREIGN KEY (`proceso_id`) REFERENCES `proceso_electoral` (`id_proceso`),
  CONSTRAINT `FKeun7mw7vyp6j7mlf69rki318c` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mesa_sufragio`
--

LOCK TABLES `mesa_sufragio` WRITE;
/*!40000 ALTER TABLE `mesa_sufragio` DISABLE KEYS */;
/*!40000 ALTER TABLE `mesa_sufragio` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `miembro_mesa`
--

DROP TABLE IF EXISTS `miembro_mesa`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `miembro_mesa` (
  `id_mesa` int(11) NOT NULL,
  `id_docente` int(11) NOT NULL,
  `rol` enum('PRESIDENTE','SECRETARIO','VOCAL','SUPLENTE') NOT NULL,
  `titular` tinyint(1) NOT NULL DEFAULT 0,
  `asistio` bit(1) DEFAULT NULL,
  `cargo` varchar(20) NOT NULL,
  `condicion` varchar(20) NOT NULL,
  `docente_id` int(11) NOT NULL,
  `mesa_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id_mesa`,`id_docente`),
  KEY `fk_miembro_docente` (`id_docente`),
  KEY `FKdgqlg3cnyf5p8s7hmqjus7j8u` (`docente_id`),
  KEY `FKkwgj3vs7ifup1fa8dp2nuajg5` (`mesa_id`),
  CONSTRAINT `FKdgqlg3cnyf5p8s7hmqjus7j8u` FOREIGN KEY (`docente_id`) REFERENCES `docente` (`id_docente`),
  CONSTRAINT `FKkwgj3vs7ifup1fa8dp2nuajg5` FOREIGN KEY (`mesa_id`) REFERENCES `mesa_sufragio` (`id`),
  CONSTRAINT `fk_miembro_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`),
  CONSTRAINT `fk_miembro_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `miembro_mesa`
--

LOCK TABLES `miembro_mesa` WRITE;
/*!40000 ALTER TABLE `miembro_mesa` DISABLE KEYS */;
/*!40000 ALTER TABLE `miembro_mesa` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `observacion_electoral`
--

DROP TABLE IF EXISTS `observacion_electoral`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `observacion_electoral` (
  `id_observacion` bigint(20) NOT NULL AUTO_INCREMENT,
  `id_personero` int(11) NOT NULL,
  `id_proceso` int(11) NOT NULL,
  `id_mesa` int(11) DEFAULT NULL,
  `id_acta` int(11) DEFAULT NULL,
  `descripcion` text NOT NULL,
  `estado` enum('PENDIENTE','ATENDIDA','RECHAZADA') NOT NULL DEFAULT 'PENDIENTE',
  `respuesta_ceunp` text DEFAULT NULL,
  `fecha_registro` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_respuesta` datetime DEFAULT NULL,
  PRIMARY KEY (`id_observacion`),
  KEY `fk_observacion_personero` (`id_personero`),
  KEY `fk_observacion_proceso` (`id_proceso`),
  KEY `fk_observacion_mesa` (`id_mesa`),
  KEY `fk_observacion_acta` (`id_acta`),
  CONSTRAINT `fk_observacion_acta` FOREIGN KEY (`id_acta`) REFERENCES `acta_electoral` (`id_acta`),
  CONSTRAINT `fk_observacion_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`),
  CONSTRAINT `fk_observacion_personero` FOREIGN KEY (`id_personero`) REFERENCES `personero` (`id_personero`),
  CONSTRAINT `fk_observacion_proceso` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `observacion_electoral`
--

LOCK TABLES `observacion_electoral` WRITE;
/*!40000 ALTER TABLE `observacion_electoral` DISABLE KEYS */;
/*!40000 ALTER TABLE `observacion_electoral` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `padron_electoral`
--

DROP TABLE IF EXISTS `padron_electoral`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `padron_electoral` (
  `id_proceso` int(11) NOT NULL,
  `id_cargo` int(11) NOT NULL,
  `id_docente` int(11) NOT NULL,
  `habilitado_para_votar` tinyint(1) NOT NULL DEFAULT 1,
  `ya_voto` tinyint(1) NOT NULL DEFAULT 0,
  `fecha_votacion` datetime DEFAULT NULL,
  `motivo_inhabilitacion` varchar(255) DEFAULT NULL,
  `fecha_generacion` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_proceso`,`id_cargo`,`id_docente`),
  KEY `fk_padron_cargo` (`id_cargo`),
  KEY `fk_padron_docente` (`id_docente`),
  CONSTRAINT `fk_padron_cargo` FOREIGN KEY (`id_cargo`) REFERENCES `cargo_electoral` (`id_cargo`),
  CONSTRAINT `fk_padron_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`),
  CONSTRAINT `fk_padron_proceso` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `padron_electoral`
--

LOCK TABLES `padron_electoral` WRITE;
/*!40000 ALTER TABLE `padron_electoral` DISABLE KEYS */;
/*!40000 ALTER TABLE `padron_electoral` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `padron_mesa`
--

DROP TABLE IF EXISTS `padron_mesa`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `padron_mesa` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `habilitado` bit(1) DEFAULT NULL,
  `hora_voto` datetime(6) DEFAULT NULL,
  `ya_voto` bit(1) DEFAULT NULL,
  `docente_id` int(11) NOT NULL,
  `mesa_id` bigint(20) NOT NULL,
  `id_docente` int(11) NOT NULL,
  `id_mesa` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `FKaj5kxhye89ik3uhcvjykmglc9` (`docente_id`),
  KEY `FKoye8231yoxjincaxyou0v229i` (`mesa_id`),
  KEY `FKdpcy50hsdqex1x63tnckj4gcc` (`id_docente`),
  CONSTRAINT `FKaj5kxhye89ik3uhcvjykmglc9` FOREIGN KEY (`docente_id`) REFERENCES `docente` (`id_docente`),
  CONSTRAINT `FKdpcy50hsdqex1x63tnckj4gcc` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`),
  CONSTRAINT `FKoye8231yoxjincaxyou0v229i` FOREIGN KEY (`mesa_id`) REFERENCES `mesa_sufragio` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `padron_mesa`
--

LOCK TABLES `padron_mesa` WRITE;
/*!40000 ALTER TABLE `padron_mesa` DISABLE KEYS */;
/*!40000 ALTER TABLE `padron_mesa` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `parametro_global`
--

DROP TABLE IF EXISTS `parametro_global`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `parametro_global` (
  `clave` varchar(80) NOT NULL,
  `descripcion` varchar(500) DEFAULT NULL,
  `valor` varchar(255) NOT NULL,
  PRIMARY KEY (`clave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `parametro_global`
--

LOCK TABLES `parametro_global` WRITE;
/*!40000 ALTER TABLE `parametro_global` DISABLE KEYS */;
INSERT INTO `parametro_global` VALUES ('MULTA_ELECTOR_OMISO_PCT','Porcentaje de multa para electores omisos (% de UIT)','2.5'),('MULTA_MIEMBRO_MESA_OMISO_PCT','Porcentaje de multa para miembros de mesa omisos (% de UIT)','3.0'),('UIT','Unidad Impositiva Tributaria (UIT) vigente en soles','5150.00');
/*!40000 ALTER TABLE `parametro_global` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `personero`
--

DROP TABLE IF EXISTS `personero`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `personero` (
  `id_personero` int(11) NOT NULL AUTO_INCREMENT,
  `id_lista` int(11) NOT NULL,
  `id_docente` int(11) NOT NULL,
  `tipo` enum('GENERAL','ALTERNO','MESA') NOT NULL,
  `id_mesa` int(11) DEFAULT NULL,
  `estado_acreditacion` enum('PENDIENTE','ACREDITADO','REVOCADO') NOT NULL DEFAULT 'PENDIENTE',
  `fecha_acreditacion` datetime DEFAULT NULL,
  PRIMARY KEY (`id_personero`),
  KEY `fk_personero_lista` (`id_lista`),
  KEY `fk_personero_docente` (`id_docente`),
  KEY `fk_personero_mesa` (`id_mesa`),
  CONSTRAINT `fk_personero_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`),
  CONSTRAINT `fk_personero_lista` FOREIGN KEY (`id_lista`) REFERENCES `lista_electoral` (`id_lista`),
  CONSTRAINT `fk_personero_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `personero`
--

LOCK TABLES `personero` WRITE;
/*!40000 ALTER TABLE `personero` DISABLE KEYS */;
/*!40000 ALTER TABLE `personero` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `proceso_electoral`
--

DROP TABLE IF EXISTS `proceso_electoral`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `proceso_electoral` (
  `id_proceso` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(200) NOT NULL,
  `fecha_inicio` datetime NOT NULL,
  `fecha_fin` datetime NOT NULL,
  `estado` enum('CREADO','INSCRIPCION','VOTACION','CERRADO','FINALIZADO','ANULADO') NOT NULL DEFAULT 'CREADO',
  `tipo` enum('PRIMERA_VUELTA','SEGUNDA_VUELTA') NOT NULL DEFAULT 'PRIMERA_VUELTA',
  `id_proceso_padre` int(11) DEFAULT NULL,
  `quorum_minimo` decimal(5,2) NOT NULL DEFAULT 60.00,
  `fecha_convocatoria` date DEFAULT NULL COMMENT 'Fecha oficial de convocatoria. Debe estar 30-45 días antes del sufragio (RN02 / Art.7-8 Res.0462-CU-2019)',
  PRIMARY KEY (`id_proceso`),
  KEY `fk_proceso_padre` (`id_proceso_padre`),
  CONSTRAINT `fk_proceso_padre` FOREIGN KEY (`id_proceso_padre`) REFERENCES `proceso_electoral` (`id_proceso`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `proceso_electoral`
--

LOCK TABLES `proceso_electoral` WRITE;
/*!40000 ALTER TABLE `proceso_electoral` DISABLE KEYS */;
INSERT INTO `proceso_electoral` VALUES (1,'Elecciones de Rector y Vicerrectores 2026-II','2026-10-30 09:00:00','2026-10-30 15:00:00','CREADO','PRIMERA_VUELTA',NULL,60.00,'2026-09-30');
/*!40000 ALTER TABLE `proceso_electoral` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sesion_activa`
--

DROP TABLE IF EXISTS `sesion_activa`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sesion_activa` (
  `id_sesion` bigint(20) NOT NULL AUTO_INCREMENT,
  `id_usuario` int(11) NOT NULL,
  `token_hash` char(64) NOT NULL,
  `fecha_inicio` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_expiracion` datetime NOT NULL,
  `revocada` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id_sesion`),
  UNIQUE KEY `token_hash` (`token_hash`),
  KEY `fk_sesion_usuario` (`id_usuario`),
  CONSTRAINT `fk_sesion_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sesion_activa`
--

LOCK TABLES `sesion_activa` WRITE;
/*!40000 ALTER TABLE `sesion_activa` DISABLE KEYS */;
/*!40000 ALTER TABLE `sesion_activa` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tacha`
--

DROP TABLE IF EXISTS `tacha`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tacha` (
  `id_tacha` int(11) NOT NULL AUTO_INCREMENT,
  `id_docente_denunciante` int(11) NOT NULL,
  `id_candidato` int(11) NOT NULL,
  `motivo` text NOT NULL,
  `estado` enum('PENDIENTE','FUNDADA','INFUNDADA') NOT NULL DEFAULT 'PENDIENTE',
  `fecha_presentacion` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_resolucion` datetime DEFAULT NULL,
  PRIMARY KEY (`id_tacha`),
  KEY `fk_tacha_denunciante` (`id_docente_denunciante`),
  KEY `fk_tacha_candidato` (`id_candidato`),
  CONSTRAINT `fk_tacha_candidato` FOREIGN KEY (`id_candidato`) REFERENCES `candidato` (`id_candidato`),
  CONSTRAINT `fk_tacha_denunciante` FOREIGN KEY (`id_docente_denunciante`) REFERENCES `docente` (`id_docente`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tacha`
--

LOCK TABLES `tacha` WRITE;
/*!40000 ALTER TABLE `tacha` DISABLE KEYS */;
/*!40000 ALTER TABLE `tacha` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `usuario`
--

DROP TABLE IF EXISTS `usuario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `usuario` (
  `id_usuario` int(11) NOT NULL AUTO_INCREMENT,
  `id_docente` int(11) DEFAULT NULL,
  `username` varchar(80) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `rol` enum('ADMIN','CEUNP','DOCENTE','PERSONERO','MIEMBRO_MESA') NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  `intentos_fallidos` int(11) NOT NULL DEFAULT 0,
  `bloqueado_hasta` datetime DEFAULT NULL,
  `ultimo_acceso` datetime DEFAULT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_usuario`),
  UNIQUE KEY `username` (`username`),
  KEY `fk_usuario_docente` (`id_docente`),
  CONSTRAINT `fk_usuario_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuario`
--

LOCK TABLES `usuario` WRITE;
/*!40000 ALTER TABLE `usuario` DISABLE KEYS */;
INSERT INTO `usuario` VALUES (1,NULL,'admin','$2a$10$OXJ2VHW1sS2YegyK7idYnu92svDipjP0oXDqmmoXESRcHsspK9pQO','ADMIN',1,0,NULL,'2026-10-14 15:56:15','2026-10-07 22:42:15'),(5,261,'lucanoxz','$2a$10$srLqN0o5IgIPkz3G38f./eiPzJaPUfsF4mNfZMTIl6b2XYB3e9JF2','CEUNP',1,0,NULL,'2026-10-15 09:15:50','2026-10-07 22:42:15');
/*!40000 ALTER TABLE `usuario` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `voto`
--

DROP TABLE IF EXISTS `voto`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `voto` (
  `id_voto` bigint(20) NOT NULL AUTO_INCREMENT,
  `id_proceso` int(11) NOT NULL,
  `id_cargo` int(11) NOT NULL,
  `id_lista_elegida` int(11) DEFAULT NULL,
  `tipo_voto` enum('VALIDO','BLANCO','NULO') NOT NULL,
  `fecha_hora` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_voto`),
  KEY `fk_voto_proceso` (`id_proceso`),
  KEY `fk_voto_cargo` (`id_cargo`),
  KEY `fk_voto_lista` (`id_lista_elegida`),
  CONSTRAINT `fk_voto_cargo` FOREIGN KEY (`id_cargo`) REFERENCES `cargo_electoral` (`id_cargo`),
  CONSTRAINT `fk_voto_lista` FOREIGN KEY (`id_lista_elegida`) REFERENCES `lista_electoral` (`id_lista`),
  CONSTRAINT `fk_voto_proceso` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `voto`
--

LOCK TABLES `voto` WRITE;
/*!40000 ALTER TABLE `voto` DISABLE KEYS */;
/*!40000 ALTER TABLE `voto` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'elecciones_unp'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-15 14:40:05
