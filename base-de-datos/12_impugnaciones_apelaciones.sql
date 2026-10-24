-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 12_impugnaciones_apelaciones.sql  ·  CUS13 Gestionar impugnaciones y apelaciones
--                                       (CUN10, módulo M11: RF80 y RF81)
--
-- Diagrama de colaboración «Colaboration - Gestionar impugnaciones y apelaciones» (modelo Rose):
--   1-5   ingresarImpugnacion(id_mesa, motivo) / registrarImpugnacion(datos)
--         verificarAcreditacion(id_personero) / insertar(id_personero, id_mesa, motivo)
--         confirmarRegistro()                                  -> sp_registrar_impugnacion (CUS12, script 11)
--   6-9   registrarDecisionMesa(id_impugnacion, decision) / resolverEnMesa(datos)
--         actualizarDecisionMesa(decision) / notificarDecision() -> sp_resolver_impugnacion_mesa   (RF80)
--   10    [decision rechazada] apelarDecision(id_impugnacion)   -> sp_apelar_impugnacion          (RF81)
--   11-14 registrarFalloCEUNP(id_impugnacion, decision) / resolverApelacion(id_impugnacion, decision)
--         actualizarDecisionCEUNP(decision, 'RESUELTA') / notificarFalloFinal()
--                                                              -> sp_resolver_apelacion          (RF81)
--
-- Tabla 21 (CUN10) y reglas del informe v2.1:
--   RN24: solo los personeros de mesa impugnan votos (lo valida sp_registrar_impugnacion).
--   RN23: los miembros de mesa son primera instancia y deciden por mayoría simple; el CEUNP
--         resuelve las apelaciones en segunda y última instancia.
--   RN36: los fallos del CEUNP son inapelables; el Pleno requiere quórum de cinco miembros y
--         decide por mayoría simple, con voto dirimente del Presidente.
--   CUS12 A4: los votos impugnados se cuentan como IMPUGNADO hasta su resolución. Al resolver,
--         la mesa (o el CEUNP en apelación) indica a qué opción va la cédula: una lista, BLANCO
--         o NULO. La vista v_impugnacion_efecto da la opción vigente para el cómputo (CUS14).
--
-- Uso: en una base ya creada, después de 11_escrutinio_conciliacion.sql (CUS12), que agrega
-- impugnacion_electoral.id_cargo y sp_registrar_impugnacion. No borra datos. Se puede volver
-- a ejecutar. 02_limpiar_datos_electorales.sql ya vacía impugnacion_electoral.
-- =====================================================================
USE elecciones_unp;
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 1. Columnas nuevas de impugnacion_electoral (sin ADD COLUMN IF NOT EXISTS: MariaDB y MySQL)
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_tmp_agregar_columna;
DROP PROCEDURE IF EXISTS sp_tmp_agregar_fk;
DELIMITER $$
CREATE PROCEDURE sp_tmp_agregar_columna(IN p_tabla VARCHAR(64), IN p_columna VARCHAR(64), IN p_definicion VARCHAR(500))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema = DATABASE() AND table_name = p_tabla AND column_name = p_columna) THEN
    SET @sql_cus13 = CONCAT('ALTER TABLE ', p_tabla, ' ADD COLUMN ', p_columna, ' ', p_definicion);
    PREPARE st_cus13 FROM @sql_cus13;
    EXECUTE st_cus13;
    DEALLOCATE PREPARE st_cus13;
  END IF;
END$$
-- Agrega la FK solo si la columna aún no tiene ninguna (otro script pudo crearla con otro nombre)
CREATE PROCEDURE sp_tmp_agregar_fk(IN p_tabla VARCHAR(64), IN p_columna VARCHAR(64), IN p_nombre VARCHAR(64),
                                   IN p_referencia VARCHAR(200))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.key_column_usage
                  WHERE table_schema = DATABASE() AND table_name = p_tabla AND column_name = p_columna
                    AND referenced_table_name IS NOT NULL) THEN
    SET @sql_cus13 = CONCAT('ALTER TABLE ', p_tabla, ' ADD CONSTRAINT ', p_nombre,
                            ' FOREIGN KEY (', p_columna, ') REFERENCES ', p_referencia);
    PREPARE st_cus13 FROM @sql_cus13;
    EXECUTE st_cus13;
    DEALLOCATE PREPARE st_cus13;
  END IF;
END$$
DELIMITER ;

-- Cargo de la cédula impugnada (lo crea el CUS12; se repite por si este script se ejecuta solo)
CALL sp_tmp_agregar_columna('impugnacion_electoral', 'id_cargo',
     'INT NULL COMMENT ''CUS12: cargo de la cédula impugnada'' AFTER id_mesa');

