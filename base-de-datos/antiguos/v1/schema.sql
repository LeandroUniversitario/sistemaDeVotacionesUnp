-- Sistema de Elecciones Docentes UNP
-- MySQL/MariaDB 10.4+
-- Importar este archivo desde phpMyAdmin.

CREATE DATABASE IF NOT EXISTS elecciones_unp
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE elecciones_unp;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS impugnacion_electoral;
DROP TABLE IF EXISTS observacion_electoral;
DROP TABLE IF EXISTS sesion_activa;
DROP TABLE IF EXISTS log_auditoria;
DROP TABLE IF EXISTS constancia_voto;
DROP TABLE IF EXISTS firma_acta;
DROP TABLE IF EXISTS acta_electoral;
DROP TABLE IF EXISTS voto;
DROP TABLE IF EXISTS padron_mesa;
DROP TABLE IF EXISTS miembro_mesa;
DROP TABLE IF EXISTS mesa_electoral;
DROP TABLE IF EXISTS mesa_sufragio;
DROP TABLE IF EXISTS padron_electoral;
DROP TABLE IF EXISTS personero;
DROP TABLE IF EXISTS tacha;
DROP TABLE IF EXISTS candidato;
DROP TABLE IF EXISTS lista_electoral;
DROP TABLE IF EXISTS cargo_categoria_permitida;
DROP TABLE IF EXISTS cargo_electoral;
DROP TABLE IF EXISTS proceso_electoral;
DROP TABLE IF EXISTS cargo_excluido_sorteo;
DROP TABLE IF EXISTS cargo_admin;
DROP TABLE IF EXISTS usuario;
DROP TABLE IF EXISTS docente;
DROP TABLE IF EXISTS departamento;
DROP TABLE IF EXISTS facultad;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE facultad (
  id_facultad INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE departamento (
  id_departamento INT AUTO_INCREMENT PRIMARY KEY,
  id_facultad INT NOT NULL,
  nombre VARCHAR(150) NOT NULL,
  UNIQUE KEY uq_departamento_facultad (id_facultad, nombre),
  CONSTRAINT fk_departamento_facultad FOREIGN KEY (id_facultad) REFERENCES facultad(id_facultad)
) ENGINE=InnoDB;

CREATE TABLE docente (
  id_docente INT AUTO_INCREMENT PRIMARY KEY,
  dni VARCHAR(8) NOT NULL UNIQUE,
  nombres VARCHAR(100) NOT NULL,
  apellidos VARCHAR(150) NOT NULL,
  categoria ENUM('PRINCIPAL','ASOCIADO','AUXILIAR') NOT NULL,
  dedicacion VARCHAR(80) NOT NULL,
  estado ENUM('ACTIVO','LICENCIA','SUSPENDIDO') NOT NULL DEFAULT 'ACTIVO',
  habilitado_para_votar BOOLEAN NOT NULL DEFAULT TRUE,
  id_facultad INT NOT NULL,
  id_departamento INT NOT NULL,
  CONSTRAINT fk_docente_facultad FOREIGN KEY (id_facultad) REFERENCES facultad(id_facultad),
  CONSTRAINT fk_docente_departamento FOREIGN KEY (id_departamento) REFERENCES departamento(id_departamento)
) ENGINE=InnoDB;

CREATE TABLE parametro_global (
  clave VARCHAR(80) NOT NULL PRIMARY KEY,
  valor VARCHAR(255) NOT NULL,
  descripcion VARCHAR(500) NULL
) ENGINE=InnoDB;

CREATE TABLE cargo_admin (
  id_cargo_admin INT AUTO_INCREMENT PRIMARY KEY,
  id_docente INT NOT NULL,
  nombre_cargo VARCHAR(150) NOT NULL,
  nivel VARCHAR(80) NOT NULL,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NULL,
  vigente BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT fk_cargo_admin_docente FOREIGN KEY (id_docente) REFERENCES docente(id_docente)
) ENGINE=InnoDB;

CREATE TABLE cargo_excluido_sorteo (
  id_cargo_excluido INT AUTO_INCREMENT PRIMARY KEY,
  nombre_cargo VARCHAR(150) NOT NULL UNIQUE,
  nivel VARCHAR(80) NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE proceso_electoral (
  id_proceso INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(200) NOT NULL,
  fecha_inicio DATETIME NOT NULL,
  fecha_fin DATETIME NOT NULL,
  estado ENUM('CREADO','INSCRIPCION','VOTACION','CERRADO','FINALIZADO','ANULADO') NOT NULL DEFAULT 'CREADO',
  tipo ENUM('PRIMERA_VUELTA','SEGUNDA_VUELTA') NOT NULL DEFAULT 'PRIMERA_VUELTA',
  id_proceso_padre INT NULL,
  quorum_minimo DECIMAL(5,2) NOT NULL DEFAULT 60.00,
  CONSTRAINT fk_proceso_padre FOREIGN KEY (id_proceso_padre) REFERENCES proceso_electoral(id_proceso)
) ENGINE=InnoDB;

CREATE TABLE cargo_electoral (
  id_cargo INT AUTO_INCREMENT PRIMARY KEY,
  id_proceso INT NOT NULL,
  nombre VARCHAR(150) NOT NULL,
  nivel_jurisdiccion ENUM('UNIVERSIDAD','FACULTAD','DEPARTAMENTO') NOT NULL,
  id_jurisdiccion INT NULL,
  CONSTRAINT fk_cargo_proceso FOREIGN KEY (id_proceso) REFERENCES proceso_electoral(id_proceso)
) ENGINE=InnoDB;

CREATE TABLE cargo_categoria_permitida (
  id_cargo INT NOT NULL,
  categoria ENUM('PRINCIPAL','ASOCIADO','AUXILIAR') NOT NULL,
  PRIMARY KEY (id_cargo, categoria),
  CONSTRAINT fk_categoria_cargo FOREIGN KEY (id_cargo) REFERENCES cargo_electoral(id_cargo)
) ENGINE=InnoDB;

CREATE TABLE lista_electoral (
  id_lista INT AUTO_INCREMENT PRIMARY KEY,
  id_cargo INT NOT NULL,
  nombre VARCHAR(150) NOT NULL,
  simbolo VARCHAR(100) NULL,
  orden_cedula INT NULL,
  estado ENUM('INSCRITA','ADMITIDA','TACHADA','EXCLUIDA') NOT NULL DEFAULT 'INSCRITA',
  fecha_inscripcion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_lista_cargo FOREIGN KEY (id_cargo) REFERENCES cargo_electoral(id_cargo)
) ENGINE=InnoDB;

CREATE TABLE candidato (
  id_candidato INT AUTO_INCREMENT PRIMARY KEY,
  id_lista INT NOT NULL,
  id_docente INT NOT NULL,
  rol_en_lista VARCHAR(100) NOT NULL,
  estado_validacion ENUM('PENDIENTE','APROBADO','OBSERVADO','EXCLUIDO') NOT NULL DEFAULT 'PENDIENTE',
  fecha_inscripcion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_candidato_lista_docente (id_lista, id_docente),
  CONSTRAINT fk_candidato_lista FOREIGN KEY (id_lista) REFERENCES lista_electoral(id_lista),
  CONSTRAINT fk_candidato_docente FOREIGN KEY (id_docente) REFERENCES docente(id_docente)
) ENGINE=InnoDB;

CREATE TABLE tacha (
  id_tacha INT AUTO_INCREMENT PRIMARY KEY,
  id_docente_denunciante INT NOT NULL,
  id_candidato INT NOT NULL,
  motivo TEXT NOT NULL,
  estado ENUM('PENDIENTE','FUNDADA','INFUNDADA') NOT NULL DEFAULT 'PENDIENTE',
  fecha_presentacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_resolucion DATETIME NULL,
  CONSTRAINT fk_tacha_denunciante FOREIGN KEY (id_docente_denunciante) REFERENCES docente(id_docente),
  CONSTRAINT fk_tacha_candidato FOREIGN KEY (id_candidato) REFERENCES candidato(id_candidato)
) ENGINE=InnoDB;

-- Tabla de mesa de sufragio (generada por JPA/Hibernate)
CREATE TABLE mesa_sufragio (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  estado ENUM('ANULADA','CERRADA','INSTALADA','PENDIENTE') NOT NULL,
  hora_cierre DATETIME(6) NULL,
  hora_instalacion DATETIME(6) NULL,
  numero VARCHAR(10) NOT NULL UNIQUE,
  total_electores INT NULL,
  proceso_id INT NOT NULL,
  id_proceso INT NOT NULL,
  CONSTRAINT FK1bf6etm8bi8sxes9s2k6k49y1 FOREIGN KEY (proceso_id) REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT FKeun7mw7vyp6j7mlf69rki318c FOREIGN KEY (id_proceso) REFERENCES proceso_electoral(id_proceso)
) ENGINE=InnoDB;

-- Tabla de padrón de mesa de sufragio (generada por JPA/Hibernate)
CREATE TABLE padron_mesa (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  habilitado BIT(1) NULL,
  hora_voto DATETIME(6) NULL,
  ya_voto BIT(1) NULL,
  docente_id INT NOT NULL,
  mesa_id BIGINT NOT NULL,
  id_docente INT NOT NULL,
  id_mesa BIGINT NOT NULL,
  CONSTRAINT FKaj5kxhye89ik3uhcvjykmglc9 FOREIGN KEY (docente_id) REFERENCES docente(id_docente),
  CONSTRAINT FKdpcy50hsdqex1x63tnckj4gcc FOREIGN KEY (id_docente) REFERENCES docente(id_docente),
  CONSTRAINT FKoye8231yoxjincaxyou0v229i FOREIGN KEY (mesa_id) REFERENCES mesa_sufragio(id)
) ENGINE=InnoDB;

CREATE TABLE mesa_electoral (
  id_mesa INT AUTO_INCREMENT PRIMARY KEY,
  id_proceso INT NOT NULL,
  numero_mesa VARCHAR(30) NOT NULL,
  ubicacion VARCHAR(200) NOT NULL,
  semilla_sorteo VARCHAR(128) NOT NULL,
  fecha_sorteo DATETIME NULL,
  UNIQUE KEY uq_mesa_proceso_numero (id_proceso, numero_mesa),
  CONSTRAINT fk_mesa_proceso FOREIGN KEY (id_proceso) REFERENCES proceso_electoral(id_proceso)
) ENGINE=InnoDB;

CREATE TABLE personero (
  id_personero INT AUTO_INCREMENT PRIMARY KEY,
  id_lista INT NOT NULL,
  id_docente INT NOT NULL,
  tipo ENUM('GENERAL','ALTERNO','MESA') NOT NULL,
  id_mesa INT NULL,
  estado_acreditacion ENUM('PENDIENTE','ACREDITADO','REVOCADO') NOT NULL DEFAULT 'PENDIENTE',
  fecha_acreditacion DATETIME NULL,
  CONSTRAINT fk_personero_lista FOREIGN KEY (id_lista) REFERENCES lista_electoral(id_lista),
  CONSTRAINT fk_personero_docente FOREIGN KEY (id_docente) REFERENCES docente(id_docente),
  CONSTRAINT fk_personero_mesa FOREIGN KEY (id_mesa) REFERENCES mesa_electoral(id_mesa)
) ENGINE=InnoDB;

CREATE TABLE padron_electoral (
  id_proceso INT NOT NULL,
  id_cargo INT NOT NULL,
  id_docente INT NOT NULL,
  habilitado_para_votar BOOLEAN NOT NULL DEFAULT TRUE,
  ya_voto BOOLEAN NOT NULL DEFAULT FALSE,
  fecha_votacion DATETIME NULL,
  motivo_inhabilitacion VARCHAR(255) NULL,
  fecha_generacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_proceso, id_cargo, id_docente),
  CONSTRAINT fk_padron_proceso FOREIGN KEY (id_proceso) REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_padron_cargo FOREIGN KEY (id_cargo) REFERENCES cargo_electoral(id_cargo),
  CONSTRAINT fk_padron_docente FOREIGN KEY (id_docente) REFERENCES docente(id_docente)
) ENGINE=InnoDB;

CREATE TABLE miembro_mesa (
  id_mesa INT NOT NULL,
  id_docente INT NOT NULL,
  rol ENUM('PRESIDENTE','SECRETARIO','VOCAL','SUPLENTE') NOT NULL,
  titular BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id_mesa, id_docente),
  CONSTRAINT fk_miembro_mesa FOREIGN KEY (id_mesa) REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_miembro_docente FOREIGN KEY (id_docente) REFERENCES docente(id_docente)
) ENGINE=InnoDB;

