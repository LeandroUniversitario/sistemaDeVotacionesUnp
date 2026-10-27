-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 15_omisos_multas.sql  ·  CUS16 Reportar omisos y multas
--                         (CUN12 Aplicar multas por omisión, módulo M14: RF103 a RF107;
--                          reglas RN35, RN36 y RN40; Art. 67, 68 y Disp. Final 2.ª y 5.ª)
--
-- Diagrama de colaboración «Reportar omisos y multas» (modelo Rose, CUS16):
--   1  solicitarReporteOmisos()          -> v_omisos_proceso (vista previa del reporte)
--   2  generarMultas()                   -> sp_generar_multas (GenerarMultas)
--   3  obtenerUIT()                      -> parametro_global: UIT, MULTA_ELECTOR_OMISO_PCT, MULTA_MIEMBRO_MESA_OMISO_PCT (RF105)
--   4  consultarNoVotaron()              -> padron_electoral: hábil, no votó y su mesa funcionó (RF103)
--   5  consultarInasistentes()           -> miembro_mesa: titular con asistio = 0 (RF104)
--   6  insertar()                        -> multa (2.5 % y 3 % de la UIT, RN35)
--   7  mostrarReporteMultas()            -> reporte_multas y sp_emitir_resolucion_multas (resolución con SHA-256 y QR)
--   8  registrarJustificacion            -> PantallaMultas (CEUNP)
--   9  justificar()                      -> sp_registrar_justificacion (RegistrarJustificacion, RF106)
--   10 actualizarEstado()                -> multa JUSTIFICADA / EXONERADA (o se mantiene si se deniega)
--   11 confirmar()                       -> fila de confirmación del descargo
--
-- Qué agrega, sin duplicar lo que ya existe (tabla multa, sp_generar_multas y sp_actualizar_multa
-- de la sección G del 00):
--   · El omiso al voto es el elector hábil que no votó por ningún cargo y cuya mesa sí se
--     instaló. Quien estaba en una mesa NO INSTALADA no pudo votar y no se multa (RF58).
--     Quien asistió y no votó (CUS10 A3) se multa marcado, para que el CEUNP resuelva (Disp. Final 5.ª).
--   · El miembro de mesa omiso es el TITULAR sorteado que no se presentó (asistio = 0, CUS08).
--   · Mientras el CEUNP no emite la resolución, las multas se pueden regenerar: se recalculan
--     con la UIT vigente y salen las que ya no corresponden (por ejemplo, las que el
--     procedimiento anterior generó a electores de mesas no instaladas).
--   · La resolución del Pleno (quórum CEUNP_QUORUM_PLENO, RN36) determina las multas: fija su
--     contenido con huella SHA-256 y QR. Desde entonces las multas no se regeneran ni cambian de monto.
--   · La notificación a cada docente (correo institucional, cédula personal o portal).
--   · El descargo (RF106): la justificación que presenta el docente dentro del plazo
--     MULTA_PLAZO_JUSTIFICACION_DIAS y que el CEUNP admite o deniega, y la exoneración de oficio
--     por lo no previsto (RN40). Uno y otro con número de resolución único (RN36).
--   · El registro del pago con número de recibo. El sistema no cobra la multa (CUN12).
--   · RF107: vista v_reporte_gestion_mesas (participación por mesa, mesas instaladas,
--     miembros, incidencias, tiempo de atención y actas recibidas).
--
-- Uso: en una base ya creada, después de 14_nulidades_segunda_vuelta.sql (CUS15). No borra datos
-- ni recrea la base. Se puede volver a ejecutar. 00_script_unico_elecciones_unp.sql (sección 5f)
-- ya lo incluye.
-- =====================================================================
USE elecciones_unp;
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 1. Columnas nuevas de multa (sin ADD COLUMN IF NOT EXISTS: MariaDB y MySQL)
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_tmp_agregar_columna;
DELIMITER $$
CREATE PROCEDURE sp_tmp_agregar_columna(IN p_tabla VARCHAR(64), IN p_columna VARCHAR(64), IN p_definicion VARCHAR(500))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema = DATABASE() AND table_name = p_tabla AND column_name = p_columna) THEN
    SET @sql_cus16 = CONCAT('ALTER TABLE ', p_tabla, ' ADD COLUMN ', p_columna, ' ', p_definicion);
    PREPARE st_cus16 FROM @sql_cus16;
    EXECUTE st_cus16;
    DEALLOCATE PREPARE st_cus16;
  END IF;
END$$
DELIMITER ;

-- 10 actualizarEstado(): la justificación admitida deja la multa JUSTIFICADA (RF106)
ALTER TABLE multa
  MODIFY COLUMN estado_pago ENUM('PENDIENTE','PAGADA','EXONERADA','JUSTIFICADA') NOT NULL DEFAULT 'PENDIENTE';

CALL sp_tmp_agregar_columna('multa', 'id_mesa',
     'INT NULL COMMENT ''CUS16: mesa del elector (OMISO_VOTACION) o de la que era miembro (OMISO_MESA)'' AFTER motivo');
CALL sp_tmp_agregar_columna('multa', 'rol_mesa',
     'VARCHAR(12) NULL COMMENT ''CUS16: cargo del miembro titular que no asistió'' AFTER id_mesa');
CALL sp_tmp_agregar_columna('multa', 'asistio_sin_votar',
     'BOOLEAN NOT NULL DEFAULT FALSE COMMENT ''CUS16: asistió a la mesa y no votó (CUS10 A3, Disp. Final 5.ª)'' AFTER rol_mesa');
CALL sp_tmp_agregar_columna('multa', 'fecha_notificacion',
     'DATETIME NULL COMMENT ''CUS16: notificación de la multa al docente'' AFTER fecha_pago');
CALL sp_tmp_agregar_columna('multa', 'medio_notificacion',
     'ENUM(''CORREO_INSTITUCIONAL'',''CEDULA_PERSONAL'',''PORTAL_ELECTORAL'') NULL AFTER fecha_notificacion');
CALL sp_tmp_agregar_columna('multa', 'documento_notificacion',
     'VARCHAR(80) NULL COMMENT ''CUS16: N.º de cédula, oficio o correo'' AFTER medio_notificacion');
CALL sp_tmp_agregar_columna('multa', 'numero_recibo',
     'VARCHAR(40) NULL COMMENT ''CUS16: recibo de pago (el sistema no cobra la multa)'' AFTER documento_notificacion');
CALL sp_tmp_agregar_columna('multa', 'fecha_actualizacion',
     'DATETIME NULL AFTER observacion');
CALL sp_tmp_agregar_columna('multa', 'id_usuario_actualizacion',
     'INT NULL AFTER fecha_actualizacion');
DROP PROCEDURE IF EXISTS sp_tmp_agregar_columna;

-- ---------------------------------------------------------------------
-- 2. Tablas nuevas
-- ---------------------------------------------------------------------

