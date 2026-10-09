
-- >>>>>>>>>> 01_esquema.sql
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
DROP TABLE IF EXISTS catalogo_cargo;
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

-- >>>>>>>>>> 02_funciones_triggers.sql
-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 02_funciones_triggers.sql  ·  Funciones y disparadores
-- Los triggers protegen las reglas aunque el INSERT/UPDATE venga del
-- backend (JPA) y no de un procedimiento almacenado.
-- =====================================================================
USE elecciones_unp;
-- Las rutinas guardan el sql_mode vigente al crearse: se fuerza modo estricto
-- (XAMPP viene sin STRICT y aceptaria valores invalidos en silencio).
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';

DROP FUNCTION IF EXISTS fn_parametro_decimal;
DROP FUNCTION IF EXISTS fn_tiene_cargo_excluyente;
DROP FUNCTION IF EXISTS fn_participacion_cargo;
DROP FUNCTION IF EXISTS fn_proceso_de_lista;

DROP TRIGGER IF EXISTS trg_docente_bi;
DROP TRIGGER IF EXISTS trg_docente_bu;
DROP TRIGGER IF EXISTS trg_proceso_bu;
DROP TRIGGER IF EXISTS trg_cargo_bi;
DROP TRIGGER IF EXISTS trg_cargo_bu;
DROP TRIGGER IF EXISTS trg_candidato_bi;
DROP TRIGGER IF EXISTS trg_personero_bi;
DROP TRIGGER IF EXISTS trg_miembro_mesa_bi;
DROP TRIGGER IF EXISTS trg_padron_bu;
DROP TRIGGER IF EXISTS trg_padron_bd;
DROP TRIGGER IF EXISTS trg_voto_bi;
DROP TRIGGER IF EXISTS trg_voto_bu;
DROP TRIGGER IF EXISTS trg_voto_bd;
DROP TRIGGER IF EXISTS trg_acta_bu;
DROP TRIGGER IF EXISTS trg_acta_bd;
DROP TRIGGER IF EXISTS trg_resultado_bu;
DROP TRIGGER IF EXISTS trg_resultado_bd;
DROP TRIGGER IF EXISTS trg_log_bu;
DROP TRIGGER IF EXISTS trg_log_bd;

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
-- PROCESO: FINALIZADO y ANULADO son estados terminales (RN26 / RN34)
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_proceso_bu BEFORE UPDATE ON proceso_electoral
FOR EACH ROW
BEGIN
  IF OLD.estado IN ('FINALIZADO','ANULADO') AND NEW.estado <> OLD.estado THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Un proceso FINALIZADO o ANULADO no puede cambiar de estado.';
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

DELIMITER ;

-- >>>>>>>>>> 03_vistas.sql
-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 03_vistas.sql  ·  Vistas de consulta y reportes
-- =====================================================================
USE elecciones_unp;

-- Docente con su facultad y departamento
CREATE OR REPLACE VIEW v_docente_detalle AS
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
CREATE OR REPLACE VIEW v_padron_detalle AS
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
CREATE OR REPLACE VIEW v_participacion_cargo AS
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
CREATE OR REPLACE VIEW v_quorum_proceso AS
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
CREATE OR REPLACE VIEW vista_quorum AS
SELECT * FROM v_quorum_proceso;

-- Conteo por lista. Solo muestra procesos CERRADOS o FINALIZADOS:
-- durante la votación no devuelve filas, así nadie ve resultados parciales.
CREATE OR REPLACE VIEW v_resultados_cargo AS
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
CREATE OR REPLACE VIEW v_cedula_votacion AS
SELECT c.id_proceso, c.id_cargo, c.nombre AS cargo,
       l.id_lista, l.orden_cedula, l.nombre AS lista, l.simbolo,
       ca.rol_en_lista, CONCAT(d.apellidos, ', ', d.nombres) AS candidato
  FROM cargo_electoral c
  JOIN lista_electoral l ON l.id_cargo = c.id_cargo AND l.estado = 'ADMITIDA'
  JOIN candidato ca      ON ca.id_lista = l.id_lista AND ca.estado_validacion = 'APROBADO'
  JOIN docente d         ON d.id_docente = ca.id_docente;

