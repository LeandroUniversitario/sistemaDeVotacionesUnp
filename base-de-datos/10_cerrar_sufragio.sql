-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 10_cerrar_sufragio.sql  ·  CUS11 Cerrar sufragio (CUN09, módulo M10: RF74 a RF76)
--
-- Diagrama de colaboración «Colaboracion - Cerrar Sufragio» (modelo Rose):
--   1-4   solicitarCierre(id_mesa) / cerrarVotacion(id_mesa) -> sp_cerrar_votacion:
--         actualizarEstado('CERRADA', hora_cierre) -> mesa_electoral
--         mostrarTotalVotantes(total)                                   (RF74)
--   5-8   confirmarAusentes() / marcarAusentes(id_mesa) -> sp_marcar_ausentes:
--         actualizarNoVoto(id_mesa) -> padron_electoral.no_voto
--         mostrarListaNoVoto()                                          (RF75)
--   9-13  ingresarObservaciones(cedulas_no_usadas, observaciones)
--         generarActa(datos) -> sp_generar_acta_sufragio:
--         insertarActa('SUFRAGIO', hash, contenido) -> acta_electoral
--         registrarFirmas(firmas) -> firma_acta
--         mostrarActaSufragio()                                         (RF76)
--
-- Tabla 37 del informe v2.1:
--   Precondición: son las 15:00 (fecha_fin del proceso) o ya votaron todos los
--   electores, y no hay electores pendientes de votar.
--   Paso 2: se bloquean nuevas verificaciones (la mesa queda CERRADA) y se
--   deshabilitan los terminales de la mesa.
--   A1 (Art. 51a): a las 15:00 aún hay electores votando: terminan y luego se
--   cierra. Un elector habilitado antes de la hora de cierre puede confirmar su
--   voto después (se redefine sp_votar_habilitado), y la mesa no se cierra
--   mientras quede una habilitación de terminal pendiente.
--   A2: el total del sistema difiere del conteo de firmas de la lista física:
--   se registra la observación (obligatoria).
--
-- Uso: en una base ya creada con 09_instalacion_mesa.sql (CUS08) y
-- 06_verificar_elector_emitir_voto.sql (CUS09/CUS10). No borra datos.
-- 01_crear_base_de_datos.sql ya incluye este script al final. Se puede volver a ejecutar.
-- =====================================================================
USE elecciones_unp;
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 1. Columna nueva: marca NO VOTÓ del padrón (RF75, actualizarNoVoto)
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_tmp_agregar_columna;
DELIMITER $$
CREATE PROCEDURE sp_tmp_agregar_columna(IN p_tabla VARCHAR(64), IN p_columna VARCHAR(64), IN p_definicion VARCHAR(500))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema = DATABASE() AND table_name = p_tabla AND column_name = p_columna) THEN
    SET @sql_cus11 = CONCAT('ALTER TABLE ', p_tabla, ' ADD COLUMN ', p_columna, ' ', p_definicion);
    PREPARE st_cus11 FROM @sql_cus11;
    EXECUTE st_cus11;
    DEALLOCATE PREPARE st_cus11;
  END IF;
END$$
DELIMITER ;

CALL sp_tmp_agregar_columna('padron_electoral', 'no_voto',
     'BOOLEAN NOT NULL DEFAULT FALSE COMMENT ''CUS11: marca NO VOTÓ al cerrar el sufragio (RF75)'' AFTER ya_voto');
DROP PROCEDURE IF EXISTS sp_tmp_agregar_columna;

-- ---------------------------------------------------------------------
-- 2. Tabla nueva: cierre de cada mesa (relación 1 a 1 con mesa_electoral)
-- ---------------------------------------------------------------------
-- Guarda el avance de los tres pasos del diagrama y los datos del acta de sufragio.
CREATE TABLE IF NOT EXISTS cierre_mesa (
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

-- ---------------------------------------------------------------------
-- 3. Parámetro (editable en la pantalla Parámetros)
-- ---------------------------------------------------------------------
INSERT INTO parametro_global (clave, valor, descripcion) VALUES
  ('SUFRAGIO_CONTROL_HORARIO', '1',
   '1 = cerrar el sufragio desde la hora de cierre del proceso (15:00, RN06) o cuando ya votaron todos; 0 = permitir cerrar a cualquier hora (pruebas)')
ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion);

-- ---------------------------------------------------------------------
-- 4. Triggers y procedimientos
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_padron_no_voto_bu;
DROP TRIGGER IF EXISTS trg_cierre_bu;
DROP TRIGGER IF EXISTS trg_cierre_bd;
DROP PROCEDURE IF EXISTS sp_votar_habilitado;
DROP PROCEDURE IF EXISTS sp_cerrar_votacion;
DROP PROCEDURE IF EXISTS sp_marcar_ausentes;
DROP PROCEDURE IF EXISTS sp_generar_acta_sufragio;

DELIMITER $$

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
