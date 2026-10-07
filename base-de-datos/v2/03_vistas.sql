-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 03_vistas.sql  ·  Vistas de consulta y reportes
-- =====================================================================
USE elecciones_unp;

-- Docente con su facultad y departamento
CREATE OR REPLACE VIEW v_docente_detalle AS
SELECT d.id_docente, d.dni, d.apellidos, d.nombres,
       CONCAT(d.apellidos, ', ', d.nombres) AS nombre_completo,
       d.categoria, d.dedicacion, d.grado_academico, d.estado, d.habilitado_para_votar,
       f.id_facultad, f.nombre AS facultad,
       dp.id_departamento, dp.nombre AS departamento,
       fn_tiene_cargo_excluyente(d.id_docente) AS es_autoridad_vigente
  FROM docente d
  JOIN departamento dp ON dp.id_departamento = d.id_departamento
  JOIN facultad f      ON f.id_facultad = dp.id_facultad;

-- Padrón electoral legible (quién vota qué y en qué mesa). No expone el voto.
CREATE OR REPLACE VIEW v_padron_detalle AS
SELECT pe.id_proceso, pe.id_cargo, c.nombre AS cargo,
       pe.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS docente,
       d.categoria, f.nombre AS facultad,
       pe.habilitado_para_votar, pe.ya_voto, pe.fecha_votacion, pe.motivo_inhabilitacion,
       pe.id_mesa, m.numero_mesa, m.ubicacion
  FROM padron_electoral pe
  JOIN cargo_electoral c ON c.id_cargo = pe.id_cargo
  JOIN docente d         ON d.id_docente = pe.id_docente
  JOIN facultad f        ON f.id_facultad = d.id_facultad
  LEFT JOIN mesa_electoral m ON m.id_mesa = pe.id_mesa;

-- RN31: participación y quórum por cargo, en tiempo real
CREATE OR REPLACE VIEW v_participacion_cargo AS
SELECT c.id_proceso, c.id_cargo, c.nombre AS cargo,
       COUNT(pe.id_docente)            AS electores_habiles,
       COALESCE(SUM(pe.ya_voto), 0)    AS votaron,
       COUNT(pe.id_docente) - COALESCE(SUM(pe.ya_voto), 0) AS faltan,
       CASE WHEN COUNT(pe.id_docente) = 0 THEN 0
            ELSE ROUND(SUM(pe.ya_voto) * 100 / COUNT(pe.id_docente), 2) END AS participacion_pct,
       p.quorum_minimo,
       CASE WHEN COUNT(pe.id_docente) > 0
             AND SUM(pe.ya_voto) * 100 / COUNT(pe.id_docente) > p.quorum_minimo
            THEN 1 ELSE 0 END AS alcanza_quorum
  FROM cargo_electoral c
  JOIN proceso_electoral p ON p.id_proceso = c.id_proceso
  LEFT JOIN padron_electoral pe ON pe.id_cargo = c.id_cargo AND pe.habilitado_para_votar = 1
 GROUP BY c.id_proceso, c.id_cargo, c.nombre, p.quorum_minimo;

-- RN31: participación global del proceso (electores distintos)
CREATE OR REPLACE VIEW v_quorum_proceso AS
SELECT p.id_proceso, p.nombre, p.estado, p.tipo, p.quorum_minimo,
       COUNT(x.id_docente)          AS electores_habiles,
       COALESCE(SUM(x.voto), 0)     AS votaron,
       CASE WHEN COUNT(x.id_docente) = 0 THEN 0
            ELSE ROUND(SUM(x.voto) * 100 / COUNT(x.id_docente), 2) END AS participacion_pct,
       CASE WHEN COUNT(x.id_docente) > 0
             AND SUM(x.voto) * 100 / COUNT(x.id_docente) > p.quorum_minimo
            THEN 1 ELSE 0 END AS alcanza_quorum
  FROM proceso_electoral p
  LEFT JOIN (SELECT id_proceso, id_docente, MAX(ya_voto) AS voto
               FROM padron_electoral
              WHERE habilitado_para_votar = 1
              GROUP BY id_proceso, id_docente) x ON x.id_proceso = p.id_proceso
 GROUP BY p.id_proceso, p.nombre, p.estado, p.tipo, p.quorum_minimo;

