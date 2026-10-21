package pe.unp.elecciones.electoral.votacion;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.service.Bitacora;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS09 / CUS10 · Lecturas compartidas por VerificarElector, RegistrarAsistencia y RegistrarVoto.
 *
 * <p>Usa la mesa de CUS08 (mesa_electoral.estado = 'INSTALADA') y el padrón (PadronMesa). Los estados
 * del elector son los de la sección 5.4.1 del informe: PENDIENTE, HABILITADO, VOTO y
 * HABILITADO_SIN_VOTAR (más INHABILITADO si el padrón lo excluye).
 */
@Service
public class VotacionConsulta {

    static final String MESA_INSTALADA = "INSTALADA";
    static final String PROCESO_EN_VOTACION = "VOTACION";

    private static final String SELECT_MESA = """
            SELECT m.id_mesa AS id, m.numero_mesa AS numero, m.ubicacion, m.estado,
                   m.hora_instalacion, m.hora_cierre, m.total_electores,
                   m.id_proceso, p.nombre AS proceso, p.estado AS estado_proceso,
                   p.fecha_inicio, p.fecha_fin
              FROM mesa_electoral m
              JOIN proceso_electoral p ON p.id_proceso = m.id_proceso
            """;

    /** Una fila por elector de la mesa: cargos del padrón, asistencia y habilitación pendiente. */
    private static final String SELECT_ELECTORES = """
            SELECT x.id_docente, d.dni, d.nombres, d.apellidos,
                   CONCAT(d.apellidos, ', ', d.nombres) AS nombre, d.categoria, d.url_foto,
                   f.nombre AS facultad,
                   x.id_proceso, x.id_mesa, x.habilitado, x.cargos, x.cargos_votados, x.pendientes,
                   a.id_asistencia, a.metodo AS metodo_asistencia, a.hora_asistencia,
                   h.id_habilitacion, h.id_terminal, t.nombre AS terminal, h.fecha_entrega
              FROM (SELECT id_docente, id_proceso, MAX(id_mesa) AS id_mesa,
                           MAX(habilitado_para_votar) AS habilitado,
                           COUNT(*) AS cargos, SUM(ya_voto) AS cargos_votados,
                           SUM(habilitado_para_votar = 1 AND ya_voto = 0) AS pendientes
                      FROM padron_electoral WHERE id_mesa = ?
                     GROUP BY id_docente, id_proceso) x
              JOIN docente d ON d.id_docente = x.id_docente
              LEFT JOIN facultad f ON f.id_facultad = d.id_facultad
              LEFT JOIN asistencia_elector a ON a.id_proceso = x.id_proceso AND a.id_docente = x.id_docente
              LEFT JOIN habilitacion_terminal h ON h.id_asistencia = a.id_asistencia AND h.estado = 'PENDIENTE'
              LEFT JOIN terminal_votacion t ON t.id_terminal = h.id_terminal
             WHERE 1 = 1
            """;

    private final ProcedimientoDao dao;
    private final Bitacora bitacora;
    private volatile boolean instalada;
    private volatile Boolean hayRolInstalacion;

    public VotacionConsulta(ProcedimientoDao dao, Bitacora bitacora) {
        this.dao = dao;
        this.bitacora = bitacora;
    }

