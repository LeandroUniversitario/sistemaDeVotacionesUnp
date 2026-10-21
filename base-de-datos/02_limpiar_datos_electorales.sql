-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 02_limpiar_datos_electorales.sql
--
-- PROPÓSITO:
--   Limpia y reinicia todos los datos transaccionales de procesos electorales,
--   mesas, padrones, votos, actas, resultados y multas.
--
-- CONSERVA INTACTO:
--   - Catálogo de Facultades (14)
--   - Catálogo de Departamentos Académicos (54)
--   - Padrón maestro de Docentes reales
--   - Cuentas de Usuarios y sus contraseñas (admin, CEUNP, etc.)
--   - Parámetros Globales (UIT, porcentajes de multas, etc.)
--   - Catálogo de Cargos Excluidos de Sorteo (RN20)
--
-- USO:
--   Ejecutar en la pestaña SQL de phpMyAdmin o mediante línea de comandos:
--   mysql -u root elecciones_unp < 02_limpiar_datos_electorales.sql
-- =====================================================================

USE elecciones_unp;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 0;

-- 1. Vaciar votos, constancias, actas y firmas
TRUNCATE TABLE voto;
TRUNCATE TABLE constancia_voto;
TRUNCATE TABLE credencial_qr;          -- CUS07 (credenciales QR)
TRUNCATE TABLE asistencia_personero_mesa;  -- CUS08 (instalación de mesa)
TRUNCATE TABLE instalacion_mesa;           -- CUS08
TRUNCATE TABLE reemplazo_mesa;             -- CUS08
TRUNCATE TABLE incidencia_mesa;        -- CUS09 / CUS10
TRUNCATE TABLE habilitacion_terminal;  -- CUS09 / CUS10
TRUNCATE TABLE terminal_votacion;      -- CUS09 / CUS10
TRUNCATE TABLE asistencia_elector;     -- CUS09 / CUS10
TRUNCATE TABLE cierre_mesa;            -- CUS11
TRUNCATE TABLE firma_acta;
TRUNCATE TABLE acta_electoral;

-- 2. Vaciar resultados oficiales y multas generadas
TRUNCATE TABLE resultado_electoral;
TRUNCATE TABLE multa;

-- 3. Vaciar observaciones e impugnaciones
TRUNCATE TABLE observacion_electoral;
TRUNCATE TABLE impugnacion_electoral;

-- 4. Vaciar padrón electoral y asignaciones de mesa
TRUNCATE TABLE padron_electoral;
TRUNCATE TABLE miembro_mesa;
TRUNCATE TABLE personero;
TRUNCATE TABLE mesa_electoral;

-- 5. Vaciar tachas, candidatos y listas inscritas
TRUNCATE TABLE tacha;
TRUNCATE TABLE candidato;
TRUNCATE TABLE lista_electoral;
TRUNCATE TABLE cargo_categoria_permitida;
TRUNCATE TABLE cargo_electoral;

-- 6. Vaciar convocatorias / procesos electorales
TRUNCATE TABLE proceso_electoral;

-- 7. Limpiar sesiones activas y bitácora de auditoría
TRUNCATE TABLE sesion_activa;
TRUNCATE TABLE log_auditoria;

-- 8. Eliminar docentes temporales de prueba (si se ejecutó sp_demo_flujo_completo con DNIs 9xxxxxxx)
DELETE FROM docente WHERE dni REGEXP '^9[0-9]{7}$';

-- 9. Normalizar estado de sufragio de los docentes reales (RN03: ACTIVO = 1, otros = 0)
UPDATE docente SET habilitado_para_votar = 1 WHERE estado = 'ACTIVO';
UPDATE docente SET habilitado_para_votar = 0 WHERE estado <> 'ACTIVO';

SET FOREIGN_KEY_CHECKS = 1;

SELECT 'Base de datos elecciones_unp limpiada exitosamente. Lista para un nuevo proceso electoral.' AS estado;
