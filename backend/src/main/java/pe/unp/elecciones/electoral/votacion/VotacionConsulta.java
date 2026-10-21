package pe.unp.elecciones.electoral.votacion;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS09 / CUS10 · Lecturas compartidas por VerificarElector y EmitirVoto.
 *
 * <p>Usa las mismas tablas que CUS08 (mesa_electoral.estado = 'INSTALADA') y que sp_emitir_voto
 * (padron_electoral.ya_voto). La autorización de cabina vive en autorizacion_voto.
 */
@Service
public class VotacionConsulta {

    static final String MESA_INSTALADA = "INSTALADA";
    static final String PROCESO_EN_VOTACION = "VOTACION";
    private static final int MINUTOS_POR_DEFECTO = 15;

    private static final String SELECT_MESA = """
            SELECT m.id_mesa AS id, m.numero_mesa AS numero, m.ubicacion, m.estado,
                   m.hora_instalacion, m.hora_cierre, m.total_electores,
                   m.id_proceso, p.nombre AS proceso, p.estado AS estado_proceso,
                   p.fecha_inicio, p.fecha_fin
              FROM mesa_electoral m
              JOIN proceso_electoral p ON p.id_proceso = m.id_proceso
            """;

    /** Una fila por elector de la mesa: cargos del padrón y autorización pendiente. */
    private static final String SELECT_ELECTORES = """
            SELECT x.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS nombre,
                   d.categoria, f.nombre AS facultad,
                   x.id_proceso, x.id_mesa, x.habilitado, x.cargos, x.cargos_votados, x.pendientes,
                   x.ultima_votacion,
                   a.id_autorizacion, a.metodo AS metodo_autorizacion,
                   a.fecha_autorizacion, a.fecha_expiracion AS autorizacion_vence
              FROM (SELECT id_docente, id_proceso, MAX(id_mesa) AS id_mesa,
                           MAX(habilitado_para_votar) AS habilitado,
                           COUNT(*) AS cargos, SUM(ya_voto) AS cargos_votados,
                           SUM(habilitado_para_votar = 1 AND ya_voto = 0) AS pendientes,
                           MAX(fecha_votacion) AS ultima_votacion
                      FROM padron_electoral WHERE id_mesa = ?
                     GROUP BY id_docente, id_proceso) x
              JOIN docente d ON d.id_docente = x.id_docente
              LEFT JOIN facultad f ON f.id_facultad = d.id_facultad
              LEFT JOIN autorizacion_voto a ON a.id_proceso = x.id_proceso
                    AND a.id_docente = x.id_docente AND a.estado = 'PENDIENTE'
             WHERE 1 = 1
            """;

    private final ProcedimientoDao dao;
    private volatile boolean instalada;

    public VotacionConsulta(ProcedimientoDao dao) {
        this.dao = dao;
    }

