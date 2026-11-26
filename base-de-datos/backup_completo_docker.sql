-- MariaDB dump 10.19  Distrib 10.4.32-MariaDB, for Win64 (AMD64)
--
-- Host: 127.0.0.1    Database: elecciones_unp
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
  `contenido_json` longtext NOT NULL,
  `hash_integridad` char(64) NOT NULL,
  `token_qr_hash` char(64) NOT NULL,
  `fecha_emision` datetime NOT NULL DEFAULT current_timestamp(),
  `estado` enum('VIGENTE','ANULADA') NOT NULL DEFAULT 'VIGENTE',
  PRIMARY KEY (`id_acta`),
  UNIQUE KEY `uq_acta_token` (`token_qr_hash`),
  UNIQUE KEY `uq_acta_mesa_tipo` (`id_mesa`,`tipo`),
  CONSTRAINT `fk_acta_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`),
  CONSTRAINT `chk_acta_json` CHECK (json_valid(`contenido_json`))
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `acta_electoral`
--

LOCK TABLES `acta_electoral` WRITE;
/*!40000 ALTER TABLE `acta_electoral` DISABLE KEYS */;
INSERT INTO `acta_electoral` VALUES (1,1,'INSTALACION','{\"tipo\":\"INSTALACION\",\"id_proceso\":1,\"proceso\":\"Elección de Jefe de Departamento de Informática 2026-II\",\"mesa\":\"001\",\"ubicacion\":\"Biblioteca Central\",\"hora_instalacion\":\"2026-11-25 09:15:57\",\"total_electores\":17,\"cedulas_recibidas\":17,\"cedulas_firmadas\":true,\"miembros\":[{\"dni\": \"40682528\", \"docente\": \"Ipanaque Silva, Rolando Elías\", \"rol_sorteo\": \"PRESIDENTE\", \"titular\": 1, \"asistio\": 1, \"rol_instalacion\": \"PRESIDENTE\", \"hora_llegada\": \"2026-11-25 09:02:51\", \"metodo\": \"DNI\"},{\"dni\": \"02810146\", \"docente\": \"Lizana Puelles, Esther Yolanda\", \"rol_sorteo\": \"SECRETARIO\", \"titular\": 1, \"asistio\": 1, \"rol_instalacion\": \"SECRETARIO\", \"hora_llegada\": \"2026-11-25 09:03:00\", \"metodo\": \"DNI\"},{\"dni\": \"02600704\", \"docente\": \"Requena Flores, Rigo Félix\", \"rol_sorteo\": \"VOCAL\", \"titular\": 1, \"asistio\": 1, \"rol_instalacion\": \"VOCAL\", \"hora_llegada\": \"2026-11-25 09:03:07\", \"metodo\": \"DNI\"},{\"dni\": \"06433589\", \"docente\": \"Valle Rios, Víctor Hugo\", \"rol_sorteo\": \"SUPLENTE\", \"titular\": 0, \"asistio\": 1, \"rol_instalacion\": null, \"hora_llegada\": \"2026-11-25 09:03:13\", \"metodo\": \"DNI\"},{\"dni\": \"02786563\", \"docente\": \"Sandoval Rivera, Jorge Luis\", \"rol_sorteo\": \"SUPLENTE\", \"titular\": 0, \"asistio\": 1, \"rol_instalacion\": null, \"hora_llegada\": \"2026-11-25 09:03:19\", \"metodo\": \"DNI\"},{\"dni\": \"02606057\", \"docente\": \"Alvarado Tabacchi, Jorge\", \"rol_sorteo\": \"SUPLENTE\", \"titular\": 0, \"asistio\": 1, \"rol_instalacion\": null, \"hora_llegada\": \"2026-11-25 09:03:23\", \"metodo\": \"DNI\"}],\"reemplazantes\":[],\"personeros\":[],\"material\":{\"PADRON\":{\"estado\":\"CONFORME\",\"observacion\":null},\"ACTAS\":{\"estado\":\"CONFORME\",\"observacion\":null},\"CEDULAS\":{\"estado\":\"CONFORME\",\"observacion\":null},\"CARTEL_CANDIDATOS\":{\"estado\":\"CONFORME\",\"observacion\":null},\"ANFORA\":{\"estado\":\"CONFORME\",\"observacion\":null},\"CABINA\":{\"estado\":\"CONFORME\",\"observacion\":null}},\"observaciones\":\"ya esta todo listo\"}','40611fb0b9bc705e67106f2a939693ef77da581e505743f399655ead6210ea34','3a4c3f8d118efbaebf50c4021c67a59aad7007fd76118eb5dbb4bd2f2a28b8df','2026-11-25 09:15:57','VIGENTE'),(2,1,'SUFRAGIO','{\"tipo\":\"SUFRAGIO\",\"id_proceso\":1,\"proceso\":\"Elección de Jefe de Departamento de Informática 2026-II\",\"mesa\":\"001\",\"ubicacion\":\"Biblioteca Central\",\"hora_instalacion\":\"2026-11-25 09:15:57\",\"hora_cierre\":\"2026-11-25 15:28:56\",\"cierre_anticipado\":false,\"total_electores\":17,\"electores_que_votaron\":16,\"electores_que_no_votaron\":1,\"asistieron_sin_votar\":1,\"cedulas_recibidas\":17,\"cedulas_no_utilizadas\":1,\"firmas_lista_fisica\":16,\"diferencia_lista_fisica\":0,\"miembros\":[{\"dni\": \"40682528\", \"docente\": \"Ipanaque Silva, Rolando Elías\", \"cargo\": \"PRESIDENTE\", \"origen\": \"TITULAR\"},{\"dni\": \"02810146\", \"docente\": \"Lizana Puelles, Esther Yolanda\", \"cargo\": \"SECRETARIO\", \"origen\": \"TITULAR\"},{\"dni\": \"02600704\", \"docente\": \"Requena Flores, Rigo Félix\", \"cargo\": \"VOCAL\", \"origen\": \"TITULAR\"}],\"no_votaron\":[{\"dni\": \"02606057\", \"docente\": \"Alvarado Tabacchi, Jorge\", \"asistio\": 1}],\"observaciones\":\"un error en cabina por un elector\"}','5b0c4bba9514ed037361cc87eb8c46735021829f893b28d07a8732c8249f63b6','728c58bc6cd77be5842aa9d16551c31897da4aaeccbb4913d8a841716077fe74','2026-11-25 15:31:59','VIGENTE'),(3,1,'ESCRUTINIO','{\"tipo\":\"ESCRUTINIO\",\"id_proceso\":1,\"proceso\":\"Elección de Jefe de Departamento de Informática 2026-II\",\"mesa\":\"001\",\"ubicacion\":\"Biblioteca Central\",\"hora_inicio\":\"2026-11-25 15:34:02\",\"hora_fin\":\"2026-11-25 15:35:44\",\"electores_que_votaron\":16,\"cedulas_contadas\":16,\"cedulas_sobrantes_destruidas\":0,\"cedulas_faltantes\":0,\"cedulas_escrutadas\":16,\"observacion_cedulas\":null,\"recuentos\":0,\"conteo_coincide_digital\":true,\"total_coincide_votantes\":true,\"prevalece_cedula_fisica\":false,\"resultados\":[{\"id_cargo\":1,\"cargo\":\"Jefe de Departamento Académico\",\"votantes\":16,\"total\":16,\"total_digital\":16,\"validos\":15,\"blancos\":1,\"nulos\":0,\"impugnados\":0,\"opciones\":[{\"opcion\":\"LISTA\",\"id_lista\":1,\"nombre\":\"A\",\"orden\":1,\"manual\":4,\"digital\":4,\"diferencia\":0},{\"opcion\":\"LISTA\",\"id_lista\":2,\"nombre\":\"B\",\"orden\":2,\"manual\":11,\"digital\":11,\"diferencia\":0},{\"opcion\":\"BLANCO\",\"id_lista\":null,\"nombre\":\"Votos en blanco\",\"orden\":null,\"manual\":1,\"digital\":1,\"diferencia\":0},{\"opcion\":\"NULO\",\"id_lista\":null,\"nombre\":\"Votos nulos\",\"orden\":null,\"manual\":0,\"digital\":0,\"diferencia\":0},{\"opcion\":\"IMPUGNADO\",\"id_lista\":null,\"nombre\":\"Votos impugnados\",\"orden\":null,\"manual\":0,\"digital\":0,\"diferencia\":0}]}],\"impugnaciones\":[],\"miembros\":[{\"dni\": \"40682528\", \"docente\": \"Ipanaque Silva, Rolando Elías\", \"cargo\": \"PRESIDENTE\", \"origen\": \"TITULAR\"},{\"dni\": \"02810146\", \"docente\": \"Lizana Puelles, Esther Yolanda\", \"cargo\": \"SECRETARIO\", \"origen\": \"TITULAR\"},{\"dni\": \"02600704\", \"docente\": \"Requena Flores, Rigo Félix\", \"cargo\": \"VOCAL\", \"origen\": \"TITULAR\"}],\"observada\":true,\"observaciones\":\"hubo un elector que no voto\"}','7df567924c8f662d8bc4448f0df293e62c937a86d26a8abc7889c7ee8150bb31','7d9753ff7b27c6d68aa828d3681720013b8a8843a7b8512fc410a938552979cb','2026-11-25 15:35:44','VIGENTE'),(4,2,'INSTALACION','{\"tipo\":\"INSTALACION\",\"id_proceso\":2,\"proceso\":\"Elección de Jefe de Departamento de Informática 2026-II\",\"mesa\":\"001\",\"ubicacion\":\"Biblioteca Central\",\"hora_instalacion\":\"2026-11-25 09:17:30\",\"total_electores\":17,\"cedulas_recibidas\":17,\"cedulas_firmadas\":true,\"miembros\":[{\"dni\": \"02786563\", \"docente\": \"Sandoval Rivera, Jorge Luis\", \"rol_sorteo\": \"PRESIDENTE\", \"titular\": 1, \"asistio\": 1, \"rol_instalacion\": \"PRESIDENTE\", \"hora_llegada\": \"2026-11-25 09:10:15\", \"metodo\": \"DNI\"},{\"dni\": \"06433589\", \"docente\": \"Valle Rios, Víctor Hugo\", \"rol_sorteo\": \"SECRETARIO\", \"titular\": 1, \"asistio\": 1, \"rol_instalacion\": \"SECRETARIO\", \"hora_llegada\": \"2026-11-25 09:15:42\", \"metodo\": \"DNI\"},{\"dni\": \"03691805\", \"docente\": \"Puicón Zapata, Hoower Augusto\", \"rol_sorteo\": \"VOCAL\", \"titular\": 1, \"asistio\": 1, \"rol_instalacion\": \"VOCAL\", \"hora_llegada\": \"2026-11-25 09:15:49\", \"metodo\": \"DNI\"},{\"dni\": \"40682528\", \"docente\": \"Ipanaque Silva, Rolando Elías\", \"rol_sorteo\": \"SUPLENTE\", \"titular\": 0, \"asistio\": 0, \"rol_instalacion\": null, \"hora_llegada\": null, \"metodo\": null},{\"dni\": \"02887733\", \"docente\": \"Sandoval Rivera, Arturo\", \"rol_sorteo\": \"SUPLENTE\", \"titular\": 0, \"asistio\": 0, \"rol_instalacion\": null, \"hora_llegada\": null, \"metodo\": null},{\"dni\": \"02635949\", \"docente\": \"Cruz Yarlequé, Wilfredo\", \"rol_sorteo\": \"SUPLENTE\", \"titular\": 0, \"asistio\": 0, \"rol_instalacion\": null, \"hora_llegada\": null, \"metodo\": null}],\"reemplazantes\":[],\"personeros\":[],\"material\":{\"PADRON\":{\"estado\":\"CONFORME\",\"observacion\":null},\"ACTAS\":{\"estado\":\"CONFORME\",\"observacion\":null},\"CEDULAS\":{\"estado\":\"CONFORME\",\"observacion\":null},\"CARTEL_CANDIDATOS\":{\"estado\":\"CONFORME\",\"observacion\":null},\"ANFORA\":{\"estado\":\"CONFORME\",\"observacion\":null},\"CABINA\":{\"estado\":\"CONFORME\",\"observacion\":null}},\"observaciones\":\"Todo conforme\"}','fd6dce97b1fa8295b9fb0e98812fde055148984f80d9bb72f105307b4bb3d61b','25495320c41aea3d45cf692c942b4b13ee777d91fcb31b0286e49b66a9755672','2026-11-25 09:17:30','VIGENTE'),(5,2,'SUFRAGIO','{\"tipo\":\"SUFRAGIO\",\"id_proceso\":2,\"proceso\":\"Elección de Jefe de Departamento de Informática 2026-II\",\"mesa\":\"001\",\"ubicacion\":\"Biblioteca Central\",\"hora_instalacion\":\"2026-11-25 09:17:30\",\"hora_cierre\":\"2026-11-25 15:07:52\",\"cierre_anticipado\":false,\"total_electores\":17,\"electores_que_votaron\":17,\"electores_que_no_votaron\":0,\"asistieron_sin_votar\":0,\"cedulas_recibidas\":17,\"cedulas_no_utilizadas\":0,\"firmas_lista_fisica\":17,\"diferencia_lista_fisica\":0,\"miembros\":[{\"dni\": \"02786563\", \"docente\": \"Sandoval Rivera, Jorge Luis\", \"cargo\": \"PRESIDENTE\", \"origen\": \"TITULAR\"},{\"dni\": \"06433589\", \"docente\": \"Valle Rios, Víctor Hugo\", \"cargo\": \"SECRETARIO\", \"origen\": \"TITULAR\"},{\"dni\": \"03691805\", \"docente\": \"Puicón Zapata, Hoower Augusto\", \"cargo\": \"VOCAL\", \"origen\": \"TITULAR\"}],\"no_votaron\":[],\"observaciones\":null}','e8b4ed5a902445af9b7697439c52050dcd02e868ed02c904af2ba61ab5f20e28','c7244a86d31c2b9774327c0ff683e245268f21ee439fca60660ae9e73313ef02','2026-11-25 15:08:38','VIGENTE'),(6,2,'ESCRUTINIO','{\"tipo\":\"ESCRUTINIO\",\"id_proceso\":2,\"proceso\":\"Elección de Jefe de Departamento de Informática 2026-II\",\"mesa\":\"001\",\"ubicacion\":\"Biblioteca Central\",\"hora_inicio\":\"2026-11-25 15:09:16\",\"hora_fin\":\"2026-11-25 15:11:38\",\"electores_que_votaron\":17,\"cedulas_contadas\":17,\"cedulas_sobrantes_destruidas\":0,\"cedulas_faltantes\":0,\"cedulas_escrutadas\":17,\"observacion_cedulas\":null,\"recuentos\":1,\"conteo_coincide_digital\":true,\"total_coincide_votantes\":true,\"prevalece_cedula_fisica\":false,\"resultados\":[{\"id_cargo\":2,\"cargo\":\"Jefe de Departamento Académico\",\"votantes\":17,\"total\":17,\"total_digital\":17,\"validos\":17,\"blancos\":0,\"nulos\":0,\"impugnados\":0,\"opciones\":[{\"opcion\":\"LISTA\",\"id_lista\":5,\"nombre\":\"Avance TI\",\"orden\":1,\"manual\":13,\"digital\":13,\"diferencia\":0},{\"opcion\":\"LISTA\",\"id_lista\":4,\"nombre\":\"Innovación Informática\",\"orden\":2,\"manual\":4,\"digital\":4,\"diferencia\":0},{\"opcion\":\"BLANCO\",\"id_lista\":null,\"nombre\":\"Votos en blanco\",\"orden\":null,\"manual\":0,\"digital\":0,\"diferencia\":0},{\"opcion\":\"NULO\",\"id_lista\":null,\"nombre\":\"Votos nulos\",\"orden\":null,\"manual\":0,\"digital\":0,\"diferencia\":0},{\"opcion\":\"IMPUGNADO\",\"id_lista\":null,\"nombre\":\"Votos impugnados\",\"orden\":null,\"manual\":0,\"digital\":0,\"diferencia\":0}]}],\"impugnaciones\":[],\"miembros\":[{\"dni\": \"02786563\", \"docente\": \"Sandoval Rivera, Jorge Luis\", \"cargo\": \"PRESIDENTE\", \"origen\": \"TITULAR\"},{\"dni\": \"06433589\", \"docente\": \"Valle Rios, Víctor Hugo\", \"cargo\": \"SECRETARIO\", \"origen\": \"TITULAR\"},{\"dni\": \"03691805\", \"docente\": \"Puicón Zapata, Hoower Augusto\", \"cargo\": \"VOCAL\", \"origen\": \"TITULAR\"}],\"observada\":false,\"observaciones\":null}','0cd145b190b1c6d5247ce29f2c8996839e4154a3546bdcf51dbf3117df8d2bff','95ea78b10b21e1be21191dbeb9c8ad7acfd24f180ce8d208a36c836b905239db','2026-11-25 15:11:38','VIGENTE');
/*!40000 ALTER TABLE `acta_electoral` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_acta_bu BEFORE UPDATE ON acta_electoral
FOR EACH ROW
BEGIN
  IF NEW.contenido_json  <> OLD.contenido_json
     OR NEW.hash_integridad <> OLD.hash_integridad
     OR NEW.token_qr_hash   <> OLD.token_qr_hash
     OR NEW.id_mesa <> OLD.id_mesa
     OR NEW.tipo    <> OLD.tipo
     OR NEW.fecha_emision <> OLD.fecha_emision THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN28: el contenido de un acta emitida no se puede modificar.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_acta_bd BEFORE DELETE ON acta_electoral
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN28: las actas no se eliminan, se anulan.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `asistencia_elector`
--

DROP TABLE IF EXISTS `asistencia_elector`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `asistencia_elector` (
  `id_asistencia` bigint(20) NOT NULL AUTO_INCREMENT,
  `id_proceso` int(11) NOT NULL,
  `id_mesa` int(11) NOT NULL,
  `id_docente` int(11) NOT NULL,
  `metodo` enum('QR','DNI') NOT NULL,
  `id_credencial` bigint(20) DEFAULT NULL,
  `hora_asistencia` datetime NOT NULL DEFAULT current_timestamp(),
  `id_usuario_mesa` int(11) DEFAULT NULL,
  PRIMARY KEY (`id_asistencia`),
  UNIQUE KEY `uq_asistencia_elector` (`id_proceso`,`id_docente`),
  KEY `ix_asistencia_mesa` (`id_mesa`),
  KEY `fk_asistencia_docente` (`id_docente`),
  KEY `fk_asistencia_credencial` (`id_credencial`),
  KEY `fk_asistencia_usuario` (`id_usuario_mesa`),
  CONSTRAINT `fk_asistencia_credencial` FOREIGN KEY (`id_credencial`) REFERENCES `credencial_qr` (`id_credencial`),
  CONSTRAINT `fk_asistencia_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`),
  CONSTRAINT `fk_asistencia_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`),
  CONSTRAINT `fk_asistencia_proceso` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`),
  CONSTRAINT `fk_asistencia_usuario` FOREIGN KEY (`id_usuario_mesa`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `chk_asistencia_qr` CHECK (`metodo` = 'DNI' or `id_credencial` is not null)
) ENGINE=InnoDB AUTO_INCREMENT=35 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `asistencia_elector`
--

LOCK TABLES `asistencia_elector` WRITE;
/*!40000 ALTER TABLE `asistencia_elector` DISABLE KEYS */;
INSERT INTO `asistencia_elector` VALUES (1,1,1,108,'QR',8,'2026-11-25 09:37:20',118),(2,1,1,101,'DNI',NULL,'2026-11-25 09:59:07',118),(3,1,1,102,'DNI',NULL,'2026-11-25 10:02:08',118),(4,1,1,103,'DNI',NULL,'2026-11-25 10:10:14',120),(5,1,1,104,'DNI',NULL,'2026-11-25 10:10:47',120),(6,1,1,105,'DNI',NULL,'2026-11-25 10:11:24',120),(7,1,1,106,'DNI',NULL,'2026-11-25 10:18:37',120),(8,1,1,107,'DNI',NULL,'2026-11-25 10:18:56',120),(9,1,1,109,'DNI',NULL,'2026-11-25 10:19:18',120),(10,1,1,110,'DNI',NULL,'2026-11-25 10:19:58',120),(11,1,1,111,'DNI',NULL,'2026-11-25 10:26:41',111),(12,1,1,112,'DNI',NULL,'2026-11-25 10:26:58',111),(13,1,1,113,'DNI',NULL,'2026-11-25 10:27:15',111),(14,1,1,114,'DNI',NULL,'2026-11-25 10:28:13',111),(15,1,1,115,'DNI',NULL,'2026-11-25 10:28:23',111),(16,1,1,116,'DNI',NULL,'2026-11-25 10:28:34',111),(17,1,1,117,'DNI',NULL,'2026-11-25 10:28:44',111),(18,2,2,101,'DNI',NULL,'2026-11-25 09:21:18',118),(19,2,2,102,'DNI',NULL,'2026-11-25 09:21:33',118),(20,2,2,103,'DNI',NULL,'2026-11-25 09:22:01',118),(21,2,2,104,'DNI',NULL,'2026-11-25 09:22:20',118),(22,2,2,105,'DNI',NULL,'2026-11-25 09:22:34',118),(23,2,2,106,'DNI',NULL,'2026-11-25 09:26:31',118),(24,2,2,107,'DNI',NULL,'2026-11-25 09:26:49',118),(25,2,2,108,'DNI',NULL,'2026-11-25 09:27:03',118),(26,2,2,109,'DNI',NULL,'2026-11-25 09:27:12',118),(27,2,2,110,'DNI',NULL,'2026-11-25 09:27:22',118),(28,2,2,111,'DNI',NULL,'2026-11-25 09:27:34',118),(29,2,2,112,'DNI',NULL,'2026-11-25 09:27:44',118),(30,2,2,113,'DNI',NULL,'2026-11-25 09:27:58',118),(31,2,2,114,'DNI',NULL,'2026-11-25 09:28:07',118),(32,2,2,115,'DNI',NULL,'2026-11-25 09:28:17',118),(33,2,2,116,'DNI',NULL,'2026-11-25 09:28:32',118),(34,2,2,117,'DNI',NULL,'2026-11-25 09:28:43',118);
/*!40000 ALTER TABLE `asistencia_elector` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_asistencia_elector_bd BEFORE DELETE ON asistencia_elector
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF64: la asistencia del elector no se elimina.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `asistencia_personero_mesa`
--

DROP TABLE IF EXISTS `asistencia_personero_mesa`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `asistencia_personero_mesa` (
  `id_mesa` int(11) NOT NULL,
  `id_personero` int(11) NOT NULL,
  `hora_acreditacion` datetime NOT NULL DEFAULT current_timestamp(),
  `metodo` enum('QR','DNI') NOT NULL,
  `id_usuario` int(11) DEFAULT NULL,
  PRIMARY KEY (`id_mesa`,`id_personero`),
  KEY `fk_asist_pers_personero` (`id_personero`),
  KEY `fk_asist_pers_usuario` (`id_usuario`),
  CONSTRAINT `fk_asist_pers_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`),
  CONSTRAINT `fk_asist_pers_personero` FOREIGN KEY (`id_personero`) REFERENCES `personero` (`id_personero`),
  CONSTRAINT `fk_asist_pers_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `asistencia_personero_mesa`
--

LOCK TABLES `asistencia_personero_mesa` WRITE;
/*!40000 ALTER TABLE `asistencia_personero_mesa` DISABLE KEYS */;
/*!40000 ALTER TABLE `asistencia_personero_mesa` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bitacora_accion`
--

DROP TABLE IF EXISTS `bitacora_accion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bitacora_accion` (
  `codigo` varchar(100) NOT NULL,
  `etiqueta` varchar(120) NOT NULL,
  `descripcion` varchar(300) DEFAULT NULL,
  `modulo` enum('SEGURIDAD','ADMINISTRACION','PREPARACION','JORNADA','ESCRUTINIO','RESULTADOS','RECURSOS','MULTAS') NOT NULL,
  `caso_uso` varchar(20) DEFAULT NULL,
  `criticidad` enum('BAJA','MEDIA','ALTA','CRITICA') NOT NULL DEFAULT 'BAJA',
  `orden` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`codigo`),
  KEY `ix_bitacora_accion_modulo` (`modulo`,`orden`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bitacora_accion`
--

LOCK TABLES `bitacora_accion` WRITE;
/*!40000 ALTER TABLE `bitacora_accion` DISABLE KEYS */;
INSERT INTO `bitacora_accion` VALUES ('ACREDITAR_PERSONERO','Personero acreditado','Acreditación de un personero de lista.','PREPARACION','CUS05','MEDIA',180),('ACTIVAR_USUARIO','Cuenta activada','La cuenta vuelve a poder iniciar sesión.','ADMINISTRACION','CUS18','MEDIA',30),('ACTUALIZAR_CRONOGRAMA','Cronograma actualizado','Cambio de las fechas del cronograma electoral.','PREPARACION','CUS01','MEDIA',30),('ACTUALIZAR_MULTA','Multa actualizada','Cambio del estado o del monto de la multa.','MULTAS','CUS16','ALTA',20),('ACTUALIZAR_USUARIO','Rol o docente de la cuenta modificado','Cambio del rol o del docente asociado a la cuenta.','ADMINISTRACION','CUS18','ALTA',20),('AGREGAR_CARGO','Cargo agregado al proceso','Se agregó un cargo a elegir.','PREPARACION','CUS01','MEDIA',40),('ANULAR_PROCESO','Proceso anulado','El proceso electoral fue anulado.','PREPARACION','CUS01','CRITICA',70),('APELAR_IMPUGNACION','Impugnación apelada','Apelación ante el CEUNP.','RECURSOS','CUS13','MEDIA',30),('APROBAR_REGENERACION_QR','Regeneración de QR aprobada','El CEUNP aprobó la solicitud y emitió un nuevo QR.','PREPARACION','CUS07','ALTA',263),('ATENDER_DISCREPANCIA_ACTA','Discrepancia de acta atendida','El CEUNP atendió la discrepancia.','RESULTADOS','CUS17','ALTA',130),('CALIFICAR_ACTA','Acta calificada','Calificación del acta en el cómputo.','RESULTADOS','CUS14','ALTA',50),('CAMBIO_CLAVE','Contraseña cambiada','El usuario cambió su propia contraseña (primer ingreso o voluntario).','SEGURIDAD','CUS21','MEDIA',50),('CAMBIO_ESTADO_PROCESO','Estado del proceso cambiado','El proceso pasó a otra etapa del cronograma.','PREPARACION','CUS01','ALTA',60),('CAMBIO_PARAMETRO','Parámetro modificado','Cambio o restauración de un parámetro del reglamento o del sistema.','ADMINISTRACION','CUS18','ALTA',80),('CERRAR_MESA','Mesa cerrada','Cierre de la votación en la mesa.','JORNADA','CUS11','ALTA',150),('CERRAR_SUFRAGIO','Sufragio cerrado','Cierre del sufragio de la mesa.','JORNADA','CUS11','ALTA',160),('COMPROBAR_ACTA','Acta comprobada','Comprobación del acta contra su huella.','RESULTADOS','CUS14','MEDIA',40),('COMPUTAR_RESULTADOS','Resultados computados','Cómputo general de la elección.','RESULTADOS','CUS14','CRITICA',70),('CONECTAR_TERMINAL','Terminal de votación conectada','Se habilitó una terminal para un elector.','JORNADA','CUS10','MEDIA',110),('CONSULTA_PUBLICA_CREDENCIAL','Credencial QR consultada (pública)','Apertura de la página pública de una credencial al escanear su QR.','PREPARACION','CUS07','BAJA',261),('CONTAR_CEDULAS','Cédulas contadas','Conteo de las cédulas de la mesa.','ESCRUTINIO','CUS12','MEDIA',10),('CREAR_MESAS','Mesas de sufragio creadas','Conformación de las mesas según el padrón.','PREPARACION','CUS06','MEDIA',200),('CREAR_PROCESO','Proceso electoral creado','Registro de una convocatoria.','PREPARACION','CUS01','MEDIA',10),('CREAR_SEGUNDA_VUELTA','Segunda vuelta convocada','Convocatoria a segunda vuelta (RN33).','RESULTADOS','CUS14','CRITICA',100),('CREAR_USUARIO','Cuenta creada','Alta de una cuenta con su rol y, si corresponde, su docente.','ADMINISTRACION','CUS18','MEDIA',10),('DECLARAR_NULIDAD_MESA','Mesa anulada en el cómputo','La calificación declaró nula la mesa.','RESULTADOS','CUS14','CRITICA',60),('DECLARAR_NULIDAD_PARCIAL','Nulidad parcial declarada','Se anularon los votos de una mesa.','RECURSOS','CUS15','CRITICA',70),('DECLARAR_NULIDAD_TOTAL','Nulidad total declarada','La elección fue declarada nula.','RECURSOS','CUS15','CRITICA',80),('DENEGAR_JUSTIFICACION','Justificación denegada','Se denegó la justificación.','MULTAS','CUS16','MEDIA',60),('DEPURAR_PADRON','Padrón depurado','Se filtraron los docentes habilitados para votar.','PREPARACION','CUS02','ALTA',90),('DESACTIVAR_USUARIO','Cuenta desactivada','La cuenta no puede iniciar sesión; conserva su historia.','ADMINISTRACION','CUS18','ALTA',40),('DESBLOQUEAR_USUARIO','Cuenta desbloqueada','Se pusieron en cero los intentos fallidos.','ADMINISTRACION','CUS18','MEDIA',60),('DESCARGAR_RESPALDO','Respaldo de la base descargado','Descarga del archivo de respaldo (contiene datos personales).','ADMINISTRACION','CUS18','ALTA',100),('DESESTIMAR_NULIDAD','Nulidad desestimada','El Pleno declaró infundado o improcedente el recurso.','RECURSOS','CUS15','ALTA',60),('DIRIMIR_EMPATE','Empate dirimido','Sorteo para dirimir un empate.','RECURSOS','CUS15','CRITICA',100),('ELIMINAR_USUARIO','Cuenta eliminada','Eliminación de una cuenta sin actividad (RN28).','ADMINISTRACION','CUS18','ALTA',70),('EMITIR_ACTA_ESCRUTINIO','Acta de escrutinio emitida','Acta de escrutinio con su huella SHA-256.','ESCRUTINIO','CUS12','ALTA',30),('EMITIR_ACTA_SUFRAGIO','Acta de sufragio emitida','Acta de sufragio con su huella SHA-256.','JORNADA','CUS11','ALTA',170),('EMITIR_CREDENCIAL','Credencial QR emitida','Emisión de una credencial con código QR.','PREPARACION','CUS07','BAJA',240),('EMITIR_RESOLUCION_MULTAS','Resolución de multas emitida','Resolución del Pleno con su huella y QR.','MULTAS','CUS16','ALTA',30),('EMITIR_VOTO','Voto emitido','El elector votó. Nunca se registra por quién (RNF05).','JORNADA','CUS10','BAJA',130),('ENTREGAR_ACTAS','Actas entregadas al CEUNP','Entrega de las actas de la mesa.','ESCRUTINIO','CUS12','ALTA',40),('EVALUAR_NULIDAD_MESA','Nulidad de mesa evaluada','Evaluación de causales de nulidad en la mesa.','ESCRUTINIO','CUS12','ALTA',50),('EXONERAR_MULTA','Multa exonerada','Exoneración de la multa.','MULTAS','CUS16','ALTA',70),('EXPORTAR_BITACORA','Bitácora exportada','Descarga de registros de la bitácora en un archivo CSV.','ADMINISTRACION','CUS19','MEDIA',130),('GENERAR_MULTAS','Multas generadas','Determinación de multas a omisos (RN35).','MULTAS','CUS16','ALTA',10),('GENERAR_PADRON','Padrón electoral generado','Padrón del proceso aprobado.','PREPARACION','CUS02','ALTA',100),('GENERAR_RESPALDO','Respaldo de la base generado','Copia completa de la base con su huella SHA-256.','ADMINISTRACION','CUS18','MEDIA',90),('IDENTIFICAR_ELECTOR','Elector identificado','Identificación del elector en la mesa.','JORNADA','CUS09','BAJA',80),('IMPORTAR_DOCENTES','Docentes importados','Carga masiva del padrón de docentes desde Excel o CSV.','PREPARACION','CUS02','MEDIA',80),('INCIDENCIA_MESA','Incidencia de mesa','Incidencia registrada durante la instalación o el sufragio.','JORNADA','CUS08','MEDIA',50),('INSCRIBIR_CANDIDATO','Candidato inscrito','Se agregó un candidato a una lista.','PREPARACION','CUS03','BAJA',120),('INSCRIBIR_LISTA','Lista inscrita','Inscripción de una lista de candidatos.','PREPARACION','CUS03','MEDIA',110),('INSTALAR_MESA','Mesa instalada','Acta de instalación de la mesa.','JORNADA','CUS08','ALTA',60),('INSTALAR_SESION_COMPUTO','Sesión de cómputo instalada','El Pleno instaló la sesión de cómputo.','RESULTADOS','CUS14','ALTA',10),('JUSTIFICAR_MULTA','Multa justificada','Se aceptó la justificación de la omisión.','MULTAS','CUS16','MEDIA',50),('LIBERAR_TERMINAL','Terminal de votación liberada','La terminal quedó libre.','JORNADA','CUS10','BAJA',120),('LOGIN_BLOQUEADO','Ingreso a una cuenta bloqueada','Intento de ingreso mientras la cuenta está bloqueada por intentos fallidos.','SEGURIDAD','CUS00','ALTA',30),('LOGIN_FAILED','Inicio de sesión fallido','Contraseña incorrecta, cuenta inactiva o bloqueada por intentos.','SEGURIDAD','CUS00','MEDIA',20),('LOGIN_INACTIVO','Ingreso a una cuenta inactiva','Intento de ingreso con una cuenta desactivada por el administrador.','SEGURIDAD','CUS00','MEDIA',40),('LOGIN_SUCCESS','Inicio de sesión','Ingreso correcto al sistema con usuario y contraseña.','SEGURIDAD','CUS00','BAJA',10),('MARCAR_ACTA_DUDOSA','Acta marcada como dudosa','El acta requiere comprobación.','RESULTADOS','CUS14','ALTA',30),('MARCAR_NO_VOTO','Elector marcado sin votar','Elector ausente al cierre del sufragio.','JORNADA','CUS11','MEDIA',140),('MESA_NO_INSTALADA','Mesa no instalada','Venció la hora límite sin instalar la mesa (RF58).','JORNADA','CUS08','ALTA',70),('NOTIFICAR_MULTAS','Multas notificadas','Notificación a los multados.','MULTAS','CUS16','MEDIA',40),('PRESENTAR_TACHA','Tacha presentada','Tacha contra una lista o un candidato.','PREPARACION','CUS04','MEDIA',160),('PROCLAMAR_RESULTADOS','Resultados proclamados','Proclamación de las listas ganadoras.','RESULTADOS','CUS14','CRITICA',80),('PUBLICAR_CONVOCATORIA','Convocatoria publicada','La convocatoria y su cronograma quedan públicos.','PREPARACION','CUS01','ALTA',20),('PUBLICAR_RESULTADOS','Resultados publicados','Publicación en el portal de resultados.','RESULTADOS','CUS14','CRITICA',90),('QUITAR_CANDIDATO','Candidato quitado','Se quitó un candidato de una lista.','PREPARACION','CUS03','MEDIA',130),('QUITAR_CARGO','Cargo quitado del proceso','Se quitó un cargo a elegir.','PREPARACION','CUS01','MEDIA',50),('QUITAR_REEMPLAZANTE_MESA','Reemplazante de mesa quitado','Se quitó al reemplazante registrado.','JORNADA','CUS08','MEDIA',30),('RECHAZAR_REGENERACION_QR','Regeneración de QR rechazada','El CEUNP rechazó la solicitud de un nuevo QR.','PREPARACION','CUS07','MEDIA',264),('RECIBIR_CREDENCIAL_PERSONERO','Credencial de personero recibida','El personero recibió su credencial.','PREPARACION','CUS07','BAJA',270),('REGISTRAR_ASISTENCIA','Asistencia del elector registrada','El elector firmó la lista de la mesa.','JORNADA','CUS09','BAJA',100),('REGISTRAR_COMUNICACION_NULIDAD','Comunicación de nulidad registrada','Comunicación de la nulidad a los órganos de gobierno.','RECURSOS','CUS15','MEDIA',90),('REGISTRAR_CONTEO_ESCRUTINIO','Conteo del escrutinio registrado','Conteo manual conciliado con el digital.','ESCRUTINIO','CUS12','ALTA',20),('REGISTRAR_COTEJO_ACTA','Acta cotejada conforme','El acta física coincide con la digital.','RESULTADOS','CUS17','BAJA',110),('REGISTRAR_IMPUGNACION','Impugnación registrada','Impugnación de un voto en la mesa.','RECURSOS','CUS13','MEDIA',10),('REGISTRAR_LLEGADA_MIEMBRO','Llegada de miembro de mesa','Registro de la hora de llegada del miembro.','JORNADA','CUS08','BAJA',10),('REGISTRAR_PAGO_MULTA','Pago de multa registrado','Registro del recibo de pago.','MULTAS','CUS16','MEDIA',80),('REGISTRAR_PERSONERO_COMPUTO','Personero en el cómputo','Asistencia de un personero al cómputo.','RESULTADOS','CUS14','BAJA',20),('REGISTRAR_RECURSO_NULIDAD','Recurso de nulidad presentado','Pedido de nulidad parcial o total.','RECURSOS','CUS15','MEDIA',50),('REGISTRAR_REEMPLAZANTE_MESA','Reemplazante de mesa registrado','Un elector reemplaza a un miembro ausente.','JORNADA','CUS08','MEDIA',20),('REGISTRAR_VOTOS_ESTUDIANTILES','Votos estudiantiles registrados','El CEUNP registró o cambió los votos del estamento estudiantil de una lista (Art. 66 Ley 30220).','RESULTADOS','CUS14','ALTA',735),('REINICIAR_BITACORA','Bitácora reiniciada','Se vaciaron los datos electorales y la bitácora (02_limpiar_datos_electorales.sql).','ADMINISTRACION','CUS19','CRITICA',140),('REPORTAR_DISCREPANCIA_ACTA','Discrepancia de acta reportada','El acta física no coincide con la digital.','RESULTADOS','CUS17','ALTA',120),('RESOLVER_APELACION','Apelación resuelta','Fallo del Pleno del CEUNP.','RECURSOS','CUS13','ALTA',40),('RESOLVER_IMPUGNACION_MESA','Impugnación resuelta por la mesa','Decisión de la mesa sobre la impugnación.','RECURSOS','CUS13','ALTA',20),('RESOLVER_TACHA','Tacha resuelta','El CEUNP declaró fundada o infundada la tacha.','PREPARACION','CUS04','ALTA',170),('RESTABLECER_PASSWORD','Contraseña restablecida','El administrador asignó una contraseña provisional.','ADMINISTRACION','CUS18','ALTA',50),('RETIRAR_LISTA','Lista retirada','La lista se retiró del proceso.','PREPARACION','CUS03','ALTA',140),('REVOCAR_CREDENCIAL','Credencial QR revocada','La credencial deja de ser válida.','PREPARACION','CUS07','ALTA',250),('REVOCAR_PERSONERO','Personero revocado','Se revocó la acreditación del personero.','PREPARACION','CUS05','ALTA',190),('SOLICITAR_REGENERACION_QR','Regeneración de QR solicitada','Un docente pidió al CEUNP un nuevo código QR para su credencial.','PREPARACION','CUS07','MEDIA',262),('SORTEO_GENERAL_MESAS','Sorteo general de miembros de mesa','Sorteo de los miembros de todas las mesas.','PREPARACION','CUS06','ALTA',220),('SORTEO_MESA','Sorteo de miembros de una mesa','Sorteo de titulares y suplentes de una mesa.','PREPARACION','CUS06','ALTA',210),('SORTEO_ORDEN_CEDULA','Sorteo del orden en la cédula','Orden de las listas en la cédula de votación.','PREPARACION','CUS06','ALTA',230),('VALIDAR_LISTA','Lista calificada','El CEUNP admitió u observó la lista.','PREPARACION','CUS03','ALTA',150),('VERIFICAR_BITACORA','Integridad de la bitácora verificada','Se recalcularon los sellos encadenados de todos los registros.','ADMINISTRACION','CUS19','BAJA',120),('VERIFICAR_CREDENCIAL','Credencial QR verificada','Lectura y comprobación de una credencial.','PREPARACION','CUS07','BAJA',260),('VERIFICAR_ELECTOR','Elector verificado','El elector figura en el padrón de la mesa.','JORNADA','CUS09','BAJA',90),('VERIFICAR_MATERIAL_MESA','Material electoral verificado','Revisión del material de la mesa.','JORNADA','CUS08','BAJA',40),('VERIFICAR_RESPALDO','Integridad del respaldo verificada','Se recalculó la huella SHA-256 del archivo de respaldo.','ADMINISTRACION','CUS18','BAJA',110);
/*!40000 ALTER TABLE `bitacora_accion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bitacora_cadena`
--

DROP TABLE IF EXISTS `bitacora_cadena`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bitacora_cadena` (
  `id_cadena` tinyint(4) NOT NULL,
  `ultimo_id_log` bigint(20) DEFAULT NULL,
  `ultimo_hash` char(64) NOT NULL,
  `total_registros` bigint(20) NOT NULL DEFAULT 0,
  `fecha_inicio` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_actualizacion` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_cadena`),
  CONSTRAINT `chk_bitacora_cadena_unica` CHECK (`id_cadena` = 1),
  CONSTRAINT `chk_bitacora_cadena_hash` CHECK (`ultimo_hash` regexp '^[0-9a-f]{64}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bitacora_cadena`
--

LOCK TABLES `bitacora_cadena` WRITE;
/*!40000 ALTER TABLE `bitacora_cadena` DISABLE KEYS */;
INSERT INTO `bitacora_cadena` VALUES (1,350,'e5d96ccaae93efd8650675833b89634b3ed76c2c33d5eeae3282657fbca1499c',350,'2026-11-25 10:52:36','2026-11-25 20:33:23');
/*!40000 ALTER TABLE `bitacora_cadena` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `calificacion_mesa`
--

DROP TABLE IF EXISTS `calificacion_mesa`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `calificacion_mesa` (
  `id_mesa` int(11) NOT NULL,
  `id_proceso` int(11) NOT NULL,
  `calificacion` enum('VALIDA','NULIDAD') NOT NULL,
  `motivo_revision` varchar(300) DEFAULT NULL,
  `fundamento` varchar(1000) NOT NULL,
  `numero_resolucion` varchar(40) DEFAULT NULL,
  `fecha` datetime NOT NULL,
  `id_usuario` int(11) DEFAULT NULL,
  PRIMARY KEY (`id_mesa`),
  UNIQUE KEY `uq_calificacion_resolucion` (`numero_resolucion`),
  KEY `fk_calif_proceso` (`id_proceso`),
  KEY `fk_calif_usuario` (`id_usuario`),
  CONSTRAINT `fk_calif_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`),
  CONSTRAINT `fk_calif_proceso` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`),
  CONSTRAINT `fk_calif_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `chk_calificacion_nulidad` CHECK (`calificacion` <> 'NULIDAD' or `numero_resolucion` is not null)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `calificacion_mesa`
--

LOCK TABLES `calificacion_mesa` WRITE;
/*!40000 ALTER TABLE `calificacion_mesa` DISABLE KEYS */;
INSERT INTO `calificacion_mesa` VALUES (1,1,'VALIDA','acta con observaciones','Si esta  de acuerdo',NULL,'2026-11-25 15:53:21',3);
/*!40000 ALTER TABLE `calificacion_mesa` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_calificacion_bi_cus15 BEFORE INSERT ON calificacion_mesa
FOR EACH ROW
BEGIN
  IF NEW.numero_resolucion IS NOT NULL
     AND (EXISTS (SELECT 1 FROM nulidad_electoral WHERE numero_resolucion = NEW.numero_resolucion)
          OR EXISTS (SELECT 1 FROM dirimencia_empate WHERE numero_resolucion = NEW.numero_resolucion)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_calificacion_bi_cus16 BEFORE INSERT ON calificacion_mesa
FOR EACH ROW
BEGIN
  IF NEW.numero_resolucion IS NOT NULL
     AND (EXISTS (SELECT 1 FROM reporte_multas WHERE numero_resolucion = NEW.numero_resolucion)
          OR EXISTS (SELECT 1 FROM multa_justificacion WHERE numero_resolucion = NEW.numero_resolucion)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_calificacion_bu BEFORE UPDATE ON calificacion_mesa
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: la calificación del acta por el CEUNP es inapelable.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_calificacion_bd BEFORE DELETE ON calificacion_mesa
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: la calificación del acta por el CEUNP es inapelable.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

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
  `url_hoja_vida` varchar(300) DEFAULT NULL,
  `motivo_exclusion` varchar(500) DEFAULT NULL,
  `url_foto` varchar(300) DEFAULT NULL,
  PRIMARY KEY (`id_candidato`),
  UNIQUE KEY `uq_candidato_lista_docente` (`id_lista`,`id_docente`),
  KEY `fk_candidato_docente` (`id_docente`),
  CONSTRAINT `fk_candidato_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`),
  CONSTRAINT `fk_candidato_lista` FOREIGN KEY (`id_lista`) REFERENCES `lista_electoral` (`id_lista`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `candidato`
--

LOCK TABLES `candidato` WRITE;
/*!40000 ALTER TABLE `candidato` DISABLE KEYS */;
INSERT INTO `candidato` VALUES (1,1,102,'JEFE_DEPARTAMENTO','APROBADO','2026-10-20 11:42:12',NULL,NULL,NULL),(2,2,106,'JEFE_DEPARTAMENTO','APROBADO','2026-10-20 11:42:32',NULL,NULL,NULL),(3,4,102,'JEFE_DEPARTAMENTO','APROBADO','2026-10-15 14:06:21',NULL,NULL,NULL),(4,5,106,'JEFE_DEPARTAMENTO','APROBADO','2026-10-15 14:06:53',NULL,NULL,NULL);
/*!40000 ALTER TABLE `candidato` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_candidato_bi BEFORE INSERT ON candidato
FOR EACH ROW
BEGIN
  DECLARE v_proceso INT;
  SET v_proceso = fn_proceso_de_lista(NEW.id_lista);

  IF EXISTS (SELECT 1
               FROM candidato ca
               JOIN lista_electoral l ON l.id_lista = ca.id_lista
               JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
              WHERE ca.id_docente = NEW.id_docente
                AND c.id_proceso = v_proceso
                AND ca.id_lista <> NEW.id_lista
                AND ca.estado_validacion <> 'EXCLUIDO') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN11: el docente ya es candidato en otra lista de este proceso.';
  END IF;

  IF EXISTS (SELECT 1
               FROM personero p
               JOIN lista_electoral l ON l.id_lista = p.id_lista
               JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
              WHERE p.id_docente = NEW.id_docente
                AND c.id_proceso = v_proceso
                AND p.estado_acreditacion <> 'REVOCADO') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN21: un personero no puede ser candidato en el mismo proceso.';
  END IF;

  IF EXISTS (SELECT 1
               FROM miembro_mesa mm
               JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
              WHERE mm.id_docente = NEW.id_docente
                AND m.id_proceso = v_proceso) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN20: un miembro de mesa no puede ser candidato en el mismo proceso.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `cargo_admin`
--

DROP TABLE IF EXISTS `cargo_admin`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cargo_admin` (
  `id_cargo_admin` int(11) NOT NULL AUTO_INCREMENT,
  `id_docente` int(11) NOT NULL,
  `id_catalogo_cargo` int(11) NOT NULL,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date DEFAULT NULL,
  `vigente` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id_cargo_admin`),
  KEY `ix_cargo_admin_vigente` (`id_docente`,`vigente`),
  KEY `fk_cargo_admin_catalogo` (`id_catalogo_cargo`),
  CONSTRAINT `fk_cargo_admin_catalogo` FOREIGN KEY (`id_catalogo_cargo`) REFERENCES `catalogo_cargo` (`id_catalogo_cargo`),
  CONSTRAINT `fk_cargo_admin_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`),
  CONSTRAINT `chk_cargo_admin_fechas` CHECK (`fecha_fin` is null or `fecha_fin` >= `fecha_inicio`)
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
  `puede_votar` tinyint(1) NOT NULL DEFAULT 1,
  `puede_postular` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id_cargo`,`categoria`),
  CONSTRAINT `fk_categoria_cargo` FOREIGN KEY (`id_cargo`) REFERENCES `cargo_electoral` (`id_cargo`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cargo_categoria_permitida`
--

LOCK TABLES `cargo_categoria_permitida` WRITE;
/*!40000 ALTER TABLE `cargo_categoria_permitida` DISABLE KEYS */;
INSERT INTO `cargo_categoria_permitida` VALUES (1,'PRINCIPAL',1,1),(1,'ASOCIADO',1,0),(1,'AUXILIAR',1,0),(2,'PRINCIPAL',1,1),(2,'ASOCIADO',1,0),(2,'AUXILIAR',1,0);
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
  `porcentaje_minimo_victoria` decimal(5,2) NOT NULL DEFAULT 50.00,
  `estado_resultado` enum('PENDIENTE','ELEGIDO','SEGUNDA_VUELTA','SIN_QUORUM','DESIERTO','EMPATE') NOT NULL DEFAULT 'PENDIENTE',
  `id_lista_ganadora` int(11) DEFAULT NULL,
  PRIMARY KEY (`id_cargo`),
  UNIQUE KEY `uq_cargo_proceso` (`id_cargo`,`id_proceso`),
  KEY `ix_cargo_jurisdiccion` (`id_proceso`,`nivel_jurisdiccion`,`id_jurisdiccion`),
  KEY `fk_cargo_lista_ganadora` (`id_lista_ganadora`),
  CONSTRAINT `fk_cargo_lista_ganadora` FOREIGN KEY (`id_lista_ganadora`) REFERENCES `lista_electoral` (`id_lista`),
  CONSTRAINT `fk_cargo_proceso` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`),
  CONSTRAINT `chk_cargo_jurisdiccion` CHECK (`nivel_jurisdiccion` = 'UNIVERSIDAD' and `id_jurisdiccion` is null or `nivel_jurisdiccion` <> 'UNIVERSIDAD' and `id_jurisdiccion` is not null),
  CONSTRAINT `chk_cargo_porcentaje` CHECK (`porcentaje_minimo_victoria` >= 0 and `porcentaje_minimo_victoria` < 100)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cargo_electoral`
--

LOCK TABLES `cargo_electoral` WRITE;
/*!40000 ALTER TABLE `cargo_electoral` DISABLE KEYS */;
INSERT INTO `cargo_electoral` VALUES (1,1,'Jefe de Departamento Académico','DEPARTAMENTO',38,50.00,'ELEGIDO',2),(2,2,'Jefe de Departamento Académico','DEPARTAMENTO',38,50.00,'ELEGIDO',5);
/*!40000 ALTER TABLE `cargo_electoral` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_cargo_bi BEFORE INSERT ON cargo_electoral
FOR EACH ROW
BEGIN
  IF NEW.nivel_jurisdiccion = 'UNIVERSIDAD' THEN
    SET NEW.id_jurisdiccion = NULL;
  ELSEIF NEW.nivel_jurisdiccion = 'FACULTAD'
     AND NOT EXISTS (SELECT 1 FROM facultad WHERE id_facultad = NEW.id_jurisdiccion) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'La facultad indicada como jurisdiccion del cargo no existe.';
  ELSEIF NEW.nivel_jurisdiccion = 'DEPARTAMENTO'
     AND NOT EXISTS (SELECT 1 FROM departamento WHERE id_departamento = NEW.id_jurisdiccion) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El departamento indicado como jurisdiccion del cargo no existe.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_cargo_bu BEFORE UPDATE ON cargo_electoral
FOR EACH ROW
BEGIN
  IF NEW.nivel_jurisdiccion = 'UNIVERSIDAD' THEN
    SET NEW.id_jurisdiccion = NULL;
  ELSEIF NEW.nivel_jurisdiccion = 'FACULTAD'
     AND NOT EXISTS (SELECT 1 FROM facultad WHERE id_facultad = NEW.id_jurisdiccion) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'La facultad indicada como jurisdiccion del cargo no existe.';
  ELSEIF NEW.nivel_jurisdiccion = 'DEPARTAMENTO'
     AND NOT EXISTS (SELECT 1 FROM departamento WHERE id_departamento = NEW.id_jurisdiccion) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El departamento indicado como jurisdiccion del cargo no existe.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `cargo_excluido_sorteo`
--

DROP TABLE IF EXISTS `cargo_excluido_sorteo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cargo_excluido_sorteo` (
  `id_cargo_excluido` int(11) NOT NULL AUTO_INCREMENT,
  `id_catalogo_cargo` int(11) NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id_cargo_excluido`),
  UNIQUE KEY `uq_cargo_excluido_catalogo` (`id_catalogo_cargo`),
  CONSTRAINT `fk_cargo_excluido_catalogo` FOREIGN KEY (`id_catalogo_cargo`) REFERENCES `catalogo_cargo` (`id_catalogo_cargo`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cargo_excluido_sorteo`
--

LOCK TABLES `cargo_excluido_sorteo` WRITE;
/*!40000 ALTER TABLE `cargo_excluido_sorteo` DISABLE KEYS */;
INSERT INTO `cargo_excluido_sorteo` VALUES (1,7,1),(2,8,1),(3,5,1),(4,9,1),(5,6,1),(6,1,1),(7,4,1),(8,2,1),(9,3,1);
/*!40000 ALTER TABLE `cargo_excluido_sorteo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `catalogo_cargo`
--

DROP TABLE IF EXISTS `catalogo_cargo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `catalogo_cargo` (
  `id_catalogo_cargo` int(11) NOT NULL AUTO_INCREMENT,
  `nombre_cargo` varchar(150) NOT NULL,
  `nivel` varchar(80) NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id_catalogo_cargo`),
  UNIQUE KEY `uq_catalogo_cargo_nombre` (`nombre_cargo`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `catalogo_cargo`
--

LOCK TABLES `catalogo_cargo` WRITE;
/*!40000 ALTER TABLE `catalogo_cargo` DISABLE KEYS */;
INSERT INTO `catalogo_cargo` VALUES (1,'Rector y Vicerrectores (Fórmula)','UNIVERSIDAD',1),(2,'Vicerrector Académico','UNIVERSIDAD',0),(3,'Vicerrector de Investigación','UNIVERSIDAD',0),(4,'Secretario General','UNIVERSIDAD',1),(5,'Director de la Escuela de Posgrado','UNIVERSIDAD',1),(6,'Miembro del CEUNP','UNIVERSIDAD',1),(7,'Decano','FACULTAD',1),(8,'Director de Escuela Profesional','FACULTAD',1),(9,'Jefe de Departamento Académico','DEPARTAMENTO',1);
/*!40000 ALTER TABLE `catalogo_cargo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cierre_mesa`
--

DROP TABLE IF EXISTS `cierre_mesa`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cierre_mesa` (
  `id_mesa` int(11) NOT NULL,
  `estado` enum('VOTACION_CERRADA','AUSENTES_MARCADOS','ACTA_EMITIDA') NOT NULL DEFAULT 'VOTACION_CERRADA',
  `hora_cierre` datetime NOT NULL,
  `cierre_anticipado` tinyint(1) NOT NULL DEFAULT 0,
  `total_electores` int(11) NOT NULL,
  `total_votaron` int(11) NOT NULL,
  `total_no_votaron` int(11) NOT NULL,
  `asistieron_sin_votar` int(11) NOT NULL DEFAULT 0,
  `cedulas_recibidas` int(11) DEFAULT NULL,
  `cedulas_no_utilizadas` int(11) DEFAULT NULL,
  `firmas_lista_fisica` int(11) DEFAULT NULL,
  `observaciones` varchar(1000) DEFAULT NULL,
  `id_acta` int(11) DEFAULT NULL,
  `fecha_ausentes` datetime DEFAULT NULL,
  `fecha_acta` datetime DEFAULT NULL,
  `id_usuario_cierre` int(11) DEFAULT NULL,
  `id_usuario_ausentes` int(11) DEFAULT NULL,
  `id_usuario_acta` int(11) DEFAULT NULL,
  PRIMARY KEY (`id_mesa`),
  UNIQUE KEY `uq_cierre_acta` (`id_acta`),
  KEY `fk_cierre_usuario` (`id_usuario_cierre`),
  KEY `fk_cierre_ausentes` (`id_usuario_ausentes`),
  KEY `fk_cierre_emisor` (`id_usuario_acta`),
  CONSTRAINT `fk_cierre_acta` FOREIGN KEY (`id_acta`) REFERENCES `acta_electoral` (`id_acta`),
  CONSTRAINT `fk_cierre_ausentes` FOREIGN KEY (`id_usuario_ausentes`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `fk_cierre_emisor` FOREIGN KEY (`id_usuario_acta`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `fk_cierre_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`),
  CONSTRAINT `fk_cierre_usuario` FOREIGN KEY (`id_usuario_cierre`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `chk_cierre_totales` CHECK (`total_votaron` >= 0 and `total_no_votaron` >= 0 and `total_electores` >= 0),
  CONSTRAINT `chk_cierre_cedulas` CHECK (`cedulas_no_utilizadas` is null or `cedulas_no_utilizadas` >= 0),
  CONSTRAINT `chk_cierre_acta` CHECK (`estado` <> 'ACTA_EMITIDA' or `id_acta` is not null and `cedulas_no_utilizadas` is not null)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cierre_mesa`
--

LOCK TABLES `cierre_mesa` WRITE;
/*!40000 ALTER TABLE `cierre_mesa` DISABLE KEYS */;
INSERT INTO `cierre_mesa` VALUES (1,'ACTA_EMITIDA','2026-11-25 15:28:56',0,17,16,1,1,17,1,16,'un error en cabina por un elector',2,'2026-11-25 15:29:13','2026-11-25 15:31:59',110,110,3),(2,'ACTA_EMITIDA','2026-11-25 15:07:52',0,17,17,0,0,17,0,17,NULL,5,'2026-11-25 15:08:01','2026-11-25 15:08:38',118,118,118);
/*!40000 ALTER TABLE `cierre_mesa` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_cierre_bu BEFORE UPDATE ON cierre_mesa
FOR EACH ROW
BEGIN
  IF OLD.estado = 'ACTA_EMITIDA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS11: el acta de sufragio de esta mesa ya fue emitida.';
  END IF;
  IF NEW.hora_cierre <> OLD.hora_cierre OR NEW.total_votaron <> OLD.total_votaron THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS11: la hora de cierre y el total de votantes no se modifican.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_cierre_bd BEFORE DELETE ON cierre_mesa
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS11: el registro de cierre no se elimina.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `computo_estudiantil`
--

DROP TABLE IF EXISTS `computo_estudiantil`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `computo_estudiantil` (
  `id_proceso` int(11) NOT NULL,
  `id_cargo` int(11) NOT NULL,
  `id_lista` int(11) NOT NULL,
  `votos_estudiantes` int(11) NOT NULL DEFAULT 0,
  `fecha_registro` datetime NOT NULL DEFAULT current_timestamp(),
  `id_usuario` int(11) NOT NULL,
  PRIMARY KEY (`id_proceso`,`id_cargo`,`id_lista`),
  KEY `fk_comp_est_cargo` (`id_cargo`),
  KEY `fk_comp_est_lista` (`id_lista`),
  KEY `fk_comp_est_usuario` (`id_usuario`),
  CONSTRAINT `fk_comp_est_cargo` FOREIGN KEY (`id_cargo`) REFERENCES `cargo_electoral` (`id_cargo`),
  CONSTRAINT `fk_comp_est_lista` FOREIGN KEY (`id_lista`) REFERENCES `lista_electoral` (`id_lista`),
  CONSTRAINT `fk_comp_est_proceso` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`),
  CONSTRAINT `fk_comp_est_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `computo_estudiantil`
--

LOCK TABLES `computo_estudiantil` WRITE;
/*!40000 ALTER TABLE `computo_estudiantil` DISABLE KEYS */;
INSERT INTO `computo_estudiantil` VALUES (2,2,4,320,'2026-11-25 15:22:27',3),(2,2,5,180,'2026-11-25 15:22:26',3);
/*!40000 ALTER TABLE `computo_estudiantil` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `computo_personero`
--

DROP TABLE IF EXISTS `computo_personero`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `computo_personero` (
  `id_proceso` int(11) NOT NULL,
  `id_personero` int(11) NOT NULL,
  `hora_registro` datetime NOT NULL DEFAULT current_timestamp(),
  `id_usuario` int(11) DEFAULT NULL,
  PRIMARY KEY (`id_proceso`,`id_personero`),
  KEY `fk_cpers_personero` (`id_personero`),
  KEY `fk_cpers_usuario` (`id_usuario`),
  CONSTRAINT `fk_cpers_computo` FOREIGN KEY (`id_proceso`) REFERENCES `computo_proceso` (`id_proceso`),
  CONSTRAINT `fk_cpers_personero` FOREIGN KEY (`id_personero`) REFERENCES `personero` (`id_personero`),
  CONSTRAINT `fk_cpers_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `computo_personero`
--

LOCK TABLES `computo_personero` WRITE;
/*!40000 ALTER TABLE `computo_personero` DISABLE KEYS */;
/*!40000 ALTER TABLE `computo_personero` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_cpersonero_bi BEFORE INSERT ON computo_personero
FOR EACH ROW
BEGIN
  IF (SELECT estado FROM computo_proceso WHERE id_proceso = NEW.id_proceso) <> 'SESION_INSTALADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF91: el cómputo ya se realizó; no se registran más asistentes.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `computo_proceso`
--

DROP TABLE IF EXISTS `computo_proceso`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `computo_proceso` (
  `id_proceso` int(11) NOT NULL,
  `estado` enum('SESION_INSTALADA','COMPUTADO','PROCLAMADO','PUBLICADO') NOT NULL DEFAULT 'SESION_INSTALADA',
  `lugar_sesion` varchar(200) NOT NULL,
  `miembros_ceunp` tinyint(4) NOT NULL,
  `observaciones_sesion` varchar(1000) DEFAULT NULL,
  `fecha_sesion` datetime NOT NULL,
  `id_usuario_sesion` int(11) DEFAULT NULL,
  `fecha_computo` datetime DEFAULT NULL,
  `mesas_total` int(11) DEFAULT NULL,
  `mesas_computadas` int(11) DEFAULT NULL,
  `mesas_no_instaladas` int(11) DEFAULT NULL,
  `mesas_anuladas` int(11) DEFAULT NULL,
  `actas_verificadas` int(11) DEFAULT NULL,
  `electores_habiles` int(11) DEFAULT NULL,
  `votaron` int(11) DEFAULT NULL,
  `participacion_pct` decimal(5,2) DEFAULT NULL,
  `resultado` enum('VALIDA','NULIDAD_TOTAL') DEFAULT NULL,
  `contenido_json` longtext DEFAULT NULL,
  `hash_integridad` char(64) DEFAULT NULL,
  `token_qr_hash` char(64) DEFAULT NULL,
  `id_usuario_computo` int(11) DEFAULT NULL,
  `numero_resolucion` varchar(40) DEFAULT NULL,
  `miembros_pleno` tinyint(4) DEFAULT NULL,
  `presidente_ceunp` varchar(150) DEFAULT NULL,
  `fundamento_proclamacion` varchar(1000) DEFAULT NULL,
  `fecha_proclamacion` datetime DEFAULT NULL,
  `contenido_proclamacion` longtext DEFAULT NULL,
  `hash_proclamacion` char(64) DEFAULT NULL,
  `token_proclamacion_hash` char(64) DEFAULT NULL,
  `id_usuario_proclamacion` int(11) DEFAULT NULL,
  `fecha_publicacion` datetime DEFAULT NULL,
  `id_usuario_publicacion` int(11) DEFAULT NULL,
  PRIMARY KEY (`id_proceso`),
  UNIQUE KEY `uq_computo_token` (`token_qr_hash`),
  UNIQUE KEY `uq_computo_token_proclamacion` (`token_proclamacion_hash`),
  UNIQUE KEY `uq_computo_resolucion` (`numero_resolucion`),
  KEY `fk_computo_u_sesion` (`id_usuario_sesion`),
  KEY `fk_computo_u_computo` (`id_usuario_computo`),
  KEY `fk_computo_u_proclama` (`id_usuario_proclamacion`),
  KEY `fk_computo_u_publica` (`id_usuario_publicacion`),
  CONSTRAINT `fk_computo_proceso` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`),
  CONSTRAINT `fk_computo_u_computo` FOREIGN KEY (`id_usuario_computo`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `fk_computo_u_proclama` FOREIGN KEY (`id_usuario_proclamacion`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `fk_computo_u_publica` FOREIGN KEY (`id_usuario_publicacion`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `fk_computo_u_sesion` FOREIGN KEY (`id_usuario_sesion`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `chk_computo_json` CHECK (`contenido_json` is null or json_valid(`contenido_json`)),
  CONSTRAINT `chk_computo_proclamacion_json` CHECK (`contenido_proclamacion` is null or json_valid(`contenido_proclamacion`)),
  CONSTRAINT `chk_computo_acta` CHECK (`estado` = 'SESION_INSTALADA' or `fecha_computo` is not null and `contenido_json` is not null and `hash_integridad` is not null and `resultado` is not null),
  CONSTRAINT `chk_computo_publicado` CHECK (`estado` <> 'PUBLICADO' or `fecha_publicacion` is not null)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `computo_proceso`
--

LOCK TABLES `computo_proceso` WRITE;
/*!40000 ALTER TABLE `computo_proceso` DISABLE KEYS */;
INSERT INTO `computo_proceso` VALUES (1,'PUBLICADO','Sala de sesiones del CEUNP',5,NULL,'2026-11-25 15:54:20',3,'2026-11-25 15:54:29',1,1,0,0,3,17,16,94.12,'VALIDA','{\"tipo\":\"COMPUTO_GENERAL\",\"id_proceso\":1,\"proceso\":\"Elección de Jefe de Departamento de Informática 2026-II\",\"vuelta\":\"PRIMERA_VUELTA\",\"fecha_computo\":\"2026-11-25 15:54:29\",\"sesion\":{\"lugar\":\"Sala de sesiones del CEUNP\",\"miembros_ceunp\":5,\"inicio\":\"2026-11-25 15:54:20\",\"personeros\":[]},\"mesas\":{\"total\":1,\"computadas\":1,\"no_instaladas\":0,\"anuladas\":0},\"actas_verificadas\":3,\"actas_dudosas\":0,\"participacion\":{\"electores\":17,\"votaron\":16,\"porcentaje\":94.12,\"quorum_minimo\":60.00},\"resultado\":\"VALIDA\",\"cargos\":[{\"id_cargo\":1,\"cargo\":\"Jefe de Departamento Académico\",\"electores\":17,\"votaron\":16,\"participacion\":94.12,\"alcanza_quorum\":true,\"porcentaje_minimo\":50.00,\"validos\":15,\"validos_estudiantes\":0,\"ponderado\":false,\"blancos\":1,\"nulos\":0,\"emitidos\":16,\"estado_resultado\":\"ELEGIDO\",\"id_lista_ganadora\":2,\"lista_ganadora\":\"B\",\"opciones\":[{\"id_lista\":2,\"lista\":\"B\",\"orden\":2,\"votos\":11,\"votos_docentes\":11,\"votos_estudiantes\":0,\"porcentaje\":73.33,\"pct_docente\":73.33,\"pct_estudiante\":0.00,\"pct_ponderado\":73.33,\"posicion\":1},{\"id_lista\":1,\"lista\":\"A\",\"orden\":1,\"votos\":4,\"votos_docentes\":4,\"votos_estudiantes\":0,\"porcentaje\":26.67,\"pct_docente\":26.67,\"pct_estudiante\":0.00,\"pct_ponderado\":26.67,\"posicion\":2}]}],\"detalle_mesas\":[{\"mesa\": \"001\", \"ubicacion\": \"Biblioteca Central\", \"situacion\": \"HABILITADA\", \"electores\": 17, \"votaron\": 16, \"calificacion\": \"VALIDA\", \"resolucion\": null, \"codigo_entrega\": \"885A91ACD4A5\"}]}','a590ad482762680778d46411de5486184a94509a107eb54a3429454cfefe5b72','ac1ee2e312052367e26a1f9554731176eb40bee7c29e2aab47047d346586488f',3,'XXXX',5,'lucano','xddddddd','2026-11-25 15:56:58','{\"tipo\":\"PROCLAMACION\",\"id_proceso\":1,\"proceso\":\"Elección de Jefe de Departamento de Informática 2026-II\",\"resolucion\":\"XXXX\",\"fecha\":\"2026-11-25 15:56:58\",\"presidente_ceunp\":\"lucano\",\"miembros_pleno\":5,\"hash_acta_general\":\"a590ad482762680778d46411de5486184a94509a107eb54a3429454cfefe5b72\",\"proclamados\":[{\"id_cargo\":1,\"cargo\":\"Jefe de Departamento Académico\",\"id_lista\":2,\"lista\":\"B\",\"votos\":11,\"porcentaje\":73.33,\"codigo_credencial\":\"F64428F5F4FC\",\"candidatos\":[{\"rol\": \"JEFE_DEPARTAMENTO\", \"nombre\": \"Iván Daniel Imán Agurto\", \"dni\": \"02867046\"}]}],\"sin_proclamar\":[],\"fundamento\":\"xddddddd\"}','f9db1e3023a92d809b3eb09068a45594acb8d05d20ad64e8ad33afb245a8b80f','b7497d3d86d5b10419dbce35beaac1dc84fd82c994d4f1aab8c408e555238230',3,'2026-11-25 16:00:50',3),(2,'PUBLICADO','Sala de sesiones del CEUNP',5,'ninguna','2026-11-25 15:16:27',3,'2026-11-25 15:24:29',1,1,0,0,3,17,17,100.00,'VALIDA','{\"tipo\":\"COMPUTO_GENERAL\",\"id_proceso\":2,\"proceso\":\"Elección de Jefe de Departamento de Informática 2026-II\",\"vuelta\":\"PRIMERA_VUELTA\",\"fecha_computo\":\"2026-11-25 15:24:29\",\"sesion\":{\"lugar\":\"Sala de sesiones del CEUNP\",\"miembros_ceunp\":5,\"inicio\":\"2026-11-25 15:16:27\",\"personeros\":[]},\"mesas\":{\"total\":1,\"computadas\":1,\"no_instaladas\":0,\"anuladas\":0},\"actas_verificadas\":3,\"actas_dudosas\":0,\"participacion\":{\"electores\":17,\"votaron\":17,\"porcentaje\":100.00,\"quorum_minimo\":60.00},\"resultado\":\"VALIDA\",\"cargos\":[{\"id_cargo\":2,\"cargo\":\"Jefe de Departamento Académico\",\"electores\":17,\"votaron\":17,\"participacion\":100.00,\"alcanza_quorum\":true,\"porcentaje_minimo\":50.00,\"validos\":17,\"validos_estudiantes\":500,\"ponderado\":true,\"blancos\":0,\"nulos\":0,\"emitidos\":17,\"estado_resultado\":\"ELEGIDO\",\"id_lista_ganadora\":5,\"lista_ganadora\":\"Avance TI\",\"opciones\":[{\"id_lista\":5,\"lista\":\"Avance TI\",\"orden\":1,\"votos\":13,\"votos_docentes\":13,\"votos_estudiantes\":180,\"porcentaje\":62.98,\"pct_docente\":76.47,\"pct_estudiante\":36.00,\"pct_ponderado\":62.98,\"posicion\":1},{\"id_lista\":4,\"lista\":\"Innovación Informática\",\"orden\":2,\"votos\":4,\"votos_docentes\":4,\"votos_estudiantes\":320,\"porcentaje\":37.02,\"pct_docente\":23.53,\"pct_estudiante\":64.00,\"pct_ponderado\":37.02,\"posicion\":2}]}],\"detalle_mesas\":[{\"mesa\": \"001\", \"ubicacion\": \"Biblioteca Central\", \"situacion\": \"HABILITADA\", \"electores\": 17, \"votaron\": 17, \"calificacion\": null, \"resolucion\": null, \"codigo_entrega\": \"62A8894A7B9C\"}]}','087293f3b6b2ba4b3b0436a49fac168713be3232848a6c0d3bae53cdf5a7dcce','0589f9ce1f484f1686df8e4811b3753864f2e762ab37abfcc0c60b6bb03904b4',3,'RES-CEUNP-2027 RE4FORLITE',5,'Leandro Emanuel Peña Avila',NULL,'2026-11-25 15:26:44','{\"tipo\":\"PROCLAMACION\",\"id_proceso\":2,\"proceso\":\"Elección de Jefe de Departamento de Informática 2026-II\",\"resolucion\":\"RES-CEUNP-2027 RE4FORLITE\",\"fecha\":\"2026-11-25 15:26:44\",\"presidente_ceunp\":\"Leandro Emanuel Peña Avila\",\"miembros_pleno\":5,\"hash_acta_general\":\"087293f3b6b2ba4b3b0436a49fac168713be3232848a6c0d3bae53cdf5a7dcce\",\"proclamados\":[{\"id_cargo\":2,\"cargo\":\"Jefe de Departamento Académico\",\"id_lista\":5,\"lista\":\"Avance TI\",\"votos\":13,\"porcentaje\":62.98,\"codigo_credencial\":\"05EF7A5ED5DA\",\"candidatos\":[{\"rol\": \"JEFE_DEPARTAMENTO\", \"nombre\": \"Iván Daniel Imán Agurto\", \"dni\": \"02867046\"}]}],\"sin_proclamar\":[],\"fundamento\":null}','2512bc2d2365cfaae33de3a5663552dde9a2f8b9a9a294d5ff715702655676f9','09663cacb9b851150c1e36991076965b691f849cdbd8a14b72d1a13c99965756',3,'2026-11-25 15:27:47',3);
/*!40000 ALTER TABLE `computo_proceso` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_computo_bu BEFORE UPDATE ON computo_proceso
FOR EACH ROW
BEGIN
  IF OLD.estado = 'PUBLICADO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF99: los resultados ya se publicaron; el cómputo no cambia.';
  END IF;
  IF NOT (NEW.lugar_sesion <=> OLD.lugar_sesion) OR NOT (NEW.miembros_ceunp <=> OLD.miembros_ceunp)
     OR NOT (NEW.fecha_sesion <=> OLD.fecha_sesion) OR NOT (NEW.id_proceso <=> OLD.id_proceso) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF91: los datos de la sesión de cómputo no se modifican.';
  END IF;
  IF OLD.estado <> 'SESION_INSTALADA' AND (NOT (NEW.contenido_json <=> OLD.contenido_json)
     OR NOT (NEW.hash_integridad <=> OLD.hash_integridad) OR NOT (NEW.token_qr_hash <=> OLD.token_qr_hash)
     OR NOT (NEW.fecha_computo <=> OLD.fecha_computo) OR NOT (NEW.resultado <=> OLD.resultado)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el cómputo oficial y su acta general son irreversibles.';
  END IF;
  IF OLD.estado IN ('PROCLAMADO','PUBLICADO') AND (NOT (NEW.numero_resolucion <=> OLD.numero_resolucion)
     OR NOT (NEW.contenido_proclamacion <=> OLD.contenido_proclamacion) OR NOT (NEW.hash_proclamacion <=> OLD.hash_proclamacion)
     OR NOT (NEW.fecha_proclamacion <=> OLD.fecha_proclamacion)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF98: la proclamación ya fue registrada.';
  END IF;
  IF FIELD(NEW.estado, 'SESION_INSTALADA','COMPUTADO','PROCLAMADO','PUBLICADO')
     < FIELD(OLD.estado, 'SESION_INSTALADA','COMPUTADO','PROCLAMADO','PUBLICADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el cómputo no retrocede de etapa.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_computo_bu_cus15 BEFORE UPDATE ON computo_proceso
FOR EACH ROW
BEGIN
  IF OLD.estado = 'SESION_INSTALADA' AND NEW.estado <> 'SESION_INSTALADA'
     AND EXISTS (SELECT 1 FROM nulidad_electoral WHERE id_proceso = NEW.id_proceso AND estado = 'PRESENTADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF94: hay recursos de nulidad pendientes; resuélvalos antes del cómputo (CUS15).';
  END IF;
  IF OLD.estado = 'COMPUTADO' AND NEW.estado = 'PROCLAMADO'
     AND EXISTS (SELECT 1 FROM nulidad_electoral WHERE id_proceso = NEW.id_proceso AND alcance = 'TOTAL' AND estado = 'PRESENTADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF94: hay un recurso de nulidad total pendiente; resuélvalo antes de proclamar (CUS15).';
  END IF;
  IF NEW.numero_resolucion IS NOT NULL AND NOT (NEW.numero_resolucion <=> OLD.numero_resolucion)
     AND (EXISTS (SELECT 1 FROM nulidad_electoral WHERE numero_resolucion = NEW.numero_resolucion)
          OR EXISTS (SELECT 1 FROM dirimencia_empate WHERE numero_resolucion = NEW.numero_resolucion)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_computo_bu_cus16 BEFORE UPDATE ON computo_proceso
FOR EACH ROW
BEGIN
  IF NEW.numero_resolucion IS NOT NULL AND NOT (NEW.numero_resolucion <=> OLD.numero_resolucion)
     AND (EXISTS (SELECT 1 FROM reporte_multas WHERE numero_resolucion = NEW.numero_resolucion)
          OR EXISTS (SELECT 1 FROM multa_justificacion WHERE numero_resolucion = NEW.numero_resolucion)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_computo_bd BEFORE DELETE ON computo_proceso
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el registro del cómputo no se elimina.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `constancia_pendiente`
--

DROP TABLE IF EXISTS `constancia_pendiente`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `constancia_pendiente` (
  `id_proceso` int(11) NOT NULL,
  `id_docente` int(11) NOT NULL,
  `id_mesa` int(11) NOT NULL,
  `cargos_json` text NOT NULL,
  `fecha_emision` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_proceso`,`id_docente`),
  KEY `fk_constancia_pend_docente` (`id_docente`),
  KEY `fk_constancia_pend_mesa` (`id_mesa`),
  CONSTRAINT `fk_constancia_pend_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`),
  CONSTRAINT `fk_constancia_pend_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `constancia_pendiente`
--

LOCK TABLES `constancia_pendiente` WRITE;
/*!40000 ALTER TABLE `constancia_pendiente` DISABLE KEYS */;
INSERT INTO `constancia_pendiente` VALUES (1,102,1,'[{\"token\":\"94803c60b6bcdef88e3f1756852a35bdb4db0b9b961611cc279b28008626f138\",\"cargo\":\"Jefe de Departamento Académico\",\"idCargo\":1}]','2026-11-25 10:02:24'),(1,103,1,'[{\"token\":\"3349e987b5d5d14d0da586f4bdfc5fc6e585200704dc195fb86ba5ed8edf56e6\",\"idCargo\":1,\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 10:10:30'),(1,104,1,'[{\"token\":\"c6a5e52f93337b12a3cb33af573998105052246bdf9bbf64513a274500dbde6c\",\"idCargo\":1,\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 10:10:58'),(1,105,1,'[{\"token\":\"6faf72779ba05203fb8e891701b420dabc25110bd23b8065eaf4f8836b45d743\",\"idCargo\":1,\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 10:11:31'),(1,106,1,'[{\"token\":\"2b3fb34df222f5a2abaced487d6a6354d88d26f94040e7a1f85fd33ba6d820a2\",\"idCargo\":1,\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 10:18:43'),(1,107,1,'[{\"token\":\"c7480470c26842689e0feb1520e70a545608b17e6952ea2105bbad20950f2ff1\",\"idCargo\":1,\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 10:19:03'),(1,108,1,'[{\"token\":\"f970afcba2fbd30c7e776d17257d5a88a74db4a10ccf085acdf8294ee3046fc1\",\"cargo\":\"Jefe de Departamento Académico\",\"idCargo\":1}]','2026-11-25 09:44:02'),(1,109,1,'[{\"token\":\"4142ce7c1d9c6e6ec215ad2d4b48382f2d4ea92e842e1deb899e004e74a854e9\",\"idCargo\":1,\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 10:19:23'),(1,110,1,'[{\"token\":\"b90a5a81459a4cebda5a91c1c2fa71d3f18f217855575df496fd0ab306b908f2\",\"idCargo\":1,\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 10:20:11'),(1,111,1,'[{\"idCargo\":1,\"token\":\"edbd01d0eba0d951410c1642b1a61b215fe77e0726a26a313504f6e0cbb6b633\",\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 10:26:51'),(1,112,1,'[{\"idCargo\":1,\"token\":\"66eb91a7a7d924c28c9e88cfa15ff1d4e07292d0463e41f5c1c3f7dc2cecc9a5\",\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 10:27:05'),(1,113,1,'[{\"idCargo\":1,\"token\":\"8390c19afd3b1b5f3aa197fad1dd0668b9682d3f1a7d0983d901c1cb8f235987\",\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 10:27:19'),(1,114,1,'[{\"idCargo\":1,\"token\":\"b8b6879cbd649b6cde1a549ae8b7d293c2595f382b5baddc7c7ddc8403586fe1\",\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 10:28:17'),(1,115,1,'[{\"idCargo\":1,\"token\":\"ea11c1194f36b6595213994980c5415823f60d07222cdc0222b2a092e516403f\",\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 10:28:27'),(1,116,1,'[{\"idCargo\":1,\"token\":\"61cfdaf1c3b0fe5f8eb8f50e0a4da41ac2acaa5dc7af3057085ddc897ade57ed\",\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 10:28:38'),(1,117,1,'[{\"idCargo\":1,\"token\":\"f832723b637457801f4e564b18f796677ed87c5a9ce1dd1160f285fda704f3e2\",\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 10:28:50'),(2,101,2,'[{\"idCargo\":2,\"token\":\"ba81c8d2e6d735b974bb49c490938a32c7eb6edf4c3946ab88d473b8cb4631ce\",\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 09:21:25'),(2,102,2,'[{\"idCargo\":2,\"token\":\"a09212628693cadc53828b5f568e60d11c117ec68d5f0356f425959b6dd3c61e\",\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 09:21:52'),(2,103,2,'[{\"idCargo\":2,\"token\":\"888c6409afe4a96107eeb81b140f88772c199568047d3afa2036f0d519268484\",\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 09:22:10'),(2,104,2,'[{\"idCargo\":2,\"token\":\"d78b2505f7e98a00bbe63c5f1f0a86e899053555c6d3ad50d99e786c94a68380\",\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 09:22:26'),(2,105,2,'[{\"idCargo\":2,\"token\":\"b10704f0c4bdc4b4002646c3b8765f1cd826c4787793ef364c5b5adf1dc3fec3\",\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 09:22:40'),(2,106,2,'[{\"idCargo\":2,\"token\":\"26f24b0246343bb4972f32d78905331de2f564f857e6677503c7b880c35a4a23\",\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 09:26:38'),(2,107,2,'[{\"idCargo\":2,\"token\":\"8aee3e64ee107dd779b436b83215dd59c395c0b226b5a98f134b2428db5cad8e\",\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 09:26:54'),(2,108,2,'[{\"idCargo\":2,\"token\":\"76ac9f698c637e80b0274f71e68e6fdb03eeb13b313f08ca76c7cd67f202f750\",\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 09:27:07'),(2,109,2,'[{\"idCargo\":2,\"token\":\"7ef74c27d31495f7dab3c8c0f53e47eeacb7962246a7943a4414823d1504ec86\",\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 09:27:17'),(2,110,2,'[{\"idCargo\":2,\"token\":\"c2b25a59ddb5ab851301b05e5ed451fe3c3ecf7f4747bf2d820227937d81705b\",\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 09:27:26'),(2,111,2,'[{\"idCargo\":2,\"token\":\"6a168890b2474ceeef4cdd2b3426877f87059b73a21ebe0ebe31290930c36b9b\",\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 09:27:39'),(2,112,2,'[{\"idCargo\":2,\"token\":\"8e0b7908b7b25ec3880cef22054a2e5061d1beeab49c5977da724cb41bb7b914\",\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 09:27:48'),(2,113,2,'[{\"idCargo\":2,\"token\":\"167384e7a59a626732bcd5dee76b9858d0a4791b33c915054bf2370b962eb50f\",\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 09:28:02'),(2,114,2,'[{\"idCargo\":2,\"token\":\"9a8930903a705629b21e27d206b625d0013d27b30a3288629953fdefd55e0dc8\",\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 09:28:12'),(2,115,2,'[{\"idCargo\":2,\"token\":\"1d97b384024bfe2d765fce50769223f1d96585b9ac2889617afebc32b2831aba\",\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 09:28:21'),(2,116,2,'[{\"idCargo\":2,\"token\":\"c2c504ce9f015439b50d6b9717e4f4bc06b7e0722dd19ed9d4ea1e583df8980e\",\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 09:28:37'),(2,117,2,'[{\"idCargo\":2,\"token\":\"e99ccf85308ce71cb275e8494d9143f1dd7405615115737baeb1ca99eb285302\",\"cargo\":\"Jefe de Departamento Académico\"}]','2026-11-25 09:28:47');
/*!40000 ALTER TABLE `constancia_pendiente` ENABLE KEYS */;
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
  UNIQUE KEY `uq_constancia_token` (`token_qr_hash`),
  UNIQUE KEY `uq_constancia_participacion` (`id_proceso`,`id_docente`,`id_cargo`),
  KEY `fk_constancia_cargo_proceso` (`id_cargo`,`id_proceso`),
  KEY `fk_constancia_docente` (`id_docente`),
  CONSTRAINT `fk_constancia_cargo_proceso` FOREIGN KEY (`id_cargo`, `id_proceso`) REFERENCES `cargo_electoral` (`id_cargo`, `id_proceso`),
  CONSTRAINT `fk_constancia_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`)
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `constancia_voto`
--

LOCK TABLES `constancia_voto` WRITE;
/*!40000 ALTER TABLE `constancia_voto` DISABLE KEYS */;
INSERT INTO `constancia_voto` VALUES (1,1,108,1,'f8c40ecc7333a1c158f8712c097b7f121e2c234da5e18ea7410857d1b79d6a86','2026-11-25 09:44:02',NULL,'VIGENTE'),(2,1,102,1,'5acd87888a6d7adbef020c343935ad3c816bd4774bc33a7fe6d83aeb1f8026b9','2026-11-25 10:02:24',NULL,'VIGENTE'),(3,1,103,1,'6fa7c7ddc82f1b80cef1a2906637f0192d94f1f01c037869683cb9f76dd34301','2026-11-25 10:10:30',NULL,'VIGENTE'),(4,1,104,1,'4ca0d16488d4a006e537664b6ce7d185fe708e1ccf9dc40633a7ea120b1abbd6','2026-11-25 10:10:58',NULL,'VIGENTE'),(5,1,105,1,'9cd4e5bd473d02c1b08316a09edac5561324fd710ad523342b4e273574641adf','2026-11-25 10:11:31',NULL,'VIGENTE'),(6,1,106,1,'41e43b5d2f9967f4427342b1206763f8f262ed23c1785f1cc9fcf3ffb80e6b79','2026-11-25 10:18:43',NULL,'VIGENTE'),(7,1,107,1,'17bc83735fbda4960b3fd84a8a4ec7cdb46099c3f81fa928d91e2d7ef6b05039','2026-11-25 10:19:03',NULL,'VIGENTE'),(8,1,109,1,'18d9e03899e546cf5c6daa963f4e340a557b9be16b1b6236a6dc120851f19636','2026-11-25 10:19:23',NULL,'VIGENTE'),(9,1,110,1,'8af0b3e72ee8a4a3fc24e3fc479a0b1a4963e81f75a9e85d0c7451858ac5bd2b','2026-11-25 10:20:11',NULL,'VIGENTE'),(10,1,111,1,'767e08420eb6bd2b680b7818448d093742eae8712914db2de0a3c7b94d21dcfe','2026-11-25 10:26:51',NULL,'VIGENTE'),(11,1,112,1,'de5afc336af8937b7a27406000941c47f5b131384cd30c0d50fd64dd6e00992c','2026-11-25 10:27:05',NULL,'VIGENTE'),(12,1,113,1,'17bdc4b2f013af1a7085d2a1cfe48fc083550e6dcb729a330982d12b80a123a3','2026-11-25 10:27:18',NULL,'VIGENTE'),(13,1,114,1,'095e3bf39074b994a1e3b972842fc523d1a3876b04c742758c6db782ea367d9e','2026-11-25 10:28:17',NULL,'VIGENTE'),(14,1,115,1,'40cd2f86d5b001a0049ecf3bfbc8a57eb8af317ccd8b44a84326b0841616eb22','2026-11-25 10:28:27',NULL,'VIGENTE'),(15,1,116,1,'e9d711f9fd4afd7e6c2af441d9baf4564bb36e79c8ad8438627d8529f20d00b2','2026-11-25 10:28:38',NULL,'VIGENTE'),(16,1,117,1,'ca79c03acf0c2e376d7e95889ca00a8aab5aa2af7d4d2e426a7fe33e79b698ec','2026-11-25 10:28:50',NULL,'VIGENTE'),(17,2,101,2,'77119173513d279266ccd4f4bfa46590f1235b4fd02b0cee14c58ac6aa6c5696','2026-11-25 09:21:25',NULL,'VIGENTE'),(18,2,102,2,'0a8cf0facd4565bb4767ea4272c6a3c67f5e15b6ea7c79ce1951043528ea258a','2026-11-25 09:21:52',NULL,'VIGENTE'),(19,2,103,2,'986e196f7c1f35c7911d13afda61e969292939d7f4922e070f23f3063c98026e','2026-11-25 09:22:10',NULL,'VIGENTE'),(20,2,104,2,'a7de3c7770f53c11a3f5892e3e8950acc54bd922fdc220eb02c017ef75db7a41','2026-11-25 09:22:26',NULL,'VIGENTE'),(21,2,105,2,'7ce4a2876ea15e105075ece466bde40843bf3f45da6732dfd2eda372dd600895','2026-11-25 09:22:40',NULL,'VIGENTE'),(22,2,106,2,'4d2a34648306e7e17903b06dc70df0ea40a98d8d3a19be30b9b5970a6f75c830','2026-11-25 09:26:38',NULL,'VIGENTE'),(23,2,107,2,'d07255be2d372885b8bbea5b7fcf71d72a39036052fed6feee3ab67f0996bf32','2026-11-25 09:26:54',NULL,'VIGENTE'),(24,2,108,2,'09fd2c882e8b0d098193d4a145ee772065c7b5423683714e58942a1cf93f8067','2026-11-25 09:27:07',NULL,'VIGENTE'),(25,2,109,2,'f91817c6880e84ee540735e63e2050733fcadbea84de19ef631f61fc73c85e43','2026-11-25 09:27:17',NULL,'VIGENTE'),(26,2,110,2,'6a64aa67f1e1e77999cee790030765c088d9e50cbee776489149fef44efdaa95','2026-11-25 09:27:26',NULL,'VIGENTE'),(27,2,111,2,'64246e2e1c4f0e8ba8d7a29828ff2c61ab01dd6100f48a91188dad3b315b68d7','2026-11-25 09:27:39',NULL,'VIGENTE'),(28,2,112,2,'fb2cd7a57d5b7aa9be6a67ca8605eea9ac98c1f2c93158d9504cf5c4f62671a8','2026-11-25 09:27:48',NULL,'VIGENTE'),(29,2,113,2,'c1162e36fc268af06bf68a32f0d8d45b3eb792814f75baaf1745f2c7adf6b08b','2026-11-25 09:28:02',NULL,'VIGENTE'),(30,2,114,2,'83b2c3a251052d87622f6f09c2120638021b91159a8d1afefab1b9aa6b5be491','2026-11-25 09:28:12',NULL,'VIGENTE'),(31,2,115,2,'0949650f9c6813dc2f7886cc14e35795b3e12daea8988a63bd1d482936b26b0b','2026-11-25 09:28:21',NULL,'VIGENTE'),(32,2,116,2,'60dd14a529de5b9c37f20b15136ec48534aed5cc7b021d0cba1193e74ad24717','2026-11-25 09:28:37',NULL,'VIGENTE'),(33,2,117,2,'3f86a8f229402ce12d011294eef9489db82e4011130b2a892f8d490e4ba8cddc','2026-11-25 09:28:47',NULL,'VIGENTE');
/*!40000 ALTER TABLE `constancia_voto` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cotejo_acta`
--

DROP TABLE IF EXISTS `cotejo_acta`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cotejo_acta` (
  `id_cotejo` int(11) NOT NULL AUTO_INCREMENT,
  `id_verificacion` bigint(20) DEFAULT NULL,
  `tipo_documento` varchar(30) NOT NULL,
  `id_documento` int(11) NOT NULL,
  `id_proceso` int(11) NOT NULL,
  `id_mesa` int(11) DEFAULT NULL,
  `hash_integridad` char(64) NOT NULL,
  `contenido_integro` tinyint(1) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `rol` varchar(20) NOT NULL,
  `id_personero` int(11) DEFAULT NULL,
  `cifras_json` longtext NOT NULL,
  `lineas` int(11) NOT NULL,
  `diferencias` int(11) NOT NULL,
  `observacion` varchar(1000) DEFAULT NULL,
  `estado` enum('CONFORME','OBSERVADO','ATENDIDO') NOT NULL,
  `fecha` datetime NOT NULL,
  `decision` enum('ACLARADA','FUNDADA') DEFAULT NULL,
  `respuesta` varchar(1000) DEFAULT NULL,
  `fecha_respuesta` datetime DEFAULT NULL,
  `id_usuario_respuesta` int(11) DEFAULT NULL,
  PRIMARY KEY (`id_cotejo`),
  KEY `ix_cotejo_proceso` (`id_proceso`,`estado`),
  KEY `ix_cotejo_documento` (`tipo_documento`,`id_documento`),
  KEY `ix_cotejo_usuario` (`id_usuario`),
  KEY `fk_cotejo_verificacion` (`id_verificacion`),
  KEY `fk_cotejo_mesa` (`id_mesa`),
  KEY `fk_cotejo_personero` (`id_personero`),
  KEY `fk_cotejo_u_respuesta` (`id_usuario_respuesta`),
  CONSTRAINT `fk_cotejo_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`),
  CONSTRAINT `fk_cotejo_personero` FOREIGN KEY (`id_personero`) REFERENCES `personero` (`id_personero`),
  CONSTRAINT `fk_cotejo_proceso` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`),
  CONSTRAINT `fk_cotejo_u_respuesta` FOREIGN KEY (`id_usuario_respuesta`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `fk_cotejo_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `fk_cotejo_verificacion` FOREIGN KEY (`id_verificacion`) REFERENCES `verificacion_documento` (`id_verificacion`),
  CONSTRAINT `chk_cotejo_json` CHECK (json_valid(`cifras_json`)),
  CONSTRAINT `chk_cotejo_cifras` CHECK (`lineas` > 0 and `diferencias` >= 0 and `diferencias` <= `lineas`),
  CONSTRAINT `chk_cotejo_estado` CHECK (`estado` = 'CONFORME' and `diferencias` = 0 and `contenido_integro` = 1 or `estado` in ('OBSERVADO','ATENDIDO') and `observacion` is not null),
  CONSTRAINT `chk_cotejo_atendido` CHECK (`estado` = 'ATENDIDO' = (`decision` is not null and `respuesta` is not null and `fecha_respuesta` is not null))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cotejo_acta`
--

LOCK TABLES `cotejo_acta` WRITE;
/*!40000 ALTER TABLE `cotejo_acta` DISABLE KEYS */;
/*!40000 ALTER TABLE `cotejo_acta` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_cotejo_bu BEFORE UPDATE ON cotejo_acta
FOR EACH ROW
BEGIN
  IF OLD.estado <> 'OBSERVADO' OR NEW.estado <> 'ATENDIDO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: el cotejo solo cambia cuando el CEUNP atiende la discrepancia reportada.';
  END IF;
  IF NOT (NEW.cifras_json <=> OLD.cifras_json AND NEW.diferencias <=> OLD.diferencias AND NEW.observacion <=> OLD.observacion
          AND NEW.id_usuario <=> OLD.id_usuario AND NEW.id_documento <=> OLD.id_documento AND NEW.fecha <=> OLD.fecha
          AND NEW.hash_integridad <=> OLD.hash_integridad) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: las cifras anotadas en el cotejo no se modifican.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_cotejo_bd BEFORE DELETE ON cotejo_acta
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: el cotejo del acta no se elimina.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `credencial_qr`
--

DROP TABLE IF EXISTS `credencial_qr`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `credencial_qr` (
  `id_credencial` bigint(20) NOT NULL AUTO_INCREMENT,
  `id_proceso` int(11) NOT NULL,
  `id_docente` int(11) NOT NULL,
  `tipo` enum('ELECTOR','MIEMBRO_MESA','PERSONERO') NOT NULL,
  `id_mesa` int(11) DEFAULT NULL,
  `id_personero` int(11) DEFAULT NULL,
  `token_qr_hash` char(64) NOT NULL,
  `codigo_qr` varchar(255) DEFAULT NULL,
  `fecha_emision` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_expiracion` datetime NOT NULL,
  `estado` enum('VIGENTE','REVOCADA') NOT NULL DEFAULT 'VIGENTE',
  `fecha_revocacion` datetime DEFAULT NULL,
  `motivo_revocacion` varchar(255) DEFAULT NULL,
  `id_usuario_emisor` int(11) DEFAULT NULL,
  `usos` int(11) NOT NULL DEFAULT 0,
  `ultimo_uso` datetime DEFAULT NULL,
  `clave_vigente` varchar(80) GENERATED ALWAYS AS (if(`estado` = 'VIGENTE',concat_ws(':',`id_proceso`,`id_docente`,`tipo`,case `tipo` when 'PERSONERO' then `id_personero` when 'MIEMBRO_MESA' then `id_mesa` else 0 end),NULL)) STORED,
  PRIMARY KEY (`id_credencial`),
  UNIQUE KEY `uq_credencial_token` (`token_qr_hash`),
  UNIQUE KEY `uq_credencial_vigente` (`clave_vigente`),
  KEY `ix_credencial_titular` (`id_proceso`,`tipo`,`id_docente`),
  KEY `ix_credencial_docente` (`id_docente`,`estado`),
  KEY `fk_credencial_mesa` (`id_mesa`),
  KEY `fk_credencial_personero` (`id_personero`),
  KEY `fk_credencial_emisor` (`id_usuario_emisor`),
  CONSTRAINT `fk_credencial_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`),
  CONSTRAINT `fk_credencial_emisor` FOREIGN KEY (`id_usuario_emisor`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `fk_credencial_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`),
  CONSTRAINT `fk_credencial_personero` FOREIGN KEY (`id_personero`) REFERENCES `personero` (`id_personero`),
  CONSTRAINT `fk_credencial_proceso` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`),
  CONSTRAINT `chk_credencial_hash` CHECK (`token_qr_hash` regexp '^[0-9a-f]{64}$'),
  CONSTRAINT `chk_credencial_tipo` CHECK (`tipo` = 'PERSONERO' and `id_personero` is not null or `tipo` = 'MIEMBRO_MESA' and `id_personero` is null and `id_mesa` is not null or `tipo` = 'ELECTOR' and `id_personero` is null),
  CONSTRAINT `chk_credencial_revocacion` CHECK (`estado` = 'VIGENTE' or `fecha_revocacion` is not null)
) ENGINE=InnoDB AUTO_INCREMENT=47 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `credencial_qr`
--

LOCK TABLES `credencial_qr` WRITE;
/*!40000 ALTER TABLE `credencial_qr` DISABLE KEYS */;
INSERT INTO `credencial_qr` VALUES (1,1,101,'ELECTOR',1,NULL,'6855ca742a6664f2078623dabd9e122c2da8c7ffce1aa5ba3387660f47866ba9','SICEUNP|E|6ba897ce55f76ba4ea20ee5812b82d1ffa1babd110fe19a445ace78adc31c8f4','2026-10-20 11:44:30','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'1:101:ELECTOR:0'),(2,1,102,'ELECTOR',1,NULL,'6093406f1c7d9b2430b1eb42e7cc34f84bab7d89125dbde6cf46228f8b6e1dd9','SICEUNP|E|77eb73ea1ea79399c4d4f3314dfdb1d5e78173a2a14f07066077e6b6aba6868c','2026-10-20 11:44:30','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'1:102:ELECTOR:0'),(3,1,103,'ELECTOR',1,NULL,'c8a19bce40f621c0f6d84868d4beb2d2868ef9f782689af2c9d135ce970998c0','SICEUNP|E|dc4deb6401dd7d029d652e63746a8546d7a0db655004fa6586cc624ea41d281b','2026-10-20 11:44:30','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'1:103:ELECTOR:0'),(4,1,104,'ELECTOR',1,NULL,'cb196a098dca9b5e80ed850e1bacfb42e7301f7ac4dda193c08223a611c9f981','SICEUNP|E|bac025e7b0a676bcdb15ea1dc15034900f95de709eb0dc7c9907f9fb730f82f5','2026-10-20 11:44:30','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'1:104:ELECTOR:0'),(5,1,105,'ELECTOR',1,NULL,'196e56b8f3d779d9797a4de626b3a73d61e2191f1f5eb438b3267359f66531d0','SICEUNP|E|0a856e44723a1e0742e16a0a851601584a6ee422866fac019eaa79f1b2018fbd','2026-10-20 11:44:30','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'1:105:ELECTOR:0'),(6,1,106,'ELECTOR',1,NULL,'b3843db19a389775ea0830fdffc257d9888fdf4cc76a057ecca2d4ea3138a859','SICEUNP|E|7e0937087b7b966a7b73c3fa5ea6a9feed6988dede35f3a4aeea4698221d26a7','2026-10-20 11:44:30','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'1:106:ELECTOR:0'),(7,1,107,'ELECTOR',1,NULL,'f22bf62ace05690f75d343ae6fc5ec963a402efe1ad65e29840ebebfcb4ddced','SICEUNP|E|dbaacde42bedd480e071e022400b1a3a7ffe0c43a08e1e21350f87939f84aa89','2026-10-20 11:44:30','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'1:107:ELECTOR:0'),(8,1,108,'ELECTOR',1,NULL,'5869ded03a6290f2e9e0681116065e14025fd1407bc95d32a3a2af3f569fdaff','SICEUNP|E|304d5f28eff14540acb49db7c3ba649a6e77df186cddc4d5b0e8e749ef5cfeb1','2026-10-20 11:44:30','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,1,'2026-11-25 09:36:48','1:108:ELECTOR:0'),(9,1,109,'ELECTOR',1,NULL,'f7689b785bbf0ccc94024c717e651f42d243d47a67ca3d24c4b554ee1a9eb9ba','SICEUNP|E|ffe8275588d513c8b33ca56d65781ce1b0e5a84e3b40cfc26878d29fd3c493b1','2026-10-20 11:44:30','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'1:109:ELECTOR:0'),(10,1,110,'ELECTOR',1,NULL,'f78234a5ec411f6740f26d35d16b1a7b75ad5981ae86d4bfad6edd0f0b3b915a','SICEUNP|E|a8a841dfa0916cc2a383ffd0bbb2935f2d5f2ac33d39cd4cd566211acb9375c6','2026-10-20 11:44:30','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'1:110:ELECTOR:0'),(11,1,111,'ELECTOR',1,NULL,'3b6d30cbefd675f3f624c9c77e10e28278570df5e5ca4349cbd246f2b419f703','SICEUNP|E|3c3ca957bede9571b8bd1dfaae5d6d2752ee42bee0f1fb658607eca435f02cd1','2026-10-20 11:44:30','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'1:111:ELECTOR:0'),(12,1,112,'ELECTOR',1,NULL,'838b117b06b477f131272c1fe32dcc353b82242e9a730fee9b3f02c4275e7ec4','SICEUNP|E|7185f43f35ed16de673ee61a3a259e93b19c9939058e7049ad2703a37e03f68f','2026-10-20 11:44:30','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'1:112:ELECTOR:0'),(13,1,113,'ELECTOR',1,NULL,'ca20c65042ebb309d1ec7e20a27c74ad4a3eb1bf4083b76884e32031a0a07854','SICEUNP|E|3bea798d541f845fdc52f8e9cce1e38976805febd2c9e7e5e887fbdceca17395','2026-10-20 11:44:30','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'1:113:ELECTOR:0'),(14,1,114,'ELECTOR',1,NULL,'9a2a503f51283cf3afefe1818852768b420684a7bf9e8dab796f1e16feea2b72','SICEUNP|E|6cc4f99d7f9f4eec60c042e2481b8f988a1206777a472cada29a8437499ab7bc','2026-10-20 11:44:30','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'1:114:ELECTOR:0'),(15,1,115,'ELECTOR',1,NULL,'198e6d79c0442f10e18d67d1f1d390bfcc0732b1be07f1974002b8f0d75b6268','SICEUNP|E|50c8ba0b23427355b7cce3f0cd1dbc6c870e8e257cf0dfdfcd341d651ed86053','2026-10-20 11:44:30','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'1:115:ELECTOR:0'),(16,1,116,'ELECTOR',1,NULL,'41d0f2e062b0a8f123870da664133c50b93b828385225370dca647a8405d20d7','SICEUNP|E|7c69499e7501f62f03f5075c3b4e6ad3e1bc686d38f888cf4243773a229adc0a','2026-10-20 11:44:30','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'1:116:ELECTOR:0'),(17,1,117,'ELECTOR',1,NULL,'b467834b0ccbd83dff82b6dc8193df12898d0da5d9d1a2db29da2dcac87cb00f','SICEUNP|E|6fa3b6e8ea69610b0a5a045744106cce22181f1bf551b45c312cec6a8968dfee','2026-10-20 11:44:30','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'1:117:ELECTOR:0'),(18,1,107,'MIEMBRO_MESA',1,NULL,'cfd8309b91feb7ba1b1b73f2b6f68c9fddc6e487264747d350dc49c00cc1f93f','SICEUNP|M|e3b0078932fffadb7b1bd80be39f53d3f36437e768d5a5b62335a70cb2b3f787','2026-10-20 11:44:57','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'1:107:MIEMBRO_MESA:1'),(19,1,108,'MIEMBRO_MESA',1,NULL,'aadcecbf47471b5ed272115b093ae3f1573acc050b81ccdebdf5bca084512e63','SICEUNP|M|ff6ed0c7af96764a207167891c261efa868792e49657ff22090b0149e3449405','2026-10-20 11:44:57','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'1:108:MIEMBRO_MESA:1'),(20,1,111,'MIEMBRO_MESA',1,NULL,'9d095b8bfec3a625957352ea84b343713e59858ded35c2799c98da214596336a','SICEUNP|M|37e818a161f9769d7f465bffcb930910c63c7ee9379e3858c675d78b8127f602','2026-10-20 11:44:57','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'1:111:MIEMBRO_MESA:1'),(21,1,117,'MIEMBRO_MESA',1,NULL,'06f448168bec94c5ab2bad2c08e88ee9351aab6d5e7063ffe486c89103e16b33','SICEUNP|M|901575a6ca5a259603e90d57206948d7556e561105d5d0ee64d7de67b74adffe','2026-10-20 11:44:57','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'1:117:MIEMBRO_MESA:1'),(22,1,115,'MIEMBRO_MESA',1,NULL,'3cf40da250ff737b1bdb6af8cb63e07cbfae7eb66bd04b23aaf4deaaf38f3e74','SICEUNP|M|dc0975c777df2a755cb7d68eb7bb798ebeb474d2f7554952b648b47fb8752f72','2026-10-20 11:44:57','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'1:115:MIEMBRO_MESA:1'),(23,1,101,'MIEMBRO_MESA',1,NULL,'31d3894fc87055e8670b33a1047e4f5b50133001c883d68bcd1583975a103dc2','SICEUNP|M|0b8abf009e1965231c4aad907df1dba6c9fc84a705cd1674f965ec32d77b2be9','2026-10-20 11:44:57','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'1:101:MIEMBRO_MESA:1'),(24,2,115,'MIEMBRO_MESA',2,NULL,'941fc18ae60b2241ac887cfc986ff7f7ea383a541658c7c3efbd6626bc016036','SICEUNP|M|f399fc3c24bb7a7319be3965deb5b8d6e8f07f5574f23ce3a6ec420540fcd3bb','2026-10-15 14:08:04','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'2:115:MIEMBRO_MESA:2'),(25,2,117,'MIEMBRO_MESA',2,NULL,'726ed41936dcdfa62af44732a8d214486f154fb4454539d29c9c6206759f3abb','SICEUNP|M|ec8cf97f2034cef12cc85ac1bbed92446f38fa450c0dd76738944a82d7f630e2','2026-10-15 14:08:04','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'2:117:MIEMBRO_MESA:2'),(26,2,110,'MIEMBRO_MESA',2,NULL,'09a8514542924ae05ac5e943abd1b74e96d0de2c5e1b7517a4df6cc12d5b8fe8','SICEUNP|M|d2f4b135032a4c05d3439c52bd184496786abc3bf14e6974db640a21b52556ca','2026-10-15 14:08:04','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'2:110:MIEMBRO_MESA:2'),(27,2,107,'MIEMBRO_MESA',2,NULL,'31807d9a38af501dc58f012c55e6a4a1990f3236fa9f318176c618dc3c2f1ab8','SICEUNP|M|dafbfd38c1e15cb62c0f1d425f75457821b876bdc7ddc9c80c878ea57de200e9','2026-10-15 14:08:04','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'2:107:MIEMBRO_MESA:2'),(28,2,114,'MIEMBRO_MESA',2,NULL,'a40720a19cc3d746e294dacdf7cdd85d697a3eb0c9b02f701053a9d1731cb048','SICEUNP|M|31aa8eb9101b9b064497544f444a63ca1a7064173902a26dc2c09f1cbd5b32ec','2026-10-15 14:08:04','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'2:114:MIEMBRO_MESA:2'),(29,2,104,'MIEMBRO_MESA',2,NULL,'9ecd48b63ad07868c090a83d2f0fe0d792e997b6a3b532c83e9d0b6ae27b7211','SICEUNP|M|2198b88b970d0e91122a406579af3bf67dd9386d2e1637b641a49f73f5ede1b4','2026-10-15 14:08:04','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'2:104:MIEMBRO_MESA:2'),(30,2,101,'ELECTOR',2,NULL,'216c6580590d1587cc394f9ed8731a883b6ac0557d952f22c71b52243a5218f2','SICEUNP|E|c9b41b5ef3996d58b318d09b7eef454ea83f6ea4d8c7f25161dbb41c986da22d','2026-10-15 14:08:25','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'2:101:ELECTOR:0'),(31,2,102,'ELECTOR',2,NULL,'82d1bc1bf177434dc1cc15588c5fd41607100c7f2d359630a72c21ef7f69ba0b','SICEUNP|E|b465144c35b607eaba5bbe9cc4ccc182c500029fc78365a1ed02efb4b1dba38c','2026-10-15 14:08:25','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'2:102:ELECTOR:0'),(32,2,103,'ELECTOR',2,NULL,'0b25a48191a70fc49532ef9078a15d1ad3f773d923403a2b275edac9ed06b54f','SICEUNP|E|1e0da6c5ce0ea7b60cc4a3696a165ca07d285e9046e669e93c15ddad10357b19','2026-10-15 14:08:25','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'2:103:ELECTOR:0'),(33,2,104,'ELECTOR',2,NULL,'fb3cdeb52d0ad44f489cac590a8e8ec581032f853f410d07d574b7ec85e15911','SICEUNP|E|d31cb648f89dfd833cc51383755e0dbbf764efe064dfef6362c6c7dec711fc4a','2026-10-15 14:08:25','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'2:104:ELECTOR:0'),(34,2,105,'ELECTOR',2,NULL,'989875ee7d5cf0e75cb73515ff8018a3225d354b49cc5ad55913b59b68d5bceb','SICEUNP|E|de6824d05f7799db26a025e95d8cd595f2366c792f10200fbf6c2b2757964aff','2026-10-15 14:08:25','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'2:105:ELECTOR:0'),(35,2,106,'ELECTOR',2,NULL,'9ea3d38e25ad84ccac9dd9f0e92b105033b6bd79d6429aadc297ca0c3689c399','SICEUNP|E|59f1ea8fb55a195882c17e01b27e494e5de4466ec2bebfa1e83c3565550e12bb','2026-10-15 14:08:25','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'2:106:ELECTOR:0'),(36,2,107,'ELECTOR',2,NULL,'62bd7c53b06719806124d419b9bc54ec9cca9bb66c1ec0fe319c519dbcbb417b','SICEUNP|E|2cbcf6f031df4e44f0ed80557d7cc58df0a876355ee7f26e63234b16af9042b3','2026-10-15 14:08:25','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'2:107:ELECTOR:0'),(37,2,108,'ELECTOR',2,NULL,'861c4e1e2a4c325a9aa5b8a79bf54def91a1a9bf53eceeb8d7d99c91e05d2627','SICEUNP|E|40ffa816a1e838c28a92a6cbc68341795a172bcd6de7b9ecc3fd6fbfc926b624','2026-10-15 14:08:25','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'2:108:ELECTOR:0'),(38,2,109,'ELECTOR',2,NULL,'b1db543c0cfd36b76233da083c61b5327d89d879a012922f7ef91df57fdda2c9','SICEUNP|E|92d581a0f7b80ebfea1d495a67430cfcc6935bf499ff27efd524c55367d79efb','2026-10-15 14:08:25','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'2:109:ELECTOR:0'),(39,2,110,'ELECTOR',2,NULL,'a4e387dcc0b09982ca3b17a4ad666d7bd0ea506227717ace51261e7bcb41a94b','SICEUNP|E|3ad7361ffd8993532779fff4b3c9c8779cb2189392db3ecbae3bdd200032bf6b','2026-10-15 14:08:25','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'2:110:ELECTOR:0'),(40,2,111,'ELECTOR',2,NULL,'fc2ea892044c4b088c30ac4370a5b5b25cb6b7fef832d8fc1183b74bea335144','SICEUNP|E|fa868a3f54389791a2124fbb8f9f652f4bdc61f3dc1e6b7e19fc885ae5e91d20','2026-10-15 14:08:25','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'2:111:ELECTOR:0'),(41,2,112,'ELECTOR',2,NULL,'4b1e9e493d50dacf7906a7e3a776ee5df5d0272b4e271ccf7641c6840c39fda3','SICEUNP|E|0d57f40353f8ba3e70bb6d14d22f86847b42334fff10e170d148c9eef7c8417f','2026-10-15 14:08:25','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'2:112:ELECTOR:0'),(42,2,113,'ELECTOR',2,NULL,'f5cad7ce59f616160f7d15c83b33604afcc797fa988076b6a84c2ef28191896c','SICEUNP|E|656defe5b928a59e85251e160954dbc83918d19e2644ee71785365e8b1e29d13','2026-10-15 14:08:25','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'2:113:ELECTOR:0'),(43,2,114,'ELECTOR',2,NULL,'c819e3e6be37faf3d12a368a08b5716132fda6050dd3405b8d5028dec5e316ce','SICEUNP|E|5fad0b41096c81ab0c7fc850f43fe7b7b9af74892c58cb769fa5ec130db81fec','2026-10-15 14:08:25','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'2:114:ELECTOR:0'),(44,2,115,'ELECTOR',2,NULL,'56f5c2aff059c5f1abcb3606f8d7e3701dce74167a0881d3902195f96ce31d97','SICEUNP|E|ff92ece58711f5152b9103eb2cc8913e8470b7219baf1ecbc3daa4b6b7250237','2026-10-15 14:08:25','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'2:115:ELECTOR:0'),(45,2,116,'ELECTOR',2,NULL,'b3b5f2e6318f8441e6b92dc6218056b08a977b6c7fca36356255f87418bd5a04','SICEUNP|E|27de27266145325b3154543093c2f82c750e4fcb7e0562aebf8802c9841c715f','2026-10-15 14:08:25','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'2:116:ELECTOR:0'),(46,2,117,'ELECTOR',2,NULL,'f29ac5b165f739c12c3b162b6ead88d326aaed9c295fcc689fecef4f78a73570','SICEUNP|E|9063705fdb5ff96b7ec9879ebbff55a1e54a4321bdd8c4bb90f3adf66a08f928','2026-10-15 14:08:25','2026-11-25 15:00:00','VIGENTE',NULL,NULL,3,0,NULL,'2:117:ELECTOR:0');
/*!40000 ALTER TABLE `credencial_qr` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_credencial_bd BEFORE DELETE ON credencial_qr
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Las credenciales QR no se eliminan: revóquelas.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `departamento`
--

DROP TABLE IF EXISTS `departamento`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `departamento` (
  `id_departamento` int(11) NOT NULL AUTO_INCREMENT,
  `id_facultad` int(11) NOT NULL,
  `nombre` varchar(150) NOT NULL,
  PRIMARY KEY (`id_departamento`),
  UNIQUE KEY `uq_departamento_facultad` (`id_facultad`,`nombre`),
  CONSTRAINT `fk_departamento_facultad` FOREIGN KEY (`id_facultad`) REFERENCES `facultad` (`id_facultad`)
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `departamento`
--

LOCK TABLES `departamento` WRITE;
/*!40000 ALTER TABLE `departamento` DISABLE KEYS */;
INSERT INTO `departamento` VALUES (1,1,'Agronomía y Fitotécnia'),(2,1,'Ingeniería Agrícola'),(5,1,'Morfofisiología Vegetal'),(3,1,'Sanidad Vegetal'),(4,1,'Suelos'),(6,2,'Arquitectura'),(7,2,'Urbanismo'),(11,3,'Ciencias Biológicas'),(10,3,'Estadística'),(9,3,'Física'),(12,3,'Ingeniería Electrónica y Telecomunicaciones'),(8,3,'Matemática'),(14,4,'Administración Aplicada'),(13,4,'Administración General'),(16,5,'Contabilidad Aplicada'),(15,5,'Contabilidad General'),(17,5,'Finanzas, Tributación y Auditoría'),(20,6,'Clínico Quirúrgico'),(23,6,'Enfermería del Adulto'),(22,6,'Enfermería Materno Perinatal'),(18,6,'Materno Infantil'),(19,6,'Morfofisiología Humana'),(21,6,'Salud Pública'),(26,7,'Ciencias de la Comunicación'),(25,7,'Ciencias Sociales'),(24,7,'Educación'),(28,8,'Ciencias Políticas'),(27,8,'Derecho'),(29,9,'Economía'),(30,10,'Ingeniería Civil'),(31,10,'Ingeniería Sanitaria y Medio Ambiente'),(36,11,'Ingeniería Ambiental y Seguridad Industrial'),(32,11,'Ingeniería de Minas'),(33,11,'Ingeniería de Petróleo'),(34,11,'Ingeniería Geológica'),(35,11,'Ingeniería Química'),(39,12,'Agroindustria e Industrias Alimentarias'),(37,12,'Ingeniería Industrial'),(38,12,'Ingeniería Informática'),(41,12,'Ingeniería Mecatrónica'),(40,12,'Investigación de Operaciones'),(42,13,'Ingeniería Pesquera'),(43,14,'Producción Animal'),(44,14,'Salud Animal');
/*!40000 ALTER TABLE `departamento` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dirimencia_empate`
--

DROP TABLE IF EXISTS `dirimencia_empate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dirimencia_empate` (
  `id_cargo` int(11) NOT NULL,
  `id_proceso` int(11) NOT NULL,
  `motivo` enum('PASE_A_SEGUNDA_VUELTA','EMPATE_SEGUNDA_VUELTA') NOT NULL,
  `semilla` varchar(100) NOT NULL,
  `cupos` tinyint(4) NOT NULL,
  `listas_empatadas` longtext NOT NULL,
  `listas_elegidas` longtext NOT NULL,
  `numero_resolucion` varchar(40) NOT NULL,
  `miembros_pleno` tinyint(4) NOT NULL,
  `fundamento` varchar(1000) DEFAULT NULL,
  `fecha` datetime NOT NULL,
  `id_usuario` int(11) DEFAULT NULL,
  `hash_integridad` char(64) NOT NULL,
  PRIMARY KEY (`id_cargo`),
  UNIQUE KEY `uq_dirimencia_resolucion` (`numero_resolucion`),
  KEY `fk_dirim_cargo` (`id_cargo`,`id_proceso`),
  KEY `fk_dirim_usuario` (`id_usuario`),
  CONSTRAINT `fk_dirim_cargo` FOREIGN KEY (`id_cargo`, `id_proceso`) REFERENCES `cargo_electoral` (`id_cargo`, `id_proceso`),
  CONSTRAINT `fk_dirim_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `chk_dirimencia_json` CHECK (json_valid(`listas_empatadas`) and json_valid(`listas_elegidas`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dirimencia_empate`
--

LOCK TABLES `dirimencia_empate` WRITE;
/*!40000 ALTER TABLE `dirimencia_empate` DISABLE KEYS */;
/*!40000 ALTER TABLE `dirimencia_empate` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_dirimencia_bu BEFORE UPDATE ON dirimencia_empate
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: la dirimencia del empate es inapelable.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_dirimencia_bd BEFORE DELETE ON dirimencia_empate
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: la dirimencia del empate no se elimina.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

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
  `estado` enum('ACTIVO','INACTIVO','LICENCIA','SUSPENDIDO') NOT NULL DEFAULT 'ACTIVO',
  `habilitado_para_votar` tinyint(1) NOT NULL DEFAULT 1,
  `id_facultad` int(11) NOT NULL,
  `id_departamento` int(11) NOT NULL,
  `grado_academico` enum('BACHILLER','MAESTRO','DOCTOR') DEFAULT NULL,
  `fecha_ingreso` date DEFAULT NULL,
  `fecha_categoria` date DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `fecha_registro` datetime NOT NULL DEFAULT current_timestamp(),
  `url_foto` varchar(300) DEFAULT NULL,
  PRIMARY KEY (`id_docente`),
  UNIQUE KEY `uq_docente_dni` (`dni`),
  KEY `ix_docente_apellidos` (`apellidos`,`nombres`),
  KEY `ix_docente_estado` (`estado`,`habilitado_para_votar`),
  KEY `fk_docente_facultad` (`id_facultad`),
  KEY `fk_docente_departamento` (`id_departamento`),
  CONSTRAINT `fk_docente_departamento` FOREIGN KEY (`id_departamento`) REFERENCES `departamento` (`id_departamento`),
  CONSTRAINT `fk_docente_facultad` FOREIGN KEY (`id_facultad`) REFERENCES `facultad` (`id_facultad`),
  CONSTRAINT `chk_docente_dni` CHECK (`dni` regexp '^[0-9]{8}$')
) ENGINE=InnoDB AUTO_INCREMENT=118 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `docente`
--

LOCK TABLES `docente` WRITE;
/*!40000 ALTER TABLE `docente` DISABLE KEYS */;
INSERT INTO `docente` VALUES (2,'03681002','María Elena','Ruiz Delgado','ASOCIADO','TC','LICENCIA',0,3,8,'DOCTOR','2010-08-15','2014-05-01','mruiz@unp.edu.pe','2026-11-08 15:08:18',NULL),(3,'03681003','Jorge Luis','Ramos Flores','AUXILIAR','TP','ACTIVO',1,4,13,'MAESTRO','2012-07-01','2012-07-01','jramos@unp.edu.pe','2026-11-08 15:08:18',NULL),(4,'03681004','Ana Patricia','Castro Silva','PRINCIPAL','DE','ACTIVO',1,5,15,'MAESTRO','1994-05-01','2006-02-01','acastro@unp.edu.pe','2026-11-08 15:08:18',NULL),(5,'03681005','Carlos Alberto','Benítes Juárez','PRINCIPAL','DE','ACTIVO',1,1,1,'MAESTRO','1992-06-01','2001-08-01','cbenites@unp.edu.pe','2026-11-08 15:08:18',NULL),(6,'03681006','Rosa María','Salazar Vega','ASOCIADO','TC','ACTIVO',1,6,20,'MAESTRO','2003-09-01','2007-03-01','rsalazar@unp.edu.pe','2026-11-08 15:08:18',NULL),(7,'03681007','Pedro José','Morales Prado','AUXILIAR','TP','SUSPENDIDO',0,11,33,'MAESTRO','2013-11-15','2013-11-15','pmorales@unp.edu.pe','2026-11-08 15:08:18',NULL),(8,'03681008','Luis Fernando','Farfán Zapata','PRINCIPAL','DE','ACTIVO',1,8,27,'DOCTOR','1994-03-15','2006-08-01','lfarfan@unp.edu.pe','2026-11-08 15:08:18',NULL),(9,'03681009','Carmen Rosa','Albán Peña','ASOCIADO','TC','ACTIVO',1,9,29,'MAESTRO','2007-07-15','2011-08-01','calban@unp.edu.pe','2026-11-08 15:08:18',NULL),(10,'03681010','Miguel Ángel','Guerrero Neira','AUXILIAR','TP','ACTIVO',1,2,6,'MAESTRO','2019-01-01','2019-01-01','mguerrero@unp.edu.pe','2026-11-08 15:08:18',NULL),(11,'03681011','Silvia Elizabeth','Vilela Yamunaqué','PRINCIPAL','DE','ACTIVO',1,10,30,'MAESTRO','2003-08-01','2012-08-01','svilela@unp.edu.pe','2026-11-08 15:08:19',NULL),(12,'03681012','Ricardo Manuel','Ojeda Dioses','ASOCIADO','TC','ACTIVO',1,14,43,'MAESTRO','2004-12-01','2010-12-01','rojeda@unp.edu.pe','2026-11-08 15:08:19',NULL),(13,'03681013','Diana Marcela','Calle Calle','AUXILIAR','TP','ACTIVO',1,13,42,'MAESTRO','2011-06-01','2011-06-01','dcalle@unp.edu.pe','2026-11-08 15:08:19',NULL),(14,'03681014','Victor Hugo','Navarro Sullón','PRINCIPAL','DE','LICENCIA',0,7,24,'DOCTOR','2005-07-15','2015-11-01','vnavarro@unp.edu.pe','2026-11-08 15:08:19',NULL),(15,'03681015','Patricia Janet','Yarlequé Medina','ASOCIADO','TC','ACTIVO',1,12,37,'MAESTRO','2007-09-01','2012-01-01','pyarleque@unp.edu.pe','2026-11-08 15:08:19',NULL),(16,'03681016','Cesar Augusto','Coronado Talledo','AUXILIAR','TP','ACTIVO',1,3,9,'MAESTRO','2016-04-15','2016-04-15','ccoronado@unp.edu.pe','2026-11-08 15:08:19',NULL),(17,'03681017','Gladys Noemí','Ipanaqué Chero','PRINCIPAL','DE','ACTIVO',1,4,14,'DOCTOR','2000-03-01','2012-08-01','gipanaque@unp.edu.pe','2026-11-08 15:08:19',NULL),(18,'03681018','Manuel Jesús','Timaná Vilchez','ASOCIADO','TC','ACTIVO',1,5,17,'DOCTOR','2012-12-15','2020-12-01','mtimana@unp.edu.pe','2026-11-08 15:08:19',NULL),(19,'03681019','Mónica Isabel','Valladolid Cherres','AUXILIAR','TP','ACTIVO',1,1,3,'MAESTRO','2022-04-15','2022-04-15','mvalladolid@unp.edu.pe','2026-11-08 15:08:19',NULL),(20,'03681020','Francisco Javier','Seminario Pasapera','PRINCIPAL','DE','ACTIVO',1,6,21,'DOCTOR','1991-10-15','2001-11-01','fseminario@unp.edu.pe','2026-11-08 15:08:19',NULL),(21,'03681021','Sofia Beatriz','Chunga Purizaca','ASOCIADO','TC','SUSPENDIDO',0,11,35,'MAESTRO','2012-11-01','2016-01-01','schunga@unp.edu.pe','2026-11-08 15:08:19',NULL),(22,'03681022','Gabriel Antonio','Reto Silva','AUXILIAR','TP','ACTIVO',1,8,28,'MAESTRO','2013-10-01','2013-10-01','greto@unp.edu.pe','2026-11-08 15:08:19',NULL),(23,'03681023','Veronica Lucia','Pazos Lazo','PRINCIPAL','DE','ACTIVO',1,9,29,'DOCTOR','2000-09-15','2013-08-01','vpazos@unp.edu.pe','2026-11-08 15:08:20',NULL),(24,'03681024','Hector Raul','Pulache Cordova','ASOCIADO','TC','ACTIVO',1,2,6,'MAESTRO','2014-12-01','2019-03-01','hpulache@unp.edu.pe','2026-11-08 15:08:20',NULL),(25,'03681025','Nancy Yolanda','Carhuapoma Yovera','AUXILIAR','TP','ACTIVO',1,10,30,'MAESTRO','2018-05-01','2018-05-01','ncarhuapoma@unp.edu.pe','2026-11-08 15:08:20',NULL),(26,'03681026','Walter Enrique','Zevallos Ramos','PRINCIPAL','DE','ACTIVO',1,14,44,'DOCTOR','1990-11-01','2001-04-01','wzevallos@unp.edu.pe','2026-11-08 15:08:20',NULL),(27,'03681027','Claudia Maria','Palacios Tavara','ASOCIADO','TC','LICENCIA',0,13,42,'MAESTRO','2010-04-01','2014-06-01','cpalacios@unp.edu.pe','2026-11-08 15:08:20',NULL),(28,'03681028','Oscar Eduardo','Saavedra Nole','AUXILIAR','TP','ACTIVO',1,7,26,'MAESTRO','2023-12-01','2023-12-01','osaavedra@unp.edu.pe','2026-11-08 15:08:20',NULL),(29,'03681029','Teresa de Jesus','Gomez Sandoval','PRINCIPAL','DE','ACTIVO',1,12,40,'DOCTOR','1992-12-01','2003-02-01','tgomez@unp.edu.pe','2026-11-08 15:08:20',NULL),(30,'03681030','Roberto Carlos','Agurto Iman','ASOCIADO','TC','ACTIVO',1,3,10,'DOCTOR','2009-08-01','2017-11-01','ragurto@unp.edu.pe','2026-11-08 15:08:20',NULL),(31,'03681031','Isabel Cristina','Montero Riofrio','AUXILIAR','TP','ACTIVO',1,4,13,'MAESTRO','2012-08-01','2012-08-01','imontero@unp.edu.pe','2026-11-08 15:08:20',NULL),(32,'03681032','Julio Cesar','Fiestas Chunga','PRINCIPAL','DE','ACTIVO',1,5,16,'MAESTRO','2001-10-01','2009-11-01','jfiestas@unp.edu.pe','2026-11-08 15:08:20',NULL),(33,'03681033','Karen Lisseth','Zapata Vilchez','ASOCIADO','TC','ACTIVO',1,1,4,'MAESTRO','2001-01-15','2008-03-01','kzapata@unp.edu.pe','2026-11-08 15:08:20',NULL),(34,'03681034','Alex Alexander','Sullon Yovera','AUXILIAR','TP','SUSPENDIDO',0,6,22,'MAESTRO','2017-01-01','2017-01-01','asullon@unp.edu.pe','2026-11-08 15:08:21',NULL),(35,'03681035','Rosa Elvira','Espinoza Garcia','PRINCIPAL','DE','ACTIVO',1,11,32,'DOCTOR','1996-12-01','2006-11-01','respinoza@unp.edu.pe','2026-11-08 15:08:21',NULL),(36,'03681036','Marcos Aurelio','Neyra Cruz','ASOCIADO','TC','ACTIVO',1,8,27,'MAESTRO','2011-07-01','2016-03-01','mneyra@unp.edu.pe','2026-11-08 15:08:21',NULL),(37,'03681037','Lourdes del Pilar','Dioses Morales','AUXILIAR','TP','ACTIVO',1,9,29,'MAESTRO','2014-09-15','2014-09-15','ldioses@unp.edu.pe','2026-11-08 15:08:21',NULL),(38,'03681038','Aldo Martin','Castillo Cherres','PRINCIPAL','DE','ACTIVO',1,2,6,'DOCTOR','2000-05-01','2013-09-01','acastillo@unp.edu.pe','2026-11-08 15:08:21',NULL),(39,'03681039','Brenda Vanessa','Rivas Vite','ASOCIADO','TC','ACTIVO',1,10,30,'DOCTOR','2008-01-01','2012-01-01','brivas@unp.edu.pe','2026-11-08 15:08:21',NULL),(40,'03681040','Christian Joel','Benites Yarleque','AUXILIAR','TP','LICENCIA',0,14,43,'MAESTRO','2021-11-01','2021-11-01','cbenites2@unp.edu.pe','2026-11-08 15:08:21',NULL),(41,'03681041','Katia Paola','Roman Silva','PRINCIPAL','DE','ACTIVO',1,13,42,'DOCTOR','1991-06-01','2003-02-01','kroman@unp.edu.pe','2026-11-08 15:08:21',NULL),(42,'03681042','Daniel Omar','Vilchez Chero','ASOCIADO','TC','ACTIVO',1,7,25,'MAESTRO','2009-04-01','2016-01-01','dvilchez@unp.edu.pe','2026-11-08 15:08:21',NULL),(43,'03681043','Andrea Fabiana','Pacherres Nole','AUXILIAR','TP','ACTIVO',1,12,39,'MAESTRO','2011-05-01','2011-05-01','apacherres@unp.edu.pe','2026-11-08 15:08:21',NULL),(44,'03681044','Gonzalo Nicolas','Requena Tavara','PRINCIPAL','DE','ACTIVO',1,3,11,'DOCTOR','1994-11-01','2005-06-01','grequena@unp.edu.pe','2026-11-08 15:08:21',NULL),(45,'03681045','Yessica Yanet','Sandoval Ipanaque','ASOCIADO','TC','ACTIVO',1,4,14,'MAESTRO','2006-10-01','2010-11-01','ysandoval@unp.edu.pe','2026-11-08 15:08:22',NULL),(46,'03681046','Ruben Dario','Cordova Purizaca','AUXILIAR','TP','ACTIVO',1,5,15,'MAESTRO','2011-05-01','2011-05-01','rcordova@unp.edu.pe','2026-11-08 15:08:22',NULL),(47,'03681047','Cecilia Ines','Prado Valladares','PRINCIPAL','DE','ACTIVO',1,1,2,'DOCTOR','2007-10-01','2018-04-01','cprado@unp.edu.pe','2026-11-08 15:08:22',NULL),(48,'03681048','Edwin David','Garcia Palacios','ASOCIADO','TC','SUSPENDIDO',0,6,19,'MAESTRO','2011-08-01','2018-09-01','egarcia@unp.edu.pe','2026-11-08 15:08:22',NULL),(49,'03681049','Giannina Maria','Talledo Saavedra','AUXILIAR','TP','ACTIVO',1,11,34,'MAESTRO','2017-05-01','2017-05-01','gtalledo@unp.edu.pe','2026-11-08 15:08:22',NULL),(50,'03681050','Raul Enrique','Vilela Chunga','PRINCIPAL','DE','ACTIVO',1,8,27,'DOCTOR','2000-10-01','2010-07-01','rvilela@unp.edu.pe','2026-11-08 15:08:22',NULL),(51,'03681051','Fiorella Lizbeth','Cruz Ramos','ASOCIADO','TC','ACTIVO',1,9,29,'MAESTRO','2007-06-15','2015-07-01','fcruz@unp.edu.pe','2026-11-08 15:08:22',NULL),(52,'03681052','Hernan Alonso','Morales Yovera','AUXILIAR','TP','ACTIVO',1,2,6,'MAESTRO','2013-06-01','2013-06-01','hmorales@unp.edu.pe','2026-11-08 15:08:22',NULL),(53,'03681053','Giuliana Mercedes','Alba Chunga','PRINCIPAL','DE','LICENCIA',0,10,30,'DOCTOR','2003-10-01','2012-10-01','galba@unp.edu.pe','2026-11-08 15:08:22',NULL),(54,'03681054','Guillermo Andres','Nole Farfan','ASOCIADO','TC','ACTIVO',1,14,44,'MAESTRO','2010-05-15','2015-03-01','gnole@unp.edu.pe','2026-11-08 15:08:22',NULL),(55,'03681055','Wendy Katherine','Purizaca Cherres','AUXILIAR','TP','ACTIVO',1,13,42,'MAESTRO','2020-11-01','2020-11-01','wpurizaca@unp.edu.pe','2026-11-08 15:08:22',NULL),(56,'03681056','Renato Stephano','Yamunaque Silva','PRINCIPAL','DE','ACTIVO',1,7,24,'DOCTOR','2007-02-01','2018-06-01','ryamunaque@unp.edu.pe','2026-11-08 15:08:22',NULL),(57,'03681057','Roxana Elizabeth','Tavara Pasapera','ASOCIADO','TC','ACTIVO',1,12,41,'MAESTRO','2008-08-01','2013-04-01','rtavara@unp.edu.pe','2026-11-08 15:08:23',NULL),(58,'03681058','Sergio Mateo','Chero Ipanaque','AUXILIAR','TP','ACTIVO',1,3,12,'MAESTRO','2017-10-01','2017-10-01','schero@unp.edu.pe','2026-11-08 15:08:23',NULL),(59,'03681059','Tatiana Soledad','Purizaca Sullon','PRINCIPAL','DE','ACTIVO',1,4,13,'DOCTOR','2007-09-01','2019-03-01','tpurizaca@unp.edu.pe','2026-11-08 15:08:23',NULL),(60,'03681060','Williams Steve','Vilchez Yarleque','ASOCIADO','TC','ACTIVO',1,5,17,'MAESTRO','2002-11-15','2007-02-01','wvilchez@unp.edu.pe','2026-11-08 15:08:23',NULL),(61,'03681061','Zoila Marina','Chunga Dioses','AUXILIAR','TP','ACTIVO',1,1,5,'MAESTRO','2022-09-01','2022-09-01','zchunga@unp.edu.pe','2026-11-08 15:08:23',NULL),(62,'03681062','Alvaro Rodrigo','Morales Sullon','PRINCIPAL','DE','SUSPENDIDO',0,6,18,'DOCTOR','2004-04-15','2017-03-01','amorales@unp.edu.pe','2026-11-08 15:08:23',NULL),(63,'03681063','Beatriz Alexandra','Farfan Nole','ASOCIADO','TC','ACTIVO',1,11,36,'MAESTRO','2011-04-01','2016-06-01','bfarfan@unp.edu.pe','2026-11-08 15:08:23',NULL),(64,'03681064','Claudio Fernando','Yovera Purizaca','AUXILIAR','TP','ACTIVO',1,8,28,'MAESTRO','2013-12-15','2013-12-15','cyovera@unp.edu.pe','2026-11-08 15:08:23',NULL),(65,'03681065','Dora Alicia','Cherres Silva','PRINCIPAL','DE','ACTIVO',1,9,29,'MAESTRO','2004-08-01','2013-05-01','dcherres@unp.edu.pe','2026-11-08 15:08:23',NULL),(66,'03681066','Eduardo Felipe','Silva Yamunaque','ASOCIADO','TC','ACTIVO',1,2,6,'MAESTRO','2007-05-15','2014-08-01','esilva@unp.edu.pe','2026-11-08 15:08:23',NULL),(67,'03681067','Fanny del Socorro','Sullon Chero','AUXILIAR','TP','ACTIVO',1,10,30,'MAESTRO','2015-08-01','2015-08-01','fsullon@unp.edu.pe','2026-11-08 15:08:23',NULL),(68,'03681068','Gustavo Adolfo','Ipanaque Yarleque','PRINCIPAL','DE','LICENCIA',0,14,43,'DOCTOR','1998-04-01','2006-05-01','gipanaque2@unp.edu.pe','2026-11-08 15:08:24',NULL),(69,'03681069','Helga Mariela','Pasapera Tavara','ASOCIADO','TC','ACTIVO',1,13,42,'MAESTRO','2014-01-01','2019-08-01','hpasapera@unp.edu.pe','2026-11-08 15:08:24',NULL),(74,'03681074','Karina Elizabeth','Dioses Purizaca','PRINCIPAL','DE','ACTIVO',1,3,8,'DOCTOR','2006-06-01','2015-08-01','kdioses@unp.edu.pe','2026-11-08 15:08:24',NULL),(75,'03681075','Luis Alberto','Yarleque Sullon','ASOCIADO','TC','ACTIVO',1,3,9,'MAESTRO','2008-01-01','2012-04-01','lyarleque@unp.edu.pe','2026-11-08 15:08:24',NULL),(76,'03681076','Martha Elena','Chero Yovera','AUXILIAR','TP','ACTIVO',1,3,10,'MAESTRO','2021-03-01','2021-03-01','mchero@unp.edu.pe','2026-11-08 15:08:24',NULL),(77,'03681077','Nestor Daniel','Silva Cherres','PRINCIPAL','DE','ACTIVO',1,3,11,'DOCTOR','2007-01-01','2017-01-01','nsilva@unp.edu.pe','2026-11-08 15:08:24',NULL),(78,'03681078','Olga Lidia','Yamunaque Pasapera','ASOCIADO','TC','SUSPENDIDO',0,3,12,'MAESTRO','2008-11-01','2012-04-01','oyamunaque@unp.edu.pe','2026-11-08 15:08:24',NULL),(79,'03681079','Pablo Antonio','Tavara Chero','AUXILIAR','TP','ACTIVO',1,4,13,'MAESTRO','2010-06-01','2010-06-01','ptavara@unp.edu.pe','2026-11-08 15:08:24',NULL),(80,'03681080','Rosa Isabel','Sullon Ipanaque','PRINCIPAL','DE','ACTIVO',1,4,14,'DOCTOR','1993-03-15','2004-04-01','rsullon@unp.edu.pe','2026-11-08 15:08:25',NULL),(81,'03681081','Samuel Eduardo','Yovera Silva','ASOCIADO','TC','ACTIVO',1,5,15,'MAESTRO','2007-04-01','2011-09-01','syovera@unp.edu.pe','2026-11-08 15:08:25',NULL),(82,'03681082','Tania Maria','Cherres Yamunaque','AUXILIAR','TP','ACTIVO',1,5,16,'MAESTRO','2013-04-01','2013-04-01','tcherres@unp.edu.pe','2026-11-08 15:08:25',NULL),(83,'03681083','Ulises Omar','Pasapera Tavara','PRINCIPAL','DE','ACTIVO',1,5,17,'MAESTRO','2004-11-15','2016-02-01','upasapera@unp.edu.pe','2026-11-08 15:08:25',NULL),(84,'03681084','Vanessa Lisset','Chero Sullon','ASOCIADO','TC','LICENCIA',0,1,1,'MAESTRO','2004-05-01','2011-07-01','vchero@unp.edu.pe','2026-11-08 15:08:25',NULL),(85,'03681085','Walter Javier','Ipanaque Yovera','AUXILIAR','TP','ACTIVO',1,1,2,'MAESTRO','2016-09-15','2016-09-15','wipanaque@unp.edu.pe','2026-11-08 15:08:25',NULL),(86,'03681086','Xavier Hernan','Silva Cherres','PRINCIPAL','DE','ACTIVO',1,1,3,'DOCTOR','1995-12-15','2008-09-01','xsilva@unp.edu.pe','2026-11-08 15:08:25',NULL),(87,'03681087','Yenny Patricia','Yamunaque Tavara','ASOCIADO','TC','ACTIVO',1,1,4,'DOCTOR','2008-07-01','2016-10-01','yyamunaque@unp.edu.pe','2026-11-08 15:08:25',NULL),(88,'03681088','Zoraida Beatri','Tavara Sullon','AUXILIAR','TP','ACTIVO',1,1,5,'MAESTRO','2012-04-01','2012-04-01','ztavara@unp.edu.pe','2026-11-08 15:08:25',NULL),(89,'03681089','Armando Jose','Chero Pasapera','PRINCIPAL','DE','ACTIVO',1,6,18,'DOCTOR','2005-07-15','2015-06-01','achero@unp.edu.pe','2026-11-08 15:08:25',NULL),(90,'03681090','Blanca Rosa','Ipanaque Tavara','ASOCIADO','TC','ACTIVO',1,6,19,'MAESTRO','2005-02-01','2011-08-01','bipanaque@unp.edu.pe','2026-11-08 15:08:25',NULL),(91,'03681091','Carlos Enrique','Yovera Chero','AUXILIAR','TP','ACTIVO',1,6,20,'MAESTRO','2011-11-01','2011-11-01','cyovera2@unp.edu.pe','2026-11-08 15:08:26',NULL),(92,'03681092','Doris Maria','Cherres Ipanaque','PRINCIPAL','DE','SUSPENDIDO',0,6,21,'MAESTRO','1991-01-15','2004-01-01','dcherres2@unp.edu.pe','2026-11-08 15:08:26',NULL),(93,'03681093','Ernesto Luis','Silva Yovera','ASOCIADO','TC','ACTIVO',1,6,22,'MAESTRO','2004-02-15','2010-05-01','esilva2@unp.edu.pe','2026-11-08 15:08:26',NULL),(94,'03681094','Fatima Soledad','Yamunaque Cherres','AUXILIAR','TP','ACTIVO',1,11,32,'MAESTRO','2021-09-15','2021-09-15','fyamunaque@unp.edu.pe','2026-11-08 15:08:26',NULL),(95,'03681095','Guillermo Jose','Tavara Silva','PRINCIPAL','DE','ACTIVO',1,11,33,'MAESTRO','1995-07-01','2003-07-01','gtavara@unp.edu.pe','2026-11-08 15:08:26',NULL),(96,'03681096','Hilda Elizabeth','Sullon Yamunaque','ASOCIADO','TC','ACTIVO',1,11,34,'DOCTOR','2012-01-01','2018-10-01','hsullon@unp.edu.pe','2026-11-08 15:08:26',NULL),(97,'03681097','Ivan Marcelino','Pasapera Chero','AUXILIAR','TP','ACTIVO',1,11,35,'MAESTRO','2016-01-15','2016-01-15','ipasapera@unp.edu.pe','2026-11-08 15:08:26',NULL),(98,'03681098','Judith Noemi','Chero Ipanaque','PRINCIPAL','DE','LICENCIA',0,11,36,'MAESTRO','1992-04-01','2000-11-01','jchero@unp.edu.pe','2026-11-08 15:08:26',NULL),(99,'03681099','Kevin Joel','Yovera Tavara','ASOCIADO','TC','ACTIVO',1,8,27,'MAESTRO','2007-10-15','2014-08-01','kyovera@unp.edu.pe','2026-11-08 15:08:26',NULL),(100,'03681100','Laura Beatri','Silva Sullon','AUXILIAR','TP','ACTIVO',1,8,28,'MAESTRO','2015-04-01','2015-04-01','lsilva@unp.edu.pe','2026-11-08 15:08:26',NULL),(101,'02606057','Jorge','Alvarado Tabacchi','ASOCIADO','TC','ACTIVO',1,12,38,'MAESTRO',NULL,NULL,'jalvaradot@unp.edu.pe','2026-11-25 10:53:25',NULL),(102,'02715290','Reucher Andrés','Correa Morocho','PRINCIPAL','DE','ACTIVO',1,12,38,'DOCTOR',NULL,NULL,'rcorream@unp.edu.pe','2026-11-25 10:53:25',NULL),(103,'02817835','Pedro Antonio','Criollo Gonzales','PRINCIPAL','DE','ACTIVO',1,12,38,'DOCTOR',NULL,NULL,'pcriollo@unp.edu.pe','2026-11-25 10:53:25',NULL),(104,'02635949','Wilfredo','Cruz Yarlequé','PRINCIPAL','DE','ACTIVO',1,12,38,'DOCTOR',NULL,NULL,'wcruz@unp.edu.pe','2026-11-25 10:53:25',NULL),(105,'02775932','Héctor Wilmer','Fiestas Bancayán','PRINCIPAL','DE','ACTIVO',1,12,38,'DOCTOR',NULL,NULL,'hfiestas@unp.edu.pe','2026-11-25 10:53:25',NULL),(106,'02867046','Iván Daniel','Imán Agurto','PRINCIPAL','DE','ACTIVO',1,12,38,'DOCTOR',NULL,NULL,'iiman@unp.edu.pe','2026-11-25 10:53:25',NULL),(107,'40682528','Rolando Elías','Ipanaque Silva','AUXILIAR','TC','ACTIVO',1,12,38,'MAESTRO',NULL,NULL,'ripanaque@unp.edu.pe','2026-11-25 10:53:25',NULL),(108,'02810146','Esther Yolanda','Lizana Puelles','ASOCIADO','TC','ACTIVO',1,12,38,'DOCTOR',NULL,NULL,'elizana@unp.edu.pe','2026-11-25 10:53:25',NULL),(109,'42627674','Jonathan David','Nima Ramos','AUXILIAR','TP','ACTIVO',1,12,38,'MAESTRO',NULL,NULL,'jnima@unp.edu.pe','2026-11-25 10:53:25',NULL),(110,'03691805','Hoower Augusto','Puicón Zapata','ASOCIADO','TC','ACTIVO',1,12,38,'DOCTOR',NULL,NULL,'hpuicon@unp.edu.pe','2026-11-25 10:53:25',NULL),(111,'02600704','Rigo Félix','Requena Flores','PRINCIPAL','DE','ACTIVO',1,12,38,'DOCTOR',NULL,NULL,'rrequena@unp.edu.pe','2026-11-25 10:53:25',NULL),(112,'42867712','Moisés David','Saavedra Arango','AUXILIAR','TC','ACTIVO',1,12,38,'DOCTOR',NULL,NULL,'msaavedra@unp.edu.pe','2026-11-25 10:53:25',NULL),(113,'02849179','Luis Armando','Saavedra Yarlequé','ASOCIADO','TC','ACTIVO',1,12,38,'MAESTRO',NULL,NULL,'lsaavedray@unp.edu.pe','2026-11-25 10:53:25',NULL),(114,'02887733','Arturo','Sandoval Rivera','ASOCIADO','DE','ACTIVO',1,12,38,'MAESTRO',NULL,NULL,'asandoval@unp.edu.pe','2026-11-25 10:53:25',NULL),(115,'02786563','Jorge Luis','Sandoval Rivera','ASOCIADO','TC','ACTIVO',1,12,38,'DOCTOR',NULL,NULL,'jsandoval@unp.edu.pe','2026-11-25 10:53:25',NULL),(116,'42813466','César','Silva More','AUXILIAR','TP','ACTIVO',1,12,38,'MAESTRO',NULL,NULL,'csilva@unp.edu.pe','2026-11-25 10:53:25',NULL),(117,'06433589','Víctor Hugo','Valle Rios','ASOCIADO','TC','ACTIVO',1,12,38,'MAESTRO',NULL,NULL,'vvalle@unp.edu.pe','2026-11-25 10:53:25',NULL);
/*!40000 ALTER TABLE `docente` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_docente_bi BEFORE INSERT ON docente
FOR EACH ROW
BEGIN
  DECLARE v_fac INT DEFAULT NULL;
  SELECT id_facultad INTO v_fac FROM departamento WHERE id_departamento = NEW.id_departamento;
  IF v_fac IS NOT NULL THEN
    SET NEW.id_facultad = v_fac;
  END IF;
  IF NEW.estado <> 'ACTIVO' THEN
    SET NEW.habilitado_para_votar = 0;
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_docente_bu BEFORE UPDATE ON docente
FOR EACH ROW
BEGIN
  DECLARE v_fac INT DEFAULT NULL;
  SELECT id_facultad INTO v_fac FROM departamento WHERE id_departamento = NEW.id_departamento;
  IF v_fac IS NOT NULL THEN
    SET NEW.id_facultad = v_fac;
  END IF;
  IF NEW.estado <> 'ACTIVO' THEN
    SET NEW.habilitado_para_votar = 0;
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `escrutinio_conteo`
--

DROP TABLE IF EXISTS `escrutinio_conteo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `escrutinio_conteo` (
  `id_conteo` int(11) NOT NULL AUTO_INCREMENT,
  `id_mesa` int(11) NOT NULL,
  `id_cargo` int(11) NOT NULL,
  `opcion` enum('LISTA','BLANCO','NULO','IMPUGNADO') NOT NULL,
  `id_lista` int(11) DEFAULT NULL,
  `votos_manual` int(11) NOT NULL,
  `votos_digital` int(11) NOT NULL DEFAULT 0,
  `lista_clave` int(11) GENERATED ALWAYS AS (coalesce(`id_lista`,0)) STORED,
  PRIMARY KEY (`id_conteo`),
  UNIQUE KEY `uq_conteo_opcion` (`id_mesa`,`id_cargo`,`opcion`,`lista_clave`),
  KEY `fk_conteo_cargo` (`id_cargo`),
  KEY `fk_conteo_lista` (`id_lista`),
  CONSTRAINT `fk_conteo_cargo` FOREIGN KEY (`id_cargo`) REFERENCES `cargo_electoral` (`id_cargo`),
  CONSTRAINT `fk_conteo_escrutinio` FOREIGN KEY (`id_mesa`) REFERENCES `escrutinio_mesa` (`id_mesa`),
  CONSTRAINT `fk_conteo_lista` FOREIGN KEY (`id_lista`) REFERENCES `lista_electoral` (`id_lista`),
  CONSTRAINT `chk_conteo_votos` CHECK (`votos_manual` >= 0 and `votos_digital` >= 0),
  CONSTRAINT `chk_conteo_lista` CHECK (`opcion` = 'LISTA' and `id_lista` is not null or `opcion` <> 'LISTA' and `id_lista` is null)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `escrutinio_conteo`
--

LOCK TABLES `escrutinio_conteo` WRITE;
/*!40000 ALTER TABLE `escrutinio_conteo` DISABLE KEYS */;
INSERT INTO `escrutinio_conteo` VALUES (1,1,1,'LISTA',1,4,4,1),(2,1,1,'LISTA',2,11,11,2),(4,1,1,'BLANCO',NULL,1,1,0),(5,1,1,'NULO',NULL,0,0,0),(6,1,1,'IMPUGNADO',NULL,0,0,0),(13,2,2,'LISTA',5,13,13,5),(14,2,2,'LISTA',4,4,4,4),(16,2,2,'BLANCO',NULL,0,0,0),(17,2,2,'NULO',NULL,0,0,0),(18,2,2,'IMPUGNADO',NULL,0,0,0);
/*!40000 ALTER TABLE `escrutinio_conteo` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_conteo_bi BEFORE INSERT ON escrutinio_conteo
FOR EACH ROW
BEGIN
  IF (SELECT estado FROM escrutinio_mesa WHERE id_mesa = NEW.id_mesa) IN ('ACTA_EMITIDA','ENTREGADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el acta de escrutinio ya fue emitida; el conteo no cambia.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_conteo_bu BEFORE UPDATE ON escrutinio_conteo
FOR EACH ROW
BEGIN
  IF (SELECT estado FROM escrutinio_mesa WHERE id_mesa = OLD.id_mesa) IN ('ACTA_EMITIDA','ENTREGADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el acta de escrutinio ya fue emitida; el conteo no cambia.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_conteo_bd BEFORE DELETE ON escrutinio_conteo
FOR EACH ROW
BEGIN
  IF (SELECT estado FROM escrutinio_mesa WHERE id_mesa = OLD.id_mesa) IN ('ACTA_EMITIDA','ENTREGADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el acta de escrutinio ya fue emitida; el conteo no cambia.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `escrutinio_mesa`
--

DROP TABLE IF EXISTS `escrutinio_mesa`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `escrutinio_mesa` (
  `id_mesa` int(11) NOT NULL,
  `estado` enum('CEDULAS_CONTADAS','CONTEO_REGISTRADO','ACTA_EMITIDA','ENTREGADA') NOT NULL DEFAULT 'CEDULAS_CONTADAS',
  `hora_inicio` datetime NOT NULL,
  `hora_fin` datetime DEFAULT NULL,
  `total_votantes` int(11) NOT NULL,
  `cedulas_contadas` int(11) NOT NULL,
  `cedulas_sobrantes` int(11) NOT NULL DEFAULT 0,
  `cedulas_faltantes` int(11) NOT NULL DEFAULT 0,
  `cedulas_escrutadas` int(11) NOT NULL,
  `observacion_cedulas` varchar(1000) DEFAULT NULL,
  `veces_conteo` int(11) NOT NULL DEFAULT 0,
  `conteo_cuadra` tinyint(1) DEFAULT NULL,
  `total_cuadra` tinyint(1) DEFAULT NULL,
  `fecha_conteo` datetime DEFAULT NULL,
  `prevalece_fisica` tinyint(1) NOT NULL DEFAULT 0,
  `observada` tinyint(1) NOT NULL DEFAULT 0,
  `observaciones` varchar(1000) DEFAULT NULL,
  `id_acta` int(11) DEFAULT NULL,
  `fecha_acta` datetime DEFAULT NULL,
  `fecha_entrega` datetime DEFAULT NULL,
  `recibido_por` varchar(150) DEFAULT NULL,
  `ejemplares` int(11) DEFAULT NULL,
  `copias_personeros` int(11) DEFAULT NULL,
  `entrega_padron` tinyint(1) DEFAULT NULL,
  `entrega_material` tinyint(1) DEFAULT NULL,
  `observacion_entrega` varchar(500) DEFAULT NULL,
  `codigo_cargo` char(12) DEFAULT NULL,
  `id_usuario_inicio` int(11) DEFAULT NULL,
  `id_usuario_conteo` int(11) DEFAULT NULL,
  `id_usuario_acta` int(11) DEFAULT NULL,
  `id_usuario_entrega` int(11) DEFAULT NULL,
  PRIMARY KEY (`id_mesa`),
  UNIQUE KEY `uq_escrutinio_acta` (`id_acta`),
  KEY `fk_escrutinio_inicio` (`id_usuario_inicio`),
  KEY `fk_escrutinio_conteo` (`id_usuario_conteo`),
  KEY `fk_escrutinio_emisor` (`id_usuario_acta`),
  KEY `fk_escrutinio_entrega` (`id_usuario_entrega`),
  CONSTRAINT `fk_escrutinio_acta` FOREIGN KEY (`id_acta`) REFERENCES `acta_electoral` (`id_acta`),
  CONSTRAINT `fk_escrutinio_conteo` FOREIGN KEY (`id_usuario_conteo`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `fk_escrutinio_emisor` FOREIGN KEY (`id_usuario_acta`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `fk_escrutinio_entrega` FOREIGN KEY (`id_usuario_entrega`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `fk_escrutinio_inicio` FOREIGN KEY (`id_usuario_inicio`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `fk_escrutinio_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`),
  CONSTRAINT `chk_escrutinio_cedulas` CHECK (`cedulas_contadas` >= 0 and `cedulas_sobrantes` >= 0 and `cedulas_faltantes` >= 0 and `cedulas_escrutadas` = `cedulas_contadas` - `cedulas_sobrantes`),
  CONSTRAINT `chk_escrutinio_acta` CHECK (`estado` not in ('ACTA_EMITIDA','ENTREGADA') or `id_acta` is not null and `hora_fin` is not null),
  CONSTRAINT `chk_escrutinio_entrega` CHECK (`estado` <> 'ENTREGADA' or `fecha_entrega` is not null and `recibido_por` is not null)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `escrutinio_mesa`
--

LOCK TABLES `escrutinio_mesa` WRITE;
/*!40000 ALTER TABLE `escrutinio_mesa` DISABLE KEYS */;
INSERT INTO `escrutinio_mesa` VALUES (1,'ENTREGADA','2026-11-25 15:34:02','2026-11-25 15:35:44',16,16,0,0,16,NULL,1,1,1,'2026-11-25 15:34:54',0,1,'hubo un elector que no voto',3,'2026-11-25 15:35:44','2026-11-25 15:41:32','lucano',3,0,1,1,NULL,'885A91ACD4A5',3,3,3,3),(2,'ENTREGADA','2026-11-25 15:09:16','2026-11-25 15:11:38',17,17,0,0,17,NULL,2,1,1,'2026-11-25 15:11:28',0,0,NULL,6,'2026-11-25 15:11:38','2026-11-25 15:12:39','lucano',3,0,1,1,NULL,'62A8894A7B9C',118,118,118,118);
/*!40000 ALTER TABLE `escrutinio_mesa` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_escrutinio_bu BEFORE UPDATE ON escrutinio_mesa
FOR EACH ROW
BEGIN
  IF OLD.estado = 'ENTREGADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: las actas de esta mesa ya se entregaron al CEUNP.';
  END IF;
  IF OLD.estado = 'ACTA_EMITIDA' AND NEW.estado <> 'ENTREGADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el acta de escrutinio de esta mesa ya fue emitida.';
  END IF;
  IF NEW.hora_inicio <> OLD.hora_inicio OR NEW.cedulas_contadas <> OLD.cedulas_contadas
     OR NEW.total_votantes <> OLD.total_votantes OR NEW.cedulas_sobrantes <> OLD.cedulas_sobrantes THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el conteo de cédulas del ánfora no se modifica.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_escrutinio_bd BEFORE DELETE ON escrutinio_mesa
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el registro del escrutinio no se elimina.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `facultad`
--

DROP TABLE IF EXISTS `facultad`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `facultad` (
  `id_facultad` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(150) NOT NULL,
  PRIMARY KEY (`id_facultad`),
  UNIQUE KEY `uq_facultad_nombre` (`nombre`)
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
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `firma_acta`
--

LOCK TABLES `firma_acta` WRITE;
/*!40000 ALTER TABLE `firma_acta` DISABLE KEYS */;
INSERT INTO `firma_acta` VALUES (1,1,107,'PRESIDENTE DE MESA','04f2f4792d632356e782b4370c36ed653940b824c56979fc97f65b330f33730d','2026-11-25 09:15:57'),(2,1,108,'SECRETARIO DE MESA','418afe3105dc1efc5418c5e52352e2b34dcfd11e1a8ca6c00f06dd69b9f6597f','2026-11-25 09:15:57'),(3,1,111,'VOCAL DE MESA','2680d43134dd64dc6391f2ae8a028ab0dca94860831ff391f96199a611f3d052','2026-11-25 09:15:57'),(4,2,107,'PRESIDENTE DE MESA','08a618790b53f142d34d5e93ecd7f941847f9271e4fbf5dd421500ac6e6cd88d','2026-11-25 15:31:59'),(5,2,108,'SECRETARIO DE MESA','76b62a5223c2b6e996d289547b4b148666eb633f5f8aa5823f373dbab339f46d','2026-11-25 15:31:59'),(7,3,107,'PRESIDENTE DE MESA','83ef3a02970ee7d55c0c080b8396f2c9b50810174f2e62100bfcee8363dbf2dd','2026-11-25 15:35:44'),(8,3,108,'SECRETARIO DE MESA','0020b04bc8c86ed70b14bc9150e8c8b9869b413bfada62431e9414ff845d82b2','2026-11-25 15:35:44'),(9,3,111,'VOCAL DE MESA','ccc5f9987ac8574f4fe7c082252f12eefd302f50d2a1e1f954822ef8e6fdafc6','2026-11-25 15:35:44'),(10,4,110,'VOCAL DE MESA','bfff24314680875f2d70109f58bf908ce9cced86d163c33682f2e3e651901a39','2026-11-25 09:17:30'),(11,4,115,'PRESIDENTE DE MESA','1015bea4ab443d4e62709bafa2011bd6725f5b029332b60ff6a71c69e2dceeae','2026-11-25 09:17:30'),(12,4,117,'SECRETARIO DE MESA','e17b8b82df834c595229932f5af7d9221c4b903863a15efc05209790b986e48f','2026-11-25 09:17:30'),(13,5,115,'PRESIDENTE DE MESA','d181ac660dc27bb9a67b226115744afa2e7444e734bb23eb4ddad33bd156ccd7','2026-11-25 15:08:38'),(14,5,117,'SECRETARIO DE MESA','358ddcb542d561b081324130d593fc8c34e51526c6f5bdc2874d05bce8e57893','2026-11-25 15:08:38'),(16,6,110,'VOCAL DE MESA','eca1990dc29a72e5a6744f71cc02af0c7656e20e13d1b5a9a0886bf54634496b','2026-11-25 15:11:38'),(17,6,115,'PRESIDENTE DE MESA','1034ced9a4762402af40adbd16300b0f24b378abca250f34731dc6dbadd9c008','2026-11-25 15:11:38'),(18,6,117,'SECRETARIO DE MESA','702f4a0a3ca737b7267390a54a5abfa2ed72e4db698236eb977e402ff428035d','2026-11-25 15:11:38');
/*!40000 ALTER TABLE `firma_acta` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `habilitacion_terminal`
--

DROP TABLE IF EXISTS `habilitacion_terminal`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `habilitacion_terminal` (
  `id_habilitacion` bigint(20) NOT NULL AUTO_INCREMENT,
  `id_asistencia` bigint(20) NOT NULL,
  `id_terminal` int(11) NOT NULL,
  `rehabilitacion` tinyint(1) NOT NULL DEFAULT 0,
  `token_hash` char(64) DEFAULT NULL,
  `fecha_habilitacion` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_entrega` datetime DEFAULT NULL,
  `estado` enum('PENDIENTE','CONSUMIDA','ANULADA') NOT NULL DEFAULT 'PENDIENTE',
  `fecha_cierre` datetime DEFAULT NULL,
  `motivo_anulacion` varchar(255) DEFAULT NULL,
  `id_usuario_mesa` int(11) DEFAULT NULL,
  `pendiente_asist` bigint(20) GENERATED ALWAYS AS (if(`estado` = 'PENDIENTE',`id_asistencia`,NULL)) STORED,
  `pendiente_term` int(11) GENERATED ALWAYS AS (if(`estado` = 'PENDIENTE',`id_terminal`,NULL)) STORED,
  PRIMARY KEY (`id_habilitacion`),
  UNIQUE KEY `uq_habilitacion_elector` (`pendiente_asist`),
  UNIQUE KEY `uq_habilitacion_terminal` (`pendiente_term`),
  UNIQUE KEY `uq_habilitacion_token` (`token_hash`),
  KEY `fk_habilitacion_asistencia` (`id_asistencia`),
  KEY `fk_habilitacion_terminal` (`id_terminal`),
  KEY `fk_habilitacion_usuario` (`id_usuario_mesa`),
  CONSTRAINT `fk_habilitacion_asistencia` FOREIGN KEY (`id_asistencia`) REFERENCES `asistencia_elector` (`id_asistencia`),
  CONSTRAINT `fk_habilitacion_terminal` FOREIGN KEY (`id_terminal`) REFERENCES `terminal_votacion` (`id_terminal`),
  CONSTRAINT `fk_habilitacion_usuario` FOREIGN KEY (`id_usuario_mesa`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `chk_habilitacion_cierre` CHECK (`estado` = 'PENDIENTE' or `fecha_cierre` is not null),
  CONSTRAINT `chk_habilitacion_anulada` CHECK (`estado` <> 'ANULADA' or `motivo_anulacion` is not null)
) ENGINE=InnoDB AUTO_INCREMENT=35 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `habilitacion_terminal`
--

LOCK TABLES `habilitacion_terminal` WRITE;
/*!40000 ALTER TABLE `habilitacion_terminal` DISABLE KEYS */;
INSERT INTO `habilitacion_terminal` VALUES (1,1,1,0,'86dc7432b33e04879cf7796ad2f486a73e1a4c1c8a454f39d741c3542c445a5a','2026-11-25 09:37:20','2026-11-25 09:37:49','CONSUMIDA','2026-11-25 09:44:02',NULL,118,NULL,NULL),(2,2,1,0,'1181111812eb50ea4de3ca1eef0ebff16d487f84a73207e9ffc5f76da51a9879','2026-11-25 09:59:07','2026-11-25 09:59:13','ANULADA','2026-11-25 09:59:48','error',118,NULL,NULL),(3,3,1,0,'cbf5544f79589a652593c12d79d9feb3d766fb2d351519b719ea3e422783201e','2026-11-25 10:02:08','2026-11-25 10:02:16','CONSUMIDA','2026-11-25 10:02:24',NULL,118,NULL,NULL),(4,4,1,0,'2a410a57e0d571dfc9c117bb44d8eb774b8fff5e054b128b3628ad6e45385e1c','2026-11-25 10:10:14','2026-11-25 10:10:17','CONSUMIDA','2026-11-25 10:10:30',NULL,120,NULL,NULL),(5,5,1,0,'adc56509c719b660c1bdfc83192e33b0b15d2cca91cc3dcd712005b767e9869b','2026-11-25 10:10:47','2026-11-25 10:10:49','CONSUMIDA','2026-11-25 10:10:58',NULL,120,NULL,NULL),(6,6,1,0,'7f57ecae8d289c8a0b40593b1cb7c704738ca7b0a3b665d663170298d64043b1','2026-11-25 10:11:24','2026-11-25 10:11:25','CONSUMIDA','2026-11-25 10:11:31',NULL,120,NULL,NULL),(7,7,1,0,'100eb0358c417e503b341a2776d7bf145fbbf367e800f9182a91729c25b30941','2026-11-25 10:18:37','2026-11-25 10:18:38','CONSUMIDA','2026-11-25 10:18:43',NULL,120,NULL,NULL),(8,8,1,0,'4b4694a66629535e064ad6c47542c8648d55e20cab02705d048aebe5bd10b31a','2026-11-25 10:18:56','2026-11-25 10:18:58','CONSUMIDA','2026-11-25 10:19:03',NULL,120,NULL,NULL),(9,9,1,0,'e1ccd7977b203f8b9f915790bc98c9176ba11ce4743894816b8341d00265fe81','2026-11-25 10:19:18','2026-11-25 10:19:18','CONSUMIDA','2026-11-25 10:19:23',NULL,120,NULL,NULL),(10,10,1,0,'a1e4fe832493cffa95c46e3a8c6165b2383f35efc257a8370743dcad100fd1c1','2026-11-25 10:19:58','2026-11-25 10:20:00','CONSUMIDA','2026-11-25 10:20:11',NULL,120,NULL,NULL),(11,11,1,0,'edcae445ab2bbdb0eb74f31f8a45d27883488da1d463d315927878b20de2ece3','2026-11-25 10:26:41','2026-11-25 10:26:41','CONSUMIDA','2026-11-25 10:26:51',NULL,111,NULL,NULL),(12,12,1,0,'cd8101042360fc2d567cade3c1aee7a768fa2724d0f66b642ff3b2908bc37d24','2026-11-25 10:26:58','2026-11-25 10:26:59','CONSUMIDA','2026-11-25 10:27:05',NULL,111,NULL,NULL),(13,13,1,0,'57b75fa1041d68fe91a7b7f213898e8308429aa69ef10760e66b04d79b321740','2026-11-25 10:27:15','2026-11-25 10:27:16','CONSUMIDA','2026-11-25 10:27:18',NULL,111,NULL,NULL),(14,14,1,0,'cb0cb48230667956ac2230b1d59b1a64de2f96fbd70d6290585594a26ef37c76','2026-11-25 10:28:13','2026-11-25 10:28:14','CONSUMIDA','2026-11-25 10:28:17',NULL,111,NULL,NULL),(15,15,1,0,'2730ae452fc8ea7cd3c17a4ee7f69cf4ecc583ff3ee41c3ec8a76f788a802b77','2026-11-25 10:28:23','2026-11-25 10:28:25','CONSUMIDA','2026-11-25 10:28:27',NULL,111,NULL,NULL),(16,16,1,0,'ba09fb754533bb145bf731b58ad2c900b4e4dbf9465f838287dbd26bfc89235b','2026-11-25 10:28:34','2026-11-25 10:28:34','CONSUMIDA','2026-11-25 10:28:38',NULL,111,NULL,NULL),(17,17,1,0,'1146fe3c3a860391d402d25897f9f9c745762b4027e02acc6becdcbb4ef9690a','2026-11-25 10:28:44','2026-11-25 10:28:46','CONSUMIDA','2026-11-25 10:28:50',NULL,111,NULL,NULL),(18,18,2,0,'2101f1ede17caad9cb3bb198f5998890ef2a2e70c096fd7ff5e47033539bdb02','2026-11-25 09:21:18','2026-11-25 09:21:19','CONSUMIDA','2026-11-25 09:21:25',NULL,118,NULL,NULL),(19,19,2,0,'29c11b72edce641a58d870518ab26323a5f43878ba64441180333ab2f142b56b','2026-11-25 09:21:33','2026-11-25 09:21:33','CONSUMIDA','2026-11-25 09:21:52',NULL,118,NULL,NULL),(20,20,2,0,'bb25d3c11ac77fd1bf83a555d9c0e839295942f68428d90f0d620beb811b1caf','2026-11-25 09:22:01','2026-11-25 09:22:01','CONSUMIDA','2026-11-25 09:22:10',NULL,118,NULL,NULL),(21,21,2,0,'2bbaba8092e9e3da80268a9001dc961f24c8b49c66933f90b6bfa64c3c901277','2026-11-25 09:22:20','2026-11-25 09:22:21','CONSUMIDA','2026-11-25 09:22:26',NULL,118,NULL,NULL),(22,22,2,0,'7d49f75619b0ad2b09691aba6ce7911c0dbdebcad23821aa1c05ac1466d89b9e','2026-11-25 09:22:34','2026-11-25 09:22:37','CONSUMIDA','2026-11-25 09:22:40',NULL,118,NULL,NULL),(23,23,2,0,'9c77f9040b04dde858a6e1ee7cd1753d3ea5fb3df5a58232bc504eb84c43461f','2026-11-25 09:26:31','2026-11-25 09:26:33','CONSUMIDA','2026-11-25 09:26:38',NULL,118,NULL,NULL),(24,24,2,0,'9e2762f06f5a3369a6128a70f2e5ac821a83f71c13c7d5274740f0a37f5ace8e','2026-11-25 09:26:49','2026-11-25 09:26:49','CONSUMIDA','2026-11-25 09:26:54',NULL,118,NULL,NULL),(25,25,2,0,'57020bc57c33395d7396a743bd13f42f015607f0e8ed21a4b9db3d9e82522aa8','2026-11-25 09:27:03','2026-11-25 09:27:04','CONSUMIDA','2026-11-25 09:27:07',NULL,118,NULL,NULL),(26,26,2,0,'5ad4c6577592538049445f914e5c15c498a8940bfd2d3809d2e13df0989a9ddf','2026-11-25 09:27:12','2026-11-25 09:27:14','CONSUMIDA','2026-11-25 09:27:17',NULL,118,NULL,NULL),(27,27,2,0,'b9ef13a59d37a74d5b543b0330b72afe71bbd56f45c74f191c6b7e8959bbb7bf','2026-11-25 09:27:22','2026-11-25 09:27:24','CONSUMIDA','2026-11-25 09:27:26',NULL,118,NULL,NULL),(28,28,2,0,'78c792dce3b0e6ae1008f84f38b2754fae498782074e18b8c7d1cd36d410b17b','2026-11-25 09:27:34','2026-11-25 09:27:34','CONSUMIDA','2026-11-25 09:27:39',NULL,118,NULL,NULL),(29,29,2,0,'d1fd6676b95c411a0ca6a4bbeebeab9e25a9fd992698e96dd35155470469ef9e','2026-11-25 09:27:44','2026-11-25 09:27:46','CONSUMIDA','2026-11-25 09:27:48',NULL,118,NULL,NULL),(30,30,2,0,'6243c1935be7f1c6f9cec3c6233ff832a4b5361e5f4c1e0bbcfb738916987f6d','2026-11-25 09:27:58','2026-11-25 09:27:59','CONSUMIDA','2026-11-25 09:28:02',NULL,118,NULL,NULL),(31,31,2,0,'bd4c4e88b6b11d0641c5c67dfb1705748ecddf77f3435aadbee5e3cb6ab40b0a','2026-11-25 09:28:07','2026-11-25 09:28:09','CONSUMIDA','2026-11-25 09:28:12',NULL,118,NULL,NULL),(32,32,2,0,'9ca1bd72a9225d51514027bb5ebcb6d856359e4c08c878e7b8438378f906acf4','2026-11-25 09:28:17','2026-11-25 09:28:19','CONSUMIDA','2026-11-25 09:28:21',NULL,118,NULL,NULL),(33,33,2,0,'eef7ce2c203bef2ba3a1baa3afc56b2dc947b72c85ce412e3796b1cb6d109ca0','2026-11-25 09:28:32','2026-11-25 09:28:34','CONSUMIDA','2026-11-25 09:28:37',NULL,118,NULL,NULL),(34,34,2,0,'07d98b253a48f475f2c06132b604a2f0d83b92d380556c6cecf0a478691daf5d','2026-11-25 09:28:43','2026-11-25 09:28:45','CONSUMIDA','2026-11-25 09:28:47',NULL,118,NULL,NULL);
/*!40000 ALTER TABLE `habilitacion_terminal` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_habilitacion_bd BEFORE DELETE ON habilitacion_terminal
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Las habilitaciones de terminal no se eliminan: se anulan.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

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
  `id_cargo` int(11) DEFAULT NULL COMMENT 'CUS12: cargo de la cédula impugnada durante el escrutinio',
  `id_acta` int(11) DEFAULT NULL,
  `motivo` text NOT NULL,
  `decision_mesa` enum('PENDIENTE','ACEPTADA','RECHAZADA') NOT NULL DEFAULT 'PENDIENTE',
  `votos_mesa_favor` tinyint(4) DEFAULT NULL COMMENT 'CUS13: miembros de mesa a favor de la impugnación',
  `votos_mesa_contra` tinyint(4) DEFAULT NULL COMMENT 'CUS13: miembros de mesa en contra',
  `opcion_mesa` enum('LISTA','BLANCO','NULO') DEFAULT NULL COMMENT 'CUS13: opción a la que la mesa asigna la cédula',
  `id_lista_mesa` int(11) DEFAULT NULL COMMENT 'CUS13: lista, si opcion_mesa = LISTA',
  `fundamento_mesa` varchar(1000) DEFAULT NULL COMMENT 'CUS13: fundamento de la decisión de la mesa',
  `fecha_decision_mesa` datetime DEFAULT NULL COMMENT 'CUS13: hora de la decisión de la mesa',
  `id_usuario_mesa` int(11) DEFAULT NULL COMMENT 'CUS13: presidente que registró la decisión',
  `id_personero_apela` int(11) DEFAULT NULL COMMENT 'CUS13: personero que apela',
  `fundamento_apelacion` varchar(1000) DEFAULT NULL COMMENT 'CUS13: fundamento de la apelación',
  `fecha_apelacion` datetime DEFAULT NULL COMMENT 'CUS13: hora de la apelación',
  `id_usuario_apelacion` int(11) DEFAULT NULL COMMENT 'CUS13: cuenta que registró la apelación',
  `decision_ceunp` enum('PENDIENTE','CONFIRMADA','MODIFICADA') NOT NULL DEFAULT 'PENDIENTE',
  `numero_resolucion` varchar(40) DEFAULT NULL COMMENT 'CUS13: número de la resolución del CEUNP',
  `miembros_pleno` tinyint(4) DEFAULT NULL COMMENT 'CUS13: miembros del Pleno presentes (quórum)',
  `votos_pleno_favor` tinyint(4) DEFAULT NULL COMMENT 'CUS13: votos a favor de la apelación',
  `votos_pleno_contra` tinyint(4) DEFAULT NULL COMMENT 'CUS13: votos en contra de la apelación',
  `voto_dirimente` enum('FAVOR','CONTRA') DEFAULT NULL COMMENT 'CUS13: voto dirimente del Presidente en empate',
  `opcion_final` enum('LISTA','BLANCO','NULO') DEFAULT NULL COMMENT 'CUS13: opción final fijada por el CEUNP',
  `id_lista_final` int(11) DEFAULT NULL COMMENT 'CUS13: lista, si opcion_final = LISTA',
  `fundamento_ceunp` varchar(1000) DEFAULT NULL COMMENT 'CUS13: fundamento del fallo',
  `fecha_fallo` datetime DEFAULT NULL COMMENT 'CUS13: fecha del fallo del CEUNP',
  `id_usuario_ceunp` int(11) DEFAULT NULL COMMENT 'CUS13: cuenta del CEUNP que registró el fallo',
  `estado` enum('PRESENTADA','RESUELTA','APELADA') NOT NULL DEFAULT 'PRESENTADA',
  `fecha_presentacion` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_resolucion` datetime DEFAULT NULL,
  PRIMARY KEY (`id_impugnacion`),
  UNIQUE KEY `uq_impugnacion_resolucion` (`numero_resolucion`),
  KEY `fk_impugnacion_personero` (`id_personero`),
  KEY `fk_impugnacion_mesa` (`id_mesa`),
  KEY `ix_impugnacion_estado` (`id_proceso`,`estado`),
  KEY `fk_impugnacion_acta` (`id_acta`),
  KEY `fk_impugnacion_cargo` (`id_cargo`),
  KEY `fk_impugnacion_lista_mesa` (`id_lista_mesa`),
  KEY `fk_impugnacion_lista_final` (`id_lista_final`),
  KEY `fk_impugnacion_usuario_mesa` (`id_usuario_mesa`),
  KEY `fk_impugnacion_apelante` (`id_personero_apela`),
  KEY `fk_impugnacion_usuario_apel` (`id_usuario_apelacion`),
  KEY `fk_impugnacion_usuario_ceunp` (`id_usuario_ceunp`),
  CONSTRAINT `fk_impugnacion_acta` FOREIGN KEY (`id_acta`) REFERENCES `acta_electoral` (`id_acta`),
  CONSTRAINT `fk_impugnacion_apelante` FOREIGN KEY (`id_personero_apela`) REFERENCES `personero` (`id_personero`),
  CONSTRAINT `fk_impugnacion_cargo` FOREIGN KEY (`id_cargo`) REFERENCES `cargo_electoral` (`id_cargo`),
  CONSTRAINT `fk_impugnacion_lista_final` FOREIGN KEY (`id_lista_final`) REFERENCES `lista_electoral` (`id_lista`),
  CONSTRAINT `fk_impugnacion_lista_mesa` FOREIGN KEY (`id_lista_mesa`) REFERENCES `lista_electoral` (`id_lista`),
  CONSTRAINT `fk_impugnacion_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`),
  CONSTRAINT `fk_impugnacion_personero` FOREIGN KEY (`id_personero`) REFERENCES `personero` (`id_personero`),
  CONSTRAINT `fk_impugnacion_proceso` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`),
  CONSTRAINT `fk_impugnacion_usuario_apel` FOREIGN KEY (`id_usuario_apelacion`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `fk_impugnacion_usuario_ceunp` FOREIGN KEY (`id_usuario_ceunp`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `fk_impugnacion_usuario_mesa` FOREIGN KEY (`id_usuario_mesa`) REFERENCES `usuario` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `impugnacion_electoral`
--

LOCK TABLES `impugnacion_electoral` WRITE;
/*!40000 ALTER TABLE `impugnacion_electoral` DISABLE KEYS */;
/*!40000 ALTER TABLE `impugnacion_electoral` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_impugnacion_bu BEFORE UPDATE ON impugnacion_electoral
FOR EACH ROW
BEGIN
  IF OLD.decision_ceunp <> 'PENDIENTE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el fallo del CEUNP es inapelable; la impugnación ya no cambia.';
  END IF;
  IF NOT (NEW.id_personero <=> OLD.id_personero) OR NOT (NEW.id_mesa <=> OLD.id_mesa)
     OR NOT (NEW.id_proceso <=> OLD.id_proceso) OR NOT (NEW.motivo <=> OLD.motivo)
     OR (OLD.id_cargo IS NOT NULL AND NOT (NEW.id_cargo <=> OLD.id_cargo)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS13: los datos de la impugnación presentada no se modifican.';
  END IF;
  IF OLD.decision_mesa <> 'PENDIENTE' AND (NOT (NEW.decision_mesa <=> OLD.decision_mesa)
     OR NOT (NEW.opcion_mesa <=> OLD.opcion_mesa) OR NOT (NEW.id_lista_mesa <=> OLD.id_lista_mesa)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN23: la decisión de la mesa solo se revisa por apelación ante el CEUNP.';
  END IF;
  IF OLD.fecha_apelacion IS NOT NULL AND NOT (NEW.fecha_apelacion <=> OLD.fecha_apelacion) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF81: la impugnación ya fue apelada.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_impugnacion_bu_cus15 BEFORE UPDATE ON impugnacion_electoral
FOR EACH ROW
BEGIN
  IF NEW.numero_resolucion IS NOT NULL AND NOT (NEW.numero_resolucion <=> OLD.numero_resolucion)
     AND (EXISTS (SELECT 1 FROM nulidad_electoral WHERE numero_resolucion = NEW.numero_resolucion)
          OR EXISTS (SELECT 1 FROM dirimencia_empate WHERE numero_resolucion = NEW.numero_resolucion)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_impugnacion_bu_cus16 BEFORE UPDATE ON impugnacion_electoral
FOR EACH ROW
BEGIN
  IF NEW.numero_resolucion IS NOT NULL AND NOT (NEW.numero_resolucion <=> OLD.numero_resolucion)
     AND (EXISTS (SELECT 1 FROM reporte_multas WHERE numero_resolucion = NEW.numero_resolucion)
          OR EXISTS (SELECT 1 FROM multa_justificacion WHERE numero_resolucion = NEW.numero_resolucion)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_impugnacion_bd BEFORE DELETE ON impugnacion_electoral
FOR EACH ROW
BEGIN
  IF OLD.decision_mesa <> 'PENDIENTE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS13: una impugnación resuelta no se elimina.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `incidencia_mesa`
--

DROP TABLE IF EXISTS `incidencia_mesa`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `incidencia_mesa` (
  `id_incidencia` bigint(20) NOT NULL AUTO_INCREMENT,
  `id_proceso` int(11) NOT NULL,
  `id_mesa` int(11) NOT NULL,
  `id_docente` int(11) DEFAULT NULL,
  `tipo` enum('QR_INVALIDO','NO_FIGURA','OTRA_MESA','YA_REGISTRADO','INHABILITADO','SUPLANTACION','ABANDONO_TERMINAL','FALLA_TERMINAL','REHABILITACION') NOT NULL,
  `detalle` varchar(500) DEFAULT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `id_usuario` int(11) DEFAULT NULL,
  PRIMARY KEY (`id_incidencia`),
  KEY `ix_incidencia_mesa` (`id_mesa`,`fecha`),
  KEY `fk_incidencia_proceso` (`id_proceso`),
  KEY `fk_incidencia_docente` (`id_docente`),
  KEY `fk_incidencia_usuario` (`id_usuario`),
  CONSTRAINT `fk_incidencia_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`),
  CONSTRAINT `fk_incidencia_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`),
  CONSTRAINT `fk_incidencia_proceso` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`),
  CONSTRAINT `fk_incidencia_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `incidencia_mesa`
--

LOCK TABLES `incidencia_mesa` WRITE;
/*!40000 ALTER TABLE `incidencia_mesa` DISABLE KEYS */;
INSERT INTO `incidencia_mesa` VALUES (1,1,1,101,'ABANDONO_TERMINAL','error','2026-11-25 09:59:48',118),(2,1,1,101,'YA_REGISTRADO','Asistencia ya registrada y sin voto.','2026-11-25 10:00:28',118),(3,1,1,NULL,'QR_INVALIDO','El código leído no es una credencial del sistema electoral.','2026-11-25 10:00:30',118),(4,1,1,101,'YA_REGISTRADO','Asistencia ya registrada y sin voto.','2026-11-25 10:00:35',118),(5,1,1,NULL,'QR_INVALIDO','El código leído no es una credencial del sistema electoral.','2026-11-25 10:00:39',118),(6,2,2,NULL,'FALLA_TERMINAL','Terminal Cabina 1 fuera de servicio.','2026-11-25 09:29:05',118);
/*!40000 ALTER TABLE `incidencia_mesa` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_incidencia_mesa_bd BEFORE DELETE ON incidencia_mesa
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Las incidencias de mesa no se eliminan.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `instalacion_mesa`
--

DROP TABLE IF EXISTS `instalacion_mesa`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `instalacion_mesa` (
  `id_mesa` int(11) NOT NULL,
  `estado` enum('EN_CURSO','INSTALADA','NO_INSTALADA') NOT NULL DEFAULT 'EN_CURSO',
  `material_json` longtext DEFAULT NULL,
  `material_completo` tinyint(1) NOT NULL DEFAULT 0,
  `cedulas_recibidas` int(11) DEFAULT NULL,
  `cedulas_firmadas` tinyint(1) NOT NULL DEFAULT 0,
  `observaciones` varchar(500) DEFAULT NULL,
  `fecha_inicio` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_actualizacion` datetime DEFAULT NULL,
  `hora_instalacion` datetime DEFAULT NULL,
  `motivo_no_instalacion` varchar(255) DEFAULT NULL,
  `automatica` tinyint(1) NOT NULL DEFAULT 0,
  `evaluacion_nulidad` enum('PROCEDE','NO_PROCEDE') DEFAULT NULL,
  `fundamento_evaluacion` varchar(500) DEFAULT NULL,
  `fecha_evaluacion` datetime DEFAULT NULL,
  `id_usuario_registro` int(11) DEFAULT NULL,
  `id_usuario_cierre` int(11) DEFAULT NULL,
  `id_usuario_evaluacion` int(11) DEFAULT NULL,
  PRIMARY KEY (`id_mesa`),
  KEY `fk_instalacion_registro` (`id_usuario_registro`),
  KEY `fk_instalacion_cierre` (`id_usuario_cierre`),
  KEY `fk_instalacion_evaluacion` (`id_usuario_evaluacion`),
  CONSTRAINT `fk_instalacion_cierre` FOREIGN KEY (`id_usuario_cierre`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `fk_instalacion_evaluacion` FOREIGN KEY (`id_usuario_evaluacion`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `fk_instalacion_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`),
  CONSTRAINT `fk_instalacion_registro` FOREIGN KEY (`id_usuario_registro`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `chk_instalacion_json` CHECK (`material_json` is null or json_valid(`material_json`)),
  CONSTRAINT `chk_instalacion_cedulas` CHECK (`cedulas_recibidas` is null or `cedulas_recibidas` >= 0),
  CONSTRAINT `chk_instalacion_motivo` CHECK (`estado` <> 'NO_INSTALADA' or `motivo_no_instalacion` is not null),
  CONSTRAINT `chk_instalacion_evaluacion` CHECK (`evaluacion_nulidad` is null or `estado` = 'NO_INSTALADA' and `fundamento_evaluacion` is not null and `fecha_evaluacion` is not null)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `instalacion_mesa`
--

LOCK TABLES `instalacion_mesa` WRITE;
/*!40000 ALTER TABLE `instalacion_mesa` DISABLE KEYS */;
INSERT INTO `instalacion_mesa` VALUES (1,'INSTALADA','{\"PADRON\":{\"estado\":\"CONFORME\",\"observacion\":null},\"ACTAS\":{\"estado\":\"CONFORME\",\"observacion\":null},\"CEDULAS\":{\"estado\":\"CONFORME\",\"observacion\":null},\"CARTEL_CANDIDATOS\":{\"estado\":\"CONFORME\",\"observacion\":null},\"ANFORA\":{\"estado\":\"CONFORME\",\"observacion\":null},\"CABINA\":{\"estado\":\"CONFORME\",\"observacion\":null}}',1,17,1,'ya esta todo listo','2026-11-25 09:13:05','2026-11-25 09:15:57','2026-11-25 09:15:57',NULL,0,NULL,NULL,NULL,3,3,NULL),(2,'INSTALADA','{\"PADRON\":{\"estado\":\"CONFORME\",\"observacion\":null},\"ACTAS\":{\"estado\":\"CONFORME\",\"observacion\":null},\"CEDULAS\":{\"estado\":\"CONFORME\",\"observacion\":null},\"CARTEL_CANDIDATOS\":{\"estado\":\"CONFORME\",\"observacion\":null},\"ANFORA\":{\"estado\":\"CONFORME\",\"observacion\":null},\"CABINA\":{\"estado\":\"CONFORME\",\"observacion\":null}}',1,17,1,'Todo conforme','2026-11-25 09:17:09','2026-11-25 09:17:30','2026-11-25 09:17:30',NULL,0,NULL,NULL,NULL,3,3,NULL);
/*!40000 ALTER TABLE `instalacion_mesa` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_instalacion_bu BEFORE UPDATE ON instalacion_mesa
FOR EACH ROW
BEGIN
  IF OLD.estado <> 'EN_CURSO'
     AND NOT (OLD.estado = 'NO_INSTALADA' AND NEW.estado = 'NO_INSTALADA'
              AND OLD.evaluacion_nulidad IS NULL AND NEW.evaluacion_nulidad IS NOT NULL
              AND NEW.motivo_no_instalacion <=> OLD.motivo_no_instalacion) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS08: la instalación de esta mesa ya se cerró.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_instalacion_bd BEFORE DELETE ON instalacion_mesa
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS08: el registro de instalación no se elimina.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

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
  `url_plan_gobierno` varchar(300) DEFAULT NULL,
  `motivo_exclusion` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`id_lista`),
  UNIQUE KEY `uq_lista_cargo_nombre` (`id_cargo`,`nombre`),
  UNIQUE KEY `uq_lista_cargo` (`id_lista`,`id_cargo`),
  UNIQUE KEY `uq_lista_cargo_orden` (`id_cargo`,`orden_cedula`),
  CONSTRAINT `fk_lista_cargo` FOREIGN KEY (`id_cargo`) REFERENCES `cargo_electoral` (`id_cargo`),
  CONSTRAINT `chk_lista_orden` CHECK (`orden_cedula` is null or `orden_cedula` > 0)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lista_electoral`
--

LOCK TABLES `lista_electoral` WRITE;
/*!40000 ALTER TABLE `lista_electoral` DISABLE KEYS */;
INSERT INTO `lista_electoral` VALUES (1,1,'A','a',1,'ADMITIDA','2026-10-20 11:41:51',NULL,NULL),(2,1,'B','b',2,'ADMITIDA','2026-10-20 11:42:23',NULL,NULL),(4,2,'Innovación Informática','II',2,'ADMITIDA','2026-10-15 14:06:10',NULL,NULL),(5,2,'Avance TI','TI',1,'ADMITIDA','2026-10-15 14:06:43','https://github.com/',NULL);
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
  `detalle_json` longtext DEFAULT NULL,
  `hash_anterior` char(64) DEFAULT NULL COMMENT 'CUS19: sello del registro anterior (cadena SHA-256)',
  `hash_registro` char(64) DEFAULT NULL COMMENT 'CUS19: SHA-256 del registro encadenado al anterior',
  PRIMARY KEY (`id_log`),
  KEY `ix_log_fecha` (`fecha_hora`),
  KEY `ix_log_accion` (`accion`,`fecha_hora`),
  KEY `ix_log_usuario_fecha` (`id_usuario`,`fecha_hora`),
  KEY `ix_log_proceso_fecha` (`id_proceso`,`fecha_hora`),
  KEY `ix_log_ip_fecha` (`ip_origen`,`fecha_hora`),
  KEY `fk_log_docente` (`id_docente`),
  CONSTRAINT `fk_log_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`),
  CONSTRAINT `fk_log_proceso` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`),
  CONSTRAINT `fk_log_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `chk_log_json` CHECK (`detalle_json` is null or json_valid(`detalle_json`))
) ENGINE=InnoDB AUTO_INCREMENT=351 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `log_auditoria`
--

LOCK TABLES `log_auditoria` WRITE;
/*!40000 ALTER TABLE `log_auditoria` DISABLE KEYS */;
INSERT INTO `log_auditoria` VALUES (1,NULL,NULL,NULL,'REINICIAR_BITACORA',NULL,NULL,'2026-11-25 10:52:36','{\"script\": \"02_limpiar_datos_electorales.sql\", \"usuario_bd\": \"root@localhost\"}','0000000000000000000000000000000000000000000000000000000000000000','be6cbccce6a6f7ea53a5d83a819d3d1d67cade7ee6fa1d03e78c6730e2380bc3'),(2,3,NULL,1,'CREAR_PROCESO',NULL,NULL,'2026-10-25 11:05:07','{\"nombre\": \"Elección de Jefe de Departamento de Informática 2026-II\"}','be6cbccce6a6f7ea53a5d83a819d3d1d67cade7ee6fa1d03e78c6730e2380bc3','27affdfc752046bbe812fb7ee7cfae8d6df672f84f45b8095f65e79e8304431c'),(3,3,NULL,1,'AGREGAR_CARGO',NULL,NULL,'2026-10-25 11:05:44','{\"id_cargo\": \"1\", \"nombre\": \"Jefe de Departamento Académico\", \"nivel\": \"DEPARTAMENTO\", \"id_jurisdiccion\": \"38\", \"votan\": \"PRINCIPAL,ASOCIADO,AUXILIAR\", \"postulan\": \"PRINCIPAL\"}','27affdfc752046bbe812fb7ee7cfae8d6df672f84f45b8095f65e79e8304431c','6d590d87374c64af6b458b74e2b293e301d078470a632db12606545de48f51d0'),(4,3,NULL,1,'CAMBIO_ESTADO_PROCESO',NULL,NULL,'2026-10-25 11:05:51','{\"anterior\": \"CREADO\", \"nuevo\": \"INSCRIPCION\"}','6d590d87374c64af6b458b74e2b293e301d078470a632db12606545de48f51d0','45d83e10c560d957266072c5555f3be0f68ae367bfb33ae34024c78e8d20533c'),(5,3,NULL,1,'PUBLICAR_CONVOCATORIA',NULL,NULL,'2026-10-25 11:05:51','{\"nombre\": \"Elección de Jefe de Departamento de Informática 2026-II\", \"fecha_convocatoria\": \"2026-10-15\", \"fecha_limite_inscripcion\": \"2026-11-02T18:00\"}','45d83e10c560d957266072c5555f3be0f68ae367bfb33ae34024c78e8d20533c','8965607fd3fc77b24ffdf4a91d564d02cfeb37764aa9578e6ec218af74fbdece'),(6,3,NULL,NULL,'DEPURAR_PADRON',NULL,NULL,'2026-10-25 11:05:59','{\"habilitados_nuevos\": \"0\", \"inhabilitados_nuevos\": \"0\"}','8965607fd3fc77b24ffdf4a91d564d02cfeb37764aa9578e6ec218af74fbdece','39c3fa85da0a5857c1e334c708d33a20aa39c7c90c07ff181388829c65677a35'),(7,3,NULL,1,'GENERAR_PADRON',NULL,NULL,'2026-10-25 11:06:04','{\"registros\": \"17\"}','39c3fa85da0a5857c1e334c708d33a20aa39c7c90c07ff181388829c65677a35','489a5a761b1c4a7e3322d7792a7912f5de11d57b6842f6e6c279818eac8c484d'),(8,3,NULL,1,'GENERAR_PADRON',NULL,NULL,'2026-10-25 11:06:30','{\"registros\": \"17\"}','489a5a761b1c4a7e3322d7792a7912f5de11d57b6842f6e6c279818eac8c484d','3215ee37af704ffe2c493c2dbddb68630e171cc3f8f77291453077283bd09935'),(9,3,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 11:35:53',NULL,'3215ee37af704ffe2c493c2dbddb68630e171cc3f8f77291453077283bd09935','c6fd40a100c51613cf3ffd1705b708123088cf985464bb70164729dfaa8eaf6e'),(10,3,NULL,1,'GENERAR_PADRON',NULL,NULL,'2026-11-25 11:36:07','{\"registros\": \"17\"}','c6fd40a100c51613cf3ffd1705b708123088cf985464bb70164729dfaa8eaf6e','c4219aa2f3330a71ca8d7c6fb8796a1e27065d381f5660a9e1dac2d939786058'),(11,3,NULL,1,'INSCRIBIR_LISTA',NULL,NULL,'2026-10-20 11:41:51','{\"id_lista\": \"1\", \"nombre\": \"A\"}','c4219aa2f3330a71ca8d7c6fb8796a1e27065d381f5660a9e1dac2d939786058','068d6d7561f98b12edfd08e106ec9a3b74decdbf76eefc3456413dc58c1afcd7'),(12,3,102,1,'INSCRIBIR_CANDIDATO',NULL,NULL,'2026-10-20 11:42:12','{\"id_lista\": \"1\", \"rol\": \"JEFE_DEPARTAMENTO\"}','068d6d7561f98b12edfd08e106ec9a3b74decdbf76eefc3456413dc58c1afcd7','7a95c338027b5b2842c8ddff0e91acd7f325079e3b36e3ebe52fb08cb321663b'),(13,3,NULL,1,'INSCRIBIR_LISTA',NULL,NULL,'2026-10-20 11:42:23','{\"id_lista\": \"2\", \"nombre\": \"B\"}','7a95c338027b5b2842c8ddff0e91acd7f325079e3b36e3ebe52fb08cb321663b','a88fd95e37a6a985b7c2bce256e13e979259b25d0ce7855b473787e542987953'),(14,3,106,1,'INSCRIBIR_CANDIDATO',NULL,NULL,'2026-10-20 11:42:32','{\"id_lista\": \"2\", \"rol\": \"JEFE_DEPARTAMENTO\"}','a88fd95e37a6a985b7c2bce256e13e979259b25d0ce7855b473787e542987953','24da9963cb7043acbe3580fc0c20a85788cdf8696d52449671e70be3ee62ec30'),(15,3,NULL,1,'CREAR_MESAS',NULL,NULL,'2026-10-20 11:43:22','{\"mesas\": \"1\", \"electores\": \"17\"}','24da9963cb7043acbe3580fc0c20a85788cdf8696d52449671e70be3ee62ec30','f0aa8422790c44552c48c6641143125c2edf42fc1f3957df6314ac12d64aec80'),(16,3,NULL,1,'SORTEO_MESA',NULL,NULL,'2026-10-20 11:43:47','{\"id_mesa\": \"1\", \"semilla\": \"48a066c39b3e7b4d1b685215150aa5bc41254ea451f2e33d766439b89c90a515\", \"algoritmo\": \"ORDER BY SHA256(semilla|dni)\"}','f0aa8422790c44552c48c6641143125c2edf42fc1f3957df6314ac12d64aec80','d4c21bc54b866576614b743456edf936d77d419701c69b688fadc2db08fb89d3'),(17,3,NULL,1,'SORTEO_GENERAL_MESAS',NULL,NULL,'2026-10-20 11:43:47','{\"semilla_base\": \"cf4dc9d54d60b74a8a00024b37518e0c60e9574f455f55f453dc0a5af617cd06\"}','d4c21bc54b866576614b743456edf936d77d419701c69b688fadc2db08fb89d3','0410d781d6d1cdeceecd1bba9551e191f15aedfb0ec0964db372280a6552fd89'),(18,3,NULL,1,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-20 11:44:30','{\"id_credencial\": \"1\", \"tipo\": \"ELECTOR\", \"id_docente\": \"101\", \"id_mesa\": \"1\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','0410d781d6d1cdeceecd1bba9551e191f15aedfb0ec0964db372280a6552fd89','66a125ffccf0075bb4a4974b5d5720dbf586e7f6f778b2b1793e66d093bd04a9'),(19,3,NULL,1,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-20 11:44:30','{\"id_credencial\": \"2\", \"tipo\": \"ELECTOR\", \"id_docente\": \"102\", \"id_mesa\": \"1\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','66a125ffccf0075bb4a4974b5d5720dbf586e7f6f778b2b1793e66d093bd04a9','d02c60a10d4027c3c0ae82a02d454362daef7c607b658caa0a7b5a68fdd8b83b'),(20,3,NULL,1,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-20 11:44:30','{\"id_credencial\": \"3\", \"tipo\": \"ELECTOR\", \"id_docente\": \"103\", \"id_mesa\": \"1\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','d02c60a10d4027c3c0ae82a02d454362daef7c607b658caa0a7b5a68fdd8b83b','307f710626c1a01c11d02baba46d1ed7f72a7f49c00b99d902769036865b8c30'),(21,3,NULL,1,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-20 11:44:30','{\"id_credencial\": \"4\", \"tipo\": \"ELECTOR\", \"id_docente\": \"104\", \"id_mesa\": \"1\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','307f710626c1a01c11d02baba46d1ed7f72a7f49c00b99d902769036865b8c30','193a6677ff5b168732fd333efa498d575026fc8b08340656b7b7e6b9200f0159'),(22,3,NULL,1,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-20 11:44:30','{\"id_credencial\": \"5\", \"tipo\": \"ELECTOR\", \"id_docente\": \"105\", \"id_mesa\": \"1\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','193a6677ff5b168732fd333efa498d575026fc8b08340656b7b7e6b9200f0159','ad0dcea570e0c26e562b2deaf01a96ec1d36ea9f9847512db3e3e7c0035a888d'),(23,3,NULL,1,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-20 11:44:30','{\"id_credencial\": \"6\", \"tipo\": \"ELECTOR\", \"id_docente\": \"106\", \"id_mesa\": \"1\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','ad0dcea570e0c26e562b2deaf01a96ec1d36ea9f9847512db3e3e7c0035a888d','d726a07824c3f40d3db27954d7b223088f706a07565aaaef6eb15be7f4e15a33'),(24,3,NULL,1,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-20 11:44:30','{\"id_credencial\": \"7\", \"tipo\": \"ELECTOR\", \"id_docente\": \"107\", \"id_mesa\": \"1\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','d726a07824c3f40d3db27954d7b223088f706a07565aaaef6eb15be7f4e15a33','6738cf56f6d1222a55211955df5f3fa7a3cd2ca9bb9a19fbf348c881757c339b'),(25,3,NULL,1,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-20 11:44:30','{\"id_credencial\": \"8\", \"tipo\": \"ELECTOR\", \"id_docente\": \"108\", \"id_mesa\": \"1\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','6738cf56f6d1222a55211955df5f3fa7a3cd2ca9bb9a19fbf348c881757c339b','bbdf6ab46bccb39c4cc10f32bd5b8f8c66b7f101832d573dee7d6725c3e96c3c'),(26,3,NULL,1,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-20 11:44:30','{\"id_credencial\": \"9\", \"tipo\": \"ELECTOR\", \"id_docente\": \"109\", \"id_mesa\": \"1\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','bbdf6ab46bccb39c4cc10f32bd5b8f8c66b7f101832d573dee7d6725c3e96c3c','b3077aa7f146dfc73cb8c42a3323cf854db309df441b567a1f8e2d4e1899cf91'),(27,3,NULL,1,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-20 11:44:30','{\"id_credencial\": \"10\", \"tipo\": \"ELECTOR\", \"id_docente\": \"110\", \"id_mesa\": \"1\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','b3077aa7f146dfc73cb8c42a3323cf854db309df441b567a1f8e2d4e1899cf91','76ba6e84018ba3cf5cf415347beeb1b3661189f0ec045fe027be51893b75b593'),(28,3,NULL,1,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-20 11:44:30','{\"id_credencial\": \"11\", \"tipo\": \"ELECTOR\", \"id_docente\": \"111\", \"id_mesa\": \"1\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','76ba6e84018ba3cf5cf415347beeb1b3661189f0ec045fe027be51893b75b593','10e26d6c5097a89c54daa2d618dace0ff9e394896d2af181e0f7bd4ebb20b621'),(29,3,NULL,1,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-20 11:44:30','{\"id_credencial\": \"12\", \"tipo\": \"ELECTOR\", \"id_docente\": \"112\", \"id_mesa\": \"1\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','10e26d6c5097a89c54daa2d618dace0ff9e394896d2af181e0f7bd4ebb20b621','d4ce4a8d4d909401958cc3c237ec5815dfd3ba2593c707bb720839ba1d65693f'),(30,3,NULL,1,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-20 11:44:30','{\"id_credencial\": \"13\", \"tipo\": \"ELECTOR\", \"id_docente\": \"113\", \"id_mesa\": \"1\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','d4ce4a8d4d909401958cc3c237ec5815dfd3ba2593c707bb720839ba1d65693f','ffabd1ef6d4f4e609a1ef30f52b2e71794a6fa0f25e6011b2a8d69b447aa21a9'),(31,3,NULL,1,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-20 11:44:30','{\"id_credencial\": \"14\", \"tipo\": \"ELECTOR\", \"id_docente\": \"114\", \"id_mesa\": \"1\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','ffabd1ef6d4f4e609a1ef30f52b2e71794a6fa0f25e6011b2a8d69b447aa21a9','d6154f973512871e5f7d7a3ebe7eed3398c636b21a091e8dd71ba35b527c1133'),(32,3,NULL,1,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-20 11:44:30','{\"id_credencial\": \"15\", \"tipo\": \"ELECTOR\", \"id_docente\": \"115\", \"id_mesa\": \"1\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','d6154f973512871e5f7d7a3ebe7eed3398c636b21a091e8dd71ba35b527c1133','d432680ba27b01af0251caffc162fc9590cb30669374a0672251b01246c0a5ec'),(33,3,NULL,1,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-20 11:44:30','{\"id_credencial\": \"16\", \"tipo\": \"ELECTOR\", \"id_docente\": \"116\", \"id_mesa\": \"1\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','d432680ba27b01af0251caffc162fc9590cb30669374a0672251b01246c0a5ec','932177218fa322288beee7cd70ef27cee05d56f96e033a6391f06164d7a7a407'),(34,3,NULL,1,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-20 11:44:30','{\"id_credencial\": \"17\", \"tipo\": \"ELECTOR\", \"id_docente\": \"117\", \"id_mesa\": \"1\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','932177218fa322288beee7cd70ef27cee05d56f96e033a6391f06164d7a7a407','bd8c023eef820dcfa071a44a121c41353ee7145132998ff3072c497415f889f7'),(35,3,NULL,1,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-20 11:44:57','{\"id_credencial\": \"18\", \"tipo\": \"MIEMBRO_MESA\", \"id_docente\": \"107\", \"id_mesa\": \"1\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','bd8c023eef820dcfa071a44a121c41353ee7145132998ff3072c497415f889f7','44be31e0ed7e885e2ca0570a02506e3ebab0c4d9edc4139bd3e27c9206ea33e7'),(36,3,NULL,1,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-20 11:44:57','{\"id_credencial\": \"19\", \"tipo\": \"MIEMBRO_MESA\", \"id_docente\": \"108\", \"id_mesa\": \"1\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','44be31e0ed7e885e2ca0570a02506e3ebab0c4d9edc4139bd3e27c9206ea33e7','fade4bbcfbb9d75a590e15a54454a2b1bab4ead9e2ba7cff898992b06a4653fe'),(37,3,NULL,1,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-20 11:44:57','{\"id_credencial\": \"20\", \"tipo\": \"MIEMBRO_MESA\", \"id_docente\": \"111\", \"id_mesa\": \"1\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','fade4bbcfbb9d75a590e15a54454a2b1bab4ead9e2ba7cff898992b06a4653fe','18301638832dd1903e2149adfacb6a0754771839d77dd9e13e77717aa5c12cbe'),(38,3,NULL,1,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-20 11:44:57','{\"id_credencial\": \"21\", \"tipo\": \"MIEMBRO_MESA\", \"id_docente\": \"117\", \"id_mesa\": \"1\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','18301638832dd1903e2149adfacb6a0754771839d77dd9e13e77717aa5c12cbe','9a139fdb0fea845c6156ead384d1d880523dccf5473d572409566f7fa5553984'),(39,3,NULL,1,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-20 11:44:57','{\"id_credencial\": \"22\", \"tipo\": \"MIEMBRO_MESA\", \"id_docente\": \"115\", \"id_mesa\": \"1\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','9a139fdb0fea845c6156ead384d1d880523dccf5473d572409566f7fa5553984','1a316bb261eec57558aae4e7c0edd131cebb01ce28b07363e82981fe637fe7a4'),(40,3,NULL,1,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-20 11:44:57','{\"id_credencial\": \"23\", \"tipo\": \"MIEMBRO_MESA\", \"id_docente\": \"101\", \"id_mesa\": \"1\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','1a316bb261eec57558aae4e7c0edd131cebb01ce28b07363e82981fe637fe7a4','5d049aa826385ff4e5c059deacebc3dc034a599343cee70cf71bcd1dc3019c60'),(41,3,NULL,1,'VALIDAR_LISTA',NULL,NULL,'2026-11-03 11:47:12','{\"id_lista\": \"1\", \"admitida\": \"SI\", \"motivo\": \"\"}','5d049aa826385ff4e5c059deacebc3dc034a599343cee70cf71bcd1dc3019c60','5f420ce68c7292be4b8b1135366bd63abe0feda1cffb4bc227160eb309d47a20'),(42,3,NULL,1,'VALIDAR_LISTA',NULL,NULL,'2026-11-03 11:47:15','{\"id_lista\": \"2\", \"admitida\": \"SI\", \"motivo\": \"\"}','5f420ce68c7292be4b8b1135366bd63abe0feda1cffb4bc227160eb309d47a20','eaa20462173045783e98913fefd0991a0ed186e96d80f79ef05123b337e46145'),(43,3,NULL,1,'SORTEO_ORDEN_CEDULA',NULL,NULL,'2026-11-25 09:02:10','{\"id_cargo\": \"1\", \"semilla\": \"d6fced70012392f7d041e788083a34d4ec7f73344c84dd0b5055685af643707c\"}','eaa20462173045783e98913fefd0991a0ed186e96d80f79ef05123b337e46145','11b6a2958b0ac6f5c3e68ffb0ac2ee898c95b699f8c708833182e2c2dbacddaa'),(44,3,NULL,1,'CAMBIO_ESTADO_PROCESO',NULL,NULL,'2026-11-25 09:02:22','{\"anterior\": \"INSCRIPCION\", \"nuevo\": \"VOTACION\"}','11b6a2958b0ac6f5c3e68ffb0ac2ee898c95b699f8c708833182e2c2dbacddaa','3dc3fa2323982d25d3801cef265a20249369c35b39c76fb0380a71037a70439f'),(45,3,NULL,1,'REGISTRAR_LLEGADA_MIEMBRO',NULL,NULL,'2026-11-25 09:02:51','{\"id_mesa\": \"1\", \"id_docente\": \"107\", \"presente\": \"true\", \"metodo\": \"DNI\"}','3dc3fa2323982d25d3801cef265a20249369c35b39c76fb0380a71037a70439f','ca446dd6ddfb62739f49934b0d601fb5f1b94b9f14e6b9c8f9479048ec97c97b'),(46,3,NULL,1,'REGISTRAR_LLEGADA_MIEMBRO',NULL,NULL,'2026-11-25 09:03:00','{\"id_mesa\": \"1\", \"id_docente\": \"108\", \"presente\": \"true\", \"metodo\": \"DNI\"}','ca446dd6ddfb62739f49934b0d601fb5f1b94b9f14e6b9c8f9479048ec97c97b','fdca89f911dbb493839c9f519b78b4142ee294a182de00069655ee909f948f4d'),(47,3,NULL,1,'REGISTRAR_LLEGADA_MIEMBRO',NULL,NULL,'2026-11-25 09:03:07','{\"id_mesa\": \"1\", \"id_docente\": \"111\", \"presente\": \"true\", \"metodo\": \"DNI\"}','fdca89f911dbb493839c9f519b78b4142ee294a182de00069655ee909f948f4d','84908cd0309c054200e13beda87eb2114c719b8bec082a6e7fe600399f021cd4'),(48,3,NULL,1,'REGISTRAR_LLEGADA_MIEMBRO',NULL,NULL,'2026-11-25 09:03:13','{\"id_mesa\": \"1\", \"id_docente\": \"117\", \"presente\": \"true\", \"metodo\": \"DNI\"}','84908cd0309c054200e13beda87eb2114c719b8bec082a6e7fe600399f021cd4','b7b8db61bbd1858680e3bcff88ade8eaf0fb7dad186f9a812c8786af0777e074'),(49,3,NULL,1,'REGISTRAR_LLEGADA_MIEMBRO',NULL,NULL,'2026-11-25 09:03:19','{\"id_mesa\": \"1\", \"id_docente\": \"115\", \"presente\": \"true\", \"metodo\": \"DNI\"}','b7b8db61bbd1858680e3bcff88ade8eaf0fb7dad186f9a812c8786af0777e074','cc13cdb0207b2890254e10bc3e243a3b4ec8dfeaf0de4283b10b7ddd2148b782'),(50,3,NULL,1,'REGISTRAR_LLEGADA_MIEMBRO',NULL,NULL,'2026-11-25 09:03:23','{\"id_mesa\": \"1\", \"id_docente\": \"101\", \"presente\": \"true\", \"metodo\": \"DNI\"}','cc13cdb0207b2890254e10bc3e243a3b4ec8dfeaf0de4283b10b7ddd2148b782','30075afc3d64c74ed5cc97ca42781a1684fc92c79f615bd39286923a42081059'),(51,3,NULL,1,'VERIFICAR_MATERIAL_MESA',NULL,NULL,'2026-11-25 09:13:05','{\"id_mesa\": \"1\", \"completo\": \"false\", \"faltantes\": \"ACTAS\", \"observados\": \"\", \"cedulas\": \"17\"}','30075afc3d64c74ed5cc97ca42781a1684fc92c79f615bd39286923a42081059','7e9dcb261c1301e43b553b300dece3dc6a917c455b8faffc04f8f082bfe324b4'),(52,3,NULL,1,'VERIFICAR_MATERIAL_MESA',NULL,NULL,'2026-11-25 09:13:33','{\"id_mesa\": \"1\", \"completo\": \"true\", \"faltantes\": \"\", \"observados\": \"\", \"cedulas\": \"17\"}','7e9dcb261c1301e43b553b300dece3dc6a917c455b8faffc04f8f082bfe324b4','c4f5850cd051afd5a58cb8d1a3007db0ae372e986c264ef117213dc9d0bf0ded'),(53,3,NULL,1,'INSTALAR_MESA',NULL,NULL,'2026-11-25 09:15:57','{\"id_mesa\": \"1\", \"id_acta\": \"1\"}','c4f5850cd051afd5a58cb8d1a3007db0ae372e986c264ef117213dc9d0bf0ded','7cbfc106fd300f97952a5c8dda0d7c7b1707e386bcbaaba49ebc896b5817b8b1'),(54,1,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 09:22:15',NULL,'7cbfc106fd300f97952a5c8dda0d7c7b1707e386bcbaaba49ebc896b5817b8b1','110435bd77c80215ef5a2084b0c1b219d0585f91b71052cc4d101b6749d35e86'),(55,3,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 09:23:49',NULL,'110435bd77c80215ef5a2084b0c1b219d0585f91b71052cc4d101b6749d35e86','321fe0cab8e124d8240bc234a0df8ae8151900668b71b492dec25e9fff995e5d'),(56,1,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 09:24:36',NULL,'321fe0cab8e124d8240bc234a0df8ae8151900668b71b492dec25e9fff995e5d','cd91c6712962d2524cf6012e5871514588513e1dda24e425e320f4353d0da6ba'),(57,111,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 09:30:11',NULL,'cd91c6712962d2524cf6012e5871514588513e1dda24e425e320f4353d0da6ba','dcc70274d8e58a03acba40deae7d18a252221f13046761c75789c0ed409b198d'),(58,111,NULL,1,'CONECTAR_TERMINAL',NULL,NULL,'2026-11-25 09:30:34','{\"id_terminal\": \"1\", \"id_mesa\": \"1\"}','dcc70274d8e58a03acba40deae7d18a252221f13046761c75789c0ed409b198d','3fd525d87f71e8f09cdaadf9efcbd11a51ad1b8abfa4911c1d8a806babb4beeb'),(59,111,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 09:32:26',NULL,'3fd525d87f71e8f09cdaadf9efcbd11a51ad1b8abfa4911c1d8a806babb4beeb','c3d7fdb3371237bb3add130a2fc0595e1774dca5c42078738b7c1f08916811ce'),(60,111,NULL,NULL,'LOGIN_FAILED','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 09:32:57',NULL,'c3d7fdb3371237bb3add130a2fc0595e1774dca5c42078738b7c1f08916811ce','5ac8f61582df7fb689460324abab16bffb894648f9022d7b63f667201d170ec8'),(61,111,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 09:33:06',NULL,'5ac8f61582df7fb689460324abab16bffb894648f9022d7b63f667201d170ec8','c33ecbd835fee862cc10ca33c6e97528d0bb06ce59a6adcd22b53836473bdccb'),(62,1,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 09:34:20',NULL,'c33ecbd835fee862cc10ca33c6e97528d0bb06ce59a6adcd22b53836473bdccb','ced11adb81c8ecb58ee835407b58a96882cf9c75ff446b841a7f818a2c6d7cca'),(63,118,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 09:36:23',NULL,'ced11adb81c8ecb58ee835407b58a96882cf9c75ff446b841a7f818a2c6d7cca','0311d4ac794dc8ddc76024af15a657c92a020283f27178c6c823aa8131650064'),(64,118,NULL,1,'VERIFICAR_CREDENCIAL',NULL,NULL,'2026-11-25 09:36:48','{\"resultado\": \"VALIDA\", \"id_credencial\": \"8\"}','0311d4ac794dc8ddc76024af15a657c92a020283f27178c6c823aa8131650064','7f09bd2ed4bd1b1b754cdd388d2b3b3b71bc909e09cbcbe05a3feb3d85a003fc'),(65,118,NULL,1,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 09:36:49','{\"id_mesa\": \"1\", \"metodo\": \"QR\", \"resultado\": \"APTO\", \"id_docente\": \"108\"}','7f09bd2ed4bd1b1b754cdd388d2b3b3b71bc909e09cbcbe05a3feb3d85a003fc','5180d4bd917a0ef7784a7c61b8a574b97327cb1f9cd9a69e79e2167d0d41974c'),(66,118,NULL,1,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 09:37:20','{\"id_mesa\": \"1\", \"id_docente\": \"108\", \"metodo\": \"QR\", \"id_terminal\": \"1\", \"id_habilitacion\": \"1\"}','5180d4bd917a0ef7784a7c61b8a574b97327cb1f9cd9a69e79e2167d0d41974c','142ffe8f2b30e867dd7e80d0cb21b2d04d0b19d98ff25a6d6dc3760dcb8cf95e'),(67,NULL,108,1,'EMITIR_VOTO',NULL,NULL,'2026-11-25 09:44:02','{\"id_cargo\": \"1\"}','142ffe8f2b30e867dd7e80d0cb21b2d04d0b19d98ff25a6d6dc3760dcb8cf95e','9e26fc1200b10083101e7b4471d9f1878ccf94ebdc0f569ac5c8fd720ffd2a66'),(68,118,NULL,1,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 09:59:01','{\"id_mesa\": \"1\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"101\"}','9e26fc1200b10083101e7b4471d9f1878ccf94ebdc0f569ac5c8fd720ffd2a66','88bbfa55c9691eb7e3a50fd09157f332cb0e4b4ac576d8abcc007e76cd77be59'),(69,118,NULL,1,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 09:59:07','{\"id_mesa\": \"1\", \"id_docente\": \"101\", \"metodo\": \"DNI\", \"id_terminal\": \"1\", \"id_habilitacion\": \"2\"}','88bbfa55c9691eb7e3a50fd09157f332cb0e4b4ac576d8abcc007e76cd77be59','8ffeb5e5dd110caf85234509f9f663e7667b4b248aa0dd1c068a0095460355c8'),(70,111,NULL,1,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 09:59:13','{\"id_terminal\": \"1\", \"id_mesa\": \"1\"}','8ffeb5e5dd110caf85234509f9f663e7667b4b248aa0dd1c068a0095460355c8','e54b35bdbf88b54082766ea83c54ce9e9b4b25505b9197de028f84805ea4b278'),(71,118,NULL,1,'INCIDENCIA_MESA',NULL,NULL,'2026-11-25 09:59:48','{\"id_mesa\": \"1\", \"id_docente\": \"101\", \"tipo\": \"ABANDONO_TERMINAL\"}','e54b35bdbf88b54082766ea83c54ce9e9b4b25505b9197de028f84805ea4b278','e57c1716aaec79380dd71a06d35ca1e12ae715957f3d10375a733ec28a6cddeb'),(72,118,NULL,1,'INCIDENCIA_MESA',NULL,NULL,'2026-11-25 10:00:28','{\"id_mesa\": \"1\", \"id_docente\": \"101\", \"tipo\": \"YA_REGISTRADO\"}','e57c1716aaec79380dd71a06d35ca1e12ae715957f3d10375a733ec28a6cddeb','92f1252a6b3ff9dcad8ed2442a2443f742fbeaf61df91149e2bd7825d3c95577'),(73,118,NULL,1,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 10:00:28','{\"id_mesa\": \"1\", \"metodo\": \"DNI\", \"resultado\": \"YA_REGISTRADO\", \"id_docente\": \"101\"}','92f1252a6b3ff9dcad8ed2442a2443f742fbeaf61df91149e2bd7825d3c95577','96e53c2f473d06c9747b2f61b3b6a194dc034a6eb7c6a15332c8c96f66da7866'),(74,118,NULL,NULL,'VERIFICAR_CREDENCIAL',NULL,NULL,'2026-11-25 10:00:30','{\"resultado\": \"FORMATO_INVALIDO\", \"id_credencial\": null}','96e53c2f473d06c9747b2f61b3b6a194dc034a6eb7c6a15332c8c96f66da7866','ff47547512fd625eb5a4100f5166aeaf6c091f501926dda209be60fdce2fb0cb'),(75,118,NULL,1,'INCIDENCIA_MESA',NULL,NULL,'2026-11-25 10:00:30','{\"id_mesa\": \"1\", \"id_docente\": null, \"tipo\": \"QR_INVALIDO\"}','ff47547512fd625eb5a4100f5166aeaf6c091f501926dda209be60fdce2fb0cb','a01886801fb485cd9ecd4b6fa4faf0bd11d101261b2843f6e9bebdd027ed7510'),(76,118,NULL,1,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 10:00:30','{\"id_mesa\": \"1\", \"metodo\": \"QR\", \"resultado\": \"QR_INVALIDO\"}','a01886801fb485cd9ecd4b6fa4faf0bd11d101261b2843f6e9bebdd027ed7510','33b8634cd83ced65728a1488bc644200352bce8fb0bd3b04ad896719348b454f'),(77,118,NULL,1,'INCIDENCIA_MESA',NULL,NULL,'2026-11-25 10:00:35','{\"id_mesa\": \"1\", \"id_docente\": \"101\", \"tipo\": \"YA_REGISTRADO\"}','33b8634cd83ced65728a1488bc644200352bce8fb0bd3b04ad896719348b454f','90f56ff8178dc75ada8534e802822b7a4314782937dc82f962e888c13c448d2f'),(78,118,NULL,1,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 10:00:35','{\"id_mesa\": \"1\", \"metodo\": \"DNI\", \"resultado\": \"YA_REGISTRADO\", \"id_docente\": \"101\"}','90f56ff8178dc75ada8534e802822b7a4314782937dc82f962e888c13c448d2f','5867a4ee098f57a8c716c5c5adc2f36e336aae45010db0fe9ed5dc8a8a461942'),(79,118,NULL,NULL,'VERIFICAR_CREDENCIAL',NULL,NULL,'2026-11-25 10:00:39','{\"resultado\": \"FORMATO_INVALIDO\", \"id_credencial\": null}','5867a4ee098f57a8c716c5c5adc2f36e336aae45010db0fe9ed5dc8a8a461942','feb311519958f610847c14e47d2052d29b6539609f050e7aec6cd0a0491375f9'),(80,118,NULL,1,'INCIDENCIA_MESA',NULL,NULL,'2026-11-25 10:00:39','{\"id_mesa\": \"1\", \"id_docente\": null, \"tipo\": \"QR_INVALIDO\"}','feb311519958f610847c14e47d2052d29b6539609f050e7aec6cd0a0491375f9','2abc39ba5771634a1d9caadadebbeab8ce1041bd734fa33bfda85f073dc2ac09'),(81,118,NULL,1,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 10:00:39','{\"id_mesa\": \"1\", \"metodo\": \"QR\", \"resultado\": \"QR_INVALIDO\"}','2abc39ba5771634a1d9caadadebbeab8ce1041bd734fa33bfda85f073dc2ac09','e74de427160dc3cb042ea50a27c7262e00c573f72f6e05bff0925bb226b83634'),(82,118,NULL,1,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 10:02:04','{\"id_mesa\": \"1\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"105\"}','e74de427160dc3cb042ea50a27c7262e00c573f72f6e05bff0925bb226b83634','ffdaeed1dc6b62cd101733a4026ea0348e9a835027ddf091f423a18cdecd5cb8'),(83,118,NULL,1,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 10:02:06','{\"id_mesa\": \"1\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"102\"}','ffdaeed1dc6b62cd101733a4026ea0348e9a835027ddf091f423a18cdecd5cb8','2f41067454765747866adc43d6c8eb6afd89bee7350944a6df3aff5d8f334c83'),(84,118,NULL,1,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 10:02:08','{\"id_mesa\": \"1\", \"id_docente\": \"102\", \"metodo\": \"DNI\", \"id_terminal\": \"1\", \"id_habilitacion\": \"3\"}','2f41067454765747866adc43d6c8eb6afd89bee7350944a6df3aff5d8f334c83','485d4ede1fe68c658ee2476be351caeca9098fcb7dfa4e13302d15103d4f6258'),(85,NULL,102,1,'EMITIR_VOTO',NULL,NULL,'2026-11-25 10:02:24','{\"id_cargo\": \"1\"}','485d4ede1fe68c658ee2476be351caeca9098fcb7dfa4e13302d15103d4f6258','ca2d3248838e1abbaae7f83fb204cce6c07683f6de0127d9a6ce4bc8bf0eaf47'),(86,120,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 10:04:01',NULL,'ca2d3248838e1abbaae7f83fb204cce6c07683f6de0127d9a6ce4bc8bf0eaf47','9077f24f926ee0a3e345fbcc3cf49f501f863e1327bbc5eb4cfc188fddd5404a'),(87,120,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 10:10:00',NULL,'9077f24f926ee0a3e345fbcc3cf49f501f863e1327bbc5eb4cfc188fddd5404a','cad0713fd657a263918e6d04ec834eca33354717bc9f95dcc8f5346806996561'),(88,120,NULL,1,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 10:10:10','{\"id_mesa\": \"1\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"103\"}','cad0713fd657a263918e6d04ec834eca33354717bc9f95dcc8f5346806996561','be4828ba2dea79760365a3aa8939cfb9c4933ef4545a41b150321036a4f60097'),(89,120,NULL,1,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 10:10:14','{\"id_mesa\": \"1\", \"id_docente\": \"103\", \"metodo\": \"DNI\", \"id_terminal\": \"1\", \"id_habilitacion\": \"4\"}','be4828ba2dea79760365a3aa8939cfb9c4933ef4545a41b150321036a4f60097','f478bb82123d6fead655abb93abc200597405b516343449cdc1c1e3c2cc206cc'),(90,NULL,103,1,'EMITIR_VOTO',NULL,NULL,'2026-11-25 10:10:30','{\"id_cargo\": \"1\"}','f478bb82123d6fead655abb93abc200597405b516343449cdc1c1e3c2cc206cc','a95b7117902c73eaebd064aa7525b4a96ce9cadbd8621f30aeb976740a088ea7'),(91,111,NULL,1,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 10:10:30','{\"id_mesa\": \"1\", \"id_terminal\": \"1\"}','a95b7117902c73eaebd064aa7525b4a96ce9cadbd8621f30aeb976740a088ea7','6cdbf246d9f088c41df270cfddbfc675bd729ef1ff4e50915279a2e66e50ee7b'),(92,120,NULL,1,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 10:10:44','{\"id_mesa\": \"1\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"104\"}','6cdbf246d9f088c41df270cfddbfc675bd729ef1ff4e50915279a2e66e50ee7b','fbd49c1c94b2abe33f5b5cbdfe6de2ab4fb1cba7a47821d9962cdc0f2a640789'),(93,120,NULL,1,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 10:10:47','{\"id_mesa\": \"1\", \"id_docente\": \"104\", \"metodo\": \"DNI\", \"id_terminal\": \"1\", \"id_habilitacion\": \"5\"}','fbd49c1c94b2abe33f5b5cbdfe6de2ab4fb1cba7a47821d9962cdc0f2a640789','a20eaaea893447ff936851942cc3d2b98453e962e6c7a8d7edc76736b4a057aa'),(94,NULL,104,1,'EMITIR_VOTO',NULL,NULL,'2026-11-25 10:10:58','{\"id_cargo\": \"1\"}','a20eaaea893447ff936851942cc3d2b98453e962e6c7a8d7edc76736b4a057aa','8a9283050224b3e73da1575f91130246539ecc42472b3ffb11f7987771a07bc6'),(95,111,NULL,1,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 10:10:58','{\"id_mesa\": \"1\", \"id_terminal\": \"1\"}','8a9283050224b3e73da1575f91130246539ecc42472b3ffb11f7987771a07bc6','371e02bfdb67463d89493bde3e0291208e3021b6bd2577a9f5a2d3b8bb43b85a'),(96,120,NULL,1,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 10:11:16','{\"id_mesa\": \"1\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"105\"}','371e02bfdb67463d89493bde3e0291208e3021b6bd2577a9f5a2d3b8bb43b85a','62369dc2c0b3dba671b142bc01c447109dadf929f61042a589be472284352099'),(97,120,NULL,1,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 10:11:19','{\"id_mesa\": \"1\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"105\"}','62369dc2c0b3dba671b142bc01c447109dadf929f61042a589be472284352099','cb997779c7b03a3adcd2037a796e7ecced2710a9a4e70c80644c09784dd4ab1e'),(98,120,NULL,1,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 10:11:24','{\"id_mesa\": \"1\", \"id_docente\": \"105\", \"metodo\": \"DNI\", \"id_terminal\": \"1\", \"id_habilitacion\": \"6\"}','cb997779c7b03a3adcd2037a796e7ecced2710a9a4e70c80644c09784dd4ab1e','140344784f98ff85e322a1c27445da46cb7c84eb0d42529b9f863ef9c36e209d'),(99,NULL,105,1,'EMITIR_VOTO',NULL,NULL,'2026-11-25 10:11:31','{\"id_cargo\": \"1\"}','140344784f98ff85e322a1c27445da46cb7c84eb0d42529b9f863ef9c36e209d','042770cfb2333f1f884992daecbac68f9f50e22cff2d990a55ee7370c2b1ba32'),(100,111,NULL,1,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 10:11:31','{\"id_mesa\": \"1\", \"id_terminal\": \"1\"}','042770cfb2333f1f884992daecbac68f9f50e22cff2d990a55ee7370c2b1ba32','4aa92252a279de66bcf8fd26f69de9901d037792c003a42fe8440d79a1c66652'),(101,120,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 10:14:10',NULL,'4aa92252a279de66bcf8fd26f69de9901d037792c003a42fe8440d79a1c66652','8d985828c42ffa488f7826372f4f6bc58f87865a0e8ba2b231474ce5b4940477'),(102,111,NULL,NULL,'LOGIN_FAILED','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 10:14:41',NULL,'8d985828c42ffa488f7826372f4f6bc58f87865a0e8ba2b231474ce5b4940477','0cec27ac4f9deb71b9fa7dab660f5a3069994c172a5269a5c540f831fbe4b97a'),(103,111,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 10:14:45',NULL,'0cec27ac4f9deb71b9fa7dab660f5a3069994c172a5269a5c540f831fbe4b97a','c9964a6340ce25767b00eb07753eec42138f342a4eb3d55943b0826790c00ecb'),(104,120,NULL,1,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 10:18:33','{\"id_mesa\": \"1\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"106\"}','c9964a6340ce25767b00eb07753eec42138f342a4eb3d55943b0826790c00ecb','9d4c085af8ce38d126307ad39c0362d599b784e38f08c3579c54282866a4929e'),(105,120,NULL,1,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 10:18:37','{\"id_mesa\": \"1\", \"id_docente\": \"106\", \"metodo\": \"DNI\", \"id_terminal\": \"1\", \"id_habilitacion\": \"7\"}','9d4c085af8ce38d126307ad39c0362d599b784e38f08c3579c54282866a4929e','bf224f584b597a75bf946885ae24e275a639da2b85e0aec728abfb7175b2945a'),(106,NULL,106,1,'EMITIR_VOTO',NULL,NULL,'2026-11-25 10:18:43','{\"id_cargo\": \"1\"}','bf224f584b597a75bf946885ae24e275a639da2b85e0aec728abfb7175b2945a','5915b72344d4b9b917a58f840dc134650d69ea2f49dd4fcd342aec01cc74d942'),(107,111,NULL,1,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 10:18:43','{\"id_mesa\": \"1\", \"id_terminal\": \"1\"}','5915b72344d4b9b917a58f840dc134650d69ea2f49dd4fcd342aec01cc74d942','dbcf709ae822a50ef1a87f85d0f015e3ee31c7a1705b2d8eccd6e69a8c812b8a'),(108,120,NULL,1,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 10:18:54','{\"id_mesa\": \"1\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"107\"}','dbcf709ae822a50ef1a87f85d0f015e3ee31c7a1705b2d8eccd6e69a8c812b8a','09eee64978b4bfef169a5aa87079e9acc88591d4e057248ad232c8b4e7dcfeab'),(109,120,NULL,1,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 10:18:56','{\"id_mesa\": \"1\", \"id_docente\": \"107\", \"metodo\": \"DNI\", \"id_terminal\": \"1\", \"id_habilitacion\": \"8\"}','09eee64978b4bfef169a5aa87079e9acc88591d4e057248ad232c8b4e7dcfeab','24251e68ed4de3cb129cc4f96dcffca53675598d4f24db64f770343a9a316e34'),(110,NULL,107,1,'EMITIR_VOTO',NULL,NULL,'2026-11-25 10:19:03','{\"id_cargo\": \"1\"}','24251e68ed4de3cb129cc4f96dcffca53675598d4f24db64f770343a9a316e34','787b597b5388d57e9705ee9ed6ad3cb89775fd1246e6f0fcddbb6312750ba616'),(111,111,NULL,1,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 10:19:03','{\"id_mesa\": \"1\", \"id_terminal\": \"1\"}','787b597b5388d57e9705ee9ed6ad3cb89775fd1246e6f0fcddbb6312750ba616','f23cf13da120bad6a7824c163d78625167d5a60b84b0080dc87dbf0e5613626f'),(112,120,NULL,1,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 10:19:15','{\"id_mesa\": \"1\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"109\"}','f23cf13da120bad6a7824c163d78625167d5a60b84b0080dc87dbf0e5613626f','2b8b5002a21c2a9d4c2b6d7a2ca0fb0c28173183f14550c8dbc1b55253e70500'),(113,120,NULL,1,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 10:19:18','{\"id_mesa\": \"1\", \"id_docente\": \"109\", \"metodo\": \"DNI\", \"id_terminal\": \"1\", \"id_habilitacion\": \"9\"}','2b8b5002a21c2a9d4c2b6d7a2ca0fb0c28173183f14550c8dbc1b55253e70500','62bc4d201510b93cac0259a50f6567db1c7fd75bfdf71c295f31dfe5d18a5dcc'),(114,NULL,109,1,'EMITIR_VOTO',NULL,NULL,'2026-11-25 10:19:23','{\"id_cargo\": \"1\"}','62bc4d201510b93cac0259a50f6567db1c7fd75bfdf71c295f31dfe5d18a5dcc','ba4c8a8f1f803f720716fe050e6f4c8f084f7842e1e4a5f2eb8dbe605457a8af'),(115,111,NULL,1,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 10:19:24','{\"id_mesa\": \"1\", \"id_terminal\": \"1\"}','ba4c8a8f1f803f720716fe050e6f4c8f084f7842e1e4a5f2eb8dbe605457a8af','066d265007406f8bb4967f176913c9a50f839240be03e523ef9299d139865e4e'),(116,120,NULL,1,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 10:19:55','{\"id_mesa\": \"1\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"110\"}','066d265007406f8bb4967f176913c9a50f839240be03e523ef9299d139865e4e','20448bcf1d4ed2eecacfdd2df1990a92ee85861e4f0c5ab302205b304980e5ae'),(117,120,NULL,1,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 10:19:58','{\"id_mesa\": \"1\", \"id_docente\": \"110\", \"metodo\": \"DNI\", \"id_terminal\": \"1\", \"id_habilitacion\": \"10\"}','20448bcf1d4ed2eecacfdd2df1990a92ee85861e4f0c5ab302205b304980e5ae','2db912e1a9359ebbe24ae704f76952fee3a5dee59bd7c9ac639939aaad1c10da'),(118,NULL,110,1,'EMITIR_VOTO',NULL,NULL,'2026-11-25 10:20:11','{\"id_cargo\": \"1\"}','2db912e1a9359ebbe24ae704f76952fee3a5dee59bd7c9ac639939aaad1c10da','d125dab03eff697480bc9941e82b09d4a123996d94ba5d9e314909ce0c56e76a'),(119,111,NULL,1,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 10:20:11','{\"id_mesa\": \"1\", \"id_terminal\": \"1\"}','d125dab03eff697480bc9941e82b09d4a123996d94ba5d9e314909ce0c56e76a','758635a72cdbe9fadee12fe787f3593f43aa5c204ecd2805feef4c78e36834e0'),(120,111,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 10:21:38',NULL,'758635a72cdbe9fadee12fe787f3593f43aa5c204ecd2805feef4c78e36834e0','006db86659029a2a13705711f8f498eeefe99dd172a4fbee95c2527083409ac0'),(121,1,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 10:22:19',NULL,'006db86659029a2a13705711f8f498eeefe99dd172a4fbee95c2527083409ac0','fee34a938a5f4fd5eaf15a8c80b8ce8274ef08236ff035d2b378c8c9639edd17'),(122,110,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 10:23:16',NULL,'fee34a938a5f4fd5eaf15a8c80b8ce8274ef08236ff035d2b378c8c9639edd17','e2a79c77bc1f28b7c089956cf5dba5d29ec8a2b25ad4c4fbbae8ed59b597df42'),(123,111,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 10:24:58',NULL,'e2a79c77bc1f28b7c089956cf5dba5d29ec8a2b25ad4c4fbbae8ed59b597df42','f54400e85634b3082e5bc2059df3ff8b8c5fa25136412c1985df537e01feb8c2'),(124,111,NULL,1,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 10:26:37','{\"id_mesa\": \"1\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"111\"}','f54400e85634b3082e5bc2059df3ff8b8c5fa25136412c1985df537e01feb8c2','23410215d6ab47e3723b254072119ffc7dbfe99491d59baf114ff74392a32e95'),(125,111,NULL,1,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 10:26:41','{\"id_mesa\": \"1\", \"id_docente\": \"111\", \"metodo\": \"DNI\", \"id_terminal\": \"1\", \"id_habilitacion\": \"11\"}','23410215d6ab47e3723b254072119ffc7dbfe99491d59baf114ff74392a32e95','e90bac9f7d86b5fb99e9b85463fdab52b6c395e8497815810a70e980f2396d5f'),(126,NULL,111,1,'EMITIR_VOTO',NULL,NULL,'2026-11-25 10:26:51','{\"id_cargo\": \"1\"}','e90bac9f7d86b5fb99e9b85463fdab52b6c395e8497815810a70e980f2396d5f','68a5bbddddfbdc802e73dac2f87b0d15e26c69ec1341c5581fc52342d43d732d'),(127,111,NULL,1,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 10:26:51','{\"id_mesa\": \"1\", \"id_terminal\": \"1\"}','68a5bbddddfbdc802e73dac2f87b0d15e26c69ec1341c5581fc52342d43d732d','3efb1b937e97ea121e25d5d64450001ca34c0c65c777f7eb6c8f000259d4043a'),(128,111,NULL,1,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 10:26:56','{\"id_mesa\": \"1\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"112\"}','3efb1b937e97ea121e25d5d64450001ca34c0c65c777f7eb6c8f000259d4043a','9cadceca3b46e0a9d94118b03a78a3a093c2e4d6ee65ece93e47dcb85ad4a9e9'),(129,111,NULL,1,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 10:26:58','{\"id_mesa\": \"1\", \"id_docente\": \"112\", \"metodo\": \"DNI\", \"id_terminal\": \"1\", \"id_habilitacion\": \"12\"}','9cadceca3b46e0a9d94118b03a78a3a093c2e4d6ee65ece93e47dcb85ad4a9e9','a3104983d31bae269edc9197847700a5379bbbfc634cc1376405dcf845695cbc'),(130,NULL,112,1,'EMITIR_VOTO',NULL,NULL,'2026-11-25 10:27:05','{\"id_cargo\": \"1\"}','a3104983d31bae269edc9197847700a5379bbbfc634cc1376405dcf845695cbc','dae0155f540d9ed2201fb7077a42f6d0c5786f468cf0529cccd20ce793262a23'),(131,111,NULL,1,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 10:27:06','{\"id_mesa\": \"1\", \"id_terminal\": \"1\"}','dae0155f540d9ed2201fb7077a42f6d0c5786f468cf0529cccd20ce793262a23','cb04be840cc56134fb9da886c55b3f39b97d166908c8014b56115f0ed8e81259'),(132,111,NULL,1,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 10:27:10','{\"id_mesa\": \"1\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"113\"}','cb04be840cc56134fb9da886c55b3f39b97d166908c8014b56115f0ed8e81259','05421e4b93f9f6551955a35c1747b45daa5d5857db3cf0a80c12932945f1da7b'),(133,111,NULL,1,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 10:27:15','{\"id_mesa\": \"1\", \"id_docente\": \"113\", \"metodo\": \"DNI\", \"id_terminal\": \"1\", \"id_habilitacion\": \"13\"}','05421e4b93f9f6551955a35c1747b45daa5d5857db3cf0a80c12932945f1da7b','03586227c4fe9f2b07a22046bca525266bdc1171a7307ea8c77d4e85a3808d70'),(134,NULL,113,1,'EMITIR_VOTO',NULL,NULL,'2026-11-25 10:27:18','{\"id_cargo\": \"1\"}','03586227c4fe9f2b07a22046bca525266bdc1171a7307ea8c77d4e85a3808d70','dec9c49be22fe79166c59776ce3ef90be190cbe71372403b9a573b9af50b9ec4'),(135,111,NULL,1,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 10:27:19','{\"id_mesa\": \"1\", \"id_terminal\": \"1\"}','dec9c49be22fe79166c59776ce3ef90be190cbe71372403b9a573b9af50b9ec4','76ffebf6e5152f45e266ebe935f6cf5bfdbc037c24a98629ad8a4712909c2ce0'),(136,111,NULL,1,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 10:28:12','{\"id_mesa\": \"1\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"114\"}','76ffebf6e5152f45e266ebe935f6cf5bfdbc037c24a98629ad8a4712909c2ce0','3b5239f757d20c6ce76b79f935719e5684f50616974c92c1b8238de7824da640'),(137,111,NULL,1,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 10:28:13','{\"id_mesa\": \"1\", \"id_docente\": \"114\", \"metodo\": \"DNI\", \"id_terminal\": \"1\", \"id_habilitacion\": \"14\"}','3b5239f757d20c6ce76b79f935719e5684f50616974c92c1b8238de7824da640','0f56fb0aec700bab7f1d07aca1e6a02b45f85afe5933339c0f45189ea0e6ca50'),(138,NULL,114,1,'EMITIR_VOTO',NULL,NULL,'2026-11-25 10:28:17','{\"id_cargo\": \"1\"}','0f56fb0aec700bab7f1d07aca1e6a02b45f85afe5933339c0f45189ea0e6ca50','1611afacc0cc45677825cf10a784040ae71df302dcd584f3eb3651f36e936637'),(139,111,NULL,1,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 10:28:17','{\"id_mesa\": \"1\", \"id_terminal\": \"1\"}','1611afacc0cc45677825cf10a784040ae71df302dcd584f3eb3651f36e936637','be93d46b51c3626f1e8181661dbb2b8fe959eba8aad5ac4d879c45cbd71e34e2'),(140,111,NULL,1,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 10:28:21','{\"id_mesa\": \"1\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"115\"}','be93d46b51c3626f1e8181661dbb2b8fe959eba8aad5ac4d879c45cbd71e34e2','90c0746c5a33bad0d516aa64c0404fb91fdfe9016fbb657e2686e57942fa8de3'),(141,111,NULL,1,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 10:28:23','{\"id_mesa\": \"1\", \"id_docente\": \"115\", \"metodo\": \"DNI\", \"id_terminal\": \"1\", \"id_habilitacion\": \"15\"}','90c0746c5a33bad0d516aa64c0404fb91fdfe9016fbb657e2686e57942fa8de3','485f10585734645ef3dc90039885510f2bc23ce03c7647689bd5822e4090ebee'),(142,NULL,115,1,'EMITIR_VOTO',NULL,NULL,'2026-11-25 10:28:27','{\"id_cargo\": \"1\"}','485f10585734645ef3dc90039885510f2bc23ce03c7647689bd5822e4090ebee','5e533cf73164b8fc34f4f12ab49c5cc781bb299bcb947f376e765ed2c2abf659'),(143,111,NULL,1,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 10:28:27','{\"id_mesa\": \"1\", \"id_terminal\": \"1\"}','5e533cf73164b8fc34f4f12ab49c5cc781bb299bcb947f376e765ed2c2abf659','1831934aab8ce08ab2563ace3367d19be9e1968d9a38821bf588134906719ba8'),(144,111,NULL,1,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 10:28:32','{\"id_mesa\": \"1\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"116\"}','1831934aab8ce08ab2563ace3367d19be9e1968d9a38821bf588134906719ba8','dcba3939c05b11b05172a3007525c4f87e619e276f8f1de99bde452a34eba491'),(145,111,NULL,1,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 10:28:34','{\"id_mesa\": \"1\", \"id_docente\": \"116\", \"metodo\": \"DNI\", \"id_terminal\": \"1\", \"id_habilitacion\": \"16\"}','dcba3939c05b11b05172a3007525c4f87e619e276f8f1de99bde452a34eba491','ac435bbd47ed090a3a758cd693db3f4ed8bf72649b76d5df553c71e0521ac378'),(146,NULL,116,1,'EMITIR_VOTO',NULL,NULL,'2026-11-25 10:28:38','{\"id_cargo\": \"1\"}','ac435bbd47ed090a3a758cd693db3f4ed8bf72649b76d5df553c71e0521ac378','df162e01b212b7000da056789fa12cb2af36b327738d4bffa41517572856ef29'),(147,111,NULL,1,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 10:28:38','{\"id_mesa\": \"1\", \"id_terminal\": \"1\"}','df162e01b212b7000da056789fa12cb2af36b327738d4bffa41517572856ef29','c1a708719847fa0c77d7da310ee00924f9f5e570eb64f57ac02c51dba0b2607f'),(148,111,NULL,1,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 10:28:42','{\"id_mesa\": \"1\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"117\"}','c1a708719847fa0c77d7da310ee00924f9f5e570eb64f57ac02c51dba0b2607f','d7b5e62e77c5e64b4d0ca580cbe5a9c5ee2df3280bf629ee7af37a93611458e2'),(149,111,NULL,1,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 10:28:44','{\"id_mesa\": \"1\", \"id_docente\": \"117\", \"metodo\": \"DNI\", \"id_terminal\": \"1\", \"id_habilitacion\": \"17\"}','d7b5e62e77c5e64b4d0ca580cbe5a9c5ee2df3280bf629ee7af37a93611458e2','08f27d656c618793a4099816a9382a6b5181d0995b3c094feee8c197a552571b'),(150,NULL,117,1,'EMITIR_VOTO',NULL,NULL,'2026-11-25 10:28:50','{\"id_cargo\": \"1\"}','08f27d656c618793a4099816a9382a6b5181d0995b3c094feee8c197a552571b','2016e40637448edf4151a44ac33589f3c07382b8df45e25188514bd2d451f12b'),(151,111,NULL,1,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 10:28:50','{\"id_mesa\": \"1\", \"id_terminal\": \"1\"}','2016e40637448edf4151a44ac33589f3c07382b8df45e25188514bd2d451f12b','4bddb1db5c3ed351f5fa5ff7874e98562cea808a96d3bef61b7f819cc26c5aa3'),(152,110,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 15:25:28',NULL,'4bddb1db5c3ed351f5fa5ff7874e98562cea808a96d3bef61b7f819cc26c5aa3','b51eddd9bf92ebf81890552bd2e9be9cc47bd8e8e2a97e1eb5dba94106e03912'),(153,1,NULL,NULL,'LOGIN_FAILED','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 15:26:16',NULL,'b51eddd9bf92ebf81890552bd2e9be9cc47bd8e8e2a97e1eb5dba94106e03912','0c469db6dff58d738a7a96d6a0ab91fe9f8a304d680b169ca31219cc291e0ff1'),(154,1,NULL,NULL,'LOGIN_FAILED','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 15:26:21',NULL,'0c469db6dff58d738a7a96d6a0ab91fe9f8a304d680b169ca31219cc291e0ff1','ed883156963f56aedb4177f7766ee6412533259cc661c6d4132526d579188efd'),(155,1,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 15:26:25',NULL,'ed883156963f56aedb4177f7766ee6412533259cc661c6d4132526d579188efd','c4e51f4ffc019bc03c7a3efa0b8b2f1800fd619e5b04688e9993f485f78e9e2e'),(156,118,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 15:26:53',NULL,'c4e51f4ffc019bc03c7a3efa0b8b2f1800fd619e5b04688e9993f485f78e9e2e','06b5bd1f8ef7e1206bce0031946ea5c451b60ded9cf2dcd35a35553f21882236'),(157,111,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 15:27:41',NULL,'06b5bd1f8ef7e1206bce0031946ea5c451b60ded9cf2dcd35a35553f21882236','eba04d5091e8c45897cfd90dbbb7e36a200d82d92d620ed8766316a41d4a8417'),(158,110,NULL,1,'CERRAR_SUFRAGIO',NULL,NULL,'2026-11-25 15:28:56','{\"id_mesa\": \"1\", \"votaron\": \"16\", \"electores\": \"17\", \"anticipado\": \"0\"}','eba04d5091e8c45897cfd90dbbb7e36a200d82d92d620ed8766316a41d4a8417','59b9a4ce69010ff9e1dd2c6a281225d6fc44632ab809962c81e6f1185554f3a6'),(159,110,NULL,1,'MARCAR_NO_VOTO',NULL,NULL,'2026-11-25 15:29:13','{\"id_mesa\": \"1\", \"marcados\": \"1\"}','59b9a4ce69010ff9e1dd2c6a281225d6fc44632ab809962c81e6f1185554f3a6','3772e8186718b7351217f47d4551f58546f7a81290f3a7b065ba897050a1d917'),(160,3,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 15:30:50',NULL,'3772e8186718b7351217f47d4551f58546f7a81290f3a7b065ba897050a1d917','a08d326fb991295b124715ecd15054a28ccc48c9da9ddebed8d110cf38fdd026'),(161,3,NULL,1,'EMITIR_ACTA_SUFRAGIO',NULL,NULL,'2026-11-25 15:31:59','{\"id_mesa\": \"1\", \"id_acta\": \"2\", \"votaron\": \"16\"}','a08d326fb991295b124715ecd15054a28ccc48c9da9ddebed8d110cf38fdd026','5c080001fbcd53be2260d5a76cb7673079c6a3e8fb26fba2be09b6bbf7e84c55'),(162,3,NULL,1,'CONTAR_CEDULAS',NULL,NULL,'2026-11-25 15:34:02','{\"id_mesa\": \"1\", \"cedulas\": \"16\", \"votantes\": \"16\", \"sobrantes_destruidas\": \"0\", \"faltantes\": \"0\"}','5c080001fbcd53be2260d5a76cb7673079c6a3e8fb26fba2be09b6bbf7e84c55','06712e8a2d426a454ced55b6e929092c3fc408394834645b3828c414b5d31722'),(163,3,NULL,1,'REGISTRAR_CONTEO_ESCRUTINIO',NULL,NULL,'2026-11-25 15:34:54','{\"id_mesa\": \"1\", \"conteo\": 1, \"cuadra\": \"1\", \"total_cuadra\": \"1\"}','06712e8a2d426a454ced55b6e929092c3fc408394834645b3828c414b5d31722','3d5aa09649ace83c2a6d0b9961491680a5511f7f8b713674da89a0719cd5b479'),(164,3,NULL,1,'EMITIR_ACTA_ESCRUTINIO',NULL,NULL,'2026-11-25 15:35:44','{\"id_mesa\": \"1\", \"id_acta\": \"3\", \"observada\": \"1\", \"prevalece_fisica\": \"0\", \"impugnados\": \"0\"}','3d5aa09649ace83c2a6d0b9961491680a5511f7f8b713674da89a0719cd5b479','f70e91ac523e52a8e9712367beb8fc80a38b60020c2af7e782cb3198d001bcf0'),(165,3,NULL,1,'ENTREGAR_ACTAS',NULL,NULL,'2026-11-25 15:41:32','{\"id_mesa\": \"1\", \"recibido_por\": \"lucano\", \"codigo\": \"885A91ACD4A5\"}','f70e91ac523e52a8e9712367beb8fc80a38b60020c2af7e782cb3198d001bcf0','c9dc6c975daf03398ca13f36f992f0e8a7dc2fc652548a785dc8dcce8675339e'),(166,3,NULL,1,'CAMBIO_ESTADO_PROCESO',NULL,NULL,'2026-11-25 15:45:17','{\"anterior\": \"VOTACION\", \"nuevo\": \"CERRADO\"}','c9dc6c975daf03398ca13f36f992f0e8a7dc2fc652548a785dc8dcce8675339e','ba1c6e15518ac25354470e9060196cba9fa86ac5b0fbed1b9006bdb728efc877'),(167,3,NULL,1,'CALIFICAR_ACTA',NULL,NULL,'2026-11-25 15:53:21','{\"id_mesa\": \"1\", \"calificacion\": \"VALIDA\", \"resolucion\": null}','ba1c6e15518ac25354470e9060196cba9fa86ac5b0fbed1b9006bdb728efc877','236342b377ded045d304a274dd3bd6719be2ea2da8a92aeecacbf48926a321cd'),(168,3,NULL,1,'INSTALAR_SESION_COMPUTO',NULL,NULL,'2026-11-25 15:54:20','{\"lugar\": \"Sala de sesiones del CEUNP\", \"miembros\": \"5\", \"personeros\": \"0\"}','236342b377ded045d304a274dd3bd6719be2ea2da8a92aeecacbf48926a321cd','0f8ab5ecf832d528bef6bc034171f5b40c81380c2a4b30511c157718847df734'),(169,3,NULL,1,'COMPUTAR_RESULTADOS',NULL,NULL,'2026-11-25 15:54:29','{\"cus\": \"CUS14\", \"mesas_computadas\": \"1\", \"cargos_con_quorum\": \"1\", \"resultado\": \"VALIDA\"}','0f8ab5ecf832d528bef6bc034171f5b40c81380c2a4b30511c157718847df734','3c2453d4c8fa7d68cd7aeca179b765182d6db635c3d55c5aaf033e4a5ec02fb4'),(170,3,NULL,1,'PROCLAMAR_RESULTADOS',NULL,NULL,'2026-11-25 15:56:58','{\"resolucion\": \"XXXX\", \"cargos_proclamados\": \"1\"}','3c2453d4c8fa7d68cd7aeca179b765182d6db635c3d55c5aaf033e4a5ec02fb4','c087d5f4e7d3762f870e925b4b3110bad459422e15f02362cf2f9fa8211df2bc'),(171,3,NULL,1,'GENERAR_MULTAS',NULL,NULL,'2026-11-25 15:57:27','{\"omisos_votacion\": \"1\", \"omisos_mesa\": \"0\", \"monto_total\": \"128.75\", \"uit\": \"5150.00\", \"retiradas\": \"0\"}','c087d5f4e7d3762f870e925b4b3110bad459422e15f02362cf2f9fa8211df2bc','217447b1e77e599715d1bb7b67cdd8a10c55eabc3ed7415e2b0738e0f2d0a947'),(172,3,NULL,1,'PUBLICAR_RESULTADOS',NULL,NULL,'2026-11-25 16:00:50','{\"estado_proceso\": \"FINALIZADO\"}','217447b1e77e599715d1bb7b67cdd8a10c55eabc3ed7415e2b0738e0f2d0a947','41ca6be5943c69cd0676e26730c85208e27a679bf4eb3523645c2c250fc41bfd'),(173,3,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 16:01:35',NULL,'41ca6be5943c69cd0676e26730c85208e27a679bf4eb3523645c2c250fc41bfd','61c0a693820a3cd4274f81bbb51c0dfd891a8078c3e9020ec0d0cc385a451378'),(174,3,NULL,2,'CREAR_PROCESO',NULL,NULL,'2026-10-15 14:04:44','{\"nombre\": \"Elección de Jefe de Departamento de Informática 2026-II\"}','61c0a693820a3cd4274f81bbb51c0dfd891a8078c3e9020ec0d0cc385a451378','58a5750e3df3dbc8393824ced7bea8d81e5d2274a8c24764abb93676ac950f4d'),(175,3,NULL,2,'AGREGAR_CARGO',NULL,NULL,'2026-10-15 14:04:56','{\"id_cargo\": \"2\", \"nombre\": \"Jefe de Departamento Académico\", \"nivel\": \"DEPARTAMENTO\", \"id_jurisdiccion\": \"38\", \"votan\": \"PRINCIPAL,ASOCIADO,AUXILIAR\", \"postulan\": \"PRINCIPAL\"}','58a5750e3df3dbc8393824ced7bea8d81e5d2274a8c24764abb93676ac950f4d','1bcbf96d92358b9eb24540edd14c8be58972e74eb0d4298093fd4a62c5359bb1'),(176,3,NULL,2,'CAMBIO_ESTADO_PROCESO',NULL,NULL,'2026-10-15 14:05:00','{\"anterior\": \"CREADO\", \"nuevo\": \"INSCRIPCION\"}','1bcbf96d92358b9eb24540edd14c8be58972e74eb0d4298093fd4a62c5359bb1','bf489062d76f9cc582880234c7634bc6052afd756a501a00fb5b5837b2e2d706'),(177,3,NULL,2,'PUBLICAR_CONVOCATORIA',NULL,NULL,'2026-10-15 14:05:00','{\"nombre\": \"Elección de Jefe de Departamento de Informática 2026-II\", \"fecha_convocatoria\": \"2026-10-15\", \"fecha_limite_inscripcion\": \"2026-10-22T14:04\"}','bf489062d76f9cc582880234c7634bc6052afd756a501a00fb5b5837b2e2d706','effad2ba57bad2c4a7a60a4501692e70e9456bbc10ff1852ebd3c487781a1d62'),(178,3,NULL,NULL,'DEPURAR_PADRON',NULL,NULL,'2026-10-15 14:05:03','{\"habilitados_nuevos\": \"0\", \"inhabilitados_nuevos\": \"0\"}','effad2ba57bad2c4a7a60a4501692e70e9456bbc10ff1852ebd3c487781a1d62','7f35a8d6660aaebe19cb0d4b903b81ed3f27a2ae2a5945b8a1104c117b9857bc'),(179,3,NULL,2,'GENERAR_PADRON',NULL,NULL,'2026-10-15 14:05:07','{\"registros\": \"17\"}','7f35a8d6660aaebe19cb0d4b903b81ed3f27a2ae2a5945b8a1104c117b9857bc','40e46bdfbd5975ce072a87f0b3fd64bfdeee778e4d9456d3a3cbc2f4d6727cb6'),(180,3,NULL,2,'INSCRIBIR_LISTA',NULL,NULL,'2026-10-15 14:05:20','{\"id_lista\": \"3\", \"nombre\": \"A\"}','40e46bdfbd5975ce072a87f0b3fd64bfdeee778e4d9456d3a3cbc2f4d6727cb6','f52d8fd6e2598dfb8dc4f5602d79b5a3c63b86de9d9380b56738c5e1fbce4472'),(181,3,NULL,2,'RETIRAR_LISTA',NULL,NULL,'2026-10-15 14:05:46','{\"id_lista\": \"3\", \"nombre\": \"A\"}','f52d8fd6e2598dfb8dc4f5602d79b5a3c63b86de9d9380b56738c5e1fbce4472','17613b5b3b6314bb0da7603b088ba2f3c4454c3aa2da4e8b1ee55a86ec94628b'),(182,3,NULL,2,'INSCRIBIR_LISTA',NULL,NULL,'2026-10-15 14:06:10','{\"id_lista\": \"4\", \"nombre\": \"Innovación Informática\"}','17613b5b3b6314bb0da7603b088ba2f3c4454c3aa2da4e8b1ee55a86ec94628b','ad529ae4338dde3133e2c965fc8108c1e98a0fe12d9bd3b13dd010507642bbfa'),(183,3,102,2,'INSCRIBIR_CANDIDATO',NULL,NULL,'2026-10-15 14:06:21','{\"id_lista\": \"4\", \"rol\": \"JEFE_DEPARTAMENTO\"}','ad529ae4338dde3133e2c965fc8108c1e98a0fe12d9bd3b13dd010507642bbfa','243665b70e013852929f3068a03306df6b8c0b2bb8564cf047a953949c16bef1'),(184,3,NULL,2,'INSCRIBIR_LISTA',NULL,NULL,'2026-10-15 14:06:43','{\"id_lista\": \"5\", \"nombre\": \"Avance TI\"}','243665b70e013852929f3068a03306df6b8c0b2bb8564cf047a953949c16bef1','2ff6ea5e00c68ee4abf5b8f92304b6f1e654ddb3f4f60c35e9af994a2d3a4107'),(185,3,106,2,'INSCRIBIR_CANDIDATO',NULL,NULL,'2026-10-15 14:06:53','{\"id_lista\": \"5\", \"rol\": \"JEFE_DEPARTAMENTO\"}','2ff6ea5e00c68ee4abf5b8f92304b6f1e654ddb3f4f60c35e9af994a2d3a4107','0cf55c1ce5975d393896712c6aa764b2c56672a6e5c3090740d33a975e85f1e5'),(186,3,NULL,2,'CREAR_MESAS',NULL,NULL,'2026-10-15 14:07:06','{\"mesas\": \"1\", \"electores\": \"17\"}','0cf55c1ce5975d393896712c6aa764b2c56672a6e5c3090740d33a975e85f1e5','a02b5a45441e8faa8583e257aa86352a476c72738bde0fe4b6e9190026ab36ca'),(187,3,NULL,2,'SORTEO_MESA',NULL,NULL,'2026-10-15 14:07:27','{\"id_mesa\": \"2\", \"semilla\": \"9a68ec22b93031aadc931ce9499c7709e5bdb1740676a6dbd4ffac0983d57319\", \"algoritmo\": \"ORDER BY SHA256(semilla|dni)\"}','a02b5a45441e8faa8583e257aa86352a476c72738bde0fe4b6e9190026ab36ca','4d7df4be96b55f36db2cf82ed82bc1368f5884cb6ef19316c4d78824f74ee2fa'),(188,3,NULL,2,'SORTEO_GENERAL_MESAS',NULL,NULL,'2026-10-15 14:07:27','{\"semilla_base\": \"a60b5b29109e191318267e42619f67d0cf3ccfe98420266739225aed6f4f49cb\"}','4d7df4be96b55f36db2cf82ed82bc1368f5884cb6ef19316c4d78824f74ee2fa','21f4d869e21b215ba80377af20d3ec6adbdb7cb00770b08fd800081f782dea36'),(189,3,NULL,2,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-15 14:08:04','{\"id_credencial\": \"24\", \"tipo\": \"MIEMBRO_MESA\", \"id_docente\": \"115\", \"id_mesa\": \"2\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','21f4d869e21b215ba80377af20d3ec6adbdb7cb00770b08fd800081f782dea36','6e8f3445441914a7a17eb1b63ffac6fd4ac74412e8735b463222f1a7974b6fb3'),(190,3,NULL,2,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-15 14:08:04','{\"id_credencial\": \"25\", \"tipo\": \"MIEMBRO_MESA\", \"id_docente\": \"117\", \"id_mesa\": \"2\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','6e8f3445441914a7a17eb1b63ffac6fd4ac74412e8735b463222f1a7974b6fb3','8e5f7da64da9fedc15f5f221358ae3edcb9f162d54d6e061f95fcd130a23e249'),(191,3,NULL,2,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-15 14:08:04','{\"id_credencial\": \"26\", \"tipo\": \"MIEMBRO_MESA\", \"id_docente\": \"110\", \"id_mesa\": \"2\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','8e5f7da64da9fedc15f5f221358ae3edcb9f162d54d6e061f95fcd130a23e249','0e2f28a984cfcb1912af40d9817c475a62fd28e25707a79e474c91c864ce6f5c'),(192,3,NULL,2,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-15 14:08:04','{\"id_credencial\": \"27\", \"tipo\": \"MIEMBRO_MESA\", \"id_docente\": \"107\", \"id_mesa\": \"2\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','0e2f28a984cfcb1912af40d9817c475a62fd28e25707a79e474c91c864ce6f5c','bd8c553efcd56df4114fdc02bc172d8f43f6414fc9cabb4ca19292517b843094'),(193,3,NULL,2,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-15 14:08:04','{\"id_credencial\": \"28\", \"tipo\": \"MIEMBRO_MESA\", \"id_docente\": \"114\", \"id_mesa\": \"2\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','bd8c553efcd56df4114fdc02bc172d8f43f6414fc9cabb4ca19292517b843094','bacde1bc7f01e686cd1fdd0ef5066d1b5354dad5430a5dec20b14f14cc5b8fd0'),(194,3,NULL,2,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-15 14:08:04','{\"id_credencial\": \"29\", \"tipo\": \"MIEMBRO_MESA\", \"id_docente\": \"104\", \"id_mesa\": \"2\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','bacde1bc7f01e686cd1fdd0ef5066d1b5354dad5430a5dec20b14f14cc5b8fd0','cb067dad77fcd8fa4b53f2597e99fcb45a8f6c2fa846f97c949ef298848216af'),(195,3,NULL,2,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-15 14:08:25','{\"id_credencial\": \"30\", \"tipo\": \"ELECTOR\", \"id_docente\": \"101\", \"id_mesa\": \"2\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','cb067dad77fcd8fa4b53f2597e99fcb45a8f6c2fa846f97c949ef298848216af','5ee5c972adfa7793f495fe70256c1718c200b92946ec7e357d9a57874472c3c3'),(196,3,NULL,2,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-15 14:08:25','{\"id_credencial\": \"31\", \"tipo\": \"ELECTOR\", \"id_docente\": \"102\", \"id_mesa\": \"2\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','5ee5c972adfa7793f495fe70256c1718c200b92946ec7e357d9a57874472c3c3','2720c1707d20f02d328a7044e9c928ba19441d27989b8e8d5fd953f4e6ff8923'),(197,3,NULL,2,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-15 14:08:25','{\"id_credencial\": \"32\", \"tipo\": \"ELECTOR\", \"id_docente\": \"103\", \"id_mesa\": \"2\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','2720c1707d20f02d328a7044e9c928ba19441d27989b8e8d5fd953f4e6ff8923','ea8562e5db08d7ddffac5d2d93dd53a39df9b2e0256a230c0e1601c6f32e9eb5'),(198,3,NULL,2,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-15 14:08:25','{\"id_credencial\": \"33\", \"tipo\": \"ELECTOR\", \"id_docente\": \"104\", \"id_mesa\": \"2\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','ea8562e5db08d7ddffac5d2d93dd53a39df9b2e0256a230c0e1601c6f32e9eb5','c6ecdb1886273ad751dd3305131e66933e03e72fa30762507b9fccf4d746a6ee'),(199,3,NULL,2,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-15 14:08:25','{\"id_credencial\": \"34\", \"tipo\": \"ELECTOR\", \"id_docente\": \"105\", \"id_mesa\": \"2\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','c6ecdb1886273ad751dd3305131e66933e03e72fa30762507b9fccf4d746a6ee','4f6d10c604c150537d751a11ff08cf3fbfe9a1cbfdedf95fe7ed5e73d6c24a08'),(200,3,NULL,2,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-15 14:08:25','{\"id_credencial\": \"35\", \"tipo\": \"ELECTOR\", \"id_docente\": \"106\", \"id_mesa\": \"2\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','4f6d10c604c150537d751a11ff08cf3fbfe9a1cbfdedf95fe7ed5e73d6c24a08','8213adb00decc9ab479ef0107bbae4ccbfd1e11992a47e457394480af38cfc64'),(201,3,NULL,2,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-15 14:08:25','{\"id_credencial\": \"36\", \"tipo\": \"ELECTOR\", \"id_docente\": \"107\", \"id_mesa\": \"2\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','8213adb00decc9ab479ef0107bbae4ccbfd1e11992a47e457394480af38cfc64','1e4aa819a02e89ad036d238707bace0644d73313672ce6dfb8570fa131a28449'),(202,3,NULL,2,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-15 14:08:25','{\"id_credencial\": \"37\", \"tipo\": \"ELECTOR\", \"id_docente\": \"108\", \"id_mesa\": \"2\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','1e4aa819a02e89ad036d238707bace0644d73313672ce6dfb8570fa131a28449','7d88939705df5d9ff399536d31ffbcf520e20e69edef9aa3a14e4303355c15f3'),(203,3,NULL,2,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-15 14:08:25','{\"id_credencial\": \"38\", \"tipo\": \"ELECTOR\", \"id_docente\": \"109\", \"id_mesa\": \"2\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','7d88939705df5d9ff399536d31ffbcf520e20e69edef9aa3a14e4303355c15f3','f151c4852f245624521d7b20cd7247687c69c655c59a5eef690fe9a0dea91145'),(204,3,NULL,2,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-15 14:08:25','{\"id_credencial\": \"39\", \"tipo\": \"ELECTOR\", \"id_docente\": \"110\", \"id_mesa\": \"2\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','f151c4852f245624521d7b20cd7247687c69c655c59a5eef690fe9a0dea91145','2a91e43b3b00a625363806fb25ea5cb7e2f3379f8623e6b8cd34c5aed278eed9'),(205,3,NULL,2,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-15 14:08:25','{\"id_credencial\": \"40\", \"tipo\": \"ELECTOR\", \"id_docente\": \"111\", \"id_mesa\": \"2\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','2a91e43b3b00a625363806fb25ea5cb7e2f3379f8623e6b8cd34c5aed278eed9','d17030067558920e1c6e911ff440fb456f7859dad49b32397b4ce246fd1606fc'),(206,3,NULL,2,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-15 14:08:25','{\"id_credencial\": \"41\", \"tipo\": \"ELECTOR\", \"id_docente\": \"112\", \"id_mesa\": \"2\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','d17030067558920e1c6e911ff440fb456f7859dad49b32397b4ce246fd1606fc','824353b58acef999a384bd7bcb21777b8690379c45ab27b0ee18082b4a071609'),(207,3,NULL,2,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-15 14:08:25','{\"id_credencial\": \"42\", \"tipo\": \"ELECTOR\", \"id_docente\": \"113\", \"id_mesa\": \"2\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','824353b58acef999a384bd7bcb21777b8690379c45ab27b0ee18082b4a071609','998dba085995edd954574bef791c029a72bd47db98400965513330da14acf384'),(208,3,NULL,2,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-15 14:08:25','{\"id_credencial\": \"43\", \"tipo\": \"ELECTOR\", \"id_docente\": \"114\", \"id_mesa\": \"2\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','998dba085995edd954574bef791c029a72bd47db98400965513330da14acf384','cb06fa2e2c8c583e65c5c3d361fb26807fd01670902a7084164483daef4df736'),(209,3,NULL,2,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-15 14:08:25','{\"id_credencial\": \"44\", \"tipo\": \"ELECTOR\", \"id_docente\": \"115\", \"id_mesa\": \"2\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','cb06fa2e2c8c583e65c5c3d361fb26807fd01670902a7084164483daef4df736','45c7e97753aaaf980a1d097d44fb05de4947ecdd381f5b18f26f416e09e573ec'),(210,3,NULL,2,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-15 14:08:25','{\"id_credencial\": \"45\", \"tipo\": \"ELECTOR\", \"id_docente\": \"116\", \"id_mesa\": \"2\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','45c7e97753aaaf980a1d097d44fb05de4947ecdd381f5b18f26f416e09e573ec','d80908a2c40649ceadb6720925fa53e9b8794bcb4fd52767700de376d6eeb064'),(211,3,NULL,2,'EMITIR_CREDENCIAL',NULL,NULL,'2026-10-15 14:08:25','{\"id_credencial\": \"46\", \"tipo\": \"ELECTOR\", \"id_docente\": \"117\", \"id_mesa\": \"2\", \"id_personero\": null, \"reemplaza_anterior\": \"false\"}','d80908a2c40649ceadb6720925fa53e9b8794bcb4fd52767700de376d6eeb064','de81711dd65310e25499ab9468e609558a69bf00e547bb8b1d0140ac05176d3c'),(212,3,NULL,2,'VALIDAR_LISTA',NULL,NULL,'2026-10-23 14:09:18','{\"id_lista\": \"4\", \"admitida\": \"SI\", \"motivo\": \"\"}','de81711dd65310e25499ab9468e609558a69bf00e547bb8b1d0140ac05176d3c','9d58fd331ff2dfe5d24474dce87f1f156588ff141398ddff7bd52fca3834bf57'),(213,3,NULL,2,'VALIDAR_LISTA',NULL,NULL,'2026-10-23 14:09:19','{\"id_lista\": \"5\", \"admitida\": \"SI\", \"motivo\": \"\"}','9d58fd331ff2dfe5d24474dce87f1f156588ff141398ddff7bd52fca3834bf57','d009ace613ee3c5ff1e2dbe9bc2589e8cdcfc6a031ff4b175c3c23eac2ec7df2'),(214,3,NULL,2,'SORTEO_ORDEN_CEDULA',NULL,NULL,'2026-10-23 14:09:26','{\"id_cargo\": \"2\", \"semilla\": \"365413a6ecf574926eebf5de4cf44d4126242df5aecd87b0f99f92be058849e4\"}','d009ace613ee3c5ff1e2dbe9bc2589e8cdcfc6a031ff4b175c3c23eac2ec7df2','f88f3c33840a4319f45e3313f0b71cccbf11aa57b4abe9a512b9c7ed65f1935a'),(215,3,NULL,2,'CAMBIO_ESTADO_PROCESO',NULL,NULL,'2026-11-25 09:09:34','{\"anterior\": \"INSCRIPCION\", \"nuevo\": \"VOTACION\"}','f88f3c33840a4319f45e3313f0b71cccbf11aa57b4abe9a512b9c7ed65f1935a','ad49baa3ab51bd007dc90772b6d6581eb8e86163a56ce1953942a2c9022537f6'),(216,3,NULL,2,'REGISTRAR_LLEGADA_MIEMBRO',NULL,NULL,'2026-11-25 09:10:15','{\"id_mesa\": \"2\", \"id_docente\": \"115\", \"presente\": \"true\", \"metodo\": \"DNI\"}','ad49baa3ab51bd007dc90772b6d6581eb8e86163a56ce1953942a2c9022537f6','d507ffa3fdc0971fc50644d863a3febc14704c8594b1e2b34770e91ee46b6331'),(217,1,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 09:10:34',NULL,'d507ffa3fdc0971fc50644d863a3febc14704c8594b1e2b34770e91ee46b6331','274866c1190b5ce3fbb626d4cb4bc2835e03c955eceefff0f09a79bc324531d3'),(218,118,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 09:14:06',NULL,'274866c1190b5ce3fbb626d4cb4bc2835e03c955eceefff0f09a79bc324531d3','d0b723b5c54b49c70742d22934573116e1805ce0fa2a3a4c59e7c1c1aa0eff4b'),(219,118,NULL,2,'REGISTRAR_LLEGADA_MIEMBRO',NULL,NULL,'2026-11-25 09:15:42','{\"id_mesa\": \"2\", \"id_docente\": \"117\", \"presente\": \"true\", \"metodo\": \"DNI\"}','d0b723b5c54b49c70742d22934573116e1805ce0fa2a3a4c59e7c1c1aa0eff4b','26b17dc20ed5204206123840f5ffc2d5ad8e5bcb51781007e60831a56537a62c'),(220,118,NULL,2,'REGISTRAR_LLEGADA_MIEMBRO',NULL,NULL,'2026-11-25 09:15:49','{\"id_mesa\": \"2\", \"id_docente\": \"110\", \"presente\": \"true\", \"metodo\": \"DNI\"}','26b17dc20ed5204206123840f5ffc2d5ad8e5bcb51781007e60831a56537a62c','f6f1759580867887af7d727a9b6793a95ab8bd06a4d18886ed55eeaf4dd9b5b0'),(221,118,NULL,2,'REGISTRAR_LLEGADA_MIEMBRO',NULL,NULL,'2026-11-25 09:16:08','{\"id_mesa\": \"2\", \"id_docente\": \"107\", \"presente\": \"false\", \"metodo\": null}','f6f1759580867887af7d727a9b6793a95ab8bd06a4d18886ed55eeaf4dd9b5b0','379a2682a28e6a737afb82e7012227d45e119507f60960093c25b861d1eeaf72'),(222,118,NULL,2,'REGISTRAR_LLEGADA_MIEMBRO',NULL,NULL,'2026-11-25 09:16:09','{\"id_mesa\": \"2\", \"id_docente\": \"114\", \"presente\": \"false\", \"metodo\": null}','379a2682a28e6a737afb82e7012227d45e119507f60960093c25b861d1eeaf72','c19fa89912a9ec5388c61592989834cc04c4670fa13c4272e6ceef56ca0f5701'),(223,118,NULL,2,'REGISTRAR_LLEGADA_MIEMBRO',NULL,NULL,'2026-11-25 09:16:10','{\"id_mesa\": \"2\", \"id_docente\": \"104\", \"presente\": \"false\", \"metodo\": null}','c19fa89912a9ec5388c61592989834cc04c4670fa13c4272e6ceef56ca0f5701','b66404cf24402143b084f06ab2286d0a73cb134ec721f4e292cc7d3f099dfc4c'),(224,3,NULL,2,'VERIFICAR_MATERIAL_MESA',NULL,NULL,'2026-11-25 09:17:09','{\"id_mesa\": \"2\", \"completo\": \"true\", \"faltantes\": \"\", \"observados\": \"\", \"cedulas\": \"17\"}','b66404cf24402143b084f06ab2286d0a73cb134ec721f4e292cc7d3f099dfc4c','2058811890cd0724b6222c3ffc06969c61957fa56476f3fe251b3a3ea75f6f0a'),(225,3,NULL,2,'INSTALAR_MESA',NULL,NULL,'2026-11-25 09:17:30','{\"id_mesa\": \"2\", \"id_acta\": \"4\"}','2058811890cd0724b6222c3ffc06969c61957fa56476f3fe251b3a3ea75f6f0a','fd459e33df3b72c2cfc6fe1837d1984aa059e8c9795fcbae7b339d298f3257b5'),(226,118,NULL,2,'CONECTAR_TERMINAL',NULL,NULL,'2026-11-25 09:18:09','{\"id_mesa\": \"2\", \"id_terminal\": \"2\"}','fd459e33df3b72c2cfc6fe1837d1984aa059e8c9795fcbae7b339d298f3257b5','70140763b015e61495ca417c280b87f88105edb82311f2ebd3e661e9b3385a10'),(227,118,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 09:19:20',NULL,'70140763b015e61495ca417c280b87f88105edb82311f2ebd3e661e9b3385a10','c46b551940aec55b0a55e19ae832bae9f6a71d9433633ca6b82fa97cfb9decdf'),(228,3,NULL,2,'CONECTAR_TERMINAL',NULL,NULL,'2026-11-25 09:20:12','{\"id_mesa\": \"2\", \"id_terminal\": \"2\"}','c46b551940aec55b0a55e19ae832bae9f6a71d9433633ca6b82fa97cfb9decdf','6cc193d3b238f5372d03a7b7dc8749014b6f8169cfd2d7e070d29bfc0bada636'),(229,3,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 09:20:39',NULL,'6cc193d3b238f5372d03a7b7dc8749014b6f8169cfd2d7e070d29bfc0bada636','a5d915e9026f508a3f97b656501ab2adc9d1417042b16cfdac3102e299b400fe'),(230,118,NULL,NULL,'LOGIN_FAILED','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 09:20:52',NULL,'a5d915e9026f508a3f97b656501ab2adc9d1417042b16cfdac3102e299b400fe','390772576a03807574b26535de498c7349a147c5885f908ed3d0703668707421'),(231,118,NULL,NULL,'LOGIN_FAILED','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 09:21:00',NULL,'390772576a03807574b26535de498c7349a147c5885f908ed3d0703668707421','eece15ddf4f4d697f5d16facedbf135b649dab080576df0f042fe0e66a01434e'),(232,118,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 09:21:06',NULL,'eece15ddf4f4d697f5d16facedbf135b649dab080576df0f042fe0e66a01434e','be002b664ed752e125949d25f2dedd4cd32c7835a22305d9bb087f05cca7bf69'),(233,118,NULL,2,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 09:21:15','{\"id_mesa\": \"2\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"101\"}','be002b664ed752e125949d25f2dedd4cd32c7835a22305d9bb087f05cca7bf69','aaa9b7a26ca4be8f31e279fc5d8bc5d49c06ebb34db4960872acef20e0156f6b'),(234,118,NULL,2,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 09:21:18','{\"id_mesa\": \"2\", \"id_docente\": \"101\", \"metodo\": \"DNI\", \"id_terminal\": \"2\", \"id_habilitacion\": \"18\"}','aaa9b7a26ca4be8f31e279fc5d8bc5d49c06ebb34db4960872acef20e0156f6b','1e5a6322283a4df2a10789731ac9a3ff40a7b09279b8056961bac26c4f602824'),(235,NULL,101,2,'EMITIR_VOTO',NULL,NULL,'2026-11-25 09:21:25','{\"id_cargo\": \"2\"}','1e5a6322283a4df2a10789731ac9a3ff40a7b09279b8056961bac26c4f602824','bd52f49f60d45c0b89eb77e01481df056a3f8096a3e7cf08f37f9e9dc6ce12dd'),(236,3,NULL,2,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 09:21:25','{\"id_mesa\": \"2\", \"id_terminal\": \"2\"}','bd52f49f60d45c0b89eb77e01481df056a3f8096a3e7cf08f37f9e9dc6ce12dd','a0c1d5d33d64f02603d22f82252683684afcc9a9556bed5a32c3f2afd7bd3edd'),(237,118,NULL,2,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 09:21:30','{\"id_mesa\": \"2\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"102\"}','a0c1d5d33d64f02603d22f82252683684afcc9a9556bed5a32c3f2afd7bd3edd','479572d54edfb5199bc32785c30b3a48a4e53307c8187f8efb0cea3940d0b1ea'),(238,118,NULL,2,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 09:21:33','{\"id_mesa\": \"2\", \"id_docente\": \"102\", \"metodo\": \"DNI\", \"id_terminal\": \"2\", \"id_habilitacion\": \"19\"}','479572d54edfb5199bc32785c30b3a48a4e53307c8187f8efb0cea3940d0b1ea','1d3d07c8be1a1888ee66379e4c301a1970e31ec0b28dee51bde5af621ac97375'),(239,NULL,102,2,'EMITIR_VOTO',NULL,NULL,'2026-11-25 09:21:52','{\"id_cargo\": \"2\"}','1d3d07c8be1a1888ee66379e4c301a1970e31ec0b28dee51bde5af621ac97375','7d53f885b4c975f31b6b121fa4c5917ebb6efe47547f3d7ac6562bd09b709ea4'),(240,3,NULL,2,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 09:21:52','{\"id_mesa\": \"2\", \"id_terminal\": \"2\"}','7d53f885b4c975f31b6b121fa4c5917ebb6efe47547f3d7ac6562bd09b709ea4','3b5d0fa4d00a13354facfa23aaa62da1eba11a203f38e34d676446707cdfb5c9'),(241,118,NULL,2,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 09:21:58','{\"id_mesa\": \"2\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"103\"}','3b5d0fa4d00a13354facfa23aaa62da1eba11a203f38e34d676446707cdfb5c9','03e01f53635006ddd5f97271877ab7a89cd4575debd088f3fbf87e5ccefead09'),(242,118,NULL,2,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 09:22:01','{\"id_mesa\": \"2\", \"id_docente\": \"103\", \"metodo\": \"DNI\", \"id_terminal\": \"2\", \"id_habilitacion\": \"20\"}','03e01f53635006ddd5f97271877ab7a89cd4575debd088f3fbf87e5ccefead09','8c69eea6fb0388970365e68778db8566eca77d4217d89481cdbe6ce0c139bc5f'),(243,NULL,103,2,'EMITIR_VOTO',NULL,NULL,'2026-11-25 09:22:10','{\"id_cargo\": \"2\"}','8c69eea6fb0388970365e68778db8566eca77d4217d89481cdbe6ce0c139bc5f','a34e46d1ec66bf4ef569c3f5e5d6c7dcfe2e0af9c6b97066cc4833910bfb0f94'),(244,3,NULL,2,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 09:22:10','{\"id_mesa\": \"2\", \"id_terminal\": \"2\"}','a34e46d1ec66bf4ef569c3f5e5d6c7dcfe2e0af9c6b97066cc4833910bfb0f94','4e896ee52e34326609f370f5964460990af47d09c93331973def312d2908f52b'),(245,118,NULL,2,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 09:22:15','{\"id_mesa\": \"2\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"104\"}','4e896ee52e34326609f370f5964460990af47d09c93331973def312d2908f52b','4706b331ce408fa3681918e9fe94df3d697a94c40b1b36ca54614dfb8a231a03'),(246,118,NULL,2,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 09:22:19','{\"id_mesa\": \"2\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"104\"}','4706b331ce408fa3681918e9fe94df3d697a94c40b1b36ca54614dfb8a231a03','538ee478be7a01c5e2354b0647d73692595d22bdf8902de4d55047942fecea3a'),(247,118,NULL,2,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 09:22:20','{\"id_mesa\": \"2\", \"id_docente\": \"104\", \"metodo\": \"DNI\", \"id_terminal\": \"2\", \"id_habilitacion\": \"21\"}','538ee478be7a01c5e2354b0647d73692595d22bdf8902de4d55047942fecea3a','f6339f4ca66c764c73105c54355ca18ae3af8093e3f59ff7ff56e6b1c891a6cc'),(248,NULL,104,2,'EMITIR_VOTO',NULL,NULL,'2026-11-25 09:22:26','{\"id_cargo\": \"2\"}','f6339f4ca66c764c73105c54355ca18ae3af8093e3f59ff7ff56e6b1c891a6cc','6e487d170d7bfbf788422b094ba7a02372b3ebe28274a4d990e2dcc708beed68'),(249,3,NULL,2,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 09:22:26','{\"id_mesa\": \"2\", \"id_terminal\": \"2\"}','6e487d170d7bfbf788422b094ba7a02372b3ebe28274a4d990e2dcc708beed68','e6455337886b497d5b5b04ae93c3ce6ccdf7bda5b1b6076e6372037b9ec8917c'),(250,118,NULL,2,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 09:22:32','{\"id_mesa\": \"2\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"105\"}','e6455337886b497d5b5b04ae93c3ce6ccdf7bda5b1b6076e6372037b9ec8917c','3bea2d62599d94442941601fd5947ef03243ef23bcc77d8a6ef13d27e12ebaba'),(251,118,NULL,2,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 09:22:34','{\"id_mesa\": \"2\", \"id_docente\": \"105\", \"metodo\": \"DNI\", \"id_terminal\": \"2\", \"id_habilitacion\": \"22\"}','3bea2d62599d94442941601fd5947ef03243ef23bcc77d8a6ef13d27e12ebaba','aac95b2496a290e49d8c5c354a51238ea8b89b65fc2ed6d41e972c9967b2b8b8'),(252,NULL,105,2,'EMITIR_VOTO',NULL,NULL,'2026-11-25 09:22:40','{\"id_cargo\": \"2\"}','aac95b2496a290e49d8c5c354a51238ea8b89b65fc2ed6d41e972c9967b2b8b8','8cd2d63f397dc4f29aaedb9dc8b27574577f0cc5ae9769b87f5a88be15657c8e'),(253,3,NULL,2,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 09:22:40','{\"id_mesa\": \"2\", \"id_terminal\": \"2\"}','8cd2d63f397dc4f29aaedb9dc8b27574577f0cc5ae9769b87f5a88be15657c8e','f96ff590eda23596af55855e9ae55c29e156b860856dc176084020adcff83daa'),(254,118,NULL,2,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 09:26:28','{\"id_mesa\": \"2\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"106\"}','f96ff590eda23596af55855e9ae55c29e156b860856dc176084020adcff83daa','8d9031cb9368a3cddc4f204560d63cdf7f13dd899dc5f7963b4fb835c4503993'),(255,118,NULL,2,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 09:26:31','{\"id_mesa\": \"2\", \"id_docente\": \"106\", \"metodo\": \"DNI\", \"id_terminal\": \"2\", \"id_habilitacion\": \"23\"}','8d9031cb9368a3cddc4f204560d63cdf7f13dd899dc5f7963b4fb835c4503993','03dd159cd01592b1861d89d527b691d048da6bb6e8b109fd2a4aedd0c9c132e8'),(256,NULL,106,2,'EMITIR_VOTO',NULL,NULL,'2026-11-25 09:26:38','{\"id_cargo\": \"2\"}','03dd159cd01592b1861d89d527b691d048da6bb6e8b109fd2a4aedd0c9c132e8','2ceb16e6c48a40d73f9a5e74488d8f0a7649185bc82dc525a56ee17c83d887c8'),(257,3,NULL,2,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 09:26:38','{\"id_mesa\": \"2\", \"id_terminal\": \"2\"}','2ceb16e6c48a40d73f9a5e74488d8f0a7649185bc82dc525a56ee17c83d887c8','00a60d5714c5ea8e9a204dfc43655753ef97bfc46d386690194753055a0aea82'),(258,118,NULL,2,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 09:26:47','{\"id_mesa\": \"2\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"107\"}','00a60d5714c5ea8e9a204dfc43655753ef97bfc46d386690194753055a0aea82','707d1733ea73b060ae98465b3d41dff96889c9f6403cf3eac621138f3da04c27'),(259,118,NULL,2,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 09:26:49','{\"id_mesa\": \"2\", \"id_docente\": \"107\", \"metodo\": \"DNI\", \"id_terminal\": \"2\", \"id_habilitacion\": \"24\"}','707d1733ea73b060ae98465b3d41dff96889c9f6403cf3eac621138f3da04c27','0033e811e668ccc21292bc22976127d9f45da73812ddd562281f65e4cbc146b8'),(260,NULL,107,2,'EMITIR_VOTO',NULL,NULL,'2026-11-25 09:26:54','{\"id_cargo\": \"2\"}','0033e811e668ccc21292bc22976127d9f45da73812ddd562281f65e4cbc146b8','5bd6cebb3889a6f71790ca23faf9baf905f9a2c1a807f3557fa8f51d380272ca'),(261,3,NULL,2,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 09:26:54','{\"id_mesa\": \"2\", \"id_terminal\": \"2\"}','5bd6cebb3889a6f71790ca23faf9baf905f9a2c1a807f3557fa8f51d380272ca','39fbded7a76f819927db6651af5fef552c84c25507a746115a7925fd2387d8eb'),(262,118,NULL,2,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 09:27:00','{\"id_mesa\": \"2\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"108\"}','39fbded7a76f819927db6651af5fef552c84c25507a746115a7925fd2387d8eb','b54e3f4f43aaea3d7043ed8b5428282b19e3ea05644788a2bdf735d6d1e9cea0'),(263,118,NULL,2,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 09:27:01','{\"id_mesa\": \"2\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"108\"}','b54e3f4f43aaea3d7043ed8b5428282b19e3ea05644788a2bdf735d6d1e9cea0','c6bf7ae98b70759a63c1fa7ae6b801d5bdaa6c1d34e1837a7c6887513278d7ee'),(264,118,NULL,2,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 09:27:03','{\"id_mesa\": \"2\", \"id_docente\": \"108\", \"metodo\": \"DNI\", \"id_terminal\": \"2\", \"id_habilitacion\": \"25\"}','c6bf7ae98b70759a63c1fa7ae6b801d5bdaa6c1d34e1837a7c6887513278d7ee','c1a9a66a81272d855300dd92ac2c7d61f94999619316b15297d8caf893b6b4be'),(265,NULL,108,2,'EMITIR_VOTO',NULL,NULL,'2026-11-25 09:27:07','{\"id_cargo\": \"2\"}','c1a9a66a81272d855300dd92ac2c7d61f94999619316b15297d8caf893b6b4be','6bb31ee377ea690305d7729442c0bd4d028209f338f4e714eefa10819838a9f3'),(266,3,NULL,2,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 09:27:07','{\"id_mesa\": \"2\", \"id_terminal\": \"2\"}','6bb31ee377ea690305d7729442c0bd4d028209f338f4e714eefa10819838a9f3','48569d6641107c2ad726a98dbd8ca822180d2c45cc6bee3c96bc9f26607f980e'),(267,118,NULL,2,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 09:27:11','{\"id_mesa\": \"2\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"109\"}','48569d6641107c2ad726a98dbd8ca822180d2c45cc6bee3c96bc9f26607f980e','e507e10affd4f310b3272cf042e38553aa20fe1645984050f1c8e36abbbfa32a'),(268,118,NULL,2,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 09:27:12','{\"id_mesa\": \"2\", \"id_docente\": \"109\", \"metodo\": \"DNI\", \"id_terminal\": \"2\", \"id_habilitacion\": \"26\"}','e507e10affd4f310b3272cf042e38553aa20fe1645984050f1c8e36abbbfa32a','9503ed6d2da23f3f55b59888bebd5be67df55b24313f76dcdaf0bec504ea37a7'),(269,NULL,109,2,'EMITIR_VOTO',NULL,NULL,'2026-11-25 09:27:17','{\"id_cargo\": \"2\"}','9503ed6d2da23f3f55b59888bebd5be67df55b24313f76dcdaf0bec504ea37a7','3fb7dd9bc24dc8e575d42567fd86cd106097cb1f96f3c93873c21ce929d8f700'),(270,3,NULL,2,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 09:27:17','{\"id_mesa\": \"2\", \"id_terminal\": \"2\"}','3fb7dd9bc24dc8e575d42567fd86cd106097cb1f96f3c93873c21ce929d8f700','13605de61166a4d72f99fda3378e9888efe4f04421ee4cf00d118bb73da7afee'),(271,118,NULL,2,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 09:27:20','{\"id_mesa\": \"2\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"110\"}','13605de61166a4d72f99fda3378e9888efe4f04421ee4cf00d118bb73da7afee','ce1c49beaeb07472170d682f43654e86aa72550049c549b5a3162d1c1ca012e3'),(272,118,NULL,2,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 09:27:22','{\"id_mesa\": \"2\", \"id_docente\": \"110\", \"metodo\": \"DNI\", \"id_terminal\": \"2\", \"id_habilitacion\": \"27\"}','ce1c49beaeb07472170d682f43654e86aa72550049c549b5a3162d1c1ca012e3','f08fcde29982d1f44cd24a821a09ada63ef171b9e0448d563c1f9bc673884b14'),(273,NULL,110,2,'EMITIR_VOTO',NULL,NULL,'2026-11-25 09:27:26','{\"id_cargo\": \"2\"}','f08fcde29982d1f44cd24a821a09ada63ef171b9e0448d563c1f9bc673884b14','670ec6c7757947637f160a9e06ee171d5d24c2893b0ef9921b1e8cb98eebd325'),(274,3,NULL,2,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 09:27:26','{\"id_mesa\": \"2\", \"id_terminal\": \"2\"}','670ec6c7757947637f160a9e06ee171d5d24c2893b0ef9921b1e8cb98eebd325','069dea5c952f86fcfbe1032c61cc33adc557083a42187126b0b1e3425210bb66'),(275,118,NULL,2,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 09:27:30','{\"id_mesa\": \"2\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"111\"}','069dea5c952f86fcfbe1032c61cc33adc557083a42187126b0b1e3425210bb66','e6a12c10631e66a5e7f060629f9b68882af1969b65fdc0bd8b2568ea0ca353fb'),(276,118,NULL,2,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 09:27:32','{\"id_mesa\": \"2\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"111\"}','e6a12c10631e66a5e7f060629f9b68882af1969b65fdc0bd8b2568ea0ca353fb','a7d67ad8b8574693a3837bf5958a77af6977dc4c4dd4669498abe665ada9157b'),(277,118,NULL,2,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 09:27:34','{\"id_mesa\": \"2\", \"id_docente\": \"111\", \"metodo\": \"DNI\", \"id_terminal\": \"2\", \"id_habilitacion\": \"28\"}','a7d67ad8b8574693a3837bf5958a77af6977dc4c4dd4669498abe665ada9157b','948fd7c853f20faf7936493490a74a8bd43463fd63bff0e6b997ca12ebbd20b2'),(278,NULL,111,2,'EMITIR_VOTO',NULL,NULL,'2026-11-25 09:27:39','{\"id_cargo\": \"2\"}','948fd7c853f20faf7936493490a74a8bd43463fd63bff0e6b997ca12ebbd20b2','2729060985b37366fec63dff95f673b6ab2b5634350345b05511d69b685d53ca'),(279,3,NULL,2,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 09:27:39','{\"id_mesa\": \"2\", \"id_terminal\": \"2\"}','2729060985b37366fec63dff95f673b6ab2b5634350345b05511d69b685d53ca','de142b7939b31c4fc25623f4ac7f49a799938a00eb62c3c7dccbaafa5eb5c20d'),(280,118,NULL,2,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 09:27:42','{\"id_mesa\": \"2\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"112\"}','de142b7939b31c4fc25623f4ac7f49a799938a00eb62c3c7dccbaafa5eb5c20d','ca35a8b44de763004920d1cd9e56a311e815651e4686182621f3d44527064203'),(281,118,NULL,2,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 09:27:44','{\"id_mesa\": \"2\", \"id_docente\": \"112\", \"metodo\": \"DNI\", \"id_terminal\": \"2\", \"id_habilitacion\": \"29\"}','ca35a8b44de763004920d1cd9e56a311e815651e4686182621f3d44527064203','1f3e40be02d63b3a45cbaf94aa5ba12ec5314c6c94345d501a254bf107a68443'),(282,NULL,112,2,'EMITIR_VOTO',NULL,NULL,'2026-11-25 09:27:48','{\"id_cargo\": \"2\"}','1f3e40be02d63b3a45cbaf94aa5ba12ec5314c6c94345d501a254bf107a68443','7caa758d604edcd71854cfb9332065fb3c35966229de01a060a40cabc120adff'),(283,3,NULL,2,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 09:27:48','{\"id_mesa\": \"2\", \"id_terminal\": \"2\"}','7caa758d604edcd71854cfb9332065fb3c35966229de01a060a40cabc120adff','2a8e0175df7de55510a08d87ea668402defa8f85c700558e9b35f14da468245a'),(284,118,NULL,2,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 09:27:56','{\"id_mesa\": \"2\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"113\"}','2a8e0175df7de55510a08d87ea668402defa8f85c700558e9b35f14da468245a','c9a266faaf4bc3d3b36c425ede0d17858ecb9e6f7d86c6ef155254e00a78d5b2'),(285,118,NULL,2,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 09:27:58','{\"id_mesa\": \"2\", \"id_docente\": \"113\", \"metodo\": \"DNI\", \"id_terminal\": \"2\", \"id_habilitacion\": \"30\"}','c9a266faaf4bc3d3b36c425ede0d17858ecb9e6f7d86c6ef155254e00a78d5b2','5472d27ad19eeae3f6ddc77a644e6745d3757a6b13f91d1e1995bf4a78774d07'),(286,NULL,113,2,'EMITIR_VOTO',NULL,NULL,'2026-11-25 09:28:02','{\"id_cargo\": \"2\"}','5472d27ad19eeae3f6ddc77a644e6745d3757a6b13f91d1e1995bf4a78774d07','284bf0cdd5385f7948a871574c8c08ee77772343a3b99c362d6b6c9ac1f9b588'),(287,3,NULL,2,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 09:28:02','{\"id_mesa\": \"2\", \"id_terminal\": \"2\"}','284bf0cdd5385f7948a871574c8c08ee77772343a3b99c362d6b6c9ac1f9b588','14049e936729fcad2c1d074b57f738092ea810bcd438df63ab7b290cb09fc449'),(288,118,NULL,2,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 09:28:06','{\"id_mesa\": \"2\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"114\"}','14049e936729fcad2c1d074b57f738092ea810bcd438df63ab7b290cb09fc449','1a07773043e10983ab3e1e00823ce7bb3ced10f321fb83334324c25c7ecdf638'),(289,118,NULL,2,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 09:28:07','{\"id_mesa\": \"2\", \"id_docente\": \"114\", \"metodo\": \"DNI\", \"id_terminal\": \"2\", \"id_habilitacion\": \"31\"}','1a07773043e10983ab3e1e00823ce7bb3ced10f321fb83334324c25c7ecdf638','888a30c6a99a277ae88039a0a86713122d44220b92372fec00b83aa0dc19edfa'),(290,NULL,114,2,'EMITIR_VOTO',NULL,NULL,'2026-11-25 09:28:12','{\"id_cargo\": \"2\"}','888a30c6a99a277ae88039a0a86713122d44220b92372fec00b83aa0dc19edfa','fb622461fe2d9461dfae3c81838721e1115b0c6eaa11a250f305e8f5eb5b0af9'),(291,3,NULL,2,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 09:28:12','{\"id_mesa\": \"2\", \"id_terminal\": \"2\"}','fb622461fe2d9461dfae3c81838721e1115b0c6eaa11a250f305e8f5eb5b0af9','9864b2beee8ed9d95c084361b9149f5c771736532c7f10cfcb40565572f15aa1'),(292,118,NULL,2,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 09:28:15','{\"id_mesa\": \"2\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"115\"}','9864b2beee8ed9d95c084361b9149f5c771736532c7f10cfcb40565572f15aa1','e83ab7340ddab0d2ff71e161d5a037811f1a29e3c542c544018657438f98b0aa'),(293,118,NULL,2,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 09:28:17','{\"id_mesa\": \"2\", \"id_docente\": \"115\", \"metodo\": \"DNI\", \"id_terminal\": \"2\", \"id_habilitacion\": \"32\"}','e83ab7340ddab0d2ff71e161d5a037811f1a29e3c542c544018657438f98b0aa','0635cff3755cb3d145341ecc1ec0af802a6e8e36d10599cca1ff6973b46f849b'),(294,NULL,115,2,'EMITIR_VOTO',NULL,NULL,'2026-11-25 09:28:21','{\"id_cargo\": \"2\"}','0635cff3755cb3d145341ecc1ec0af802a6e8e36d10599cca1ff6973b46f849b','6153c6023b43b9ade4f89e0027ac0d1b129856d8be7767110ad35f7871e30a0a'),(295,3,NULL,2,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 09:28:21','{\"id_mesa\": \"2\", \"id_terminal\": \"2\"}','6153c6023b43b9ade4f89e0027ac0d1b129856d8be7767110ad35f7871e30a0a','a65ae69d74e3c8eb095ccbc77d51cbfed03ac9ec71b2a6cf84e69ebcf9c74209'),(296,118,NULL,2,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 09:28:24','{\"id_mesa\": \"2\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"116\"}','a65ae69d74e3c8eb095ccbc77d51cbfed03ac9ec71b2a6cf84e69ebcf9c74209','97ee28e4acfcdb5eeaf6ce1a3c0bef4b678e65bede3a370656235648f6f2adfa'),(297,118,NULL,2,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 09:28:27','{\"id_mesa\": \"2\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"116\"}','97ee28e4acfcdb5eeaf6ce1a3c0bef4b678e65bede3a370656235648f6f2adfa','31b500a9277236c7979c6129ca38b290d8c8ba98c2eccdab4d77230751162b50'),(298,118,NULL,2,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 09:28:32','{\"id_mesa\": \"2\", \"id_docente\": \"116\", \"metodo\": \"DNI\", \"id_terminal\": \"2\", \"id_habilitacion\": \"33\"}','31b500a9277236c7979c6129ca38b290d8c8ba98c2eccdab4d77230751162b50','e0fd4640736ddd2bda3293ae8a0e8a6f0edb2be4c17826608ae9e9a4a17b7cbe'),(299,NULL,116,2,'EMITIR_VOTO',NULL,NULL,'2026-11-25 09:28:37','{\"id_cargo\": \"2\"}','e0fd4640736ddd2bda3293ae8a0e8a6f0edb2be4c17826608ae9e9a4a17b7cbe','099159f802a8e15f91538b149dfd3181bb4c8b8a5342ea9322c8e19557c4d6ac'),(300,3,NULL,2,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 09:28:37','{\"id_mesa\": \"2\", \"id_terminal\": \"2\"}','099159f802a8e15f91538b149dfd3181bb4c8b8a5342ea9322c8e19557c4d6ac','bd719f39aa2675a974f80577227d6ad92252c5532dd5846bb6634c86995e2673'),(301,118,NULL,2,'VERIFICAR_ELECTOR',NULL,NULL,'2026-11-25 09:28:42','{\"id_mesa\": \"2\", \"metodo\": \"DNI\", \"resultado\": \"APTO\", \"id_docente\": \"117\"}','bd719f39aa2675a974f80577227d6ad92252c5532dd5846bb6634c86995e2673','d7fab4117b1750d30fb378d80786838ac21a200af9c85d1563b0b10717b88c2f'),(302,118,NULL,2,'REGISTRAR_ASISTENCIA',NULL,NULL,'2026-11-25 09:28:43','{\"id_mesa\": \"2\", \"id_docente\": \"117\", \"metodo\": \"DNI\", \"id_terminal\": \"2\", \"id_habilitacion\": \"34\"}','d7fab4117b1750d30fb378d80786838ac21a200af9c85d1563b0b10717b88c2f','c25caae412cf7f66029b9bd6cb012c6abfe173927a05638a77dff30c2aed822a'),(303,NULL,117,2,'EMITIR_VOTO',NULL,NULL,'2026-11-25 09:28:47','{\"id_cargo\": \"2\"}','c25caae412cf7f66029b9bd6cb012c6abfe173927a05638a77dff30c2aed822a','90e131d15ddcfddd5974e0540bd5c38ada192ecd9bac08bd587469c1a98cd8a4'),(304,3,NULL,2,'LIBERAR_TERMINAL',NULL,NULL,'2026-11-25 09:28:47','{\"id_mesa\": \"2\", \"id_terminal\": \"2\"}','90e131d15ddcfddd5974e0540bd5c38ada192ecd9bac08bd587469c1a98cd8a4','5be00629e6c965776cd061a54c39bc6e83059844198f9dbb6cb1fb9c3f187107'),(305,118,NULL,2,'INCIDENCIA_MESA',NULL,NULL,'2026-11-25 09:29:05','{\"id_mesa\": \"2\", \"id_docente\": null, \"tipo\": \"FALLA_TERMINAL\"}','5be00629e6c965776cd061a54c39bc6e83059844198f9dbb6cb1fb9c3f187107','6aa6ce4f7b655c55d9f2d505784fc27cda467bae78982b941a7bb1f25beb57f6'),(306,118,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 15:05:36',NULL,'6aa6ce4f7b655c55d9f2d505784fc27cda467bae78982b941a7bb1f25beb57f6','7c3b5fcad3fa3f55a53abfd50890a30c64ef83d0b93e5706f49d82028eb1c75b'),(307,3,NULL,NULL,'LOGIN_FAILED','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 15:05:56',NULL,'7c3b5fcad3fa3f55a53abfd50890a30c64ef83d0b93e5706f49d82028eb1c75b','8a7df978a2b8f0b2e196ee1f2d46dac09c137b75f00c18ad85b44b9a2691986c'),(308,3,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 15:05:58',NULL,'8a7df978a2b8f0b2e196ee1f2d46dac09c137b75f00c18ad85b44b9a2691986c','232339f4c776e376bee1541b9af2f6d79d326352bcb1c53c5f544edf52463026'),(309,118,NULL,2,'CERRAR_SUFRAGIO',NULL,NULL,'2026-11-25 15:07:53','{\"id_mesa\": \"2\", \"votaron\": \"17\", \"electores\": \"17\", \"anticipado\": \"0\"}','232339f4c776e376bee1541b9af2f6d79d326352bcb1c53c5f544edf52463026','062830415fb7332f490e5ab064faf18653725d7cc155310b86a41479e8d8ea29'),(310,118,NULL,2,'MARCAR_NO_VOTO',NULL,NULL,'2026-11-25 15:08:01','{\"id_mesa\": \"2\", \"marcados\": \"0\"}','062830415fb7332f490e5ab064faf18653725d7cc155310b86a41479e8d8ea29','176577db574e5ea06a87ea4a41168f644b092f7a23722e95031b81933d34db48'),(311,118,NULL,2,'EMITIR_ACTA_SUFRAGIO',NULL,NULL,'2026-11-25 15:08:38','{\"id_mesa\": \"2\", \"id_acta\": \"5\", \"votaron\": \"17\"}','176577db574e5ea06a87ea4a41168f644b092f7a23722e95031b81933d34db48','68472ae05e16ab127048a851add0d89610cd4ab04867dae86e699c0f3b0ba8ba'),(312,118,NULL,2,'CONTAR_CEDULAS',NULL,NULL,'2026-11-25 15:09:16','{\"id_mesa\": \"2\", \"cedulas\": \"17\", \"votantes\": \"17\", \"sobrantes_destruidas\": \"0\", \"faltantes\": \"0\"}','68472ae05e16ab127048a851add0d89610cd4ab04867dae86e699c0f3b0ba8ba','f24b2a579ea26f519107b3336803dc0860397321f6947addd72e5fc95575be9e'),(313,118,NULL,2,'REGISTRAR_CONTEO_ESCRUTINIO',NULL,NULL,'2026-11-25 15:09:37','{\"id_mesa\": \"2\", \"conteo\": 1, \"cuadra\": \"0\", \"total_cuadra\": \"1\"}','f24b2a579ea26f519107b3336803dc0860397321f6947addd72e5fc95575be9e','84ba00f37a202ce60163f5aa3d9a9bdbf958656d16c11eb5e03065a8294ddec0'),(314,118,NULL,2,'REGISTRAR_CONTEO_ESCRUTINIO',NULL,NULL,'2026-11-25 15:11:28','{\"id_mesa\": \"2\", \"conteo\": 2, \"cuadra\": \"1\", \"total_cuadra\": \"1\"}','84ba00f37a202ce60163f5aa3d9a9bdbf958656d16c11eb5e03065a8294ddec0','4c38ccb0ec2662b19e415951dee2694799426547870ba98d92dd3c189431aadb'),(315,118,NULL,2,'EMITIR_ACTA_ESCRUTINIO',NULL,NULL,'2026-11-25 15:11:38','{\"id_mesa\": \"2\", \"id_acta\": \"6\", \"observada\": \"0\", \"prevalece_fisica\": \"0\", \"impugnados\": \"0\"}','4c38ccb0ec2662b19e415951dee2694799426547870ba98d92dd3c189431aadb','568567289c18242e01300913880a964db2853874063db42e71c0bcff47c9cd47'),(316,118,NULL,2,'ENTREGAR_ACTAS',NULL,NULL,'2026-11-25 15:12:39','{\"id_mesa\": \"2\", \"recibido_por\": \"lucano\", \"codigo\": \"62A8894A7B9C\"}','568567289c18242e01300913880a964db2853874063db42e71c0bcff47c9cd47','e0bd8dd2e8afa794c09072c7fea7694706c41f48dafce0078c17e43c7e1c8882'),(317,3,NULL,2,'CAMBIO_ESTADO_PROCESO',NULL,NULL,'2026-11-25 15:15:16','{\"anterior\": \"VOTACION\", \"nuevo\": \"CERRADO\"}','e0bd8dd2e8afa794c09072c7fea7694706c41f48dafce0078c17e43c7e1c8882','20bbf97b0dba6a79c7e060838a67f40358e29a332f62498f299b97b9183b6655'),(318,3,NULL,2,'INSTALAR_SESION_COMPUTO',NULL,NULL,'2026-11-25 15:16:27','{\"lugar\": \"Sala de sesiones del CEUNP\", \"miembros\": \"5\", \"personeros\": \"0\"}','20bbf97b0dba6a79c7e060838a67f40358e29a332f62498f299b97b9183b6655','e4df28ef795b490ccfb44dc82ad320b4d96e9b436df7db7616234047644017eb'),(319,3,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 15:20:31',NULL,'e4df28ef795b490ccfb44dc82ad320b4d96e9b436df7db7616234047644017eb','c01de9faa19ec694b50acfaf3bcda3c3b6a9b7af2236016b389bd306cb1826fc'),(320,3,NULL,2,'REGISTRAR_VOTOS_ESTUDIANTILES',NULL,NULL,'2026-11-25 15:21:51','{\"id_cargo\": \"2\", \"id_lista\": \"5\", \"votos_estudiantes\": \"180\"}','c01de9faa19ec694b50acfaf3bcda3c3b6a9b7af2236016b389bd306cb1826fc','d7e8008a5c8e21cbde05a80e543d939a00c518e4c0481b15912806af98bdeb2d'),(321,3,NULL,2,'REGISTRAR_VOTOS_ESTUDIANTILES',NULL,NULL,'2026-11-25 15:21:51','{\"id_cargo\": \"2\", \"id_lista\": \"4\", \"votos_estudiantes\": \"320\"}','d7e8008a5c8e21cbde05a80e543d939a00c518e4c0481b15912806af98bdeb2d','d6812093db75b15de842f5e54069a0d28374aace16d76554bcc564416c8d848b'),(322,3,NULL,2,'REGISTRAR_VOTOS_ESTUDIANTILES',NULL,NULL,'2026-11-25 15:22:17','{\"id_cargo\": \"2\", \"id_lista\": \"5\", \"votos_estudiantes\": \"200\"}','d6812093db75b15de842f5e54069a0d28374aace16d76554bcc564416c8d848b','7819f413f4c9715b2e637c66bb73859c0cdc20e0695c835bf6d55b6859e7e9d4'),(323,3,NULL,2,'REGISTRAR_VOTOS_ESTUDIANTILES',NULL,NULL,'2026-11-25 15:22:17','{\"id_cargo\": \"2\", \"id_lista\": \"4\", \"votos_estudiantes\": \"320\"}','7819f413f4c9715b2e637c66bb73859c0cdc20e0695c835bf6d55b6859e7e9d4','89ef339922f653ebcb0d6221634289a2c3aa61dd67c23fc4cbcec720f0866657'),(324,3,NULL,2,'REGISTRAR_VOTOS_ESTUDIANTILES',NULL,NULL,'2026-11-25 15:22:24','{\"id_cargo\": \"2\", \"id_lista\": \"5\", \"votos_estudiantes\": \"180\"}','89ef339922f653ebcb0d6221634289a2c3aa61dd67c23fc4cbcec720f0866657','384275821094a8eea515c0564dcdcb01eee3343fb7bcb371f78eb1adc5e0eb6f'),(325,3,NULL,2,'REGISTRAR_VOTOS_ESTUDIANTILES',NULL,NULL,'2026-11-25 15:22:24','{\"id_cargo\": \"2\", \"id_lista\": \"4\", \"votos_estudiantes\": \"320\"}','384275821094a8eea515c0564dcdcb01eee3343fb7bcb371f78eb1adc5e0eb6f','68c692b291eb8393d81d2225d239fb8e3f2649c44c4c2b90020d36a3f534da4b'),(326,3,NULL,2,'REGISTRAR_VOTOS_ESTUDIANTILES',NULL,NULL,'2026-11-25 15:22:26','{\"id_cargo\": \"2\", \"id_lista\": \"5\", \"votos_estudiantes\": \"180\"}','68c692b291eb8393d81d2225d239fb8e3f2649c44c4c2b90020d36a3f534da4b','16f43c3c1f2ff57b63ad6b2fd2b0ba697b4b9bc9c4f079cfffb7cc8812307213'),(327,3,NULL,2,'REGISTRAR_VOTOS_ESTUDIANTILES',NULL,NULL,'2026-11-25 15:22:27','{\"id_cargo\": \"2\", \"id_lista\": \"4\", \"votos_estudiantes\": \"320\"}','16f43c3c1f2ff57b63ad6b2fd2b0ba697b4b9bc9c4f079cfffb7cc8812307213','da8456ce6b9e6eb96a546cffa53128adc4f4f71359c9283fb219921ff0f37ac8'),(328,3,NULL,2,'COMPUTAR_RESULTADOS',NULL,NULL,'2026-11-25 15:24:29','{\"cus\": \"CUS14\", \"mesas_computadas\": \"1\", \"cargos_con_quorum\": \"1\", \"resultado\": \"VALIDA\"}','da8456ce6b9e6eb96a546cffa53128adc4f4f71359c9283fb219921ff0f37ac8','aaf48c69eb8b50a726116c8f32b9777e82fb504163bdfa64678ca847e65ce529'),(329,3,NULL,2,'PROCLAMAR_RESULTADOS',NULL,NULL,'2026-11-25 15:26:45','{\"resolucion\": \"RES-CEUNP-2027 RE4FORLITE\", \"cargos_proclamados\": \"1\"}','aaf48c69eb8b50a726116c8f32b9777e82fb504163bdfa64678ca847e65ce529','aabd3c4ae4080f8765abeb2268d9e89654653acb67c8ce430a13a19635630733'),(330,3,NULL,2,'PUBLICAR_RESULTADOS',NULL,NULL,'2026-11-25 15:27:47','{\"estado_proceso\": \"FINALIZADO\"}','aabd3c4ae4080f8765abeb2268d9e89654653acb67c8ce430a13a19635630733','39b5ce6362e332ebff2be875e80829d3624a309fe9a284d302864eb394235f78'),(331,3,NULL,2,'GENERAR_MULTAS',NULL,NULL,'2026-11-25 15:04:52','{\"omisos_votacion\": \"0\", \"omisos_mesa\": \"3\", \"monto_total\": \"463.50\", \"uit\": \"5150.00\", \"retiradas\": \"0\"}','39b5ce6362e332ebff2be875e80829d3624a309fe9a284d302864eb394235f78','d27818c999b9a41ecdf6554baa3796201f2d5a8cca4fb3330499b693d00687d7'),(332,1,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 15:05:14',NULL,'d27818c999b9a41ecdf6554baa3796201f2d5a8cca4fb3330499b693d00687d7','356019f5dccf705edc8c54b8f49da0d2162f5a02af38e71197e90ab1c0ab3311'),(333,110,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 15:05:46',NULL,'356019f5dccf705edc8c54b8f49da0d2162f5a02af38e71197e90ab1c0ab3311','daa9739e7d44c9f87dfc2a0da8f08b1b4c86b7828cdbe2ccb4efabc26df2d555'),(334,3,NULL,2,'EMITIR_RESOLUCION_MULTAS',NULL,NULL,'2026-11-25 15:07:23','{\"resolucion\": \"378-2026\", \"omisos_votacion\": \"0\", \"omisos_mesa\": \"3\", \"monto_total\": \"463.50\"}','daa9739e7d44c9f87dfc2a0da8f08b1b4c86b7828cdbe2ccb4efabc26df2d555','522da834e8e5ab3144540d8e91272fcba9d02d12f5d61518db8beb3f0e5bcc66'),(335,3,NULL,2,'NOTIFICAR_MULTAS',NULL,NULL,'2026-11-25 15:08:20','{\"id_multa\": null, \"notificadas\": \"3\", \"medio\": \"CORREO_INSTITUCIONAL\", \"documento\": \"correo57\"}','522da834e8e5ab3144540d8e91272fcba9d02d12f5d61518db8beb3f0e5bcc66','d3f539a8712cffe316c62bdab3fb81ac473e7200e7d28bd3d936de64aeb4ad38'),(336,3,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 15:24:32',NULL,'d3f539a8712cffe316c62bdab3fb81ac473e7200e7d28bd3d936de64aeb4ad38','74ff9169162d57be6ba4d0047a48f61e688defe7e5bb3aa29185fec0acc1823c'),(337,1,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 18:12:38',NULL,'74ff9169162d57be6ba4d0047a48f61e688defe7e5bb3aa29185fec0acc1823c','abe8e62cc2cff0dd45781bd3d414a10e6ae08c320e6288c97f69fef4e9b6342d'),(338,3,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 18:12:53',NULL,'abe8e62cc2cff0dd45781bd3d414a10e6ae08c320e6288c97f69fef4e9b6342d','ebda145e0653951fd4f7bfe695aef76ab0906cae4fea7ea89567d8839033bcc3'),(339,1,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 18:15:54',NULL,'ebda145e0653951fd4f7bfe695aef76ab0906cae4fea7ea89567d8839033bcc3','0248eff5b7d305cb1833fff8e20decd71cff7c143b4c02b79c4df4d0182d2827'),(340,107,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 18:17:00',NULL,'0248eff5b7d305cb1833fff8e20decd71cff7c143b4c02b79c4df4d0182d2827','2820e9a9d1acdd5625ba8150c012d686706c4387403cbbfd851a5e1919cf75c6'),(341,3,104,2,'REGISTRAR_PAGO_MULTA',NULL,NULL,'2026-11-25 18:21:17','{\"id_multa\": \"2\", \"recibo\": \"0003443\"}','2820e9a9d1acdd5625ba8150c012d686706c4387403cbbfd851a5e1919cf75c6','5ebc4e6f6a1f6a5d0d03e05c9d1ae4fb972283cf2559fd1c097b7e4c4eed5d44'),(342,3,107,2,'DENEGAR_JUSTIFICACION',NULL,NULL,'2026-11-25 18:23:48','{\"id_multa\": \"3\", \"id_justificacion\": \"1\", \"causal\": \"SALUD\", \"resolucion\": \"4883 - CEUNP\"}','5ebc4e6f6a1f6a5d0d03e05c9d1ae4fb972283cf2559fd1c097b7e4c4eed5d44','362f1042beefb8a001de383f98bd024187d8a3f820000372f2355fe396059d81'),(343,3,114,2,'REGISTRAR_PAGO_MULTA',NULL,NULL,'2026-11-25 18:24:12','{\"id_multa\": \"4\", \"recibo\": \"00203-3344\"}','362f1042beefb8a001de383f98bd024187d8a3f820000372f2355fe396059d81','087dc1ee8ad3ead4d55bd68cc2fa70aa216c11c3759b7049eebb500a9dca0fcb'),(344,3,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 19:29:54',NULL,'087dc1ee8ad3ead4d55bd68cc2fa70aa216c11c3759b7049eebb500a9dca0fcb','d39edb3926abc8e67a20187b6877aa5dfe675002095cd5d4f004e63864af5946'),(345,3,107,2,'JUSTIFICAR_MULTA',NULL,NULL,'2026-11-25 19:33:28','{\"id_multa\": \"3\", \"id_justificacion\": \"2\", \"causal\": \"SALUD\", \"resolucion\": \"089-CEUNP\"}','d39edb3926abc8e67a20187b6877aa5dfe675002095cd5d4f004e63864af5946','bc5e91c45ebb00727d000f35818aa6838547d45eb609e1b61827beec2ce4bade'),(346,3,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 19:43:56',NULL,'bc5e91c45ebb00727d000f35818aa6838547d45eb609e1b61827beec2ce4bade','146f91920c0e519f64161fca00acaeefdedb55b85b9f6b5ca42101f04b85ebb5'),(347,3,NULL,1,'GENERAR_MULTAS',NULL,NULL,'2026-11-25 19:44:40','{\"omisos_votacion\": \"1\", \"omisos_mesa\": \"0\", \"monto_total\": \"128.75\", \"uit\": \"5150.00\", \"retiradas\": \"0\"}','146f91920c0e519f64161fca00acaeefdedb55b85b9f6b5ca42101f04b85ebb5','80c5e8ea8268cc97291c923dba2da1f9342d1a0747ee42a7cef97772919cfff7'),(348,3,NULL,1,'EMITIR_RESOLUCION_MULTAS',NULL,NULL,'2026-11-25 19:45:06','{\"resolucion\": \"394893- CEUNP\", \"omisos_votacion\": \"1\", \"omisos_mesa\": \"0\", \"monto_total\": \"128.75\"}','80c5e8ea8268cc97291c923dba2da1f9342d1a0747ee42a7cef97772919cfff7','e6c9fae4e5dc7cf797ea7dceb1db0ba00340b1fdf97aed01ec747e809844163e'),(349,3,NULL,1,'NOTIFICAR_MULTAS',NULL,NULL,'2026-11-25 19:45:19','{\"id_multa\": null, \"notificadas\": \"1\", \"medio\": \"CORREO_INSTITUCIONAL\", \"documento\": \"xxxx\"}','e6c9fae4e5dc7cf797ea7dceb1db0ba00340b1fdf97aed01ec747e809844163e','e6adcc392da5e578c85455050da56fc8221b0a118002a3333292be74ca3df91d'),(350,3,NULL,NULL,'LOGIN_SUCCESS','0:0:0:0:0:0:0:1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-25 20:33:22',NULL,'e6adcc392da5e578c85455050da56fc8221b0a118002a3333292be74ca3df91d','e5d96ccaae93efd8650675833b89634b3ed76c2c33d5eeae3282657fbca1499c');
/*!40000 ALTER TABLE `log_auditoria` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_log_bi BEFORE INSERT ON log_auditoria
FOR EACH ROW
BEGIN
  DECLARE v_prev CHAR(64) DEFAULT NULL;

  IF NEW.fecha_hora IS NULL THEN
    SET NEW.fecha_hora = NOW();
  END IF;
  SELECT ultimo_hash INTO v_prev FROM bitacora_cadena WHERE id_cadena = 1 FOR UPDATE;
  SET NEW.hash_anterior = COALESCE(v_prev, REPEAT('0', 64));
  SET NEW.hash_registro = fn_hash_bitacora(NEW.hash_anterior, NEW.id_usuario, NEW.id_docente, NEW.id_proceso,
                                           NEW.accion, NEW.ip_origen, NEW.user_agent, NEW.fecha_hora, NEW.detalle_json);
  INSERT IGNORE INTO bitacora_cadena (id_cadena, ultimo_hash, total_registros, fecha_inicio, fecha_actualizacion)
  VALUES (1, NEW.hash_registro, 1, NOW(), NOW())
  ON DUPLICATE KEY UPDATE ultimo_hash = NEW.hash_registro, total_registros = total_registros + 1,
                          fecha_actualizacion = NOW();
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_log_ai AFTER INSERT ON log_auditoria
FOR EACH ROW
BEGIN
  UPDATE bitacora_cadena SET ultimo_id_log = NEW.id_log WHERE id_cadena = 1;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_log_bu BEFORE UPDATE ON log_auditoria
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La bitacora de auditoria es inmutable.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_log_bd BEFORE DELETE ON log_auditoria
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La bitacora de auditoria es inmutable.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

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
  `semilla_sorteo` varchar(128) NOT NULL DEFAULT 'PENDIENTE',
  `fecha_sorteo` datetime DEFAULT NULL,
  `estado` enum('PENDIENTE','INSTALADA','CERRADA','ANULADA','NO_INSTALADA') NOT NULL DEFAULT 'PENDIENTE',
  `hora_instalacion` datetime DEFAULT NULL,
  `hora_cierre` datetime DEFAULT NULL,
  `total_electores` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id_mesa`),
  UNIQUE KEY `uq_mesa_proceso_numero` (`id_proceso`,`numero_mesa`),
  CONSTRAINT `fk_mesa_proceso` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mesa_electoral`
--

LOCK TABLES `mesa_electoral` WRITE;
/*!40000 ALTER TABLE `mesa_electoral` DISABLE KEYS */;
INSERT INTO `mesa_electoral` VALUES (1,1,'001','Biblioteca Central','48a066c39b3e7b4d1b685215150aa5bc41254ea451f2e33d766439b89c90a515','2026-10-20 11:43:47','CERRADA','2026-11-25 09:15:57','2026-11-25 15:28:56',17),(2,2,'001','Biblioteca Central','9a68ec22b93031aadc931ce9499c7709e5bdb1740676a6dbd4ffac0983d57319','2026-10-15 14:07:27','CERRADA','2026-11-25 09:17:30','2026-11-25 15:07:52',17);
/*!40000 ALTER TABLE `mesa_electoral` ENABLE KEYS */;
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
  `orden_sorteo` int(11) DEFAULT NULL,
  `asistio` tinyint(1) DEFAULT NULL,
  `hora_acreditacion` datetime DEFAULT NULL COMMENT 'CUS08: hora de llegada',
  `metodo_acreditacion` enum('QR','DNI') DEFAULT NULL COMMENT 'CUS08: credencial QR o DNI',
  `rol_instalacion` enum('PRESIDENTE','SECRETARIO','VOCAL') DEFAULT NULL COMMENT 'CUS08: cargo ejercido',
  `qr_credencial_hash` char(64) DEFAULT NULL,
  `rol_titular` varchar(12) GENERATED ALWAYS AS (if(`titular` = 1,`rol`,NULL)) STORED,
  PRIMARY KEY (`id_mesa`,`id_docente`),
  UNIQUE KEY `uq_miembro_rol_titular` (`id_mesa`,`rol_titular`),
  UNIQUE KEY `uq_miembro_qr` (`qr_credencial_hash`),
  KEY `fk_miembro_docente` (`id_docente`),
  CONSTRAINT `fk_miembro_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`),
  CONSTRAINT `fk_miembro_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`) ON DELETE CASCADE,
  CONSTRAINT `chk_miembro_rol` CHECK (`titular` = 1 and `rol` in ('PRESIDENTE','SECRETARIO','VOCAL') or `titular` = 0 and `rol` = 'SUPLENTE')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `miembro_mesa`
--

LOCK TABLES `miembro_mesa` WRITE;
/*!40000 ALTER TABLE `miembro_mesa` DISABLE KEYS */;
INSERT INTO `miembro_mesa` VALUES (1,101,'SUPLENTE',0,6,1,'2026-11-25 09:03:23','DNI',NULL,'31d3894fc87055e8670b33a1047e4f5b50133001c883d68bcd1583975a103dc2',NULL),(1,107,'PRESIDENTE',1,1,1,'2026-11-25 09:02:51','DNI','PRESIDENTE','cfd8309b91feb7ba1b1b73f2b6f68c9fddc6e487264747d350dc49c00cc1f93f','PRESIDENTE'),(1,108,'SECRETARIO',1,2,1,'2026-11-25 09:03:00','DNI','SECRETARIO','aadcecbf47471b5ed272115b093ae3f1573acc050b81ccdebdf5bca084512e63','SECRETARIO'),(1,111,'VOCAL',1,3,1,'2026-11-25 09:03:07','DNI','VOCAL','9d095b8bfec3a625957352ea84b343713e59858ded35c2799c98da214596336a','VOCAL'),(1,115,'SUPLENTE',0,5,1,'2026-11-25 09:03:19','DNI',NULL,'3cf40da250ff737b1bdb6af8cb63e07cbfae7eb66bd04b23aaf4deaaf38f3e74',NULL),(1,117,'SUPLENTE',0,4,1,'2026-11-25 09:03:13','DNI',NULL,'06f448168bec94c5ab2bad2c08e88ee9351aab6d5e7063ffe486c89103e16b33',NULL),(2,104,'SUPLENTE',0,6,0,NULL,NULL,NULL,'9ecd48b63ad07868c090a83d2f0fe0d792e997b6a3b532c83e9d0b6ae27b7211',NULL),(2,107,'SUPLENTE',0,4,0,NULL,NULL,NULL,'31807d9a38af501dc58f012c55e6a4a1990f3236fa9f318176c618dc3c2f1ab8',NULL),(2,110,'VOCAL',1,3,1,'2026-11-25 09:15:49','DNI','VOCAL','09a8514542924ae05ac5e943abd1b74e96d0de2c5e1b7517a4df6cc12d5b8fe8','VOCAL'),(2,114,'SUPLENTE',0,5,0,NULL,NULL,NULL,'a40720a19cc3d746e294dacdf7cdd85d697a3eb0c9b02f701053a9d1731cb048',NULL),(2,115,'PRESIDENTE',1,1,1,'2026-11-25 09:10:15','DNI','PRESIDENTE','941fc18ae60b2241ac887cfc986ff7f7ea383a541658c7c3efbd6626bc016036','PRESIDENTE'),(2,117,'SECRETARIO',1,2,1,'2026-11-25 09:15:42','DNI','SECRETARIO','726ed41936dcdfa62af44732a8d214486f154fb4454539d29c9c6206759f3abb','SECRETARIO');
/*!40000 ALTER TABLE `miembro_mesa` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_miembro_mesa_bi BEFORE INSERT ON miembro_mesa
FOR EACH ROW
BEGIN
  DECLARE v_proceso INT DEFAULT NULL;
  SELECT id_proceso INTO v_proceso FROM mesa_electoral WHERE id_mesa = NEW.id_mesa;

  IF EXISTS (SELECT 1
               FROM miembro_mesa mm
               JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
              WHERE mm.id_docente = NEW.id_docente
                AND m.id_proceso = v_proceso
                AND mm.id_mesa <> NEW.id_mesa) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El docente ya es miembro de otra mesa en este proceso.';
  END IF;

  IF EXISTS (SELECT 1
               FROM candidato ca
               JOIN lista_electoral l ON l.id_lista = ca.id_lista
               JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
              WHERE ca.id_docente = NEW.id_docente
                AND c.id_proceso = v_proceso
                AND ca.estado_validacion <> 'EXCLUIDO') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN20: un candidato no puede ser miembro de mesa.';
  END IF;

  IF EXISTS (SELECT 1
               FROM personero p
               JOIN lista_electoral l ON l.id_lista = p.id_lista
               JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
              WHERE p.id_docente = NEW.id_docente
                AND c.id_proceso = v_proceso
                AND p.estado_acreditacion <> 'REVOCADO') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN20: un personero no puede ser miembro de mesa.';
  END IF;

  IF fn_tiene_cargo_excluyente(NEW.id_docente) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN20: una autoridad vigente no puede ser miembro de mesa.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `multa`
--

DROP TABLE IF EXISTS `multa`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `multa` (
  `id_multa` int(11) NOT NULL AUTO_INCREMENT,
  `id_docente` int(11) NOT NULL,
  `id_proceso` int(11) NOT NULL,
  `motivo` enum('OMISO_VOTACION','OMISO_MESA') NOT NULL,
  `id_mesa` int(11) DEFAULT NULL COMMENT 'CUS16: mesa del elector (OMISO_VOTACION) o de la que era miembro (OMISO_MESA)',
  `rol_mesa` varchar(12) DEFAULT NULL COMMENT 'CUS16: cargo del miembro titular que no asistió',
  `asistio_sin_votar` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'CUS16: asistió a la mesa y no votó (CUS10 A3, Disp. Final 5.ª)',
  `uit_referencia` decimal(10,2) NOT NULL,
  `porcentaje_uit` decimal(5,2) NOT NULL,
  `monto` decimal(10,2) NOT NULL,
  `estado_pago` enum('PENDIENTE','PAGADA','EXONERADA','JUSTIFICADA') NOT NULL DEFAULT 'PENDIENTE',
  `fecha_generacion` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_pago` datetime DEFAULT NULL,
  `fecha_notificacion` datetime DEFAULT NULL COMMENT 'CUS16: notificación de la multa al docente',
  `medio_notificacion` enum('CORREO_INSTITUCIONAL','CEDULA_PERSONAL','PORTAL_ELECTORAL') DEFAULT NULL,
  `documento_notificacion` varchar(80) DEFAULT NULL COMMENT 'CUS16: N.º de cédula, oficio o correo',
  `numero_recibo` varchar(40) DEFAULT NULL COMMENT 'CUS16: recibo de pago (el sistema no cobra la multa)',
  `observacion` varchar(300) DEFAULT NULL,
  `fecha_actualizacion` datetime DEFAULT NULL,
  `id_usuario_actualizacion` int(11) DEFAULT NULL,
  PRIMARY KEY (`id_multa`),
  UNIQUE KEY `uq_multa` (`id_docente`,`id_proceso`,`motivo`),
  KEY `ix_multa_estado` (`estado_pago`),
  KEY `fk_multa_proceso` (`id_proceso`),
  CONSTRAINT `fk_multa_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`),
  CONSTRAINT `fk_multa_proceso` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`),
  CONSTRAINT `chk_multa_monto` CHECK (`monto` >= 0)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `multa`
--

LOCK TABLES `multa` WRITE;
/*!40000 ALTER TABLE `multa` DISABLE KEYS */;
INSERT INTO `multa` VALUES (1,101,1,'OMISO_VOTACION',1,NULL,1,5150.00,2.50,128.75,'PENDIENTE','2026-11-25 19:44:40',NULL,'2026-11-25 19:45:00','CORREO_INSTITUCIONAL','xxxx',NULL,NULL,'2026-11-25 19:45:19',3),(2,104,2,'OMISO_MESA',2,'SUPLENTE',0,5150.00,3.00,154.50,'PAGADA','2026-11-25 15:04:52','2026-11-25 18:20:00','2026-11-25 15:07:00','CORREO_INSTITUCIONAL','correo57','0003443','pago su multa completo','2026-11-25 18:21:17',3),(3,107,2,'OMISO_MESA',2,'SUPLENTE',0,5150.00,3.00,154.50,'JUSTIFICADA','2026-11-25 15:04:52',NULL,'2026-11-25 15:07:00','CORREO_INSTITUCIONAL','correo57',NULL,'Justificada por Resolución 089-CEUNP.','2026-11-25 19:33:28',3),(4,114,2,'OMISO_MESA',2,'SUPLENTE',0,5150.00,3.00,154.50,'PAGADA','2026-11-25 15:04:52','2026-11-25 18:23:00','2026-11-25 15:07:00','CORREO_INSTITUCIONAL','correo57','00203-3344','ninguna','2026-11-25 18:24:12',3);
/*!40000 ALTER TABLE `multa` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_multa_bi_cus16 BEFORE INSERT ON multa
FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM reporte_multas WHERE id_proceso = NEW.id_proceso AND estado = 'RESUELTO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: las multas del proceso ya fueron determinadas por resolución del CEUNP.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_multa_bu_cus16 BEFORE UPDATE ON multa
FOR EACH ROW
BEGIN
  DECLARE v_resuelto INT DEFAULT 0;
  SET v_resuelto = EXISTS (SELECT 1 FROM reporte_multas WHERE id_proceso = OLD.id_proceso AND estado = 'RESUELTO');
  IF NOT (NEW.id_docente <=> OLD.id_docente) OR NOT (NEW.id_proceso <=> OLD.id_proceso) OR NOT (NEW.motivo <=> OLD.motivo) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: el docente, el proceso y el motivo de la multa no se modifican.';
  END IF;
  IF v_resuelto = 1 AND (NOT (NEW.uit_referencia <=> OLD.uit_referencia) OR NOT (NEW.porcentaje_uit <=> OLD.porcentaje_uit)
                         OR NOT (NEW.monto <=> OLD.monto) OR NOT (NEW.id_mesa <=> OLD.id_mesa)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: la multa determinada por resolución no cambia de monto.';
  END IF;
  IF NOT (NEW.estado_pago <=> OLD.estado_pago) THEN
    IF v_resuelto = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF103: la multa se paga o se justifica después de la resolución del CEUNP que la determina.';
    END IF;
    IF OLD.estado_pago <> 'PENDIENTE' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF106: el pago, la justificación o la exoneración registrados no se revierten.';
    END IF;
  END IF;
  IF OLD.fecha_notificacion IS NOT NULL AND (NOT (NEW.fecha_notificacion <=> OLD.fecha_notificacion)
       OR NOT (NEW.medio_notificacion <=> OLD.medio_notificacion) OR NOT (NEW.documento_notificacion <=> OLD.documento_notificacion)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: la notificación registrada no se modifica.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_multa_bd_cus16 BEFORE DELETE ON multa
FOR EACH ROW
BEGIN
  IF NOT (@cus16_regenerar <=> OLD.id_proceso) OR OLD.estado_pago <> 'PENDIENTE'
     OR EXISTS (SELECT 1 FROM reporte_multas WHERE id_proceso = OLD.id_proceso AND estado = 'RESUELTO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: una multa no se elimina; si procede, se justifica o se exonera (RF106).';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `multa_justificacion`
--

DROP TABLE IF EXISTS `multa_justificacion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `multa_justificacion` (
  `id_justificacion` int(11) NOT NULL AUTO_INCREMENT,
  `id_multa` int(11) NOT NULL,
  `tipo` enum('JUSTIFICACION','EXONERACION') NOT NULL,
  `causal` enum('SALUD','DUELO','COMISION_SERVICIO','LICENCIA','CASO_FORTUITO','FALLECIMIENTO','ERROR_PADRON','OTRA') NOT NULL,
  `sustento` varchar(1000) NOT NULL,
  `documento` varchar(150) DEFAULT NULL,
  `fecha_presentacion` datetime NOT NULL,
  `decision` enum('ADMITIDA','DENEGADA') NOT NULL,
  `fundamento` varchar(1000) NOT NULL,
  `numero_resolucion` varchar(40) NOT NULL,
  `miembros_pleno` tinyint(4) NOT NULL,
  `fecha_resolucion` datetime NOT NULL,
  `id_usuario` int(11) DEFAULT NULL,
  `justificacion_unica` int(11) GENERATED ALWAYS AS (if(`tipo` = 'JUSTIFICACION',`id_multa`,NULL)) STORED,
  `admitida_unica` int(11) GENERATED ALWAYS AS (if(`decision` = 'ADMITIDA',`id_multa`,NULL)) STORED,
  PRIMARY KEY (`id_justificacion`),
  UNIQUE KEY `uq_mjust_resolucion` (`numero_resolucion`),
  UNIQUE KEY `uq_mjust_justificacion` (`justificacion_unica`),
  UNIQUE KEY `uq_mjust_admitida` (`admitida_unica`),
  KEY `ix_mjust_multa` (`id_multa`),
  KEY `fk_mjust_usuario` (`id_usuario`),
  CONSTRAINT `fk_mjust_multa` FOREIGN KEY (`id_multa`) REFERENCES `multa` (`id_multa`),
  CONSTRAINT `fk_mjust_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `chk_mjust_exoneracion` CHECK (`tipo` = 'JUSTIFICACION' or `decision` = 'ADMITIDA')
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `multa_justificacion`
--

LOCK TABLES `multa_justificacion` WRITE;
/*!40000 ALTER TABLE `multa_justificacion` DISABLE KEYS */;
INSERT INTO `multa_justificacion` VALUES (2,3,'JUSTIFICACION','SALUD','Tuvo un accidente de transito y no pudo asistir','032-34478','2026-11-25 19:30:00','ADMITIDA','El certificado admite la justificacion','089-CEUNP',5,'2026-11-25 19:33:28',3,3,3);
/*!40000 ALTER TABLE `multa_justificacion` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_mjust_bu BEFORE UPDATE ON multa_justificacion
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: la decisión del CEUNP sobre el descargo es inapelable.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_mjust_bd BEFORE DELETE ON multa_justificacion
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el descargo resuelto no se elimina.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `nulidad_comunicacion`
--

DROP TABLE IF EXISTS `nulidad_comunicacion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nulidad_comunicacion` (
  `id_nulidad` int(11) NOT NULL,
  `destinatario` enum('SUNEDU','ASAMBLEA_UNIVERSITARIA','CONSEJO_UNIVERSITARIO','PORTAL','EL_PERUANO') NOT NULL,
  `documento` varchar(80) NOT NULL,
  `fecha_envio` datetime NOT NULL,
  `observacion` varchar(500) DEFAULT NULL,
  `fecha_registro` datetime NOT NULL DEFAULT current_timestamp(),
  `id_usuario` int(11) DEFAULT NULL,
  PRIMARY KEY (`id_nulidad`,`destinatario`),
  KEY `fk_ncom_usuario` (`id_usuario`),
  CONSTRAINT `fk_ncom_nulidad` FOREIGN KEY (`id_nulidad`) REFERENCES `nulidad_electoral` (`id_nulidad`),
  CONSTRAINT `fk_ncom_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `nulidad_comunicacion`
--

LOCK TABLES `nulidad_comunicacion` WRITE;
/*!40000 ALTER TABLE `nulidad_comunicacion` DISABLE KEYS */;
/*!40000 ALTER TABLE `nulidad_comunicacion` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_ncom_bu BEFORE UPDATE ON nulidad_comunicacion
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF102: la comunicación registrada no se modifica.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_ncom_bd BEFORE DELETE ON nulidad_comunicacion
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF102: la comunicación registrada no se elimina.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `nulidad_electoral`
--

DROP TABLE IF EXISTS `nulidad_electoral`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nulidad_electoral` (
  `id_nulidad` int(11) NOT NULL AUTO_INCREMENT,
  `id_proceso` int(11) NOT NULL,
  `alcance` enum('PARCIAL','TOTAL') NOT NULL,
  `id_mesa` int(11) DEFAULT NULL,
  `causal` enum('INSTALACION_IRREGULAR','FRAUDE_MESA','ADMISION_INDEBIDA','ACTA_NO_AUTENTICA','OTRA_CAUSAL','FRAUDE','COHECHO','SOBORNO','INTIMIDACION','VIOLENCIA','PARTICIPACION_INSUFICIENTE') NOT NULL,
  `origen` enum('DE_OFICIO','PERSONERO') NOT NULL,
  `id_personero` int(11) DEFAULT NULL,
  `sustento` varchar(1000) NOT NULL,
  `pruebas` varchar(500) DEFAULT NULL,
  `etapa` enum('ANTES_COMPUTO','DESPUES_COMPUTO') NOT NULL,
  `fecha_presentacion` datetime NOT NULL,
  `id_usuario_registro` int(11) DEFAULT NULL,
  `estado` enum('PRESENTADA','FUNDADA','INFUNDADA','IMPROCEDENTE') NOT NULL DEFAULT 'PRESENTADA',
  `numero_resolucion` varchar(40) DEFAULT NULL,
  `fundamento_resolucion` varchar(1000) DEFAULT NULL,
  `miembros_pleno` tinyint(4) DEFAULT NULL,
  `votos_favor` tinyint(4) DEFAULT NULL,
  `votos_contra` tinyint(4) DEFAULT NULL,
  `voto_dirimente` tinyint(1) DEFAULT NULL,
  `fecha_resolucion` datetime DEFAULT NULL,
  `id_usuario_resolucion` int(11) DEFAULT NULL,
  `contenido_json` longtext DEFAULT NULL,
  `hash_integridad` char(64) DEFAULT NULL,
  `token_qr_hash` char(64) DEFAULT NULL,
  PRIMARY KEY (`id_nulidad`),
  UNIQUE KEY `uq_nulidad_resolucion` (`numero_resolucion`),
  UNIQUE KEY `uq_nulidad_token` (`token_qr_hash`),
  KEY `ix_nulidad_proceso` (`id_proceso`,`estado`),
  KEY `ix_nulidad_mesa` (`id_mesa`),
  KEY `fk_nulidad_personero` (`id_personero`),
  KEY `fk_nulidad_u_reg` (`id_usuario_registro`),
  KEY `fk_nulidad_u_res` (`id_usuario_resolucion`),
  CONSTRAINT `fk_nulidad_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`),
  CONSTRAINT `fk_nulidad_personero` FOREIGN KEY (`id_personero`) REFERENCES `personero` (`id_personero`),
  CONSTRAINT `fk_nulidad_proceso` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`),
  CONSTRAINT `fk_nulidad_u_reg` FOREIGN KEY (`id_usuario_registro`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `fk_nulidad_u_res` FOREIGN KEY (`id_usuario_resolucion`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `chk_nulidad_alcance` CHECK (`alcance` = 'PARCIAL' and `id_mesa` is not null and `causal` in ('INSTALACION_IRREGULAR','FRAUDE_MESA','ADMISION_INDEBIDA','ACTA_NO_AUTENTICA','OTRA_CAUSAL') or `alcance` = 'TOTAL' and `id_mesa` is null and `causal` in ('FRAUDE','COHECHO','SOBORNO','INTIMIDACION','VIOLENCIA','PARTICIPACION_INSUFICIENTE')),
  CONSTRAINT `chk_nulidad_origen` CHECK (`origen` = 'PERSONERO' = (`id_personero` is not null)),
  CONSTRAINT `chk_nulidad_resuelta` CHECK (`estado` = 'PRESENTADA' or `fecha_resolucion` is not null and `fundamento_resolucion` is not null),
  CONSTRAINT `chk_nulidad_documento` CHECK (`contenido_json` is null or json_valid(`contenido_json`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `nulidad_electoral`
--

LOCK TABLES `nulidad_electoral` WRITE;
/*!40000 ALTER TABLE `nulidad_electoral` DISABLE KEYS */;
/*!40000 ALTER TABLE `nulidad_electoral` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_nulidad_bu BEFORE UPDATE ON nulidad_electoral
FOR EACH ROW
BEGIN
  IF OLD.estado <> 'PRESENTADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: la resolución de nulidad del CEUNP es inapelable.';
  END IF;
  IF NOT (NEW.id_proceso <=> OLD.id_proceso) OR NOT (NEW.alcance <=> OLD.alcance) OR NOT (NEW.id_mesa <=> OLD.id_mesa)
     OR NOT (NEW.causal <=> OLD.causal) OR NOT (NEW.origen <=> OLD.origen) OR NOT (NEW.id_personero <=> OLD.id_personero)
     OR NOT (NEW.sustento <=> OLD.sustento) OR NOT (NEW.fecha_presentacion <=> OLD.fecha_presentacion) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF94: los datos del recurso de nulidad presentado no se modifican.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_nulidad_bd BEFORE DELETE ON nulidad_electoral
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF94: un recurso de nulidad no se elimina.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

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
  `no_voto` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'CUS11: marca NO VOTÓ al cerrar el sufragio (RF75)',
  `fecha_votacion` datetime DEFAULT NULL,
  `motivo_inhabilitacion` varchar(255) DEFAULT NULL,
  `fecha_generacion` datetime NOT NULL DEFAULT current_timestamp(),
  `id_mesa` int(11) DEFAULT NULL,
  PRIMARY KEY (`id_proceso`,`id_cargo`,`id_docente`),
  KEY `ix_padron_docente` (`id_docente`,`id_proceso`),
  KEY `ix_padron_mesa` (`id_mesa`),
  KEY `ix_padron_conteo` (`id_cargo`,`habilitado_para_votar`,`ya_voto`),
  KEY `fk_padron_cargo_proceso` (`id_cargo`,`id_proceso`),
  CONSTRAINT `fk_padron_cargo_proceso` FOREIGN KEY (`id_cargo`, `id_proceso`) REFERENCES `cargo_electoral` (`id_cargo`, `id_proceso`),
  CONSTRAINT `fk_padron_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`),
  CONSTRAINT `fk_padron_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`),
  CONSTRAINT `chk_padron_voto` CHECK (`ya_voto` = 0 or `fecha_votacion` is not null)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `padron_electoral`
--

LOCK TABLES `padron_electoral` WRITE;
/*!40000 ALTER TABLE `padron_electoral` DISABLE KEYS */;
INSERT INTO `padron_electoral` VALUES (1,1,101,1,0,1,NULL,NULL,'2026-11-25 11:36:07',1),(1,1,102,1,1,0,'2026-11-25 10:00:00',NULL,'2026-11-25 11:36:07',1),(1,1,103,1,1,0,'2026-11-25 10:00:00',NULL,'2026-11-25 11:36:07',1),(1,1,104,1,1,0,'2026-11-25 10:00:00',NULL,'2026-11-25 11:36:07',1),(1,1,105,1,1,0,'2026-11-25 10:00:00',NULL,'2026-11-25 11:36:07',1),(1,1,106,1,1,0,'2026-11-25 10:00:00',NULL,'2026-11-25 11:36:07',1),(1,1,107,1,1,0,'2026-11-25 10:00:00',NULL,'2026-11-25 11:36:07',1),(1,1,108,1,1,0,'2026-11-25 09:00:00',NULL,'2026-11-25 11:36:07',1),(1,1,109,1,1,0,'2026-11-25 10:00:00',NULL,'2026-11-25 11:36:07',1),(1,1,110,1,1,0,'2026-11-25 10:00:00',NULL,'2026-11-25 11:36:07',1),(1,1,111,1,1,0,'2026-11-25 10:00:00',NULL,'2026-11-25 11:36:07',1),(1,1,112,1,1,0,'2026-11-25 10:00:00',NULL,'2026-11-25 11:36:07',1),(1,1,113,1,1,0,'2026-11-25 10:00:00',NULL,'2026-11-25 11:36:07',1),(1,1,114,1,1,0,'2026-11-25 10:00:00',NULL,'2026-11-25 11:36:07',1),(1,1,115,1,1,0,'2026-11-25 10:00:00',NULL,'2026-11-25 11:36:07',1),(1,1,116,1,1,0,'2026-11-25 10:00:00',NULL,'2026-11-25 11:36:07',1),(1,1,117,1,1,0,'2026-11-25 10:00:00',NULL,'2026-11-25 11:36:07',1),(2,2,101,1,1,0,'2026-11-25 09:00:00',NULL,'2026-10-15 14:05:07',2),(2,2,102,1,1,0,'2026-11-25 09:00:00',NULL,'2026-10-15 14:05:07',2),(2,2,103,1,1,0,'2026-11-25 09:00:00',NULL,'2026-10-15 14:05:07',2),(2,2,104,1,1,0,'2026-11-25 09:00:00',NULL,'2026-10-15 14:05:07',2),(2,2,105,1,1,0,'2026-11-25 09:00:00',NULL,'2026-10-15 14:05:07',2),(2,2,106,1,1,0,'2026-11-25 09:00:00',NULL,'2026-10-15 14:05:07',2),(2,2,107,1,1,0,'2026-11-25 09:00:00',NULL,'2026-10-15 14:05:07',2),(2,2,108,1,1,0,'2026-11-25 09:00:00',NULL,'2026-10-15 14:05:07',2),(2,2,109,1,1,0,'2026-11-25 09:00:00',NULL,'2026-10-15 14:05:07',2),(2,2,110,1,1,0,'2026-11-25 09:00:00',NULL,'2026-10-15 14:05:07',2),(2,2,111,1,1,0,'2026-11-25 09:00:00',NULL,'2026-10-15 14:05:07',2),(2,2,112,1,1,0,'2026-11-25 09:00:00',NULL,'2026-10-15 14:05:07',2),(2,2,113,1,1,0,'2026-11-25 09:00:00',NULL,'2026-10-15 14:05:07',2),(2,2,114,1,1,0,'2026-11-25 09:00:00',NULL,'2026-10-15 14:05:07',2),(2,2,115,1,1,0,'2026-11-25 09:00:00',NULL,'2026-10-15 14:05:07',2),(2,2,116,1,1,0,'2026-11-25 09:00:00',NULL,'2026-10-15 14:05:07',2),(2,2,117,1,1,0,'2026-11-25 09:00:00',NULL,'2026-10-15 14:05:07',2);
/*!40000 ALTER TABLE `padron_electoral` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_padron_bu BEFORE UPDATE ON padron_electoral
FOR EACH ROW
BEGIN
  DECLARE v_estado VARCHAR(20) DEFAULT NULL;

  IF OLD.ya_voto = 1 AND (NEW.ya_voto = 0
        OR NEW.id_docente <> OLD.id_docente
        OR NEW.id_cargo   <> OLD.id_cargo
        OR NEW.id_proceso <> OLD.id_proceso) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN01: no se puede revertir ni reasignar un registro de padron que ya voto.';
  END IF;

  IF OLD.ya_voto = 0 AND NEW.ya_voto = 1 THEN
    SELECT estado INTO v_estado FROM proceso_electoral WHERE id_proceso = NEW.id_proceso;
    IF v_estado <> 'VOTACION' THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN06: solo se registra el sufragio con el proceso en VOTACION.';
    END IF;
    IF NEW.habilitado_para_votar = 0 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN04: el docente no esta habilitado en el padron.';
    END IF;
    
    SET NEW.fecha_votacion = DATE_FORMAT(COALESCE(NEW.fecha_votacion, NOW()), '%Y-%m-%d %H:00:00');
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_padron_no_voto_bu BEFORE UPDATE ON padron_electoral
FOR EACH ROW
BEGIN
  IF OLD.no_voto = 1 AND NEW.no_voto = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF75: la marca NO VOTO no se puede quitar.';
  END IF;
  IF NEW.no_voto = 1 AND NEW.ya_voto = 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF75: un elector marcado NO VOTO ya no puede votar.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_padron_bd BEFORE DELETE ON padron_electoral
FOR EACH ROW
BEGIN
  IF OLD.ya_voto = 1 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No se puede eliminar del padron a un docente que ya voto.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `parametro_definicion`
--

DROP TABLE IF EXISTS `parametro_definicion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `parametro_definicion` (
  `clave` varchar(80) NOT NULL,
  `grupo` enum('MULTAS','JORNADA','CEUNP','SEGURIDAD') NOT NULL,
  `etiqueta` varchar(120) NOT NULL,
  `tipo` enum('DECIMAL','ENTERO','HORA','INDICADOR','TEXTO') NOT NULL,
  `minimo` decimal(12,2) DEFAULT NULL,
  `maximo` decimal(12,2) DEFAULT NULL,
  `unidad` varchar(30) DEFAULT NULL,
  `referencia` varchar(80) DEFAULT NULL,
  `bloqueo_jornada` tinyint(1) NOT NULL DEFAULT 0,
  `orden` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`clave`),
  CONSTRAINT `chk_param_def_rango` CHECK (`minimo` is null or `maximo` is null or `minimo` <= `maximo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `parametro_definicion`
--

LOCK TABLES `parametro_definicion` WRITE;
/*!40000 ALTER TABLE `parametro_definicion` DISABLE KEYS */;
INSERT INTO `parametro_definicion` VALUES ('BITACORA_EXPORTACION_MAX','SEGURIDAD','Registros por exportación de la bitácora','ENTERO',100.00,100000.00,'registros','RN28',0,40),('CEUNP_QUORUM_PLENO','CEUNP','Quórum del Pleno del CEUNP','ENTERO',5.00,9.00,'miembros','RN36',0,10),('ELECTORES_POR_MESA','JORNADA','Electores por mesa de sufragio','ENTERO',10.00,500.00,'electores','RN08',1,10),('IMPUGNACION_PLAZO_APELACION_HORAS','CEUNP','Plazo para apelar ante el CEUNP','ENTERO',0.00,168.00,'horas','RF81',0,20),('INSTALACION_CONTROL_HORARIO','JORNADA','Exigir el horario de instalación','INDICADOR',0.00,1.00,NULL,'RN07',1,50),('INSTALACION_HORA_INICIO','JORNADA','Inicio de la instalación de mesas','HORA',0.00,23.99,'hora','RN07',1,30),('INSTALACION_HORA_LIMITE','JORNADA','Límite para instalar las mesas','HORA',0.00,23.99,'hora','RF58',1,40),('MULTA_ELECTOR_OMISO_PCT','MULTAS','Multa al elector omiso','DECIMAL',0.00,100.00,'% de la UIT','RN35 · Art. 68',0,20),('MULTA_MIEMBRO_MESA_OMISO_PCT','MULTAS','Multa al miembro de mesa inasistente','DECIMAL',0.00,100.00,'% de la UIT','RN35 · Art. 67',0,30),('MULTA_PLAZO_JUSTIFICACION_DIAS','MULTAS','Plazo para justificar la omisión','ENTERO',0.00,90.00,'días','RF106',0,40),('QUORUM_MINIMO_LEGAL_PCT','CEUNP','Quórum mínimo legal de un proceso','DECIMAL',0.00,100.00,'%','RN31',1,40),('SEGUNDA_VUELTA_PLAZO_DIAS','CEUNP','Plazo para la segunda vuelta','ENTERO',1.00,60.00,'días','RN33 · Art. 63',0,30),('SEGURIDAD_BLOQUEO_MINUTOS','SEGURIDAD','Duración del bloqueo de la cuenta','ENTERO',1.00,1440.00,'minutos','RNF seguridad',0,20),('SEGURIDAD_INTENTOS_MAXIMOS','SEGURIDAD','Intentos fallidos antes del bloqueo','ENTERO',3.00,10.00,'intentos','RNF seguridad',0,10),('SEGURIDAD_PASSWORD_MIN','SEGURIDAD','Longitud mínima de la contraseña','ENTERO',8.00,32.00,'caracteres','RNF seguridad',0,30),('SUFRAGIO_CONTROL_HORARIO','JORNADA','Exigir el horario de cierre del sufragio','INDICADOR',0.00,1.00,NULL,'RN06',1,60),('UBICACION_SUFRAGIO','JORNADA','Lugar de sufragio por defecto','TEXTO',3.00,150.00,NULL,'RN08',1,20),('UIT','MULTAS','Unidad Impositiva Tributaria vigente','DECIMAL',1.00,100000.00,'S/','RF105',0,10);
/*!40000 ALTER TABLE `parametro_definicion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `parametro_global`
--

DROP TABLE IF EXISTS `parametro_global`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `parametro_global` (
  `clave` varchar(80) NOT NULL,
  `valor` varchar(255) NOT NULL,
  `descripcion` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`clave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `parametro_global`
--

LOCK TABLES `parametro_global` WRITE;
/*!40000 ALTER TABLE `parametro_global` DISABLE KEYS */;
INSERT INTO `parametro_global` VALUES ('BITACORA_EXPORTACION_MAX','20000','Máximo de registros de la bitácora que se descargan en una exportación (CUS19)'),('CEUNP_QUORUM_PLENO','5','Miembros del Pleno del CEUNP necesarios para resolver una apelación (RN36)'),('ELECTORES_POR_MESA','200','Cantidad máxima de electores por mesa de sufragio'),('IMPUGNACION_PLAZO_APELACION_HORAS','24','Horas que tiene el personero para apelar la decisión de la mesa ante el CEUNP (RF81); 0 = sin plazo'),('INSTALACION_CONTROL_HORARIO','1','1 = exigir el día y el horario de instalación; 0 = permitir instalar a cualquier hora (pruebas)'),('INSTALACION_HORA_INICIO','9','Hora desde la que se instalan las mesas el día de la elección (9 = 09:00) - RN07'),('INSTALACION_HORA_LIMITE','12','Hora límite para instalar las mesas (12 = 12:00); luego la mesa queda NO INSTALADA - RF58'),('MULTA_ELECTOR_OMISO_PCT','2.5','Porcentaje de multa para electores omisos (% de UIT) - RN35'),('MULTA_MIEMBRO_MESA_OMISO_PCT','3.0','Porcentaje de multa para miembros de mesa omisos (% de UIT) - RN35'),('MULTA_PLAZO_JUSTIFICACION_DIAS','10','Días desde la notificación de la multa para presentar la justificación ante el CEUNP (RF106); 0 = sin plazo'),('QUORUM_MINIMO_LEGAL_PCT','10','Quórum mínimo legal que puede fijar un proceso (RN31: más del 60 %). Solo se baja para demostraciones.'),('SEGUNDA_VUELTA_PLAZO_DIAS','15','Días desde el cómputo dentro de los que debe realizarse la segunda vuelta (RN33, Art. 63)'),('SEGURIDAD_BLOQUEO_MINUTOS','15','Minutos que la cuenta queda bloqueada tras superar los intentos fallidos'),('SEGURIDAD_INTENTOS_MAXIMOS','5','Intentos fallidos de inicio de sesión antes de bloquear la cuenta temporalmente'),('SEGURIDAD_PASSWORD_MIN','8','Longitud mínima de las contraseñas (debe tener letras y números)'),('SUFRAGIO_CONTROL_HORARIO','1','1 = cerrar el sufragio desde la hora de cierre del proceso (15:00, RN06) o cuando ya votaron todos; 0 = permitir cerrar a cualquier hora (pruebas)'),('UBICACION_SUFRAGIO','Biblioteca Central','Lugar de sufragio por defecto - RN08'),('UIT','5150.00','Unidad Impositiva Tributaria (UIT) vigente en soles. Actualizar cada año.');
/*!40000 ALTER TABLE `parametro_global` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_parametro_global_bu BEFORE UPDATE ON parametro_global
FOR EACH ROW
BEGIN
  DECLARE v_error VARCHAR(300);
  IF NOT (NEW.valor <=> OLD.valor) THEN
    SET v_error = fn_validar_parametro(NEW.clave, NEW.valor);
    IF v_error IS NOT NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_parametro_global_au AFTER UPDATE ON parametro_global
FOR EACH ROW
BEGIN
  IF NOT (NEW.valor <=> OLD.valor) THEN
    INSERT INTO parametro_historial (clave, valor_anterior, valor_nuevo, motivo, origen, id_usuario, ip)
    VALUES (NEW.clave, OLD.valor, NEW.valor,
            COALESCE(@cus18_motivo, 'Cambio realizado directamente en la base de datos'),
            COALESCE(@cus18_origen, 'BASE_DATOS'), @cus18_id_usuario, @cus18_ip);
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `parametro_historial`
--

DROP TABLE IF EXISTS `parametro_historial`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `parametro_historial` (
  `id_historial` bigint(20) NOT NULL AUTO_INCREMENT,
  `clave` varchar(80) NOT NULL,
  `valor_anterior` varchar(255) DEFAULT NULL,
  `valor_nuevo` varchar(255) NOT NULL,
  `motivo` varchar(500) DEFAULT NULL,
  `origen` enum('PANTALLA','RESTAURACION','BASE_DATOS') NOT NULL DEFAULT 'BASE_DATOS',
  `id_usuario` int(11) DEFAULT NULL,
  `ip` varchar(45) DEFAULT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_historial`),
  KEY `ix_param_hist_clave` (`clave`,`fecha`),
  KEY `fk_param_hist_usuario` (`id_usuario`),
  CONSTRAINT `fk_param_hist_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `parametro_historial`
--

LOCK TABLES `parametro_historial` WRITE;
/*!40000 ALTER TABLE `parametro_historial` DISABLE KEYS */;
INSERT INTO `parametro_historial` VALUES (1,'QUORUM_MINIMO_LEGAL_PCT','60','10','prueba del sistema','PANTALLA',1,'0:0:0:0:0:0:0:1','2026-11-08 15:47:49');
/*!40000 ALTER TABLE `parametro_historial` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_param_hist_bu BEFORE UPDATE ON parametro_historial
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: el historial de parámetros es inmutable.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_param_hist_bd BEFORE DELETE ON parametro_historial
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: el historial de parámetros es inmutable.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

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
  `qr_credencial_hash` char(64) DEFAULT NULL,
  PRIMARY KEY (`id_personero`),
  UNIQUE KEY `uq_personero_lista_docente` (`id_lista`,`id_docente`),
  UNIQUE KEY `uq_personero_qr` (`qr_credencial_hash`),
  KEY `fk_personero_docente` (`id_docente`),
  KEY `fk_personero_mesa` (`id_mesa`),
  CONSTRAINT `fk_personero_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`),
  CONSTRAINT `fk_personero_lista` FOREIGN KEY (`id_lista`) REFERENCES `lista_electoral` (`id_lista`),
  CONSTRAINT `fk_personero_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`),
  CONSTRAINT `chk_personero_mesa` CHECK (`tipo` = 'MESA' and `id_mesa` is not null or `tipo` <> 'MESA' and `id_mesa` is null)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `personero`
--

LOCK TABLES `personero` WRITE;
/*!40000 ALTER TABLE `personero` DISABLE KEYS */;
/*!40000 ALTER TABLE `personero` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_personero_bi BEFORE INSERT ON personero
FOR EACH ROW
BEGIN
  DECLARE v_proceso INT;
  SET v_proceso = fn_proceso_de_lista(NEW.id_lista);

  IF EXISTS (SELECT 1
               FROM candidato ca
               JOIN lista_electoral l ON l.id_lista = ca.id_lista
               JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
              WHERE ca.id_docente = NEW.id_docente
                AND c.id_proceso = v_proceso
                AND ca.estado_validacion <> 'EXCLUIDO') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN21: un candidato no puede ser personero en el mismo proceso.';
  END IF;

  IF fn_tiene_cargo_excluyente(NEW.id_docente) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN21: una autoridad vigente no puede ser personero.';
  END IF;

  IF NEW.id_mesa IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM mesa_electoral
                      WHERE id_mesa = NEW.id_mesa AND id_proceso = v_proceso) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'La mesa del personero no pertenece al proceso de su lista.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_personero_au_credencial AFTER UPDATE ON personero
FOR EACH ROW
BEGIN
  IF OLD.estado_acreditacion = 'ACREDITADO' AND NEW.estado_acreditacion <> 'ACREDITADO' THEN
    UPDATE credencial_qr
       SET estado = 'REVOCADA', fecha_revocacion = NOW(),
           motivo_revocacion = 'Acreditación del personero revocada (CUS05)'
     WHERE id_personero = NEW.id_personero AND estado = 'VIGENTE';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

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
  `fecha_convocatoria` date DEFAULT NULL,
  `fecha_limite_inscripcion` datetime DEFAULT NULL,
  `fecha_cierre_real` datetime DEFAULT NULL,
  `motivo_anulacion` varchar(500) DEFAULT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_proceso`),
  KEY `ix_proceso_estado` (`estado`),
  KEY `fk_proceso_padre` (`id_proceso_padre`),
  CONSTRAINT `fk_proceso_padre` FOREIGN KEY (`id_proceso_padre`) REFERENCES `proceso_electoral` (`id_proceso`),
  CONSTRAINT `chk_proceso_fechas` CHECK (`fecha_fin` > `fecha_inicio`),
  CONSTRAINT `chk_proceso_quorum` CHECK (`quorum_minimo` >= 0 and `quorum_minimo` <= 100),
  CONSTRAINT `chk_proceso_vuelta` CHECK (`tipo` = 'PRIMERA_VUELTA' and `id_proceso_padre` is null or `tipo` = 'SEGUNDA_VUELTA' and `id_proceso_padre` is not null)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `proceso_electoral`
--

LOCK TABLES `proceso_electoral` WRITE;
/*!40000 ALTER TABLE `proceso_electoral` DISABLE KEYS */;
INSERT INTO `proceso_electoral` VALUES (1,'Elección de Jefe de Departamento de Informática 2026-II','2026-11-25 09:00:00','2026-11-25 15:00:00','FINALIZADO','PRIMERA_VUELTA',NULL,60.00,'2026-10-15','2026-11-02 18:00:00','2026-11-25 15:45:17',NULL,'2026-10-25 11:05:07'),(2,'Elección de Jefe de Departamento de Informática 2026-II','2026-11-25 09:00:00','2026-11-25 15:00:00','FINALIZADO','PRIMERA_VUELTA',NULL,60.00,'2026-10-15','2026-10-22 14:04:00','2026-11-25 15:15:16',NULL,'2026-10-15 14:04:44');
/*!40000 ALTER TABLE `proceso_electoral` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_proceso_quorum_bi BEFORE INSERT ON proceso_electoral
FOR EACH ROW
BEGIN
  IF NEW.quorum_minimo < COALESCE(fn_parametro_decimal('QUORUM_MINIMO_LEGAL_PCT'), 60) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN31: el quorum del proceso no puede ser menor que el minimo legal (parametro QUORUM_MINIMO_LEGAL_PCT).';
  END IF;
  
  IF NEW.fecha_convocatoria IS NOT NULL
     AND DATEDIFF(DATE(NEW.fecha_inicio), NEW.fecha_convocatoria) NOT BETWEEN 30 AND 45 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN02: la convocatoria debe publicarse entre 30 y 45 dias naturales antes del sufragio.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_proceso_bi_cus15 BEFORE INSERT ON proceso_electoral
FOR EACH ROW
BEGIN
  IF NEW.tipo = 'SEGUNDA_VUELTA' AND EXISTS (SELECT 1 FROM nulidad_electoral
                                               WHERE id_proceso = NEW.id_proceso_padre AND alcance = 'TOTAL'
                                                 AND estado = 'PRESENTADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF94: hay un recurso de nulidad total pendiente; resuélvalo antes de convocar la segunda vuelta.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_proceso_bu BEFORE UPDATE ON proceso_electoral
FOR EACH ROW
BEGIN
  IF OLD.estado IN ('FINALIZADO','ANULADO') AND NEW.estado <> OLD.estado
     AND NOT (OLD.estado = 'FINALIZADO' AND NEW.estado = 'ANULADO' AND @cus15_nulidad_total <=> OLD.id_proceso) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Un proceso FINALIZADO o ANULADO no puede cambiar de estado.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_proceso_quorum_bu BEFORE UPDATE ON proceso_electoral
FOR EACH ROW
BEGIN
  IF NOT (NEW.quorum_minimo <=> OLD.quorum_minimo)
     AND NEW.quorum_minimo < COALESCE(fn_parametro_decimal('QUORUM_MINIMO_LEGAL_PCT'), 60) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN31: el quorum del proceso no puede ser menor que el minimo legal (parametro QUORUM_MINIMO_LEGAL_PCT).';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `proclamacion_cargo`
--

DROP TABLE IF EXISTS `proclamacion_cargo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `proclamacion_cargo` (
  `id_cargo` int(11) NOT NULL,
  `id_proceso` int(11) NOT NULL,
  `id_lista` int(11) NOT NULL,
  `votos` int(11) NOT NULL,
  `porcentaje_validos` decimal(5,2) DEFAULT NULL,
  `codigo_credencial` char(12) NOT NULL,
  `fecha_proclamacion` datetime NOT NULL,
  PRIMARY KEY (`id_cargo`),
  UNIQUE KEY `uq_proclamacion_codigo` (`codigo_credencial`),
  KEY `fk_procl_cargo` (`id_cargo`,`id_proceso`),
  KEY `fk_procl_lista` (`id_lista`),
  CONSTRAINT `fk_procl_cargo` FOREIGN KEY (`id_cargo`, `id_proceso`) REFERENCES `cargo_electoral` (`id_cargo`, `id_proceso`),
  CONSTRAINT `fk_procl_lista` FOREIGN KEY (`id_lista`) REFERENCES `lista_electoral` (`id_lista`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `proclamacion_cargo`
--

LOCK TABLES `proclamacion_cargo` WRITE;
/*!40000 ALTER TABLE `proclamacion_cargo` DISABLE KEYS */;
INSERT INTO `proclamacion_cargo` VALUES (1,1,2,11,73.33,'F64428F5F4FC','2026-11-25 15:56:58'),(2,2,5,13,62.98,'05EF7A5ED5DA','2026-11-25 15:26:44');
/*!40000 ALTER TABLE `proclamacion_cargo` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_proclamacion_bu BEFORE UPDATE ON proclamacion_cargo
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF98: la acreditación de la lista ganadora no se modifica.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_proclamacion_bd BEFORE DELETE ON proclamacion_cargo
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF98: la acreditación de la lista ganadora no se elimina.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `reemplazo_mesa`
--

DROP TABLE IF EXISTS `reemplazo_mesa`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `reemplazo_mesa` (
  `id_mesa` int(11) NOT NULL,
  `cargo` enum('PRESIDENTE','SECRETARIO','VOCAL') NOT NULL,
  `id_docente` int(11) NOT NULL,
  `hora_acreditacion` datetime NOT NULL DEFAULT current_timestamp(),
  `id_usuario` int(11) DEFAULT NULL,
  PRIMARY KEY (`id_mesa`,`cargo`),
  UNIQUE KEY `uq_reemplazo_docente` (`id_mesa`,`id_docente`),
  KEY `fk_reemplazo_docente` (`id_docente`),
  KEY `fk_reemplazo_usuario` (`id_usuario`),
  CONSTRAINT `fk_reemplazo_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`),
  CONSTRAINT `fk_reemplazo_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`),
  CONSTRAINT `fk_reemplazo_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reemplazo_mesa`
--

LOCK TABLES `reemplazo_mesa` WRITE;
/*!40000 ALTER TABLE `reemplazo_mesa` DISABLE KEYS */;
/*!40000 ALTER TABLE `reemplazo_mesa` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `reporte_multas`
--

DROP TABLE IF EXISTS `reporte_multas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `reporte_multas` (
  `id_reporte` int(11) NOT NULL AUTO_INCREMENT,
  `id_proceso` int(11) NOT NULL,
  `estado` enum('GENERADO','RESUELTO') NOT NULL DEFAULT 'GENERADO',
  `uit_referencia` decimal(10,2) NOT NULL,
  `pct_elector` decimal(5,2) NOT NULL,
  `pct_miembro` decimal(5,2) NOT NULL,
  `omisos_votacion` int(11) NOT NULL DEFAULT 0,
  `omisos_mesa` int(11) NOT NULL DEFAULT 0,
  `monto_total` decimal(12,2) NOT NULL DEFAULT 0.00,
  `veces_generado` int(11) NOT NULL DEFAULT 1,
  `fecha_generacion` datetime NOT NULL,
  `id_usuario_generacion` int(11) DEFAULT NULL,
  `numero_resolucion` varchar(40) DEFAULT NULL,
  `fundamento` varchar(1000) DEFAULT NULL,
  `miembros_pleno` tinyint(4) DEFAULT NULL,
  `fecha_resolucion` datetime DEFAULT NULL,
  `id_usuario_resolucion` int(11) DEFAULT NULL,
  `contenido_json` longtext DEFAULT NULL,
  `hash_integridad` char(64) DEFAULT NULL,
  `token_qr_hash` char(64) DEFAULT NULL,
  PRIMARY KEY (`id_reporte`),
  UNIQUE KEY `uq_reporte_multas_proceso` (`id_proceso`),
  UNIQUE KEY `uq_reporte_multas_resolucion` (`numero_resolucion`),
  UNIQUE KEY `uq_reporte_multas_token` (`token_qr_hash`),
  KEY `fk_reporte_multas_u_gen` (`id_usuario_generacion`),
  KEY `fk_reporte_multas_u_res` (`id_usuario_resolucion`),
  CONSTRAINT `fk_reporte_multas_proceso` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`),
  CONSTRAINT `fk_reporte_multas_u_gen` FOREIGN KEY (`id_usuario_generacion`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `fk_reporte_multas_u_res` FOREIGN KEY (`id_usuario_resolucion`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `chk_reporte_multas_resuelto` CHECK (`estado` = 'GENERADO' or `numero_resolucion` is not null and `fecha_resolucion` is not null and `contenido_json` is not null and `hash_integridad` is not null),
  CONSTRAINT `chk_reporte_multas_json` CHECK (`contenido_json` is null or json_valid(`contenido_json`))
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reporte_multas`
--

LOCK TABLES `reporte_multas` WRITE;
/*!40000 ALTER TABLE `reporte_multas` DISABLE KEYS */;
INSERT INTO `reporte_multas` VALUES (1,1,'RESUELTO',5150.00,2.50,3.00,1,0,128.75,2,'2026-11-25 19:44:40',3,'394893- CEUNP','Concluida la votación del proceso «Elección de Jefe de Departamento de Informática 2026-II», se identificó a los docentes hábiles que no votaron y a los miembros titulares de mesa que no asistieron, conforme a los artículos 67 y 68 del Reglamento de Elecciones.',5,'2026-11-25 19:45:06',3,'{\"tipo\":\"RESOLUCION_MULTAS\",\"id_proceso\":1,\"proceso\":\"Elección de Jefe de Departamento de Informática 2026-II\",\"vuelta\":\"PRIMERA_VUELTA\",\"estado_proceso\":\"FINALIZADO\",\"resolucion\":\"394893- CEUNP\",\"fecha\":\"2026-11-25 19:45:06\",\"pleno\":{\"miembros\":5,\"quorum\":5},\"fundamento\":\"Concluida la votación del proceso «Elección de Jefe de Departamento de Informática 2026-II», se identificó a los docentes hábiles que no votaron y a los miembros titulares de mesa que no asistieron, conforme a los artículos 67 y 68 del Reglamento de Elecciones.\",\"uit\":5150.00,\"porcentaje_elector\":2.50,\"porcentaje_miembro\":3.00,\"monto_elector\":128.75,\"monto_miembro\":154.50,\"participacion\":{\"electores\": 17, \"votaron\": 16, \"porcentaje\": 94.12},\"omisos_votacion\":1,\"omisos_mesa\":0,\"monto_total\":128.75,\"multas\":[{\"id_multa\": 1, \"dni\": \"02606057\", \"docente\": \"Alvarado Tabacchi, Jorge\", \"facultad\": \"Facultad de Ingeniería Industrial\", \"motivo\": \"OMISO_VOTACION\", \"mesa\": \"001\", \"rol\": null, \"asistio_sin_votar\": \"true\", \"porcentaje\": 2.50, \"monto\": 128.75}],\"nota\":\"El sistema determina las multas; no las cobra. El docente puede justificar su inasistencia ante el CEUNP (Disp. Final 2.ª y 5.ª).\"}','9c8f2b5d51b34dfc0be9362e40b9d778911f4c19f94934b753379c8634b9c955','c5a18962079eaee3e515c8f1c0e578a202dea3b962d53873e72e9536afee38ef'),(2,2,'RESUELTO',5150.00,2.50,3.00,0,3,463.50,1,'2026-11-25 15:04:52',3,'378-2026','Concluida la votación del proceso «Elección de Jefe de Departamento de Informática 2026-II», se identificó a los docentes hábiles que no votaron y a los miembros titulares de mesa que no asistieron, conforme a los artículos 67 y 68 del Reglamento de Elecciones.',5,'2026-11-25 15:07:23',3,'{\"tipo\":\"RESOLUCION_MULTAS\",\"id_proceso\":2,\"proceso\":\"Elección de Jefe de Departamento de Informática 2026-II\",\"vuelta\":\"PRIMERA_VUELTA\",\"estado_proceso\":\"FINALIZADO\",\"resolucion\":\"378-2026\",\"fecha\":\"2026-11-25 15:07:23\",\"pleno\":{\"miembros\":5,\"quorum\":5},\"fundamento\":\"Concluida la votación del proceso «Elección de Jefe de Departamento de Informática 2026-II», se identificó a los docentes hábiles que no votaron y a los miembros titulares de mesa que no asistieron, conforme a los artículos 67 y 68 del Reglamento de Elecciones.\",\"uit\":5150.00,\"porcentaje_elector\":2.50,\"porcentaje_miembro\":3.00,\"monto_elector\":128.75,\"monto_miembro\":154.50,\"participacion\":{\"electores\": 17, \"votaron\": 17, \"porcentaje\": 100.00},\"omisos_votacion\":0,\"omisos_mesa\":3,\"monto_total\":463.50,\"multas\":[{\"id_multa\": 2, \"dni\": \"02635949\", \"docente\": \"Cruz Yarlequé, Wilfredo\", \"facultad\": \"Facultad de Ingeniería Industrial\", \"motivo\": \"OMISO_MESA\", \"mesa\": \"001\", \"rol\": \"SUPLENTE\", \"asistio_sin_votar\": \"false\", \"porcentaje\": 3.00, \"monto\": 154.50},{\"id_multa\": 3, \"dni\": \"40682528\", \"docente\": \"Ipanaque Silva, Rolando Elías\", \"facultad\": \"Facultad de Ingeniería Industrial\", \"motivo\": \"OMISO_MESA\", \"mesa\": \"001\", \"rol\": \"SUPLENTE\", \"asistio_sin_votar\": \"false\", \"porcentaje\": 3.00, \"monto\": 154.50},{\"id_multa\": 4, \"dni\": \"02887733\", \"docente\": \"Sandoval Rivera, Arturo\", \"facultad\": \"Facultad de Ingeniería Industrial\", \"motivo\": \"OMISO_MESA\", \"mesa\": \"001\", \"rol\": \"SUPLENTE\", \"asistio_sin_votar\": \"false\", \"porcentaje\": 3.00, \"monto\": 154.50}],\"nota\":\"El sistema determina las multas; no las cobra. El docente puede justificar su inasistencia ante el CEUNP (Disp. Final 2.ª y 5.ª).\"}','f48ba0108bb072a7c357cc8e81b3944ee9c0ade598fdd147521869fb200a060f','0eab1d970d938682423163e74ff568793f7119ae29cbe680c6e2b6805511ee35');
/*!40000 ALTER TABLE `reporte_multas` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_rmultas_bu BEFORE UPDATE ON reporte_multas
FOR EACH ROW
BEGIN
  IF OLD.estado = 'RESUELTO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: la resolución de multas del CEUNP no se modifica.';
  END IF;
  IF NOT (NEW.id_proceso <=> OLD.id_proceso) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El reporte de multas no cambia de proceso.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_rmultas_bd BEFORE DELETE ON reporte_multas
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: el reporte de multas no se elimina.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `respaldo_bd`
--

DROP TABLE IF EXISTS `respaldo_bd`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `respaldo_bd` (
  `id_respaldo` int(11) NOT NULL AUTO_INCREMENT,
  `nombre_archivo` varchar(150) NOT NULL,
  `motivo` varchar(300) DEFAULT NULL,
  `tablas` int(11) NOT NULL DEFAULT 0,
  `vistas` int(11) NOT NULL DEFAULT 0,
  `rutinas` int(11) NOT NULL DEFAULT 0,
  `disparadores` int(11) NOT NULL DEFAULT 0,
  `filas` bigint(20) NOT NULL DEFAULT 0,
  `tamano_bytes` bigint(20) NOT NULL DEFAULT 0,
  `hash_sha256` char(64) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `ip` varchar(45) DEFAULT NULL,
  `fecha_inicio` datetime NOT NULL,
  `fecha_fin` datetime NOT NULL,
  PRIMARY KEY (`id_respaldo`),
  UNIQUE KEY `uq_respaldo_archivo` (`nombre_archivo`),
  KEY `ix_respaldo_fecha` (`fecha_fin`),
  KEY `fk_respaldo_usuario` (`id_usuario`),
  CONSTRAINT `fk_respaldo_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `chk_respaldo_hash` CHECK (`hash_sha256` regexp '^[0-9a-f]{64}$'),
  CONSTRAINT `chk_respaldo_fechas` CHECK (`fecha_fin` >= `fecha_inicio`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `respaldo_bd`
--

LOCK TABLES `respaldo_bd` WRITE;
/*!40000 ALTER TABLE `respaldo_bd` DISABLE KEYS */;
/*!40000 ALTER TABLE `respaldo_bd` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_respaldo_bu BEFORE UPDATE ON respaldo_bd
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: el registro de respaldos es inmutable.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_respaldo_bd BEFORE DELETE ON respaldo_bd
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: el registro de respaldos es inmutable.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `resultado_electoral`
--

DROP TABLE IF EXISTS `resultado_electoral`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `resultado_electoral` (
  `id_resultado` int(11) NOT NULL AUTO_INCREMENT,
  `id_proceso` int(11) NOT NULL,
  `id_cargo` int(11) NOT NULL,
  `id_lista` int(11) DEFAULT NULL,
  `tipo_voto` enum('VALIDO','BLANCO','NULO') NOT NULL,
  `total_votos` int(11) NOT NULL DEFAULT 0,
  `votos_docentes` int(11) DEFAULT NULL,
  `votos_estudiantes` int(11) DEFAULT NULL,
  `porcentaje_validos` decimal(5,2) DEFAULT NULL,
  `pct_docente` decimal(5,2) DEFAULT NULL,
  `pct_estudiante` decimal(5,2) DEFAULT NULL,
  `pct_ponderado` decimal(5,2) DEFAULT NULL,
  `posicion` int(11) DEFAULT NULL,
  `fecha_computo` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_resultado`),
  KEY `ix_resultado_cargo` (`id_cargo`,`posicion`),
  KEY `fk_resultado_cargo_proceso` (`id_cargo`,`id_proceso`),
  KEY `fk_resultado_lista` (`id_lista`),
  CONSTRAINT `fk_resultado_cargo_proceso` FOREIGN KEY (`id_cargo`, `id_proceso`) REFERENCES `cargo_electoral` (`id_cargo`, `id_proceso`),
  CONSTRAINT `fk_resultado_lista` FOREIGN KEY (`id_lista`) REFERENCES `lista_electoral` (`id_lista`),
  CONSTRAINT `chk_resultado_total` CHECK (`total_votos` >= 0)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `resultado_electoral`
--

LOCK TABLES `resultado_electoral` WRITE;
/*!40000 ALTER TABLE `resultado_electoral` DISABLE KEYS */;
INSERT INTO `resultado_electoral` VALUES (1,1,1,2,'VALIDO',11,11,0,73.33,73.33,0.00,73.33,1,'2026-11-25 15:54:29'),(2,1,1,1,'VALIDO',4,4,0,26.67,26.67,0.00,26.67,2,'2026-11-25 15:54:29'),(4,1,1,NULL,'BLANCO',1,1,0,NULL,NULL,NULL,NULL,NULL,'2026-11-25 15:54:29'),(5,1,1,NULL,'NULO',0,0,0,NULL,NULL,NULL,NULL,NULL,'2026-11-25 15:54:29'),(7,2,2,5,'VALIDO',13,13,180,62.98,76.47,36.00,62.98,1,'2026-11-25 15:24:29'),(8,2,2,4,'VALIDO',4,4,320,37.02,23.53,64.00,37.02,2,'2026-11-25 15:24:29'),(10,2,2,NULL,'BLANCO',0,0,0,NULL,NULL,NULL,NULL,NULL,'2026-11-25 15:24:29'),(11,2,2,NULL,'NULO',0,0,0,NULL,NULL,NULL,NULL,NULL,'2026-11-25 15:24:29');
/*!40000 ALTER TABLE `resultado_electoral` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_resultado_bu BEFORE UPDATE ON resultado_electoral
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el computo oficial es irreversible.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_resultado_bd BEFORE DELETE ON resultado_electoral
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el computo oficial es irreversible.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

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
  UNIQUE KEY `uq_sesion_token` (`token_hash`),
  KEY `ix_sesion_expiracion` (`fecha_expiracion`),
  KEY `fk_sesion_usuario` (`id_usuario`),
  CONSTRAINT `fk_sesion_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`) ON DELETE CASCADE,
  CONSTRAINT `chk_sesion_fechas` CHECK (`fecha_expiracion` > `fecha_inicio`)
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
-- Table structure for table `solicitud_regeneracion_qr`
--

DROP TABLE IF EXISTS `solicitud_regeneracion_qr`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `solicitud_regeneracion_qr` (
  `id_solicitud` int(11) NOT NULL AUTO_INCREMENT,
  `id_proceso` int(11) NOT NULL,
  `id_docente` int(11) NOT NULL,
  `tipo` enum('ELECTOR','MIEMBRO_MESA','PERSONERO') NOT NULL,
  `id_titular` int(11) DEFAULT NULL,
  `motivo` varchar(255) NOT NULL,
  `estado` enum('PENDIENTE','APROBADA','RECHAZADA') NOT NULL DEFAULT 'PENDIENTE',
  `fecha_solicitud` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_atencion` datetime DEFAULT NULL,
  `id_usuario_atencion` int(11) DEFAULT NULL,
  `observacion_atencion` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id_solicitud`),
  KEY `fk_sol_proc` (`id_proceso`),
  KEY `fk_sol_doc` (`id_docente`),
  KEY `fk_sol_usu` (`id_usuario_atencion`),
  CONSTRAINT `fk_sol_doc` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`),
  CONSTRAINT `fk_sol_proc` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`),
  CONSTRAINT `fk_sol_usu` FOREIGN KEY (`id_usuario_atencion`) REFERENCES `usuario` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `solicitud_regeneracion_qr`
--

LOCK TABLES `solicitud_regeneracion_qr` WRITE;
/*!40000 ALTER TABLE `solicitud_regeneracion_qr` DISABLE KEYS */;
/*!40000 ALTER TABLE `solicitud_regeneracion_qr` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sorteo_compromiso`
--

DROP TABLE IF EXISTS `sorteo_compromiso`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sorteo_compromiso` (
  `ambito` varchar(40) NOT NULL,
  `secreto` char(64) NOT NULL,
  `compromiso` char(64) NOT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`ambito`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sorteo_compromiso`
--

LOCK TABLES `sorteo_compromiso` WRITE;
/*!40000 ALTER TABLE `sorteo_compromiso` DISABLE KEYS */;
/*!40000 ALTER TABLE `sorteo_compromiso` ENABLE KEYS */;
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
  `resolucion` text DEFAULT NULL,
  `id_usuario_resuelve` int(11) DEFAULT NULL,
  PRIMARY KEY (`id_tacha`),
  KEY `ix_tacha_estado` (`estado`),
  KEY `fk_tacha_denunciante` (`id_docente_denunciante`),
  KEY `fk_tacha_candidato` (`id_candidato`),
  KEY `fk_tacha_usuario` (`id_usuario_resuelve`),
  CONSTRAINT `fk_tacha_candidato` FOREIGN KEY (`id_candidato`) REFERENCES `candidato` (`id_candidato`),
  CONSTRAINT `fk_tacha_denunciante` FOREIGN KEY (`id_docente_denunciante`) REFERENCES `docente` (`id_docente`),
  CONSTRAINT `fk_tacha_usuario` FOREIGN KEY (`id_usuario_resuelve`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `chk_tacha_resolucion` CHECK (`estado` = 'PENDIENTE' and `fecha_resolucion` is null or `estado` <> 'PENDIENTE' and `fecha_resolucion` is not null)
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
-- Table structure for table `terminal_votacion`
--

DROP TABLE IF EXISTS `terminal_votacion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `terminal_votacion` (
  `id_terminal` int(11) NOT NULL AUTO_INCREMENT,
  `id_mesa` int(11) NOT NULL,
  `nombre` varchar(40) NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  `fecha_registro` datetime NOT NULL DEFAULT current_timestamp(),
  `ultima_conexion` datetime DEFAULT NULL,
  `secreto_hash` char(64) DEFAULT NULL,
  `id_usuario_conexion` int(11) DEFAULT NULL,
  PRIMARY KEY (`id_terminal`),
  UNIQUE KEY `uq_terminal_mesa_nombre` (`id_mesa`,`nombre`),
  CONSTRAINT `fk_terminal_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `terminal_votacion`
--

LOCK TABLES `terminal_votacion` WRITE;
/*!40000 ALTER TABLE `terminal_votacion` DISABLE KEYS */;
INSERT INTO `terminal_votacion` VALUES (1,1,'Cabina 1',0,'2026-11-25 09:30:34','2026-11-25 16:00:58','c4f837b91d6a2b514436f1f708ab5d4f9f72174e3cf96c9e2bacd28ce869b2fa',111),(2,2,'Cabina 1',0,'2026-11-25 09:18:09','2026-11-25 15:13:36','728d6d779518dd70e2684d3e6db7b9afdeb25a03431d1ce7bb71025556f8407a',3);
/*!40000 ALTER TABLE `terminal_votacion` ENABLE KEYS */;
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
  `id_usuario_creador` int(11) DEFAULT NULL COMMENT 'CUS18: administrador que creó la cuenta',
  `fecha_actualizacion` datetime DEFAULT NULL COMMENT 'CUS18: último cambio de rol, docente, estado o contraseña',
  `motivo_estado` varchar(300) DEFAULT NULL COMMENT 'CUS18: motivo de la última desactivación o reactivación',
  `debe_cambiar_password` tinyint(1) NOT NULL DEFAULT 0,
  `token_valido_desde` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id_usuario`),
  UNIQUE KEY `uq_usuario_username` (`username`),
  KEY `fk_usuario_docente` (`id_docente`),
  KEY `fk_usuario_creador` (`id_usuario_creador`),
  CONSTRAINT `fk_usuario_creador` FOREIGN KEY (`id_usuario_creador`) REFERENCES `usuario` (`id_usuario`) ON DELETE SET NULL,
  CONSTRAINT `fk_usuario_docente` FOREIGN KEY (`id_docente`) REFERENCES `docente` (`id_docente`)
) ENGINE=InnoDB AUTO_INCREMENT=121 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuario`
--

LOCK TABLES `usuario` WRITE;
/*!40000 ALTER TABLE `usuario` DISABLE KEYS */;
INSERT INTO `usuario` VALUES (1,NULL,'admin','$2a$10$t2mMtYn9x.03grbeLf2s3u5bX.Kj4pvCzqya2u/gW9zOgXWiTQVAm','ADMIN',1,0,NULL,'2026-11-25 18:15:54','2026-11-03 23:23:13',NULL,NULL,NULL,0,'2026-11-03 23:24:10.292'),(2,NULL,'ceunp','$2a$10$t2mMtYn9x.03grbeLf2s3u5bX.Kj4pvCzqya2u/gW9zOgXWiTQVAm','CEUNP',1,0,NULL,'2026-11-03 23:26:26','2026-11-03 23:24:10',NULL,NULL,NULL,0,NULL),(3,NULL,'lucanoxz','$2a$10$bSBp/wP7W3GYJv5wmKaz9uOgUHO8T1WlEAWIN2Xgire.bHHKR7cLO','CEUNP',1,0,NULL,'2026-11-25 20:33:22','2026-11-03 23:35:13',1,'2026-11-08 15:06:30',NULL,0,'2026-11-08 15:07:13.604'),(5,2,'mruiz','$2a$10$MuTXnSDePkFCBOiXWBV.Xe8M5SFcP3/.i.5y4kjgPSoXb7tycnPvy','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:18',NULL,NULL,NULL,1,NULL),(6,3,'jramos','$2a$10$J0Qc7FWsJsR3vJQ2oIt0juhR0zcuw2mQ.t.99RI.wP8EPR69VHV.u','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:18',NULL,NULL,NULL,1,NULL),(7,4,'acastro','$2a$10$nOoVI9pKEjc1eIe8g2oki.IgEkPdRqyJMZ90X/nWYQWwKvFEAbVsa','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:18',NULL,NULL,NULL,1,NULL),(8,5,'cbenites','$2a$10$tFnmbVwk76EQWWT.znMEru0PFv79q5OCVQn3L/.4qLRpMH29LPKtK','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:18',NULL,NULL,NULL,1,NULL),(9,6,'rsalazar','$2a$10$vv6ve6ELg3fW68.nQxJgY.oSpN7oyWGw/V1RAPSkD1u2Wa6bVTx26','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:18',NULL,NULL,NULL,1,NULL),(10,7,'pmorales','$2a$10$HqWwHwb.cc5adLx3p92gUO4yFh1RvWBiI5jOrfTZbp7yxQB2rfSAu','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:18',NULL,NULL,NULL,1,NULL),(11,8,'lfarfan','$2a$10$pHhrj0pDVyEMA3ycHqa4XugBLTz7S/MaVW05JBqvr4UhbJZjkWDTa','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:18',NULL,NULL,NULL,1,NULL),(12,9,'calban','$2a$10$sCOSQvNsUpeu1xuOv52OfOCV7Vd/fM55xQcuo2hvEGwHKEySP9mlG','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:18',NULL,NULL,NULL,1,NULL),(13,10,'mguerrero','$2a$10$VhkT4TjjJcqzFZFrO1SPJOk8wXbtLoRta2jXTUHOwAxM4.RAo54OC','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:18',NULL,NULL,NULL,1,NULL),(14,11,'svilela','$2a$10$jAo2kqoiSPkU3JQtfUkNJOxE.IZUXJtcLtIDZDs6i/7Wm6k8bD2PO','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:19',NULL,NULL,NULL,1,NULL),(15,12,'rojeda','$2a$10$YD0R.FaMRmvXL4GMEU3DpeNJcu1VJcFeYeTyuvdLhTSfw2kyZGwoa','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:19',NULL,NULL,NULL,1,NULL),(16,13,'dcalle','$2a$10$PE6X2Bd0MJPTKKlA8q1Vd.dWYKHqu9s5xKOCwp4r9aFlpdCc0pccm','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:19',NULL,NULL,NULL,1,NULL),(17,14,'vnavarro','$2a$10$stWmct2QquzJ/hfvoYZI0uWmzTY01rHc2u3qtCMgDJVBFFzMnIp4W','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:19',NULL,NULL,NULL,1,NULL),(18,15,'pyarleque','$2a$10$H/MMTAgc1L8SQhR61z3sCOiiSH60tdJz7OSKNOqRv9VM3BUPofRkS','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:19',NULL,NULL,NULL,1,NULL),(19,16,'ccoronado','$2a$10$hXr15rVLcdGrDTFRBsBkOOsG7kxyYjqbQDzbJt6DUme.fM3mHlBza','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:19',NULL,NULL,NULL,1,NULL),(20,17,'gipanaque','$2a$10$f1GHx/MvT4di8JU2RYrA1eZRNFps.PMRl3ga7Xmmfc4YpW36zU2Sq','DOCENTE',1,0,NULL,'2026-11-20 15:04:05','2026-11-08 15:08:19',NULL,'2026-11-08 18:00:22',NULL,0,'2026-11-08 18:00:52.509'),(21,18,'mtimana','$2a$10$xw8ZavRNE49HIB2G3jhseeuHguiyuAviCj8tTqncnJ52moSB4.5X2','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:19',NULL,NULL,NULL,1,NULL),(22,19,'mvalladolid','$2a$10$N451VuxZ/U3wBHmGxqCrN.fxfO4lyWI..151TdT6mIYNqEcP5ICbS','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:19',NULL,NULL,NULL,1,NULL),(23,20,'fseminario','$2a$10$4S1RuNFNWknTEOHyqbvu5OBDCTmM9z4/cnmAQmUHOOVmTmFH0twSu','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:19',NULL,NULL,NULL,1,NULL),(24,21,'schunga','$2a$10$3QSkndIorEZNUUxHIZcwUu1hGo3ji/LWqffAiJ7wEWg7pvB6MwRiO','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:19',NULL,NULL,NULL,1,NULL),(25,22,'greto','$2a$10$rddskhFsPhL6Kt/lrxQVyui6gpbt7QbjiAlSU80.w4eUI2raChhMi','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:20',NULL,NULL,NULL,1,NULL),(26,23,'vpazos','$2a$10$Xmgb9VcLBrh4Z7fzvJMpCOk8a6XBlZ0uM/KcdzLxY.Wc6K1ARQBs.','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:20',NULL,NULL,NULL,1,NULL),(27,24,'hpulache','$2a$10$o3LJNzi6sxjzRCRHF891J.Zg5KCv9WfdzpLIzi.optgqVNkOI5e0u','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:20',NULL,NULL,NULL,1,NULL),(28,25,'ncarhuapoma','$2a$10$BbWN8d59bORuhj45Astwt.kHtYI8aYngUGOGlb7WdUYGJX.lZltki','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:20',NULL,NULL,NULL,1,NULL),(29,26,'wzevallos','$2a$10$ndgn8BwvaAhk0XKow1qYWO2gqJX8e4hnZRvfhnRN9/1mMgOnH8x8e','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:20',NULL,NULL,NULL,1,NULL),(30,27,'cpalacios','$2a$10$dHFwI6wiuCvFNEnREniYHukAqkArsDZ1EaUmpBqAyFDJ6jmkx0WCG','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:20',NULL,NULL,NULL,1,NULL),(31,28,'osaavedra','$2a$10$huYrtLiBSIJwa1eeVmAuaeV3dXdq/5JIdhG5/cVSjdtSKgCasKjai','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:20',NULL,NULL,NULL,1,NULL),(32,29,'tgomez','$2a$10$uX3cd1iFW7dVDjkPo1OidOeMFp6vz7Pq4RfyJU/VSCGANCQsAc7Oi','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:20',NULL,NULL,NULL,1,NULL),(33,30,'ragurto','$2a$10$ZPJXqoVfOp8xbu2TKg6XTeqCrO8.xvrnULiVWM1vqpsnNyIlwSdCO','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:20',NULL,NULL,NULL,1,NULL),(34,31,'imontero','$2a$10$BqP5COxNGoSEOYUVUyMa5udvS.7iCibx6YwXMTYLd6i4aMD7Pfiwe','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:20',NULL,NULL,NULL,1,NULL),(35,32,'jfiestas','$2a$10$hTIS23XUfM8UjVOqydgtH.tuSKJUlGO3j.QWeQJRdVwILfAEi3mWi','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:20',NULL,NULL,NULL,1,NULL),(36,33,'kzapata','$2a$10$pAS.GIgBcGDYp/F4gFlrseQ0YLvtN9tyqEJ2jpWsudc03yf1cqD0G','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:21',NULL,NULL,NULL,1,NULL),(37,34,'asullon','$2a$10$O/DBgonSUEH0aTzVTp3WmOVGMGyOagvVl9C8xI9fRyrYmcbkIV5.C','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:21',NULL,NULL,NULL,1,NULL),(38,35,'respinoza','$2a$10$4BS9Nlx06d60DmXZ7SkXle2b6yjtXRY0MfIJM8vU9J7zAmP.N5MP.','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:21',NULL,NULL,NULL,1,NULL),(39,36,'mneyra','$2a$10$d/lOU9fi8XOidjoHcx456uelEWE74LVFIwUuodguXW7B4IsSXLluS','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:21',NULL,NULL,NULL,1,NULL),(40,37,'ldioses','$2a$10$BLkK5aPmmbc8imkTWPw3c.u6VTkLpP8XGJVabB5MXbqMeIfCkLFHC','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:21',NULL,NULL,NULL,1,NULL),(41,38,'acastillo','$2a$10$L3W.8sI4ns/IvhoRSby1ceilaBc0HCO6u8C8A.o6psS2zHW2ZbH/q','DOCENTE',1,1,NULL,NULL,'2026-11-08 15:08:21',NULL,NULL,NULL,1,NULL),(42,39,'brivas','$2a$10$UFgDGm4A4QG5gSsQXZFrvuJXINT.nUUxxx68UVgfQJmfPokXiRP0W','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:21',NULL,NULL,NULL,1,NULL),(43,40,'cbenites2','$2a$10$eBQlY2.amZn.RFSNrZZR5OiN6v2KmDzz1Ox.1y7aiPkzxG4mlu/om','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:21',NULL,NULL,NULL,1,NULL),(44,41,'kroman','$2a$10$Mq.W7ytCNP/DowQ0Eq5jOO3C7sdRMtvnzARurYo9bWWcb7wP7m5pS','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:21',NULL,NULL,NULL,1,NULL),(45,42,'dvilchez','$2a$10$WwAGbSkWd4Fzur2ZWWrfde6fuUm0HgExjojOQKC9GVZxhX1mO87sC','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:21',NULL,NULL,NULL,1,NULL),(46,43,'apacherres','$2a$10$KhS5UOfKpFMJatjpoLGCjubWyrjygWvTZmnr.VWWWLLqh0wtCqQYS','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:21',NULL,NULL,NULL,1,NULL),(47,44,'grequena','$2a$10$JbFP1N32wJY2yef.b6ruy.DDA.2T/VK1m53SUtSrjOYPrLrG5x/Vu','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:22',NULL,NULL,NULL,1,NULL),(48,45,'ysandoval','$2a$10$zItIWkHgdSbefumPPVcZyuYEreplKkdb0ulB76wpCzgoQcVpkEpje','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:22',NULL,NULL,NULL,1,NULL),(49,46,'rcordova','$2a$10$BJpmTo1yt1nQa5a1SfJxruMpVUqOwQ6fW2ze1XjVRrbCG1NAzUx1a','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:22',NULL,NULL,NULL,1,NULL),(50,47,'cprado','$2a$10$bHDkBQQKFH/K5K4dSirsyOldqBaVfyq6bxQ8VCLF3Ren7tfxpTe86','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:22',NULL,NULL,NULL,1,NULL),(51,48,'egarcia','$2a$10$hnp7dK23EKXYA5aoVww.8OFFB5U0sLkVKpCqN0u3nzSLln8TsxFKm','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:22',NULL,NULL,NULL,1,NULL),(52,49,'gtalledo','$2a$10$sSmy3aDlDHcFs4t776.GyOIQpyqpC.BCxMc4YSrhTG/1tpXlzVfYy','DOCENTE',1,0,NULL,'2026-11-20 17:38:52','2026-11-08 15:08:22',NULL,'2026-11-20 17:38:27',NULL,0,'2026-11-08 19:19:25.000'),(53,50,'rvilela','$2a$10$JgfBGC9U40J1mlG.5Lu.q.O6jOA2Cuw214rPut1TqqJg1b0ovh8nS','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:22',NULL,NULL,NULL,1,NULL),(54,51,'fcruz','$2a$10$fc8ByVwLnMHeQGdPfdV9AuzRhOZpdOLgDsLLKUv4M77ZH1vWjZLzq','DOCENTE',1,0,NULL,'2026-11-08 19:46:24','2026-11-08 15:08:22',NULL,'2026-12-06 09:04:36',NULL,0,'2026-11-08 19:19:25.000'),(55,52,'hmorales','$2a$10$flemp5eYrHGYRF96zRE6ruG.Cnq5.bbmzkoCcdiQGFe.hmGEgCpFW','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:22',NULL,NULL,NULL,1,NULL),(56,53,'galba','$2a$10$hX5150dxzu2BJJ0NxptCeOZyJSOD0Y/yOkNyyINN5ee7/soIGx916','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:22',NULL,NULL,NULL,1,NULL),(57,54,'gnole','$2a$10$sVQVee9niWQk.YRYYWoTruRM8DhFZ8oQ5RQxYHMiGTgLpZiiPnDoO','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:22',NULL,NULL,NULL,1,NULL),(58,55,'wpurizaca','$2a$10$iH4oWCwUbi2EE7e5VpOLie/sszoQNe02MlyDKa3NcXvkdxAJJI3Pe','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:22',NULL,NULL,NULL,1,NULL),(59,56,'ryamunaque','$2a$10$uklhbc6GCjpMEPtTSF5c0ecw7cNA5m7rVkarmuXrzOldWmkna1hmO','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:23',NULL,NULL,NULL,1,NULL),(60,57,'rtavara','$2a$10$yjTwdkzKYOzPHONRWrBeL.5SsCR.qguVNisrrudy1rpT088bj8CfK','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:23',NULL,NULL,NULL,1,NULL),(61,58,'schero','$2a$10$RWdULd/qhdWjdLvMBGU2WuVOyrbmQSkdlhc2bgXR2pWfjatcaTS62','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:23',NULL,NULL,NULL,1,NULL),(62,59,'tpurizaca','$2a$10$5OO9JxRUaUgixrIcqMIcXOY41wqyPi2yBn09N/CnsY5NM8J.X92HW','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:23',NULL,NULL,NULL,1,NULL),(63,60,'wvilchez','$2a$10$d5o7i.EdNDTUoRfYTUGaZ.PB/iH8BDZVi.8cRwhll1mDV5aIkQ.TG','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:23',NULL,NULL,NULL,1,NULL),(64,61,'zchunga','$2a$10$P3YrfleobRP1dqHSI30p9OnxYxKkHWohv1OKdtZq2GGZvz4qkYun2','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:23',NULL,NULL,NULL,1,NULL),(65,62,'amorales','$2a$10$io5Fwhisnfs8N5pvKGXkDeqBdD2amz2wrIfnJJR9iIJPK8/ykECH.','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:23',NULL,NULL,NULL,1,NULL),(66,63,'bfarfan','$2a$10$vY428.N8Snv6ivvXzV4cDudmN83hxOSTCVA17JdD1Wxg2AN/gIrXK','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:23',NULL,NULL,NULL,1,NULL),(67,64,'cyovera','$2a$10$7ZgwCZqGxVSt1UId3f5T0.vQoItonEgjmZcstotSlZQdDx1k7HQRy','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:23',NULL,NULL,NULL,1,NULL),(68,65,'dcherres','$2a$10$d2VdtHlovGuBdK0Ec5PWrOn1PketumGXvA9Vja496QfPNW6NUQxie','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:23',NULL,NULL,NULL,1,NULL),(69,66,'esilva','$2a$10$5aaKQIdObKqX11KvAtCUou9lNcRt4oP8pFklpCSApUyjvSD634MyK','DOCENTE',1,0,NULL,'2026-12-06 09:06:24','2026-11-08 15:08:23',NULL,'2026-12-06 09:06:11',NULL,0,'2026-11-08 19:19:25.000'),(70,67,'fsullon','$2a$10$c6yxlNPqLBfI6K4/CiICQe2eh2GX9Z18UkX96JKCKVf/gCupuCip6','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:24',NULL,NULL,NULL,1,NULL),(71,68,'gipanaque2','$2a$10$nKKDQNijLju9WMpCOza2NOyD.UGTTnVcjTTSNomAmnADR5oU40C9O','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:24',NULL,NULL,NULL,1,NULL),(72,69,'hpasapera','$2a$10$S2R9J/UkgXQVHXsnrlluOutD9CZBP7Cr1oKvxNkUhX5fUnlabcTdq','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:24',NULL,NULL,NULL,1,NULL),(77,74,'kdioses','$2a$10$n26eIZ1cLzqmGikunC5kYezNv9YMJGsA.n3R7dhalWtZ16nqSFEAG','DOCENTE',1,0,NULL,'2026-11-12 14:40:11','2026-11-08 15:08:24',NULL,'2026-11-20 17:35:21',NULL,0,'2026-11-08 19:19:25.000'),(78,75,'lyarleque','$2a$10$L1iraWDESLH6d/xvIJcmgeVRpj07560pOgkSm0hh7r/AFI4Pw8Toa','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:24',NULL,NULL,NULL,1,NULL),(79,76,'mchero','$2a$10$2dO6jY9p0XJr.IEFw8ge1udb2CR.ivYutRaO7Jey0daiBguCjrOza','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:24',NULL,NULL,NULL,1,NULL),(80,77,'nsilva','$2a$10$7PVtP9vm/P.mZFtLlp2oReYYKfuBNA/oi5z6bNcVQJlvtdCvV5svO','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:24',NULL,NULL,NULL,1,NULL),(81,78,'oyamunaque','$2a$10$j0ghvPwTxZp2HGQqrXG9MexyFcFCRSrBcd0z2wSW8QumYIKbkUgMS','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:24',NULL,NULL,NULL,1,NULL),(82,79,'ptavara','$2a$10$iFOd1q26ldIos/vIjhHQ.O7GXKGG89OsfuBZNofRsBCPond5XyWMu','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:25',NULL,NULL,NULL,1,NULL),(83,80,'rsullon','$2a$10$8caDq5mgPC9tS0AUZ6ZtTewoK1afG6s5CYhhjp3WIxEthsKLkNU.K','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:25',NULL,NULL,NULL,1,NULL),(84,81,'syovera','$2a$10$Mi7MzX0Qv3dIuUfzCFsbReC6uq2eeCEqvuYDQFD6QUgxxh3tRVBqa','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:25',NULL,NULL,NULL,1,NULL),(85,82,'tcherres','$2a$10$oJi.zerFbxqyadCiYxx58ewX8lCWW/mwe.veeJVMYe1v0mIIWMV6a','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:25',NULL,NULL,NULL,1,NULL),(86,83,'upasapera','$2a$10$riUXwHm6YfsBHPlbw8r.reak3WAj6AjF.RDfGeGvO5rsJWSru4kra','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:25',NULL,NULL,NULL,1,NULL),(87,84,'vchero','$2a$10$Ls4fiySuhbkSaiIWVpBQ.uyrICyYB2fiiF0MwxPeCNqkAfwO2IKeW','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:25',NULL,NULL,NULL,1,NULL),(88,85,'wipanaque','$2a$10$zzsTyQhL6HCQNu6bU6G6HuPV8AATMeue914XFB7ZRSwI1fmLrNeKy','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:25',NULL,NULL,NULL,1,NULL),(89,86,'xsilva','$2a$10$.iweNNELuhB63rDu81ych.AglPsYPIq.CphqJLdyS38AW8RuEgNI6','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:25',NULL,NULL,NULL,1,NULL),(90,87,'yyamunaque','$2a$10$OGxWvyn5r4LYTW4uuvvAf.8RZwwLIla4iHifH82nETuxKt/O6jHFO','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:25',NULL,NULL,NULL,1,NULL),(91,88,'ztavara','$2a$10$VuTSHzRCU/RbEaKapb80felEXVDlM4G5HDtmbsQLELfxJqgqHykAu','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:25',NULL,NULL,NULL,1,NULL),(92,89,'achero','$2a$10$ApNE1mtLwp8pNG4NbBk.bOad8HpRJMFk76BUu2fCBa33bYWDJvU8m','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:25',NULL,NULL,NULL,1,NULL),(93,90,'bipanaque','$2a$10$bbPJdqW04bLjWD3.sgPezeMwdg9pBuMA7yDS/K835WWGYGtrDxRf6','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:26',NULL,NULL,NULL,1,NULL),(94,91,'cyovera2','$2a$10$cs2S3bT2J/OeK1loj8nEVOIU6l4YoQY2tIczMiLzv8YuxnMjCyqse','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:26',NULL,NULL,NULL,1,NULL),(95,92,'dcherres2','$2a$10$0jgneAGD5q1LtrGizak4BOvXGJV7mAQL2PBykRQZQM1QeDsbIcDBi','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:26',NULL,NULL,NULL,1,NULL),(96,93,'esilva2','$2a$10$UlZV4vVnzUu1EnDes8XHxehdj0leOkj7xJxDahmslInGTpIBUu1ly','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:26',NULL,NULL,NULL,1,NULL),(97,94,'fyamunaque','$2a$10$HACAFBfXeZzF7b7JuS3oR.RQG67CM/LWLaxWcY9PwRr6WViKkTORG','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:26',NULL,NULL,NULL,1,NULL),(98,95,'gtavara','$2a$10$DXGxKbwNZHzHRF7t/Hqj1OFmbn.PAtN9BOSe6zMd1kd9KouPkXSZ2','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:26',NULL,NULL,NULL,1,NULL),(99,96,'hsullon','$2a$10$eg7U7QQ1EgtEBaPKdZ/zUODq9RuzExozqbru9voOv/b65kkcHc5Pa','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:26',NULL,NULL,NULL,1,NULL),(100,97,'ipasapera','$2a$10$8/vMnR.PLB0IpvjwZT8CLe0oQI9rUu7u5z5fL3BEZrV6ng8g7hCOC','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:26',NULL,NULL,NULL,1,NULL),(101,98,'jchero','$2a$10$IHkLojfa7ojQabsemvqYb.UfCVxEnP6rB1.WkO8Q8XgvIIOMouPnS','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:26',NULL,NULL,NULL,1,NULL),(102,99,'kyovera','$2a$10$1Fy5RwpsdX6g4xVRSayAveX13neClVLi5Fax8ghE26C0b39XffAmu','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:26',NULL,NULL,NULL,1,NULL),(103,100,'lsilva','$2a$10$bjewQgaxKozM0s67Q4bmWe5l8Vy.2RmtpVqUmWv.l8eBVQzqEDlHa','DOCENTE',1,0,NULL,NULL,'2026-11-08 15:08:27',NULL,NULL,NULL,1,NULL),(104,101,'jalvarado','$2a$10$PoKWP5YvcUJdR9IUVII7NOxeIPjQVPR64o9WUXGlOIAC0N9pB1azK','DOCENTE',1,0,NULL,NULL,'2026-11-25 10:53:25',NULL,NULL,NULL,0,NULL),(105,102,'rcorrea','$2a$10$PoKWP5YvcUJdR9IUVII7NOxeIPjQVPR64o9WUXGlOIAC0N9pB1azK','DOCENTE',1,0,NULL,NULL,'2026-11-25 10:53:25',NULL,NULL,NULL,0,NULL),(106,103,'pcriollo','$2a$10$PoKWP5YvcUJdR9IUVII7NOxeIPjQVPR64o9WUXGlOIAC0N9pB1azK','DOCENTE',1,0,NULL,NULL,'2026-11-25 10:53:25',NULL,NULL,NULL,0,NULL),(107,104,'wcruzy','$2a$10$PoKWP5YvcUJdR9IUVII7NOxeIPjQVPR64o9WUXGlOIAC0N9pB1azK','DOCENTE',1,0,NULL,'2026-11-25 18:17:00','2026-11-25 10:53:25',NULL,NULL,NULL,0,NULL),(108,105,'hfiestasb','$2a$10$PoKWP5YvcUJdR9IUVII7NOxeIPjQVPR64o9WUXGlOIAC0N9pB1azK','DOCENTE',1,0,NULL,NULL,'2026-11-25 10:53:25',NULL,NULL,NULL,0,NULL),(109,106,'iiman','$2a$10$PoKWP5YvcUJdR9IUVII7NOxeIPjQVPR64o9WUXGlOIAC0N9pB1azK','DOCENTE',1,0,NULL,NULL,'2026-11-25 10:53:25',NULL,NULL,NULL,0,NULL),(110,107,'ripanaque','$2a$10$PoKWP5YvcUJdR9IUVII7NOxeIPjQVPR64o9WUXGlOIAC0N9pB1azK','DOCENTE',1,0,NULL,'2026-11-25 15:05:46','2026-11-25 10:53:25',NULL,NULL,NULL,0,NULL),(111,108,'elizana','$2a$10$PoKWP5YvcUJdR9IUVII7NOxeIPjQVPR64o9WUXGlOIAC0N9pB1azK','DOCENTE',1,0,NULL,'2026-11-25 15:27:41','2026-11-25 10:53:25',NULL,NULL,NULL,0,NULL),(112,109,'jnima','$2a$10$PoKWP5YvcUJdR9IUVII7NOxeIPjQVPR64o9WUXGlOIAC0N9pB1azK','DOCENTE',1,0,NULL,NULL,'2026-11-25 10:53:25',NULL,NULL,NULL,0,NULL),(113,110,'hpuicon','$2a$10$PoKWP5YvcUJdR9IUVII7NOxeIPjQVPR64o9WUXGlOIAC0N9pB1azK','DOCENTE',1,0,NULL,NULL,'2026-11-25 10:53:25',NULL,NULL,NULL,0,NULL),(114,111,'rrequenaf','$2a$10$PoKWP5YvcUJdR9IUVII7NOxeIPjQVPR64o9WUXGlOIAC0N9pB1azK','DOCENTE',1,0,NULL,NULL,'2026-11-25 10:53:25',NULL,NULL,NULL,0,NULL),(115,112,'msaavedra','$2a$10$PoKWP5YvcUJdR9IUVII7NOxeIPjQVPR64o9WUXGlOIAC0N9pB1azK','DOCENTE',1,0,NULL,NULL,'2026-11-25 10:53:25',NULL,NULL,NULL,0,NULL),(116,113,'lsaavedray','$2a$10$PoKWP5YvcUJdR9IUVII7NOxeIPjQVPR64o9WUXGlOIAC0N9pB1azK','DOCENTE',1,0,NULL,NULL,'2026-11-25 10:53:25',NULL,NULL,NULL,0,NULL),(117,114,'asandoval','$2a$10$PoKWP5YvcUJdR9IUVII7NOxeIPjQVPR64o9WUXGlOIAC0N9pB1azK','DOCENTE',1,0,NULL,NULL,'2026-11-25 10:53:25',NULL,NULL,NULL,0,NULL),(118,115,'jsandoval','$2a$10$PoKWP5YvcUJdR9IUVII7NOxeIPjQVPR64o9WUXGlOIAC0N9pB1azK','DOCENTE',1,0,NULL,'2026-11-25 15:05:36','2026-11-25 10:53:25',NULL,NULL,NULL,0,NULL),(119,116,'csilva','$2a$10$PoKWP5YvcUJdR9IUVII7NOxeIPjQVPR64o9WUXGlOIAC0N9pB1azK','DOCENTE',1,0,NULL,NULL,'2026-11-25 10:53:25',NULL,NULL,NULL,0,NULL),(120,117,'vvalle','$2a$10$PoKWP5YvcUJdR9IUVII7NOxeIPjQVPR64o9WUXGlOIAC0N9pB1azK','DOCENTE',1,0,NULL,'2026-11-25 10:14:10','2026-11-25 10:53:25',NULL,NULL,NULL,0,NULL);
/*!40000 ALTER TABLE `usuario` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_usuario_admin_bu BEFORE UPDATE ON usuario
FOR EACH ROW
BEGIN
  IF OLD.rol = 'ADMIN' AND OLD.activo = 1 AND (NEW.rol <> 'ADMIN' OR NEW.activo = 0)
     AND NOT EXISTS (SELECT 1 FROM usuario WHERE rol = 'ADMIN' AND activo = 1 AND id_usuario <> OLD.id_usuario) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: debe quedar al menos un administrador activo.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_usuario_revocar_bu BEFORE UPDATE ON usuario
FOR EACH ROW
BEGIN
  IF NOT (NEW.password_hash <=> OLD.password_hash) OR (OLD.activo = 1 AND NEW.activo = 0) THEN
    SET NEW.token_valido_desde = NOW(3);
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_usuario_admin_bd BEFORE DELETE ON usuario
FOR EACH ROW
BEGIN
  IF OLD.rol = 'ADMIN' AND OLD.activo = 1
     AND NOT EXISTS (SELECT 1 FROM usuario WHERE rol = 'ADMIN' AND activo = 1 AND id_usuario <> OLD.id_usuario) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: debe quedar al menos un administrador activo.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Temporary table structure for view `v_bitacora`
--

DROP TABLE IF EXISTS `v_bitacora`;
/*!50001 DROP VIEW IF EXISTS `v_bitacora`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_bitacora` AS SELECT
 1 AS `id_log`,
  1 AS `fecha_hora`,
  1 AS `accion`,
  1 AS `etiqueta`,
  1 AS `descripcion_accion`,
  1 AS `modulo`,
  1 AS `caso_uso`,
  1 AS `criticidad`,
  1 AS `catalogada`,
  1 AS `id_usuario`,
  1 AS `username`,
  1 AS `rol`,
  1 AS `usuario_docente`,
  1 AS `id_docente`,
  1 AS `docente`,
  1 AS `dni_docente`,
  1 AS `id_proceso`,
  1 AS `proceso`,
  1 AS `ip_origen`,
  1 AS `user_agent`,
  1 AS `detalle_json`,
  1 AS `hash_anterior`,
  1 AS `hash_registro` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_candidatos_publicos`
--

DROP TABLE IF EXISTS `v_candidatos_publicos`;
/*!50001 DROP VIEW IF EXISTS `v_candidatos_publicos`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_candidatos_publicos` AS SELECT
 1 AS `id_proceso`,
  1 AS `cargo`,
  1 AS `lista`,
  1 AS `url_plan_gobierno`,
  1 AS `rol_en_lista`,
  1 AS `candidato`,
  1 AS `categoria`,
  1 AS `grado_academico`,
  1 AS `facultad`,
  1 AS `url_hoja_vida` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_cedula_votacion`
--

DROP TABLE IF EXISTS `v_cedula_votacion`;
/*!50001 DROP VIEW IF EXISTS `v_cedula_votacion`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_cedula_votacion` AS SELECT
 1 AS `id_proceso`,
  1 AS `id_cargo`,
  1 AS `cargo`,
  1 AS `id_lista`,
  1 AS `orden_cedula`,
  1 AS `lista`,
  1 AS `simbolo`,
  1 AS `rol_en_lista`,
  1 AS `candidato` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_computo_actas`
--

DROP TABLE IF EXISTS `v_computo_actas`;
/*!50001 DROP VIEW IF EXISTS `v_computo_actas`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_computo_actas` AS SELECT
 1 AS `id_proceso`,
  1 AS `id_mesa`,
  1 AS `numero_mesa`,
  1 AS `id_acta`,
  1 AS `tipo`,
  1 AS `estado`,
  1 AS `fecha_emision`,
  1 AS `hash_integridad`,
  1 AS `integra`,
  1 AS `dudosa`,
  1 AS `motivo_duda`,
  1 AS `fecha_marca`,
  1 AS `comprobacion`,
  1 AS `huella_coincide`,
  1 AS `qr_coincide`,
  1 AS `observacion_comprobacion`,
  1 AS `fecha_comprobacion` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_computo_conteo_mesa`
--

DROP TABLE IF EXISTS `v_computo_conteo_mesa`;
/*!50001 DROP VIEW IF EXISTS `v_computo_conteo_mesa`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_computo_conteo_mesa` AS SELECT
 1 AS `id_proceso`,
  1 AS `id_mesa`,
  1 AS `numero_mesa`,
  1 AS `id_cargo`,
  1 AS `opcion`,
  1 AS `id_lista`,
  1 AS `votos_acta`,
  1 AS `impugnados_asignados`,
  1 AS `votos`,
  1 AS `votos_digital` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_computo_mesas`
--

DROP TABLE IF EXISTS `v_computo_mesas`;
/*!50001 DROP VIEW IF EXISTS `v_computo_mesas`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_computo_mesas` AS SELECT
 1 AS `id_proceso`,
  1 AS `id_mesa`,
  1 AS `numero_mesa`,
  1 AS `ubicacion`,
  1 AS `estado`,
  1 AS `total_electores`,
  1 AS `estado_escrutinio`,
  1 AS `total_votantes`,
  1 AS `cedulas_escrutadas`,
  1 AS `observada`,
  1 AS `prevalece_fisica`,
  1 AS `conteo_cuadra`,
  1 AS `total_cuadra`,
  1 AS `fecha_entrega`,
  1 AS `recibido_por`,
  1 AS `codigo_cargo`,
  1 AS `actas_vigentes`,
  1 AS `actas_alteradas`,
  1 AS `actas_dudosas`,
  1 AS `actas_no_autenticas`,
  1 AS `impugnaciones`,
  1 AS `impugnaciones_pendientes`,
  1 AS `requiere_calificacion`,
  1 AS `calificacion`,
  1 AS `motivo_revision`,
  1 AS `fundamento_calificacion`,
  1 AS `resolucion_calificacion`,
  1 AS `fecha_calificacion`,
  1 AS `situacion` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_computo_resultados`
--

DROP TABLE IF EXISTS `v_computo_resultados`;
/*!50001 DROP VIEW IF EXISTS `v_computo_resultados`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_computo_resultados` AS SELECT
 1 AS `id_proceso`,
  1 AS `id_cargo`,
  1 AS `cargo`,
  1 AS `opcion`,
  1 AS `id_lista`,
  1 AS `lista`,
  1 AS `orden_cedula`,
  1 AS `mesas`,
  1 AS `votos_actas`,
  1 AS `impugnados_asignados`,
  1 AS `votos`,
  1 AS `votos_digital` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_cotejos_acta`
--

DROP TABLE IF EXISTS `v_cotejos_acta`;
/*!50001 DROP VIEW IF EXISTS `v_cotejos_acta`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_cotejos_acta` AS SELECT
 1 AS `id_cotejo`,
  1 AS `id_proceso`,
  1 AS `proceso`,
  1 AS `tipo_documento`,
  1 AS `id_documento`,
  1 AS `id_mesa`,
  1 AS `numero_mesa`,
  1 AS `hash_integridad`,
  1 AS `contenido_integro`,
  1 AS `lineas`,
  1 AS `diferencias`,
  1 AS `observacion`,
  1 AS `estado`,
  1 AS `fecha`,
  1 AS `id_usuario`,
  1 AS `username`,
  1 AS `rol`,
  1 AS `registrado_por`,
  1 AS `id_personero`,
  1 AS `lista_personero`,
  1 AS `tipo_personero`,
  1 AS `decision`,
  1 AS `respuesta`,
  1 AS `fecha_respuesta`,
  1 AS `atendido_por`,
  1 AS `cifras_json` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_cuadre_votos`
--

DROP TABLE IF EXISTS `v_cuadre_votos`;
/*!50001 DROP VIEW IF EXISTS `v_cuadre_votos`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_cuadre_votos` AS SELECT
 1 AS `id_proceso`,
  1 AS `id_cargo`,
  1 AS `cargo`,
  1 AS `electores_que_votaron`,
  1 AS `votos_en_urna`,
  1 AS `diferencia` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_docente_detalle`
--

DROP TABLE IF EXISTS `v_docente_detalle`;
/*!50001 DROP VIEW IF EXISTS `v_docente_detalle`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_docente_detalle` AS SELECT
 1 AS `id_docente`,
  1 AS `dni`,
  1 AS `apellidos`,
  1 AS `nombres`,
  1 AS `nombre_completo`,
  1 AS `categoria`,
  1 AS `dedicacion`,
  1 AS `grado_academico`,
  1 AS `estado`,
  1 AS `habilitado_para_votar`,
  1 AS `id_facultad`,
  1 AS `facultad`,
  1 AS `id_departamento`,
  1 AS `departamento`,
  1 AS `es_autoridad_vigente` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_documentos_verificables`
--

DROP TABLE IF EXISTS `v_documentos_verificables`;
/*!50001 DROP VIEW IF EXISTS `v_documentos_verificables`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_documentos_verificables` AS SELECT
 1 AS `id_proceso`,
  1 AS `tipo_documento`,
  1 AS `id_documento`,
  1 AS `id_mesa`,
  1 AS `numero_mesa`,
  1 AS `numero_resolucion`,
  1 AS `fecha_emision`,
  1 AS `estado`,
  1 AS `hash_integridad`,
  1 AS `integra`,
  1 AS `firmas`,
  1 AS `verificaciones`,
  1 AS `cotejos`,
  1 AS `observados` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_elegibles_sorteo`
--

DROP TABLE IF EXISTS `v_elegibles_sorteo`;
/*!50001 DROP VIEW IF EXISTS `v_elegibles_sorteo`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_elegibles_sorteo` AS SELECT
 1 AS `id_proceso`,
  1 AS `id_mesa`,
  1 AS `id_docente`,
  1 AS `dni`,
  1 AS `docente` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_impugnacion_efecto`
--

DROP TABLE IF EXISTS `v_impugnacion_efecto`;
/*!50001 DROP VIEW IF EXISTS `v_impugnacion_efecto`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_impugnacion_efecto` AS SELECT
 1 AS `id_impugnacion`,
  1 AS `id_proceso`,
  1 AS `id_mesa`,
  1 AS `id_cargo`,
  1 AS `situacion`,
  1 AS `opcion_vigente`,
  1 AS `id_lista_vigente` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_impugnaciones_mesa_cargo`
--

DROP TABLE IF EXISTS `v_impugnaciones_mesa_cargo`;
/*!50001 DROP VIEW IF EXISTS `v_impugnaciones_mesa_cargo`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_impugnaciones_mesa_cargo` AS SELECT
 1 AS `id_proceso`,
  1 AS `id_mesa`,
  1 AS `id_cargo`,
  1 AS `opcion_vigente`,
  1 AS `id_lista_vigente`,
  1 AS `cedulas`,
  1 AS `firmes` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_mesa_detalle`
--

DROP TABLE IF EXISTS `v_mesa_detalle`;
/*!50001 DROP VIEW IF EXISTS `v_mesa_detalle`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_mesa_detalle` AS SELECT
 1 AS `id_proceso`,
  1 AS `id_mesa`,
  1 AS `numero_mesa`,
  1 AS `ubicacion`,
  1 AS `estado`,
  1 AS `total_electores`,
  1 AS `hora_instalacion`,
  1 AS `hora_cierre`,
  1 AS `fecha_sorteo`,
  1 AS `semilla_sorteo`,
  1 AS `miembros`,
  1 AS `electores_que_votaron`,
  1 AS `actas_emitidas` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_miembros_mesa`
--

DROP TABLE IF EXISTS `v_miembros_mesa`;
/*!50001 DROP VIEW IF EXISTS `v_miembros_mesa`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_miembros_mesa` AS SELECT
 1 AS `id_proceso`,
  1 AS `id_mesa`,
  1 AS `numero_mesa`,
  1 AS `orden_sorteo`,
  1 AS `rol`,
  1 AS `titular`,
  1 AS `asistio`,
  1 AS `id_docente`,
  1 AS `dni`,
  1 AS `docente`,
  1 AS `facultad` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_multas_detalle`
--

DROP TABLE IF EXISTS `v_multas_detalle`;
/*!50001 DROP VIEW IF EXISTS `v_multas_detalle`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_multas_detalle` AS SELECT
 1 AS `id_multa`,
  1 AS `id_proceso`,
  1 AS `proceso`,
  1 AS `id_docente`,
  1 AS `dni`,
  1 AS `docente`,
  1 AS `facultad`,
  1 AS `motivo`,
  1 AS `uit_referencia`,
  1 AS `porcentaje_uit`,
  1 AS `monto`,
  1 AS `estado_pago`,
  1 AS `fecha_generacion`,
  1 AS `fecha_pago`,
  1 AS `tipo_proceso`,
  1 AS `estado_proceso`,
  1 AS `departamento`,
  1 AS `categoria`,
  1 AS `email`,
  1 AS `id_mesa`,
  1 AS `numero_mesa`,
  1 AS `ubicacion`,
  1 AS `rol_mesa`,
  1 AS `asistio_sin_votar`,
  1 AS `observacion`,
  1 AS `fecha_notificacion`,
  1 AS `medio_notificacion`,
  1 AS `documento_notificacion`,
  1 AS `numero_recibo`,
  1 AS `fecha_actualizacion`,
  1 AS `estado_reporte`,
  1 AS `resolucion_multas`,
  1 AS `fecha_resolucion_multas`,
  1 AS `descargos`,
  1 AS `id_justificacion`,
  1 AS `tipo_descargo`,
  1 AS `causal_descargo`,
  1 AS `decision_descargo`,
  1 AS `resolucion_descargo`,
  1 AS `fecha_descargo`,
  1 AS `limite_justificacion` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_nulidades`
--

DROP TABLE IF EXISTS `v_nulidades`;
/*!50001 DROP VIEW IF EXISTS `v_nulidades`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_nulidades` AS SELECT
 1 AS `id_nulidad`,
  1 AS `id_proceso`,
  1 AS `proceso`,
  1 AS `estado_proceso`,
  1 AS `tipo_proceso`,
  1 AS `alcance`,
  1 AS `id_mesa`,
  1 AS `numero_mesa`,
  1 AS `ubicacion`,
  1 AS `estado_mesa`,
  1 AS `causal`,
  1 AS `origen`,
  1 AS `id_personero`,
  1 AS `personero`,
  1 AS `lista_personero`,
  1 AS `tipo_personero`,
  1 AS `sustento`,
  1 AS `pruebas`,
  1 AS `etapa`,
  1 AS `fecha_presentacion`,
  1 AS `registrado_por`,
  1 AS `estado`,
  1 AS `numero_resolucion`,
  1 AS `fundamento_resolucion`,
  1 AS `miembros_pleno`,
  1 AS `votos_favor`,
  1 AS `votos_contra`,
  1 AS `voto_dirimente`,
  1 AS `fecha_resolucion`,
  1 AS `resuelto_por`,
  1 AS `hash_integridad`,
  1 AS `resolucion_integra`,
  1 AS `comunicaciones`,
  1 AS `comunicaciones_oficio`,
  1 AS `fecha_portal` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_omisos_proceso`
--

DROP TABLE IF EXISTS `v_omisos_proceso`;
/*!50001 DROP VIEW IF EXISTS `v_omisos_proceso`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_omisos_proceso` AS SELECT
 1 AS `id_proceso`,
  1 AS `id_docente`,
  1 AS `motivo`,
  1 AS `id_mesa`,
  1 AS `rol_mesa`,
  1 AS `asistio_sin_votar` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_padron_detalle`
--

DROP TABLE IF EXISTS `v_padron_detalle`;
/*!50001 DROP VIEW IF EXISTS `v_padron_detalle`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_padron_detalle` AS SELECT
 1 AS `id_proceso`,
  1 AS `id_cargo`,
  1 AS `cargo`,
  1 AS `id_docente`,
  1 AS `dni`,
  1 AS `docente`,
  1 AS `categoria`,
  1 AS `facultad`,
  1 AS `habilitado_para_votar`,
  1 AS `ya_voto`,
  1 AS `fecha_votacion`,
  1 AS `motivo_inhabilitacion`,
  1 AS `id_mesa`,
  1 AS `numero_mesa`,
  1 AS `ubicacion` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_parametro_historial`
--

DROP TABLE IF EXISTS `v_parametro_historial`;
/*!50001 DROP VIEW IF EXISTS `v_parametro_historial`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_parametro_historial` AS SELECT
 1 AS `id_historial`,
  1 AS `clave`,
  1 AS `etiqueta`,
  1 AS `unidad`,
  1 AS `valor_anterior`,
  1 AS `valor_nuevo`,
  1 AS `motivo`,
  1 AS `origen`,
  1 AS `id_usuario`,
  1 AS `username`,
  1 AS `ip`,
  1 AS `fecha` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_parametros_admin`
--

DROP TABLE IF EXISTS `v_parametros_admin`;
/*!50001 DROP VIEW IF EXISTS `v_parametros_admin`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_parametros_admin` AS SELECT
 1 AS `clave`,
  1 AS `valor`,
  1 AS `descripcion`,
  1 AS `grupo`,
  1 AS `etiqueta`,
  1 AS `tipo`,
  1 AS `minimo`,
  1 AS `maximo`,
  1 AS `unidad`,
  1 AS `referencia`,
  1 AS `bloqueo_jornada`,
  1 AS `orden`,
  1 AS `bloqueado`,
  1 AS `cambios`,
  1 AS `fecha_ultimo_cambio`,
  1 AS `modificado_por` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_participacion_cargo`
--

DROP TABLE IF EXISTS `v_participacion_cargo`;
/*!50001 DROP VIEW IF EXISTS `v_participacion_cargo`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_participacion_cargo` AS SELECT
 1 AS `id_proceso`,
  1 AS `id_cargo`,
  1 AS `cargo`,
  1 AS `electores_habiles`,
  1 AS `votaron`,
  1 AS `faltan`,
  1 AS `participacion_pct`,
  1 AS `quorum_minimo`,
  1 AS `alcanza_quorum` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_portal_nulidades`
--

DROP TABLE IF EXISTS `v_portal_nulidades`;
/*!50001 DROP VIEW IF EXISTS `v_portal_nulidades`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_portal_nulidades` AS SELECT
 1 AS `id_nulidad`,
  1 AS `id_proceso`,
  1 AS `proceso`,
  1 AS `tipo`,
  1 AS `estado_proceso`,
  1 AS `alcance`,
  1 AS `numero_mesa`,
  1 AS `causal`,
  1 AS `numero_resolucion`,
  1 AS `fundamento_resolucion`,
  1 AS `fecha_resolucion`,
  1 AS `fecha_publicacion`,
  1 AS `hash_integridad`,
  1 AS `comunicado_a` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_portal_resultados`
--

DROP TABLE IF EXISTS `v_portal_resultados`;
/*!50001 DROP VIEW IF EXISTS `v_portal_resultados`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_portal_resultados` AS SELECT
 1 AS `id_proceso`,
  1 AS `proceso`,
  1 AS `tipo`,
  1 AS `estado_proceso`,
  1 AS `resultado`,
  1 AS `participacion_pct`,
  1 AS `electores_habiles`,
  1 AS `votaron`,
  1 AS `numero_resolucion`,
  1 AS `fecha_computo`,
  1 AS `fecha_proclamacion`,
  1 AS `fecha_publicacion` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_quorum_proceso`
--

DROP TABLE IF EXISTS `v_quorum_proceso`;
/*!50001 DROP VIEW IF EXISTS `v_quorum_proceso`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_quorum_proceso` AS SELECT
 1 AS `id_proceso`,
  1 AS `nombre`,
  1 AS `estado`,
  1 AS `tipo`,
  1 AS `quorum_minimo`,
  1 AS `electores_habiles`,
  1 AS `votaron`,
  1 AS `participacion_pct`,
  1 AS `alcanza_quorum` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_reporte_gestion_mesas`
--

DROP TABLE IF EXISTS `v_reporte_gestion_mesas`;
/*!50001 DROP VIEW IF EXISTS `v_reporte_gestion_mesas`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_reporte_gestion_mesas` AS SELECT
 1 AS `id_proceso`,
  1 AS `id_mesa`,
  1 AS `numero_mesa`,
  1 AS `ubicacion`,
  1 AS `estado`,
  1 AS `hora_instalacion`,
  1 AS `hora_cierre`,
  1 AS `electores`,
  1 AS `votaron`,
  1 AS `asistieron`,
  1 AS `titulares_presentes`,
  1 AS `titulares_ausentes`,
  1 AS `suplentes_en_funcion`,
  1 AS `incidencias`,
  1 AS `atencion_promedio_seg`,
  1 AS `actas_emitidas`,
  1 AS `estado_escrutinio`,
  1 AS `fecha_entrega`,
  1 AS `recibido_por` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_respaldos`
--

DROP TABLE IF EXISTS `v_respaldos`;
/*!50001 DROP VIEW IF EXISTS `v_respaldos`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_respaldos` AS SELECT
 1 AS `id_respaldo`,
  1 AS `nombre_archivo`,
  1 AS `motivo`,
  1 AS `tablas`,
  1 AS `vistas`,
  1 AS `rutinas`,
  1 AS `disparadores`,
  1 AS `filas`,
  1 AS `tamano_bytes`,
  1 AS `hash_sha256`,
  1 AS `id_usuario`,
  1 AS `username`,
  1 AS `ip`,
  1 AS `fecha_inicio`,
  1 AS `fecha_fin`,
  1 AS `duracion_seg` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_resultados_cargo`
--

DROP TABLE IF EXISTS `v_resultados_cargo`;
/*!50001 DROP VIEW IF EXISTS `v_resultados_cargo`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_resultados_cargo` AS SELECT
 1 AS `id_proceso`,
  1 AS `id_cargo`,
  1 AS `cargo`,
  1 AS `id_lista`,
  1 AS `lista`,
  1 AS `orden_cedula`,
  1 AS `votos`,
  1 AS `estado_resultado`,
  1 AS `es_ganadora` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_resultados_mesa`
--

DROP TABLE IF EXISTS `v_resultados_mesa`;
/*!50001 DROP VIEW IF EXISTS `v_resultados_mesa`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_resultados_mesa` AS SELECT
 1 AS `id_proceso`,
  1 AS `id_mesa`,
  1 AS `numero_mesa`,
  1 AS `estado_mesa`,
  1 AS `id_cargo`,
  1 AS `cargo`,
  1 AS `opcion`,
  1 AS `id_lista`,
  1 AS `lista`,
  1 AS `orden_cedula`,
  1 AS `votos`,
  1 AS `fuente` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_resultados_procesos`
--

DROP TABLE IF EXISTS `v_resultados_procesos`;
/*!50001 DROP VIEW IF EXISTS `v_resultados_procesos`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_resultados_procesos` AS SELECT
 1 AS `id_proceso`,
  1 AS `proceso`,
  1 AS `tipo`,
  1 AS `estado_proceso`,
  1 AS `id_proceso_padre`,
  1 AS `proceso_padre`,
  1 AS `origen`,
  1 AS `resultado`,
  1 AS `electores_habiles`,
  1 AS `votaron`,
  1 AS `participacion_pct`,
  1 AS `quorum_minimo`,
  1 AS `mesas_total`,
  1 AS `mesas_computadas`,
  1 AS `mesas_anuladas`,
  1 AS `mesas_no_instaladas`,
  1 AS `numero_resolucion`,
  1 AS `fecha_computo`,
  1 AS `fecha_proclamacion`,
  1 AS `fecha_publicacion`,
  1 AS `cargos`,
  1 AS `mesas` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_segunda_vuelta_procesos`
--

DROP TABLE IF EXISTS `v_segunda_vuelta_procesos`;
/*!50001 DROP VIEW IF EXISTS `v_segunda_vuelta_procesos`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_segunda_vuelta_procesos` AS SELECT
 1 AS `id_proceso`,
  1 AS `nombre`,
  1 AS `estado`,
  1 AS `fecha_inicio`,
  1 AS `fecha_fin`,
  1 AS `fecha_creacion`,
  1 AS `motivo_anulacion`,
  1 AS `id_proceso_padre`,
  1 AS `proceso_padre`,
  1 AS `fecha_computo_padre`,
  1 AS `cargos`,
  1 AS `listas`,
  1 AS `padron`,
  1 AS `mesas`,
  1 AS `estado_computo` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_tachas_detalle`
--

DROP TABLE IF EXISTS `v_tachas_detalle`;
/*!50001 DROP VIEW IF EXISTS `v_tachas_detalle`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_tachas_detalle` AS SELECT
 1 AS `id_tacha`,
  1 AS `id_proceso`,
  1 AS `cargo`,
  1 AS `id_lista`,
  1 AS `lista`,
  1 AS `id_candidato`,
  1 AS `rol_en_lista`,
  1 AS `candidato`,
  1 AS `denunciante`,
  1 AS `motivo`,
  1 AS `estado`,
  1 AS `fecha_presentacion`,
  1 AS `fecha_resolucion`,
  1 AS `resolucion` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_usuarios_admin`
--

DROP TABLE IF EXISTS `v_usuarios_admin`;
/*!50001 DROP VIEW IF EXISTS `v_usuarios_admin`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `v_usuarios_admin` AS SELECT
 1 AS `id_usuario`,
  1 AS `username`,
  1 AS `rol`,
  1 AS `activo`,
  1 AS `debe_cambiar_password`,
  1 AS `intentos_fallidos`,
  1 AS `bloqueado_hasta`,
  1 AS `bloqueada`,
  1 AS `ultimo_acceso`,
  1 AS `fecha_creacion`,
  1 AS `fecha_actualizacion`,
  1 AS `motivo_estado`,
  1 AS `id_usuario_creador`,
  1 AS `creado_por`,
  1 AS `id_docente`,
  1 AS `dni`,
  1 AS `docente`,
  1 AS `estado_docente`,
  1 AS `categoria`,
  1 AS `email`,
  1 AS `facultad`,
  1 AS `departamento`,
  1 AS `actividad`,
  1 AS `cargo_mesa`,
  1 AS `es_titular_mesa`,
  1 AS `id_mesa_asignada`,
  1 AS `numero_mesa` */;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `verificacion_acta`
--

DROP TABLE IF EXISTS `verificacion_acta`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `verificacion_acta` (
  `id_acta` int(11) NOT NULL,
  `id_proceso` int(11) NOT NULL,
  `id_mesa` int(11) NOT NULL,
  `motivo_duda` varchar(500) NOT NULL,
  `fecha_marca` datetime NOT NULL,
  `id_usuario_marca` int(11) DEFAULT NULL,
  `resultado` enum('AUTENTICA','NO_AUTENTICA') DEFAULT NULL,
  `hash_recalculado` char(64) DEFAULT NULL,
  `huella_coincide` tinyint(1) DEFAULT NULL,
  `qr_coincide` tinyint(1) DEFAULT NULL,
  `observacion_comprobacion` varchar(500) DEFAULT NULL,
  `fecha_comprobacion` datetime DEFAULT NULL,
  `id_usuario_comprobacion` int(11) DEFAULT NULL,
  PRIMARY KEY (`id_acta`),
  KEY `ix_verificacion_mesa` (`id_mesa`),
  KEY `fk_verif_proceso` (`id_proceso`),
  KEY `fk_verif_u_marca` (`id_usuario_marca`),
  KEY `fk_verif_u_comprob` (`id_usuario_comprobacion`),
  CONSTRAINT `fk_verif_acta` FOREIGN KEY (`id_acta`) REFERENCES `acta_electoral` (`id_acta`),
  CONSTRAINT `fk_verif_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`),
  CONSTRAINT `fk_verif_proceso` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`),
  CONSTRAINT `fk_verif_u_comprob` FOREIGN KEY (`id_usuario_comprobacion`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `fk_verif_u_marca` FOREIGN KEY (`id_usuario_marca`) REFERENCES `usuario` (`id_usuario`),
  CONSTRAINT `chk_verificacion_resultado` CHECK (`resultado` is null or `fecha_comprobacion` is not null and `hash_recalculado` is not null)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `verificacion_acta`
--

LOCK TABLES `verificacion_acta` WRITE;
/*!40000 ALTER TABLE `verificacion_acta` DISABLE KEYS */;
/*!40000 ALTER TABLE `verificacion_acta` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_verificacion_bu BEFORE UPDATE ON verificacion_acta
FOR EACH ROW
BEGIN
  IF OLD.resultado IS NOT NULL
     AND NOT (OLD.resultado = 'NO_AUTENTICA' AND OLD.huella_coincide = 1
              AND NOT EXISTS (SELECT 1 FROM calificacion_mesa WHERE id_mesa = OLD.id_mesa)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: la autenticidad de esta acta ya fue comprobada.';
  END IF;
  IF NOT (NEW.motivo_duda <=> OLD.motivo_duda) OR NOT (NEW.id_acta <=> OLD.id_acta) OR NOT (NEW.fecha_marca <=> OLD.fecha_marca) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: la marca de acta dudosa no se modifica.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_verificacion_bd BEFORE DELETE ON verificacion_acta
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: la verificación de un acta no se elimina.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `verificacion_documento`
--

DROP TABLE IF EXISTS `verificacion_documento`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `verificacion_documento` (
  `id_verificacion` bigint(20) NOT NULL AUTO_INCREMENT,
  `codigo_hash` char(64) NOT NULL,
  `metodo` enum('TOKEN','HUELLA') DEFAULT NULL,
  `canal` enum('QR','CODIGO','LISTA','PORTAL') NOT NULL DEFAULT 'QR',
  `tipo_documento` varchar(30) DEFAULT NULL,
  `id_documento` int(11) DEFAULT NULL,
  `id_proceso` int(11) DEFAULT NULL,
  `id_mesa` int(11) DEFAULT NULL,
  `resultado` enum('AUTENTICA','ALTERADA','ANULADA','NO_ENCONTRADA') NOT NULL,
  `id_usuario` int(11) DEFAULT NULL,
  `rol` varchar(20) DEFAULT NULL,
  `ip` varchar(45) DEFAULT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_verificacion`),
  KEY `ix_verificacion_proceso` (`id_proceso`,`fecha`),
  KEY `ix_verificacion_documento` (`tipo_documento`,`id_documento`),
  KEY `ix_verificacion_usuario` (`id_usuario`,`fecha`),
  KEY `fk_verificacion_mesa` (`id_mesa`),
  CONSTRAINT `fk_verificacion_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`),
  CONSTRAINT `fk_verificacion_proceso` FOREIGN KEY (`id_proceso`) REFERENCES `proceso_electoral` (`id_proceso`),
  CONSTRAINT `fk_verificacion_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `verificacion_documento`
--

LOCK TABLES `verificacion_documento` WRITE;
/*!40000 ALTER TABLE `verificacion_documento` DISABLE KEYS */;
INSERT INTO `verificacion_documento` VALUES (1,'5869ded03a6290f2e9e0681116065e14025fd1407bc95d32a3a2af3f569fdaff',NULL,'CODIGO',NULL,NULL,NULL,NULL,'NO_ENCONTRADA',3,'CEUNP','0:0:0:0:0:0:0:1','2026-11-25 15:58:49'),(2,'7d9753ff7b27c6d68aa828d3681720013b8a8843a7b8512fc410a938552979cb','TOKEN','QR','ACTA_ESCRUTINIO',3,1,1,'AUTENTICA',3,'CEUNP','0:0:0:0:0:0:0:1','2026-11-25 15:59:42'),(3,'d74f51c9f2463c2e2b170e0f66fe225fab7eb7f3a66c9e10535f8ba0c26afc5c','HUELLA','PORTAL','COMPUTO_GENERAL',2,2,NULL,'AUTENTICA',NULL,NULL,'0:0:0:0:0:0:0:1','2026-11-25 15:28:19');
/*!40000 ALTER TABLE `verificacion_documento` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_verificacion_doc_bu BEFORE UPDATE ON verificacion_documento
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF55: el registro de verificaciones no se modifica.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_verificacion_doc_bd BEFORE DELETE ON verificacion_documento
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF55: el registro de verificaciones no se elimina.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Temporary table structure for view `vista_quorum`
--

DROP TABLE IF EXISTS `vista_quorum`;
/*!50001 DROP VIEW IF EXISTS `vista_quorum`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `vista_quorum` AS SELECT
 1 AS `id_proceso`,
  1 AS `nombre`,
  1 AS `estado`,
  1 AS `tipo`,
  1 AS `quorum_minimo`,
  1 AS `electores_habiles`,
  1 AS `votaron`,
  1 AS `participacion_pct`,
  1 AS `alcanza_quorum` */;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `voto`
--

DROP TABLE IF EXISTS `voto`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `voto` (
  `id_voto` binary(16) NOT NULL,
  `id_proceso` int(11) NOT NULL,
  `id_cargo` int(11) NOT NULL,
  `id_lista_elegida` int(11) DEFAULT NULL,
  `tipo_voto` enum('VALIDO','BLANCO','NULO') NOT NULL,
  `fecha_hora` datetime NOT NULL DEFAULT current_timestamp(),
  `id_mesa` int(11) DEFAULT NULL,
  PRIMARY KEY (`id_voto`),
  KEY `ix_voto_conteo` (`id_cargo`,`tipo_voto`,`id_lista_elegida`),
  KEY `ix_voto_mesa` (`id_mesa`,`id_cargo`),
  KEY `fk_voto_cargo_proceso` (`id_cargo`,`id_proceso`),
  KEY `fk_voto_lista_cargo` (`id_lista_elegida`,`id_cargo`),
  CONSTRAINT `fk_voto_cargo_proceso` FOREIGN KEY (`id_cargo`, `id_proceso`) REFERENCES `cargo_electoral` (`id_cargo`, `id_proceso`),
  CONSTRAINT `fk_voto_lista_cargo` FOREIGN KEY (`id_lista_elegida`, `id_cargo`) REFERENCES `lista_electoral` (`id_lista`, `id_cargo`),
  CONSTRAINT `fk_voto_mesa` FOREIGN KEY (`id_mesa`) REFERENCES `mesa_electoral` (`id_mesa`),
  CONSTRAINT `chk_voto_tipo` CHECK (`tipo_voto` = 'VALIDO' and `id_lista_elegida` is not null or `tipo_voto` in ('BLANCO','NULO') and `id_lista_elegida` is null)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `voto`
--

LOCK TABLES `voto` WRITE;
/*!40000 ALTER TABLE `voto` DISABLE KEYS */;
INSERT INTO `voto` VALUES ('\n>w6\'v���ln�z�\'',2,2,5,'VALIDO','2026-11-25 09:00:00',2),('0������2�K�',2,2,4,'VALIDO','2026-11-25 09:00:00',2),('�ќ��L��p�W�Q��',1,1,2,'VALIDO','2026-11-25 10:00:00',1),('��O�bΤ�ˊ.}4N',1,1,2,'VALIDO','2026-11-25 10:00:00',1),('M�����|$�؉6N�',1,1,2,'VALIDO','2026-11-25 10:00:00',1),('�<3t�*�8y B���',1,1,NULL,'BLANCO','2026-11-25 10:00:00',1),('!��}�Z,\Za+EhX',2,2,5,'VALIDO','2026-11-25 09:00:00',2),('2�u�`��ug$)ʦ',2,2,5,'VALIDO','2026-11-25 09:00:00',2),('=1$�>D�R�]<��',1,1,2,'VALIDO','2026-11-25 10:00:00',1),('=�#{Ҋ�f���`',2,2,5,'VALIDO','2026-11-25 09:00:00',2),('D+��ѲϦ�g�vO��',1,1,1,'VALIDO','2026-11-25 10:00:00',1),('F����y��6y�f�`',1,1,1,'VALIDO','2026-11-25 10:00:00',1),('W�F��\"tL��M�l��u',2,2,4,'VALIDO','2026-11-25 09:00:00',2),('f���-/K\0zk���!�',2,2,5,'VALIDO','2026-11-25 09:00:00',2),('n*�Z�/�Ԁ��Hqb',1,1,1,'VALIDO','2026-11-25 09:00:00',1),('tS���Z�81#��',1,1,2,'VALIDO','2026-11-25 10:00:00',1),('��}MZŅP��k���',1,1,2,'VALIDO','2026-11-25 10:00:00',1),('��NN���[������',2,2,4,'VALIDO','2026-11-25 09:00:00',2),('��u�l�y�Q���}',2,2,5,'VALIDO','2026-11-25 09:00:00',2),('�%����-����2}',2,2,5,'VALIDO','2026-11-25 09:00:00',2),('��Aw�懝��O[�r',1,1,2,'VALIDO','2026-11-25 10:00:00',1),('�*v�:S��#۩\n�l',1,1,2,'VALIDO','2026-11-25 10:00:00',1),('�X���uv�m��}���',1,1,1,'VALIDO','2026-11-25 10:00:00',1),('��\0c��{���\'�uQ',2,2,4,'VALIDO','2026-11-25 09:00:00',2),('�Jpo��k�tEn',2,2,5,'VALIDO','2026-11-25 09:00:00',2),('��s�^q�B��\ZE�',2,2,5,'VALIDO','2026-11-25 09:00:00',2),('���;�5:k�Ψe�',1,1,2,'VALIDO','2026-11-25 10:00:00',1),('�o�Bz�wZ����\'c�',2,2,5,'VALIDO','2026-11-25 09:00:00',2),('���?�𘰛8ؒ�T׫',1,1,2,'VALIDO','2026-11-25 10:00:00',1),('��E���g�MMX(��U',2,2,5,'VALIDO','2026-11-25 09:00:00',2),('�D�=E����w�T2Ŭ',2,2,5,'VALIDO','2026-11-25 09:00:00',2),('��Q�Y⃫*���P��',2,2,5,'VALIDO','2026-11-25 09:00:00',2),('��H���t~.�S+ę�',1,1,2,'VALIDO','2026-11-25 10:00:00',1);
/*!40000 ALTER TABLE `voto` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_voto_bi BEFORE INSERT ON voto
FOR EACH ROW
BEGIN
  DECLARE v_estado VARCHAR(20) DEFAULT NULL;
  SELECT estado INTO v_estado FROM proceso_electoral WHERE id_proceso = NEW.id_proceso;
  IF v_estado IS NULL OR v_estado <> 'VOTACION' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN06: solo se aceptan votos con el proceso en VOTACION.';
  END IF;

  IF NEW.id_lista_elegida IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM lista_electoral
                      WHERE id_lista = NEW.id_lista_elegida AND estado = 'ADMITIDA') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Solo se puede votar por listas ADMITIDAS.';
  END IF;

  
  
  SET NEW.id_voto = fn_bytes_aleatorios(16);
  SET NEW.fecha_hora = DATE_FORMAT(NOW(), '%Y-%m-%d %H:00:00');
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_voto_bu BEFORE UPDATE ON voto
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: los votos son inmutables.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_voto_bd BEFORE DELETE ON voto
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: los votos no se pueden eliminar.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Dumping events for database 'elecciones_unp'
--

--
-- Dumping routines for database 'elecciones_unp'
--
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_bytes_aleatorios` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_bytes_aleatorios`(p_n INT) RETURNS varbinary(32)
    NO SQL
BEGIN
  RETURN LEFT(UNHEX(SHA2(CONCAT_WS('|', UUID(), RAND(), RAND(), SYSDATE(6), CONNECTION_ID()), 256)),
              LEAST(GREATEST(p_n, 1), 32));
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_error_docente_usuario` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_error_docente_usuario`(p_id_docente INT, p_rol VARCHAR(20), p_id_usuario INT) RETURNS varchar(300) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci
    READS SQL DATA
BEGIN
  DECLARE v_estado VARCHAR(12);
  DECLARE v_otra   VARCHAR(80);

  IF p_rol IN ('DOCENTE', 'PERSONERO', 'MIEMBRO_MESA') AND p_id_docente IS NULL THEN
    RETURN 'CUS18: el rol elegido requiere asociar la cuenta a un docente del padrón.';
  END IF;
  IF p_id_docente IS NULL THEN
    RETURN NULL;
  END IF;
  SET v_estado = (SELECT CONCAT(estado, '') FROM docente WHERE id_docente = p_id_docente);
  IF v_estado IS NULL THEN
    RETURN 'CUS18: el docente no existe en el padrón.';
  END IF;
  IF v_estado <> 'ACTIVO' THEN
    RETURN CONCAT('CUS18: el docente está ', LOWER(v_estado), ': solo un docente activo puede tener una cuenta.');
  END IF;
  SET v_otra = (SELECT username FROM usuario
                 WHERE id_docente = p_id_docente AND rol = p_rol
                   AND (p_id_usuario IS NULL OR id_usuario <> p_id_usuario)
                 LIMIT 1);
  IF v_otra IS NOT NULL THEN
    RETURN CONCAT('CUS18: el docente ya tiene una cuenta con el rol ', p_rol, ' («', v_otra, '»).');
  END IF;
  RETURN NULL;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_hash_bitacora` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_hash_bitacora`(p_hash_anterior CHAR(64), p_id_usuario INT, p_id_docente INT, p_id_proceso INT,
                                 p_accion VARCHAR(100), p_ip VARCHAR(45), p_user_agent VARCHAR(500),
                                 p_fecha DATETIME, p_detalle LONGTEXT) RETURNS char(64) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci
    NO SQL
    DETERMINISTIC
BEGIN
  RETURN SHA2(CONCAT_WS('|',
           COALESCE(p_hash_anterior, ''), COALESCE(p_id_usuario, ''), COALESCE(p_id_docente, ''),
           COALESCE(p_id_proceso, ''), COALESCE(p_accion, ''), COALESCE(p_ip, ''), COALESCE(p_user_agent, ''),
           COALESCE(DATE_FORMAT(p_fecha, '%Y-%m-%d %H:%i:%s'), ''), COALESCE(p_detalle, '')), 256);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_jornada_en_curso` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_jornada_en_curso`() RETURNS tinyint(4)
    READS SQL DATA
BEGIN
  RETURN EXISTS (SELECT 1 FROM proceso_electoral WHERE estado = 'VOTACION');
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_parametro_decimal` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_parametro_decimal`(p_clave VARCHAR(80)) RETURNS decimal(12,2)
    READS SQL DATA
BEGIN
  DECLARE v_valor DECIMAL(12,2) DEFAULT NULL;
  SELECT CAST(valor AS DECIMAL(12,2)) INTO v_valor
    FROM parametro_global WHERE clave = p_clave LIMIT 1;
  RETURN v_valor;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_participacion_cargo` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_participacion_cargo`(p_id_cargo INT) RETURNS decimal(5,2)
    READS SQL DATA
BEGIN
  DECLARE v_hab INT DEFAULT 0;
  DECLARE v_vot INT DEFAULT 0;
  SELECT COUNT(*), COALESCE(SUM(ya_voto), 0) INTO v_hab, v_vot
    FROM padron_electoral
   WHERE id_cargo = p_id_cargo AND habilitado_para_votar = 1;
  IF v_hab = 0 THEN
    RETURN 0;
  END IF;
  RETURN ROUND(v_vot * 100 / v_hab, 2);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_proceso_de_lista` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_proceso_de_lista`(p_id_lista INT) RETURNS int(11)
    READS SQL DATA
BEGIN
  DECLARE v_id INT DEFAULT NULL;
  SELECT c.id_proceso INTO v_id
    FROM lista_electoral l
    JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
   WHERE l.id_lista = p_id_lista LIMIT 1;
  RETURN v_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_resolucion_en_uso` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_resolucion_en_uso`(p_numero VARCHAR(40)) RETURNS tinyint(1)
    READS SQL DATA
BEGIN
  IF p_numero IS NULL OR TRIM(p_numero) = '' THEN
    RETURN FALSE;
  END IF;
  RETURN EXISTS (SELECT 1 FROM nulidad_electoral     WHERE numero_resolucion = p_numero)
      OR EXISTS (SELECT 1 FROM dirimencia_empate     WHERE numero_resolucion = p_numero)
      OR EXISTS (SELECT 1 FROM calificacion_mesa     WHERE numero_resolucion = p_numero)
      OR EXISTS (SELECT 1 FROM computo_proceso       WHERE numero_resolucion = p_numero)
      OR EXISTS (SELECT 1 FROM impugnacion_electoral WHERE numero_resolucion = p_numero)
      OR EXISTS (SELECT 1 FROM reporte_multas        WHERE numero_resolucion = p_numero)
      OR EXISTS (SELECT 1 FROM multa_justificacion   WHERE numero_resolucion = p_numero);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_resultados_disponibles` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_resultados_disponibles`(p_id_proceso INT) RETURNS tinyint(4)
    READS SQL DATA
BEGIN
  DECLARE v_comp VARCHAR(20) DEFAULT NULL;
  DECLARE v_est  VARCHAR(20) DEFAULT NULL;
  SELECT estado INTO v_est FROM proceso_electoral WHERE id_proceso = p_id_proceso;
  IF v_est IS NULL THEN
    RETURN 0;
  END IF;
  SELECT CONCAT(estado, '') INTO v_comp FROM computo_proceso WHERE id_proceso = p_id_proceso;
  IF v_comp IS NOT NULL THEN
    RETURN IF(v_comp = 'PUBLICADO', 1, 0);
  END IF;
  RETURN IF(v_est IN ('FINALIZADO','ANULADO')
            AND EXISTS (SELECT 1 FROM resultado_electoral WHERE id_proceso = p_id_proceso), 1, 0);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_tiene_cargo_excluyente` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_tiene_cargo_excluyente`(p_id_docente INT) RETURNS tinyint(1)
    READS SQL DATA
BEGIN
  DECLARE v_n INT DEFAULT 0;
  SELECT COUNT(*) INTO v_n
    FROM cargo_admin ca
    JOIN cargo_excluido_sorteo ce ON ce.id_catalogo_cargo = ca.id_catalogo_cargo AND ce.activo = 1
   WHERE ca.id_docente = p_id_docente
     AND ca.vigente = 1
     AND ca.fecha_inicio <= CURDATE()
     AND (ca.fecha_fin IS NULL OR ca.fecha_fin >= CURDATE());
  RETURN v_n > 0;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_validar_parametro` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_validar_parametro`(p_clave VARCHAR(80), p_valor VARCHAR(255)) RETURNS varchar(300) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci
    READS SQL DATA
BEGIN
  DECLARE v_tipo   VARCHAR(10);
  DECLARE v_etq    VARCHAR(120);
  DECLARE v_min    DECIMAL(12,2);
  DECLARE v_max    DECIMAL(12,2);
  DECLARE v_unidad VARCHAR(30);
  DECLARE v_valor  VARCHAR(255);
  DECLARE v_num    DECIMAL(16,4);
  DECLARE v_otro   DECIMAL(16,4);

  SET v_tipo = (SELECT CONCAT(tipo, '') FROM parametro_definicion WHERE clave = p_clave);
  IF v_tipo IS NULL THEN
    RETURN NULL;
  END IF;
  SELECT etiqueta, minimo, maximo, unidad INTO v_etq, v_min, v_max, v_unidad
    FROM parametro_definicion WHERE clave = p_clave;
  SET v_valor = TRIM(p_valor);

  IF v_valor IS NULL OR v_valor = '' THEN
    RETURN CONCAT('CUS18: indique un valor para «', v_etq, '».');
  END IF;

  IF v_tipo = 'TEXTO' THEN
    IF v_min IS NOT NULL AND CHAR_LENGTH(v_valor) < v_min THEN
      RETURN CONCAT('CUS18: «', v_etq, '» debe tener al menos ', ROUND(v_min), ' caracteres.');
    END IF;
    IF v_max IS NOT NULL AND CHAR_LENGTH(v_valor) > v_max THEN
      RETURN CONCAT('CUS18: «', v_etq, '» admite hasta ', ROUND(v_max), ' caracteres.');
    END IF;
    RETURN NULL;
  END IF;

  IF v_tipo = 'INDICADOR' THEN
    IF v_valor NOT IN ('0', '1') THEN
      RETURN CONCAT('CUS18: «', v_etq, '» solo admite 1 (sí) o 0 (no).');
    END IF;
    RETURN NULL;
  END IF;

  IF v_tipo = 'ENTERO' AND v_valor NOT REGEXP '^[0-9]+$' THEN
    RETURN CONCAT('CUS18: «', v_etq, '» debe ser un número entero.');
  END IF;
  IF v_tipo IN ('DECIMAL', 'HORA') AND v_valor NOT REGEXP '^[0-9]+([.][0-9]{1,4})?$' THEN
    RETURN CONCAT('CUS18: «', v_etq, '» debe ser un número positivo (use punto decimal, por ejemplo 9.5).');
  END IF;

  SET v_num = CAST(v_valor AS DECIMAL(16,4));
  IF v_min IS NOT NULL AND v_num < v_min THEN
    RETURN CONCAT('CUS18: «', v_etq, '» no puede ser menor que ',
                  TRIM(TRAILING '.' FROM TRIM(TRAILING '0' FROM v_min)), IF(v_unidad IS NULL, '', CONCAT(' ', v_unidad)), '.');
  END IF;
  IF v_max IS NOT NULL AND v_num > v_max THEN
    RETURN CONCAT('CUS18: «', v_etq, '» no puede ser mayor que ',
                  TRIM(TRAILING '.' FROM TRIM(TRAILING '0' FROM v_max)), IF(v_unidad IS NULL, '', CONCAT(' ', v_unidad)), '.');
  END IF;

  
  IF p_clave = 'INSTALACION_HORA_INICIO' THEN
    SET v_otro = (SELECT CAST(valor AS DECIMAL(16,4)) FROM parametro_global WHERE clave = 'INSTALACION_HORA_LIMITE');
    IF v_otro IS NOT NULL AND v_num >= v_otro THEN
      RETURN 'CUS18: la hora de inicio de la instalación debe ser anterior a la hora límite (RN07).';
    END IF;
  END IF;
  IF p_clave = 'INSTALACION_HORA_LIMITE' THEN
    SET v_otro = (SELECT CAST(valor AS DECIMAL(16,4)) FROM parametro_global WHERE clave = 'INSTALACION_HORA_INICIO');
    IF v_otro IS NOT NULL AND v_num <= v_otro THEN
      RETURN 'CUS18: la hora límite de la instalación debe ser posterior a la hora de inicio (RF58).';
    END IF;
  END IF;
  RETURN NULL;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_actualizar_multa` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_actualizar_multa`(
  IN p_id_multa    INT,
  IN p_estado_pago VARCHAR(12),
  IN p_observacion VARCHAR(300),
  IN p_id_usuario  INT
)
BEGIN
  DECLARE v_est VARCHAR(12);
  SET v_est = UPPER(TRIM(p_estado_pago));
  IF v_est IS NULL OR v_est NOT IN ('PENDIENTE','PAGADA','EXONERADA','JUSTIFICADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estado de pago invalido.';
  END IF;
  IF v_est = 'PENDIENTE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF106: el pago, la justificación o la exoneración registrados no se revierten.';
  END IF;
  IF v_est IN ('EXONERADA','JUSTIFICADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF106: la justificación o la exoneración se registran con la resolución del CEUNP (Omisos y multas, CUS16).';
  END IF;
  CALL sp_registrar_pago_multa(p_id_multa, p_id_usuario, p_observacion, NULL, NULL);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_actualizar_parametro` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_actualizar_parametro`(
  IN p_id_admin INT,
  IN p_clave    VARCHAR(80),
  IN p_valor    VARCHAR(255),
  IN p_motivo   VARCHAR(500),
  IN p_origen   VARCHAR(12),
  IN p_ip       VARCHAR(45)
)
BEGIN
  DECLARE v_anterior VARCHAR(255);
  DECLARE v_valor    VARCHAR(255);
  DECLARE v_motivo   VARCHAR(500);
  DECLARE v_error    VARCHAR(300);
  DECLARE v_bloqueo  TINYINT;
  DECLARE v_etq      VARCHAR(120);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET @cus18_id_usuario = NULL, @cus18_motivo = NULL, @cus18_origen = NULL, @cus18_ip = NULL;
    RESIGNAL;
  END;

  CALL sp_validar_admin(p_id_admin);
  SET v_valor = TRIM(p_valor);
  SET v_motivo = NULLIF(TRIM(p_motivo), '');
  IF v_motivo IS NULL OR CHAR_LENGTH(v_motivo) < 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: indique el motivo del cambio (al menos 10 caracteres).';
  END IF;

  START TRANSACTION;
  SELECT valor INTO v_anterior FROM parametro_global WHERE clave = p_clave FOR UPDATE;
  IF v_anterior IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: el parámetro no existe.';
  END IF;
  IF v_anterior = v_valor THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: el valor es igual al vigente.';
  END IF;
  SELECT COALESCE(bloqueo_jornada, 0), etiqueta INTO v_bloqueo, v_etq FROM parametro_definicion WHERE clave = p_clave;
  IF v_bloqueo = 1 AND fn_jornada_en_curso() = 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: hay un proceso en votación: este parámetro de la jornada no se puede cambiar hasta el cierre.';
  END IF;
  SET v_error = fn_validar_parametro(p_clave, v_valor);
  IF v_error IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
  END IF;

  SET @cus18_id_usuario = p_id_admin, @cus18_motivo = v_motivo,
      @cus18_origen = IF(p_origen = 'RESTAURACION', 'RESTAURACION', 'PANTALLA'), @cus18_ip = p_ip;
  UPDATE parametro_global SET valor = v_valor WHERE clave = p_clave;
  SET @cus18_id_usuario = NULL, @cus18_motivo = NULL, @cus18_origen = NULL, @cus18_ip = NULL;

  CALL sp_registrar_auditoria(p_id_admin, NULL, NULL, 'CAMBIO_PARAMETRO',
       JSON_OBJECT('clave', p_clave, 'anterior', v_anterior, 'nuevo', v_valor, 'motivo', v_motivo,
                   'origen', IF(p_origen = 'RESTAURACION', 'RESTAURACION', 'PANTALLA')));
  COMMIT;

  
  SELECT p_clave AS clave, COALESCE(v_etq, p_clave) AS etiqueta, v_anterior AS valor_anterior, v_valor AS valor_nuevo,
         (SELECT MAX(id_historial) FROM parametro_historial WHERE clave = p_clave) AS id_historial, NOW() AS fecha;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_actualizar_usuario` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_actualizar_usuario`(
  IN p_id_admin   INT,
  IN p_id_usuario INT,
  IN p_rol        VARCHAR(20),
  IN p_id_docente INT
)
BEGIN
  DECLARE v_rol     VARCHAR(20);
  DECLARE v_docente INT;
  DECLARE v_error   VARCHAR(300);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  CALL sp_validar_admin(p_id_admin);
  IF p_rol IS NULL OR p_rol NOT IN ('ADMIN', 'CEUNP', 'DOCENTE', 'PERSONERO', 'MIEMBRO_MESA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: rol no válido.';
  END IF;

  START TRANSACTION;
  SELECT CONCAT(rol, ''), id_docente INTO v_rol, v_docente FROM usuario WHERE id_usuario = p_id_usuario FOR UPDATE;
  IF v_rol IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: la cuenta no existe.';
  END IF;
  IF p_id_usuario = p_id_admin AND p_rol <> v_rol THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: no puede cambiar el rol de su propia cuenta.';
  END IF;
  IF p_rol = v_rol AND (p_id_docente <=> v_docente) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: no hay cambios que guardar.';
  END IF;
  SET v_error = fn_error_docente_usuario(p_id_docente, p_rol, p_id_usuario);
  IF v_error IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
  END IF;

  UPDATE usuario SET rol = p_rol, id_docente = p_id_docente, fecha_actualizacion = NOW()
   WHERE id_usuario = p_id_usuario;

  CALL sp_registrar_auditoria(p_id_admin, p_id_docente, NULL, 'ACTUALIZAR_USUARIO',
       JSON_OBJECT('id_usuario', p_id_usuario, 'rol_anterior', v_rol, 'rol_nuevo', p_rol,
                   'docente_anterior', v_docente, 'docente_nuevo', p_id_docente));
  COMMIT;

  SELECT * FROM v_usuarios_admin WHERE id_usuario = p_id_usuario;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_agregar_cargo` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_agregar_cargo`(
  IN  p_id_proceso          INT,
  IN  p_nombre              VARCHAR(150),
  IN  p_nivel               VARCHAR(20),     
  IN  p_id_jurisdiccion     INT,             
  IN  p_categorias_votan    VARCHAR(60),
  IN  p_categorias_postulan VARCHAR(60),
  OUT p_id_cargo            INT
)
BEGIN
  DECLARE v_estado  VARCHAR(20) DEFAULT NULL;
  DECLARE v_i       INT DEFAULT 1;
  DECLARE v_cat     VARCHAR(10);
  DECLARE v_votan   VARCHAR(60);
  DECLARE v_postula VARCHAR(60);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT estado INTO v_estado FROM proceso_electoral WHERE id_proceso = p_id_proceso;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;
  IF v_estado NOT IN ('CREADO','INSCRIPCION') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se agregan cargos con el proceso en CREADO o INSCRIPCION.';
  END IF;

  IF p_nivel IS NULL OR UPPER(p_nivel) NOT IN ('UNIVERSIDAD','FACULTAD','DEPARTAMENTO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nivel invalido: use UNIVERSIDAD, FACULTAD o DEPARTAMENTO.';
  END IF;

  INSERT INTO cargo_electoral (id_proceso, nombre, nivel_jurisdiccion, id_jurisdiccion)
  VALUES (p_id_proceso, p_nombre, UPPER(p_nivel), p_id_jurisdiccion);
  SET p_id_cargo = LAST_INSERT_ID();

  SET v_votan   = COALESCE(REPLACE(UPPER(p_categorias_votan), ' ', ''),   'PRINCIPAL,ASOCIADO,AUXILIAR');
  SET v_postula = COALESCE(REPLACE(UPPER(p_categorias_postulan), ' ', ''), 'PRINCIPAL,ASOCIADO,AUXILIAR');

  WHILE v_i <= 3 DO
    SET v_cat = ELT(v_i, 'PRINCIPAL', 'ASOCIADO', 'AUXILIAR');
    IF FIND_IN_SET(v_cat, v_votan) > 0 OR FIND_IN_SET(v_cat, v_postula) > 0 THEN
      INSERT INTO cargo_categoria_permitida (id_cargo, categoria, puede_votar, puede_postular)
      VALUES (p_id_cargo, v_cat, FIND_IN_SET(v_cat, v_votan) > 0, FIND_IN_SET(v_cat, v_postula) > 0);
    END IF;
    SET v_i = v_i + 1;
  END WHILE;

  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_anular_proceso` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_anular_proceso`(
  IN p_id_proceso INT,
  IN p_motivo     VARCHAR(500),
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_estado VARCHAR(20) DEFAULT NULL;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT estado INTO v_estado FROM proceso_electoral WHERE id_proceso = p_id_proceso FOR UPDATE;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;
  IF v_estado IN ('FINALIZADO','ANULADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso ya esta FINALIZADO o ANULADO.';
  END IF;
  IF p_motivo IS NULL OR TRIM(p_motivo) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN34: la anulacion requiere un motivo.';
  END IF;

  UPDATE proceso_electoral
     SET estado = 'ANULADO', motivo_anulacion = p_motivo, fecha_cierre_real = COALESCE(fecha_cierre_real, NOW())
   WHERE id_proceso = p_id_proceso;
  UPDATE acta_electoral a
    JOIN mesa_electoral m ON m.id_mesa = a.id_mesa
     SET a.estado = 'ANULADA'
   WHERE m.id_proceso = p_id_proceso;
  UPDATE mesa_electoral SET estado = 'ANULADA' WHERE id_proceso = p_id_proceso;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'ANULAR_PROCESO',
       JSON_OBJECT('motivo', p_motivo, 'estado_anterior', v_estado));
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_apelar_impugnacion` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_apelar_impugnacion`(
  IN p_id_impugnacion BIGINT,
  IN p_id_usuario     INT,
  IN p_id_personero   INT,
  IN p_fundamento     VARCHAR(1000)
)
BEGIN
  DECLARE v_mesa      INT DEFAULT NULL;
  DECLARE v_proceso   INT;
  DECLARE v_estado    VARCHAR(12);
  DECLARE v_dec_mesa  VARCHAR(12);
  DECLARE v_fecha_dec DATETIME;
  DECLARE v_proc_est  VARCHAR(20);
  DECLARE v_lista     INT;
  DECLARE v_lista_ap  INT DEFAULT NULL;
  DECLARE v_acred     VARCHAR(12);
  DECLARE v_plazo     DECIMAL(8,2) DEFAULT 24;
  DECLARE v_fund      VARCHAR(1000);
  DECLARE v_msg       VARCHAR(255);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT i.id_mesa, i.id_proceso, i.estado, i.decision_mesa, i.fecha_decision_mesa, p.estado, pe.id_lista
    INTO v_mesa, v_proceso, v_estado, v_dec_mesa, v_fecha_dec, v_proc_est, v_lista
    FROM impugnacion_electoral i
    JOIN proceso_electoral p ON p.id_proceso = i.id_proceso
    JOIN personero pe        ON pe.id_personero = i.id_personero
   WHERE i.id_impugnacion = p_id_impugnacion
     FOR UPDATE;

  IF v_mesa IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La impugnación no existe.';
  END IF;
  IF v_estado = 'APELADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF81: la impugnación ya fue apelada ante el CEUNP.';
  END IF;
  IF v_dec_mesa = 'PENDIENTE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF81: se apela la decisión de la mesa; la mesa aún no resuelve.';
  END IF;
  IF v_dec_mesa <> 'RECHAZADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF81: solo se apela una impugnación RECHAZADA por la mesa.';
  END IF;
  IF v_proc_est NOT IN ('VOTACION', 'CERRADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS13: el proceso ya no admite apelaciones.';
  END IF;

  
  SELECT id_lista, estado_acreditacion INTO v_lista_ap, v_acred
    FROM personero WHERE id_personero = p_id_personero;
  IF v_lista_ap IS NULL OR v_lista_ap <> v_lista THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF81: apela un personero de la lista que presentó la impugnación.';
  END IF;
  IF v_acred <> 'ACREDITADO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF81: el personero que apela debe estar ACREDITADO (CUS05).';
  END IF;

  
  SET v_plazo = COALESCE((SELECT CAST(valor AS DECIMAL(8,2)) FROM parametro_global
                           WHERE clave = 'IMPUGNACION_PLAZO_APELACION_HORAS'), 24);
  IF v_plazo > 0 AND NOW() > v_fecha_dec + INTERVAL ROUND(v_plazo * 60) MINUTE THEN
    SET v_msg = CONCAT('RF81: venció el plazo de ', v_plazo + 0e0, ' horas para apelar (la mesa decidió el ',
                       DATE_FORMAT(v_fecha_dec, '%d/%m/%Y %H:%i'), ').');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  SET v_fund = NULLIF(TRIM(p_fundamento), '');
  IF v_fund IS NULL OR CHAR_LENGTH(v_fund) < 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF81: fundamente la apelación (al menos 10 caracteres).';
  END IF;

  UPDATE impugnacion_electoral
     SET estado = 'APELADA', id_personero_apela = p_id_personero, fundamento_apelacion = v_fund,
         fecha_apelacion = NOW(), id_usuario_apelacion = p_id_usuario, fecha_resolucion = NULL
   WHERE id_impugnacion = p_id_impugnacion;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'APELAR_IMPUGNACION',
       JSON_OBJECT('id_impugnacion', p_id_impugnacion, 'id_mesa', v_mesa, 'id_personero', p_id_personero));
  COMMIT;

  SELECT p_id_impugnacion AS id_impugnacion, 'APELADA' AS estado;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_atender_cotejo_acta` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_atender_cotejo_acta`(
  IN p_id_cotejo  INT,
  IN p_id_usuario INT,
  IN p_decision   VARCHAR(10),
  IN p_respuesta  VARCHAR(1000)
)
BEGIN
  DECLARE v_estado  VARCHAR(10) DEFAULT NULL;
  DECLARE v_proceso INT;
  DECLARE v_rol     VARCHAR(20) DEFAULT NULL;
  DECLARE v_dec     VARCHAR(10);
  DECLARE v_resp    VARCHAR(1000);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SELECT CONCAT(rol, '') INTO v_rol FROM usuario WHERE id_usuario = p_id_usuario AND activo = 1;
  IF v_rol IS NULL OR v_rol <> 'CEUNP' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: solo el CEUNP atiende las discrepancias reportadas.';
  END IF;
  SET v_dec = UPPER(TRIM(p_decision));
  IF v_dec IS NULL OR v_dec NOT IN ('ACLARADA','FUNDADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: indique si la discrepancia queda aclarada o es fundada.';
  END IF;
  SET v_resp = NULLIF(TRIM(p_respuesta), '');
  IF v_resp IS NULL OR CHAR_LENGTH(v_resp) < 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: fundamente la respuesta (al menos 10 caracteres).';
  END IF;

  START TRANSACTION;
  SELECT CONCAT(estado, ''), id_proceso INTO v_estado, v_proceso FROM cotejo_acta WHERE id_cotejo = p_id_cotejo FOR UPDATE;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: el cotejo no existe.';
  END IF;
  IF v_estado <> 'OBSERVADO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: el cotejo no tiene una discrepancia pendiente de atención.';
  END IF;

  UPDATE cotejo_acta
     SET estado = 'ATENDIDO', decision = v_dec, respuesta = v_resp, fecha_respuesta = NOW(), id_usuario_respuesta = p_id_usuario
   WHERE id_cotejo = p_id_cotejo;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'ATENDER_DISCREPANCIA_ACTA',
       JSON_OBJECT('id_cotejo', p_id_cotejo, 'decision', v_dec));
  COMMIT;

  SELECT p_id_cotejo AS id_cotejo, 'ATENDIDO' AS estado, v_dec AS decision;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_calificar_mesa` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_calificar_mesa`(
  IN p_id_mesa           INT,
  IN p_id_usuario        INT,
  IN p_calificacion      VARCHAR(10),
  IN p_fundamento        VARCHAR(1000),
  IN p_numero_resolucion VARCHAR(40)
)
BEGIN
  DECLARE v_proceso   INT DEFAULT NULL;
  DECLARE v_estado    VARCHAR(20);
  DECLARE v_mesa_est  VARCHAR(20);
  DECLARE v_calif     VARCHAR(10);
  DECLARE v_fund      VARCHAR(1000);
  DECLARE v_res       VARCHAR(40);
  DECLARE v_requiere  INT DEFAULT 0;
  DECLARE v_no_aut    INT DEFAULT 0;
  DECLARE v_esc       VARCHAR(20);
  DECLARE v_motivo    VARCHAR(300);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT m.id_proceso, p.estado, m.estado INTO v_proceso, v_estado, v_mesa_est
    FROM mesa_electoral m JOIN proceso_electoral p ON p.id_proceso = m.id_proceso
   WHERE m.id_mesa = p_id_mesa
     FOR UPDATE;
  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no existe.';
  END IF;
  IF v_estado <> 'CERRADO'
     OR EXISTS (SELECT 1 FROM computo_proceso WHERE id_proceso = v_proceso AND estado <> 'SESION_INSTALADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF94: las actas y nulidades se resuelven con la votación concluida y antes del cómputo.';
  END IF;
  IF EXISTS (SELECT 1 FROM calificacion_mesa WHERE id_mesa = p_id_mesa) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el CEUNP ya calificó esta mesa; su decisión es inapelable.';
  END IF;
  IF v_mesa_est <> 'CERRADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF95: solo se califica una mesa que cerró su sufragio y entregó sus actas.';
  END IF;

  SET v_calif = UPPER(TRIM(p_calificacion));
  IF v_calif IS NULL OR v_calif NOT IN ('VALIDA','NULIDAD') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF95: la calificación es VALIDA o NULIDAD.';
  END IF;
  SET v_fund = NULLIF(TRIM(p_fundamento), '');
  IF v_fund IS NULL OR CHAR_LENGTH(v_fund) < 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF95: fundamente la decisión del CEUNP (al menos 10 caracteres).';
  END IF;
  SET v_res = NULLIF(TRIM(p_numero_resolucion), '');

  SELECT estado_escrutinio, requiere_calificacion, actas_no_autenticas + actas_alteradas,
         CONCAT_WS('; ',
           IF(conteo_cuadra = 0, 'el conteo manual difiere del digital (prevalece la cédula física)', NULL),
           IF(total_cuadra = 0, 'los votos no igualan a los electores que votaron', NULL),
           IF(observada = 1, 'acta con observaciones', NULL),
           IF(actas_no_autenticas + actas_alteradas > 0, 'acta no auténtica', NULL))
    INTO v_esc, v_requiere, v_no_aut, v_motivo
    FROM v_computo_mesas WHERE id_mesa = p_id_mesa;

  IF v_calif = 'VALIDA' THEN
    IF v_no_aut > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: el acta no es auténtica; solo procede declarar la nulidad de la mesa.';
    END IF;
    IF v_esc IS NULL OR v_esc NOT IN ('ACTA_EMITIDA','ENTREGADA') THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF95: la mesa aún no emite su acta de escrutinio (CUS12).';
    END IF;
    IF v_requiere = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A3: el acta coincide con el conteo; no requiere calificación.';
    END IF;
  ELSE
    IF v_res IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN34: la nulidad se declara por resolución del CEUNP; indique su número.';
    END IF;
  END IF;
  IF v_res IS NOT NULL AND (EXISTS (SELECT 1 FROM calificacion_mesa WHERE numero_resolucion = v_res)
       OR EXISTS (SELECT 1 FROM computo_proceso WHERE numero_resolucion = v_res)
       OR EXISTS (SELECT 1 FROM impugnacion_electoral WHERE numero_resolucion = v_res)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;

  INSERT INTO calificacion_mesa (id_mesa, id_proceso, calificacion, motivo_revision, fundamento, numero_resolucion, fecha, id_usuario)
  VALUES (p_id_mesa, v_proceso, v_calif, NULLIF(v_motivo, ''), v_fund, v_res, NOW(), p_id_usuario);

  IF v_calif = 'NULIDAD' THEN
    
    UPDATE acta_electoral SET estado = 'ANULADA' WHERE id_mesa = p_id_mesa;
    UPDATE mesa_electoral SET estado = 'ANULADA' WHERE id_mesa = p_id_mesa;
  END IF;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, IF(v_calif = 'NULIDAD', 'DECLARAR_NULIDAD_MESA', 'CALIFICAR_ACTA'),
       JSON_OBJECT('id_mesa', p_id_mesa, 'calificacion', v_calif, 'resolucion', v_res));
  COMMIT;

  SELECT p_id_mesa AS id_mesa, v_calif AS calificacion;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_cambiar_estado_proceso` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cambiar_estado_proceso`(
  IN p_id_proceso   INT,
  IN p_nuevo_estado VARCHAR(20),
  IN p_id_usuario   INT
)
BEGIN
  DECLARE v_estado VARCHAR(20) DEFAULT NULL;
  DECLARE v_nuevo  VARCHAR(20);
  DECLARE v_n      INT DEFAULT 0;
  DECLARE v_abiertas TEXT DEFAULT NULL;
  DECLARE v_msg    VARCHAR(255);
  DECLARE v_limite DATETIME DEFAULT NULL;
  DECLARE v_inicio DATETIME DEFAULT NULL;
  DECLARE v_fin    DATETIME DEFAULT NULL;
  DECLARE v_control INT DEFAULT 1;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SET v_nuevo = UPPER(p_nuevo_estado);

  SELECT estado INTO v_estado FROM proceso_electoral WHERE id_proceso = p_id_proceso FOR UPDATE;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;

  IF v_nuevo IS NULL OR NOT ( (v_estado = 'CREADO'      AND v_nuevo = 'INSCRIPCION')
        OR (v_estado = 'INSCRIPCION' AND v_nuevo = 'VOTACION')
        OR (v_estado = 'VOTACION'    AND v_nuevo = 'CERRADO') ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Transicion no permitida. Orden: CREADO > INSCRIPCION > VOTACION > CERRADO.';
  END IF;

  IF v_nuevo = 'INSCRIPCION' THEN
    SELECT COUNT(*) INTO v_n FROM cargo_electoral WHERE id_proceso = p_id_proceso;
    IF v_n = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso no tiene cargos a elegir.';
    END IF;
  END IF;

  IF v_nuevo = 'VOTACION' THEN
    
    
    
    
    SELECT fecha_limite_inscripcion, fecha_inicio, fecha_fin INTO v_limite, v_inicio, v_fin
      FROM proceso_electoral WHERE id_proceso = p_id_proceso;
    SET v_control = COALESCE((SELECT CAST(valor AS UNSIGNED) FROM parametro_global
                               WHERE clave = 'INSTALACION_CONTROL_HORARIO'), 1);
    IF v_limite IS NOT NULL AND NOW() < v_limite THEN
      SET v_msg = CONCAT('RN05: el plazo de inscripcion de listas sigue abierto hasta el ',
                         DATE_FORMAT(v_limite, '%d/%m/%Y %H:%i'), '; la votacion se abre despues.');
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
    IF v_fin IS NOT NULL AND NOW() >= v_fin THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN06: la hora de fin del sufragio ya paso; no se puede abrir la votacion.';
    END IF;
    IF v_control = 1 AND v_inicio IS NOT NULL AND CURDATE() <> DATE(v_inicio) THEN
      SET v_msg = CONCAT('RN06: la votacion se abre el dia del sufragio (',
                         DATE_FORMAT(v_inicio, '%d/%m/%Y'), ').');
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
    
    SELECT COUNT(*) INTO v_n FROM padron_electoral WHERE id_proceso = p_id_proceso;
    IF v_n = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN04: falta generar el padron electoral.';
    END IF;
    
    SELECT COUNT(*) INTO v_n
      FROM cargo_electoral c
     WHERE c.id_proceso = p_id_proceso
       AND NOT EXISTS (SELECT 1 FROM lista_electoral l
                        WHERE l.id_cargo = c.id_cargo AND l.estado = 'ADMITIDA');
    IF v_n > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hay cargos sin ninguna lista ADMITIDA.';
    END IF;
    
    SELECT COUNT(*) INTO v_n
      FROM lista_electoral l
      JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
     WHERE c.id_proceso = p_id_proceso AND l.estado = 'ADMITIDA' AND l.orden_cedula IS NULL;
    IF v_n > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN18: falta sortear el orden de las listas en la cedula.';
    END IF;
    
    SELECT COUNT(*) INTO v_n FROM mesa_electoral WHERE id_proceso = p_id_proceso AND estado <> 'ANULADA';
    IF v_n = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay mesas de sufragio creadas.';
    END IF;
    SELECT COUNT(*) INTO v_n
      FROM mesa_electoral m
     WHERE m.id_proceso = p_id_proceso AND m.estado <> 'ANULADA'
       AND (SELECT COUNT(*) FROM miembro_mesa mm WHERE mm.id_mesa = m.id_mesa) <> 6;
    IF v_n > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN19: hay mesas sin sus 3 titulares y 3 suplentes.';
    END IF;
  END IF;

  
  
  IF v_nuevo = 'CERRADO' THEN
    SELECT GROUP_CONCAT(CONCAT('Mesa ', numero_mesa,
                               IF(estado = 'INSTALADA', ' con el sufragio abierto (CUS11)', ' sin instalar (CUS08)'))
                        ORDER BY LENGTH(numero_mesa), numero_mesa SEPARATOR '; ')
      INTO v_abiertas
      FROM mesa_electoral
     WHERE id_proceso = p_id_proceso AND estado IN ('INSTALADA', 'PENDIENTE');
    IF v_abiertas IS NOT NULL THEN
      SET v_msg = LEFT(CONCAT('RN32: la votacion concluye con todas las mesas cerradas. ', v_abiertas, '.'), 255);
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
  END IF;

  UPDATE proceso_electoral
     SET estado = v_nuevo,
         fecha_cierre_real = IF(v_nuevo = 'CERRADO', NOW(), fecha_cierre_real)
   WHERE id_proceso = p_id_proceso;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'CAMBIO_ESTADO_PROCESO',
       JSON_OBJECT('anterior', v_estado, 'nuevo', v_nuevo));
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_cambiar_estado_usuario` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cambiar_estado_usuario`(
  IN p_id_admin   INT,
  IN p_id_usuario INT,
  IN p_activo     BOOLEAN,
  IN p_motivo     VARCHAR(300)
)
BEGIN
  DECLARE v_activo TINYINT;
  DECLARE v_motivo VARCHAR(300);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  CALL sp_validar_admin(p_id_admin);
  IF p_id_usuario = p_id_admin AND NOT p_activo THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: no puede desactivar su propia cuenta.';
  END IF;
  SET v_motivo = NULLIF(TRIM(p_motivo), '');
  IF NOT p_activo AND (v_motivo IS NULL OR CHAR_LENGTH(v_motivo) < 10) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: indique el motivo de la desactivación (al menos 10 caracteres).';
  END IF;

  START TRANSACTION;
  SELECT activo INTO v_activo FROM usuario WHERE id_usuario = p_id_usuario FOR UPDATE;
  IF v_activo IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: la cuenta no existe.';
  END IF;
  IF v_activo = p_activo THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: la cuenta ya está en ese estado.';
  END IF;

  UPDATE usuario
     SET activo = p_activo, motivo_estado = v_motivo, fecha_actualizacion = NOW(),
         intentos_fallidos = IF(p_activo, 0, intentos_fallidos), bloqueado_hasta = IF(p_activo, NULL, bloqueado_hasta)
   WHERE id_usuario = p_id_usuario;

  CALL sp_registrar_auditoria(p_id_admin, NULL, NULL, IF(p_activo, 'ACTIVAR_USUARIO', 'DESACTIVAR_USUARIO'),
       JSON_OBJECT('id_usuario', p_id_usuario, 'motivo', v_motivo));
  COMMIT;

  SELECT * FROM v_usuarios_admin WHERE id_usuario = p_id_usuario;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_cerrar_mesa` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cerrar_mesa`(
  IN p_id_mesa    INT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_proceso   INT DEFAULT NULL;
  DECLARE v_estado    VARCHAR(20) DEFAULT NULL;
  DECLARE v_mesa_est  VARCHAR(20) DEFAULT NULL;
  DECLARE v_numero    VARCHAR(30);
  DECLARE v_total     INT DEFAULT 0;
  DECLARE v_votaron   INT DEFAULT 0;
  DECLARE v_detalle   LONGTEXT;
  DECLARE v_contenido LONGTEXT;
  DECLARE v_token_suf CHAR(64);
  DECLARE v_token_esc CHAR(64);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET SESSION group_concat_max_len = 1000000;
  START TRANSACTION;

  SELECT m.id_proceso, p.estado, m.estado, m.numero_mesa, m.total_electores
    INTO v_proceso, v_estado, v_mesa_est, v_numero, v_total
    FROM mesa_electoral m JOIN proceso_electoral p ON p.id_proceso = m.id_proceso
   WHERE m.id_mesa = p_id_mesa
     FOR UPDATE;

  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no existe.';
  END IF;
  IF v_estado NOT IN ('VOTACION','CERRADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa solo se cierra durante o al termino de la votacion.';
  END IF;
  IF v_mesa_est <> 'INSTALADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se puede cerrar una mesa INSTALADA.';
  END IF;

  SELECT COUNT(DISTINCT id_docente) INTO v_votaron
    FROM padron_electoral WHERE id_mesa = p_id_mesa AND ya_voto = 1;

  
  UPDATE mesa_electoral SET estado = 'CERRADA', hora_cierre = NOW() WHERE id_mesa = p_id_mesa;

  
  SET v_contenido = CONCAT(
      '{"tipo":"SUFRAGIO"',
      ',"id_proceso":', v_proceso,
      ',"mesa":', JSON_QUOTE(v_numero),
      ',"hora_cierre":', JSON_QUOTE(DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s')),
      ',"electores_habiles":', v_total,
      ',"electores_que_votaron":', v_votaron,
      ',"electores_omisos":', v_total - v_votaron,
      '}');
  CALL sp_emitir_acta(p_id_mesa, 'SUFRAGIO', v_contenido, v_token_suf);

  
  SELECT CONCAT('[', GROUP_CONCAT(
           JSON_OBJECT('cargo', c.nombre,
                       'lista', COALESCE(l.nombre, CONCAT('VOTO ', x.tipo_voto)),
                       'tipo',  CONCAT(x.tipo_voto, ''),
                       'votos', x.n)
           ORDER BY c.id_cargo, x.n DESC SEPARATOR ','), ']')
    INTO v_detalle
    FROM (SELECT id_cargo, id_lista_elegida, tipo_voto, COUNT(*) AS n
            FROM voto WHERE id_mesa = p_id_mesa
           GROUP BY id_cargo, id_lista_elegida, tipo_voto) x
    JOIN cargo_electoral c ON c.id_cargo = x.id_cargo
    LEFT JOIN lista_electoral l ON l.id_lista = x.id_lista_elegida;

  SET v_contenido = CONCAT(
      '{"tipo":"ESCRUTINIO"',
      ',"id_proceso":', v_proceso,
      ',"mesa":', JSON_QUOTE(v_numero),
      ',"electores_que_votaron":', v_votaron,
      ',"resultados":', COALESCE(v_detalle, '[]'),
      '}');
  CALL sp_emitir_acta(p_id_mesa, 'ESCRUTINIO', v_contenido, v_token_esc);

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'CERRAR_MESA',
       JSON_OBJECT('id_mesa', p_id_mesa, 'votaron', v_votaron));
  COMMIT;

  SELECT p_id_mesa AS id_mesa, v_token_suf AS token_qr_sufragio, v_token_esc AS token_qr_escrutinio;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_cerrar_votacion` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cerrar_votacion`(
  IN p_id_mesa    INT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_proceso    INT DEFAULT NULL;
  DECLARE v_estado     VARCHAR(20) DEFAULT NULL;
  DECLARE v_mesa_est   VARCHAR(20) DEFAULT NULL;
  DECLARE v_fin        DATETIME;
  DECLARE v_control    INT DEFAULT 1;
  DECLARE v_electores  INT DEFAULT 0;
  DECLARE v_votaron    INT DEFAULT 0;
  DECLARE v_asistieron INT DEFAULT 0;
  DECLARE v_votando    INT DEFAULT 0;
  DECLARE v_cedulas    INT DEFAULT NULL;
  DECLARE v_anticipado INT DEFAULT 0;
  DECLARE v_ahora      DATETIME;
  DECLARE v_msg        VARCHAR(255);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT m.id_proceso, p.estado, m.estado, p.fecha_fin
    INTO v_proceso, v_estado, v_mesa_est, v_fin
    FROM mesa_electoral m JOIN proceso_electoral p ON p.id_proceso = m.id_proceso
   WHERE m.id_mesa = p_id_mesa
     FOR UPDATE;

  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no existe.';
  END IF;
  IF v_mesa_est = 'CERRADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El sufragio de esta mesa ya se cerró.';
  END IF;
  IF v_estado <> 'VOTACION' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El sufragio se cierra con el proceso en VOTACION.';
  END IF;
  IF v_mesa_est <> 'INSTALADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se cierra el sufragio de una mesa INSTALADA (CUS08).';
  END IF;

  
  SELECT COUNT(*), COALESCE(SUM(x.voto), 0)
    INTO v_electores, v_votaron
    FROM (SELECT id_docente, MAX(ya_voto) AS voto
            FROM padron_electoral
           WHERE id_mesa = p_id_mesa AND habilitado_para_votar = 1
           GROUP BY id_docente) x;
  SELECT COUNT(*) INTO v_asistieron FROM asistencia_elector WHERE id_mesa = p_id_mesa;

  
  SELECT COUNT(*) INTO v_votando
    FROM habilitacion_terminal h JOIN asistencia_elector a ON a.id_asistencia = h.id_asistencia
   WHERE a.id_mesa = p_id_mesa AND h.estado = 'PENDIENTE';
  IF v_votando > 0 THEN
    SET v_msg = CONCAT('A1 (Art. 51a): ', v_votando, ' elector(es) aún votan en un terminal. Espere a que terminen ',
                       'o anule la habilitación si el elector abandonó la cabina.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  
  SET v_ahora = NOW();
  SET v_control = COALESCE((SELECT ROUND(CAST(valor AS DECIMAL(6,2)))
                              FROM parametro_global WHERE clave = 'SUFRAGIO_CONTROL_HORARIO'), 1);
  IF v_ahora < v_fin THEN
    IF v_votaron >= v_electores THEN
      SET v_anticipado = 1;
    ELSEIF v_control = 1 THEN
      SET v_msg = CONCAT('RN06: el sufragio se cierra a las ', DATE_FORMAT(v_fin, '%H:%i'), ' del ',
                         DATE_FORMAT(v_fin, '%d/%m/%Y'), '. Antes solo se cierra si ya votaron todos los electores (faltan ',
                         v_electores - v_votaron, ').');
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    ELSE
      SET v_anticipado = 1;
    END IF;
  END IF;

  SELECT MAX(cedulas_recibidas) INTO v_cedulas FROM instalacion_mesa WHERE id_mesa = p_id_mesa;

  
  UPDATE mesa_electoral SET estado = 'CERRADA', hora_cierre = v_ahora WHERE id_mesa = p_id_mesa;
  
  UPDATE terminal_votacion SET activo = 0 WHERE id_mesa = p_id_mesa;

  INSERT INTO cierre_mesa (id_mesa, estado, hora_cierre, cierre_anticipado, total_electores, total_votaron,
                           total_no_votaron, asistieron_sin_votar, cedulas_recibidas, id_usuario_cierre)
  VALUES (p_id_mesa, 'VOTACION_CERRADA', v_ahora, v_anticipado, v_electores, v_votaron,
          v_electores - v_votaron, GREATEST(v_asistieron - v_votaron, 0), v_cedulas, p_id_usuario);

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'CERRAR_SUFRAGIO',
       JSON_OBJECT('id_mesa', p_id_mesa, 'votaron', v_votaron, 'electores', v_electores,
                   'anticipado', v_anticipado));
  COMMIT;

  
  SELECT p_id_mesa AS id_mesa, v_ahora AS hora_cierre, v_electores AS total_electores,
         v_votaron AS total_votaron, v_electores - v_votaron AS total_no_votaron;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_comprobar_acta` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_comprobar_acta`(
  IN p_id_acta     INT,
  IN p_id_usuario  INT,
  IN p_token_qr    VARCHAR(300),
  IN p_observacion VARCHAR(500)
)
BEGIN
  DECLARE v_proceso   INT DEFAULT NULL;
  DECLARE v_resultado VARCHAR(12) DEFAULT NULL;
  DECLARE v_hash      CHAR(64);
  DECLARE v_guardado  CHAR(64);
  DECLARE v_token_h   CHAR(64);
  DECLARE v_token     VARCHAR(64);
  DECLARE v_huella    INT;
  DECLARE v_qr        INT DEFAULT NULL;
  DECLARE v_final     VARCHAR(12);
  DECLARE v_n         INT DEFAULT 0;
  DECLARE v_huella_prev INT DEFAULT NULL;
  DECLARE v_mesa_ver  INT DEFAULT NULL;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT COUNT(*) INTO v_n FROM verificacion_acta WHERE id_acta = p_id_acta;
  IF v_n = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: marque primero el acta como dudosa.';
  END IF;
  SELECT v.id_proceso, v.resultado, v.huella_coincide, v.id_mesa, SHA2(a.contenido_json, 256), a.hash_integridad, a.token_qr_hash
    INTO v_proceso, v_resultado, v_huella_prev, v_mesa_ver, v_hash, v_guardado, v_token_h
    FROM verificacion_acta v JOIN acta_electoral a ON a.id_acta = v.id_acta
   WHERE v.id_acta = p_id_acta
     FOR UPDATE;
  
  IF v_resultado = 'AUTENTICA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: la autenticidad de esta acta ya fue comprobada.';
  END IF;
  IF v_resultado = 'NO_AUTENTICA' AND (COALESCE(v_huella_prev, 0) = 0
       OR EXISTS (SELECT 1 FROM calificacion_mesa WHERE id_mesa = v_mesa_ver)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: el contenido del acta no coincide con su huella o la mesa ya fue calificada; solo procede la nulidad de la mesa.';
  END IF;
  IF EXISTS (SELECT 1 FROM computo_proceso WHERE id_proceso = v_proceso AND estado <> 'SESION_INSTALADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN32: las actas se verifican antes del cómputo.';
  END IF;

  SET v_huella = IF(v_hash = v_guardado, 1, 0);
  IF p_token_qr IS NOT NULL AND TRIM(p_token_qr) <> '' THEN
    SET v_token = LOWER(REGEXP_SUBSTR(p_token_qr, '[0-9a-fA-F]{64}'));
    IF v_token IS NULL OR v_token = '' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: el código QR leído no es un código de acta válido.';
    END IF;
    SET v_qr = IF(SHA2(v_token, 256) = v_token_h, 1, 0);
  END IF;
  SET v_final = IF(v_huella = 1 AND COALESCE(v_qr, 1) = 1, 'AUTENTICA', 'NO_AUTENTICA');

  UPDATE verificacion_acta
     SET resultado = v_final, hash_recalculado = v_hash, huella_coincide = v_huella, qr_coincide = v_qr,
         observacion_comprobacion = NULLIF(TRIM(p_observacion), ''), fecha_comprobacion = NOW(),
         id_usuario_comprobacion = p_id_usuario
   WHERE id_acta = p_id_acta;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'COMPROBAR_ACTA',
       JSON_OBJECT('id_acta', p_id_acta, 'resultado', v_final, 'huella', v_huella, 'qr', v_qr));
  COMMIT;

  SELECT p_id_acta AS id_acta, v_final AS resultado, v_huella AS huella_coincide, v_qr AS qr_coincide,
         v_hash AS hash_recalculado, v_guardado AS hash_integridad;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_computar_resultados` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_computar_resultados`(
  IN p_id_proceso INT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_estado   VARCHAR(20) DEFAULT NULL;
  DECLARE v_tipo     VARCHAR(20) DEFAULT NULL;
  DECLARE v_quorum   DECIMAL(5,2);
  DECLARE v_fin      INT DEFAULT 0;
  DECLARE v_cargo    INT;
  DECLARE v_pct_min  DECIMAL(5,2);
  DECLARE v_hab      INT DEFAULT 0;
  DECLARE v_vot      INT DEFAULT 0;
  DECLARE v_validos  INT DEFAULT 0;
  DECLARE v_top      INT DEFAULT 0;
  DECLARE v_empate   INT DEFAULT 0;
  DECLARE v_ganadora INT DEFAULT NULL;
  DECLARE v_result   VARCHAR(20);
  DECLARE v_n        INT DEFAULT 0;
  DECLARE cur_cargos CURSOR FOR
    SELECT id_cargo, porcentaje_minimo_victoria
      FROM cargo_electoral WHERE id_proceso = p_id_proceso ORDER BY id_cargo;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = 1;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT COUNT(*) INTO v_n FROM proceso_electoral WHERE id_proceso = p_id_proceso;
  IF v_n = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;
  SELECT estado, tipo, quorum_minimo INTO v_estado, v_tipo, v_quorum
    FROM proceso_electoral WHERE id_proceso = p_id_proceso FOR UPDATE;

  IF v_estado <> 'CERRADO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el computo requiere el proceso en estado CERRADO.';
  END IF;
  SELECT COUNT(*) INTO v_n FROM resultado_electoral WHERE id_proceso = p_id_proceso;
  IF v_n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el computo ya fue realizado y es irreversible.';
  END IF;
  
  SELECT COUNT(*) INTO v_n FROM mesa_electoral
   WHERE id_proceso = p_id_proceso AND estado = 'INSTALADA';
  IF v_n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN32: aun hay mesas instaladas sin cerrar.';
  END IF;
  
  SELECT COUNT(*) INTO v_n FROM v_cuadre_votos WHERE id_proceso = p_id_proceso AND diferencia <> 0;
  IF v_n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN27: los votos no cuadran con el padron. Revise v_cuadre_votos.';
  END IF;

  
  INSERT INTO resultado_electoral (id_proceso, id_cargo, id_lista, tipo_voto, total_votos, porcentaje_validos, posicion)
  SELECT x.id_proceso, x.id_cargo, x.id_lista, 'VALIDO', x.n,
         CASE WHEN SUM(x.n) OVER (PARTITION BY x.id_cargo) = 0 THEN 0
              ELSE ROUND(x.n * 100 / SUM(x.n) OVER (PARTITION BY x.id_cargo), 2) END,
         RANK() OVER (PARTITION BY x.id_cargo ORDER BY x.n DESC)
    FROM (SELECT c.id_proceso, c.id_cargo, l.id_lista, COUNT(v.id_voto) AS n
            FROM cargo_electoral c
            JOIN lista_electoral l ON l.id_cargo = c.id_cargo AND l.estado = 'ADMITIDA'
            LEFT JOIN voto v ON v.id_lista_elegida = l.id_lista AND v.tipo_voto = 'VALIDO'
           WHERE c.id_proceso = p_id_proceso
           GROUP BY c.id_proceso, c.id_cargo, l.id_lista) x;

  
  INSERT INTO resultado_electoral (id_proceso, id_cargo, id_lista, tipo_voto, total_votos)
  SELECT c.id_proceso, c.id_cargo, NULL, 'BLANCO',
         (SELECT COUNT(*) FROM voto v WHERE v.id_cargo = c.id_cargo AND v.tipo_voto = 'BLANCO')
    FROM cargo_electoral c WHERE c.id_proceso = p_id_proceso;
  INSERT INTO resultado_electoral (id_proceso, id_cargo, id_lista, tipo_voto, total_votos)
  SELECT c.id_proceso, c.id_cargo, NULL, 'NULO',
         (SELECT COUNT(*) FROM voto v WHERE v.id_cargo = c.id_cargo AND v.tipo_voto = 'NULO')
    FROM cargo_electoral c WHERE c.id_proceso = p_id_proceso;

  
  SET v_fin = 0;
  OPEN cur_cargos;
  bucle: LOOP
    FETCH cur_cargos INTO v_cargo, v_pct_min;
    IF v_fin = 1 THEN
      LEAVE bucle;
    END IF;

    SELECT COUNT(*), COALESCE(SUM(ya_voto), 0) INTO v_hab, v_vot
      FROM padron_electoral WHERE id_cargo = v_cargo AND habilitado_para_votar = 1;

    SELECT COALESCE(SUM(total_votos), 0), COALESCE(MAX(total_votos), 0) INTO v_validos, v_top
      FROM resultado_electoral WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO';

    SELECT COUNT(*), MIN(id_lista) INTO v_empate, v_ganadora
      FROM resultado_electoral
     WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO' AND total_votos = v_top;

    IF v_hab = 0 OR (v_vot * 100 / v_hab) <= v_quorum THEN
      SET v_result = 'SIN_QUORUM';
    ELSEIF v_validos = 0 THEN
      SET v_result = 'DESIERTO';
    ELSEIF v_tipo = 'SEGUNDA_VUELTA' THEN
      SET v_result = IF(v_empate = 1, 'ELEGIDO', 'EMPATE');
    ELSEIF v_empate = 1 AND (v_top * 100 / v_validos) > v_pct_min THEN
      SET v_result = 'ELEGIDO';
    ELSE
      SET v_result = 'SEGUNDA_VUELTA';
    END IF;

    UPDATE cargo_electoral
       SET estado_resultado  = v_result,
           id_lista_ganadora = IF(v_result = 'ELEGIDO', v_ganadora, NULL)
     WHERE id_cargo = v_cargo;

    SET v_fin = 0;
  END LOOP;
  CLOSE cur_cargos;

  SELECT COUNT(*) INTO v_n FROM cargo_electoral
   WHERE id_proceso = p_id_proceso AND estado_resultado <> 'SIN_QUORUM';

  IF v_n = 0 THEN
    UPDATE proceso_electoral
       SET estado = 'ANULADO', motivo_anulacion = 'RN31: no se alcanzo el quorum minimo de participacion.'
     WHERE id_proceso = p_id_proceso;
  ELSE
    UPDATE proceso_electoral SET estado = 'FINALIZADO' WHERE id_proceso = p_id_proceso;
  END IF;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'COMPUTAR_RESULTADOS',
       JSON_OBJECT('cargos_con_quorum', v_n));
  COMMIT;

  SELECT c.nombre AS cargo, c.estado_resultado, l.nombre AS lista_ganadora,
         fn_participacion_cargo(c.id_cargo) AS participacion_pct
    FROM cargo_electoral c
    LEFT JOIN lista_electoral l ON l.id_lista = c.id_lista_ganadora
   WHERE c.id_proceso = p_id_proceso;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_contar_cedulas` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_contar_cedulas`(
  IN p_id_mesa        INT,
  IN p_id_usuario     INT,
  IN p_total_cedulas  INT,
  IN p_destruidas     BOOLEAN,
  IN p_observacion    VARCHAR(1000)
)
BEGIN
  DECLARE v_proceso   INT DEFAULT NULL;
  DECLARE v_estado    VARCHAR(20);
  DECLARE v_mesa_est  VARCHAR(20);
  DECLARE v_cierre    VARCHAR(20) DEFAULT NULL;
  DECLARE v_votantes  INT DEFAULT 0;
  DECLARE v_sobran    INT DEFAULT 0;
  DECLARE v_faltan    INT DEFAULT 0;
  DECLARE v_obs       VARCHAR(1000);
  DECLARE v_ahora     DATETIME;
  DECLARE v_msg       VARCHAR(255);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT m.id_proceso, p.estado, m.estado, c.estado, c.total_votaron
    INTO v_proceso, v_estado, v_mesa_est, v_cierre, v_votantes
    FROM mesa_electoral m
    JOIN proceso_electoral p ON p.id_proceso = m.id_proceso
    LEFT JOIN cierre_mesa c  ON c.id_mesa = m.id_mesa
   WHERE m.id_mesa = p_id_mesa
     FOR UPDATE;

  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no existe.';
  END IF;
  IF EXISTS (SELECT 1 FROM escrutinio_mesa WHERE id_mesa = p_id_mesa) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: las cédulas de esta mesa ya se contaron; el escrutinio es irreversible.';
  END IF;
  IF v_estado NOT IN ('VOTACION','CERRADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El escrutinio se realiza al terminar la votación del proceso.';
  END IF;
  IF v_mesa_est <> 'CERRADA' OR v_cierre IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondición: cierre primero el sufragio de la mesa (CUS11).';
  END IF;
  IF v_cierre <> 'ACTA_EMITIDA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondición: emita y firme primero el acta de sufragio (CUS11).';
  END IF;
  IF p_total_cedulas IS NULL OR p_total_cedulas < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF77: ingrese el total de cédulas contadas en el ánfora.';
  END IF;

  
  SET v_sobran = GREATEST(p_total_cedulas - v_votantes, 0);
  SET v_faltan = GREATEST(v_votantes - p_total_cedulas, 0);
  SET v_obs = NULLIF(TRIM(p_observacion), '');

  IF v_sobran > 0 AND COALESCE(p_destruidas, 0) = 0 THEN
    SET v_msg = CONCAT('A1 (RN27): hay ', v_sobran, ' cédula(s) más que votantes (', v_votantes,
                       '). Retírelas al azar, destrúyalas sin abrirlas y confírmelo.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  IF (v_sobran > 0 OR v_faltan > 0) AND v_obs IS NULL THEN
    SET v_msg = CONCAT(IF(v_sobran > 0, 'A1', 'A2'), ' (RF78): el ánfora tiene ', p_total_cedulas,
                       ' cédulas y votaron ', v_votantes, ' electores. Registre la observación.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  SET v_ahora = NOW();
  INSERT INTO escrutinio_mesa (id_mesa, estado, hora_inicio, total_votantes, cedulas_contadas, cedulas_sobrantes,
                               cedulas_faltantes, cedulas_escrutadas, observacion_cedulas, id_usuario_inicio)
  VALUES (p_id_mesa, 'CEDULAS_CONTADAS', v_ahora, v_votantes, p_total_cedulas, v_sobran,
          v_faltan, p_total_cedulas - v_sobran, v_obs, p_id_usuario);

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'CONTAR_CEDULAS',
       JSON_OBJECT('id_mesa', p_id_mesa, 'cedulas', p_total_cedulas, 'votantes', v_votantes,
                   'sobrantes_destruidas', v_sobran, 'faltantes', v_faltan));
  COMMIT;

  
  SELECT p_id_mesa AS id_mesa, v_ahora AS hora_inicio, v_votantes AS total_votantes,
         p_total_cedulas AS cedulas_contadas, v_sobran AS cedulas_sobrantes, v_faltan AS cedulas_faltantes,
         p_total_cedulas - v_sobran AS cedulas_escrutadas,
         IF(v_sobran > 0, 'SOBRAN', IF(v_faltan > 0, 'FALTAN', 'COINCIDE')) AS resultado;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_convocar_segunda_vuelta` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_convocar_segunda_vuelta`(
  IN  p_id_proceso       INT,
  IN  p_fecha_inicio     DATETIME,
  IN  p_fecha_fin        DATETIME,
  IN  p_id_usuario       INT,
  OUT p_id_proceso_nuevo INT
)
BEGIN
  DECLARE v_comp    VARCHAR(20) DEFAULT NULL;
  DECLARE v_fecha   DATETIME;
  DECLARE v_plazo   INT;
  DECLARE v_msg     VARCHAR(255);

  SELECT estado, fecha_computo INTO v_comp, v_fecha FROM computo_proceso WHERE id_proceso = p_id_proceso;
  IF v_comp IS NULL OR v_comp = 'SESION_INSTALADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN33: la segunda vuelta se convoca después del cómputo oficial.';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM cargo_electoral
                  WHERE id_proceso = p_id_proceso AND estado_resultado = 'SEGUNDA_VUELTA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN33: ningun cargo de este proceso requiere segunda vuelta.';
  END IF;
  IF p_fecha_inicio IS NULL OR p_fecha_fin IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Indique fecha de inicio y de fin de la segunda vuelta.';
  END IF;
  SET v_plazo = COALESCE(ROUND((SELECT CAST(valor AS DECIMAL(6,2)) FROM parametro_global WHERE clave = 'SEGUNDA_VUELTA_PLAZO_DIAS')), 15);
  IF p_fecha_inicio <= NOW() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN33: la segunda vuelta debe programarse en una fecha futura.';
  END IF;
  IF v_plazo > 0 AND p_fecha_inicio > v_fecha + INTERVAL v_plazo DAY THEN
    SET v_msg = CONCAT('RN33: la segunda vuelta se realiza dentro de los ', v_plazo, ' días siguientes al cómputo (hasta el ',
                       DATE_FORMAT(v_fecha + INTERVAL v_plazo DAY, '%d/%m/%Y'), ').');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  CALL sp_crear_segunda_vuelta(p_id_proceso, p_fecha_inicio, p_fecha_fin, p_id_usuario, p_id_proceso_nuevo);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_crear_mesas` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_crear_mesas`(
  IN p_id_proceso         INT,
  IN p_electores_por_mesa INT,
  IN p_ubicacion          VARCHAR(200),    
  IN p_id_usuario         INT
)
BEGIN
  DECLARE v_estado  VARCHAR(20) DEFAULT NULL;
  DECLARE v_tam     INT;
  DECLARE v_total   INT DEFAULT 0;
  DECLARE v_mesas   INT DEFAULT 0;
  DECLARE v_bloque  INT DEFAULT 0;
  DECLARE v_i       INT DEFAULT 1;
  DECLARE v_id_mesa INT;
  DECLARE v_n       INT DEFAULT 0;
  DECLARE v_ubic    VARCHAR(200);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT estado INTO v_estado FROM proceso_electoral WHERE id_proceso = p_id_proceso FOR UPDATE;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;
  IF v_estado NOT IN ('CREADO','INSCRIPCION') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Las mesas se crean antes de iniciar la votacion.';
  END IF;
  SELECT COUNT(*) INTO v_n FROM mesa_electoral WHERE id_proceso = p_id_proceso;
  IF v_n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso ya tiene mesas creadas.';
  END IF;

  SET v_tam = COALESCE(p_electores_por_mesa, fn_parametro_decimal('ELECTORES_POR_MESA'), 200);
  IF v_tam < 6 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN19: una mesa necesita al menos 6 electores para el sorteo.';
  END IF;
  SET v_ubic = COALESCE(NULLIF(TRIM(p_ubicacion), ''),
                        (SELECT valor FROM parametro_global WHERE clave = 'UBICACION_SUFRAGIO'),
                        'Biblioteca Central');

  DROP TEMPORARY TABLE IF EXISTS tmp_elector;
  CREATE TEMPORARY TABLE tmp_elector (n INT PRIMARY KEY, id_docente INT NOT NULL);
  INSERT INTO tmp_elector (n, id_docente)
  SELECT ROW_NUMBER() OVER (ORDER BY d.id_facultad, d.apellidos, d.nombres, d.id_docente), d.id_docente
    FROM docente d
   WHERE d.id_docente IN (SELECT pe.id_docente FROM padron_electoral pe
                           WHERE pe.id_proceso = p_id_proceso AND pe.habilitado_para_votar = 1);

  SELECT COUNT(*) INTO v_total FROM tmp_elector;
  IF v_total = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN04: primero genere el padron electoral.';
  END IF;

  SET v_mesas  = CEIL(v_total / v_tam);
  SET v_bloque = CEIL(v_total / v_mesas);

  WHILE v_i <= v_mesas DO
    SELECT COUNT(*) INTO v_n FROM tmp_elector
     WHERE n > (v_i - 1) * v_bloque AND n <= v_i * v_bloque;

    INSERT INTO mesa_electoral (id_proceso, numero_mesa, ubicacion, total_electores)
    VALUES (p_id_proceso, LPAD(v_i, 3, '0'), v_ubic, v_n);
    SET v_id_mesa = LAST_INSERT_ID();

    UPDATE padron_electoral pe
      JOIN tmp_elector t ON t.id_docente = pe.id_docente
       SET pe.id_mesa = v_id_mesa
     WHERE pe.id_proceso = p_id_proceso
       AND t.n > (v_i - 1) * v_bloque AND t.n <= v_i * v_bloque;

    SET v_i = v_i + 1;
  END WHILE;
  DROP TEMPORARY TABLE IF EXISTS tmp_elector;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'CREAR_MESAS',
       JSON_OBJECT('mesas', v_mesas, 'electores', v_total));
  COMMIT;

  SELECT id_mesa, numero_mesa, ubicacion, total_electores
    FROM mesa_electoral WHERE id_proceso = p_id_proceso ORDER BY numero_mesa;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_crear_proceso` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_crear_proceso`(
  IN  p_nombre             VARCHAR(200),
  IN  p_fecha_inicio       DATETIME,
  IN  p_fecha_fin          DATETIME,
  IN  p_quorum_minimo      DECIMAL(5,2),     
  IN  p_fecha_convocatoria DATE,             
  IN  p_limite_inscripcion DATETIME,         
  IN  p_id_usuario         INT,
  OUT p_id_proceso         INT
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  IF p_fecha_fin <= p_fecha_inicio THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de fin debe ser posterior a la de inicio.';
  END IF;
  IF p_limite_inscripcion IS NOT NULL AND p_limite_inscripcion >= p_fecha_inicio THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El limite de inscripcion debe ser anterior al inicio del sufragio.';
  END IF;

  INSERT INTO proceso_electoral (nombre, fecha_inicio, fecha_fin, estado, tipo, quorum_minimo,
                                 fecha_convocatoria, fecha_limite_inscripcion)
  VALUES (p_nombre, p_fecha_inicio, p_fecha_fin, 'CREADO', 'PRIMERA_VUELTA',
          COALESCE(p_quorum_minimo, 60.00), p_fecha_convocatoria, p_limite_inscripcion);
  SET p_id_proceso = LAST_INSERT_ID();

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'CREAR_PROCESO',
       JSON_OBJECT('nombre', p_nombre));
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_crear_segunda_vuelta` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_crear_segunda_vuelta`(
  IN  p_id_proceso_padre INT,
  IN  p_fecha_inicio     DATETIME,
  IN  p_fecha_fin        DATETIME,
  IN  p_id_usuario       INT,
  OUT p_id_proceso_nuevo INT
)
BEGIN
  DECLARE v_estado   VARCHAR(20) DEFAULT NULL;
  DECLARE v_tipo     VARCHAR(20) DEFAULT NULL;
  DECLARE v_nombre   VARCHAR(200);
  DECLARE v_quorum   DECIMAL(5,2);
  DECLARE v_fin      INT DEFAULT 0;
  DECLARE v_cargo    INT;
  DECLARE v_c_nombre VARCHAR(150);
  DECLARE v_c_nivel  VARCHAR(20);
  DECLARE v_c_jur    INT;
  DECLARE v_c_pct    DECIMAL(5,2);
  DECLARE v_cargo_nuevo INT;
  DECLARE v_l1       INT DEFAULT NULL;
  DECLARE v_l2       INT DEFAULT NULL;
  DECLARE v_lista_vieja INT;
  DECLARE v_lista_nueva INT;
  DECLARE v_i        INT;
  DECLARE v_n        INT DEFAULT 0;
  DECLARE v_max DECIMAL(9,4);
  DECLARE v_v2 DECIMAL(9,4);
  DECLARE v_arriba   INT;
  DECLARE v_empat    INT;
  DECLARE v_elegidas LONGTEXT;
  DECLARE v_msg      VARCHAR(255);
  DECLARE cur_cargos CURSOR FOR
    SELECT id_cargo, nombre, nivel_jurisdiccion, id_jurisdiccion, porcentaje_minimo_victoria
      FROM cargo_electoral
     WHERE id_proceso = p_id_proceso_padre AND estado_resultado = 'SEGUNDA_VUELTA'
     ORDER BY id_cargo;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = 1;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT COUNT(*) INTO v_n FROM proceso_electoral WHERE id_proceso = p_id_proceso_padre;
  IF v_n = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso de primera vuelta no existe.';
  END IF;
  SELECT estado, tipo, nombre, quorum_minimo INTO v_estado, v_tipo, v_nombre, v_quorum
    FROM proceso_electoral WHERE id_proceso = p_id_proceso_padre;

  IF v_estado <> 'FINALIZADO' OR v_tipo <> 'PRIMERA_VUELTA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN33: se requiere una primera vuelta FINALIZADA.';
  END IF;
  SELECT COUNT(*) INTO v_n FROM cargo_electoral
   WHERE id_proceso = p_id_proceso_padre AND estado_resultado = 'SEGUNDA_VUELTA';
  IF v_n = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN33: ningun cargo de este proceso requiere segunda vuelta.';
  END IF;
  SELECT COUNT(*) INTO v_n FROM proceso_electoral
   WHERE id_proceso_padre = p_id_proceso_padre AND estado <> 'ANULADO';
  IF v_n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe una segunda vuelta vigente para este proceso.';
  END IF;
  IF p_fecha_fin <= p_fecha_inicio THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de fin debe ser posterior a la de inicio.';
  END IF;

  INSERT INTO proceso_electoral (nombre, fecha_inicio, fecha_fin, estado, tipo, id_proceso_padre, quorum_minimo)
  VALUES (LEFT(CONCAT(v_nombre, ' - Segunda vuelta'), 200), p_fecha_inicio, p_fecha_fin,
          'CREADO', 'SEGUNDA_VUELTA', p_id_proceso_padre, v_quorum);
  SET p_id_proceso_nuevo = LAST_INSERT_ID();

  DROP TEMPORARY TABLE IF EXISTS tmp_candidato_sv;
  CREATE TEMPORARY TABLE tmp_candidato_sv (
    id_docente INT NOT NULL, rol_en_lista VARCHAR(100) NOT NULL, url_hoja_vida VARCHAR(300) NULL);

  SET v_fin = 0;
  OPEN cur_cargos;
  bucle: LOOP
    FETCH cur_cargos INTO v_cargo, v_c_nombre, v_c_nivel, v_c_jur, v_c_pct;
    IF v_fin = 1 THEN
      LEAVE bucle;
    END IF;

    INSERT INTO cargo_electoral (id_proceso, nombre, nivel_jurisdiccion, id_jurisdiccion, porcentaje_minimo_victoria)
    VALUES (p_id_proceso_nuevo, v_c_nombre, v_c_nivel, v_c_jur, v_c_pct);
    SET v_cargo_nuevo = LAST_INSERT_ID();

    INSERT INTO cargo_categoria_permitida (id_cargo, categoria, puede_votar, puede_postular)
    SELECT v_cargo_nuevo, categoria, puede_votar, puede_postular
      FROM cargo_categoria_permitida WHERE id_cargo = v_cargo;

    
    
    
    SELECT MAX(COALESCE(pct_ponderado, porcentaje_validos)) INTO v_max FROM resultado_electoral WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO';
    SELECT COUNT(*) INTO v_n FROM resultado_electoral WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO' AND COALESCE(pct_ponderado, porcentaje_validos) = v_max;
    SET v_v2 = v_max;
    IF v_n < 2 THEN
      SELECT COALESCE(MAX(COALESCE(pct_ponderado, porcentaje_validos)), v_max) INTO v_v2
        FROM resultado_electoral WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO' AND COALESCE(pct_ponderado, porcentaje_validos) < v_max;
    END IF;
    SELECT COUNT(*) INTO v_arriba FROM resultado_electoral WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO' AND COALESCE(pct_ponderado, porcentaje_validos) > v_v2;
    SELECT COUNT(*) INTO v_empat FROM resultado_electoral WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO' AND COALESCE(pct_ponderado, porcentaje_validos) = v_v2;
    SET v_elegidas = NULL;
    IF v_empat > 2 - v_arriba THEN
      SELECT MAX(listas_elegidas) INTO v_elegidas FROM dirimencia_empate
       WHERE id_cargo = v_cargo AND motivo = 'PASE_A_SEGUNDA_VUELTA';
      IF v_elegidas IS NULL THEN
        SET v_msg = CONCAT('RN33: en ', v_c_nombre, ' hay ', v_empat, ' listas empatadas por ', 2 - v_arriba,
                           ' cupo(s) de la segunda vuelta; el Pleno debe dirimirlo por sorteo (CUS15).');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
      END IF;
    END IF;
    SELECT MIN(id_lista), IF(COUNT(*) > 1, MAX(id_lista), NULL) INTO v_l1, v_l2
      FROM resultado_electoral
     WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO'
       AND (COALESCE(pct_ponderado, porcentaje_validos) > v_v2
            OR (COALESCE(pct_ponderado, porcentaje_validos) = v_v2 AND (v_elegidas IS NULL OR JSON_CONTAINS(v_elegidas, CAST(id_lista AS CHAR)))));

    SET v_i = 1;
    WHILE v_i <= 2 DO
      SET v_lista_vieja = IF(v_i = 1, v_l1, v_l2);
      IF v_lista_vieja IS NOT NULL THEN
        INSERT INTO lista_electoral (id_cargo, nombre, simbolo, estado, url_plan_gobierno)
        SELECT v_cargo_nuevo, nombre, simbolo, 'ADMITIDA', url_plan_gobierno
          FROM lista_electoral WHERE id_lista = v_lista_vieja;
        SET v_lista_nueva = LAST_INSERT_ID();

        DELETE FROM tmp_candidato_sv;
        INSERT INTO tmp_candidato_sv (id_docente, rol_en_lista, url_hoja_vida)
        SELECT id_docente, rol_en_lista, url_hoja_vida
          FROM candidato WHERE id_lista = v_lista_vieja AND estado_validacion = 'APROBADO';
        INSERT INTO candidato (id_lista, id_docente, rol_en_lista, url_hoja_vida, estado_validacion)
        SELECT v_lista_nueva, id_docente, rol_en_lista, url_hoja_vida, 'APROBADO'
          FROM tmp_candidato_sv;
      END IF;
      SET v_i = v_i + 1;
    END WHILE;

    
    INSERT INTO padron_electoral (id_proceso, id_cargo, id_docente, habilitado_para_votar, motivo_inhabilitacion)
    SELECT p_id_proceso_nuevo, v_cargo_nuevo, id_docente, habilitado_para_votar, motivo_inhabilitacion
      FROM padron_electoral WHERE id_cargo = v_cargo;

    SET v_fin = 0;
  END LOOP;
  CLOSE cur_cargos;
  DROP TEMPORARY TABLE IF EXISTS tmp_candidato_sv;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso_nuevo, 'CREAR_SEGUNDA_VUELTA',
       JSON_OBJECT('id_proceso_padre', p_id_proceso_padre));
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_crear_usuario` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_crear_usuario`(
  IN p_id_admin      INT,
  IN p_username      VARCHAR(80),
  IN p_password_hash VARCHAR(255),
  IN p_rol           VARCHAR(20),
  IN p_id_docente    INT,
  IN p_provisional   BOOLEAN
)
BEGIN
  DECLARE v_username VARCHAR(80);
  DECLARE v_error    VARCHAR(300);
  DECLARE v_id       INT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  CALL sp_validar_admin(p_id_admin);
  SET v_username = TRIM(p_username);
  IF v_username IS NULL OR CHAR_LENGTH(v_username) < 3 OR CHAR_LENGTH(v_username) > 80 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: el nombre de usuario debe tener entre 3 y 80 caracteres.';
  END IF;
  IF v_username NOT REGEXP '^[A-Za-z0-9._-]+$' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: el nombre de usuario solo admite letras, números, punto, guion y guion bajo.';
  END IF;
  IF p_rol IS NULL OR p_rol NOT IN ('ADMIN', 'CEUNP', 'DOCENTE', 'PERSONERO', 'MIEMBRO_MESA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: rol no válido.';
  END IF;
  IF p_password_hash IS NULL OR p_password_hash NOT LIKE '$2%' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: la contraseña debe llegar cifrada.';
  END IF;

  START TRANSACTION;
  IF EXISTS (SELECT 1 FROM usuario WHERE username = v_username FOR UPDATE) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: el nombre de usuario ya existe.';
  END IF;
  
  SET v_error = fn_error_docente_usuario(p_id_docente, p_rol, NULL);
  IF v_error IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
  END IF;

  INSERT INTO usuario (id_docente, username, password_hash, rol, activo, debe_cambiar_password, id_usuario_creador)
  VALUES (p_id_docente, v_username, p_password_hash, p_rol, TRUE, COALESCE(p_provisional, TRUE), p_id_admin);
  SET v_id = LAST_INSERT_ID();

  CALL sp_registrar_auditoria(p_id_admin, p_id_docente, NULL, 'CREAR_USUARIO',
       JSON_OBJECT('id_usuario', v_id, 'username', v_username, 'rol', p_rol, 'id_docente', p_id_docente,
                   'clave_provisional', IF(COALESCE(p_provisional, TRUE), 'SI', 'NO')));
  COMMIT;

  
  SELECT * FROM v_usuarios_admin WHERE id_usuario = v_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_declarar_mesa_no_instalada` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_declarar_mesa_no_instalada`(
  IN p_id_mesa    INT,
  IN p_id_usuario INT,
  IN p_motivo     VARCHAR(255)
)
BEGIN
  DECLARE v_proceso  INT DEFAULT NULL;
  DECLARE v_estado   VARCHAR(20) DEFAULT NULL;
  DECLARE v_mesa_est VARCHAR(20) DEFAULT NULL;
  DECLARE v_abierta  INT DEFAULT 0;
  DECLARE v_vencida  INT DEFAULT 0;
  DECLARE v_control  INT DEFAULT 1;
  DECLARE v_msg      VARCHAR(255);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_motivo IS NULL OR CHAR_LENGTH(TRIM(p_motivo)) < 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Indique el motivo (al menos 10 caracteres).';
  END IF;

  START TRANSACTION;

  SELECT m.id_proceso, p.estado, m.estado INTO v_proceso, v_estado, v_mesa_est
    FROM mesa_electoral m JOIN proceso_electoral p ON p.id_proceso = m.id_proceso
   WHERE m.id_mesa = p_id_mesa
     FOR UPDATE;

  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no existe.';
  END IF;
  IF v_estado <> 'VOTACION' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF58: solo durante la VOTACION se declara una mesa no instalada.';
  END IF;
  IF v_mesa_est <> 'PENDIENTE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo una mesa PENDIENTE puede declararse no instalada.';
  END IF;

  CALL sp_ventana_instalacion(v_proceso, v_abierta, v_vencida, v_control, v_msg);
  IF v_control = 1 AND v_vencida = 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RF58: la mesa se declara NO INSTALADA recién cuando vence el plazo de instalación.';
  END IF;

  UPDATE mesa_electoral SET estado = 'NO_INSTALADA' WHERE id_mesa = p_id_mesa;
  UPDATE miembro_mesa SET asistio = 0 WHERE id_mesa = p_id_mesa AND asistio IS NULL;
  UPDATE miembro_mesa SET rol_instalacion = NULL WHERE id_mesa = p_id_mesa;

  INSERT INTO instalacion_mesa (id_mesa, estado, motivo_no_instalacion, automatica, fecha_actualizacion,
                                id_usuario_registro, id_usuario_cierre)
  VALUES (p_id_mesa, 'NO_INSTALADA', TRIM(p_motivo), FALSE, NOW(), p_id_usuario, p_id_usuario)
  ON DUPLICATE KEY UPDATE estado = 'NO_INSTALADA', motivo_no_instalacion = TRIM(p_motivo), automatica = FALSE,
                          fecha_actualizacion = NOW(), id_usuario_cierre = p_id_usuario;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'MESA_NO_INSTALADA',
       JSON_OBJECT('id_mesa', p_id_mesa, 'motivo', TRIM(p_motivo), 'automatica', FALSE));
  COMMIT;

  SELECT p_id_mesa AS id_mesa, 'NO_INSTALADA' AS estado;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_demo_flujo_completo` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_demo_flujo_completo`()
BEGIN
  DECLARE v_i        INT DEFAULT 1;
  DECLARE v_deps     INT DEFAULT 0;
  DECLARE v_off      INT;
  DECLARE v_dep      INT;
  DECLARE v_fac      INT;
  DECLARE v_dni      VARCHAR(8);
  DECLARE v_doc      INT;
  DECLARE v_proceso  INT;
  DECLARE v_cargo    INT;
  DECLARE v_lista_a  INT;
  DECLARE v_lista_b  INT;
  DECLARE v_lista_c  INT;
  DECLARE v_cand     INT;
  DECLARE v_cand_c   INT;
  DECLARE v_tacha    INT;
  DECLARE v_mesa     INT DEFAULT 0;
  DECLARE v_sig      INT;
  DECLARE v_token    CHAR(64);
  DECLARE v_control  VARCHAR(255);

  SELECT COUNT(*) INTO v_deps FROM departamento;
  IF v_deps = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Importe primero 05_datos_iniciales.sql (facultades y departamentos).';
  END IF;

  
  WHILE v_i <= 60 DO
    SET v_dni = CONCAT('9', LPAD(v_i, 7, '0'));
    IF NOT EXISTS (SELECT 1 FROM docente WHERE dni = v_dni) THEN
      SET v_off = v_i MOD v_deps;
      SELECT id_departamento, id_facultad INTO v_dep, v_fac
        FROM departamento ORDER BY id_departamento LIMIT v_off, 1;
      INSERT INTO docente (dni, nombres, apellidos, categoria, dedicacion, estado,
                           id_facultad, id_departamento, grado_academico)
      VALUES (v_dni, 'Docente', CONCAT('Demo ', LPAD(v_i, 3, '0')),
              ELT(1 + (v_i MOD 3), 'PRINCIPAL', 'ASOCIADO', 'AUXILIAR'),
              'TC', 'ACTIVO', v_fac, v_dep, IF(v_i MOD 3 = 0, 'DOCTOR', 'MAESTRO'));
    END IF;
    SET v_i = v_i + 1;
  END WHILE;

  
  SELECT id_docente INTO v_doc FROM docente WHERE dni = '90000060';
  IF NOT EXISTS (SELECT 1 FROM cargo_admin WHERE id_docente = v_doc AND vigente = 1) THEN
    INSERT INTO cargo_admin (id_docente, id_catalogo_cargo, fecha_inicio)
    SELECT v_doc, id_catalogo_cargo, CURDATE() - INTERVAL 1 YEAR
      FROM catalogo_cargo WHERE nombre_cargo = 'Decano';
  END IF;

  
  CALL sp_crear_proceso(CONCAT('DEMO Elección de Rector ', DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s')),
                        NOW() - INTERVAL 1 HOUR, NOW() + INTERVAL 6 HOUR,
                        60.00, CURDATE() - INTERVAL 35 DAY, NULL, NULL, v_proceso);
  CALL sp_agregar_cargo(v_proceso, 'Rector y Vicerrectores', 'UNIVERSIDAD', NULL,
                        'PRINCIPAL,ASOCIADO,AUXILIAR', 'PRINCIPAL', v_cargo);
  CALL sp_cambiar_estado_proceso(v_proceso, 'INSCRIPCION', NULL);

  
  CALL sp_inscribir_lista(v_cargo, 'Lista A - Integridad Universitaria', 'A', NULL, NULL, v_lista_a);
  CALL sp_inscribir_lista(v_cargo, 'Lista B - Renovación Académica',     'B', NULL, NULL, v_lista_b);
  CALL sp_inscribir_lista(v_cargo, 'Lista C - Unidad Docente',           'C', NULL, NULL, v_lista_c);

  SELECT id_docente INTO v_doc FROM docente WHERE dni = '90000003';
  CALL sp_inscribir_candidato(v_lista_a, v_doc, 'RECTOR', NULL, NULL, v_cand);
  SELECT id_docente INTO v_doc FROM docente WHERE dni = '90000006';
  CALL sp_inscribir_candidato(v_lista_a, v_doc, 'VICERRECTOR_ACADEMICO', NULL, NULL, v_cand);
  SELECT id_docente INTO v_doc FROM docente WHERE dni = '90000009';
  CALL sp_inscribir_candidato(v_lista_a, v_doc, 'VICERRECTOR_INVESTIGACION', NULL, NULL, v_cand);

  SELECT id_docente INTO v_doc FROM docente WHERE dni = '90000012';
  CALL sp_inscribir_candidato(v_lista_b, v_doc, 'RECTOR', NULL, NULL, v_cand);
  SELECT id_docente INTO v_doc FROM docente WHERE dni = '90000015';
  CALL sp_inscribir_candidato(v_lista_b, v_doc, 'VICERRECTOR_ACADEMICO', NULL, NULL, v_cand);
  SELECT id_docente INTO v_doc FROM docente WHERE dni = '90000018';
  CALL sp_inscribir_candidato(v_lista_b, v_doc, 'VICERRECTOR_INVESTIGACION', NULL, NULL, v_cand);

  SELECT id_docente INTO v_doc FROM docente WHERE dni = '90000021';
  CALL sp_inscribir_candidato(v_lista_c, v_doc, 'RECTOR', NULL, NULL, v_cand_c);
  SELECT id_docente INTO v_doc FROM docente WHERE dni = '90000024';
  CALL sp_inscribir_candidato(v_lista_c, v_doc, 'VICERRECTOR_ACADEMICO', NULL, NULL, v_cand);
  SELECT id_docente INTO v_doc FROM docente WHERE dni = '90000027';
  CALL sp_inscribir_candidato(v_lista_c, v_doc, 'VICERRECTOR_INVESTIGACION', NULL, NULL, v_cand);

  
  SELECT id_docente INTO v_doc FROM docente WHERE dni = '90000001';
  CALL sp_presentar_tacha(v_doc, v_cand_c, 'No acredita el grado de Doctor (RN09).', v_tacha);
  CALL sp_resolver_tacha(v_tacha, 'FUNDADA', 'Se verificó que no cumple el requisito.', NULL);

  CALL sp_validar_lista(v_lista_a, TRUE, NULL, NULL);
  CALL sp_validar_lista(v_lista_b, TRUE, NULL, NULL);

  
  CALL sp_sortear_orden_cedula(v_cargo, 'DEMO-2026', NULL);
  CALL sp_generar_padron(v_proceso, NULL);
  CALL sp_crear_mesas(v_proceso, 30, 'Biblioteca Central', NULL);
  CALL sp_sortear_todas_las_mesas(v_proceso, 'DEMO-2026', NULL);

  
  CALL sp_cambiar_estado_proceso(v_proceso, 'VOTACION', NULL);

  
  
  UPDATE miembro_mesa mm JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
     SET mm.asistio = 1, mm.hora_acreditacion = NOW(), mm.metodo_acreditacion = 'DNI'
   WHERE m.id_proceso = v_proceso;
  UPDATE miembro_mesa mm JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
     SET mm.asistio = 0, mm.hora_acreditacion = NULL, mm.metodo_acreditacion = NULL
   WHERE m.id_proceso = v_proceso AND mm.rol = 'VOCAL' AND m.numero_mesa = '001';
  
  INSERT INTO instalacion_mesa (id_mesa, material_json, material_completo, cedulas_recibidas, cedulas_firmadas)
  SELECT id_mesa, CONCAT('{"PADRON":{"estado":"CONFORME","observacion":null},"ACTAS":{"estado":"CONFORME","observacion":null},',
                         '"CEDULAS":{"estado":"CONFORME","observacion":null},"CARTEL_CANDIDATOS":{"estado":"CONFORME","observacion":null},',
                         '"ANFORA":{"estado":"CONFORME","observacion":null},"CABINA":{"estado":"CONFORME","observacion":null}}'),
         TRUE, total_electores, TRUE
    FROM mesa_electoral WHERE id_proceso = v_proceso;

  
  SELECT valor INTO v_control FROM parametro_global WHERE clave = 'INSTALACION_CONTROL_HORARIO';
  UPDATE parametro_global SET valor = '0' WHERE clave = 'INSTALACION_CONTROL_HORARIO';

  SET v_mesa = 0;
  instalar: LOOP
    SELECT MIN(id_mesa) INTO v_sig FROM mesa_electoral WHERE id_proceso = v_proceso AND id_mesa > v_mesa;
    IF v_sig IS NULL THEN
      LEAVE instalar;
    END IF;
    CALL sp_instalar_mesa(v_sig, NULL);
    SET v_mesa = v_sig;
  END LOOP;

  UPDATE parametro_global SET valor = COALESCE(v_control, '1') WHERE clave = 'INSTALACION_CONTROL_HORARIO';

  
  SET v_i = 1;
  WHILE v_i <= 60 DO
    IF v_i MOD 7 <> 0 THEN
      SELECT id_docente INTO v_doc FROM docente WHERE dni = CONCAT('9', LPAD(v_i, 7, '0'));
      IF v_i MOD 10 = 0 THEN
        CALL sp_emitir_voto(v_proceso, v_cargo, v_doc, NULL, 'BLANCO', v_token);
      ELSEIF v_i MOD 5 < 3 THEN
        CALL sp_emitir_voto(v_proceso, v_cargo, v_doc, v_lista_a, 'VALIDO', v_token);
      ELSE
        CALL sp_emitir_voto(v_proceso, v_cargo, v_doc, v_lista_b, 'VALIDO', v_token);
      END IF;
    END IF;
    SET v_i = v_i + 1;
  END WHILE;

  
  SET v_mesa = 0;
  cerrar: LOOP
    SELECT MIN(id_mesa) INTO v_sig FROM mesa_electoral WHERE id_proceso = v_proceso AND id_mesa > v_mesa;
    IF v_sig IS NULL THEN
      LEAVE cerrar;
    END IF;
    CALL sp_cerrar_mesa(v_sig, NULL);
    SET v_mesa = v_sig;
  END LOOP;

  CALL sp_cambiar_estado_proceso(v_proceso, 'CERRADO', NULL);
  CALL sp_computar_resultados(v_proceso, NULL);
  CALL sp_generar_multas(v_proceso, NULL);

  
  SELECT * FROM v_quorum_proceso  WHERE id_proceso = v_proceso;
  SELECT * FROM v_resultados_cargo WHERE id_proceso = v_proceso ORDER BY votos DESC;
  SELECT * FROM v_cuadre_votos    WHERE id_proceso = v_proceso;
  SELECT * FROM v_mesa_detalle    WHERE id_proceso = v_proceso;
  SELECT 'La última constancia emitida se verifica así:' AS nota, v_token AS token_de_ejemplo;
  CALL sp_verificar_constancia(v_token);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_desbloquear_usuario` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_desbloquear_usuario`(IN p_id_admin INT, IN p_id_usuario INT)
BEGIN
  DECLARE v_intentos INT;
  DECLARE v_hasta    DATETIME;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  CALL sp_validar_admin(p_id_admin);
  START TRANSACTION;
  SELECT intentos_fallidos, bloqueado_hasta INTO v_intentos, v_hasta FROM usuario WHERE id_usuario = p_id_usuario FOR UPDATE;
  IF v_intentos IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: la cuenta no existe.';
  END IF;
  IF v_intentos = 0 AND (v_hasta IS NULL OR v_hasta <= NOW()) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: la cuenta no está bloqueada ni tiene intentos fallidos.';
  END IF;
  UPDATE usuario SET intentos_fallidos = 0, bloqueado_hasta = NULL, fecha_actualizacion = NOW()
   WHERE id_usuario = p_id_usuario;
  CALL sp_registrar_auditoria(p_id_admin, NULL, NULL, 'DESBLOQUEAR_USUARIO',
       JSON_OBJECT('id_usuario', p_id_usuario, 'intentos', v_intentos));
  COMMIT;

  SELECT * FROM v_usuarios_admin WHERE id_usuario = p_id_usuario;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_detalle_bitacora` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_detalle_bitacora`(IN p_id_admin INT, IN p_id_log BIGINT)
BEGIN
  DECLARE v_ant BIGINT;
  DECLARE v_sig BIGINT;
  DECLARE v_hash_ant CHAR(64);

  
  CALL sp_validar_admin(p_id_admin);
  IF NOT EXISTS (SELECT 1 FROM log_auditoria WHERE id_log = p_id_log) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS19: el registro de la bitácora no existe.';
  END IF;

  SELECT MAX(id_log) INTO v_ant FROM log_auditoria WHERE id_log < p_id_log;
  SELECT MIN(id_log) INTO v_sig FROM log_auditoria WHERE id_log > p_id_log;
  SELECT hash_registro INTO v_hash_ant FROM log_auditoria WHERE id_log = v_ant;

  SELECT v.*,
         v_ant AS id_anterior,
         v_sig AS id_siguiente,
         fn_hash_bitacora(l.hash_anterior, l.id_usuario, l.id_docente, l.id_proceso, l.accion,
                          l.ip_origen, l.user_agent, l.fecha_hora, l.detalle_json) AS hash_calculado,
         (l.hash_registro IS NOT NULL
          AND l.hash_registro = fn_hash_bitacora(l.hash_anterior, l.id_usuario, l.id_docente, l.id_proceso, l.accion,
                                                 l.ip_origen, l.user_agent, l.fecha_hora, l.detalle_json)) AS contenido_integro,
         
         (l.hash_anterior IS NOT NULL
          AND (l.hash_anterior = v_hash_ant OR (l.hash_anterior = REPEAT('0', 64)
               AND (v_ant IS NULL OR l.accion = 'REINICIAR_BITACORA')))) AS enlace_valido,
         (SELECT COUNT(*) FROM log_auditoria x
           WHERE x.id_usuario = l.id_usuario AND l.id_usuario IS NOT NULL) AS acciones_usuario,
         (SELECT COUNT(*) FROM log_auditoria x
           WHERE x.id_proceso = l.id_proceso AND l.id_proceso IS NOT NULL) AS acciones_proceso
    FROM v_bitacora v JOIN log_auditoria l ON l.id_log = v.id_log
   WHERE v.id_log = p_id_log;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_dirimir_empate` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_dirimir_empate`(
  IN p_id_cargo          INT,
  IN p_id_usuario        INT,
  IN p_semilla           VARCHAR(100),
  IN p_numero_resolucion VARCHAR(40),
  IN p_miembros_pleno    INT,
  IN p_fundamento        VARCHAR(1000)
)
BEGIN
  DECLARE v_proceso  INT DEFAULT NULL;
  DECLARE v_cargo_n  VARCHAR(150);
  DECLARE v_result   VARCHAR(20);
  DECLARE v_tipo     VARCHAR(20);
  DECLARE v_estado   VARCHAR(20);
  DECLARE v_comp     VARCHAR(20);
  DECLARE v_motivo   VARCHAR(25);
  DECLARE v_semilla  VARCHAR(100);
  DECLARE v_res      VARCHAR(40);
  DECLARE v_quorum   INT;
  DECLARE v_max DECIMAL(9,4);
  DECLARE v_v2 DECIMAL(9,4);
  DECLARE v_n        INT DEFAULT 0;
  DECLARE v_arriba   INT DEFAULT 0;
  DECLARE v_empat    INT DEFAULT 0;
  DECLARE v_cupos    INT;
  DECLARE v_ganadora INT;
  DECLARE v_listas   LONGTEXT;
  DECLARE v_elegidas LONGTEXT;
  DECLARE v_nombres  VARCHAR(500);
  DECLARE v_msg      VARCHAR(255);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET SESSION group_concat_max_len = 100000;
  START TRANSACTION;
  SELECT c.id_proceso, c.nombre, CONCAT(c.estado_resultado, ''), p.tipo, p.estado
    INTO v_proceso, v_cargo_n, v_result, v_tipo, v_estado
    FROM cargo_electoral c JOIN proceso_electoral p ON p.id_proceso = c.id_proceso
   WHERE c.id_cargo = p_id_cargo FOR UPDATE;
  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cargo no existe.';
  END IF;
  SELECT estado INTO v_comp FROM computo_proceso WHERE id_proceso = v_proceso;
  IF v_tipo = 'SEGUNDA_VUELTA' AND v_result = 'EMPATE' THEN
    SET v_motivo = 'EMPATE_SEGUNDA_VUELTA';
    IF v_estado <> 'FINALIZADO' OR COALESCE(v_comp, '') <> 'COMPUTADO' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF98: el empate se dirime después del cómputo y antes de la proclamación.';
    END IF;
  ELSEIF v_tipo = 'PRIMERA_VUELTA' AND v_result = 'SEGUNDA_VUELTA' THEN
    SET v_motivo = 'PASE_A_SEGUNDA_VUELTA';
    IF v_estado <> 'FINALIZADO' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN33: el pase a la segunda vuelta se dirime con la primera vuelta computada.';
    END IF;
    IF EXISTS (SELECT 1 FROM proceso_electoral WHERE id_proceso_padre = v_proceso AND estado <> 'ANULADO') THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN33: la segunda vuelta ya fue convocada.';
    END IF;
  ELSE
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF97: el cargo no tiene un empate que dirimir.';
  END IF;
  IF EXISTS (SELECT 1 FROM dirimencia_empate WHERE id_cargo = p_id_cargo) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el empate de este cargo ya fue dirimido.';
  END IF;

  
  SELECT MAX(COALESCE(pct_ponderado, porcentaje_validos)) INTO v_max FROM resultado_electoral WHERE id_cargo = p_id_cargo AND tipo_voto = 'VALIDO';
  IF v_motivo = 'EMPATE_SEGUNDA_VUELTA' THEN
    SET v_v2 = v_max;
    SET v_cupos = 1;
  ELSE
    SELECT COUNT(*) INTO v_n FROM resultado_electoral WHERE id_cargo = p_id_cargo AND tipo_voto = 'VALIDO' AND COALESCE(pct_ponderado, porcentaje_validos) = v_max;
    SET v_v2 = v_max;
    IF v_n < 2 THEN
      SELECT COALESCE(MAX(COALESCE(pct_ponderado, porcentaje_validos)), v_max) INTO v_v2
        FROM resultado_electoral WHERE id_cargo = p_id_cargo AND tipo_voto = 'VALIDO' AND COALESCE(pct_ponderado, porcentaje_validos) < v_max;
    END IF;
    SELECT COUNT(*) INTO v_arriba FROM resultado_electoral WHERE id_cargo = p_id_cargo AND tipo_voto = 'VALIDO' AND COALESCE(pct_ponderado, porcentaje_validos) > v_v2;
    SET v_cupos = 2 - v_arriba;
  END IF;
  SELECT COUNT(*), CONCAT('[', GROUP_CONCAT(JSON_OBJECT('id_lista', r.id_lista, 'lista', l.nombre, 'votos', r.total_votos)
                                            ORDER BY r.id_lista SEPARATOR ','), ']')
    INTO v_empat, v_listas
    FROM resultado_electoral r JOIN lista_electoral l ON l.id_lista = r.id_lista
   WHERE r.id_cargo = p_id_cargo AND r.tipo_voto = 'VALIDO' AND COALESCE(r.pct_ponderado, r.porcentaje_validos) = v_v2;
  IF v_empat <= v_cupos OR v_cupos < 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF97: no hay listas empatadas que dirimir en este cargo.';
  END IF;

  SET v_semilla = NULLIF(TRIM(p_semilla), '');
  IF v_semilla IS NULL OR CHAR_LENGTH(v_semilla) < 4 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Indique la semilla pública del sorteo (al menos 4 caracteres).';
  END IF;
  SET v_res = NULLIF(TRIM(p_numero_resolucion), '');
  IF v_res IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: indique el número de la resolución del CEUNP.';
  END IF;
  IF fn_resolucion_en_uso(v_res) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;
  SET v_quorum = COALESCE(ROUND((SELECT CAST(valor AS DECIMAL(6,2)) FROM parametro_global WHERE clave = 'CEUNP_QUORUM_PLENO')), 5);
  IF p_miembros_pleno IS NULL OR p_miembros_pleno < v_quorum OR p_miembros_pleno > 9 THEN
    SET v_msg = CONCAT('RN36: el Pleno del CEUNP resuelve con quórum de ', v_quorum, ' de sus 9 miembros.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  
  SELECT CONCAT('[', GROUP_CONCAT(x.id_lista ORDER BY x.orden SEPARATOR ','), ']'),
         GROUP_CONCAT(x.nombre ORDER BY x.orden SEPARATOR ' y '), MIN(IF(x.orden = 1, x.id_lista, NULL))
    INTO v_elegidas, v_nombres, v_ganadora
    FROM (SELECT r.id_lista, l.nombre,
                 ROW_NUMBER() OVER (ORDER BY SHA2(CONCAT(v_semilla, '|', p_id_cargo, '|', r.id_lista), 256)) AS orden
            FROM resultado_electoral r JOIN lista_electoral l ON l.id_lista = r.id_lista
           WHERE r.id_cargo = p_id_cargo AND r.tipo_voto = 'VALIDO' AND COALESCE(r.pct_ponderado, r.porcentaje_validos) = v_v2) x
   WHERE x.orden <= v_cupos;

  INSERT INTO dirimencia_empate (id_cargo, id_proceso, motivo, semilla, cupos, listas_empatadas, listas_elegidas,
                                 numero_resolucion, miembros_pleno, fundamento, fecha, id_usuario, hash_integridad)
  VALUES (p_id_cargo, v_proceso, v_motivo, v_semilla, v_cupos, v_listas, v_elegidas, v_res, p_miembros_pleno,
          NULLIF(TRIM(p_fundamento), ''), NOW(), p_id_usuario,
          SHA2(CONCAT(v_semilla, '|', p_id_cargo, '|', v_listas, '|', v_elegidas, '|', v_res), 256));
  IF v_motivo = 'EMPATE_SEGUNDA_VUELTA' THEN
    UPDATE cargo_electoral SET estado_resultado = 'ELEGIDO', id_lista_ganadora = v_ganadora WHERE id_cargo = p_id_cargo;
  END IF;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'DIRIMIR_EMPATE',
       JSON_OBJECT('id_cargo', p_id_cargo, 'motivo', v_motivo, 'semilla', v_semilla, 'elegidas', v_elegidas, 'resolucion', v_res));
  COMMIT;

  SELECT p_id_cargo AS id_cargo, v_cargo_n AS cargo, v_motivo AS motivo, v_cupos AS cupos, v_empat AS empatadas,
         v_elegidas AS listas_elegidas, v_nombres AS listas;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_ejecutar_computo` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ejecutar_computo`(
  IN p_id_proceso INT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_estado    VARCHAR(20) DEFAULT NULL;
  DECLARE v_tipo      VARCHAR(20);
  DECLARE v_nombre    VARCHAR(200);
  DECLARE v_quorum    DECIMAL(5,2);
  DECLARE v_comp      VARCHAR(20) DEFAULT NULL;
  DECLARE v_lugar     VARCHAR(200);
  DECLARE v_miembros  INT;
  DECLARE v_sesion    DATETIME;
  DECLARE v_fin       INT DEFAULT 0;
  DECLARE v_cargo     INT;
  DECLARE v_pct_min   DECIMAL(5,2);
  DECLARE v_hab       INT DEFAULT 0;
  DECLARE v_vot       INT DEFAULT 0;
  DECLARE v_validos   INT DEFAULT 0;
  DECLARE v_top_pct   DECIMAL(5,2) DEFAULT 0;
  DECLARE v_empate    INT DEFAULT 0;
  DECLARE v_ganadora  INT DEFAULT NULL;
  DECLARE v_result    VARCHAR(20);
  DECLARE v_n         INT DEFAULT 0;
  DECLARE v_txt       VARCHAR(200);
  DECLARE v_msg       VARCHAR(255);
  DECLARE v_mesas     INT DEFAULT 0;
  DECLARE v_computadas INT DEFAULT 0;
  DECLARE v_no_inst   INT DEFAULT 0;
  DECLARE v_anuladas  INT DEFAULT 0;
  DECLARE v_actas     INT DEFAULT 0;
  DECLARE v_dudosas   INT DEFAULT 0;
  DECLARE v_p_hab     INT DEFAULT 0;
  DECLARE v_p_vot     INT DEFAULT 0;
  DECLARE v_p_pct     DECIMAL(5,2) DEFAULT 0;
  DECLARE v_con_q     INT DEFAULT 0;
  DECLARE v_resultado VARCHAR(15);
  DECLARE v_ahora     DATETIME;
  DECLARE v_cargos    LONGTEXT;
  DECLARE v_det_mesas LONGTEXT;
  DECLARE v_pers      LONGTEXT;
  DECLARE v_contenido LONGTEXT;
  DECLARE v_token     CHAR(64);
  DECLARE cur_cargos CURSOR FOR
    SELECT id_cargo, porcentaje_minimo_victoria
      FROM cargo_electoral WHERE id_proceso = p_id_proceso ORDER BY id_cargo;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = 1;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET SESSION group_concat_max_len = 4000000;
  CREATE TEMPORARY TABLE IF NOT EXISTS tmp_computo_cus14 (
    id_cargo INT NOT NULL, opcion VARCHAR(12) NOT NULL, id_lista INT NULL, votos INT NOT NULL,
    clave INT NOT NULL, PRIMARY KEY (id_cargo, opcion, clave)) ENGINE=MEMORY;
  DELETE FROM tmp_computo_cus14;

  START TRANSACTION;

  SELECT estado, tipo, nombre, quorum_minimo INTO v_estado, v_tipo, v_nombre, v_quorum
    FROM proceso_electoral WHERE id_proceso = p_id_proceso FOR UPDATE;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;
  SELECT estado, lugar_sesion, miembros_ceunp, fecha_sesion INTO v_comp, v_lugar, v_miembros, v_sesion
    FROM computo_proceso WHERE id_proceso = p_id_proceso FOR UPDATE;
  IF v_comp IS NOT NULL AND v_comp <> 'SESION_INSTALADA'
     OR EXISTS (SELECT 1 FROM resultado_electoral WHERE id_proceso = p_id_proceso) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el cómputo ya fue realizado y es irreversible.';
  END IF;
  IF v_estado <> 'CERRADO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN32: el cómputo requiere la votación del proceso concluida (CERRADO).';
  END IF;
  IF v_comp IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF91: instale primero la sesión de cómputo general.';
  END IF;

  
  SELECT COUNT(*), MIN(CONCAT('mesa ', numero_mesa, ': ', REPLACE(LOWER(situacion), '_', ' ')))
    INTO v_n, v_txt
    FROM v_computo_mesas
   WHERE id_proceso = p_id_proceso AND situacion NOT IN ('HABILITADA','NO_INSTALADA','ANULADA');
  IF v_n > 0 THEN
    SET v_msg = CONCAT('RN32: ', v_n, ' mesa(s) impiden el cómputo (', v_txt, '). Revise la verificación previa.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  SELECT COUNT(*), COALESCE(SUM(situacion = 'HABILITADA'), 0), COALESCE(SUM(situacion = 'NO_INSTALADA'), 0),
         COALESCE(SUM(situacion = 'ANULADA'), 0)
    INTO v_mesas, v_computadas, v_no_inst, v_anuladas
    FROM v_computo_mesas WHERE id_proceso = p_id_proceso;

  
  SELECT COUNT(*), COALESCE(SUM(integra = 0), 0), COALESCE(SUM(dudosa), 0) INTO v_actas, v_n, v_dudosas
    FROM v_computo_actas WHERE id_proceso = p_id_proceso AND estado = 'VIGENTE';
  IF v_n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: hay actas cuya huella SHA-256 no coincide con su contenido.';
  END IF;

  
  INSERT INTO tmp_computo_cus14 (id_cargo, opcion, id_lista, votos, clave)
  SELECT id_cargo, opcion, id_lista, votos, COALESCE(id_lista, 0)
    FROM v_computo_resultados WHERE id_proceso = p_id_proceso;
  IF EXISTS (SELECT 1 FROM tmp_computo_cus14 WHERE opcion = 'IMPUGNADO' AND votos > 0) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS13: hay cédulas impugnadas sin opción asignada.';
  END IF;

  
  INSERT INTO resultado_electoral (id_proceso, id_cargo, id_lista, tipo_voto, total_votos, votos_docentes, votos_estudiantes, porcentaje_validos, pct_docente, pct_estudiante, pct_ponderado, posicion)
  SELECT 
    sub.id_proceso,
    sub.id_cargo,
    sub.id_lista,
    'VALIDO',
    sub.n_doc AS total_votos,   
    sub.n_doc AS votos_docentes,
    sub.n_est AS votos_estudiantes,
    sub.pct_pond AS porcentaje_validos,
    sub.pct_doc AS pct_docente,
    sub.pct_est AS pct_estudiante,
    sub.pct_pond AS pct_ponderado,
    RANK() OVER (PARTITION BY sub.id_cargo ORDER BY sub.pct_pond DESC, sub.n_doc DESC, sub.n_est DESC) AS posicion
  FROM (
    SELECT 
      c.id_proceso, 
      c.id_cargo, 
      l.id_lista,
      COALESCE(t.votos, 0) AS n_doc,
      COALESCE(ce.votos_estudiantes, 0) AS n_est,
      CASE 
        WHEN SUM(COALESCE(t.votos, 0)) OVER (PARTITION BY c.id_cargo) = 0 THEN 0.00
        ELSE ROUND(COALESCE(t.votos, 0) * 100.0 / SUM(COALESCE(t.votos, 0)) OVER (PARTITION BY c.id_cargo), 2)
      END AS pct_doc,
      CASE 
        WHEN SUM(COALESCE(ce.votos_estudiantes, 0)) OVER (PARTITION BY c.id_cargo) = 0 THEN 0.00
        ELSE ROUND(COALESCE(ce.votos_estudiantes, 0) * 100.0 / SUM(COALESCE(ce.votos_estudiantes, 0)) OVER (PARTITION BY c.id_cargo), 2)
      END AS pct_est,
      CASE
        WHEN SUM(COALESCE(ce.votos_estudiantes, 0)) OVER (PARTITION BY c.id_cargo) > 0 THEN
          ROUND(
            (CASE 
               WHEN SUM(COALESCE(t.votos, 0)) OVER (PARTITION BY c.id_cargo) = 0 THEN 0.00
               ELSE (COALESCE(t.votos, 0) * 100.0 / SUM(COALESCE(t.votos, 0)) OVER (PARTITION BY c.id_cargo))
             END * (2.0 / 3.0)) +
            (CASE 
               WHEN SUM(COALESCE(ce.votos_estudiantes, 0)) OVER (PARTITION BY c.id_cargo) = 0 THEN 0.00
               ELSE (COALESCE(ce.votos_estudiantes, 0) * 100.0 / SUM(COALESCE(ce.votos_estudiantes, 0)) OVER (PARTITION BY c.id_cargo))
             END * (1.0 / 3.0)),
            2
          )
        ELSE
          CASE 
            WHEN SUM(COALESCE(t.votos, 0)) OVER (PARTITION BY c.id_cargo) = 0 THEN 0.00
            ELSE ROUND(COALESCE(t.votos, 0) * 100.0 / SUM(COALESCE(t.votos, 0)) OVER (PARTITION BY c.id_cargo), 2)
          END
      END AS pct_pond
    FROM cargo_electoral c
    JOIN lista_electoral l ON l.id_cargo = c.id_cargo AND l.estado = 'ADMITIDA'
    LEFT JOIN tmp_computo_cus14 t ON t.id_cargo = c.id_cargo AND t.opcion = 'LISTA' AND t.clave = l.id_lista
    LEFT JOIN computo_estudiantil ce ON ce.id_cargo = c.id_cargo AND ce.id_lista = l.id_lista AND ce.id_proceso = p_id_proceso
    WHERE c.id_proceso = p_id_proceso
  ) sub;

  INSERT INTO resultado_electoral (id_proceso, id_cargo, id_lista, tipo_voto, total_votos, votos_docentes, votos_estudiantes)
  SELECT c.id_proceso, c.id_cargo, NULL, o.opcion, COALESCE(t.votos, 0), COALESCE(t.votos, 0), 0
    FROM cargo_electoral c
    CROSS JOIN (SELECT 'BLANCO' AS opcion UNION ALL SELECT 'NULO') o
    LEFT JOIN tmp_computo_cus14 t ON t.id_cargo = c.id_cargo AND t.opcion = o.opcion AND t.clave = 0
   WHERE c.id_proceso = p_id_proceso;

  
  SET v_fin = 0;
  OPEN cur_cargos;
  bucle: LOOP
    FETCH cur_cargos INTO v_cargo, v_pct_min;
    IF v_fin = 1 THEN
      LEAVE bucle;
    END IF;

    SELECT COUNT(*), COALESCE(SUM(ya_voto), 0) INTO v_hab, v_vot
      FROM padron_electoral WHERE id_cargo = v_cargo AND habilitado_para_votar = 1;
    SELECT COALESCE(SUM(total_votos), 0), COALESCE(MAX(pct_ponderado), 0) INTO v_validos, v_top_pct
      FROM resultado_electoral WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO';
    SELECT COUNT(*), MIN(id_lista) INTO v_empate, v_ganadora
      FROM resultado_electoral
     WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO' AND pct_ponderado = v_top_pct;

    IF v_hab = 0 OR (v_vot * 100 / v_hab) <= v_quorum THEN
      SET v_result = 'SIN_QUORUM';
    ELSEIF v_validos = 0 THEN
      SET v_result = 'DESIERTO';
    ELSEIF v_tipo = 'SEGUNDA_VUELTA' THEN
      SET v_result = IF(v_empate = 1 AND v_top_pct > 50.00, 'ELEGIDO', 'EMPATE');
    ELSEIF v_empate = 1 AND v_top_pct > v_pct_min THEN
      SET v_result = 'ELEGIDO';
    ELSE
      SET v_result = 'SEGUNDA_VUELTA';
    END IF;

    UPDATE cargo_electoral
       SET estado_resultado  = v_result,
           id_lista_ganadora = IF(v_result = 'ELEGIDO', v_ganadora, NULL)
     WHERE id_cargo = v_cargo;
    SET v_fin = 0;
  END LOOP;
  CLOSE cur_cargos;

  SELECT COUNT(*) INTO v_con_q FROM cargo_electoral
   WHERE id_proceso = p_id_proceso AND estado_resultado <> 'SIN_QUORUM';
  SELECT electores_habiles, votaron, participacion_pct INTO v_p_hab, v_p_vot, v_p_pct
    FROM v_quorum_proceso WHERE id_proceso = p_id_proceso;

  
  IF v_con_q = 0 THEN
    SET v_resultado = 'NULIDAD_TOTAL';
    UPDATE proceso_electoral
       SET estado = 'ANULADO',
           motivo_anulacion = CONCAT('RN31: la participación (', v_p_pct, ' %) no superó el quórum mínimo de ',
                                     v_quorum, ' %. Nulidad total de la elección (RN34).')
     WHERE id_proceso = p_id_proceso;
  ELSE
    SET v_resultado = 'VALIDA';
    UPDATE proceso_electoral SET estado = 'FINALIZADO' WHERE id_proceso = p_id_proceso;
  END IF;

  
  SELECT CONCAT('[', GROUP_CONCAT(z.j ORDER BY z.id_cargo SEPARATOR ','), ']') INTO v_cargos
    FROM (SELECT c.id_cargo,
                 CONCAT('{"id_cargo":', c.id_cargo,
                        ',"cargo":', JSON_QUOTE(c.nombre),
                        ',"electores":', pc.electores_habiles,
                        ',"votaron":', pc.votaron,
                        ',"participacion":', pc.participacion_pct,
                        ',"alcanza_quorum":', IF(pc.alcanza_quorum = 1, 'true', 'false'),
                        ',"porcentaje_minimo":', c.porcentaje_minimo_victoria,
                        ',"validos":', (SELECT COALESCE(SUM(r.total_votos), 0) FROM resultado_electoral r
                                         WHERE r.id_cargo = c.id_cargo AND r.tipo_voto = 'VALIDO'),
                        ',"validos_estudiantes":', (SELECT COALESCE(SUM(r.votos_estudiantes), 0) FROM resultado_electoral r
                                         WHERE r.id_cargo = c.id_cargo AND r.tipo_voto = 'VALIDO'),
                        ',"ponderado":', IF((SELECT COALESCE(SUM(r.votos_estudiantes), 0) FROM resultado_electoral r
                                         WHERE r.id_cargo = c.id_cargo AND r.tipo_voto = 'VALIDO') > 0, 'true', 'false'),
                        ',"blancos":', (SELECT COALESCE(SUM(r.total_votos), 0) FROM resultado_electoral r
                                         WHERE r.id_cargo = c.id_cargo AND r.tipo_voto = 'BLANCO'),
                        ',"nulos":', (SELECT COALESCE(SUM(r.total_votos), 0) FROM resultado_electoral r
                                       WHERE r.id_cargo = c.id_cargo AND r.tipo_voto = 'NULO'),
                        ',"emitidos":', (SELECT COALESCE(SUM(r.total_votos), 0) FROM resultado_electoral r
                                          WHERE r.id_cargo = c.id_cargo),
                        ',"estado_resultado":', JSON_QUOTE(c.estado_resultado),
                        ',"id_lista_ganadora":', COALESCE(c.id_lista_ganadora, 'null'),
                        ',"lista_ganadora":', IF(g.nombre IS NULL, 'null', JSON_QUOTE(g.nombre)),
                        ',"opciones":[',
                        COALESCE((SELECT GROUP_CONCAT(CONCAT('{"id_lista":', r.id_lista,
                                                       ',"lista":', JSON_QUOTE(l.nombre),
                                                       ',"orden":', COALESCE(l.orden_cedula, 'null'),
                                                       ',"votos":', r.total_votos,
                                                       ',"votos_docentes":', COALESCE(r.votos_docentes, r.total_votos),
                                                       ',"votos_estudiantes":', COALESCE(r.votos_estudiantes, 0),
                                                       ',"porcentaje":', COALESCE(r.porcentaje_validos, 0),
                                                       ',"pct_docente":', COALESCE(r.pct_docente, r.porcentaje_validos, 0),
                                                       ',"pct_estudiante":', COALESCE(r.pct_estudiante, 0),
                                                       ',"pct_ponderado":', COALESCE(r.pct_ponderado, r.porcentaje_validos, 0),
                                                       ',"posicion":', COALESCE(r.posicion, 'null'), '}')
                                                ORDER BY r.posicion, l.orden_cedula SEPARATOR ',')
                                    FROM resultado_electoral r JOIN lista_electoral l ON l.id_lista = r.id_lista
                                   WHERE r.id_cargo = c.id_cargo AND r.tipo_voto = 'VALIDO'), ''),
                        ']}') AS j
            FROM cargo_electoral c
            JOIN v_participacion_cargo pc ON pc.id_cargo = c.id_cargo
            LEFT JOIN lista_electoral g   ON g.id_lista = c.id_lista_ganadora
           WHERE c.id_proceso = p_id_proceso) z;

  SELECT CONCAT('[', GROUP_CONCAT(JSON_OBJECT('mesa', m.numero_mesa, 'ubicacion', m.ubicacion,
                                              'situacion', m.situacion, 'electores', m.total_electores,
                                              'votaron', m.total_votantes, 'calificacion', m.calificacion,
                                              'resolucion', m.resolucion_calificacion, 'codigo_entrega', m.codigo_cargo)
                                  ORDER BY m.numero_mesa SEPARATOR ','), ']') INTO v_det_mesas
    FROM v_computo_mesas m WHERE m.id_proceso = p_id_proceso;

  SELECT CONCAT('[', GROUP_CONCAT(JSON_OBJECT('personero', CONCAT(d.apellidos, ', ', d.nombres), 'dni', d.dni,
                                              'lista', l.nombre, 'tipo', CONCAT(pe.tipo, ''))
                                  ORDER BY l.nombre, d.apellidos SEPARATOR ','), ']')
    INTO v_pers
    FROM computo_personero cp
    JOIN personero pe      ON pe.id_personero = cp.id_personero
    JOIN docente d         ON d.id_docente = pe.id_docente
    JOIN lista_electoral l ON l.id_lista = pe.id_lista
   WHERE cp.id_proceso = p_id_proceso;

  SET v_ahora = NOW();
  SET v_contenido = CONCAT(
      '{"tipo":"COMPUTO_GENERAL"',
      ',"id_proceso":', p_id_proceso,
      ',"proceso":', JSON_QUOTE(v_nombre),
      ',"vuelta":', JSON_QUOTE(v_tipo),
      ',"fecha_computo":', JSON_QUOTE(DATE_FORMAT(v_ahora, '%Y-%m-%d %H:%i:%s')),
      ',"sesion":{"lugar":', JSON_QUOTE(v_lugar), ',"miembros_ceunp":', v_miembros,
      ',"inicio":', JSON_QUOTE(DATE_FORMAT(v_sesion, '%Y-%m-%d %H:%i:%s')),
      ',"personeros":', COALESCE(v_pers, '[]'), '}',
      ',"mesas":{"total":', v_mesas, ',"computadas":', v_computadas, ',"no_instaladas":', v_no_inst,
      ',"anuladas":', v_anuladas, '}',
      ',"actas_verificadas":', v_actas,
      ',"actas_dudosas":', v_dudosas,
      ',"participacion":{"electores":', COALESCE(v_p_hab, 0), ',"votaron":', COALESCE(v_p_vot, 0),
      ',"porcentaje":', COALESCE(v_p_pct, 0), ',"quorum_minimo":', v_quorum, '}',
      ',"resultado":', JSON_QUOTE(v_resultado),
      ',"cargos":', COALESCE(v_cargos, '[]'),
      ',"detalle_mesas":', COALESCE(v_det_mesas, '[]'),
      IF(v_resultado = 'NULIDAD_TOTAL',
         ',"comunicar_a":["SUNEDU","Asamblea Universitaria","Consejo Universitario"]', ''),
      '}');

  SET v_token = LOWER(HEX(fn_bytes_aleatorios(32)));

  UPDATE computo_proceso
     SET estado = 'COMPUTADO', fecha_computo = v_ahora, mesas_total = v_mesas, mesas_computadas = v_computadas,
         mesas_no_instaladas = v_no_inst, mesas_anuladas = v_anuladas, actas_verificadas = v_actas,
         electores_habiles = COALESCE(v_p_hab, 0), votaron = COALESCE(v_p_vot, 0), participacion_pct = COALESCE(v_p_pct, 0),
         resultado = v_resultado, contenido_json = v_contenido, hash_integridad = SHA2(v_contenido, 256),
         token_qr_hash = SHA2(v_token, 256), id_usuario_computo = p_id_usuario
   WHERE id_proceso = p_id_proceso;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'COMPUTAR_RESULTADOS',
       JSON_OBJECT('cus', 'CUS14', 'mesas_computadas', v_computadas, 'cargos_con_quorum', v_con_q, 'resultado', v_resultado));
  COMMIT;

  
  SELECT p_id_proceso AS id_proceso, v_resultado AS resultado, v_token AS token_qr, v_computadas AS mesas_computadas,
         IF(v_resultado = 'VALIDA', 'FINALIZADO', 'ANULADO') AS estado_proceso;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_eliminar_usuario` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_eliminar_usuario`(IN p_id_admin INT, IN p_id_usuario INT)
BEGIN
  DECLARE v_username VARCHAR(80);
  DECLARE v_rol      VARCHAR(20);
  DECLARE EXIT HANDLER FOR 1451
  BEGIN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: la cuenta tiene actividad registrada (RN28): desactívela en lugar de eliminarla.';
  END;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  CALL sp_validar_admin(p_id_admin);
  IF p_id_usuario = p_id_admin THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: no puede eliminar su propia cuenta.';
  END IF;

  START TRANSACTION;
  SELECT username, CONCAT(rol, '') INTO v_username, v_rol FROM usuario WHERE id_usuario = p_id_usuario FOR UPDATE;
  IF v_username IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: la cuenta no existe.';
  END IF;
  IF EXISTS (SELECT 1 FROM log_auditoria WHERE id_usuario = p_id_usuario) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: la cuenta tiene actividad registrada (RN28): desactívela en lugar de eliminarla.';
  END IF;
  DELETE FROM usuario WHERE id_usuario = p_id_usuario;
  CALL sp_registrar_auditoria(p_id_admin, NULL, NULL, 'ELIMINAR_USUARIO',
       JSON_OBJECT('id_usuario', p_id_usuario, 'username', v_username, 'rol', v_rol));
  COMMIT;

  SELECT p_id_usuario AS id_usuario, v_username AS username, 'ELIMINADA' AS estado;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_emitir_acta` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_emitir_acta`(
  IN  p_id_mesa   INT,
  IN  p_tipo      VARCHAR(12),
  IN  p_contenido LONGTEXT,
  OUT p_token     CHAR(64)
)
BEGIN
  SET p_token = LOWER(HEX(fn_bytes_aleatorios(32)));
  INSERT INTO acta_electoral (id_mesa, tipo, contenido_json, hash_integridad, token_qr_hash)
  VALUES (p_id_mesa, p_tipo, p_contenido, SHA2(p_contenido, 256), SHA2(p_token, 256));
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_emitir_resolucion_multas` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_emitir_resolucion_multas`(
  IN p_id_proceso        INT,
  IN p_id_usuario        INT,
  IN p_numero_resolucion VARCHAR(40),
  IN p_miembros_pleno    INT,
  IN p_fundamento        VARCHAR(1000)
)
BEGIN
  DECLARE v_nombre    VARCHAR(200) DEFAULT NULL;
  DECLARE v_tipo      VARCHAR(20);
  DECLARE v_estado    VARCHAR(20);
  DECLARE v_reporte   INT DEFAULT NULL;
  DECLARE v_rep_est   VARCHAR(10);
  DECLARE v_uit       DECIMAL(10,2);
  DECLARE v_pe        DECIMAL(5,2);
  DECLARE v_pm        DECIMAL(5,2);
  DECLARE v_res       VARCHAR(40);
  DECLARE v_fund      VARCHAR(1000);
  DECLARE v_quorum    INT;
  DECLARE v_vigentes  INT DEFAULT 0;
  DECLARE v_coinciden INT DEFAULT 0;
  DECLARE v_n1        INT DEFAULT 0;
  DECLARE v_n2        INT DEFAULT 0;
  DECLARE v_total     DECIMAL(12,2) DEFAULT 0;
  DECLARE v_lista     LONGTEXT;
  DECLARE v_part      LONGTEXT;
  DECLARE v_ahora     DATETIME;
  DECLARE v_contenido LONGTEXT;
  DECLARE v_token     CHAR(64);
  DECLARE v_msg       VARCHAR(255);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET SESSION group_concat_max_len = 16000000;
  START TRANSACTION;
  SELECT nombre, tipo, estado INTO v_nombre, v_tipo, v_estado FROM proceso_electoral WHERE id_proceso = p_id_proceso;
  IF v_nombre IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;
  SELECT id_reporte, estado, uit_referencia, pct_elector, pct_miembro
    INTO v_reporte, v_rep_est, v_uit, v_pe, v_pm
    FROM reporte_multas WHERE id_proceso = p_id_proceso FOR UPDATE;
  IF v_reporte IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF103: genere primero el reporte de omisos y multas.';
  END IF;
  IF v_rep_est = 'RESUELTO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: las multas del proceso ya fueron determinadas por resolución del CEUNP.';
  END IF;

  
  SELECT COUNT(*) INTO v_vigentes FROM v_omisos_proceso WHERE id_proceso = p_id_proceso;
  SELECT COUNT(*) INTO v_coinciden
    FROM multa mu JOIN v_omisos_proceso o ON o.id_proceso = mu.id_proceso AND o.id_docente = mu.id_docente AND o.motivo = mu.motivo
   WHERE mu.id_proceso = p_id_proceso;
  SELECT COUNT(*) INTO v_n1 FROM multa WHERE id_proceso = p_id_proceso;
  IF v_vigentes <> v_coinciden OR v_n1 <> v_coinciden THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF103: el reporte no está al día con el padrón y las mesas; vuelva a generar las multas.';
  END IF;
  IF EXISTS (SELECT 1 FROM multa WHERE id_proceso = p_id_proceso AND uit_referencia <> v_uit) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF105: las multas no se calcularon con la misma UIT; vuelva a generarlas.';
  END IF;

  SET v_res = NULLIF(TRIM(p_numero_resolucion), '');
  IF v_res IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: las multas se determinan por resolución del CEUNP; indique su número.';
  END IF;
  IF fn_resolucion_en_uso(v_res) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;
  SET v_quorum = COALESCE(ROUND((SELECT CAST(valor AS DECIMAL(6,2)) FROM parametro_global WHERE clave = 'CEUNP_QUORUM_PLENO')), 5);
  IF p_miembros_pleno IS NULL OR p_miembros_pleno < v_quorum OR p_miembros_pleno > 9 THEN
    SET v_msg = CONCAT('RN36: el Pleno del CEUNP resuelve con quórum de ', v_quorum, ' de sus 9 miembros.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  SET v_fund = NULLIF(TRIM(p_fundamento), '');
  IF v_fund IS NOT NULL AND CHAR_LENGTH(v_fund) < 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el fundamento debe tener al menos 10 caracteres.';
  END IF;
  SET v_fund = COALESCE(v_fund, CONCAT('Concluida la votación del proceso «', v_nombre, '», se identificó a los docentes ',
                        'hábiles que no votaron y a los miembros titulares de mesa que no asistieron, conforme a los ',
                        'artículos 67 y 68 del Reglamento de Elecciones.'));

  SELECT COALESCE(SUM(motivo = 'OMISO_VOTACION'), 0), COALESCE(SUM(motivo = 'OMISO_MESA'), 0), COALESCE(SUM(monto), 0)
    INTO v_n1, v_n2, v_total
    FROM multa WHERE id_proceso = p_id_proceso;
  SELECT CONCAT('[', COALESCE(GROUP_CONCAT(JSON_OBJECT('id_multa', mu.id_multa, 'dni', d.dni,
                                                       'docente', CONCAT(d.apellidos, ', ', d.nombres),
                                                       'facultad', f.nombre, 'motivo', mu.motivo,
                                                       'mesa', m.numero_mesa, 'rol', mu.rol_mesa,
                                                       'asistio_sin_votar', IF(mu.asistio_sin_votar, 'true', 'false'),
                                                       'porcentaje', mu.porcentaje_uit, 'monto', mu.monto)
                                           ORDER BY FIELD(mu.motivo, 'OMISO_MESA', 'OMISO_VOTACION'), d.apellidos, d.nombres
                                           SEPARATOR ','), ''), ']')
    INTO v_lista
    FROM multa mu
    JOIN docente d  ON d.id_docente = mu.id_docente
    JOIN facultad f ON f.id_facultad = d.id_facultad
    LEFT JOIN mesa_electoral m ON m.id_mesa = mu.id_mesa
   WHERE mu.id_proceso = p_id_proceso;
  SELECT JSON_OBJECT('electores', electores_habiles, 'votaron', votaron, 'porcentaje', participacion_pct)
    INTO v_part FROM v_quorum_proceso WHERE id_proceso = p_id_proceso;

  SET v_ahora = NOW();
  SET v_contenido = CONCAT(
      '{"tipo":"RESOLUCION_MULTAS"',
      ',"id_proceso":', p_id_proceso,
      ',"proceso":', JSON_QUOTE(v_nombre),
      ',"vuelta":', JSON_QUOTE(v_tipo),
      ',"estado_proceso":', JSON_QUOTE(v_estado),
      ',"resolucion":', JSON_QUOTE(v_res),
      ',"fecha":', JSON_QUOTE(DATE_FORMAT(v_ahora, '%Y-%m-%d %H:%i:%s')),
      ',"pleno":{"miembros":', p_miembros_pleno, ',"quorum":', v_quorum, '}',
      ',"fundamento":', JSON_QUOTE(v_fund),
      ',"uit":', v_uit,
      ',"porcentaje_elector":', v_pe,
      ',"porcentaje_miembro":', v_pm,
      ',"monto_elector":', ROUND(v_uit * v_pe / 100, 2),
      ',"monto_miembro":', ROUND(v_uit * v_pm / 100, 2),
      ',"participacion":', COALESCE(v_part, 'null'),
      ',"omisos_votacion":', v_n1,
      ',"omisos_mesa":', v_n2,
      ',"monto_total":', v_total,
      ',"multas":', v_lista,
      ',"nota":', JSON_QUOTE('El sistema determina las multas; no las cobra. El docente puede justificar su inasistencia ante el CEUNP (Disp. Final 2.ª y 5.ª).'),
      '}');
  SET v_token = LOWER(HEX(fn_bytes_aleatorios(32)));

  UPDATE reporte_multas
     SET estado = 'RESUELTO', numero_resolucion = v_res, fundamento = v_fund, miembros_pleno = p_miembros_pleno,
         fecha_resolucion = v_ahora, id_usuario_resolucion = p_id_usuario, omisos_votacion = v_n1, omisos_mesa = v_n2,
         monto_total = v_total, contenido_json = v_contenido, hash_integridad = SHA2(v_contenido, 256),
         token_qr_hash = SHA2(v_token, 256)
   WHERE id_reporte = v_reporte;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'EMITIR_RESOLUCION_MULTAS',
       JSON_OBJECT('resolucion', v_res, 'omisos_votacion', v_n1, 'omisos_mesa', v_n2, 'monto_total', v_total));
  COMMIT;

  SELECT v_reporte AS id_reporte, v_res AS numero_resolucion, v_token AS token_qr, v_n1 AS omisos_votacion,
         v_n2 AS omisos_mesa, v_total AS monto_total;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_emitir_voto` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_emitir_voto`(
  IN  p_id_proceso INT,
  IN  p_id_cargo   INT,
  IN  p_id_docente INT,
  IN  p_id_lista   INT,
  IN  p_tipo_voto  VARCHAR(10),
  OUT p_token_constancia CHAR(64)
)
BEGIN
  DECLARE v_estado   VARCHAR(20) DEFAULT NULL;
  DECLARE v_inicio   DATETIME;
  DECLARE v_fin      DATETIME;
  DECLARE v_tipo     VARCHAR(10);
  DECLARE v_hab      INT DEFAULT NULL;
  DECLARE v_ya       INT DEFAULT NULL;
  DECLARE v_mesa     INT DEFAULT NULL;
  DECLARE v_mesa_est VARCHAR(20) DEFAULT NULL;
  DECLARE v_n        INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SET v_tipo = UPPER(TRIM(p_tipo_voto));

  
  SELECT estado, fecha_inicio, fecha_fin INTO v_estado, v_inicio, v_fin
    FROM proceso_electoral WHERE id_proceso = p_id_proceso;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;
  IF v_estado <> 'VOTACION' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN06: el proceso no esta en VOTACION.';
  END IF;
  IF NOW() < v_inicio OR NOW() > v_fin THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN06: fuera del horario de sufragio.';
  END IF;

  
  IF v_tipo IS NULL OR v_tipo NOT IN ('VALIDO','BLANCO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN25: el voto debe ser VALIDO (por una lista) o BLANCO.';
  END IF;
  IF v_tipo = 'BLANCO' AND p_id_lista IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un voto en BLANCO no lleva lista.';
  END IF;
  IF v_tipo = 'VALIDO' THEN
    SELECT COUNT(*) INTO v_n FROM lista_electoral
     WHERE id_lista = p_id_lista AND id_cargo = p_id_cargo AND estado = 'ADMITIDA';
    IF v_n = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La lista elegida no esta ADMITIDA para este cargo.';
    END IF;
  END IF;

  
  SELECT habilitado_para_votar, ya_voto, id_mesa INTO v_hab, v_ya, v_mesa
    FROM padron_electoral
   WHERE id_proceso = p_id_proceso AND id_cargo = p_id_cargo AND id_docente = p_id_docente
     FOR UPDATE;

  IF v_hab IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN04: el docente no figura en el padron de este cargo.';
  END IF;
  IF v_hab = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN04: el docente no esta habilitado para votar.';
  END IF;
  IF v_ya = 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN01: el docente ya voto por este cargo.';
  END IF;

  
  IF v_mesa IS NOT NULL THEN
    SELECT estado INTO v_mesa_est FROM mesa_electoral WHERE id_mesa = v_mesa;
    IF v_mesa_est <> 'INSTALADA' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN07: la mesa del elector no esta INSTALADA.';
    END IF;
  END IF;

  
  UPDATE padron_electoral
     SET ya_voto = 1, fecha_votacion = DATE_FORMAT(NOW(), '%Y-%m-%d %H:00:00')
   WHERE id_proceso = p_id_proceso AND id_cargo = p_id_cargo AND id_docente = p_id_docente;

  
  INSERT INTO voto (id_proceso, id_cargo, id_lista_elegida, tipo_voto, id_mesa)
  VALUES (p_id_proceso, p_id_cargo, IF(v_tipo = 'VALIDO', p_id_lista, NULL), v_tipo, v_mesa);

  
  SET p_token_constancia = LOWER(HEX(fn_bytes_aleatorios(32)));
  INSERT INTO constancia_voto (id_proceso, id_docente, id_cargo, token_qr_hash)
  VALUES (p_id_proceso, p_id_docente, p_id_cargo, SHA2(p_token_constancia, 256));

  
  CALL sp_registrar_auditoria(NULL, p_id_docente, p_id_proceso, 'EMITIR_VOTO',
       JSON_OBJECT('id_cargo', p_id_cargo));
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_evaluar_nulidad_mesa` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_evaluar_nulidad_mesa`(
  IN p_id_mesa    INT,
  IN p_id_usuario INT,
  IN p_decision   VARCHAR(12),
  IN p_fundamento VARCHAR(500)
)
BEGIN
  DECLARE v_proceso  INT DEFAULT NULL;
  DECLARE v_mesa_est VARCHAR(20) DEFAULT NULL;
  DECLARE v_eval     VARCHAR(12) DEFAULT NULL;
  DECLARE v_n        INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_decision IS NULL OR p_decision NOT IN ('PROCEDE', 'NO_PROCEDE') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF60: la evaluación debe ser PROCEDE o NO_PROCEDE.';
  END IF;
  IF p_fundamento IS NULL OR CHAR_LENGTH(TRIM(p_fundamento)) < 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF60: fundamente la evaluación (al menos 10 caracteres).';
  END IF;

  START TRANSACTION;
  SELECT m.id_proceso, m.estado INTO v_proceso, v_mesa_est
    FROM mesa_electoral m WHERE m.id_mesa = p_id_mesa FOR UPDATE;
  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no existe.';
  END IF;
  IF v_mesa_est <> 'NO_INSTALADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF60: solo se evalúa la nulidad de una mesa NO INSTALADA.';
  END IF;
  SELECT COUNT(*), MAX(evaluacion_nulidad) INTO v_n, v_eval FROM instalacion_mesa WHERE id_mesa = p_id_mesa;
  IF v_n = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no tiene registro de instalación.';
  END IF;
  IF v_eval IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF60: la nulidad de esta mesa ya fue evaluada.';
  END IF;

  UPDATE instalacion_mesa
     SET evaluacion_nulidad = p_decision, fundamento_evaluacion = TRIM(p_fundamento),
         fecha_evaluacion = NOW(), id_usuario_evaluacion = p_id_usuario
   WHERE id_mesa = p_id_mesa;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'EVALUAR_NULIDAD_MESA',
       JSON_OBJECT('id_mesa', p_id_mesa, 'decision', p_decision));
  COMMIT;

  SELECT p_id_mesa AS id_mesa, p_decision AS evaluacion_nulidad;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_generar_acta_escrutinio` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_generar_acta_escrutinio`(
  IN p_id_mesa          INT,
  IN p_id_usuario       INT,
  IN p_prevalece_fisica BOOLEAN,
  IN p_observaciones    VARCHAR(1000),
  IN p_personeros       LONGTEXT
)
BEGIN
  DECLARE v_proceso    INT DEFAULT NULL;
  DECLARE v_nombre     VARCHAR(200);
  DECLARE v_numero     VARCHAR(30);
  DECLARE v_ubic       VARCHAR(200);
  DECLARE v_esc        VARCHAR(20) DEFAULT NULL;
  DECLARE v_inicio     DATETIME;
  DECLARE v_votantes   INT;
  DECLARE v_contadas   INT;
  DECLARE v_sobran     INT;
  DECLARE v_faltan     INT;
  DECLARE v_escrutadas INT;
  DECLARE v_obs_ced    VARCHAR(1000);
  DECLARE v_veces      INT;
  DECLARE v_cuadra     INT;
  DECLARE v_total_ok   INT;
  DECLARE v_prevalece  INT DEFAULT 0;
  DECLARE v_obs        VARCHAR(1000);
  DECLARE v_observada  INT DEFAULT 0;
  DECLARE v_personeros LONGTEXT;
  DECLARE v_n          INT DEFAULT 0;
  DECLARE v_validos    INT DEFAULT 0;
  DECLARE v_impug      INT DEFAULT 0;
  DECLARE v_resultados LONGTEXT;
  DECLARE v_miembros   LONGTEXT;
  DECLARE v_impugnaciones LONGTEXT;
  DECLARE v_contenido  LONGTEXT;
  DECLARE v_token      CHAR(64);
  DECLARE v_id_acta    INT;
  DECLARE v_hash       CHAR(64);
  DECLARE v_ahora      DATETIME;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET SESSION group_concat_max_len = 1000000;
  START TRANSACTION;

  SELECT m.id_proceso, p.nombre, m.numero_mesa, m.ubicacion,
         e.estado, e.hora_inicio, e.total_votantes, e.cedulas_contadas, e.cedulas_sobrantes,
         e.cedulas_faltantes, e.cedulas_escrutadas, e.observacion_cedulas, e.veces_conteo,
         e.conteo_cuadra, e.total_cuadra
    INTO v_proceso, v_nombre, v_numero, v_ubic,
         v_esc, v_inicio, v_votantes, v_contadas, v_sobran,
         v_faltan, v_escrutadas, v_obs_ced, v_veces,
         v_cuadra, v_total_ok
    FROM mesa_electoral m
    JOIN proceso_electoral p    ON p.id_proceso = m.id_proceso
    LEFT JOIN escrutinio_mesa e ON e.id_mesa = m.id_mesa
   WHERE m.id_mesa = p_id_mesa
     FOR UPDATE;

  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no existe.';
  END IF;
  IF v_esc IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF77: cuente primero las cédulas del ánfora.';
  END IF;
  IF v_esc IN ('ACTA_EMITIDA','ENTREGADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN28: el acta de escrutinio de esta mesa ya fue emitida.';
  END IF;
  IF v_esc <> 'CONTEO_REGISTRADO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF79: registre el conteo manual por lista, en blanco, nulos e impugnados.';
  END IF;

  SET v_obs = NULLIF(TRIM(p_observaciones), '');
  SET v_prevalece = COALESCE(p_prevalece_fisica, 0);
  
  IF v_cuadra = 0 THEN
    IF v_veces < 2 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A3: el conteo manual difiere del digital. Recuente las cédulas y registre otra vez el conteo.';
    END IF;
    IF v_prevalece = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A3 (RF84): la diferencia persiste tras el recuento; confirme que prevalece la cédula física.';
    END IF;
    IF v_obs IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A3 (RF83): detalle en la observación la diferencia entre el conteo manual y el digital.';
    END IF;
  ELSE
    SET v_prevalece = 0;
  END IF;
  
  IF v_total_ok = 0 AND v_obs IS NULL AND v_obs_ced IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF82: el total de votos no es igual al de electores que votaron. Registre la observación.';
  END IF;
  
  SET v_observada = IF(v_obs IS NOT NULL OR v_obs_ced IS NOT NULL, 1, 0);

  
  SET v_personeros = IF(p_personeros IS NULL OR TRIM(p_personeros) = '', '[]', p_personeros);
  IF JSON_VALID(v_personeros) = 0 OR JSON_TYPE(v_personeros) <> 'ARRAY' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lista de personeros firmantes no válida.';
  END IF;
  SET v_n = JSON_LENGTH(v_personeros);
  SELECT COUNT(*) INTO v_validos
    FROM asistencia_personero_mesa ap
   WHERE ap.id_mesa = p_id_mesa AND JSON_CONTAINS(v_personeros, CAST(ap.id_personero AS CHAR));
  IF v_validos <> v_n THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo firman el acta los personeros presentes en la mesa.';
  END IF;

  
  SELECT COUNT(*) INTO v_n FROM (
    SELECT rol_instalacion AS cargo FROM miembro_mesa
     WHERE id_mesa = p_id_mesa AND rol_instalacion IN ('PRESIDENTE', 'SECRETARIO')
    UNION
    SELECT cargo FROM reemplazo_mesa WHERE id_mesa = p_id_mesa AND cargo IN ('PRESIDENTE', 'SECRETARIO')) f;
  IF v_n < 2 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no registra presidente y secretario en funciones (CUS08).';
  END IF;

  
  SELECT CONCAT('[', GROUP_CONCAT(x.cargo_json ORDER BY x.id_cargo SEPARATOR ','), ']')
    INTO v_resultados
    FROM (SELECT c.id_cargo,
                 CONCAT('{"id_cargo":', c.id_cargo,
                        ',"cargo":', JSON_QUOTE(c.nombre),
                        ',"votantes":', (SELECT COUNT(*) FROM padron_electoral pe
                                          WHERE pe.id_mesa = p_id_mesa AND pe.id_cargo = c.id_cargo AND pe.ya_voto = 1),
                        ',"total":', SUM(k.votos_manual),
                        ',"total_digital":', SUM(k.votos_digital),
                        ',"validos":', SUM(IF(k.opcion = 'LISTA', k.votos_manual, 0)),
                        ',"blancos":', SUM(IF(k.opcion = 'BLANCO', k.votos_manual, 0)),
                        ',"nulos":', SUM(IF(k.opcion = 'NULO', k.votos_manual, 0)),
                        ',"impugnados":', SUM(IF(k.opcion = 'IMPUGNADO', k.votos_manual, 0)),
                        ',"opciones":[',
                        GROUP_CONCAT(CONCAT('{"opcion":', JSON_QUOTE(k.opcion),
                                            ',"id_lista":', IF(k.id_lista IS NULL, 'null', k.id_lista),
                                            ',"nombre":', JSON_QUOTE(COALESCE(l.nombre, CASE k.opcion
                                                 WHEN 'BLANCO' THEN 'Votos en blanco'
                                                 WHEN 'NULO' THEN 'Votos nulos'
                                                 ELSE 'Votos impugnados' END)),
                                            ',"orden":', IF(l.orden_cedula IS NULL, 'null', l.orden_cedula),
                                            ',"manual":', k.votos_manual,
                                            ',"digital":', k.votos_digital,
                                            ',"diferencia":', IF(k.opcion = 'IMPUGNADO', 0, k.votos_manual - k.votos_digital), '}')
                                     ORDER BY FIELD(k.opcion, 'LISTA', 'BLANCO', 'NULO', 'IMPUGNADO'),
                                              COALESCE(l.orden_cedula, 999), l.nombre SEPARATOR ','),
                        ']}') AS cargo_json
            FROM escrutinio_conteo k
            JOIN cargo_electoral c ON c.id_cargo = k.id_cargo
            LEFT JOIN lista_electoral l ON l.id_lista = k.id_lista
           WHERE k.id_mesa = p_id_mesa
           GROUP BY c.id_cargo, c.nombre) x;

  SELECT CONCAT('[', GROUP_CONCAT(
           JSON_OBJECT('dni', f.dni, 'docente', f.docente, 'cargo', f.cargo, 'origen', f.origen)
           ORDER BY FIELD(f.cargo, 'PRESIDENTE', 'SECRETARIO', 'VOCAL') SEPARATOR ','), ']')
    INTO v_miembros
    FROM (SELECT d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS docente, CONCAT(mm.rol_instalacion, '') AS cargo,
                 IF(mm.titular = 1, 'TITULAR', 'SUPLENTE') AS origen
            FROM miembro_mesa mm JOIN docente d ON d.id_docente = mm.id_docente
           WHERE mm.id_mesa = p_id_mesa AND mm.rol_instalacion IS NOT NULL
          UNION ALL
          SELECT d.dni, CONCAT(d.apellidos, ', ', d.nombres), CONCAT(r.cargo, ''), 'REEMPLAZANTE'
            FROM reemplazo_mesa r JOIN docente d ON d.id_docente = r.id_docente
           WHERE r.id_mesa = p_id_mesa) f;

  SELECT COUNT(*), CONCAT('[', GROUP_CONCAT(
           JSON_OBJECT('id', i.id_impugnacion, 'cargo', c.nombre, 'personero', CONCAT(d.apellidos, ', ', d.nombres),
                       'lista', l.nombre, 'motivo', i.motivo, 'estado', CONCAT(i.estado, ''))
           ORDER BY i.id_impugnacion SEPARATOR ','), ']')
    INTO v_impug, v_impugnaciones
    FROM impugnacion_electoral i
    JOIN personero pe      ON pe.id_personero = i.id_personero
    JOIN docente d         ON d.id_docente = pe.id_docente
    JOIN lista_electoral l ON l.id_lista = pe.id_lista
    LEFT JOIN cargo_electoral c ON c.id_cargo = i.id_cargo
   WHERE i.id_mesa = p_id_mesa;

  SET v_ahora = NOW();
  SET v_contenido = CONCAT(
      '{"tipo":"ESCRUTINIO"',
      ',"id_proceso":', v_proceso,
      ',"proceso":', JSON_QUOTE(v_nombre),
      ',"mesa":', JSON_QUOTE(v_numero),
      ',"ubicacion":', JSON_QUOTE(v_ubic),
      ',"hora_inicio":', JSON_QUOTE(DATE_FORMAT(v_inicio, '%Y-%m-%d %H:%i:%s')),
      ',"hora_fin":', JSON_QUOTE(DATE_FORMAT(v_ahora, '%Y-%m-%d %H:%i:%s')),
      ',"electores_que_votaron":', v_votantes,
      ',"cedulas_contadas":', v_contadas,
      ',"cedulas_sobrantes_destruidas":', v_sobran,
      ',"cedulas_faltantes":', v_faltan,
      ',"cedulas_escrutadas":', v_escrutadas,
      ',"observacion_cedulas":', IF(v_obs_ced IS NULL, 'null', JSON_QUOTE(v_obs_ced)),
      ',"recuentos":', GREATEST(v_veces - 1, 0),
      ',"conteo_coincide_digital":', IF(v_cuadra = 1, 'true', 'false'),
      ',"total_coincide_votantes":', IF(v_total_ok = 1, 'true', 'false'),
      ',"prevalece_cedula_fisica":', IF(v_prevalece = 1, 'true', 'false'),
      ',"resultados":', COALESCE(v_resultados, '[]'),
      ',"impugnaciones":', COALESCE(v_impugnaciones, '[]'),
      ',"miembros":', COALESCE(v_miembros, '[]'),
      ',"observada":', IF(v_observada = 1, 'true', 'false'),
      ',"observaciones":', IF(v_obs IS NULL, 'null', JSON_QUOTE(v_obs)),
      '}');

  
  CALL sp_emitir_acta(p_id_mesa, 'ESCRUTINIO', v_contenido, v_token);
  SELECT id_acta, hash_integridad INTO v_id_acta, v_hash
    FROM acta_electoral WHERE id_mesa = p_id_mesa AND tipo = 'ESCRUTINIO';

  
  INSERT INTO firma_acta (id_acta, id_docente, rol, firma_digital, fecha_firma)
  SELECT v_id_acta, mm.id_docente,
         CONCAT(mm.rol_instalacion, ' DE MESA', IF(mm.titular = 1, '', ' (SUPLENTE)')),
         SHA2(CONCAT(v_hash, '|', d.dni, '|', mm.rol_instalacion), 256), v_ahora
    FROM miembro_mesa mm JOIN docente d ON d.id_docente = mm.id_docente
   WHERE mm.id_mesa = p_id_mesa AND mm.rol_instalacion IN ('PRESIDENTE', 'SECRETARIO', 'VOCAL');

  INSERT INTO firma_acta (id_acta, id_docente, rol, firma_digital, fecha_firma)
  SELECT v_id_acta, r.id_docente, CONCAT(r.cargo, ' DE MESA (REEMPLAZANTE)'),
         SHA2(CONCAT(v_hash, '|', d.dni, '|', r.cargo), 256), v_ahora
    FROM reemplazo_mesa r JOIN docente d ON d.id_docente = r.id_docente
   WHERE r.id_mesa = p_id_mesa;

  INSERT IGNORE INTO firma_acta (id_acta, id_docente, rol, firma_digital, fecha_firma)
  SELECT v_id_acta, pe.id_docente, LEFT(CONCAT('PERSONERO ', pe.tipo, ' - ', l.nombre), 80),
         SHA2(CONCAT(v_hash, '|', d.dni, '|PERSONERO'), 256), v_ahora
    FROM asistencia_personero_mesa ap
    JOIN personero pe      ON pe.id_personero = ap.id_personero
    JOIN lista_electoral l ON l.id_lista = pe.id_lista
    JOIN docente d         ON d.id_docente = pe.id_docente
   WHERE ap.id_mesa = p_id_mesa AND JSON_CONTAINS(v_personeros, CAST(ap.id_personero AS CHAR));

  
  UPDATE impugnacion_electoral SET id_acta = v_id_acta WHERE id_mesa = p_id_mesa AND id_acta IS NULL;

  UPDATE escrutinio_mesa
     SET estado = 'ACTA_EMITIDA', hora_fin = v_ahora, prevalece_fisica = v_prevalece, observada = v_observada,
         observaciones = v_obs, id_acta = v_id_acta, fecha_acta = v_ahora, id_usuario_acta = p_id_usuario
   WHERE id_mesa = p_id_mesa;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'EMITIR_ACTA_ESCRUTINIO',
       JSON_OBJECT('id_mesa', p_id_mesa, 'id_acta', v_id_acta, 'observada', v_observada,
                   'prevalece_fisica', v_prevalece, 'impugnados', v_impug));
  COMMIT;

  
  SELECT p_id_mesa AS id_mesa, v_id_acta AS id_acta, 'ESCRUTINIO' AS acta, v_token AS token_qr,
         v_observada AS observada;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_generar_acta_sufragio` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_generar_acta_sufragio`(
  IN p_id_mesa               INT,
  IN p_id_usuario            INT,
  IN p_cedulas_no_utilizadas INT,
  IN p_firmas_lista_fisica   INT,
  IN p_observaciones         VARCHAR(1000),
  IN p_personeros            LONGTEXT
)
BEGIN
  DECLARE v_proceso    INT DEFAULT NULL;
  DECLARE v_nombre     VARCHAR(200);
  DECLARE v_numero     VARCHAR(30);
  DECLARE v_ubic       VARCHAR(200);
  DECLARE v_hora_inst  DATETIME;
  DECLARE v_cierre     VARCHAR(20) DEFAULT NULL;
  DECLARE v_hora       DATETIME;
  DECLARE v_anticipado INT;
  DECLARE v_electores  INT;
  DECLARE v_votaron    INT;
  DECLARE v_no_votaron INT;
  DECLARE v_sin_votar  INT;
  DECLARE v_cedulas    INT;
  DECLARE v_obs        VARCHAR(1000);
  DECLARE v_personeros LONGTEXT;
  DECLARE v_n          INT DEFAULT 0;
  DECLARE v_validos    INT DEFAULT 0;
  DECLARE v_no_voto    LONGTEXT;
  DECLARE v_miembros   LONGTEXT;
  DECLARE v_contenido  LONGTEXT;
  DECLARE v_token      CHAR(64);
  DECLARE v_id_acta    INT;
  DECLARE v_hash       CHAR(64);
  DECLARE v_ahora      DATETIME;
  DECLARE v_msg        VARCHAR(255);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET SESSION group_concat_max_len = 1000000;
  START TRANSACTION;

  SELECT m.id_proceso, p.nombre, m.numero_mesa, m.ubicacion, m.hora_instalacion,
         c.estado, c.hora_cierre, c.cierre_anticipado, c.total_electores, c.total_votaron,
         c.total_no_votaron, c.asistieron_sin_votar, c.cedulas_recibidas
    INTO v_proceso, v_nombre, v_numero, v_ubic, v_hora_inst,
         v_cierre, v_hora, v_anticipado, v_electores, v_votaron,
         v_no_votaron, v_sin_votar, v_cedulas
    FROM mesa_electoral m
    JOIN proceso_electoral p ON p.id_proceso = m.id_proceso
    LEFT JOIN cierre_mesa c  ON c.id_mesa = m.id_mesa
   WHERE m.id_mesa = p_id_mesa
     FOR UPDATE;

  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no existe.';
  END IF;
  IF v_cierre IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cierre primero el sufragio de la mesa.';
  END IF;
  IF v_cierre = 'ACTA_EMITIDA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN28: el acta de sufragio de esta mesa ya fue emitida.';
  END IF;
  IF v_cierre <> 'AUSENTES_MARCADOS' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF75: marque primero NO VOTO a los electores que no votaron.';
  END IF;

  
  IF p_cedulas_no_utilizadas IS NULL OR p_cedulas_no_utilizadas < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF76: indique la cantidad de cédulas no utilizadas.';
  END IF;
  IF v_cedulas IS NOT NULL AND p_cedulas_no_utilizadas > v_cedulas THEN
    SET v_msg = CONCAT('RF76: las cédulas no utilizadas (', p_cedulas_no_utilizadas,
                       ') no pueden superar las recibidas en la instalación (', v_cedulas, ').');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  IF p_firmas_lista_fisica IS NOT NULL AND p_firmas_lista_fisica < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El conteo de firmas de la lista física no puede ser negativo.';
  END IF;
  SET v_obs = NULLIF(TRIM(p_observaciones), '');
  
  
  IF v_cedulas IS NOT NULL AND v_votaron + p_cedulas_no_utilizadas <> v_cedulas AND v_obs IS NULL THEN
    SET v_msg = CONCAT('RF76: ', v_votaron, ' votantes más ', p_cedulas_no_utilizadas, ' cédulas no utilizadas suman ',
                       v_votaron + p_cedulas_no_utilizadas, ' y se recibieron ', v_cedulas,
                       ' cédulas. Corrija la cantidad o explique la diferencia en las observaciones.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  
  IF p_firmas_lista_fisica IS NOT NULL AND p_firmas_lista_fisica <> v_votaron AND v_obs IS NULL THEN
    SET v_msg = CONCAT('A2: la lista física tiene ', p_firmas_lista_fisica, ' firmas y el sistema registra ',
                       v_votaron, ' votantes. Registre la observación.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  
  SET v_personeros = IF(p_personeros IS NULL OR TRIM(p_personeros) = '', '[]', p_personeros);
  IF JSON_VALID(v_personeros) = 0 OR JSON_TYPE(v_personeros) <> 'ARRAY' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lista de personeros firmantes no válida.';
  END IF;
  SET v_n = JSON_LENGTH(v_personeros);
  SELECT COUNT(*) INTO v_validos
    FROM asistencia_personero_mesa ap
   WHERE ap.id_mesa = p_id_mesa AND JSON_CONTAINS(v_personeros, CAST(ap.id_personero AS CHAR));
  IF v_validos <> v_n THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo firman el acta los personeros presentes en la mesa.';
  END IF;

  
  SELECT COUNT(*) INTO v_n FROM (
    SELECT rol_instalacion AS cargo FROM miembro_mesa
     WHERE id_mesa = p_id_mesa AND rol_instalacion IN ('PRESIDENTE', 'SECRETARIO')
    UNION
    SELECT cargo FROM reemplazo_mesa WHERE id_mesa = p_id_mesa AND cargo IN ('PRESIDENTE', 'SECRETARIO')) f;
  IF v_n < 2 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no registra presidente y secretario en funciones (CUS08).';
  END IF;

  
  SELECT CONCAT('[', GROUP_CONCAT(
           JSON_OBJECT('dni', x.dni, 'docente', x.docente, 'asistio', x.asistio)
           ORDER BY x.docente SEPARATOR ','), ']')
    INTO v_no_voto
    FROM (SELECT d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS docente,
                 (a.id_asistencia IS NOT NULL) AS asistio
            FROM padron_electoral pe
            JOIN docente d ON d.id_docente = pe.id_docente
            LEFT JOIN asistencia_elector a ON a.id_proceso = pe.id_proceso AND a.id_docente = pe.id_docente
           WHERE pe.id_mesa = p_id_mesa AND pe.no_voto = 1
           GROUP BY d.dni, d.apellidos, d.nombres, a.id_asistencia) x;

  SELECT CONCAT('[', GROUP_CONCAT(
           JSON_OBJECT('dni', f.dni, 'docente', f.docente, 'cargo', f.cargo, 'origen', f.origen)
           ORDER BY FIELD(f.cargo, 'PRESIDENTE', 'SECRETARIO', 'VOCAL') SEPARATOR ','), ']')
    INTO v_miembros
    FROM (SELECT d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS docente, CONCAT(mm.rol_instalacion, '') AS cargo,
                 IF(mm.titular = 1, 'TITULAR', 'SUPLENTE') AS origen
            FROM miembro_mesa mm JOIN docente d ON d.id_docente = mm.id_docente
           WHERE mm.id_mesa = p_id_mesa AND mm.rol_instalacion IS NOT NULL
          UNION ALL
          SELECT d.dni, CONCAT(d.apellidos, ', ', d.nombres), CONCAT(r.cargo, ''), 'REEMPLAZANTE'
            FROM reemplazo_mesa r JOIN docente d ON d.id_docente = r.id_docente
           WHERE r.id_mesa = p_id_mesa) f;

  
  SET v_ahora = NOW();
  SET v_contenido = CONCAT(
      '{"tipo":"SUFRAGIO"',
      ',"id_proceso":', v_proceso,
      ',"proceso":', JSON_QUOTE(v_nombre),
      ',"mesa":', JSON_QUOTE(v_numero),
      ',"ubicacion":', JSON_QUOTE(v_ubic),
      ',"hora_instalacion":', IF(v_hora_inst IS NULL, 'null', JSON_QUOTE(DATE_FORMAT(v_hora_inst, '%Y-%m-%d %H:%i:%s'))),
      ',"hora_cierre":', JSON_QUOTE(DATE_FORMAT(v_hora, '%Y-%m-%d %H:%i:%s')),
      ',"cierre_anticipado":', IF(v_anticipado = 1, 'true', 'false'),
      ',"total_electores":', v_electores,
      ',"electores_que_votaron":', v_votaron,
      ',"electores_que_no_votaron":', v_no_votaron,
      ',"asistieron_sin_votar":', v_sin_votar,
      ',"cedulas_recibidas":', IF(v_cedulas IS NULL, 'null', v_cedulas),
      ',"cedulas_no_utilizadas":', p_cedulas_no_utilizadas,
      ',"firmas_lista_fisica":', IF(p_firmas_lista_fisica IS NULL, 'null', p_firmas_lista_fisica),
      ',"diferencia_lista_fisica":', IF(p_firmas_lista_fisica IS NULL, 'null', p_firmas_lista_fisica - v_votaron),
      ',"miembros":', COALESCE(v_miembros, '[]'),
      ',"no_votaron":', COALESCE(v_no_voto, '[]'),
      ',"observaciones":', IF(v_obs IS NULL, 'null', JSON_QUOTE(v_obs)),
      '}');

  
  CALL sp_emitir_acta(p_id_mesa, 'SUFRAGIO', v_contenido, v_token);
  SELECT id_acta, hash_integridad INTO v_id_acta, v_hash
    FROM acta_electoral WHERE id_mesa = p_id_mesa AND tipo = 'SUFRAGIO';

  
  INSERT INTO firma_acta (id_acta, id_docente, rol, firma_digital, fecha_firma)
  SELECT v_id_acta, mm.id_docente,
         CONCAT(mm.rol_instalacion, ' DE MESA', IF(mm.titular = 1, '', ' (SUPLENTE)')),
         SHA2(CONCAT(v_hash, '|', d.dni, '|', mm.rol_instalacion), 256), v_ahora
    FROM miembro_mesa mm JOIN docente d ON d.id_docente = mm.id_docente
   WHERE mm.id_mesa = p_id_mesa AND mm.rol_instalacion IN ('PRESIDENTE', 'SECRETARIO');

  INSERT INTO firma_acta (id_acta, id_docente, rol, firma_digital, fecha_firma)
  SELECT v_id_acta, r.id_docente, CONCAT(r.cargo, ' DE MESA (REEMPLAZANTE)'),
         SHA2(CONCAT(v_hash, '|', d.dni, '|', r.cargo), 256), v_ahora
    FROM reemplazo_mesa r JOIN docente d ON d.id_docente = r.id_docente
   WHERE r.id_mesa = p_id_mesa AND r.cargo IN ('PRESIDENTE', 'SECRETARIO');

  INSERT IGNORE INTO firma_acta (id_acta, id_docente, rol, firma_digital, fecha_firma)
  SELECT v_id_acta, pe.id_docente, LEFT(CONCAT('PERSONERO ', pe.tipo, ' - ', l.nombre), 80),
         SHA2(CONCAT(v_hash, '|', d.dni, '|PERSONERO'), 256), v_ahora
    FROM asistencia_personero_mesa ap
    JOIN personero pe      ON pe.id_personero = ap.id_personero
    JOIN lista_electoral l ON l.id_lista = pe.id_lista
    JOIN docente d         ON d.id_docente = pe.id_docente
   WHERE ap.id_mesa = p_id_mesa AND JSON_CONTAINS(v_personeros, CAST(ap.id_personero AS CHAR));

  UPDATE cierre_mesa
     SET estado = 'ACTA_EMITIDA', cedulas_no_utilizadas = p_cedulas_no_utilizadas,
         firmas_lista_fisica = p_firmas_lista_fisica, observaciones = v_obs, id_acta = v_id_acta,
         fecha_acta = v_ahora, id_usuario_acta = p_id_usuario
   WHERE id_mesa = p_id_mesa;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'EMITIR_ACTA_SUFRAGIO',
       JSON_OBJECT('id_mesa', p_id_mesa, 'id_acta', v_id_acta, 'votaron', v_votaron));
  COMMIT;

  
  SELECT p_id_mesa AS id_mesa, v_id_acta AS id_acta, 'SUFRAGIO' AS acta, v_token AS token_qr;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_generar_multas` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_generar_multas`(
  IN p_id_proceso INT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_estado   VARCHAR(20) DEFAULT NULL;
  DECLARE v_reporte  VARCHAR(10) DEFAULT NULL;
  DECLARE v_res      VARCHAR(40);
  DECLARE v_uit      DECIMAL(12,2);
  DECLARE v_pct_elec DECIMAL(12,2);
  DECLARE v_pct_mesa DECIMAL(12,2);
  DECLARE v_abiertas INT DEFAULT 0;
  DECLARE v_instal   INT DEFAULT 0;
  DECLARE v_retiradas INT DEFAULT 0;
  DECLARE v_n1       INT DEFAULT 0;
  DECLARE v_n2       INT DEFAULT 0;
  DECLARE v_total    DECIMAL(12,2) DEFAULT 0;
  DECLARE v_msg      VARCHAR(255);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    SET @cus16_regenerar = NULL;
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT estado INTO v_estado FROM proceso_electoral WHERE id_proceso = p_id_proceso FOR UPDATE;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;
  IF v_estado NOT IN ('CERRADO','FINALIZADO','ANULADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: las multas se generan con la votación ya concluida.';
  END IF;
  SELECT COUNT(*), COALESCE(SUM(hora_instalacion IS NOT NULL), 0) INTO v_abiertas, v_instal
    FROM mesa_electoral WHERE id_proceso = p_id_proceso;
  IF v_instal = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF103: ninguna mesa del proceso se instaló; no hubo sufragio que omitir.';
  END IF;
  SELECT COUNT(*) INTO v_abiertas FROM mesa_electoral WHERE id_proceso = p_id_proceso AND estado IN ('PENDIENTE','INSTALADA');
  IF v_abiertas > 0 THEN
    SET v_msg = CONCAT('RF103: ', v_abiertas, ' mesa(s) aún no cierran su sufragio (CUS11).');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  SELECT estado, numero_resolucion INTO v_reporte, v_res FROM reporte_multas WHERE id_proceso = p_id_proceso FOR UPDATE;
  IF v_reporte = 'RESUELTO' THEN
    SET v_msg = CONCAT('RN35: las multas ya fueron determinadas por la Resolución ', v_res, '; no se regeneran.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  
  SET v_uit      = fn_parametro_decimal('UIT');
  SET v_pct_elec = fn_parametro_decimal('MULTA_ELECTOR_OMISO_PCT');
  SET v_pct_mesa = fn_parametro_decimal('MULTA_MIEMBRO_MESA_OMISO_PCT');
  IF v_uit IS NULL OR v_pct_elec IS NULL OR v_pct_mesa IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF105: faltan parámetros: UIT y porcentajes de multa.';
  END IF;
  IF v_uit <= 0 OR v_pct_elec < 0 OR v_pct_elec > 100 OR v_pct_mesa < 0 OR v_pct_mesa > 100 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF105: la UIT debe ser positiva y los porcentajes de multa estar entre 0 y 100.';
  END IF;

  
  SET @cus16_regenerar = p_id_proceso;
  DELETE mu FROM multa mu
   WHERE mu.id_proceso = p_id_proceso AND mu.estado_pago = 'PENDIENTE'
     AND NOT EXISTS (SELECT 1 FROM v_omisos_proceso o
                      WHERE o.id_proceso = mu.id_proceso AND o.id_docente = mu.id_docente AND o.motivo = mu.motivo);
  SET v_retiradas = ROW_COUNT();
  SET @cus16_regenerar = NULL;

  
  INSERT INTO multa (id_docente, id_proceso, motivo, id_mesa, rol_mesa, asistio_sin_votar, uit_referencia, porcentaje_uit, monto)
  SELECT o.id_docente, o.id_proceso, o.motivo, o.id_mesa, o.rol_mesa, o.asistio_sin_votar, v_uit,
         IF(o.motivo = 'OMISO_VOTACION', v_pct_elec, v_pct_mesa),
         ROUND(v_uit * IF(o.motivo = 'OMISO_VOTACION', v_pct_elec, v_pct_mesa) / 100, 2)
    FROM v_omisos_proceso o
   WHERE o.id_proceso = p_id_proceso
  ON DUPLICATE KEY UPDATE id_mesa = VALUES(id_mesa), rol_mesa = VALUES(rol_mesa), asistio_sin_votar = VALUES(asistio_sin_votar),
                          uit_referencia = VALUES(uit_referencia), porcentaje_uit = VALUES(porcentaje_uit), monto = VALUES(monto),
                          fecha_generacion = NOW();

  SELECT COALESCE(SUM(motivo = 'OMISO_VOTACION'), 0), COALESCE(SUM(motivo = 'OMISO_MESA'), 0), COALESCE(SUM(monto), 0)
    INTO v_n1, v_n2, v_total
    FROM multa WHERE id_proceso = p_id_proceso;

  INSERT INTO reporte_multas (id_proceso, estado, uit_referencia, pct_elector, pct_miembro, omisos_votacion, omisos_mesa,
                              monto_total, veces_generado, fecha_generacion, id_usuario_generacion)
  VALUES (p_id_proceso, 'GENERADO', v_uit, v_pct_elec, v_pct_mesa, v_n1, v_n2, v_total, 1, NOW(), p_id_usuario)
  ON DUPLICATE KEY UPDATE uit_referencia = VALUES(uit_referencia), pct_elector = VALUES(pct_elector),
                          pct_miembro = VALUES(pct_miembro), omisos_votacion = VALUES(omisos_votacion),
                          omisos_mesa = VALUES(omisos_mesa), monto_total = VALUES(monto_total),
                          veces_generado = veces_generado + 1, fecha_generacion = VALUES(fecha_generacion),
                          id_usuario_generacion = VALUES(id_usuario_generacion);

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'GENERAR_MULTAS',
       JSON_OBJECT('omisos_votacion', v_n1, 'omisos_mesa', v_n2, 'monto_total', v_total, 'uit', v_uit,
                   'retiradas', v_retiradas));
  COMMIT;

  SELECT motivo, COUNT(*) AS multas, SUM(monto) AS total_soles
    FROM multa WHERE id_proceso = p_id_proceso GROUP BY motivo;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_generar_padron` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_generar_padron`(
  IN p_id_proceso INT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_estado VARCHAR(20) DEFAULT NULL;
  DECLARE v_n      INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT estado INTO v_estado FROM proceso_electoral WHERE id_proceso = p_id_proceso FOR UPDATE;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;
  IF v_estado NOT IN ('CREADO','INSCRIPCION') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN04: el padron no se modifica una vez iniciada la votacion.';
  END IF;
  SELECT COUNT(*) INTO v_n FROM mesa_electoral WHERE id_proceso = p_id_proceso;
  IF v_n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existen mesas: el padron no puede regenerarse.';
  END IF;

  DELETE FROM padron_electoral WHERE id_proceso = p_id_proceso;

  INSERT INTO padron_electoral (id_proceso, id_cargo, id_docente)
  SELECT c.id_proceso, c.id_cargo, d.id_docente
    FROM cargo_electoral c
    JOIN docente d
      ON ( c.nivel_jurisdiccion = 'UNIVERSIDAD'
        OR (c.nivel_jurisdiccion = 'FACULTAD'     AND d.id_facultad     = c.id_jurisdiccion)
        OR (c.nivel_jurisdiccion = 'DEPARTAMENTO' AND d.id_departamento = c.id_jurisdiccion) )
   WHERE c.id_proceso = p_id_proceso
     AND d.estado = 'ACTIVO'
     AND d.habilitado_para_votar = 1
     AND ( NOT EXISTS (SELECT 1 FROM cargo_categoria_permitida x WHERE x.id_cargo = c.id_cargo)
        OR EXISTS (SELECT 1 FROM cargo_categoria_permitida x
                    WHERE x.id_cargo = c.id_cargo AND x.categoria = d.categoria AND x.puede_votar = 1) );
  SET v_n = ROW_COUNT();

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'GENERAR_PADRON',
       JSON_OBJECT('registros', v_n));
  COMMIT;

  SELECT cargo, electores_habiles FROM v_participacion_cargo WHERE id_proceso = p_id_proceso;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_inscribir_candidato` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_inscribir_candidato`(
  IN  p_id_lista     INT,
  IN  p_id_docente   INT,
  IN  p_rol_en_lista VARCHAR(100),
  IN  p_url_hoja_vida VARCHAR(300),
  IN  p_id_usuario   INT,
  OUT p_id_candidato INT
)
BEGIN
  DECLARE v_proceso   INT DEFAULT NULL;
  DECLARE v_cargo     INT DEFAULT NULL;
  DECLARE v_estado    VARCHAR(20) DEFAULT NULL;
  DECLARE v_limite    DATETIME DEFAULT NULL;
  DECLARE v_lista_est VARCHAR(20) DEFAULT NULL;
  DECLARE v_nivel     VARCHAR(20) DEFAULT NULL;
  DECLARE v_jur       INT DEFAULT NULL;
  DECLARE v_doc_est   VARCHAR(20) DEFAULT NULL;
  DECLARE v_doc_cat   VARCHAR(10) DEFAULT NULL;
  DECLARE v_doc_fac   INT DEFAULT NULL;
  DECLARE v_doc_dep   INT DEFAULT NULL;
  DECLARE v_n         INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT p.id_proceso, p.estado, p.fecha_limite_inscripcion, l.estado,
         c.id_cargo, c.nivel_jurisdiccion, c.id_jurisdiccion
    INTO v_proceso, v_estado, v_limite, v_lista_est, v_cargo, v_nivel, v_jur
    FROM lista_electoral l
    JOIN cargo_electoral c   ON c.id_cargo = l.id_cargo
    JOIN proceso_electoral p ON p.id_proceso = c.id_proceso
   WHERE l.id_lista = p_id_lista;

  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La lista electoral no existe.';
  END IF;
  IF v_estado <> 'INSCRIPCION' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso no esta en etapa de INSCRIPCION.';
  END IF;
  IF v_limite IS NOT NULL AND NOW() > v_limite THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN13: vencio el plazo para modificar la lista.';
  END IF;
  IF v_lista_est <> 'INSCRITA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN12: la lista ya fue calificada; no admite nuevos candidatos.';
  END IF;

  SELECT estado, categoria, id_facultad, id_departamento
    INTO v_doc_est, v_doc_cat, v_doc_fac, v_doc_dep
    FROM docente WHERE id_docente = p_id_docente;

  IF v_doc_est IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El docente no existe.';
  END IF;
  IF v_doc_est <> 'ACTIVO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN09: solo un docente ACTIVO puede ser candidato.';
  END IF;
  IF (v_nivel = 'FACULTAD' AND v_doc_fac <> v_jur)
     OR (v_nivel = 'DEPARTAMENTO' AND v_doc_dep <> v_jur) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El docente no pertenece a la jurisdiccion del cargo.';
  END IF;

  
  SELECT COUNT(*) INTO v_n FROM cargo_categoria_permitida WHERE id_cargo = v_cargo;
  IF v_n > 0 THEN
    SELECT COUNT(*) INTO v_n FROM cargo_categoria_permitida
     WHERE id_cargo = v_cargo AND categoria = v_doc_cat AND puede_postular = 1;
    IF v_n = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN09: la categoria del docente no puede postular a este cargo.';
    END IF;
  END IF;

  
  INSERT INTO candidato (id_lista, id_docente, rol_en_lista, url_hoja_vida, estado_validacion)
  VALUES (p_id_lista, p_id_docente, UPPER(TRIM(p_rol_en_lista)), p_url_hoja_vida, 'PENDIENTE');
  SET p_id_candidato = LAST_INSERT_ID();

  CALL sp_registrar_auditoria(p_id_usuario, p_id_docente, v_proceso, 'INSCRIBIR_CANDIDATO',
       JSON_OBJECT('id_lista', p_id_lista, 'rol', p_rol_en_lista));
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_inscribir_lista` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_inscribir_lista`(
  IN  p_id_cargo  INT,
  IN  p_nombre    VARCHAR(150),
  IN  p_simbolo   VARCHAR(100),
  IN  p_url_plan  VARCHAR(300),
  IN  p_id_usuario INT,
  OUT p_id_lista  INT
)
BEGIN
  DECLARE v_proceso INT DEFAULT NULL;
  DECLARE v_estado  VARCHAR(20) DEFAULT NULL;
  DECLARE v_limite  DATETIME DEFAULT NULL;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT p.id_proceso, p.estado, p.fecha_limite_inscripcion
    INTO v_proceso, v_estado, v_limite
    FROM cargo_electoral c
    JOIN proceso_electoral p ON p.id_proceso = c.id_proceso
   WHERE c.id_cargo = p_id_cargo;

  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cargo electoral no existe.';
  END IF;
  IF v_estado <> 'INSCRIPCION' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso no esta en etapa de INSCRIPCION.';
  END IF;
  IF v_limite IS NOT NULL AND NOW() > v_limite THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN13: vencio el plazo de inscripcion de listas.';
  END IF;

  INSERT INTO lista_electoral (id_cargo, nombre, simbolo, url_plan_gobierno, estado)
  VALUES (p_id_cargo, TRIM(p_nombre), p_simbolo, p_url_plan, 'INSCRITA');
  SET p_id_lista = LAST_INSERT_ID();

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'INSCRIBIR_LISTA',
       JSON_OBJECT('id_lista', p_id_lista, 'nombre', p_nombre));
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_instalar_mesa` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_instalar_mesa`(
  IN p_id_mesa    INT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_proceso    INT DEFAULT NULL;
  DECLARE v_nombre     VARCHAR(200);
  DECLARE v_estado     VARCHAR(20) DEFAULT NULL;
  DECLARE v_mesa_est   VARCHAR(20) DEFAULT NULL;
  DECLARE v_numero     VARCHAR(30);
  DECLARE v_ubic       VARCHAR(200);
  DECLARE v_total      INT DEFAULT 0;
  DECLARE v_n          INT DEFAULT 0;
  DECLARE v_i          INT DEFAULT 1;
  DECLARE v_rol        VARCHAR(12);
  DECLARE v_abierta    INT DEFAULT 0;
  DECLARE v_vencida    INT DEFAULT 0;
  DECLARE v_control    INT DEFAULT 1;
  DECLARE v_msg        VARCHAR(255);
  DECLARE v_mat_ok     INT DEFAULT 0;
  DECLARE v_cedulas    INT DEFAULT NULL;
  DECLARE v_firmadas   INT DEFAULT 0;
  DECLARE v_material   LONGTEXT;
  DECLARE v_obs        VARCHAR(500);
  DECLARE v_miembros   LONGTEXT;
  DECLARE v_reemplazos LONGTEXT;
  DECLARE v_personeros LONGTEXT;
  DECLARE v_contenido  LONGTEXT;
  DECLARE v_token      CHAR(64);
  DECLARE v_id_acta    INT;
  DECLARE v_hash       CHAR(64);
  DECLARE v_ahora      DATETIME;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET SESSION group_concat_max_len = 1000000;
  START TRANSACTION;

  SELECT m.id_proceso, p.nombre, p.estado, m.estado, m.numero_mesa, m.ubicacion, m.total_electores
    INTO v_proceso, v_nombre, v_estado, v_mesa_est, v_numero, v_ubic, v_total
    FROM mesa_electoral m JOIN proceso_electoral p ON p.id_proceso = m.id_proceso
   WHERE m.id_mesa = p_id_mesa
     FOR UPDATE;

  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no existe.';
  END IF;
  IF v_estado <> 'VOTACION' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN07: la mesa se instala con el proceso en VOTACION.';
  END IF;
  IF v_mesa_est <> 'PENDIENTE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa ya fue instalada, cerrada, anulada o declarada no instalada.';
  END IF;

  
  CALL sp_ventana_instalacion(v_proceso, v_abierta, v_vencida, v_control, v_msg);
  IF v_abierta = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  SELECT COUNT(*) INTO v_n FROM miembro_mesa WHERE id_mesa = p_id_mesa;
  IF v_n <> 6 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN19: la mesa no tiene sus 6 miembros sorteados.';
  END IF;

  
  SELECT COUNT(*), COALESCE(MAX(material_completo), 0), MAX(cedulas_recibidas), COALESCE(MAX(cedulas_firmadas), 0),
         MAX(material_json), MAX(observaciones)
    INTO v_n, v_mat_ok, v_cedulas, v_firmadas, v_material, v_obs
    FROM instalacion_mesa WHERE id_mesa = p_id_mesa;
  IF v_n = 0 OR v_mat_ok = 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RF57: registre la recepción del padrón, actas, cédulas, cartel de candidatos, ánfora y cabina.';
  END IF;
  IF v_cedulas IS NULL OR v_cedulas <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF59: indique la cantidad de cédulas recibidas.';
  END IF;
  IF v_firmadas = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUN07: el presidente debe firmar las cédulas en el reverso antes de instalar.';
  END IF;

  
  UPDATE miembro_mesa SET rol_instalacion = NULL WHERE id_mesa = p_id_mesa;
  WHILE v_i <= 3 DO
    SET v_rol = ELT(v_i, 'PRESIDENTE', 'SECRETARIO', 'VOCAL');
    UPDATE miembro_mesa SET rol_instalacion = v_rol
     WHERE id_mesa = p_id_mesa AND titular = 1 AND rol = v_rol AND asistio = 1;
    IF ROW_COUNT() = 0 THEN
      UPDATE miembro_mesa SET rol_instalacion = v_rol
       WHERE id_mesa = p_id_mesa AND titular = 0 AND asistio = 1 AND rol_instalacion IS NULL
       ORDER BY orden_sorteo, id_docente
       LIMIT 1;
      IF ROW_COUNT() = 0 THEN
        SELECT COUNT(*) INTO v_n FROM reemplazo_mesa WHERE id_mesa = p_id_mesa AND cargo = v_rol;
        IF v_n = 0 THEN
          SET v_msg = CONCAT('RN19: nadie asume el cargo de ', LOWER(v_rol),
                             ' (acredite a un suplente o registre un reemplazante).');
          SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
        END IF;
      END IF;
    END IF;
    SET v_i = v_i + 1;
  END WHILE;

  
  DELETE r FROM reemplazo_mesa r
   WHERE r.id_mesa = p_id_mesa
     AND EXISTS (SELECT 1 FROM miembro_mesa mm WHERE mm.id_mesa = r.id_mesa AND mm.rol_instalacion = r.cargo);

  
  UPDATE miembro_mesa SET asistio = 0 WHERE id_mesa = p_id_mesa AND asistio IS NULL;

  SELECT CONCAT('[', GROUP_CONCAT(
           JSON_OBJECT('dni', d.dni,
                       'docente', CONCAT(d.apellidos, ', ', d.nombres),
                       'rol_sorteo', CONCAT(mm.rol, ''),
                       'titular', mm.titular,
                       'asistio', mm.asistio,
                       'rol_instalacion', CONCAT(mm.rol_instalacion, ''),
                       'hora_llegada', DATE_FORMAT(mm.hora_acreditacion, '%Y-%m-%d %H:%i:%s'),
                       'metodo', CONCAT(mm.metodo_acreditacion, ''))
           ORDER BY mm.orden_sorteo SEPARATOR ','), ']')
    INTO v_miembros
    FROM miembro_mesa mm JOIN docente d ON d.id_docente = mm.id_docente
   WHERE mm.id_mesa = p_id_mesa;

  SELECT CONCAT('[', GROUP_CONCAT(
           JSON_OBJECT('dni', d.dni,
                       'docente', CONCAT(d.apellidos, ', ', d.nombres),
                       'cargo', CONCAT(r.cargo, ''),
                       'hora_llegada', DATE_FORMAT(r.hora_acreditacion, '%Y-%m-%d %H:%i:%s'))
           ORDER BY FIELD(r.cargo, 'PRESIDENTE', 'SECRETARIO', 'VOCAL') SEPARATOR ','), ']')
    INTO v_reemplazos
    FROM reemplazo_mesa r JOIN docente d ON d.id_docente = r.id_docente
   WHERE r.id_mesa = p_id_mesa;

  SELECT CONCAT('[', GROUP_CONCAT(
           JSON_OBJECT('dni', d.dni,
                       'docente', CONCAT(d.apellidos, ', ', d.nombres),
                       'lista', l.nombre,
                       'tipo', CONCAT(pe.tipo, ''),
                       'hora_llegada', DATE_FORMAT(ap.hora_acreditacion, '%Y-%m-%d %H:%i:%s'),
                       'metodo', CONCAT(ap.metodo, ''))
           ORDER BY ap.hora_acreditacion SEPARATOR ','), ']')
    INTO v_personeros
    FROM asistencia_personero_mesa ap
    JOIN personero pe       ON pe.id_personero = ap.id_personero
    JOIN lista_electoral l  ON l.id_lista = pe.id_lista
    JOIN docente d          ON d.id_docente = pe.id_docente
   WHERE ap.id_mesa = p_id_mesa;

  
  SET v_ahora = NOW();
  SET v_contenido = CONCAT(
      '{"tipo":"INSTALACION"',
      ',"id_proceso":', v_proceso,
      ',"proceso":', JSON_QUOTE(v_nombre),
      ',"mesa":', JSON_QUOTE(v_numero),
      ',"ubicacion":', JSON_QUOTE(v_ubic),
      ',"hora_instalacion":', JSON_QUOTE(DATE_FORMAT(v_ahora, '%Y-%m-%d %H:%i:%s')),
      ',"total_electores":', v_total,
      ',"cedulas_recibidas":', v_cedulas,
      ',"cedulas_firmadas":true',
      ',"miembros":', COALESCE(v_miembros, '[]'),
      ',"reemplazantes":', COALESCE(v_reemplazos, '[]'),
      ',"personeros":', COALESCE(v_personeros, '[]'),
      ',"material":', COALESCE(v_material, '{}'),
      ',"observaciones":', IF(v_obs IS NULL OR v_obs = '', 'null', JSON_QUOTE(v_obs)),
      '}');

  
  UPDATE mesa_electoral SET estado = 'INSTALADA', hora_instalacion = v_ahora WHERE id_mesa = p_id_mesa;
  
  CALL sp_emitir_acta(p_id_mesa, 'INSTALACION', v_contenido, v_token);
  SELECT id_acta, hash_integridad INTO v_id_acta, v_hash
    FROM acta_electoral WHERE id_mesa = p_id_mesa AND tipo = 'INSTALACION';

  
  INSERT INTO firma_acta (id_acta, id_docente, rol, firma_digital, fecha_firma)
  SELECT v_id_acta, mm.id_docente,
         CONCAT(mm.rol_instalacion, ' DE MESA', IF(mm.titular = 1, '', ' (SUPLENTE)')),
         SHA2(CONCAT(v_hash, '|', d.dni, '|', mm.rol_instalacion), 256), v_ahora
    FROM miembro_mesa mm JOIN docente d ON d.id_docente = mm.id_docente
   WHERE mm.id_mesa = p_id_mesa AND mm.rol_instalacion IS NOT NULL;

  INSERT INTO firma_acta (id_acta, id_docente, rol, firma_digital, fecha_firma)
  SELECT v_id_acta, r.id_docente, CONCAT(r.cargo, ' DE MESA (REEMPLAZANTE)'),
         SHA2(CONCAT(v_hash, '|', d.dni, '|', r.cargo), 256), v_ahora
    FROM reemplazo_mesa r JOIN docente d ON d.id_docente = r.id_docente
   WHERE r.id_mesa = p_id_mesa;

  INSERT IGNORE INTO firma_acta (id_acta, id_docente, rol, firma_digital, fecha_firma)
  SELECT v_id_acta, pe.id_docente, LEFT(CONCAT('PERSONERO ', pe.tipo, ' - ', l.nombre), 80),
         SHA2(CONCAT(v_hash, '|', d.dni, '|PERSONERO'), 256), v_ahora
    FROM asistencia_personero_mesa ap
    JOIN personero pe      ON pe.id_personero = ap.id_personero
    JOIN lista_electoral l ON l.id_lista = pe.id_lista
    JOIN docente d         ON d.id_docente = pe.id_docente
   WHERE ap.id_mesa = p_id_mesa;

  UPDATE instalacion_mesa
     SET estado = 'INSTALADA', hora_instalacion = v_ahora, fecha_actualizacion = v_ahora,
         id_usuario_cierre = p_id_usuario
   WHERE id_mesa = p_id_mesa;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'INSTALAR_MESA',
       JSON_OBJECT('id_mesa', p_id_mesa, 'id_acta', v_id_acta));
  COMMIT;

  SELECT p_id_mesa AS id_mesa, v_id_acta AS id_acta, 'INSTALACION' AS acta, v_token AS token_qr;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_instalar_sesion_computo` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_instalar_sesion_computo`(
  IN p_id_proceso    INT,
  IN p_id_usuario    INT,
  IN p_lugar         VARCHAR(200),
  IN p_miembros      INT,
  IN p_observaciones VARCHAR(1000),
  IN p_personeros    LONGTEXT
)
BEGIN
  DECLARE v_estado   VARCHAR(20) DEFAULT NULL;
  DECLARE v_quorum   INT;
  DECLARE v_lugar    VARCHAR(200);
  DECLARE v_pers     LONGTEXT;
  DECLARE v_n        INT DEFAULT 0;
  DECLARE v_validos  INT DEFAULT 0;
  DECLARE v_msg      VARCHAR(255);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT estado INTO v_estado FROM proceso_electoral WHERE id_proceso = p_id_proceso FOR UPDATE;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;
  IF EXISTS (SELECT 1 FROM computo_proceso WHERE id_proceso = p_id_proceso) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF91: la sesión de cómputo de este proceso ya fue instalada.';
  END IF;
  IF v_estado <> 'CERRADO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN32: la sesión de cómputo se instala con la votación del proceso concluida (CERRADO).';
  END IF;
  SET v_lugar = NULLIF(TRIM(p_lugar), '');
  IF v_lugar IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF91: indique el lugar de la sesión de cómputo.';
  END IF;
  SET v_quorum = COALESCE(ROUND((SELECT CAST(valor AS DECIMAL(6,2)) FROM parametro_global WHERE clave = 'CEUNP_QUORUM_PLENO')), 5);
  IF p_miembros IS NULL OR p_miembros < v_quorum OR p_miembros > 9 THEN
    SET v_msg = CONCAT('RN36: el Pleno del CEUNP sesiona con quórum de ', v_quorum, ' de sus 9 miembros.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  SET v_pers = IF(p_personeros IS NULL OR TRIM(p_personeros) = '', '[]', p_personeros);
  IF JSON_VALID(v_pers) = 0 OR JSON_TYPE(v_pers) <> 'ARRAY' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lista de personeros presentes no válida.';
  END IF;
  SET v_n = JSON_LENGTH(v_pers);
  SELECT COUNT(*) INTO v_validos
    FROM personero pe
    JOIN lista_electoral l ON l.id_lista = pe.id_lista
    JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
   WHERE c.id_proceso = p_id_proceso AND pe.estado_acreditacion = 'ACREDITADO'
     AND JSON_CONTAINS(v_pers, CAST(pe.id_personero AS CHAR));
  IF v_validos <> v_n THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF91: solo asisten a la sesión los personeros acreditados del proceso.';
  END IF;

  INSERT INTO computo_proceso (id_proceso, estado, lugar_sesion, miembros_ceunp, observaciones_sesion, fecha_sesion, id_usuario_sesion)
  VALUES (p_id_proceso, 'SESION_INSTALADA', v_lugar, p_miembros, NULLIF(TRIM(p_observaciones), ''), NOW(), p_id_usuario);

  INSERT INTO computo_personero (id_proceso, id_personero, id_usuario)
  SELECT p_id_proceso, pe.id_personero, p_id_usuario
    FROM personero pe
    JOIN lista_electoral l ON l.id_lista = pe.id_lista
    JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
   WHERE c.id_proceso = p_id_proceso AND JSON_CONTAINS(v_pers, CAST(pe.id_personero AS CHAR));

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'INSTALAR_SESION_COMPUTO',
       JSON_OBJECT('lugar', v_lugar, 'miembros', p_miembros, 'personeros', v_n));
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_localizar_documento` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_localizar_documento`(
  IN  p_codigo CHAR(64),
  OUT p_tipo   VARCHAR(30),
  OUT p_id     INT,
  OUT p_metodo VARCHAR(6)
)
BEGIN
  DECLARE v_token CHAR(64);
  SET p_tipo = NULL;
  SET p_id = NULL;
  SET p_metodo = NULL;
  SET v_token = SHA2(LOWER(p_codigo), 256);

  
  SELECT CONCAT('ACTA_', tipo), id_acta INTO p_tipo, p_id FROM acta_electoral WHERE token_qr_hash = v_token;
  IF p_id IS NULL THEN
    SELECT 'COMPUTO_GENERAL', id_proceso INTO p_tipo, p_id FROM computo_proceso WHERE token_qr_hash = v_token;
  END IF;
  IF p_id IS NULL THEN
    SELECT 'PROCLAMACION', id_proceso INTO p_tipo, p_id FROM computo_proceso WHERE token_proclamacion_hash = v_token;
  END IF;
  IF p_id IS NULL THEN
    SELECT 'RESOLUCION_NULIDAD', id_nulidad INTO p_tipo, p_id FROM nulidad_electoral WHERE token_qr_hash = v_token;
  END IF;
  IF p_id IS NULL THEN
    SELECT 'RESOLUCION_MULTAS', id_reporte INTO p_tipo, p_id FROM reporte_multas
     WHERE token_qr_hash = v_token AND estado = 'RESUELTO';
  END IF;
  IF p_id IS NULL THEN
    SELECT 'CONSTANCIA_VOTO', id_constancia INTO p_tipo, p_id FROM constancia_voto WHERE token_qr_hash = v_token;
  END IF;
  IF p_id IS NOT NULL THEN
    SET p_metodo = 'TOKEN';
  ELSE
    
    SELECT CONCAT('ACTA_', tipo), id_acta INTO p_tipo, p_id FROM acta_electoral
     WHERE hash_integridad = LOWER(p_codigo) ORDER BY id_acta LIMIT 1;
    IF p_id IS NULL THEN
      SELECT 'COMPUTO_GENERAL', id_proceso INTO p_tipo, p_id FROM computo_proceso WHERE hash_integridad = LOWER(p_codigo) LIMIT 1;
    END IF;
    IF p_id IS NULL THEN
      SELECT 'PROCLAMACION', id_proceso INTO p_tipo, p_id FROM computo_proceso WHERE hash_proclamacion = LOWER(p_codigo) LIMIT 1;
    END IF;
    IF p_id IS NULL THEN
      SELECT 'RESOLUCION_NULIDAD', id_nulidad INTO p_tipo, p_id FROM nulidad_electoral WHERE hash_integridad = LOWER(p_codigo) LIMIT 1;
    END IF;
    IF p_id IS NULL THEN
      SELECT 'RESOLUCION_MULTAS', id_reporte INTO p_tipo, p_id FROM reporte_multas
       WHERE hash_integridad = LOWER(p_codigo) AND estado = 'RESUELTO' LIMIT 1;
    END IF;
    IF p_id IS NOT NULL THEN
      SET p_metodo = 'HUELLA';
    END IF;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_marcar_acta_dudosa` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_marcar_acta_dudosa`(
  IN p_id_acta    INT,
  IN p_id_usuario INT,
  IN p_motivo     VARCHAR(500)
)
BEGIN
  DECLARE v_mesa     INT DEFAULT NULL;
  DECLARE v_proceso  INT;
  DECLARE v_estado   VARCHAR(20);
  DECLARE v_acta_est VARCHAR(10);
  DECLARE v_tipo     VARCHAR(12);
  DECLARE v_motivo   VARCHAR(500);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT a.id_mesa, m.id_proceso, p.estado, a.estado, a.tipo INTO v_mesa, v_proceso, v_estado, v_acta_est, v_tipo
    FROM acta_electoral a
    JOIN mesa_electoral m    ON m.id_mesa = a.id_mesa
    JOIN proceso_electoral p ON p.id_proceso = m.id_proceso
   WHERE a.id_acta = p_id_acta
     FOR UPDATE;
  IF v_mesa IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El acta no existe.';
  END IF;
  IF v_estado NOT IN ('VOTACION','CERRADO')
     OR EXISTS (SELECT 1 FROM computo_proceso WHERE id_proceso = v_proceso AND estado <> 'SESION_INSTALADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN32: las actas se verifican antes del cómputo.';
  END IF;
  IF v_acta_est <> 'VIGENTE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: el acta está anulada.';
  END IF;
  IF EXISTS (SELECT 1 FROM verificacion_acta WHERE id_acta = p_id_acta) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: el acta ya está marcada como dudosa.';
  END IF;
  SET v_motivo = NULLIF(TRIM(p_motivo), '');
  IF v_motivo IS NULL OR CHAR_LENGTH(v_motivo) < 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: indique por qué el acta es dudosa (al menos 10 caracteres).';
  END IF;

  INSERT INTO verificacion_acta (id_acta, id_proceso, id_mesa, motivo_duda, fecha_marca, id_usuario_marca)
  VALUES (p_id_acta, v_proceso, v_mesa, v_motivo, NOW(), p_id_usuario);

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'MARCAR_ACTA_DUDOSA',
       JSON_OBJECT('id_acta', p_id_acta, 'id_mesa', v_mesa, 'tipo', v_tipo));
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_marcar_ausentes` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_marcar_ausentes`(
  IN p_id_mesa    INT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_proceso  INT DEFAULT NULL;
  DECLARE v_cierre   VARCHAR(20) DEFAULT NULL;
  DECLARE v_marcados INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT m.id_proceso, c.estado INTO v_proceso, v_cierre
    FROM mesa_electoral m LEFT JOIN cierre_mesa c ON c.id_mesa = m.id_mesa
   WHERE m.id_mesa = p_id_mesa
     FOR UPDATE;
  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no existe.';
  END IF;
  IF v_cierre IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cierre primero el sufragio de la mesa.';
  END IF;
  IF v_cierre <> 'VOTACION_CERRADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF75: los electores que no votaron ya fueron marcados NO VOTO.';
  END IF;

  
  UPDATE padron_electoral SET no_voto = 1
   WHERE id_mesa = p_id_mesa AND habilitado_para_votar = 1 AND ya_voto = 0;

  SELECT COUNT(DISTINCT id_docente) INTO v_marcados
    FROM padron_electoral WHERE id_mesa = p_id_mesa AND no_voto = 1;

  UPDATE cierre_mesa
     SET estado = 'AUSENTES_MARCADOS', total_no_votaron = v_marcados,
         fecha_ausentes = NOW(), id_usuario_ausentes = p_id_usuario
   WHERE id_mesa = p_id_mesa;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'MARCAR_NO_VOTO',
       JSON_OBJECT('id_mesa', p_id_mesa, 'marcados', v_marcados));
  COMMIT;

  SELECT p_id_mesa AS id_mesa, v_marcados AS marcados;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_marcar_mesas_no_instaladas` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_marcar_mesas_no_instaladas`()
BEGIN
  DECLARE v_fin      INT DEFAULT 0;
  DECLARE v_proceso  INT;
  DECLARE v_abierta  INT DEFAULT 0;
  DECLARE v_vencida  INT DEFAULT 0;
  DECLARE v_control  INT DEFAULT 1;
  DECLARE v_msg      VARCHAR(255);
  DECLARE v_motivo   VARCHAR(255);
  DECLARE v_total    INT DEFAULT 0;
  DECLARE cur CURSOR FOR
    SELECT DISTINCT p.id_proceso
      FROM proceso_electoral p JOIN mesa_electoral m ON m.id_proceso = p.id_proceso
     WHERE p.estado = 'VOTACION' AND m.estado = 'PENDIENTE';
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = 1;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  OPEN cur;
  procesos: LOOP
    FETCH cur INTO v_proceso;
    IF v_fin = 1 THEN
      LEAVE procesos;
    END IF;
    CALL sp_ventana_instalacion(v_proceso, v_abierta, v_vencida, v_control, v_msg);
    IF v_control = 1 AND v_vencida = 1 THEN
      SET v_motivo = CONCAT('RF58: la mesa no se instaló dentro del plazo (', TIME_FORMAT(
              SEC_TO_TIME(ROUND(COALESCE((SELECT CAST(valor AS DECIMAL(6,2)) FROM parametro_global
                                           WHERE clave = 'INSTALACION_HORA_LIMITE'), 12) * 3600)), '%H:%i'),
              '). Registro automático del sistema.');
      START TRANSACTION;
      UPDATE miembro_mesa mm JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
         SET mm.asistio = COALESCE(mm.asistio, 0), mm.rol_instalacion = NULL
       WHERE m.id_proceso = v_proceso AND m.estado = 'PENDIENTE';
      INSERT INTO instalacion_mesa (id_mesa, estado, motivo_no_instalacion, automatica, fecha_actualizacion)
      SELECT m.id_mesa, 'NO_INSTALADA', v_motivo, TRUE, NOW()
        FROM mesa_electoral m WHERE m.id_proceso = v_proceso AND m.estado = 'PENDIENTE'
      ON DUPLICATE KEY UPDATE estado = 'NO_INSTALADA', motivo_no_instalacion = VALUES(motivo_no_instalacion),
                              automatica = TRUE, fecha_actualizacion = NOW();
      INSERT INTO log_auditoria (id_usuario, id_docente, id_proceso, accion, detalle_json)
      SELECT NULL, NULL, v_proceso, 'MESA_NO_INSTALADA', JSON_OBJECT('id_mesa', m.id_mesa, 'automatica', TRUE)
        FROM mesa_electoral m WHERE m.id_proceso = v_proceso AND m.estado = 'PENDIENTE';
      UPDATE mesa_electoral SET estado = 'NO_INSTALADA'
       WHERE id_proceso = v_proceso AND estado = 'PENDIENTE';
      SET v_total = v_total + ROW_COUNT();
      COMMIT;
    END IF;
  END LOOP;
  CLOSE cur;

  SELECT v_total AS mesas_marcadas;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_notificar_multas` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_notificar_multas`(
  IN p_id_proceso INT,
  IN p_id_multa   INT,
  IN p_id_usuario INT,
  IN p_medio      VARCHAR(25),
  IN p_documento  VARCHAR(80),
  IN p_fecha      DATETIME
)
BEGIN
  DECLARE v_rep_est VARCHAR(10) DEFAULT NULL;
  DECLARE v_fecha_r DATETIME;
  DECLARE v_medio   VARCHAR(25);
  DECLARE v_doc     VARCHAR(80);
  DECLARE v_fecha   DATETIME;
  DECLARE v_proc_m  INT DEFAULT NULL;
  DECLARE v_notif   DATETIME;
  DECLARE v_n       INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT estado, fecha_resolucion INTO v_rep_est, v_fecha_r FROM reporte_multas WHERE id_proceso = p_id_proceso;
  IF v_rep_est IS NULL OR v_rep_est <> 'RESUELTO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: se notifican las multas determinadas por la resolución del CEUNP.';
  END IF;
  SET v_medio = UPPER(TRIM(p_medio));
  IF v_medio IS NULL OR v_medio NOT IN ('CORREO_INSTITUCIONAL','CEDULA_PERSONAL','PORTAL_ELECTORAL') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: el medio de notificación es correo institucional, cédula personal o portal electoral.';
  END IF;
  SET v_doc = NULLIF(TRIM(p_documento), '');
  IF v_medio = 'CEDULA_PERSONAL' AND (v_doc IS NULL OR CHAR_LENGTH(v_doc) < 3) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: indique el número de la cédula de notificación.';
  END IF;
  SET v_fecha = COALESCE(p_fecha, NOW());
  IF v_fecha > NOW() + INTERVAL 5 MINUTE OR v_fecha < v_fecha_r - INTERVAL 1 MINUTE THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: la fecha de notificación va desde la resolución hasta hoy.';
  END IF;

  IF p_id_multa IS NOT NULL THEN
    SELECT id_proceso, fecha_notificacion INTO v_proc_m, v_notif FROM multa WHERE id_multa = p_id_multa FOR UPDATE;
    IF v_proc_m IS NULL OR v_proc_m <> p_id_proceso THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La multa no pertenece al proceso.';
    END IF;
    IF v_notif IS NOT NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: la multa ya fue notificada.';
    END IF;
  END IF;

  UPDATE multa
     SET fecha_notificacion = v_fecha, medio_notificacion = v_medio, documento_notificacion = v_doc,
         fecha_actualizacion = NOW(), id_usuario_actualizacion = p_id_usuario
   WHERE id_proceso = p_id_proceso AND fecha_notificacion IS NULL
     AND (p_id_multa IS NULL OR id_multa = p_id_multa);
  SET v_n = ROW_COUNT();
  IF v_n = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: no hay multas por notificar.';
  END IF;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'NOTIFICAR_MULTAS',
       JSON_OBJECT('id_multa', p_id_multa, 'notificadas', v_n, 'medio', v_medio, 'documento', v_doc));
  COMMIT;

  SELECT v_n AS notificadas;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_obtener_votos_estudiantiles` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_obtener_votos_estudiantiles`(
  IN p_id_proceso INT
)
BEGIN
  SELECT ce.id_proceso, ce.id_cargo, ce.id_lista, l.nombre AS lista, ce.votos_estudiantes, ce.fecha_registro
    FROM computo_estudiantil ce
    JOIN lista_electoral l ON l.id_lista = ce.id_lista
   WHERE ce.id_proceso = p_id_proceso
   ORDER BY ce.id_cargo, l.orden_cedula;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_presentar_tacha` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_presentar_tacha`(
  IN  p_id_docente_denunciante INT,
  IN  p_id_candidato INT,
  IN  p_motivo       TEXT,
  OUT p_id_tacha     INT
)
BEGIN
  DECLARE v_proceso INT DEFAULT NULL;
  DECLARE v_estado  VARCHAR(20) DEFAULT NULL;
  DECLARE v_limite  DATETIME DEFAULT NULL;
  DECLARE v_doc_est VARCHAR(20) DEFAULT NULL;
  DECLARE v_cand_docente INT DEFAULT NULL;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT p.id_proceso, p.estado, p.fecha_limite_inscripcion, ca.id_docente
    INTO v_proceso, v_estado, v_limite, v_cand_docente
    FROM candidato ca
    JOIN lista_electoral l   ON l.id_lista = ca.id_lista
    JOIN cargo_electoral c   ON c.id_cargo = l.id_cargo
    JOIN proceso_electoral p ON p.id_proceso = c.id_proceso
   WHERE ca.id_candidato = p_id_candidato;

  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El candidato no existe.';
  END IF;
  IF v_estado <> 'INSCRIPCION' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Las tachas solo se presentan en etapa de INSCRIPCION.';
  END IF;
  IF v_limite IS NOT NULL AND NOW() > v_limite THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Vencio el plazo para presentar tachas en este proceso electoral (RN13).';
  END IF;

  SELECT estado INTO v_doc_est FROM docente WHERE id_docente = p_id_docente_denunciante;
  IF v_doc_est IS NULL OR v_doc_est <> 'ACTIVO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo un docente ACTIVO del padron puede presentar tachas.';
  END IF;
  IF v_cand_docente = p_id_docente_denunciante THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un candidato no puede tacharse a si mismo.';
  END IF;
  IF p_motivo IS NULL OR TRIM(p_motivo) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La tacha debe estar fundamentada por escrito.';
  END IF;

  INSERT INTO tacha (id_docente_denunciante, id_candidato, motivo)
  VALUES (p_id_docente_denunciante, p_id_candidato, p_motivo);
  SET p_id_tacha = LAST_INSERT_ID();

  CALL sp_registrar_auditoria(NULL, p_id_docente_denunciante, v_proceso, 'PRESENTAR_TACHA',
       JSON_OBJECT('id_tacha', p_id_tacha, 'id_candidato', p_id_candidato));
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_proclamar_resultados` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_proclamar_resultados`(
  IN p_id_proceso        INT,
  IN p_id_usuario        INT,
  IN p_numero_resolucion VARCHAR(40),
  IN p_miembros_pleno    INT,
  IN p_presidente        VARCHAR(150),
  IN p_fundamento        VARCHAR(1000)
)
BEGIN
  DECLARE v_comp     VARCHAR(20) DEFAULT NULL;
  DECLARE v_estado   VARCHAR(20);
  DECLARE v_nombre   VARCHAR(200);
  DECLARE v_res      VARCHAR(40);
  DECLARE v_pres     VARCHAR(150);
  DECLARE v_quorum   INT;
  DECLARE v_hash_c   CHAR(64);
  DECLARE v_ahora    DATETIME;
  DECLARE v_procl    LONGTEXT;
  DECLARE v_sin      LONGTEXT;
  DECLARE v_contenido LONGTEXT;
  DECLARE v_token    CHAR(64);
  DECLARE v_n        INT DEFAULT 0;
  DECLARE v_msg      VARCHAR(255);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET SESSION group_concat_max_len = 1000000;
  START TRANSACTION;
  SELECT cp.estado, p.estado, p.nombre, cp.hash_integridad INTO v_comp, v_estado, v_nombre, v_hash_c
    FROM computo_proceso cp JOIN proceso_electoral p ON p.id_proceso = cp.id_proceso
   WHERE cp.id_proceso = p_id_proceso
     FOR UPDATE;
  IF v_comp IS NULL OR v_comp = 'SESION_INSTALADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF98: realice primero el cómputo oficial.';
  END IF;
  IF v_comp IN ('PROCLAMADO','PUBLICADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF98: los resultados ya fueron proclamados.';
  END IF;
  IF v_estado = 'ANULADO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A1 (RN31): la elección fue declarada nula; no hay resultados que proclamar. Publique el acta general.';
  END IF;
  SET v_res = NULLIF(TRIM(p_numero_resolucion), '');
  IF v_res IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF98: indique el número de la resolución de proclamación.';
  END IF;
  IF EXISTS (SELECT 1 FROM computo_proceso WHERE numero_resolucion = v_res)
     OR EXISTS (SELECT 1 FROM calificacion_mesa WHERE numero_resolucion = v_res)
     OR EXISTS (SELECT 1 FROM impugnacion_electoral WHERE numero_resolucion = v_res) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;
  SET v_quorum = COALESCE(ROUND((SELECT CAST(valor AS DECIMAL(6,2)) FROM parametro_global WHERE clave = 'CEUNP_QUORUM_PLENO')), 5);
  IF p_miembros_pleno IS NULL OR p_miembros_pleno < v_quorum OR p_miembros_pleno > 9 THEN
    SET v_msg = CONCAT('RN36: el Pleno del CEUNP proclama con quórum de ', v_quorum, ' de sus 9 miembros.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  SET v_pres = NULLIF(TRIM(p_presidente), '');
  IF v_pres IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF98: indique el nombre del Presidente del CEUNP que proclama.';
  END IF;

  SET v_ahora = NOW();
  
  INSERT INTO proclamacion_cargo (id_cargo, id_proceso, id_lista, votos, porcentaje_validos, codigo_credencial, fecha_proclamacion)
  SELECT c.id_cargo, c.id_proceso, c.id_lista_ganadora, r.total_votos, r.porcentaje_validos,
         UPPER(LEFT(SHA2(CONCAT(c.id_cargo, '|', c.id_lista_ganadora, '|', v_res, '|', HEX(fn_bytes_aleatorios(16))), 256), 12)), v_ahora
    FROM cargo_electoral c
    JOIN resultado_electoral r ON r.id_cargo = c.id_cargo AND r.id_lista = c.id_lista_ganadora AND r.tipo_voto = 'VALIDO'
   WHERE c.id_proceso = p_id_proceso AND c.estado_resultado = 'ELEGIDO';
  SET v_n = ROW_COUNT();

  SELECT CONCAT('[', GROUP_CONCAT(CONCAT('{"id_cargo":', pc.id_cargo,
                                         ',"cargo":', JSON_QUOTE(c.nombre),
                                         ',"id_lista":', pc.id_lista,
                                         ',"lista":', JSON_QUOTE(l.nombre),
                                         ',"votos":', pc.votos,
                                         ',"porcentaje":', COALESCE(pc.porcentaje_validos, 0),
                                         ',"codigo_credencial":', JSON_QUOTE(pc.codigo_credencial),
                                         ',"candidatos":[',
                                         COALESCE((SELECT GROUP_CONCAT(JSON_OBJECT('rol', ca.rol_en_lista,
                                                                  'nombre', CONCAT(d.nombres, ' ', d.apellidos), 'dni', d.dni)
                                                          ORDER BY ca.id_candidato SEPARATOR ',')
                                                     FROM candidato ca JOIN docente d ON d.id_docente = ca.id_docente
                                                    WHERE ca.id_lista = pc.id_lista AND ca.estado_validacion = 'APROBADO'), ''),
                                         ']}') ORDER BY pc.id_cargo SEPARATOR ','), ']')
    INTO v_procl
    FROM proclamacion_cargo pc
    JOIN cargo_electoral c ON c.id_cargo = pc.id_cargo
    JOIN lista_electoral l ON l.id_lista = pc.id_lista
   WHERE pc.id_proceso = p_id_proceso;

  SELECT CONCAT('[', GROUP_CONCAT(JSON_OBJECT('id_cargo', c.id_cargo, 'cargo', c.nombre,
                                              'estado_resultado', CONCAT(c.estado_resultado, ''))
                                  ORDER BY c.id_cargo SEPARATOR ','), ']')
    INTO v_sin
    FROM cargo_electoral c
   WHERE c.id_proceso = p_id_proceso AND c.estado_resultado <> 'ELEGIDO';

  SET v_contenido = CONCAT(
      '{"tipo":"PROCLAMACION"',
      ',"id_proceso":', p_id_proceso,
      ',"proceso":', JSON_QUOTE(v_nombre),
      ',"resolucion":', JSON_QUOTE(v_res),
      ',"fecha":', JSON_QUOTE(DATE_FORMAT(v_ahora, '%Y-%m-%d %H:%i:%s')),
      ',"presidente_ceunp":', JSON_QUOTE(v_pres),
      ',"miembros_pleno":', p_miembros_pleno,
      ',"hash_acta_general":', JSON_QUOTE(v_hash_c),
      ',"proclamados":', COALESCE(v_procl, '[]'),
      ',"sin_proclamar":', COALESCE(v_sin, '[]'),
      ',"fundamento":', IF(NULLIF(TRIM(p_fundamento), '') IS NULL, 'null', JSON_QUOTE(TRIM(p_fundamento))),
      '}');
  SET v_token = LOWER(HEX(fn_bytes_aleatorios(32)));

  UPDATE computo_proceso
     SET estado = 'PROCLAMADO', numero_resolucion = v_res, miembros_pleno = p_miembros_pleno, presidente_ceunp = v_pres,
         fundamento_proclamacion = NULLIF(TRIM(p_fundamento), ''), fecha_proclamacion = v_ahora,
         contenido_proclamacion = v_contenido, hash_proclamacion = SHA2(v_contenido, 256),
         token_proclamacion_hash = SHA2(v_token, 256), id_usuario_proclamacion = p_id_usuario
   WHERE id_proceso = p_id_proceso;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'PROCLAMAR_RESULTADOS',
       JSON_OBJECT('resolucion', v_res, 'cargos_proclamados', v_n));
  COMMIT;

  SELECT p_id_proceso AS id_proceso, v_res AS numero_resolucion, v_n AS cargos_proclamados, v_token AS token_qr;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_publicar_resultados` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_publicar_resultados`(
  IN p_id_proceso INT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_comp   VARCHAR(20) DEFAULT NULL;
  DECLARE v_estado VARCHAR(20);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT cp.estado, p.estado INTO v_comp, v_estado
    FROM computo_proceso cp JOIN proceso_electoral p ON p.id_proceso = cp.id_proceso
   WHERE cp.id_proceso = p_id_proceso
     FOR UPDATE;
  IF v_comp IS NULL OR v_comp = 'SESION_INSTALADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF99: los resultados se publican después del cómputo oficial.';
  END IF;
  IF v_comp = 'PUBLICADO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF99: los resultados ya están publicados en el portal.';
  END IF;
  IF v_comp = 'COMPUTADO' AND v_estado <> 'ANULADO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF99: proclame primero los resultados (RF98).';
  END IF;

  UPDATE computo_proceso SET estado = 'PUBLICADO', fecha_publicacion = NOW(), id_usuario_publicacion = p_id_usuario
   WHERE id_proceso = p_id_proceso;

  
  UPDATE usuario u
    JOIN personero pe ON pe.id_docente = u.id_docente
    JOIN lista_electoral l ON l.id_lista = pe.id_lista
    JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
     SET u.rol = 'DOCENTE'
   WHERE c.id_proceso = p_id_proceso AND u.rol = 'PERSONERO';

  UPDATE usuario u
    JOIN miembro_mesa mm ON mm.id_docente = u.id_docente
    JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
     SET u.rol = 'DOCENTE'
   WHERE m.id_proceso = p_id_proceso AND u.rol = 'MIEMBRO_MESA';

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'PUBLICAR_RESULTADOS',
       JSON_OBJECT('estado_proceso', v_estado));
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_asistencia_miembro` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_asistencia_miembro`(
  IN p_id_mesa    INT,
  IN p_id_docente INT,
  IN p_asistio    BOOLEAN
)
BEGIN
  UPDATE miembro_mesa SET asistio = p_asistio
   WHERE id_mesa = p_id_mesa AND id_docente = p_id_docente;
  IF ROW_COUNT() = 0 AND NOT EXISTS (SELECT 1 FROM miembro_mesa
                                      WHERE id_mesa = p_id_mesa AND id_docente = p_id_docente) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El docente no es miembro de esa mesa.';
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_auditoria` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_auditoria`(
  IN p_id_usuario INT,
  IN p_id_docente INT,
  IN p_id_proceso INT,
  IN p_accion     VARCHAR(100),
  IN p_detalle_json LONGTEXT
)
BEGIN
  INSERT INTO log_auditoria (id_usuario, id_docente, id_proceso, accion, detalle_json)
  VALUES (p_id_usuario, p_id_docente, p_id_proceso, p_accion, p_detalle_json);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_comunicacion_nulidad` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_comunicacion_nulidad`(
  IN p_id_nulidad   INT,
  IN p_id_usuario   INT,
  IN p_destinatario VARCHAR(25),
  IN p_documento    VARCHAR(80),
  IN p_fecha_envio  DATETIME,
  IN p_observacion  VARCHAR(500)
)
BEGIN
  DECLARE v_proceso INT DEFAULT NULL;
  DECLARE v_estado  VARCHAR(12);
  DECLARE v_fecha_r DATETIME;
  DECLARE v_dest    VARCHAR(25);
  DECLARE v_doc     VARCHAR(80);
  DECLARE v_fecha   DATETIME;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT id_proceso, estado, fecha_resolucion INTO v_proceso, v_estado, v_fecha_r
    FROM nulidad_electoral WHERE id_nulidad = p_id_nulidad FOR UPDATE;
  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El recurso de nulidad no existe.';
  END IF;
  IF v_estado <> 'FUNDADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF102: solo se comunica una nulidad declarada (FUNDADA).';
  END IF;
  SET v_dest = UPPER(TRIM(p_destinatario));
  IF v_dest IS NULL OR v_dest NOT IN ('SUNEDU','ASAMBLEA_UNIVERSITARIA','CONSEJO_UNIVERSITARIO','PORTAL','EL_PERUANO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF102: destinatario no válido (SUNEDU, Asamblea Universitaria, Consejo Universitario, portal o El Peruano).';
  END IF;
  IF EXISTS (SELECT 1 FROM nulidad_comunicacion WHERE id_nulidad = p_id_nulidad AND destinatario = v_dest) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF102: la comunicación a ese destinatario ya fue registrada.';
  END IF;
  SET v_doc = COALESCE(NULLIF(TRIM(p_documento), ''), IF(v_dest = 'PORTAL', 'Portal electoral', NULL));
  IF v_doc IS NULL OR CHAR_LENGTH(v_doc) < 3 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF102: indique el número del oficio o la edición de la publicación.';
  END IF;
  SET v_fecha = COALESCE(p_fecha_envio, NOW());
  IF v_fecha > NOW() + INTERVAL 5 MINUTE OR v_fecha < v_fecha_r - INTERVAL 1 MINUTE THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF102: la fecha de envío va desde la resolución hasta hoy.';
  END IF;

  INSERT INTO nulidad_comunicacion (id_nulidad, destinatario, documento, fecha_envio, observacion, id_usuario)
  VALUES (p_id_nulidad, v_dest, v_doc, v_fecha, NULLIF(TRIM(p_observacion), ''), p_id_usuario);

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'REGISTRAR_COMUNICACION_NULIDAD',
       JSON_OBJECT('id_nulidad', p_id_nulidad, 'destinatario', v_dest, 'documento', v_doc));
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_conteo` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_conteo`(
  IN p_id_mesa    INT,
  IN p_id_usuario INT,
  IN p_conteo     LONGTEXT
)
BEGIN
  DECLARE v_proceso   INT DEFAULT NULL;
  DECLARE v_esc       VARCHAR(20) DEFAULT NULL;
  DECLARE v_escrutadas INT DEFAULT 0;
  DECLARE v_faltantes INT DEFAULT 0;
  DECLARE v_veces     INT DEFAULT 0;
  DECLARE v_n         INT DEFAULT 0;
  DECLARE v_i         INT DEFAULT 0;
  DECLARE v_cargo     INT;
  DECLARE v_opcion    VARCHAR(12);
  DECLARE v_lista     INT;
  DECLARE v_votos_txt VARCHAR(40);
  DECLARE v_votos     INT;
  DECLARE v_mal       INT DEFAULT 0;
  DECLARE v_cuadra    INT DEFAULT 1;
  DECLARE v_total_ok  INT DEFAULT 1;
  DECLARE v_msg       VARCHAR(255);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  CREATE TEMPORARY TABLE IF NOT EXISTS tmp_conteo_cus12 (
    id_cargo INT NOT NULL, opcion VARCHAR(12) NOT NULL, id_lista INT NULL, votos INT NOT NULL,
    clave INT NOT NULL, UNIQUE KEY (id_cargo, opcion, clave)) ENGINE=MEMORY;
  CREATE TEMPORARY TABLE IF NOT EXISTS tmp_cargos_cus12 (
    id_cargo INT PRIMARY KEY, votantes INT NOT NULL, impugnaciones INT NOT NULL,
    votos_manuales INT NOT NULL DEFAULT 0, faltan_digital INT NOT NULL DEFAULT 0, sobran_manual INT NOT NULL DEFAULT 0,
    impugnados INT NOT NULL DEFAULT 0) ENGINE=MEMORY;
  DELETE FROM tmp_conteo_cus12;
  DELETE FROM tmp_cargos_cus12;

  START TRANSACTION;

  SELECT m.id_proceso, e.estado, e.cedulas_escrutadas, e.cedulas_faltantes, e.veces_conteo
    INTO v_proceso, v_esc, v_escrutadas, v_faltantes, v_veces
    FROM mesa_electoral m LEFT JOIN escrutinio_mesa e ON e.id_mesa = m.id_mesa
   WHERE m.id_mesa = p_id_mesa
     FOR UPDATE;
  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no existe.';
  END IF;
  IF v_esc IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF77: cuente primero las cédulas del ánfora.';
  END IF;
  IF v_esc NOT IN ('CEDULAS_CONTADAS','CONTEO_REGISTRADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el acta de escrutinio ya fue emitida; el conteo no cambia.';
  END IF;

  IF p_conteo IS NULL OR JSON_VALID(p_conteo) = 0 OR JSON_TYPE(p_conteo) <> 'ARRAY' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El conteo manual no es válido.';
  END IF;

  
  INSERT INTO tmp_cargos_cus12 (id_cargo, votantes, impugnaciones)
  SELECT pe.id_cargo, SUM(pe.ya_voto),
         (SELECT COUNT(*) FROM impugnacion_electoral i WHERE i.id_mesa = p_id_mesa AND i.id_cargo = pe.id_cargo)
    FROM padron_electoral pe
   WHERE pe.id_mesa = p_id_mesa AND pe.habilitado_para_votar = 1
   GROUP BY pe.id_cargo;

  
  SET v_n = JSON_LENGTH(p_conteo);
  WHILE v_i < v_n DO
    SET v_cargo = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_conteo, CONCAT('$[', v_i, '].id_cargo'))) AS UNSIGNED);
    SET v_opcion = UPPER(JSON_UNQUOTE(JSON_EXTRACT(p_conteo, CONCAT('$[', v_i, '].opcion'))));
    SET v_lista = NULLIF(NULLIF(JSON_UNQUOTE(JSON_EXTRACT(p_conteo, CONCAT('$[', v_i, '].id_lista'))), 'null'), '');
    SET v_votos_txt = JSON_UNQUOTE(JSON_EXTRACT(p_conteo, CONCAT('$[', v_i, '].votos')));
    IF v_votos_txt IS NULL OR v_votos_txt NOT REGEXP '^[0-9]{1,6}$' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF79: cada opción lleva una cantidad de votos entera y no negativa.';
    END IF;
    SET v_votos = CAST(v_votos_txt AS UNSIGNED);
    IF v_cargo IS NULL OR NOT EXISTS (SELECT 1 FROM tmp_cargos_cus12 WHERE id_cargo = v_cargo) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El conteo incluye un cargo que no se vota en esta mesa.';
    END IF;
    IF v_opcion IS NULL OR v_opcion NOT IN ('LISTA','BLANCO','NULO','IMPUGNADO') THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF79: la opción debe ser LISTA, BLANCO, NULO o IMPUGNADO.';
    END IF;
    IF v_opcion = 'LISTA' THEN
      IF v_lista IS NULL OR NOT EXISTS (SELECT 1 FROM lista_electoral
                                          WHERE id_lista = v_lista AND id_cargo = v_cargo AND estado = 'ADMITIDA') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El conteo incluye una lista que no está ADMITIDA para el cargo.';
      END IF;
    ELSE
      SET v_lista = NULL;
    END IF;
    IF EXISTS (SELECT 1 FROM tmp_conteo_cus12 WHERE id_cargo = v_cargo AND opcion = v_opcion AND clave = COALESCE(v_lista, 0)) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El conteo repite una opción del mismo cargo.';
    END IF;
    INSERT INTO tmp_conteo_cus12 (id_cargo, opcion, id_lista, votos, clave)
    VALUES (v_cargo, v_opcion, v_lista, v_votos, COALESCE(v_lista, 0));
    SET v_i = v_i + 1;
  END WHILE;

  IF EXISTS (SELECT 1 FROM tmp_cargos_cus12 c
              WHERE NOT EXISTS (SELECT 1 FROM tmp_conteo_cus12 t WHERE t.id_cargo = c.id_cargo)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF79: registre el conteo de todos los cargos de la mesa.';
  END IF;

  
  DELETE FROM escrutinio_conteo WHERE id_mesa = p_id_mesa;

  INSERT INTO escrutinio_conteo (id_mesa, id_cargo, opcion, id_lista, votos_manual, votos_digital)
  SELECT p_id_mesa, c.id_cargo, 'LISTA', l.id_lista,
         COALESCE((SELECT t.votos FROM tmp_conteo_cus12 t WHERE t.id_cargo = c.id_cargo AND t.opcion = 'LISTA' AND t.clave = l.id_lista), 0),
         (SELECT COUNT(*) FROM voto v WHERE v.id_mesa = p_id_mesa AND v.id_cargo = c.id_cargo
                                         AND v.tipo_voto = 'VALIDO' AND v.id_lista_elegida = l.id_lista)
    FROM tmp_cargos_cus12 c
    JOIN lista_electoral l ON l.id_cargo = c.id_cargo
   WHERE l.estado = 'ADMITIDA'
      OR EXISTS (SELECT 1 FROM voto v WHERE v.id_mesa = p_id_mesa AND v.id_lista_elegida = l.id_lista);

  INSERT INTO escrutinio_conteo (id_mesa, id_cargo, opcion, id_lista, votos_manual, votos_digital)
  SELECT p_id_mesa, c.id_cargo, o.opcion, NULL,
         COALESCE((SELECT t.votos FROM tmp_conteo_cus12 t WHERE t.id_cargo = c.id_cargo AND t.opcion = o.opcion), 0),
         IF(o.opcion = 'IMPUGNADO', 0,
            (SELECT COUNT(*) FROM voto v WHERE v.id_mesa = p_id_mesa AND v.id_cargo = c.id_cargo AND v.tipo_voto = o.opcion))
    FROM tmp_cargos_cus12 c
    CROSS JOIN (SELECT 'BLANCO' AS opcion UNION ALL SELECT 'NULO' UNION ALL SELECT 'IMPUGNADO') o;

  
  UPDATE tmp_cargos_cus12 c
     SET c.votos_manuales = (SELECT COALESCE(SUM(k.votos_manual), 0) FROM escrutinio_conteo k
                      WHERE k.id_mesa = p_id_mesa AND k.id_cargo = c.id_cargo),
         c.impugnados = (SELECT COALESCE(SUM(k.votos_manual), 0) FROM escrutinio_conteo k
                          WHERE k.id_mesa = p_id_mesa AND k.id_cargo = c.id_cargo AND k.opcion = 'IMPUGNADO'),
         c.faltan_digital = (SELECT COALESCE(SUM(GREATEST(k.votos_digital - k.votos_manual, 0)), 0) FROM escrutinio_conteo k
                              WHERE k.id_mesa = p_id_mesa AND k.id_cargo = c.id_cargo AND k.opcion <> 'IMPUGNADO'),
         c.sobran_manual = (SELECT COALESCE(SUM(GREATEST(k.votos_manual - k.votos_digital, 0)), 0) FROM escrutinio_conteo k
                             WHERE k.id_mesa = p_id_mesa AND k.id_cargo = c.id_cargo AND k.opcion <> 'IMPUGNADO');

  
  SELECT COUNT(*) INTO v_mal FROM tmp_cargos_cus12 WHERE votos_manuales > v_escrutadas;
  IF v_mal > 0 THEN
    SET v_msg = CONCAT('RF79: un cargo suma más votos que las ', v_escrutadas, ' cédulas escrutadas. Revise el conteo.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  
  SELECT COUNT(*) INTO v_mal FROM tmp_cargos_cus12 WHERE impugnados <> impugnaciones;
  IF v_mal > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A4: los votos impugnados deben coincidir con las impugnaciones registradas de cada cargo.';
  END IF;

  
  
  SELECT IF(COUNT(*) = 0, 1, 0) INTO v_cuadra FROM tmp_cargos_cus12
   WHERE sobran_manual > 0 OR faltan_digital - impugnados < 0 OR faltan_digital - impugnados > v_faltantes;
  SELECT IF(COUNT(*) = 0, 1, 0) INTO v_total_ok FROM tmp_cargos_cus12 WHERE votos_manuales <> votantes;

  UPDATE escrutinio_mesa
     SET estado = 'CONTEO_REGISTRADO', veces_conteo = v_veces + 1, conteo_cuadra = v_cuadra,
         total_cuadra = v_total_ok, fecha_conteo = NOW(), id_usuario_conteo = p_id_usuario
   WHERE id_mesa = p_id_mesa;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'REGISTRAR_CONTEO_ESCRUTINIO',
       JSON_OBJECT('id_mesa', p_id_mesa, 'conteo', v_veces + 1, 'cuadra', v_cuadra, 'total_cuadra', v_total_ok));
  COMMIT;

  SELECT p_id_mesa AS id_mesa, v_cuadra AS conteo_cuadra, v_total_ok AS total_cuadra,
         v_veces + 1 AS veces_conteo;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_cotejo_acta` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_cotejo_acta`(
  IN p_codigo          VARCHAR(64),
  IN p_id_verificacion BIGINT,
  IN p_id_usuario      INT,
  IN p_cifras_json     LONGTEXT,
  IN p_observacion     VARCHAR(1000)
)
BEGIN
  DECLARE v_tipo     VARCHAR(30);
  DECLARE v_id       INT;
  DECLARE v_metodo   VARCHAR(6);
  DECLARE v_proceso  INT DEFAULT NULL;
  DECLARE v_mesa     INT DEFAULT NULL;
  DECLARE v_hash     CHAR(64) DEFAULT NULL;
  DECLARE v_calc     CHAR(64) DEFAULT NULL;
  DECLARE v_rol      VARCHAR(20) DEFAULT NULL;
  DECLARE v_docente  INT DEFAULT NULL;
  DECLARE v_pers     INT DEFAULT NULL;
  DECLARE v_n        INT;
  DECLARE v_i        INT DEFAULT 0;
  DECLARE v_dif      INT DEFAULT 0;
  DECLARE v_digital  VARCHAR(20);
  DECLARE v_fisico   VARCHAR(20);
  DECLARE v_obs      VARCHAR(1000);
  DECLARE v_integro  TINYINT;
  DECLARE v_estado   VARCHAR(10);
  DECLARE v_id_cot   INT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SELECT CONCAT(rol, ''), id_docente INTO v_rol, v_docente FROM usuario WHERE id_usuario = p_id_usuario AND activo = 1;
  IF v_rol IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: inicie sesión para cotejar el acta.';
  END IF;
  IF p_codigo IS NULL OR NOT (LOWER(TRIM(p_codigo)) REGEXP '^[0-9a-f]{64}$') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: el código del documento no es válido.';
  END IF;
  CALL sp_localizar_documento(LOWER(TRIM(p_codigo)), v_tipo, v_id, v_metodo);
  IF v_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: el documento no existe o el código no es válido.';
  END IF;
  IF v_tipo IN ('CONSTANCIA_VOTO','RESOLUCION_MULTAS') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: el cotejo de cifras se hace sobre las actas, el acta general y la resolución de proclamación.';
  END IF;

  IF v_tipo LIKE 'ACTA\_%' THEN
    SELECT m.id_proceso, a.id_mesa, a.hash_integridad, SHA2(a.contenido_json, 256)
      INTO v_proceso, v_mesa, v_hash, v_calc
      FROM acta_electoral a JOIN mesa_electoral m ON m.id_mesa = a.id_mesa WHERE a.id_acta = v_id;
  ELSEIF v_tipo = 'COMPUTO_GENERAL' THEN
    SELECT id_proceso, hash_integridad, SHA2(contenido_json, 256) INTO v_proceso, v_hash, v_calc
      FROM computo_proceso WHERE id_proceso = v_id;
  ELSEIF v_tipo = 'PROCLAMACION' THEN
    SELECT id_proceso, hash_proclamacion, SHA2(contenido_proclamacion, 256) INTO v_proceso, v_hash, v_calc
      FROM computo_proceso WHERE id_proceso = v_id;
  ELSE
    SELECT id_proceso, id_mesa, hash_integridad, SHA2(contenido_json, 256) INTO v_proceso, v_mesa, v_hash, v_calc
      FROM nulidad_electoral WHERE id_nulidad = v_id;
  END IF;
  SET v_integro = IF(v_calc <=> v_hash, 1, 0);

  
  IF p_cifras_json IS NULL OR JSON_VALID(p_cifras_json) = 0 OR JSON_TYPE(p_cifras_json) <> 'ARRAY' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: las cifras del cotejo no son válidas.';
  END IF;
  SET v_n = JSON_LENGTH(p_cifras_json);
  IF v_n = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: anote al menos una cifra del ejemplar físico.';
  END IF;
  WHILE v_i < v_n DO
    SET v_digital = JSON_UNQUOTE(JSON_EXTRACT(p_cifras_json, CONCAT('$[', v_i, '].digital')));
    SET v_fisico  = JSON_UNQUOTE(JSON_EXTRACT(p_cifras_json, CONCAT('$[', v_i, '].fisico')));
    IF v_digital IS NULL OR v_fisico IS NULL OR v_fisico = 'null'
       OR NOT (v_digital REGEXP '^[0-9]+(\\.[0-9]+)?$') OR NOT (v_fisico REGEXP '^[0-9]+(\\.[0-9]+)?$') THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: anote todas las cifras del ejemplar físico (números enteros, sin signo).';
    END IF;
    IF CAST(v_digital AS DECIMAL(14,2)) <> CAST(v_fisico AS DECIMAL(14,2)) THEN
      SET v_dif = v_dif + 1;
    END IF;
    SET v_i = v_i + 1;
  END WHILE;

  SET v_obs = NULLIF(TRIM(p_observacion), '');
  IF (v_dif > 0 OR v_integro = 0) AND (v_obs IS NULL OR CHAR_LENGTH(v_obs) < 10) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: describa la discrepancia (al menos 10 caracteres) para reportarla al CEUNP.';
  END IF;
  SET v_estado = IF(v_dif = 0 AND v_integro = 1, 'CONFORME', 'OBSERVADO');

  IF v_estado = 'OBSERVADO' AND EXISTS (SELECT 1 FROM cotejo_acta
                                         WHERE id_usuario = p_id_usuario AND tipo_documento = v_tipo
                                           AND id_documento = v_id AND estado = 'OBSERVADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: ya reportó una discrepancia sobre este documento; espere la respuesta del CEUNP.';
  END IF;

  
  IF v_docente IS NOT NULL THEN
    SELECT pe.id_personero INTO v_pers
      FROM personero pe
      JOIN lista_electoral l ON l.id_lista = pe.id_lista
      JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
     WHERE pe.id_docente = v_docente AND c.id_proceso = v_proceso AND pe.estado_acreditacion = 'ACREDITADO'
     ORDER BY (pe.id_mesa <=> v_mesa) DESC, pe.id_personero
     LIMIT 1;
  END IF;

  IF p_id_verificacion IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM verificacion_documento
                      WHERE id_verificacion = p_id_verificacion AND tipo_documento = v_tipo AND id_documento = v_id) THEN
    SET p_id_verificacion = NULL;
  END IF;

  START TRANSACTION;
  INSERT INTO cotejo_acta (id_verificacion, tipo_documento, id_documento, id_proceso, id_mesa, hash_integridad,
                           contenido_integro, id_usuario, rol, id_personero, cifras_json, lineas, diferencias,
                           observacion, estado, fecha)
  VALUES (p_id_verificacion, v_tipo, v_id, v_proceso, v_mesa, v_hash, v_integro, p_id_usuario, v_rol, v_pers,
          p_cifras_json, v_n, v_dif, v_obs, v_estado, NOW());
  SET v_id_cot = LAST_INSERT_ID();

  CALL sp_registrar_auditoria(p_id_usuario, v_docente, v_proceso,
       IF(v_estado = 'CONFORME', 'REGISTRAR_COTEJO_ACTA', 'REPORTAR_DISCREPANCIA_ACTA'),
       JSON_OBJECT('id_cotejo', v_id_cot, 'tipo', v_tipo, 'id_documento', v_id, 'id_mesa', v_mesa,
                   'lineas', v_n, 'diferencias', v_dif, 'contenido_integro', v_integro));
  COMMIT;

  SELECT v_id_cot AS id_cotejo, v_estado AS estado, v_tipo AS tipo_documento, v_id AS id_documento,
         v_proceso AS id_proceso, v_mesa AS id_mesa, v_n AS lineas, v_dif AS diferencias, v_integro AS contenido_integro;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_entrega_actas` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_entrega_actas`(
  IN p_id_mesa           INT,
  IN p_id_usuario        INT,
  IN p_recibido_por      VARCHAR(150),
  IN p_ejemplares        INT,
  IN p_copias_personeros INT,
  IN p_padron            BOOLEAN,
  IN p_material          BOOLEAN,
  IN p_observacion       VARCHAR(500)
)
BEGIN
  DECLARE v_proceso  INT DEFAULT NULL;
  DECLARE v_esc      VARCHAR(20) DEFAULT NULL;
  DECLARE v_numero   VARCHAR(30);
  DECLARE v_recibe   VARCHAR(150);
  DECLARE v_obs      VARCHAR(500);
  DECLARE v_codigo   CHAR(12);
  DECLARE v_ahora    DATETIME;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT m.id_proceso, m.numero_mesa, e.estado INTO v_proceso, v_numero, v_esc
    FROM mesa_electoral m LEFT JOIN escrutinio_mesa e ON e.id_mesa = m.id_mesa
   WHERE m.id_mesa = p_id_mesa
     FOR UPDATE;
  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no existe.';
  END IF;
  IF v_esc = 'ENTREGADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF87: las actas de esta mesa ya se entregaron al CEUNP.';
  END IF;
  IF v_esc IS NULL OR v_esc <> 'ACTA_EMITIDA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF87: emita primero el acta de escrutinio.';
  END IF;
  SET v_recibe = NULLIF(TRIM(p_recibido_por), '');
  IF v_recibe IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF87: indique quién recibe las actas por el CEUNP.';
  END IF;
  IF p_ejemplares IS NULL OR p_ejemplares <> 3 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF86 (RN28): se entregan los tres ejemplares del acta (CEUNP, ONPE y local de votación).';
  END IF;
  IF p_copias_personeros IS NOT NULL AND (p_copias_personeros < 0 OR p_copias_personeros > 50) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF86: cantidad de copias para personeros no válida.';
  END IF;
  SET v_obs = NULLIF(TRIM(p_observacion), '');
  IF (COALESCE(p_padron, 0) = 0 OR COALESCE(p_material, 0) = 0) AND v_obs IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF87: si no se entrega el padrón o el material, explique el motivo en la observación.';
  END IF;

  SET v_ahora = NOW();
  SET v_codigo = UPPER(LEFT(SHA2(CONCAT(p_id_mesa, '|', v_numero, '|', v_ahora, '|', HEX(fn_bytes_aleatorios(16))), 256), 12));

  UPDATE escrutinio_mesa
     SET estado = 'ENTREGADA', fecha_entrega = v_ahora, recibido_por = v_recibe, ejemplares = p_ejemplares,
         copias_personeros = COALESCE(p_copias_personeros, 0), entrega_padron = COALESCE(p_padron, 0),
         entrega_material = COALESCE(p_material, 0), observacion_entrega = v_obs, codigo_cargo = v_codigo,
         id_usuario_entrega = p_id_usuario
   WHERE id_mesa = p_id_mesa;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'ENTREGAR_ACTAS',
       JSON_OBJECT('id_mesa', p_id_mesa, 'recibido_por', v_recibe, 'codigo', v_codigo));
  COMMIT;

  SELECT p_id_mesa AS id_mesa, v_codigo AS codigo_cargo, v_ahora AS fecha_entrega;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_exportacion_bitacora` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_exportacion_bitacora`(IN p_id_admin INT, IN p_formato VARCHAR(10), IN p_registros INT,
                                                   IN p_filtros LONGTEXT, IN p_ip VARCHAR(45), IN p_user_agent VARCHAR(500))
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  CALL sp_validar_admin(p_id_admin);
  IF p_filtros IS NOT NULL AND NOT JSON_VALID(p_filtros) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS19: los filtros de la exportación no son un JSON válido.';
  END IF;

  START TRANSACTION;
  INSERT INTO log_auditoria (id_usuario, accion, ip_origen, user_agent, detalle_json)
  VALUES (p_id_admin, 'EXPORTAR_BITACORA', p_ip, LEFT(p_user_agent, 500),
          JSON_OBJECT('formato', p_formato, 'registros', p_registros,
                      'filtros', JSON_EXTRACT(COALESCE(p_filtros, '{}'), '$')));
  COMMIT;

  SELECT LAST_INSERT_ID() AS id_log;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_impugnacion` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_impugnacion`(
  IN  p_id_mesa      INT,
  IN  p_id_usuario   INT,
  IN  p_id_personero INT,
  IN  p_id_cargo     INT,
  IN  p_motivo       VARCHAR(1000),
  OUT p_id_impugnacion BIGINT
)
BEGIN
  DECLARE v_proceso INT DEFAULT NULL;
  DECLARE v_esc     VARCHAR(20) DEFAULT NULL;
  DECLARE v_motivo  VARCHAR(1000);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT m.id_proceso, e.estado INTO v_proceso, v_esc
    FROM mesa_electoral m LEFT JOIN escrutinio_mesa e ON e.id_mesa = m.id_mesa
   WHERE m.id_mesa = p_id_mesa
     FOR UPDATE;
  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no existe.';
  END IF;
  IF v_esc IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Las impugnaciones se registran durante el escrutinio: cuente primero las cédulas.';
  END IF;
  IF v_esc NOT IN ('CEDULAS_CONTADAS','CONTEO_REGISTRADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el acta de escrutinio ya fue emitida.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM asistencia_personero_mesa WHERE id_mesa = p_id_mesa AND id_personero = p_id_personero) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN24: solo impugna un personero presente en la mesa.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM padron_electoral WHERE id_mesa = p_id_mesa AND id_cargo = p_id_cargo) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cargo no se vota en esta mesa.';
  END IF;
  SET v_motivo = NULLIF(TRIM(p_motivo), '');
  IF v_motivo IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF80: indique el motivo de la impugnación.';
  END IF;

  INSERT INTO impugnacion_electoral (id_personero, id_proceso, id_mesa, id_cargo, motivo)
  VALUES (p_id_personero, v_proceso, p_id_mesa, p_id_cargo, v_motivo);
  SET p_id_impugnacion = LAST_INSERT_ID();

  
  UPDATE escrutinio_mesa SET estado = 'CEDULAS_CONTADAS', conteo_cuadra = NULL, total_cuadra = NULL
   WHERE id_mesa = p_id_mesa AND estado = 'CONTEO_REGISTRADO';

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'REGISTRAR_IMPUGNACION',
       JSON_OBJECT('id_mesa', p_id_mesa, 'id_impugnacion', p_id_impugnacion, 'id_cargo', p_id_cargo,
                   'id_personero', p_id_personero));
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_justificacion` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_justificacion`(
  IN p_id_multa           INT,
  IN p_id_usuario         INT,
  IN p_tipo               VARCHAR(15),
  IN p_causal             VARCHAR(20),
  IN p_sustento           VARCHAR(1000),
  IN p_documento          VARCHAR(150),
  IN p_fecha_presentacion DATETIME,
  IN p_decision           VARCHAR(10),
  IN p_fundamento         VARCHAR(1000),
  IN p_numero_resolucion  VARCHAR(40),
  IN p_miembros_pleno     INT
)
BEGIN
  DECLARE v_proceso  INT DEFAULT NULL;
  DECLARE v_docente  INT;
  DECLARE v_estado   VARCHAR(12);
  DECLARE v_notif    DATETIME;
  DECLARE v_rep_est  VARCHAR(10);
  DECLARE v_fecha_r  DATETIME;
  DECLARE v_tipo     VARCHAR(15);
  DECLARE v_causal   VARCHAR(20);
  DECLARE v_decision VARCHAR(10);
  DECLARE v_sustento VARCHAR(1000);
  DECLARE v_fund     VARCHAR(1000);
  DECLARE v_res      VARCHAR(40);
  DECLARE v_fecha    DATETIME;
  DECLARE v_plazo    INT;
  DECLARE v_quorum   INT;
  DECLARE v_nuevo    VARCHAR(12);
  DECLARE v_ahora    DATETIME;
  DECLARE v_id       INT;
  DECLARE v_msg      VARCHAR(255);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT id_proceso, id_docente, estado_pago, fecha_notificacion INTO v_proceso, v_docente, v_estado, v_notif
    FROM multa WHERE id_multa = p_id_multa FOR UPDATE;
  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La multa no existe.';
  END IF;
  SELECT estado, fecha_resolucion INTO v_rep_est, v_fecha_r FROM reporte_multas WHERE id_proceso = v_proceso;
  IF v_rep_est IS NULL OR v_rep_est <> 'RESUELTO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF106: la multa aún no ha sido determinada por resolución del CEUNP.';
  END IF;
  IF v_estado <> 'PENDIENTE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF106: solo se justifica o exonera una multa PENDIENTE.';
  END IF;

  SET v_tipo     = UPPER(TRIM(p_tipo));
  SET v_causal   = UPPER(TRIM(p_causal));
  SET v_decision = UPPER(TRIM(COALESCE(p_decision, IF(UPPER(TRIM(p_tipo)) = 'EXONERACION', 'ADMITIDA', NULL))));
  IF v_tipo IS NULL OR v_tipo NOT IN ('JUSTIFICACION','EXONERACION') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF106: el descargo es una JUSTIFICACION del docente o una EXONERACION de oficio.';
  END IF;
  IF v_causal IS NULL OR v_causal NOT IN ('SALUD','DUELO','COMISION_SERVICIO','LICENCIA','CASO_FORTUITO','FALLECIMIENTO','ERROR_PADRON','OTRA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF106: indique la causal del descargo.';
  END IF;
  IF v_decision IS NULL OR v_decision NOT IN ('ADMITIDA','DENEGADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF106: la decisión del CEUNP es ADMITIDA o DENEGADA.';
  END IF;
  IF v_tipo = 'EXONERACION' AND v_decision <> 'ADMITIDA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN40: la exoneración de oficio solo se registra cuando el CEUNP la concede.';
  END IF;
  SET v_sustento = NULLIF(TRIM(p_sustento), '');
  IF v_sustento IS NULL OR CHAR_LENGTH(v_sustento) < 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF106: describa el sustento del descargo (al menos 10 caracteres).';
  END IF;
  SET v_fund = NULLIF(TRIM(p_fundamento), '');
  IF v_fund IS NULL OR CHAR_LENGTH(v_fund) < 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: fundamente la decisión del CEUNP (al menos 10 caracteres).';
  END IF;
  SET v_res = NULLIF(TRIM(p_numero_resolucion), '');
  IF v_res IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el descargo se resuelve por resolución del CEUNP; indique su número.';
  END IF;
  IF fn_resolucion_en_uso(v_res) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;
  SET v_quorum = COALESCE(ROUND((SELECT CAST(valor AS DECIMAL(6,2)) FROM parametro_global WHERE clave = 'CEUNP_QUORUM_PLENO')), 5);
  IF p_miembros_pleno IS NULL OR p_miembros_pleno < v_quorum OR p_miembros_pleno > 9 THEN
    SET v_msg = CONCAT('RN36: el Pleno del CEUNP resuelve con quórum de ', v_quorum, ' de sus 9 miembros.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  SET v_ahora = NOW();
  SET v_fecha = COALESCE(p_fecha_presentacion, v_ahora);
  IF v_fecha > v_ahora + INTERVAL 5 MINUTE THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF106: la fecha de presentación no puede ser futura.';
  END IF;
  IF v_tipo = 'JUSTIFICACION' THEN
    IF EXISTS (SELECT 1 FROM multa_justificacion WHERE id_multa = p_id_multa AND tipo = 'JUSTIFICACION') THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: la justificación de esta multa ya fue resuelta; la decisión es inapelable.';
    END IF;
    SET v_plazo = COALESCE(ROUND((SELECT CAST(valor AS DECIMAL(8,2)) FROM parametro_global
                                   WHERE clave = 'MULTA_PLAZO_JUSTIFICACION_DIAS')), 10);
    IF v_plazo > 0 AND v_fecha > COALESCE(v_notif, v_fecha_r) + INTERVAL v_plazo DAY THEN
      SET v_msg = CONCAT('RF106: la justificación se presenta dentro de los ', v_plazo, ' días siguientes a la notificación.');
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
  END IF;

  
  INSERT INTO multa_justificacion (id_multa, tipo, causal, sustento, documento, fecha_presentacion, decision, fundamento,
                                   numero_resolucion, miembros_pleno, fecha_resolucion, id_usuario)
  VALUES (p_id_multa, v_tipo, v_causal, v_sustento, NULLIF(TRIM(p_documento), ''), v_fecha, v_decision, v_fund,
          v_res, p_miembros_pleno, v_ahora, p_id_usuario);
  SET v_id = LAST_INSERT_ID();

  
  SET v_nuevo = IF(v_decision = 'DENEGADA', 'PENDIENTE', IF(v_tipo = 'EXONERACION', 'EXONERADA', 'JUSTIFICADA'));
  UPDATE multa
     SET estado_pago = v_nuevo, fecha_actualizacion = v_ahora, id_usuario_actualizacion = p_id_usuario,
         observacion = LEFT(CONCAT(IF(v_decision = 'DENEGADA', 'Justificación denegada', IF(v_tipo = 'EXONERACION', 'Exonerada', 'Justificada')),
                                   ' por Resolución ', v_res, '.'), 300)
   WHERE id_multa = p_id_multa;

  CALL sp_registrar_auditoria(p_id_usuario, v_docente, v_proceso,
       CASE WHEN v_decision = 'DENEGADA' THEN 'DENEGAR_JUSTIFICACION'
            WHEN v_tipo = 'EXONERACION' THEN 'EXONERAR_MULTA' ELSE 'JUSTIFICAR_MULTA' END,
       JSON_OBJECT('id_multa', p_id_multa, 'id_justificacion', v_id, 'causal', v_causal, 'resolucion', v_res));
  COMMIT;

  
  SELECT v_id AS id_justificacion, p_id_multa AS id_multa, v_tipo AS tipo, v_decision AS decision,
         v_nuevo AS estado_pago, v_res AS numero_resolucion;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_nulidad` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_nulidad`(
  IN  p_id_proceso   INT,
  IN  p_id_usuario   INT,
  IN  p_alcance      VARCHAR(10),
  IN  p_id_mesa      INT,
  IN  p_causal       VARCHAR(30),
  IN  p_origen       VARCHAR(10),
  IN  p_id_personero INT,
  IN  p_sustento     VARCHAR(1000),
  IN  p_pruebas      VARCHAR(500),
  OUT p_id_nulidad   INT
)
BEGIN
  DECLARE v_estado    VARCHAR(20) DEFAULT NULL;
  DECLARE v_comp      VARCHAR(20) DEFAULT NULL;
  DECLARE v_resultado VARCHAR(15) DEFAULT NULL;
  DECLARE v_alcance   VARCHAR(10);
  DECLARE v_causal    VARCHAR(30);
  DECLARE v_origen    VARCHAR(10);
  DECLARE v_sustento  VARCHAR(1000);
  DECLARE v_mesa_proc INT DEFAULT NULL;
  DECLARE v_mesa_est  VARCHAR(20);
  DECLARE v_pers_tipo VARCHAR(10) DEFAULT NULL;
  DECLARE v_pers_mesa INT;
  DECLARE v_etapa     VARCHAR(15);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT estado INTO v_estado FROM proceso_electoral WHERE id_proceso = p_id_proceso FOR UPDATE;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;
  SELECT estado, resultado INTO v_comp, v_resultado FROM computo_proceso WHERE id_proceso = p_id_proceso;
  SET v_etapa = IF(v_comp IS NULL OR v_comp = 'SESION_INSTALADA', 'ANTES_COMPUTO', 'DESPUES_COMPUTO');

  SET v_alcance = UPPER(TRIM(p_alcance));
  SET v_causal  = UPPER(TRIM(p_causal));
  SET v_origen  = UPPER(TRIM(p_origen));
  IF v_alcance IS NULL OR v_alcance NOT IN ('PARCIAL','TOTAL') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN34: la nulidad es PARCIAL (una mesa) o TOTAL (la elección).';
  END IF;
  IF v_origen IS NULL OR v_origen NOT IN ('DE_OFICIO','PERSONERO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF101: la nulidad se declara de oficio o a pedido de un personero.';
  END IF;
  IF v_alcance = 'PARCIAL' AND (v_causal IS NULL OR v_causal NOT IN ('INSTALACION_IRREGULAR','FRAUDE_MESA','ADMISION_INDEBIDA','ACTA_NO_AUTENTICA','OTRA_CAUSAL')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF100: indique una causal de nulidad parcial del reglamento (Art. 64).';
  END IF;
  IF v_alcance = 'TOTAL' AND (v_causal IS NULL OR v_causal NOT IN ('FRAUDE','COHECHO','SOBORNO','INTIMIDACION','VIOLENCIA','PARTICIPACION_INSUFICIENTE')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF101: indique una causal de nulidad total del reglamento (Art. 65).';
  END IF;
  SET v_sustento = NULLIF(TRIM(p_sustento), '');
  IF v_sustento IS NULL OR CHAR_LENGTH(v_sustento) < 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF94: sustente el recurso de nulidad (al menos 10 caracteres).';
  END IF;

  IF v_alcance = 'PARCIAL' THEN
    
    IF v_estado <> 'CERRADO' OR v_etapa <> 'ANTES_COMPUTO' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF100: la nulidad parcial se plantea con la votación concluida y antes del cómputo (RN26).';
    END IF;
    SELECT id_proceso, estado INTO v_mesa_proc, v_mesa_est FROM mesa_electoral WHERE id_mesa = p_id_mesa FOR UPDATE;
    IF v_mesa_proc IS NULL OR v_mesa_proc <> p_id_proceso THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no pertenece al proceso.';
    END IF;
    IF v_mesa_est = 'ANULADA' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF100: la votación de esta mesa ya fue anulada.';
    END IF;
    IF v_mesa_est <> 'CERRADA' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF100: solo se anula la votación de una mesa que funcionó y cerró su sufragio (la mesa no instalada se evalúa en el CUS08, RF60).';
    END IF;
    IF EXISTS (SELECT 1 FROM nulidad_electoral WHERE id_mesa = p_id_mesa AND estado = 'PRESENTADA') THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF94: la mesa ya tiene un recurso de nulidad pendiente.';
    END IF;
  ELSE
    
    IF EXISTS (SELECT 1 FROM nulidad_electoral WHERE id_proceso = p_id_proceso AND alcance = 'TOTAL' AND estado IN ('PRESENTADA','FUNDADA')) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF101: el proceso ya tiene un recurso de nulidad total pendiente o declarado.';
    END IF;
    IF v_causal = 'PARTICIPACION_INSUFICIENTE' THEN
      IF v_resultado IS NULL OR v_resultado <> 'NULIDAD_TOTAL' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN31: la nulidad por participación la determina el cómputo oficial (A1 del CUS14).';
      END IF;
      IF v_origen <> 'DE_OFICIO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN31: la nulidad por falta de participación se declara de oficio.';
      END IF;
    ELSE
      IF v_estado = 'ANULADO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF101: la elección ya está anulada.';
      END IF;
      IF NOT (v_estado = 'CERRADO' OR (v_estado = 'FINALIZADO' AND v_comp = 'COMPUTADO')) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF101: la nulidad total se plantea con la votación concluida y antes de la proclamación (RF94).';
      END IF;
    END IF;
  END IF;

  IF v_origen = 'PERSONERO' THEN
    SELECT CONCAT(pe.tipo, ''), pe.id_mesa INTO v_pers_tipo, v_pers_mesa
      FROM personero pe
      JOIN lista_electoral l ON l.id_lista = pe.id_lista
      JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
     WHERE pe.id_personero = p_id_personero AND c.id_proceso = p_id_proceso AND pe.estado_acreditacion = 'ACREDITADO';
    IF v_pers_tipo IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF101: solo un personero acreditado del proceso puede pedir la nulidad.';
    END IF;
    IF v_alcance = 'PARCIAL' AND v_pers_tipo = 'MESA' AND NOT (v_pers_mesa <=> p_id_mesa) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF100: el personero de mesa solo pide la nulidad de su propia mesa.';
    END IF;
  END IF;

  INSERT INTO nulidad_electoral (id_proceso, alcance, id_mesa, causal, origen, id_personero, sustento, pruebas, etapa,
                                 fecha_presentacion, id_usuario_registro)
  VALUES (p_id_proceso, v_alcance, IF(v_alcance = 'PARCIAL', p_id_mesa, NULL), v_causal, v_origen,
          IF(v_origen = 'PERSONERO', p_id_personero, NULL), v_sustento, NULLIF(TRIM(p_pruebas), ''), v_etapa,
          NOW(), p_id_usuario);
  SET p_id_nulidad = LAST_INSERT_ID();

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'REGISTRAR_RECURSO_NULIDAD',
       JSON_OBJECT('id_nulidad', p_id_nulidad, 'alcance', v_alcance, 'id_mesa', p_id_mesa, 'causal', v_causal, 'origen', v_origen));
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_pago_multa` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_pago_multa`(
  IN p_id_multa      INT,
  IN p_id_usuario    INT,
  IN p_numero_recibo VARCHAR(40),
  IN p_fecha_pago    DATETIME,
  IN p_observacion   VARCHAR(300)
)
BEGIN
  DECLARE v_proceso INT DEFAULT NULL;
  DECLARE v_docente INT;
  DECLARE v_estado  VARCHAR(12);
  DECLARE v_rep_est VARCHAR(10);
  DECLARE v_fecha_r DATETIME;
  DECLARE v_recibo  VARCHAR(40);
  DECLARE v_fecha   DATETIME;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT id_proceso, id_docente, estado_pago INTO v_proceso, v_docente, v_estado FROM multa WHERE id_multa = p_id_multa FOR UPDATE;
  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La multa no existe.';
  END IF;
  SELECT estado, fecha_resolucion INTO v_rep_est, v_fecha_r FROM reporte_multas WHERE id_proceso = v_proceso;
  IF v_rep_est IS NULL OR v_rep_est <> 'RESUELTO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF103: la multa se paga después de la resolución del CEUNP que la determina.';
  END IF;
  IF v_estado <> 'PENDIENTE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La multa no está pendiente de pago.';
  END IF;
  SET v_recibo = NULLIF(TRIM(p_numero_recibo), '');
  IF v_recibo IS NULL OR CHAR_LENGTH(v_recibo) < 3 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Indique el número del recibo de pago.';
  END IF;
  IF EXISTS (SELECT 1 FROM multa WHERE numero_recibo = v_recibo) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El número de recibo ya fue registrado en otra multa.';
  END IF;
  SET v_fecha = COALESCE(p_fecha_pago, NOW());
  IF v_fecha > NOW() + INTERVAL 5 MINUTE OR v_fecha < v_fecha_r - INTERVAL 1 MINUTE THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de pago va desde la resolución hasta hoy.';
  END IF;

  UPDATE multa
     SET estado_pago = 'PAGADA', fecha_pago = v_fecha, numero_recibo = v_recibo,
         observacion = COALESCE(NULLIF(TRIM(p_observacion), ''), observacion),
         fecha_actualizacion = NOW(), id_usuario_actualizacion = p_id_usuario
   WHERE id_multa = p_id_multa;

  CALL sp_registrar_auditoria(p_id_usuario, v_docente, v_proceso, 'REGISTRAR_PAGO_MULTA',
       JSON_OBJECT('id_multa', p_id_multa, 'recibo', v_recibo));
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_personero_computo` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_personero_computo`(
  IN p_id_proceso   INT,
  IN p_id_usuario   INT,
  IN p_id_personero INT
)
BEGIN
  DECLARE v_estado VARCHAR(20) DEFAULT NULL;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT estado INTO v_estado FROM computo_proceso WHERE id_proceso = p_id_proceso FOR UPDATE;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF91: instale primero la sesión de cómputo.';
  END IF;
  IF v_estado <> 'SESION_INSTALADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF91: el cómputo ya se realizó; no se registran más asistentes.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM personero pe
                   JOIN lista_electoral l ON l.id_lista = pe.id_lista
                   JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                  WHERE pe.id_personero = p_id_personero AND c.id_proceso = p_id_proceso
                    AND pe.estado_acreditacion = 'ACREDITADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF91: solo asisten a la sesión los personeros acreditados del proceso.';
  END IF;
  IF EXISTS (SELECT 1 FROM computo_personero WHERE id_proceso = p_id_proceso AND id_personero = p_id_personero) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF91: el personero ya figura como asistente.';
  END IF;

  INSERT INTO computo_personero (id_proceso, id_personero, id_usuario) VALUES (p_id_proceso, p_id_personero, p_id_usuario);
  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'REGISTRAR_PERSONERO_COMPUTO',
       JSON_OBJECT('id_personero', p_id_personero));
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_respaldo` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_respaldo`(
  IN p_id_admin     INT,
  IN p_archivo      VARCHAR(150),
  IN p_motivo       VARCHAR(300),
  IN p_tablas       INT,
  IN p_vistas       INT,
  IN p_rutinas      INT,
  IN p_disparadores INT,
  IN p_filas        BIGINT,
  IN p_bytes        BIGINT,
  IN p_hash         CHAR(64),
  IN p_ip           VARCHAR(45),
  IN p_inicio       DATETIME,
  IN p_fin          DATETIME
)
BEGIN
  DECLARE v_id INT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  CALL sp_validar_admin(p_id_admin);
  IF p_hash IS NULL OR LOWER(p_hash) NOT REGEXP '^[0-9a-f]{64}$' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: la huella SHA-256 del respaldo no es válida.';
  END IF;

  START TRANSACTION;
  INSERT INTO respaldo_bd (nombre_archivo, motivo, tablas, vistas, rutinas, disparadores, filas,
                           tamano_bytes, hash_sha256, id_usuario, ip, fecha_inicio, fecha_fin)
  VALUES (p_archivo, NULLIF(TRIM(p_motivo), ''), p_tablas, p_vistas, p_rutinas, p_disparadores, p_filas,
          p_bytes, LOWER(p_hash), p_id_admin, p_ip, p_inicio, p_fin);
  SET v_id = LAST_INSERT_ID();
  CALL sp_registrar_auditoria(p_id_admin, NULL, NULL, 'GENERAR_RESPALDO',
       JSON_OBJECT('id_respaldo', v_id, 'archivo', p_archivo, 'filas', p_filas,
                   'bytes', p_bytes, 'hash', LOWER(p_hash)));
  COMMIT;

  
  SELECT * FROM v_respaldos WHERE id_respaldo = v_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_votos_estudiantiles` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_votos_estudiantiles`(
  IN p_id_proceso INT,
  IN p_id_cargo INT,
  IN p_id_lista INT,
  IN p_votos_estudiantes INT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_estado VARCHAR(20);
  
  SELECT estado INTO v_estado FROM proceso_electoral WHERE id_proceso = p_id_proceso;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;
  IF v_estado IN ('FINALIZADO', 'ANULADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: no se pueden modificar votos tras el cierre definitivo.';
  END IF;
  IF p_votos_estudiantes IS NULL OR p_votos_estudiantes < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cantidad de votos estudiantiles no puede ser negativa.';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM lista_electoral l JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                  WHERE l.id_lista = p_id_lista AND l.id_cargo = p_id_cargo
                    AND c.id_proceso = p_id_proceso AND l.estado = 'ADMITIDA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se registran votos estudiantiles para listas ADMITIDAS del cargo.';
  END IF;

  INSERT INTO computo_estudiantil (id_proceso, id_cargo, id_lista, votos_estudiantes, fecha_registro, id_usuario)
  VALUES (p_id_proceso, p_id_cargo, p_id_lista, p_votos_estudiantes, NOW(), p_id_usuario)
  ON DUPLICATE KEY UPDATE
    votos_estudiantes = VALUES(votos_estudiantes),
    fecha_registro = VALUES(fecha_registro),
    id_usuario = VALUES(id_usuario);

  
  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'REGISTRAR_VOTOS_ESTUDIANTILES',
       JSON_OBJECT('id_cargo', p_id_cargo, 'id_lista', p_id_lista, 'votos_estudiantes', p_votos_estudiantes));
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_resolver_apelacion` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_resolver_apelacion`(
  IN p_id_impugnacion    BIGINT,
  IN p_id_usuario        INT,
  IN p_decision          VARCHAR(12),
  IN p_numero_resolucion VARCHAR(40),
  IN p_miembros_pleno    INT,
  IN p_votos_favor       INT,
  IN p_votos_contra      INT,
  IN p_voto_dirimente    VARCHAR(6),
  IN p_opcion            VARCHAR(10),
  IN p_id_lista          INT,
  IN p_fundamento        VARCHAR(1000)
)
BEGIN
  DECLARE v_mesa      INT DEFAULT NULL;
  DECLARE v_proceso   INT;
  DECLARE v_cargo     INT;
  DECLARE v_estado    VARCHAR(12);
  DECLARE v_proc_est  VARCHAR(20);
  DECLARE v_op_mesa   VARCHAR(10);
  DECLARE v_lista_m   INT;
  DECLARE v_decision  VARCHAR(12);
  DECLARE v_dirimente VARCHAR(6);
  DECLARE v_opcion    VARCHAR(10);
  DECLARE v_lista     INT;
  DECLARE v_numero    VARCHAR(40);
  DECLARE v_fund      VARCHAR(1000);
  DECLARE v_quorum    INT DEFAULT 5;
  DECLARE v_gana      VARCHAR(6);
  DECLARE v_n         INT DEFAULT 0;
  DECLARE v_msg       VARCHAR(255);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT i.id_mesa, i.id_proceso, i.id_cargo, i.estado, p.estado, i.opcion_mesa, i.id_lista_mesa
    INTO v_mesa, v_proceso, v_cargo, v_estado, v_proc_est, v_op_mesa, v_lista_m
    FROM impugnacion_electoral i
    JOIN proceso_electoral p ON p.id_proceso = i.id_proceso
   WHERE i.id_impugnacion = p_id_impugnacion
     FOR UPDATE;

  IF v_mesa IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La impugnación no existe.';
  END IF;
  IF v_estado <> 'APELADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN23: el CEUNP resuelve solo las impugnaciones apeladas.';
  END IF;
  IF v_proc_est NOT IN ('VOTACION', 'CERRADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS13: el proceso ya no admite resolver apelaciones.';
  END IF;

  SET v_decision = UPPER(TRIM(p_decision));
  IF v_decision IS NULL OR v_decision NOT IN ('CONFIRMADA', 'MODIFICADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el fallo del CEUNP CONFIRMA o MODIFICA la decisión de la mesa.';
  END IF;

  SET v_numero = NULLIF(TRIM(p_numero_resolucion), '');
  IF v_numero IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: indique el número de la resolución del CEUNP.';
  END IF;
  SELECT COUNT(*) INTO v_n FROM impugnacion_electoral WHERE numero_resolucion = v_numero;
  IF v_n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: ya existe un fallo con ese número de resolución.';
  END IF;

  
  SET v_quorum = COALESCE((SELECT ROUND(CAST(valor AS DECIMAL(6,2))) FROM parametro_global
                            WHERE clave = 'CEUNP_QUORUM_PLENO'), 5);
  IF p_miembros_pleno IS NULL OR p_miembros_pleno < v_quorum THEN
    SET v_msg = CONCAT('RN36: el Pleno del CEUNP resuelve con quórum de ', v_quorum, ' miembros.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  IF p_votos_favor IS NULL OR p_votos_contra IS NULL OR p_votos_favor < 0 OR p_votos_contra < 0
     OR p_votos_favor + p_votos_contra <> p_miembros_pleno THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: los votos a favor y en contra deben sumar los miembros presentes del Pleno.';
  END IF;
  SET v_dirimente = NULLIF(UPPER(TRIM(p_voto_dirimente)), '');
  IF p_votos_favor = p_votos_contra THEN
    IF v_dirimente IS NULL OR v_dirimente NOT IN ('FAVOR', 'CONTRA') THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: hay empate; registre el voto dirimente del Presidente del CEUNP.';
    END IF;
    SET v_gana = v_dirimente;
  ELSE
    SET v_dirimente = NULL;
    SET v_gana = IF(p_votos_favor > p_votos_contra, 'FAVOR', 'CONTRA');
  END IF;
  IF (v_decision = 'MODIFICADA' AND v_gana <> 'FAVOR') OR (v_decision = 'CONFIRMADA' AND v_gana <> 'CONTRA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el fallo no coincide con la mayoría del Pleno.';
  END IF;

  
  IF v_decision = 'CONFIRMADA' THEN
    SET v_opcion = v_op_mesa;
    SET v_lista = v_lista_m;
  ELSE
    SET v_opcion = UPPER(TRIM(p_opcion));
    SET v_lista = IF(v_opcion = 'LISTA', p_id_lista, NULL);
    IF v_opcion IS NULL OR v_opcion NOT IN ('LISTA', 'BLANCO', 'NULO') THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS13: indique a qué opción va la cédula (lista, BLANCO o NULO).';
    END IF;
    IF v_opcion = 'LISTA' THEN
      SELECT COUNT(*) INTO v_n
        FROM lista_electoral l JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
       WHERE l.id_lista = v_lista AND c.id_proceso = v_proceso AND l.estado = 'ADMITIDA'
         AND (v_cargo IS NULL OR l.id_cargo = v_cargo);
      IF v_n = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS13: la lista no está ADMITIDA para el cargo de la cédula impugnada.';
      END IF;
    ELSEIF p_id_lista IS NOT NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS13: un voto en BLANCO o NULO no lleva lista.';
    END IF;
    IF v_opcion = v_op_mesa AND v_lista <=> v_lista_m THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: para MODIFICAR la decisión, la opción final debe ser distinta de la que fijó la mesa.';
    END IF;
  END IF;

  SET v_fund = NULLIF(TRIM(p_fundamento), '');
  IF v_fund IS NULL OR CHAR_LENGTH(v_fund) < 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: fundamente el fallo (al menos 10 caracteres).';
  END IF;

  
  UPDATE impugnacion_electoral
     SET decision_ceunp = v_decision, numero_resolucion = v_numero, miembros_pleno = p_miembros_pleno,
         votos_pleno_favor = p_votos_favor, votos_pleno_contra = p_votos_contra, voto_dirimente = v_dirimente,
         opcion_final = v_opcion, id_lista_final = v_lista, fundamento_ceunp = v_fund,
         fecha_fallo = NOW(), id_usuario_ceunp = p_id_usuario, estado = 'RESUELTA', fecha_resolucion = NOW()
   WHERE id_impugnacion = p_id_impugnacion;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'RESOLVER_APELACION',
       JSON_OBJECT('id_impugnacion', p_id_impugnacion, 'id_mesa', v_mesa, 'decision', v_decision,
                   'resolucion', v_numero, 'favor', p_votos_favor, 'contra', p_votos_contra,
                   'dirimente', v_dirimente, 'opcion', v_opcion));
  COMMIT;

  
  SELECT p_id_impugnacion AS id_impugnacion, v_decision AS decision_ceunp, v_opcion AS opcion_final;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_resolver_impugnacion_mesa` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_resolver_impugnacion_mesa`(
  IN p_id_impugnacion BIGINT,
  IN p_id_usuario     INT,
  IN p_decision       VARCHAR(10),
  IN p_votos_favor    INT,
  IN p_votos_contra   INT,
  IN p_opcion         VARCHAR(10),
  IN p_id_lista       INT,
  IN p_fundamento     VARCHAR(1000)
)
BEGIN
  DECLARE v_mesa      INT DEFAULT NULL;
  DECLARE v_proceso   INT;
  DECLARE v_cargo     INT;
  DECLARE v_estado    VARCHAR(12);
  DECLARE v_dec_mesa  VARCHAR(12);
  DECLARE v_mesa_est  VARCHAR(20);
  DECLARE v_proc_est  VARCHAR(20);
  DECLARE v_decision  VARCHAR(10);
  DECLARE v_opcion    VARCHAR(10);
  DECLARE v_fund      VARCHAR(1000);
  DECLARE v_miembros  INT DEFAULT 0;
  DECLARE v_n         INT DEFAULT 0;
  DECLARE v_msg       VARCHAR(255);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT i.id_mesa, i.id_proceso, i.id_cargo, i.estado, i.decision_mesa, m.estado, p.estado
    INTO v_mesa, v_proceso, v_cargo, v_estado, v_dec_mesa, v_mesa_est, v_proc_est
    FROM impugnacion_electoral i
    JOIN mesa_electoral m    ON m.id_mesa = i.id_mesa
    JOIN proceso_electoral p ON p.id_proceso = i.id_proceso
   WHERE i.id_impugnacion = p_id_impugnacion
     FOR UPDATE;

  IF v_mesa IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La impugnación no existe.';
  END IF;
  IF v_dec_mesa <> 'PENDIENTE' OR v_estado <> 'PRESENTADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN23: la mesa ya resolvió esta impugnación.';
  END IF;
  IF v_proc_est NOT IN ('VOTACION', 'CERRADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS13: el proceso ya no admite resolver impugnaciones.';
  END IF;
  IF v_mesa_est <> 'CERRADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS13: la mesa resuelve las impugnaciones en el escrutinio, con el sufragio cerrado (CUS11).';
  END IF;

  SET v_decision = UPPER(TRIM(p_decision));
  IF v_decision IS NULL OR v_decision NOT IN ('ACEPTADA', 'RECHAZADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN23: la decisión de la mesa es ACEPTADA o RECHAZADA.';
  END IF;

  
  SELECT COUNT(*) INTO v_miembros FROM (
    SELECT rol_instalacion AS cargo FROM miembro_mesa WHERE id_mesa = v_mesa AND rol_instalacion IS NOT NULL
    UNION
    SELECT cargo FROM reemplazo_mesa WHERE id_mesa = v_mesa) f;
  IF v_miembros = 0 THEN
    SET v_miembros = 3;
  END IF;
  IF p_votos_favor IS NULL OR p_votos_contra IS NULL OR p_votos_favor < 0 OR p_votos_contra < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN23: registre cuántos miembros votaron a favor y en contra.';
  END IF;
  IF p_votos_favor + p_votos_contra <> v_miembros THEN
    SET v_msg = CONCAT('RN23: votan los ', v_miembros, ' miembros de mesa en funciones (se registraron ',
                       p_votos_favor + p_votos_contra, ').');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  IF p_votos_favor = p_votos_contra THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN23: hay empate; la mesa decide por mayoría simple.';
  END IF;
  IF (v_decision = 'ACEPTADA' AND p_votos_favor < p_votos_contra)
     OR (v_decision = 'RECHAZADA' AND p_votos_favor > p_votos_contra) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN23: la decisión no coincide con la mayoría de los miembros de mesa.';
  END IF;

  
  SET v_opcion = UPPER(TRIM(p_opcion));
  IF v_opcion IS NULL OR v_opcion NOT IN ('LISTA', 'BLANCO', 'NULO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS13: indique si la cédula va a una lista, en BLANCO o NULO.';
  END IF;
  IF v_opcion = 'LISTA' THEN
    SELECT COUNT(*) INTO v_n
      FROM lista_electoral l JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
     WHERE l.id_lista = p_id_lista AND c.id_proceso = v_proceso AND l.estado = 'ADMITIDA'
       AND (v_cargo IS NULL OR l.id_cargo = v_cargo);
    IF v_n = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS13: la lista no está ADMITIDA para el cargo de la cédula impugnada.';
    END IF;
  ELSEIF p_id_lista IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS13: un voto en BLANCO o NULO no lleva lista.';
  END IF;

  SET v_fund = NULLIF(TRIM(p_fundamento), '');
  IF v_fund IS NULL OR CHAR_LENGTH(v_fund) < 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS13: fundamente la decisión de la mesa (al menos 10 caracteres).';
  END IF;

  
  UPDATE impugnacion_electoral
     SET decision_mesa = v_decision, votos_mesa_favor = p_votos_favor, votos_mesa_contra = p_votos_contra,
         opcion_mesa = v_opcion, id_lista_mesa = IF(v_opcion = 'LISTA', p_id_lista, NULL),
         id_cargo = COALESCE(v_cargo, (SELECT id_cargo FROM lista_electoral WHERE id_lista = p_id_lista)),
         fundamento_mesa = v_fund, fecha_decision_mesa = NOW(), id_usuario_mesa = p_id_usuario,
         estado = 'RESUELTA', fecha_resolucion = NOW()
   WHERE id_impugnacion = p_id_impugnacion;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'RESOLVER_IMPUGNACION_MESA',
       JSON_OBJECT('id_impugnacion', p_id_impugnacion, 'id_mesa', v_mesa, 'decision', v_decision,
                   'favor', p_votos_favor, 'contra', p_votos_contra, 'opcion', v_opcion));
  COMMIT;

  
  SELECT p_id_impugnacion AS id_impugnacion, v_decision AS decision_mesa, v_opcion AS opcion_mesa;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_resolver_nulidad` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_resolver_nulidad`(
  IN p_id_nulidad        INT,
  IN p_id_usuario        INT,
  IN p_decision          VARCHAR(12),
  IN p_fundamento        VARCHAR(1000),
  IN p_numero_resolucion VARCHAR(40),
  IN p_miembros_pleno    INT,
  IN p_votos_favor       INT,
  IN p_votos_contra      INT,
  IN p_voto_dirimente    BOOLEAN
)
BEGIN
  DECLARE v_proceso   INT DEFAULT NULL;
  DECLARE v_alcance   VARCHAR(10);
  DECLARE v_mesa      INT;
  DECLARE v_causal    VARCHAR(30);
  DECLARE v_origen    VARCHAR(10);
  DECLARE v_sustento  VARCHAR(1000);
  DECLARE v_estado_n  VARCHAR(12);
  DECLARE v_estado    VARCHAR(20);
  DECLARE v_nombre    VARCHAR(200);
  DECLARE v_tipo      VARCHAR(20);
  DECLARE v_comp      VARCHAR(20);
  DECLARE v_mesa_est  VARCHAR(20);
  DECLARE v_numero    VARCHAR(20);
  DECLARE v_decision  VARCHAR(12);
  DECLARE v_fund      VARCHAR(1000);
  DECLARE v_res       VARCHAR(40);
  DECLARE v_quorum    INT;
  DECLARE v_dirimente BOOLEAN DEFAULT FALSE;
  DECLARE v_sin_materia INT DEFAULT 0;
  DECLARE v_hijo      INT DEFAULT NULL;
  DECLARE v_hijo_est  VARCHAR(20);
  DECLARE v_motivo    VARCHAR(500);
  DECLARE v_efecto    VARCHAR(300);
  DECLARE v_votos     LONGTEXT;
  DECLARE v_part      LONGTEXT;
  DECLARE v_pers      LONGTEXT;
  DECLARE v_ahora     DATETIME;
  DECLARE v_contenido LONGTEXT;
  DECLARE v_token     CHAR(64);
  DECLARE v_msg       VARCHAR(255);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    SET @cus15_nulidad_total = NULL;
    ROLLBACK;
    RESIGNAL;
  END;

  SET SESSION group_concat_max_len = 1000000;
  START TRANSACTION;
  SELECT n.id_proceso, n.alcance, n.id_mesa, n.causal, n.origen, n.sustento, n.estado
    INTO v_proceso, v_alcance, v_mesa, v_causal, v_origen, v_sustento, v_estado_n
    FROM nulidad_electoral n WHERE n.id_nulidad = p_id_nulidad FOR UPDATE;
  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El recurso de nulidad no existe.';
  END IF;
  IF v_estado_n <> 'PRESENTADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el recurso ya fue resuelto; la decisión del CEUNP es inapelable.';
  END IF;
  SELECT estado, nombre, tipo INTO v_estado, v_nombre, v_tipo FROM proceso_electoral WHERE id_proceso = v_proceso FOR UPDATE;
  SELECT estado INTO v_comp FROM computo_proceso WHERE id_proceso = v_proceso;
  IF v_mesa IS NOT NULL THEN
    SELECT estado, numero_mesa INTO v_mesa_est, v_numero FROM mesa_electoral WHERE id_mesa = v_mesa FOR UPDATE;
  END IF;

  SET v_decision = UPPER(TRIM(p_decision));
  IF v_decision IS NULL OR v_decision NOT IN ('FUNDADA','INFUNDADA','IMPROCEDENTE') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF94: la decisión es FUNDADA, INFUNDADA o IMPROCEDENTE.';
  END IF;
  SET v_fund = NULLIF(TRIM(p_fundamento), '');
  IF v_fund IS NULL OR CHAR_LENGTH(v_fund) < 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF94: fundamente la resolución del CEUNP (al menos 10 caracteres).';
  END IF;
  SET v_res = NULLIF(TRIM(p_numero_resolucion), '');
  IF v_res IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN34: la nulidad se resuelve por resolución del CEUNP; indique su número.';
  END IF;
  IF fn_resolucion_en_uso(v_res) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;

  
  SET v_quorum = COALESCE(ROUND((SELECT CAST(valor AS DECIMAL(6,2)) FROM parametro_global WHERE clave = 'CEUNP_QUORUM_PLENO')), 5);
  IF p_miembros_pleno IS NULL OR p_miembros_pleno < v_quorum OR p_miembros_pleno > 9 THEN
    SET v_msg = CONCAT('RN36: el Pleno del CEUNP resuelve con quórum de ', v_quorum, ' de sus 9 miembros.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  IF p_votos_favor IS NULL OR p_votos_contra IS NULL OR p_votos_favor < 0 OR p_votos_contra < 0
     OR p_votos_favor + p_votos_contra > p_miembros_pleno OR p_votos_favor + p_votos_contra = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: los votos a favor y en contra no pueden superar a los miembros presentes.';
  END IF;
  SET v_dirimente = COALESCE(p_voto_dirimente, FALSE) AND p_votos_favor = p_votos_contra;
  IF p_votos_favor < p_votos_contra OR (p_votos_favor = p_votos_contra AND NOT v_dirimente) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: los votos a favor de la decisión elegida deben ser mayoría simple; en empate decide el voto dirimente del Presidente.';
  END IF;

  
  IF v_alcance = 'PARCIAL' THEN
    SET v_sin_materia = IF(v_estado = 'ANULADO' OR v_mesa_est = 'ANULADA', 1, 0);
    IF v_sin_materia = 0 AND (v_estado <> 'CERRADO' OR COALESCE(v_comp, 'SESION_INSTALADA') <> 'SESION_INSTALADA') THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF100: la nulidad parcial se resuelve antes del cómputo (RN26).';
    END IF;
  ELSEIF v_causal = 'PARTICIPACION_INSUFICIENTE' THEN
    IF v_decision <> 'FUNDADA' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN31: la falta de participación quedó determinada por el cómputo oficial; la nulidad solo se declara FUNDADA.';
    END IF;
  ELSE
    SET v_sin_materia = IF(v_estado = 'ANULADO', 1, 0);
    IF v_sin_materia = 0 AND NOT (v_estado = 'CERRADO' OR (v_estado = 'FINALIZADO' AND v_comp = 'COMPUTADO')) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF94: la nulidad total se resuelve antes de la proclamación.';
    END IF;
    IF v_decision = 'FUNDADA' AND v_sin_materia = 0 THEN
      SELECT MIN(id_proceso) INTO v_hijo FROM proceso_electoral WHERE id_proceso_padre = v_proceso AND estado <> 'ANULADO';
      IF v_hijo IS NOT NULL THEN
        SELECT estado INTO v_hijo_est FROM proceso_electoral WHERE id_proceso = v_hijo FOR UPDATE;
        IF v_hijo_est = 'FINALIZADO' THEN
          SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF101: la segunda vuelta de esta elección ya concluyó; la nulidad se plantea sobre ese proceso.';
        END IF;
      END IF;
    END IF;
  END IF;
  IF v_sin_materia = 1 AND v_decision <> 'IMPROCEDENTE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF94: la mesa o la elección ya fueron anuladas; el recurso solo puede declararse IMPROCEDENTE.';
  END IF;

  SET v_ahora = NOW();

  
  IF v_alcance = 'PARCIAL' THEN
    SELECT CONCAT('[', GROUP_CONCAT(JSON_OBJECT('cargo', c.nombre, 'opcion', x.opcion,
                                                'lista', COALESCE(l.nombre, x.opcion), 'votos', x.votos)
                                    ORDER BY x.id_cargo, FIELD(x.opcion, 'LISTA', 'BLANCO', 'NULO', 'IMPUGNADO'),
                                             COALESCE(l.orden_cedula, 999) SEPARATOR ','), ']')
      INTO v_votos
      FROM v_computo_conteo_mesa x
      JOIN cargo_electoral c ON c.id_cargo = x.id_cargo
      LEFT JOIN lista_electoral l ON l.id_lista = x.id_lista
     WHERE x.id_mesa = v_mesa;
  END IF;
  SELECT JSON_OBJECT('electores', electores_habiles, 'votaron', votaron, 'porcentaje', participacion_pct,
                     'quorum_minimo', quorum_minimo)
    INTO v_part FROM v_quorum_proceso WHERE id_proceso = v_proceso;
  IF v_origen = 'PERSONERO' THEN
    SELECT JSON_OBJECT('nombre', CONCAT(d.apellidos, ', ', d.nombres), 'dni', d.dni, 'lista', l.nombre, 'tipo', CONCAT(pe.tipo, ''))
      INTO v_pers
      FROM nulidad_electoral n
      JOIN personero pe      ON pe.id_personero = n.id_personero
      JOIN docente d         ON d.id_docente = pe.id_docente
      JOIN lista_electoral l ON l.id_lista = pe.id_lista
     WHERE n.id_nulidad = p_id_nulidad;
  END IF;

  IF v_decision = 'FUNDADA' AND v_alcance = 'PARCIAL' THEN
    
    UPDATE acta_electoral SET estado = 'ANULADA' WHERE id_mesa = v_mesa;
    UPDATE mesa_electoral SET estado = 'ANULADA' WHERE id_mesa = v_mesa;
    SET v_efecto = CONCAT('Se anula la votación de la mesa ', v_numero, ' y sus actas; sus votos no se computan (RF100).');
  ELSEIF v_decision = 'FUNDADA' AND v_causal <> 'PARTICIPACION_INSUFICIENTE' THEN
    
    SET v_motivo = LEFT(CONCAT('RN34: nulidad total de la elección por causal de ',
                               ELT(FIELD(v_causal, 'FRAUDE','COHECHO','SOBORNO','INTIMIDACION','VIOLENCIA'),
                                   'fraude', 'cohecho', 'soborno', 'intimidación', 'violencia'),
                               ' (Art. 65), declarada por Resolución ', v_res, '. ', v_fund), 500);
    SET @cus15_nulidad_total = v_proceso;
    UPDATE proceso_electoral
       SET estado = 'ANULADO', motivo_anulacion = v_motivo, fecha_cierre_real = COALESCE(fecha_cierre_real, v_ahora)
     WHERE id_proceso = v_proceso;
    SET @cus15_nulidad_total = NULL;
    UPDATE acta_electoral a JOIN mesa_electoral m ON m.id_mesa = a.id_mesa
       SET a.estado = 'ANULADA' WHERE m.id_proceso = v_proceso;
    UPDATE mesa_electoral SET estado = 'ANULADA' WHERE id_proceso = v_proceso;
    IF v_hijo IS NOT NULL THEN
      UPDATE proceso_electoral
         SET estado = 'ANULADO', fecha_cierre_real = COALESCE(fecha_cierre_real, v_ahora),
             motivo_anulacion = LEFT(CONCAT('RN34: se anula la segunda vuelta por la nulidad total de la primera (Resolución ', v_res, ').'), 500)
       WHERE id_proceso = v_hijo;
      UPDATE acta_electoral a JOIN mesa_electoral m ON m.id_mesa = a.id_mesa
         SET a.estado = 'ANULADA' WHERE m.id_proceso = v_hijo;
      UPDATE mesa_electoral SET estado = 'ANULADA' WHERE id_proceso = v_hijo;
    END IF;
    SET v_efecto = CONCAT('Se declara la nulidad total de la elección: el proceso, sus mesas y sus actas quedan anulados',
                          IF(v_hijo IS NULL, '', CONCAT(', y también la segunda vuelta convocada (proceso N.º ', v_hijo, ')')),
                          '. Se comunica a SUNEDU, la Asamblea Universitaria y el Consejo Universitario (RF102).');
  ELSEIF v_decision = 'FUNDADA' THEN
    SET v_efecto = 'Se formaliza la nulidad total por no superar la participación mínima (A1, RN31). Se comunica a SUNEDU, la Asamblea Universitaria y el Consejo Universitario (RF102).';
  ELSEIF v_decision = 'INFUNDADA' THEN
    SET v_efecto = IF(v_alcance = 'PARCIAL', CONCAT('La votación de la mesa ', v_numero, ' se mantiene y se computa.'),
                      'La elección se mantiene válida.');
  ELSE
    SET v_efecto = IF(v_sin_materia = 1, 'Improcedente por sustracción de la materia: la mesa o la elección ya estaban anuladas.',
                      'El recurso no reúne los requisitos de procedencia; no se pronuncia sobre el fondo.');
  END IF;

  SET v_contenido = CONCAT(
      '{"tipo":"RESOLUCION_NULIDAD"',
      ',"id_nulidad":', p_id_nulidad,
      ',"id_proceso":', v_proceso,
      ',"proceso":', JSON_QUOTE(v_nombre),
      ',"vuelta":', JSON_QUOTE(v_tipo),
      ',"resolucion":', JSON_QUOTE(v_res),
      ',"fecha":', JSON_QUOTE(DATE_FORMAT(v_ahora, '%Y-%m-%d %H:%i:%s')),
      ',"alcance":', JSON_QUOTE(v_alcance),
      ',"mesa":', IF(v_numero IS NULL, 'null', JSON_QUOTE(v_numero)),
      ',"causal":', JSON_QUOTE(v_causal),
      ',"origen":', JSON_QUOTE(v_origen),
      ',"personero":', COALESCE(v_pers, 'null'),
      ',"sustento":', JSON_QUOTE(v_sustento),
      ',"decision":', JSON_QUOTE(v_decision),
      ',"pleno":{"miembros":', p_miembros_pleno, ',"a_favor":', p_votos_favor, ',"en_contra":', p_votos_contra,
      ',"voto_dirimente":', IF(v_dirimente, 'true', 'false'), '}',
      ',"fundamento":', JSON_QUOTE(v_fund),
      ',"efecto":', JSON_QUOTE(v_efecto),
      ',"participacion":', COALESCE(v_part, 'null'),
      ',"votos_excluidos":', IF(v_decision = 'FUNDADA' AND v_alcance = 'PARCIAL', COALESCE(v_votos, '[]'), '[]'),
      IF(v_decision = 'FUNDADA' AND v_alcance = 'TOTAL',
         ',"comunicar_a":["SUNEDU","Asamblea Universitaria","Consejo Universitario"]', ''),
      '}');
  SET v_token = LOWER(HEX(fn_bytes_aleatorios(32)));

  UPDATE nulidad_electoral
     SET estado = v_decision, numero_resolucion = v_res, fundamento_resolucion = v_fund,
         miembros_pleno = p_miembros_pleno, votos_favor = p_votos_favor, votos_contra = p_votos_contra,
         voto_dirimente = v_dirimente, fecha_resolucion = v_ahora, id_usuario_resolucion = p_id_usuario,
         contenido_json = v_contenido, hash_integridad = SHA2(v_contenido, 256), token_qr_hash = SHA2(v_token, 256)
   WHERE id_nulidad = p_id_nulidad;

  
  IF v_decision = 'FUNDADA' AND v_alcance = 'TOTAL' THEN
    UPDATE nulidad_electoral
       SET estado = 'IMPROCEDENTE', fecha_resolucion = v_ahora, id_usuario_resolucion = p_id_usuario,
           fundamento_resolucion = LEFT(CONCAT('Sustracción de la materia: la elección fue declarada nula por Resolución ', v_res, '.'), 1000)
     WHERE id_proceso = v_proceso AND alcance = 'PARCIAL' AND estado = 'PRESENTADA';
  END IF;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso,
       CASE WHEN v_decision <> 'FUNDADA' THEN 'DESESTIMAR_NULIDAD'
            WHEN v_alcance = 'PARCIAL' THEN 'DECLARAR_NULIDAD_PARCIAL' ELSE 'DECLARAR_NULIDAD_TOTAL' END,
       JSON_OBJECT('id_nulidad', p_id_nulidad, 'decision', v_decision, 'resolucion', v_res, 'id_mesa', v_mesa,
                   'causal', v_causal, 'segunda_vuelta_anulada', v_hijo));
  COMMIT;

  SELECT p_id_nulidad AS id_nulidad, v_decision AS decision, v_alcance AS alcance, v_res AS numero_resolucion,
         v_token AS token_qr, v_efecto AS efecto, v_hijo AS id_segunda_vuelta_anulada;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_resolver_tacha` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_resolver_tacha`(
  IN p_id_tacha   INT,
  IN p_resultado  VARCHAR(10),      
  IN p_resolucion TEXT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_estado    VARCHAR(20) DEFAULT NULL;
  DECLARE v_candidato INT DEFAULT NULL;
  DECLARE v_lista     INT DEFAULT NULL;
  DECLARE v_proceso   INT DEFAULT NULL;
  DECLARE v_res       VARCHAR(10);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SET v_res = UPPER(p_resultado);

  SELECT t.estado, t.id_candidato, ca.id_lista INTO v_estado, v_candidato, v_lista
    FROM tacha t JOIN candidato ca ON ca.id_candidato = t.id_candidato
   WHERE t.id_tacha = p_id_tacha
     FOR UPDATE;

  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La tacha no existe.';
  END IF;
  IF v_estado <> 'PENDIENTE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La tacha ya fue resuelta.';
  END IF;
  IF v_res IS NULL OR v_res NOT IN ('FUNDADA','INFUNDADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El resultado debe ser FUNDADA o INFUNDADA.';
  END IF;

  SET v_proceso = fn_proceso_de_lista(v_lista);

  UPDATE tacha
     SET estado = v_res, fecha_resolucion = NOW(), resolucion = p_resolucion, id_usuario_resuelve = p_id_usuario
   WHERE id_tacha = p_id_tacha;

  IF v_res = 'FUNDADA' THEN
    UPDATE candidato
       SET estado_validacion = 'EXCLUIDO', motivo_exclusion = 'Tacha declarada fundada'
     WHERE id_candidato = v_candidato;
    
    UPDATE candidato
       SET estado_validacion = 'EXCLUIDO', motivo_exclusion = 'Lista tachada por RN12 (inscripción en bloque)'
     WHERE id_lista = v_lista AND id_candidato <> v_candidato;
    UPDATE lista_electoral
       SET estado = 'TACHADA', orden_cedula = NULL, motivo_exclusion = 'Tacha fundada contra un integrante (RN12)'
     WHERE id_lista = v_lista;
  END IF;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'RESOLVER_TACHA',
       JSON_OBJECT('id_tacha', p_id_tacha, 'resultado', v_res));
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_restablecer_password` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_restablecer_password`(
  IN p_id_admin      INT,
  IN p_id_usuario    INT,
  IN p_password_hash VARCHAR(255)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  CALL sp_validar_admin(p_id_admin);
  IF p_id_usuario = p_id_admin THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: cambie su propia contraseña en «Configuración».';
  END IF;
  IF p_password_hash IS NULL OR p_password_hash NOT LIKE '$2%' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: la contraseña debe llegar cifrada.';
  END IF;

  START TRANSACTION;
  IF NOT EXISTS (SELECT 1 FROM usuario WHERE id_usuario = p_id_usuario FOR UPDATE) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: la cuenta no existe.';
  END IF;
  UPDATE usuario
     SET password_hash = p_password_hash, debe_cambiar_password = TRUE, intentos_fallidos = 0,
         bloqueado_hasta = NULL, fecha_actualizacion = NOW()
   WHERE id_usuario = p_id_usuario;
  CALL sp_registrar_auditoria(p_id_admin, NULL, NULL, 'RESTABLECER_PASSWORD', JSON_OBJECT('id_usuario', p_id_usuario));
  COMMIT;

  SELECT * FROM v_usuarios_admin WHERE id_usuario = p_id_usuario;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_sortear_miembros_mesa` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_sortear_miembros_mesa`(
  IN p_id_mesa    INT,
  IN p_semilla    VARCHAR(128),     
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_proceso   INT DEFAULT NULL;
  DECLARE v_estado    VARCHAR(20) DEFAULT NULL;
  DECLARE v_semilla   VARCHAR(128);
  DECLARE v_asignados INT DEFAULT 0;
  DECLARE v_n         INT DEFAULT 0;

  SELECT m.id_proceso, p.estado INTO v_proceso, v_estado
    FROM mesa_electoral m JOIN proceso_electoral p ON p.id_proceso = m.id_proceso
   WHERE m.id_mesa = p_id_mesa;

  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no existe.';
  END IF;
  IF v_estado NOT IN ('CREADO','INSCRIPCION') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El sorteo de mesas se realiza antes de la votacion.';
  END IF;
  SELECT COUNT(*) INTO v_n FROM miembro_mesa WHERE id_mesa = p_id_mesa;
  IF v_n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN19: la mesa ya fue sorteada (el cargo es irrenunciable).';
  END IF;

  SET v_semilla = COALESCE(NULLIF(TRIM(p_semilla), ''), LOWER(HEX(fn_bytes_aleatorios(32))));
  SELECT COUNT(*) INTO v_asignados FROM padron_electoral WHERE id_mesa = p_id_mesa;

  DROP TEMPORARY TABLE IF EXISTS tmp_sorteo;
  CREATE TEMPORARY TABLE tmp_sorteo (n INT PRIMARY KEY, id_docente INT NOT NULL);
  INSERT INTO tmp_sorteo (n, id_docente)
  SELECT ROW_NUMBER() OVER (ORDER BY SHA2(CONCAT(v_semilla, '|', e.dni), 256)), e.id_docente
    FROM (SELECT DISTINCT id_docente, dni
            FROM v_elegibles_sorteo
           WHERE id_proceso = v_proceso
             AND (v_asignados = 0 OR id_mesa = p_id_mesa)) e;

  SELECT COUNT(*) INTO v_n FROM tmp_sorteo;
  IF v_n < 6 THEN
    DROP TEMPORARY TABLE IF EXISTS tmp_sorteo;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN19: no hay 6 docentes elegibles para sortear esta mesa.';
  END IF;

  INSERT INTO miembro_mesa (id_mesa, id_docente, rol, titular, orden_sorteo)
  SELECT p_id_mesa, t.id_docente,
         CASE t.n WHEN 1 THEN 'PRESIDENTE' WHEN 2 THEN 'SECRETARIO' WHEN 3 THEN 'VOCAL' ELSE 'SUPLENTE' END,
         IF(t.n <= 3, 1, 0),
         t.n
    FROM tmp_sorteo t
   WHERE t.n <= 6;
  DROP TEMPORARY TABLE IF EXISTS tmp_sorteo;

  UPDATE mesa_electoral SET semilla_sorteo = v_semilla, fecha_sorteo = NOW() WHERE id_mesa = p_id_mesa;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'SORTEO_MESA',
       JSON_OBJECT('id_mesa', p_id_mesa, 'semilla', v_semilla, 'algoritmo', 'ORDER BY SHA256(semilla|dni)'));
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_sortear_orden_cedula` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_sortear_orden_cedula`(
  IN p_id_cargo   INT,
  IN p_semilla    VARCHAR(128),     
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_proceso INT DEFAULT NULL;
  DECLARE v_estado  VARCHAR(20) DEFAULT NULL;
  DECLARE v_semilla VARCHAR(128);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT p.id_proceso, p.estado INTO v_proceso, v_estado
    FROM cargo_electoral c JOIN proceso_electoral p ON p.id_proceso = c.id_proceso
   WHERE c.id_cargo = p_id_cargo;

  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cargo electoral no existe.';
  END IF;
  IF v_estado NOT IN ('CREADO','INSCRIPCION') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN18: la cedula solo se sortea antes de la VOTACION.';
  END IF;
  
  IF EXISTS (SELECT 1 FROM lista_electoral WHERE id_cargo = p_id_cargo AND estado = 'ADMITIDA')
     AND NOT EXISTS (SELECT 1 FROM lista_electoral
                      WHERE id_cargo = p_id_cargo AND estado = 'ADMITIDA' AND orden_cedula IS NULL) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN18: el orden de la cedula de este cargo ya fue sorteado; no se repite.';
  END IF;

  SET v_semilla = COALESCE(NULLIF(TRIM(p_semilla), ''), LOWER(HEX(fn_bytes_aleatorios(32))));

  DROP TEMPORARY TABLE IF EXISTS tmp_orden_cedula;
  CREATE TEMPORARY TABLE tmp_orden_cedula (id_lista INT PRIMARY KEY, n INT NOT NULL);
  INSERT INTO tmp_orden_cedula (id_lista, n)
  SELECT l.id_lista,
         ROW_NUMBER() OVER (ORDER BY SHA2(CONCAT(v_semilla, '|', l.id_lista), 256))
    FROM lista_electoral l
   WHERE l.id_cargo = p_id_cargo AND l.estado = 'ADMITIDA';

  UPDATE lista_electoral SET orden_cedula = NULL WHERE id_cargo = p_id_cargo;
  UPDATE lista_electoral l
    JOIN tmp_orden_cedula t ON t.id_lista = l.id_lista
     SET l.orden_cedula = t.n;
  DROP TEMPORARY TABLE IF EXISTS tmp_orden_cedula;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'SORTEO_ORDEN_CEDULA',
       JSON_OBJECT('id_cargo', p_id_cargo, 'semilla', v_semilla));
  COMMIT;

  SELECT id_lista, nombre, orden_cedula FROM lista_electoral
   WHERE id_cargo = p_id_cargo AND estado = 'ADMITIDA' ORDER BY orden_cedula;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_sortear_todas_las_mesas` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_sortear_todas_las_mesas`(
  IN p_id_proceso   INT,
  IN p_semilla_base VARCHAR(128),   
  IN p_id_usuario   INT
)
BEGIN
  DECLARE v_fin     INT DEFAULT 0;
  DECLARE v_id_mesa INT;
  DECLARE v_numero  VARCHAR(30);
  DECLARE v_base    VARCHAR(128);
  DECLARE v_semilla VARCHAR(128);
  DECLARE cur_mesas CURSOR FOR
    SELECT m.id_mesa, m.numero_mesa
      FROM mesa_electoral m
     WHERE m.id_proceso = p_id_proceso
       AND NOT EXISTS (SELECT 1 FROM miembro_mesa mm WHERE mm.id_mesa = m.id_mesa)
     ORDER BY m.numero_mesa;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = 1;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SET v_base = COALESCE(NULLIF(TRIM(p_semilla_base), ''), LOWER(HEX(fn_bytes_aleatorios(32))));

  SET v_fin = 0;
  OPEN cur_mesas;
  bucle: LOOP
    FETCH cur_mesas INTO v_id_mesa, v_numero;
    IF v_fin = 1 THEN
      LEAVE bucle;
    END IF;
    SET v_semilla = SHA2(CONCAT(v_base, '|', v_numero), 256);
    CALL sp_sortear_miembros_mesa(v_id_mesa, v_semilla, p_id_usuario);
    SET v_fin = 0;
  END LOOP;
  CLOSE cur_mesas;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'SORTEO_GENERAL_MESAS',
       JSON_OBJECT('semilla_base', v_base));

  
  UPDATE usuario u
    JOIN miembro_mesa mm ON mm.id_docente = u.id_docente
    JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
     SET u.rol = 'MIEMBRO_MESA'
   WHERE m.id_proceso = p_id_proceso AND u.rol = 'DOCENTE';

  COMMIT;

  SELECT numero_mesa, orden_sorteo, rol, docente, dni
    FROM v_miembros_mesa WHERE id_proceso = p_id_proceso ORDER BY numero_mesa, orden_sorteo;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_validar_admin` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_validar_admin`(IN p_id_usuario INT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM usuario WHERE id_usuario = p_id_usuario AND rol = 'ADMIN' AND activo = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: solo un administrador activo puede realizar esta operación.';
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_validar_lista` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_validar_lista`(
  IN p_id_lista   INT,
  IN p_admitir    BOOLEAN,
  IN p_motivo     VARCHAR(500),
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_proceso   INT DEFAULT NULL;
  DECLARE v_estado    VARCHAR(20) DEFAULT NULL;
  DECLARE v_lista_est VARCHAR(20) DEFAULT NULL;
  DECLARE v_n         INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT p.id_proceso, p.estado, l.estado INTO v_proceso, v_estado, v_lista_est
    FROM lista_electoral l
    JOIN cargo_electoral c   ON c.id_cargo = l.id_cargo
    JOIN proceso_electoral p ON p.id_proceso = c.id_proceso
   WHERE l.id_lista = p_id_lista
     FOR UPDATE;

  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La lista electoral no existe.';
  END IF;
  IF v_estado <> 'INSCRIPCION' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Las listas solo se califican en etapa de INSCRIPCION.';
  END IF;
  IF v_lista_est = 'TACHADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN12: la lista quedo TACHADA por una tacha fundada; ya no se califica.';
  END IF;
  IF v_lista_est <> 'INSCRITA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La lista ya fue calificada.';
  END IF;

  IF p_admitir THEN
    SELECT COUNT(*) INTO v_n FROM candidato
     WHERE id_lista = p_id_lista AND estado_validacion <> 'EXCLUIDO';
    IF v_n = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN10: la lista no tiene candidatos inscritos.';
    END IF;
    SELECT COUNT(*) INTO v_n
      FROM tacha t JOIN candidato ca ON ca.id_candidato = t.id_candidato
     WHERE ca.id_lista = p_id_lista AND t.estado = 'PENDIENTE';
    IF v_n > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La lista tiene tachas PENDIENTES de resolver.';
    END IF;

    UPDATE candidato SET estado_validacion = 'APROBADO'
     WHERE id_lista = p_id_lista AND estado_validacion IN ('PENDIENTE','OBSERVADO');
    UPDATE lista_electoral SET estado = 'ADMITIDA', motivo_exclusion = NULL WHERE id_lista = p_id_lista;
  ELSE
    IF p_motivo IS NULL OR TRIM(p_motivo) = '' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La exclusion de una lista requiere un motivo.';
    END IF;
    UPDATE candidato SET estado_validacion = 'EXCLUIDO', motivo_exclusion = p_motivo
     WHERE id_lista = p_id_lista;
    UPDATE lista_electoral SET estado = 'EXCLUIDA', motivo_exclusion = p_motivo, orden_cedula = NULL
     WHERE id_lista = p_id_lista;
  END IF;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'VALIDAR_LISTA',
       JSON_OBJECT('id_lista', p_id_lista, 'admitida', IF(p_admitir, 'SI', 'NO'), 'motivo', p_motivo));
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_ventana_instalacion` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ventana_instalacion`(
  IN  p_id_proceso INT,
  OUT p_abierta    INT,
  OUT p_vencida    INT,
  OUT p_control    INT,
  OUT p_mensaje    VARCHAR(255)
)
BEGIN
  DECLARE v_inicio DATETIME DEFAULT NULL;
  DECLARE v_dia    DATE;
  DECLARE v_h_ini  TIME;
  DECLARE v_h_lim  TIME;
  DECLARE v_ahora  DATETIME;

  SELECT fecha_inicio INTO v_inicio FROM proceso_electoral WHERE id_proceso = p_id_proceso;
  SET p_control = COALESCE((SELECT ROUND(CAST(valor AS DECIMAL(6,2)))
                              FROM parametro_global WHERE clave = 'INSTALACION_CONTROL_HORARIO'), 1);
  SET v_h_ini = SEC_TO_TIME(ROUND(COALESCE((SELECT CAST(valor AS DECIMAL(6,2)) FROM parametro_global
                                              WHERE clave = 'INSTALACION_HORA_INICIO'), 9) * 3600));
  SET v_h_lim = SEC_TO_TIME(ROUND(COALESCE((SELECT CAST(valor AS DECIMAL(6,2)) FROM parametro_global
                                              WHERE clave = 'INSTALACION_HORA_LIMITE'), 12) * 3600));
  SET v_ahora = NOW();
  SET v_dia = DATE(v_inicio);

  IF v_inicio IS NULL THEN
    SET p_abierta = 0, p_vencida = 0, p_mensaje = 'El proceso electoral no existe.';
  ELSEIF p_control = 0 THEN
    SET p_abierta = 1, p_vencida = 0,
        p_mensaje = 'Control horario desactivado (INSTALACION_CONTROL_HORARIO = 0): se puede instalar a cualquier hora.';
  ELSEIF DATE(v_ahora) < v_dia OR (DATE(v_ahora) = v_dia AND TIME(v_ahora) < v_h_ini) THEN
    SET p_abierta = 0, p_vencida = 0,
        p_mensaje = CONCAT('RN07: la instalación empieza el ', DATE_FORMAT(v_dia, '%d/%m/%Y'),
                           ' a las ', TIME_FORMAT(v_h_ini, '%H:%i'), '.');
  ELSEIF DATE(v_ahora) = v_dia AND TIME(v_ahora) <= v_h_lim THEN
    SET p_abierta = 1, p_vencida = 0,
        p_mensaje = CONCAT('Instalación abierta hasta las ', TIME_FORMAT(v_h_lim, '%H:%i'), '.');
  ELSE
    SET p_abierta = 0, p_vencida = 1,
        p_mensaje = CONCAT('RF58: venció el plazo de instalación (', TIME_FORMAT(v_h_lim, '%H:%i'),
                           ' del ', DATE_FORMAT(v_dia, '%d/%m/%Y'), ').');
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_verificar_acta` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_verificar_acta`(IN p_token CHAR(64))
BEGIN
  SELECT a.id_acta, m.numero_mesa, a.tipo, a.fecha_emision, a.estado,
         a.hash_integridad,
         CASE WHEN SHA2(a.contenido_json, 256) = a.hash_integridad THEN 1 ELSE 0 END AS contenido_integro,
         a.contenido_json
    FROM acta_electoral a
    JOIN mesa_electoral m ON m.id_mesa = a.id_mesa
   WHERE a.token_qr_hash = SHA2(p_token, 256);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_verificar_acta_computo` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_verificar_acta_computo`(IN p_token CHAR(64))
BEGIN
  SELECT cp.id_proceso, p.nombre AS proceso, 'COMPUTO_GENERAL' AS tipo, cp.fecha_computo AS fecha_emision,
         cp.estado, cp.resultado, cp.hash_integridad,
         IF(SHA2(cp.contenido_json, 256) = cp.hash_integridad, 1, 0) AS contenido_integro, cp.contenido_json
    FROM computo_proceso cp JOIN proceso_electoral p ON p.id_proceso = cp.id_proceso
   WHERE cp.token_qr_hash = SHA2(p_token, 256)
  UNION ALL
  SELECT cp.id_proceso, p.nombre, 'PROCLAMACION', cp.fecha_proclamacion,
         cp.estado, cp.resultado, cp.hash_proclamacion,
         IF(SHA2(cp.contenido_proclamacion, 256) = cp.hash_proclamacion, 1, 0), cp.contenido_proclamacion
    FROM computo_proceso cp JOIN proceso_electoral p ON p.id_proceso = cp.id_proceso
   WHERE cp.token_proclamacion_hash = SHA2(p_token, 256);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_verificar_bitacora` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_verificar_bitacora`(IN p_id_admin INT, IN p_ip VARCHAR(45), IN p_user_agent VARCHAR(500),
                                       OUT p_estado VARCHAR(20), OUT p_registros BIGINT, OUT p_anomalias INT,
                                       OUT p_primer_id BIGINT, OUT p_hash_final CHAR(64), OUT p_id_log BIGINT)
BEGIN
  DECLARE v_fin TINYINT DEFAULT 0;
  DECLARE v_id BIGINT;
  DECLARE v_accion VARCHAR(100);
  DECLARE v_fecha DATETIME;
  DECLARE v_ant, v_hash, v_calc CHAR(64);
  DECLARE v_prev CHAR(64) DEFAULT REPEAT('0', 64);
  DECLARE v_alterados, v_rotos, v_sin_sello INT DEFAULT 0;
  DECLARE v_total BIGINT DEFAULT 0;
  DECLARE v_ultimo BIGINT DEFAULT NULL;
  DECLARE v_sello_id BIGINT;
  DECLARE v_sello_hash CHAR(64);
  DECLARE v_sello_total BIGINT;
  DECLARE v_sello_ok TINYINT DEFAULT 1;
  DECLARE v_inicio DATETIME(3) DEFAULT NOW(3);
  DECLARE c_log CURSOR FOR
    SELECT id_log, accion, fecha_hora, hash_anterior, hash_registro,
           fn_hash_bitacora(hash_anterior, id_usuario, id_docente, id_proceso, accion, ip_origen, user_agent,
                            fecha_hora, detalle_json)
      FROM log_auditoria ORDER BY id_log;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = 1;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    DROP TEMPORARY TABLE IF EXISTS tmp_bitacora_anomalia;
    RESIGNAL;
  END;

  
  CALL sp_validar_admin(p_id_admin);

  DROP TEMPORARY TABLE IF EXISTS tmp_bitacora_anomalia;
  CREATE TEMPORARY TABLE tmp_bitacora_anomalia (
    id_log  BIGINT NOT NULL,
    tipo    VARCHAR(20) NOT NULL,
    accion  VARCHAR(100) NULL,
    fecha   DATETIME NULL,
    detalle VARCHAR(300) NOT NULL
  ) ENGINE=MEMORY;

  
  START TRANSACTION WITH CONSISTENT SNAPSHOT;
  SELECT ultimo_id_log, ultimo_hash, total_registros INTO v_sello_id, v_sello_hash, v_sello_total
    FROM bitacora_cadena WHERE id_cadena = 1;

  OPEN c_log;
  recorrer: LOOP
    FETCH c_log INTO v_id, v_accion, v_fecha, v_ant, v_hash, v_calc;
    IF v_fin = 1 THEN
      LEAVE recorrer;
    END IF;
    SET v_total = v_total + 1;
    SET v_ultimo = v_id;
    IF v_hash IS NULL THEN
      SET v_sin_sello = v_sin_sello + 1;
      INSERT INTO tmp_bitacora_anomalia VALUES (v_id, 'SIN_SELLO', v_accion, v_fecha,
        'Registro sin sello: se escribió sin pasar por el trigger de la bitácora.');
    ELSE
      IF v_hash <> v_calc THEN
        SET v_alterados = v_alterados + 1;
        INSERT INTO tmp_bitacora_anomalia VALUES (v_id, 'CONTENIDO_ALTERADO', v_accion, v_fecha,
          'El contenido del registro cambió después de sellarse.');
      END IF;
      
      IF NOT (v_ant <=> v_prev) AND NOT (v_accion = 'REINICIAR_BITACORA' AND v_ant = REPEAT('0', 64)) THEN
        SET v_rotos = v_rotos + 1;
        INSERT INTO tmp_bitacora_anomalia VALUES (v_id, 'ENLACE_ROTO', v_accion, v_fecha,
          'No se enlaza con el registro anterior: falta un registro o se insertó uno por fuera de la cadena.');
      END IF;
      SET v_prev = v_hash;
    END IF;
  END LOOP;
  CLOSE c_log;
  COMMIT;

  IF v_total > 0 AND (v_sello_id IS NULL OR v_sello_id <> v_ultimo OR v_sello_hash <> v_prev) THEN
    SET v_sello_ok = 0;
    INSERT INTO tmp_bitacora_anomalia VALUES (COALESCE(v_sello_id, v_ultimo), 'FINAL_ELIMINADO', NULL, NULL,
      LEFT(CONCAT('El sello vigente indica el registro N.º ', COALESCE(v_sello_id, '—'), ' como último y la bitácora termina en el N.º ',
                  v_ultimo, ': se eliminaron o alteraron los registros finales.'), 300));
  ELSEIF v_total = 0 AND COALESCE(v_sello_total, 0) > 0 THEN
    SET v_sello_ok = 0;
    INSERT INTO tmp_bitacora_anomalia VALUES (COALESCE(v_sello_id, 0), 'FINAL_ELIMINADO', NULL, NULL,
      'El sello vigente registra entradas, pero la bitácora está vacía.');
  END IF;

  SET p_registros = v_total;
  SET p_anomalias = v_alterados + v_rotos + v_sin_sello + (1 - v_sello_ok);
  SET p_estado = IF(v_total = 0 AND p_anomalias = 0, 'VACIA', IF(p_anomalias = 0, 'INTEGRA', 'ALTERADA'));
  SET p_hash_final = IF(v_total = 0, NULL, v_prev);
  SELECT MIN(id_log) INTO p_primer_id FROM tmp_bitacora_anomalia WHERE tipo <> 'FINAL_ELIMINADO';
  IF p_primer_id IS NULL AND v_sello_ok = 0 THEN
    SET p_primer_id = v_ultimo;
  END IF;

  START TRANSACTION;
  INSERT INTO log_auditoria (id_usuario, accion, ip_origen, user_agent, detalle_json)
  VALUES (p_id_admin, 'VERIFICAR_BITACORA', p_ip, LEFT(p_user_agent, 500),
          JSON_OBJECT('resultado', p_estado, 'registros', v_total, 'contenido_alterado', v_alterados,
                      'enlaces_rotos', v_rotos, 'sin_sello', v_sin_sello, 'sello_vigente_coincide', v_sello_ok = 1,
                      'primer_registro_anomalo', p_primer_id, 'ultimo_registro', v_ultimo, 'hash_final', p_hash_final,
                      'duracion_ms', TIMESTAMPDIFF(MICROSECOND, v_inicio, NOW(3)) DIV 1000));
  SET p_id_log = LAST_INSERT_ID();
  COMMIT;

  SELECT id_log, tipo, accion, fecha, detalle FROM tmp_bitacora_anomalia ORDER BY id_log, tipo LIMIT 100;
  DROP TEMPORARY TABLE IF EXISTS tmp_bitacora_anomalia;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_verificar_constancia` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_verificar_constancia`(IN p_token CHAR(64))
BEGIN
  SELECT cv.id_constancia, p.nombre AS proceso, c.nombre AS cargo,
         CONCAT(d.nombres, ' ', d.apellidos) AS docente,
         cv.fecha_emision, cv.estado,
         CASE WHEN cv.estado = 'VIGENTE'
               AND (cv.fecha_expiracion IS NULL OR cv.fecha_expiracion >= NOW())
              THEN 1 ELSE 0 END AS es_valida
    FROM constancia_voto cv
    JOIN proceso_electoral p ON p.id_proceso = cv.id_proceso
    JOIN cargo_electoral c   ON c.id_cargo = cv.id_cargo
    JOIN docente d           ON d.id_docente = cv.id_docente
   WHERE cv.token_qr_hash = SHA2(p_token, 256);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_verificar_docente_usuario` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_verificar_docente_usuario`(IN p_id_docente INT, IN p_rol VARCHAR(20), IN p_id_usuario INT)
BEGIN
  DECLARE v_error VARCHAR(300);
  DECLARE v_aviso VARCHAR(300) DEFAULT NULL;

  SET v_error = fn_error_docente_usuario(p_id_docente, p_rol, p_id_usuario);
  IF v_error IS NULL AND p_id_docente IS NOT NULL THEN
    IF p_rol = 'MIEMBRO_MESA' AND NOT EXISTS (
         SELECT 1 FROM miembro_mesa mm JOIN mesa_electoral me ON me.id_mesa = mm.id_mesa
           JOIN proceso_electoral p ON p.id_proceso = me.id_proceso
          WHERE mm.id_docente = p_id_docente AND p.estado NOT IN ('FINALIZADO', 'ANULADO')) THEN
      SET v_aviso = 'El docente aún no figura como miembro de mesa sorteado en un proceso vigente (CUS06).';
    ELSEIF p_rol = 'PERSONERO' AND NOT EXISTS (
         SELECT 1 FROM personero pe JOIN lista_electoral l ON l.id_lista = pe.id_lista
           JOIN cargo_electoral ce ON ce.id_cargo = l.id_cargo
           JOIN proceso_electoral p ON p.id_proceso = ce.id_proceso
          WHERE pe.id_docente = p_id_docente AND pe.estado_acreditacion = 'ACREDITADO'
            AND p.estado NOT IN ('FINALIZADO', 'ANULADO')) THEN
      SET v_aviso = 'El docente aún no está acreditado como personero en un proceso vigente (CUS05).';
    ELSEIF p_rol = 'DOCENTE' AND (SELECT habilitado_para_votar FROM docente WHERE id_docente = p_id_docente) = 0 THEN
      SET v_aviso = 'El docente no está habilitado para votar (RN03): podrá ingresar, pero no figurará en el padrón.';
    END IF;
  END IF;

  SELECT d.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS docente, CONCAT(d.estado, '') AS estado,
         CONCAT(d.categoria, '') AS categoria, d.habilitado_para_votar, d.email,
         f.nombre AS facultad, dp.nombre AS departamento,
         (SELECT GROUP_CONCAT(CONCAT(u.username, ' (', u.rol, IF(u.activo = 1, '', ', inactiva'), ')')
                              ORDER BY u.id_usuario SEPARATOR ' · ')
            FROM usuario u WHERE u.id_docente = d.id_docente) AS cuentas,
         (SELECT GROUP_CONCAT(DISTINCT CONCAT('Mesa ', me.numero_mesa, ' · ', LOWER(mm.rol)) SEPARATOR ' · ')
            FROM miembro_mesa mm JOIN mesa_electoral me ON me.id_mesa = mm.id_mesa
            JOIN proceso_electoral p ON p.id_proceso = me.id_proceso
           WHERE mm.id_docente = d.id_docente AND p.estado NOT IN ('FINALIZADO', 'ANULADO')) AS mesas,
         (SELECT GROUP_CONCAT(DISTINCT CONCAT('Personero ', LOWER(pe.tipo), ' · ', l.nombre) SEPARATOR ' · ')
            FROM personero pe JOIN lista_electoral l ON l.id_lista = pe.id_lista
            JOIN cargo_electoral ce ON ce.id_cargo = l.id_cargo
            JOIN proceso_electoral p ON p.id_proceso = ce.id_proceso
           WHERE pe.id_docente = d.id_docente AND pe.estado_acreditacion = 'ACREDITADO'
             AND p.estado NOT IN ('FINALIZADO', 'ANULADO')) AS personerias,
         v_error AS error, v_aviso AS advertencia
    FROM (SELECT 1 AS x) uno
    LEFT JOIN docente d       ON d.id_docente = p_id_docente
    LEFT JOIN facultad f      ON f.id_facultad = d.id_facultad
    LEFT JOIN departamento dp ON dp.id_departamento = d.id_departamento;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_verificar_documento` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_verificar_documento`(
  IN p_codigo     VARCHAR(200),
  IN p_canal      VARCHAR(10),
  IN p_id_usuario INT,
  IN p_ip         VARCHAR(45)
)
BEGIN
  DECLARE v_codigo    CHAR(64) DEFAULT NULL;
  DECLARE v_tipo      VARCHAR(30);
  DECLARE v_id        INT;
  DECLARE v_metodo    VARCHAR(6);
  DECLARE v_proceso   INT DEFAULT NULL;
  DECLARE v_mesa      INT DEFAULT NULL;
  DECLARE v_estado    VARCHAR(20) DEFAULT NULL;
  DECLARE v_fecha     DATETIME DEFAULT NULL;
  DECLARE v_res_num   VARCHAR(40) DEFAULT NULL;
  DECLARE v_hash      CHAR(64) DEFAULT NULL;
  DECLARE v_calc      CHAR(64) DEFAULT NULL;
  DECLARE v_contenido LONGTEXT DEFAULT NULL;
  DECLARE v_vigente   TINYINT DEFAULT 1;
  DECLARE v_firmas    INT DEFAULT 0;
  DECLARE v_resultado VARCHAR(15);
  DECLARE v_canal     VARCHAR(10);
  DECLARE v_rol       VARCHAR(20) DEFAULT NULL;
  DECLARE v_id_verif  BIGINT;

  SET v_canal = UPPER(COALESCE(NULLIF(TRIM(p_canal), ''), 'QR'));
  IF v_canal NOT IN ('QR','CODIGO','LISTA','PORTAL') THEN
    SET v_canal = 'QR';
  END IF;
  IF LOWER(TRIM(p_codigo)) REGEXP '^[0-9a-f]{64}$' THEN
    SET v_codigo = LOWER(TRIM(p_codigo));
    CALL sp_localizar_documento(v_codigo, v_tipo, v_id, v_metodo);
  END IF;

  IF v_id IS NOT NULL THEN
    IF v_tipo LIKE 'ACTA\_%' THEN
      SELECT m.id_proceso, a.id_mesa, CONCAT(a.estado, ''), a.fecha_emision, a.hash_integridad,
             SHA2(a.contenido_json, 256), a.contenido_json, IF(a.estado = 'VIGENTE' AND m.estado <> 'ANULADA', 1, 0),
             (SELECT COUNT(*) FROM firma_acta f WHERE f.id_acta = a.id_acta)
        INTO v_proceso, v_mesa, v_estado, v_fecha, v_hash, v_calc, v_contenido, v_vigente, v_firmas
        FROM acta_electoral a JOIN mesa_electoral m ON m.id_mesa = a.id_mesa
       WHERE a.id_acta = v_id;
    ELSEIF v_tipo = 'COMPUTO_GENERAL' THEN
      SELECT cp.id_proceso, CONCAT(cp.estado, ''), cp.fecha_computo, cp.hash_integridad, SHA2(cp.contenido_json, 256), cp.contenido_json
        INTO v_proceso, v_estado, v_fecha, v_hash, v_calc, v_contenido
        FROM computo_proceso cp WHERE cp.id_proceso = v_id;
    ELSEIF v_tipo = 'PROCLAMACION' THEN
      SELECT cp.id_proceso, CONCAT(cp.estado, ''), cp.fecha_proclamacion, cp.numero_resolucion, cp.hash_proclamacion,
             SHA2(cp.contenido_proclamacion, 256), cp.contenido_proclamacion
        INTO v_proceso, v_estado, v_fecha, v_res_num, v_hash, v_calc, v_contenido
        FROM computo_proceso cp WHERE cp.id_proceso = v_id;
    ELSEIF v_tipo = 'RESOLUCION_NULIDAD' THEN
      SELECT n.id_proceso, n.id_mesa, CONCAT(n.estado, ''), n.fecha_resolucion, n.numero_resolucion, n.hash_integridad,
             SHA2(n.contenido_json, 256), n.contenido_json
        INTO v_proceso, v_mesa, v_estado, v_fecha, v_res_num, v_hash, v_calc, v_contenido
        FROM nulidad_electoral n WHERE n.id_nulidad = v_id;
    ELSEIF v_tipo = 'RESOLUCION_MULTAS' THEN
      
      SELECT r.id_proceso, CONCAT(r.estado, ''), r.fecha_resolucion, r.numero_resolucion, r.hash_integridad,
             SHA2(r.contenido_json, 256),
             JSON_OBJECT('tipo', 'RESOLUCION_MULTAS', 'resolucion', r.numero_resolucion, 'omisos_votacion', r.omisos_votacion,
                         'omisos_mesa', r.omisos_mesa, 'monto_total', r.monto_total, 'uit', r.uit_referencia,
                         'pct_elector', r.pct_elector, 'pct_miembro', r.pct_miembro)
        INTO v_proceso, v_estado, v_fecha, v_res_num, v_hash, v_calc, v_contenido
        FROM reporte_multas r WHERE r.id_reporte = v_id;
    ELSEIF v_tipo = 'CONSTANCIA_VOTO' THEN
      
      SELECT cv.id_proceso, CONCAT(cv.estado, ''), cv.fecha_emision,
             IF(cv.estado = 'VIGENTE' AND (cv.fecha_expiracion IS NULL OR cv.fecha_expiracion >= NOW()), 1, 0),
             JSON_OBJECT('tipo', 'CONSTANCIA_VOTO', 'cargo', c.nombre, 'docente', CONCAT(d.nombres, ' ', d.apellidos),
                         'fecha_emision', DATE_FORMAT(cv.fecha_emision, '%Y-%m-%d %H:%i:%s'))
        INTO v_proceso, v_estado, v_fecha, v_vigente, v_contenido
        FROM constancia_voto cv
        JOIN cargo_electoral c ON c.id_cargo = cv.id_cargo
        JOIN docente d         ON d.id_docente = cv.id_docente
       WHERE cv.id_constancia = v_id;
    END IF;
  END IF;

  SET v_resultado = CASE
    WHEN v_id IS NULL THEN 'NO_ENCONTRADA'
    WHEN v_tipo <> 'CONSTANCIA_VOTO' AND NOT (v_calc <=> v_hash) THEN 'ALTERADA'
    WHEN v_vigente = 0 THEN 'ANULADA'
    ELSE 'AUTENTICA' END;

  IF p_id_usuario IS NOT NULL THEN
    SELECT CONCAT(rol, '') INTO v_rol FROM usuario WHERE id_usuario = p_id_usuario;
  END IF;

  
  
  IF p_id_usuario IS NOT NULL OR v_id IS NOT NULL THEN
    INSERT INTO verificacion_documento (codigo_hash, metodo, canal, tipo_documento, id_documento, id_proceso, id_mesa,
                                        resultado, id_usuario, rol, ip, fecha)
    VALUES (SHA2(COALESCE(v_codigo, LEFT(COALESCE(p_codigo, ''), 200)), 256), v_metodo, v_canal, v_tipo, v_id, v_proceso, v_mesa,
            v_resultado, IF(v_rol IS NULL, NULL, p_id_usuario), v_rol, LEFT(p_ip, 45), NOW());
    SET v_id_verif = LAST_INSERT_ID();
  END IF;

  
  SELECT v_id_verif AS id_verificacion, v_resultado AS resultado, v_metodo AS metodo, v_tipo AS tipo_documento,
         v_id AS id_documento, v_proceso AS id_proceso, p.nombre AS proceso, CONCAT(p.tipo, '') AS tipo_proceso,
         v_mesa AS id_mesa, m.numero_mesa, m.ubicacion, v_estado AS estado, v_fecha AS fecha_emision,
         v_res_num AS numero_resolucion, v_hash AS hash_guardado, v_calc AS hash_recalculado,
         IF(v_id IS NULL OR v_tipo = 'CONSTANCIA_VOTO', NULL, IF(v_calc <=> v_hash, 1, 0)) AS contenido_integro,
         v_firmas AS firmas, fn_resultados_disponibles(v_proceso) AS resultados_publicados,
         (SELECT COUNT(*) FROM verificacion_documento v
           WHERE v.tipo_documento = v_tipo AND v.id_documento = v_id) AS veces_verificado,
         v_contenido AS contenido_json
    FROM (SELECT 1) uno
    LEFT JOIN proceso_electoral p ON p.id_proceso = v_proceso
    LEFT JOIN mesa_electoral m    ON m.id_mesa = v_mesa;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_verificar_resolucion_multas` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_verificar_resolucion_multas`(IN p_token CHAR(64))
BEGIN
  SELECT r.id_proceso, p.nombre AS proceso, r.numero_resolucion, r.fecha_resolucion, r.omisos_votacion, r.omisos_mesa,
         r.monto_total, r.uit_referencia, r.hash_integridad,
         IF(SHA2(r.contenido_json, 256) = r.hash_integridad, 1, 0) AS contenido_integro
    FROM reporte_multas r
    JOIN proceso_electoral p ON p.id_proceso = r.id_proceso
   WHERE r.token_qr_hash = SHA2(p_token, 256) AND r.estado = 'RESUELTO';
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_verificar_resolucion_nulidad` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_verificar_resolucion_nulidad`(IN p_token CHAR(64))
BEGIN
  SELECT n.id_nulidad, n.id_proceso, p.nombre AS proceso, 'RESOLUCION_NULIDAD' AS tipo, n.alcance, n.estado,
         n.numero_resolucion, n.fecha_resolucion AS fecha_emision, n.hash_integridad,
         IF(SHA2(n.contenido_json, 256) = n.hash_integridad, 1, 0) AS contenido_integro, n.contenido_json
    FROM nulidad_electoral n JOIN proceso_electoral p ON p.id_proceso = n.id_proceso
   WHERE n.token_qr_hash = SHA2(p_token, 256);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_votar_habilitado` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_votar_habilitado`(
  IN  p_id_habilitacion BIGINT,
  IN  p_token           CHAR(64),
  IN  p_id_cargo        INT,
  IN  p_id_lista        INT,
  IN  p_tipo_voto       VARCHAR(10),
  OUT p_token_constancia CHAR(64)
)
BEGIN
  DECLARE v_estado_hab VARCHAR(12) DEFAULT NULL;
  DECLARE v_hash       CHAR(64);
  DECLARE v_fecha_hab  DATETIME;
  DECLARE v_docente    INT;
  DECLARE v_proceso    INT;
  DECLARE v_mesa       INT;
  DECLARE v_mesa_est   VARCHAR(20);
  DECLARE v_estado     VARCHAR(20);
  DECLARE v_inicio     DATETIME;
  DECLARE v_fin        DATETIME;
  DECLARE v_tipo       VARCHAR(10);
  DECLARE v_hab        INT DEFAULT NULL;
  DECLARE v_ya         INT DEFAULT NULL;
  DECLARE v_n          INT DEFAULT 0;

  SET v_tipo = UPPER(TRIM(p_tipo_voto));

  
  SELECT h.estado, h.token_hash, h.fecha_habilitacion, a.id_docente, a.id_proceso, a.id_mesa
    INTO v_estado_hab, v_hash, v_fecha_hab, v_docente, v_proceso, v_mesa
    FROM habilitacion_terminal h
    JOIN asistencia_elector a ON a.id_asistencia = h.id_asistencia
   WHERE h.id_habilitacion = p_id_habilitacion
     FOR UPDATE;
  IF v_estado_hab IS NULL OR v_hash IS NULL OR v_hash <> SHA2(p_token, 256) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF67: la habilitación del terminal no es válida.';
  END IF;
  IF v_estado_hab <> 'PENDIENTE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF67: la habilitación ya fue usada o anulada.';
  END IF;

  SELECT p.estado, p.fecha_inicio, p.fecha_fin, m.estado
    INTO v_estado, v_inicio, v_fin, v_mesa_est
    FROM proceso_electoral p JOIN mesa_electoral m ON m.id_proceso = p.id_proceso
   WHERE m.id_mesa = v_mesa;
  IF v_estado <> 'VOTACION' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN06: el proceso no esta en VOTACION.';
  END IF;
  IF v_mesa_est = 'CERRADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS11: el sufragio de esta mesa ya se cerró.';
  END IF;
  IF NOW() < v_inicio OR (NOW() > v_fin AND v_fecha_hab > v_fin) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN06: fuera del horario de sufragio.';
  END IF;
  IF v_mesa_est <> 'INSTALADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF61: la mesa no esta INSTALADA.';
  END IF;

  IF v_tipo IS NULL OR v_tipo NOT IN ('VALIDO','BLANCO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN25: el voto debe ser por una lista o en BLANCO.';
  END IF;
  IF v_tipo = 'BLANCO' AND p_id_lista IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un voto en BLANCO no lleva lista.';
  END IF;
  IF v_tipo = 'VALIDO' THEN
    SELECT COUNT(*) INTO v_n FROM lista_electoral
     WHERE id_lista = p_id_lista AND id_cargo = p_id_cargo AND estado = 'ADMITIDA';
    IF v_n = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La lista elegida no esta ADMITIDA para este cargo.';
    END IF;
  END IF;

  
  SELECT habilitado_para_votar, ya_voto INTO v_hab, v_ya
    FROM padron_electoral
   WHERE id_proceso = v_proceso AND id_cargo = p_id_cargo AND id_docente = v_docente
     FOR UPDATE;
  IF v_hab IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN04: el elector no figura en el padron de este cargo.';
  END IF;
  IF v_hab = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN04: el elector no esta habilitado para votar.';
  END IF;
  IF v_ya = 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN01: el elector ya voto por este cargo.';
  END IF;

  
  UPDATE padron_electoral
     SET ya_voto = 1, fecha_votacion = DATE_FORMAT(NOW(), '%Y-%m-%d %H:00:00')
   WHERE id_proceso = v_proceso AND id_cargo = p_id_cargo AND id_docente = v_docente;

  
  INSERT INTO voto (id_proceso, id_cargo, id_lista_elegida, tipo_voto, id_mesa)
  VALUES (v_proceso, p_id_cargo, IF(v_tipo = 'VALIDO', p_id_lista, NULL), v_tipo, v_mesa);

  
  SET p_token_constancia = LOWER(HEX(fn_bytes_aleatorios(32)));
  INSERT INTO constancia_voto (id_proceso, id_docente, id_cargo, token_qr_hash)
  VALUES (v_proceso, v_docente, p_id_cargo, SHA2(p_token_constancia, 256));

  CALL sp_registrar_auditoria(NULL, v_docente, v_proceso, 'EMITIR_VOTO',
       JSON_OBJECT('id_cargo', p_id_cargo));
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Final view structure for view `v_bitacora`
--

/*!50001 DROP VIEW IF EXISTS `v_bitacora`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_bitacora` AS select `l`.`id_log` AS `id_log`,`l`.`fecha_hora` AS `fecha_hora`,`l`.`accion` AS `accion`,coalesce(`a`.`etiqueta`,replace(`l`.`accion`,'_',' ')) AS `etiqueta`,`a`.`descripcion` AS `descripcion_accion`,coalesce(`a`.`modulo`,'SIN_CLASIFICAR') AS `modulo`,`a`.`caso_uso` AS `caso_uso`,coalesce(`a`.`criticidad`,'MEDIA') AS `criticidad`,`a`.`codigo` is not null AS `catalogada`,`l`.`id_usuario` AS `id_usuario`,`u`.`username` AS `username`,`u`.`rol` AS `rol`,concat(`du`.`apellidos`,', ',`du`.`nombres`) AS `usuario_docente`,`l`.`id_docente` AS `id_docente`,concat(`d`.`apellidos`,', ',`d`.`nombres`) AS `docente`,`d`.`dni` AS `dni_docente`,`l`.`id_proceso` AS `id_proceso`,`p`.`nombre` AS `proceso`,`l`.`ip_origen` AS `ip_origen`,`l`.`user_agent` AS `user_agent`,`l`.`detalle_json` AS `detalle_json`,`l`.`hash_anterior` AS `hash_anterior`,`l`.`hash_registro` AS `hash_registro` from (((((`log_auditoria` `l` left join `bitacora_accion` `a` on(`a`.`codigo` = `l`.`accion`)) left join `usuario` `u` on(`u`.`id_usuario` = `l`.`id_usuario`)) left join `docente` `du` on(`du`.`id_docente` = `u`.`id_docente`)) left join `docente` `d` on(`d`.`id_docente` = `l`.`id_docente`)) left join `proceso_electoral` `p` on(`p`.`id_proceso` = `l`.`id_proceso`)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_candidatos_publicos`
--

/*!50001 DROP VIEW IF EXISTS `v_candidatos_publicos`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_candidatos_publicos` AS select `c`.`id_proceso` AS `id_proceso`,`c`.`nombre` AS `cargo`,`l`.`nombre` AS `lista`,`l`.`url_plan_gobierno` AS `url_plan_gobierno`,`ca`.`rol_en_lista` AS `rol_en_lista`,concat(`d`.`nombres`,' ',`d`.`apellidos`) AS `candidato`,`d`.`categoria` AS `categoria`,`d`.`grado_academico` AS `grado_academico`,`f`.`nombre` AS `facultad`,`ca`.`url_hoja_vida` AS `url_hoja_vida` from ((((`candidato` `ca` join `lista_electoral` `l` on(`l`.`id_lista` = `ca`.`id_lista` and `l`.`estado` = 'ADMITIDA')) join `cargo_electoral` `c` on(`c`.`id_cargo` = `l`.`id_cargo`)) join `docente` `d` on(`d`.`id_docente` = `ca`.`id_docente`)) join `facultad` `f` on(`f`.`id_facultad` = `d`.`id_facultad`)) where `ca`.`estado_validacion` = 'APROBADO' */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_cedula_votacion`
--

/*!50001 DROP VIEW IF EXISTS `v_cedula_votacion`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_cedula_votacion` AS select `c`.`id_proceso` AS `id_proceso`,`c`.`id_cargo` AS `id_cargo`,`c`.`nombre` AS `cargo`,`l`.`id_lista` AS `id_lista`,`l`.`orden_cedula` AS `orden_cedula`,`l`.`nombre` AS `lista`,`l`.`simbolo` AS `simbolo`,`ca`.`rol_en_lista` AS `rol_en_lista`,concat(`d`.`apellidos`,', ',`d`.`nombres`) AS `candidato` from (((`cargo_electoral` `c` join `lista_electoral` `l` on(`l`.`id_cargo` = `c`.`id_cargo` and `l`.`estado` = 'ADMITIDA')) join `candidato` `ca` on(`ca`.`id_lista` = `l`.`id_lista` and `ca`.`estado_validacion` = 'APROBADO')) join `docente` `d` on(`d`.`id_docente` = `ca`.`id_docente`)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_computo_actas`
--

/*!50001 DROP VIEW IF EXISTS `v_computo_actas`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_computo_actas` AS select `m`.`id_proceso` AS `id_proceso`,`a`.`id_mesa` AS `id_mesa`,`m`.`numero_mesa` AS `numero_mesa`,`a`.`id_acta` AS `id_acta`,`a`.`tipo` AS `tipo`,`a`.`estado` AS `estado`,`a`.`fecha_emision` AS `fecha_emision`,`a`.`hash_integridad` AS `hash_integridad`,if(sha2(`a`.`contenido_json`,256) = `a`.`hash_integridad`,1,0) AS `integra`,if(`v`.`id_acta` is null,0,1) AS `dudosa`,`v`.`motivo_duda` AS `motivo_duda`,`v`.`fecha_marca` AS `fecha_marca`,`v`.`resultado` AS `comprobacion`,`v`.`huella_coincide` AS `huella_coincide`,`v`.`qr_coincide` AS `qr_coincide`,`v`.`observacion_comprobacion` AS `observacion_comprobacion`,`v`.`fecha_comprobacion` AS `fecha_comprobacion` from ((`acta_electoral` `a` join `mesa_electoral` `m` on(`m`.`id_mesa` = `a`.`id_mesa`)) left join `verificacion_acta` `v` on(`v`.`id_acta` = `a`.`id_acta`)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_computo_conteo_mesa`
--

/*!50001 DROP VIEW IF EXISTS `v_computo_conteo_mesa`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_computo_conteo_mesa` AS select `m`.`id_proceso` AS `id_proceso`,`k`.`id_mesa` AS `id_mesa`,`m`.`numero_mesa` AS `numero_mesa`,`k`.`id_cargo` AS `id_cargo`,`k`.`opcion` AS `opcion`,`k`.`id_lista` AS `id_lista`,`k`.`votos_manual` AS `votos_acta`,(select count(0) from `v_impugnacion_efecto` `i` where `i`.`id_mesa` = `k`.`id_mesa` and `i`.`id_cargo` = `k`.`id_cargo` and `i`.`opcion_vigente` = `k`.`opcion` and (`k`.`opcion` <> 'LISTA' or `i`.`id_lista_vigente` = `k`.`id_lista`)) AS `impugnados_asignados`,`k`.`votos_manual` + (select count(0) from `v_impugnacion_efecto` `i` where `i`.`id_mesa` = `k`.`id_mesa` and `i`.`id_cargo` = `k`.`id_cargo` and `i`.`opcion_vigente` = `k`.`opcion` and (`k`.`opcion` <> 'LISTA' or `i`.`id_lista_vigente` = `k`.`id_lista`)) AS `votos`,`k`.`votos_digital` AS `votos_digital` from ((`escrutinio_conteo` `k` join `mesa_electoral` `m` on(`m`.`id_mesa` = `k`.`id_mesa`)) join `escrutinio_mesa` `e` on(`e`.`id_mesa` = `k`.`id_mesa` and `e`.`estado` in ('ACTA_EMITIDA','ENTREGADA'))) where `k`.`opcion` <> 'IMPUGNADO' union all select `m`.`id_proceso` AS `id_proceso`,`k`.`id_mesa` AS `id_mesa`,`m`.`numero_mesa` AS `numero_mesa`,`k`.`id_cargo` AS `id_cargo`,`k`.`opcion` AS `opcion`,NULL AS `NULL`,`k`.`votos_manual` AS `votos_manual`,0 AS `0`,(select count(0) from `v_impugnacion_efecto` `i` where `i`.`id_mesa` = `k`.`id_mesa` and `i`.`id_cargo` = `k`.`id_cargo` and `i`.`opcion_vigente` = 'IMPUGNADO') AS `Name_exp_9`,0 AS `0` from ((`escrutinio_conteo` `k` join `mesa_electoral` `m` on(`m`.`id_mesa` = `k`.`id_mesa`)) join `escrutinio_mesa` `e` on(`e`.`id_mesa` = `k`.`id_mesa` and `e`.`estado` in ('ACTA_EMITIDA','ENTREGADA'))) where `k`.`opcion` = 'IMPUGNADO' */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_computo_mesas`
--

/*!50001 DROP VIEW IF EXISTS `v_computo_mesas`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_computo_mesas` AS select `x`.`id_proceso` AS `id_proceso`,`x`.`id_mesa` AS `id_mesa`,`x`.`numero_mesa` AS `numero_mesa`,`x`.`ubicacion` AS `ubicacion`,`x`.`estado` AS `estado`,`x`.`total_electores` AS `total_electores`,`x`.`estado_escrutinio` AS `estado_escrutinio`,`x`.`total_votantes` AS `total_votantes`,`x`.`cedulas_escrutadas` AS `cedulas_escrutadas`,`x`.`observada` AS `observada`,`x`.`prevalece_fisica` AS `prevalece_fisica`,`x`.`conteo_cuadra` AS `conteo_cuadra`,`x`.`total_cuadra` AS `total_cuadra`,`x`.`fecha_entrega` AS `fecha_entrega`,`x`.`recibido_por` AS `recibido_por`,`x`.`codigo_cargo` AS `codigo_cargo`,`x`.`actas_vigentes` AS `actas_vigentes`,`x`.`actas_alteradas` AS `actas_alteradas`,`x`.`actas_dudosas` AS `actas_dudosas`,`x`.`actas_no_autenticas` AS `actas_no_autenticas`,`x`.`impugnaciones` AS `impugnaciones`,`x`.`impugnaciones_pendientes` AS `impugnaciones_pendientes`,`x`.`requiere_calificacion` AS `requiere_calificacion`,`x`.`calificacion` AS `calificacion`,`x`.`motivo_revision` AS `motivo_revision`,`x`.`fundamento_calificacion` AS `fundamento_calificacion`,`x`.`resolucion_calificacion` AS `resolucion_calificacion`,`x`.`fecha_calificacion` AS `fecha_calificacion`,case when `x`.`estado` = 'ANULADA' then 'ANULADA' when `x`.`estado` = 'NO_INSTALADA' then 'NO_INSTALADA' when `x`.`estado` = 'PENDIENTE' then 'SIN_INSTALAR' when `x`.`estado` = 'INSTALADA' then 'EN_SUFRAGIO' when `x`.`estado_escrutinio` is null or `x`.`estado_escrutinio` in ('CEDULAS_CONTADAS','CONTEO_REGISTRADO') then 'ESCRUTINIO_PENDIENTE' when `x`.`estado_escrutinio` = 'ACTA_EMITIDA' then 'ACTAS_SIN_ENTREGAR' when `x`.`actas_vigentes` < 3 then 'ACTAS_INCOMPLETAS' when `x`.`actas_alteradas` > 0 or `x`.`actas_no_autenticas` > 0 then 'ACTA_NO_AUTENTICA' when `x`.`actas_dudosas` > 0 then 'ACTA_DUDOSA' when `x`.`impugnaciones_pendientes` > 0 then 'IMPUGNACIONES_PENDIENTES' when `x`.`requiere_calificacion` = 1 and `x`.`calificacion` is null then 'POR_CALIFICAR' else 'HABILITADA' end AS `situacion` from (select `m`.`id_proceso` AS `id_proceso`,`m`.`id_mesa` AS `id_mesa`,`m`.`numero_mesa` AS `numero_mesa`,`m`.`ubicacion` AS `ubicacion`,`m`.`estado` AS `estado`,`m`.`total_electores` AS `total_electores`,`e`.`estado` AS `estado_escrutinio`,`e`.`total_votantes` AS `total_votantes`,`e`.`cedulas_escrutadas` AS `cedulas_escrutadas`,`e`.`observada` AS `observada`,`e`.`prevalece_fisica` AS `prevalece_fisica`,`e`.`conteo_cuadra` AS `conteo_cuadra`,`e`.`total_cuadra` AS `total_cuadra`,`e`.`fecha_entrega` AS `fecha_entrega`,`e`.`recibido_por` AS `recibido_por`,`e`.`codigo_cargo` AS `codigo_cargo`,(select count(distinct `a`.`tipo`) from `acta_electoral` `a` where `a`.`id_mesa` = `m`.`id_mesa` and `a`.`estado` = 'VIGENTE') AS `actas_vigentes`,(select count(0) from `acta_electoral` `a` where `a`.`id_mesa` = `m`.`id_mesa` and `a`.`estado` = 'VIGENTE' and sha2(`a`.`contenido_json`,256) <> `a`.`hash_integridad`) AS `actas_alteradas`,(select count(0) from `verificacion_acta` `v` where `v`.`id_mesa` = `m`.`id_mesa` and `v`.`resultado` is null) AS `actas_dudosas`,(select count(0) from `verificacion_acta` `v` where `v`.`id_mesa` = `m`.`id_mesa` and `v`.`resultado` = 'NO_AUTENTICA') AS `actas_no_autenticas`,(select count(0) from `impugnacion_electoral` `i` where `i`.`id_mesa` = `m`.`id_mesa`) AS `impugnaciones`,(select count(0) from `v_impugnacion_efecto` `i` where `i`.`id_mesa` = `m`.`id_mesa` and (`i`.`situacion` in ('PENDIENTE_MESA','EN_APELACION') or `i`.`situacion` = 'APELABLE' and coalesce((select cast(`g`.`valor` as decimal(8,2)) from `parametro_global` `g` where `g`.`clave` = 'IMPUGNACION_PLAZO_APELACION_HORAS'),24) > 0)) AS `impugnaciones_pendientes`,if(`e`.`observada` = 1 or `e`.`conteo_cuadra` = 0 or `e`.`total_cuadra` = 0,1,0) AS `requiere_calificacion`,`c`.`calificacion` AS `calificacion`,`c`.`motivo_revision` AS `motivo_revision`,`c`.`fundamento` AS `fundamento_calificacion`,`c`.`numero_resolucion` AS `resolucion_calificacion`,`c`.`fecha` AS `fecha_calificacion` from ((`mesa_electoral` `m` left join `escrutinio_mesa` `e` on(`e`.`id_mesa` = `m`.`id_mesa`)) left join `calificacion_mesa` `c` on(`c`.`id_mesa` = `m`.`id_mesa`))) `x` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_computo_resultados`
--

/*!50001 DROP VIEW IF EXISTS `v_computo_resultados`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_computo_resultados` AS select `c`.`id_proceso` AS `id_proceso`,`c`.`id_cargo` AS `id_cargo`,`c`.`nombre` AS `cargo`,`x`.`opcion` AS `opcion`,`x`.`id_lista` AS `id_lista`,coalesce(`l`.`nombre`,case `x`.`opcion` when 'BLANCO' then 'Votos en blanco' when 'NULO' then 'Votos nulos' else 'Impugnados sin resolver' end) AS `lista`,`l`.`orden_cedula` AS `orden_cedula`,count(distinct `x`.`id_mesa`) AS `mesas`,sum(`x`.`votos_acta`) AS `votos_actas`,sum(`x`.`impugnados_asignados`) AS `impugnados_asignados`,sum(`x`.`votos`) AS `votos`,sum(`x`.`votos_digital`) AS `votos_digital` from (((`v_computo_conteo_mesa` `x` join `mesa_electoral` `m` on(`m`.`id_mesa` = `x`.`id_mesa` and `m`.`estado` <> 'ANULADA')) join `cargo_electoral` `c` on(`c`.`id_cargo` = `x`.`id_cargo`)) left join `lista_electoral` `l` on(`l`.`id_lista` = `x`.`id_lista`)) group by `c`.`id_proceso`,`c`.`id_cargo`,`c`.`nombre`,`x`.`opcion`,`x`.`id_lista`,`l`.`nombre`,`l`.`orden_cedula` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_cotejos_acta`
--

/*!50001 DROP VIEW IF EXISTS `v_cotejos_acta`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_cotejos_acta` AS select `k`.`id_cotejo` AS `id_cotejo`,`k`.`id_proceso` AS `id_proceso`,`p`.`nombre` AS `proceso`,`k`.`tipo_documento` AS `tipo_documento`,`k`.`id_documento` AS `id_documento`,`k`.`id_mesa` AS `id_mesa`,`m`.`numero_mesa` AS `numero_mesa`,`k`.`hash_integridad` AS `hash_integridad`,`k`.`contenido_integro` AS `contenido_integro`,`k`.`lineas` AS `lineas`,`k`.`diferencias` AS `diferencias`,`k`.`observacion` AS `observacion`,`k`.`estado` AS `estado`,`k`.`fecha` AS `fecha`,`k`.`id_usuario` AS `id_usuario`,`u`.`username` AS `username`,`k`.`rol` AS `rol`,concat(`d`.`apellidos`,', ',`d`.`nombres`) AS `registrado_por`,`k`.`id_personero` AS `id_personero`,`l`.`nombre` AS `lista_personero`,concat(`pe`.`tipo`,'') AS `tipo_personero`,`k`.`decision` AS `decision`,`k`.`respuesta` AS `respuesta`,`k`.`fecha_respuesta` AS `fecha_respuesta`,`ur`.`username` AS `atendido_por`,`k`.`cifras_json` AS `cifras_json` from (((((((`cotejo_acta` `k` join `proceso_electoral` `p` on(`p`.`id_proceso` = `k`.`id_proceso`)) join `usuario` `u` on(`u`.`id_usuario` = `k`.`id_usuario`)) left join `docente` `d` on(`d`.`id_docente` = `u`.`id_docente`)) left join `mesa_electoral` `m` on(`m`.`id_mesa` = `k`.`id_mesa`)) left join `personero` `pe` on(`pe`.`id_personero` = `k`.`id_personero`)) left join `lista_electoral` `l` on(`l`.`id_lista` = `pe`.`id_lista`)) left join `usuario` `ur` on(`ur`.`id_usuario` = `k`.`id_usuario_respuesta`)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_cuadre_votos`
--

/*!50001 DROP VIEW IF EXISTS `v_cuadre_votos`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_cuadre_votos` AS select `c`.`id_proceso` AS `id_proceso`,`c`.`id_cargo` AS `id_cargo`,`c`.`nombre` AS `cargo`,(select count(0) from `padron_electoral` `pe` where `pe`.`id_cargo` = `c`.`id_cargo` and `pe`.`ya_voto` = 1) AS `electores_que_votaron`,(select count(0) from `voto` `v` where `v`.`id_cargo` = `c`.`id_cargo`) AS `votos_en_urna`,(select count(0) from `voto` `v` where `v`.`id_cargo` = `c`.`id_cargo`) - (select count(0) from `padron_electoral` `pe` where `pe`.`id_cargo` = `c`.`id_cargo` and `pe`.`ya_voto` = 1) AS `diferencia` from `cargo_electoral` `c` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_docente_detalle`
--

/*!50001 DROP VIEW IF EXISTS `v_docente_detalle`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_docente_detalle` AS select `d`.`id_docente` AS `id_docente`,`d`.`dni` AS `dni`,`d`.`apellidos` AS `apellidos`,`d`.`nombres` AS `nombres`,concat(`d`.`apellidos`,', ',`d`.`nombres`) AS `nombre_completo`,`d`.`categoria` AS `categoria`,`d`.`dedicacion` AS `dedicacion`,`d`.`grado_academico` AS `grado_academico`,`d`.`estado` AS `estado`,`d`.`habilitado_para_votar` AS `habilitado_para_votar`,`f`.`id_facultad` AS `id_facultad`,`f`.`nombre` AS `facultad`,`dp`.`id_departamento` AS `id_departamento`,`dp`.`nombre` AS `departamento`,`fn_tiene_cargo_excluyente`(`d`.`id_docente`) AS `es_autoridad_vigente` from ((`docente` `d` join `departamento` `dp` on(`dp`.`id_departamento` = `d`.`id_departamento`)) join `facultad` `f` on(`f`.`id_facultad` = `dp`.`id_facultad`)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_documentos_verificables`
--

/*!50001 DROP VIEW IF EXISTS `v_documentos_verificables`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_documentos_verificables` AS select `d`.`id_proceso` AS `id_proceso`,`d`.`tipo_documento` AS `tipo_documento`,`d`.`id_documento` AS `id_documento`,`d`.`id_mesa` AS `id_mesa`,`d`.`numero_mesa` AS `numero_mesa`,`d`.`numero_resolucion` AS `numero_resolucion`,`d`.`fecha_emision` AS `fecha_emision`,`d`.`estado` AS `estado`,`d`.`hash_integridad` AS `hash_integridad`,`d`.`integra` AS `integra`,`d`.`firmas` AS `firmas`,(select count(0) from `verificacion_documento` `v` where `v`.`tipo_documento` = `d`.`tipo_documento` and `v`.`id_documento` = `d`.`id_documento`) AS `verificaciones`,(select count(0) from `cotejo_acta` `k` where `k`.`tipo_documento` = `d`.`tipo_documento` and `k`.`id_documento` = `d`.`id_documento`) AS `cotejos`,(select count(0) from `cotejo_acta` `k` where `k`.`tipo_documento` = `d`.`tipo_documento` and `k`.`id_documento` = `d`.`id_documento` and `k`.`estado` = 'OBSERVADO') AS `observados` from (select `m`.`id_proceso` AS `id_proceso`,concat('ACTA_',`a`.`tipo`) AS `tipo_documento`,`a`.`id_acta` AS `id_documento`,`a`.`id_mesa` AS `id_mesa`,`m`.`numero_mesa` AS `numero_mesa`,NULL AS `numero_resolucion`,`a`.`fecha_emision` AS `fecha_emision`,concat(`a`.`estado`,'') AS `estado`,`a`.`hash_integridad` AS `hash_integridad`,if(sha2(`a`.`contenido_json`,256) = `a`.`hash_integridad`,1,0) AS `integra`,(select count(0) from `firma_acta` `f` where `f`.`id_acta` = `a`.`id_acta`) AS `firmas` from (`acta_electoral` `a` join `mesa_electoral` `m` on(`m`.`id_mesa` = `a`.`id_mesa`)) union all select `cp`.`id_proceso` AS `id_proceso`,'COMPUTO_GENERAL' AS `COMPUTO_GENERAL`,`cp`.`id_proceso` AS `id_proceso`,NULL AS `NULL`,NULL AS `NULL`,NULL AS `NULL`,`cp`.`fecha_computo` AS `fecha_computo`,concat(`cp`.`estado`,'') AS `CONCAT(cp.estado, '')`,`cp`.`hash_integridad` AS `hash_integridad`,if(sha2(`cp`.`contenido_json`,256) = `cp`.`hash_integridad`,1,0) AS `IF(SHA2(cp.contenido_json, 256) = cp.hash_integridad, 1, 0)`,0 AS `0` from `computo_proceso` `cp` where `cp`.`hash_integridad` is not null union all select `cp`.`id_proceso` AS `id_proceso`,'PROCLAMACION' AS `PROCLAMACION`,`cp`.`id_proceso` AS `id_proceso`,NULL AS `NULL`,NULL AS `NULL`,`cp`.`numero_resolucion` AS `numero_resolucion`,`cp`.`fecha_proclamacion` AS `fecha_proclamacion`,concat(`cp`.`estado`,'') AS `CONCAT(cp.estado, '')`,`cp`.`hash_proclamacion` AS `hash_proclamacion`,if(sha2(`cp`.`contenido_proclamacion`,256) = `cp`.`hash_proclamacion`,1,0),0 AS `0` from `computo_proceso` `cp` where `cp`.`hash_proclamacion` is not null union all select `n`.`id_proceso` AS `id_proceso`,'RESOLUCION_NULIDAD' AS `RESOLUCION_NULIDAD`,`n`.`id_nulidad` AS `id_nulidad`,`n`.`id_mesa` AS `id_mesa`,`m`.`numero_mesa` AS `numero_mesa`,`n`.`numero_resolucion` AS `numero_resolucion`,`n`.`fecha_resolucion` AS `fecha_resolucion`,concat(`n`.`estado`,'') AS `CONCAT(n.estado, '')`,`n`.`hash_integridad` AS `hash_integridad`,if(sha2(`n`.`contenido_json`,256) = `n`.`hash_integridad`,1,0) AS `IF(SHA2(n.contenido_json, 256) = n.hash_integridad, 1, 0)`,0 AS `0` from (`nulidad_electoral` `n` left join `mesa_electoral` `m` on(`m`.`id_mesa` = `n`.`id_mesa`)) where `n`.`hash_integridad` is not null union all select `r`.`id_proceso` AS `id_proceso`,'RESOLUCION_MULTAS' AS `RESOLUCION_MULTAS`,`r`.`id_reporte` AS `id_reporte`,NULL AS `NULL`,NULL AS `NULL`,`r`.`numero_resolucion` AS `numero_resolucion`,`r`.`fecha_resolucion` AS `fecha_resolucion`,concat(`r`.`estado`,'') AS `CONCAT(r.estado, '')`,`r`.`hash_integridad` AS `hash_integridad`,if(sha2(`r`.`contenido_json`,256) = `r`.`hash_integridad`,1,0) AS `IF(SHA2(r.contenido_json, 256) = r.hash_integridad, 1, 0)`,0 AS `0` from `reporte_multas` `r` where `r`.`estado` = 'RESUELTO' and `r`.`hash_integridad` is not null) `d` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_elegibles_sorteo`
--

/*!50001 DROP VIEW IF EXISTS `v_elegibles_sorteo`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_elegibles_sorteo` AS select distinct `pe`.`id_proceso` AS `id_proceso`,`pe`.`id_mesa` AS `id_mesa`,`d`.`id_docente` AS `id_docente`,`d`.`dni` AS `dni`,concat(`d`.`apellidos`,', ',`d`.`nombres`) AS `docente` from (`padron_electoral` `pe` join `docente` `d` on(`d`.`id_docente` = `pe`.`id_docente`)) where `pe`.`habilitado_para_votar` = 1 and `d`.`estado` = 'ACTIVO' and `fn_tiene_cargo_excluyente`(`d`.`id_docente`) = 0 and !exists(select 1 from ((`candidato` `ca` join `lista_electoral` `l` on(`l`.`id_lista` = `ca`.`id_lista`)) join `cargo_electoral` `c` on(`c`.`id_cargo` = `l`.`id_cargo`)) where `ca`.`id_docente` = `d`.`id_docente` and `c`.`id_proceso` = `pe`.`id_proceso` and `ca`.`estado_validacion` <> 'EXCLUIDO' limit 1) and !exists(select 1 from ((`personero` `p` join `lista_electoral` `l` on(`l`.`id_lista` = `p`.`id_lista`)) join `cargo_electoral` `c` on(`c`.`id_cargo` = `l`.`id_cargo`)) where `p`.`id_docente` = `d`.`id_docente` and `c`.`id_proceso` = `pe`.`id_proceso` and `p`.`estado_acreditacion` <> 'REVOCADO' limit 1) and !exists(select 1 from (`miembro_mesa` `mm` join `mesa_electoral` `m` on(`m`.`id_mesa` = `mm`.`id_mesa`)) where `mm`.`id_docente` = `d`.`id_docente` and `m`.`id_proceso` = `pe`.`id_proceso` limit 1) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_impugnacion_efecto`
--

/*!50001 DROP VIEW IF EXISTS `v_impugnacion_efecto`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_impugnacion_efecto` AS select `i`.`id_impugnacion` AS `id_impugnacion`,`i`.`id_proceso` AS `id_proceso`,`i`.`id_mesa` AS `id_mesa`,`i`.`id_cargo` AS `id_cargo`,case when `i`.`decision_ceunp` <> 'PENDIENTE' then 'FIRME' when `i`.`estado` = 'APELADA' then 'EN_APELACION' when `i`.`decision_mesa` = 'PENDIENTE' then 'PENDIENTE_MESA' when `i`.`decision_mesa` = 'ACEPTADA' then 'FIRME' when coalesce((select cast(`g`.`valor` as decimal(8,2)) from `parametro_global` `g` where `g`.`clave` = 'IMPUGNACION_PLAZO_APELACION_HORAS'),24) <= 0 or current_timestamp() <= `i`.`fecha_decision_mesa` + interval round(coalesce((select cast(`g`.`valor` as decimal(8,2)) from `parametro_global` `g` where `g`.`clave` = 'IMPUGNACION_PLAZO_APELACION_HORAS'),24) * 60,0) minute then 'APELABLE' else 'FIRME' end AS `situacion`,case when `i`.`decision_ceunp` <> 'PENDIENTE' then `i`.`opcion_final` when `i`.`estado` = 'APELADA' or `i`.`decision_mesa` = 'PENDIENTE' then 'IMPUGNADO' else `i`.`opcion_mesa` end AS `opcion_vigente`,case when `i`.`decision_ceunp` <> 'PENDIENTE' then `i`.`id_lista_final` when `i`.`estado` = 'APELADA' or `i`.`decision_mesa` = 'PENDIENTE' then NULL else `i`.`id_lista_mesa` end AS `id_lista_vigente` from `impugnacion_electoral` `i` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_impugnaciones_mesa_cargo`
--

/*!50001 DROP VIEW IF EXISTS `v_impugnaciones_mesa_cargo`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_impugnaciones_mesa_cargo` AS select `e`.`id_proceso` AS `id_proceso`,`e`.`id_mesa` AS `id_mesa`,`e`.`id_cargo` AS `id_cargo`,`e`.`opcion_vigente` AS `opcion_vigente`,`e`.`id_lista_vigente` AS `id_lista_vigente`,count(0) AS `cedulas`,sum(`e`.`situacion` = 'FIRME') AS `firmes` from `v_impugnacion_efecto` `e` group by `e`.`id_proceso`,`e`.`id_mesa`,`e`.`id_cargo`,`e`.`opcion_vigente`,`e`.`id_lista_vigente` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_mesa_detalle`
--

/*!50001 DROP VIEW IF EXISTS `v_mesa_detalle`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_mesa_detalle` AS select `m`.`id_proceso` AS `id_proceso`,`m`.`id_mesa` AS `id_mesa`,`m`.`numero_mesa` AS `numero_mesa`,`m`.`ubicacion` AS `ubicacion`,`m`.`estado` AS `estado`,`m`.`total_electores` AS `total_electores`,`m`.`hora_instalacion` AS `hora_instalacion`,`m`.`hora_cierre` AS `hora_cierre`,`m`.`fecha_sorteo` AS `fecha_sorteo`,`m`.`semilla_sorteo` AS `semilla_sorteo`,(select count(0) from `miembro_mesa` `mm` where `mm`.`id_mesa` = `m`.`id_mesa`) AS `miembros`,(select count(distinct `pe`.`id_docente`) from `padron_electoral` `pe` where `pe`.`id_mesa` = `m`.`id_mesa` and `pe`.`ya_voto` = 1) AS `electores_que_votaron`,(select count(0) from `acta_electoral` `a` where `a`.`id_mesa` = `m`.`id_mesa` and `a`.`estado` = 'VIGENTE') AS `actas_emitidas` from `mesa_electoral` `m` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_miembros_mesa`
--

/*!50001 DROP VIEW IF EXISTS `v_miembros_mesa`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_miembros_mesa` AS select `m`.`id_proceso` AS `id_proceso`,`m`.`id_mesa` AS `id_mesa`,`m`.`numero_mesa` AS `numero_mesa`,`mm`.`orden_sorteo` AS `orden_sorteo`,`mm`.`rol` AS `rol`,`mm`.`titular` AS `titular`,`mm`.`asistio` AS `asistio`,`d`.`id_docente` AS `id_docente`,`d`.`dni` AS `dni`,concat(`d`.`apellidos`,', ',`d`.`nombres`) AS `docente`,`f`.`nombre` AS `facultad` from (((`miembro_mesa` `mm` join `mesa_electoral` `m` on(`m`.`id_mesa` = `mm`.`id_mesa`)) join `docente` `d` on(`d`.`id_docente` = `mm`.`id_docente`)) join `facultad` `f` on(`f`.`id_facultad` = `d`.`id_facultad`)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_multas_detalle`
--

/*!50001 DROP VIEW IF EXISTS `v_multas_detalle`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_multas_detalle` AS select `mu`.`id_multa` AS `id_multa`,`mu`.`id_proceso` AS `id_proceso`,`p`.`nombre` AS `proceso`,`d`.`id_docente` AS `id_docente`,`d`.`dni` AS `dni`,concat(`d`.`apellidos`,', ',`d`.`nombres`) AS `docente`,`f`.`nombre` AS `facultad`,`mu`.`motivo` AS `motivo`,`mu`.`uit_referencia` AS `uit_referencia`,`mu`.`porcentaje_uit` AS `porcentaje_uit`,`mu`.`monto` AS `monto`,`mu`.`estado_pago` AS `estado_pago`,`mu`.`fecha_generacion` AS `fecha_generacion`,`mu`.`fecha_pago` AS `fecha_pago`,`p`.`tipo` AS `tipo_proceso`,`p`.`estado` AS `estado_proceso`,`dp`.`nombre` AS `departamento`,concat(`d`.`categoria`,'') AS `categoria`,`d`.`email` AS `email`,`mu`.`id_mesa` AS `id_mesa`,`m`.`numero_mesa` AS `numero_mesa`,`m`.`ubicacion` AS `ubicacion`,`mu`.`rol_mesa` AS `rol_mesa`,`mu`.`asistio_sin_votar` AS `asistio_sin_votar`,`mu`.`observacion` AS `observacion`,`mu`.`fecha_notificacion` AS `fecha_notificacion`,concat(`mu`.`medio_notificacion`,'') AS `medio_notificacion`,`mu`.`documento_notificacion` AS `documento_notificacion`,`mu`.`numero_recibo` AS `numero_recibo`,`mu`.`fecha_actualizacion` AS `fecha_actualizacion`,`r`.`estado` AS `estado_reporte`,`r`.`numero_resolucion` AS `resolucion_multas`,`r`.`fecha_resolucion` AS `fecha_resolucion_multas`,(select count(0) from `multa_justificacion` `j` where `j`.`id_multa` = `mu`.`id_multa`) AS `descargos`,`j`.`id_justificacion` AS `id_justificacion`,concat(`j`.`tipo`,'') AS `tipo_descargo`,concat(`j`.`causal`,'') AS `causal_descargo`,`j`.`decision` AS `decision_descargo`,`j`.`numero_resolucion` AS `resolucion_descargo`,`j`.`fecha_resolucion` AS `fecha_descargo`,if(`r`.`estado` = 'RESUELTO' and `g`.`dias` > 0,coalesce(`mu`.`fecha_notificacion`,`r`.`fecha_resolucion`) + interval `g`.`dias` day,NULL) AS `limite_justificacion` from ((((((((`multa` `mu` join `proceso_electoral` `p` on(`p`.`id_proceso` = `mu`.`id_proceso`)) join `docente` `d` on(`d`.`id_docente` = `mu`.`id_docente`)) join `facultad` `f` on(`f`.`id_facultad` = `d`.`id_facultad`)) left join `departamento` `dp` on(`dp`.`id_departamento` = `d`.`id_departamento`)) left join `mesa_electoral` `m` on(`m`.`id_mesa` = `mu`.`id_mesa`)) left join `reporte_multas` `r` on(`r`.`id_proceso` = `mu`.`id_proceso`)) left join `multa_justificacion` `j` on(`j`.`id_justificacion` = (select max(`x`.`id_justificacion`) from `multa_justificacion` `x` where `x`.`id_multa` = `mu`.`id_multa`))) join (select coalesce(round((select cast(`parametro_global`.`valor` as decimal(8,2)) from `parametro_global` where `parametro_global`.`clave` = 'MULTA_PLAZO_JUSTIFICACION_DIAS'),0),10) AS `dias`) `g`) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_nulidades`
--

/*!50001 DROP VIEW IF EXISTS `v_nulidades`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_nulidades` AS select `n`.`id_nulidad` AS `id_nulidad`,`n`.`id_proceso` AS `id_proceso`,`p`.`nombre` AS `proceso`,`p`.`estado` AS `estado_proceso`,`p`.`tipo` AS `tipo_proceso`,`n`.`alcance` AS `alcance`,`n`.`id_mesa` AS `id_mesa`,`m`.`numero_mesa` AS `numero_mesa`,`m`.`ubicacion` AS `ubicacion`,`m`.`estado` AS `estado_mesa`,`n`.`causal` AS `causal`,`n`.`origen` AS `origen`,`n`.`id_personero` AS `id_personero`,concat(`d`.`apellidos`,', ',`d`.`nombres`) AS `personero`,`l`.`nombre` AS `lista_personero`,concat(`pe`.`tipo`,'') AS `tipo_personero`,`n`.`sustento` AS `sustento`,`n`.`pruebas` AS `pruebas`,`n`.`etapa` AS `etapa`,`n`.`fecha_presentacion` AS `fecha_presentacion`,`ur`.`username` AS `registrado_por`,`n`.`estado` AS `estado`,`n`.`numero_resolucion` AS `numero_resolucion`,`n`.`fundamento_resolucion` AS `fundamento_resolucion`,`n`.`miembros_pleno` AS `miembros_pleno`,`n`.`votos_favor` AS `votos_favor`,`n`.`votos_contra` AS `votos_contra`,`n`.`voto_dirimente` AS `voto_dirimente`,`n`.`fecha_resolucion` AS `fecha_resolucion`,`us`.`username` AS `resuelto_por`,`n`.`hash_integridad` AS `hash_integridad`,if(`n`.`contenido_json` is null,NULL,if(sha2(`n`.`contenido_json`,256) = `n`.`hash_integridad`,1,0)) AS `resolucion_integra`,(select count(0) from `nulidad_comunicacion` `c` where `c`.`id_nulidad` = `n`.`id_nulidad`) AS `comunicaciones`,(select count(0) from `nulidad_comunicacion` `c` where `c`.`id_nulidad` = `n`.`id_nulidad` and `c`.`destinatario` in ('SUNEDU','ASAMBLEA_UNIVERSITARIA','CONSEJO_UNIVERSITARIO')) AS `comunicaciones_oficio`,(select max(`c`.`fecha_envio`) from `nulidad_comunicacion` `c` where `c`.`id_nulidad` = `n`.`id_nulidad` and `c`.`destinatario` = 'PORTAL') AS `fecha_portal` from (((((((`nulidad_electoral` `n` join `proceso_electoral` `p` on(`p`.`id_proceso` = `n`.`id_proceso`)) left join `mesa_electoral` `m` on(`m`.`id_mesa` = `n`.`id_mesa`)) left join `personero` `pe` on(`pe`.`id_personero` = `n`.`id_personero`)) left join `docente` `d` on(`d`.`id_docente` = `pe`.`id_docente`)) left join `lista_electoral` `l` on(`l`.`id_lista` = `pe`.`id_lista`)) left join `usuario` `ur` on(`ur`.`id_usuario` = `n`.`id_usuario_registro`)) left join `usuario` `us` on(`us`.`id_usuario` = `n`.`id_usuario_resolucion`)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_omisos_proceso`
--

/*!50001 DROP VIEW IF EXISTS `v_omisos_proceso`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_omisos_proceso` AS select `x`.`id_proceso` AS `id_proceso`,`x`.`id_docente` AS `id_docente`,_utf8mb4'OMISO_VOTACION' collate utf8mb4_unicode_ci AS `motivo`,`x`.`id_mesa` AS `id_mesa`,cast(NULL as char(12) charset utf8mb4) collate utf8mb4_unicode_ci AS `rol_mesa`,if(exists(select 1 from `asistencia_elector` `a` where `a`.`id_proceso` = `x`.`id_proceso` and `a`.`id_docente` = `x`.`id_docente` limit 1),1,0) AS `asistio_sin_votar` from (select `pe`.`id_proceso` AS `id_proceso`,`pe`.`id_docente` AS `id_docente`,min(`pe`.`id_mesa`) AS `id_mesa` from (`padron_electoral` `pe` join `mesa_electoral` `m` on(`m`.`id_mesa` = `pe`.`id_mesa`)) where `pe`.`habilitado_para_votar` = 1 group by `pe`.`id_proceso`,`pe`.`id_docente` having max(`pe`.`ya_voto`) = 0 and max(`m`.`hora_instalacion` is not null) = 1) `x` union all select `m`.`id_proceso` AS `id_proceso`,`mm`.`id_docente` AS `id_docente`,_utf8mb4'OMISO_MESA' collate utf8mb4_unicode_ci AS `_utf8mb4'OMISO_MESA' COLLATE utf8mb4_unicode_ci`,`m`.`id_mesa` AS `id_mesa`,convert(concat(`mm`.`rol`,'') using utf8mb4) collate utf8mb4_unicode_ci AS `Name_exp_5`,0 AS `0` from (`miembro_mesa` `mm` join `mesa_electoral` `m` on(`m`.`id_mesa` = `mm`.`id_mesa`)) where `mm`.`asistio` = 0 */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_padron_detalle`
--

/*!50001 DROP VIEW IF EXISTS `v_padron_detalle`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_padron_detalle` AS select `pe`.`id_proceso` AS `id_proceso`,`pe`.`id_cargo` AS `id_cargo`,`c`.`nombre` AS `cargo`,`pe`.`id_docente` AS `id_docente`,`d`.`dni` AS `dni`,concat(`d`.`apellidos`,', ',`d`.`nombres`) AS `docente`,`d`.`categoria` AS `categoria`,`f`.`nombre` AS `facultad`,`pe`.`habilitado_para_votar` AS `habilitado_para_votar`,`pe`.`ya_voto` AS `ya_voto`,`pe`.`fecha_votacion` AS `fecha_votacion`,`pe`.`motivo_inhabilitacion` AS `motivo_inhabilitacion`,`pe`.`id_mesa` AS `id_mesa`,`m`.`numero_mesa` AS `numero_mesa`,`m`.`ubicacion` AS `ubicacion` from ((((`padron_electoral` `pe` join `cargo_electoral` `c` on(`c`.`id_cargo` = `pe`.`id_cargo`)) join `docente` `d` on(`d`.`id_docente` = `pe`.`id_docente`)) join `facultad` `f` on(`f`.`id_facultad` = `d`.`id_facultad`)) left join `mesa_electoral` `m` on(`m`.`id_mesa` = `pe`.`id_mesa`)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_parametro_historial`
--

/*!50001 DROP VIEW IF EXISTS `v_parametro_historial`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_parametro_historial` AS select `h`.`id_historial` AS `id_historial`,`h`.`clave` AS `clave`,coalesce(`d`.`etiqueta`,`h`.`clave`) AS `etiqueta`,`d`.`unidad` AS `unidad`,`h`.`valor_anterior` AS `valor_anterior`,`h`.`valor_nuevo` AS `valor_nuevo`,`h`.`motivo` AS `motivo`,concat(`h`.`origen`,'') AS `origen`,`h`.`id_usuario` AS `id_usuario`,`u`.`username` AS `username`,`h`.`ip` AS `ip`,`h`.`fecha` AS `fecha` from ((`parametro_historial` `h` left join `parametro_definicion` `d` on(`d`.`clave` = `h`.`clave`)) left join `usuario` `u` on(`u`.`id_usuario` = `h`.`id_usuario`)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_parametros_admin`
--

/*!50001 DROP VIEW IF EXISTS `v_parametros_admin`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_parametros_admin` AS select `p`.`clave` AS `clave`,`p`.`valor` AS `valor`,`p`.`descripcion` AS `descripcion`,coalesce(concat(`d`.`grupo`,''),'OTROS') AS `grupo`,coalesce(`d`.`etiqueta`,`p`.`clave`) AS `etiqueta`,coalesce(concat(`d`.`tipo`,''),'TEXTO') AS `tipo`,`d`.`minimo` AS `minimo`,`d`.`maximo` AS `maximo`,`d`.`unidad` AS `unidad`,`d`.`referencia` AS `referencia`,coalesce(`d`.`bloqueo_jornada`,0) AS `bloqueo_jornada`,coalesce(`d`.`orden`,999) AS `orden`,coalesce(`d`.`bloqueo_jornada`,0) = 1 and `fn_jornada_en_curso`() = 1 AS `bloqueado`,(select count(0) from `parametro_historial` `h` where `h`.`clave` = `p`.`clave`) AS `cambios`,(select max(`h`.`fecha`) from `parametro_historial` `h` where `h`.`clave` = `p`.`clave`) AS `fecha_ultimo_cambio`,(select `u`.`username` from (`parametro_historial` `h` left join `usuario` `u` on(`u`.`id_usuario` = `h`.`id_usuario`)) where `h`.`clave` = `p`.`clave` order by `h`.`fecha` desc,`h`.`id_historial` desc limit 1) AS `modificado_por` from (`parametro_global` `p` left join `parametro_definicion` `d` on(`d`.`clave` = `p`.`clave`)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_participacion_cargo`
--

/*!50001 DROP VIEW IF EXISTS `v_participacion_cargo`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_participacion_cargo` AS select `c`.`id_proceso` AS `id_proceso`,`c`.`id_cargo` AS `id_cargo`,`c`.`nombre` AS `cargo`,count(`pe`.`id_docente`) AS `electores_habiles`,coalesce(sum(`pe`.`ya_voto`),0) AS `votaron`,count(`pe`.`id_docente`) - coalesce(sum(`pe`.`ya_voto`),0) AS `faltan`,case when count(`pe`.`id_docente`) = 0 then 0 else round(sum(`pe`.`ya_voto`) * 100 / count(`pe`.`id_docente`),2) end AS `participacion_pct`,`p`.`quorum_minimo` AS `quorum_minimo`,case when count(`pe`.`id_docente`) > 0 and sum(`pe`.`ya_voto`) * 100 / count(`pe`.`id_docente`) > `p`.`quorum_minimo` then 1 else 0 end AS `alcanza_quorum` from ((`cargo_electoral` `c` join `proceso_electoral` `p` on(`p`.`id_proceso` = `c`.`id_proceso`)) left join `padron_electoral` `pe` on(`pe`.`id_cargo` = `c`.`id_cargo` and `pe`.`habilitado_para_votar` = 1)) group by `c`.`id_proceso`,`c`.`id_cargo`,`c`.`nombre`,`p`.`quorum_minimo` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_portal_nulidades`
--

/*!50001 DROP VIEW IF EXISTS `v_portal_nulidades`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_portal_nulidades` AS select `n`.`id_nulidad` AS `id_nulidad`,`n`.`id_proceso` AS `id_proceso`,`p`.`nombre` AS `proceso`,`p`.`tipo` AS `tipo`,`p`.`estado` AS `estado_proceso`,`n`.`alcance` AS `alcance`,`m`.`numero_mesa` AS `numero_mesa`,`n`.`causal` AS `causal`,`n`.`numero_resolucion` AS `numero_resolucion`,`n`.`fundamento_resolucion` AS `fundamento_resolucion`,`n`.`fecha_resolucion` AS `fecha_resolucion`,`c`.`fecha_envio` AS `fecha_publicacion`,`n`.`hash_integridad` AS `hash_integridad`,(select group_concat(concat(`x`.`destinatario`,'') order by `x`.`fecha_envio` ASC separator ',') from `nulidad_comunicacion` `x` where `x`.`id_nulidad` = `n`.`id_nulidad`) AS `comunicado_a` from (((`nulidad_electoral` `n` join `proceso_electoral` `p` on(`p`.`id_proceso` = `n`.`id_proceso`)) join `nulidad_comunicacion` `c` on(`c`.`id_nulidad` = `n`.`id_nulidad` and `c`.`destinatario` = 'PORTAL')) left join `mesa_electoral` `m` on(`m`.`id_mesa` = `n`.`id_mesa`)) where `n`.`estado` = 'FUNDADA' */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_portal_resultados`
--

/*!50001 DROP VIEW IF EXISTS `v_portal_resultados`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_portal_resultados` AS select `p`.`id_proceso` AS `id_proceso`,`p`.`nombre` AS `proceso`,`p`.`tipo` AS `tipo`,`p`.`estado` AS `estado_proceso`,`cp`.`resultado` AS `resultado`,`cp`.`participacion_pct` AS `participacion_pct`,`cp`.`electores_habiles` AS `electores_habiles`,`cp`.`votaron` AS `votaron`,`cp`.`numero_resolucion` AS `numero_resolucion`,`cp`.`fecha_computo` AS `fecha_computo`,`cp`.`fecha_proclamacion` AS `fecha_proclamacion`,`cp`.`fecha_publicacion` AS `fecha_publicacion` from (`computo_proceso` `cp` join `proceso_electoral` `p` on(`p`.`id_proceso` = `cp`.`id_proceso`)) where `cp`.`estado` = 'PUBLICADO' */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_quorum_proceso`
--

/*!50001 DROP VIEW IF EXISTS `v_quorum_proceso`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_quorum_proceso` AS select `p`.`id_proceso` AS `id_proceso`,`p`.`nombre` AS `nombre`,`p`.`estado` AS `estado`,`p`.`tipo` AS `tipo`,`p`.`quorum_minimo` AS `quorum_minimo`,count(`x`.`id_docente`) AS `electores_habiles`,coalesce(sum(`x`.`voto`),0) AS `votaron`,case when count(`x`.`id_docente`) = 0 then 0 else round(sum(`x`.`voto`) * 100 / count(`x`.`id_docente`),2) end AS `participacion_pct`,case when count(`x`.`id_docente`) > 0 and sum(`x`.`voto`) * 100 / count(`x`.`id_docente`) > `p`.`quorum_minimo` then 1 else 0 end AS `alcanza_quorum` from (`proceso_electoral` `p` left join (select `padron_electoral`.`id_proceso` AS `id_proceso`,`padron_electoral`.`id_docente` AS `id_docente`,max(`padron_electoral`.`ya_voto`) AS `voto` from `padron_electoral` where `padron_electoral`.`habilitado_para_votar` = 1 group by `padron_electoral`.`id_proceso`,`padron_electoral`.`id_docente`) `x` on(`x`.`id_proceso` = `p`.`id_proceso`)) group by `p`.`id_proceso`,`p`.`nombre`,`p`.`estado`,`p`.`tipo`,`p`.`quorum_minimo` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_reporte_gestion_mesas`
--

/*!50001 DROP VIEW IF EXISTS `v_reporte_gestion_mesas`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_reporte_gestion_mesas` AS select `m`.`id_proceso` AS `id_proceso`,`m`.`id_mesa` AS `id_mesa`,`m`.`numero_mesa` AS `numero_mesa`,`m`.`ubicacion` AS `ubicacion`,`m`.`estado` AS `estado`,`m`.`hora_instalacion` AS `hora_instalacion`,`m`.`hora_cierre` AS `hora_cierre`,(select count(distinct `pe`.`id_docente`) from `padron_electoral` `pe` where `pe`.`id_mesa` = `m`.`id_mesa` and `pe`.`habilitado_para_votar` = 1) AS `electores`,(select count(distinct `pe`.`id_docente`) from `padron_electoral` `pe` where `pe`.`id_mesa` = `m`.`id_mesa` and `pe`.`habilitado_para_votar` = 1 and `pe`.`ya_voto` = 1) AS `votaron`,(select count(0) from `asistencia_elector` `a` where `a`.`id_mesa` = `m`.`id_mesa`) AS `asistieron`,(select count(0) from `miembro_mesa` `mm` where `mm`.`id_mesa` = `m`.`id_mesa` and `mm`.`titular` = 1 and `mm`.`asistio` = 1) AS `titulares_presentes`,(select count(0) from `miembro_mesa` `mm` where `mm`.`id_mesa` = `m`.`id_mesa` and `mm`.`titular` = 1 and `mm`.`asistio` = 0) AS `titulares_ausentes`,(select count(0) from `miembro_mesa` `mm` where `mm`.`id_mesa` = `m`.`id_mesa` and `mm`.`titular` = 0 and `mm`.`rol_instalacion` is not null) AS `suplentes_en_funcion`,(select count(0) from `incidencia_mesa` `i` where `i`.`id_mesa` = `m`.`id_mesa`) AS `incidencias`,(select round(avg(timestampdiff(SECOND,`a`.`hora_asistencia`,`h`.`fecha_cierre`)),0) from (`habilitacion_terminal` `h` join `asistencia_elector` `a` on(`a`.`id_asistencia` = `h`.`id_asistencia`)) where `a`.`id_mesa` = `m`.`id_mesa` and `h`.`estado` = 'CONSUMIDA') AS `atencion_promedio_seg`,(select count(distinct `ac`.`tipo`) from `acta_electoral` `ac` where `ac`.`id_mesa` = `m`.`id_mesa`) AS `actas_emitidas`,`e`.`estado` AS `estado_escrutinio`,`e`.`fecha_entrega` AS `fecha_entrega`,`e`.`recibido_por` AS `recibido_por` from (`mesa_electoral` `m` left join `escrutinio_mesa` `e` on(`e`.`id_mesa` = `m`.`id_mesa`)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_respaldos`
--

/*!50001 DROP VIEW IF EXISTS `v_respaldos`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_respaldos` AS select `r`.`id_respaldo` AS `id_respaldo`,`r`.`nombre_archivo` AS `nombre_archivo`,`r`.`motivo` AS `motivo`,`r`.`tablas` AS `tablas`,`r`.`vistas` AS `vistas`,`r`.`rutinas` AS `rutinas`,`r`.`disparadores` AS `disparadores`,`r`.`filas` AS `filas`,`r`.`tamano_bytes` AS `tamano_bytes`,`r`.`hash_sha256` AS `hash_sha256`,`r`.`id_usuario` AS `id_usuario`,`u`.`username` AS `username`,`r`.`ip` AS `ip`,`r`.`fecha_inicio` AS `fecha_inicio`,`r`.`fecha_fin` AS `fecha_fin`,timestampdiff(SECOND,`r`.`fecha_inicio`,`r`.`fecha_fin`) AS `duracion_seg` from (`respaldo_bd` `r` join `usuario` `u` on(`u`.`id_usuario` = `r`.`id_usuario`)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_resultados_cargo`
--

/*!50001 DROP VIEW IF EXISTS `v_resultados_cargo`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_resultados_cargo` AS select `c`.`id_proceso` AS `id_proceso`,`c`.`id_cargo` AS `id_cargo`,`c`.`nombre` AS `cargo`,`l`.`id_lista` AS `id_lista`,`l`.`nombre` AS `lista`,`l`.`orden_cedula` AS `orden_cedula`,count(`v`.`id_voto`) AS `votos`,`c`.`estado_resultado` AS `estado_resultado`,case when `c`.`id_lista_ganadora` = `l`.`id_lista` then 1 else 0 end AS `es_ganadora` from (((`cargo_electoral` `c` join `proceso_electoral` `p` on(`p`.`id_proceso` = `c`.`id_proceso` and `p`.`estado` in ('CERRADO','FINALIZADO'))) join `lista_electoral` `l` on(`l`.`id_cargo` = `c`.`id_cargo` and `l`.`estado` = 'ADMITIDA')) left join `voto` `v` on(`v`.`id_lista_elegida` = `l`.`id_lista` and `v`.`tipo_voto` = 'VALIDO')) group by `c`.`id_proceso`,`c`.`id_cargo`,`c`.`nombre`,`l`.`id_lista`,`l`.`nombre`,`l`.`orden_cedula`,`c`.`estado_resultado`,`c`.`id_lista_ganadora` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_resultados_mesa`
--

/*!50001 DROP VIEW IF EXISTS `v_resultados_mesa`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_resultados_mesa` AS select `x`.`id_proceso` AS `id_proceso`,`x`.`id_mesa` AS `id_mesa`,`x`.`numero_mesa` AS `numero_mesa`,concat(`m`.`estado`,'') AS `estado_mesa`,`x`.`id_cargo` AS `id_cargo`,`c`.`nombre` AS `cargo`,concat(`x`.`opcion`,'') AS `opcion`,`x`.`id_lista` AS `id_lista`,coalesce(`l`.`nombre`,case `x`.`opcion` when 'BLANCO' then 'Votos en blanco' else 'Votos nulos' end) AS `lista`,`l`.`orden_cedula` AS `orden_cedula`,`x`.`votos` AS `votos`,'ACTA_ESCRUTINIO' AS `fuente` from (((`v_computo_conteo_mesa` `x` join `mesa_electoral` `m` on(`m`.`id_mesa` = `x`.`id_mesa`)) join `cargo_electoral` `c` on(`c`.`id_cargo` = `x`.`id_cargo`)) left join `lista_electoral` `l` on(`l`.`id_lista` = `x`.`id_lista`)) where `x`.`opcion` <> 'IMPUGNADO' union all select `m`.`id_proceso` AS `id_proceso`,`m`.`id_mesa` AS `id_mesa`,`m`.`numero_mesa` AS `numero_mesa`,concat(`m`.`estado`,'') AS `CONCAT(m.estado, '')`,`v`.`id_cargo` AS `id_cargo`,`c`.`nombre` AS `nombre`,if(`v`.`tipo_voto` = 'VALIDO','LISTA',concat(`v`.`tipo_voto`,'')) AS `IF(v.tipo_voto = 'VALIDO', 'LISTA', CONCAT(v.tipo_voto, ''))`,`v`.`id_lista_elegida` AS `id_lista_elegida`,coalesce(`l`.`nombre`,if(`v`.`tipo_voto` = 'BLANCO','Votos en blanco','Votos nulos')) AS `Name_exp_9`,`l`.`orden_cedula` AS `orden_cedula`,count(0) AS `COUNT(*)`,'URNA_DIGITAL' AS `URNA_DIGITAL` from (((`voto` `v` join `mesa_electoral` `m` on(`m`.`id_mesa` = `v`.`id_mesa`)) join `cargo_electoral` `c` on(`c`.`id_cargo` = `v`.`id_cargo`)) left join `lista_electoral` `l` on(`l`.`id_lista` = `v`.`id_lista_elegida`)) where !exists(select 1 from `escrutinio_mesa` `e` where `e`.`id_mesa` = `m`.`id_mesa` and `e`.`estado` in ('ACTA_EMITIDA','ENTREGADA') limit 1) group by `m`.`id_proceso`,`m`.`id_mesa`,`m`.`numero_mesa`,`m`.`estado`,`v`.`id_cargo`,`c`.`nombre`,`v`.`tipo_voto`,`v`.`id_lista_elegida`,`l`.`nombre`,`l`.`orden_cedula` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_resultados_procesos`
--

/*!50001 DROP VIEW IF EXISTS `v_resultados_procesos`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_resultados_procesos` AS select `p`.`id_proceso` AS `id_proceso`,`p`.`nombre` AS `proceso`,`p`.`tipo` AS `tipo`,`p`.`estado` AS `estado_proceso`,`p`.`id_proceso_padre` AS `id_proceso_padre`,`pp`.`nombre` AS `proceso_padre`,if(`cp`.`id_proceso` is null,'HEREDADO','CUS14') AS `origen`,coalesce(concat(`cp`.`resultado`,''),if(`p`.`estado` = 'ANULADO','NULIDAD_TOTAL','VALIDA')) AS `resultado`,coalesce(`cp`.`electores_habiles`,`q`.`electores_habiles`) AS `electores_habiles`,coalesce(`cp`.`votaron`,`q`.`votaron`) AS `votaron`,coalesce(`cp`.`participacion_pct`,`q`.`participacion_pct`) AS `participacion_pct`,`p`.`quorum_minimo` AS `quorum_minimo`,`cp`.`mesas_total` AS `mesas_total`,`cp`.`mesas_computadas` AS `mesas_computadas`,`cp`.`mesas_anuladas` AS `mesas_anuladas`,`cp`.`mesas_no_instaladas` AS `mesas_no_instaladas`,`cp`.`numero_resolucion` AS `numero_resolucion`,coalesce(`cp`.`fecha_computo`,(select max(`r`.`fecha_computo`) from `resultado_electoral` `r` where `r`.`id_proceso` = `p`.`id_proceso`)) AS `fecha_computo`,`cp`.`fecha_proclamacion` AS `fecha_proclamacion`,`cp`.`fecha_publicacion` AS `fecha_publicacion`,(select count(0) from `cargo_electoral` `c` where `c`.`id_proceso` = `p`.`id_proceso`) AS `cargos`,(select count(0) from `mesa_electoral` `m` where `m`.`id_proceso` = `p`.`id_proceso`) AS `mesas` from (((`proceso_electoral` `p` left join `proceso_electoral` `pp` on(`pp`.`id_proceso` = `p`.`id_proceso_padre`)) left join `computo_proceso` `cp` on(`cp`.`id_proceso` = `p`.`id_proceso`)) left join `v_quorum_proceso` `q` on(`q`.`id_proceso` = `p`.`id_proceso`)) where `fn_resultados_disponibles`(`p`.`id_proceso`) = 1 */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_segunda_vuelta_procesos`
--

/*!50001 DROP VIEW IF EXISTS `v_segunda_vuelta_procesos`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_segunda_vuelta_procesos` AS select `h`.`id_proceso` AS `id_proceso`,`h`.`nombre` AS `nombre`,`h`.`estado` AS `estado`,`h`.`fecha_inicio` AS `fecha_inicio`,`h`.`fecha_fin` AS `fecha_fin`,`h`.`fecha_creacion` AS `fecha_creacion`,`h`.`motivo_anulacion` AS `motivo_anulacion`,`h`.`id_proceso_padre` AS `id_proceso_padre`,`p`.`nombre` AS `proceso_padre`,`cp`.`fecha_computo` AS `fecha_computo_padre`,(select count(0) from `cargo_electoral` `c` where `c`.`id_proceso` = `h`.`id_proceso`) AS `cargos`,(select count(0) from (`lista_electoral` `l` join `cargo_electoral` `c` on(`c`.`id_cargo` = `l`.`id_cargo`)) where `c`.`id_proceso` = `h`.`id_proceso`) AS `listas`,(select count(0) from `padron_electoral` `e` where `e`.`id_proceso` = `h`.`id_proceso`) AS `padron`,(select count(0) from `mesa_electoral` `m` where `m`.`id_proceso` = `h`.`id_proceso`) AS `mesas`,`hc`.`estado` AS `estado_computo` from (((`proceso_electoral` `h` join `proceso_electoral` `p` on(`p`.`id_proceso` = `h`.`id_proceso_padre`)) left join `computo_proceso` `cp` on(`cp`.`id_proceso` = `p`.`id_proceso`)) left join `computo_proceso` `hc` on(`hc`.`id_proceso` = `h`.`id_proceso`)) where `h`.`tipo` = 'SEGUNDA_VUELTA' */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_tachas_detalle`
--

/*!50001 DROP VIEW IF EXISTS `v_tachas_detalle`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_tachas_detalle` AS select `t`.`id_tacha` AS `id_tacha`,`c`.`id_proceso` AS `id_proceso`,`c`.`nombre` AS `cargo`,`l`.`id_lista` AS `id_lista`,`l`.`nombre` AS `lista`,`ca`.`id_candidato` AS `id_candidato`,`ca`.`rol_en_lista` AS `rol_en_lista`,concat(`dc`.`apellidos`,', ',`dc`.`nombres`) AS `candidato`,concat(`dd`.`apellidos`,', ',`dd`.`nombres`) AS `denunciante`,`t`.`motivo` AS `motivo`,`t`.`estado` AS `estado`,`t`.`fecha_presentacion` AS `fecha_presentacion`,`t`.`fecha_resolucion` AS `fecha_resolucion`,`t`.`resolucion` AS `resolucion` from (((((`tacha` `t` join `candidato` `ca` on(`ca`.`id_candidato` = `t`.`id_candidato`)) join `lista_electoral` `l` on(`l`.`id_lista` = `ca`.`id_lista`)) join `cargo_electoral` `c` on(`c`.`id_cargo` = `l`.`id_cargo`)) join `docente` `dc` on(`dc`.`id_docente` = `ca`.`id_docente`)) join `docente` `dd` on(`dd`.`id_docente` = `t`.`id_docente_denunciante`)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_usuarios_admin`
--

/*!50001 DROP VIEW IF EXISTS `v_usuarios_admin`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_usuarios_admin` AS select `u`.`id_usuario` AS `id_usuario`,`u`.`username` AS `username`,concat(`u`.`rol`,'') AS `rol`,`u`.`activo` AS `activo`,`u`.`debe_cambiar_password` AS `debe_cambiar_password`,`u`.`intentos_fallidos` AS `intentos_fallidos`,`u`.`bloqueado_hasta` AS `bloqueado_hasta`,`u`.`bloqueado_hasta` is not null and `u`.`bloqueado_hasta` > current_timestamp() AS `bloqueada`,`u`.`ultimo_acceso` AS `ultimo_acceso`,`u`.`fecha_creacion` AS `fecha_creacion`,`u`.`fecha_actualizacion` AS `fecha_actualizacion`,`u`.`motivo_estado` AS `motivo_estado`,`u`.`id_usuario_creador` AS `id_usuario_creador`,`c`.`username` AS `creado_por`,`u`.`id_docente` AS `id_docente`,`d`.`dni` AS `dni`,concat(`d`.`apellidos`,', ',`d`.`nombres`) AS `docente`,concat(`d`.`estado`,'') AS `estado_docente`,concat(`d`.`categoria`,'') AS `categoria`,`d`.`email` AS `email`,`f`.`nombre` AS `facultad`,`dp`.`nombre` AS `departamento`,(select count(0) from `log_auditoria` `l` where `l`.`id_usuario` = `u`.`id_usuario`) AS `actividad`,`mm`.`rol` AS `cargo_mesa`,`mm`.`titular` AS `es_titular_mesa`,`mm`.`id_mesa` AS `id_mesa_asignada`,`me`.`numero_mesa` AS `numero_mesa` from ((((((`usuario` `u` left join `usuario` `c` on(`c`.`id_usuario` = `u`.`id_usuario_creador`)) left join `docente` `d` on(`d`.`id_docente` = `u`.`id_docente`)) left join `facultad` `f` on(`f`.`id_facultad` = `d`.`id_facultad`)) left join `departamento` `dp` on(`dp`.`id_departamento` = `d`.`id_departamento`)) left join `mesa_electoral` `me` on(`me`.`id_mesa` = (select `mm2`.`id_mesa` from ((`miembro_mesa` `mm2` join `mesa_electoral` `m2` on(`m2`.`id_mesa` = `mm2`.`id_mesa`)) join `proceso_electoral` `p2` on(`p2`.`id_proceso` = `m2`.`id_proceso`)) where `mm2`.`id_docente` = `u`.`id_docente` and `u`.`rol` = 'MIEMBRO_MESA' and `p2`.`estado` not in ('FINALIZADO','ANULADO') order by `p2`.`id_proceso` desc,`m2`.`id_mesa` desc limit 1))) left join `miembro_mesa` `mm` on(`mm`.`id_mesa` = `me`.`id_mesa` and `mm`.`id_docente` = `u`.`id_docente`)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vista_quorum`
--

/*!50001 DROP VIEW IF EXISTS `vista_quorum`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vista_quorum` AS select `v_quorum_proceso`.`id_proceso` AS `id_proceso`,`v_quorum_proceso`.`nombre` AS `nombre`,`v_quorum_proceso`.`estado` AS `estado`,`v_quorum_proceso`.`tipo` AS `tipo`,`v_quorum_proceso`.`quorum_minimo` AS `quorum_minimo`,`v_quorum_proceso`.`electores_habiles` AS `electores_habiles`,`v_quorum_proceso`.`votaron` AS `votaron`,`v_quorum_proceso`.`participacion_pct` AS `participacion_pct`,`v_quorum_proceso`.`alcanza_quorum` AS `alcanza_quorum` from `v_quorum_proceso` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-11-25 20:54:37
