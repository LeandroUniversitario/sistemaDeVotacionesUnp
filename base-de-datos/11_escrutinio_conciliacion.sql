-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 11_escrutinio_conciliacion.sql  ·  CUS12 Realizar escrutinio y conciliar
--                                     (CUN09, módulo M11: RF77 a RF87)
--
-- Diagrama de colaboración «Colaboracion - Realizar escrutinio y conciliar» (modelo Rose):
--   1-4   ingresarTotalCedulas(total) / verificarTotal() -> sp_contar_cedulas:
--         contarVotantes() -> padron_electoral (total de electores que votaron)
--         mostrarResultadoValidacion()                                   (RF77, RF78)
--   5-8   ingresarConteoManual(conteo_listas) / compararConDigital(conteo) -> sp_registrar_conteo:
--         contarVotosDigitales() -> voto (conteo digital de la mesa)
--         mostrarCuadre()                                                (RF79, RF82, RF83)
--   9-13  confirmarEscrutinio() / crearActa(resultados) -> sp_generar_acta_escrutinio:
--         insertarActa(hash, contenido) -> acta_electoral (tipo ESCRUTINIO)
--         registrarFirmas(firmas) -> firma_acta
--         mostrarActaGenerada()                                          (RF84, RF85)
--   Tabla 38, paso 9 (después del mensaje 13): se imprimen los tres ejemplares y se
--   entregan al CEUNP -> sp_registrar_entrega_actas                     (RF86, RF87)
--
-- Tabla 38 del informe v2.1:
--   Precondición: sufragio cerrado y acta de sufragio firmada (CUS11).
--   Paso 4: los personeros pueden impugnar un voto (CUS13) -> sp_registrar_impugnacion
--   A1 (RN27): hay más cédulas que votantes: se retiran al azar las sobrantes, sin abrirlas,
--      y se destruyen; se registra la observación.
--   A2: hay menos cédulas: se continúa y se registra la observación.
--   A3: el conteo manual difiere del digital: se muestran las diferencias por opción, se
--      recuenta y, si persiste, prevalece la cédula física y se detalla en el acta (RF84).
--   A4: los votos impugnados pendientes se cuentan como impugnados hasta su resolución.
--   A5: el acta con observaciones se genera marcada como observada.
--
-- Compatible con MariaDB 10.4 (XAMPP): no usa JSON_TABLE.
-- Uso: en una base ya creada con 10_cerrar_sufragio.sql (CUS11). No borra datos.
-- 01_crear_base_de_datos.sql ya incluye este script al final. Se puede volver a ejecutar.
-- =====================================================================
USE elecciones_unp;
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 1. Columna nueva: cargo del voto impugnado (paso 4 y A4; lo resuelve el CUS13)
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_tmp_agregar_columna;
DELIMITER $$
CREATE PROCEDURE sp_tmp_agregar_columna(IN p_tabla VARCHAR(64), IN p_columna VARCHAR(64), IN p_definicion VARCHAR(500))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema = DATABASE() AND table_name = p_tabla AND column_name = p_columna) THEN
    SET @sql_cus12 = CONCAT('ALTER TABLE ', p_tabla, ' ADD COLUMN ', p_columna, ' ', p_definicion);
    PREPARE st_cus12 FROM @sql_cus12;
    EXECUTE st_cus12;
    DEALLOCATE PREPARE st_cus12;
  END IF;
END$$
DELIMITER ;

CALL sp_tmp_agregar_columna('impugnacion_electoral', 'id_cargo',
     'INT NULL COMMENT ''CUS12: cargo de la cédula impugnada durante el escrutinio'' AFTER id_mesa');
DROP PROCEDURE IF EXISTS sp_tmp_agregar_columna;

-- ---------------------------------------------------------------------
-- 2. Tablas nuevas
-- ---------------------------------------------------------------------
-- Escrutinio de cada mesa (relación 1 a 1 con mesa_electoral). Guarda el avance de los
-- pasos del diagrama, el cuadre de cédulas (RN27), la conciliación y la entrega al CEUNP.
CREATE TABLE IF NOT EXISTS escrutinio_mesa (
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
CREATE TABLE IF NOT EXISTS escrutinio_conteo (
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
DROP TRIGGER IF EXISTS trg_escrutinio_bu;
DROP TRIGGER IF EXISTS trg_escrutinio_bd;
DROP TRIGGER IF EXISTS trg_conteo_bi;
DROP TRIGGER IF EXISTS trg_conteo_bu;
DROP TRIGGER IF EXISTS trg_conteo_bd;
DROP PROCEDURE IF EXISTS sp_contar_cedulas;
DROP PROCEDURE IF EXISTS sp_registrar_impugnacion;
DROP PROCEDURE IF EXISTS sp_registrar_conteo;
DROP PROCEDURE IF EXISTS sp_generar_acta_escrutinio;
DROP PROCEDURE IF EXISTS sp_registrar_entrega_actas;

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
