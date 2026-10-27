-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 16_resultados_verificacion.sql  ·  CUS17 Consultar resultados y verificar actas
--                         (CUN11, módulos M07 y M12: RF52, RF55 y RF99; reglas RN15, RN26 y RN28;
--                          Art. 59, 62 y 66)
--
-- Diagrama de colaboración «Consultar resultados y verificar actas» (modelo Rose, CUS17):
--   1  seleccionarProceso()        -> PantallaResultados (DocenteElector)
--   2  obtenerResultados()         -> ConsultarResultados (control)
--   3  verificarComputoCerrado()   -> fn_resultados_disponibles: cómputo PUBLICADO (RF99) o cómputo heredado
--   4  consultarResultados()       -> v_resultados_procesos, resultado_electoral, v_resultados_mesa
--   5  devolverResultados()        -> resultados generales, por cargo y por mesa
--   6  mostrarResultados()         -> PantallaResultados
--   7  escanearQR                  -> PantallaResultados (Personero de mesa): QR, pistola, código o huella
--   8  verificarActa()             -> VerificarActa (control) · sp_verificar_documento
--   9  consultarPorToken()         -> sp_localizar_documento: acta, cómputo, proclamación, nulidad, multas o constancia
--   10 recalcularHash()            -> SHA2(contenido_json, 256) frente a la huella guardada
--   11 mostrarAutenticidad()       -> AUTÉNTICA, ALTERADA, ANULADA o NO ENCONTRADA (verificacion_documento)
--
-- Qué agrega, sin duplicar lo que ya existe (sp_verificar_acta, sp_verificar_acta_computo,
-- sp_verificar_resolucion_nulidad y sp_verificar_resolucion_multas se mantienen):
--   · Un solo punto de verificación para todos los documentos con QR del sistema. Acepta el
--     token del QR o, si el QR no se puede leer, la huella SHA-256 impresa en el documento.
--   · El registro de cada consulta de autenticidad (RF55), sin guardar el código leído: solo su
--     SHA-256. La bitácora de verificaciones no se modifica ni se borra.
--   · El cotejo del acta física con la digital: el personero o el docente anota las cifras de su
--     ejemplar; el sistema las compara con las del documento digital. Si no coinciden, la
--     discrepancia queda reportada al CEUNP, que la atiende con una respuesta (aclarada o fundada).
--   · Las vistas de resultados para el docente y el personero: procesos con resultados
--     publicados (o computados con el cómputo heredado, sin CUS14) y resultados por mesa.
--
-- Uso: en una base ya creada, después de 15_omisos_multas.sql (CUS16). No borra datos ni recrea
-- la base. Se puede volver a ejecutar. 00_script_unico_elecciones_unp.sql (sección 5g) ya lo incluye.
-- =====================================================================
USE elecciones_unp;
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 1. Tablas nuevas
-- ---------------------------------------------------------------------

