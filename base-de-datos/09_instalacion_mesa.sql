-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 09_instalacion_mesa.sql  ·  CUS08 Instalar mesa
--
-- Instalación de la mesa de sufragio el día de la elección
-- (RN07, RN19, RN28; Art. 45, 48 y 49 del Reglamento de Elecciones):
--   1. Los miembros sorteados se acreditan con su fotocheck QR (CUS07)
--      o con su DNI. Quien no se presenta queda con asistio = 0 (RN35).
--   2. Si falta un titular, lo reemplaza el primer suplente presente
--      según el orden del sorteo (miembro_mesa.rol_instalacion).
--   3. Se registra la presencia de los personeros (opcional).
--   4. Se registra el material electoral recibido.
--   5. sp_instalar_mesa valida todo, emite el Acta de Instalación con su
--      huella SHA-256 y la firman los tres miembros y los personeros.
--   6. Vencido el plazo (12:00), el CEUNP declara la mesa NO_INSTALADA.
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

-- RN07: una mesa que no se instaló dentro del plazo queda NO_INSTALADA
ALTER TABLE mesa_electoral
  MODIFY estado ENUM('PENDIENTE','INSTALADA','CERRADA','ANULADA','NO_INSTALADA') NOT NULL DEFAULT 'PENDIENTE';

-- Acreditación de cada miembro el día de la elección
CALL sp_tmp_agregar_columna('miembro_mesa', 'hora_acreditacion',
     'DATETIME NULL COMMENT ''CUS08: hora en que se acreditó'' AFTER asistio');
CALL sp_tmp_agregar_columna('miembro_mesa', 'metodo_acreditacion',
     'ENUM(''QR'',''DNI'') NULL COMMENT ''CUS08: fotocheck QR o DNI'' AFTER hora_acreditacion');
-- Cargo que ejerce en la instalación (un suplente puede asumir el de un titular ausente)
CALL sp_tmp_agregar_columna('miembro_mesa', 'rol_instalacion',
     'ENUM(''PRESIDENTE'',''SECRETARIO'',''VOCAL'') NULL COMMENT ''CUS08: cargo ejercido'' AFTER metodo_acreditacion');

DROP PROCEDURE IF EXISTS sp_tmp_agregar_columna;

-- ---------------------------------------------------------------------
-- 2. Tablas nuevas
-- ---------------------------------------------------------------------