-- Alias con el nombre que usa tu documentación (diccionario_y_cambios_arquitectura.md)
CREATE OR REPLACE VIEW vista_quorum AS
SELECT * FROM v_quorum_proceso;

-- Conteo por lista. Solo muestra procesos CERRADOS o FINALIZADOS:
-- durante la votación no devuelve filas, así nadie ve resultados parciales.
CREATE OR REPLACE VIEW v_resultados_cargo AS
SELECT c.id_proceso, c.id_cargo, c.nombre AS cargo,
       l.id_lista, l.nombre AS lista, l.orden_cedula,
       COUNT(v.id_voto) AS votos,
       c.estado_resultado,
       CASE WHEN c.id_lista_ganadora = l.id_lista THEN 1 ELSE 0 END AS es_ganadora
  FROM cargo_electoral c
  JOIN proceso_electoral p ON p.id_proceso = c.id_proceso AND p.estado IN ('CERRADO','FINALIZADO')
  JOIN lista_electoral l   ON l.id_cargo = c.id_cargo AND l.estado = 'ADMITIDA'
  LEFT JOIN voto v         ON v.id_lista_elegida = l.id_lista AND v.tipo_voto = 'VALIDO'
 GROUP BY c.id_proceso, c.id_cargo, c.nombre, l.id_lista, l.nombre, l.orden_cedula,
          c.estado_resultado, c.id_lista_ganadora;

-- RN18: cédula de votación (listas admitidas en el orden sorteado, con su fórmula)
CREATE OR REPLACE VIEW v_cedula_votacion AS
SELECT c.id_proceso, c.id_cargo, c.nombre AS cargo,
       l.id_lista, l.orden_cedula, l.nombre AS lista, l.simbolo,
       ca.rol_en_lista, CONCAT(d.apellidos, ', ', d.nombres) AS candidato
  FROM cargo_electoral c
  JOIN lista_electoral l ON l.id_cargo = c.id_cargo AND l.estado = 'ADMITIDA'
  JOIN candidato ca      ON ca.id_lista = l.id_lista AND ca.estado_validacion = 'APROBADO'
  JOIN docente d         ON d.id_docente = ca.id_docente;

-- RN15: portal de transparencia (solo candidatos aprobados de listas admitidas)
CREATE OR REPLACE VIEW v_candidatos_publicos AS
SELECT c.id_proceso, c.nombre AS cargo, l.nombre AS lista, l.url_plan_gobierno,
       ca.rol_en_lista, CONCAT(d.nombres, ' ', d.apellidos) AS candidato,
       d.categoria, d.grado_academico, f.nombre AS facultad, ca.url_hoja_vida
  FROM candidato ca
  JOIN lista_electoral l ON l.id_lista = ca.id_lista AND l.estado = 'ADMITIDA'
  JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
  JOIN docente d         ON d.id_docente = ca.id_docente
  JOIN facultad f        ON f.id_facultad = d.id_facultad
 WHERE ca.estado_validacion = 'APROBADO';

-- RN27: cuadre de votos emitidos contra electores que sufragaron (debe dar diferencia 0)
CREATE OR REPLACE VIEW v_cuadre_votos AS
SELECT c.id_proceso, c.id_cargo, c.nombre AS cargo,
       (SELECT COUNT(*) FROM padron_electoral pe WHERE pe.id_cargo = c.id_cargo AND pe.ya_voto = 1) AS electores_que_votaron,
       (SELECT COUNT(*) FROM voto v WHERE v.id_cargo = c.id_cargo) AS votos_en_urna,
       (SELECT COUNT(*) FROM voto v WHERE v.id_cargo = c.id_cargo)
     - (SELECT COUNT(*) FROM padron_electoral pe WHERE pe.id_cargo = c.id_cargo AND pe.ya_voto = 1) AS diferencia
  FROM cargo_electoral c;