CREATE TABLE voto (
  id_voto BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_proceso INT NOT NULL,
  id_cargo INT NOT NULL,
  id_lista_elegida INT NULL,
  tipo_voto ENUM('VALIDO','BLANCO','NULO') NOT NULL,
  fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_voto_proceso FOREIGN KEY (id_proceso) REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_voto_cargo FOREIGN KEY (id_cargo) REFERENCES cargo_electoral(id_cargo),
  CONSTRAINT fk_voto_lista FOREIGN KEY (id_lista_elegida) REFERENCES lista_electoral(id_lista)
) ENGINE=InnoDB;

CREATE TABLE acta_electoral (
  id_acta INT AUTO_INCREMENT PRIMARY KEY,
  id_mesa INT NOT NULL,
  tipo ENUM('INSTALACION','SUFRAGIO','ESCRUTINIO') NOT NULL,
  contenido_json JSON NOT NULL,
  hash_integridad CHAR(64) NOT NULL,
  token_qr_hash CHAR(64) NOT NULL UNIQUE,
  fecha_emision DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado ENUM('VIGENTE','ANULADA') NOT NULL DEFAULT 'VIGENTE',
  UNIQUE KEY uq_acta_mesa_tipo (id_mesa, tipo),
  CONSTRAINT fk_acta_mesa FOREIGN KEY (id_mesa) REFERENCES mesa_electoral(id_mesa)
) ENGINE=InnoDB;