-- RN15: portal de transparencia (solo candidatos aprobados de listas admitidas)
CREATE OR REPLACE VIEW v_candidatos_publicos AS
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
CREATE OR REPLACE VIEW v_cuadre_votos AS
SELECT c.id_proceso, c.id_cargo, c.nombre AS cargo,
       (SELECT COUNT(*) FROM padron_electoral pe WHERE pe.id_cargo = c.id_cargo AND pe.ya_voto = 1) AS electores_que_votaron,
       (SELECT COUNT(*) FROM voto v WHERE v.id_cargo = c.id_cargo) AS votos_en_urna,
       (SELECT COUNT(*) FROM voto v WHERE v.id_cargo = c.id_cargo)
     - (SELECT COUNT(*) FROM padron_electoral pe WHERE pe.id_cargo = c.id_cargo AND pe.ya_voto = 1) AS diferencia
  FROM cargo_electoral c;

-- Estado de las mesas
CREATE OR REPLACE VIEW v_mesa_detalle AS
SELECT m.id_proceso, m.id_mesa, m.numero_mesa, m.ubicacion, m.estado,
       m.total_electores, m.hora_instalacion, m.hora_cierre, m.fecha_sorteo, m.semilla_sorteo,
       (SELECT COUNT(*) FROM miembro_mesa mm WHERE mm.id_mesa = m.id_mesa) AS miembros,
       (SELECT COUNT(DISTINCT pe.id_docente) FROM padron_electoral pe
         WHERE pe.id_mesa = m.id_mesa AND pe.ya_voto = 1) AS electores_que_votaron,
       (SELECT COUNT(*) FROM acta_electoral a WHERE a.id_mesa = m.id_mesa AND a.estado = 'VIGENTE') AS actas_emitidas
  FROM mesa_electoral m;

CREATE OR REPLACE VIEW v_miembros_mesa AS
SELECT m.id_proceso, m.id_mesa, m.numero_mesa, mm.orden_sorteo, mm.rol, mm.titular, mm.asistio,
       d.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS docente, f.nombre AS facultad
  FROM miembro_mesa mm
  JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
  JOIN docente d        ON d.id_docente = mm.id_docente
  JOIN facultad f       ON f.id_facultad = d.id_facultad;

-- RN20: docentes que SÍ pueden entrar al sorteo de mesas de cada proceso
CREATE OR REPLACE VIEW v_elegibles_sorteo AS
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

-- RN35: multas con datos del docente
CREATE OR REPLACE VIEW v_multas_detalle AS
SELECT mu.id_multa, mu.id_proceso, p.nombre AS proceso,
       d.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS docente, f.nombre AS facultad,
       mu.motivo, mu.uit_referencia, mu.porcentaje_uit, mu.monto,
       mu.estado_pago, mu.fecha_generacion, mu.fecha_pago
  FROM multa mu
  JOIN proceso_electoral p ON p.id_proceso = mu.id_proceso
  JOIN docente d           ON d.id_docente = mu.id_docente
  JOIN facultad f          ON f.id_facultad = d.id_facultad;

-- Tachas con denunciante, candidato y lista
CREATE OR REPLACE VIEW v_tachas_detalle AS
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

-- >>>>>>>>>> 04_procedimientos.sql
-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 04_procedimientos.sql  ·  Procedimientos almacenados (ciclo electoral completo)
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
--   E. Día de elección .... sp_instalar_mesa, sp_emitir_voto, sp_cerrar_mesa
--   F. Resultados ......... sp_computar_resultados, sp_crear_segunda_vuelta
--   G. Sanciones .......... sp_generar_multas, sp_actualizar_multa
--   H. Verificación QR .... sp_verificar_constancia, sp_verificar_acta
-- =====================================================================
USE elecciones_unp;
-- Las rutinas guardan el sql_mode vigente al crearse: se fuerza modo estricto
-- (XAMPP viene sin STRICT y aceptaria valores invalidos en silencio).
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