-- 6-8 registrarDecisionMesa / actualizarDecisionMesa(decision): primera instancia (RN23)
CALL sp_tmp_agregar_columna('impugnacion_electoral', 'votos_mesa_favor',
     'TINYINT NULL COMMENT ''CUS13: miembros de mesa a favor de la impugnación'' AFTER decision_mesa');
CALL sp_tmp_agregar_columna('impugnacion_electoral', 'votos_mesa_contra',
     'TINYINT NULL COMMENT ''CUS13: miembros de mesa en contra'' AFTER votos_mesa_favor');
CALL sp_tmp_agregar_columna('impugnacion_electoral', 'opcion_mesa',
     'ENUM(''LISTA'',''BLANCO'',''NULO'') NULL COMMENT ''CUS13: opción a la que la mesa asigna la cédula'' AFTER votos_mesa_contra');
CALL sp_tmp_agregar_columna('impugnacion_electoral', 'id_lista_mesa',
     'INT NULL COMMENT ''CUS13: lista, si opcion_mesa = LISTA'' AFTER opcion_mesa');
CALL sp_tmp_agregar_columna('impugnacion_electoral', 'fundamento_mesa',
     'VARCHAR(1000) NULL COMMENT ''CUS13: fundamento de la decisión de la mesa'' AFTER id_lista_mesa');
CALL sp_tmp_agregar_columna('impugnacion_electoral', 'fecha_decision_mesa',
     'DATETIME NULL COMMENT ''CUS13: hora de la decisión de la mesa'' AFTER fundamento_mesa');
CALL sp_tmp_agregar_columna('impugnacion_electoral', 'id_usuario_mesa',
     'INT NULL COMMENT ''CUS13: presidente que registró la decisión'' AFTER fecha_decision_mesa');

-- 10 apelarDecision(id_impugnacion) (RF81)
CALL sp_tmp_agregar_columna('impugnacion_electoral', 'id_personero_apela',
     'INT NULL COMMENT ''CUS13: personero que apela'' AFTER id_usuario_mesa');
CALL sp_tmp_agregar_columna('impugnacion_electoral', 'fundamento_apelacion',
     'VARCHAR(1000) NULL COMMENT ''CUS13: fundamento de la apelación'' AFTER id_personero_apela');
CALL sp_tmp_agregar_columna('impugnacion_electoral', 'fecha_apelacion',
     'DATETIME NULL COMMENT ''CUS13: hora de la apelación'' AFTER fundamento_apelacion');
CALL sp_tmp_agregar_columna('impugnacion_electoral', 'id_usuario_apelacion',
     'INT NULL COMMENT ''CUS13: cuenta que registró la apelación'' AFTER fecha_apelacion');

-- 11-13 registrarFalloCEUNP / actualizarDecisionCEUNP(decision, 'RESUELTA') (RN36)
CALL sp_tmp_agregar_columna('impugnacion_electoral', 'numero_resolucion',
     'VARCHAR(40) NULL COMMENT ''CUS13: número de la resolución del CEUNP'' AFTER decision_ceunp');
CALL sp_tmp_agregar_columna('impugnacion_electoral', 'miembros_pleno',
     'TINYINT NULL COMMENT ''CUS13: miembros del Pleno presentes (quórum)'' AFTER numero_resolucion');
CALL sp_tmp_agregar_columna('impugnacion_electoral', 'votos_pleno_favor',
     'TINYINT NULL COMMENT ''CUS13: votos a favor de la apelación'' AFTER miembros_pleno');
CALL sp_tmp_agregar_columna('impugnacion_electoral', 'votos_pleno_contra',
     'TINYINT NULL COMMENT ''CUS13: votos en contra de la apelación'' AFTER votos_pleno_favor');
CALL sp_tmp_agregar_columna('impugnacion_electoral', 'voto_dirimente',
     'ENUM(''FAVOR'',''CONTRA'') NULL COMMENT ''CUS13: voto dirimente del Presidente en empate'' AFTER votos_pleno_contra');
CALL sp_tmp_agregar_columna('impugnacion_electoral', 'opcion_final',
     'ENUM(''LISTA'',''BLANCO'',''NULO'') NULL COMMENT ''CUS13: opción final fijada por el CEUNP'' AFTER voto_dirimente');
CALL sp_tmp_agregar_columna('impugnacion_electoral', 'id_lista_final',
     'INT NULL COMMENT ''CUS13: lista, si opcion_final = LISTA'' AFTER opcion_final');
CALL sp_tmp_agregar_columna('impugnacion_electoral', 'fundamento_ceunp',
     'VARCHAR(1000) NULL COMMENT ''CUS13: fundamento del fallo'' AFTER id_lista_final');
