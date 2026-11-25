-- ============================================================================
-- 17_cargo_mesa_en_vista.sql
-- Agrega cargo de miembro de mesa (PRESIDENTE, SECRETARIO, VOCAL, SUPLENTE),
-- indicador titular/suplente y mesa asignada a la vista v_usuarios_admin.
-- Prerequisito: 00_script_unico_elecciones_unp.sql + actualizar_sin_borrar.sql
-- ============================================================================

-- ─── Recrear vista v_usuarios_admin con campos de miembro de mesa ─────────
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
    -- Campos de miembro de mesa (solo del proceso activo si la cuenta tiene rol MIEMBRO_MESA)
    mm.rol        AS cargo_mesa,
    mm.titular    AS es_titular_mesa,
    mm.id_mesa    AS id_mesa_asignada,
    me.numero_mesa
FROM usuario u
LEFT JOIN usuario c          ON c.id_usuario     = u.id_usuario_creador
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
