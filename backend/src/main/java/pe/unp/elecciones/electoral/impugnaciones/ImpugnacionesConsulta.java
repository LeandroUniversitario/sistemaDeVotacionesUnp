package pe.unp.elecciones.electoral.impugnaciones;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Rol;
import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS13 · Lecturas compartidas por RegistrarImpugnacion, ResolverImpugnacion y TramitarApelacion:
 * mesas, impugnaciones con su situación (v_impugnacion_efecto), personeros que pueden impugnar
 * o apelar, miembros en funciones de la mesa (RN23) y parámetros de plazo y quórum (RN36).
 */
@Service
public class ImpugnacionesConsulta {

    private static final String SELECT_MESA = """
            SELECT m.id_mesa AS id, m.numero_mesa AS numero, m.ubicacion, m.estado, m.id_proceso,
                   p.nombre AS proceso, p.estado AS estado_proceso, m.hora_cierre,
                   (SELECT COUNT(*) FROM impugnacion_electoral i WHERE i.id_mesa = m.id_mesa) AS impugnaciones,
                   (SELECT COUNT(*) FROM impugnacion_electoral i
                     WHERE i.id_mesa = m.id_mesa AND i.decision_mesa = 'PENDIENTE') AS por_resolver,
                   (SELECT COUNT(*) FROM impugnacion_electoral i
                     WHERE i.id_mesa = m.id_mesa AND i.estado = 'APELADA') AS apeladas
              FROM mesa_electoral m
              JOIN proceso_electoral p ON p.id_proceso = m.id_proceso
            """;
    private static final String ORDEN_MESAS = " ORDER BY m.id_proceso DESC, LENGTH(m.numero_mesa), m.numero_mesa";

    /** Impugnación con todos sus datos, nombres legibles y situación para el cómputo. */
    private static final String SELECT_IMPUGNACION = """
            SELECT i.id_impugnacion AS id, i.id_proceso, i.id_mesa, m.numero_mesa, i.id_cargo, c.nombre AS cargo,
                   i.motivo, i.estado, i.fecha_presentacion, i.fecha_resolucion, i.id_acta,
                   i.id_personero, CONCAT(dp.apellidos, ', ', dp.nombres) AS personero, dp.dni AS dni_personero,
                   pe.tipo AS tipo_personero, pe.id_lista AS id_lista_personero, lp.nombre AS lista_personero,
                   i.decision_mesa, i.votos_mesa_favor, i.votos_mesa_contra, i.opcion_mesa, i.id_lista_mesa,
                   lm.nombre AS lista_mesa, i.fundamento_mesa, i.fecha_decision_mesa, um.username AS decidido_por,
                   i.id_personero_apela, CONCAT(da.apellidos, ', ', da.nombres) AS apelante,
                   i.fundamento_apelacion, i.fecha_apelacion, ua.username AS apelacion_registrada_por,
                   i.decision_ceunp, i.numero_resolucion, i.miembros_pleno, i.votos_pleno_favor, i.votos_pleno_contra,
                   i.voto_dirimente, i.opcion_final, i.id_lista_final, lf.nombre AS lista_final,
                   i.fundamento_ceunp, i.fecha_fallo, uc.username AS fallado_por,
                   e.situacion, e.opcion_vigente, e.id_lista_vigente, lv.nombre AS lista_vigente
              FROM impugnacion_electoral i
              JOIN mesa_electoral m       ON m.id_mesa = i.id_mesa
              JOIN personero pe           ON pe.id_personero = i.id_personero
              JOIN docente dp             ON dp.id_docente = pe.id_docente
              JOIN lista_electoral lp     ON lp.id_lista = pe.id_lista
              JOIN v_impugnacion_efecto e ON e.id_impugnacion = i.id_impugnacion
              LEFT JOIN cargo_electoral c ON c.id_cargo = i.id_cargo
              LEFT JOIN lista_electoral lm ON lm.id_lista = i.id_lista_mesa
              LEFT JOIN lista_electoral lf ON lf.id_lista = i.id_lista_final
              LEFT JOIN lista_electoral lv ON lv.id_lista = e.id_lista_vigente
              LEFT JOIN personero pa      ON pa.id_personero = i.id_personero_apela
              LEFT JOIN docente da        ON da.id_docente = pa.id_docente
              LEFT JOIN usuario um        ON um.id_usuario = i.id_usuario_mesa
              LEFT JOIN usuario ua        ON ua.id_usuario = i.id_usuario_apelacion
              LEFT JOIN usuario uc        ON uc.id_usuario = i.id_usuario_ceunp
            """;

