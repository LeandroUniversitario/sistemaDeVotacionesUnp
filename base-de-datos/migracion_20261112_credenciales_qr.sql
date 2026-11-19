-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP
-- Migración segura: Credenciales QR y Solicitudes de Regeneración (CUS07)
-- =====================================================================

USE elecciones_unp;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 1. Columna codigo_qr en credencial_qr (si no existe)
DROP PROCEDURE IF EXISTS sp_tmp_add_col;
DELIMITER $$
CREATE PROCEDURE sp_tmp_add_col(IN p_tbl VARCHAR(64), IN p_col VARCHAR(64), IN p_def VARCHAR(500))
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = p_tbl AND COLUMN_NAME = p_col
  ) THEN
    SET @s = CONCAT('ALTER TABLE ', p_tbl, ' ADD COLUMN ', p_col, ' ', p_def);
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END$$
DELIMITER ;

CALL sp_tmp_add_col('credencial_qr', 'codigo_qr', 'VARCHAR(255) NULL AFTER token_qr_hash');
DROP PROCEDURE IF EXISTS sp_tmp_add_col;

-- 2. Tabla solicitud_regeneracion_qr (si no existe)
CREATE TABLE IF NOT EXISTS solicitud_regeneracion_qr (
  id_solicitud        INT AUTO_INCREMENT PRIMARY KEY,
  id_proceso          INT NOT NULL,
  id_docente          INT NOT NULL,
  tipo                ENUM('ELECTOR','MIEMBRO_MESA','PERSONERO') NOT NULL,
  id_titular          INT NULL,
  motivo              VARCHAR(255) NOT NULL,
  estado              ENUM('PENDIENTE','APROBADA','RECHAZADA') NOT NULL DEFAULT 'PENDIENTE',
  fecha_solicitud     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_atencion      DATETIME NULL,
  id_usuario_atencion INT NULL,
  observacion_atencion VARCHAR(255) NULL,
  CONSTRAINT fk_sol_proc FOREIGN KEY (id_proceso) REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_sol_doc  FOREIGN KEY (id_docente) REFERENCES docente(id_docente),
  CONSTRAINT fk_sol_usu  FOREIGN KEY (id_usuario_atencion) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Actualización de sp_resolver_tacha para RN12
DROP PROCEDURE IF EXISTS sp_resolver_tacha;
DELIMITER $$
CREATE PROCEDURE sp_resolver_tacha(
  IN p_id_tacha   INT,
  IN p_resultado  VARCHAR(10),      -- FUNDADA / INFUNDADA
  IN p_resolucion TEXT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_estado    VARCHAR(20) DEFAULT NULL;
  DECLARE v_candidato INT DEFAULT NULL;
  DECLARE v_lista     INT DEFAULT NULL;
  DECLARE v_proceso   INT DEFAULT NULL;
  DECLARE v_res       VARCHAR(10);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SET v_res = UPPER(p_resultado);

  SELECT t.estado, t.id_candidato, ca.id_lista INTO v_estado, v_candidato, v_lista
    FROM tacha t JOIN candidato ca ON ca.id_candidato = t.id_candidato
   WHERE t.id_tacha = p_id_tacha
     FOR UPDATE;

  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La tacha no existe.';
  END IF;
  IF v_estado <> 'PENDIENTE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La tacha ya fue resuelta.';
  END IF;
  IF v_res IS NULL OR v_res NOT IN ('FUNDADA','INFUNDADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El resultado debe ser FUNDADA o INFUNDADA.';
  END IF;

  SET v_proceso = fn_proceso_de_lista(v_lista);

  UPDATE tacha
     SET estado = v_res, fecha_resolucion = NOW(), resolucion = p_resolucion, id_usuario_resuelve = p_id_usuario
   WHERE id_tacha = p_id_tacha;

  IF v_res = 'FUNDADA' THEN
    UPDATE candidato
       SET estado_validacion = 'EXCLUIDO', motivo_exclusion = 'Tacha declarada fundada'
     WHERE id_candidato = v_candidato;
    UPDATE candidato
       SET estado_validacion = 'EXCLUIDO', motivo_exclusion = 'Lista tachada por RN12 (inscripción en bloque)'
     WHERE id_lista = v_lista AND id_candidato <> v_candidato;
    UPDATE lista_electoral
       SET estado = 'TACHADA', orden_cedula = NULL, motivo_exclusion = 'Tacha fundada contra un integrante (RN12)'
     WHERE id_lista = v_lista;
  END IF;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'RESOLVER_TACHA',
       JSON_OBJECT('id_tacha', p_id_tacha, 'resultado', v_res));
  COMMIT;
END$$
DELIMITER ;

