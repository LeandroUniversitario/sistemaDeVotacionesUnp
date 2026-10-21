package pe.unp.elecciones.electoral.cierre;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import pe.unp.elecciones.auth.Rol;
import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;
import pe.unp.elecciones.electoral.votacion.VotacionConsulta;

/**
 * CUS11 · Lecturas compartidas por CerrarVotacion, MarcarAusentes y GenerarActaSufragio:
 * mesas, requisitos del cierre (precondición y A1 de la tabla 37), total de votantes
 * (4 mostrarTotalVotantes), lista NO VOTÓ (8 mostrarListaNoVoto) y acta de sufragio
 * (13 mostrarActaSufragio).
 */
@Service
public class CierreConsulta {

    private static final String SELECT_MESA = """
            SELECT m.id_mesa AS id, m.numero_mesa AS numero, m.ubicacion, m.estado, m.total_electores,
                   m.hora_instalacion, m.hora_cierre, m.id_proceso, p.nombre AS proceso, p.estado AS estado_proceso,
                   p.fecha_inicio, p.fecha_fin, c.estado AS estado_cierre, c.total_votaron, c.total_no_votaron
              FROM mesa_electoral m
              JOIN proceso_electoral p ON p.id_proceso = m.id_proceso
              LEFT JOIN cierre_mesa c ON c.id_mesa = m.id_mesa
            """;
    private static final String ORDEN_MESAS = " ORDER BY m.id_proceso DESC, LENGTH(m.numero_mesa), m.numero_mesa";

    private final ProcedimientoDao dao;
    private final VotacionConsulta votacion;
    private final ObjectMapper json;
    private volatile boolean instalada;

    public CierreConsulta(ProcedimientoDao dao, VotacionConsulta votacion, ObjectMapper json) {
        this.dao = dao;
        this.votacion = votacion;
        this.json = json;
    }

