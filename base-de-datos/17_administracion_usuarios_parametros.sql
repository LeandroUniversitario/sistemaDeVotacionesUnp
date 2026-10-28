-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 17_administracion_usuarios_parametros.sql  ·  CUS18 Administrar usuarios y parámetros
--                         (módulo M01 Seguridad y administración: cuentas y roles, parámetros
--                          del reglamento, bitácora y respaldo de la base de datos;
--                          reglas RN28 trazabilidad, RN35 multas, RN36 Pleno, RF105 UIT)
--
-- Diagrama de colaboración «Administrar usuarios y parámetros» (modelo Rose, CUS18):
--   1   ingresarUsuario()       -> PantallaAdministrador (Admin)
--   1.1 crearUsuario()          -> GestionarUsuarios (control)
--   2   verificarDocente()      -> sp_verificar_docente_usuario · fn_error_docente_usuario (docente)
--   3   insertarUsuario()       -> sp_crear_usuario (Usuario)
--   4   mostrarUsuario()        -> v_usuarios_admin
--   5   modificarParametro()    -> PantallaAdministrador
--   6   actualizar()            -> actualizarParametros (control)
--   7   actualizarParametro()   -> sp_actualizar_parametro · fn_validar_parametro (ParametroGlobal)
--   8   registrarAuditoria()    -> parametro_historial (trg_parametro_global_au) y log_auditoria
--   9   confirmarCambio()       -> fila de confirmación con el valor anterior y el nuevo
--   10  solicitarRespaldo()     -> PantallaAdministrador
--   11  generarRespaldo()       -> respaldarBD (control): el backend vuelca la base a un archivo .sql
--   12  registrarAuditoria()    -> sp_registrar_respaldo (respaldo_bd y log_auditoria)
--   13  mostrarRespaldo()       -> v_respaldos (archivo, tamaño, objetos, filas y huella SHA-256)
--
-- Qué agrega, sin duplicar lo que ya existe (usuario, parametro_global y log_auditoria se mantienen):
--   · Columnas de trazabilidad en usuario: quién creó la cuenta, cuándo se modificó y el motivo
--     de su desactivación.
--   · Las altas, cambios de rol, activación, desactivación, desbloqueo, restablecimiento de clave y
--     eliminación pasan por procedimientos que validan las reglas y escriben la bitácora. La base
--     garantiza que siempre quede un administrador activo.
--   · El catálogo de parámetros (parametro_definicion): grupo, tipo, rango, unidad, norma y si se
--     bloquea durante la jornada electoral. Toda modificación de un parámetro, por la pantalla o
--     directamente en la base, se valida y queda en parametro_historial (inmutable).
--   · Los parámetros de seguridad del inicio de sesión (intentos, minutos de bloqueo y longitud
--     mínima de la contraseña), que antes estaban fijos en el código.
--   · El registro de los respaldos de la base (respaldo_bd, inmutable) con su huella SHA-256.
--
-- Uso: en una base ya creada, después de 16_resultados_verificacion.sql (CUS17). No borra datos ni
-- recrea la base. Se puede volver a ejecutar. 00_script_unico_elecciones_unp.sql (sección 5h) ya lo incluye.
-- =====================================================================
USE elecciones_unp;
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 1. Columnas nuevas de usuario (sin ADD COLUMN IF NOT EXISTS: MariaDB y MySQL)
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_tmp_cus18_columna;
DROP PROCEDURE IF EXISTS sp_tmp_cus18_fk;
DELIMITER $$
CREATE PROCEDURE sp_tmp_cus18_columna(IN p_tabla VARCHAR(64), IN p_columna VARCHAR(64), IN p_definicion VARCHAR(500))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema = DATABASE() AND table_name = p_tabla AND column_name = p_columna) THEN
    SET @sql_cus18 = CONCAT('ALTER TABLE ', p_tabla, ' ADD COLUMN ', p_columna, ' ', p_definicion);
    PREPARE st_cus18 FROM @sql_cus18;
    EXECUTE st_cus18;
    DEALLOCATE PREPARE st_cus18;
  END IF;
END$$
CREATE PROCEDURE sp_tmp_cus18_fk(IN p_tabla VARCHAR(64), IN p_columna VARCHAR(64), IN p_nombre VARCHAR(64),
                                 IN p_referencia VARCHAR(200))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.key_column_usage
                  WHERE table_schema = DATABASE() AND table_name = p_tabla AND column_name = p_columna
                    AND referenced_table_name IS NOT NULL) THEN
    SET @sql_cus18 = CONCAT('ALTER TABLE ', p_tabla, ' ADD CONSTRAINT ', p_nombre,
                            ' FOREIGN KEY (', p_columna, ') REFERENCES ', p_referencia);
    PREPARE st_cus18 FROM @sql_cus18;
    EXECUTE st_cus18;
    DEALLOCATE PREPARE st_cus18;
  END IF;
END$$
DELIMITER ;

CALL sp_tmp_cus18_columna('usuario', 'id_usuario_creador',
     'INT NULL COMMENT ''CUS18: administrador que creó la cuenta'' AFTER fecha_creacion');
CALL sp_tmp_cus18_columna('usuario', 'fecha_actualizacion',
     'DATETIME NULL COMMENT ''CUS18: último cambio de rol, docente, estado o contraseña'' AFTER id_usuario_creador');