DROP PROCEDURE IF EXISTS sp_registrar_auditoria;
DROP PROCEDURE IF EXISTS sp_emitir_acta;
DROP PROCEDURE IF EXISTS sp_crear_proceso;
DROP PROCEDURE IF EXISTS sp_agregar_cargo;
DROP PROCEDURE IF EXISTS sp_cambiar_estado_proceso;
DROP PROCEDURE IF EXISTS sp_anular_proceso;
DROP PROCEDURE IF EXISTS sp_inscribir_lista;
DROP PROCEDURE IF EXISTS sp_inscribir_candidato;
DROP PROCEDURE IF EXISTS sp_validar_lista;
DROP PROCEDURE IF EXISTS sp_presentar_tacha;
DROP PROCEDURE IF EXISTS sp_resolver_tacha;
DROP PROCEDURE IF EXISTS sp_sortear_orden_cedula;
DROP PROCEDURE IF EXISTS sp_generar_padron;
DROP PROCEDURE IF EXISTS sp_crear_mesas;
DROP PROCEDURE IF EXISTS sp_sortear_miembros_mesa;
DROP PROCEDURE IF EXISTS sp_sortear_todas_las_mesas;
DROP PROCEDURE IF EXISTS sp_registrar_asistencia_miembro;
DROP PROCEDURE IF EXISTS sp_instalar_mesa;
DROP PROCEDURE IF EXISTS sp_emitir_voto;
DROP PROCEDURE IF EXISTS sp_cerrar_mesa;
DROP PROCEDURE IF EXISTS sp_computar_resultados;
DROP PROCEDURE IF EXISTS sp_crear_segunda_vuelta;
DROP PROCEDURE IF EXISTS sp_generar_multas;
DROP PROCEDURE IF EXISTS sp_actualizar_multa;
DROP PROCEDURE IF EXISTS sp_verificar_constancia;
DROP PROCEDURE IF EXISTS sp_verificar_acta;

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
  DECLARE v_doc_est VARCHAR(20) DEFAULT NULL;
  DECLARE v_cand_docente INT DEFAULT NULL;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT p.id_proceso, p.estado, ca.id_docente INTO v_proceso, v_estado, v_cand_docente
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