CREATE TABLE firma_acta (
  id_firma INT AUTO_INCREMENT PRIMARY KEY,
  id_acta INT NOT NULL,
  id_docente INT NOT NULL,
  rol VARCHAR(80) NOT NULL,
  firma_digital TEXT NULL,
  fecha_firma DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_firma_acta_docente (id_acta, id_docente),
  CONSTRAINT fk_firma_acta FOREIGN KEY (id_acta) REFERENCES acta_electoral(id_acta),
  CONSTRAINT fk_firma_docente FOREIGN KEY (id_docente) REFERENCES docente(id_docente)
) ENGINE=InnoDB;

CREATE TABLE usuario (
  id_usuario INT AUTO_INCREMENT PRIMARY KEY,
  id_docente INT NULL,
  username VARCHAR(80) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  rol ENUM('ADMIN','CEUNP','DOCENTE','PERSONERO','MIEMBRO_MESA') NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT fk_usuario_docente FOREIGN KEY (id_docente) REFERENCES docente(id_docente)
) ENGINE=InnoDB;

CREATE TABLE constancia_voto (
  id_constancia BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_proceso INT NOT NULL,
  id_docente INT NOT NULL,
  id_cargo INT NOT NULL,
  token_qr_hash CHAR(64) NOT NULL UNIQUE,
  fecha_emision DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_expiracion DATETIME NULL,
  estado ENUM('VIGENTE','REVOCADA') NOT NULL DEFAULT 'VIGENTE',
  UNIQUE KEY uq_constancia_participacion (id_proceso, id_docente, id_cargo),
  CONSTRAINT fk_constancia_proceso FOREIGN KEY (id_proceso) REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_constancia_docente FOREIGN KEY (id_docente) REFERENCES docente(id_docente),
  CONSTRAINT fk_constancia_cargo FOREIGN KEY (id_cargo) REFERENCES cargo_electoral(id_cargo)
) ENGINE=InnoDB;

