-- ============================================================================
-- 19_multas_miembros_mesa_suplentes.sql
-- Incluye a todos los miembros de mesa sorteados (titulares y suplentes)
-- que no asistieron en el reporte de omisos y multas (Art. 38, Art. 67, RF104).
-- ============================================================================

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
 WHERE mm.asistio = 0;