    /** Falla con un mensaje claro si falta ejecutar la migración del CUS11. */
    void verificarInstalacion() {
        if (instalada) {
            return;
        }
        int existe = dao.entero("""
                SELECT COUNT(*) FROM information_schema.tables
                 WHERE table_schema = DATABASE() AND table_name = 'cierre_mesa'
                """);
        if (existe == 0) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Faltan las tablas del CUS11: ejecute base-de-datos/10_cerrar_sufragio.sql en la base de datos.");
        }
        instalada = true;
    }

    // ─── Procesos y mesas ────────────────────────────────────────────────────

    public List<Map<String, Object>> procesos() {
        verificarInstalacion();
        return dao.consultar("""
                SELECT p.id_proceso AS id, p.nombre, p.estado, p.fecha_inicio, p.fecha_fin,
                       COUNT(m.id_mesa) AS mesas,
                       COALESCE(SUM(m.estado = 'INSTALADA'), 0) AS abiertas,
                       COALESCE(SUM(m.estado = 'CERRADA'), 0) AS cerradas,
                       COALESCE(SUM(c.estado = 'ACTA_EMITIDA'), 0) AS actas
                  FROM proceso_electoral p
                  LEFT JOIN mesa_electoral m ON m.id_proceso = p.id_proceso
                  LEFT JOIN cierre_mesa c ON c.id_mesa = m.id_mesa
                 WHERE p.estado <> 'ANULADO'
                 GROUP BY p.id_proceso, p.nombre, p.estado, p.fecha_inicio, p.fecha_fin
                 ORDER BY (p.estado = 'VOTACION') DESC, p.fecha_inicio DESC
                """);
    }

    public List<Map<String, Object>> mesas(Integer idProceso) {
        verificarInstalacion();
        if (idProceso == null) {
            return dao.consultar(SELECT_MESA + " WHERE p.estado <> 'ANULADO'" + ORDEN_MESAS);
        }
        return dao.consultar(SELECT_MESA + " WHERE m.id_proceso = ?" + ORDEN_MESAS, idProceso);
    }

    /** Mesas en las que el docente fue sorteado (rol MIEMBRO_MESA). */
    public List<Map<String, Object>> mesasDeMiembro(Integer idDocente) {
        verificarInstalacion();
        return dao.consultar(SELECT_MESA + """
                 WHERE p.estado <> 'ANULADO'
                   AND EXISTS (SELECT 1 FROM miembro_mesa x WHERE x.id_mesa = m.id_mesa AND x.id_docente = ?)
                """ + ORDEN_MESAS, idDocente);
    }

    public Map<String, Object> mesa(Integer idMesa) {
        verificarInstalacion();
        List<Map<String, Object>> filas = dao.consultar(SELECT_MESA + " WHERE m.id_mesa = ?", idMesa);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Mesa no encontrada.");
        }
        return filas.get(0);
    }

    public boolean esMiembro(Integer idMesa, Integer idDocente) {
        return idDocente != null && dao.entero(
                "SELECT COUNT(*) FROM miembro_mesa WHERE id_mesa = ? AND id_docente = ?", idMesa, idDocente) > 0;
    }

    // ─── Presidente de mesa (actor del CUS11) ───────────────────────────────

    /** Presidente y secretario en funciones desde la instalación (CUS08): titular, suplente o reemplazante. */
    List<Map<String, Object>> firmantes(Integer idMesa) {
        return dao.consultar("""
                SELECT mm.rol_instalacion AS cargo, mm.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS nombre,
                       IF(mm.titular = 1, 'TITULAR', 'SUPLENTE') AS origen
                  FROM miembro_mesa mm JOIN docente d ON d.id_docente = mm.id_docente
                 WHERE mm.id_mesa = ? AND mm.rol_instalacion IN ('PRESIDENTE', 'SECRETARIO')
                UNION ALL
                SELECT r.cargo, r.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres), 'REEMPLAZANTE'
                  FROM reemplazo_mesa r JOIN docente d ON d.id_docente = r.id_docente
                 WHERE r.id_mesa = ? AND r.cargo IN ('PRESIDENTE', 'SECRETARIO')
                 ORDER BY FIELD(cargo, 'PRESIDENTE', 'SECRETARIO')
                """, idMesa, idMesa);
    }

    /**
     * El actor del CUS11 es el Presidente de mesa: entre los miembros, cierra quien ejerce la
     * presidencia. Si la asume un reemplazante sin cuenta, puede hacerlo cualquier miembro presente.
     * El CEUNP siempre puede cerrar.
     */
    void exigirPresidente(Integer idMesa, Usuario usuario) {
        if (usuario.getRol() != Rol.MIEMBRO_MESA) {
            return;
        }
        Map<String, Object> presidente = firmantes(idMesa).stream()
                .filter(f -> "PRESIDENTE".equals(f.get("cargo"))).findFirst().orElse(null);
        if (presidente == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La mesa no registra presidente en funciones (CUS08).");
        }
        if ("REEMPLAZANTE".equals(presidente.get("origen"))) {
            if (dao.entero("SELECT COUNT(*) FROM miembro_mesa WHERE id_mesa = ? AND id_docente = ? AND asistio = 1",
                    idMesa, usuario.getIdDocente()) == 0) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Solo un miembro presente de la mesa puede cerrar el sufragio.");
            }
            return;
        }
        if (numero(presidente.get("idDocente")) != numero(usuario.getIdDocente())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Cierra el sufragio el presidente en funciones: " + presidente.get("nombre") + ".");
        }
    }

    // ─── Detalle de la mesa ──────────────────────────────────────────────────

    public Map<String, Object> detalle(Integer idMesa) {
        Map<String, Object> mesa = mesa(idMesa);
        String estado = String.valueOf(mesa.get("estado"));
        boolean enVotacion = "VOTACION".equals(String.valueOf(mesa.get("estadoProceso")));
        Map<String, Object> registro = registro(idMesa);
        String paso = registro == null ? "CERRAR" : switch (String.valueOf(registro.get("estado"))) {
            case "VOTACION_CERRADA" -> "AUSENTES";
            case "AUSENTES_MARCADOS" -> "ACTA";
            default -> "EMITIDA";
        };

        List<Map<String, Object>> electores = votacion.electoresDeMesa(idMesa);
        Map<String, Object> resumen = votacion.resumen(electores);
        int votando = dao.entero("""
                SELECT COUNT(*) FROM habilitacion_terminal h JOIN asistencia_elector a ON a.id_asistencia = h.id_asistencia
                 WHERE a.id_mesa = ? AND h.estado = 'PENDIENTE'
                """, idMesa);
        Map<String, Object> horario = horario(mesa);

        List<Map<String, Object>> requisitos = new ArrayList<>();
        if (registro == null) {
            boolean instalada = "INSTALADA".equals(estado);
            long faltan = numero(resumen.get("PENDIENTE")) + numero(resumen.get("HABILITADO"))
                    + numero(resumen.get("HABILITADO_SIN_VOTAR"));
            boolean hora = Boolean.TRUE.equals(horario.get("alcanzada")) || !Boolean.TRUE.equals(horario.get("control"));
            requisitos.add(requisito("PROCESO", "Proceso electoral en VOTACION", enVotacion,
                    enVotacion ? null : "El proceso está " + mesa.get("estadoProceso") + "."));
            requisitos.add(requisito("MESA", "Mesa instalada (CUS08)", instalada,
                    instalada ? null : "La mesa está " + estado + "."));
            requisitos.add(requisito("HORARIO", "Son las " + horario.get("horaCierre") + " o ya votaron todos los electores (RN06)",
                    hora || faltan == 0, hora || faltan == 0 ? null
                            : "Faltan " + faltan + " elector(es) por votar y el sufragio termina a las " + horario.get("horaCierre") + "."));
            requisitos.add(requisito("VOTANDO", "Ningún elector votando en un terminal (A1, Art. 51a)", votando == 0,
                    votando == 0 ? null : votando + " elector(es) aún votan: espere a que terminen o anule la habilitación en «Verificar elector»."));
        }
        boolean cumple = requisitos.stream().allMatch(r -> Boolean.TRUE.equals(r.get("cumplido")));

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mesa", mesa);
        respuesta.put("horario", horario);
        respuesta.put("resumen", resumen);
        respuesta.put("votando", votando);
        respuesta.put("requisitos", requisitos);
        respuesta.put("registro", registro);
        respuesta.put("paso", paso);
        respuesta.put("noVotaron", noVotaron(idMesa));
        respuesta.put("firmantes", firmantes(idMesa));
        respuesta.put("personeros", personeros(idMesa));
        respuesta.put("puedeCerrar", registro == null && cumple);
        respuesta.put("puedeMarcar", "AUSENTES".equals(paso));
        respuesta.put("puedeEmitir", "ACTA".equals(paso));
        respuesta.put("acta", acta(idMesa));
        return respuesta;
    }

    /** RN06: hora de cierre del sufragio (fecha_fin del proceso) y control horario (SUFRAGIO_CONTROL_HORARIO). */
    Map<String, Object> horario(Map<String, Object> mesa) {
        Map<String, Object> horario = new LinkedHashMap<>();
        LocalDateTime ahora = (LocalDateTime) dao.consultar("SELECT NOW() AS ahora").get(0).get("ahora");
        Object fin = mesa.get("fechaFin");
        List<Map<String, Object>> control = dao.consultar(
                "SELECT valor FROM parametro_global WHERE clave = 'SUFRAGIO_CONTROL_HORARIO'");
        horario.put("control", control.isEmpty() || !"0".equals(String.valueOf(control.get(0).get("valor")).trim()));
        horario.put("fin", fin);
        horario.put("horaCierre", fin instanceof LocalDateTime f ? String.format("%02d:%02d", f.getHour(), f.getMinute()) : "15:00");
        horario.put("alcanzada", fin instanceof LocalDateTime f && !ahora.isBefore(f));
        horario.put("ahora", ahora);
        return horario;
    }

    Map<String, Object> registro(Integer idMesa) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT c.estado, c.hora_cierre, c.cierre_anticipado, c.total_electores, c.total_votaron,
                       c.total_no_votaron, c.asistieron_sin_votar, c.cedulas_recibidas, c.cedulas_no_utilizadas,
                       c.firmas_lista_fisica, c.observaciones, c.fecha_ausentes, c.fecha_acta,
                       uc.username AS cerrado_por, ua.username AS marcado_por, ue.username AS emitido_por
                  FROM cierre_mesa c
                  LEFT JOIN usuario uc ON uc.id_usuario = c.id_usuario_cierre
                  LEFT JOIN usuario ua ON ua.id_usuario = c.id_usuario_ausentes
                  LEFT JOIN usuario ue ON ue.id_usuario = c.id_usuario_acta
                 WHERE c.id_mesa = ?
                """, idMesa);
        return filas.isEmpty() ? null : filas.get(0);
    }

    /**
     * 8 mostrarListaNoVoto(): electores hábiles que no votaron. Antes de marcar es la lista que
     * quedará marcada; después, la marca NO VOTÓ del padrón (RF75).
     */
    List<Map<String, Object>> noVotaron(Integer idMesa) {
        return dao.consultar("""
                SELECT d.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS nombre, f.nombre AS facultad,
                       MAX(pe.no_voto) AS marcado, (a.id_asistencia IS NOT NULL) AS asistio, a.hora_asistencia
                  FROM padron_electoral pe
                  JOIN docente d ON d.id_docente = pe.id_docente
                  LEFT JOIN facultad f ON f.id_facultad = d.id_facultad
                  LEFT JOIN asistencia_elector a ON a.id_proceso = pe.id_proceso AND a.id_docente = pe.id_docente
                 WHERE pe.id_mesa = ? AND pe.habilitado_para_votar = 1
                 GROUP BY d.id_docente, d.dni, d.apellidos, d.nombres, f.nombre, a.id_asistencia, a.hora_asistencia
                HAVING MAX(pe.ya_voto) = 0
                 ORDER BY d.apellidos, d.nombres
                """, idMesa);
    }

    /** Personeros presentes en la mesa (CUS08): pueden firmar el acta si lo desean. */
    List<Map<String, Object>> personeros(Integer idMesa) {
        return dao.consultar("""
                SELECT pe.id_personero, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS nombre, pe.tipo,
                       l.nombre AS lista, ap.hora_acreditacion AS hora_llegada
                  FROM asistencia_personero_mesa ap
                  JOIN personero pe      ON pe.id_personero = ap.id_personero
                  JOIN lista_electoral l ON l.id_lista = pe.id_lista
                  JOIN docente d         ON d.id_docente = pe.id_docente
                 WHERE ap.id_mesa = ?
                 ORDER BY FIELD(pe.tipo, 'MESA', 'GENERAL', 'ALTERNO'), l.nombre, d.apellidos
                """, idMesa);
    }

    /** 13 mostrarActaSufragio(): acta emitida, sin el token del QR (solo se entrega al emitirla). */
    Map<String, Object> acta(Integer idMesa) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT id_acta, fecha_emision, estado, hash_integridad, contenido_json
                  FROM acta_electoral WHERE id_mesa = ? AND tipo = 'SUFRAGIO'
                """, idMesa);
        if (filas.isEmpty()) {
            return null;
        }
        Map<String, Object> acta = filas.get(0);
        try {
            acta.put("contenido", json.readValue(String.valueOf(acta.remove("contenidoJson")),
                    new TypeReference<Map<String, Object>>() { }));
        } catch (Exception e) {
            acta.put("contenido", null);
        }
        acta.put("firmas", dao.consultar("""
                SELECT f.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS nombre, f.rol,
                       f.fecha_firma, f.firma_digital
                  FROM firma_acta f JOIN docente d ON d.id_docente = f.id_docente
                 WHERE f.id_acta = ?
                 ORDER BY FIELD(SUBSTRING_INDEX(f.rol, ' ', 1), 'PRESIDENTE', 'SECRETARIO', 'PERSONERO'), f.id_firma
                """, acta.get("idActa")));
        return acta;
    }

    private static Map<String, Object> requisito(String codigo, String texto, boolean cumplido, String detalle) {
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("codigo", codigo);
        r.put("texto", texto);
        r.put("cumplido", cumplido);
        r.put("detalle", detalle);
        return r;
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
