-- =====================================================================
-- MIGRACIÓN: Agregar fecha_convocatoria a proceso_electoral
-- Fundamento: Art. 7 y 8  Res. N.º 0462-CU-2019  /  RN02 del sistema
--
-- Ejecutar una sola vez en la BD activa (elecciones_unp o la que uses).
-- Compatible con MariaDB 10.4+ (XAMPP / phpMyAdmin).
-- =====================================================================

USE elecciones_unp;

-- Agrega la columna SOLO si no existe (seguro para re-ejecución)
ALTER TABLE proceso_electoral
    ADD COLUMN IF NOT EXISTS fecha_convocatoria DATE NULL
        COMMENT 'Fecha oficial de convocatoria. Debe estar 30-45 días antes del sufragio (RN02 / Art.7-8 Res.0462-CU-2019)'
        AFTER quorum_minimo;

-- Verificar que el campo fue creado
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_COMMENT
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_SCHEMA = DATABASE()
   AND TABLE_NAME   = 'proceso_electoral'
   AND COLUMN_NAME  = 'fecha_convocatoria';
