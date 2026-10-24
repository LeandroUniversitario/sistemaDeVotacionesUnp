package pe.unp.elecciones.electoral.escrutinio;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import pe.unp.elecciones.auth.Rol;
import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS12 · Lecturas compartidas por ValidarTotales, ConciliarVotos y GenerarActaEscrutinio:
 * mesas, precondición (sufragio cerrado y acta de sufragio firmada), votantes (3 contarVotantes),
 * cuadre manual contra digital por cargo (8 mostrarCuadre), impugnaciones (paso 4) y acta de
 * escrutinio (13 mostrarActaGenerada).
 *
 * <p>El conteo digital solo se muestra después de registrar el conteo manual, para que no
 * condicione la lectura de las cédulas.
 */
@Service
public class EscrutinioConsulta {

    private static final String SELECT_MESA = """
            SELECT m.id_mesa AS id, m.numero_mesa AS numero, m.ubicacion, m.estado, m.total_electores,
                   m.hora_instalacion, m.hora_cierre, m.id_proceso, p.nombre AS proceso, p.estado AS estado_proceso,
                   c.estado AS estado_cierre, c.total_votaron, e.estado AS estado_escrutinio, e.observada
              FROM mesa_electoral m
              JOIN proceso_electoral p ON p.id_proceso = m.id_proceso
              LEFT JOIN cierre_mesa c ON c.id_mesa = m.id_mesa
              LEFT JOIN escrutinio_mesa e ON e.id_mesa = m.id_mesa
            """;
    private static final String ORDEN_MESAS = " ORDER BY m.id_proceso DESC, LENGTH(m.numero_mesa), m.numero_mesa";
    private static final Map<String, String> NOMBRE_CARGO =
            Map.of("PRESIDENTE", "presidente", "SECRETARIO", "secretario", "VOCAL", "vocal");

    private final ProcedimientoDao dao;
    private final ObjectMapper json;
    private volatile boolean instalada;

    public EscrutinioConsulta(ProcedimientoDao dao, ObjectMapper json) {
        this.dao = dao;
        this.json = json;
    }

