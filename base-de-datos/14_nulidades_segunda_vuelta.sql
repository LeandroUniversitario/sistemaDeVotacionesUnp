-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 14_nulidades_segunda_vuelta.sql  ·  CUS15 Gestionar nulidades y segunda vuelta
--                                     (CUN10 y CUN11, módulos M12 y M13: RF94, RF96, RF97,
--                                      RF100, RF101 y RF102; reglas RN31, RN33, RN34 y RN36)
--
-- Diagrama de colaboración «Gestionar nulidades y segunda vuelta» (modelo Rose, CUS15):
--   1  ingresarNulidadParcial(id_mesa, causal)        -> sp_registrar_nulidad (PARCIAL)
--   2  anularMesa(id_mesa, causal)                    -> sp_resolver_nulidad (DeclararNulidadParcial)
--   3  actualizarEstado('ANULADA')                    -> mesa y actas ANULADAS: salen del cómputo (RF100)
--   4  mostrarMesaExcluida()                          -> v_nulidades (votos_excluidos)
--   5  ingresarNulidadTotal(id_proceso, motivo)       -> sp_registrar_nulidad (TOTAL)
--   6  anularProceso(id_proceso, motivo)              -> sp_resolver_nulidad (DeclararNulidadTotal)
--   7  actualizarEstado('ANULADO', motivo_anulacion)  -> proceso, mesas y actas ANULADOS (RF101, RN34)
--   8  registrarComunicacion('SUNEDU, AU, CU')        -> sp_registrar_comunicacion_nulidad (RF102)
--   9  mostrarResolucionNulidad()                     -> resolución con huella SHA-256 y QR
--   10 [sin minimo legal] convocarSegundaVuelta(id_proceso, fechas) -> sp_convocar_segunda_vuelta (CUS14)
--   11 crearSegundaVuelta(id_proceso, fechas)         -> sp_crear_segunda_vuelta (ConfigurarSegundaVuelta)
--   12 insertar('SEGUNDA_VUELTA', id_proceso_padre)   -> proceso_electoral (trg_proceso_bi_cus15)
--   13 copiarDosMasVotadas(id_cargo)                  -> sp_crear_segunda_vuelta
--   14 copiarPadron(id_proceso_nuevo)                 -> sp_crear_segunda_vuelta
--   15 mostrarSegundaVuelta()                         -> v_segunda_vuelta_procesos
--
-- Qué agrega al CUS14 (13_computo_proclamacion.sql), sin duplicarlo:
--   · El recurso de nulidad (RF94): de oficio o a pedido de un personero, con causal del
--     reglamento (Art. 64 parcial, Art. 65 total), y su resolución por el Pleno con quórum y
--     mayoría simple con voto dirimente del Presidente (RN36). El fallo es inapelable.
--   · La nulidad parcial excluye la votación de la mesa del cómputo (RF100). La calificación
--     NULIDAD del acta en el CUS14 (A3) sigue igual; este caso cubre las demás causales.
--   · La nulidad total por fraude, cohecho, soborno, intimidación o violencia (RF101), antes del
--     cómputo o ya computado pero antes de la proclamación. La nulidad por participación
--     (A1 del CUS14, RN31) se formaliza aquí con su resolución.
--   · Las comunicaciones a SUNEDU, Asamblea Universitaria y Consejo Universitario, y la
--     publicación en el portal y en El Peruano (RF102, Art. 66).
--   · La segunda vuelta reutiliza sp_convocar_segunda_vuelta (CUS14). sp_crear_segunda_vuelta se
--     redefine solo en la elección de las dos listas: si varias empatan por un cupo exige el
--     sorteo del Pleno en vez de tomar la de menor id. No se crea con una nulidad total pendiente.
--   · sp_dirimir_empate: sorteo con semilla pública (SHA-256) para el empate por el pase a la
--     segunda vuelta y para el empate en la segunda vuelta (EMPATE del CUS14, RF97).
--   · Bloqueos: no se computa con recursos de nulidad pendientes ni se proclama con una nulidad
--     total pendiente (RF94). Un número de resolución no se repite en ningún caso de uso.
--
-- Uso: en una base ya creada, después de 13_computo_proclamacion.sql (CUS14). No borra datos
-- ni recrea la base. Se puede volver a ejecutar. 00_script_unico_elecciones_unp.sql (sección 5e)
-- ya lo incluye.
-- =====================================================================
USE elecciones_unp;
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 1. Tablas nuevas
-- ---------------------------------------------------------------------

-- Recurso de nulidad y su resolución por el CEUNP (RF94, RF100, RF101). Una fila por recurso.
-- PARCIAL: votación de una mesa (Art. 64). TOTAL: toda la elección (Art. 65).
CREATE TABLE IF NOT EXISTS nulidad_electoral (
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
CREATE TABLE IF NOT EXISTS nulidad_comunicacion (
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
CREATE TABLE IF NOT EXISTS dirimencia_empate (
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
-- 2. Función: número de resolución ya usado en cualquier caso de uso (RN36)
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_resolucion_en_uso;

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
      OR EXISTS (SELECT 1 FROM impugnacion_electoral WHERE numero_resolucion = p_numero);
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- 3. Triggers
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_proceso_bu;
DROP TRIGGER IF EXISTS trg_proceso_bi_cus15;
DROP TRIGGER IF EXISTS trg_nulidad_bu;
DROP TRIGGER IF EXISTS trg_nulidad_bd;
DROP TRIGGER IF EXISTS trg_ncom_bu;
DROP TRIGGER IF EXISTS trg_ncom_bd;
DROP TRIGGER IF EXISTS trg_dirimencia_bu;
DROP TRIGGER IF EXISTS trg_dirimencia_bd;
DROP TRIGGER IF EXISTS trg_computo_bu_cus15;
DROP TRIGGER IF EXISTS trg_calificacion_bi_cus15;
DROP TRIGGER IF EXISTS trg_impugnacion_bu_cus15;

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
-- 4. Vistas
-- ---------------------------------------------------------------------

-- 4 mostrarMesaExcluida() / 9 mostrarResolucionNulidad(): recursos con su mesa, personero,
-- resolución y comunicaciones registradas (RF102).
CREATE OR REPLACE VIEW v_nulidades AS
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
CREATE OR REPLACE VIEW v_portal_nulidades AS
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
CREATE OR REPLACE VIEW v_segunda_vuelta_procesos AS
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
-- 5. Procedimientos
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_registrar_nulidad;
DROP PROCEDURE IF EXISTS sp_resolver_nulidad;
DROP PROCEDURE IF EXISTS sp_registrar_comunicacion_nulidad;
DROP PROCEDURE IF EXISTS sp_dirimir_empate;
DROP PROCEDURE IF EXISTS sp_crear_segunda_vuelta;
DROP PROCEDURE IF EXISTS sp_verificar_resolucion_nulidad;

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

SELECT 'CUS15 instalado: nulidades y segunda vuelta (sp_registrar_nulidad, sp_resolver_nulidad, sp_registrar_comunicacion_nulidad, sp_dirimir_empate).' AS estado;
