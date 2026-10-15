package pe.unp.elecciones.electoral.credenciales;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS07 · Lecturas compartidas por GenerarTokenQR, EmitirConstancia y VerificarCredencial.
 *
 * <p>Cada titular sale con {@code apto} (si hoy puede recibir credencial) y, si la tiene,
 * su credencial VIGENTE (sin token: el token solo se entrega al emitir).
 */
@Service
public class CredencialesConsulta {

    /** Estados del proceso en que se emiten credenciales: antes y durante la jornada. */
    static final Set<String> ESTADOS_EMISION = Set.of("CREADO", "INSCRIPCION", "VOTACION");
    /** Mesas en que la credencial todavía sirve. */
    static final Set<String> MESAS_ACTIVAS = Set.of("PENDIENTE", "INSTALADA");
    /** Listas que siguen en carrera. */
    static final Set<String> LISTAS_HABILES = Set.of("INSCRITA", "ADMITIDA");

    private static final String DATOS_DOCENTE = """
            d.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS nombre, d.categoria,
            f.nombre AS facultad,
            """;
    private static final String DATOS_CREDENCIAL = """
            cq.id_credencial, cq.fecha_emision, cq.fecha_expiracion, cq.usos, cq.ultimo_uso
            """;

    private final ProcedimientoDao dao;
    private volatile boolean instalada;

    public CredencialesConsulta(ProcedimientoDao dao) {
        this.dao = dao;
    }