-- 8 verificarActa() · 11 mostrarAutenticidad(): una fila por consulta de autenticidad (RF55).
-- No guarda el código leído (token o huella), solo su SHA-256.
CREATE TABLE IF NOT EXISTS verificacion_documento (
  id_verificacion BIGINT AUTO_INCREMENT PRIMARY KEY,
  codigo_hash     CHAR(64) NOT NULL,
  metodo          ENUM('TOKEN','HUELLA') NULL,
  canal           ENUM('QR','CODIGO','LISTA','PORTAL') NOT NULL DEFAULT 'QR',
  tipo_documento  VARCHAR(30) NULL,
  id_documento    INT NULL,
  id_proceso      INT NULL,
  id_mesa         INT NULL,
  resultado       ENUM('AUTENTICA','ALTERADA','ANULADA','NO_ENCONTRADA') NOT NULL,
  id_usuario      INT NULL,
  rol             VARCHAR(20) NULL,
  ip              VARCHAR(45) NULL,
  fecha           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_verificacion_proceso (id_proceso, fecha),
  KEY ix_verificacion_documento (tipo_documento, id_documento),
  KEY ix_verificacion_usuario (id_usuario, fecha),
  CONSTRAINT fk_verificacion_proceso FOREIGN KEY (id_proceso) REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_verificacion_mesa    FOREIGN KEY (id_mesa)    REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_verificacion_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Cotejo del ejemplar físico con el documento digital. CONFORME si todas las cifras coinciden y
-- el contenido está íntegro; OBSERVADO si hay diferencias (discrepancia reportada al CEUNP);
-- ATENDIDO cuando el CEUNP responde.
CREATE TABLE IF NOT EXISTS cotejo_acta (
  id_cotejo            INT AUTO_INCREMENT PRIMARY KEY,
  id_verificacion      BIGINT NULL,
  tipo_documento       VARCHAR(30) NOT NULL,
  id_documento         INT NOT NULL,
  id_proceso           INT NOT NULL,
  id_mesa              INT NULL,
  hash_integridad      CHAR(64) NOT NULL,
  contenido_integro    BOOLEAN NOT NULL,
  id_usuario           INT NOT NULL,
  rol                  VARCHAR(20) NOT NULL,
  id_personero         INT NULL,
  cifras_json          LONGTEXT NOT NULL,
  lineas               INT NOT NULL,
  diferencias          INT NOT NULL,
  observacion          VARCHAR(1000) NULL,
  estado               ENUM('CONFORME','OBSERVADO','ATENDIDO') NOT NULL,
  fecha                DATETIME NOT NULL,
  -- atención del CEUNP
  decision             ENUM('ACLARADA','FUNDADA') NULL,
  respuesta            VARCHAR(1000) NULL,
  fecha_respuesta      DATETIME NULL,
  id_usuario_respuesta INT NULL,
  KEY ix_cotejo_proceso (id_proceso, estado),
  KEY ix_cotejo_documento (tipo_documento, id_documento),
  KEY ix_cotejo_usuario (id_usuario),
  CONSTRAINT chk_cotejo_json CHECK (JSON_VALID(cifras_json)),
  CONSTRAINT chk_cotejo_cifras CHECK (lineas > 0 AND diferencias >= 0 AND diferencias <= lineas),
  CONSTRAINT chk_cotejo_estado CHECK (
       (estado = 'CONFORME' AND diferencias = 0 AND contenido_integro = 1)
    OR (estado IN ('OBSERVADO','ATENDIDO') AND observacion IS NOT NULL)),
  CONSTRAINT chk_cotejo_atendido CHECK ((estado = 'ATENDIDO') =
       (decision IS NOT NULL AND respuesta IS NOT NULL AND fecha_respuesta IS NOT NULL)),
  CONSTRAINT fk_cotejo_verificacion FOREIGN KEY (id_verificacion)      REFERENCES verificacion_documento(id_verificacion),
  CONSTRAINT fk_cotejo_proceso      FOREIGN KEY (id_proceso)           REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_cotejo_mesa         FOREIGN KEY (id_mesa)              REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_cotejo_usuario      FOREIGN KEY (id_usuario)           REFERENCES usuario(id_usuario),
  CONSTRAINT fk_cotejo_personero    FOREIGN KEY (id_personero)         REFERENCES personero(id_personero),
  CONSTRAINT fk_cotejo_u_respuesta  FOREIGN KEY (id_usuario_respuesta) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 2. Triggers: la bitácora de verificaciones y los cotejos no se alteran
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_verificacion_doc_bu;
DROP TRIGGER IF EXISTS trg_verificacion_doc_bd;
DROP TRIGGER IF EXISTS trg_cotejo_bu;
DROP TRIGGER IF EXISTS trg_cotejo_bd;

DELIMITER $$

CREATE TRIGGER trg_verificacion_doc_bu BEFORE UPDATE ON verificacion_documento
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF55: el registro de verificaciones no se modifica.';
END$$

CREATE TRIGGER trg_verificacion_doc_bd BEFORE DELETE ON verificacion_documento
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF55: el registro de verificaciones no se elimina.';
END$$

-- Solo cambia la atención del CEUNP, una vez, sobre un cotejo OBSERVADO
CREATE TRIGGER trg_cotejo_bu BEFORE UPDATE ON cotejo_acta
FOR EACH ROW
BEGIN
  IF OLD.estado <> 'OBSERVADO' OR NEW.estado <> 'ATENDIDO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: el cotejo solo cambia cuando el CEUNP atiende la discrepancia reportada.';
  END IF;
  IF NOT (NEW.cifras_json <=> OLD.cifras_json AND NEW.diferencias <=> OLD.diferencias AND NEW.observacion <=> OLD.observacion
          AND NEW.id_usuario <=> OLD.id_usuario AND NEW.id_documento <=> OLD.id_documento AND NEW.fecha <=> OLD.fecha
          AND NEW.hash_integridad <=> OLD.hash_integridad) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: las cifras anotadas en el cotejo no se modifican.';
  END IF;
END$$

CREATE TRIGGER trg_cotejo_bd BEFORE DELETE ON cotejo_acta
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: el cotejo del acta no se elimina.';
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- 3. Función
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_resultados_disponibles;

DELIMITER $$

-- 3 verificarComputoCerrado(): hay resultados que mostrar al docente y al personero cuando el
-- CEUNP publicó el cómputo (CUS14, RF99) o, sin CUS14, cuando el proceso se computó con el
-- cómputo heredado (sp_computar_resultados) y quedó FINALIZADO o ANULADO (RN26).
CREATE FUNCTION fn_resultados_disponibles(p_id_proceso INT) RETURNS TINYINT
READS SQL DATA
BEGIN
  DECLARE v_comp VARCHAR(20) DEFAULT NULL;
  DECLARE v_est  VARCHAR(20) DEFAULT NULL;
  SELECT estado INTO v_est FROM proceso_electoral WHERE id_proceso = p_id_proceso;
  IF v_est IS NULL THEN
    RETURN 0;
  END IF;
  SELECT CONCAT(estado, '') INTO v_comp FROM computo_proceso WHERE id_proceso = p_id_proceso;
  IF v_comp IS NOT NULL THEN
    RETURN IF(v_comp = 'PUBLICADO', 1, 0);
  END IF;
  RETURN IF(v_est IN ('FINALIZADO','ANULADO')
            AND EXISTS (SELECT 1 FROM resultado_electoral WHERE id_proceso = p_id_proceso), 1, 0);
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- 4. Vistas
-- ---------------------------------------------------------------------

-- 1 seleccionarProceso() · 4 consultarResultados(): procesos con resultados que se pueden consultar.
CREATE OR REPLACE VIEW v_resultados_procesos AS
SELECT p.id_proceso, p.nombre AS proceso, p.tipo, p.estado AS estado_proceso, p.id_proceso_padre,
       pp.nombre AS proceso_padre,
       IF(cp.id_proceso IS NULL, 'HEREDADO', 'CUS14') AS origen,
       COALESCE(CONCAT(cp.resultado, ''), IF(p.estado = 'ANULADO', 'NULIDAD_TOTAL', 'VALIDA')) AS resultado,
       COALESCE(cp.electores_habiles, q.electores_habiles) AS electores_habiles,
       COALESCE(cp.votaron, q.votaron) AS votaron,
       COALESCE(cp.participacion_pct, q.participacion_pct) AS participacion_pct,
       p.quorum_minimo,
       cp.mesas_total, cp.mesas_computadas, cp.mesas_anuladas, cp.mesas_no_instaladas,
       cp.numero_resolucion,
       COALESCE(cp.fecha_computo, (SELECT MAX(r.fecha_computo) FROM resultado_electoral r WHERE r.id_proceso = p.id_proceso)) AS fecha_computo,
       cp.fecha_proclamacion, cp.fecha_publicacion,
       (SELECT COUNT(*) FROM cargo_electoral c WHERE c.id_proceso = p.id_proceso) AS cargos,
       (SELECT COUNT(*) FROM mesa_electoral m WHERE m.id_proceso = p.id_proceso) AS mesas
  FROM proceso_electoral p
  LEFT JOIN proceso_electoral pp ON pp.id_proceso = p.id_proceso_padre
  LEFT JOIN computo_proceso cp   ON cp.id_proceso = p.id_proceso
  LEFT JOIN v_quorum_proceso q   ON q.id_proceso = p.id_proceso
 WHERE fn_resultados_disponibles(p.id_proceso) = 1;

-- 5 devolverResultados(): resultados por mesa. Con CUS12 son las cifras del acta de escrutinio con
-- las impugnaciones asignadas (v_computo_conteo_mesa); con el cierre heredado, el conteo de la urna.
CREATE OR REPLACE VIEW v_resultados_mesa AS
SELECT x.id_proceso, x.id_mesa, x.numero_mesa, CONCAT(m.estado, '') AS estado_mesa, x.id_cargo, c.nombre AS cargo,
       CONCAT(x.opcion, '') AS opcion, x.id_lista,
       COALESCE(l.nombre, CASE x.opcion WHEN 'BLANCO' THEN 'Votos en blanco' ELSE 'Votos nulos' END) AS lista,
       l.orden_cedula, x.votos, 'ACTA_ESCRUTINIO' AS fuente
  FROM v_computo_conteo_mesa x
  JOIN mesa_electoral m  ON m.id_mesa = x.id_mesa
  JOIN cargo_electoral c ON c.id_cargo = x.id_cargo
  LEFT JOIN lista_electoral l ON l.id_lista = x.id_lista
 WHERE x.opcion <> 'IMPUGNADO'
UNION ALL
SELECT m.id_proceso, m.id_mesa, m.numero_mesa, CONCAT(m.estado, ''), v.id_cargo, c.nombre,
       IF(v.tipo_voto = 'VALIDO', 'LISTA', CONCAT(v.tipo_voto, '')), v.id_lista_elegida,
       COALESCE(l.nombre, IF(v.tipo_voto = 'BLANCO', 'Votos en blanco', 'Votos nulos')),
       l.orden_cedula, COUNT(*), 'URNA_DIGITAL'
  FROM voto v
  JOIN mesa_electoral m  ON m.id_mesa = v.id_mesa
  JOIN cargo_electoral c ON c.id_cargo = v.id_cargo
  LEFT JOIN lista_electoral l ON l.id_lista = v.id_lista_elegida
 WHERE NOT EXISTS (SELECT 1 FROM escrutinio_mesa e
                    WHERE e.id_mesa = m.id_mesa AND e.estado IN ('ACTA_EMITIDA','ENTREGADA'))
 GROUP BY m.id_proceso, m.id_mesa, m.numero_mesa, m.estado, v.id_cargo, c.nombre, v.tipo_voto,
          v.id_lista_elegida, l.nombre, l.orden_cedula;

-- RF52 · RF55: documentos con QR y huella SHA-256 del proceso, con su integridad recalculada,
-- firmas, verificaciones y cotejos. La huella se imprime en el documento: no es secreta.
CREATE OR REPLACE VIEW v_documentos_verificables AS
SELECT d.*,
       (SELECT COUNT(*) FROM verificacion_documento v
         WHERE v.tipo_documento = d.tipo_documento AND v.id_documento = d.id_documento) AS verificaciones,
       (SELECT COUNT(*) FROM cotejo_acta k
         WHERE k.tipo_documento = d.tipo_documento AND k.id_documento = d.id_documento) AS cotejos,
       (SELECT COUNT(*) FROM cotejo_acta k
         WHERE k.tipo_documento = d.tipo_documento AND k.id_documento = d.id_documento AND k.estado = 'OBSERVADO') AS observados
  FROM (
    SELECT m.id_proceso, CONCAT('ACTA_', a.tipo) AS tipo_documento, a.id_acta AS id_documento, a.id_mesa, m.numero_mesa,
           NULL AS numero_resolucion, a.fecha_emision, CONCAT(a.estado, '') AS estado, a.hash_integridad,
           IF(SHA2(a.contenido_json, 256) = a.hash_integridad, 1, 0) AS integra,
           (SELECT COUNT(*) FROM firma_acta f WHERE f.id_acta = a.id_acta) AS firmas
      FROM acta_electoral a JOIN mesa_electoral m ON m.id_mesa = a.id_mesa
    UNION ALL
    SELECT cp.id_proceso, 'COMPUTO_GENERAL', cp.id_proceso, NULL, NULL, NULL, cp.fecha_computo, CONCAT(cp.estado, ''),
           cp.hash_integridad, IF(SHA2(cp.contenido_json, 256) = cp.hash_integridad, 1, 0), 0
      FROM computo_proceso cp WHERE cp.hash_integridad IS NOT NULL
    UNION ALL
    SELECT cp.id_proceso, 'PROCLAMACION', cp.id_proceso, NULL, NULL, cp.numero_resolucion, cp.fecha_proclamacion,
           CONCAT(cp.estado, ''), cp.hash_proclamacion, IF(SHA2(cp.contenido_proclamacion, 256) = cp.hash_proclamacion, 1, 0), 0
      FROM computo_proceso cp WHERE cp.hash_proclamacion IS NOT NULL
    UNION ALL
    SELECT n.id_proceso, 'RESOLUCION_NULIDAD', n.id_nulidad, n.id_mesa, m.numero_mesa, n.numero_resolucion,
           n.fecha_resolucion, CONCAT(n.estado, ''), n.hash_integridad, IF(SHA2(n.contenido_json, 256) = n.hash_integridad, 1, 0), 0
      FROM nulidad_electoral n LEFT JOIN mesa_electoral m ON m.id_mesa = n.id_mesa
     WHERE n.hash_integridad IS NOT NULL
    UNION ALL
    SELECT r.id_proceso, 'RESOLUCION_MULTAS', r.id_reporte, NULL, NULL, r.numero_resolucion, r.fecha_resolucion,
           CONCAT(r.estado, ''), r.hash_integridad, IF(SHA2(r.contenido_json, 256) = r.hash_integridad, 1, 0), 0
      FROM reporte_multas r WHERE r.estado = 'RESUELTO' AND r.hash_integridad IS NOT NULL
  ) d;

-- Cotejos con quién los registró y su atención
CREATE OR REPLACE VIEW v_cotejos_acta AS
SELECT k.id_cotejo, k.id_proceso, p.nombre AS proceso, k.tipo_documento, k.id_documento, k.id_mesa, m.numero_mesa,
       k.hash_integridad, k.contenido_integro, k.lineas, k.diferencias, k.observacion, k.estado, k.fecha,
       k.id_usuario, u.username, k.rol, CONCAT(d.apellidos, ', ', d.nombres) AS registrado_por,
       k.id_personero, l.nombre AS lista_personero, CONCAT(pe.tipo, '') AS tipo_personero,
       k.decision, k.respuesta, k.fecha_respuesta, ur.username AS atendido_por, k.cifras_json
  FROM cotejo_acta k
  JOIN proceso_electoral p ON p.id_proceso = k.id_proceso
  JOIN usuario u           ON u.id_usuario = k.id_usuario
  LEFT JOIN docente d      ON d.id_docente = u.id_docente
  LEFT JOIN mesa_electoral m  ON m.id_mesa = k.id_mesa
  LEFT JOIN personero pe      ON pe.id_personero = k.id_personero
  LEFT JOIN lista_electoral l ON l.id_lista = pe.id_lista
  LEFT JOIN usuario ur        ON ur.id_usuario = k.id_usuario_respuesta;

-- ---------------------------------------------------------------------
-- 5. Procedimientos
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_localizar_documento;
DROP PROCEDURE IF EXISTS sp_verificar_documento;
DROP PROCEDURE IF EXISTS sp_registrar_cotejo_acta;
DROP PROCEDURE IF EXISTS sp_atender_cotejo_acta;

DELIMITER $$

-- 9 consultarPorToken(): busca el documento por el SHA-256 del token del QR y, si no aparece, por su
-- huella SHA-256 (cuando el QR no se puede leer). No modifica datos.
CREATE PROCEDURE sp_localizar_documento(
  IN  p_codigo CHAR(64),
  OUT p_tipo   VARCHAR(30),
  OUT p_id     INT,
  OUT p_metodo VARCHAR(6)
)
BEGIN
  DECLARE v_token CHAR(64);
  SET p_tipo = NULL;
  SET p_id = NULL;
  SET p_metodo = NULL;
  SET v_token = SHA2(LOWER(p_codigo), 256);

  -- Token del QR
  SELECT CONCAT('ACTA_', tipo), id_acta INTO p_tipo, p_id FROM acta_electoral WHERE token_qr_hash = v_token;
  IF p_id IS NULL THEN
    SELECT 'COMPUTO_GENERAL', id_proceso INTO p_tipo, p_id FROM computo_proceso WHERE token_qr_hash = v_token;
  END IF;
  IF p_id IS NULL THEN
    SELECT 'PROCLAMACION', id_proceso INTO p_tipo, p_id FROM computo_proceso WHERE token_proclamacion_hash = v_token;
  END IF;
  IF p_id IS NULL THEN
    SELECT 'RESOLUCION_NULIDAD', id_nulidad INTO p_tipo, p_id FROM nulidad_electoral WHERE token_qr_hash = v_token;
  END IF;
  IF p_id IS NULL THEN
    SELECT 'RESOLUCION_MULTAS', id_reporte INTO p_tipo, p_id FROM reporte_multas
     WHERE token_qr_hash = v_token AND estado = 'RESUELTO';
  END IF;
  IF p_id IS NULL THEN
    SELECT 'CONSTANCIA_VOTO', id_constancia INTO p_tipo, p_id FROM constancia_voto WHERE token_qr_hash = v_token;
  END IF;
  IF p_id IS NOT NULL THEN
    SET p_metodo = 'TOKEN';
  ELSE
    -- Huella SHA-256 impresa en el documento
    SELECT CONCAT('ACTA_', tipo), id_acta INTO p_tipo, p_id FROM acta_electoral
     WHERE hash_integridad = LOWER(p_codigo) ORDER BY id_acta LIMIT 1;
    IF p_id IS NULL THEN
      SELECT 'COMPUTO_GENERAL', id_proceso INTO p_tipo, p_id FROM computo_proceso WHERE hash_integridad = LOWER(p_codigo) LIMIT 1;
    END IF;
    IF p_id IS NULL THEN
      SELECT 'PROCLAMACION', id_proceso INTO p_tipo, p_id FROM computo_proceso WHERE hash_proclamacion = LOWER(p_codigo) LIMIT 1;
    END IF;
    IF p_id IS NULL THEN
      SELECT 'RESOLUCION_NULIDAD', id_nulidad INTO p_tipo, p_id FROM nulidad_electoral WHERE hash_integridad = LOWER(p_codigo) LIMIT 1;
    END IF;
    IF p_id IS NULL THEN
      SELECT 'RESOLUCION_MULTAS', id_reporte INTO p_tipo, p_id FROM reporte_multas
       WHERE hash_integridad = LOWER(p_codigo) AND estado = 'RESUELTO' LIMIT 1;
    END IF;
    IF p_id IS NOT NULL THEN
      SET p_metodo = 'HUELLA';
    END IF;
  END IF;
END$$

-- 8 verificarActa() · 9 consultarPorToken() · 10 recalcularHash() · 11 mostrarAutenticidad().
-- Devuelve una fila con el documento y el resultado, y registra la consulta (RF55).
-- AUTENTICA: la huella recalculada coincide. ALTERADA: no coincide. ANULADA: íntegra, pero el
-- documento ya no tiene efecto (acta de una mesa anulada, constancia revocada o vencida).
-- La resolución de multas no devuelve la relación de docentes, solo sus totales (CUS16).
CREATE PROCEDURE sp_verificar_documento(
  IN p_codigo     VARCHAR(200),
  IN p_canal      VARCHAR(10),
  IN p_id_usuario INT,
  IN p_ip         VARCHAR(45)
)
BEGIN
  DECLARE v_codigo    CHAR(64) DEFAULT NULL;
  DECLARE v_tipo      VARCHAR(30);
  DECLARE v_id        INT;
  DECLARE v_metodo    VARCHAR(6);
  DECLARE v_proceso   INT DEFAULT NULL;
  DECLARE v_mesa      INT DEFAULT NULL;
  DECLARE v_estado    VARCHAR(20) DEFAULT NULL;
  DECLARE v_fecha     DATETIME DEFAULT NULL;
  DECLARE v_res_num   VARCHAR(40) DEFAULT NULL;
  DECLARE v_hash      CHAR(64) DEFAULT NULL;
  DECLARE v_calc      CHAR(64) DEFAULT NULL;
  DECLARE v_contenido LONGTEXT DEFAULT NULL;
  DECLARE v_vigente   TINYINT DEFAULT 1;
  DECLARE v_firmas    INT DEFAULT 0;
  DECLARE v_resultado VARCHAR(15);
  DECLARE v_canal     VARCHAR(10);
  DECLARE v_rol       VARCHAR(20) DEFAULT NULL;
  DECLARE v_id_verif  BIGINT;

  SET v_canal = UPPER(COALESCE(NULLIF(TRIM(p_canal), ''), 'QR'));
  IF v_canal NOT IN ('QR','CODIGO','LISTA','PORTAL') THEN
    SET v_canal = 'QR';
  END IF;
  IF LOWER(TRIM(p_codigo)) REGEXP '^[0-9a-f]{64}$' THEN
    SET v_codigo = LOWER(TRIM(p_codigo));
    CALL sp_localizar_documento(v_codigo, v_tipo, v_id, v_metodo);
  END IF;

  IF v_id IS NOT NULL THEN
    IF v_tipo LIKE 'ACTA\_%' THEN
      SELECT m.id_proceso, a.id_mesa, CONCAT(a.estado, ''), a.fecha_emision, a.hash_integridad,
             SHA2(a.contenido_json, 256), a.contenido_json, IF(a.estado = 'VIGENTE' AND m.estado <> 'ANULADA', 1, 0),
             (SELECT COUNT(*) FROM firma_acta f WHERE f.id_acta = a.id_acta)
        INTO v_proceso, v_mesa, v_estado, v_fecha, v_hash, v_calc, v_contenido, v_vigente, v_firmas
        FROM acta_electoral a JOIN mesa_electoral m ON m.id_mesa = a.id_mesa
       WHERE a.id_acta = v_id;
    ELSEIF v_tipo = 'COMPUTO_GENERAL' THEN
      SELECT cp.id_proceso, CONCAT(cp.estado, ''), cp.fecha_computo, cp.hash_integridad, SHA2(cp.contenido_json, 256), cp.contenido_json
        INTO v_proceso, v_estado, v_fecha, v_hash, v_calc, v_contenido
        FROM computo_proceso cp WHERE cp.id_proceso = v_id;
    ELSEIF v_tipo = 'PROCLAMACION' THEN
      SELECT cp.id_proceso, CONCAT(cp.estado, ''), cp.fecha_proclamacion, cp.numero_resolucion, cp.hash_proclamacion,
             SHA2(cp.contenido_proclamacion, 256), cp.contenido_proclamacion
        INTO v_proceso, v_estado, v_fecha, v_res_num, v_hash, v_calc, v_contenido
        FROM computo_proceso cp WHERE cp.id_proceso = v_id;
    ELSEIF v_tipo = 'RESOLUCION_NULIDAD' THEN
      SELECT n.id_proceso, n.id_mesa, CONCAT(n.estado, ''), n.fecha_resolucion, n.numero_resolucion, n.hash_integridad,
             SHA2(n.contenido_json, 256), n.contenido_json
        INTO v_proceso, v_mesa, v_estado, v_fecha, v_res_num, v_hash, v_calc, v_contenido
        FROM nulidad_electoral n WHERE n.id_nulidad = v_id;
    ELSEIF v_tipo = 'RESOLUCION_MULTAS' THEN
      -- Solo los totales: la relación de docentes no se expone
      SELECT r.id_proceso, CONCAT(r.estado, ''), r.fecha_resolucion, r.numero_resolucion, r.hash_integridad,
             SHA2(r.contenido_json, 256),
             JSON_OBJECT('tipo', 'RESOLUCION_MULTAS', 'resolucion', r.numero_resolucion, 'omisos_votacion', r.omisos_votacion,
                         'omisos_mesa', r.omisos_mesa, 'monto_total', r.monto_total, 'uit', r.uit_referencia,
                         'pct_elector', r.pct_elector, 'pct_miembro', r.pct_miembro)
        INTO v_proceso, v_estado, v_fecha, v_res_num, v_hash, v_calc, v_contenido
        FROM reporte_multas r WHERE r.id_reporte = v_id;
    ELSEIF v_tipo = 'CONSTANCIA_VOTO' THEN
      -- La constancia no tiene contenido con huella: vale si está vigente. Nunca dice por quién votó.
      SELECT cv.id_proceso, CONCAT(cv.estado, ''), cv.fecha_emision,
             IF(cv.estado = 'VIGENTE' AND (cv.fecha_expiracion IS NULL OR cv.fecha_expiracion >= NOW()), 1, 0),
             JSON_OBJECT('tipo', 'CONSTANCIA_VOTO', 'cargo', c.nombre, 'docente', CONCAT(d.nombres, ' ', d.apellidos),
                         'fecha_emision', DATE_FORMAT(cv.fecha_emision, '%Y-%m-%d %H:%i:%s'))
        INTO v_proceso, v_estado, v_fecha, v_vigente, v_contenido
        FROM constancia_voto cv
        JOIN cargo_electoral c ON c.id_cargo = cv.id_cargo
        JOIN docente d         ON d.id_docente = cv.id_docente
       WHERE cv.id_constancia = v_id;
    END IF;
  END IF;

  SET v_resultado = CASE
    WHEN v_id IS NULL THEN 'NO_ENCONTRADA'
    WHEN v_tipo <> 'CONSTANCIA_VOTO' AND NOT (v_calc <=> v_hash) THEN 'ALTERADA'
    WHEN v_vigente = 0 THEN 'ANULADA'
    ELSE 'AUTENTICA' END;

  IF p_id_usuario IS NOT NULL THEN
    SELECT CONCAT(rol, '') INTO v_rol FROM usuario WHERE id_usuario = p_id_usuario;
  END IF;

  INSERT INTO verificacion_documento (codigo_hash, metodo, canal, tipo_documento, id_documento, id_proceso, id_mesa,
                                      resultado, id_usuario, rol, ip, fecha)
  VALUES (SHA2(COALESCE(v_codigo, LEFT(COALESCE(p_codigo, ''), 200)), 256), v_metodo, v_canal, v_tipo, v_id, v_proceso, v_mesa,
          v_resultado, IF(v_rol IS NULL, NULL, p_id_usuario), v_rol, LEFT(p_ip, 45), NOW());
  SET v_id_verif = LAST_INSERT_ID();

  -- 11 mostrarAutenticidad()
  SELECT v_id_verif AS id_verificacion, v_resultado AS resultado, v_metodo AS metodo, v_tipo AS tipo_documento,
         v_id AS id_documento, v_proceso AS id_proceso, p.nombre AS proceso, CONCAT(p.tipo, '') AS tipo_proceso,
         v_mesa AS id_mesa, m.numero_mesa, m.ubicacion, v_estado AS estado, v_fecha AS fecha_emision,
         v_res_num AS numero_resolucion, v_hash AS hash_guardado, v_calc AS hash_recalculado,
         IF(v_id IS NULL OR v_tipo = 'CONSTANCIA_VOTO', NULL, IF(v_calc <=> v_hash, 1, 0)) AS contenido_integro,
         v_firmas AS firmas, fn_resultados_disponibles(v_proceso) AS resultados_publicados,
         (SELECT COUNT(*) FROM verificacion_documento v
           WHERE v.tipo_documento = v_tipo AND v.id_documento = v_id) AS veces_verificado,
         v_contenido AS contenido_json
    FROM (SELECT 1) uno
    LEFT JOIN proceso_electoral p ON p.id_proceso = v_proceso
    LEFT JOIN mesa_electoral m    ON m.id_mesa = v_mesa;
END$$

-- Cotejo del ejemplar físico con el documento digital (RF55). La aplicación arma p_cifras_json con
-- las cifras del documento digital ("digital") y las anotadas del ejemplar ("fisico"):
--   [{"clave": "...", "etiqueta": "...", "digital": 15, "fisico": 15}, ...]
-- El procedimiento vuelve a localizar el documento, recalcula su huella y cuenta las diferencias.
CREATE PROCEDURE sp_registrar_cotejo_acta(
  IN p_codigo          VARCHAR(64),
  IN p_id_verificacion BIGINT,
  IN p_id_usuario      INT,
  IN p_cifras_json     LONGTEXT,
  IN p_observacion     VARCHAR(1000)
)
BEGIN
  DECLARE v_tipo     VARCHAR(30);
  DECLARE v_id       INT;
  DECLARE v_metodo   VARCHAR(6);
  DECLARE v_proceso  INT DEFAULT NULL;
  DECLARE v_mesa     INT DEFAULT NULL;
  DECLARE v_hash     CHAR(64) DEFAULT NULL;
  DECLARE v_calc     CHAR(64) DEFAULT NULL;
  DECLARE v_rol      VARCHAR(20) DEFAULT NULL;
  DECLARE v_docente  INT DEFAULT NULL;
  DECLARE v_pers     INT DEFAULT NULL;
  DECLARE v_n        INT;
  DECLARE v_i        INT DEFAULT 0;
  DECLARE v_dif      INT DEFAULT 0;
  DECLARE v_digital  VARCHAR(20);
  DECLARE v_fisico   VARCHAR(20);
  DECLARE v_obs      VARCHAR(1000);
  DECLARE v_integro  TINYINT;
  DECLARE v_estado   VARCHAR(10);
  DECLARE v_id_cot   INT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SELECT CONCAT(rol, ''), id_docente INTO v_rol, v_docente FROM usuario WHERE id_usuario = p_id_usuario AND activo = 1;
  IF v_rol IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: inicie sesión para cotejar el acta.';
  END IF;
  IF p_codigo IS NULL OR NOT (LOWER(TRIM(p_codigo)) REGEXP '^[0-9a-f]{64}$') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: el código del documento no es válido.';
  END IF;
  CALL sp_localizar_documento(LOWER(TRIM(p_codigo)), v_tipo, v_id, v_metodo);
  IF v_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: el documento no existe o el código no es válido.';
  END IF;
  IF v_tipo IN ('CONSTANCIA_VOTO','RESOLUCION_MULTAS') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: el cotejo de cifras se hace sobre las actas, el acta general y la resolución de proclamación.';
  END IF;

  IF v_tipo LIKE 'ACTA\_%' THEN
    SELECT m.id_proceso, a.id_mesa, a.hash_integridad, SHA2(a.contenido_json, 256)
      INTO v_proceso, v_mesa, v_hash, v_calc
      FROM acta_electoral a JOIN mesa_electoral m ON m.id_mesa = a.id_mesa WHERE a.id_acta = v_id;
  ELSEIF v_tipo = 'COMPUTO_GENERAL' THEN
    SELECT id_proceso, hash_integridad, SHA2(contenido_json, 256) INTO v_proceso, v_hash, v_calc
      FROM computo_proceso WHERE id_proceso = v_id;
  ELSEIF v_tipo = 'PROCLAMACION' THEN
    SELECT id_proceso, hash_proclamacion, SHA2(contenido_proclamacion, 256) INTO v_proceso, v_hash, v_calc
      FROM computo_proceso WHERE id_proceso = v_id;
  ELSE
    SELECT id_proceso, id_mesa, hash_integridad, SHA2(contenido_json, 256) INTO v_proceso, v_mesa, v_hash, v_calc
      FROM nulidad_electoral WHERE id_nulidad = v_id;
  END IF;
  SET v_integro = IF(v_calc <=> v_hash, 1, 0);

  -- Cifras anotadas del ejemplar físico
  IF p_cifras_json IS NULL OR JSON_VALID(p_cifras_json) = 0 OR JSON_TYPE(p_cifras_json) <> 'ARRAY' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: las cifras del cotejo no son válidas.';
  END IF;
  SET v_n = JSON_LENGTH(p_cifras_json);
  IF v_n = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: anote al menos una cifra del ejemplar físico.';
  END IF;
  WHILE v_i < v_n DO
    SET v_digital = JSON_UNQUOTE(JSON_EXTRACT(p_cifras_json, CONCAT('$[', v_i, '].digital')));
    SET v_fisico  = JSON_UNQUOTE(JSON_EXTRACT(p_cifras_json, CONCAT('$[', v_i, '].fisico')));
    IF v_digital IS NULL OR v_fisico IS NULL OR v_fisico = 'null'
       OR NOT (v_digital REGEXP '^[0-9]+(\\.[0-9]+)?$') OR NOT (v_fisico REGEXP '^[0-9]+(\\.[0-9]+)?$') THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: anote todas las cifras del ejemplar físico (números enteros, sin signo).';
    END IF;
    IF CAST(v_digital AS DECIMAL(14,2)) <> CAST(v_fisico AS DECIMAL(14,2)) THEN
      SET v_dif = v_dif + 1;
    END IF;
    SET v_i = v_i + 1;
  END WHILE;

  SET v_obs = NULLIF(TRIM(p_observacion), '');
  IF (v_dif > 0 OR v_integro = 0) AND (v_obs IS NULL OR CHAR_LENGTH(v_obs) < 10) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: describa la discrepancia (al menos 10 caracteres) para reportarla al CEUNP.';
  END IF;
  SET v_estado = IF(v_dif = 0 AND v_integro = 1, 'CONFORME', 'OBSERVADO');

  IF v_estado = 'OBSERVADO' AND EXISTS (SELECT 1 FROM cotejo_acta
                                         WHERE id_usuario = p_id_usuario AND tipo_documento = v_tipo
                                           AND id_documento = v_id AND estado = 'OBSERVADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: ya reportó una discrepancia sobre este documento; espere la respuesta del CEUNP.';
  END IF;

  -- Personero acreditado de una lista del proceso (de esa mesa o general)
  IF v_docente IS NOT NULL THEN
    SELECT pe.id_personero INTO v_pers
      FROM personero pe
      JOIN lista_electoral l ON l.id_lista = pe.id_lista
      JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
     WHERE pe.id_docente = v_docente AND c.id_proceso = v_proceso AND pe.estado_acreditacion = 'ACREDITADO'
     ORDER BY (pe.id_mesa <=> v_mesa) DESC, pe.id_personero
     LIMIT 1;
  END IF;

  IF p_id_verificacion IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM verificacion_documento
                      WHERE id_verificacion = p_id_verificacion AND tipo_documento = v_tipo AND id_documento = v_id) THEN
    SET p_id_verificacion = NULL;
  END IF;

  START TRANSACTION;
  INSERT INTO cotejo_acta (id_verificacion, tipo_documento, id_documento, id_proceso, id_mesa, hash_integridad,
                           contenido_integro, id_usuario, rol, id_personero, cifras_json, lineas, diferencias,
                           observacion, estado, fecha)
  VALUES (p_id_verificacion, v_tipo, v_id, v_proceso, v_mesa, v_hash, v_integro, p_id_usuario, v_rol, v_pers,
          p_cifras_json, v_n, v_dif, v_obs, v_estado, NOW());
  SET v_id_cot = LAST_INSERT_ID();

  CALL sp_registrar_auditoria(p_id_usuario, v_docente, v_proceso,
       IF(v_estado = 'CONFORME', 'REGISTRAR_COTEJO_ACTA', 'REPORTAR_DISCREPANCIA_ACTA'),
       JSON_OBJECT('id_cotejo', v_id_cot, 'tipo', v_tipo, 'id_documento', v_id, 'id_mesa', v_mesa,
                   'lineas', v_n, 'diferencias', v_dif, 'contenido_integro', v_integro));
  COMMIT;

  SELECT v_id_cot AS id_cotejo, v_estado AS estado, v_tipo AS tipo_documento, v_id AS id_documento,
         v_proceso AS id_proceso, v_mesa AS id_mesa, v_n AS lineas, v_dif AS diferencias, v_integro AS contenido_integro;
END$$

-- El CEUNP atiende la discrepancia reportada: ACLARADA (el ejemplar se anotó o leyó mal, o la
-- diferencia ya se resolvió en el cómputo) o FUNDADA (procede la revisión: calificación del acta,
-- CUS14, o nulidad, CUS15). La respuesta no se modifica.
CREATE PROCEDURE sp_atender_cotejo_acta(
  IN p_id_cotejo  INT,
  IN p_id_usuario INT,
  IN p_decision   VARCHAR(10),
  IN p_respuesta  VARCHAR(1000)
)
BEGIN
  DECLARE v_estado  VARCHAR(10) DEFAULT NULL;
  DECLARE v_proceso INT;
  DECLARE v_rol     VARCHAR(20) DEFAULT NULL;
  DECLARE v_dec     VARCHAR(10);
  DECLARE v_resp    VARCHAR(1000);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SELECT CONCAT(rol, '') INTO v_rol FROM usuario WHERE id_usuario = p_id_usuario AND activo = 1;
  IF v_rol IS NULL OR v_rol <> 'CEUNP' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: solo el CEUNP atiende las discrepancias reportadas.';
  END IF;
  SET v_dec = UPPER(TRIM(p_decision));
  IF v_dec IS NULL OR v_dec NOT IN ('ACLARADA','FUNDADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: indique si la discrepancia queda aclarada o es fundada.';
  END IF;
  SET v_resp = NULLIF(TRIM(p_respuesta), '');
  IF v_resp IS NULL OR CHAR_LENGTH(v_resp) < 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: fundamente la respuesta (al menos 10 caracteres).';
  END IF;

  START TRANSACTION;
  SELECT CONCAT(estado, ''), id_proceso INTO v_estado, v_proceso FROM cotejo_acta WHERE id_cotejo = p_id_cotejo FOR UPDATE;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: el cotejo no existe.';
  END IF;
  IF v_estado <> 'OBSERVADO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS17: el cotejo no tiene una discrepancia pendiente de atención.';
  END IF;

  UPDATE cotejo_acta
     SET estado = 'ATENDIDO', decision = v_dec, respuesta = v_resp, fecha_respuesta = NOW(), id_usuario_respuesta = p_id_usuario
   WHERE id_cotejo = p_id_cotejo;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'ATENDER_DISCREPANCIA_ACTA',
       JSON_OBJECT('id_cotejo', p_id_cotejo, 'decision', v_dec));
  COMMIT;

  SELECT p_id_cotejo AS id_cotejo, 'ATENDIDO' AS estado, v_dec AS decision;
END$$

DELIMITER ;