-- Registro de la instalación: material recibido, observaciones y resultado
CREATE TABLE IF NOT EXISTS instalacion_mesa (
  id_mesa               INT PRIMARY KEY,
  estado                ENUM('EN_CURSO','INSTALADA','NO_INSTALADA') NOT NULL DEFAULT 'EN_CURSO',
  material_json         LONGTEXT NULL,             -- {"PADRON_MESA":true, ...}
  material_completo     BOOLEAN NOT NULL DEFAULT FALSE,   -- todo el material obligatorio recibido
  observaciones         VARCHAR(500) NULL,
  fecha_inicio          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion   DATETIME NULL,
  hora_instalacion      DATETIME NULL,
  motivo_no_instalacion VARCHAR(255) NULL,
  id_usuario_registro   INT NULL,
  id_usuario_cierre     INT NULL,
  CONSTRAINT chk_instalacion_json CHECK (material_json IS NULL OR JSON_VALID(material_json)),
  CONSTRAINT chk_instalacion_motivo CHECK (estado <> 'NO_INSTALADA' OR motivo_no_instalacion IS NOT NULL),
  CONSTRAINT fk_instalacion_mesa     FOREIGN KEY (id_mesa)             REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_instalacion_registro FOREIGN KEY (id_usuario_registro) REFERENCES usuario(id_usuario),
  CONSTRAINT fk_instalacion_cierre   FOREIGN KEY (id_usuario_cierre)   REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Personeros presentes en la instalación (firman el acta)
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

-- ---------------------------------------------------------------------
-- 3. Parámetros (editables en la pantalla Parámetros; horas en decimal: 9.5 = 09:30)
-- ---------------------------------------------------------------------
INSERT INTO parametro_global (clave, valor, descripcion) VALUES
  ('INSTALACION_HORA_INICIO', '9', 'Hora desde la que se instalan las mesas el día de la elección (9 = 09:00) - RN07'),
  ('INSTALACION_HORA_LIMITE', '12', 'Hora límite para instalar las mesas (12 = 12:00); luego la mesa queda NO INSTALADA - RN07'),
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

DELIMITER $$

-- Cerrada la instalación (INSTALADA o NO_INSTALADA), su registro ya no cambia.
CREATE TRIGGER trg_instalacion_bu BEFORE UPDATE ON instalacion_mesa
FOR EACH ROW
BEGIN
  IF OLD.estado <> 'EN_CURSO' THEN
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
        p_mensaje = CONCAT('RN07: venció el plazo de instalación (', TIME_FORMAT(v_h_lim, '%H:%i'),
                           ' del ', DATE_FORMAT(v_dia, '%d/%m/%Y'), ').');
  END IF;
END$$

-- CUS08 / RN07 / RN19 / RN28: instala la mesa y emite el Acta de Instalación.
-- Requiere: proceso en VOTACION, mesa PENDIENTE, dentro del horario, 6 miembros sorteados,
-- material obligatorio recibido y un miembro presente para cada cargo (un suplente
-- presente asume el cargo de un titular ausente, en el orden del sorteo).
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
  DECLARE v_material   LONGTEXT;
  DECLARE v_obs        VARCHAR(500);
  DECLARE v_miembros   LONGTEXT;
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

  CALL sp_ventana_instalacion(v_proceso, v_abierta, v_vencida, v_control, v_msg);
  IF v_abierta = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  SELECT COUNT(*) INTO v_n FROM miembro_mesa WHERE id_mesa = p_id_mesa;
  IF v_n <> 6 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN19: la mesa no tiene sus 6 miembros sorteados.';
  END IF;

  SELECT COUNT(*), COALESCE(MAX(material_completo), 0), MAX(material_json), MAX(observaciones)
    INTO v_n, v_mat_ok, v_material, v_obs
    FROM instalacion_mesa WHERE id_mesa = p_id_mesa;
  IF v_n = 0 OR v_mat_ok = 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'CUS08: registre la recepción de todo el material electoral obligatorio.';
  END IF;

  -- Conformación: titular presente o, en su lugar, el primer suplente presente
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
        SET v_msg = CONCAT('RN19: no hay un miembro presente que asuma el cargo de ', LOWER(v_rol),
                           ' (acredite a un suplente).');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
      END IF;
    END IF;
    SET v_i = v_i + 1;
  END WHILE;

  -- RN35: quien no se acreditó no asistió
  UPDATE miembro_mesa SET asistio = 0 WHERE id_mesa = p_id_mesa AND asistio IS NULL;

  SELECT CONCAT('[', GROUP_CONCAT(
           JSON_OBJECT('dni', d.dni,
                       'docente', CONCAT(d.apellidos, ', ', d.nombres),
                       'rol_sorteo', CONCAT(mm.rol, ''),
                       'titular', mm.titular,
                       'asistio', mm.asistio,
                       'rol_instalacion', CONCAT(mm.rol_instalacion, ''),
                       'hora_acreditacion', DATE_FORMAT(mm.hora_acreditacion, '%Y-%m-%d %H:%i:%s'),
                       'metodo', CONCAT(mm.metodo_acreditacion, ''))
           ORDER BY mm.orden_sorteo SEPARATOR ','), ']')
    INTO v_miembros
    FROM miembro_mesa mm JOIN docente d ON d.id_docente = mm.id_docente
   WHERE mm.id_mesa = p_id_mesa;

  SELECT CONCAT('[', GROUP_CONCAT(
           JSON_OBJECT('dni', d.dni,
                       'docente', CONCAT(d.apellidos, ', ', d.nombres),
                       'lista', l.nombre,
                       'tipo', CONCAT(pe.tipo, ''),
                       'hora_acreditacion', DATE_FORMAT(ap.hora_acreditacion, '%Y-%m-%d %H:%i:%s'),
                       'metodo', CONCAT(ap.metodo, ''))
           ORDER BY ap.hora_acreditacion SEPARATOR ','), ']')
    INTO v_personeros
    FROM asistencia_personero_mesa ap
    JOIN personero pe       ON pe.id_personero = ap.id_personero
    JOIN lista_electoral l  ON l.id_lista = pe.id_lista
    JOIN docente d          ON d.id_docente = pe.id_docente
   WHERE ap.id_mesa = p_id_mesa;

  SET v_ahora = NOW();
  SET v_contenido = CONCAT(
      '{"tipo":"INSTALACION"',
      ',"id_proceso":', v_proceso,
      ',"proceso":', JSON_QUOTE(v_nombre),
      ',"mesa":', JSON_QUOTE(v_numero),
      ',"ubicacion":', JSON_QUOTE(v_ubic),
      ',"hora_instalacion":', JSON_QUOTE(DATE_FORMAT(v_ahora, '%Y-%m-%d %H:%i:%s')),
      ',"total_electores":', v_total,
      ',"miembros":', COALESCE(v_miembros, '[]'),
      ',"personeros":', COALESCE(v_personeros, '[]'),
      ',"material":', COALESCE(v_material, '{}'),
      ',"observaciones":', IF(v_obs IS NULL OR v_obs = '', 'null', JSON_QUOTE(v_obs)),
      '}');

  UPDATE mesa_electoral SET estado = 'INSTALADA', hora_instalacion = v_ahora WHERE id_mesa = p_id_mesa;
  CALL sp_emitir_acta(p_id_mesa, 'INSTALACION', v_contenido, v_token);
  SELECT id_acta, hash_integridad INTO v_id_acta, v_hash
    FROM acta_electoral WHERE id_mesa = p_id_mesa AND tipo = 'INSTALACION';

  -- Firman el acta los tres miembros que la instalan y los personeros presentes
  INSERT INTO firma_acta (id_acta, id_docente, rol, firma_digital, fecha_firma)
  SELECT v_id_acta, mm.id_docente,
         CONCAT(mm.rol_instalacion, ' DE MESA', IF(mm.titular = 1, '', ' (SUPLENTE)')),
         SHA2(CONCAT(v_hash, '|', d.dni, '|', mm.rol_instalacion), 256), v_ahora
    FROM miembro_mesa mm JOIN docente d ON d.id_docente = mm.id_docente
   WHERE mm.id_mesa = p_id_mesa AND mm.rol_instalacion IS NOT NULL;

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

-- CUS08 / RN07: vencido el plazo sin instalar, el CEUNP declara la mesa NO_INSTALADA.
-- Sus electores ya no pueden votar en ella y los miembros que no se acreditaron
-- quedan como inasistentes (multa OMISO_MESA, RN35).
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
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN07: solo durante la VOTACION se declara una mesa no instalada.';
  END IF;
  IF v_mesa_est <> 'PENDIENTE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo una mesa PENDIENTE puede declararse no instalada.';
  END IF;

  CALL sp_ventana_instalacion(v_proceso, v_abierta, v_vencida, v_control, v_msg);
  IF v_control = 1 AND v_vencida = 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN07: la mesa se declara NO INSTALADA recién cuando vence el plazo de instalación.';
  END IF;

  UPDATE mesa_electoral SET estado = 'NO_INSTALADA' WHERE id_mesa = p_id_mesa;
  UPDATE miembro_mesa SET asistio = 0 WHERE id_mesa = p_id_mesa AND asistio IS NULL;
  UPDATE miembro_mesa SET rol_instalacion = NULL WHERE id_mesa = p_id_mesa;

  INSERT INTO instalacion_mesa (id_mesa, estado, motivo_no_instalacion, fecha_actualizacion,
                                id_usuario_registro, id_usuario_cierre)
  VALUES (p_id_mesa, 'NO_INSTALADA', TRIM(p_motivo), NOW(), p_id_usuario, p_id_usuario)
  ON DUPLICATE KEY UPDATE estado = 'NO_INSTALADA', motivo_no_instalacion = TRIM(p_motivo),
                          fecha_actualizacion = NOW(), id_usuario_cierre = p_id_usuario;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'MESA_NO_INSTALADA',
       JSON_OBJECT('id_mesa', p_id_mesa, 'motivo', TRIM(p_motivo)));
  COMMIT;

  SELECT p_id_mesa AS id_mesa, 'NO_INSTALADA' AS estado;
END$$

DELIMITER ;