    /** Falla con un mensaje claro si falta ejecutar la migración de la tabla credencial_qr. */
    void verificarInstalacion() {
        if (instalada) {
            return;
        }
        int existe = dao.entero("""
                SELECT COUNT(*) FROM information_schema.tables
                 WHERE table_schema = DATABASE() AND table_name = 'credencial_qr'
                """);
        if (existe == 0) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Falta la tabla credencial_qr: ejecute base-de-datos/04_credenciales_qr.sql en la base de datos.");
        }
        instalada = true;
    }

    // ─── Procesos ────────────────────────────────────────────────────────────

    public List<Map<String, Object>> procesos() {
        verificarInstalacion();
        List<Map<String, Object>> procesos = dao.consultar("""
                SELECT p.id_proceso AS id, p.nombre, p.estado, p.fecha_inicio, p.fecha_fin,
                       (SELECT COUNT(*) FROM credencial_qr cq
                         WHERE cq.id_proceso = p.id_proceso AND cq.estado = 'VIGENTE') AS vigentes
                  FROM proceso_electoral p
                 WHERE p.estado <> 'ANULADO'
                 ORDER BY (p.estado IN ('CREADO', 'INSCRIPCION', 'VOTACION')) DESC, p.fecha_creacion DESC
                """);
        procesos.forEach(CredencialesConsulta::marcarAdmision);
        return procesos;
    }

    public Map<String, Object> proceso(Integer idProceso) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT id_proceso AS id, nombre, estado, fecha_inicio, fecha_fin
                  FROM proceso_electoral WHERE id_proceso = ?
                """, idProceso);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El proceso electoral no existe.");
        }
        return marcarAdmision(filas.get(0));
    }

    /** Agrega admiteEmision y, si no admite, el motivo. */
    private static Map<String, Object> marcarAdmision(Map<String, Object> proceso) {
        String estado = String.valueOf(proceso.get("estado"));
        String motivo = null;
        if (!ESTADOS_EMISION.contains(estado)) {
            motivo = "El proceso está " + estado + ": ya no se emiten credenciales.";
        } else if (proceso.get("fechaFin") instanceof LocalDateTime fin && !fin.isAfter(LocalDateTime.now())) {
            motivo = "El sufragio del proceso ya terminó ("
                    + fin.format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")) + ").";
        }
        proceso.put("admiteEmision", motivo == null);
        proceso.put("motivoNoAdmite", motivo);
        return proceso;
    }

    // ─── Titulares ───────────────────────────────────────────────────────────

    /** Proceso, resumen por tipo y titulares del tipo pedido. */
    public Map<String, Object> detalle(Integer idProceso, TipoCredencial tipo) {
        verificarInstalacion();
        Map<String, Object> proceso = proceso(idProceso);
        Map<TipoCredencial, Map<String, Object>> resumen = new EnumMap<>(TipoCredencial.class);
        List<Map<String, Object>> titularesDelTipo = List.of();
        for (TipoCredencial t : TipoCredencial.values()) {
            List<Map<String, Object>> titulares = titulares(idProceso, t, null, null);
            Map<String, Object> cuenta = new LinkedHashMap<>();
            cuenta.put("titulares", titulares.size());
            cuenta.put("aptos", titulares.stream().filter(x -> Boolean.TRUE.equals(x.get("apto"))).count());
            cuenta.put("vigentes", titulares.stream().filter(x -> x.get("credencial") != null).count());
            cuenta.put("pendientes", titulares.stream()
                    .filter(x -> Boolean.TRUE.equals(x.get("apto")) && x.get("credencial") == null).count());
            resumen.put(t, cuenta);
            if (t == tipo) {
                titularesDelTipo = titulares;
            }
        }
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("proceso", proceso);
        respuesta.put("tipo", tipo.name());
        respuesta.put("resumen", resumen);
        respuesta.put("titulares", titularesDelTipo);
        return respuesta;
    }

    /** Un titular (para emitir); 404 si no figura en el proceso. */
    public Map<String, Object> titular(Integer idProceso, TipoCredencial tipo, Integer idTitular) {
        List<Map<String, Object>> filas = titulares(idProceso, tipo, idTitular, null);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, switch (tipo) {
                case ELECTOR -> "El docente no figura en el padrón definitivo del proceso.";
                case MIEMBRO_MESA -> "El docente no es miembro de una mesa de este proceso.";
                case PERSONERO -> "El personero no está acreditado en este proceso.";
            });
        }
        return filas.get(0);
    }

    /**
     * Titulares de un tipo. {@code idTitular} filtra uno (id_docente o id_personero) y
     * {@code idDocente} filtra los de un docente (credenciales propias).
     */
    List<Map<String, Object>> titulares(Integer idProceso, TipoCredencial tipo, Integer idTitular, Integer idDocente) {
        List<Object> args = new ArrayList<>();
        String sql = switch (tipo) {
            case ELECTOR -> {
                args.add(idProceso);
                args.add(idProceso);
                yield """
                        SELECT x.id_docente AS id_titular, %s
                               x.id_mesa, m.numero_mesa, m.ubicacion, m.estado AS estado_mesa,
                               x.habilitado, x.cargos, x.cargos_votados, %s
                          FROM (SELECT id_docente, MAX(id_mesa) AS id_mesa,
                                       MAX(habilitado_para_votar) AS habilitado,
                                       SUM(habilitado_para_votar) AS cargos, SUM(ya_voto) AS cargos_votados
                                  FROM padron_electoral WHERE id_proceso = ? GROUP BY id_docente) x
                          JOIN docente d ON d.id_docente = x.id_docente
                          LEFT JOIN facultad f ON f.id_facultad = d.id_facultad
                          LEFT JOIN mesa_electoral m ON m.id_mesa = x.id_mesa
                          LEFT JOIN credencial_qr cq ON cq.id_proceso = ? AND cq.tipo = 'ELECTOR'
                                AND cq.id_docente = x.id_docente AND cq.estado = 'VIGENTE'
                         WHERE 1 = 1
                        """.formatted(DATOS_DOCENTE, DATOS_CREDENCIAL)
                        + filtro(args, "x.id_docente", idTitular, idDocente)
                        + " ORDER BY d.apellidos, d.nombres";
            }
            case MIEMBRO_MESA -> {
                args.add(idProceso);
                yield """
                        SELECT mm.id_docente AS id_titular, %s
                               mm.id_mesa, m.numero_mesa, m.ubicacion, m.estado AS estado_mesa,
                               mm.rol, mm.titular, %s
                          FROM miembro_mesa mm
                          JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
                          JOIN docente d ON d.id_docente = mm.id_docente
                          LEFT JOIN facultad f ON f.id_facultad = d.id_facultad
                          LEFT JOIN credencial_qr cq ON cq.id_proceso = m.id_proceso AND cq.tipo = 'MIEMBRO_MESA'
                                AND cq.id_docente = mm.id_docente AND cq.id_mesa = mm.id_mesa AND cq.estado = 'VIGENTE'
                         WHERE m.id_proceso = ? AND m.estado <> 'ANULADA'
                        """.formatted(DATOS_DOCENTE, DATOS_CREDENCIAL)
                        + filtro(args, "mm.id_docente", idTitular, idDocente)
                        + " ORDER BY LENGTH(m.numero_mesa), m.numero_mesa, mm.titular DESC, mm.orden_sorteo";
            }
            case PERSONERO -> {
                args.add(idProceso);
                yield """
                        SELECT pe.id_personero AS id_titular, %s
                               pe.id_mesa, m.numero_mesa, m.ubicacion, m.estado AS estado_mesa,
                               pe.tipo AS tipo_personero, l.nombre AS lista, l.estado AS estado_lista,
                               c.nombre AS cargo, %s
                          FROM personero pe
                          JOIN lista_electoral l ON l.id_lista = pe.id_lista
                          JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                          JOIN docente d ON d.id_docente = pe.id_docente
                          LEFT JOIN facultad f ON f.id_facultad = d.id_facultad
                          LEFT JOIN mesa_electoral m ON m.id_mesa = pe.id_mesa
                          LEFT JOIN credencial_qr cq ON cq.id_personero = pe.id_personero AND cq.estado = 'VIGENTE'
                         WHERE c.id_proceso = ? AND pe.estado_acreditacion = 'ACREDITADO'
                        """.formatted(DATOS_DOCENTE, DATOS_CREDENCIAL)
                        + filtro(args, idTitular != null ? "pe.id_personero" : "pe.id_docente",
                                idTitular, idDocente)
                        + " ORDER BY c.id_cargo, l.nombre, FIELD(pe.tipo, 'GENERAL', 'ALTERNO', 'MESA'),"
                        + " LENGTH(m.numero_mesa), m.numero_mesa";
            }
        };
        List<Map<String, Object>> filas = dao.consultar(sql, args.toArray());
        filas.forEach(fila -> completar(tipo, fila));
        return filas;
    }

    private static String filtro(List<Object> args, String columnaTitular, Integer idTitular, Integer idDocente) {
        StringBuilder sql = new StringBuilder();
        if (idTitular != null) {
            sql.append(" AND ").append(columnaTitular).append(" = ?");
            args.add(idTitular);
        }
        if (idDocente != null) {
            sql.append(" AND d.id_docente = ?");
            args.add(idDocente);
        }
        return sql.toString();
    }

    /** Calcula apto/motivo, el texto de la función y anida la credencial vigente. */
    private static void completar(TipoCredencial tipo, Map<String, Object> fila) {
        String estadoMesa = fila.get("estadoMesa") == null ? null : String.valueOf(fila.get("estadoMesa"));
        String motivo = null;
        String funcion;
        switch (tipo) {
            case ELECTOR -> {
                funcion = "Elector";
                if (!verdadero(fila.get("habilitado"))) {
                    motivo = "Inhabilitado en el padrón definitivo.";
                } else if (fila.get("idMesa") == null) {
                    motivo = "Sin mesa de sufragio asignada (conforme las mesas en CUS06).";
                } else if (!MESAS_ACTIVAS.contains(estadoMesa)) {
                    motivo = "Su mesa está " + estadoMesa + ".";
                }
            }
            case MIEMBRO_MESA -> {
                String rol = String.valueOf(fila.get("rol"));
                funcion = verdadero(fila.get("titular"))
                        ? rol.charAt(0) + rol.substring(1).toLowerCase() + " de mesa (titular)"
                        : "Suplente de mesa";
                if (!MESAS_ACTIVAS.contains(estadoMesa)) {
                    motivo = "La mesa está " + estadoMesa + ".";
                }
            }
            default -> {
                String tipoPersonero = String.valueOf(fila.get("tipoPersonero"));
                funcion = "Personero " + tipoPersonero.toLowerCase() + " · " + fila.get("lista");
                if (!LISTAS_HABILES.contains(String.valueOf(fila.get("estadoLista")))) {
                    motivo = "La lista está " + fila.get("estadoLista") + ".";
                } else if ("MESA".equals(tipoPersonero) && !MESAS_ACTIVAS.contains(estadoMesa)) {
                    motivo = "Su mesa está " + estadoMesa + ".";
                }
            }
        }
        if (fila.get("idMesa") == null && tipo == TipoCredencial.PERSONERO) {
            fila.put("ubicacion", "Todas las mesas del proceso");
        }
        fila.put("funcion", funcion);
        fila.put("apto", motivo == null);
        fila.put("motivo", motivo);

        Object idCredencial = fila.remove("idCredencial");
        Map<String, Object> credencial = null;
        if (idCredencial != null) {
            credencial = new LinkedHashMap<>();
            credencial.put("id", idCredencial);
            credencial.put("fechaEmision", fila.get("fechaEmision"));
            credencial.put("fechaExpiracion", fila.get("fechaExpiracion"));
            credencial.put("usos", fila.get("usos"));
            credencial.put("ultimoUso", fila.get("ultimoUso"));
        }
        fila.remove("fechaEmision");
        fila.remove("fechaExpiracion");
        fila.remove("usos");
        fila.remove("ultimoUso");
        fila.put("credencial", credencial);
    }

    static boolean verdadero(Object valor) {
        if (valor instanceof Boolean b) {
            return b;
        }
        if (valor instanceof Number n) {
            return n.intValue() != 0;
        }
        return valor != null && "1".equals(String.valueOf(valor));
    }

    // ─── Historial y credenciales propias ────────────────────────────────────

    /** Todas las emisiones del proceso, vigentes y revocadas (auditoría). */
    public List<Map<String, Object>> historial(Integer idProceso) {
        verificarInstalacion();
        proceso(idProceso);
        return dao.consultar("""
                SELECT cq.id_credencial AS id, cq.tipo, cq.estado, d.dni,
                       CONCAT(d.apellidos, ', ', d.nombres) AS nombre, m.numero_mesa,
                       cq.fecha_emision, cq.fecha_expiracion, cq.fecha_revocacion, cq.motivo_revocacion,
                       cq.usos, cq.ultimo_uso, u.username AS emisor
                  FROM credencial_qr cq
                  JOIN docente d ON d.id_docente = cq.id_docente
                  LEFT JOIN mesa_electoral m ON m.id_mesa = cq.id_mesa
                  LEFT JOIN usuario u ON u.id_usuario = cq.id_usuario_emisor
                 WHERE cq.id_proceso = ?
                 ORDER BY cq.id_credencial DESC
                 LIMIT 500
                """, idProceso);
    }

    /** Credenciales a las que tiene derecho el docente en los procesos en curso. */
    public List<Map<String, Object>> misCredenciales(Integer idDocente) {
        verificarInstalacion();
        List<Map<String, Object>> procesos = dao.consultar("""
                SELECT id_proceso AS id, nombre, estado, fecha_inicio, fecha_fin
                  FROM proceso_electoral
                 WHERE estado IN ('CREADO', 'INSCRIPCION', 'VOTACION')
                 ORDER BY fecha_inicio
                """);
        List<Map<String, Object>> respuesta = new ArrayList<>();
        for (Map<String, Object> proceso : procesos) {
            marcarAdmision(proceso);
            Integer idProceso = ((Number) proceso.get("id")).intValue();
            List<Map<String, Object>> credenciales = new ArrayList<>();
            for (TipoCredencial tipo : TipoCredencial.values()) {
                for (Map<String, Object> titular : titulares(idProceso, tipo, null, idDocente)) {
                    titular.put("tipo", tipo.name());
                    titular.put("titulo", tipo.titulo());
                    credenciales.add(titular);
                }
            }
            if (!credenciales.isEmpty()) {
                proceso.put("credenciales", credenciales);
                respuesta.add(proceso);
            }
        }
        return respuesta;
    }
}