-- 2 generarMultas() y 7 mostrarReporteMultas(): un reporte por proceso. GENERADO mientras se
-- puede regenerar; RESUELTO cuando el Pleno emite la resolución que determina las multas.
CREATE TABLE IF NOT EXISTS reporte_multas (
  id_reporte            INT AUTO_INCREMENT PRIMARY KEY,
  id_proceso            INT NOT NULL,
  estado                ENUM('GENERADO','RESUELTO') NOT NULL DEFAULT 'GENERADO',
  -- 3 obtenerUIT(): valores con los que se calcularon las multas (RF105)
  uit_referencia        DECIMAL(10,2) NOT NULL,
  pct_elector           DECIMAL(5,2)  NOT NULL,
  pct_miembro           DECIMAL(5,2)  NOT NULL,
  omisos_votacion       INT NOT NULL DEFAULT 0,
  omisos_mesa           INT NOT NULL DEFAULT 0,
  monto_total           DECIMAL(12,2) NOT NULL DEFAULT 0,
  veces_generado        INT NOT NULL DEFAULT 1,
  fecha_generacion      DATETIME NOT NULL,
  id_usuario_generacion INT NULL,
  -- resolución del Pleno (RN36)
  numero_resolucion     VARCHAR(40) NULL,
  fundamento            VARCHAR(1000) NULL,
  miembros_pleno        TINYINT NULL,
  fecha_resolucion      DATETIME NULL,
  id_usuario_resolucion INT NULL,
  contenido_json        LONGTEXT NULL,
  hash_integridad       CHAR(64) NULL,
  token_qr_hash         CHAR(64) NULL,
  UNIQUE KEY uq_reporte_multas_proceso (id_proceso),
  UNIQUE KEY uq_reporte_multas_resolucion (numero_resolucion),
  UNIQUE KEY uq_reporte_multas_token (token_qr_hash),
  CONSTRAINT chk_reporte_multas_resuelto CHECK (estado = 'GENERADO'
    OR (numero_resolucion IS NOT NULL AND fecha_resolucion IS NOT NULL AND contenido_json IS NOT NULL AND hash_integridad IS NOT NULL)),
  CONSTRAINT chk_reporte_multas_json CHECK (contenido_json IS NULL OR JSON_VALID(contenido_json)),
  CONSTRAINT fk_reporte_multas_proceso FOREIGN KEY (id_proceso)            REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_reporte_multas_u_gen   FOREIGN KEY (id_usuario_generacion) REFERENCES usuario(id_usuario),
  CONSTRAINT fk_reporte_multas_u_res   FOREIGN KEY (id_usuario_resolucion) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9 justificar() (RF106): justificación del docente que el CEUNP admite o deniega, o
-- exoneración de oficio por lo no previsto en el reglamento (RN40). Una justificación por multa.
CREATE TABLE IF NOT EXISTS multa_justificacion (
  id_justificacion   INT AUTO_INCREMENT PRIMARY KEY,
  id_multa           INT NOT NULL,
  tipo               ENUM('JUSTIFICACION','EXONERACION') NOT NULL,
  causal             ENUM('SALUD','DUELO','COMISION_SERVICIO','LICENCIA','CASO_FORTUITO','FALLECIMIENTO','ERROR_PADRON','OTRA') NOT NULL,
  sustento           VARCHAR(1000) NOT NULL,
  documento          VARCHAR(150) NULL,                 -- certificado, constancia o expediente que acompaña
  fecha_presentacion DATETIME NOT NULL,
  decision           ENUM('ADMITIDA','DENEGADA') NOT NULL,
  fundamento         VARCHAR(1000) NOT NULL,
  numero_resolucion  VARCHAR(40) NOT NULL,
  miembros_pleno     TINYINT NOT NULL,
  fecha_resolucion   DATETIME NOT NULL,
  id_usuario         INT NULL,
  justificacion_unica INT AS (IF(tipo = 'JUSTIFICACION', id_multa, NULL)) STORED,
  admitida_unica      INT AS (IF(decision = 'ADMITIDA', id_multa, NULL)) STORED,
  UNIQUE KEY uq_mjust_resolucion (numero_resolucion),
  UNIQUE KEY uq_mjust_justificacion (justificacion_unica),
  UNIQUE KEY uq_mjust_admitida (admitida_unica),
  KEY ix_mjust_multa (id_multa),
  CONSTRAINT chk_mjust_exoneracion CHECK (tipo = 'JUSTIFICACION' OR decision = 'ADMITIDA'),
  CONSTRAINT fk_mjust_multa   FOREIGN KEY (id_multa)   REFERENCES multa(id_multa),
  CONSTRAINT fk_mjust_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 3. Parámetros (editables en la pantalla Parámetros, RF105)
-- ---------------------------------------------------------------------
INSERT INTO parametro_global (clave, valor, descripcion) VALUES
  ('MULTA_PLAZO_JUSTIFICACION_DIAS', '10',
   'Días desde la notificación de la multa para presentar la justificación ante el CEUNP (RF106); 0 = sin plazo'),
  ('CEUNP_QUORUM_PLENO', '5',
   'Miembros del Pleno del CEUNP necesarios para resolver una apelación (RN36)')
ON DUPLICATE KEY UPDATE descripcion = descripcion;

-- ---------------------------------------------------------------------
-- 4. Función: número de resolución ya usado en cualquier caso de uso (RN36)
--    Redefine la del CUS15 agregando las resoluciones de multas y de descargos.
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
      OR EXISTS (SELECT 1 FROM impugnacion_electoral WHERE numero_resolucion = p_numero)
      OR EXISTS (SELECT 1 FROM reporte_multas        WHERE numero_resolucion = p_numero)
      OR EXISTS (SELECT 1 FROM multa_justificacion   WHERE numero_resolucion = p_numero);
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- 5. Triggers
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_multa_bi_cus16;
DROP TRIGGER IF EXISTS trg_multa_bu_cus16;
DROP TRIGGER IF EXISTS trg_multa_bd_cus16;
DROP TRIGGER IF EXISTS trg_rmultas_bu;
DROP TRIGGER IF EXISTS trg_rmultas_bd;
DROP TRIGGER IF EXISTS trg_mjust_bu;
DROP TRIGGER IF EXISTS trg_mjust_bd;
DROP TRIGGER IF EXISTS trg_computo_bu_cus16;
DROP TRIGGER IF EXISTS trg_calificacion_bi_cus16;
DROP TRIGGER IF EXISTS trg_impugnacion_bu_cus16;

DELIMITER $$

-- Determinadas por la resolución, las multas del proceso ya no se agregan (RN35)
CREATE TRIGGER trg_multa_bi_cus16 BEFORE INSERT ON multa
FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM reporte_multas WHERE id_proceso = NEW.id_proceso AND estado = 'RESUELTO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: las multas del proceso ya fueron determinadas por resolución del CEUNP.';
  END IF;
END$$

-- Antes de la resolución las multas se recalculan; después solo cambia su estado, una vez,
-- desde PENDIENTE (pago, justificación o exoneración), y su notificación no se modifica.
CREATE TRIGGER trg_multa_bu_cus16 BEFORE UPDATE ON multa
FOR EACH ROW
BEGIN
  DECLARE v_resuelto INT DEFAULT 0;
  SET v_resuelto = EXISTS (SELECT 1 FROM reporte_multas WHERE id_proceso = OLD.id_proceso AND estado = 'RESUELTO');
  IF NOT (NEW.id_docente <=> OLD.id_docente) OR NOT (NEW.id_proceso <=> OLD.id_proceso) OR NOT (NEW.motivo <=> OLD.motivo) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: el docente, el proceso y el motivo de la multa no se modifican.';
  END IF;
  IF v_resuelto = 1 AND (NOT (NEW.uit_referencia <=> OLD.uit_referencia) OR NOT (NEW.porcentaje_uit <=> OLD.porcentaje_uit)
                         OR NOT (NEW.monto <=> OLD.monto) OR NOT (NEW.id_mesa <=> OLD.id_mesa)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: la multa determinada por resolución no cambia de monto.';
  END IF;
  IF NOT (NEW.estado_pago <=> OLD.estado_pago) THEN
    IF v_resuelto = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF103: la multa se paga o se justifica después de la resolución del CEUNP que la determina.';
    END IF;
    IF OLD.estado_pago <> 'PENDIENTE' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF106: el pago, la justificación o la exoneración registrados no se revierten.';
    END IF;
  END IF;
  IF OLD.fecha_notificacion IS NOT NULL AND (NOT (NEW.fecha_notificacion <=> OLD.fecha_notificacion)
       OR NOT (NEW.medio_notificacion <=> OLD.medio_notificacion) OR NOT (NEW.documento_notificacion <=> OLD.documento_notificacion)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: la notificación registrada no se modifica.';
  END IF;
END$$

-- Solo sp_generar_multas retira, antes de la resolución, la multa que ya no corresponde.
-- La limpieza de datos usa TRUNCATE (02_limpiar_datos_electorales.sql).
CREATE TRIGGER trg_multa_bd_cus16 BEFORE DELETE ON multa
FOR EACH ROW
BEGIN
  IF NOT (@cus16_regenerar <=> OLD.id_proceso) OR OLD.estado_pago <> 'PENDIENTE'
     OR EXISTS (SELECT 1 FROM reporte_multas WHERE id_proceso = OLD.id_proceso AND estado = 'RESUELTO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: una multa no se elimina; si procede, se justifica o se exonera (RF106).';
  END IF;
END$$

-- RN36: la resolución que determina las multas es inapelable
CREATE TRIGGER trg_rmultas_bu BEFORE UPDATE ON reporte_multas
FOR EACH ROW
BEGIN
  IF OLD.estado = 'RESUELTO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: la resolución de multas del CEUNP no se modifica.';
  END IF;
  IF NOT (NEW.id_proceso <=> OLD.id_proceso) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El reporte de multas no cambia de proceso.';
  END IF;
END$$

CREATE TRIGGER trg_rmultas_bd BEFORE DELETE ON reporte_multas
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: el reporte de multas no se elimina.';
END$$

CREATE TRIGGER trg_mjust_bu BEFORE UPDATE ON multa_justificacion
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: la decisión del CEUNP sobre el descargo es inapelable.';
END$$

CREATE TRIGGER trg_mjust_bd BEFORE DELETE ON multa_justificacion
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el descargo resuelto no se elimina.';
END$$

-- RN36: el número de resolución tampoco se repite frente a las multas y sus descargos
CREATE TRIGGER trg_computo_bu_cus16 BEFORE UPDATE ON computo_proceso
FOR EACH ROW
BEGIN
  IF NEW.numero_resolucion IS NOT NULL AND NOT (NEW.numero_resolucion <=> OLD.numero_resolucion)
     AND (EXISTS (SELECT 1 FROM reporte_multas WHERE numero_resolucion = NEW.numero_resolucion)
          OR EXISTS (SELECT 1 FROM multa_justificacion WHERE numero_resolucion = NEW.numero_resolucion)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;
END$$

CREATE TRIGGER trg_calificacion_bi_cus16 BEFORE INSERT ON calificacion_mesa
FOR EACH ROW
BEGIN
  IF NEW.numero_resolucion IS NOT NULL
     AND (EXISTS (SELECT 1 FROM reporte_multas WHERE numero_resolucion = NEW.numero_resolucion)
          OR EXISTS (SELECT 1 FROM multa_justificacion WHERE numero_resolucion = NEW.numero_resolucion)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;
END$$

CREATE TRIGGER trg_impugnacion_bu_cus16 BEFORE UPDATE ON impugnacion_electoral
FOR EACH ROW
BEGIN
  IF NEW.numero_resolucion IS NOT NULL AND NOT (NEW.numero_resolucion <=> OLD.numero_resolucion)
     AND (EXISTS (SELECT 1 FROM reporte_multas WHERE numero_resolucion = NEW.numero_resolucion)
          OR EXISTS (SELECT 1 FROM multa_justificacion WHERE numero_resolucion = NEW.numero_resolucion)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- 6. Vistas
-- ---------------------------------------------------------------------

-- 1 solicitarReporteOmisos(): quiénes corresponden a multa, antes y después de generarla.
--   4 consultarNoVotaron(): elector hábil que no votó por ningún cargo, con mesa que se
--     instaló (la mesa NO INSTALADA no permitió votar: RF58). Marca a quien asistió sin votar.
--   5 consultarInasistentes(): miembro TITULAR sorteado que no se presentó (CUS08).
CREATE OR REPLACE VIEW v_omisos_proceso AS
SELECT x.id_proceso, x.id_docente, _utf8mb4'OMISO_VOTACION' COLLATE utf8mb4_unicode_ci AS motivo, x.id_mesa,
       CAST(NULL AS CHAR(12) CHARACTER SET utf8mb4) COLLATE utf8mb4_unicode_ci AS rol_mesa,
       IF(EXISTS (SELECT 1 FROM asistencia_elector a WHERE a.id_proceso = x.id_proceso AND a.id_docente = x.id_docente), 1, 0) AS asistio_sin_votar
  FROM (SELECT pe.id_proceso, pe.id_docente, MIN(pe.id_mesa) AS id_mesa
          FROM padron_electoral pe
          JOIN mesa_electoral m ON m.id_mesa = pe.id_mesa
         WHERE pe.habilitado_para_votar = 1
         GROUP BY pe.id_proceso, pe.id_docente
        HAVING MAX(pe.ya_voto) = 0 AND MAX(m.hora_instalacion IS NOT NULL) = 1) x
UNION ALL
SELECT m.id_proceso, mm.id_docente, _utf8mb4'OMISO_MESA' COLLATE utf8mb4_unicode_ci, m.id_mesa,
       CONVERT(CONCAT(mm.rol, '') USING utf8mb4) COLLATE utf8mb4_unicode_ci, 0
  FROM miembro_mesa mm
  JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
 WHERE mm.titular = 1 AND mm.asistio = 0;

-- RN35: multas con datos del docente. Conserva las columnas anteriores (ProcesoService) y agrega
-- la mesa, la notificación, el pago, el último descargo y el plazo para justificar (CUS16).
CREATE OR REPLACE VIEW v_multas_detalle AS
SELECT mu.id_multa, mu.id_proceso, p.nombre AS proceso,
       d.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS docente, f.nombre AS facultad,
       mu.motivo, mu.uit_referencia, mu.porcentaje_uit, mu.monto,
       mu.estado_pago, mu.fecha_generacion, mu.fecha_pago,
       p.tipo AS tipo_proceso, p.estado AS estado_proceso, dp.nombre AS departamento, CONCAT(d.categoria, '') AS categoria, d.email,
       mu.id_mesa, m.numero_mesa, m.ubicacion, mu.rol_mesa, mu.asistio_sin_votar, mu.observacion,
       mu.fecha_notificacion, CONCAT(mu.medio_notificacion, '') AS medio_notificacion, mu.documento_notificacion,
       mu.numero_recibo, mu.fecha_actualizacion,
       r.estado AS estado_reporte, r.numero_resolucion AS resolucion_multas, r.fecha_resolucion AS fecha_resolucion_multas,
       (SELECT COUNT(*) FROM multa_justificacion j WHERE j.id_multa = mu.id_multa) AS descargos,
       j.id_justificacion, CONCAT(j.tipo, '') AS tipo_descargo, CONCAT(j.causal, '') AS causal_descargo, j.decision AS decision_descargo,
       j.numero_resolucion AS resolucion_descargo, j.fecha_resolucion AS fecha_descargo,
       IF(r.estado = 'RESUELTO' AND g.dias > 0,
          COALESCE(mu.fecha_notificacion, r.fecha_resolucion) + INTERVAL g.dias DAY, NULL) AS limite_justificacion
  FROM multa mu
  JOIN proceso_electoral p    ON p.id_proceso = mu.id_proceso
  JOIN docente d              ON d.id_docente = mu.id_docente
  JOIN facultad f             ON f.id_facultad = d.id_facultad
  LEFT JOIN departamento dp   ON dp.id_departamento = d.id_departamento
  LEFT JOIN mesa_electoral m  ON m.id_mesa = mu.id_mesa
  LEFT JOIN reporte_multas r  ON r.id_proceso = mu.id_proceso
  LEFT JOIN multa_justificacion j ON j.id_justificacion = (SELECT MAX(x.id_justificacion) FROM multa_justificacion x
                                                           WHERE x.id_multa = mu.id_multa)
  CROSS JOIN (SELECT COALESCE(ROUND((SELECT CAST(valor AS DECIMAL(8,2)) FROM parametro_global
                                     WHERE clave = 'MULTA_PLAZO_JUSTIFICACION_DIAS')), 10) AS dias) g;

-- RF107: reporte de gestión por mesa (participación, instalación, miembros, incidencias,
-- tiempo de atención del elector y actas recibidas por el CEUNP).
CREATE OR REPLACE VIEW v_reporte_gestion_mesas AS
SELECT m.id_proceso, m.id_mesa, m.numero_mesa, m.ubicacion, m.estado, m.hora_instalacion, m.hora_cierre,
       (SELECT COUNT(DISTINCT pe.id_docente) FROM padron_electoral pe
         WHERE pe.id_mesa = m.id_mesa AND pe.habilitado_para_votar = 1) AS electores,
       (SELECT COUNT(DISTINCT pe.id_docente) FROM padron_electoral pe
         WHERE pe.id_mesa = m.id_mesa AND pe.habilitado_para_votar = 1 AND pe.ya_voto = 1) AS votaron,
       (SELECT COUNT(*) FROM asistencia_elector a WHERE a.id_mesa = m.id_mesa) AS asistieron,
       (SELECT COUNT(*) FROM miembro_mesa mm WHERE mm.id_mesa = m.id_mesa AND mm.titular = 1 AND mm.asistio = 1) AS titulares_presentes,
       (SELECT COUNT(*) FROM miembro_mesa mm WHERE mm.id_mesa = m.id_mesa AND mm.titular = 1 AND mm.asistio = 0) AS titulares_ausentes,
       (SELECT COUNT(*) FROM miembro_mesa mm WHERE mm.id_mesa = m.id_mesa AND mm.titular = 0 AND mm.rol_instalacion IS NOT NULL) AS suplentes_en_funcion,
       (SELECT COUNT(*) FROM incidencia_mesa i WHERE i.id_mesa = m.id_mesa) AS incidencias,
       (SELECT ROUND(AVG(TIMESTAMPDIFF(SECOND, a.hora_asistencia, h.fecha_cierre)))
          FROM habilitacion_terminal h JOIN asistencia_elector a ON a.id_asistencia = h.id_asistencia
         WHERE a.id_mesa = m.id_mesa AND h.estado = 'CONSUMIDA') AS atencion_promedio_seg,
       (SELECT COUNT(DISTINCT ac.tipo) FROM acta_electoral ac WHERE ac.id_mesa = m.id_mesa) AS actas_emitidas,
       e.estado AS estado_escrutinio, e.fecha_entrega, e.recibido_por
  FROM mesa_electoral m
  LEFT JOIN escrutinio_mesa e ON e.id_mesa = m.id_mesa;

-- ---------------------------------------------------------------------
-- 7. Procedimientos
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_generar_multas;
DROP PROCEDURE IF EXISTS sp_emitir_resolucion_multas;
DROP PROCEDURE IF EXISTS sp_notificar_multas;
DROP PROCEDURE IF EXISTS sp_registrar_justificacion;
DROP PROCEDURE IF EXISTS sp_registrar_pago_multa;
DROP PROCEDURE IF EXISTS sp_actualizar_multa;
DROP PROCEDURE IF EXISTS sp_verificar_resolucion_multas;

DELIMITER $$

-- Mensajes 2 a 6 (GenerarMultas). Redefine el de la sección G con la misma firma:
--   3 obtenerUIT(): UIT y porcentajes de parametro_global (RF105)
--   4 consultarNoVotaron() y 5 consultarInasistentes(): v_omisos_proceso (RF103, RF104)
--   6 insertar(): una multa por docente y motivo con monto = UIT * % / 100 (RN35)
-- Se genera con la votación concluida en todas las mesas. Mientras no haya resolución, al
-- volver a ejecutarlo recalcula los montos y retira las multas que ya no corresponden.
CREATE PROCEDURE sp_generar_multas(
  IN p_id_proceso INT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_estado   VARCHAR(20) DEFAULT NULL;
  DECLARE v_reporte  VARCHAR(10) DEFAULT NULL;
  DECLARE v_res      VARCHAR(40);
  DECLARE v_uit      DECIMAL(12,2);
  DECLARE v_pct_elec DECIMAL(12,2);
  DECLARE v_pct_mesa DECIMAL(12,2);
  DECLARE v_abiertas INT DEFAULT 0;
  DECLARE v_instal   INT DEFAULT 0;
  DECLARE v_retiradas INT DEFAULT 0;
  DECLARE v_n1       INT DEFAULT 0;
  DECLARE v_n2       INT DEFAULT 0;
  DECLARE v_total    DECIMAL(12,2) DEFAULT 0;
  DECLARE v_msg      VARCHAR(255);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    SET @cus16_regenerar = NULL;
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT estado INTO v_estado FROM proceso_electoral WHERE id_proceso = p_id_proceso FOR UPDATE;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;
  IF v_estado NOT IN ('CERRADO','FINALIZADO','ANULADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: las multas se generan con la votación ya concluida.';
  END IF;
  SELECT COUNT(*), COALESCE(SUM(hora_instalacion IS NOT NULL), 0) INTO v_abiertas, v_instal
    FROM mesa_electoral WHERE id_proceso = p_id_proceso;
  IF v_instal = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF103: ninguna mesa del proceso se instaló; no hubo sufragio que omitir.';
  END IF;
  SELECT COUNT(*) INTO v_abiertas FROM mesa_electoral WHERE id_proceso = p_id_proceso AND estado IN ('PENDIENTE','INSTALADA');
  IF v_abiertas > 0 THEN
    SET v_msg = CONCAT('RF103: ', v_abiertas, ' mesa(s) aún no cierran su sufragio (CUS11).');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  SELECT estado, numero_resolucion INTO v_reporte, v_res FROM reporte_multas WHERE id_proceso = p_id_proceso FOR UPDATE;
  IF v_reporte = 'RESUELTO' THEN
    SET v_msg = CONCAT('RN35: las multas ya fueron determinadas por la Resolución ', v_res, '; no se regeneran.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  -- 3 obtenerUIT()
  SET v_uit      = fn_parametro_decimal('UIT');
  SET v_pct_elec = fn_parametro_decimal('MULTA_ELECTOR_OMISO_PCT');
  SET v_pct_mesa = fn_parametro_decimal('MULTA_MIEMBRO_MESA_OMISO_PCT');
  IF v_uit IS NULL OR v_pct_elec IS NULL OR v_pct_mesa IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF105: faltan parámetros: UIT y porcentajes de multa.';
  END IF;
  IF v_uit <= 0 OR v_pct_elec < 0 OR v_pct_elec > 100 OR v_pct_mesa < 0 OR v_pct_mesa > 100 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF105: la UIT debe ser positiva y los porcentajes de multa estar entre 0 y 100.';
  END IF;

  -- Retira las multas que ya no corresponden (solo antes de la resolución)
  SET @cus16_regenerar = p_id_proceso;
  DELETE mu FROM multa mu
   WHERE mu.id_proceso = p_id_proceso AND mu.estado_pago = 'PENDIENTE'
     AND NOT EXISTS (SELECT 1 FROM v_omisos_proceso o
                      WHERE o.id_proceso = mu.id_proceso AND o.id_docente = mu.id_docente AND o.motivo = mu.motivo);
  SET v_retiradas = ROW_COUNT();
  SET @cus16_regenerar = NULL;

  -- 4 consultarNoVotaron() · 5 consultarInasistentes() · 6 insertar()
  INSERT INTO multa (id_docente, id_proceso, motivo, id_mesa, rol_mesa, asistio_sin_votar, uit_referencia, porcentaje_uit, monto)
  SELECT o.id_docente, o.id_proceso, o.motivo, o.id_mesa, o.rol_mesa, o.asistio_sin_votar, v_uit,
         IF(o.motivo = 'OMISO_VOTACION', v_pct_elec, v_pct_mesa),
         ROUND(v_uit * IF(o.motivo = 'OMISO_VOTACION', v_pct_elec, v_pct_mesa) / 100, 2)
    FROM v_omisos_proceso o
   WHERE o.id_proceso = p_id_proceso
  ON DUPLICATE KEY UPDATE id_mesa = VALUES(id_mesa), rol_mesa = VALUES(rol_mesa), asistio_sin_votar = VALUES(asistio_sin_votar),
                          uit_referencia = VALUES(uit_referencia), porcentaje_uit = VALUES(porcentaje_uit), monto = VALUES(monto),
                          fecha_generacion = NOW();

  SELECT COALESCE(SUM(motivo = 'OMISO_VOTACION'), 0), COALESCE(SUM(motivo = 'OMISO_MESA'), 0), COALESCE(SUM(monto), 0)
    INTO v_n1, v_n2, v_total
    FROM multa WHERE id_proceso = p_id_proceso;

  INSERT INTO reporte_multas (id_proceso, estado, uit_referencia, pct_elector, pct_miembro, omisos_votacion, omisos_mesa,
                              monto_total, veces_generado, fecha_generacion, id_usuario_generacion)
  VALUES (p_id_proceso, 'GENERADO', v_uit, v_pct_elec, v_pct_mesa, v_n1, v_n2, v_total, 1, NOW(), p_id_usuario)
  ON DUPLICATE KEY UPDATE uit_referencia = VALUES(uit_referencia), pct_elector = VALUES(pct_elector),
                          pct_miembro = VALUES(pct_miembro), omisos_votacion = VALUES(omisos_votacion),
                          omisos_mesa = VALUES(omisos_mesa), monto_total = VALUES(monto_total),
                          veces_generado = veces_generado + 1, fecha_generacion = VALUES(fecha_generacion),
                          id_usuario_generacion = VALUES(id_usuario_generacion);

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'GENERAR_MULTAS',
       JSON_OBJECT('omisos_votacion', v_n1, 'omisos_mesa', v_n2, 'monto_total', v_total, 'uit', v_uit,
                   'retiradas', v_retiradas));
  COMMIT;

  SELECT motivo, COUNT(*) AS multas, SUM(monto) AS total_soles
    FROM multa WHERE id_proceso = p_id_proceso GROUP BY motivo;
END$$

-- Mensaje 7 mostrarReporteMultas(): el Pleno del CEUNP (quórum CEUNP_QUORUM_PLENO, RN36) emite
-- la resolución que determina las multas del reporte generado. Guarda su contenido con huella
-- SHA-256 y devuelve el token del QR (solo esta vez). Desde entonces las multas quedan fijas.
CREATE PROCEDURE sp_emitir_resolucion_multas(
  IN p_id_proceso        INT,
  IN p_id_usuario        INT,
  IN p_numero_resolucion VARCHAR(40),
  IN p_miembros_pleno    INT,
  IN p_fundamento        VARCHAR(1000)
)
BEGIN
  DECLARE v_nombre    VARCHAR(200) DEFAULT NULL;
  DECLARE v_tipo      VARCHAR(20);
  DECLARE v_estado    VARCHAR(20);
  DECLARE v_reporte   INT DEFAULT NULL;
  DECLARE v_rep_est   VARCHAR(10);
  DECLARE v_uit       DECIMAL(10,2);
  DECLARE v_pe        DECIMAL(5,2);
  DECLARE v_pm        DECIMAL(5,2);
  DECLARE v_res       VARCHAR(40);
  DECLARE v_fund      VARCHAR(1000);
  DECLARE v_quorum    INT;
  DECLARE v_vigentes  INT DEFAULT 0;
  DECLARE v_coinciden INT DEFAULT 0;
  DECLARE v_n1        INT DEFAULT 0;
  DECLARE v_n2        INT DEFAULT 0;
  DECLARE v_total     DECIMAL(12,2) DEFAULT 0;
  DECLARE v_lista     LONGTEXT;
  DECLARE v_part      LONGTEXT;
  DECLARE v_ahora     DATETIME;
  DECLARE v_contenido LONGTEXT;
  DECLARE v_token     CHAR(64);
  DECLARE v_msg       VARCHAR(255);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET SESSION group_concat_max_len = 16000000;
  START TRANSACTION;
  SELECT nombre, tipo, estado INTO v_nombre, v_tipo, v_estado FROM proceso_electoral WHERE id_proceso = p_id_proceso;
  IF v_nombre IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;
  SELECT id_reporte, estado, uit_referencia, pct_elector, pct_miembro
    INTO v_reporte, v_rep_est, v_uit, v_pe, v_pm
    FROM reporte_multas WHERE id_proceso = p_id_proceso FOR UPDATE;
  IF v_reporte IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF103: genere primero el reporte de omisos y multas.';
  END IF;
  IF v_rep_est = 'RESUELTO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: las multas del proceso ya fueron determinadas por resolución del CEUNP.';
  END IF;

  -- El reporte debe estar al día: las multas generadas coinciden con los omisos actuales
  SELECT COUNT(*) INTO v_vigentes FROM v_omisos_proceso WHERE id_proceso = p_id_proceso;
  SELECT COUNT(*) INTO v_coinciden
    FROM multa mu JOIN v_omisos_proceso o ON o.id_proceso = mu.id_proceso AND o.id_docente = mu.id_docente AND o.motivo = mu.motivo
   WHERE mu.id_proceso = p_id_proceso;
  SELECT COUNT(*) INTO v_n1 FROM multa WHERE id_proceso = p_id_proceso;
  IF v_vigentes <> v_coinciden OR v_n1 <> v_coinciden THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF103: el reporte no está al día con el padrón y las mesas; vuelva a generar las multas.';
  END IF;
  IF EXISTS (SELECT 1 FROM multa WHERE id_proceso = p_id_proceso AND uit_referencia <> v_uit) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF105: las multas no se calcularon con la misma UIT; vuelva a generarlas.';
  END IF;

  SET v_res = NULLIF(TRIM(p_numero_resolucion), '');
  IF v_res IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: las multas se determinan por resolución del CEUNP; indique su número.';
  END IF;
  IF fn_resolucion_en_uso(v_res) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;
  SET v_quorum = COALESCE(ROUND((SELECT CAST(valor AS DECIMAL(6,2)) FROM parametro_global WHERE clave = 'CEUNP_QUORUM_PLENO')), 5);
  IF p_miembros_pleno IS NULL OR p_miembros_pleno < v_quorum OR p_miembros_pleno > 9 THEN
    SET v_msg = CONCAT('RN36: el Pleno del CEUNP resuelve con quórum de ', v_quorum, ' de sus 9 miembros.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  SET v_fund = NULLIF(TRIM(p_fundamento), '');
  IF v_fund IS NOT NULL AND CHAR_LENGTH(v_fund) < 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el fundamento debe tener al menos 10 caracteres.';
  END IF;
  SET v_fund = COALESCE(v_fund, CONCAT('Concluida la votación del proceso «', v_nombre, '», se identificó a los docentes ',
                        'hábiles que no votaron y a los miembros titulares de mesa que no asistieron, conforme a los ',
                        'artículos 67 y 68 del Reglamento de Elecciones.'));

  SELECT COALESCE(SUM(motivo = 'OMISO_VOTACION'), 0), COALESCE(SUM(motivo = 'OMISO_MESA'), 0), COALESCE(SUM(monto), 0)
    INTO v_n1, v_n2, v_total
    FROM multa WHERE id_proceso = p_id_proceso;
  SELECT CONCAT('[', COALESCE(GROUP_CONCAT(JSON_OBJECT('id_multa', mu.id_multa, 'dni', d.dni,
                                                       'docente', CONCAT(d.apellidos, ', ', d.nombres),
                                                       'facultad', f.nombre, 'motivo', mu.motivo,
                                                       'mesa', m.numero_mesa, 'rol', mu.rol_mesa,
                                                       'asistio_sin_votar', IF(mu.asistio_sin_votar, 'true', 'false'),
                                                       'porcentaje', mu.porcentaje_uit, 'monto', mu.monto)
                                           ORDER BY FIELD(mu.motivo, 'OMISO_MESA', 'OMISO_VOTACION'), d.apellidos, d.nombres
                                           SEPARATOR ','), ''), ']')
    INTO v_lista
    FROM multa mu
    JOIN docente d  ON d.id_docente = mu.id_docente
    JOIN facultad f ON f.id_facultad = d.id_facultad
    LEFT JOIN mesa_electoral m ON m.id_mesa = mu.id_mesa
   WHERE mu.id_proceso = p_id_proceso;
  SELECT JSON_OBJECT('electores', electores_habiles, 'votaron', votaron, 'porcentaje', participacion_pct)
    INTO v_part FROM v_quorum_proceso WHERE id_proceso = p_id_proceso;

  SET v_ahora = NOW();
  SET v_contenido = CONCAT(
      '{"tipo":"RESOLUCION_MULTAS"',
      ',"id_proceso":', p_id_proceso,
      ',"proceso":', JSON_QUOTE(v_nombre),
      ',"vuelta":', JSON_QUOTE(v_tipo),
      ',"estado_proceso":', JSON_QUOTE(v_estado),
      ',"resolucion":', JSON_QUOTE(v_res),
      ',"fecha":', JSON_QUOTE(DATE_FORMAT(v_ahora, '%Y-%m-%d %H:%i:%s')),
      ',"pleno":{"miembros":', p_miembros_pleno, ',"quorum":', v_quorum, '}',
      ',"fundamento":', JSON_QUOTE(v_fund),
      ',"uit":', v_uit,
      ',"porcentaje_elector":', v_pe,
      ',"porcentaje_miembro":', v_pm,
      ',"monto_elector":', ROUND(v_uit * v_pe / 100, 2),
      ',"monto_miembro":', ROUND(v_uit * v_pm / 100, 2),
      ',"participacion":', COALESCE(v_part, 'null'),
      ',"omisos_votacion":', v_n1,
      ',"omisos_mesa":', v_n2,
      ',"monto_total":', v_total,
      ',"multas":', v_lista,
      ',"nota":', JSON_QUOTE('El sistema determina las multas; no las cobra. El docente puede justificar su inasistencia ante el CEUNP (Disp. Final 2.ª y 5.ª).'),
      '}');
  SET v_token = SHA2(CONCAT(UUID(), RAND(), p_id_proceso, 'MULTAS', NOW(6)), 256);

  UPDATE reporte_multas
     SET estado = 'RESUELTO', numero_resolucion = v_res, fundamento = v_fund, miembros_pleno = p_miembros_pleno,
         fecha_resolucion = v_ahora, id_usuario_resolucion = p_id_usuario, omisos_votacion = v_n1, omisos_mesa = v_n2,
         monto_total = v_total, contenido_json = v_contenido, hash_integridad = SHA2(v_contenido, 256),
         token_qr_hash = SHA2(v_token, 256)
   WHERE id_reporte = v_reporte;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'EMITIR_RESOLUCION_MULTAS',
       JSON_OBJECT('resolucion', v_res, 'omisos_votacion', v_n1, 'omisos_mesa', v_n2, 'monto_total', v_total));
  COMMIT;

  SELECT v_reporte AS id_reporte, v_res AS numero_resolucion, v_token AS token_qr, v_n1 AS omisos_votacion,
         v_n2 AS omisos_mesa, v_total AS monto_total;
END$$

-- Notificación de las multas determinadas a cada docente (CUN12 paso 3). p_id_multa NULL
-- notifica de una vez todas las que faltan. Devuelve cuántas notificó.
CREATE PROCEDURE sp_notificar_multas(
  IN p_id_proceso INT,
  IN p_id_multa   INT,
  IN p_id_usuario INT,
  IN p_medio      VARCHAR(25),
  IN p_documento  VARCHAR(80),
  IN p_fecha      DATETIME
)
BEGIN
  DECLARE v_rep_est VARCHAR(10) DEFAULT NULL;
  DECLARE v_fecha_r DATETIME;
  DECLARE v_medio   VARCHAR(25);
  DECLARE v_doc     VARCHAR(80);
  DECLARE v_fecha   DATETIME;
  DECLARE v_proc_m  INT DEFAULT NULL;
  DECLARE v_notif   DATETIME;
  DECLARE v_n       INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT estado, fecha_resolucion INTO v_rep_est, v_fecha_r FROM reporte_multas WHERE id_proceso = p_id_proceso;
  IF v_rep_est IS NULL OR v_rep_est <> 'RESUELTO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: se notifican las multas determinadas por la resolución del CEUNP.';
  END IF;
  SET v_medio = UPPER(TRIM(p_medio));
  IF v_medio IS NULL OR v_medio NOT IN ('CORREO_INSTITUCIONAL','CEDULA_PERSONAL','PORTAL_ELECTORAL') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: el medio de notificación es correo institucional, cédula personal o portal electoral.';
  END IF;
  SET v_doc = NULLIF(TRIM(p_documento), '');
  IF v_medio = 'CEDULA_PERSONAL' AND (v_doc IS NULL OR CHAR_LENGTH(v_doc) < 3) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: indique el número de la cédula de notificación.';
  END IF;
  SET v_fecha = COALESCE(p_fecha, NOW());
  IF v_fecha > NOW() + INTERVAL 5 MINUTE OR v_fecha < v_fecha_r - INTERVAL 1 MINUTE THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: la fecha de notificación va desde la resolución hasta hoy.';
  END IF;

  IF p_id_multa IS NOT NULL THEN
    SELECT id_proceso, fecha_notificacion INTO v_proc_m, v_notif FROM multa WHERE id_multa = p_id_multa FOR UPDATE;
    IF v_proc_m IS NULL OR v_proc_m <> p_id_proceso THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La multa no pertenece al proceso.';
    END IF;
    IF v_notif IS NOT NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: la multa ya fue notificada.';
    END IF;
  END IF;

  UPDATE multa
     SET fecha_notificacion = v_fecha, medio_notificacion = v_medio, documento_notificacion = v_doc,
         fecha_actualizacion = NOW(), id_usuario_actualizacion = p_id_usuario
   WHERE id_proceso = p_id_proceso AND fecha_notificacion IS NULL
     AND (p_id_multa IS NULL OR id_multa = p_id_multa);
  SET v_n = ROW_COUNT();
  IF v_n = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: no hay multas por notificar.';
  END IF;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'NOTIFICAR_MULTAS',
       JSON_OBJECT('id_multa', p_id_multa, 'notificadas', v_n, 'medio', v_medio, 'documento', v_doc));
  COMMIT;

  SELECT v_n AS notificadas;
END$$

-- Mensajes 8 registrarJustificacion -> 9 justificar() -> 10 actualizarEstado() -> 11 confirmar().
-- RF106: el CEUNP registra el descargo de una multa determinada y PENDIENTE con su decisión,
-- por resolución del Pleno con quórum (RN36):
--   JUSTIFICACION: la presenta el docente dentro de MULTA_PLAZO_JUSTIFICACION_DIAS desde la
--                  notificación (una por multa). ADMITIDA -> JUSTIFICADA; DENEGADA -> sigue PENDIENTE.
--   EXONERACION:   de oficio, por lo no previsto en el reglamento (RN40). Siempre ADMITIDA -> EXONERADA.
CREATE PROCEDURE sp_registrar_justificacion(
  IN p_id_multa           INT,
  IN p_id_usuario         INT,
  IN p_tipo               VARCHAR(15),
  IN p_causal             VARCHAR(20),
  IN p_sustento           VARCHAR(1000),
  IN p_documento          VARCHAR(150),
  IN p_fecha_presentacion DATETIME,
  IN p_decision           VARCHAR(10),
  IN p_fundamento         VARCHAR(1000),
  IN p_numero_resolucion  VARCHAR(40),
  IN p_miembros_pleno     INT
)
BEGIN
  DECLARE v_proceso  INT DEFAULT NULL;
  DECLARE v_docente  INT;
  DECLARE v_estado   VARCHAR(12);
  DECLARE v_notif    DATETIME;
  DECLARE v_rep_est  VARCHAR(10);
  DECLARE v_fecha_r  DATETIME;
  DECLARE v_tipo     VARCHAR(15);
  DECLARE v_causal   VARCHAR(20);
  DECLARE v_decision VARCHAR(10);
  DECLARE v_sustento VARCHAR(1000);
  DECLARE v_fund     VARCHAR(1000);
  DECLARE v_res      VARCHAR(40);
  DECLARE v_fecha    DATETIME;
  DECLARE v_plazo    INT;
  DECLARE v_quorum   INT;
  DECLARE v_nuevo    VARCHAR(12);
  DECLARE v_ahora    DATETIME;
  DECLARE v_id       INT;
  DECLARE v_msg      VARCHAR(255);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT id_proceso, id_docente, estado_pago, fecha_notificacion INTO v_proceso, v_docente, v_estado, v_notif
    FROM multa WHERE id_multa = p_id_multa FOR UPDATE;
  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La multa no existe.';
  END IF;
  SELECT estado, fecha_resolucion INTO v_rep_est, v_fecha_r FROM reporte_multas WHERE id_proceso = v_proceso;
  IF v_rep_est IS NULL OR v_rep_est <> 'RESUELTO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF106: la multa aún no ha sido determinada por resolución del CEUNP.';
  END IF;
  IF v_estado <> 'PENDIENTE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF106: solo se justifica o exonera una multa PENDIENTE.';
  END IF;

  SET v_tipo     = UPPER(TRIM(p_tipo));
  SET v_causal   = UPPER(TRIM(p_causal));
  SET v_decision = UPPER(TRIM(COALESCE(p_decision, IF(UPPER(TRIM(p_tipo)) = 'EXONERACION', 'ADMITIDA', NULL))));
  IF v_tipo IS NULL OR v_tipo NOT IN ('JUSTIFICACION','EXONERACION') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF106: el descargo es una JUSTIFICACION del docente o una EXONERACION de oficio.';
  END IF;
  IF v_causal IS NULL OR v_causal NOT IN ('SALUD','DUELO','COMISION_SERVICIO','LICENCIA','CASO_FORTUITO','FALLECIMIENTO','ERROR_PADRON','OTRA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF106: indique la causal del descargo.';
  END IF;
  IF v_decision IS NULL OR v_decision NOT IN ('ADMITIDA','DENEGADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF106: la decisión del CEUNP es ADMITIDA o DENEGADA.';
  END IF;
  IF v_tipo = 'EXONERACION' AND v_decision <> 'ADMITIDA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN40: la exoneración de oficio solo se registra cuando el CEUNP la concede.';
  END IF;
  SET v_sustento = NULLIF(TRIM(p_sustento), '');
  IF v_sustento IS NULL OR CHAR_LENGTH(v_sustento) < 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF106: describa el sustento del descargo (al menos 10 caracteres).';
  END IF;
  SET v_fund = NULLIF(TRIM(p_fundamento), '');
  IF v_fund IS NULL OR CHAR_LENGTH(v_fund) < 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: fundamente la decisión del CEUNP (al menos 10 caracteres).';
  END IF;
  SET v_res = NULLIF(TRIM(p_numero_resolucion), '');
  IF v_res IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el descargo se resuelve por resolución del CEUNP; indique su número.';
  END IF;
  IF fn_resolucion_en_uso(v_res) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;
  SET v_quorum = COALESCE(ROUND((SELECT CAST(valor AS DECIMAL(6,2)) FROM parametro_global WHERE clave = 'CEUNP_QUORUM_PLENO')), 5);
  IF p_miembros_pleno IS NULL OR p_miembros_pleno < v_quorum OR p_miembros_pleno > 9 THEN
    SET v_msg = CONCAT('RN36: el Pleno del CEUNP resuelve con quórum de ', v_quorum, ' de sus 9 miembros.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  SET v_ahora = NOW();
  SET v_fecha = COALESCE(p_fecha_presentacion, v_ahora);
  IF v_fecha > v_ahora + INTERVAL 5 MINUTE THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF106: la fecha de presentación no puede ser futura.';
  END IF;
  IF v_tipo = 'JUSTIFICACION' THEN
    IF EXISTS (SELECT 1 FROM multa_justificacion WHERE id_multa = p_id_multa AND tipo = 'JUSTIFICACION') THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: la justificación de esta multa ya fue resuelta; la decisión es inapelable.';
    END IF;
    SET v_plazo = COALESCE(ROUND((SELECT CAST(valor AS DECIMAL(8,2)) FROM parametro_global
                                   WHERE clave = 'MULTA_PLAZO_JUSTIFICACION_DIAS')), 10);
    IF v_plazo > 0 AND v_fecha > COALESCE(v_notif, v_fecha_r) + INTERVAL v_plazo DAY THEN
      SET v_msg = CONCAT('RF106: la justificación se presenta dentro de los ', v_plazo, ' días siguientes a la notificación.');
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
  END IF;

  -- 9 justificar()
  INSERT INTO multa_justificacion (id_multa, tipo, causal, sustento, documento, fecha_presentacion, decision, fundamento,
                                   numero_resolucion, miembros_pleno, fecha_resolucion, id_usuario)
  VALUES (p_id_multa, v_tipo, v_causal, v_sustento, NULLIF(TRIM(p_documento), ''), v_fecha, v_decision, v_fund,
          v_res, p_miembros_pleno, v_ahora, p_id_usuario);
  SET v_id = LAST_INSERT_ID();

  -- 10 actualizarEstado()
  SET v_nuevo = IF(v_decision = 'DENEGADA', 'PENDIENTE', IF(v_tipo = 'EXONERACION', 'EXONERADA', 'JUSTIFICADA'));
  UPDATE multa
     SET estado_pago = v_nuevo, fecha_actualizacion = v_ahora, id_usuario_actualizacion = p_id_usuario,
         observacion = LEFT(CONCAT(IF(v_decision = 'DENEGADA', 'Justificación denegada', IF(v_tipo = 'EXONERACION', 'Exonerada', 'Justificada')),
                                   ' por Resolución ', v_res, '.'), 300)
   WHERE id_multa = p_id_multa;

  CALL sp_registrar_auditoria(p_id_usuario, v_docente, v_proceso,
       CASE WHEN v_decision = 'DENEGADA' THEN 'DENEGAR_JUSTIFICACION'
            WHEN v_tipo = 'EXONERACION' THEN 'EXONERAR_MULTA' ELSE 'JUSTIFICAR_MULTA' END,
       JSON_OBJECT('id_multa', p_id_multa, 'id_justificacion', v_id, 'causal', v_causal, 'resolucion', v_res));
  COMMIT;

  -- 11 confirmar()
  SELECT v_id AS id_justificacion, p_id_multa AS id_multa, v_tipo AS tipo, v_decision AS decision,
         v_nuevo AS estado_pago, v_res AS numero_resolucion;
END$$

-- Pago de una multa determinada (el sistema no cobra: registra el recibo de Tesorería).
CREATE PROCEDURE sp_registrar_pago_multa(
  IN p_id_multa      INT,
  IN p_id_usuario    INT,
  IN p_numero_recibo VARCHAR(40),
  IN p_fecha_pago    DATETIME,
  IN p_observacion   VARCHAR(300)
)
BEGIN
  DECLARE v_proceso INT DEFAULT NULL;
  DECLARE v_docente INT;
  DECLARE v_estado  VARCHAR(12);
  DECLARE v_rep_est VARCHAR(10);
  DECLARE v_fecha_r DATETIME;
  DECLARE v_recibo  VARCHAR(40);
  DECLARE v_fecha   DATETIME;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT id_proceso, id_docente, estado_pago INTO v_proceso, v_docente, v_estado FROM multa WHERE id_multa = p_id_multa FOR UPDATE;
  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La multa no existe.';
  END IF;
  SELECT estado, fecha_resolucion INTO v_rep_est, v_fecha_r FROM reporte_multas WHERE id_proceso = v_proceso;
  IF v_rep_est IS NULL OR v_rep_est <> 'RESUELTO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF103: la multa se paga después de la resolución del CEUNP que la determina.';
  END IF;
  IF v_estado <> 'PENDIENTE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La multa no está pendiente de pago.';
  END IF;
  SET v_recibo = NULLIF(TRIM(p_numero_recibo), '');
  IF v_recibo IS NULL OR CHAR_LENGTH(v_recibo) < 3 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Indique el número del recibo de pago.';
  END IF;
  IF EXISTS (SELECT 1 FROM multa WHERE numero_recibo = v_recibo) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El número de recibo ya fue registrado en otra multa.';
  END IF;
  SET v_fecha = COALESCE(p_fecha_pago, NOW());
  IF v_fecha > NOW() + INTERVAL 5 MINUTE OR v_fecha < v_fecha_r - INTERVAL 1 MINUTE THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de pago va desde la resolución hasta hoy.';
  END IF;

  UPDATE multa
     SET estado_pago = 'PAGADA', fecha_pago = v_fecha, numero_recibo = v_recibo,
         observacion = COALESCE(NULLIF(TRIM(p_observacion), ''), observacion),
         fecha_actualizacion = NOW(), id_usuario_actualizacion = p_id_usuario
   WHERE id_multa = p_id_multa;

  CALL sp_registrar_auditoria(p_id_usuario, v_docente, v_proceso, 'REGISTRAR_PAGO_MULTA',
       JSON_OBJECT('id_multa', p_id_multa, 'recibo', v_recibo));
  COMMIT;
END$$

-- Redefine el de la sección G (PATCH /api/multas/{id}) con las reglas del CUS16: PAGADA exige el
-- recibo en p_observacion; la justificación y la exoneración van con su resolución (RF106).
CREATE PROCEDURE sp_actualizar_multa(
  IN p_id_multa    INT,
  IN p_estado_pago VARCHAR(12),
  IN p_observacion VARCHAR(300),
  IN p_id_usuario  INT
)
BEGIN
  DECLARE v_est VARCHAR(12);
  SET v_est = UPPER(TRIM(p_estado_pago));
  IF v_est IS NULL OR v_est NOT IN ('PENDIENTE','PAGADA','EXONERADA','JUSTIFICADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estado de pago invalido.';
  END IF;
  IF v_est = 'PENDIENTE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF106: el pago, la justificación o la exoneración registrados no se revierten.';
  END IF;
  IF v_est IN ('EXONERADA','JUSTIFICADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF106: la justificación o la exoneración se registran con la resolución del CEUNP (Omisos y multas, CUS16).';
  END IF;
  CALL sp_registrar_pago_multa(p_id_multa, p_id_usuario, p_observacion, NULL, NULL);
END$$

-- Destino del QR de la resolución de multas: recalcula el SHA-256 del contenido. No devuelve la
-- relación de docentes, solo los totales.
CREATE PROCEDURE sp_verificar_resolucion_multas(IN p_token CHAR(64))
BEGIN
  SELECT r.id_proceso, p.nombre AS proceso, r.numero_resolucion, r.fecha_resolucion, r.omisos_votacion, r.omisos_mesa,
         r.monto_total, r.uit_referencia, r.hash_integridad,
         IF(SHA2(r.contenido_json, 256) = r.hash_integridad, 1, 0) AS contenido_integro
    FROM reporte_multas r
    JOIN proceso_electoral p ON p.id_proceso = r.id_proceso
   WHERE r.token_qr_hash = SHA2(p_token, 256) AND r.estado = 'RESUELTO';
END$$

DELIMITER ;

SELECT 'CUS16 instalado: omisos y multas (sp_generar_multas, sp_emitir_resolucion_multas, sp_notificar_multas, sp_registrar_justificacion, sp_registrar_pago_multa).' AS estado;
