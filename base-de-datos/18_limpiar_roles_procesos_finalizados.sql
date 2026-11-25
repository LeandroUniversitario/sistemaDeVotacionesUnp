-- ============================================================================
-- 18_limpiar_roles_procesos_finalizados.sql
-- 1) Corrige v_usuarios_admin para no duplicar usuarios que fueron miembros de
--    mesa en procesos anteriores y mostrar solo el cargo del proceso activo.
-- 2) Devuelve a DOCENTE a los usuarios MIEMBRO_MESA o PERSONERO que no tienen
--    asignación vigente en un proceso activo (no FINALIZADO ni ANULADO).
-- ============================================================================

CREATE OR REPLACE VIEW v_usuarios_admin AS
SELECT
    u.id_usuario,
    u.username,
    CONCAT(u.rol, '') AS rol,
    u.activo,
    u.debe_cambiar_password,
    u.intentos_fallidos,
    u.bloqueado_hasta,
    u.bloqueado_hasta IS NOT NULL AND u.bloqueado_hasta > CURRENT_TIMESTAMP() AS bloqueada,
    u.ultimo_acceso,
    u.fecha_creacion,
    u.fecha_actualizacion,
    u.motivo_estado,
    u.id_usuario_creador,
    c.username AS creado_por,
    u.id_docente,
    d.dni,
    CONCAT(d.apellidos, ', ', d.nombres) AS docente,
    CONCAT(d.estado, '') AS estado_docente,
    CONCAT(d.categoria, '') AS categoria,
    d.email,
    f.nombre AS facultad,
    dp.nombre AS departamento,
    (SELECT COUNT(*) FROM log_auditoria l WHERE l.id_usuario = u.id_usuario) AS actividad,
    mm.rol        AS cargo_mesa,
    mm.titular    AS es_titular_mesa,
    mm.id_mesa    AS id_mesa_asignada,
    me.numero_mesa
FROM usuario u
LEFT JOIN usuario c          ON c.id_usuario      = u.id_usuario_creador
LEFT JOIN docente d          ON d.id_docente      = u.id_docente
LEFT JOIN facultad f         ON f.id_facultad     = d.id_facultad
LEFT JOIN departamento dp    ON dp.id_departamento = d.id_departamento
LEFT JOIN mesa_electoral me  ON me.id_mesa = (
    SELECT mm2.id_mesa
      FROM miembro_mesa mm2
      JOIN mesa_electoral m2 ON m2.id_mesa = mm2.id_mesa
      JOIN proceso_electoral p2 ON p2.id_proceso = m2.id_proceso
     WHERE mm2.id_docente = u.id_docente
       AND u.rol = 'MIEMBRO_MESA'
       AND p2.estado NOT IN ('FINALIZADO', 'ANULADO')
     ORDER BY p2.id_proceso DESC, m2.id_mesa DESC
     LIMIT 1
)
LEFT JOIN miembro_mesa mm    ON mm.id_mesa = me.id_mesa AND mm.id_docente = u.id_docente;

UPDATE usuario u
   SET u.rol = 'DOCENTE'
 WHERE u.rol = 'MIEMBRO_MESA'
   AND NOT EXISTS (
       SELECT 1
         FROM miembro_mesa mm
         JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
         JOIN proceso_electoral p ON p.id_proceso = m.id_proceso
        WHERE mm.id_docente = u.id_docente
          AND p.estado NOT IN ('FINALIZADO', 'ANULADO')
   );

UPDATE usuario u
   SET u.rol = 'DOCENTE'
 WHERE u.rol = 'PERSONERO'
   AND NOT EXISTS (
       SELECT 1
         FROM personero pe
         JOIN lista_electoral l ON l.id_lista = pe.id_lista
         JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
         JOIN proceso_electoral p ON p.id_proceso = c.id_proceso
        WHERE pe.id_docente = u.id_docente
          AND pe.estado_acreditacion = 'ACREDITADO'
          AND p.estado NOT IN ('FINALIZADO', 'ANULADO')
   );