    /** Falla con un mensaje claro si falta ejecutar la migración de autorizacion_voto. */
    void verificarInstalacion() {
        if (instalada) {
            return;
        }
        int existe = dao.entero("""
                SELECT COUNT(*) FROM information_schema.tables
                 WHERE table_schema = DATABASE() AND table_name = 'autorizacion_voto'
                """);
        if (existe == 0) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Falta la tabla autorizacion_voto: ejecute base-de-datos/06_verificar_elector_emitir_voto.sql.");
        }
        instalada = true;
    }

    /** Las autorizaciones vencidas sin votar se anulan solas (el elector debe volver a la mesa). */
    void anularVencidas() {
        verificarInstalacion();
        dao.ejecutar("""
                UPDATE autorizacion_voto
                   SET estado = 'ANULADA', motivo_anulacion = 'Venció sin que el elector termine de votar.'
                 WHERE estado = 'PENDIENTE' AND fecha_expiracion <= NOW()
                """);
    }

    int minutosAutorizacion() {
        List<Map<String, Object>> filas = dao.consultar(
                "SELECT valor FROM parametro_global WHERE clave = 'MINUTOS_AUTORIZACION_VOTO'");
        try {
            int minutos = filas.isEmpty() ? MINUTOS_POR_DEFECTO
                    : Integer.parseInt(String.valueOf(filas.get(0).get("valor")).trim());
            return minutos > 0 ? minutos : MINUTOS_POR_DEFECTO;
        } catch (NumberFormatException e) {
            return MINUTOS_POR_DEFECTO;
        }
    }

    // ─── Mesas ───────────────────────────────────────────────────────────────

    /** Mesas de los procesos vigentes; un miembro de mesa solo ve las suyas. */
    public List<Map<String, Object>> mesas(Integer idDocenteMiembro) {
        String filtro = idDocenteMiembro == null ? "" : """
                 AND EXISTS (SELECT 1 FROM miembro_mesa mm WHERE mm.id_mesa = m.id_mesa AND mm.id_docente = ?)
                """;
        String sql = SELECT_MESA + " WHERE p.estado NOT IN ('ANULADO', 'FINALIZADO') AND m.estado <> 'ANULADA'"
                + filtro + " ORDER BY (m.estado = 'INSTALADA') DESC, m.id_proceso DESC, LENGTH(m.numero_mesa), m.numero_mesa";
        return idDocenteMiembro == null ? dao.consultar(sql) : dao.consultar(sql, idDocenteMiembro);
    }

    public Map<String, Object> mesa(Integer idMesa) {
        List<Map<String, Object>> filas = dao.consultar(SELECT_MESA + " WHERE m.id_mesa = ?", idMesa);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "La mesa no existe.");
        }
        Map<String, Object> mesa = filas.get(0);
        mesa.put("atiende", motivoNoAtiende(mesa) == null);
        mesa.put("motivoNoAtiende", motivoNoAtiende(mesa));
        return mesa;
    }

    /** null si la mesa puede atender electores; si no, el motivo (RN06 / RN07). */
    static String motivoNoAtiende(Map<String, Object> mesa) {
        String estado = String.valueOf(mesa.get("estado"));
        if (!PROCESO_EN_VOTACION.equals(String.valueOf(mesa.get("estadoProceso")))) {
            return "RN06: el proceso está " + mesa.get("estadoProceso") + ", no en VOTACION.";
        }
        if (!MESA_INSTALADA.equals(estado)) {
            return "PENDIENTE".equals(estado)
                    ? "RN07: la mesa aún no está instalada (CUS08 Instalar mesa)."
                    : "La mesa está " + estado + ": ya no atiende electores.";
        }
        LocalDateTime ahora = LocalDateTime.now();
        if (mesa.get("fechaInicio") instanceof LocalDateTime inicio && ahora.isBefore(inicio)) {
            return "RN06: el sufragio aún no empieza.";
        }
        if (mesa.get("fechaFin") instanceof LocalDateTime fin && ahora.isAfter(fin)) {
            return "RN06: el horario de sufragio ya terminó.";
        }
        return null;
    }

    /** Totales de la mesa para el tablero del miembro de mesa. */
    public Map<String, Object> resumen(List<Map<String, Object>> electores) {
        Map<String, Object> resumen = new LinkedHashMap<>();
        resumen.put("electores", electores.size());
        for (String estado : List.of("VOTO", "AUTORIZADO", "PENDIENTE", "INHABILITADO")) {
            resumen.put(estado.toLowerCase(), electores.stream().filter(e -> estado.equals(e.get("estadoElector"))).count());
        }
        long votaron = (long) resumen.get("voto");
        int habilitados = (int) electores.stream().filter(e -> !"INHABILITADO".equals(e.get("estadoElector"))).count();
        resumen.put("participacion", habilitados == 0 ? 0 : Math.round(votaron * 1000.0 / habilitados) / 10.0);
        return resumen;
    }

    // ─── Electores ───────────────────────────────────────────────────────────

    public List<Map<String, Object>> electoresDeMesa(Integer idMesa) {
        List<Map<String, Object>> filas = dao.consultar(SELECT_ELECTORES + " ORDER BY d.apellidos, d.nombres", idMesa);
        filas.forEach(VotacionConsulta::completarElector);
        return filas;
    }

    /** El elector en el padrón de ESTA mesa, por DNI o por id; null si no figura en ella. */
    Map<String, Object> electorEnMesa(Integer idMesa, String dni, Integer idDocente) {
        List<Map<String, Object>> filas = dni != null
                ? dao.consultar(SELECT_ELECTORES + " AND d.dni = ?", idMesa, dni)
                : dao.consultar(SELECT_ELECTORES + " AND d.id_docente = ?", idMesa, idDocente);
        if (filas.isEmpty()) {
            return null;
        }
        Map<String, Object> elector = filas.get(0);
        completarElector(elector);
        return elector;
    }

    /** Si el docente figura en el padrón del proceso pero en otra mesa, la indica (para orientarlo). */
    Map<String, Object> mesaAsignada(Integer idProceso, String dni, Integer idDocente) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT m.id_mesa, m.numero_mesa, m.ubicacion
                  FROM padron_electoral pe
                  JOIN docente d ON d.id_docente = pe.id_docente
                  JOIN mesa_electoral m ON m.id_mesa = pe.id_mesa
                 WHERE pe.id_proceso = ? AND (d.dni = ? OR d.id_docente = ?)
                 LIMIT 1
                """, idProceso, dni, idDocente);
        return filas.isEmpty() ? null : filas.get(0);
    }

    /** Calcula estadoElector: VOTO, AUTORIZADO, PENDIENTE o INHABILITADO. */
    private static void completarElector(Map<String, Object> e) {
        int pendientes = numero(e.get("pendientes"));
        int votados = numero(e.get("cargosVotados"));
        String estado;
        if (numero(e.get("habilitado")) == 0) {
            estado = "INHABILITADO";
        } else if (pendientes == 0) {
            estado = votados > 0 ? "VOTO" : "INHABILITADO";
        } else if (e.get("idAutorizacion") != null) {
            estado = "AUTORIZADO";
        } else {
            estado = "PENDIENTE";
        }
        e.put("estadoElector", estado);
        e.put("habilitado", numero(e.get("habilitado")) == 1);
        e.put("pendientes", pendientes);
        e.put("cargosVotados", votados);
        e.put("cargos", numero(e.get("cargos")));
    }

    // ─── Autorizaciones ──────────────────────────────────────────────────────

    /** Autorización PENDIENTE (y sin vencer) del docente en el proceso; null si no tiene. */
    Map<String, Object> autorizacionPendiente(Integer idProceso, Integer idDocente) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT a.id_autorizacion, a.id_mesa, m.numero_mesa, m.ubicacion, m.estado AS estado_mesa,
                       a.metodo, a.fecha_autorizacion, a.fecha_expiracion
                  FROM autorizacion_voto a
                  JOIN mesa_electoral m ON m.id_mesa = a.id_mesa
                 WHERE a.id_proceso = ? AND a.id_docente = ? AND a.estado = 'PENDIENTE'
                   AND a.fecha_expiracion > NOW()
                """, idProceso, idDocente);
        return filas.isEmpty() ? null : filas.get(0);
    }

    /** Últimas autorizaciones de la mesa (sin dato alguno del sentido del voto). */
    public List<Map<String, Object>> autorizacionesDeMesa(Integer idMesa) {
        return dao.consultar("""
                SELECT a.id_autorizacion, a.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS nombre,
                       a.metodo, a.estado, a.fecha_autorizacion, a.fecha_expiracion, a.fecha_uso,
                       a.motivo_anulacion, u.username AS autorizado_por
                  FROM autorizacion_voto a
                  JOIN docente d ON d.id_docente = a.id_docente
                  LEFT JOIN usuario u ON u.id_usuario = a.id_usuario_mesa
                 WHERE a.id_mesa = ?
                 ORDER BY a.id_autorizacion DESC
                 LIMIT 50
                """, idMesa);
    }

    static int numero(Object valor) {
        if (valor instanceof Number n) {
            return n.intValue();
        }
        if (valor instanceof Boolean b) {
            return b ? 1 : 0;
        }
        return 0;
    }
}
