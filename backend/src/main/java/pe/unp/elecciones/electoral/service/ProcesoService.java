package pe.unp.elecciones.electoral.service;

import java.sql.Types;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

/**
 * Ciclo de vida del proceso electoral sobre los procedimientos almacenados:
 * estados, padrón, calificación de listas, cómputo, segunda vuelta, nulidad y multas.
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

    /** RN34: nulidad del proceso por causal. */
    public Map<String, Object> anular(Integer idProceso, String motivo, Integer idUsuario) {
        dao.llamar("sp_anular_proceso", ProcedimientoDao.SIN_SALIDA, idProceso, motivo, idUsuario);
        return obtener(idProceso);
    }

    // ─── Padrón y participación ───────────────────────────────────────────────

    /** RF05: genera (o regenera) el padrón de cada cargo. */
    public Map<String, Object> generarPadron(Integer idProceso, Integer idUsuario) {
        ProcedimientoDao.Resultado resultado =
                dao.llamar("sp_generar_padron", ProcedimientoDao.SIN_SALIDA, idProceso, idUsuario);
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Padrón electoral generado.");
        respuesta.put("cargos", resultado.filas());
        return respuesta;
    }

    public List<Map<String, Object>> padron(Integer idProceso) {
        obtener(idProceso);
        return dao.consultar("""
                SELECT id_cargo, cargo, id_docente, dni, docente, categoria, facultad,
                       habilitado_para_votar AS habilitado, ya_voto, fecha_votacion,
                       motivo_inhabilitacion, id_mesa, numero_mesa, ubicacion
                  FROM v_padron_detalle WHERE id_proceso = ?
                 ORDER BY cargo, docente
                """, idProceso);
    }

    /** RN31: participación global y por cargo, en tiempo real. */
    public Map<String, Object> participacion(Integer idProceso) {
        obtener(idProceso);
        List<Map<String, Object>> global = dao.consultar(
                "SELECT * FROM v_quorum_proceso WHERE id_proceso = ?", idProceso);
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("proceso", global.isEmpty() ? Map.of() : global.get(0));
        respuesta.put("cargos", dao.consultar(
                "SELECT * FROM v_participacion_cargo WHERE id_proceso = ? ORDER BY id_cargo", idProceso));
        respuesta.put("cuadre", dao.consultar(
                "SELECT * FROM v_cuadre_votos WHERE id_proceso = ? ORDER BY id_cargo", idProceso));
        return respuesta;
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

    /**
     * RN18: cédula de votación. Listas ADMITIDAS de todos los cargos del proceso,
     * en el orden sorteado. Es lo que consume la terminal de votación.
     */
    public List<Map<String, Object>> cedula(Integer idProceso) {
        obtener(idProceso);
        return dao.consultar("""
                SELECT l.id_lista AS id, l.nombre, l.simbolo, l.orden_cedula,
                       c.id_cargo, c.nombre AS cargo,
                       (SELECT CONCAT(d.nombres, ' ', d.apellidos)
                          FROM candidato ca
                          JOIN docente d ON d.id_docente = ca.id_docente
                         WHERE ca.id_lista = l.id_lista AND ca.estado_validacion = 'APROBADO'
                         ORDER BY (ca.rol_en_lista IN ('RECTOR', 'DECANO')) DESC, ca.id_candidato
                         LIMIT 1) AS candidato_rector,
                       (SELECT GROUP_CONCAT(CONCAT(ca.rol_en_lista, ': ', d.nombres, ' ', d.apellidos)
                                            ORDER BY ca.id_candidato SEPARATOR ' | ')
                          FROM candidato ca
                          JOIN docente d ON d.id_docente = ca.id_docente
                         WHERE ca.id_lista = l.id_lista AND ca.estado_validacion = 'APROBADO') AS formula
                  FROM lista_electoral l
                  JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                 WHERE c.id_proceso = ? AND l.estado = 'ADMITIDA'
                 ORDER BY c.id_cargo, l.orden_cedula
                """, idProceso);
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

    /** RN26 / RN31 / RN33: cómputo oficial, una sola vez. */
    public Map<String, Object> computarResultados(Integer idProceso, Integer idUsuario) {
        dao.llamar("sp_computar_resultados", ProcedimientoDao.SIN_SALIDA, idProceso, idUsuario);
        return resultados(idProceso);
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

    /** RN33: crea el proceso hijo con las dos listas más votadas y el mismo padrón. */
    public Map<String, Object> crearSegundaVuelta(Integer idProcesoPadre, LocalDateTime inicio,
            LocalDateTime fin, Integer idUsuario) {
        if (inicio == null || fin == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Indique fecha de inicio y de fin de la segunda vuelta.");
        }
        ProcedimientoDao.Resultado resultado = dao.llamar("sp_crear_segunda_vuelta",
                new int[] {Types.INTEGER}, idProcesoPadre, inicio, fin, idUsuario);
        Object idNuevo = resultado.salidas()[0];
        if (!(idNuevo instanceof Number numero)) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR,
                    "No se obtuvo el identificador de la segunda vuelta.");
        }
        return obtener(numero.intValue());
    }

    // ─── Multas (RN35) ────────────────────────────────────────────────────────

    public Map<String, Object> generarMultas(Integer idProceso, Integer idUsuario) {
        ProcedimientoDao.Resultado resultado =
                dao.llamar("sp_generar_multas", ProcedimientoDao.SIN_SALIDA, idProceso, idUsuario);
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Multas generadas.");
        respuesta.put("resumen", resultado.filas());
        return respuesta;
    }

    public List<Map<String, Object>> multas(Integer idProceso) {
        obtener(idProceso);
        return dao.consultar(
                "SELECT * FROM v_multas_detalle WHERE id_proceso = ? ORDER BY docente, motivo", idProceso);
    }

    public List<Map<String, Object>> multasDeDocente(Integer idDocente) {
        return dao.consultar(
                "SELECT * FROM v_multas_detalle WHERE id_docente = ? ORDER BY fecha_generacion DESC", idDocente);
    }

    public List<Map<String, Object>> actualizarMulta(Integer idMulta, String estadoPago,
            String observacion, Integer idUsuario) {
        dao.llamar("sp_actualizar_multa", ProcedimientoDao.SIN_SALIDA, idMulta, estadoPago, observacion, idUsuario);
        return dao.consultar("SELECT * FROM v_multas_detalle WHERE id_multa = ?", idMulta);
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
