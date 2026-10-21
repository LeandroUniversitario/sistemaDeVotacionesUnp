-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 06_verificar_elector_emitir_voto.sql  ·  CUS09 Verificar elector y CUS10 Emitir voto
--
-- Tabla autorizacion_voto: el miembro de mesa (CUS09) identifica al
-- elector con su pase QR (CUS07) o con su DNI contra el padrón de su
-- mesa INSTALADA (CUS08) y le habilita la cabina. Sin una autorización
-- PENDIENTE y sin vencer, el docente no puede emitir su voto (CUS10).
--
-- La autorización dice QUIÉN pasó a la cabina, nunca por quién votó:
-- no referencia a la tabla voto. El voto lo sigue grabando
-- sp_emitir_voto (marca en el padrón + voto anónimo + constancia).
--
-- Uso: SOLO para una base ya creada antes de CUS09 (no borra datos de
-- otras tablas). 01_crear_base_de_datos.sql ya incluye esta tabla.
-- Se puede volver a ejecutar (recrea autorizacion_voto vacía).
-- =====================================================================
USE elecciones_unp;
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

DROP TRIGGER IF EXISTS trg_autorizacion_bd;
DROP TABLE IF EXISTS autorizacion_voto;

CREATE TABLE autorizacion_voto (
  id_autorizacion    BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_proceso         INT NOT NULL,
  id_mesa            INT NOT NULL,
  id_docente         INT NOT NULL,
  metodo             ENUM('QR','DNI') NOT NULL,           -- cómo se identificó al elector (RN05)
  id_credencial      BIGINT NULL,                         -- pase QR leído (solo metodo = QR)
  id_usuario_mesa    INT NULL,                            -- miembro de mesa que autorizó
  fecha_autorizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_expiracion   DATETIME NOT NULL,
  fecha_uso          DATETIME NULL,                       -- el elector terminó de votar
  estado             ENUM('PENDIENTE','USADA','ANULADA') NOT NULL DEFAULT 'PENDIENTE',
  motivo_anulacion   VARCHAR(255) NULL,
  -- una sola autorización PENDIENTE por elector y proceso
  clave_pendiente    VARCHAR(40) AS (IF(estado = 'PENDIENTE', CONCAT(id_proceso, ':', id_docente), NULL)) STORED,
  UNIQUE KEY uq_autorizacion_pendiente (clave_pendiente),
  KEY ix_autorizacion_mesa (id_mesa, estado),
  KEY ix_autorizacion_docente (id_docente, id_proceso),
  CONSTRAINT chk_autorizacion_qr CHECK (metodo = 'DNI' OR id_credencial IS NOT NULL),
  CONSTRAINT chk_autorizacion_uso CHECK (estado <> 'USADA' OR fecha_uso IS NOT NULL),
  CONSTRAINT chk_autorizacion_anulada CHECK (estado <> 'ANULADA' OR motivo_anulacion IS NOT NULL),
  CONSTRAINT fk_autorizacion_proceso    FOREIGN KEY (id_proceso)      REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_autorizacion_mesa       FOREIGN KEY (id_mesa)         REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_autorizacion_docente    FOREIGN KEY (id_docente)      REFERENCES docente(id_docente),
  CONSTRAINT fk_autorizacion_credencial FOREIGN KEY (id_credencial)   REFERENCES credencial_qr(id_credencial),
  CONSTRAINT fk_autorizacion_usuario    FOREIGN KEY (id_usuario_mesa) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELIMITER $$

-- Las autorizaciones son evidencia de la jornada: se anulan, no se borran.
CREATE TRIGGER trg_autorizacion_bd BEFORE DELETE ON autorizacion_voto
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Las autorizaciones de voto no se eliminan: anúlelas.';
END$$

DELIMITER ;

-- Minutos que tiene el elector para votar después de ser autorizado en mesa.
INSERT INTO parametro_global (clave, valor, descripcion) VALUES
  ('MINUTOS_AUTORIZACION_VOTO', '15', 'Minutos de vigencia de la autorización de cabina que da el miembro de mesa (CUS09)')
ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion);