    /** Falla con un mensaje claro si falta ejecutar la migración de CUS09 / CUS10. */
    void verificarInstalacion() {
        if (instalada) {
            return;
        }
        int existe = dao.entero("""
                SELECT COUNT(*) FROM information_schema.tables
                 WHERE table_schema = DATABASE() AND table_name = 'asistencia_elector'
                """);
        if (existe == 0) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Faltan las tablas de CUS09/CUS10: ejecute base-de-datos/06_verificar_elector_emitir_voto.sql.");
        }
        instalada = true;
    }

    // ─── Mesas ───────────────────────────────────────────────────────────────

    /** Mesas de los procesos vigentes; un miembro de mesa solo ve las suyas. */
    public List<Map<String, Object>> mesas(Integer idDocenteMiembro) {
        verificarInstalacion();
        String filtro = idDocenteMiembro == null ? "" : """
                 AND EXISTS (SELECT 1 FROM miembro_mesa mm WHERE mm.id_mesa = m.id_mesa AND mm.id_docente = ?)
                """;
        String sql = SELECT_MESA + " WHERE p.estado NOT IN ('ANULADO', 'FINALIZADO') AND m.estado <> 'ANULADA'"
                + filtro + " ORDER BY (m.estado = 'INSTALADA') DESC, m.id_proceso DESC, LENGTH(m.numero_mesa), m.numero_mesa";
        return idDocenteMiembro == null ? dao.consultar(sql) : dao.consultar(sql, idDocenteMiembro);
    }

    public Map<String, Object> mesa(Integer idMesa) {
        verificarInstalacion();
        List<Map<String, Object>> filas = dao.consultar(SELECT_MESA + " WHERE m.id_mesa = ?", idMesa);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "La mesa no existe.");
        }
        Map<String, Object> mesa = filas.get(0);
        String motivo = motivoNoAtiende(mesa);
        mesa.put("atiende", motivo == null);
        mesa.put("motivoNoAtiende", motivo);
        return mesa;
    }

    /** null si la mesa puede atender electores; si no, el motivo (RF61, RN06, RF73). */
    static String motivoNoAtiende(Map<String, Object> mesa) {
        String estado = String.valueOf(mesa.get("estado"));
        if (!PROCESO_EN_VOTACION.equals(String.valueOf(mesa.get("estadoProceso")))) {
            return "RN06: el proceso está " + mesa.get("estadoProceso") + ", no en VOTACION.";
        }
        if (!MESA_INSTALADA.equals(estado)) {
            return "PENDIENTE".equals(estado)
                    ? "RF61: la mesa aún no está instalada (CUS08 Instalar mesa)."
                    : "La mesa está " + estado + ": no atiende electores.";
        }
        LocalDateTime ahora = LocalDateTime.now();
        if (mesa.get("fechaInicio") instanceof LocalDateTime inicio && ahora.isBefore(inicio)) {
            return "RN06: el sufragio aún no empieza.";
        }
        if (mesa.get("fechaFin") instanceof LocalDateTime fin && ahora.isAfter(fin)) {
            return "RF73: el horario de sufragio ya terminó.";
        }
        return null;
    }

    static void exigirQueAtienda(Map<String, Object> mesa) {
        String motivo = motivoNoAtiende(mesa);
        if (motivo != null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, motivo);
        }
    }

    // ─── Electores (PadronMesa) ─────────────────────────────────────────────

    public List<Map<String, Object>> electoresDeMesa(Integer idMesa) {
        List<Map<String, Object>> filas = dao.consultar(SELECT_ELECTORES + " ORDER BY d.apellidos, d.nombres", idMesa);
        filas.forEach(VotacionConsulta::completarElector);
        return filas;
    }

    /** 3 consultarHabilitacion(): el elector en el padrón de ESTA mesa; null si no figura en ella. */
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

    /** A3: si figura en el padrón del proceso pero en otra mesa, la indica. */
    Map<String, Object> mesaAsignada(Integer idProceso, String dni, Integer idDocente) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT d.id_docente, CONCAT(d.apellidos, ', ', d.nombres) AS nombre,
                       m.id_mesa, m.numero_mesa, m.ubicacion
                  FROM padron_electoral pe
                  JOIN docente d ON d.id_docente = pe.id_docente
                  JOIN mesa_electoral m ON m.id_mesa = pe.id_mesa
                 WHERE pe.id_proceso = ? AND (d.dni = ? OR d.id_docente = ?)
                 LIMIT 1
                """, idProceso, dni, idDocente);
        return filas.isEmpty() ? null : filas.get(0);
    }

    private static void completarElector(Map<String, Object> e) {
        int pendientes = numero(e.get("pendientes"));
        int votados = numero(e.get("cargosVotados"));
        String estado;
        if (numero(e.get("habilitado")) == 0 || (pendientes == 0 && votados == 0)) {
            estado = "INHABILITADO";
        } else if (pendientes == 0) {
            estado = "VOTO";
        } else if (e.get("idHabilitacion") != null) {
            estado = "HABILITADO";
        } else if (e.get("idAsistencia") != null) {
            estado = "HABILITADO_SIN_VOTAR";
        } else {
            estado = "PENDIENTE";
        }
        e.put("estadoElector", estado);
        e.put("habilitado", numero(e.get("habilitado")) == 1);
        e.put("pendientes", pendientes);
        e.put("cargosVotados", votados);
        e.put("cargos", numero(e.get("cargos")));
    }

    /** Totales de la mesa por estado del elector. */
    public Map<String, Object> resumen(List<Map<String, Object>> electores) {
        Map<String, Object> resumen = new LinkedHashMap<>();
        resumen.put("electores", electores.size());
        for (String estado : List.of("PENDIENTE", "HABILITADO", "VOTO", "HABILITADO_SIN_VOTAR", "INHABILITADO")) {
            resumen.put(estado, electores.stream().filter(e -> estado.equals(e.get("estadoElector"))).count());
        }
        long votaron = (long) resumen.get("VOTO");
        long habiles = electores.size() - (long) resumen.get("INHABILITADO");
        resumen.put("participacion", habiles == 0 ? 0 : Math.round(votaron * 1000.0 / habiles) / 10.0);
        return resumen;
    }

    // ─── Terminales ──────────────────────────────────────────────────────────

    /** Terminales de la mesa con su estado: LIBRE, HABILITADO, EN_USO o FUERA_DE_SERVICIO. */
    public List<Map<String, Object>> terminales(Integer idMesa) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT t.id_terminal, t.nombre, t.activo, t.ultima_conexion,
                       h.id_habilitacion, h.fecha_habilitacion, h.fecha_entrega
                  FROM terminal_votacion t
                  LEFT JOIN habilitacion_terminal h ON h.id_terminal = t.id_terminal AND h.estado = 'PENDIENTE'
                 WHERE t.id_mesa = ?
                 ORDER BY t.nombre
                """, idMesa);
        for (Map<String, Object> t : filas) {
            String estado;
            if (numero(t.get("activo")) == 0) {
                estado = "FUERA_DE_SERVICIO";
            } else if (t.get("idHabilitacion") == null) {
                estado = "LIBRE";
            } else {
                estado = t.get("fechaEntrega") == null ? "HABILITADO" : "EN_USO";
            }
            t.put("activo", numero(t.get("activo")) == 1);
            t.put("estadoTerminal", estado);
        }
        return filas;
    }

    Map<String, Object> terminal(Integer idTerminal) {
        List<Map<String, Object>> filas = dao.consultar(
                "SELECT id_terminal, id_mesa, nombre, activo FROM terminal_votacion WHERE id_terminal = ?", idTerminal);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El terminal no existe.");
        }
        return filas.get(0);
    }

    // ─── Incidencias (RF66) ──────────────────────────────────────────────────

    void registrarIncidencia(Integer idProceso, Integer idMesa, Integer idDocente, String tipo, String detalle,
            Integer idUsuario) {
        dao.ejecutar("""
                INSERT INTO incidencia_mesa (id_proceso, id_mesa, id_docente, tipo, detalle, id_usuario)
                VALUES (?, ?, ?, ?, ?, ?)
                """, idProceso, idMesa, idDocente, tipo, detalle, idUsuario);
        Map<String, Object> bit = new LinkedHashMap<>();
        bit.put("id_mesa", idMesa);
        bit.put("id_docente", idDocente);
        bit.put("tipo", tipo);
        bitacora.registrar(idUsuario, idProceso, "INCIDENCIA_MESA", bit);
    }

    public List<Map<String, Object>> incidencias(Integer idMesa) {
        return dao.consultar("""
                SELECT i.id_incidencia, i.tipo, i.detalle, i.fecha, i.id_docente, d.dni,
                       CONCAT(d.apellidos, ', ', d.nombres) AS nombre, u.username AS registrado_por
                  FROM incidencia_mesa i
                  LEFT JOIN docente d ON d.id_docente = i.id_docente
                  LEFT JOIN usuario u ON u.id_usuario = i.id_usuario
                 WHERE i.id_mesa = ?
                 ORDER BY i.id_incidencia DESC
                 LIMIT 100
                """, idMesa);
    }

    // ─── Presidente de mesa ──────────────────────────────────────────────────

    /**
     * El Presidente que ejerce en la mesa. Si existe la columna de CUS08 (rol_instalacion: un suplente
     * puede asumir la presidencia), se usa; si no, el presidente titular sorteado.
     */
    boolean esPresidente(Integer idMesa, Integer idDocente) {
        if (idDocente == null) {
            return false;
        }
        if (hayRolInstalacion == null) {
            hayRolInstalacion = dao.entero("""
                    SELECT COUNT(*) FROM information_schema.columns
                     WHERE table_schema = DATABASE() AND table_name = 'miembro_mesa' AND column_name = 'rol_instalacion'
                    """) > 0;
        }
        String condicion = hayRolInstalacion
                ? "COALESCE(rol_instalacion, IF(titular = 1, rol, NULL)) = 'PRESIDENTE'"
                : "titular = 1 AND rol = 'PRESIDENTE'";
        return dao.entero("SELECT COUNT(*) FROM miembro_mesa WHERE id_mesa = ? AND id_docente = ? AND " + condicion,
                idMesa, idDocente) > 0;
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
