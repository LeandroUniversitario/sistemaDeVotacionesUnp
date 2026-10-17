-- =====================================================================
-- 07_agregar_debe_cambiar_password.sql
-- Migracion incremental: agrega la columna debe_cambiar_password
-- a la tabla usuario para el cambio obligatorio de clave en 1er login.
-- Ejecutar si ya tienes la BD creada.
-- =====================================================================

USE elecciones_unp;

ALTER TABLE usuario
  ADD COLUMN IF NOT EXISTS debe_cambiar_password BOOLEAN NOT NULL DEFAULT FALSE
  COMMENT 'TRUE: docente creado masivamente, debe cambiar su contrasena en el primer login';

-- Marcar todos los docentes como pendientes de cambio (se crearon sin elegir su clave)
UPDATE usuario SET debe_cambiar_password = TRUE WHERE rol = 'DOCENTE';