-- RN07 / RN28: instala la mesa y emite el Acta de Instalación.
-- Devuelve el token del QR del acta (solo se muestra esta vez).
CREATE PROCEDURE sp_instalar_mesa(
  IN p_id_mesa    INT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_proceso   INT DEFAULT NULL;
  DECLARE v_estado    VARCHAR(20) DEFAULT NULL;
  DECLARE v_mesa_est  VARCHAR(20) DEFAULT NULL;
  DECLARE v_numero    VARCHAR(30);
  DECLARE v_ubic      VARCHAR(200);
  DECLARE v_total     INT DEFAULT 0;
  DECLARE v_n         INT DEFAULT 0;
  DECLARE v_miembros  LONGTEXT;
  DECLARE v_contenido LONGTEXT;
  DECLARE v_token     CHAR(64);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET SESSION group_concat_max_len = 1000000;
  START TRANSACTION;

  SELECT m.id_proceso, p.estado, m.estado, m.numero_mesa, m.ubicacion, m.total_electores
    INTO v_proceso, v_estado, v_mesa_est, v_numero, v_ubic, v_total
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
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa ya fue instalada, cerrada o anulada.';
  END IF;
  SELECT COUNT(*) INTO v_n FROM miembro_mesa WHERE id_mesa = p_id_mesa;
  IF v_n <> 6 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN19: la mesa no tiene sus 6 miembros sorteados.';
  END IF;

  SELECT CONCAT('[', GROUP_CONCAT(
           JSON_OBJECT('dni', d.dni,
                       'docente', CONCAT(d.apellidos, ', ', d.nombres),
                       'rol', CONCAT(mm.rol, ''),
                       'titular', mm.titular)
           ORDER BY mm.orden_sorteo SEPARATOR ','), ']')
    INTO v_miembros
    FROM miembro_mesa mm JOIN docente d ON d.id_docente = mm.id_docente
   WHERE mm.id_mesa = p_id_mesa;

  SET v_contenido = CONCAT(
      '{"tipo":"INSTALACION"',
      ',"id_proceso":', v_proceso,
      ',"mesa":', JSON_QUOTE(v_numero),
      ',"ubicacion":', JSON_QUOTE(v_ubic),
      ',"hora_instalacion":', JSON_QUOTE(DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s')),
      ',"total_electores":', v_total,
      ',"miembros":', COALESCE(v_miembros, '[]'),
      '}');

  UPDATE mesa_electoral SET estado = 'INSTALADA', hora_instalacion = NOW() WHERE id_mesa = p_id_mesa;
  CALL sp_emitir_acta(p_id_mesa, 'INSTALACION', v_contenido, v_token);

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'INSTALAR_MESA',
       JSON_OBJECT('id_mesa', p_id_mesa));
  COMMIT;

  SELECT p_id_mesa AS id_mesa, 'INSTALACION' AS acta, v_token AS token_qr;
END$$

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

-- RN33: crea el proceso de segunda vuelta para los cargos en estado SEGUNDA_VUELTA.
-- Clona el cargo, sus categorías, las DOS listas más votadas (con sus candidatos) y el padrón.
-- El nuevo proceso nace en CREADO: faltan mesas, sorteo de miembros y sorteo de cédula.
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

    -- Las dos listas más votadas (agregados: no disparan el handler NOT FOUND)
    SELECT MIN(id_lista) INTO v_l1
      FROM resultado_electoral
     WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO' AND posicion = 1;
    SELECT MIN(id_lista) INTO v_l2
      FROM resultado_electoral
     WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO' AND id_lista <> v_l1
       AND total_votos = (SELECT MAX(r2.total_votos) FROM resultado_electoral r2
                           WHERE r2.id_cargo = v_cargo AND r2.tipo_voto = 'VALIDO' AND r2.id_lista <> v_l1);

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

-- =====================================================================
-- G. SANCIONES
-- =====================================================================

-- RN35: genera las multas del proceso (se puede ejecutar más de una vez sin duplicar).
--   OMISO_VOTACION .. habilitado en el padrón que no votó por ningún cargo
--   OMISO_MESA ...... miembro TITULAR con asistio = FALSE
-- Monto = UIT * porcentaje / 100, tomados de parametro_global.
CREATE PROCEDURE sp_generar_multas(
  IN p_id_proceso INT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_estado   VARCHAR(20) DEFAULT NULL;
  DECLARE v_uit      DECIMAL(12,2);
  DECLARE v_pct_elec DECIMAL(12,2);
  DECLARE v_pct_mesa DECIMAL(12,2);
  DECLARE v_n1       INT DEFAULT 0;
  DECLARE v_n2       INT DEFAULT 0;
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
  IF v_estado NOT IN ('CERRADO','FINALIZADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: las multas se generan con la votacion ya cerrada.';
  END IF;

  SET v_uit      = fn_parametro_decimal('UIT');
  SET v_pct_elec = fn_parametro_decimal('MULTA_ELECTOR_OMISO_PCT');
  SET v_pct_mesa = fn_parametro_decimal('MULTA_MIEMBRO_MESA_OMISO_PCT');
  IF v_uit IS NULL OR v_pct_elec IS NULL OR v_pct_mesa IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Faltan parametros: UIT y porcentajes de multa.';
  END IF;

  INSERT INTO multa (id_docente, id_proceso, motivo, uit_referencia, porcentaje_uit, monto)
  SELECT x.id_docente, p_id_proceso, 'OMISO_VOTACION', v_uit, v_pct_elec, ROUND(v_uit * v_pct_elec / 100, 2)
    FROM (SELECT id_docente
            FROM padron_electoral
           WHERE id_proceso = p_id_proceso AND habilitado_para_votar = 1
           GROUP BY id_docente
          HAVING MAX(ya_voto) = 0) x
  ON DUPLICATE KEY UPDATE observacion = multa.observacion;
  SET v_n1 = ROW_COUNT();

  INSERT INTO multa (id_docente, id_proceso, motivo, uit_referencia, porcentaje_uit, monto)
  SELECT mm.id_docente, p_id_proceso, 'OMISO_MESA', v_uit, v_pct_mesa, ROUND(v_uit * v_pct_mesa / 100, 2)
    FROM miembro_mesa mm
    JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
   WHERE m.id_proceso = p_id_proceso AND mm.titular = 1 AND mm.asistio = 0
  ON DUPLICATE KEY UPDATE observacion = multa.observacion;
  SET v_n2 = ROW_COUNT();

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'GENERAR_MULTAS',
       JSON_OBJECT('omisos_votacion', v_n1, 'omisos_mesa', v_n2));
  COMMIT;

  SELECT motivo, COUNT(*) AS multas, SUM(monto) AS total_soles
    FROM multa WHERE id_proceso = p_id_proceso GROUP BY motivo;
END$$

-- Registra el pago o la exoneración de una multa.
CREATE PROCEDURE sp_actualizar_multa(
  IN p_id_multa    INT,
  IN p_estado_pago VARCHAR(12),     -- PAGADA / EXONERADA / PENDIENTE
  IN p_observacion VARCHAR(300),
  IN p_id_usuario  INT
)
BEGIN
  DECLARE v_proceso INT DEFAULT NULL;
  DECLARE v_docente INT DEFAULT NULL;
  DECLARE v_est     VARCHAR(12);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SET v_est = UPPER(p_estado_pago);

  SELECT id_proceso, id_docente INTO v_proceso, v_docente FROM multa WHERE id_multa = p_id_multa FOR UPDATE;
  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La multa no existe.';
  END IF;
  IF v_est IS NULL OR v_est NOT IN ('PENDIENTE','PAGADA','EXONERADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estado de pago invalido.';
  END IF;

  UPDATE multa
     SET estado_pago = v_est,
         fecha_pago  = IF(v_est = 'PAGADA', NOW(), NULL),
         observacion = COALESCE(p_observacion, observacion)
   WHERE id_multa = p_id_multa;

  CALL sp_registrar_auditoria(p_id_usuario, v_docente, v_proceso, 'ACTUALIZAR_MULTA',
       JSON_OBJECT('id_multa', p_id_multa, 'estado', v_est));
  COMMIT;
END$$

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

DELIMITER ;

-- >>>>>>>>>> 05_datos_iniciales.sql
-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 05_datos_iniciales.sql  ·  Parámetros, catálogos, usuario inicial,
--                            facultades y departamentos
-- =====================================================================
USE elecciones_unp;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- Parámetros globales (editables desde la pantalla Parámetros)
-- Las tres primeras claves son las que ya usa ParametrosController.java
-- ---------------------------------------------------------------------
INSERT INTO parametro_global (clave, valor, descripcion) VALUES
  ('UIT', '5150.00', 'Unidad Impositiva Tributaria (UIT) vigente en soles. Actualizar cada año.'),
  ('MULTA_ELECTOR_OMISO_PCT', '2.5', 'Porcentaje de multa para electores omisos (% de UIT) - RN35'),
  ('MULTA_MIEMBRO_MESA_OMISO_PCT', '3.0', 'Porcentaje de multa para miembros de mesa omisos (% de UIT) - RN35'),
  ('ELECTORES_POR_MESA', '200', 'Cantidad máxima de electores por mesa de sufragio'),
  ('UBICACION_SUFRAGIO', 'Biblioteca Central', 'Lugar de sufragio por defecto - RN08')
ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion);

-- ---------------------------------------------------------------------
-- RN20: catálogo general de cargos y cargos que impiden ser miembro de mesa.
-- ---------------------------------------------------------------------
INSERT INTO catalogo_cargo (nombre_cargo, nivel) VALUES
  ('Rector', 'UNIVERSIDAD'),
  ('Vicerrector Académico', 'UNIVERSIDAD'),
  ('Vicerrector de Investigación', 'UNIVERSIDAD'),
  ('Secretario General', 'UNIVERSIDAD'),
  ('Director de la Escuela de Posgrado', 'UNIVERSIDAD'),
  ('Miembro del CEUNP', 'UNIVERSIDAD'),
  ('Decano', 'FACULTAD'),
  ('Director de Escuela Profesional', 'FACULTAD'),
  ('Jefe de Departamento Académico', 'DEPARTAMENTO')
ON DUPLICATE KEY UPDATE nivel = VALUES(nivel);

INSERT INTO cargo_excluido_sorteo (id_catalogo_cargo)
SELECT id_catalogo_cargo FROM catalogo_cargo
ON DUPLICATE KEY UPDATE activo = VALUES(activo);

-- ---------------------------------------------------------------------
-- Usuario administrador inicial
--   usuario: admin      contraseña: Admin2026*
-- El hash es BCrypt (compatible con BCryptPasswordEncoder del backend).
-- CAMBIA LA CONTRASEÑA en el primer ingreso (pantalla Cuenta).
-- ---------------------------------------------------------------------
INSERT INTO usuario (id_docente, username, password_hash, rol, activo)
SELECT NULL, 'admin', '$2a$10$Gjdc.v/mPodGrFSr3ojj6Ogjfi95wczcAli81wzZbaVMitWRCnq3y', 'ADMIN', TRUE
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM usuario WHERE username = 'admin');

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

-- Facultad de Agronomía
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Agronomía'), 'Agronomía y Fitotecnia'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Agronomía'), 'Ingeniería Agrícola'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Agronomía'), 'Sanidad Vegetal'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Agronomía'), 'Suelos'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Agronomía'), 'Morfofisiología Vegetal');

