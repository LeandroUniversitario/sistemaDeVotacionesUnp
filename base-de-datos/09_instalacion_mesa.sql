-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 09_instalacion_mesa.sql  ·  CUS08 Instalar mesa (CUN07, módulo M08: RF56 a RF60)
--
-- Diagrama de colaboración «Colaboracion - Instalar mesa»:
--   1-4   escanearCredencialQR / registrarLlegada / actualizarAsistencia(id_docente, hora_llegada)
--         -> miembro_mesa.asistio, hora_acreditacion, metodo_acreditacion          (RF56)
--   5-8   ingresarMaterial / verificarMaterial / registrarMaterial(id_mesa, estado_material)
--         -> instalacion_mesa (material, cédulas recibidas y firmadas)            (RF57)
--   9-13  confirmarInstalacion / instalarMesa(id_mesa) -> sp_instalar_mesa:
--         [antes de 12:00] actualizarEstado('INSTALADA', hora_instalacion)
--         insertarActa('INSTALACION', hash)                                      (RF58, RF59)
--
-- Flujos alternos (CUN07):
--   · Falta un titular: lo reemplaza el primer suplente presente (orden del sorteo).
--   · Faltan titulares y suplentes: asume otro integrante de la comunidad
--     universitaria (tabla reemplazo_mesa).
--   · Pasadas las 12:00 la mesa queda NO_INSTALADA (sp_marcar_mesas_no_instaladas,
--     lo ejecuta el backend cada minuto) y el CEUNP registra su evaluación de
--     nulidad (sp_evaluar_nulidad_mesa)                                          (RF58, RF60)
--
-- Uso: en una base ya creada (no borra datos). 01_crear_base_de_datos.sql
-- ya incluye este script al final. Se puede volver a ejecutar.
-- =====================================================================
USE elecciones_unp;
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 1. Columnas nuevas (sin ADD COLUMN IF NOT EXISTS: funciona en MariaDB y MySQL)
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_tmp_agregar_columna;
DELIMITER $$
CREATE PROCEDURE sp_tmp_agregar_columna(IN p_tabla VARCHAR(64), IN p_columna VARCHAR(64), IN p_definicion VARCHAR(500))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema = DATABASE() AND table_name = p_tabla AND column_name = p_columna) THEN
    SET @sql_cus08 = CONCAT('ALTER TABLE ', p_tabla, ' ADD COLUMN ', p_columna, ' ', p_definicion);
    PREPARE st_cus08 FROM @sql_cus08;
    EXECUTE st_cus08;
    DEALLOCATE PREPARE st_cus08;
  END IF;
END$$
DELIMITER ;

-- RF58: una mesa que no se instaló hasta las 12:00 queda NO_INSTALADA
ALTER TABLE mesa_electoral
  MODIFY estado ENUM('PENDIENTE','INSTALADA','CERRADA','ANULADA','NO_INSTALADA') NOT NULL DEFAULT 'PENDIENTE';

-- RF56: llegada de cada miembro (actualizarAsistencia(id_docente, hora_llegada))
CALL sp_tmp_agregar_columna('miembro_mesa', 'hora_acreditacion',
     'DATETIME NULL COMMENT ''CUS08: hora de llegada'' AFTER asistio');
CALL sp_tmp_agregar_columna('miembro_mesa', 'metodo_acreditacion',
     'ENUM(''QR'',''DNI'') NULL COMMENT ''CUS08: credencial QR o DNI'' AFTER hora_acreditacion');
-- Cargo que ejerce en la instalación (un suplente puede asumir el de un titular ausente)
CALL sp_tmp_agregar_columna('miembro_mesa', 'rol_instalacion',
     'ENUM(''PRESIDENTE'',''SECRETARIO'',''VOCAL'') NULL COMMENT ''CUS08: cargo ejercido'' AFTER metodo_acreditacion');

-- ---------------------------------------------------------------------
-- 2. Tablas nuevas
-- ---------------------------------------------------------------------

-- Datos de instalación de cada mesa (relación 1 a 1 con mesa_electoral):
-- registrarMaterial(id_mesa, estado_material) del diagrama, resultado y evaluación de nulidad.
CREATE TABLE IF NOT EXISTS instalacion_mesa (
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
CREATE TABLE IF NOT EXISTS asistencia_personero_mesa (
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
CREATE TABLE IF NOT EXISTS reemplazo_mesa (
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

-- ---------------------------------------------------------------------
-- 3. Parámetros (editables en la pantalla Parámetros; horas en decimal: 9.5 = 09:30)
-- ---------------------------------------------------------------------
INSERT INTO parametro_global (clave, valor, descripcion) VALUES
  ('INSTALACION_HORA_INICIO', '9', 'Hora desde la que se instalan las mesas el día de la elección (9 = 09:00) - RN07'),
  ('INSTALACION_HORA_LIMITE', '12', 'Hora límite para instalar las mesas (12 = 12:00); luego la mesa queda NO INSTALADA - RF58'),
  ('INSTALACION_CONTROL_HORARIO', '1', '1 = exigir el día y el horario de instalación; 0 = permitir instalar a cualquier hora (pruebas)')
ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion);

-- ---------------------------------------------------------------------
-- 4. Triggers y procedimientos
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_instalacion_bu;
DROP TRIGGER IF EXISTS trg_instalacion_bd;
DROP PROCEDURE IF EXISTS sp_ventana_instalacion;
DROP PROCEDURE IF EXISTS sp_instalar_mesa;
DROP PROCEDURE IF EXISTS sp_declarar_mesa_no_instalada;
DROP PROCEDURE IF EXISTS sp_marcar_mesas_no_instaladas;
DROP PROCEDURE IF EXISTS sp_evaluar_nulidad_mesa;

DELIMITER $$

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

DELIMITER ;

DROP PROCEDURE IF EXISTS sp_tmp_agregar_columna;