-- Estado de las mesas
CREATE OR REPLACE VIEW v_mesa_detalle AS
SELECT m.id_proceso, m.id_mesa, m.numero_mesa, m.ubicacion, m.estado,
       m.total_electores, m.hora_instalacion, m.hora_cierre, m.fecha_sorteo, m.semilla_sorteo,
       (SELECT COUNT(*) FROM miembro_mesa mm WHERE mm.id_mesa = m.id_mesa) AS miembros,
       (SELECT COUNT(DISTINCT pe.id_docente) FROM padron_electoral pe
         WHERE pe.id_mesa = m.id_mesa AND pe.ya_voto = 1) AS electores_que_votaron,
       (SELECT COUNT(*) FROM acta_electoral a WHERE a.id_mesa = m.id_mesa AND a.estado = 'VIGENTE') AS actas_emitidas
  FROM mesa_electoral m;

CREATE OR REPLACE VIEW v_miembros_mesa AS
SELECT m.id_proceso, m.id_mesa, m.numero_mesa, mm.orden_sorteo, mm.rol, mm.titular, mm.asistio,
       d.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS docente, f.nombre AS facultad
  FROM miembro_mesa mm
  JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
  JOIN docente d        ON d.id_docente = mm.id_docente
  JOIN facultad f       ON f.id_facultad = d.id_facultad;

-- RN20: docentes que SÍ pueden entrar al sorteo de mesas de cada proceso
CREATE OR REPLACE VIEW v_elegibles_sorteo AS
SELECT DISTINCT pe.id_proceso, pe.id_mesa, d.id_docente, d.dni,
       CONCAT(d.apellidos, ', ', d.nombres) AS docente
  FROM padron_electoral pe
  JOIN docente d ON d.id_docente = pe.id_docente
 WHERE pe.habilitado_para_votar = 1
   AND d.estado = 'ACTIVO'
   AND fn_tiene_cargo_excluyente(d.id_docente) = 0
   AND NOT EXISTS (SELECT 1 FROM candidato ca
                     JOIN lista_electoral l ON l.id_lista = ca.id_lista
                     JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                    WHERE ca.id_docente = d.id_docente AND c.id_proceso = pe.id_proceso
                      AND ca.estado_validacion <> 'EXCLUIDO')
   AND NOT EXISTS (SELECT 1 FROM personero p
                     JOIN lista_electoral l ON l.id_lista = p.id_lista
                     JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                    WHERE p.id_docente = d.id_docente AND c.id_proceso = pe.id_proceso
                      AND p.estado_acreditacion <> 'REVOCADO')
   AND NOT EXISTS (SELECT 1 FROM miembro_mesa mm
                     JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
                    WHERE mm.id_docente = d.id_docente AND m.id_proceso = pe.id_proceso);

-- RN35: multas con datos del docente
CREATE OR REPLACE VIEW v_multas_detalle AS
SELECT mu.id_multa, mu.id_proceso, p.nombre AS proceso,
       d.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS docente, f.nombre AS facultad,
       mu.motivo, mu.uit_referencia, mu.porcentaje_uit, mu.monto,
       mu.estado_pago, mu.fecha_generacion, mu.fecha_pago
  FROM multa mu
  JOIN proceso_electoral p ON p.id_proceso = mu.id_proceso
  JOIN docente d           ON d.id_docente = mu.id_docente
  JOIN facultad f          ON f.id_facultad = d.id_facultad;

-- Tachas con denunciante, candidato y lista
CREATE OR REPLACE VIEW v_tachas_detalle AS
SELECT t.id_tacha, c.id_proceso, c.nombre AS cargo, l.id_lista, l.nombre AS lista,
       ca.id_candidato, ca.rol_en_lista,
       CONCAT(dc.apellidos, ', ', dc.nombres) AS candidato,
       CONCAT(dd.apellidos, ', ', dd.nombres) AS denunciante,
       t.motivo, t.estado, t.fecha_presentacion, t.fecha_resolucion, t.resolucion
  FROM tacha t
  JOIN candidato ca      ON ca.id_candidato = t.id_candidato
  JOIN lista_electoral l ON l.id_lista = ca.id_lista
  JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
  JOIN docente dc        ON dc.id_docente = ca.id_docente
  JOIN docente dd        ON dd.id_docente = t.id_docente_denunciante;
