-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 04_credenciales_qr.sql  ·  CUS07 Emitir credenciales y QR
--
-- Tabla credencial_qr: credenciales QR de identificación para la
-- jornada electoral.
--   ELECTOR       pase de votación del docente habilitado (RF62)
--   MIEMBRO_MESA  fotocheck digital del miembro de mesa (RF56)
--   PERSONERO     credencial del personero acreditado (RF51)
--
-- Es una tabla distinta de constancia_voto: la constancia la emite
-- sp_emitir_voto DESPUÉS de votar (prueba de participación); la
-- credencial se emite ANTES (identificación).
--
-- Seguridad: el token en claro solo aparece en el código QR que se
-- entrega al titular; aquí se guarda únicamente SHA-256(token).
-- Volver a emitir revoca la credencial anterior (solo una VIGENTE
-- por titular y tipo).
--
-- Uso: SOLO para una base ya creada antes de CUS07 (no borra datos de
-- otras tablas). 01_crear_base_de_datos.sql ya incluye esta tabla.
-- Se puede volver a ejecutar (recrea credencial_qr vacía).
-- =====================================================================
USE elecciones_unp;
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

DROP TRIGGER IF EXISTS trg_personero_au_credencial;
DROP TRIGGER IF EXISTS trg_credencial_bd;
DROP TABLE IF EXISTS credencial_qr;

CREATE TABLE credencial_qr (
  id_credencial     BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_proceso        INT NOT NULL,
  id_docente        INT NOT NULL,
  tipo              ENUM('ELECTOR','MIEMBRO_MESA','PERSONERO') NOT NULL,
  id_mesa           INT NULL,                  -- mesa del elector / del miembro / del personero de mesa
  id_personero      INT NULL,                  -- solo PERSONERO
  token_qr_hash     CHAR(64) NOT NULL,         -- SHA-256 del token (nunca el token)
  fecha_emision     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_expiracion  DATETIME NOT NULL,         -- fin del sufragio del proceso
  estado            ENUM('VIGENTE','REVOCADA') NOT NULL DEFAULT 'VIGENTE',
  fecha_revocacion  DATETIME NULL,
  motivo_revocacion VARCHAR(255) NULL,
  id_usuario_emisor INT NULL,
  usos              INT NOT NULL DEFAULT 0,    -- lecturas válidas registradas
  ultimo_uso        DATETIME NULL,
  -- una sola credencial VIGENTE por titular: (proceso, docente, tipo, personero o mesa)
  clave_vigente     VARCHAR(80) AS (IF(estado = 'VIGENTE',
                      CONCAT_WS(':', id_proceso, id_docente, tipo,
                        CASE tipo WHEN 'PERSONERO' THEN id_personero
                                  WHEN 'MIEMBRO_MESA' THEN id_mesa
                                  ELSE 0 END),
                      NULL)) STORED,
  UNIQUE KEY uq_credencial_token (token_qr_hash),
  UNIQUE KEY uq_credencial_vigente (clave_vigente),
  KEY ix_credencial_titular (id_proceso, tipo, id_docente),
  KEY ix_credencial_docente (id_docente, estado),
  CONSTRAINT chk_credencial_hash CHECK (token_qr_hash REGEXP '^[0-9a-f]{64}$'),
  CONSTRAINT chk_credencial_tipo CHECK (
       (tipo = 'PERSONERO'    AND id_personero IS NOT NULL)
    OR (tipo = 'MIEMBRO_MESA' AND id_personero IS NULL AND id_mesa IS NOT NULL)
    OR (tipo = 'ELECTOR'      AND id_personero IS NULL)),
  CONSTRAINT chk_credencial_revocacion CHECK (estado = 'VIGENTE' OR fecha_revocacion IS NOT NULL),
  CONSTRAINT fk_credencial_proceso   FOREIGN KEY (id_proceso)        REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_credencial_docente   FOREIGN KEY (id_docente)        REFERENCES docente(id_docente),
  CONSTRAINT fk_credencial_mesa      FOREIGN KEY (id_mesa)           REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_credencial_personero FOREIGN KEY (id_personero)      REFERENCES personero(id_personero),
  CONSTRAINT fk_credencial_emisor    FOREIGN KEY (id_usuario_emisor) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELIMITER $$

-- Si el CEUNP revoca la acreditación de un personero (CUS05), su credencial deja de valer.
CREATE TRIGGER trg_personero_au_credencial AFTER UPDATE ON personero
FOR EACH ROW
BEGIN
  IF OLD.estado_acreditacion = 'ACREDITADO' AND NEW.estado_acreditacion <> 'ACREDITADO' THEN
    UPDATE credencial_qr
       SET estado = 'REVOCADA', fecha_revocacion = NOW(),
           motivo_revocacion = 'Acreditación del personero revocada (CUS05)'
     WHERE id_personero = NEW.id_personero AND estado = 'VIGENTE';
  END IF;
END$$

-- Las credenciales son evidencia de auditoría: se revocan, no se borran.
CREATE TRIGGER trg_credencial_bd BEFORE DELETE ON credencial_qr
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Las credenciales QR no se eliminan: revóquelas.';
END$$

DELIMITER ;
