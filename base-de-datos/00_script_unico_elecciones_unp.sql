-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS
-- 00_script_unico_elecciones_unp.sql  ·  Script único de creación (versión final)
-- Motor: MariaDB 10.4+ (XAMPP / phpMyAdmin)
--
-- Crea la base elecciones_unp desde cero con la versión final de cada objeto,
-- CUS01 a CUS19 incluidos (firmas de actas, escrutinio, impugnaciones, cómputo,
-- nulidades, multas, verificación de actas, administración y bitácora).
-- No hace falta importar ningún otro script después de este.
--
-- Contenido: 56 tablas, 10 funciones, 79 triggers, 35 vistas, 79 procedimientos
-- (+ sp_demo_flujo_completo opcional), 17 parámetros con su catálogo, 97 acciones
-- de bitácora, usuario admin, 14 facultades y 44 departamentos académicos.
--
-- Cada tabla se crea una sola vez con todas sus columnas, claves e índices, y cada
-- función, trigger, vista y procedimiento aparece una sola vez, en su versión final.
--
--   1.  Base de datos
--   2.  Tablas base (módulos 1 a 10), con las columnas que agregaron CUS12 a CUS19
--   3.  Funciones y triggers base
--   4.  Vistas base
--   5.  Procedimientos base (A. utilitarios … J. cierre del sufragio)
--   5b. CUS12 · Escrutinio y conciliación
--   5c. CUS13 · Impugnaciones y apelaciones
--   5d. CUS14 · Cómputo y proclamación
--   5e. CUS15 · Nulidades y segunda vuelta
--   5f. CUS16 · Omisos y multas
--   5g. CUS17 · Resultados y verificación de actas
--   5h. CUS18 · Usuarios y parámetros
--   5i. CUS19 · Consultar bitácora
--   6.  Datos iniciales: parámetros y su catálogo, cargos, usuario admin,
--       facultades y departamentos
--   7.  OPCIONAL · Demo de punta a punta (solo crea sp_demo_flujo_completo)
--
-- Los scripts 11 a 18 quedan solo para actualizar una base ya instalada sin ese
-- CUS; en una instalación nueva basta con este archivo.
--
-- ATENCIÓN: ELIMINA la base elecciones_unp si ya existe y la vuelve a crear.
-- Exporta tu base actual desde phpMyAdmin antes de importarlo.
--
-- Uso:  mysql -u root < "base-de-datos/00_script_unico_elecciones_unp.sql"
--       (o phpMyAdmin > Importar, sin elegir una base de datos)
-- =====================================================================

-- =====================================================================
-- 1. BASE DE DATOS
-- =====================================================================
DROP DATABASE IF EXISTS elecciones_unp;
CREATE DATABASE elecciones_unp
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE elecciones_unp;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
-- Las rutinas guardan el sql_mode vigente al crearse: se fuerza modo estricto
-- (XAMPP viene sin STRICT y aceptaria valores invalidos en silencio).
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';

-- =====================================================================
-- 2. TABLAS
-- =====================================================================

-- =====================================================================
-- MÓDULO 1 · UNIVERSIDAD Y PADRÓN DOCENTE
-- =====================================================================

