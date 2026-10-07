-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 01_esquema.sql  ·  Tablas, claves, restricciones e índices
-- Motor: MariaDB 10.4+ (XAMPP / phpMyAdmin)
--
-- ATENCIÓN: este script ELIMINA y vuelve a crear todas las tablas.
-- Exporta tu base actual desde phpMyAdmin antes de importarlo.
-- Orden de importación: 01 -> 02 -> 03 -> 04 -> 05  (06 es opcional, demo)
-- =====================================================================

CREATE DATABASE IF NOT EXISTS elecciones_unp
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER DATABASE elecciones_unp
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE elecciones_unp;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 0;

DROP VIEW IF EXISTS v_docente_detalle, v_padron_detalle, v_participacion_cargo,
  v_quorum_proceso, v_resultados_cargo, v_cedula_votacion, v_cuadre_votos,
  v_mesa_detalle, v_miembros_mesa, v_multas_detalle, v_tachas_detalle,
  v_candidatos_publicos, v_elegibles_sorteo, vista_quorum;

DROP TABLE IF EXISTS multa;
DROP TABLE IF EXISTS resultado_electoral;
DROP TABLE IF EXISTS impugnacion_electoral;
DROP TABLE IF EXISTS observacion_electoral;
DROP TABLE IF EXISTS sesion_activa;
DROP TABLE IF EXISTS log_auditoria;
DROP TABLE IF EXISTS constancia_voto;
DROP TABLE IF EXISTS firma_acta;
DROP TABLE IF EXISTS acta_electoral;
DROP TABLE IF EXISTS voto;
DROP TABLE IF EXISTS padron_mesa;        -- residuo generado por Hibernate (duplicado)
DROP TABLE IF EXISTS mesa_sufragio;      -- residuo generado por Hibernate (duplicado)
DROP TABLE IF EXISTS padron_electoral;
DROP TABLE IF EXISTS personero;
DROP TABLE IF EXISTS miembro_mesa;
DROP TABLE IF EXISTS mesa_electoral;
DROP TABLE IF EXISTS tacha;
DROP TABLE IF EXISTS candidato;
DROP TABLE IF EXISTS lista_electoral;
DROP TABLE IF EXISTS cargo_categoria_permitida;
DROP TABLE IF EXISTS cargo_electoral;
DROP TABLE IF EXISTS proceso_electoral;
DROP TABLE IF EXISTS cargo_excluido_sorteo;
DROP TABLE IF EXISTS cargo_admin;
DROP TABLE IF EXISTS usuario;
DROP TABLE IF EXISTS parametro_global;
DROP TABLE IF EXISTS docente;
DROP TABLE IF EXISTS departamento;
DROP TABLE IF EXISTS facultad;

SET FOREIGN_KEY_CHECKS = 1;

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

-- Catálogo configurable por el CEUNP (RN20): cargos que impiden ser miembro de mesa
CREATE TABLE cargo_excluido_sorteo (
  id_cargo_excluido INT AUTO_INCREMENT PRIMARY KEY,
  nombre_cargo      VARCHAR(150) NOT NULL,
  nivel             VARCHAR(80)  NOT NULL,
  activo            BOOLEAN      NOT NULL DEFAULT TRUE,
  UNIQUE KEY uq_cargo_excluido_nombre (nombre_cargo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Cargos administrativos que ejerce cada docente (autoridades)
CREATE TABLE cargo_admin (
  id_cargo_admin INT AUTO_INCREMENT PRIMARY KEY,
  id_docente     INT NOT NULL,
  nombre_cargo   VARCHAR(150) NOT NULL,     -- debe coincidir con cargo_excluido_sorteo.nombre_cargo para excluir
  nivel          VARCHAR(80)  NOT NULL,
  fecha_inicio   DATE NOT NULL,
  fecha_fin      DATE NULL,
  vigente        BOOLEAN NOT NULL DEFAULT TRUE,
  KEY ix_cargo_admin_vigente (id_docente, vigente),
  KEY ix_cargo_admin_nombre (nombre_cargo),
  CONSTRAINT chk_cargo_admin_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
  CONSTRAINT fk_cargo_admin_docente FOREIGN KEY (id_docente) REFERENCES docente(id_docente)
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
  activo            BOOLEAN NOT NULL DEFAULT TRUE,
  intentos_fallidos INT NOT NULL DEFAULT 0,
  bloqueado_hasta   DATETIME NULL,
  ultimo_acceso     DATETIME NULL,
  fecha_creacion    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_usuario_username (username),
  CONSTRAINT fk_usuario_docente FOREIGN KEY (id_docente) REFERENCES docente(id_docente)
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
  estado           ENUM('PENDIENTE','INSTALADA','CERRADA','ANULADA') NOT NULL DEFAULT 'PENDIENTE',
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
  qr_credencial_hash  CHAR(64) NULL,             -- RF56: fotocheck digital
  rol_titular         VARCHAR(12) AS (IF(titular = 1, rol, NULL)) PERSISTENT,
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
  uit_referencia   DECIMAL(10,2) NOT NULL,
  porcentaje_uit   DECIMAL(5,2)  NOT NULL,
  monto            DECIMAL(10,2) NOT NULL,
  estado_pago      ENUM('PENDIENTE','PAGADA','EXONERADA') NOT NULL DEFAULT 'PENDIENTE',
  fecha_generacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_pago       DATETIME NULL,
  observacion      VARCHAR(300) NULL,
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
  KEY ix_log_fecha (fecha_hora),
  KEY ix_log_accion (accion, fecha_hora),
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
  id_acta            INT NULL,
  motivo             TEXT NOT NULL,
  decision_mesa      ENUM('PENDIENTE','ACEPTADA','RECHAZADA') NOT NULL DEFAULT 'PENDIENTE',
  decision_ceunp     ENUM('PENDIENTE','CONFIRMADA','MODIFICADA') NOT NULL DEFAULT 'PENDIENTE',
  estado             ENUM('PRESENTADA','RESUELTA','APELADA') NOT NULL DEFAULT 'PRESENTADA',
  fecha_presentacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_resolucion   DATETIME NULL,
  CONSTRAINT fk_impugnacion_personero FOREIGN KEY (id_personero) REFERENCES personero(id_personero),
  CONSTRAINT fk_impugnacion_proceso   FOREIGN KEY (id_proceso)   REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_impugnacion_mesa      FOREIGN KEY (id_mesa)      REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_impugnacion_acta      FOREIGN KEY (id_acta)      REFERENCES acta_electoral(id_acta)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