CALL sp_tmp_agregar_columna('impugnacion_electoral', 'fecha_fallo',
     'DATETIME NULL COMMENT ''CUS13: fecha del fallo del CEUNP'' AFTER fundamento_ceunp');
CALL sp_tmp_agregar_columna('impugnacion_electoral', 'id_usuario_ceunp',
     'INT NULL COMMENT ''CUS13: cuenta del CEUNP que registró el fallo'' AFTER fecha_fallo');

CALL sp_tmp_agregar_fk('impugnacion_electoral', 'id_cargo',             'fk_impugnacion_cargo',        'cargo_electoral(id_cargo)');
CALL sp_tmp_agregar_fk('impugnacion_electoral', 'id_lista_mesa',        'fk_impugnacion_lista_mesa',   'lista_electoral(id_lista)');
CALL sp_tmp_agregar_fk('impugnacion_electoral', 'id_lista_final',       'fk_impugnacion_lista_final',  'lista_electoral(id_lista)');
CALL sp_tmp_agregar_fk('impugnacion_electoral', 'id_usuario_mesa',      'fk_impugnacion_usuario_mesa', 'usuario(id_usuario)');
CALL sp_tmp_agregar_fk('impugnacion_electoral', 'id_personero_apela',   'fk_impugnacion_apelante',     'personero(id_personero)');
CALL sp_tmp_agregar_fk('impugnacion_electoral', 'id_usuario_apelacion', 'fk_impugnacion_usuario_apel', 'usuario(id_usuario)');
CALL sp_tmp_agregar_fk('impugnacion_electoral', 'id_usuario_ceunp',     'fk_impugnacion_usuario_ceunp','usuario(id_usuario)');

-- Un número de resolución del CEUNP no se repite
SET @existe_uq = (SELECT COUNT(*) FROM information_schema.statistics
                   WHERE table_schema = DATABASE() AND table_name = 'impugnacion_electoral'
                     AND index_name = 'uq_impugnacion_resolucion');
SET @sql_cus13 = IF(@existe_uq = 0,
  'ALTER TABLE impugnacion_electoral ADD UNIQUE KEY uq_impugnacion_resolucion (numero_resolucion)', 'DO 0');
PREPARE st_cus13 FROM @sql_cus13;
EXECUTE st_cus13;
DEALLOCATE PREPARE st_cus13;
SET @existe_ix = (SELECT COUNT(*) FROM information_schema.statistics
                   WHERE table_schema = DATABASE() AND table_name = 'impugnacion_electoral'
                     AND index_name = 'ix_impugnacion_estado');
SET @sql_cus13 = IF(@existe_ix = 0,
  'ALTER TABLE impugnacion_electoral ADD KEY ix_impugnacion_estado (id_proceso, estado)', 'DO 0');
PREPARE st_cus13 FROM @sql_cus13;
EXECUTE st_cus13;
DEALLOCATE PREPARE st_cus13;

DROP PROCEDURE IF EXISTS sp_tmp_agregar_columna;
DROP PROCEDURE IF EXISTS sp_tmp_agregar_fk;

-- ---------------------------------------------------------------------
-- 2. Parámetros (editables en la pantalla Parámetros)
-- ---------------------------------------------------------------------
INSERT INTO parametro_global (clave, valor, descripcion) VALUES
  ('IMPUGNACION_PLAZO_APELACION_HORAS', '24',
   'Horas que tiene el personero para apelar la decisión de la mesa ante el CEUNP (RF81); 0 = sin plazo'),
  ('CEUNP_QUORUM_PLENO', '5',
   'Miembros del Pleno del CEUNP necesarios para resolver una apelación (RN36)')
ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion);

-- ---------------------------------------------------------------------
-- 3. Triggers, procedimientos y vistas
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_impugnacion_bu;
DROP TRIGGER IF EXISTS trg_impugnacion_bd;
DROP PROCEDURE IF EXISTS sp_resolver_impugnacion_mesa;
DROP PROCEDURE IF EXISTS sp_apelar_impugnacion;
DROP PROCEDURE IF EXISTS sp_resolver_apelacion;

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
CREATE OR REPLACE VIEW v_impugnacion_efecto AS
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
CREATE OR REPLACE VIEW v_impugnaciones_mesa_cargo AS
SELECT e.id_proceso, e.id_mesa, e.id_cargo, e.opcion_vigente, e.id_lista_vigente,
       COUNT(*) AS cedulas, SUM(e.situacion = 'FIRME') AS firmes
  FROM v_impugnacion_efecto e
 GROUP BY e.id_proceso, e.id_mesa, e.id_cargo, e.opcion_vigente, e.id_lista_vigente;

SELECT 'CUS13 instalado: impugnaciones y apelaciones (sp_resolver_impugnacion_mesa, sp_apelar_impugnacion, sp_resolver_apelacion).' AS estado;
