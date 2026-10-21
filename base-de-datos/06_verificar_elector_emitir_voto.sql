-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 06_verificar_elector_emitir_voto.sql  ·  CUS09 Verificar elector con QR y CUS10 Registrar voto
--
-- Según la colaboración «Verificar elector y emitir voto» (modelo Rose) y
-- las tablas 35 y 36 del informe v2.1:
--   asistencia_elector    RegistrarAsistencia: asistencia con hora, separada
--                         del voto; bloquea un segundo ingreso (RF64).
--   terminal_votacion     TerminalVotacion de cada mesa (el docente NO inicia
--                         sesión: vota en el terminal que habilita la mesa).
--   habilitacion_terminal habilitarTerminal(): habilitación de un solo uso
--                         para ese elector en ese terminal (RF67).
--   incidencia_mesa       casos en que el elector no vota, QR inválidos,
--                         abandonos y rehabilitaciones (RF66, CUS10 A3).
--   sp_votar_habilitado   crear(opción, mesa) de un cargo, SIN abrir su propia
--                         transacción: el backend vota todos los cargos de la
--                         cédula y consume la habilitación en UNA transacción.
--
-- Estados del elector en el padrón de su mesa (sección 5.4.1 del informe):
--   Pendiente → Habilitado (asistencia + habilitación) → Votó (solo dentro de
--   la transacción del voto) | Habilitado sin votar (abandono o falla).
--
-- RNF06: ninguna de estas tablas referencia a la tabla voto.
-- Uso: SOLO para una base ya creada antes de CUS09 (no borra datos de otras
-- tablas). 01_crear_base_de_datos.sql ya incluye este bloque.
-- =====================================================================
USE elecciones_unp;
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- RF62 / RF68: fotografía del padrón y del candidato a Rector (URL o ruta de la imagen)
ALTER TABLE docente   ADD COLUMN IF NOT EXISTS url_foto VARCHAR(300) NULL;
ALTER TABLE candidato ADD COLUMN IF NOT EXISTS url_foto VARCHAR(300) NULL;

DROP PROCEDURE IF EXISTS sp_votar_habilitado;
DROP TRIGGER IF EXISTS trg_asistencia_elector_bd;
DROP TRIGGER IF EXISTS trg_habilitacion_bd;
DROP TRIGGER IF EXISTS trg_incidencia_mesa_bd;
DROP TABLE IF EXISTS incidencia_mesa;
DROP TABLE IF EXISTS habilitacion_terminal;
DROP TABLE IF EXISTS terminal_votacion;
DROP TABLE IF EXISTS asistencia_elector;
DROP TABLE IF EXISTS autorizacion_voto;   -- versión previa de este caso de uso

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

DELIMITER $$

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

-- CUS10 · mensaje 10 crear(opción, mesa) para UN cargo de la cédula.
-- El terminal solo envía la habilitación (token) y la opción, nunca datos del elector:
-- el docente se obtiene de la habilitación. NO abre ni confirma transacción: el backend
-- llama este procedimiento por cada cargo y consume la habilitación en una sola transacción
-- (CUS10 A5: si algo falla se revierte todo y no se imprime cédula).
-- p_tipo_voto: 'VALIDO' (con p_id_lista) o 'BLANCO' (RN25 / D12: sin voto nulo electrónico).
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
  SELECT h.estado, h.token_hash, a.id_docente, a.id_proceso, a.id_mesa
    INTO v_estado_hab, v_hash, v_docente, v_proceso, v_mesa
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
  IF NOW() < v_inicio OR NOW() > v_fin THEN
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

DELIMITER ;