CREATE TABLE sesion_activa (
  id_sesion BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_usuario INT NOT NULL,
  token_hash CHAR(64) NOT NULL UNIQUE,
  fecha_inicio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_expiracion DATETIME NOT NULL,
  revocada BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT fk_sesion_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB;

CREATE TABLE log_auditoria (
  id_log BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_usuario INT NULL,
  id_docente INT NULL,
  id_proceso INT NULL,
  accion VARCHAR(100) NOT NULL,
  ip_origen VARCHAR(45) NULL,
  user_agent VARCHAR(500) NULL,
  fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  detalle_json JSON NULL,
  CONSTRAINT fk_log_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
  CONSTRAINT fk_log_docente FOREIGN KEY (id_docente) REFERENCES docente(id_docente),
  CONSTRAINT fk_log_proceso FOREIGN KEY (id_proceso) REFERENCES proceso_electoral(id_proceso)
) ENGINE=InnoDB;

CREATE TABLE observacion_electoral (
  id_observacion BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_personero INT NOT NULL,
  id_proceso INT NOT NULL,
  id_mesa INT NULL,
  id_acta INT NULL,
  descripcion TEXT NOT NULL,
  estado ENUM('PENDIENTE','ATENDIDA','RECHAZADA') NOT NULL DEFAULT 'PENDIENTE',
  respuesta_ceunp TEXT NULL,
  fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_respuesta DATETIME NULL,
  CONSTRAINT fk_observacion_personero FOREIGN KEY (id_personero) REFERENCES personero(id_personero),
  CONSTRAINT fk_observacion_proceso FOREIGN KEY (id_proceso) REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_observacion_mesa FOREIGN KEY (id_mesa) REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_observacion_acta FOREIGN KEY (id_acta) REFERENCES acta_electoral(id_acta)
) ENGINE=InnoDB;

CREATE TABLE impugnacion_electoral (
  id_impugnacion BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_personero INT NOT NULL,
  id_proceso INT NOT NULL,
  id_mesa INT NOT NULL,
  id_acta INT NULL,
  motivo TEXT NOT NULL,
  decision_mesa ENUM('PENDIENTE','ACEPTADA','RECHAZADA') NOT NULL DEFAULT 'PENDIENTE',
  decision_ceunp ENUM('PENDIENTE','CONFIRMADA','MODIFICADA') NOT NULL DEFAULT 'PENDIENTE',
  estado ENUM('PRESENTADA','RESUELTA','APELADA') NOT NULL DEFAULT 'PRESENTADA',
  fecha_presentacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_resolucion DATETIME NULL,
  CONSTRAINT fk_impugnacion_personero FOREIGN KEY (id_personero) REFERENCES personero(id_personero),
  CONSTRAINT fk_impugnacion_proceso FOREIGN KEY (id_proceso) REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_impugnacion_mesa FOREIGN KEY (id_mesa) REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_impugnacion_acta FOREIGN KEY (id_acta) REFERENCES acta_electoral(id_acta)
) ENGINE=InnoDB;