    /** Falla con un mensaje claro si falta ejecutar la migración del CUS12. */
    void verificarInstalacion() {
        if (instalada) {
            return;
        }
        int existe = dao.entero("""
                SELECT COUNT(*) FROM information_schema.tables
                 WHERE table_schema = DATABASE() AND table_name IN ('escrutinio_mesa', 'escrutinio_conteo', 'cierre_mesa')
                """);
        if (existe < 3) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Faltan las tablas del CUS12: ejecute base-de-datos/11_escrutinio_conciliacion.sql en la base de datos.");
        }
        instalada = true;
    }

    // ─── Procesos y mesas ────────────────────────────────────────────────────

    public List<Map<String, Object>> procesos() {
        verificarInstalacion();
        return dao.consultar("""
                SELECT p.id_proceso AS id, p.nombre, p.estado, p.fecha_inicio, p.fecha_fin,
                       COUNT(m.id_mesa) AS mesas,
                       COALESCE(SUM(c.estado = 'ACTA_EMITIDA'), 0) AS cerradas,
                       COALESCE(SUM(e.id_mesa IS NOT NULL AND e.estado IN ('CEDULAS_CONTADAS', 'CONTEO_REGISTRADO')), 0) AS en_curso,
                       COALESCE(SUM(e.estado IN ('ACTA_EMITIDA', 'ENTREGADA')), 0) AS actas,
                       COALESCE(SUM(e.estado = 'ENTREGADA'), 0) AS entregadas,
                       COALESCE(SUM(e.observada = 1), 0) AS observadas
                  FROM proceso_electoral p
                  LEFT JOIN mesa_electoral m  ON m.id_proceso = p.id_proceso
                  LEFT JOIN cierre_mesa c     ON c.id_mesa = m.id_mesa
                  LEFT JOIN escrutinio_mesa e ON e.id_mesa = m.id_mesa
                 WHERE p.estado <> 'ANULADO'
                 GROUP BY p.id_proceso, p.nombre, p.estado, p.fecha_inicio, p.fecha_fin
                 ORDER BY (p.estado IN ('VOTACION', 'CERRADO')) DESC, p.fecha_inicio DESC
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
                   AND (EXISTS (SELECT 1 FROM miembro_mesa x WHERE x.id_mesa = m.id_mesa AND x.id_docente = ?)
                        OR EXISTS (SELECT 1 FROM reemplazo_mesa r WHERE r.id_mesa = m.id_mesa AND r.id_docente = ?))
                """ + ORDEN_MESAS, idDocente, idDocente);
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
        return idDocente != null && dao.entero("""
                SELECT (SELECT COUNT(*) FROM miembro_mesa WHERE id_mesa = ? AND id_docente = ?)
                     + (SELECT COUNT(*) FROM reemplazo_mesa WHERE id_mesa = ? AND id_docente = ?)
                """, idMesa, idDocente, idMesa, idDocente) > 0;
    }

    // ─── Actores: presidente y secretario de mesa ───────────────────────────

    /** Miembros en funciones desde la instalación (CUS08): titular, suplente o reemplazante. */
    List<Map<String, Object>> firmantes(Integer idMesa) {
        return dao.consultar("""
                SELECT mm.rol_instalacion AS cargo, mm.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS nombre,
                       IF(mm.titular = 1, 'TITULAR', 'SUPLENTE') AS origen
                  FROM miembro_mesa mm JOIN docente d ON d.id_docente = mm.id_docente
                 WHERE mm.id_mesa = ? AND mm.rol_instalacion IN ('PRESIDENTE', 'SECRETARIO', 'VOCAL')
                UNION ALL
                SELECT r.cargo, r.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres), 'REEMPLAZANTE'
                  FROM reemplazo_mesa r JOIN docente d ON d.id_docente = r.id_docente
                 WHERE r.id_mesa = ?
                 ORDER BY FIELD(cargo, 'PRESIDENTE', 'SECRETARIO', 'VOCAL')
                """, idMesa, idMesa);
    }

    /**
     * Entre los miembros, actúa quien ejerce alguno de los cargos indicados (tabla 38: el
     * presidente cuenta las cédulas y confirma; el secretario ingresa el conteo). Si ese cargo
     * lo ejerce un reemplazante, puede actuar cualquier miembro presente. El CEUNP siempre puede.
     */
    void exigirCargo(Integer idMesa, Usuario usuario, String accion, String... cargos) {
        if (usuario.getRol() != Rol.MIEMBRO_MESA) {
            return;
        }
        List<String> permitidos = Arrays.asList(cargos);
        List<Map<String, Object>> enFunciones = firmantes(idMesa).stream()
                .filter(f -> permitidos.contains(String.valueOf(f.get("cargo")))).toList();
        if (enFunciones.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La mesa no registra "
                    + NOMBRE_CARGO.get(cargos[0]) + " en funciones (CUS08).");
        }
        for (Map<String, Object> f : enFunciones) {
            if (!"REEMPLAZANTE".equals(f.get("origen")) && numero(f.get("idDocente")) == numero(usuario.getIdDocente())) {
                return;
            }
        }
        boolean hayReemplazante = enFunciones.stream().anyMatch(f -> "REEMPLAZANTE".equals(f.get("origen")));
        if (hayReemplazante && dao.entero("SELECT COUNT(*) FROM miembro_mesa WHERE id_mesa = ? AND id_docente = ? AND asistio = 1",
                idMesa, usuario.getIdDocente()) > 0) {
            return;
        }
        String quienes = enFunciones.stream()
                .map(f -> "al " + NOMBRE_CARGO.get(String.valueOf(f.get("cargo"))) + " en funciones (" + f.get("nombre") + ")")
                .collect(Collectors.joining(" o "));
        throw new ResponseStatusException(HttpStatus.FORBIDDEN, accion + " le corresponde a " + quienes + ".");
    }

    // ─── Detalle de la mesa ──────────────────────────────────────────────────

    public Map<String, Object> detalle(Integer idMesa) {
        Map<String, Object> mesa = mesa(idMesa);
        Map<String, Object> registro = registro(idMesa);
        Map<String, Object> cierre = cierre(idMesa);
        String estado = registro == null ? null : String.valueOf(registro.get("estado"));
        String paso = estado == null ? "CEDULAS" : switch (estado) {
            case "CEDULAS_CONTADAS" -> "CONTEO";
            case "CONTEO_REGISTRADO" -> "ACTA";
            case "ACTA_EMITIDA" -> "ENTREGA";
            default -> "FIN";
        };

        List<Map<String, Object>> requisitos = new ArrayList<>();
        if (registro == null) {
            String estadoProceso = String.valueOf(mesa.get("estadoProceso"));
            boolean proceso = "VOTACION".equals(estadoProceso) || "CERRADO".equals(estadoProceso);
            boolean cerrada = "CERRADA".equals(mesa.get("estado")) && cierre != null;
            boolean actaSufragio = cierre != null && "ACTA_EMITIDA".equals(cierre.get("estado"));
            requisitos.add(requisito("PROCESO", "Votación del proceso concluida o en curso (VOTACION o CERRADO)", proceso,
                    proceso ? null : "El proceso está " + estadoProceso + "."));
            requisitos.add(requisito("CIERRE", "Sufragio de la mesa cerrado (CUS11)", cerrada,
                    cerrada ? null : "La mesa está " + mesa.get("estado") + ": cierre primero el sufragio."));
            requisitos.add(requisito("ACTA_SUFRAGIO", "Acta de sufragio emitida y firmada (CUS11)", actaSufragio,
                    actaSufragio ? null : "Emita el acta de sufragio en «Cerrar sufragio»."));
        }
        boolean cumple = requisitos.stream().allMatch(r -> Boolean.TRUE.equals(r.get("cumplido")));
        boolean abierto = "CEDULAS_CONTADAS".equals(estado) || "CONTEO_REGISTRADO".equals(estado);

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mesa", mesa);
        respuesta.put("cierre", cierre);
        respuesta.put("registro", registro);
        respuesta.put("paso", paso);
        respuesta.put("requisitos", requisitos);
        respuesta.put("cargos", cargos(idMesa, registro));
        respuesta.put("impugnaciones", impugnaciones(idMesa));
        respuesta.put("personeros", personeros(idMesa));
        respuesta.put("firmantes", firmantes(idMesa));
        respuesta.put("puedeContar", registro == null && cumple);
        respuesta.put("puedeConciliar", abierto);
        respuesta.put("puedeEmitir", "CONTEO_REGISTRADO".equals(estado));
        respuesta.put("puedeEntregar", "ACTA_EMITIDA".equals(estado));
        respuesta.put("acta", acta(idMesa));
        return respuesta;
    }

    Map<String, Object> registro(Integer idMesa) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT e.estado, e.hora_inicio, e.hora_fin, e.total_votantes, e.cedulas_contadas, e.cedulas_sobrantes,
                       e.cedulas_faltantes, e.cedulas_escrutadas, e.observacion_cedulas, e.veces_conteo,
                       e.conteo_cuadra, e.total_cuadra, e.fecha_conteo, e.prevalece_fisica, e.observada, e.observaciones,
                       e.fecha_acta, e.fecha_entrega, e.recibido_por, e.ejemplares, e.copias_personeros,
                       e.entrega_padron, e.entrega_material, e.observacion_entrega, e.codigo_cargo,
                       ui.username AS iniciado_por, uc.username AS contado_por, ua.username AS emitido_por,
                       ue.username AS entregado_por
                  FROM escrutinio_mesa e
                  LEFT JOIN usuario ui ON ui.id_usuario = e.id_usuario_inicio
                  LEFT JOIN usuario uc ON uc.id_usuario = e.id_usuario_conteo
                  LEFT JOIN usuario ua ON ua.id_usuario = e.id_usuario_acta
                  LEFT JOIN usuario ue ON ue.id_usuario = e.id_usuario_entrega
                 WHERE e.id_mesa = ?
                """, idMesa);
        return filas.isEmpty() ? null : filas.get(0);
    }

    /** Datos del cierre (CUS11) que usa el escrutinio: votantes y acta de sufragio. */
    Map<String, Object> cierre(Integer idMesa) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT c.estado, c.hora_cierre, c.total_electores, c.total_votaron, c.total_no_votaron,
                       c.cedulas_recibidas, c.cedulas_no_utilizadas, c.id_acta AS id_acta_sufragio, c.fecha_acta
                  FROM cierre_mesa c WHERE c.id_mesa = ?
                """, idMesa);
        return filas.isEmpty() ? null : filas.get(0);
    }

    /**
     * Cargos que se votan en la mesa con sus listas admitidas (en el orden de la cédula, RN18) y,
     * una vez registrado el conteo, el cuadre por opción (8 mostrarCuadre).
     */
    List<Map<String, Object>> cargos(Integer idMesa, Map<String, Object> registro) {
        List<Map<String, Object>> cargos = dao.consultar("""
                SELECT c.id_cargo, c.nombre, SUM(pe.ya_voto) AS votantes,
                       (SELECT COUNT(*) FROM impugnacion_electoral i WHERE i.id_mesa = pe.id_mesa AND i.id_cargo = c.id_cargo) AS impugnaciones
                  FROM padron_electoral pe JOIN cargo_electoral c ON c.id_cargo = pe.id_cargo
                 WHERE pe.id_mesa = ? AND pe.habilitado_para_votar = 1
                 GROUP BY c.id_cargo, c.nombre, pe.id_mesa
                 ORDER BY c.id_cargo
                """, idMesa);
        int faltantes = registro == null ? 0 : numero(registro.get("cedulasFaltantes"));
        for (Map<String, Object> cargo : cargos) {
            Object idCargo = cargo.get("idCargo");
            cargo.put("listas", dao.consultar("""
                    SELECT id_lista, nombre, simbolo, orden_cedula
                      FROM lista_electoral WHERE id_cargo = ? AND estado = 'ADMITIDA'
                     ORDER BY COALESCE(orden_cedula, 999), nombre
                    """, idCargo));
            List<Map<String, Object>> conteo = dao.consultar("""
                    SELECT k.opcion, k.id_lista, l.nombre, l.orden_cedula, k.votos_manual, k.votos_digital,
                           IF(k.opcion = 'IMPUGNADO', 0, k.votos_manual - k.votos_digital) AS diferencia
                      FROM escrutinio_conteo k LEFT JOIN lista_electoral l ON l.id_lista = k.id_lista
                     WHERE k.id_mesa = ? AND k.id_cargo = ?
                     ORDER BY FIELD(k.opcion, 'LISTA', 'BLANCO', 'NULO', 'IMPUGNADO'), COALESCE(l.orden_cedula, 999), l.nombre
                    """, idMesa, idCargo);
            cargo.put("conteo", conteo);
            if (!conteo.isEmpty()) {
                int manual = 0;
                int digital = 0;
                int impugnados = 0;
                int sobran = 0;
                int faltan = 0;
                for (Map<String, Object> fila : conteo) {
                    int m = numero(fila.get("votosManual"));
                    int d = numero(fila.get("votosDigital"));
                    manual += m;
                    digital += d;
                    if ("IMPUGNADO".equals(fila.get("opcion"))) {
                        impugnados += m;
                    } else {
                        sobran += Math.max(m - d, 0);
                        faltan += Math.max(d - m, 0);
                    }
                }
                cargo.put("totalManual", manual);
                cargo.put("totalDigital", digital);
                cargo.put("impugnados", impugnados);
                // Igual que sp_registrar_conteo (RF83, A2 y A4)
                cargo.put("cuadra", sobran == 0 && faltan - impugnados >= 0 && faltan - impugnados <= faltantes);
                cargo.put("totalCuadra", manual == numero(cargo.get("votantes"))); // RF82
            }
        }
        return cargos;
    }

    /** Paso 4: votos impugnados por los personeros durante el escrutinio (A4: pendientes). */
    List<Map<String, Object>> impugnaciones(Integer idMesa) {
        return dao.consultar("""
                SELECT i.id_impugnacion, i.id_cargo, c.nombre AS cargo, i.motivo, i.estado, i.decision_mesa,
                       i.fecha_presentacion, pe.id_personero, CONCAT(d.apellidos, ', ', d.nombres) AS personero,
                       l.nombre AS lista
                  FROM impugnacion_electoral i
                  JOIN personero pe      ON pe.id_personero = i.id_personero
                  JOIN docente d         ON d.id_docente = pe.id_docente
                  JOIN lista_electoral l ON l.id_lista = pe.id_lista
                  LEFT JOIN cargo_electoral c ON c.id_cargo = i.id_cargo
                 WHERE i.id_mesa = ?
                 ORDER BY i.id_impugnacion
                """, idMesa);
    }

    /** Personeros presentes en la mesa (CUS08): fiscalizan, impugnan y pueden firmar el acta. */
    List<Map<String, Object>> personeros(Integer idMesa) {
        return dao.consultar("""
                SELECT pe.id_personero, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS nombre, pe.tipo,
                       l.nombre AS lista
                  FROM asistencia_personero_mesa ap
                  JOIN personero pe      ON pe.id_personero = ap.id_personero
                  JOIN lista_electoral l ON l.id_lista = pe.id_lista
                  JOIN docente d         ON d.id_docente = pe.id_docente
                 WHERE ap.id_mesa = ?
                 ORDER BY FIELD(pe.tipo, 'MESA', 'GENERAL', 'ALTERNO'), l.nombre, d.apellidos
                """, idMesa);
    }

    /** 13 mostrarActaGenerada(): acta de escrutinio emitida, sin el token del QR (solo se entrega al emitirla). */
    Map<String, Object> acta(Integer idMesa) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT id_acta, fecha_emision, estado, hash_integridad, contenido_json
                  FROM acta_electoral WHERE id_mesa = ? AND tipo = 'ESCRUTINIO'
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
                 ORDER BY FIELD(SUBSTRING_INDEX(f.rol, ' ', 1), 'PRESIDENTE', 'SECRETARIO', 'VOCAL', 'PERSONERO'), f.id_firma
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