    private final ProcedimientoDao dao;
    private volatile boolean instalada;

    public ImpugnacionesConsulta(ProcedimientoDao dao) {
        this.dao = dao;
    }

    /** Falla con un mensaje claro si falta ejecutar la migración del CUS13 (o la del CUS12). */
    void verificarInstalacion() {
        if (instalada) {
            return;
        }
        if (dao.entero("""
                SELECT COUNT(*) FROM information_schema.columns
                 WHERE table_schema = DATABASE() AND table_name = 'impugnacion_electoral' AND column_name = 'opcion_mesa'
                """) == 0) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Faltan los cambios del CUS13: ejecute base-de-datos/12_impugnaciones_apelaciones.sql en la base de datos.");
        }
        instalada = true;
    }

    /** sp_registrar_impugnacion lo crea el CUS12 (11_escrutinio_conciliacion.sql). */
    boolean registroDisponible() {
        return dao.entero("""
                SELECT COUNT(*) FROM information_schema.routines
                 WHERE routine_schema = DATABASE() AND routine_name = 'sp_registrar_impugnacion'
                """) > 0;
    }

    // ─── Procesos y mesas ────────────────────────────────────────────────────

    public List<Map<String, Object>> procesos() {
        verificarInstalacion();
        return dao.consultar("""
                SELECT p.id_proceso AS id, p.nombre, p.estado,
                       (SELECT COUNT(*) FROM mesa_electoral m WHERE m.id_proceso = p.id_proceso) AS mesas,
                       COUNT(i.id_impugnacion) AS impugnaciones,
                       COALESCE(SUM(i.decision_mesa = 'PENDIENTE'), 0) AS por_resolver,
                       COALESCE(SUM(i.estado = 'APELADA'), 0) AS apeladas,
                       COALESCE(SUM(i.decision_ceunp <> 'PENDIENTE'), 0) AS falladas
                  FROM proceso_electoral p
                  LEFT JOIN impugnacion_electoral i ON i.id_proceso = p.id_proceso
                 WHERE p.estado <> 'ANULADO'
                 GROUP BY p.id_proceso, p.nombre, p.estado, p.fecha_inicio
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
                   AND EXISTS (SELECT 1 FROM miembro_mesa x WHERE x.id_mesa = m.id_mesa AND x.id_docente = ?)
                """ + ORDEN_MESAS, idDocente);
    }

    /**
     * Mesas que fiscaliza el personero: la suya si es personero de mesa; todas las del proceso si
     * es personero general o alterno de una lista acreditada.
     */
    public List<Map<String, Object>> mesasDePersonero(Integer idDocente) {
        verificarInstalacion();
        return dao.consultar(SELECT_MESA + """
                 WHERE p.estado <> 'ANULADO'
                   AND EXISTS (SELECT 1 FROM personero x
                                 JOIN lista_electoral l ON l.id_lista = x.id_lista
                                 JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                                WHERE x.id_docente = ? AND x.estado_acreditacion = 'ACREDITADO'
                                  AND c.id_proceso = m.id_proceso
                                  AND (x.id_mesa = m.id_mesa OR x.tipo <> 'MESA'))
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

    public boolean fiscaliza(Integer idMesa, Integer idDocente) {
        return idDocente != null && dao.entero("""
                SELECT COUNT(*) FROM personero x
                  JOIN lista_electoral l ON l.id_lista = x.id_lista
                  JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                  JOIN mesa_electoral m  ON m.id_proceso = c.id_proceso
                 WHERE m.id_mesa = ? AND x.id_docente = ? AND x.estado_acreditacion = 'ACREDITADO'
                   AND (x.id_mesa = m.id_mesa OR x.tipo <> 'MESA')
                """, idMesa, idDocente) > 0;
    }

    /** Acceso a una mesa según el rol: MIEMBRO_MESA solo la suya, PERSONERO las que fiscaliza. */
    void exigirAcceso(Integer idMesa, Usuario usuario) {
        if (usuario.getRol() == Rol.MIEMBRO_MESA && !esMiembro(idMesa, usuario.getIdDocente())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No es miembro de esta mesa.");
        }
        if (usuario.getRol() == Rol.PERSONERO && !fiscaliza(idMesa, usuario.getIdDocente())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No es personero acreditado para esta mesa.");
        }
        if (usuario.getRol() == Rol.DOCENTE) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Solo los personeros, la mesa y el CEUNP gestionan impugnaciones.");
        }
    }

    // ─── Miembros de mesa (RN23) ─────────────────────────────────────────────

    /** Presidente, secretario y vocal en funciones desde la instalación (CUS08). */
    List<Map<String, Object>> miembrosEnFunciones(Integer idMesa) {
        return dao.consultar("""
                SELECT CONCAT(mm.rol_instalacion, '') AS cargo, mm.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS nombre,
                       IF(mm.titular = 1, 'TITULAR', 'SUPLENTE') AS origen
                  FROM miembro_mesa mm JOIN docente d ON d.id_docente = mm.id_docente
                 WHERE mm.id_mesa = ? AND mm.rol_instalacion IS NOT NULL
                UNION ALL
                SELECT CONCAT(r.cargo, ''), r.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres), 'REEMPLAZANTE'
                  FROM reemplazo_mesa r JOIN docente d ON d.id_docente = r.id_docente
                 WHERE r.id_mesa = ?
                 ORDER BY FIELD(cargo, 'PRESIDENTE', 'SECRETARIO', 'VOCAL')
                """, idMesa, idMesa);
    }

    /**
     * La decisión de la mesa la registra su presidente en funciones (actor del diagrama). Si la
     * presidencia la ejerce un reemplazante sin cuenta, puede hacerlo cualquier miembro presente.
     */
    void exigirPresidente(Integer idMesa, Usuario usuario) {
        if (usuario.getRol() != Rol.MIEMBRO_MESA) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "RN23: la mesa resuelve en primera instancia; la decisión la registra su presidente.");
        }
        Map<String, Object> presidente = miembrosEnFunciones(idMesa).stream()
                .filter(f -> "PRESIDENTE".equals(f.get("cargo"))).findFirst().orElse(null);
        if (presidente == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La mesa no registra presidente en funciones (CUS08).");
        }
        if ("REEMPLAZANTE".equals(presidente.get("origen"))) {
            if (dao.entero("SELECT COUNT(*) FROM miembro_mesa WHERE id_mesa = ? AND id_docente = ? AND asistio = 1",
                    idMesa, usuario.getIdDocente()) == 0) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Solo un miembro presente de la mesa registra la decisión.");
            }
            return;
        }
        if (numero(presidente.get("idDocente")) != numero(usuario.getIdDocente())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Registra la decisión de la mesa su presidente en funciones: " + presidente.get("nombre") + ".");
        }
    }

    // ─── Personeros ──────────────────────────────────────────────────────────

    /**
     * RN24: personeros presentes en la mesa (registraron su llegada en la instalación, CUS08), que son
     * quienes pueden impugnar un voto en el escrutinio (mismo criterio que sp_registrar_impugnacion).
     */
    List<Map<String, Object>> personerosDeMesa(Integer idMesa) {
        return dao.consultar("""
                SELECT pe.id_personero, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS nombre, pe.tipo,
                       pe.id_lista, l.nombre AS lista, l.id_cargo, ap.hora_acreditacion AS hora_llegada
                  FROM asistencia_personero_mesa ap
                  JOIN personero pe      ON pe.id_personero = ap.id_personero
                  JOIN docente d         ON d.id_docente = pe.id_docente
                  JOIN lista_electoral l ON l.id_lista = pe.id_lista
                 WHERE ap.id_mesa = ? AND pe.estado_acreditacion = 'ACREDITADO'
                 ORDER BY FIELD(pe.tipo, 'MESA', 'GENERAL', 'ALTERNO'), l.nombre, d.apellidos
                """, idMesa);
    }

    /** Personeros acreditados de una lista (pueden apelar por ella, RF81). */
    List<Map<String, Object>> personerosDeLista(Integer idLista) {
        return dao.consultar("""
                SELECT pe.id_personero, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS nombre, pe.tipo, pe.id_mesa
                  FROM personero pe JOIN docente d ON d.id_docente = pe.id_docente
                 WHERE pe.id_lista = ? AND pe.estado_acreditacion = 'ACREDITADO'
                 ORDER BY FIELD(pe.tipo, 'MESA', 'GENERAL', 'ALTERNO'), d.apellidos
                """, idLista);
    }

    /** Registros de personero de la cuenta (un docente puede ser personero de más de una lista). */
    List<Map<String, Object>> personerosDelDocente(Integer idDocente) {
        if (idDocente == null) {
            return List.of();
        }
        return dao.consultar("""
                SELECT pe.id_personero, pe.tipo, pe.id_mesa, pe.id_lista, l.nombre AS lista
                  FROM personero pe JOIN lista_electoral l ON l.id_lista = pe.id_lista
                 WHERE pe.id_docente = ? AND pe.estado_acreditacion = 'ACREDITADO'
                """, idDocente);
    }

    // ─── Impugnaciones ───────────────────────────────────────────────────────

    public Map<String, Object> impugnacion(Long id) {
        verificarInstalacion();
        List<Map<String, Object>> filas = dao.consultar(SELECT_IMPUGNACION + " WHERE i.id_impugnacion = ?", id);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Impugnación no encontrada.");
        }
        return filas.get(0);
    }

    List<Map<String, Object>> impugnacionesDeMesa(Integer idMesa) {
        return dao.consultar(SELECT_IMPUGNACION + " WHERE i.id_mesa = ? ORDER BY i.id_impugnacion", idMesa);
    }

    /** Bandeja del CEUNP: impugnaciones del proceso, primero las apeladas por resolver. */
    public List<Map<String, Object>> bandeja(Integer idProceso) {
        verificarInstalacion();
        return dao.consultar(SELECT_IMPUGNACION + """
                 WHERE i.id_proceso = ?
                 ORDER BY (i.estado = 'APELADA') DESC, i.fecha_apelacion, LENGTH(m.numero_mesa), m.numero_mesa, i.id_impugnacion
                """, idProceso);
    }

    // ─── Detalle de la mesa ──────────────────────────────────────────────────

    public Map<String, Object> detalle(Integer idMesa, Usuario usuario) {
        Map<String, Object> mesa = mesa(idMesa);
        boolean cerrada = "CERRADA".equals(String.valueOf(mesa.get("estado")));
        boolean procesoAbierto = List.of("VOTACION", "CERRADO").contains(String.valueOf(mesa.get("estadoProceso")));
        List<Map<String, Object>> miembros = miembrosEnFunciones(idMesa);
        List<Map<String, Object>> personeros = personerosDeMesa(idMesa);
        List<Map<String, Object>> mios = usuario.getRol() == Rol.PERSONERO
                ? personerosDelDocente(usuario.getIdDocente()) : List.of();
        boolean presidente = esPresidente(idMesa, usuario, miembros);
        int plazo = parametro("IMPUGNACION_PLAZO_APELACION_HORAS", 24);
        LocalDateTime ahora = (LocalDateTime) dao.consultar("SELECT NOW() AS ahora").get(0).get("ahora");

        List<Map<String, Object>> impugnaciones = new ArrayList<>();
        for (Map<String, Object> i : impugnacionesDeMesa(idMesa)) {
            i.put("puedeDecidir", procesoAbierto && cerrada && presidente && "PENDIENTE".equals(i.get("decisionMesa")));
            boolean apelable = procesoAbierto && "RECHAZADA".equals(i.get("decisionMesa")) && "RESUELTA".equals(i.get("estado"))
                    && "PENDIENTE".equals(i.get("decisionCeunp")) && dentroDelPlazo(i.get("fechaDecisionMesa"), plazo, ahora);
            boolean mismaLista = mios.stream().anyMatch(p -> numero(p.get("idLista")) == numero(i.get("idListaPersonero")));
            i.put("puedeApelar", apelable && (presidente || mismaLista));
            i.put("venceApelacion", plazo > 0 && i.get("fechaDecisionMesa") instanceof LocalDateTime f ? f.plusHours(plazo) : null);
            impugnaciones.add(i);
        }

        // Listas y cargos de la mesa (para asignar la cédula impugnada)
        List<Map<String, Object>> cargos = dao.consultar("""
                SELECT DISTINCT c.id_cargo, c.nombre
                  FROM padron_electoral pe JOIN cargo_electoral c ON c.id_cargo = pe.id_cargo
                 WHERE pe.id_mesa = ?
                 ORDER BY c.id_cargo
                """, idMesa);
        if (cargos.isEmpty()) {
            cargos = dao.consultar("SELECT id_cargo, nombre FROM cargo_electoral WHERE id_proceso = ? ORDER BY id_cargo",
                    mesa.get("idProceso"));
        }
        agregarListas(cargos);

        Map<String, Object> escrutinio = escrutinio(idMesa);
        boolean escrutinioEnCurso = escrutinio != null
                && List.of("CEDULAS_CONTADAS", "CONTEO_REGISTRADO").contains(String.valueOf(escrutinio.get("estado")));
        boolean personeroPresente = mios.stream().anyMatch(p -> personeros.stream()
                .anyMatch(x -> numero(x.get("idPersonero")) == numero(p.get("idPersonero"))));
        boolean miembro = usuario.getRol() == Rol.MIEMBRO_MESA && esMiembro(idMesa, usuario.getIdDocente());
        boolean puedeRegistrar = procesoAbierto && cerrada && escrutinioEnCurso && registroDisponible()
                && (miembro || personeroPresente);
        String motivoNoRegistra = !cerrada ? "Se impugna durante el escrutinio: primero se cierra el sufragio (CUS11)."
                : escrutinio == null ? "La mesa aún no inicia el escrutinio: el presidente debe contar las cédulas (CUS12)."
                : !escrutinioEnCurso ? "El acta de escrutinio ya fue emitida: no se registran nuevas impugnaciones."
                : usuario.getRol() == Rol.PERSONERO && !personeroPresente ? "RN24: impugna un personero presente en la mesa."
                : null;

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mesa", mesa);
        respuesta.put("escrutinio", escrutinio);
        respuesta.put("miembros", miembros);
        respuesta.put("personeros", personeros);
        respuesta.put("misPersoneros", mios);
        respuesta.put("cargos", cargos);
        respuesta.put("impugnaciones", impugnaciones);
        respuesta.put("resumen", resumen(impugnaciones));
        respuesta.put("plazoApelacionHoras", plazo);
        respuesta.put("soyPresidente", presidente);
        respuesta.put("puedeRegistrar", puedeRegistrar);
        respuesta.put("motivoNoRegistra", motivoNoRegistra);
        respuesta.put("registroDisponible", registroDisponible());
        respuesta.put("ahora", ahora);
        return respuesta;
    }

    /** Cargos del proceso con sus listas admitidas (el CEUNP fija la opción final de la cédula). */
    List<Map<String, Object>> cargosConListas(Integer idProceso) {
        List<Map<String, Object>> cargos = dao.consultar(
                "SELECT id_cargo, nombre FROM cargo_electoral WHERE id_proceso = ? ORDER BY id_cargo", idProceso);
        agregarListas(cargos);
        return cargos;
    }

    private void agregarListas(List<Map<String, Object>> cargos) {
        for (Map<String, Object> c : cargos) {
            c.put("listas", dao.consultar("""
                    SELECT id_lista, nombre, simbolo, orden_cedula FROM lista_electoral
                     WHERE id_cargo = ? AND estado = 'ADMITIDA' ORDER BY COALESCE(orden_cedula, 999), nombre
                    """, c.get("idCargo")));
        }
    }

    /** Estado del escrutinio de la mesa (CUS12), si su migración está instalada. */
    Map<String, Object> escrutinio(Integer idMesa) {
        if (dao.entero("""
                SELECT COUNT(*) FROM information_schema.tables
                 WHERE table_schema = DATABASE() AND table_name = 'escrutinio_mesa'
                """) == 0) {
            return null;
        }
        List<Map<String, Object>> filas = dao.consultar("SELECT estado FROM escrutinio_mesa WHERE id_mesa = ?", idMesa);
        return filas.isEmpty() ? null : filas.get(0);
    }

    static Map<String, Object> resumen(List<Map<String, Object>> impugnaciones) {
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("total", impugnaciones.size());
        r.put("porResolver", impugnaciones.stream().filter(i -> "PENDIENTE".equals(i.get("decisionMesa"))).count());
        r.put("aceptadas", impugnaciones.stream().filter(i -> "ACEPTADA".equals(i.get("decisionMesa"))).count());
        r.put("rechazadas", impugnaciones.stream().filter(i -> "RECHAZADA".equals(i.get("decisionMesa"))).count());
        r.put("apeladas", impugnaciones.stream().filter(i -> "APELADA".equals(i.get("estado"))).count());
        r.put("falladas", impugnaciones.stream().filter(i -> !"PENDIENTE".equals(i.get("decisionCeunp"))).count());
        r.put("firmes", impugnaciones.stream().filter(i -> "FIRME".equals(i.get("situacion"))).count());
        return r;
    }

    boolean esPresidente(Integer idMesa, Usuario usuario, List<Map<String, Object>> miembros) {
        if (usuario.getRol() != Rol.MIEMBRO_MESA) {
            return false;
        }
        Map<String, Object> presidente = miembros.stream()
                .filter(f -> "PRESIDENTE".equals(f.get("cargo"))).findFirst().orElse(null);
        if (presidente == null) {
            return false;
        }
        if ("REEMPLAZANTE".equals(presidente.get("origen"))) {
            return dao.entero("SELECT COUNT(*) FROM miembro_mesa WHERE id_mesa = ? AND id_docente = ? AND asistio = 1",
                    idMesa, usuario.getIdDocente()) > 0;
        }
        return numero(presidente.get("idDocente")) == numero(usuario.getIdDocente());
    }

    int parametro(String clave, int porDefecto) {
        List<Map<String, Object>> filas = dao.consultar("SELECT valor FROM parametro_global WHERE clave = ?", clave);
        if (filas.isEmpty()) {
            return porDefecto;
        }
        try {
            return (int) Math.round(Double.parseDouble(String.valueOf(filas.get(0).get("valor")).trim()));
        } catch (NumberFormatException e) {
            return porDefecto;
        }
    }

    private static boolean dentroDelPlazo(Object fechaDecision, int plazo, LocalDateTime ahora) {
        if (plazo <= 0) {
            return true;
        }
        return fechaDecision instanceof LocalDateTime f && !ahora.isAfter(f.plusHours(plazo));
    }

    static int numero(Object valor) {
        if (valor instanceof Number n) {
            return n.intValue();
        }
        if (valor instanceof Boolean b) {
            return b ? 1 : 0;
        }
        return -1;
    }
}