CREATE TABLE facultad (
  id_facultad INT AUTO_INCREMENT PRIMARY KEY,
  nombre      VARCHAR(150) NOT NULL,
  UNIQUE KEY uq_facultad_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE departamento (
  id_departamento INT AUTO_INCREMENT PRIMARY KEY,
  id_facultad     INT NOT NULL,
  nombre          VARCHAR(150) NOT NULL,
  UNIQUE KEY uq_departamento_facultad (id_facultad, nombre),
  CONSTRAINT fk_departamento_facultad FOREIGN KEY (id_facultad) REFERENCES facultad(id_facultad)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE docente (
  id_docente            INT AUTO_INCREMENT PRIMARY KEY,
  dni                   VARCHAR(8)   NOT NULL,
  nombres               VARCHAR(100) NOT NULL,
  apellidos             VARCHAR(150) NOT NULL,
  categoria             ENUM('PRINCIPAL','ASOCIADO','AUXILIAR') NOT NULL,
  dedicacion            VARCHAR(80)  NOT NULL,               -- DE / TC / TP
  estado                ENUM('ACTIVO','INACTIVO','LICENCIA','SUSPENDIDO') NOT NULL DEFAULT 'ACTIVO',
  habilitado_para_votar BOOLEAN      NOT NULL DEFAULT TRUE,
  id_facultad           INT NOT NULL,                        -- se sincroniza con el departamento (trigger)
  id_departamento       INT NOT NULL,
  -- columnas nuevas (opcionales para el backend)
  grado_academico       ENUM('BACHILLER','MAESTRO','DOCTOR') NULL,   -- RN09: requisito para Rector/Decano
  fecha_ingreso         DATE NULL,
  fecha_categoria       DATE NULL,                           -- RN09: antigüedad en la categoría
  email                 VARCHAR(150) NULL,
  fecha_registro        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  url_foto              VARCHAR(300) NULL,                   -- RF62: fotografía del padrón (CUS09)
  UNIQUE KEY uq_docente_dni (dni),
  KEY ix_docente_apellidos (apellidos, nombres),
  KEY ix_docente_estado (estado, habilitado_para_votar),
  CONSTRAINT chk_docente_dni CHECK (dni REGEXP '^[0-9]{8}$'),
  CONSTRAINT fk_docente_facultad     FOREIGN KEY (id_facultad)     REFERENCES facultad(id_facultad),
  CONSTRAINT fk_docente_departamento FOREIGN KEY (id_departamento) REFERENCES departamento(id_departamento)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE parametro_global (
  clave       VARCHAR(80)  NOT NULL PRIMARY KEY,
  valor       VARCHAR(255) NOT NULL,
  descripcion VARCHAR(500) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Catálogo general de todos los cargos administrativos/institucionales posibles
CREATE TABLE catalogo_cargo (
  id_catalogo_cargo INT AUTO_INCREMENT PRIMARY KEY,
  nombre_cargo      VARCHAR(150) NOT NULL,
  nivel             VARCHAR(80)  NOT NULL,
  activo            BOOLEAN      NOT NULL DEFAULT TRUE,
  UNIQUE KEY uq_catalogo_cargo_nombre (nombre_cargo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Catálogo configurable por el CEUNP (RN20): qué cargos del catálogo general impiden ser miembro de mesa
CREATE TABLE cargo_excluido_sorteo (
  id_cargo_excluido INT AUTO_INCREMENT PRIMARY KEY,
  id_catalogo_cargo INT NOT NULL,
  activo            BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE KEY uq_cargo_excluido_catalogo (id_catalogo_cargo),
  CONSTRAINT fk_cargo_excluido_catalogo FOREIGN KEY (id_catalogo_cargo) REFERENCES catalogo_cargo(id_catalogo_cargo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Cargos administrativos que ejerce cada docente actualmente (autoridades)
CREATE TABLE cargo_admin (
  id_cargo_admin    INT AUTO_INCREMENT PRIMARY KEY,
  id_docente        INT NOT NULL,
  id_catalogo_cargo INT NOT NULL,
  fecha_inicio      DATE NOT NULL,
  fecha_fin         DATE NULL,
  vigente           BOOLEAN NOT NULL DEFAULT TRUE,
  KEY ix_cargo_admin_vigente (id_docente, vigente),
  CONSTRAINT chk_cargo_admin_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
  CONSTRAINT fk_cargo_admin_docente FOREIGN KEY (id_docente) REFERENCES docente(id_docente),
  CONSTRAINT fk_cargo_admin_catalogo FOREIGN KEY (id_catalogo_cargo) REFERENCES catalogo_cargo(id_catalogo_cargo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- MÓDULO 2 · SEGURIDAD (se crea antes porque otras tablas lo referencian)
-- =====================================================================

CREATE TABLE usuario (
  id_usuario        INT AUTO_INCREMENT PRIMARY KEY,
  id_docente        INT NULL,                 -- NULL: personal de TI / CEUNP no docente
  username          VARCHAR(80)  NOT NULL,
  password_hash     VARCHAR(255) NOT NULL,    -- BCrypt (lo genera el backend)
  rol               ENUM('ADMIN','CEUNP','DOCENTE','PERSONERO','MIEMBRO_MESA') NOT NULL,
  activo                BOOLEAN NOT NULL DEFAULT TRUE,
  intentos_fallidos     INT NOT NULL DEFAULT 0,
  bloqueado_hasta       DATETIME NULL,
  ultimo_acceso         DATETIME NULL,
  fecha_creacion        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_usuario_creador    INT NULL COMMENT 'CUS18: administrador que creó la cuenta',
  fecha_actualizacion   DATETIME NULL COMMENT 'CUS18: último cambio de rol, docente, estado o contraseña',
  motivo_estado         VARCHAR(300) NULL COMMENT 'CUS18: motivo de la última desactivación o reactivación',
  debe_cambiar_password BOOLEAN NOT NULL DEFAULT FALSE,  -- TRUE: docente importado, debe cambiar clave en 1er login
  UNIQUE KEY uq_usuario_username (username),
  CONSTRAINT fk_usuario_docente FOREIGN KEY (id_docente) REFERENCES docente(id_docente),
  CONSTRAINT fk_usuario_creador FOREIGN KEY (id_usuario_creador) REFERENCES usuario(id_usuario) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE sesion_activa (
  id_sesion        BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_usuario       INT NOT NULL,
  token_hash       CHAR(64) NOT NULL,         -- SHA-256 del JWT, nunca el token en claro
  fecha_inicio     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_expiracion DATETIME NOT NULL,
  revocada         BOOLEAN NOT NULL DEFAULT FALSE,
  UNIQUE KEY uq_sesion_token (token_hash),
  KEY ix_sesion_expiracion (fecha_expiracion),
  CONSTRAINT chk_sesion_fechas CHECK (fecha_expiracion > fecha_inicio),
  CONSTRAINT fk_sesion_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- MÓDULO 3 · PROCESO ELECTORAL, LISTAS Y CANDIDATOS
-- =====================================================================

CREATE TABLE proceso_electoral (
  id_proceso               INT AUTO_INCREMENT PRIMARY KEY,
  nombre                   VARCHAR(200) NOT NULL,
  fecha_inicio             DATETIME NOT NULL,      -- inicio del sufragio (RN06)
  fecha_fin                DATETIME NOT NULL,      -- cierre del sufragio (RN06)
  estado                   ENUM('CREADO','INSCRIPCION','VOTACION','CERRADO','FINALIZADO','ANULADO') NOT NULL DEFAULT 'CREADO',
  tipo                     ENUM('PRIMERA_VUELTA','SEGUNDA_VUELTA') NOT NULL DEFAULT 'PRIMERA_VUELTA',
  id_proceso_padre         INT NULL,               -- solo segunda vuelta (RN33)
  quorum_minimo            DECIMAL(5,2) NOT NULL DEFAULT 60.00,   -- RN31
  -- columnas nuevas
  fecha_convocatoria       DATE NULL,              -- RN02: 30 a 45 días antes
  fecha_limite_inscripcion DATETIME NULL,          -- RN13 / RN16
  fecha_cierre_real        DATETIME NULL,
  motivo_anulacion         VARCHAR(500) NULL,      -- RN34
  fecha_creacion           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_proceso_estado (estado),
  CONSTRAINT chk_proceso_fechas CHECK (fecha_fin > fecha_inicio),
  CONSTRAINT chk_proceso_quorum CHECK (quorum_minimo >= 0 AND quorum_minimo <= 100),
  CONSTRAINT chk_proceso_vuelta CHECK (
       (tipo = 'PRIMERA_VUELTA' AND id_proceso_padre IS NULL)
    OR (tipo = 'SEGUNDA_VUELTA' AND id_proceso_padre IS NOT NULL)),
  CONSTRAINT fk_proceso_padre FOREIGN KEY (id_proceso_padre) REFERENCES proceso_electoral(id_proceso)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE cargo_electoral (
  id_cargo                   INT AUTO_INCREMENT PRIMARY KEY,
  id_proceso                 INT NOT NULL,
  nombre                     VARCHAR(150) NOT NULL,
  nivel_jurisdiccion         ENUM('UNIVERSIDAD','FACULTAD','DEPARTAMENTO') NOT NULL,
  id_jurisdiccion            INT NULL,     -- id_facultad o id_departamento según el nivel (validado por trigger)
  -- columnas nuevas
  porcentaje_minimo_victoria DECIMAL(5,2) NOT NULL DEFAULT 50.00,   -- RN33: debe SUPERAR este % de votos válidos
  estado_resultado           ENUM('PENDIENTE','ELEGIDO','SEGUNDA_VUELTA','SIN_QUORUM','DESIERTO','EMPATE') NOT NULL DEFAULT 'PENDIENTE',
  id_lista_ganadora          INT NULL,
  UNIQUE KEY uq_cargo_proceso (id_cargo, id_proceso),   -- soporte de FKs compuestas
  KEY ix_cargo_jurisdiccion (id_proceso, nivel_jurisdiccion, id_jurisdiccion),
  CONSTRAINT chk_cargo_jurisdiccion CHECK (
       (nivel_jurisdiccion = 'UNIVERSIDAD' AND id_jurisdiccion IS NULL)
    OR (nivel_jurisdiccion <> 'UNIVERSIDAD' AND id_jurisdiccion IS NOT NULL)),
  CONSTRAINT chk_cargo_porcentaje CHECK (porcentaje_minimo_victoria >= 0 AND porcentaje_minimo_victoria < 100),
  CONSTRAINT fk_cargo_proceso FOREIGN KEY (id_proceso) REFERENCES proceso_electoral(id_proceso)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- RF03: categorías docentes que pueden votar y/o postular por cargo.
-- Si un cargo no tiene filas aquí, se asume que todas las categorías participan.
CREATE TABLE cargo_categoria_permitida (
  id_cargo       INT NOT NULL,
  categoria      ENUM('PRINCIPAL','ASOCIADO','AUXILIAR') NOT NULL,
  puede_votar    BOOLEAN NOT NULL DEFAULT TRUE,
  puede_postular BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (id_cargo, categoria),
  CONSTRAINT fk_categoria_cargo FOREIGN KEY (id_cargo) REFERENCES cargo_electoral(id_cargo) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE lista_electoral (
  id_lista          INT AUTO_INCREMENT PRIMARY KEY,
  id_cargo          INT NOT NULL,
  nombre            VARCHAR(150) NOT NULL,
  simbolo           VARCHAR(100) NULL,          -- RN17
  orden_cedula      INT NULL,                   -- RN18: orden sorteado
  estado            ENUM('INSCRITA','ADMITIDA','TACHADA','EXCLUIDA') NOT NULL DEFAULT 'INSCRITA',
  fecha_inscripcion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  -- columnas nuevas
  url_plan_gobierno VARCHAR(300) NULL,          -- RN15
  motivo_exclusion  VARCHAR(500) NULL,
  UNIQUE KEY uq_lista_cargo_nombre (id_cargo, nombre),
  UNIQUE KEY uq_lista_cargo_orden (id_cargo, orden_cedula),
  UNIQUE KEY uq_lista_cargo (id_lista, id_cargo),       -- soporte de FK compuesta desde voto
  CONSTRAINT chk_lista_orden CHECK (orden_cedula IS NULL OR orden_cedula > 0),
  CONSTRAINT fk_lista_cargo FOREIGN KEY (id_cargo) REFERENCES cargo_electoral(id_cargo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE cargo_electoral
  ADD CONSTRAINT fk_cargo_lista_ganadora
  FOREIGN KEY (id_lista_ganadora) REFERENCES lista_electoral(id_lista);

CREATE TABLE candidato (
  id_candidato      INT AUTO_INCREMENT PRIMARY KEY,
  id_lista          INT NOT NULL,
  id_docente        INT NOT NULL,
  rol_en_lista      VARCHAR(100) NOT NULL,      -- RECTOR / VICERRECTOR_ACADEMICO / VICERRECTOR_INVESTIGACION / DECANO ...
  estado_validacion ENUM('PENDIENTE','APROBADO','OBSERVADO','EXCLUIDO') NOT NULL DEFAULT 'PENDIENTE',
  fecha_inscripcion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  -- columnas nuevas
  url_hoja_vida     VARCHAR(300) NULL,          -- RN15 / RN16
  motivo_exclusion  VARCHAR(500) NULL,          -- RN14
  url_foto          VARCHAR(300) NULL,          -- RF68: fotografía del candidato en la cédula (CUS10)
  UNIQUE KEY uq_candidato_lista_docente (id_lista, id_docente),
  CONSTRAINT fk_candidato_lista   FOREIGN KEY (id_lista)   REFERENCES lista_electoral(id_lista) ON DELETE CASCADE,
  CONSTRAINT fk_candidato_docente FOREIGN KEY (id_docente) REFERENCES docente(id_docente)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE tacha (
  id_tacha               INT AUTO_INCREMENT PRIMARY KEY,
  id_docente_denunciante INT NOT NULL,
  id_candidato           INT NOT NULL,
  motivo                 TEXT NOT NULL,
  estado                 ENUM('PENDIENTE','FUNDADA','INFUNDADA') NOT NULL DEFAULT 'PENDIENTE',
  fecha_presentacion     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_resolucion       DATETIME NULL,
  -- columnas nuevas
  resolucion             TEXT NULL,
  id_usuario_resuelve    INT NULL,
  KEY ix_tacha_estado (estado),
  CONSTRAINT chk_tacha_resolucion CHECK (
       (estado = 'PENDIENTE' AND fecha_resolucion IS NULL)
    OR (estado <> 'PENDIENTE' AND fecha_resolucion IS NOT NULL)),
  CONSTRAINT fk_tacha_denunciante FOREIGN KEY (id_docente_denunciante) REFERENCES docente(id_docente),
  CONSTRAINT fk_tacha_candidato   FOREIGN KEY (id_candidato) REFERENCES candidato(id_candidato),
  CONSTRAINT fk_tacha_usuario     FOREIGN KEY (id_usuario_resuelve) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- MÓDULO 4 · MESAS, PADRÓN, VOTO Y ACTAS
-- =====================================================================

CREATE TABLE mesa_electoral (
  id_mesa          INT AUTO_INCREMENT PRIMARY KEY,
  id_proceso       INT NOT NULL,
  numero_mesa      VARCHAR(30)  NOT NULL,
  ubicacion        VARCHAR(200) NOT NULL,                       -- RN08 (parametrizable)
  semilla_sorteo   VARCHAR(128) NOT NULL DEFAULT 'PENDIENTE',   -- RNF01: sorteo auditable
  fecha_sorteo     DATETIME NULL,
  -- columnas nuevas (en MesaSufragio.java hoy son @Transient: ya pueden persistirse)
  estado           ENUM('PENDIENTE','INSTALADA','CERRADA','ANULADA','NO_INSTALADA') NOT NULL DEFAULT 'PENDIENTE',  -- RF58: NO_INSTALADA (CUS08)
  hora_instalacion DATETIME NULL,                               -- RN07
  hora_cierre      DATETIME NULL,
  total_electores  INT NOT NULL DEFAULT 0,
  UNIQUE KEY uq_mesa_proceso_numero (id_proceso, numero_mesa),
  CONSTRAINT fk_mesa_proceso FOREIGN KEY (id_proceso) REFERENCES proceso_electoral(id_proceso)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- RN19: 3 titulares (presidente, secretario, vocal) + 3 suplentes por mesa
CREATE TABLE miembro_mesa (
  id_mesa             INT NOT NULL,
  id_docente          INT NOT NULL,
  rol                 ENUM('PRESIDENTE','SECRETARIO','VOCAL','SUPLENTE') NOT NULL,
  titular             BOOLEAN NOT NULL DEFAULT FALSE,
  -- columnas nuevas
  orden_sorteo        INT NULL,                  -- posición obtenida en el sorteo (1..6)
  asistio             BOOLEAN NULL,              -- NULL = sin registrar; FALSE genera multa (RN35)
  hora_acreditacion   DATETIME NULL COMMENT 'CUS08: hora de llegada',                         -- RF56
  metodo_acreditacion ENUM('QR','DNI') NULL COMMENT 'CUS08: credencial QR o DNI',
  rol_instalacion     ENUM('PRESIDENTE','SECRETARIO','VOCAL') NULL COMMENT 'CUS08: cargo ejercido',  -- un suplente puede asumir el de un titular ausente
  qr_credencial_hash  CHAR(64) NULL,             -- RF56: fotocheck digital
  rol_titular         VARCHAR(12) AS (IF(titular = 1, rol, NULL)) STORED,
  PRIMARY KEY (id_mesa, id_docente),
  UNIQUE KEY uq_miembro_rol_titular (id_mesa, rol_titular),   -- un solo presidente/secretario/vocal por mesa
  UNIQUE KEY uq_miembro_qr (qr_credencial_hash),
  CONSTRAINT chk_miembro_rol CHECK (
       (titular = 1 AND rol IN ('PRESIDENTE','SECRETARIO','VOCAL'))
    OR (titular = 0 AND rol = 'SUPLENTE')),
  CONSTRAINT fk_miembro_mesa    FOREIGN KEY (id_mesa)    REFERENCES mesa_electoral(id_mesa) ON DELETE CASCADE,
  CONSTRAINT fk_miembro_docente FOREIGN KEY (id_docente) REFERENCES docente(id_docente)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE personero (
  id_personero        INT AUTO_INCREMENT PRIMARY KEY,
  id_lista            INT NOT NULL,
  id_docente          INT NOT NULL,
  tipo                ENUM('GENERAL','ALTERNO','MESA') NOT NULL,
  id_mesa             INT NULL,
  estado_acreditacion ENUM('PENDIENTE','ACREDITADO','REVOCADO') NOT NULL DEFAULT 'PENDIENTE',
  fecha_acreditacion  DATETIME NULL,
  qr_credencial_hash  CHAR(64) NULL,             -- RF51
  UNIQUE KEY uq_personero_lista_docente (id_lista, id_docente),
  UNIQUE KEY uq_personero_qr (qr_credencial_hash),
  CONSTRAINT chk_personero_mesa CHECK (
       (tipo = 'MESA' AND id_mesa IS NOT NULL)
    OR (tipo <> 'MESA' AND id_mesa IS NULL)),
  CONSTRAINT fk_personero_lista   FOREIGN KEY (id_lista)   REFERENCES lista_electoral(id_lista),
  CONSTRAINT fk_personero_docente FOREIGN KEY (id_docente) REFERENCES docente(id_docente),
  CONSTRAINT fk_personero_mesa    FOREIGN KEY (id_mesa)    REFERENCES mesa_electoral(id_mesa)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Padrón por cargo: dice QUIÉN puede votar y QUIÉN ya votó, nunca por quién.
CREATE TABLE padron_electoral (
  id_proceso            INT NOT NULL,
  id_cargo              INT NOT NULL,
  id_docente            INT NOT NULL,
  habilitado_para_votar BOOLEAN  NOT NULL DEFAULT TRUE,
  ya_voto               BOOLEAN  NOT NULL DEFAULT FALSE,
  no_voto               BOOLEAN  NOT NULL DEFAULT FALSE COMMENT 'CUS11: marca NO VOTÓ al cerrar el sufragio (RF75)',
  fecha_votacion        DATETIME NULL,
  motivo_inhabilitacion VARCHAR(255) NULL,
  fecha_generacion      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_mesa               INT NULL,                 -- nuevo: mesa asignada al elector
  PRIMARY KEY (id_proceso, id_cargo, id_docente),
  KEY ix_padron_docente (id_docente, id_proceso),
  KEY ix_padron_mesa (id_mesa),
  KEY ix_padron_conteo (id_cargo, habilitado_para_votar, ya_voto),
  CONSTRAINT chk_padron_voto CHECK (ya_voto = 0 OR fecha_votacion IS NOT NULL),
  -- FK compuesta: garantiza que el cargo pertenece al proceso indicado
  CONSTRAINT fk_padron_cargo_proceso FOREIGN KEY (id_cargo, id_proceso) REFERENCES cargo_electoral(id_cargo, id_proceso),
  CONSTRAINT fk_padron_docente FOREIGN KEY (id_docente) REFERENCES docente(id_docente),
  CONSTRAINT fk_padron_mesa    FOREIGN KEY (id_mesa)    REFERENCES mesa_electoral(id_mesa)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- REGLA DE ORO: esta tabla NO referencia a docente, usuario, sesión ni constancia.
CREATE TABLE voto (
  id_voto          BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_proceso       INT NOT NULL,
  id_cargo         INT NOT NULL,
  id_lista_elegida INT NULL,
  tipo_voto        ENUM('VALIDO','BLANCO','NULO') NOT NULL,
  fecha_hora       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,  -- el trigger la trunca a la hora (anti-correlación)
  id_mesa          INT NULL,                                     -- nuevo: permite el escrutinio por mesa
  KEY ix_voto_conteo (id_cargo, tipo_voto, id_lista_elegida),
  KEY ix_voto_mesa (id_mesa, id_cargo),
  CONSTRAINT chk_voto_tipo CHECK (
       (tipo_voto = 'VALIDO' AND id_lista_elegida IS NOT NULL)
    OR (tipo_voto IN ('BLANCO','NULO') AND id_lista_elegida IS NULL)),
  CONSTRAINT fk_voto_cargo_proceso FOREIGN KEY (id_cargo, id_proceso) REFERENCES cargo_electoral(id_cargo, id_proceso),
  -- FK compuesta: la lista elegida tiene que ser de ESE cargo
  CONSTRAINT fk_voto_lista_cargo FOREIGN KEY (id_lista_elegida, id_cargo) REFERENCES lista_electoral(id_lista, id_cargo),
  CONSTRAINT fk_voto_mesa FOREIGN KEY (id_mesa) REFERENCES mesa_electoral(id_mesa)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Certifica que el docente participó (no por quién votó). Se guarda solo el hash del token del QR.
CREATE TABLE constancia_voto (
  id_constancia    BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_proceso       INT NOT NULL,
  id_docente       INT NOT NULL,
  id_cargo         INT NOT NULL,
  token_qr_hash    CHAR(64) NOT NULL,
  fecha_emision    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_expiracion DATETIME NULL,
  estado           ENUM('VIGENTE','REVOCADA') NOT NULL DEFAULT 'VIGENTE',
  UNIQUE KEY uq_constancia_token (token_qr_hash),
  UNIQUE KEY uq_constancia_participacion (id_proceso, id_docente, id_cargo),
  CONSTRAINT fk_constancia_cargo_proceso FOREIGN KEY (id_cargo, id_proceso) REFERENCES cargo_electoral(id_cargo, id_proceso),
  CONSTRAINT fk_constancia_docente FOREIGN KEY (id_docente) REFERENCES docente(id_docente)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- RN28: tres actas por mesa, con huella SHA-256 del contenido
CREATE TABLE acta_electoral (
  id_acta         INT AUTO_INCREMENT PRIMARY KEY,
  id_mesa         INT NOT NULL,
  tipo            ENUM('INSTALACION','SUFRAGIO','ESCRUTINIO') NOT NULL,
  contenido_json  LONGTEXT NOT NULL,
  hash_integridad CHAR(64) NOT NULL,
  token_qr_hash   CHAR(64) NOT NULL,
  fecha_emision   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado          ENUM('VIGENTE','ANULADA') NOT NULL DEFAULT 'VIGENTE',
  UNIQUE KEY uq_acta_token (token_qr_hash),
  UNIQUE KEY uq_acta_mesa_tipo (id_mesa, tipo),
  CONSTRAINT chk_acta_json CHECK (JSON_VALID(contenido_json)),
  CONSTRAINT fk_acta_mesa FOREIGN KEY (id_mesa) REFERENCES mesa_electoral(id_mesa)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE firma_acta (
  id_firma      INT AUTO_INCREMENT PRIMARY KEY,
  id_acta       INT NOT NULL,
  id_docente    INT NOT NULL,
  rol           VARCHAR(80) NOT NULL,
  firma_digital TEXT NULL,
  fecha_firma   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_firma_acta_docente (id_acta, id_docente),
  CONSTRAINT fk_firma_acta    FOREIGN KEY (id_acta)    REFERENCES acta_electoral(id_acta),
  CONSTRAINT fk_firma_docente FOREIGN KEY (id_docente) REFERENCES docente(id_docente)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- MÓDULO 5 · RESULTADOS Y SANCIONES  (tablas nuevas)
-- =====================================================================

-- RN26: cómputo oficial congelado al cerrar. id_lista NULL = fila de blancos o nulos.
CREATE TABLE resultado_electoral (
  id_resultado       INT AUTO_INCREMENT PRIMARY KEY,
  id_proceso         INT NOT NULL,
  id_cargo           INT NOT NULL,
  id_lista           INT NULL,
  tipo_voto          ENUM('VALIDO','BLANCO','NULO') NOT NULL,
  total_votos        INT NOT NULL DEFAULT 0,
  porcentaje_validos DECIMAL(5,2) NULL,
  posicion           INT NULL,
  fecha_computo      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_resultado_cargo (id_cargo, posicion),
  CONSTRAINT chk_resultado_total CHECK (total_votos >= 0),
  CONSTRAINT fk_resultado_cargo_proceso FOREIGN KEY (id_cargo, id_proceso) REFERENCES cargo_electoral(id_cargo, id_proceso),
  CONSTRAINT fk_resultado_lista FOREIGN KEY (id_lista) REFERENCES lista_electoral(id_lista)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- RN35: multas a omisos al sufragio y a miembros de mesa que no asistieron
CREATE TABLE multa (
  id_multa         INT AUTO_INCREMENT PRIMARY KEY,
  id_docente       INT NOT NULL,
  id_proceso       INT NOT NULL,
  motivo           ENUM('OMISO_VOTACION','OMISO_MESA') NOT NULL,
  id_mesa          INT NULL COMMENT 'CUS16: mesa del elector (OMISO_VOTACION) o de la que era miembro (OMISO_MESA)',
  rol_mesa         VARCHAR(12) NULL COMMENT 'CUS16: cargo del miembro titular que no asistió',
  asistio_sin_votar BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'CUS16: asistió a la mesa y no votó (CUS10 A3, Disp. Final 5.ª)',
  uit_referencia   DECIMAL(10,2) NOT NULL,
  porcentaje_uit   DECIMAL(5,2)  NOT NULL,
  monto            DECIMAL(10,2) NOT NULL,
  estado_pago      ENUM('PENDIENTE','PAGADA','EXONERADA','JUSTIFICADA') NOT NULL DEFAULT 'PENDIENTE',  -- JUSTIFICADA: CUS16 (RF106)
  fecha_generacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_pago       DATETIME NULL,
  fecha_notificacion     DATETIME NULL COMMENT 'CUS16: notificación de la multa al docente',
  medio_notificacion     ENUM('CORREO_INSTITUCIONAL','CEDULA_PERSONAL','PORTAL_ELECTORAL') NULL,
  documento_notificacion VARCHAR(80) NULL COMMENT 'CUS16: N.º de cédula, oficio o correo',
  numero_recibo          VARCHAR(40) NULL COMMENT 'CUS16: recibo de pago (el sistema no cobra la multa)',
  observacion      VARCHAR(300) NULL,
  fecha_actualizacion      DATETIME NULL,
  id_usuario_actualizacion INT NULL,
  UNIQUE KEY uq_multa (id_docente, id_proceso, motivo),
  KEY ix_multa_estado (estado_pago),
  CONSTRAINT chk_multa_monto CHECK (monto >= 0),
  CONSTRAINT fk_multa_docente FOREIGN KEY (id_docente) REFERENCES docente(id_docente),
  CONSTRAINT fk_multa_proceso FOREIGN KEY (id_proceso) REFERENCES proceso_electoral(id_proceso)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- MÓDULO 6 · AUDITORÍA, OBSERVACIONES E IMPUGNACIONES
-- =====================================================================

-- Bitácora inmutable (los triggers impiden UPDATE y DELETE). Nunca guarda datos del voto.
CREATE TABLE log_auditoria (
  id_log       BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_usuario   INT NULL,
  id_docente   INT NULL,
  id_proceso   INT NULL,
  accion       VARCHAR(100) NOT NULL,
  ip_origen    VARCHAR(45)  NULL,
  user_agent   VARCHAR(500) NULL,
  fecha_hora   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  detalle_json LONGTEXT NULL,
  hash_anterior CHAR(64) NULL COMMENT 'CUS19: sello del registro anterior (cadena SHA-256)',
  hash_registro CHAR(64) NULL COMMENT 'CUS19: SHA-256 del registro encadenado al anterior',
  KEY ix_log_fecha (fecha_hora),
  KEY ix_log_accion (accion, fecha_hora),
  KEY ix_log_usuario_fecha (id_usuario, fecha_hora),   -- CUS19: filtros de la bitácora
  KEY ix_log_proceso_fecha (id_proceso, fecha_hora),
  KEY ix_log_ip_fecha (ip_origen, fecha_hora),
  CONSTRAINT chk_log_json CHECK (detalle_json IS NULL OR JSON_VALID(detalle_json)),
  CONSTRAINT fk_log_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
  CONSTRAINT fk_log_docente FOREIGN KEY (id_docente) REFERENCES docente(id_docente),
  CONSTRAINT fk_log_proceso FOREIGN KEY (id_proceso) REFERENCES proceso_electoral(id_proceso)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE observacion_electoral (
  id_observacion  BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_personero    INT NOT NULL,
  id_proceso      INT NOT NULL,
  id_mesa         INT NULL,
  id_acta         INT NULL,
  descripcion     TEXT NOT NULL,
  estado          ENUM('PENDIENTE','ATENDIDA','RECHAZADA') NOT NULL DEFAULT 'PENDIENTE',
  respuesta_ceunp TEXT NULL,
  fecha_registro  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_respuesta DATETIME NULL,
  CONSTRAINT fk_observacion_personero FOREIGN KEY (id_personero) REFERENCES personero(id_personero),
  CONSTRAINT fk_observacion_proceso   FOREIGN KEY (id_proceso)   REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_observacion_mesa      FOREIGN KEY (id_mesa)      REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_observacion_acta      FOREIGN KEY (id_acta)      REFERENCES acta_electoral(id_acta)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- RN23 / RN24: solo los personeros impugnan; resuelve la mesa y luego el CEUNP
CREATE TABLE impugnacion_electoral (
  id_impugnacion     BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_personero       INT NOT NULL,
  id_proceso         INT NOT NULL,
  id_mesa            INT NOT NULL,
  id_cargo           INT NULL COMMENT 'CUS12: cargo de la cédula impugnada durante el escrutinio',
  id_acta            INT NULL,
  motivo             TEXT NOT NULL,
  decision_mesa      ENUM('PENDIENTE','ACEPTADA','RECHAZADA') NOT NULL DEFAULT 'PENDIENTE',
  -- CUS13 · decisión de la mesa en primera instancia (RN23)
  votos_mesa_favor     TINYINT NULL COMMENT 'CUS13: miembros de mesa a favor de la impugnación',
  votos_mesa_contra    TINYINT NULL COMMENT 'CUS13: miembros de mesa en contra',
  opcion_mesa          ENUM('LISTA','BLANCO','NULO') NULL COMMENT 'CUS13: opción a la que la mesa asigna la cédula',
  id_lista_mesa        INT NULL COMMENT 'CUS13: lista, si opcion_mesa = LISTA',
  fundamento_mesa      VARCHAR(1000) NULL COMMENT 'CUS13: fundamento de la decisión de la mesa',
  fecha_decision_mesa  DATETIME NULL COMMENT 'CUS13: hora de la decisión de la mesa',
  id_usuario_mesa      INT NULL COMMENT 'CUS13: presidente que registró la decisión',
  -- CUS13 · apelación (RF81)
  id_personero_apela   INT NULL COMMENT 'CUS13: personero que apela',
  fundamento_apelacion VARCHAR(1000) NULL COMMENT 'CUS13: fundamento de la apelación',
  fecha_apelacion      DATETIME NULL COMMENT 'CUS13: hora de la apelación',
  id_usuario_apelacion INT NULL COMMENT 'CUS13: cuenta que registró la apelación',
  decision_ceunp     ENUM('PENDIENTE','CONFIRMADA','MODIFICADA') NOT NULL DEFAULT 'PENDIENTE',
  -- CUS13 · fallo del CEUNP (RN36)
  numero_resolucion    VARCHAR(40) NULL COMMENT 'CUS13: número de la resolución del CEUNP',
  miembros_pleno       TINYINT NULL COMMENT 'CUS13: miembros del Pleno presentes (quórum)',
  votos_pleno_favor    TINYINT NULL COMMENT 'CUS13: votos a favor de la apelación',
  votos_pleno_contra   TINYINT NULL COMMENT 'CUS13: votos en contra de la apelación',
  voto_dirimente       ENUM('FAVOR','CONTRA') NULL COMMENT 'CUS13: voto dirimente del Presidente en empate',
  opcion_final         ENUM('LISTA','BLANCO','NULO') NULL COMMENT 'CUS13: opción final fijada por el CEUNP',
  id_lista_final       INT NULL COMMENT 'CUS13: lista, si opcion_final = LISTA',
  fundamento_ceunp     VARCHAR(1000) NULL COMMENT 'CUS13: fundamento del fallo',
  fecha_fallo          DATETIME NULL COMMENT 'CUS13: fecha del fallo del CEUNP',
  id_usuario_ceunp     INT NULL COMMENT 'CUS13: cuenta del CEUNP que registró el fallo',
  estado             ENUM('PRESENTADA','RESUELTA','APELADA') NOT NULL DEFAULT 'PRESENTADA',
  fecha_presentacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_resolucion   DATETIME NULL,
  CONSTRAINT fk_impugnacion_personero FOREIGN KEY (id_personero) REFERENCES personero(id_personero),
  CONSTRAINT fk_impugnacion_proceso   FOREIGN KEY (id_proceso)   REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_impugnacion_mesa      FOREIGN KEY (id_mesa)      REFERENCES mesa_electoral(id_mesa),
  UNIQUE KEY uq_impugnacion_resolucion (numero_resolucion),   -- una resolución del CEUNP no se repite
  KEY ix_impugnacion_estado (id_proceso, estado),
  CONSTRAINT fk_impugnacion_acta      FOREIGN KEY (id_acta)      REFERENCES acta_electoral(id_acta),
  CONSTRAINT fk_impugnacion_cargo          FOREIGN KEY (id_cargo)             REFERENCES cargo_electoral(id_cargo),
  CONSTRAINT fk_impugnacion_lista_mesa     FOREIGN KEY (id_lista_mesa)        REFERENCES lista_electoral(id_lista),
  CONSTRAINT fk_impugnacion_lista_final    FOREIGN KEY (id_lista_final)       REFERENCES lista_electoral(id_lista),
  CONSTRAINT fk_impugnacion_usuario_mesa   FOREIGN KEY (id_usuario_mesa)      REFERENCES usuario(id_usuario),
  CONSTRAINT fk_impugnacion_apelante       FOREIGN KEY (id_personero_apela)   REFERENCES personero(id_personero),
  CONSTRAINT fk_impugnacion_usuario_apel   FOREIGN KEY (id_usuario_apelacion) REFERENCES usuario(id_usuario),
  CONSTRAINT fk_impugnacion_usuario_ceunp  FOREIGN KEY (id_usuario_ceunp)     REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- MÓDULO 7 · CREDENCIALES QR (CUS07)
-- =====================================================================

-- Pase de votación, fotocheck de miembro de mesa y credencial de personero.
CREATE TABLE credencial_qr (
  id_credencial     BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_proceso        INT NOT NULL,
  id_docente        INT NOT NULL,
  tipo              ENUM('ELECTOR','MIEMBRO_MESA','PERSONERO') NOT NULL,
  id_mesa           INT NULL,                  -- mesa del elector / del miembro / del personero de mesa
  id_personero      INT NULL,                  -- solo PERSONERO
  token_qr_hash     CHAR(64) NOT NULL,         -- SHA-256 del token (nunca el token)
  fecha_emision     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_expiracion  DATETIME NOT NULL,         -- fin del sufragio del proceso
  estado            ENUM('VIGENTE','REVOCADA') NOT NULL DEFAULT 'VIGENTE',
  fecha_revocacion  DATETIME NULL,
  motivo_revocacion VARCHAR(255) NULL,
  id_usuario_emisor INT NULL,
  usos              INT NOT NULL DEFAULT 0,    -- lecturas válidas registradas
  ultimo_uso        DATETIME NULL,
  -- una sola credencial VIGENTE por titular: (proceso, docente, tipo, personero o mesa)
  clave_vigente     VARCHAR(80) AS (IF(estado = 'VIGENTE',
                      CONCAT_WS(':', id_proceso, id_docente, tipo,
                        CASE tipo WHEN 'PERSONERO' THEN id_personero
                                  WHEN 'MIEMBRO_MESA' THEN id_mesa
                                  ELSE 0 END),
                      NULL)) STORED,
  UNIQUE KEY uq_credencial_token (token_qr_hash),
  UNIQUE KEY uq_credencial_vigente (clave_vigente),
  KEY ix_credencial_titular (id_proceso, tipo, id_docente),
  KEY ix_credencial_docente (id_docente, estado),
  CONSTRAINT chk_credencial_hash CHECK (token_qr_hash REGEXP '^[0-9a-f]{64}$'),
  CONSTRAINT chk_credencial_tipo CHECK (
       (tipo = 'PERSONERO'    AND id_personero IS NOT NULL)
    OR (tipo = 'MIEMBRO_MESA' AND id_personero IS NULL AND id_mesa IS NOT NULL)
    OR (tipo = 'ELECTOR'      AND id_personero IS NULL)),
  CONSTRAINT chk_credencial_revocacion CHECK (estado = 'VIGENTE' OR fecha_revocacion IS NOT NULL),
  CONSTRAINT fk_credencial_proceso   FOREIGN KEY (id_proceso)        REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_credencial_docente   FOREIGN KEY (id_docente)        REFERENCES docente(id_docente),
  CONSTRAINT fk_credencial_mesa      FOREIGN KEY (id_mesa)           REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_credencial_personero FOREIGN KEY (id_personero)      REFERENCES personero(id_personero),
  CONSTRAINT fk_credencial_emisor    FOREIGN KEY (id_usuario_emisor) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- MÓDULO 8 · INSTALACIÓN DE MESA (CUS08)
-- =====================================================================

-- Datos de instalación de cada mesa (relación 1 a 1 con mesa_electoral):
-- registrarMaterial(id_mesa, estado_material) del diagrama, resultado y evaluación de nulidad.
CREATE TABLE instalacion_mesa (
  id_mesa               INT PRIMARY KEY,
  estado                ENUM('EN_CURSO','INSTALADA','NO_INSTALADA') NOT NULL DEFAULT 'EN_CURSO',
  material_json         LONGTEXT NULL,             -- {"PADRON":{"estado":"CONFORME","observacion":null}, ...}
  material_completo     BOOLEAN NOT NULL DEFAULT FALSE,   -- RF57: todo el material recibido
  cedulas_recibidas     INT NULL,                  -- RF59: cantidad de cédulas recibidas
  cedulas_firmadas      BOOLEAN NOT NULL DEFAULT FALSE,   -- CUN07 paso 4: el presidente firmó el reverso
  observaciones         VARCHAR(500) NULL,
  fecha_inicio          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion   DATETIME NULL,
  hora_instalacion      DATETIME NULL,
  motivo_no_instalacion VARCHAR(255) NULL,
  automatica            BOOLEAN NOT NULL DEFAULT FALSE,   -- NO_INSTALADA registrada por el sistema
  evaluacion_nulidad    ENUM('PROCEDE','NO_PROCEDE') NULL, -- RF60: decisión del CEUNP
  fundamento_evaluacion VARCHAR(500) NULL,
  fecha_evaluacion      DATETIME NULL,
  id_usuario_registro   INT NULL,
  id_usuario_cierre     INT NULL,
  id_usuario_evaluacion INT NULL,
  CONSTRAINT chk_instalacion_json CHECK (material_json IS NULL OR JSON_VALID(material_json)),
  CONSTRAINT chk_instalacion_cedulas CHECK (cedulas_recibidas IS NULL OR cedulas_recibidas >= 0),
  CONSTRAINT chk_instalacion_motivo CHECK (estado <> 'NO_INSTALADA' OR motivo_no_instalacion IS NOT NULL),
  CONSTRAINT chk_instalacion_evaluacion CHECK (evaluacion_nulidad IS NULL
    OR (estado = 'NO_INSTALADA' AND fundamento_evaluacion IS NOT NULL AND fecha_evaluacion IS NOT NULL)),
  CONSTRAINT fk_instalacion_mesa       FOREIGN KEY (id_mesa)               REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_instalacion_registro   FOREIGN KEY (id_usuario_registro)   REFERENCES usuario(id_usuario),
  CONSTRAINT fk_instalacion_cierre     FOREIGN KEY (id_usuario_cierre)     REFERENCES usuario(id_usuario),
  CONSTRAINT fk_instalacion_evaluacion FOREIGN KEY (id_usuario_evaluacion) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Personeros presentes en la instalación (el presidente recibe sus credenciales; firman el acta)
CREATE TABLE asistencia_personero_mesa (
  id_mesa           INT NOT NULL,
  id_personero      INT NOT NULL,
  hora_acreditacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  metodo            ENUM('QR','DNI') NOT NULL,
  id_usuario        INT NULL,
  PRIMARY KEY (id_mesa, id_personero),
  CONSTRAINT fk_asist_pers_mesa      FOREIGN KEY (id_mesa)      REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_asist_pers_personero FOREIGN KEY (id_personero) REFERENCES personero(id_personero),
  CONSTRAINT fk_asist_pers_usuario   FOREIGN KEY (id_usuario)   REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- CUN07 flujo alterno: faltan titulares y suplentes -> asume otro integrante de la comunidad universitaria
CREATE TABLE reemplazo_mesa (
  id_mesa           INT NOT NULL,
  cargo             ENUM('PRESIDENTE','SECRETARIO','VOCAL') NOT NULL,
  id_docente        INT NOT NULL,
  hora_acreditacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_usuario        INT NULL,
  PRIMARY KEY (id_mesa, cargo),
  UNIQUE KEY uq_reemplazo_docente (id_mesa, id_docente),
  CONSTRAINT fk_reemplazo_mesa    FOREIGN KEY (id_mesa)    REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_reemplazo_docente FOREIGN KEY (id_docente) REFERENCES docente(id_docente),
  CONSTRAINT fk_reemplazo_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- MÓDULO 9 · VERIFICAR ELECTOR Y EMITIR VOTO (CUS09 / CUS10)
-- =====================================================================

CREATE TABLE asistencia_elector (
  id_asistencia   BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_proceso      INT NOT NULL,
  id_mesa         INT NOT NULL,
  id_docente      INT NOT NULL,
  metodo          ENUM('QR','DNI') NOT NULL,          -- QR leído o búsqueda por DNI (A1/A2)
  id_credencial   BIGINT NULL,                        -- pase QR leído (CUS07)
  hora_asistencia DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_usuario_mesa INT NULL,                           -- Secretario que verificó
  UNIQUE KEY uq_asistencia_elector (id_proceso, id_docente),   -- RF64: bloquea un segundo ingreso
  KEY ix_asistencia_mesa (id_mesa),
  CONSTRAINT chk_asistencia_qr CHECK (metodo = 'DNI' OR id_credencial IS NOT NULL),
  CONSTRAINT fk_asistencia_proceso    FOREIGN KEY (id_proceso)      REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_asistencia_mesa       FOREIGN KEY (id_mesa)         REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_asistencia_docente    FOREIGN KEY (id_docente)      REFERENCES docente(id_docente),
  CONSTRAINT fk_asistencia_credencial FOREIGN KEY (id_credencial)   REFERENCES credencial_qr(id_credencial),
  CONSTRAINT fk_asistencia_usuario    FOREIGN KEY (id_usuario_mesa) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE terminal_votacion (
  id_terminal      INT AUTO_INCREMENT PRIMARY KEY,
  id_mesa          INT NOT NULL,
  nombre           VARCHAR(40) NOT NULL,              -- «Cabina 1», «Cabina 2»…
  activo           BOOLEAN NOT NULL DEFAULT TRUE,     -- FALSE: fuera de servicio (CUS10 A4)
  fecha_registro   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ultima_conexion  DATETIME NULL,
  UNIQUE KEY uq_terminal_mesa_nombre (id_mesa, nombre),
  CONSTRAINT fk_terminal_mesa FOREIGN KEY (id_mesa) REFERENCES mesa_electoral(id_mesa)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE habilitacion_terminal (
  id_habilitacion    BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_asistencia      BIGINT NOT NULL,
  id_terminal        INT NOT NULL,
  rehabilitacion     BOOLEAN NOT NULL DEFAULT FALSE,  -- autorizada por el Presidente (CUS10 A3/A5)
  token_hash         CHAR(64) NULL,                   -- SHA-256 del token que recibe el terminal
  fecha_habilitacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_entrega      DATETIME NULL,                   -- el terminal tomó la habilitación
  estado             ENUM('PENDIENTE','CONSUMIDA','ANULADA') NOT NULL DEFAULT 'PENDIENTE',
  fecha_cierre       DATETIME NULL,
  motivo_anulacion   VARCHAR(255) NULL,
  id_usuario_mesa    INT NULL,
  -- un solo uso: una PENDIENTE por elector y una por terminal
  pendiente_asist    BIGINT AS (IF(estado = 'PENDIENTE', id_asistencia, NULL)) STORED,
  pendiente_term     INT    AS (IF(estado = 'PENDIENTE', id_terminal, NULL)) STORED,
  UNIQUE KEY uq_habilitacion_elector (pendiente_asist),
  UNIQUE KEY uq_habilitacion_terminal (pendiente_term),
  UNIQUE KEY uq_habilitacion_token (token_hash),
  CONSTRAINT chk_habilitacion_cierre CHECK (estado = 'PENDIENTE' OR fecha_cierre IS NOT NULL),
  CONSTRAINT chk_habilitacion_anulada CHECK (estado <> 'ANULADA' OR motivo_anulacion IS NOT NULL),
  CONSTRAINT fk_habilitacion_asistencia FOREIGN KEY (id_asistencia)   REFERENCES asistencia_elector(id_asistencia),
  CONSTRAINT fk_habilitacion_terminal   FOREIGN KEY (id_terminal)     REFERENCES terminal_votacion(id_terminal),
  CONSTRAINT fk_habilitacion_usuario    FOREIGN KEY (id_usuario_mesa) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE incidencia_mesa (
  id_incidencia  BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_proceso     INT NOT NULL,
  id_mesa        INT NOT NULL,
  id_docente     INT NULL,                            -- NULL si no se pudo identificar
  tipo           ENUM('QR_INVALIDO','NO_FIGURA','OTRA_MESA','YA_REGISTRADO','INHABILITADO',
                      'SUPLANTACION','ABANDONO_TERMINAL','FALLA_TERMINAL','REHABILITACION') NOT NULL,
  detalle        VARCHAR(500) NULL,
  fecha          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_usuario     INT NULL,
  KEY ix_incidencia_mesa (id_mesa, fecha),
  CONSTRAINT fk_incidencia_proceso FOREIGN KEY (id_proceso) REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_incidencia_mesa    FOREIGN KEY (id_mesa)    REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_incidencia_docente FOREIGN KEY (id_docente) REFERENCES docente(id_docente),
  CONSTRAINT fk_incidencia_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- MÓDULO 10 · CERRAR SUFRAGIO (CUS11)
-- =====================================================================

-- Guarda el avance de los tres pasos del diagrama y los datos del acta de sufragio.
CREATE TABLE cierre_mesa (
  id_mesa               INT PRIMARY KEY,
  estado                ENUM('VOTACION_CERRADA','AUSENTES_MARCADOS','ACTA_EMITIDA') NOT NULL DEFAULT 'VOTACION_CERRADA',
  hora_cierre           DATETIME NOT NULL,          -- actualizarEstado('CERRADA', hora_cierre)
  cierre_anticipado     BOOLEAN NOT NULL DEFAULT FALSE,  -- antes de la hora de cierre: ya votaron todos
  total_electores       INT NOT NULL,               -- electores hábiles de la mesa
  total_votaron         INT NOT NULL,               -- mostrarTotalVotantes(total) (RF74)
  total_no_votaron      INT NOT NULL,               -- marca NO VOTÓ (RF75)
  asistieron_sin_votar  INT NOT NULL DEFAULT 0,     -- CUS10 A3: asistió y no votó (Disp. Final 5.ª)
  cedulas_recibidas     INT NULL,                   -- del acta de instalación (CUS08)
  cedulas_no_utilizadas INT NULL,                   -- ingresarObservaciones(cedulas_no_usadas, ...) (RF76)
  firmas_lista_fisica   INT NULL,                   -- A2: conteo de firmas en la lista física
  observaciones         VARCHAR(1000) NULL,
  id_acta               INT NULL,                   -- acta de sufragio emitida
  fecha_ausentes        DATETIME NULL,
  fecha_acta            DATETIME NULL,
  id_usuario_cierre     INT NULL,
  id_usuario_ausentes   INT NULL,
  id_usuario_acta       INT NULL,
  UNIQUE KEY uq_cierre_acta (id_acta),
  CONSTRAINT chk_cierre_totales CHECK (total_votaron >= 0 AND total_no_votaron >= 0 AND total_electores >= 0),
  CONSTRAINT chk_cierre_cedulas CHECK (cedulas_no_utilizadas IS NULL OR cedulas_no_utilizadas >= 0),
  CONSTRAINT chk_cierre_acta CHECK (estado <> 'ACTA_EMITIDA' OR (id_acta IS NOT NULL AND cedulas_no_utilizadas IS NOT NULL)),
  CONSTRAINT fk_cierre_mesa     FOREIGN KEY (id_mesa)             REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_cierre_acta     FOREIGN KEY (id_acta)             REFERENCES acta_electoral(id_acta),
  CONSTRAINT fk_cierre_usuario  FOREIGN KEY (id_usuario_cierre)   REFERENCES usuario(id_usuario),
  CONSTRAINT fk_cierre_ausentes FOREIGN KEY (id_usuario_ausentes) REFERENCES usuario(id_usuario),
  CONSTRAINT fk_cierre_emisor   FOREIGN KEY (id_usuario_acta)     REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 3. FUNCIONES Y TRIGGERS
-- Los triggers protegen las reglas aunque el INSERT/UPDATE venga del
-- backend (JPA) y no de un procedimiento almacenado.
-- =====================================================================

DELIMITER $$

-- ---------------------------------------------------------------------
-- FUNCIONES
-- ---------------------------------------------------------------------

-- Lee un parámetro numérico (UIT, porcentajes, tamaños). Devuelve NULL si no existe.
CREATE FUNCTION fn_parametro_decimal(p_clave VARCHAR(80))
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
  DECLARE v_valor DECIMAL(12,2) DEFAULT NULL;
  SELECT CAST(valor AS DECIMAL(12,2)) INTO v_valor
    FROM parametro_global WHERE clave = p_clave LIMIT 1;
  RETURN v_valor;
END$$

-- RN20 / RN21: ¿el docente ejerce hoy un cargo que figura en el catálogo de excluidos?
CREATE FUNCTION fn_tiene_cargo_excluyente(p_id_docente INT)
RETURNS BOOLEAN
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
END$$

-- RN31: % de participación de un cargo (votaron / habilitados * 100)
CREATE FUNCTION fn_participacion_cargo(p_id_cargo INT)
RETURNS DECIMAL(5,2)
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
END$$

-- Proceso al que pertenece una lista
CREATE FUNCTION fn_proceso_de_lista(p_id_lista INT)
RETURNS INT
READS SQL DATA
BEGIN
  DECLARE v_id INT DEFAULT NULL;
  SELECT c.id_proceso INTO v_id
    FROM lista_electoral l
    JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
   WHERE l.id_lista = p_id_lista LIMIT 1;
  RETURN v_id;
END$$

-- ---------------------------------------------------------------------
-- DOCENTE: la facultad siempre es la del departamento; solo ACTIVO vota (RN03)
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_docente_bi BEFORE INSERT ON docente
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
END$$

CREATE TRIGGER trg_docente_bu BEFORE UPDATE ON docente
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
END$$

-- ---------------------------------------------------------------------
-- CARGO: valida que la jurisdicción exista según el nivel
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_cargo_bi BEFORE INSERT ON cargo_electoral
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
END$$

CREATE TRIGGER trg_cargo_bu BEFORE UPDATE ON cargo_electoral
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
END$$

-- ---------------------------------------------------------------------
-- CANDIDATO: RN11 (no puede estar en dos listas del mismo proceso)
--            y no puede ser personero ni miembro de mesa del proceso
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_candidato_bi BEFORE INSERT ON candidato
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
END$$

-- ---------------------------------------------------------------------
-- PERSONERO: RN21 (no candidato, no autoridad)
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_personero_bi BEFORE INSERT ON personero
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
END$$

-- ---------------------------------------------------------------------
-- MIEMBRO DE MESA: RN20 (ni candidato, ni personero, ni autoridad)
--                  y una sola mesa por proceso
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_miembro_mesa_bi BEFORE INSERT ON miembro_mesa
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
END$$

-- ---------------------------------------------------------------------
-- PADRÓN: nadie "des-vota"; solo se marca el voto con el proceso en VOTACION
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_padron_bu BEFORE UPDATE ON padron_electoral
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
    IF NEW.fecha_votacion IS NULL THEN
      SET NEW.fecha_votacion = NOW();
    END IF;
  END IF;
END$$

CREATE TRIGGER trg_padron_bd BEFORE DELETE ON padron_electoral
FOR EACH ROW
BEGIN
  IF OLD.ya_voto = 1 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No se puede eliminar del padron a un docente que ya voto.';
  END IF;
END$$

-- ---------------------------------------------------------------------
-- VOTO: solo durante la votación, con hora truncada, e inmutable (RN26)
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_voto_bi BEFORE INSERT ON voto
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

  -- Secreto del voto: se guarda solo la hora (sin minutos ni segundos) para que no
  -- se pueda cruzar con padron_electoral.fecha_votacion ni con la bitácora.
  SET NEW.fecha_hora = DATE_FORMAT(NOW(), '%Y-%m-%d %H:00:00');
END$$

CREATE TRIGGER trg_voto_bu BEFORE UPDATE ON voto
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: los votos son inmutables.';
END$$

CREATE TRIGGER trg_voto_bd BEFORE DELETE ON voto
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: los votos no se pueden eliminar.';
END$$

-- ---------------------------------------------------------------------
-- ACTAS: el contenido y su huella no cambian; solo se puede ANULAR (RN28)
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_acta_bu BEFORE UPDATE ON acta_electoral
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
END$$

CREATE TRIGGER trg_acta_bd BEFORE DELETE ON acta_electoral
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN28: las actas no se eliminan, se anulan.';
END$$

-- ---------------------------------------------------------------------
-- RESULTADOS: cómputo irreversible (RN26)
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_resultado_bu BEFORE UPDATE ON resultado_electoral
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el computo oficial es irreversible.';
END$$

CREATE TRIGGER trg_resultado_bd BEFORE DELETE ON resultado_electoral
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el computo oficial es irreversible.';
END$$

-- ---------------------------------------------------------------------
-- BITÁCORA: registro inmutable
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_log_bu BEFORE UPDATE ON log_auditoria
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La bitacora de auditoria es inmutable.';
END$$

CREATE TRIGGER trg_log_bd BEFORE DELETE ON log_auditoria
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La bitacora de auditoria es inmutable.';
END$$

-- ---------------------------------------------------------------------
-- CUS07 · CREDENCIALES QR
-- ---------------------------------------------------------------------

-- Si el CEUNP revoca la acreditación de un personero (CUS05), su credencial deja de valer.
CREATE TRIGGER trg_personero_au_credencial AFTER UPDATE ON personero
FOR EACH ROW
BEGIN
  IF OLD.estado_acreditacion = 'ACREDITADO' AND NEW.estado_acreditacion <> 'ACREDITADO' THEN
    UPDATE credencial_qr
       SET estado = 'REVOCADA', fecha_revocacion = NOW(),
           motivo_revocacion = 'Acreditación del personero revocada (CUS05)'
     WHERE id_personero = NEW.id_personero AND estado = 'VIGENTE';
  END IF;
END$$

-- Las credenciales son evidencia de auditoría: se revocan, no se borran.
CREATE TRIGGER trg_credencial_bd BEFORE DELETE ON credencial_qr
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Las credenciales QR no se eliminan: revóquelas.';
END$$

-- ---------------------------------------------------------------------
-- CUS08 · INSTALACIÓN DE MESA
-- ---------------------------------------------------------------------

-- Cerrada la instalación, su registro ya no cambia. Única excepción (RF60): una mesa
-- NO_INSTALADA recibe una sola vez la evaluación de nulidad del CEUNP.
CREATE TRIGGER trg_instalacion_bu BEFORE UPDATE ON instalacion_mesa
FOR EACH ROW
BEGIN
  IF OLD.estado <> 'EN_CURSO'
     AND NOT (OLD.estado = 'NO_INSTALADA' AND NEW.estado = 'NO_INSTALADA'
              AND OLD.evaluacion_nulidad IS NULL AND NEW.evaluacion_nulidad IS NOT NULL
              AND NEW.motivo_no_instalacion <=> OLD.motivo_no_instalacion) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS08: la instalación de esta mesa ya se cerró.';
  END IF;
END$$

CREATE TRIGGER trg_instalacion_bd BEFORE DELETE ON instalacion_mesa
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS08: el registro de instalación no se elimina.';
END$$

-- ---------------------------------------------------------------------
-- CUS09 / CUS10 · ASISTENCIA, HABILITACIONES E INCIDENCIAS
-- ---------------------------------------------------------------------

-- La asistencia, las habilitaciones y las incidencias son evidencia de la jornada.
CREATE TRIGGER trg_asistencia_elector_bd BEFORE DELETE ON asistencia_elector
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF64: la asistencia del elector no se elimina.';
END$$

CREATE TRIGGER trg_habilitacion_bd BEFORE DELETE ON habilitacion_terminal
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Las habilitaciones de terminal no se eliminan: se anulan.';
END$$

CREATE TRIGGER trg_incidencia_mesa_bd BEFORE DELETE ON incidencia_mesa
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Las incidencias de mesa no se eliminan.';
END$$

-- ---------------------------------------------------------------------
-- CUS11 · CIERRE DEL SUFRAGIO
-- ---------------------------------------------------------------------

-- RF75: la marca NO VOTÓ no se quita, y quien la tiene ya no puede votar.
CREATE TRIGGER trg_padron_no_voto_bu BEFORE UPDATE ON padron_electoral
FOR EACH ROW
BEGIN
  IF OLD.no_voto = 1 AND NEW.no_voto = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF75: la marca NO VOTO no se puede quitar.';
  END IF;
  IF NEW.no_voto = 1 AND NEW.ya_voto = 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF75: un elector marcado NO VOTO ya no puede votar.';
  END IF;
END$$

-- Emitida el acta, el cierre de la mesa ya no cambia (RN28).
CREATE TRIGGER trg_cierre_bu BEFORE UPDATE ON cierre_mesa
FOR EACH ROW
BEGIN
  IF OLD.estado = 'ACTA_EMITIDA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS11: el acta de sufragio de esta mesa ya fue emitida.';
  END IF;
  IF NEW.hora_cierre <> OLD.hora_cierre OR NEW.total_votaron <> OLD.total_votaron THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS11: la hora de cierre y el total de votantes no se modifican.';
  END IF;
END$$

CREATE TRIGGER trg_cierre_bd BEFORE DELETE ON cierre_mesa
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS11: el registro de cierre no se elimina.';
END$$

DELIMITER ;

-- =====================================================================
-- 4. VISTAS DE CONSULTA Y REPORTES
-- =====================================================================

-- Docente con su facultad y departamento
CREATE VIEW v_docente_detalle AS
SELECT d.id_docente, d.dni, d.apellidos, d.nombres,
       CONCAT(d.apellidos, ', ', d.nombres) AS nombre_completo,
       d.categoria, d.dedicacion, d.grado_academico, d.estado, d.habilitado_para_votar,
       f.id_facultad, f.nombre AS facultad,
       dp.id_departamento, dp.nombre AS departamento,
       fn_tiene_cargo_excluyente(d.id_docente) AS es_autoridad_vigente
  FROM docente d
  JOIN departamento dp ON dp.id_departamento = d.id_departamento
  JOIN facultad f      ON f.id_facultad = dp.id_facultad;

-- Padrón electoral legible (quién vota qué y en qué mesa). No expone el voto.
CREATE VIEW v_padron_detalle AS
SELECT pe.id_proceso, pe.id_cargo, c.nombre AS cargo,
       pe.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS docente,
       d.categoria, f.nombre AS facultad,
       pe.habilitado_para_votar, pe.ya_voto, pe.fecha_votacion, pe.motivo_inhabilitacion,
       pe.id_mesa, m.numero_mesa, m.ubicacion
  FROM padron_electoral pe
  JOIN cargo_electoral c ON c.id_cargo = pe.id_cargo
  JOIN docente d         ON d.id_docente = pe.id_docente
  JOIN facultad f        ON f.id_facultad = d.id_facultad
  LEFT JOIN mesa_electoral m ON m.id_mesa = pe.id_mesa;

-- RN31: participación y quórum por cargo, en tiempo real
CREATE VIEW v_participacion_cargo AS
SELECT c.id_proceso, c.id_cargo, c.nombre AS cargo,
       COUNT(pe.id_docente)            AS electores_habiles,
       COALESCE(SUM(pe.ya_voto), 0)    AS votaron,
       COUNT(pe.id_docente) - COALESCE(SUM(pe.ya_voto), 0) AS faltan,
       CASE WHEN COUNT(pe.id_docente) = 0 THEN 0
            ELSE ROUND(SUM(pe.ya_voto) * 100 / COUNT(pe.id_docente), 2) END AS participacion_pct,
       p.quorum_minimo,
       CASE WHEN COUNT(pe.id_docente) > 0
             AND SUM(pe.ya_voto) * 100 / COUNT(pe.id_docente) > p.quorum_minimo
            THEN 1 ELSE 0 END AS alcanza_quorum
  FROM cargo_electoral c
  JOIN proceso_electoral p ON p.id_proceso = c.id_proceso
  LEFT JOIN padron_electoral pe ON pe.id_cargo = c.id_cargo AND pe.habilitado_para_votar = 1
 GROUP BY c.id_proceso, c.id_cargo, c.nombre, p.quorum_minimo;

-- RN31: participación global del proceso (electores distintos)
CREATE VIEW v_quorum_proceso AS
SELECT p.id_proceso, p.nombre, p.estado, p.tipo, p.quorum_minimo,
       COUNT(x.id_docente)          AS electores_habiles,
       COALESCE(SUM(x.voto), 0)     AS votaron,
       CASE WHEN COUNT(x.id_docente) = 0 THEN 0
            ELSE ROUND(SUM(x.voto) * 100 / COUNT(x.id_docente), 2) END AS participacion_pct,
       CASE WHEN COUNT(x.id_docente) > 0
             AND SUM(x.voto) * 100 / COUNT(x.id_docente) > p.quorum_minimo
            THEN 1 ELSE 0 END AS alcanza_quorum
  FROM proceso_electoral p
  LEFT JOIN (SELECT id_proceso, id_docente, MAX(ya_voto) AS voto
               FROM padron_electoral
              WHERE habilitado_para_votar = 1
              GROUP BY id_proceso, id_docente) x ON x.id_proceso = p.id_proceso
 GROUP BY p.id_proceso, p.nombre, p.estado, p.tipo, p.quorum_minimo;

-- Alias con el nombre que usa tu documentación (diccionario_y_cambios_arquitectura.md)
CREATE VIEW vista_quorum AS
SELECT * FROM v_quorum_proceso;

-- Conteo por lista. Solo muestra procesos CERRADOS o FINALIZADOS:
-- durante la votación no devuelve filas, así nadie ve resultados parciales.
CREATE VIEW v_resultados_cargo AS
SELECT c.id_proceso, c.id_cargo, c.nombre AS cargo,
       l.id_lista, l.nombre AS lista, l.orden_cedula,
       COUNT(v.id_voto) AS votos,
       c.estado_resultado,
       CASE WHEN c.id_lista_ganadora = l.id_lista THEN 1 ELSE 0 END AS es_ganadora
  FROM cargo_electoral c
  JOIN proceso_electoral p ON p.id_proceso = c.id_proceso AND p.estado IN ('CERRADO','FINALIZADO')
  JOIN lista_electoral l   ON l.id_cargo = c.id_cargo AND l.estado = 'ADMITIDA'
  LEFT JOIN voto v         ON v.id_lista_elegida = l.id_lista AND v.tipo_voto = 'VALIDO'
 GROUP BY c.id_proceso, c.id_cargo, c.nombre, l.id_lista, l.nombre, l.orden_cedula,
          c.estado_resultado, c.id_lista_ganadora;

-- RN18: cédula de votación (listas admitidas en el orden sorteado, con su fórmula)
CREATE VIEW v_cedula_votacion AS
SELECT c.id_proceso, c.id_cargo, c.nombre AS cargo,
       l.id_lista, l.orden_cedula, l.nombre AS lista, l.simbolo,
       ca.rol_en_lista, CONCAT(d.apellidos, ', ', d.nombres) AS candidato
  FROM cargo_electoral c
  JOIN lista_electoral l ON l.id_cargo = c.id_cargo AND l.estado = 'ADMITIDA'
  JOIN candidato ca      ON ca.id_lista = l.id_lista AND ca.estado_validacion = 'APROBADO'
  JOIN docente d         ON d.id_docente = ca.id_docente;

-- RN15: portal de transparencia (solo candidatos aprobados de listas admitidas)
CREATE VIEW v_candidatos_publicos AS
SELECT c.id_proceso, c.nombre AS cargo, l.nombre AS lista, l.url_plan_gobierno,
       ca.rol_en_lista, CONCAT(d.nombres, ' ', d.apellidos) AS candidato,
       d.categoria, d.grado_academico, f.nombre AS facultad, ca.url_hoja_vida
  FROM candidato ca
  JOIN lista_electoral l ON l.id_lista = ca.id_lista AND l.estado = 'ADMITIDA'
  JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
  JOIN docente d         ON d.id_docente = ca.id_docente
  JOIN facultad f        ON f.id_facultad = d.id_facultad
 WHERE ca.estado_validacion = 'APROBADO';

-- RN27: cuadre de votos emitidos contra electores que sufragaron (debe dar diferencia 0)
CREATE VIEW v_cuadre_votos AS
SELECT c.id_proceso, c.id_cargo, c.nombre AS cargo,
       (SELECT COUNT(*) FROM padron_electoral pe WHERE pe.id_cargo = c.id_cargo AND pe.ya_voto = 1) AS electores_que_votaron,
       (SELECT COUNT(*) FROM voto v WHERE v.id_cargo = c.id_cargo) AS votos_en_urna,
       (SELECT COUNT(*) FROM voto v WHERE v.id_cargo = c.id_cargo)
     - (SELECT COUNT(*) FROM padron_electoral pe WHERE pe.id_cargo = c.id_cargo AND pe.ya_voto = 1) AS diferencia
  FROM cargo_electoral c;

-- Estado de las mesas
CREATE VIEW v_mesa_detalle AS
SELECT m.id_proceso, m.id_mesa, m.numero_mesa, m.ubicacion, m.estado,
       m.total_electores, m.hora_instalacion, m.hora_cierre, m.fecha_sorteo, m.semilla_sorteo,
       (SELECT COUNT(*) FROM miembro_mesa mm WHERE mm.id_mesa = m.id_mesa) AS miembros,
       (SELECT COUNT(DISTINCT pe.id_docente) FROM padron_electoral pe
         WHERE pe.id_mesa = m.id_mesa AND pe.ya_voto = 1) AS electores_que_votaron,
       (SELECT COUNT(*) FROM acta_electoral a WHERE a.id_mesa = m.id_mesa AND a.estado = 'VIGENTE') AS actas_emitidas
  FROM mesa_electoral m;

CREATE VIEW v_miembros_mesa AS
SELECT m.id_proceso, m.id_mesa, m.numero_mesa, mm.orden_sorteo, mm.rol, mm.titular, mm.asistio,
       d.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS docente, f.nombre AS facultad
  FROM miembro_mesa mm
  JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
  JOIN docente d        ON d.id_docente = mm.id_docente
  JOIN facultad f       ON f.id_facultad = d.id_facultad;

-- RN20: docentes que SÍ pueden entrar al sorteo de mesas de cada proceso
CREATE VIEW v_elegibles_sorteo AS
SELECT DISTINCT pe.id_proceso, pe.id_mesa, d.id_docente, d.dni,
       CONCAT(d.apellidos, ', ', d.nombres) AS docente
  FROM padron_electoral pe
  JOIN docente d ON d.id_docente = pe.id_docente
 WHERE pe.habilitado_para_votar = 1
   AND d.estado = 'ACTIVO'
   AND fn_tiene_cargo_excluyente(d.id_docente) = 0
   AND NOT EXISTS (SELECT 1 FROM candidato ca
                     JOIN lista_electoral l ON l.id_lista = ca.id_lista
                     JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                    WHERE ca.id_docente = d.id_docente AND c.id_proceso = pe.id_proceso
                      AND ca.estado_validacion <> 'EXCLUIDO')
   AND NOT EXISTS (SELECT 1 FROM personero p
                     JOIN lista_electoral l ON l.id_lista = p.id_lista
                     JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                    WHERE p.id_docente = d.id_docente AND c.id_proceso = pe.id_proceso
                      AND p.estado_acreditacion <> 'REVOCADO')
   AND NOT EXISTS (SELECT 1 FROM miembro_mesa mm
                     JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
                    WHERE mm.id_docente = d.id_docente AND m.id_proceso = pe.id_proceso);

-- Tachas con denunciante, candidato y lista
CREATE VIEW v_tachas_detalle AS
SELECT t.id_tacha, c.id_proceso, c.nombre AS cargo, l.id_lista, l.nombre AS lista,
       ca.id_candidato, ca.rol_en_lista,
       CONCAT(dc.apellidos, ', ', dc.nombres) AS candidato,
       CONCAT(dd.apellidos, ', ', dd.nombres) AS denunciante,
       t.motivo, t.estado, t.fecha_presentacion, t.fecha_resolucion, t.resolucion
  FROM tacha t
  JOIN candidato ca      ON ca.id_candidato = t.id_candidato
  JOIN lista_electoral l ON l.id_lista = ca.id_lista
  JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
  JOIN docente dc        ON dc.id_docente = ca.id_docente
  JOIN docente dd        ON dd.id_docente = t.id_docente_denunciante;

-- =====================================================================
-- 5. PROCEDIMIENTOS ALMACENADOS (ciclo electoral completo)
--
-- Convenciones:
--   p_  parámetros      v_  variables locales
--   Todo procedimiento que modifica datos abre su transacción y, ante
--   cualquier error, hace ROLLBACK y relanza el mensaje (SQLSTATE 45000).
--   Los mensajes citan la regla de negocio (RNxx) que se incumple.
--
-- Índice
--   A. Utilitarios ........ sp_registrar_auditoria, sp_emitir_acta
--   B. Proceso ............ sp_crear_proceso, sp_agregar_cargo, sp_cambiar_estado_proceso, sp_anular_proceso
--   C. Listas ............. sp_inscribir_lista, sp_inscribir_candidato, sp_validar_lista,
--                           sp_presentar_tacha, sp_resolver_tacha, sp_sortear_orden_cedula
--   D. Padrón y mesas ..... sp_generar_padron, sp_crear_mesas, sp_sortear_miembros_mesa,
--                           sp_sortear_todas_las_mesas, sp_registrar_asistencia_miembro
--   E. Día de elección .... sp_emitir_voto, sp_cerrar_mesa
--   F. Resultados ......... sp_computar_resultados, sp_crear_segunda_vuelta
--   G. Sanciones .......... sp_generar_multas, sp_actualizar_multa
--   H. Verificación QR .... sp_verificar_constancia, sp_verificar_acta
--   I. Instalación (CUS08)  sp_ventana_instalacion, sp_instalar_mesa, sp_declarar_mesa_no_instalada,
--                           sp_marcar_mesas_no_instaladas, sp_evaluar_nulidad_mesa
--   J. Voto y cierre ...... sp_votar_habilitado (CUS10, con el flujo A1 de CUS11),
--                           sp_cerrar_votacion, sp_marcar_ausentes, sp_generar_acta_sufragio
-- =====================================================================

DELIMITER $$

-- =====================================================================
-- A. UTILITARIOS
-- =====================================================================

-- Inserta una fila en la bitácora. No abre transacción: participa en la del llamador.
-- p_detalle_json debe ser JSON válido o NULL. Nunca registrar aquí la lista votada.
CREATE PROCEDURE sp_registrar_auditoria(
  IN p_id_usuario INT,
  IN p_id_docente INT,
  IN p_id_proceso INT,
  IN p_accion     VARCHAR(100),
  IN p_detalle_json LONGTEXT
)
BEGIN
  INSERT INTO log_auditoria (id_usuario, id_docente, id_proceso, accion, detalle_json)
  VALUES (p_id_usuario, p_id_docente, p_id_proceso, p_accion, p_detalle_json);
END$$

-- Emite un acta con su huella SHA-256 y un token de verificación (uso interno).
-- En la BD solo queda el hash del token; el token en claro va dentro del QR.
CREATE PROCEDURE sp_emitir_acta(
  IN  p_id_mesa   INT,
  IN  p_tipo      VARCHAR(12),
  IN  p_contenido LONGTEXT,
  OUT p_token     CHAR(64)
)
BEGIN
  SET p_token = SHA2(CONCAT(UUID(), RAND(), p_id_mesa, p_tipo, NOW(6)), 256);
  INSERT INTO acta_electoral (id_mesa, tipo, contenido_json, hash_integridad, token_qr_hash)
  VALUES (p_id_mesa, p_tipo, p_contenido, SHA2(p_contenido, 256), SHA2(p_token, 256));
END$$

-- =====================================================================
-- B. PROCESO ELECTORAL
-- =====================================================================

-- RF02: crea la convocatoria en estado CREADO.
CREATE PROCEDURE sp_crear_proceso(
  IN  p_nombre             VARCHAR(200),
  IN  p_fecha_inicio       DATETIME,
  IN  p_fecha_fin          DATETIME,
  IN  p_quorum_minimo      DECIMAL(5,2),     -- NULL = 60.00
  IN  p_fecha_convocatoria DATE,             -- puede ser NULL
  IN  p_limite_inscripcion DATETIME,         -- puede ser NULL
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
END$$

-- RF03: agrega un cargo y define qué categorías votan y cuáles postulan.
-- Las listas de categorías van separadas por coma, p. ej. 'PRINCIPAL,ASOCIADO'. NULL = todas.
CREATE PROCEDURE sp_agregar_cargo(
  IN  p_id_proceso          INT,
  IN  p_nombre              VARCHAR(150),
  IN  p_nivel               VARCHAR(20),     -- UNIVERSIDAD / FACULTAD / DEPARTAMENTO
  IN  p_id_jurisdiccion     INT,             -- NULL si es UNIVERSIDAD
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
END$$

-- Máquina de estados: CREADO -> INSCRIPCION -> VOTACION -> CERRADO.
-- FINALIZADO solo lo pone sp_computar_resultados; ANULADO solo sp_anular_proceso.
CREATE PROCEDURE sp_cambiar_estado_proceso(
  IN p_id_proceso   INT,
  IN p_nuevo_estado VARCHAR(20),
  IN p_id_usuario   INT
)
BEGIN
  DECLARE v_estado VARCHAR(20) DEFAULT NULL;
  DECLARE v_nuevo  VARCHAR(20);
  DECLARE v_n      INT DEFAULT 0;
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
    -- RN04: padrón aprobado
    SELECT COUNT(*) INTO v_n FROM padron_electoral WHERE id_proceso = p_id_proceso;
    IF v_n = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN04: falta generar el padron electoral.';
    END IF;
    -- cada cargo necesita al menos una lista admitida
    SELECT COUNT(*) INTO v_n
      FROM cargo_electoral c
     WHERE c.id_proceso = p_id_proceso
       AND NOT EXISTS (SELECT 1 FROM lista_electoral l
                        WHERE l.id_cargo = c.id_cargo AND l.estado = 'ADMITIDA');
    IF v_n > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hay cargos sin ninguna lista ADMITIDA.';
    END IF;
    -- RN18: orden de cédula sorteado
    SELECT COUNT(*) INTO v_n
      FROM lista_electoral l
      JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
     WHERE c.id_proceso = p_id_proceso AND l.estado = 'ADMITIDA' AND l.orden_cedula IS NULL;
    IF v_n > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN18: falta sortear el orden de las listas en la cedula.';
    END IF;
    -- RN19: mesas con sus 6 miembros
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

  UPDATE proceso_electoral
     SET estado = v_nuevo,
         fecha_cierre_real = IF(v_nuevo = 'CERRADO', NOW(), fecha_cierre_real)
   WHERE id_proceso = p_id_proceso;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'CAMBIO_ESTADO_PROCESO',
       JSON_OBJECT('anterior', v_estado, 'nuevo', v_nuevo));
  COMMIT;
END$$

-- RN34: nulidad del proceso por causal. Anula también mesas y actas.
CREATE PROCEDURE sp_anular_proceso(
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
END$$

-- =====================================================================
-- C. LISTAS, CANDIDATOS Y TACHAS
-- =====================================================================

-- CUN03: inscribe una lista (fórmula) para un cargo.
CREATE PROCEDURE sp_inscribir_lista(
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
END$$

-- RN10 / RN11 / RN13: agrega un integrante a la fórmula.
CREATE PROCEDURE sp_inscribir_candidato(
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

  -- RF03: categoría habilitada para postular (si el cargo tiene categorías configuradas)
  SELECT COUNT(*) INTO v_n FROM cargo_categoria_permitida WHERE id_cargo = v_cargo;
  IF v_n > 0 THEN
    SELECT COUNT(*) INTO v_n FROM cargo_categoria_permitida
     WHERE id_cargo = v_cargo AND categoria = v_doc_cat AND puede_postular = 1;
    IF v_n = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN09: la categoria del docente no puede postular a este cargo.';
    END IF;
  END IF;

  -- RN11 y RN20/21 los valida además el trigger trg_candidato_bi
  INSERT INTO candidato (id_lista, id_docente, rol_en_lista, url_hoja_vida, estado_validacion)
  VALUES (p_id_lista, p_id_docente, UPPER(TRIM(p_rol_en_lista)), p_url_hoja_vida, 'PENDIENTE');
  SET p_id_candidato = LAST_INSERT_ID();

  CALL sp_registrar_auditoria(p_id_usuario, p_id_docente, v_proceso, 'INSCRIBIR_CANDIDATO',
       JSON_OBJECT('id_lista', p_id_lista, 'rol', p_rol_en_lista));
  COMMIT;
END$$

-- CEUNP califica la lista completa (RN12: inscripción en bloque).
--   p_admitir = TRUE  -> lista ADMITIDA y candidatos APROBADO
--   p_admitir = FALSE -> lista EXCLUIDA y candidatos EXCLUIDO (requiere motivo)
CREATE PROCEDURE sp_validar_lista(
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
END$$

-- CUN04: un docente presenta una tacha contra un candidato (antes de la elección).
CREATE PROCEDURE sp_presentar_tacha(
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
END$$

-- CEUNP resuelve la tacha. FUNDADA: el candidato queda EXCLUIDO y,
-- por RN12 (inscripción en bloque), toda su lista pasa a TACHADA.
CREATE PROCEDURE sp_resolver_tacha(
  IN p_id_tacha   INT,
  IN p_resultado  VARCHAR(10),      -- FUNDADA / INFUNDADA
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
    UPDATE lista_electoral
       SET estado = 'TACHADA', orden_cedula = NULL, motivo_exclusion = 'Tacha fundada contra un integrante (RN12)'
     WHERE id_lista = v_lista;
  END IF;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'RESOLVER_TACHA',
       JSON_OBJECT('id_tacha', p_id_tacha, 'resultado', v_res));
  COMMIT;
END$$

-- RN18: sortea el orden de las listas ADMITIDAS en la cédula.
-- Reproducible: orden ascendente de SHA-256( semilla | id_lista ).
CREATE PROCEDURE sp_sortear_orden_cedula(
  IN p_id_cargo   INT,
  IN p_semilla    VARCHAR(128),     -- NULL = el sistema genera una
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

  SET v_semilla = COALESCE(NULLIF(TRIM(p_semilla), ''), SHA2(CONCAT(UUID(), RAND()), 256));

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
END$$

-- =====================================================================
-- D. PADRÓN ELECTORAL Y MESAS
-- =====================================================================

-- RF05 / RN03 / RN04: genera el padrón de cada cargo del proceso.
-- Incluye docentes ACTIVOS y habilitados, de la jurisdicción del cargo
-- y de una categoría con derecho a voto. Se puede regenerar mientras no haya mesas.
CREATE PROCEDURE sp_generar_padron(
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
END$$

-- Crea las mesas necesarias y reparte a los electores en bloques parejos,
-- ordenados por facultad y apellido. p_electores_por_mesa NULL = parámetro ELECTORES_POR_MESA.
CREATE PROCEDURE sp_crear_mesas(
  IN p_id_proceso         INT,
  IN p_electores_por_mesa INT,
  IN p_ubicacion          VARCHAR(200),    -- RN08; NULL = parámetro UBICACION_SUFRAGIO
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
END$$

-- RF06 / RN19 / RN20 / RNF01: sortea los 6 miembros de una mesa.
--   Elegibles ..... vista v_elegibles_sorteo (sin autoridades, candidatos, personeros
--                   ni miembros de otra mesa); se prefieren los electores de la propia mesa.
--   Algoritmo ..... orden ascendente de SHA-256( semilla | DNI ). Cualquiera puede
--                   repetir el cálculo con la semilla guardada y obtener el mismo resultado.
--   Asignación .... 1 PRESIDENTE, 2 SECRETARIO, 3 VOCAL, 4-6 SUPLENTE.
-- No abre transacción propia para poder invocarse desde sp_sortear_todas_las_mesas.
CREATE PROCEDURE sp_sortear_miembros_mesa(
  IN p_id_mesa    INT,
  IN p_semilla    VARCHAR(128),     -- NULL = el sistema genera una
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

  SET v_semilla = COALESCE(NULLIF(TRIM(p_semilla), ''), SHA2(CONCAT(UUID(), RAND()), 256));
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
END$$

-- Sortea todas las mesas pendientes del proceso en una sola transacción.
-- La semilla de cada mesa se deriva de la base: SHA-256( base | numero_mesa ).
CREATE PROCEDURE sp_sortear_todas_las_mesas(
  IN p_id_proceso   INT,
  IN p_semilla_base VARCHAR(128),   -- NULL = el sistema genera una
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
  SET v_base = COALESCE(NULLIF(TRIM(p_semilla_base), ''), SHA2(CONCAT(UUID(), RAND()), 256));

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
  COMMIT;

  SELECT numero_mesa, orden_sorteo, rol, docente, dni
    FROM v_miembros_mesa WHERE id_proceso = p_id_proceso ORDER BY numero_mesa, orden_sorteo;
END$$

-- Registra si un miembro de mesa se presentó (insumo de la multa OMISO_MESA, RN35).
CREATE PROCEDURE sp_registrar_asistencia_miembro(
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
END$$

-- =====================================================================
-- E. DÍA DE LA ELECCIÓN
-- =====================================================================
-- CORAZÓN DEL SISTEMA  (RN01, RN04, RN06, RN25, RN27, RF08, RF09)
-- En UNA sola transacción:
--   1. bloquea la fila del padrón (FOR UPDATE) -> imposible el doble voto concurrente
--   2. marca que el docente votó (sabemos QUIÉN)
--   3. inserta el voto anónimo (sabemos QUÉ, sin saber de quién)
--   4. emite la constancia con token QR
-- Si algo falla, no queda ni la marca ni el voto ni la constancia.
-- p_tipo_voto: 'VALIDO' (con p_id_lista) o 'BLANCO' (p_id_lista NULL).
CREATE PROCEDURE sp_emitir_voto(
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

  -- Proceso abierto y dentro del horario de sufragio
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

  -- Tipo de voto (RN25: en voto electrónico no existe el voto nulo)
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

  -- Padrón: bloqueo de fila
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

  -- RN07: su mesa debe estar instalada
  IF v_mesa IS NOT NULL THEN
    SELECT estado INTO v_mesa_est FROM mesa_electoral WHERE id_mesa = v_mesa;
    IF v_mesa_est <> 'INSTALADA' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN07: la mesa del elector no esta INSTALADA.';
    END IF;
  END IF;

  -- 2. quién votó
  UPDATE padron_electoral
     SET ya_voto = 1, fecha_votacion = NOW()
   WHERE id_proceso = p_id_proceso AND id_cargo = p_id_cargo AND id_docente = p_id_docente;

  -- 3. voto anónimo (sin id_docente)
  INSERT INTO voto (id_proceso, id_cargo, id_lista_elegida, tipo_voto, id_mesa)
  VALUES (p_id_proceso, p_id_cargo, IF(v_tipo = 'VALIDO', p_id_lista, NULL), v_tipo, v_mesa);

  -- 4. constancia de participación
  SET p_token_constancia = SHA2(CONCAT(UUID(), RAND(), p_id_docente, NOW(6)), 256);
  INSERT INTO constancia_voto (id_proceso, id_docente, id_cargo, token_qr_hash)
  VALUES (p_id_proceso, p_id_docente, p_id_cargo, SHA2(p_token_constancia, 256));

  -- Bitácora: registra que votó, jamás por quién (RNF05)
  CALL sp_registrar_auditoria(NULL, p_id_docente, p_id_proceso, 'EMITIR_VOTO',
       JSON_OBJECT('id_cargo', p_id_cargo));
  COMMIT;
END$$

-- RN27 / RN28: cierra la mesa y emite las actas de Sufragio y Escrutinio.
CREATE PROCEDURE sp_cerrar_mesa(
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

  -- La mesa deja de recibir votos antes de contar
  UPDATE mesa_electoral SET estado = 'CERRADA', hora_cierre = NOW() WHERE id_mesa = p_id_mesa;

  -- Acta de sufragio
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

  -- Acta de escrutinio (conteo por cargo y lista de los votos de esta mesa)
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
END$$

-- =====================================================================
-- F. RESULTADOS
-- =====================================================================

-- RN26 / RN27 / RN31 / RN32 / RN33: cómputo oficial e irreversible.
-- Requisitos: proceso CERRADO, todas las mesas cerradas y votos cuadrados.
-- Por cada cargo decide:
--   SIN_QUORUM ...... participación <= quórum mínimo
--   DESIERTO ........ hubo quórum pero ningún voto válido
--   ELEGIDO ......... una lista SUPERA el % mínimo de votos válidos (en 2.ª vuelta: la más votada)
--   SEGUNDA_VUELTA .. ninguna lista supera el % mínimo (o hay empate en 1.ª vuelta)
--   EMPATE .......... empate en segunda vuelta (lo resuelve el CEUNP)
-- El proceso queda FINALIZADO, o ANULADO si ningún cargo alcanzó el quórum.
CREATE PROCEDURE sp_computar_resultados(
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
  -- RN32: todas las mesas deben haber cerrado y emitido sus actas
  SELECT COUNT(*) INTO v_n FROM mesa_electoral
   WHERE id_proceso = p_id_proceso AND estado = 'INSTALADA';
  IF v_n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN32: aun hay mesas instaladas sin cerrar.';
  END IF;
  -- RN27: votos en urna = electores que sufragaron
  SELECT COUNT(*) INTO v_n FROM v_cuadre_votos WHERE id_proceso = p_id_proceso AND diferencia <> 0;
  IF v_n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN27: los votos no cuadran con el padron. Revise v_cuadre_votos.';
  END IF;

  -- Votos por lista, porcentaje sobre válidos y posición
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

  -- Blancos y nulos (id_lista NULL)
  INSERT INTO resultado_electoral (id_proceso, id_cargo, id_lista, tipo_voto, total_votos)
  SELECT c.id_proceso, c.id_cargo, NULL, 'BLANCO',
         (SELECT COUNT(*) FROM voto v WHERE v.id_cargo = c.id_cargo AND v.tipo_voto = 'BLANCO')
    FROM cargo_electoral c WHERE c.id_proceso = p_id_proceso;
  INSERT INTO resultado_electoral (id_proceso, id_cargo, id_lista, tipo_voto, total_votos)
  SELECT c.id_proceso, c.id_cargo, NULL, 'NULO',
         (SELECT COUNT(*) FROM voto v WHERE v.id_cargo = c.id_cargo AND v.tipo_voto = 'NULO')
    FROM cargo_electoral c WHERE c.id_proceso = p_id_proceso;

  -- Decisión por cargo (solo consultas con agregados: siempre devuelven una fila)
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
END$$

-- =====================================================================
-- G. SANCIONES: sp_generar_multas y sp_actualizar_multa están en la sección 5f (CUS16)
-- =====================================================================

-- =====================================================================
-- H. VERIFICACIÓN POR QR
-- =====================================================================

-- Verifica una constancia de voto a partir del token del QR.
-- Informa que el docente participó; nunca por quién votó.
CREATE PROCEDURE sp_verificar_constancia(IN p_token CHAR(64))
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
END$$

-- Verifica un acta: recalcula el SHA-256 del contenido y lo compara con la huella guardada.
CREATE PROCEDURE sp_verificar_acta(IN p_token CHAR(64))
BEGIN
  SELECT a.id_acta, m.numero_mesa, a.tipo, a.fecha_emision, a.estado,
         a.hash_integridad,
         CASE WHEN SHA2(a.contenido_json, 256) = a.hash_integridad THEN 1 ELSE 0 END AS contenido_integro,
         a.contenido_json
    FROM acta_electoral a
    JOIN mesa_electoral m ON m.id_mesa = a.id_mesa
   WHERE a.token_qr_hash = SHA2(p_token, 256);
END$$

-- =====================================================================
-- I. INSTALACIÓN DE MESA (CUS08: RF56 a RF60)
-- =====================================================================

-- RN07: ¿se puede instalar ahora? Lee INSTALACION_HORA_INICIO, INSTALACION_HORA_LIMITE
-- e INSTALACION_CONTROL_HORARIO. La jornada es el día de fecha_inicio del proceso.
-- No modifica datos (se puede llamar dentro de otra transacción).
CREATE PROCEDURE sp_ventana_instalacion(
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
END$$

-- Mensajes 10 a 12 del diagrama: instalarMesa(id_mesa) ->
--   [antes de 12:00] actualizarEstado('INSTALADA', hora_instalacion) -> insertarActa('INSTALACION', hash)
-- Requiere: proceso en VOTACION, mesa PENDIENTE, dentro del horario, 6 miembros sorteados,
-- material recibido (RF57) y los tres cargos cubiertos: titular presente, si no el primer
-- suplente presente (orden del sorteo) y, si tampoco hay, el reemplazante registrado.
-- Devuelve el token del QR del acta (solo se muestra esta vez).
CREATE PROCEDURE sp_instalar_mesa(
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

  -- [antes de 12:00]
  CALL sp_ventana_instalacion(v_proceso, v_abierta, v_vencida, v_control, v_msg);
  IF v_abierta = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  SELECT COUNT(*) INTO v_n FROM miembro_mesa WHERE id_mesa = p_id_mesa;
  IF v_n <> 6 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN19: la mesa no tiene sus 6 miembros sorteados.';
  END IF;

  -- RF57: material verificado
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

  -- Conformación: titular presente, si no el primer suplente presente, si no el reemplazante
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

  -- Reemplazantes que no hicieron falta (llegó un titular o un suplente) no quedan en la mesa
  DELETE r FROM reemplazo_mesa r
   WHERE r.id_mesa = p_id_mesa
     AND EXISTS (SELECT 1 FROM miembro_mesa mm WHERE mm.id_mesa = r.id_mesa AND mm.rol_instalacion = r.cargo);

  -- RN35: quien no llegó no asistió
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

  -- RF59: hora, estado del material, cédulas recibidas, observaciones y firmas
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

  -- 11: actualizarEstado('INSTALADA', hora_instalacion)
  UPDATE mesa_electoral SET estado = 'INSTALADA', hora_instalacion = v_ahora WHERE id_mesa = p_id_mesa;
  -- 12: insertarActa('INSTALACION', hash)
  CALL sp_emitir_acta(p_id_mesa, 'INSTALACION', v_contenido, v_token);
  SELECT id_acta, hash_integridad INTO v_id_acta, v_hash
    FROM acta_electoral WHERE id_mesa = p_id_mesa AND tipo = 'INSTALACION';

  -- Firman el acta quienes ejercen los tres cargos y los personeros presentes
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
END$$

-- RF58: el CEUNP deja constancia de que una mesa no se instaló (con el control horario
-- activo, solo vencido el plazo). Sus electores ya no pueden votar en ella y los miembros
-- que no llegaron quedan como inasistentes (multa OMISO_MESA, RN35).
CREATE PROCEDURE sp_declarar_mesa_no_instalada(
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
END$$

-- RF58: pasadas las 12:00 (con el control horario activo), toda mesa PENDIENTE de un proceso
-- en VOTACION queda NO_INSTALADA. El backend lo ejecuta cada minuto y al consultar las mesas.
-- Devuelve cuántas mesas marcó.
CREATE PROCEDURE sp_marcar_mesas_no_instaladas()
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
END$$

-- RF60: el CEUNP registra su evaluación de nulidad de una mesa NO INSTALADA (una sola vez).
CREATE PROCEDURE sp_evaluar_nulidad_mesa(
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
END$$

-- =====================================================================
-- J. CERRAR SUFRAGIO (CUS11: RF74 a RF76) y voto desde el terminal (CUS10)
-- =====================================================================

-- CUS10 · crear(opción, mesa), igual que en 06_verificar_elector_emitir_voto.sql salvo el
-- horario: CUS11 A1 (Art. 51a) permite terminar su voto, pasada la hora de cierre, al
-- elector habilitado antes de esa hora. La mesa CERRADA ya no recibe votos.
CREATE PROCEDURE sp_votar_habilitado(
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

  -- Habilitación de un solo uso (bloqueada hasta el fin de la transacción)
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

  -- Padrón: bloqueo de fila (RN01: imposible el doble voto concurrente)
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

  -- Votó: se marca solo aquí, dentro de la transacción del voto
  UPDATE padron_electoral
     SET ya_voto = 1, fecha_votacion = NOW()
   WHERE id_proceso = v_proceso AND id_cargo = p_id_cargo AND id_docente = v_docente;

  -- Voto sin vínculo con el elector (RF69, RNF06)
  INSERT INTO voto (id_proceso, id_cargo, id_lista_elegida, tipo_voto, id_mesa)
  VALUES (v_proceso, p_id_cargo, IF(v_tipo = 'VALIDO', p_id_lista, NULL), v_tipo, v_mesa);

  -- generarConstancia(): prueba de participación (no del sentido del voto)
  SET p_token_constancia = SHA2(CONCAT(UUID(), RAND(), v_docente, NOW(6)), 256);
  INSERT INTO constancia_voto (id_proceso, id_docente, id_cargo, token_qr_hash)
  VALUES (v_proceso, v_docente, p_id_cargo, SHA2(p_token_constancia, 256));

  CALL sp_registrar_auditoria(NULL, v_docente, v_proceso, 'EMITIR_VOTO',
       JSON_OBJECT('id_cargo', p_id_cargo));
END$$

-- Mensajes 2 a 4: cerrarVotacion(id_mesa) -> actualizarEstado('CERRADA', hora_cierre)
--   -> mostrarTotalVotantes(total).
-- Requiere: proceso en VOTACION, mesa INSTALADA, la hora de cierre del proceso (fecha_fin,
-- 15:00 por RN06) o que ya votaron todos los electores de la mesa, y ningún elector votando
-- en un terminal (A1). Bloquea nuevas verificaciones (la mesa queda CERRADA) y deshabilita
-- los terminales de la mesa.
CREATE PROCEDURE sp_cerrar_votacion(
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

  -- Totales por elector (un docente vota todos sus cargos en una sola cédula)
  SELECT COUNT(*), COALESCE(SUM(x.voto), 0)
    INTO v_electores, v_votaron
    FROM (SELECT id_docente, MAX(ya_voto) AS voto
            FROM padron_electoral
           WHERE id_mesa = p_id_mesa AND habilitado_para_votar = 1
           GROUP BY id_docente) x;
  SELECT COUNT(*) INTO v_asistieron FROM asistencia_elector WHERE id_mesa = p_id_mesa;

  -- A1 (Art. 51a): quien está votando termina antes del cierre
  SELECT COUNT(*) INTO v_votando
    FROM habilitacion_terminal h JOIN asistencia_elector a ON a.id_asistencia = h.id_asistencia
   WHERE a.id_mesa = p_id_mesa AND h.estado = 'PENDIENTE';
  IF v_votando > 0 THEN
    SET v_msg = CONCAT('A1 (Art. 51a): ', v_votando, ' elector(es) aún votan en un terminal. Espere a que terminen ',
                       'o anule la habilitación si el elector abandonó la cabina.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  -- Precondición: hora de cierre (RN06) o ya votaron todos los electores
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

  -- 3: actualizarEstado('CERRADA', hora_cierre). La mesa CERRADA ya no verifica electores.
  UPDATE mesa_electoral SET estado = 'CERRADA', hora_cierre = v_ahora WHERE id_mesa = p_id_mesa;
  -- Paso 2 de la tabla 37: se deshabilitan los terminales de la mesa
  UPDATE terminal_votacion SET activo = 0 WHERE id_mesa = p_id_mesa;

  INSERT INTO cierre_mesa (id_mesa, estado, hora_cierre, cierre_anticipado, total_electores, total_votaron,
                           total_no_votaron, asistieron_sin_votar, cedulas_recibidas, id_usuario_cierre)
  VALUES (p_id_mesa, 'VOTACION_CERRADA', v_ahora, v_anticipado, v_electores, v_votaron,
          v_electores - v_votaron, GREATEST(v_asistieron - v_votaron, 0), v_cedulas, p_id_usuario);

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'CERRAR_SUFRAGIO',
       JSON_OBJECT('id_mesa', p_id_mesa, 'votaron', v_votaron, 'electores', v_electores,
                   'anticipado', v_anticipado));
  COMMIT;

  -- 4: mostrarTotalVotantes(total)
  SELECT p_id_mesa AS id_mesa, v_ahora AS hora_cierre, v_electores AS total_electores,
         v_votaron AS total_votaron, v_electores - v_votaron AS total_no_votaron;
END$$

-- Mensajes 6 a 8: marcarAusentes(id_mesa) -> actualizarNoVoto(id_mesa) -> mostrarListaNoVoto().
-- Marca NO VOTÓ en el padrón de la mesa a los electores hábiles que no votaron (RF75):
-- los que no asistieron y los que asistieron sin votar (CUS10 A3).
CREATE PROCEDURE sp_marcar_ausentes(
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

  -- 7: actualizarNoVoto(id_mesa)
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
END$$

-- Mensajes 10 a 12: generarActa(datos) -> insertarActa('SUFRAGIO', hash, contenido)
--   -> registrarFirmas(firmas).
-- RF76: total de electores que votaron, cédulas no utilizadas, hora de cierre, observaciones
-- y firmas. Firman el presidente y el secretario en funciones (titular, suplente o
-- reemplazante) y los personeros presentes que lo deseen (p_personeros: arreglo JSON de
-- id_personero). A2: si el conteo de firmas de la lista física difiere del total del
-- sistema, la observación es obligatoria. Devuelve el token del QR (solo esta vez).
CREATE PROCEDURE sp_generar_acta_sufragio(
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

  -- 9: ingresarObservaciones(cedulas_no_usadas, observaciones)
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
  -- A2: el total del sistema difiere del conteo de firmas en la lista física
  IF p_firmas_lista_fisica IS NOT NULL AND p_firmas_lista_fisica <> v_votaron AND v_obs IS NULL THEN
    SET v_msg = CONCAT('A2: la lista física tiene ', p_firmas_lista_fisica, ' firmas y el sistema registra ',
                       v_votaron, ' votantes. Registre la observación.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  -- Personeros que firman: deben estar presentes en la mesa (CUS08)
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

  -- Firman el presidente y el secretario en funciones
  SELECT COUNT(*) INTO v_n FROM (
    SELECT rol_instalacion AS cargo FROM miembro_mesa
     WHERE id_mesa = p_id_mesa AND rol_instalacion IN ('PRESIDENTE', 'SECRETARIO')
    UNION
    SELECT cargo FROM reemplazo_mesa WHERE id_mesa = p_id_mesa AND cargo IN ('PRESIDENTE', 'SECRETARIO')) f;
  IF v_n < 2 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no registra presidente y secretario en funciones (CUS08).';
  END IF;

  -- RF75: lista de electores con la marca NO VOTÓ
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

  -- 10: generarActa(datos). RF76: votantes, cédulas no utilizadas, hora de cierre y observaciones
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

  -- 11: insertarActa('SUFRAGIO', hash, contenido)
  CALL sp_emitir_acta(p_id_mesa, 'SUFRAGIO', v_contenido, v_token);
  SELECT id_acta, hash_integridad INTO v_id_acta, v_hash
    FROM acta_electoral WHERE id_mesa = p_id_mesa AND tipo = 'SUFRAGIO';

  -- 12: registrarFirmas(firmas): presidente y secretario en funciones, y personeros que lo desean
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

  -- 13: mostrarActaSufragio()
  SELECT p_id_mesa AS id_mesa, v_id_acta AS id_acta, 'SUFRAGIO' AS acta, v_token AS token_qr;
END$$

DELIMITER ;

-- =====================================================================
-- 5b. CUS12 · Realizar escrutinio y conciliar (cédulas, conteo manual vs. digital,
--     impugnaciones, acta de escrutinio y entrega al CEUNP)
-- (en una base ya instalada sin este CUS se aplica 11_escrutinio_conciliacion.sql)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. La columna impugnacion_electoral.id_cargo ya viene en su CREATE TABLE (sección 2)
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- 2. Tablas nuevas
-- ---------------------------------------------------------------------
-- Escrutinio de cada mesa (relación 1 a 1 con mesa_electoral). Guarda el avance de los
-- pasos del diagrama, el cuadre de cédulas (RN27), la conciliación y la entrega al CEUNP.
CREATE TABLE escrutinio_mesa (
  id_mesa              INT PRIMARY KEY,
  estado               ENUM('CEDULAS_CONTADAS','CONTEO_REGISTRADO','ACTA_EMITIDA','ENTREGADA') NOT NULL DEFAULT 'CEDULAS_CONTADAS',
  hora_inicio          DATETIME NOT NULL,          -- RF85: hora de inicio del escrutinio
  hora_fin             DATETIME NULL,              -- RF85: hora de fin (al emitir el acta)
  total_votantes       INT NOT NULL,               -- 3 contarVotantes() (acta de sufragio, CUS11)
  cedulas_contadas     INT NOT NULL,               -- 1 ingresarTotalCedulas(total) (RF77)
  cedulas_sobrantes    INT NOT NULL DEFAULT 0,     -- A1: retiradas al azar y destruidas sin abrir (RF78)
  cedulas_faltantes    INT NOT NULL DEFAULT 0,     -- A2: faltan cédulas (RF78)
  cedulas_escrutadas   INT NOT NULL,               -- cédulas que se leen y clasifican
  observacion_cedulas  VARCHAR(1000) NULL,         -- A1 / A2
  veces_conteo         INT NOT NULL DEFAULT 0,     -- 1 = primer conteo; > 1 = recuentos (A3)
  conteo_cuadra        BOOLEAN NULL,               -- RF83: manual = digital en todas las opciones
  total_cuadra         BOOLEAN NULL,               -- RF82: votos emitidos = electores que votaron
  fecha_conteo         DATETIME NULL,
  prevalece_fisica     BOOLEAN NOT NULL DEFAULT FALSE, -- RF84 / A3: prevalece la cédula física
  observada            BOOLEAN NOT NULL DEFAULT FALSE, -- A5: acta con observaciones
  observaciones        VARCHAR(1000) NULL,
  id_acta              INT NULL,                   -- acta de escrutinio emitida
  fecha_acta           DATETIME NULL,
  fecha_entrega        DATETIME NULL,              -- RF87: entrega al CEUNP
  recibido_por         VARCHAR(150) NULL,
  ejemplares           INT NULL,                   -- RF86: CEUNP, ONPE y local de votación
  copias_personeros    INT NULL,                   -- RF86: copias simples a los personeros
  entrega_padron       BOOLEAN NULL,
  entrega_material     BOOLEAN NULL,
  observacion_entrega  VARCHAR(500) NULL,
  codigo_cargo         CHAR(12) NULL,              -- RF87: código del cargo de entrega
  id_usuario_inicio    INT NULL,
  id_usuario_conteo    INT NULL,
  id_usuario_acta      INT NULL,
  id_usuario_entrega   INT NULL,
  UNIQUE KEY uq_escrutinio_acta (id_acta),
  CONSTRAINT chk_escrutinio_cedulas CHECK (cedulas_contadas >= 0 AND cedulas_sobrantes >= 0 AND cedulas_faltantes >= 0
                                           AND cedulas_escrutadas = cedulas_contadas - cedulas_sobrantes),
  CONSTRAINT chk_escrutinio_acta CHECK (estado NOT IN ('ACTA_EMITIDA','ENTREGADA') OR (id_acta IS NOT NULL AND hora_fin IS NOT NULL)),
  CONSTRAINT chk_escrutinio_entrega CHECK (estado <> 'ENTREGADA' OR (fecha_entrega IS NOT NULL AND recibido_por IS NOT NULL)),
  CONSTRAINT fk_escrutinio_mesa     FOREIGN KEY (id_mesa)            REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_escrutinio_acta     FOREIGN KEY (id_acta)            REFERENCES acta_electoral(id_acta),
  CONSTRAINT fk_escrutinio_inicio   FOREIGN KEY (id_usuario_inicio)  REFERENCES usuario(id_usuario),
  CONSTRAINT fk_escrutinio_conteo   FOREIGN KEY (id_usuario_conteo)  REFERENCES usuario(id_usuario),
  CONSTRAINT fk_escrutinio_emisor   FOREIGN KEY (id_usuario_acta)    REFERENCES usuario(id_usuario),
  CONSTRAINT fk_escrutinio_entrega  FOREIGN KEY (id_usuario_entrega) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Conteo manual por opción (5 ingresarConteoManual) junto al conteo digital (7 contarVotosDigitales).
-- opcion: LISTA (id_lista), BLANCO, NULO o IMPUGNADO (solo manual: la cédula apartada).
CREATE TABLE escrutinio_conteo (
  id_conteo     INT AUTO_INCREMENT PRIMARY KEY,
  id_mesa       INT NOT NULL,
  id_cargo      INT NOT NULL,
  opcion        ENUM('LISTA','BLANCO','NULO','IMPUGNADO') NOT NULL,
  id_lista      INT NULL,
  votos_manual  INT NOT NULL,
  votos_digital INT NOT NULL DEFAULT 0,
  lista_clave   INT AS (COALESCE(id_lista, 0)) STORED,
  UNIQUE KEY uq_conteo_opcion (id_mesa, id_cargo, opcion, lista_clave),
  CONSTRAINT chk_conteo_votos CHECK (votos_manual >= 0 AND votos_digital >= 0),
  CONSTRAINT chk_conteo_lista CHECK ((opcion = 'LISTA' AND id_lista IS NOT NULL) OR (opcion <> 'LISTA' AND id_lista IS NULL)),
  CONSTRAINT fk_conteo_escrutinio FOREIGN KEY (id_mesa)  REFERENCES escrutinio_mesa(id_mesa),
  CONSTRAINT fk_conteo_cargo      FOREIGN KEY (id_cargo) REFERENCES cargo_electoral(id_cargo),
  CONSTRAINT fk_conteo_lista      FOREIGN KEY (id_lista) REFERENCES lista_electoral(id_lista)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 3. Triggers y procedimientos
-- ---------------------------------------------------------------------

DELIMITER $$

-- RN26: el escrutinio es irreversible. El cuadre de cédulas no cambia; emitida el acta,
-- solo se registra la entrega, y entregada ya no cambia nada.
CREATE TRIGGER trg_escrutinio_bu BEFORE UPDATE ON escrutinio_mesa
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
END$$

CREATE TRIGGER trg_escrutinio_bd BEFORE DELETE ON escrutinio_mesa
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el registro del escrutinio no se elimina.';
END$$

-- El conteo se puede repetir (recuento, A3) solo hasta emitir el acta.
CREATE TRIGGER trg_conteo_bi BEFORE INSERT ON escrutinio_conteo
FOR EACH ROW
BEGIN
  IF (SELECT estado FROM escrutinio_mesa WHERE id_mesa = NEW.id_mesa) IN ('ACTA_EMITIDA','ENTREGADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el acta de escrutinio ya fue emitida; el conteo no cambia.';
  END IF;
END$$

CREATE TRIGGER trg_conteo_bu BEFORE UPDATE ON escrutinio_conteo
FOR EACH ROW
BEGIN
  IF (SELECT estado FROM escrutinio_mesa WHERE id_mesa = OLD.id_mesa) IN ('ACTA_EMITIDA','ENTREGADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el acta de escrutinio ya fue emitida; el conteo no cambia.';
  END IF;
END$$

CREATE TRIGGER trg_conteo_bd BEFORE DELETE ON escrutinio_conteo
FOR EACH ROW
BEGIN
  IF (SELECT estado FROM escrutinio_mesa WHERE id_mesa = OLD.id_mesa) IN ('ACTA_EMITIDA','ENTREGADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el acta de escrutinio ya fue emitida; el conteo no cambia.';
  END IF;
END$$

-- Mensajes 1 a 4: ingresarTotalCedulas(total) -> verificarTotal() -> contarVotantes()
--   -> mostrarResultadoValidacion().
-- Requiere el sufragio cerrado y el acta de sufragio emitida (CUS11). Abre el escrutinio
-- (hora de inicio, RF85) y compara las cédulas del ánfora con los electores que votaron
-- (RF77). A1: si sobran, el presidente confirma que las retiró al azar y las destruyó sin
-- abrirlas. A1 y A2 exigen la observación (RF78).
CREATE PROCEDURE sp_contar_cedulas(
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

  -- 2-3: verificarTotal() -> contarVotantes()
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

  -- 4: mostrarResultadoValidacion()
  SELECT p_id_mesa AS id_mesa, v_ahora AS hora_inicio, v_votantes AS total_votantes,
         p_total_cedulas AS cedulas_contadas, v_sobran AS cedulas_sobrantes, v_faltan AS cedulas_faltantes,
         p_total_cedulas - v_sobran AS cedulas_escrutadas,
         IF(v_sobran > 0, 'SOBRAN', IF(v_faltan > 0, 'FALTAN', 'COINCIDE')) AS resultado;
END$$

-- Paso 4 de la tabla 38: un personero presente en la mesa impugna un voto (RN24, RF80).
-- La cédula se aparta y se cuenta como IMPUGNADA hasta que se resuelva (A4, CUS13).
-- Si el conteo ya estaba registrado, hay que volver a registrarlo con el nuevo impugnado.
CREATE PROCEDURE sp_registrar_impugnacion(
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

  -- El conteo registrado ya no refleja los impugnados: se vuelve a registrar
  UPDATE escrutinio_mesa SET estado = 'CEDULAS_CONTADAS', conteo_cuadra = NULL, total_cuadra = NULL
   WHERE id_mesa = p_id_mesa AND estado = 'CONTEO_REGISTRADO';

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'REGISTRAR_IMPUGNACION',
       JSON_OBJECT('id_mesa', p_id_mesa, 'id_impugnacion', p_id_impugnacion, 'id_cargo', p_id_cargo,
                   'id_personero', p_id_personero));
  COMMIT;
END$$

-- Mensajes 5 a 8: ingresarConteoManual(conteo_listas) -> compararConDigital(conteo)
--   -> contarVotosDigitales() -> mostrarCuadre().
-- p_conteo: arreglo JSON [{"id_cargo":1,"opcion":"LISTA","id_lista":3,"votos":12},
--   {"id_cargo":1,"opcion":"BLANCO","votos":2}, {"id_cargo":1,"opcion":"NULO","votos":0},
--   {"id_cargo":1,"opcion":"IMPUGNADO","votos":1}]. Una opción omitida vale 0.
-- Reglas por cargo:
--   · no hay más votos que cédulas escrutadas (error);
--   · los impugnados coinciden con las impugnaciones registradas (A4);
--   · RF82: votos emitidos = electores que votaron ese cargo (si no, se exige observación);
--   · RF83: cuadra si ninguna opción tiene más votos manuales que digitales y lo que falta en
--     las opciones son las cédulas impugnadas (sin impugnados: igualdad exacta), más, si
--     faltaron cédulas en el ánfora (A2), a lo sumo las que faltaron.
-- Volver a registrarlo es un recuento (A3).
CREATE PROCEDURE sp_registrar_conteo(
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
    manual INT NOT NULL DEFAULT 0, faltan_digital INT NOT NULL DEFAULT 0, sobran_manual INT NOT NULL DEFAULT 0,
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

  -- Cargos que se votan en la mesa, con sus votantes y sus impugnaciones registradas
  INSERT INTO tmp_cargos_cus12 (id_cargo, votantes, impugnaciones)
  SELECT pe.id_cargo, SUM(pe.ya_voto),
         (SELECT COUNT(*) FROM impugnacion_electoral i WHERE i.id_mesa = p_id_mesa AND i.id_cargo = pe.id_cargo)
    FROM padron_electoral pe
   WHERE pe.id_mesa = p_id_mesa AND pe.habilitado_para_votar = 1
   GROUP BY pe.id_cargo;

  -- 5: ingresarConteoManual(conteo_listas)
  SET v_n = JSON_LENGTH(p_conteo);
  WHILE v_i < v_n DO
    SET v_cargo = JSON_EXTRACT(p_conteo, CONCAT('$[', v_i, '].id_cargo'));
    SET v_opcion = UPPER(JSON_UNQUOTE(JSON_EXTRACT(p_conteo, CONCAT('$[', v_i, '].opcion'))));
    SET v_lista = NULLIF(JSON_EXTRACT(p_conteo, CONCAT('$[', v_i, '].id_lista')), 'null');
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

  -- 6-7: compararConDigital(conteo) -> contarVotosDigitales(). Se rehace el conteo (recuento, A3).
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

  -- Totales por cargo
  UPDATE tmp_cargos_cus12 c
     SET c.manual = (SELECT COALESCE(SUM(k.votos_manual), 0) FROM escrutinio_conteo k
                      WHERE k.id_mesa = p_id_mesa AND k.id_cargo = c.id_cargo),
         c.impugnados = (SELECT COALESCE(SUM(k.votos_manual), 0) FROM escrutinio_conteo k
                          WHERE k.id_mesa = p_id_mesa AND k.id_cargo = c.id_cargo AND k.opcion = 'IMPUGNADO'),
         c.faltan_digital = (SELECT COALESCE(SUM(GREATEST(k.votos_digital - k.votos_manual, 0)), 0) FROM escrutinio_conteo k
                              WHERE k.id_mesa = p_id_mesa AND k.id_cargo = c.id_cargo AND k.opcion <> 'IMPUGNADO'),
         c.sobran_manual = (SELECT COALESCE(SUM(GREATEST(k.votos_manual - k.votos_digital, 0)), 0) FROM escrutinio_conteo k
                             WHERE k.id_mesa = p_id_mesa AND k.id_cargo = c.id_cargo AND k.opcion <> 'IMPUGNADO');

  -- No puede haber más votos que cédulas escrutadas
  SELECT COUNT(*) INTO v_mal FROM tmp_cargos_cus12 WHERE manual > v_escrutadas;
  IF v_mal > 0 THEN
    SET v_msg = CONCAT('RF79: un cargo suma más votos que las ', v_escrutadas, ' cédulas escrutadas. Revise el conteo.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  -- A4: los impugnados son las cédulas apartadas por una impugnación registrada
  SELECT COUNT(*) INTO v_mal FROM tmp_cargos_cus12 WHERE impugnados <> impugnaciones;
  IF v_mal > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A4: los votos impugnados deben coincidir con las impugnaciones registradas de cada cargo.';
  END IF;

  -- 8: mostrarCuadre(). RF83 (conciliación) y RF82 (total de votos = electores que votaron)
  -- Con cédulas faltantes (A2), los votos digitales sin cédula no pasan de las que faltan.
  SELECT IF(COUNT(*) = 0, 1, 0) INTO v_cuadra FROM tmp_cargos_cus12
   WHERE sobran_manual > 0 OR faltan_digital - impugnados < 0 OR faltan_digital - impugnados > v_faltantes;
  SELECT IF(COUNT(*) = 0, 1, 0) INTO v_total_ok FROM tmp_cargos_cus12 WHERE manual <> votantes;

  UPDATE escrutinio_mesa
     SET estado = 'CONTEO_REGISTRADO', veces_conteo = v_veces + 1, conteo_cuadra = v_cuadra,
         total_cuadra = v_total_ok, fecha_conteo = NOW(), id_usuario_conteo = p_id_usuario
   WHERE id_mesa = p_id_mesa;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'REGISTRAR_CONTEO_ESCRUTINIO',
       JSON_OBJECT('id_mesa', p_id_mesa, 'conteo', v_veces + 1, 'cuadra', v_cuadra, 'total_cuadra', v_total_ok));
  COMMIT;

  SELECT p_id_mesa AS id_mesa, v_cuadra AS conteo_cuadra, v_total_ok AS total_cuadra,
         v_veces + 1 AS veces_conteo;
END$$

-- Mensajes 9 a 13: confirmarEscrutinio() -> crearActa(resultados) -> insertarActa(hash, contenido)
--   -> registrarFirmas(firmas) -> mostrarActaGenerada().
-- RF85: hora de inicio y fin, votos por lista, en blanco, nulos, impugnados, total, observaciones
-- y firmas. A3: si el conteo manual difiere del digital, debe haberse recontado al menos una vez
-- y se confirma que prevalece la cédula física (RF84), con observación. RF82: si los votos no
-- igualan a los votantes, se exige observación. A5: con observaciones, el acta sale OBSERVADA.
-- Firman los miembros en funciones (presidente, secretario y vocal: titular, suplente o
-- reemplazante) y los personeros presentes que lo deseen. Devuelve el token del QR (solo esta vez).
CREATE PROCEDURE sp_generar_acta_escrutinio(
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
  -- A3: el conteo manual difiere del digital
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
  -- RF82: votos emitidos distintos de los electores que votaron
  IF v_total_ok = 0 AND v_obs IS NULL AND v_obs_ced IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF82: el total de votos no es igual al de electores que votaron. Registre la observación.';
  END IF;
  -- A5
  SET v_observada = IF(v_obs IS NOT NULL OR v_obs_ced IS NOT NULL, 1, 0);

  -- Personeros que firman: deben estar presentes en la mesa (CUS08)
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

  -- Firman al menos el presidente y el secretario en funciones
  SELECT COUNT(*) INTO v_n FROM (
    SELECT rol_instalacion AS cargo FROM miembro_mesa
     WHERE id_mesa = p_id_mesa AND rol_instalacion IN ('PRESIDENTE', 'SECRETARIO')
    UNION
    SELECT cargo FROM reemplazo_mesa WHERE id_mesa = p_id_mesa AND cargo IN ('PRESIDENTE', 'SECRETARIO')) f;
  IF v_n < 2 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no registra presidente y secretario en funciones (CUS08).';
  END IF;

  -- 10: crearActa(resultados). Resultados por cargo: manual (oficial, RF84) y digital
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

  -- 11: insertarActa(hash, contenido)
  CALL sp_emitir_acta(p_id_mesa, 'ESCRUTINIO', v_contenido, v_token);
  SELECT id_acta, hash_integridad INTO v_id_acta, v_hash
    FROM acta_electoral WHERE id_mesa = p_id_mesa AND tipo = 'ESCRUTINIO';

  -- 12: registrarFirmas(firmas): miembros en funciones y personeros que lo desean
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

  -- Las impugnaciones quedan vinculadas al acta para su trámite (CUS13)
  UPDATE impugnacion_electoral SET id_acta = v_id_acta WHERE id_mesa = p_id_mesa AND id_acta IS NULL;

  UPDATE escrutinio_mesa
     SET estado = 'ACTA_EMITIDA', hora_fin = v_ahora, prevalece_fisica = v_prevalece, observada = v_observada,
         observaciones = v_obs, id_acta = v_id_acta, fecha_acta = v_ahora, id_usuario_acta = p_id_usuario
   WHERE id_mesa = p_id_mesa;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'EMITIR_ACTA_ESCRUTINIO',
       JSON_OBJECT('id_mesa', p_id_mesa, 'id_acta', v_id_acta, 'observada', v_observada,
                   'prevalece_fisica', v_prevalece, 'impugnados', v_impug));
  COMMIT;

  -- 13: mostrarActaGenerada()
  SELECT p_id_mesa AS id_mesa, v_id_acta AS id_acta, 'ESCRUTINIO' AS acta, v_token AS token_qr,
         v_observada AS observada;
END$$

-- Paso 9 de la tabla 38 (RF86, RF87): se imprimen los tres ejemplares (CEUNP, ONPE y local de
-- votación) y las copias para los personeros, y se registra la entrega al CEUNP de las actas,
-- el padrón y el material, con el código del cargo de entrega.
CREATE PROCEDURE sp_registrar_entrega_actas(
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
  SET v_codigo = UPPER(LEFT(SHA2(CONCAT(p_id_mesa, '|', v_numero, '|', v_ahora, '|', UUID()), 256), 12));

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
END$$

DELIMITER ;

-- =====================================================================
-- 5c. CUS13 · Gestionar impugnaciones y apelaciones (decisión de la mesa, apelación
--     y fallo del CEUNP)
-- (en una base ya instalada sin este CUS se aplica 12_impugnaciones_apelaciones.sql)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Columnas, claves foráneas e índices de impugnacion_electoral: ya vienen en su
--    CREATE TABLE (sección 2)
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- 2. Parámetros (editables en la pantalla Parámetros)
-- ---------------------------------------------------------------------
-- (Se cargan en la sección 6, junto con los demás parámetros.)

-- ---------------------------------------------------------------------
-- 3. Triggers, procedimientos y vistas
-- ---------------------------------------------------------------------

DELIMITER $$

-- RN23 / RN36: la decisión de la mesa solo cambia por apelación y el fallo del CEUNP es
-- inapelable. Los datos de origen (personero, mesa, cargo y motivo) no se modifican.
CREATE TRIGGER trg_impugnacion_bu BEFORE UPDATE ON impugnacion_electoral
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
END$$

-- Una impugnación ya decidida por la mesa no se elimina (la limpieza usa TRUNCATE).
CREATE TRIGGER trg_impugnacion_bd BEFORE DELETE ON impugnacion_electoral
FOR EACH ROW
BEGIN
  IF OLD.decision_mesa <> 'PENDIENTE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS13: una impugnación resuelta no se elimina.';
  END IF;
END$$

-- Mensajes 6 a 9: registrarDecisionMesa(id_impugnacion, decision) -> resolverEnMesa(datos)
--   -> actualizarDecisionMesa(decision) -> notificarDecision().
-- RN23: los miembros de mesa en funciones (presidente, secretario y vocal: titulares, suplentes
-- o reemplazantes) deciden por mayoría simple. p_decision: ACEPTADA (la impugnación es fundada)
-- o RECHAZADA (infundada). p_opcion / p_id_lista: opción a la que se asigna la cédula (LISTA,
-- BLANCO o NULO). Requiere el sufragio cerrado (CUS11) y el proceso sin finalizar.
CREATE PROCEDURE sp_resolver_impugnacion_mesa(
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

  -- RN23: mayoría simple de los miembros en funciones
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

  -- Opción a la que va la cédula
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

  -- 8: actualizarDecisionMesa(decision)
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

  -- 9: notificarDecision()
  SELECT p_id_impugnacion AS id_impugnacion, v_decision AS decision_mesa, v_opcion AS opcion_mesa;
END$$

-- Mensaje 10: [decision rechazada] apelarDecision(id_impugnacion).
-- RF81: el personero de la lista que impugnó apela la decisión RECHAZADA de la mesa dentro del
-- plazo IMPUGNACION_PLAZO_APELACION_HORAS. La mesa eleva la apelación al CEUNP.
CREATE PROCEDURE sp_apelar_impugnacion(
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

  -- Apela un personero acreditado de la misma lista
  SELECT id_lista, estado_acreditacion INTO v_lista_ap, v_acred
    FROM personero WHERE id_personero = p_id_personero;
  IF v_lista_ap IS NULL OR v_lista_ap <> v_lista THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF81: apela un personero de la lista que presentó la impugnación.';
  END IF;
  IF v_acred <> 'ACREDITADO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF81: el personero que apela debe estar ACREDITADO (CUS05).';
  END IF;

  -- Plazo para apelar
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
END$$

-- Mensajes 11 a 14: registrarFalloCEUNP(id_impugnacion, decision) -> resolverApelacion(id_impugnacion,
--   decision) -> actualizarDecisionCEUNP(decision, 'RESUELTA') -> notificarFalloFinal().
-- RN36: resuelve el Pleno con quórum (CEUNP_QUORUM_PLENO, 5) por mayoría simple; en empate decide
-- el voto dirimente del Presidente. p_votos_favor / p_votos_contra: votos a favor y en contra de
-- la apelación. CONFIRMADA mantiene la decisión de la mesa; MODIFICADA la revoca y fija la
-- opción final de la cédula. El fallo es inapelable.
CREATE PROCEDURE sp_resolver_apelacion(
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

  -- RN36: quórum del Pleno y mayoría simple con voto dirimente
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

  -- Opción final de la cédula
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

  -- 13: actualizarDecisionCEUNP(decision, 'RESUELTA')
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

  -- 14: notificarFalloFinal()
  SELECT p_id_impugnacion AS id_impugnacion, v_decision AS decision_ceunp, v_opcion AS opcion_final;
END$$

DELIMITER ;

-- Situación de cada impugnación y opción vigente de la cédula para el cómputo (CUS14).
--   PENDIENTE_MESA  la mesa aún no decide: la cédula sigue como IMPUGNADO (CUS12 A4)
--   APELABLE        la mesa la RECHAZÓ y corre el plazo de apelación (o no hay plazo, parámetro 0):
--                   vale la decisión de la mesa
--   EN_APELACION    la resuelve el CEUNP: la cédula sigue como IMPUGNADO
--   FIRME           decisión de la mesa consentida o fallo del CEUNP (RN36)
CREATE VIEW v_impugnacion_efecto AS
SELECT i.id_impugnacion, i.id_proceso, i.id_mesa, i.id_cargo,
       CASE
         WHEN i.decision_ceunp <> 'PENDIENTE' THEN 'FIRME'
         WHEN i.estado = 'APELADA' THEN 'EN_APELACION'
         WHEN i.decision_mesa = 'PENDIENTE' THEN 'PENDIENTE_MESA'
         WHEN i.decision_mesa = 'ACEPTADA' THEN 'FIRME'
         WHEN COALESCE((SELECT CAST(g.valor AS DECIMAL(8,2)) FROM parametro_global g
                         WHERE g.clave = 'IMPUGNACION_PLAZO_APELACION_HORAS'), 24) <= 0
              OR NOW() <= i.fecha_decision_mesa + INTERVAL ROUND(COALESCE((SELECT CAST(g.valor AS DECIMAL(8,2))
                         FROM parametro_global g WHERE g.clave = 'IMPUGNACION_PLAZO_APELACION_HORAS'), 24) * 60) MINUTE
           THEN 'APELABLE'
         ELSE 'FIRME'
       END AS situacion,
       CASE
         WHEN i.decision_ceunp <> 'PENDIENTE' THEN i.opcion_final
         WHEN i.estado = 'APELADA' OR i.decision_mesa = 'PENDIENTE' THEN 'IMPUGNADO'
         ELSE i.opcion_mesa
       END AS opcion_vigente,
       CASE
         WHEN i.decision_ceunp <> 'PENDIENTE' THEN i.id_lista_final
         WHEN i.estado = 'APELADA' OR i.decision_mesa = 'PENDIENTE' THEN NULL
         ELSE i.id_lista_mesa
       END AS id_lista_vigente
  FROM impugnacion_electoral i;

-- Cédulas impugnadas por mesa, cargo y opción vigente (insumo del cómputo, CUS14)
CREATE VIEW v_impugnaciones_mesa_cargo AS
SELECT e.id_proceso, e.id_mesa, e.id_cargo, e.opcion_vigente, e.id_lista_vigente,
       COUNT(*) AS cedulas, SUM(e.situacion = 'FIRME') AS firmes
  FROM v_impugnacion_efecto e
 GROUP BY e.id_proceso, e.id_mesa, e.id_cargo, e.opcion_vigente, e.id_lista_vigente;

-- =====================================================================
-- 5d. CUS14 · Computar y proclamar resultados (verificación previa, sesión de cómputo,
--     consolidación, nulidad o segunda vuelta, proclamación y publicación)
-- (en una base ya instalada sin este CUS se aplica 13_computo_proclamacion.sql)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Tablas nuevas
-- ---------------------------------------------------------------------

-- ComputoGeneral del informe: una fila por proceso. Guarda la sesión de cómputo (RF91), el
-- cómputo con su acta general (RF92, huella SHA-256 y QR), la proclamación (RF98) y la
-- publicación en el portal (RF99).
CREATE TABLE computo_proceso (
  id_proceso              INT PRIMARY KEY,
  estado                  ENUM('SESION_INSTALADA','COMPUTADO','PROCLAMADO','PUBLICADO') NOT NULL DEFAULT 'SESION_INSTALADA',
  -- 4: sesión de cómputo general (RF91)
  lugar_sesion            VARCHAR(200) NOT NULL,
  miembros_ceunp          TINYINT NOT NULL,            -- miembros del Pleno presentes (RN36: quórum)
  observaciones_sesion    VARCHAR(1000) NULL,
  fecha_sesion            DATETIME NOT NULL,
  id_usuario_sesion       INT NULL,
  -- 5-8: cómputo y acta general de sufragios (RF92, RF93, RF96)
  fecha_computo           DATETIME NULL,
  mesas_total             INT NULL,
  mesas_computadas        INT NULL,
  mesas_no_instaladas     INT NULL,
  mesas_anuladas          INT NULL,
  actas_verificadas       INT NULL,
  electores_habiles       INT NULL,
  votaron                 INT NULL,
  participacion_pct       DECIMAL(5,2) NULL,
  resultado               ENUM('VALIDA','NULIDAD_TOTAL') NULL,
  contenido_json          LONGTEXT NULL,
  hash_integridad         CHAR(64) NULL,
  token_qr_hash           CHAR(64) NULL,
  id_usuario_computo      INT NULL,
  -- 9: proclamación por el Presidente del CEUNP (RF98)
  numero_resolucion       VARCHAR(40) NULL,
  miembros_pleno          TINYINT NULL,
  presidente_ceunp        VARCHAR(150) NULL,
  fundamento_proclamacion VARCHAR(1000) NULL,
  fecha_proclamacion      DATETIME NULL,
  contenido_proclamacion  LONGTEXT NULL,
  hash_proclamacion       CHAR(64) NULL,
  token_proclamacion_hash CHAR(64) NULL,
  id_usuario_proclamacion INT NULL,
  -- publicación en el portal (RF99)
  fecha_publicacion       DATETIME NULL,
  id_usuario_publicacion  INT NULL,
  UNIQUE KEY uq_computo_token (token_qr_hash),
  UNIQUE KEY uq_computo_token_proclamacion (token_proclamacion_hash),
  UNIQUE KEY uq_computo_resolucion (numero_resolucion),
  CONSTRAINT chk_computo_json CHECK (contenido_json IS NULL OR JSON_VALID(contenido_json)),
  CONSTRAINT chk_computo_proclamacion_json CHECK (contenido_proclamacion IS NULL OR JSON_VALID(contenido_proclamacion)),
  CONSTRAINT chk_computo_acta CHECK (estado = 'SESION_INSTALADA'
    OR (fecha_computo IS NOT NULL AND contenido_json IS NOT NULL AND hash_integridad IS NOT NULL AND resultado IS NOT NULL)),
  CONSTRAINT chk_computo_publicado CHECK (estado <> 'PUBLICADO' OR fecha_publicacion IS NOT NULL),
  CONSTRAINT fk_computo_proceso      FOREIGN KEY (id_proceso)              REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_computo_u_sesion     FOREIGN KEY (id_usuario_sesion)       REFERENCES usuario(id_usuario),
  CONSTRAINT fk_computo_u_computo    FOREIGN KEY (id_usuario_computo)      REFERENCES usuario(id_usuario),
  CONSTRAINT fk_computo_u_proclama   FOREIGN KEY (id_usuario_proclamacion) REFERENCES usuario(id_usuario),
  CONSTRAINT fk_computo_u_publica    FOREIGN KEY (id_usuario_publicacion)  REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- RF91: personeros acreditados presentes en la sesión de cómputo (asistencia facultativa)
CREATE TABLE computo_personero (
  id_proceso    INT NOT NULL,
  id_personero  INT NOT NULL,
  hora_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_usuario    INT NULL,
  PRIMARY KEY (id_proceso, id_personero),
  CONSTRAINT fk_cpers_computo   FOREIGN KEY (id_proceso)   REFERENCES computo_proceso(id_proceso),
  CONSTRAINT fk_cpers_personero FOREIGN KEY (id_personero) REFERENCES personero(id_personero),
  CONSTRAINT fk_cpers_usuario   FOREIGN KEY (id_usuario)   REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- RF90: acta marcada como dudosa y comprobación de su autenticidad (QR y huella SHA-256)
CREATE TABLE verificacion_acta (
  id_acta                 INT PRIMARY KEY,
  id_proceso              INT NOT NULL,
  id_mesa                 INT NOT NULL,
  motivo_duda             VARCHAR(500) NOT NULL,
  fecha_marca             DATETIME NOT NULL,
  id_usuario_marca        INT NULL,
  resultado               ENUM('AUTENTICA','NO_AUTENTICA') NULL,
  hash_recalculado        CHAR(64) NULL,
  huella_coincide         BOOLEAN NULL,
  qr_coincide             BOOLEAN NULL,                -- NULL: no se leyó el QR del ejemplar físico
  observacion_comprobacion VARCHAR(500) NULL,
  fecha_comprobacion      DATETIME NULL,
  id_usuario_comprobacion INT NULL,
  KEY ix_verificacion_mesa (id_mesa),
  CONSTRAINT chk_verificacion_resultado CHECK (resultado IS NULL OR (fecha_comprobacion IS NOT NULL AND hash_recalculado IS NOT NULL)),
  CONSTRAINT fk_verif_acta      FOREIGN KEY (id_acta)                 REFERENCES acta_electoral(id_acta),
  CONSTRAINT fk_verif_proceso   FOREIGN KEY (id_proceso)              REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_verif_mesa      FOREIGN KEY (id_mesa)                 REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_verif_u_marca   FOREIGN KEY (id_usuario_marca)        REFERENCES usuario(id_usuario),
  CONSTRAINT fk_verif_u_comprob FOREIGN KEY (id_usuario_comprobacion) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- A3 / RF95 y paso 7: calificación del CEUNP de la mesa cuya acta difiere del consolidado
-- (VALIDA: se computa con la cédula física) o nulidad de su votación (NULIDAD, RF94 y RF100).
CREATE TABLE calificacion_mesa (
  id_mesa           INT PRIMARY KEY,
  id_proceso        INT NOT NULL,
  calificacion      ENUM('VALIDA','NULIDAD') NOT NULL,
  motivo_revision   VARCHAR(300) NULL,               -- por qué se revisó (diferencias del acta)
  fundamento        VARCHAR(1000) NOT NULL,
  numero_resolucion VARCHAR(40) NULL,
  fecha             DATETIME NOT NULL,
  id_usuario        INT NULL,
  UNIQUE KEY uq_calificacion_resolucion (numero_resolucion),
  CONSTRAINT chk_calificacion_nulidad CHECK (calificacion <> 'NULIDAD' OR numero_resolucion IS NOT NULL),
  CONSTRAINT fk_calif_mesa    FOREIGN KEY (id_mesa)    REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_calif_proceso FOREIGN KEY (id_proceso) REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_calif_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 16-17 acreditarGanadora(idLista) / listaAcreditada(): una credencial por cargo proclamado (RF98)
CREATE TABLE proclamacion_cargo (
  id_cargo           INT PRIMARY KEY,
  id_proceso         INT NOT NULL,
  id_lista           INT NOT NULL,
  votos              INT NOT NULL,
  porcentaje_validos DECIMAL(5,2) NULL,
  codigo_credencial  CHAR(12) NOT NULL,
  fecha_proclamacion DATETIME NOT NULL,
  UNIQUE KEY uq_proclamacion_codigo (codigo_credencial),
  CONSTRAINT fk_procl_cargo   FOREIGN KEY (id_cargo, id_proceso) REFERENCES cargo_electoral(id_cargo, id_proceso),
  CONSTRAINT fk_procl_lista   FOREIGN KEY (id_lista)             REFERENCES lista_electoral(id_lista)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 2. Parámetros (editables en la pantalla Parámetros)
-- ---------------------------------------------------------------------
-- (Se cargan en la sección 6, junto con los demás parámetros.)

-- ---------------------------------------------------------------------
-- 3. Triggers
-- ---------------------------------------------------------------------

DELIMITER $$

-- RN26: el cómputo es irreversible. Cada etapa solo avanza (sesión > cómputo > proclamación >
-- publicación) y lo registrado en una etapa ya no cambia.
CREATE TRIGGER trg_computo_bu BEFORE UPDATE ON computo_proceso
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
END$$

-- La limpieza de datos usa TRUNCATE (02_limpiar_datos_electorales.sql).
CREATE TRIGGER trg_computo_bd BEFORE DELETE ON computo_proceso
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el registro del cómputo no se elimina.';
END$$

-- Los personeros se registran en la sesión antes del cómputo
CREATE TRIGGER trg_cpersonero_bi BEFORE INSERT ON computo_personero
FOR EACH ROW
BEGIN
  IF (SELECT estado FROM computo_proceso WHERE id_proceso = NEW.id_proceso) <> 'SESION_INSTALADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF91: el cómputo ya se realizó; no se registran más asistentes.';
  END IF;
END$$

-- RF90: la comprobación de un acta dudosa se registra una sola vez
CREATE TRIGGER trg_verificacion_bu BEFORE UPDATE ON verificacion_acta
FOR EACH ROW
BEGIN
  IF OLD.resultado IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: la autenticidad de esta acta ya fue comprobada.';
  END IF;
  IF NOT (NEW.motivo_duda <=> OLD.motivo_duda) OR NOT (NEW.id_acta <=> OLD.id_acta) OR NOT (NEW.fecha_marca <=> OLD.fecha_marca) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: la marca de acta dudosa no se modifica.';
  END IF;
END$$

CREATE TRIGGER trg_verificacion_bd BEFORE DELETE ON verificacion_acta
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: la verificación de un acta no se elimina.';
END$$

-- RF95 / RN36: la calificación del CEUNP es inapelable
CREATE TRIGGER trg_calificacion_bu BEFORE UPDATE ON calificacion_mesa
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: la calificación del acta por el CEUNP es inapelable.';
END$$

CREATE TRIGGER trg_calificacion_bd BEFORE DELETE ON calificacion_mesa
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: la calificación del acta por el CEUNP es inapelable.';
END$$

CREATE TRIGGER trg_proclamacion_bu BEFORE UPDATE ON proclamacion_cargo
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF98: la acreditación de la lista ganadora no se modifica.';
END$$

CREATE TRIGGER trg_proclamacion_bd BEFORE DELETE ON proclamacion_cargo
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF98: la acreditación de la lista ganadora no se elimina.';
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- 4. Vistas
-- ---------------------------------------------------------------------

-- 4-5 validarIntegridad(actas): cada acta con su huella recalculada y su verificación (RF90)
CREATE VIEW v_computo_actas AS
SELECT m.id_proceso, a.id_mesa, m.numero_mesa, a.id_acta, a.tipo, a.estado, a.fecha_emision,
       a.hash_integridad,
       IF(SHA2(a.contenido_json, 256) = a.hash_integridad, 1, 0) AS integra,
       IF(v.id_acta IS NULL, 0, 1) AS dudosa,
       v.motivo_duda, v.fecha_marca, v.resultado AS comprobacion, v.huella_coincide, v.qr_coincide,
       v.observacion_comprobacion, v.fecha_comprobacion
  FROM acta_electoral a
  JOIN mesa_electoral m ON m.id_mesa = a.id_mesa
  LEFT JOIN verificacion_acta v ON v.id_acta = a.id_acta;

-- 2-3 verificarActasEntregadas(idProceso) / actasEntregadas(totalMesas) (RF89, RN32).
-- situacion: por qué una mesa entra o no al cómputo. Solo HABILITADA se computa; NO_INSTALADA y
-- ANULADA no tienen votos que computar. Las demás impiden el cómputo hasta resolverse.
CREATE VIEW v_computo_mesas AS
SELECT x.*,
       CASE
         WHEN x.estado = 'ANULADA' THEN 'ANULADA'
         WHEN x.estado = 'NO_INSTALADA' THEN 'NO_INSTALADA'
         WHEN x.estado = 'PENDIENTE' THEN 'SIN_INSTALAR'
         WHEN x.estado = 'INSTALADA' THEN 'EN_SUFRAGIO'
         WHEN x.estado_escrutinio IS NULL OR x.estado_escrutinio IN ('CEDULAS_CONTADAS','CONTEO_REGISTRADO') THEN 'ESCRUTINIO_PENDIENTE'
         WHEN x.estado_escrutinio = 'ACTA_EMITIDA' THEN 'ACTAS_SIN_ENTREGAR'
         WHEN x.actas_vigentes < 3 THEN 'ACTAS_INCOMPLETAS'
         WHEN x.actas_alteradas > 0 OR x.actas_no_autenticas > 0 THEN 'ACTA_NO_AUTENTICA'
         WHEN x.actas_dudosas > 0 THEN 'ACTA_DUDOSA'
         WHEN x.impugnaciones_pendientes > 0 THEN 'IMPUGNACIONES_PENDIENTES'
         WHEN x.requiere_calificacion = 1 AND x.calificacion IS NULL THEN 'POR_CALIFICAR'
         ELSE 'HABILITADA'
       END AS situacion
  FROM (SELECT m.id_proceso, m.id_mesa, m.numero_mesa, m.ubicacion, m.estado, m.total_electores,
               e.estado AS estado_escrutinio, e.total_votantes, e.cedulas_escrutadas, e.observada,
               e.prevalece_fisica, e.conteo_cuadra, e.total_cuadra, e.fecha_entrega, e.recibido_por, e.codigo_cargo,
               (SELECT COUNT(DISTINCT a.tipo) FROM acta_electoral a
                 WHERE a.id_mesa = m.id_mesa AND a.estado = 'VIGENTE') AS actas_vigentes,
               (SELECT COUNT(*) FROM acta_electoral a
                 WHERE a.id_mesa = m.id_mesa AND a.estado = 'VIGENTE'
                   AND SHA2(a.contenido_json, 256) <> a.hash_integridad) AS actas_alteradas,
               (SELECT COUNT(*) FROM verificacion_acta v WHERE v.id_mesa = m.id_mesa AND v.resultado IS NULL) AS actas_dudosas,
               (SELECT COUNT(*) FROM verificacion_acta v WHERE v.id_mesa = m.id_mesa AND v.resultado = 'NO_AUTENTICA') AS actas_no_autenticas,
               (SELECT COUNT(*) FROM impugnacion_electoral i WHERE i.id_mesa = m.id_mesa) AS impugnaciones,
               (SELECT COUNT(*) FROM v_impugnacion_efecto i
                 WHERE i.id_mesa = m.id_mesa
                   AND (i.situacion IN ('PENDIENTE_MESA','EN_APELACION')
                        OR (i.situacion = 'APELABLE'
                            AND COALESCE((SELECT CAST(g.valor AS DECIMAL(8,2)) FROM parametro_global g
                                           WHERE g.clave = 'IMPUGNACION_PLAZO_APELACION_HORAS'), 24) > 0))) AS impugnaciones_pendientes,
               IF(e.observada = 1 OR e.conteo_cuadra = 0 OR e.total_cuadra = 0, 1, 0) AS requiere_calificacion,
               c.calificacion, c.motivo_revision, c.fundamento AS fundamento_calificacion,
               c.numero_resolucion AS resolucion_calificacion, c.fecha AS fecha_calificacion
          FROM mesa_electoral m
          LEFT JOIN escrutinio_mesa e   ON e.id_mesa = m.id_mesa
          LEFT JOIN calificacion_mesa c ON c.id_mesa = m.id_mesa) x;

-- 6-7 consolidarVotos(idCargo) por mesa. Votos de la cédula física (acta de escrutinio, RF84)
-- más las cédulas impugnadas que la mesa o el CEUNP asignaron a la opción (CUS13). La fila
-- IMPUGNADO trae las cédulas cuya impugnación aún no tiene opción.
CREATE VIEW v_computo_conteo_mesa AS
SELECT m.id_proceso, k.id_mesa, m.numero_mesa, k.id_cargo, k.opcion, k.id_lista,
       k.votos_manual AS votos_acta,
       (SELECT COUNT(*) FROM v_impugnacion_efecto i
         WHERE i.id_mesa = k.id_mesa AND i.id_cargo = k.id_cargo AND i.opcion_vigente = k.opcion
           AND (k.opcion <> 'LISTA' OR i.id_lista_vigente = k.id_lista)) AS impugnados_asignados,
       k.votos_manual
       + (SELECT COUNT(*) FROM v_impugnacion_efecto i
           WHERE i.id_mesa = k.id_mesa AND i.id_cargo = k.id_cargo AND i.opcion_vigente = k.opcion
             AND (k.opcion <> 'LISTA' OR i.id_lista_vigente = k.id_lista)) AS votos,
       k.votos_digital
  FROM escrutinio_conteo k
  JOIN mesa_electoral m  ON m.id_mesa = k.id_mesa
  JOIN escrutinio_mesa e ON e.id_mesa = k.id_mesa AND e.estado IN ('ACTA_EMITIDA','ENTREGADA')
 WHERE k.opcion <> 'IMPUGNADO'
UNION ALL
SELECT m.id_proceso, k.id_mesa, m.numero_mesa, k.id_cargo, k.opcion, NULL,
       k.votos_manual, 0,
       (SELECT COUNT(*) FROM v_impugnacion_efecto i
         WHERE i.id_mesa = k.id_mesa AND i.id_cargo = k.id_cargo AND i.opcion_vigente = 'IMPUGNADO'),
       0
  FROM escrutinio_conteo k
  JOIN mesa_electoral m  ON m.id_mesa = k.id_mesa
  JOIN escrutinio_mesa e ON e.id_mesa = k.id_mesa AND e.estado IN ('ACTA_EMITIDA','ENTREGADA')
 WHERE k.opcion = 'IMPUGNADO';

-- 7 totalesPorLista(votos): consolidado por cargo y opción de las actas de las mesas no anuladas
CREATE VIEW v_computo_resultados AS
SELECT c.id_proceso, c.id_cargo, c.nombre AS cargo, x.opcion, x.id_lista,
       COALESCE(l.nombre, CASE x.opcion WHEN 'BLANCO' THEN 'Votos en blanco' WHEN 'NULO' THEN 'Votos nulos'
                                        ELSE 'Impugnados sin resolver' END) AS lista,
       l.orden_cedula,
       COUNT(DISTINCT x.id_mesa) AS mesas,
       SUM(x.votos_acta) AS votos_actas,
       SUM(x.impugnados_asignados) AS impugnados_asignados,
       SUM(x.votos) AS votos,
       SUM(x.votos_digital) AS votos_digital
  FROM v_computo_conteo_mesa x
  JOIN mesa_electoral m  ON m.id_mesa = x.id_mesa AND m.estado <> 'ANULADA'
  JOIN cargo_electoral c ON c.id_cargo = x.id_cargo
  LEFT JOIN lista_electoral l ON l.id_lista = x.id_lista
 GROUP BY c.id_proceso, c.id_cargo, c.nombre, x.opcion, x.id_lista, l.nombre, l.orden_cedula;

-- RF99: resultados publicados en el portal (solo después de la publicación)
CREATE VIEW v_portal_resultados AS
SELECT p.id_proceso, p.nombre AS proceso, p.tipo, p.estado AS estado_proceso,
       cp.resultado, cp.participacion_pct, cp.electores_habiles, cp.votaron,
       cp.numero_resolucion, cp.fecha_computo, cp.fecha_proclamacion, cp.fecha_publicacion
  FROM computo_proceso cp
  JOIN proceso_electoral p ON p.id_proceso = cp.id_proceso
 WHERE cp.estado = 'PUBLICADO';

-- ---------------------------------------------------------------------
-- 5. Procedimientos
-- ---------------------------------------------------------------------

DELIMITER $$

-- Paso 4 de la tabla 39 (RF91): el CEUNP instala la sesión de cómputo general con quórum
-- (RN36, CEUNP_QUORUM_PLENO) y registra a los personeros acreditados presentes.
-- p_personeros: arreglo JSON de id_personero, p. ej. [3, 7]. Puede ir vacío.
CREATE PROCEDURE sp_instalar_sesion_computo(
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
END$$

-- RF91: un personero acreditado llega a la sesión ya instalada (antes del cómputo)
CREATE PROCEDURE sp_registrar_personero_computo(
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
END$$

-- Paso 3 de la tabla 39 (RF90): el CEUNP marca un acta como dudosa antes del cómputo.
CREATE PROCEDURE sp_marcar_acta_dudosa(
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
END$$

-- Paso 3 de la tabla 39 (RF90): comprobación de la autenticidad del acta dudosa. Recalcula la
-- huella SHA-256 del contenido y, si se leyó el QR del ejemplar físico (token o URL de
-- verificación), comprueba que corresponde al acta. AUTENTICA si todo coincide.
CREATE PROCEDURE sp_comprobar_acta(
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
  SELECT v.id_proceso, v.resultado, SHA2(a.contenido_json, 256), a.hash_integridad, a.token_qr_hash
    INTO v_proceso, v_resultado, v_hash, v_guardado, v_token_h
    FROM verificacion_acta v JOIN acta_electoral a ON a.id_acta = v.id_acta
   WHERE v.id_acta = p_id_acta
     FOR UPDATE;
  IF v_resultado IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: la autenticidad de esta acta ya fue comprobada.';
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
END$$

-- Paso 7 y A3 de la tabla 39 (RF94, RF95, RF100): el CEUNP califica la mesa cuya acta difiere del
-- consolidado (VALIDA: se computa con la cédula física, RF84) o declara la nulidad de su
-- votación (NULIDAD: la mesa y sus actas quedan ANULADAS y salen del cómputo). Un acta no
-- auténtica solo admite NULIDAD. La nulidad lleva el número de resolución del CEUNP.
CREATE PROCEDURE sp_calificar_mesa(
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
    -- RF100: la votación de la mesa se excluye del cómputo
    UPDATE acta_electoral SET estado = 'ANULADA' WHERE id_mesa = p_id_mesa;
    UPDATE mesa_electoral SET estado = 'ANULADA' WHERE id_mesa = p_id_mesa;
  END IF;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, IF(v_calif = 'NULIDAD', 'DECLARAR_NULIDAD_MESA', 'CALIFICAR_ACTA'),
       JSON_OBJECT('id_mesa', p_id_mesa, 'calificacion', v_calif, 'resolucion', v_res));
  COMMIT;

  SELECT p_id_mesa AS id_mesa, v_calif AS calificacion;
END$$

-- Mensajes 1 a 15 del diagrama: ejecutarComputo(idProceso). Cómputo oficial e irreversible (RN26).
--   2-3   todas las mesas instaladas entregaron sus tres actas, o fueron declaradas no instaladas
--         o anuladas; no quedan actas dudosas, impugnaciones ni calificaciones pendientes (RN32)
--   4-5   la huella SHA-256 de cada acta coincide (RF90)
--   6-7   consolida los votos de las actas habilitadas (RF92)
--   8-11  participación por cargo sobre el padrón y quórum (> quorum_minimo, RN31)
--   12-15 registra el cómputo y determina el resultado de cada cargo:
--           SIN_QUORUM .... participación <= quórum
--           DESIERTO ...... hubo quórum pero ningún voto válido
--           ELEGIDO ....... una lista SUPERA el % mínimo de votos válidos (2.ª vuelta: 50 % + 1, RF97)
--           SEGUNDA_VUELTA  ninguna lista lo supera o hay empate (RF96, A2)
--           EMPATE ........ empate en segunda vuelta (lo resuelve el CEUNP)
-- El proceso queda FINALIZADO, o ANULADO si ningún cargo alcanzó el quórum (A1, RN31 y RN34).
-- Emite el acta general de sufragios (contenido JSON, huella SHA-256 y QR). Devuelve el token.
CREATE PROCEDURE sp_ejecutar_computo(
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
  DECLARE v_top       INT DEFAULT 0;
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

  -- 2-3: verificarActasEntregadas(idProceso) -> actasEntregadas(totalMesas)
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

  -- 4-5: validarIntegridad(actas) -> actasValidas(hashCorrecto)
  SELECT COUNT(*), COALESCE(SUM(integra = 0), 0), COALESCE(SUM(dudosa), 0) INTO v_actas, v_n, v_dudosas
    FROM v_computo_actas WHERE id_proceso = p_id_proceso AND estado = 'VIGENTE';
  IF v_n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: hay actas cuya huella SHA-256 no coincide con su contenido.';
  END IF;

  -- 6-7: consolidarVotos(idCargo) -> totalesPorLista(votos)
  INSERT INTO tmp_computo_cus14 (id_cargo, opcion, id_lista, votos, clave)
  SELECT id_cargo, opcion, id_lista, votos, COALESCE(id_lista, 0)
    FROM v_computo_resultados WHERE id_proceso = p_id_proceso;
  IF EXISTS (SELECT 1 FROM tmp_computo_cus14 WHERE opcion = 'IMPUGNADO' AND votos > 0) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS13: hay cédulas impugnadas sin opción asignada.';
  END IF;

  -- 12-13: [quorum > 60%] registrarComputo(totales) -> computoRegistrado(resultados)
  INSERT INTO resultado_electoral (id_proceso, id_cargo, id_lista, tipo_voto, total_votos, porcentaje_validos, posicion)
  SELECT x.id_proceso, x.id_cargo, x.id_lista, 'VALIDO', x.n,
         CASE WHEN SUM(x.n) OVER (PARTITION BY x.id_cargo) = 0 THEN 0
              ELSE ROUND(x.n * 100 / SUM(x.n) OVER (PARTITION BY x.id_cargo), 2) END,
         RANK() OVER (PARTITION BY x.id_cargo ORDER BY x.n DESC)
    FROM (SELECT c.id_proceso, c.id_cargo, l.id_lista, COALESCE(t.votos, 0) AS n
            FROM cargo_electoral c
            JOIN lista_electoral l ON l.id_cargo = c.id_cargo AND l.estado = 'ADMITIDA'
            LEFT JOIN tmp_computo_cus14 t ON t.id_cargo = c.id_cargo AND t.opcion = 'LISTA' AND t.clave = l.id_lista
           WHERE c.id_proceso = p_id_proceso) x;

  INSERT INTO resultado_electoral (id_proceso, id_cargo, id_lista, tipo_voto, total_votos)
  SELECT c.id_proceso, c.id_cargo, NULL, o.opcion, COALESCE(t.votos, 0)
    FROM cargo_electoral c
    CROSS JOIN (SELECT 'BLANCO' AS opcion UNION ALL SELECT 'NULO') o
    LEFT JOIN tmp_computo_cus14 t ON t.id_cargo = c.id_cargo AND t.opcion = o.opcion AND t.clave = 0
   WHERE c.id_proceso = p_id_proceso;

  -- 8-11 y 14-15: calcularParticipacion -> validarQuorum -> determinarGanador -> ganadorOSegundaVuelta
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
      SET v_result = IF(v_empate = 1 AND v_top * 2 > v_validos, 'ELEGIDO', 'EMPATE');
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

  SELECT COUNT(*) INTO v_con_q FROM cargo_electoral
   WHERE id_proceso = p_id_proceso AND estado_resultado <> 'SIN_QUORUM';
  SELECT electores_habiles, votaron, participacion_pct INTO v_p_hab, v_p_vot, v_p_pct
    FROM v_quorum_proceso WHERE id_proceso = p_id_proceso;

  -- 8: [participacion <= 60%] anularProceso(motivo) (A1)
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

  -- 12: emitirActaGeneral(totales): acta general de sufragios docentes (RF92)
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
                                                       ',"porcentaje":', COALESCE(r.porcentaje_validos, 0),
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
                                  ORDER BY LENGTH(m.numero_mesa), m.numero_mesa SEPARATOR ','), ']')
    INTO v_det_mesas
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

  SET v_token = SHA2(CONCAT(UUID(), RAND(), p_id_proceso, 'COMPUTO', NOW(6)), 256);
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

  -- 13: mostrarResultados(resultados)
  SELECT p_id_proceso AS id_proceso, v_resultado AS resultado, v_token AS token_qr, v_computadas AS mesas_computadas,
         IF(v_resultado = 'VALIDA', 'FINALIZADO', 'ANULADO') AS estado_proceso;
END$$

-- Mensajes 16 y 17 del diagrama y paso 9 de la tabla 39 (RF98): el Presidente del CEUNP proclama
-- los resultados en sesión del Pleno (RN36: quórum) y se acredita la lista ganadora de cada cargo
-- ELEGIDO con un código de credencial. Emite la resolución de proclamación con huella y QR.
CREATE PROCEDURE sp_proclamar_resultados(
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
  -- 16: acreditarGanadora(idLista) -> 17 listaAcreditada()
  INSERT INTO proclamacion_cargo (id_cargo, id_proceso, id_lista, votos, porcentaje_validos, codigo_credencial, fecha_proclamacion)
  SELECT c.id_cargo, c.id_proceso, c.id_lista_ganadora, r.total_votos, r.porcentaje_validos,
         UPPER(LEFT(SHA2(CONCAT(c.id_cargo, '|', c.id_lista_ganadora, '|', v_res, '|', UUID()), 256), 12)), v_ahora
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
  SET v_token = SHA2(CONCAT(UUID(), RAND(), p_id_proceso, 'PROCLAMACION', NOW(6)), 256);

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
END$$

-- Mensajes 18 y 19 del diagrama (RF99): publica en el portal los resultados por mesa y generales.
-- Se publica tras la proclamación o, si la elección se anuló por falta de quórum (A1), el acta
-- general con la nulidad para su comunicación (RN34).
CREATE PROCEDURE sp_publicar_resultados(
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
  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'PUBLICAR_RESULTADOS',
       JSON_OBJECT('estado_proceso', v_estado));
  COMMIT;
END$$

-- A2 de la tabla 39 (RN33, RF96): convoca la segunda vuelta entre las dos listas más votadas
-- dentro del plazo (SEGUNDA_VUELTA_PLAZO_DIAS, 15) contado desde el cómputo. Valida y delega
-- en sp_crear_segunda_vuelta, que clona cargos, listas y padrón (no abre otra transacción aquí).
CREATE PROCEDURE sp_convocar_segunda_vuelta(
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
END$$

-- Destino del QR del acta general y de la resolución de proclamación: recalcula el SHA-256.
CREATE PROCEDURE sp_verificar_acta_computo(IN p_token CHAR(64))
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
END$$

DELIMITER ;

-- =====================================================================
-- 5e. CUS15 · Gestionar nulidades y segunda vuelta (recursos de nulidad parcial y total,
--     resolución del Pleno, comunicaciones, empates por sorteo y segunda vuelta)
-- (en una base ya instalada sin este CUS se aplica 14_nulidades_segunda_vuelta.sql)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Tablas nuevas
-- ---------------------------------------------------------------------

-- Recurso de nulidad y su resolución por el CEUNP (RF94, RF100, RF101). Una fila por recurso.
-- PARCIAL: votación de una mesa (Art. 64). TOTAL: toda la elección (Art. 65).
CREATE TABLE nulidad_electoral (
  id_nulidad            INT AUTO_INCREMENT PRIMARY KEY,
  id_proceso            INT NOT NULL,
  alcance               ENUM('PARCIAL','TOTAL') NOT NULL,
  id_mesa               INT NULL,
  causal                ENUM('INSTALACION_IRREGULAR','FRAUDE_MESA','ADMISION_INDEBIDA','ACTA_NO_AUTENTICA','OTRA_CAUSAL',
                             'FRAUDE','COHECHO','SOBORNO','INTIMIDACION','VIOLENCIA','PARTICIPACION_INSUFICIENTE') NOT NULL,
  origen                ENUM('DE_OFICIO','PERSONERO') NOT NULL,
  id_personero          INT NULL,
  sustento              VARCHAR(1000) NOT NULL,
  pruebas               VARCHAR(500) NULL,
  etapa                 ENUM('ANTES_COMPUTO','DESPUES_COMPUTO') NOT NULL,
  fecha_presentacion    DATETIME NOT NULL,
  id_usuario_registro   INT NULL,
  -- resolución del Pleno (RN36)
  estado                ENUM('PRESENTADA','FUNDADA','INFUNDADA','IMPROCEDENTE') NOT NULL DEFAULT 'PRESENTADA',
  numero_resolucion     VARCHAR(40) NULL,
  fundamento_resolucion VARCHAR(1000) NULL,
  miembros_pleno        TINYINT NULL,
  votos_favor           TINYINT NULL,
  votos_contra          TINYINT NULL,
  voto_dirimente        BOOLEAN NULL,                -- empate resuelto por el voto del Presidente
  fecha_resolucion      DATETIME NULL,
  id_usuario_resolucion INT NULL,
  contenido_json        LONGTEXT NULL,
  hash_integridad       CHAR(64) NULL,
  token_qr_hash         CHAR(64) NULL,
  UNIQUE KEY uq_nulidad_resolucion (numero_resolucion),
  UNIQUE KEY uq_nulidad_token (token_qr_hash),
  KEY ix_nulidad_proceso (id_proceso, estado),
  KEY ix_nulidad_mesa (id_mesa),
  CONSTRAINT chk_nulidad_alcance CHECK (
       (alcance = 'PARCIAL' AND id_mesa IS NOT NULL
        AND causal IN ('INSTALACION_IRREGULAR','FRAUDE_MESA','ADMISION_INDEBIDA','ACTA_NO_AUTENTICA','OTRA_CAUSAL'))
    OR (alcance = 'TOTAL' AND id_mesa IS NULL
        AND causal IN ('FRAUDE','COHECHO','SOBORNO','INTIMIDACION','VIOLENCIA','PARTICIPACION_INSUFICIENTE'))),
  CONSTRAINT chk_nulidad_origen CHECK ((origen = 'PERSONERO') = (id_personero IS NOT NULL)),
  CONSTRAINT chk_nulidad_resuelta CHECK (estado = 'PRESENTADA'
    OR (fecha_resolucion IS NOT NULL AND fundamento_resolucion IS NOT NULL)),
  CONSTRAINT chk_nulidad_documento CHECK (contenido_json IS NULL OR JSON_VALID(contenido_json)),
  CONSTRAINT fk_nulidad_proceso   FOREIGN KEY (id_proceso)            REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_nulidad_mesa      FOREIGN KEY (id_mesa)               REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_nulidad_personero FOREIGN KEY (id_personero)          REFERENCES personero(id_personero),
  CONSTRAINT fk_nulidad_u_reg     FOREIGN KEY (id_usuario_registro)   REFERENCES usuario(id_usuario),
  CONSTRAINT fk_nulidad_u_res     FOREIGN KEY (id_usuario_resolucion) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8 registrarComunicacion('SUNEDU, AU, CU') y publicación (RF102, Art. 66): una por destinatario
CREATE TABLE nulidad_comunicacion (
  id_nulidad     INT NOT NULL,
  destinatario   ENUM('SUNEDU','ASAMBLEA_UNIVERSITARIA','CONSEJO_UNIVERSITARIO','PORTAL','EL_PERUANO') NOT NULL,
  documento      VARCHAR(80) NOT NULL,                -- N.º de oficio, edición de El Peruano o «Portal electoral»
  fecha_envio    DATETIME NOT NULL,
  observacion    VARCHAR(500) NULL,
  fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_usuario     INT NULL,
  PRIMARY KEY (id_nulidad, destinatario),
  CONSTRAINT fk_ncom_nulidad FOREIGN KEY (id_nulidad) REFERENCES nulidad_electoral(id_nulidad),
  CONSTRAINT fk_ncom_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Empates que decide el Pleno por sorteo con semilla pública (RN36). La elección se calcula con
-- SHA-256, así cualquiera puede repetir el sorteo:
--   PASE_A_SEGUNDA_VUELTA: en la primera vuelta varias listas empatan por un cupo de la segunda
--                          (RN33: pasan las dos más votadas).
--   EMPATE_SEGUNDA_VUELTA: en la segunda vuelta las dos listas empatan (EMPATE del CUS14, RF97).
CREATE TABLE dirimencia_empate (
  id_cargo          INT PRIMARY KEY,
  id_proceso        INT NOT NULL,
  motivo            ENUM('PASE_A_SEGUNDA_VUELTA','EMPATE_SEGUNDA_VUELTA') NOT NULL,
  semilla           VARCHAR(100) NOT NULL,
  cupos             TINYINT NOT NULL,
  listas_empatadas  LONGTEXT NOT NULL,
  listas_elegidas   LONGTEXT NOT NULL,
  numero_resolucion VARCHAR(40) NOT NULL,
  miembros_pleno    TINYINT NOT NULL,
  fundamento        VARCHAR(1000) NULL,
  fecha             DATETIME NOT NULL,
  id_usuario        INT NULL,
  hash_integridad   CHAR(64) NOT NULL,
  UNIQUE KEY uq_dirimencia_resolucion (numero_resolucion),
  CONSTRAINT chk_dirimencia_json CHECK (JSON_VALID(listas_empatadas) AND JSON_VALID(listas_elegidas)),
  CONSTRAINT fk_dirim_cargo   FOREIGN KEY (id_cargo, id_proceso) REFERENCES cargo_electoral(id_cargo, id_proceso),
  CONSTRAINT fk_dirim_usuario FOREIGN KEY (id_usuario)           REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 2. Triggers
-- ---------------------------------------------------------------------

DELIMITER $$

-- PROCESO: FINALIZADO y ANULADO siguen siendo terminales (RN26 / RN34). Única excepción: la
-- nulidad total declarada por el CEUNP sobre una elección ya computada y aún no proclamada
-- (RF101). sp_resolver_nulidad la habilita con @cus15_nulidad_total = id del proceso.
CREATE TRIGGER trg_proceso_bu BEFORE UPDATE ON proceso_electoral
FOR EACH ROW
BEGIN
  IF OLD.estado IN ('FINALIZADO','ANULADO') AND NEW.estado <> OLD.estado
     AND NOT (OLD.estado = 'FINALIZADO' AND NEW.estado = 'ANULADO' AND @cus15_nulidad_total <=> OLD.id_proceso) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Un proceso FINALIZADO o ANULADO no puede cambiar de estado.';
  END IF;
END$$

-- 12 insertar('SEGUNDA_VUELTA', id_proceso_padre): no se crea la segunda vuelta con una
-- nulidad total pendiente sobre la primera (RF94).
CREATE TRIGGER trg_proceso_bi_cus15 BEFORE INSERT ON proceso_electoral
FOR EACH ROW
BEGIN
  IF NEW.tipo = 'SEGUNDA_VUELTA' AND EXISTS (SELECT 1 FROM nulidad_electoral
                                               WHERE id_proceso = NEW.id_proceso_padre AND alcance = 'TOTAL'
                                                 AND estado = 'PRESENTADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF94: hay un recurso de nulidad total pendiente; resuélvalo antes de convocar la segunda vuelta.';
  END IF;
END$$

-- RN36: el fallo del Pleno es inapelable; lo presentado no se modifica
CREATE TRIGGER trg_nulidad_bu BEFORE UPDATE ON nulidad_electoral
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
END$$

-- La limpieza de datos usa TRUNCATE (02_limpiar_datos_electorales.sql).
CREATE TRIGGER trg_nulidad_bd BEFORE DELETE ON nulidad_electoral
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF94: un recurso de nulidad no se elimina.';
END$$

CREATE TRIGGER trg_ncom_bu BEFORE UPDATE ON nulidad_comunicacion
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF102: la comunicación registrada no se modifica.';
END$$

CREATE TRIGGER trg_ncom_bd BEFORE DELETE ON nulidad_comunicacion
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF102: la comunicación registrada no se elimina.';
END$$

CREATE TRIGGER trg_dirimencia_bu BEFORE UPDATE ON dirimencia_empate
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: la dirimencia del empate es inapelable.';
END$$

CREATE TRIGGER trg_dirimencia_bd BEFORE DELETE ON dirimencia_empate
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: la dirimencia del empate no se elimina.';
END$$

-- RF94 (paso 7 de la tabla 39): no se computa con recursos de nulidad pendientes y no se
-- proclama con una nulidad total pendiente. El número de resolución no se repite (RN36).
CREATE TRIGGER trg_computo_bu_cus15 BEFORE UPDATE ON computo_proceso
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
END$$

CREATE TRIGGER trg_calificacion_bi_cus15 BEFORE INSERT ON calificacion_mesa
FOR EACH ROW
BEGIN
  IF NEW.numero_resolucion IS NOT NULL
     AND (EXISTS (SELECT 1 FROM nulidad_electoral WHERE numero_resolucion = NEW.numero_resolucion)
          OR EXISTS (SELECT 1 FROM dirimencia_empate WHERE numero_resolucion = NEW.numero_resolucion)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;
END$$

CREATE TRIGGER trg_impugnacion_bu_cus15 BEFORE UPDATE ON impugnacion_electoral
FOR EACH ROW
BEGIN
  IF NEW.numero_resolucion IS NOT NULL AND NOT (NEW.numero_resolucion <=> OLD.numero_resolucion)
     AND (EXISTS (SELECT 1 FROM nulidad_electoral WHERE numero_resolucion = NEW.numero_resolucion)
          OR EXISTS (SELECT 1 FROM dirimencia_empate WHERE numero_resolucion = NEW.numero_resolucion)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- 3. Vistas
-- ---------------------------------------------------------------------

-- 4 mostrarMesaExcluida() / 9 mostrarResolucionNulidad(): recursos con su mesa, personero,
-- resolución y comunicaciones registradas (RF102).
CREATE VIEW v_nulidades AS
SELECT n.id_nulidad, n.id_proceso, p.nombre AS proceso, p.estado AS estado_proceso, p.tipo AS tipo_proceso,
       n.alcance, n.id_mesa, m.numero_mesa, m.ubicacion, m.estado AS estado_mesa, n.causal, n.origen,
       n.id_personero, CONCAT(d.apellidos, ', ', d.nombres) AS personero, l.nombre AS lista_personero,
       CONCAT(pe.tipo, '') AS tipo_personero,
       n.sustento, n.pruebas, n.etapa, n.fecha_presentacion, ur.username AS registrado_por,
       n.estado, n.numero_resolucion, n.fundamento_resolucion, n.miembros_pleno, n.votos_favor, n.votos_contra,
       n.voto_dirimente, n.fecha_resolucion, us.username AS resuelto_por, n.hash_integridad,
       IF(n.contenido_json IS NULL, NULL, IF(SHA2(n.contenido_json, 256) = n.hash_integridad, 1, 0)) AS resolucion_integra,
       (SELECT COUNT(*) FROM nulidad_comunicacion c WHERE c.id_nulidad = n.id_nulidad) AS comunicaciones,
       (SELECT COUNT(*) FROM nulidad_comunicacion c WHERE c.id_nulidad = n.id_nulidad
          AND c.destinatario IN ('SUNEDU','ASAMBLEA_UNIVERSITARIA','CONSEJO_UNIVERSITARIO')) AS comunicaciones_oficio,
       (SELECT MAX(c.fecha_envio) FROM nulidad_comunicacion c WHERE c.id_nulidad = n.id_nulidad
          AND c.destinatario = 'PORTAL') AS fecha_portal
  FROM nulidad_electoral n
  JOIN proceso_electoral p    ON p.id_proceso = n.id_proceso
  LEFT JOIN mesa_electoral m  ON m.id_mesa = n.id_mesa
  LEFT JOIN personero pe      ON pe.id_personero = n.id_personero
  LEFT JOIN docente d         ON d.id_docente = pe.id_docente
  LEFT JOIN lista_electoral l ON l.id_lista = pe.id_lista
  LEFT JOIN usuario ur        ON ur.id_usuario = n.id_usuario_registro
  LEFT JOIN usuario us        ON us.id_usuario = n.id_usuario_resolucion;

-- RF102 / RF99: resoluciones de nulidad publicadas en el portal electoral
CREATE VIEW v_portal_nulidades AS
SELECT n.id_nulidad, n.id_proceso, p.nombre AS proceso, p.tipo, p.estado AS estado_proceso, n.alcance,
       m.numero_mesa, n.causal, n.numero_resolucion, n.fundamento_resolucion, n.fecha_resolucion,
       c.fecha_envio AS fecha_publicacion, n.hash_integridad,
       (SELECT GROUP_CONCAT(CONCAT(x.destinatario, '') ORDER BY x.fecha_envio SEPARATOR ',')
          FROM nulidad_comunicacion x WHERE x.id_nulidad = n.id_nulidad) AS comunicado_a
  FROM nulidad_electoral n
  JOIN proceso_electoral p    ON p.id_proceso = n.id_proceso
  JOIN nulidad_comunicacion c ON c.id_nulidad = n.id_nulidad AND c.destinatario = 'PORTAL'
  LEFT JOIN mesa_electoral m  ON m.id_mesa = n.id_mesa
 WHERE n.estado = 'FUNDADA';

-- 15 mostrarSegundaVuelta(): segunda vuelta de cada proceso con su plazo (RN33) y su avance
CREATE VIEW v_segunda_vuelta_procesos AS
SELECT h.id_proceso, h.nombre, h.estado, h.fecha_inicio, h.fecha_fin, h.fecha_creacion, h.motivo_anulacion,
       h.id_proceso_padre, p.nombre AS proceso_padre, cp.fecha_computo AS fecha_computo_padre,
       (SELECT COUNT(*) FROM cargo_electoral c WHERE c.id_proceso = h.id_proceso) AS cargos,
       (SELECT COUNT(*) FROM lista_electoral l JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
         WHERE c.id_proceso = h.id_proceso) AS listas,
       (SELECT COUNT(*) FROM padron_electoral e WHERE e.id_proceso = h.id_proceso) AS padron,
       (SELECT COUNT(*) FROM mesa_electoral m WHERE m.id_proceso = h.id_proceso) AS mesas,
       hc.estado AS estado_computo
  FROM proceso_electoral h
  JOIN proceso_electoral p     ON p.id_proceso = h.id_proceso_padre
  LEFT JOIN computo_proceso cp ON cp.id_proceso = p.id_proceso
  LEFT JOIN computo_proceso hc ON hc.id_proceso = h.id_proceso
 WHERE h.tipo = 'SEGUNDA_VUELTA';

-- ---------------------------------------------------------------------
-- 4. Procedimientos
-- ---------------------------------------------------------------------

DELIMITER $$

-- Mensajes 1 ingresarNulidadParcial(id_mesa, causal) y 5 ingresarNulidadTotal(id_proceso, motivo).
-- El CEUNP registra el recurso de nulidad, de oficio o a pedido de un personero acreditado (RF94).
--   PARCIAL: proceso CERRADO y antes del cómputo (RN26), mesa CERRADA con votación.
--   TOTAL:   proceso CERRADO, o FINALIZADO con el cómputo hecho y sin proclamar (RF101).
--            PARTICIPACION_INSUFICIENTE solo formaliza la nulidad A1 del cómputo (RN31) y es de oficio.
CREATE PROCEDURE sp_registrar_nulidad(
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
    -- 1 ingresarNulidadParcial(id_mesa, causal)
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
    -- 5 ingresarNulidadTotal(id_proceso, motivo)
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
END$$

-- Mensajes 2-4 (DeclararNulidadParcial) y 6-9 (DeclararNulidadTotal). El Pleno del CEUNP
-- resuelve el recurso con quórum (CEUNP_QUORUM_PLENO) y mayoría simple, con voto dirimente
-- del Presidente en caso de empate (RN36). FUNDADA:
--   PARCIAL: 3 actualizarEstado('ANULADA'): la mesa y sus actas se anulan y salen del cómputo.
--   TOTAL:   7 actualizarEstado('ANULADO', motivo): proceso, mesas y actas anulados; la segunda
--            vuelta convocada que no concluyó también se anula; los recursos parciales
--            pendientes quedan IMPROCEDENTES por sustracción de la materia.
-- Emite la resolución con huella SHA-256 y devuelve el token de su QR (9 mostrarResolucionNulidad).
CREATE PROCEDURE sp_resolver_nulidad(
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

  -- RN36: quórum del Pleno y mayoría simple con voto dirimente del Presidente
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
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: la decisión requiere mayoría simple; en empate decide el voto dirimente del Presidente.';
  END IF;

  -- Etapa en que se puede resolver; si el recurso perdió su objeto solo procede IMPROCEDENTE
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

  -- 4 mostrarMesaExcluida(): votos que salen del cómputo (antes de anular)
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
    -- 2 anularMesa(id_mesa, causal) -> 3 actualizarEstado('ANULADA') (RF100)
    UPDATE acta_electoral SET estado = 'ANULADA' WHERE id_mesa = v_mesa;
    UPDATE mesa_electoral SET estado = 'ANULADA' WHERE id_mesa = v_mesa;
    SET v_efecto = CONCAT('Se anula la votación de la mesa ', v_numero, ' y sus actas; sus votos no se computan (RF100).');
  ELSEIF v_decision = 'FUNDADA' AND v_causal <> 'PARTICIPACION_INSUFICIENTE' THEN
    -- 6 anularProceso(id_proceso, motivo) -> 7 actualizarEstado('ANULADO', motivo_anulacion) (RF101)
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
  SET v_token = SHA2(CONCAT(UUID(), RAND(), p_id_nulidad, 'NULIDAD', NOW(6)), 256);

  UPDATE nulidad_electoral
     SET estado = v_decision, numero_resolucion = v_res, fundamento_resolucion = v_fund,
         miembros_pleno = p_miembros_pleno, votos_favor = p_votos_favor, votos_contra = p_votos_contra,
         voto_dirimente = v_dirimente, fecha_resolucion = v_ahora, id_usuario_resolucion = p_id_usuario,
         contenido_json = v_contenido, hash_integridad = SHA2(v_contenido, 256), token_qr_hash = SHA2(v_token, 256)
   WHERE id_nulidad = p_id_nulidad;

  -- Recursos parciales pendientes de una elección anulada: sustracción de la materia
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
END$$

-- Mensaje 8 registrarComunicacion('SUNEDU, AU, CU') (RF102, Art. 66): se registra cada envío
-- de la resolución de nulidad declarada y su publicación en el portal y en El Peruano.
CREATE PROCEDURE sp_registrar_comunicacion_nulidad(
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
END$$

-- Empates que decide el Pleno del CEUNP con quórum (RN36) por sorteo con semilla pública. La
-- semilla se anuncia en la sesión y el sistema ordena las listas empatadas por
--   SHA2(CONCAT(semilla, '|', id_cargo, '|', id_lista), 256)
-- y elige las primeras según los cupos; cualquiera puede repetir el cálculo.
--   PASE_A_SEGUNDA_VUELTA: cargo en SEGUNDA_VUELTA de una primera vuelta cuyas listas empatan por
--                          los cupos de la segunda (RN33), antes de convocarla.
--   EMPATE_SEGUNDA_VUELTA: cargo en EMPATE de una segunda vuelta (RF97); pasa a ELEGIDO y se proclama.
CREATE PROCEDURE sp_dirimir_empate(
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
  DECLARE v_max      INT;
  DECLARE v_v2       INT;
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

  -- Listas empatadas y cupos en disputa (con agregados, como sp_crear_segunda_vuelta)
  SELECT MAX(total_votos) INTO v_max FROM resultado_electoral WHERE id_cargo = p_id_cargo AND tipo_voto = 'VALIDO';
  IF v_motivo = 'EMPATE_SEGUNDA_VUELTA' THEN
    SET v_v2 = v_max;
    SET v_cupos = 1;
  ELSE
    SELECT COUNT(*) INTO v_n FROM resultado_electoral WHERE id_cargo = p_id_cargo AND tipo_voto = 'VALIDO' AND total_votos = v_max;
    SET v_v2 = v_max;
    IF v_n < 2 THEN
      SELECT COALESCE(MAX(total_votos), v_max) INTO v_v2
        FROM resultado_electoral WHERE id_cargo = p_id_cargo AND tipo_voto = 'VALIDO' AND total_votos < v_max;
    END IF;
    SELECT COUNT(*) INTO v_arriba FROM resultado_electoral WHERE id_cargo = p_id_cargo AND tipo_voto = 'VALIDO' AND total_votos > v_v2;
    SET v_cupos = 2 - v_arriba;
  END IF;
  SELECT COUNT(*), CONCAT('[', GROUP_CONCAT(JSON_OBJECT('id_lista', r.id_lista, 'lista', l.nombre, 'votos', r.total_votos)
                                            ORDER BY r.id_lista SEPARATOR ','), ']')
    INTO v_empat, v_listas
    FROM resultado_electoral r JOIN lista_electoral l ON l.id_lista = r.id_lista
   WHERE r.id_cargo = p_id_cargo AND r.tipo_voto = 'VALIDO' AND r.total_votos = v_v2;
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

  -- Sorteo: orden por SHA-256 de la semilla con el cargo y la lista
  SELECT CONCAT('[', GROUP_CONCAT(x.id_lista ORDER BY x.orden SEPARATOR ','), ']'),
         GROUP_CONCAT(x.nombre ORDER BY x.orden SEPARATOR ' y '), MIN(IF(x.orden = 1, x.id_lista, NULL))
    INTO v_elegidas, v_nombres, v_ganadora
    FROM (SELECT r.id_lista, l.nombre,
                 ROW_NUMBER() OVER (ORDER BY SHA2(CONCAT(v_semilla, '|', p_id_cargo, '|', r.id_lista), 256)) AS orden
            FROM resultado_electoral r JOIN lista_electoral l ON l.id_lista = r.id_lista
           WHERE r.id_cargo = p_id_cargo AND r.tipo_voto = 'VALIDO' AND r.total_votos = v_v2) x
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
END$$

-- Mensajes 11 a 14 (ConfigurarSegundaVuelta): crearSegundaVuelta(id_proceso, fechas) ->
--   12 insertar('SEGUNDA_VUELTA', id_proceso_padre) -> 13 copiarDosMasVotadas(id_cargo)
--   -> 14 copiarPadron(id_proceso_nuevo).
-- Igual que la versión anterior (RN33: clona el cargo, sus categorías, las DOS listas más
-- votadas con sus candidatos y el padrón; el nuevo proceso nace en CREADO), salvo la elección
-- de las dos listas: si varias empatan por un cupo, ya no se toma la de menor id en silencio;
-- se exige el sorteo del Pleno (sp_dirimir_empate, PASE_A_SEGUNDA_VUELTA) y se usan las sorteadas.
CREATE PROCEDURE sp_crear_segunda_vuelta(
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
  DECLARE v_max      INT;
  DECLARE v_v2       INT;
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

    -- 13 copiarDosMasVotadas(id_cargo). Con agregados (no disparan el handler NOT FOUND):
    -- v_v2 = votos de la segunda lista del ranking; las que tienen más pasan directo y las que
    -- tienen v_v2 compiten por los cupos restantes.
    SELECT MAX(total_votos) INTO v_max FROM resultado_electoral WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO';
    SELECT COUNT(*) INTO v_n FROM resultado_electoral WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO' AND total_votos = v_max;
    SET v_v2 = v_max;
    IF v_n < 2 THEN
      SELECT COALESCE(MAX(total_votos), v_max) INTO v_v2
        FROM resultado_electoral WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO' AND total_votos < v_max;
    END IF;
    SELECT COUNT(*) INTO v_arriba FROM resultado_electoral WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO' AND total_votos > v_v2;
    SELECT COUNT(*) INTO v_empat FROM resultado_electoral WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO' AND total_votos = v_v2;
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
       AND (total_votos > v_v2
            OR (total_votos = v_v2 AND (v_elegidas IS NULL OR JSON_CONTAINS(v_elegidas, CAST(id_lista AS CHAR)))));

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

    -- Mismo padrón de la primera vuelta, sin marcas de voto ni mesa
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
END$$

-- Destino del QR de la resolución de nulidad: recalcula el SHA-256 del contenido.
CREATE PROCEDURE sp_verificar_resolucion_nulidad(IN p_token CHAR(64))
BEGIN
  SELECT n.id_nulidad, n.id_proceso, p.nombre AS proceso, 'RESOLUCION_NULIDAD' AS tipo, n.alcance, n.estado,
         n.numero_resolucion, n.fecha_resolucion AS fecha_emision, n.hash_integridad,
         IF(SHA2(n.contenido_json, 256) = n.hash_integridad, 1, 0) AS contenido_integro, n.contenido_json
    FROM nulidad_electoral n JOIN proceso_electoral p ON p.id_proceso = n.id_proceso
   WHERE n.token_qr_hash = SHA2(p_token, 256);
END$$

DELIMITER ;

-- =====================================================================
-- 5f. CUS16 · Reportar omisos y multas (reporte de omisos, multas al 2.5 % y 3 % de la UIT,
--     resolución del Pleno con QR, notificación, justificación, exoneración, pago y RF107)
-- (en una base ya instalada sin este CUS se aplica 15_omisos_multas.sql)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Estado JUSTIFICADA y columnas nuevas de multa: ya vienen en su CREATE TABLE (sección 2)
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- 2. Tablas nuevas
-- ---------------------------------------------------------------------

-- 2 generarMultas() y 7 mostrarReporteMultas(): un reporte por proceso. GENERADO mientras se
-- puede regenerar; RESUELTO cuando el Pleno emite la resolución que determina las multas.
CREATE TABLE reporte_multas (
  id_reporte            INT AUTO_INCREMENT PRIMARY KEY,
  id_proceso            INT NOT NULL,
  estado                ENUM('GENERADO','RESUELTO') NOT NULL DEFAULT 'GENERADO',
  -- 3 obtenerUIT(): valores con los que se calcularon las multas (RF105)
  uit_referencia        DECIMAL(10,2) NOT NULL,
  pct_elector           DECIMAL(5,2)  NOT NULL,
  pct_miembro           DECIMAL(5,2)  NOT NULL,
  omisos_votacion       INT NOT NULL DEFAULT 0,
  omisos_mesa           INT NOT NULL DEFAULT 0,
  monto_total           DECIMAL(12,2) NOT NULL DEFAULT 0,
  veces_generado        INT NOT NULL DEFAULT 1,
  fecha_generacion      DATETIME NOT NULL,
  id_usuario_generacion INT NULL,
  -- resolución del Pleno (RN36)
  numero_resolucion     VARCHAR(40) NULL,
  fundamento            VARCHAR(1000) NULL,
  miembros_pleno        TINYINT NULL,
  fecha_resolucion      DATETIME NULL,
  id_usuario_resolucion INT NULL,
  contenido_json        LONGTEXT NULL,
  hash_integridad       CHAR(64) NULL,
  token_qr_hash         CHAR(64) NULL,
  UNIQUE KEY uq_reporte_multas_proceso (id_proceso),
  UNIQUE KEY uq_reporte_multas_resolucion (numero_resolucion),
  UNIQUE KEY uq_reporte_multas_token (token_qr_hash),
  CONSTRAINT chk_reporte_multas_resuelto CHECK (estado = 'GENERADO'
    OR (numero_resolucion IS NOT NULL AND fecha_resolucion IS NOT NULL AND contenido_json IS NOT NULL AND hash_integridad IS NOT NULL)),
  CONSTRAINT chk_reporte_multas_json CHECK (contenido_json IS NULL OR JSON_VALID(contenido_json)),
  CONSTRAINT fk_reporte_multas_proceso FOREIGN KEY (id_proceso)            REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_reporte_multas_u_gen   FOREIGN KEY (id_usuario_generacion) REFERENCES usuario(id_usuario),
  CONSTRAINT fk_reporte_multas_u_res   FOREIGN KEY (id_usuario_resolucion) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9 justificar() (RF106): justificación del docente que el CEUNP admite o deniega, o
-- exoneración de oficio por lo no previsto en el reglamento (RN40). Una justificación por multa.
CREATE TABLE multa_justificacion (
  id_justificacion   INT AUTO_INCREMENT PRIMARY KEY,
  id_multa           INT NOT NULL,
  tipo               ENUM('JUSTIFICACION','EXONERACION') NOT NULL,
  causal             ENUM('SALUD','DUELO','COMISION_SERVICIO','LICENCIA','CASO_FORTUITO','FALLECIMIENTO','ERROR_PADRON','OTRA') NOT NULL,
  sustento           VARCHAR(1000) NOT NULL,
  documento          VARCHAR(150) NULL,                 -- certificado, constancia o expediente que acompaña
  fecha_presentacion DATETIME NOT NULL,
  decision           ENUM('ADMITIDA','DENEGADA') NOT NULL,
  fundamento         VARCHAR(1000) NOT NULL,
  numero_resolucion  VARCHAR(40) NOT NULL,
  miembros_pleno     TINYINT NOT NULL,
  fecha_resolucion   DATETIME NOT NULL,
  id_usuario         INT NULL,
  justificacion_unica INT AS (IF(tipo = 'JUSTIFICACION', id_multa, NULL)) STORED,
  admitida_unica      INT AS (IF(decision = 'ADMITIDA', id_multa, NULL)) STORED,
  UNIQUE KEY uq_mjust_resolucion (numero_resolucion),
  UNIQUE KEY uq_mjust_justificacion (justificacion_unica),
  UNIQUE KEY uq_mjust_admitida (admitida_unica),
  KEY ix_mjust_multa (id_multa),
  CONSTRAINT chk_mjust_exoneracion CHECK (tipo = 'JUSTIFICACION' OR decision = 'ADMITIDA'),
  CONSTRAINT fk_mjust_multa   FOREIGN KEY (id_multa)   REFERENCES multa(id_multa),
  CONSTRAINT fk_mjust_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 3. Parámetros (editables en la pantalla Parámetros, RF105)
-- ---------------------------------------------------------------------
-- (Se cargan en la sección 6, junto con los demás parámetros.)

-- ---------------------------------------------------------------------
-- 4. Función: número de resolución ya usado en cualquier caso de uso (RN36)
--    Incluye las resoluciones de nulidad, empate, calificación, cómputo, impugnación, multas y descargos.
-- ---------------------------------------------------------------------

DELIMITER $$

CREATE FUNCTION fn_resolucion_en_uso(p_numero VARCHAR(40))
RETURNS BOOLEAN
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
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- 5. Triggers
-- ---------------------------------------------------------------------

DELIMITER $$

-- Determinadas por la resolución, las multas del proceso ya no se agregan (RN35)
CREATE TRIGGER trg_multa_bi_cus16 BEFORE INSERT ON multa
FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM reporte_multas WHERE id_proceso = NEW.id_proceso AND estado = 'RESUELTO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: las multas del proceso ya fueron determinadas por resolución del CEUNP.';
  END IF;
END$$

-- Antes de la resolución las multas se recalculan; después solo cambia su estado, una vez,
-- desde PENDIENTE (pago, justificación o exoneración), y su notificación no se modifica.
CREATE TRIGGER trg_multa_bu_cus16 BEFORE UPDATE ON multa
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
END$$

-- Solo sp_generar_multas retira, antes de la resolución, la multa que ya no corresponde.
-- La limpieza de datos usa TRUNCATE (02_limpiar_datos_electorales.sql).
CREATE TRIGGER trg_multa_bd_cus16 BEFORE DELETE ON multa
FOR EACH ROW
BEGIN
  IF NOT (@cus16_regenerar <=> OLD.id_proceso) OR OLD.estado_pago <> 'PENDIENTE'
     OR EXISTS (SELECT 1 FROM reporte_multas WHERE id_proceso = OLD.id_proceso AND estado = 'RESUELTO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: una multa no se elimina; si procede, se justifica o se exonera (RF106).';
  END IF;
END$$

-- RN36: la resolución que determina las multas es inapelable
CREATE TRIGGER trg_rmultas_bu BEFORE UPDATE ON reporte_multas
FOR EACH ROW
BEGIN
  IF OLD.estado = 'RESUELTO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: la resolución de multas del CEUNP no se modifica.';
  END IF;
  IF NOT (NEW.id_proceso <=> OLD.id_proceso) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El reporte de multas no cambia de proceso.';
  END IF;
END$$

CREATE TRIGGER trg_rmultas_bd BEFORE DELETE ON reporte_multas
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: el reporte de multas no se elimina.';
END$$

CREATE TRIGGER trg_mjust_bu BEFORE UPDATE ON multa_justificacion
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: la decisión del CEUNP sobre el descargo es inapelable.';
END$$

CREATE TRIGGER trg_mjust_bd BEFORE DELETE ON multa_justificacion
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el descargo resuelto no se elimina.';
END$$

-- RN36: el número de resolución tampoco se repite frente a las multas y sus descargos
CREATE TRIGGER trg_computo_bu_cus16 BEFORE UPDATE ON computo_proceso
FOR EACH ROW
BEGIN
  IF NEW.numero_resolucion IS NOT NULL AND NOT (NEW.numero_resolucion <=> OLD.numero_resolucion)
     AND (EXISTS (SELECT 1 FROM reporte_multas WHERE numero_resolucion = NEW.numero_resolucion)
          OR EXISTS (SELECT 1 FROM multa_justificacion WHERE numero_resolucion = NEW.numero_resolucion)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;
END$$

CREATE TRIGGER trg_calificacion_bi_cus16 BEFORE INSERT ON calificacion_mesa
FOR EACH ROW
BEGIN
  IF NEW.numero_resolucion IS NOT NULL
     AND (EXISTS (SELECT 1 FROM reporte_multas WHERE numero_resolucion = NEW.numero_resolucion)
          OR EXISTS (SELECT 1 FROM multa_justificacion WHERE numero_resolucion = NEW.numero_resolucion)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;
END$$

CREATE TRIGGER trg_impugnacion_bu_cus16 BEFORE UPDATE ON impugnacion_electoral
FOR EACH ROW
BEGIN
  IF NEW.numero_resolucion IS NOT NULL AND NOT (NEW.numero_resolucion <=> OLD.numero_resolucion)
     AND (EXISTS (SELECT 1 FROM reporte_multas WHERE numero_resolucion = NEW.numero_resolucion)
          OR EXISTS (SELECT 1 FROM multa_justificacion WHERE numero_resolucion = NEW.numero_resolucion)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- 6. Vistas
-- ---------------------------------------------------------------------

-- 1 solicitarReporteOmisos(): quiénes corresponden a multa, antes y después de generarla.
--   4 consultarNoVotaron(): elector hábil que no votó por ningún cargo, con mesa que se
--     instaló (la mesa NO INSTALADA no permitió votar: RF58). Marca a quien asistió sin votar.
--   5 consultarInasistentes(): miembro TITULAR sorteado que no se presentó (CUS08).
CREATE VIEW v_omisos_proceso AS
SELECT x.id_proceso, x.id_docente, _utf8mb4'OMISO_VOTACION' COLLATE utf8mb4_unicode_ci AS motivo, x.id_mesa,
       CAST(NULL AS CHAR(12) CHARACTER SET utf8mb4) COLLATE utf8mb4_unicode_ci AS rol_mesa,
       IF(EXISTS (SELECT 1 FROM asistencia_elector a WHERE a.id_proceso = x.id_proceso AND a.id_docente = x.id_docente), 1, 0) AS asistio_sin_votar
  FROM (SELECT pe.id_proceso, pe.id_docente, MIN(pe.id_mesa) AS id_mesa
          FROM padron_electoral pe
          JOIN mesa_electoral m ON m.id_mesa = pe.id_mesa
         WHERE pe.habilitado_para_votar = 1
         GROUP BY pe.id_proceso, pe.id_docente
        HAVING MAX(pe.ya_voto) = 0 AND MAX(m.hora_instalacion IS NOT NULL) = 1) x
UNION ALL
SELECT m.id_proceso, mm.id_docente, _utf8mb4'OMISO_MESA' COLLATE utf8mb4_unicode_ci, m.id_mesa,
       CONVERT(CONCAT(mm.rol, '') USING utf8mb4) COLLATE utf8mb4_unicode_ci, 0
  FROM miembro_mesa mm
  JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
 WHERE mm.titular = 1 AND mm.asistio = 0;

-- RN35: multas con datos del docente. Conserva las columnas anteriores (ProcesoService) y agrega
-- la mesa, la notificación, el pago, el último descargo y el plazo para justificar (CUS16).
CREATE VIEW v_multas_detalle AS
SELECT mu.id_multa, mu.id_proceso, p.nombre AS proceso,
       d.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS docente, f.nombre AS facultad,
       mu.motivo, mu.uit_referencia, mu.porcentaje_uit, mu.monto,
       mu.estado_pago, mu.fecha_generacion, mu.fecha_pago,
       p.tipo AS tipo_proceso, p.estado AS estado_proceso, dp.nombre AS departamento, CONCAT(d.categoria, '') AS categoria, d.email,
       mu.id_mesa, m.numero_mesa, m.ubicacion, mu.rol_mesa, mu.asistio_sin_votar, mu.observacion,
       mu.fecha_notificacion, CONCAT(mu.medio_notificacion, '') AS medio_notificacion, mu.documento_notificacion,
       mu.numero_recibo, mu.fecha_actualizacion,
       r.estado AS estado_reporte, r.numero_resolucion AS resolucion_multas, r.fecha_resolucion AS fecha_resolucion_multas,
       (SELECT COUNT(*) FROM multa_justificacion j WHERE j.id_multa = mu.id_multa) AS descargos,
       j.id_justificacion, CONCAT(j.tipo, '') AS tipo_descargo, CONCAT(j.causal, '') AS causal_descargo, j.decision AS decision_descargo,
       j.numero_resolucion AS resolucion_descargo, j.fecha_resolucion AS fecha_descargo,
       IF(r.estado = 'RESUELTO' AND g.dias > 0,
          COALESCE(mu.fecha_notificacion, r.fecha_resolucion) + INTERVAL g.dias DAY, NULL) AS limite_justificacion
  FROM multa mu
  JOIN proceso_electoral p    ON p.id_proceso = mu.id_proceso
  JOIN docente d              ON d.id_docente = mu.id_docente
  JOIN facultad f             ON f.id_facultad = d.id_facultad
  LEFT JOIN departamento dp   ON dp.id_departamento = d.id_departamento
  LEFT JOIN mesa_electoral m  ON m.id_mesa = mu.id_mesa
  LEFT JOIN reporte_multas r  ON r.id_proceso = mu.id_proceso
  LEFT JOIN multa_justificacion j ON j.id_justificacion = (SELECT MAX(x.id_justificacion) FROM multa_justificacion x
                                                           WHERE x.id_multa = mu.id_multa)
  CROSS JOIN (SELECT COALESCE(ROUND((SELECT CAST(valor AS DECIMAL(8,2)) FROM parametro_global
                                     WHERE clave = 'MULTA_PLAZO_JUSTIFICACION_DIAS')), 10) AS dias) g;

-- RF107: reporte de gestión por mesa (participación, instalación, miembros, incidencias,
-- tiempo de atención del elector y actas recibidas por el CEUNP).
CREATE VIEW v_reporte_gestion_mesas AS
SELECT m.id_proceso, m.id_mesa, m.numero_mesa, m.ubicacion, m.estado, m.hora_instalacion, m.hora_cierre,
       (SELECT COUNT(DISTINCT pe.id_docente) FROM padron_electoral pe
         WHERE pe.id_mesa = m.id_mesa AND pe.habilitado_para_votar = 1) AS electores,
       (SELECT COUNT(DISTINCT pe.id_docente) FROM padron_electoral pe
         WHERE pe.id_mesa = m.id_mesa AND pe.habilitado_para_votar = 1 AND pe.ya_voto = 1) AS votaron,
       (SELECT COUNT(*) FROM asistencia_elector a WHERE a.id_mesa = m.id_mesa) AS asistieron,
       (SELECT COUNT(*) FROM miembro_mesa mm WHERE mm.id_mesa = m.id_mesa AND mm.titular = 1 AND mm.asistio = 1) AS titulares_presentes,
       (SELECT COUNT(*) FROM miembro_mesa mm WHERE mm.id_mesa = m.id_mesa AND mm.titular = 1 AND mm.asistio = 0) AS titulares_ausentes,
       (SELECT COUNT(*) FROM miembro_mesa mm WHERE mm.id_mesa = m.id_mesa AND mm.titular = 0 AND mm.rol_instalacion IS NOT NULL) AS suplentes_en_funcion,
       (SELECT COUNT(*) FROM incidencia_mesa i WHERE i.id_mesa = m.id_mesa) AS incidencias,
       (SELECT ROUND(AVG(TIMESTAMPDIFF(SECOND, a.hora_asistencia, h.fecha_cierre)))
          FROM habilitacion_terminal h JOIN asistencia_elector a ON a.id_asistencia = h.id_asistencia
         WHERE a.id_mesa = m.id_mesa AND h.estado = 'CONSUMIDA') AS atencion_promedio_seg,
       (SELECT COUNT(DISTINCT ac.tipo) FROM acta_electoral ac WHERE ac.id_mesa = m.id_mesa) AS actas_emitidas,
       e.estado AS estado_escrutinio, e.fecha_entrega, e.recibido_por
  FROM mesa_electoral m
  LEFT JOIN escrutinio_mesa e ON e.id_mesa = m.id_mesa;

-- ---------------------------------------------------------------------
-- 7. Procedimientos
-- ---------------------------------------------------------------------

DELIMITER $$

-- Mensajes 2 a 6 (GenerarMultas):
--   3 obtenerUIT(): UIT y porcentajes de parametro_global (RF105)
--   4 consultarNoVotaron() y 5 consultarInasistentes(): v_omisos_proceso (RF103, RF104)
--   6 insertar(): una multa por docente y motivo con monto = UIT * % / 100 (RN35)
-- Se genera con la votación concluida en todas las mesas. Mientras no haya resolución, al
-- volver a ejecutarlo recalcula los montos y retira las multas que ya no corresponden.
CREATE PROCEDURE sp_generar_multas(
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

  -- 3 obtenerUIT()
  SET v_uit      = fn_parametro_decimal('UIT');
  SET v_pct_elec = fn_parametro_decimal('MULTA_ELECTOR_OMISO_PCT');
  SET v_pct_mesa = fn_parametro_decimal('MULTA_MIEMBRO_MESA_OMISO_PCT');
  IF v_uit IS NULL OR v_pct_elec IS NULL OR v_pct_mesa IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF105: faltan parámetros: UIT y porcentajes de multa.';
  END IF;
  IF v_uit <= 0 OR v_pct_elec < 0 OR v_pct_elec > 100 OR v_pct_mesa < 0 OR v_pct_mesa > 100 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF105: la UIT debe ser positiva y los porcentajes de multa estar entre 0 y 100.';
  END IF;

  -- Retira las multas que ya no corresponden (solo antes de la resolución)
  SET @cus16_regenerar = p_id_proceso;
  DELETE mu FROM multa mu
   WHERE mu.id_proceso = p_id_proceso AND mu.estado_pago = 'PENDIENTE'
     AND NOT EXISTS (SELECT 1 FROM v_omisos_proceso o
                      WHERE o.id_proceso = mu.id_proceso AND o.id_docente = mu.id_docente AND o.motivo = mu.motivo);
  SET v_retiradas = ROW_COUNT();
  SET @cus16_regenerar = NULL;

  -- 4 consultarNoVotaron() · 5 consultarInasistentes() · 6 insertar()
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
END$$

-- Mensaje 7 mostrarReporteMultas(): el Pleno del CEUNP (quórum CEUNP_QUORUM_PLENO, RN36) emite
-- la resolución que determina las multas del reporte generado. Guarda su contenido con huella
-- SHA-256 y devuelve el token del QR (solo esta vez). Desde entonces las multas quedan fijas.
CREATE PROCEDURE sp_emitir_resolucion_multas(
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

  -- El reporte debe estar al día: las multas generadas coinciden con los omisos actuales
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
  SET v_token = SHA2(CONCAT(UUID(), RAND(), p_id_proceso, 'MULTAS', NOW(6)), 256);

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
END$$

-- Notificación de las multas determinadas a cada docente (CUN12 paso 3). p_id_multa NULL
-- notifica de una vez todas las que faltan. Devuelve cuántas notificó.
CREATE PROCEDURE sp_notificar_multas(
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
END$$

-- Mensajes 8 registrarJustificacion -> 9 justificar() -> 10 actualizarEstado() -> 11 confirmar().
-- RF106: el CEUNP registra el descargo de una multa determinada y PENDIENTE con su decisión,
-- por resolución del Pleno con quórum (RN36):
--   JUSTIFICACION: la presenta el docente dentro de MULTA_PLAZO_JUSTIFICACION_DIAS desde la
--                  notificación (una por multa). ADMITIDA -> JUSTIFICADA; DENEGADA -> sigue PENDIENTE.
--   EXONERACION:   de oficio, por lo no previsto en el reglamento (RN40). Siempre ADMITIDA -> EXONERADA.
CREATE PROCEDURE sp_registrar_justificacion(
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

  -- 9 justificar()
  INSERT INTO multa_justificacion (id_multa, tipo, causal, sustento, documento, fecha_presentacion, decision, fundamento,
                                   numero_resolucion, miembros_pleno, fecha_resolucion, id_usuario)
  VALUES (p_id_multa, v_tipo, v_causal, v_sustento, NULLIF(TRIM(p_documento), ''), v_fecha, v_decision, v_fund,
          v_res, p_miembros_pleno, v_ahora, p_id_usuario);
  SET v_id = LAST_INSERT_ID();

  -- 10 actualizarEstado()
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

  -- 11 confirmar()
  SELECT v_id AS id_justificacion, p_id_multa AS id_multa, v_tipo AS tipo, v_decision AS decision,
         v_nuevo AS estado_pago, v_res AS numero_resolucion;
END$$

-- Pago de una multa determinada (el sistema no cobra: registra el recibo de Tesorería).
CREATE PROCEDURE sp_registrar_pago_multa(
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
END$$

-- PATCH /api/multas/{id}, con las reglas del CUS16: PAGADA exige el
-- recibo en p_observacion; la justificación y la exoneración van con su resolución (RF106).
CREATE PROCEDURE sp_actualizar_multa(
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
END$$

-- Destino del QR de la resolución de multas: recalcula el SHA-256 del contenido. No devuelve la
-- relación de docentes, solo los totales.
CREATE PROCEDURE sp_verificar_resolucion_multas(IN p_token CHAR(64))
BEGIN
  SELECT r.id_proceso, p.nombre AS proceso, r.numero_resolucion, r.fecha_resolucion, r.omisos_votacion, r.omisos_mesa,
         r.monto_total, r.uit_referencia, r.hash_integridad,
         IF(SHA2(r.contenido_json, 256) = r.hash_integridad, 1, 0) AS contenido_integro
    FROM reporte_multas r
    JOIN proceso_electoral p ON p.id_proceso = r.id_proceso
   WHERE r.token_qr_hash = SHA2(p_token, 256) AND r.estado = 'RESUELTO';
END$$

DELIMITER ;

-- =====================================================================
-- 5g. CUS17 · Consultar resultados y verificar actas (verificación única por QR o huella,
--     registro de verificaciones, cotejo del ejemplar físico y resultados por mesa)
-- (en una base ya instalada sin este CUS se aplica 16_resultados_verificacion.sql)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Tablas nuevas
-- ---------------------------------------------------------------------

-- 8 verificarActa() · 11 mostrarAutenticidad(): una fila por consulta de autenticidad (RF55).
-- No guarda el código leído (token o huella), solo su SHA-256.
CREATE TABLE verificacion_documento (
  id_verificacion BIGINT AUTO_INCREMENT PRIMARY KEY,
  codigo_hash     CHAR(64) NOT NULL,
  metodo          ENUM('TOKEN','HUELLA') NULL,
  canal           ENUM('QR','CODIGO','LISTA','PORTAL') NOT NULL DEFAULT 'QR',
  tipo_documento  VARCHAR(30) NULL,
  id_documento    INT NULL,
  id_proceso      INT NULL,
  id_mesa         INT NULL,
  resultado       ENUM('AUTENTICA','ALTERADA','ANULADA','NO_ENCONTRADA') NOT NULL,
  id_usuario      INT NULL,
  rol             VARCHAR(20) NULL,
  ip              VARCHAR(45) NULL,
  fecha           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_verificacion_proceso (id_proceso, fecha),
  KEY ix_verificacion_documento (tipo_documento, id_documento),
  KEY ix_verificacion_usuario (id_usuario, fecha),
  CONSTRAINT fk_verificacion_proceso FOREIGN KEY (id_proceso) REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_verificacion_mesa    FOREIGN KEY (id_mesa)    REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_verificacion_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Cotejo del ejemplar físico con el documento digital. CONFORME si todas las cifras coinciden y
-- el contenido está íntegro; OBSERVADO si hay diferencias (discrepancia reportada al CEUNP);
-- ATENDIDO cuando el CEUNP responde.
CREATE TABLE cotejo_acta (
  id_cotejo            INT AUTO_INCREMENT PRIMARY KEY,
  id_verificacion      BIGINT NULL,
  tipo_documento       VARCHAR(30) NOT NULL,
  id_documento         INT NOT NULL,
  id_proceso           INT NOT NULL,
  id_mesa              INT NULL,
  hash_integridad      CHAR(64) NOT NULL,
  contenido_integro    BOOLEAN NOT NULL,
  id_usuario           INT NOT NULL,
  rol                  VARCHAR(20) NOT NULL,
  id_personero         INT NULL,
  cifras_json          LONGTEXT NOT NULL,
  lineas               INT NOT NULL,
  diferencias          INT NOT NULL,
  observacion          VARCHAR(1000) NULL,
  estado               ENUM('CONFORME','OBSERVADO','ATENDIDO') NOT NULL,
  fecha                DATETIME NOT NULL,
  -- atención del CEUNP
  decision             ENUM('ACLARADA','FUNDADA') NULL,
  respuesta            VARCHAR(1000) NULL,
  fecha_respuesta      DATETIME NULL,
  id_usuario_respuesta INT NULL,
  KEY ix_cotejo_proceso (id_proceso, estado),
  KEY ix_cotejo_documento (tipo_documento, id_documento),
  KEY ix_cotejo_usuario (id_usuario),
  CONSTRAINT chk_cotejo_json CHECK (JSON_VALID(cifras_json)),
  CONSTRAINT chk_cotejo_cifras CHECK (lineas > 0 AND diferencias >= 0 AND diferencias <= lineas),
  CONSTRAINT chk_cotejo_estado CHECK (
       (estado = 'CONFORME' AND diferencias = 0 AND contenido_integro = 1)
    OR (estado IN ('OBSERVADO','ATENDIDO') AND observacion IS NOT NULL)),
  CONSTRAINT chk_cotejo_atendido CHECK ((estado = 'ATENDIDO') =
       (decision IS NOT NULL AND respuesta IS NOT NULL AND fecha_respuesta IS NOT NULL)),
  CONSTRAINT fk_cotejo_verificacion FOREIGN KEY (id_verificacion)      REFERENCES verificacion_documento(id_verificacion),
  CONSTRAINT fk_cotejo_proceso      FOREIGN KEY (id_proceso)           REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_cotejo_mesa         FOREIGN KEY (id_mesa)              REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_cotejo_usuario      FOREIGN KEY (id_usuario)           REFERENCES usuario(id_usuario),
  CONSTRAINT fk_cotejo_personero    FOREIGN KEY (id_personero)         REFERENCES personero(id_personero),
  CONSTRAINT fk_cotejo_u_respuesta  FOREIGN KEY (id_usuario_respuesta) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 2. Triggers: la bitácora de verificaciones y los cotejos no se alteran
-- ---------------------------------------------------------------------

DELIMITER $$

CREATE TRIGGER trg_verificacion_doc_bu BEFORE UPDATE ON verificacion_documento
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF55: el registro de verificaciones no se modifica.';
END$$

CREATE TRIGGER trg_verificacion_doc_bd BEFORE DELETE ON verificacion_documento
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF55: el registro de verificaciones no se elimina.';
END$$

-- Solo cambia la atención del CEUNP, una vez, sobre un cotejo OBSERVADO
CREATE TRIGGER trg_cotejo_bu BEFORE UPDATE ON cotejo_acta
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
END$$

CREATE TRIGGER trg_cotejo_bd BEFORE DELETE ON cotejo_acta
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: el cotejo del acta no se elimina.';
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- 3. Función
-- ---------------------------------------------------------------------

DELIMITER $$

-- 3 verificarComputoCerrado(): hay resultados que mostrar al docente y al personero cuando el
-- CEUNP publicó el cómputo (CUS14, RF99) o, sin CUS14, cuando el proceso se computó con el
-- cómputo heredado (sp_computar_resultados) y quedó FINALIZADO o ANULADO (RN26).
CREATE FUNCTION fn_resultados_disponibles(p_id_proceso INT) RETURNS TINYINT
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
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- 4. Vistas
-- ---------------------------------------------------------------------

-- 1 seleccionarProceso() · 4 consultarResultados(): procesos con resultados que se pueden consultar.
CREATE VIEW v_resultados_procesos AS
SELECT p.id_proceso, p.nombre AS proceso, p.tipo, p.estado AS estado_proceso, p.id_proceso_padre,
       pp.nombre AS proceso_padre,
       IF(cp.id_proceso IS NULL, 'HEREDADO', 'CUS14') AS origen,
       COALESCE(CONCAT(cp.resultado, ''), IF(p.estado = 'ANULADO', 'NULIDAD_TOTAL', 'VALIDA')) AS resultado,
       COALESCE(cp.electores_habiles, q.electores_habiles) AS electores_habiles,
       COALESCE(cp.votaron, q.votaron) AS votaron,
       COALESCE(cp.participacion_pct, q.participacion_pct) AS participacion_pct,
       p.quorum_minimo,
       cp.mesas_total, cp.mesas_computadas, cp.mesas_anuladas, cp.mesas_no_instaladas,
       cp.numero_resolucion,
       COALESCE(cp.fecha_computo, (SELECT MAX(r.fecha_computo) FROM resultado_electoral r WHERE r.id_proceso = p.id_proceso)) AS fecha_computo,
       cp.fecha_proclamacion, cp.fecha_publicacion,
       (SELECT COUNT(*) FROM cargo_electoral c WHERE c.id_proceso = p.id_proceso) AS cargos,
       (SELECT COUNT(*) FROM mesa_electoral m WHERE m.id_proceso = p.id_proceso) AS mesas
  FROM proceso_electoral p
  LEFT JOIN proceso_electoral pp ON pp.id_proceso = p.id_proceso_padre
  LEFT JOIN computo_proceso cp   ON cp.id_proceso = p.id_proceso
  LEFT JOIN v_quorum_proceso q   ON q.id_proceso = p.id_proceso
 WHERE fn_resultados_disponibles(p.id_proceso) = 1;

-- 5 devolverResultados(): resultados por mesa. Con CUS12 son las cifras del acta de escrutinio con
-- las impugnaciones asignadas (v_computo_conteo_mesa); con el cierre heredado, el conteo de la urna.
CREATE VIEW v_resultados_mesa AS
SELECT x.id_proceso, x.id_mesa, x.numero_mesa, CONCAT(m.estado, '') AS estado_mesa, x.id_cargo, c.nombre AS cargo,
       CONCAT(x.opcion, '') AS opcion, x.id_lista,
       COALESCE(l.nombre, CASE x.opcion WHEN 'BLANCO' THEN 'Votos en blanco' ELSE 'Votos nulos' END) AS lista,
       l.orden_cedula, x.votos, 'ACTA_ESCRUTINIO' AS fuente
  FROM v_computo_conteo_mesa x
  JOIN mesa_electoral m  ON m.id_mesa = x.id_mesa
  JOIN cargo_electoral c ON c.id_cargo = x.id_cargo
  LEFT JOIN lista_electoral l ON l.id_lista = x.id_lista
 WHERE x.opcion <> 'IMPUGNADO'
UNION ALL
SELECT m.id_proceso, m.id_mesa, m.numero_mesa, CONCAT(m.estado, ''), v.id_cargo, c.nombre,
       IF(v.tipo_voto = 'VALIDO', 'LISTA', CONCAT(v.tipo_voto, '')), v.id_lista_elegida,
       COALESCE(l.nombre, IF(v.tipo_voto = 'BLANCO', 'Votos en blanco', 'Votos nulos')),
       l.orden_cedula, COUNT(*), 'URNA_DIGITAL'
  FROM voto v
  JOIN mesa_electoral m  ON m.id_mesa = v.id_mesa
  JOIN cargo_electoral c ON c.id_cargo = v.id_cargo
  LEFT JOIN lista_electoral l ON l.id_lista = v.id_lista_elegida
 WHERE NOT EXISTS (SELECT 1 FROM escrutinio_mesa e
                    WHERE e.id_mesa = m.id_mesa AND e.estado IN ('ACTA_EMITIDA','ENTREGADA'))
 GROUP BY m.id_proceso, m.id_mesa, m.numero_mesa, m.estado, v.id_cargo, c.nombre, v.tipo_voto,
          v.id_lista_elegida, l.nombre, l.orden_cedula;

-- RF52 · RF55: documentos con QR y huella SHA-256 del proceso, con su integridad recalculada,
-- firmas, verificaciones y cotejos. La huella se imprime en el documento: no es secreta.
CREATE VIEW v_documentos_verificables AS
SELECT d.*,
       (SELECT COUNT(*) FROM verificacion_documento v
         WHERE v.tipo_documento = d.tipo_documento AND v.id_documento = d.id_documento) AS verificaciones,
       (SELECT COUNT(*) FROM cotejo_acta k
         WHERE k.tipo_documento = d.tipo_documento AND k.id_documento = d.id_documento) AS cotejos,
       (SELECT COUNT(*) FROM cotejo_acta k
         WHERE k.tipo_documento = d.tipo_documento AND k.id_documento = d.id_documento AND k.estado = 'OBSERVADO') AS observados
  FROM (
    SELECT m.id_proceso, CONCAT('ACTA_', a.tipo) AS tipo_documento, a.id_acta AS id_documento, a.id_mesa, m.numero_mesa,
           NULL AS numero_resolucion, a.fecha_emision, CONCAT(a.estado, '') AS estado, a.hash_integridad,
           IF(SHA2(a.contenido_json, 256) = a.hash_integridad, 1, 0) AS integra,
           (SELECT COUNT(*) FROM firma_acta f WHERE f.id_acta = a.id_acta) AS firmas
      FROM acta_electoral a JOIN mesa_electoral m ON m.id_mesa = a.id_mesa
    UNION ALL
    SELECT cp.id_proceso, 'COMPUTO_GENERAL', cp.id_proceso, NULL, NULL, NULL, cp.fecha_computo, CONCAT(cp.estado, ''),
           cp.hash_integridad, IF(SHA2(cp.contenido_json, 256) = cp.hash_integridad, 1, 0), 0
      FROM computo_proceso cp WHERE cp.hash_integridad IS NOT NULL
    UNION ALL
    SELECT cp.id_proceso, 'PROCLAMACION', cp.id_proceso, NULL, NULL, cp.numero_resolucion, cp.fecha_proclamacion,
           CONCAT(cp.estado, ''), cp.hash_proclamacion, IF(SHA2(cp.contenido_proclamacion, 256) = cp.hash_proclamacion, 1, 0), 0
      FROM computo_proceso cp WHERE cp.hash_proclamacion IS NOT NULL
    UNION ALL
    SELECT n.id_proceso, 'RESOLUCION_NULIDAD', n.id_nulidad, n.id_mesa, m.numero_mesa, n.numero_resolucion,
           n.fecha_resolucion, CONCAT(n.estado, ''), n.hash_integridad, IF(SHA2(n.contenido_json, 256) = n.hash_integridad, 1, 0), 0
      FROM nulidad_electoral n LEFT JOIN mesa_electoral m ON m.id_mesa = n.id_mesa
     WHERE n.hash_integridad IS NOT NULL
    UNION ALL
    SELECT r.id_proceso, 'RESOLUCION_MULTAS', r.id_reporte, NULL, NULL, r.numero_resolucion, r.fecha_resolucion,
           CONCAT(r.estado, ''), r.hash_integridad, IF(SHA2(r.contenido_json, 256) = r.hash_integridad, 1, 0), 0
      FROM reporte_multas r WHERE r.estado = 'RESUELTO' AND r.hash_integridad IS NOT NULL
  ) d;

-- Cotejos con quién los registró y su atención
CREATE VIEW v_cotejos_acta AS
SELECT k.id_cotejo, k.id_proceso, p.nombre AS proceso, k.tipo_documento, k.id_documento, k.id_mesa, m.numero_mesa,
       k.hash_integridad, k.contenido_integro, k.lineas, k.diferencias, k.observacion, k.estado, k.fecha,
       k.id_usuario, u.username, k.rol, CONCAT(d.apellidos, ', ', d.nombres) AS registrado_por,
       k.id_personero, l.nombre AS lista_personero, CONCAT(pe.tipo, '') AS tipo_personero,
       k.decision, k.respuesta, k.fecha_respuesta, ur.username AS atendido_por, k.cifras_json
  FROM cotejo_acta k
  JOIN proceso_electoral p ON p.id_proceso = k.id_proceso
  JOIN usuario u           ON u.id_usuario = k.id_usuario
  LEFT JOIN docente d      ON d.id_docente = u.id_docente
  LEFT JOIN mesa_electoral m  ON m.id_mesa = k.id_mesa
  LEFT JOIN personero pe      ON pe.id_personero = k.id_personero
  LEFT JOIN lista_electoral l ON l.id_lista = pe.id_lista
  LEFT JOIN usuario ur        ON ur.id_usuario = k.id_usuario_respuesta;

-- ---------------------------------------------------------------------
-- 5. Procedimientos
-- ---------------------------------------------------------------------

DELIMITER $$

-- 9 consultarPorToken(): busca el documento por el SHA-256 del token del QR y, si no aparece, por su
-- huella SHA-256 (cuando el QR no se puede leer). No modifica datos.
CREATE PROCEDURE sp_localizar_documento(
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

  -- Token del QR
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
    -- Huella SHA-256 impresa en el documento
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
END$$

-- 8 verificarActa() · 9 consultarPorToken() · 10 recalcularHash() · 11 mostrarAutenticidad().
-- Devuelve una fila con el documento y el resultado, y registra la consulta (RF55).
-- AUTENTICA: la huella recalculada coincide. ALTERADA: no coincide. ANULADA: íntegra, pero el
-- documento ya no tiene efecto (acta de una mesa anulada, constancia revocada o vencida).
-- La resolución de multas no devuelve la relación de docentes, solo sus totales (CUS16).
CREATE PROCEDURE sp_verificar_documento(
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
      -- Solo los totales: la relación de docentes no se expone
      SELECT r.id_proceso, CONCAT(r.estado, ''), r.fecha_resolucion, r.numero_resolucion, r.hash_integridad,
             SHA2(r.contenido_json, 256),
             JSON_OBJECT('tipo', 'RESOLUCION_MULTAS', 'resolucion', r.numero_resolucion, 'omisos_votacion', r.omisos_votacion,
                         'omisos_mesa', r.omisos_mesa, 'monto_total', r.monto_total, 'uit', r.uit_referencia,
                         'pct_elector', r.pct_elector, 'pct_miembro', r.pct_miembro)
        INTO v_proceso, v_estado, v_fecha, v_res_num, v_hash, v_calc, v_contenido
        FROM reporte_multas r WHERE r.id_reporte = v_id;
    ELSEIF v_tipo = 'CONSTANCIA_VOTO' THEN
      -- La constancia no tiene contenido con huella: vale si está vigente. Nunca dice por quién votó.
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

  INSERT INTO verificacion_documento (codigo_hash, metodo, canal, tipo_documento, id_documento, id_proceso, id_mesa,
                                      resultado, id_usuario, rol, ip, fecha)
  VALUES (SHA2(COALESCE(v_codigo, LEFT(COALESCE(p_codigo, ''), 200)), 256), v_metodo, v_canal, v_tipo, v_id, v_proceso, v_mesa,
          v_resultado, IF(v_rol IS NULL, NULL, p_id_usuario), v_rol, LEFT(p_ip, 45), NOW());
  SET v_id_verif = LAST_INSERT_ID();

  -- 11 mostrarAutenticidad()
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
END$$

-- Cotejo del ejemplar físico con el documento digital (RF55). La aplicación arma p_cifras_json con
-- las cifras del documento digital ("digital") y las anotadas del ejemplar ("fisico"):
--   [{"clave": "...", "etiqueta": "...", "digital": 15, "fisico": 15}, ...]
-- El procedimiento vuelve a localizar el documento, recalcula su huella y cuenta las diferencias.
CREATE PROCEDURE sp_registrar_cotejo_acta(
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

  -- Cifras anotadas del ejemplar físico
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

  -- Personero acreditado de una lista del proceso (de esa mesa o general)
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
END$$

-- El CEUNP atiende la discrepancia reportada: ACLARADA (el ejemplar se anotó o leyó mal, o la
-- diferencia ya se resolvió en el cómputo) o FUNDADA (procede la revisión: calificación del acta,
-- CUS14, o nulidad, CUS15). La respuesta no se modifica.
CREATE PROCEDURE sp_atender_cotejo_acta(
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
END$$

DELIMITER ;

-- =====================================================================
-- 5h. CUS18 · Administrar usuarios y parámetros (cuentas con docente verificado, catálogo e
--     historial de parámetros, parámetros de seguridad y registro de respaldos de la base)
-- (en una base ya instalada sin este CUS se aplica 17_administracion_usuarios_parametros.sql)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Columnas nuevas de usuario y su clave foránea: ya vienen en su CREATE TABLE (sección 2)
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- 2. Tablas nuevas
-- ---------------------------------------------------------------------

-- 5 modificarParametro(): catálogo que describe cada parámetro de parametro_global para validarlo
-- y mostrarlo agrupado. No tiene FK: una definición sin parámetro simplemente no se muestra.
CREATE TABLE parametro_definicion (
  clave           VARCHAR(80)  NOT NULL PRIMARY KEY,
  grupo           ENUM('MULTAS','JORNADA','CEUNP','SEGURIDAD') NOT NULL,
  etiqueta        VARCHAR(120) NOT NULL,
  tipo            ENUM('DECIMAL','ENTERO','HORA','INDICADOR','TEXTO') NOT NULL,
  minimo          DECIMAL(12,2) NULL,             -- en TEXTO: longitud mínima
  maximo          DECIMAL(12,2) NULL,             -- en TEXTO: longitud máxima
  unidad          VARCHAR(30)  NULL,
  referencia      VARCHAR(80)  NULL,              -- norma o requisito que lo exige
  bloqueo_jornada BOOLEAN      NOT NULL DEFAULT FALSE,  -- no se cambia con un proceso en votación
  orden           INT          NOT NULL DEFAULT 0,
  CONSTRAINT chk_param_def_rango CHECK (minimo IS NULL OR maximo IS NULL OR minimo <= maximo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8 registrarAuditoria(): historia de cada parámetro. La escribe el trigger de parametro_global,
-- así queda también el cambio hecho directamente en la base. No se modifica ni se borra.
CREATE TABLE parametro_historial (
  id_historial   BIGINT AUTO_INCREMENT PRIMARY KEY,
  clave          VARCHAR(80)  NOT NULL,
  valor_anterior VARCHAR(255) NULL,
  valor_nuevo    VARCHAR(255) NOT NULL,
  motivo         VARCHAR(500) NULL,
  origen         ENUM('PANTALLA','RESTAURACION','BASE_DATOS') NOT NULL DEFAULT 'BASE_DATOS',
  id_usuario     INT NULL,
  ip             VARCHAR(45) NULL,
  fecha          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_param_hist_clave (clave, fecha),
  CONSTRAINT fk_param_hist_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11 generarRespaldo() · 12 registrarAuditoria(): una fila por respaldo generado, con la huella
-- SHA-256 del archivo para comprobar después que no fue alterado. No se modifica ni se borra.
CREATE TABLE respaldo_bd (
  id_respaldo    INT AUTO_INCREMENT PRIMARY KEY,
  nombre_archivo VARCHAR(150) NOT NULL,
  motivo         VARCHAR(300) NULL,
  tablas         INT    NOT NULL DEFAULT 0,
  vistas         INT    NOT NULL DEFAULT 0,
  rutinas        INT    NOT NULL DEFAULT 0,
  disparadores   INT    NOT NULL DEFAULT 0,
  filas          BIGINT NOT NULL DEFAULT 0,
  tamano_bytes   BIGINT NOT NULL DEFAULT 0,
  hash_sha256    CHAR(64) NOT NULL,
  id_usuario     INT NOT NULL,
  ip             VARCHAR(45) NULL,
  fecha_inicio   DATETIME NOT NULL,
  fecha_fin      DATETIME NOT NULL,
  UNIQUE KEY uq_respaldo_archivo (nombre_archivo),
  KEY ix_respaldo_fecha (fecha_fin),
  CONSTRAINT chk_respaldo_hash CHECK (hash_sha256 REGEXP '^[0-9a-f]{64}$'),
  CONSTRAINT chk_respaldo_fechas CHECK (fecha_fin >= fecha_inicio),
  CONSTRAINT fk_respaldo_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 3. Parámetros nuevos y catálogo de parámetros
-- ---------------------------------------------------------------------
-- (Se cargan en la sección 6, junto con los demás parámetros.)

-- ---------------------------------------------------------------------
-- 4. Funciones
-- ---------------------------------------------------------------------

DELIMITER $$

-- Hay jornada electoral en curso cuando algún proceso está en votación: entonces no se cambian
-- los parámetros marcados con bloqueo_jornada (horarios, mesas y lugar de sufragio).
CREATE FUNCTION fn_jornada_en_curso() RETURNS TINYINT
READS SQL DATA
BEGIN
  RETURN EXISTS (SELECT 1 FROM proceso_electoral WHERE estado = 'VOTACION');
END$$

-- 7 actualizarParametro(): valida el valor según parametro_definicion. Devuelve el motivo del
-- rechazo o NULL si es válido. Un parámetro sin definición no se valida (compatibilidad).
CREATE FUNCTION fn_validar_parametro(p_clave VARCHAR(80), p_valor VARCHAR(255)) RETURNS VARCHAR(300)
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

  -- Coherencia del horario de instalación (RN07, RF58)
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
END$$

-- 2 verificarDocente(): reglas para asociar una cuenta a un docente. Devuelve el motivo del
-- rechazo o NULL. p_id_usuario es la cuenta que se edita (NULL al crear).
CREATE FUNCTION fn_error_docente_usuario(p_id_docente INT, p_rol VARCHAR(20), p_id_usuario INT) RETURNS VARCHAR(300)
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
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- 5. Triggers
-- ---------------------------------------------------------------------

DELIMITER $$

-- Siempre debe quedar al menos un administrador activo (no se desactiva, degrada ni elimina el último)
CREATE TRIGGER trg_usuario_admin_bu BEFORE UPDATE ON usuario
FOR EACH ROW
BEGIN
  IF OLD.rol = 'ADMIN' AND OLD.activo = 1 AND (NEW.rol <> 'ADMIN' OR NEW.activo = 0)
     AND NOT EXISTS (SELECT 1 FROM usuario WHERE rol = 'ADMIN' AND activo = 1 AND id_usuario <> OLD.id_usuario) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: debe quedar al menos un administrador activo.';
  END IF;
END$$

CREATE TRIGGER trg_usuario_admin_bd BEFORE DELETE ON usuario
FOR EACH ROW
BEGIN
  IF OLD.rol = 'ADMIN' AND OLD.activo = 1
     AND NOT EXISTS (SELECT 1 FROM usuario WHERE rol = 'ADMIN' AND activo = 1 AND id_usuario <> OLD.id_usuario) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: debe quedar al menos un administrador activo.';
  END IF;
END$$

-- 7 actualizarParametro(): todo valor nuevo se valida, venga de la pantalla o de la base
CREATE TRIGGER trg_parametro_global_bu BEFORE UPDATE ON parametro_global
FOR EACH ROW
BEGIN
  DECLARE v_error VARCHAR(300);
  IF NOT (NEW.valor <=> OLD.valor) THEN
    SET v_error = fn_validar_parametro(NEW.clave, NEW.valor);
    IF v_error IS NOT NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
  END IF;
END$$

-- 8 registrarAuditoria(): la historia del parámetro. sp_actualizar_parametro informa quién, por qué
-- y desde dónde con variables de sesión; sin ellas el cambio se hizo directamente en la base.
CREATE TRIGGER trg_parametro_global_au AFTER UPDATE ON parametro_global
FOR EACH ROW
BEGIN
  IF NOT (NEW.valor <=> OLD.valor) THEN
    INSERT INTO parametro_historial (clave, valor_anterior, valor_nuevo, motivo, origen, id_usuario, ip)
    VALUES (NEW.clave, OLD.valor, NEW.valor,
            COALESCE(@cus18_motivo, 'Cambio realizado directamente en la base de datos'),
            COALESCE(@cus18_origen, 'BASE_DATOS'), @cus18_id_usuario, @cus18_ip);
  END IF;
END$$

CREATE TRIGGER trg_param_hist_bu BEFORE UPDATE ON parametro_historial
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: el historial de parámetros es inmutable.';
END$$

CREATE TRIGGER trg_param_hist_bd BEFORE DELETE ON parametro_historial
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: el historial de parámetros es inmutable.';
END$$

CREATE TRIGGER trg_respaldo_bu BEFORE UPDATE ON respaldo_bd
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: el registro de respaldos es inmutable.';
END$$

CREATE TRIGGER trg_respaldo_bd BEFORE DELETE ON respaldo_bd
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: el registro de respaldos es inmutable.';
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- 6. Vistas
-- ---------------------------------------------------------------------

-- 4 mostrarUsuario(): cuentas con su docente, estado, bloqueo y actividad en la bitácora
CREATE VIEW v_usuarios_admin AS
SELECT u.id_usuario, u.username, CONCAT(u.rol, '') AS rol, u.activo, u.debe_cambiar_password,
       u.intentos_fallidos, u.bloqueado_hasta,
       (u.bloqueado_hasta IS NOT NULL AND u.bloqueado_hasta > NOW()) AS bloqueada,
       u.ultimo_acceso, u.fecha_creacion, u.fecha_actualizacion, u.motivo_estado,
       u.id_usuario_creador, c.username AS creado_por,
       u.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS docente,
       CONCAT(d.estado, '') AS estado_docente, CONCAT(d.categoria, '') AS categoria, d.email,
       f.nombre AS facultad, dp.nombre AS departamento,
       (SELECT COUNT(*) FROM log_auditoria l WHERE l.id_usuario = u.id_usuario) AS actividad
  FROM usuario u
  LEFT JOIN usuario c       ON c.id_usuario = u.id_usuario_creador
  LEFT JOIN docente d       ON d.id_docente = u.id_docente
  LEFT JOIN facultad f      ON f.id_facultad = d.id_facultad
  LEFT JOIN departamento dp ON dp.id_departamento = d.id_departamento;

-- 5 modificarParametro(): parámetros con su definición y su último cambio
CREATE VIEW v_parametros_admin AS
SELECT p.clave, p.valor, p.descripcion,
       COALESCE(CONCAT(d.grupo, ''), 'OTROS') AS grupo, COALESCE(d.etiqueta, p.clave) AS etiqueta,
       COALESCE(CONCAT(d.tipo, ''), 'TEXTO') AS tipo, d.minimo, d.maximo, d.unidad, d.referencia,
       COALESCE(d.bloqueo_jornada, 0) AS bloqueo_jornada, COALESCE(d.orden, 999) AS orden,
       (COALESCE(d.bloqueo_jornada, 0) = 1 AND fn_jornada_en_curso() = 1) AS bloqueado,
       (SELECT COUNT(*) FROM parametro_historial h WHERE h.clave = p.clave) AS cambios,
       (SELECT MAX(h.fecha) FROM parametro_historial h WHERE h.clave = p.clave) AS fecha_ultimo_cambio,
       (SELECT u.username FROM parametro_historial h LEFT JOIN usuario u ON u.id_usuario = h.id_usuario
         WHERE h.clave = p.clave ORDER BY h.fecha DESC, h.id_historial DESC LIMIT 1) AS modificado_por
  FROM parametro_global p
  LEFT JOIN parametro_definicion d ON d.clave = p.clave;

-- 8 registrarAuditoria(): historial de parámetros con el usuario
CREATE VIEW v_parametro_historial AS
SELECT h.id_historial, h.clave, COALESCE(d.etiqueta, h.clave) AS etiqueta, d.unidad,
       h.valor_anterior, h.valor_nuevo, h.motivo, CONCAT(h.origen, '') AS origen,
       h.id_usuario, u.username, h.ip, h.fecha
  FROM parametro_historial h
  LEFT JOIN parametro_definicion d ON d.clave = h.clave
  LEFT JOIN usuario u              ON u.id_usuario = h.id_usuario;

-- 13 mostrarRespaldo(): respaldos generados
CREATE VIEW v_respaldos AS
SELECT r.id_respaldo, r.nombre_archivo, r.motivo, r.tablas, r.vistas,
       r.rutinas, r.disparadores, r.filas, r.tamano_bytes, r.hash_sha256, r.id_usuario, u.username,
       r.ip, r.fecha_inicio, r.fecha_fin, TIMESTAMPDIFF(SECOND, r.fecha_inicio, r.fecha_fin) AS duracion_seg
  FROM respaldo_bd r
  JOIN usuario u ON u.id_usuario = r.id_usuario;

-- ---------------------------------------------------------------------
-- 7. Procedimientos
-- ---------------------------------------------------------------------

DELIMITER $$

-- Solo un administrador activo administra cuentas, parámetros y respaldos
CREATE PROCEDURE sp_validar_admin(IN p_id_usuario INT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM usuario WHERE id_usuario = p_id_usuario AND rol = 'ADMIN' AND activo = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS18: solo un administrador activo puede realizar esta operación.';
  END IF;
END$$

-- 2 verificarDocente(): datos del docente, sus cuentas y si cumple las reglas para el rol.
-- No modifica datos. error: impide crear la cuenta; advertencia: se informa pero no impide.
CREATE PROCEDURE sp_verificar_docente_usuario(IN p_id_docente INT, IN p_rol VARCHAR(20), IN p_id_usuario INT)
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
END$$

-- 1.1 crearUsuario() · 3 insertarUsuario(): la contraseña llega ya cifrada con BCrypt (backend)
CREATE PROCEDURE sp_crear_usuario(
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
  -- 2 verificarDocente()
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

  -- 4 mostrarUsuario()
  SELECT * FROM v_usuarios_admin WHERE id_usuario = v_id;
END$$

-- Cambio de rol o de docente asociado
CREATE PROCEDURE sp_actualizar_usuario(
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
END$$

-- Activar o desactivar una cuenta (nunca se pierde su historia). Desactivar exige el motivo.
CREATE PROCEDURE sp_cambiar_estado_usuario(
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
END$$

-- Contraseña provisional: el usuario debe cambiarla al ingresar. También levanta el bloqueo.
CREATE PROCEDURE sp_restablecer_password(
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
END$$

-- Levanta el bloqueo por intentos fallidos sin cambiar la contraseña
CREATE PROCEDURE sp_desbloquear_usuario(IN p_id_admin INT, IN p_id_usuario INT)
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
END$$

-- Elimina una cuenta sin actividad (creada por error). Con actividad registrada la base lo impide
-- (RN28: la bitácora conserva quién hizo cada acción): entonces se desactiva.
CREATE PROCEDURE sp_eliminar_usuario(IN p_id_admin INT, IN p_id_usuario INT)
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
END$$

-- 6 actualizar() · 7 actualizarParametro() · 8 registrarAuditoria() · 9 confirmarCambio().
-- p_origen: PANTALLA o RESTAURACION (volver a un valor del historial).
CREATE PROCEDURE sp_actualizar_parametro(
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

  -- 9 confirmarCambio()
  SELECT p_clave AS clave, COALESCE(v_etq, p_clave) AS etiqueta, v_anterior AS valor_anterior, v_valor AS valor_nuevo,
         (SELECT MAX(id_historial) FROM parametro_historial WHERE clave = p_clave) AS id_historial, NOW() AS fecha;
END$$

-- 12 registrarAuditoria(): registra el respaldo que generó el backend (11 generarRespaldo)
CREATE PROCEDURE sp_registrar_respaldo(
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

  -- 13 mostrarRespaldo()
  SELECT * FROM v_respaldos WHERE id_respaldo = v_id;
END$$

DELIMITER ;

-- =====================================================================
-- 5i. CUS19 · Consultar bitácora (catálogo de acciones, sello SHA-256 encadenado de cada
--     registro, detalle, verificación de la cadena y registro de exportaciones)
-- (en una base ya instalada sin este CUS se aplica 18_consultar_bitacora.sql)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Sello encadenado e índices de log_auditoria: ya vienen en su CREATE TABLE (sección 2)
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- 2. Tablas nuevas
-- ---------------------------------------------------------------------

-- 4 consultar() · 5 mostrarRegistros(): catálogo de los códigos de acción de la bitácora. No tiene FK
-- con log_auditoria: un código nuevo sin catálogo se sigue registrando y se muestra «sin clasificar».
CREATE TABLE bitacora_accion (
  codigo      VARCHAR(100) NOT NULL PRIMARY KEY,
  etiqueta    VARCHAR(120) NOT NULL,
  descripcion VARCHAR(300) NULL,
  modulo      ENUM('SEGURIDAD','ADMINISTRACION','PREPARACION','JORNADA','ESCRUTINIO','RESULTADOS','RECURSOS','MULTAS')
              NOT NULL,
  caso_uso    VARCHAR(20)  NULL,             -- CUS que la registra (CUS01 … CUS19)
  criticidad  ENUM('BAJA','MEDIA','ALTA','CRITICA') NOT NULL DEFAULT 'BAJA',
  orden       INT NOT NULL DEFAULT 0,
  KEY ix_bitacora_accion_modulo (modulo, orden)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Sello vigente de la cadena: último registro sellado y total desde el último reinicio. Una sola
-- fila (id_cadena = 1). trg_log_bi la bloquea (FOR UPDATE) para encadenar en orden aunque haya
-- inserciones simultáneas, y sp_verificar_bitacora la compara con el último registro.
CREATE TABLE bitacora_cadena (
  id_cadena           TINYINT  NOT NULL PRIMARY KEY,
  ultimo_id_log       BIGINT   NULL,
  ultimo_hash         CHAR(64) NOT NULL,
  total_registros     BIGINT   NOT NULL DEFAULT 0,
  fecha_inicio        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,   -- inicio de la cadena (instalación o reinicio)
  fecha_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_bitacora_cadena_unica CHECK (id_cadena = 1),
  CONSTRAINT chk_bitacora_cadena_hash CHECK (ultimo_hash REGEXP '^[0-9a-f]{64}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 3. Catálogo de acciones y parámetro nuevo
-- ---------------------------------------------------------------------
INSERT INTO bitacora_accion (codigo, etiqueta, descripcion, modulo, caso_uso, criticidad, orden) VALUES
  -- Seguridad del acceso
  ('LOGIN_SUCCESS',                  'Inicio de sesión',                      'Ingreso correcto al sistema con usuario y contraseña.', 'SEGURIDAD', 'CUS01', 'BAJA', 10),
  ('LOGIN_FAILED',                   'Inicio de sesión fallido',              'Contraseña incorrecta, cuenta inactiva o bloqueada por intentos.', 'SEGURIDAD', 'CUS01', 'MEDIA', 20),
  -- Administración (CUS18) y bitácora (CUS19)
  ('CREAR_USUARIO',                  'Cuenta creada',                         'Alta de una cuenta con su rol y, si corresponde, su docente.', 'ADMINISTRACION', 'CUS18', 'MEDIA', 10),
  ('ACTUALIZAR_USUARIO',             'Rol o docente de la cuenta modificado', 'Cambio del rol o del docente asociado a la cuenta.', 'ADMINISTRACION', 'CUS18', 'ALTA', 20),
  ('ACTIVAR_USUARIO',                'Cuenta activada',                       'La cuenta vuelve a poder iniciar sesión.', 'ADMINISTRACION', 'CUS18', 'MEDIA', 30),
  ('DESACTIVAR_USUARIO',             'Cuenta desactivada',                    'La cuenta no puede iniciar sesión; conserva su historia.', 'ADMINISTRACION', 'CUS18', 'ALTA', 40),
  ('RESTABLECER_PASSWORD',           'Contraseña restablecida',               'El administrador asignó una contraseña provisional.', 'ADMINISTRACION', 'CUS18', 'ALTA', 50),
  ('DESBLOQUEAR_USUARIO',            'Cuenta desbloqueada',                   'Se pusieron en cero los intentos fallidos.', 'ADMINISTRACION', 'CUS18', 'MEDIA', 60),
  ('ELIMINAR_USUARIO',               'Cuenta eliminada',                      'Eliminación de una cuenta sin actividad (RN28).', 'ADMINISTRACION', 'CUS18', 'ALTA', 70),
  ('CAMBIO_PARAMETRO',               'Parámetro modificado',                  'Cambio o restauración de un parámetro del reglamento o del sistema.', 'ADMINISTRACION', 'CUS18', 'ALTA', 80),
  ('GENERAR_RESPALDO',               'Respaldo de la base generado',          'Copia completa de la base con su huella SHA-256.', 'ADMINISTRACION', 'CUS18', 'MEDIA', 90),
  ('DESCARGAR_RESPALDO',             'Respaldo de la base descargado',        'Descarga del archivo de respaldo (contiene datos personales).', 'ADMINISTRACION', 'CUS18', 'ALTA', 100),
  ('VERIFICAR_RESPALDO',             'Integridad del respaldo verificada',    'Se recalculó la huella SHA-256 del archivo de respaldo.', 'ADMINISTRACION', 'CUS18', 'BAJA', 110),
  ('VERIFICAR_BITACORA',             'Integridad de la bitácora verificada',  'Se recalcularon los sellos encadenados de todos los registros.', 'ADMINISTRACION', 'CUS19', 'BAJA', 120),
  ('EXPORTAR_BITACORA',              'Bitácora exportada',                    'Descarga de registros de la bitácora en un archivo CSV.', 'ADMINISTRACION', 'CUS19', 'MEDIA', 130),
  ('REINICIAR_BITACORA',             'Bitácora reiniciada',                   'Se vaciaron los datos electorales y la bitácora (02_limpiar_datos_electorales.sql).', 'ADMINISTRACION', 'CUS19', 'CRITICA', 140),
  -- Preparación del proceso (CUS01-CUS07)
  ('CREAR_PROCESO',                  'Proceso electoral creado',              'Registro de una convocatoria.', 'PREPARACION', 'CUS01', 'MEDIA', 10),
  ('PUBLICAR_CONVOCATORIA',          'Convocatoria publicada',                'La convocatoria y su cronograma quedan públicos.', 'PREPARACION', 'CUS01', 'ALTA', 20),
  ('ACTUALIZAR_CRONOGRAMA',          'Cronograma actualizado',                'Cambio de las fechas del cronograma electoral.', 'PREPARACION', 'CUS01', 'MEDIA', 30),
  ('AGREGAR_CARGO',                  'Cargo agregado al proceso',             'Se agregó un cargo a elegir.', 'PREPARACION', 'CUS01', 'MEDIA', 40),
  ('QUITAR_CARGO',                   'Cargo quitado del proceso',             'Se quitó un cargo a elegir.', 'PREPARACION', 'CUS01', 'MEDIA', 50),
  ('CAMBIO_ESTADO_PROCESO',          'Estado del proceso cambiado',           'El proceso pasó a otra etapa del cronograma.', 'PREPARACION', 'CUS01', 'ALTA', 60),
  ('ANULAR_PROCESO',                 'Proceso anulado',                       'El proceso electoral fue anulado.', 'PREPARACION', 'CUS01', 'CRITICA', 70),
  ('IMPORTAR_DOCENTES',              'Docentes importados',                   'Carga masiva del padrón de docentes desde Excel o CSV.', 'PREPARACION', 'CUS02', 'MEDIA', 80),
  ('DEPURAR_PADRON',                 'Padrón depurado',                       'Se filtraron los docentes habilitados para votar.', 'PREPARACION', 'CUS02', 'ALTA', 90),
  ('GENERAR_PADRON',                 'Padrón electoral generado',             'Padrón del proceso aprobado.', 'PREPARACION', 'CUS02', 'ALTA', 100),
  ('INSCRIBIR_LISTA',                'Lista inscrita',                        'Inscripción de una lista de candidatos.', 'PREPARACION', 'CUS03', 'MEDIA', 110),
  ('INSCRIBIR_CANDIDATO',            'Candidato inscrito',                    'Se agregó un candidato a una lista.', 'PREPARACION', 'CUS03', 'BAJA', 120),
  ('QUITAR_CANDIDATO',               'Candidato quitado',                     'Se quitó un candidato de una lista.', 'PREPARACION', 'CUS03', 'MEDIA', 130),
  ('RETIRAR_LISTA',                  'Lista retirada',                        'La lista se retiró del proceso.', 'PREPARACION', 'CUS03', 'ALTA', 140),
  ('VALIDAR_LISTA',                  'Lista calificada',                      'El CEUNP admitió u observó la lista.', 'PREPARACION', 'CUS03', 'ALTA', 150),
  ('PRESENTAR_TACHA',                'Tacha presentada',                      'Tacha contra una lista o un candidato.', 'PREPARACION', 'CUS04', 'MEDIA', 160),
  ('RESOLVER_TACHA',                 'Tacha resuelta',                        'El CEUNP declaró fundada o infundada la tacha.', 'PREPARACION', 'CUS04', 'ALTA', 170),
  ('ACREDITAR_PERSONERO',            'Personero acreditado',                  'Acreditación de un personero de lista.', 'PREPARACION', 'CUS05', 'MEDIA', 180),
  ('REVOCAR_PERSONERO',              'Personero revocado',                    'Se revocó la acreditación del personero.', 'PREPARACION', 'CUS05', 'ALTA', 190),
  ('CREAR_MESAS',                    'Mesas de sufragio creadas',             'Conformación de las mesas según el padrón.', 'PREPARACION', 'CUS06', 'MEDIA', 200),
  ('SORTEO_MESA',                    'Sorteo de miembros de una mesa',        'Sorteo de titulares y suplentes de una mesa.', 'PREPARACION', 'CUS06', 'ALTA', 210),
  ('SORTEO_GENERAL_MESAS',           'Sorteo general de miembros de mesa',    'Sorteo de los miembros de todas las mesas.', 'PREPARACION', 'CUS06', 'ALTA', 220),
  ('SORTEO_ORDEN_CEDULA',            'Sorteo del orden en la cédula',         'Orden de las listas en la cédula de votación.', 'PREPARACION', 'CUS06', 'ALTA', 230),
  ('EMITIR_CREDENCIAL',              'Credencial QR emitida',                 'Emisión de una credencial con código QR.', 'PREPARACION', 'CUS07', 'BAJA', 240),
  ('REVOCAR_CREDENCIAL',             'Credencial QR revocada',                'La credencial deja de ser válida.', 'PREPARACION', 'CUS07', 'ALTA', 250),
  ('VERIFICAR_CREDENCIAL',           'Credencial QR verificada',              'Lectura y comprobación de una credencial.', 'PREPARACION', 'CUS07', 'BAJA', 260),
  ('CONSULTA_PUBLICA_CREDENCIAL',    'Credencial QR consultada (pública)',    'Apertura de la página pública de una credencial al escanear su QR.', 'PREPARACION', 'CUS07', 'BAJA', 261),
  ('RECIBIR_CREDENCIAL_PERSONERO',   'Credencial de personero recibida',      'El personero recibió su credencial.', 'PREPARACION', 'CUS07', 'BAJA', 270),
  -- Jornada electoral (CUS08-CUS11)
  ('REGISTRAR_LLEGADA_MIEMBRO',      'Llegada de miembro de mesa',            'Registro de la hora de llegada del miembro.', 'JORNADA', 'CUS08', 'BAJA', 10),
  ('REGISTRAR_REEMPLAZANTE_MESA',    'Reemplazante de mesa registrado',       'Un elector reemplaza a un miembro ausente.', 'JORNADA', 'CUS08', 'MEDIA', 20),
  ('QUITAR_REEMPLAZANTE_MESA',       'Reemplazante de mesa quitado',          'Se quitó al reemplazante registrado.', 'JORNADA', 'CUS08', 'MEDIA', 30),
  ('VERIFICAR_MATERIAL_MESA',        'Material electoral verificado',         'Revisión del material de la mesa.', 'JORNADA', 'CUS08', 'BAJA', 40),
  ('INCIDENCIA_MESA',                'Incidencia de mesa',                    'Incidencia registrada durante la instalación o el sufragio.', 'JORNADA', 'CUS08', 'MEDIA', 50),
  ('INSTALAR_MESA',                  'Mesa instalada',                        'Acta de instalación de la mesa.', 'JORNADA', 'CUS08', 'ALTA', 60),
  ('MESA_NO_INSTALADA',              'Mesa no instalada',                     'Venció la hora límite sin instalar la mesa (RF58).', 'JORNADA', 'CUS08', 'ALTA', 70),
  ('IDENTIFICAR_ELECTOR',            'Elector identificado',                  'Identificación del elector en la mesa.', 'JORNADA', 'CUS09', 'BAJA', 80),
  ('VERIFICAR_ELECTOR',              'Elector verificado',                    'El elector figura en el padrón de la mesa.', 'JORNADA', 'CUS09', 'BAJA', 90),
  ('REGISTRAR_ASISTENCIA',           'Asistencia del elector registrada',     'El elector firmó la lista de la mesa.', 'JORNADA', 'CUS09', 'BAJA', 100),
  ('CONECTAR_TERMINAL',              'Terminal de votación conectada',        'Se habilitó una terminal para un elector.', 'JORNADA', 'CUS10', 'MEDIA', 110),
  ('LIBERAR_TERMINAL',               'Terminal de votación liberada',         'La terminal quedó libre.', 'JORNADA', 'CUS10', 'BAJA', 120),
  ('EMITIR_VOTO',                    'Voto emitido',                          'El elector votó. Nunca se registra por quién (RNF05).', 'JORNADA', 'CUS10', 'BAJA', 130),
  ('MARCAR_NO_VOTO',                 'Elector marcado sin votar',             'Elector ausente al cierre del sufragio.', 'JORNADA', 'CUS11', 'MEDIA', 140),
  ('CERRAR_MESA',                    'Mesa cerrada',                          'Cierre de la votación en la mesa.', 'JORNADA', 'CUS11', 'ALTA', 150),
  ('CERRAR_SUFRAGIO',                'Sufragio cerrado',                      'Cierre del sufragio de la mesa.', 'JORNADA', 'CUS11', 'ALTA', 160),
  ('EMITIR_ACTA_SUFRAGIO',           'Acta de sufragio emitida',              'Acta de sufragio con su huella SHA-256.', 'JORNADA', 'CUS11', 'ALTA', 170),
  -- Escrutinio (CUS12)
  ('CONTAR_CEDULAS',                 'Cédulas contadas',                      'Conteo de las cédulas de la mesa.', 'ESCRUTINIO', 'CUS12', 'MEDIA', 10),
  ('REGISTRAR_CONTEO_ESCRUTINIO',    'Conteo del escrutinio registrado',      'Conteo manual conciliado con el digital.', 'ESCRUTINIO', 'CUS12', 'ALTA', 20),
  ('EMITIR_ACTA_ESCRUTINIO',         'Acta de escrutinio emitida',            'Acta de escrutinio con su huella SHA-256.', 'ESCRUTINIO', 'CUS12', 'ALTA', 30),
  ('ENTREGAR_ACTAS',                 'Actas entregadas al CEUNP',             'Entrega de las actas de la mesa.', 'ESCRUTINIO', 'CUS12', 'ALTA', 40),
  ('EVALUAR_NULIDAD_MESA',           'Nulidad de mesa evaluada',              'Evaluación de causales de nulidad en la mesa.', 'ESCRUTINIO', 'CUS12', 'ALTA', 50),
  -- Impugnaciones y nulidades (CUS13, CUS15)
  ('REGISTRAR_IMPUGNACION',          'Impugnación registrada',                'Impugnación de un voto en la mesa.', 'RECURSOS', 'CUS13', 'MEDIA', 10),
  ('RESOLVER_IMPUGNACION_MESA',      'Impugnación resuelta por la mesa',      'Decisión de la mesa sobre la impugnación.', 'RECURSOS', 'CUS13', 'ALTA', 20),
  ('APELAR_IMPUGNACION',             'Impugnación apelada',                   'Apelación ante el CEUNP.', 'RECURSOS', 'CUS13', 'MEDIA', 30),
  ('RESOLVER_APELACION',             'Apelación resuelta',                    'Fallo del Pleno del CEUNP.', 'RECURSOS', 'CUS13', 'ALTA', 40),
  ('REGISTRAR_RECURSO_NULIDAD',      'Recurso de nulidad presentado',         'Pedido de nulidad parcial o total.', 'RECURSOS', 'CUS15', 'MEDIA', 50),
  ('DESESTIMAR_NULIDAD',             'Nulidad desestimada',                   'El Pleno declaró infundado o improcedente el recurso.', 'RECURSOS', 'CUS15', 'ALTA', 60),
  ('DECLARAR_NULIDAD_PARCIAL',       'Nulidad parcial declarada',             'Se anularon los votos de una mesa.', 'RECURSOS', 'CUS15', 'CRITICA', 70),
  ('DECLARAR_NULIDAD_TOTAL',         'Nulidad total declarada',               'La elección fue declarada nula.', 'RECURSOS', 'CUS15', 'CRITICA', 80),
  ('REGISTRAR_COMUNICACION_NULIDAD', 'Comunicación de nulidad registrada',    'Comunicación de la nulidad a los órganos de gobierno.', 'RECURSOS', 'CUS15', 'MEDIA', 90),
  ('DIRIMIR_EMPATE',                 'Empate dirimido',                       'Sorteo para dirimir un empate.', 'RECURSOS', 'CUS15', 'CRITICA', 100),
  -- Cómputo y resultados (CUS14, CUS17)
  ('INSTALAR_SESION_COMPUTO',        'Sesión de cómputo instalada',           'El Pleno instaló la sesión de cómputo.', 'RESULTADOS', 'CUS14', 'ALTA', 10),
  ('REGISTRAR_PERSONERO_COMPUTO',    'Personero en el cómputo',               'Asistencia de un personero al cómputo.', 'RESULTADOS', 'CUS14', 'BAJA', 20),
  ('MARCAR_ACTA_DUDOSA',             'Acta marcada como dudosa',              'El acta requiere comprobación.', 'RESULTADOS', 'CUS14', 'ALTA', 30),
  ('COMPROBAR_ACTA',                 'Acta comprobada',                       'Comprobación del acta contra su huella.', 'RESULTADOS', 'CUS14', 'MEDIA', 40),
  ('CALIFICAR_ACTA',                 'Acta calificada',                       'Calificación del acta en el cómputo.', 'RESULTADOS', 'CUS14', 'ALTA', 50),
  ('DECLARAR_NULIDAD_MESA',          'Mesa anulada en el cómputo',            'La calificación declaró nula la mesa.', 'RESULTADOS', 'CUS14', 'CRITICA', 60),
  ('COMPUTAR_RESULTADOS',            'Resultados computados',                 'Cómputo general de la elección.', 'RESULTADOS', 'CUS14', 'CRITICA', 70),
  ('PROCLAMAR_RESULTADOS',           'Resultados proclamados',                'Proclamación de las listas ganadoras.', 'RESULTADOS', 'CUS14', 'CRITICA', 80),
  ('PUBLICAR_RESULTADOS',            'Resultados publicados',                 'Publicación en el portal de resultados.', 'RESULTADOS', 'CUS14', 'CRITICA', 90),
  ('CREAR_SEGUNDA_VUELTA',           'Segunda vuelta convocada',              'Convocatoria a segunda vuelta (RN33).', 'RESULTADOS', 'CUS14', 'CRITICA', 100),
  ('REGISTRAR_COTEJO_ACTA',          'Acta cotejada conforme',                'El acta física coincide con la digital.', 'RESULTADOS', 'CUS17', 'BAJA', 110),
  ('REPORTAR_DISCREPANCIA_ACTA',     'Discrepancia de acta reportada',        'El acta física no coincide con la digital.', 'RESULTADOS', 'CUS17', 'ALTA', 120),
  ('ATENDER_DISCREPANCIA_ACTA',      'Discrepancia de acta atendida',         'El CEUNP atendió la discrepancia.', 'RESULTADOS', 'CUS17', 'ALTA', 130),
  -- Omisos y multas (CUS16)
  ('GENERAR_MULTAS',                 'Multas generadas',                      'Determinación de multas a omisos (RN35).', 'MULTAS', 'CUS16', 'ALTA', 10),
  ('ACTUALIZAR_MULTA',               'Multa actualizada',                     'Cambio del estado o del monto de la multa.', 'MULTAS', 'CUS16', 'ALTA', 20),
  ('EMITIR_RESOLUCION_MULTAS',       'Resolución de multas emitida',          'Resolución del Pleno con su huella y QR.', 'MULTAS', 'CUS16', 'ALTA', 30),
  ('NOTIFICAR_MULTAS',               'Multas notificadas',                    'Notificación a los multados.', 'MULTAS', 'CUS16', 'MEDIA', 40),
  ('JUSTIFICAR_MULTA',               'Multa justificada',                     'Se aceptó la justificación de la omisión.', 'MULTAS', 'CUS16', 'MEDIA', 50),
  ('DENEGAR_JUSTIFICACION',          'Justificación denegada',                'Se denegó la justificación.', 'MULTAS', 'CUS16', 'MEDIA', 60),
  ('EXONERAR_MULTA',                 'Multa exonerada',                       'Exoneración de la multa.', 'MULTAS', 'CUS16', 'ALTA', 70),
  ('REGISTRAR_PAGO_MULTA',           'Pago de multa registrado',              'Registro del recibo de pago.', 'MULTAS', 'CUS16', 'MEDIA', 80);

-- (Se cargan en la sección 6, junto con los demás parámetros.)

-- ---------------------------------------------------------------------
-- 4. Función del sello
-- ---------------------------------------------------------------------

DELIMITER $$

-- SHA-256 de un registro encadenado al sello del anterior. Cubre todos los campos del registro;
-- cambiar cualquiera (o el orden de la cadena) cambia el sello.
CREATE FUNCTION fn_hash_bitacora(p_hash_anterior CHAR(64), p_id_usuario INT, p_id_docente INT, p_id_proceso INT,
                                 p_accion VARCHAR(100), p_ip VARCHAR(45), p_user_agent VARCHAR(500),
                                 p_fecha DATETIME, p_detalle LONGTEXT) RETURNS CHAR(64)
DETERMINISTIC NO SQL
BEGIN
  RETURN SHA2(CONCAT_WS('|',
           COALESCE(p_hash_anterior, ''), COALESCE(p_id_usuario, ''), COALESCE(p_id_docente, ''),
           COALESCE(p_id_proceso, ''), COALESCE(p_accion, ''), COALESCE(p_ip, ''), COALESCE(p_user_agent, ''),
           COALESCE(DATE_FORMAT(p_fecha, '%Y-%m-%d %H:%i:%s'), ''), COALESCE(p_detalle, '')), 256);
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- 5. Triggers (trg_log_bu, que hace inmutable la bitácora, está en la sección 3)
-- ---------------------------------------------------------------------

DELIMITER $$

-- Sello encadenado de cada registro nuevo. El FOR UPDATE sobre bitacora_cadena ordena las
-- inserciones simultáneas: cada una se encadena al sello vigente y lo reemplaza. Si la inserción
-- falla, el cambio del sello se deshace con ella.
CREATE TRIGGER trg_log_bi BEFORE INSERT ON log_auditoria
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
  INSERT INTO bitacora_cadena (id_cadena, ultimo_hash, total_registros, fecha_inicio, fecha_actualizacion)
  VALUES (1, NEW.hash_registro, 1, NOW(), NOW())
  ON DUPLICATE KEY UPDATE ultimo_hash = NEW.hash_registro, total_registros = total_registros + 1,
                          fecha_actualizacion = NOW();
END$$

CREATE TRIGGER trg_log_ai AFTER INSERT ON log_auditoria
FOR EACH ROW
BEGIN
  UPDATE bitacora_cadena SET ultimo_id_log = NEW.id_log WHERE id_cadena = 1;
END$$

DELIMITER ;

-- Cadena vacía (instalación sin registros): sello inicial de ceros.
INSERT INTO bitacora_cadena (id_cadena, ultimo_id_log, ultimo_hash, total_registros)
VALUES (1, NULL, REPEAT('0', 64), 0);

-- ---------------------------------------------------------------------
-- 6. Vista
-- ---------------------------------------------------------------------

-- 4 consultar(filtros) · 5 mostrarRegistros(lista): cada registro con su autor (cuenta, rol y
-- docente de la cuenta), el docente al que se refiere (elector, miembro, candidato), el proceso
-- y la acción catalogada. EMITIR_VOTO solo dice que el docente votó, nunca por quién (RNF05).
CREATE VIEW v_bitacora AS
SELECT l.id_log,
       l.fecha_hora,
       l.accion,
       COALESCE(a.etiqueta, REPLACE(l.accion, '_', ' ')) AS etiqueta,
       a.descripcion                                     AS descripcion_accion,
       COALESCE(a.modulo, 'SIN_CLASIFICAR')              AS modulo,
       a.caso_uso,
       COALESCE(a.criticidad, 'MEDIA')                   AS criticidad,
       (a.codigo IS NOT NULL)                            AS catalogada,
       l.id_usuario,
       u.username,
       u.rol,
       CONCAT(du.apellidos, ', ', du.nombres)            AS usuario_docente,
       l.id_docente,
       CONCAT(d.apellidos, ', ', d.nombres)              AS docente,
       d.dni                                             AS dni_docente,
       l.id_proceso,
       p.nombre                                          AS proceso,
       l.ip_origen,
       l.user_agent,
       l.detalle_json,
       l.hash_anterior,
       l.hash_registro
  FROM log_auditoria l
  LEFT JOIN bitacora_accion a    ON a.codigo = l.accion
  LEFT JOIN usuario u            ON u.id_usuario = l.id_usuario
  LEFT JOIN docente du           ON du.id_docente = u.id_docente
  LEFT JOIN docente d            ON d.id_docente = l.id_docente
  LEFT JOIN proceso_electoral p  ON p.id_proceso = l.id_proceso;

-- ---------------------------------------------------------------------
-- 7. Procedimientos
-- ---------------------------------------------------------------------

DELIMITER $$

-- 7 obtenerDetalle(id_log) → 8 consultarDetalle(id_log): el registro, el anterior y el siguiente de la
-- cadena, y si su sello es válido (contenido sin cambios y enlazado al registro anterior). Solo lectura.
CREATE PROCEDURE sp_detalle_bitacora(IN p_id_admin INT, IN p_id_log BIGINT)
BEGIN
  DECLARE v_ant BIGINT;
  DECLARE v_sig BIGINT;
  DECLARE v_hash_ant CHAR(64);

  -- 3 validarRolAdministrador()
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
         -- El primero de la cadena se enlaza al sello inicial (ceros); los demás, al sello del anterior.
         (l.hash_anterior IS NOT NULL
          AND (l.hash_anterior = v_hash_ant OR (l.hash_anterior = REPEAT('0', 64)
               AND (v_ant IS NULL OR l.accion = 'REINICIAR_BITACORA')))) AS enlace_valido,
         (SELECT COUNT(*) FROM log_auditoria x
           WHERE x.id_usuario = l.id_usuario AND l.id_usuario IS NOT NULL) AS acciones_usuario,
         (SELECT COUNT(*) FROM log_auditoria x
           WHERE x.id_proceso = l.id_proceso AND l.id_proceso IS NOT NULL) AS acciones_proceso
    FROM v_bitacora v JOIN log_auditoria l ON l.id_log = v.id_log
   WHERE v.id_log = p_id_log;
END$$

-- Verifica la cadena completa: recalcula el sello de cada registro, comprueba que esté enlazado al
-- anterior y que el último coincida con bitacora_cadena (registros borrados al final). Devuelve las
-- anomalías (hasta 100) y el resumen en parámetros OUT, y registra VERIFICAR_BITACORA.
--   CONTENIDO_ALTERADO: el registro cambió después de sellarse.
--   ENLACE_ROTO:        falta el registro anterior (borrado) o se insertó uno por fuera de la cadena.
--   SIN_SELLO:          registro escrito sin el trigger trg_log_bi.
--   FINAL_ELIMINADO:    el último registro no es el que indica el sello vigente.
CREATE PROCEDURE sp_verificar_bitacora(IN p_id_admin INT, IN p_ip VARCHAR(45), IN p_user_agent VARCHAR(500),
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

  -- 3 validarRolAdministrador()
  CALL sp_validar_admin(p_id_admin);

  DROP TEMPORARY TABLE IF EXISTS tmp_bitacora_anomalia;
  CREATE TEMPORARY TABLE tmp_bitacora_anomalia (
    id_log  BIGINT NOT NULL,
    tipo    VARCHAR(20) NOT NULL,
    accion  VARCHAR(100) NULL,
    fecha   DATETIME NULL,
    detalle VARCHAR(300) NOT NULL
  ) ENGINE=MEMORY;

  -- La cadena y su sello se leen en la misma instantánea: lo que se inserte mientras tanto no cuenta.
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
      -- Un reinicio documentado (02_limpiar_datos_electorales.sql) empieza una cadena nueva.
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
END$$

-- Deja constancia de una exportación: quién descargó cuántos registros, con qué filtros y desde dónde.
CREATE PROCEDURE sp_registrar_exportacion_bitacora(IN p_id_admin INT, IN p_formato VARCHAR(10), IN p_registros INT,
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
END$$

DELIMITER ;

-- =====================================================================
-- 6. DATOS INICIALES
-- =====================================================================

-- ---------------------------------------------------------------------
-- Parámetros globales (editables desde la pantalla Parámetros)
-- Las tres primeras claves son las que ya usa ParametrosController.java
-- ---------------------------------------------------------------------
INSERT INTO parametro_global (clave, valor, descripcion) VALUES
  ('UIT', '5150.00', 'Unidad Impositiva Tributaria (UIT) vigente en soles. Actualizar cada año.'),
  ('MULTA_ELECTOR_OMISO_PCT', '2.5', 'Porcentaje de multa para electores omisos (% de UIT) - RN35'),
  ('MULTA_MIEMBRO_MESA_OMISO_PCT', '3.0', 'Porcentaje de multa para miembros de mesa omisos (% de UIT) - RN35'),
  ('ELECTORES_POR_MESA', '200', 'Cantidad máxima de electores por mesa de sufragio'),
  ('UBICACION_SUFRAGIO', 'Biblioteca Central', 'Lugar de sufragio por defecto - RN08'),
  -- CUS08 · horas en decimal: 9.5 = 09:30
  ('INSTALACION_HORA_INICIO', '9', 'Hora desde la que se instalan las mesas el día de la elección (9 = 09:00) - RN07'),
  ('INSTALACION_HORA_LIMITE', '12', 'Hora límite para instalar las mesas (12 = 12:00); luego la mesa queda NO INSTALADA - RF58'),
  ('INSTALACION_CONTROL_HORARIO', '1', '1 = exigir el día y el horario de instalación; 0 = permitir instalar a cualquier hora (pruebas)'),
  -- CUS11
  ('SUFRAGIO_CONTROL_HORARIO', '1',
   '1 = cerrar el sufragio desde la hora de cierre del proceso (15:00, RN06) o cuando ya votaron todos; 0 = permitir cerrar a cualquier hora (pruebas)'),
  -- CUS13
  ('IMPUGNACION_PLAZO_APELACION_HORAS', '24',
   'Horas que tiene el personero para apelar la decisión de la mesa ante el CEUNP (RF81); 0 = sin plazo'),
  ('CEUNP_QUORUM_PLENO', '5',
   'Miembros del Pleno del CEUNP necesarios para resolver una apelación (RN36)'),
  -- CUS14
  ('SEGUNDA_VUELTA_PLAZO_DIAS', '15',
   'Días desde el cómputo dentro de los que debe realizarse la segunda vuelta (RN33, Art. 63)'),
  -- CUS16
  ('MULTA_PLAZO_JUSTIFICACION_DIAS', '10',
   'Días desde la notificación de la multa para presentar la justificación ante el CEUNP (RF106); 0 = sin plazo'),
  -- CUS18
  ('SEGURIDAD_INTENTOS_MAXIMOS', '5',
   'Intentos fallidos de inicio de sesión antes de bloquear la cuenta temporalmente'),
  ('SEGURIDAD_BLOQUEO_MINUTOS', '15',
   'Minutos que la cuenta queda bloqueada tras superar los intentos fallidos'),
  ('SEGURIDAD_PASSWORD_MIN', '8',
   'Longitud mínima de las contraseñas (debe tener letras y números)'),
  -- CUS19
  ('BITACORA_EXPORTACION_MAX', '20000', 'Máximo de registros de la bitácora que se descargan en una exportación (CUS19)')
;

-- Catálogo de parámetros (CUS18): grupo, tipo, rango, unidad, norma y si se bloquean durante la votación
INSERT INTO parametro_definicion (clave, grupo, etiqueta, tipo, minimo, maximo, unidad, referencia, bloqueo_jornada, orden) VALUES
  ('UIT',                               'MULTAS',    'Unidad Impositiva Tributaria vigente', 'DECIMAL', 1, 100000, 'S/',           'RF105',        FALSE, 10),
  ('MULTA_ELECTOR_OMISO_PCT',           'MULTAS',    'Multa al elector omiso',               'DECIMAL', 0, 100,    '% de la UIT',  'RN35 · Art. 68', FALSE, 20),
  ('MULTA_MIEMBRO_MESA_OMISO_PCT',      'MULTAS',    'Multa al miembro de mesa inasistente', 'DECIMAL', 0, 100,    '% de la UIT',  'RN35 · Art. 67', FALSE, 30),
  ('MULTA_PLAZO_JUSTIFICACION_DIAS',    'MULTAS',    'Plazo para justificar la omisión',     'ENTERO',  0, 90,     'días',         'RF106',        FALSE, 40),
  ('ELECTORES_POR_MESA',                'JORNADA',   'Electores por mesa de sufragio',       'ENTERO',  10, 500,   'electores',    'RN08',         TRUE,  10),
  ('UBICACION_SUFRAGIO',                'JORNADA',   'Lugar de sufragio por defecto',        'TEXTO',   3, 150,    NULL,           'RN08',         TRUE,  20),
  ('INSTALACION_HORA_INICIO',           'JORNADA',   'Inicio de la instalación de mesas',    'HORA',    0, 23.99,  'hora',         'RN07',         TRUE,  30),
  ('INSTALACION_HORA_LIMITE',           'JORNADA',   'Límite para instalar las mesas',       'HORA',    0, 23.99,  'hora',         'RF58',         TRUE,  40),
  ('INSTALACION_CONTROL_HORARIO',       'JORNADA',   'Exigir el horario de instalación',     'INDICADOR', 0, 1,    NULL,           'RN07',         TRUE,  50),
  ('SUFRAGIO_CONTROL_HORARIO',          'JORNADA',   'Exigir el horario de cierre del sufragio', 'INDICADOR', 0, 1, NULL,          'RN06',         TRUE,  60),
  ('CEUNP_QUORUM_PLENO',                'CEUNP',     'Quórum del Pleno del CEUNP',           'ENTERO',  5, 9,      'miembros',     'RN36',         FALSE, 10),
  ('IMPUGNACION_PLAZO_APELACION_HORAS', 'CEUNP',     'Plazo para apelar ante el CEUNP',      'ENTERO',  0, 168,    'horas',        'RF81',         FALSE, 20),
  ('SEGUNDA_VUELTA_PLAZO_DIAS',         'CEUNP',     'Plazo para la segunda vuelta',         'ENTERO',  1, 60,     'días',         'RN33 · Art. 63', FALSE, 30),
  ('SEGURIDAD_INTENTOS_MAXIMOS',        'SEGURIDAD', 'Intentos fallidos antes del bloqueo',  'ENTERO',  3, 10,     'intentos',     'RNF seguridad', FALSE, 10),
  ('SEGURIDAD_BLOQUEO_MINUTOS',         'SEGURIDAD', 'Duración del bloqueo de la cuenta',    'ENTERO',  1, 1440,   'minutos',      'RNF seguridad', FALSE, 20),
  ('SEGURIDAD_PASSWORD_MIN',            'SEGURIDAD', 'Longitud mínima de la contraseña',     'ENTERO',  8, 32,     'caracteres',   'RNF seguridad', FALSE, 30),
  ('BITACORA_EXPORTACION_MAX', 'SEGURIDAD', 'Registros por exportación de la bitácora', 'ENTERO', 100, 100000, 'registros', 'RN28', FALSE, 40)
;

-- ---------------------------------------------------------------------
-- RN20: catálogo general de cargos y cargos que impiden ser miembro de mesa.
-- ---------------------------------------------------------------------
INSERT INTO catalogo_cargo (nombre_cargo, nivel, activo) VALUES
  ('Rector y Vicerrectores (Fórmula)', 'UNIVERSIDAD', 1),
  ('Vicerrector Académico', 'UNIVERSIDAD', 0),
  ('Vicerrector de Investigación', 'UNIVERSIDAD', 0),
  ('Secretario General', 'UNIVERSIDAD', 1),
  ('Director de la Escuela de Posgrado', 'UNIVERSIDAD', 1),
  ('Miembro del CEUNP', 'UNIVERSIDAD', 1),
  ('Decano', 'FACULTAD', 1),
  ('Director de Escuela Profesional', 'FACULTAD', 1),
  ('Jefe de Departamento Académico', 'DEPARTAMENTO', 1);

INSERT INTO cargo_excluido_sorteo (id_catalogo_cargo)
SELECT id_catalogo_cargo FROM catalogo_cargo;

-- ---------------------------------------------------------------------
-- Usuario administrador inicial
--   usuario: admin      contraseña: Admin2026*
-- El hash es BCrypt (compatible con BCryptPasswordEncoder del backend).
-- CAMBIA LA CONTRASEÑA en el primer ingreso (pantalla Cuenta).
-- ---------------------------------------------------------------------
INSERT INTO usuario (id_docente, username, password_hash, rol, activo) VALUES
  (NULL, 'admin', '$2a$10$Gjdc.v/mPodGrFSr3ojj6Ogjfi95wczcAli81wzZbaVMitWRCnq3y', 'ADMIN', TRUE);

-- =========================================================
-- 1. INSERTAR FACULTADES EN LA UNP
-- =========================================================
INSERT INTO facultad (nombre) VALUES 
('Facultad de Agronomía'),
('Facultad de Arquitectura y Urbanismo'),
('Facultad de Ciencias'),
('Facultad de Ciencias Administrativas'),
('Facultad de Ciencias Contables y Financieras'),
('Facultad de Ciencias de la Salud'),
('Facultad de Ciencias Sociales y Educación'),
('Facultad de Derecho y Ciencias Políticas'),
('Facultad de Economía'),
('Facultad de Ingeniería Civil'),
('Facultad de Ingeniería de Minas'),
('Facultad de Ingeniería Industrial'),
('Facultad de Ingeniería Pesquera'),
('Facultad de Zootecnia');

-- =========================================================
-- 2. INSERTAR DEPARTAMENTOS VINCULADOS A CADA FACULTAD
-- =========================================================

-- Facultad de Agronomía (5 departamentos)
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Agronomía'), 'Agronomía y Fitotécnia'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Agronomía'), 'Ingeniería Agrícola'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Agronomía'), 'Sanidad Vegetal'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Agronomía'), 'Suelos'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Agronomía'), 'Morfofisiología Vegetal');

-- Facultad de Arquitectura y Urbanismo (2 departamentos)
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Arquitectura y Urbanismo'), 'Arquitectura'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Arquitectura y Urbanismo'), 'Urbanismo');

-- Facultad de Ciencias (5 departamentos)
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias'), 'Matemática'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias'), 'Física'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias'), 'Estadística'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias'), 'Ciencias Biológicas'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias'), 'Ingeniería Electrónica y Telecomunicaciones');

-- Facultad de Ciencias Administrativas (2 departamentos)
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Administrativas'), 'Administración General'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Administrativas'), 'Administración Aplicada');

-- Facultad de Ciencias Contables y Financieras (3 departamentos)
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Contables y Financieras'), 'Contabilidad General'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Contables y Financieras'), 'Contabilidad Aplicada'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Contables y Financieras'), 'Finanzas, Tributación y Auditoría');

-- Facultad de Ciencias de la Salud (6 departamentos)
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias de la Salud'), 'Materno Infantil'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias de la Salud'), 'Morfofisiología Humana'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias de la Salud'), 'Clínico Quirúrgico'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias de la Salud'), 'Salud Pública'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias de la Salud'), 'Enfermería Materno Perinatal'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias de la Salud'), 'Enfermería del Adulto');

-- Facultad de Ciencias Sociales y Educación (3 departamentos)
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Sociales y Educación'), 'Educación'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Sociales y Educación'), 'Ciencias Sociales'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Sociales y Educación'), 'Ciencias de la Comunicación');

-- Facultad de Derecho y Ciencias Políticas
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Derecho y Ciencias Políticas'), 'Derecho'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Derecho y Ciencias Políticas'), 'Ciencias Políticas');

-- Facultad de Economía
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Economía'), 'Economía');

-- Facultad de Ingeniería Civil (2 departamentos)
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería Civil'), 'Ingeniería Civil'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería Civil'), 'Ingeniería Sanitaria y Medio Ambiente');

-- Facultad de Ingeniería de Minas
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería de Minas'), 'Ingeniería de Minas'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería de Minas'), 'Ingeniería de Petróleo'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería de Minas'), 'Ingeniería Geológica'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería de Minas'), 'Ingeniería Química'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería de Minas'), 'Ingeniería Ambiental y Seguridad Industrial');

-- Facultad de Ingeniería Industrial
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería Industrial'), 'Ingeniería Industrial'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería Industrial'), 'Ingeniería Informática'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería Industrial'), 'Agroindustria e Industrias Alimentarias'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería Industrial'), 'Investigación de Operaciones'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería Industrial'), 'Ingeniería Mecatrónica');

-- Facultad de Ingeniería Pesquera
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería Pesquera'), 'Ingeniería Pesquera');

-- Facultad de Zootecnia
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Zootecnia'), 'Producción Animal'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Zootecnia'), 'Salud Animal');

-- =====================================================================
-- 7. OPCIONAL · DEMO DE PUNTA A PUNTA
-- Solo crea el procedimiento; no inserta nada hasta que lo llames.
-- Crea 60 docentes ficticios (DNI 90000001..90000060) y ejecuta una
-- elección completa de Rector usando solo los procedimientos almacenados.
--     CALL sp_demo_flujo_completo();
-- Para dejar la base limpia otra vez: 02_limpiar_datos_electorales.sql
-- Si no quieres la demo, borra desde aquí hasta el final del archivo.
-- =====================================================================

DELIMITER $$

CREATE PROCEDURE sp_demo_flujo_completo()
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

  -- 1. Padrón docente de prueba ------------------------------------------------
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

  -- Una autoridad vigente: no debe salir sorteada como miembro de mesa (RN20)
  SELECT id_docente INTO v_doc FROM docente WHERE dni = '90000060';
  IF NOT EXISTS (SELECT 1 FROM cargo_admin WHERE id_docente = v_doc AND vigente = 1) THEN
    INSERT INTO cargo_admin (id_docente, id_catalogo_cargo, fecha_inicio)
    SELECT v_doc, id_catalogo_cargo, CURDATE() - INTERVAL 1 YEAR
      FROM catalogo_cargo WHERE nombre_cargo = 'Decano';
  END IF;

  -- 2. Proceso y cargo ---------------------------------------------------------
  CALL sp_crear_proceso(CONCAT('DEMO Elección de Rector ', DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s')),
                        NOW() - INTERVAL 1 HOUR, NOW() + INTERVAL 6 HOUR,
                        60.00, CURDATE() - INTERVAL 35 DAY, NULL, NULL, v_proceso);
  CALL sp_agregar_cargo(v_proceso, 'Rector y Vicerrectores', 'UNIVERSIDAD', NULL,
                        'PRINCIPAL,ASOCIADO,AUXILIAR', 'PRINCIPAL', v_cargo);
  CALL sp_cambiar_estado_proceso(v_proceso, 'INSCRIPCION', NULL);

  -- 3. Tres listas (fórmulas de 3 docentes principales) -------------------------
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

  -- 4. Tacha fundada contra el Rector de la Lista C: cae toda la lista (RN12) ----
  SELECT id_docente INTO v_doc FROM docente WHERE dni = '90000001';
  CALL sp_presentar_tacha(v_doc, v_cand_c, 'No acredita el grado de Doctor (RN09).', v_tacha);
  CALL sp_resolver_tacha(v_tacha, 'FUNDADA', 'Se verificó que no cumple el requisito.', NULL);

  CALL sp_validar_lista(v_lista_a, TRUE, NULL, NULL);
  CALL sp_validar_lista(v_lista_b, TRUE, NULL, NULL);

  -- 5. Sorteos, padrón y mesas -------------------------------------------------
  CALL sp_sortear_orden_cedula(v_cargo, 'DEMO-2026', NULL);
  CALL sp_generar_padron(v_proceso, NULL);
  CALL sp_crear_mesas(v_proceso, 30, 'Biblioteca Central', NULL);
  CALL sp_sortear_todas_las_mesas(v_proceso, 'DEMO-2026', NULL);

  -- 6. Día de la elección ------------------------------------------------------
  CALL sp_cambiar_estado_proceso(v_proceso, 'VOTACION', NULL);

  -- CUS08: acreditación de miembros. Todos asisten salvo un vocal (recibirá multa
  -- OMISO_MESA); en su mesa el primer suplente asume el cargo de vocal.
  UPDATE miembro_mesa mm JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
     SET mm.asistio = 1, mm.hora_acreditacion = NOW(), mm.metodo_acreditacion = 'DNI'
   WHERE m.id_proceso = v_proceso;
  UPDATE miembro_mesa mm JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
     SET mm.asistio = 0, mm.hora_acreditacion = NULL, mm.metodo_acreditacion = NULL
   WHERE m.id_proceso = v_proceso AND mm.rol = 'VOCAL' AND m.numero_mesa = '001';
  -- Material electoral recibido en todas las mesas
  INSERT INTO instalacion_mesa (id_mesa, material_json, material_completo, cedulas_recibidas, cedulas_firmadas)
  SELECT id_mesa, CONCAT('{"PADRON":{"estado":"CONFORME","observacion":null},"ACTAS":{"estado":"CONFORME","observacion":null},',
                         '"CEDULAS":{"estado":"CONFORME","observacion":null},"CARTEL_CANDIDATOS":{"estado":"CONFORME","observacion":null},',
                         '"ANFORA":{"estado":"CONFORME","observacion":null},"CABINA":{"estado":"CONFORME","observacion":null}}'),
         TRUE, total_electores, TRUE
    FROM mesa_electoral WHERE id_proceso = v_proceso;

  -- La demo se ejecuta a cualquier hora: se suspende el control horario (RN07) y se restaura
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

  -- Votan todos menos 1 de cada 7 (omisos). 1 de cada 10 vota en blanco.
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

  -- 7. Cierre, cómputo y multas -------------------------------------------------
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

  -- 8. Resumen -----------------------------------------------------------------
  SELECT * FROM v_quorum_proceso  WHERE id_proceso = v_proceso;
  SELECT * FROM v_resultados_cargo WHERE id_proceso = v_proceso ORDER BY votos DESC;
  SELECT * FROM v_cuadre_votos    WHERE id_proceso = v_proceso;
  SELECT * FROM v_mesa_detalle    WHERE id_proceso = v_proceso;
  SELECT 'La última constancia emitida se verifica así:' AS nota, v_token AS token_de_ejemplo;
  CALL sp_verificar_constancia(v_token);
END$$

DELIMITER ;
