-- =====================================================================
-- MIGRACIÓN: Agregar campos de auditoría y bloqueo a la tabla `usuario`
-- Causa del error: Unknown column 'u1_0.bloqueado_hasta' in 'field list'
-- =====================================================================

USE elecciones_unp;

ALTER TABLE usuario
  ADD COLUMN IF NOT EXISTS intentos_fallidos INT NOT NULL DEFAULT 0 AFTER activo,
  ADD COLUMN IF NOT EXISTS bloqueado_hasta DATETIME NULL AFTER intentos_fallidos,
  ADD COLUMN IF NOT EXISTS ultimo_acceso DATETIME NULL AFTER bloqueado_hasta,
  ADD COLUMN IF NOT EXISTS fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER ultimo_acceso;

-- Verificar la estructura final
DESCRIBE usuario;