-- Facultad de Arquitectura y Urbanismo
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Arquitectura y Urbanismo'), 'Arquitectura y Urbanismo');

-- Facultad de Ciencias
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias'), 'Matemática'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias'), 'Física'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias'), 'Estadística'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias'), 'Ciencias Biológicas'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias'), 'Ingeniería Electrónica y Telecomunicaciones');

-- Facultad de Ciencias Administrativas
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Administrativas'), 'Administración General'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Administrativas'), 'Administración Aplicada');

-- Facultad de Ciencias Contables y Financieras
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Contables y Financieras'), 'Contabilidad General'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Contables y Financieras'), 'Contabilidad Aplicada'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Contables y Financieras'), 'Finanzas, Tributación y Auditoría');

-- Facultad de Ciencias de la Salud
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias de la Salud'), 'Materno Infantil'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias de la Salud'), 'Morfofisiología Humana'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias de la Salud'), 'Clínico Quirúrgico'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias de la Salud'), 'Salud Pública'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias de la Salud'), 'Enfermería');

-- Facultad de Ciencias Sociales y Educación
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Sociales y Educación'), 'Educación'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Sociales y Educación'), 'Ciencias de la Comunicación'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Sociales y Educación'), 'Humanidades');

-- Facultad de Derecho y Ciencias Políticas
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Derecho y Ciencias Políticas'), 'Derecho'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Derecho y Ciencias Políticas'), 'Ciencias Políticas');

-- Facultad de Economía
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Economía'), 'Economía');

-- Facultad de Ingeniería Civil
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería Civil'), 'Ingeniería Civil');

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
