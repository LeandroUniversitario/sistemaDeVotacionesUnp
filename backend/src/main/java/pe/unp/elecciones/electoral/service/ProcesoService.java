package pe.unp.elecciones.electoral.service;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

/**
 * Ciclo de vida del proceso electoral sobre los procedimientos almacenados:
 * cambio de estado (con las reglas en sp_cambiar_estado_proceso), calificación de listas y consultas
 * públicas. El cómputo, la segunda vuelta, las nulidades y las multas viven en sus CUS (computo/, nulidades/, multas/).
 * Sin @Transactional a propósito (ver ProcedimientoDao).
 */
@Service
public class ProcesoService {

    private final ProcedimientoDao dao;

    public ProcesoService(ProcedimientoDao dao) {
        this.dao = dao;
    }

    // ─── Proceso ──────────────────────────────────────────────────────────────

    public Map<String, Object> obtener(Integer idProceso) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT id_proceso AS id, nombre, fecha_inicio, fecha_fin, estado, tipo,
                       id_proceso_padre, quorum_minimo, fecha_convocatoria,
                       fecha_limite_inscripcion, fecha_cierre_real, motivo_anulacion
                  FROM proceso_electoral WHERE id_proceso = ?
                """, idProceso);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Proceso electoral no encontrado");
        }
        return filas.get(0);
    }

    /** CREADO -> INSCRIPCION -> VOTACION -> CERRADO, con los requisitos de cada paso. */
    public Map<String, Object> cambiarEstado(Integer idProceso, String nuevoEstado, Integer idUsuario) {
        dao.llamar("sp_cambiar_estado_proceso", ProcedimientoDao.SIN_SALIDA, idProceso, nuevoEstado, idUsuario);
        return obtener(idProceso);
    }

    // ─── Listas y cédula ──────────────────────────────────────────────────────

    /** RN12: el CEUNP admite o excluye la fórmula completa. */
    public List<Map<String, Object>> validarLista(Integer idLista, boolean admitir, String motivo, Integer idUsuario) {
        dao.llamar("sp_validar_lista", ProcedimientoDao.SIN_SALIDA, idLista, admitir, motivo, idUsuario);
        return dao.consultar("""
                SELECT id_lista AS id, id_cargo, nombre, simbolo, orden_cedula, estado,
                       fecha_inscripcion, motivo_exclusion
                  FROM lista_electoral WHERE id_lista = ?
                """, idLista);
    }

    /** RN15: candidatos aprobados de listas admitidas (portal de transparencia). */
    public List<Map<String, Object>> candidatosPublicos(Integer idProceso) {
        return dao.consultar("""
                SELECT cargo, lista, url_plan_gobierno, rol_en_lista, candidato,
                       categoria, grado_academico, facultad, url_hoja_vida
                  FROM v_candidatos_publicos WHERE id_proceso = ?
                 ORDER BY cargo, lista, rol_en_lista
                """, idProceso);
    }

    // ─── Resultados ───────────────────────────────────────────────────────────

    /**
     * RF99: el portal muestra los resultados solo después de su publicación por el CEUNP (CUS14).
     */
    public Map<String, Object> resultadosPublicos(Integer idProceso) {
        List<Map<String, Object>> computo = dao.consultar(
                "SELECT estado FROM computo_proceso WHERE id_proceso = ?", idProceso);
        if (computo.isEmpty() || !"PUBLICADO".equals(String.valueOf(computo.get(0).get("estado")))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "RF99: los resultados se muestran después de su publicación por el CEUNP.");
        }
        Map<String, Object> respuesta = resultados(idProceso);
        {
            List<Map<String, Object>> publicado = dao.consultar("""
                    SELECT resultado, participacion_pct, electores_habiles, votaron, numero_resolucion,
                           fecha_computo, fecha_proclamacion, fecha_publicacion
                      FROM v_portal_resultados WHERE id_proceso = ?
                    """, idProceso);
            respuesta.put("publicacion", publicado.isEmpty() ? null : publicado.get(0));
            if (!publicado.isEmpty()) {
                respuesta.put("proclamados", dao.consultar("""
                        SELECT c.nombre AS cargo, l.nombre AS lista, pc.votos, pc.porcentaje_validos, pc.codigo_credencial
                          FROM proclamacion_cargo pc
                          JOIN cargo_electoral c ON c.id_cargo = pc.id_cargo
                          JOIN lista_electoral l ON l.id_lista = pc.id_lista
                         WHERE pc.id_proceso = ? ORDER BY pc.id_cargo
                        """, idProceso));
                respuesta.put("mesas", dao.consultar("""
                        SELECT x.numero_mesa, c.nombre AS cargo,
                               COALESCE(l.nombre, CASE x.opcion WHEN 'BLANCO' THEN 'Votos en blanco' ELSE 'Votos nulos' END) AS lista,
                               x.votos
                          FROM v_computo_conteo_mesa x
                          JOIN mesa_electoral m  ON m.id_mesa = x.id_mesa AND m.estado <> 'ANULADA'
                          JOIN cargo_electoral c ON c.id_cargo = x.id_cargo
                          LEFT JOIN lista_electoral l ON l.id_lista = x.id_lista
                         WHERE x.id_proceso = ? AND x.opcion <> 'IMPUGNADO'
                         ORDER BY LENGTH(x.numero_mesa), x.numero_mesa, x.id_cargo,
                                  FIELD(x.opcion, 'LISTA', 'BLANCO', 'NULO'), COALESCE(l.orden_cedula, 999)
                        """, idProceso));
            }
        }
        return respuesta;
    }

    /** RF99: procesos con resultados publicados en el portal. */
    public List<Map<String, Object>> resultadosPublicados() {
        return dao.consultar("""
                SELECT id_proceso, proceso, tipo, estado_proceso, resultado, participacion_pct, numero_resolucion,
                       fecha_publicacion
                  FROM v_portal_resultados ORDER BY fecha_publicacion DESC
                """);
    }

    /** Destino del QR del acta general de cómputo y de la resolución de proclamación (CUS14). */
    public Map<String, Object> verificarActaComputo(String token) {
        return primeraFila(dao.llamar("sp_verificar_acta_computo", ProcedimientoDao.SIN_SALIDA, tokenValido(token)),
                "El acta no existe o el código no es válido.");
    }

    /** RF102: resoluciones de nulidad declaradas y publicadas en el portal (CUS15). */
    public List<Map<String, Object>> nulidadesPublicadas() {
        return dao.consultar("""
                SELECT id_nulidad, id_proceso, proceso, tipo, estado_proceso, alcance, numero_mesa, causal,
                       numero_resolucion, fundamento_resolucion, fecha_resolucion, fecha_publicacion, comunicado_a
                  FROM v_portal_nulidades ORDER BY fecha_publicacion DESC
                """);
    }

    /** Destino del QR de una resolución de nulidad (CUS15). */
    public Map<String, Object> verificarResolucionNulidad(String token) {
        return primeraFila(dao.llamar("sp_verificar_resolucion_nulidad", ProcedimientoDao.SIN_SALIDA, tokenValido(token)),
                "La resolución no existe o el código no es válido.");
    }

    /** Destino del QR de la resolución de multas (CUS16). */
    public Map<String, Object> verificarResolucionMultas(String token) {
        return primeraFila(dao.llamar("sp_verificar_resolucion_multas", ProcedimientoDao.SIN_SALIDA, tokenValido(token)),
                "La resolución no existe o el código no es válido.");
    }

    /** Solo hay resultados después del cómputo: nunca se exponen conteos parciales. */
    public Map<String, Object> resultados(Integer idProceso) {
        Map<String, Object> proceso = obtener(idProceso);
        if (dao.entero("SELECT COUNT(*) FROM resultado_electoral WHERE id_proceso = ?", idProceso) == 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "RN26: los resultados se publican después del cómputo oficial.");
        }
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("proceso", proceso);
        respuesta.put("cargos", dao.consultar("""
                SELECT c.id_cargo, c.nombre AS cargo, c.estado_resultado,
                       c.id_lista_ganadora, l.nombre AS lista_ganadora,
                       fn_participacion_cargo(c.id_cargo) AS participacion_pct
                  FROM cargo_electoral c
                  LEFT JOIN lista_electoral l ON l.id_lista = c.id_lista_ganadora
                 WHERE c.id_proceso = ? ORDER BY c.id_cargo
                """, idProceso));
        respuesta.put("detalle", dao.consultar("""
                SELECT r.id_cargo, r.id_lista, COALESCE(l.nombre, CONCAT('VOTO ', r.tipo_voto)) AS lista,
                       r.tipo_voto, r.total_votos, r.porcentaje_validos, r.posicion
                  FROM resultado_electoral r
                  LEFT JOIN lista_electoral l ON l.id_lista = r.id_lista
                 WHERE r.id_proceso = ?
                 ORDER BY r.id_cargo, (r.id_lista IS NULL), r.total_votos DESC
                """, idProceso));
        return respuesta;
    }

    /** CUS16: el docente ve sus multas cuando el Pleno ya las determinó (las generadas sin resolución aún pueden cambiar). */
    public List<Map<String, Object>> multasDeDocente(Integer idDocente) {
        return dao.consultar(
                """
                SELECT * FROM v_multas_detalle
                 WHERE id_docente = ? AND (estado_reporte IS NULL OR estado_reporte = 'RESUELTO')
                 ORDER BY fecha_generacion DESC
                """, idDocente);
    }

    // ─── Verificación por QR ──────────────────────────────────────────────────

    public Map<String, Object> verificarConstancia(String token) {
        return primeraFila(dao.llamar("sp_verificar_constancia", ProcedimientoDao.SIN_SALIDA, tokenValido(token)),
                "La constancia no existe o el código no es válido.");
    }

    public Map<String, Object> verificarActa(String token) {
        return primeraFila(dao.llamar("sp_verificar_acta", ProcedimientoDao.SIN_SALIDA, tokenValido(token)),
                "El acta no existe o el código no es válido.");
    }

    private static Map<String, Object> primeraFila(ProcedimientoDao.Resultado resultado, String mensaje) {
        if (resultado.filas().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, mensaje);
        }
        return resultado.filas().get(0);
    }

    private static String tokenValido(String token) {
        String limpio = token == null ? "" : token.trim().toLowerCase();
        if (!limpio.matches("[0-9a-f]{64}")) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El código no es válido.");
        }
        return limpio;
    }
}