CALL sp_tmp_cus18_columna('usuario', 'motivo_estado',
     'VARCHAR(300) NULL COMMENT ''CUS18: motivo de la última desactivación o reactivación'' AFTER fecha_actualizacion');
CALL sp_tmp_cus18_fk('usuario', 'id_usuario_creador', 'fk_usuario_creador',
     'usuario(id_usuario) ON DELETE SET NULL');

DROP PROCEDURE IF EXISTS sp_tmp_cus18_columna;
DROP PROCEDURE IF EXISTS sp_tmp_cus18_fk;

-- ---------------------------------------------------------------------
-- 2. Tablas nuevas
-- ---------------------------------------------------------------------

-- 5 modificarParametro(): catálogo que describe cada parámetro de parametro_global para validarlo
-- y mostrarlo agrupado. No tiene FK: una definición sin parámetro simplemente no se muestra.
CREATE TABLE IF NOT EXISTS parametro_definicion (
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
CREATE TABLE IF NOT EXISTS parametro_historial (
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
CREATE TABLE IF NOT EXISTS respaldo_bd (
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
-- Seguridad del inicio de sesión (antes fijos en Usuario.java: 5 intentos, 15 minutos, 8 caracteres)
INSERT INTO parametro_global (clave, valor, descripcion) VALUES
  ('SEGURIDAD_INTENTOS_MAXIMOS', '5',
   'Intentos fallidos de inicio de sesión antes de bloquear la cuenta temporalmente'),
  ('SEGURIDAD_BLOQUEO_MINUTOS', '15',
   'Minutos que la cuenta queda bloqueada tras superar los intentos fallidos'),
  ('SEGURIDAD_PASSWORD_MIN', '8',
   'Longitud mínima de las contraseñas (debe tener letras y números)')
ON DUPLICATE KEY UPDATE descripcion = descripcion;

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
  ('SEGURIDAD_PASSWORD_MIN',            'SEGURIDAD', 'Longitud mínima de la contraseña',     'ENTERO',  8, 32,     'caracteres',   'RNF seguridad', FALSE, 30)
ON DUPLICATE KEY UPDATE grupo = VALUES(grupo), etiqueta = VALUES(etiqueta), tipo = VALUES(tipo),
  minimo = VALUES(minimo), maximo = VALUES(maximo), unidad = VALUES(unidad), referencia = VALUES(referencia),
  bloqueo_jornada = VALUES(bloqueo_jornada), orden = VALUES(orden);

-- ---------------------------------------------------------------------
-- 4. Funciones
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_jornada_en_curso;
DROP FUNCTION IF EXISTS fn_validar_parametro;
DROP FUNCTION IF EXISTS fn_error_docente_usuario;

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
DROP TRIGGER IF EXISTS trg_usuario_admin_bu;
DROP TRIGGER IF EXISTS trg_usuario_admin_bd;
DROP TRIGGER IF EXISTS trg_parametro_global_bu;
DROP TRIGGER IF EXISTS trg_parametro_global_au;
DROP TRIGGER IF EXISTS trg_param_hist_bu;
DROP TRIGGER IF EXISTS trg_param_hist_bd;
DROP TRIGGER IF EXISTS trg_respaldo_bu;
DROP TRIGGER IF EXISTS trg_respaldo_bd;

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
CREATE OR REPLACE VIEW v_usuarios_admin AS
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
CREATE OR REPLACE VIEW v_parametros_admin AS
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
CREATE OR REPLACE VIEW v_parametro_historial AS
SELECT h.id_historial, h.clave, COALESCE(d.etiqueta, h.clave) AS etiqueta, d.unidad,
       h.valor_anterior, h.valor_nuevo, h.motivo, CONCAT(h.origen, '') AS origen,
       h.id_usuario, u.username, h.ip, h.fecha
  FROM parametro_historial h
  LEFT JOIN parametro_definicion d ON d.clave = h.clave
  LEFT JOIN usuario u              ON u.id_usuario = h.id_usuario;

-- 13 mostrarRespaldo(): respaldos generados
CREATE OR REPLACE VIEW v_respaldos AS
SELECT r.id_respaldo, r.nombre_archivo, r.motivo, r.tablas, r.vistas,
       r.rutinas, r.disparadores, r.filas, r.tamano_bytes, r.hash_sha256, r.id_usuario, u.username,
       r.ip, r.fecha_inicio, r.fecha_fin, TIMESTAMPDIFF(SECOND, r.fecha_inicio, r.fecha_fin) AS duracion_seg
  FROM respaldo_bd r
  JOIN usuario u ON u.id_usuario = r.id_usuario;

-- ---------------------------------------------------------------------
-- 7. Procedimientos
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_validar_admin;
DROP PROCEDURE IF EXISTS sp_verificar_docente_usuario;
DROP PROCEDURE IF EXISTS sp_crear_usuario;
DROP PROCEDURE IF EXISTS sp_actualizar_usuario;
DROP PROCEDURE IF EXISTS sp_cambiar_estado_usuario;
DROP PROCEDURE IF EXISTS sp_restablecer_password;
DROP PROCEDURE IF EXISTS sp_desbloquear_usuario;
DROP PROCEDURE IF EXISTS sp_eliminar_usuario;
DROP PROCEDURE IF EXISTS sp_actualizar_parametro;
DROP PROCEDURE IF EXISTS sp_registrar_respaldo;

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
