package pe.unp.elecciones.electoral.nulidades;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Rol;
import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS15 · Lecturas compartidas por DeclararNulidadParcial, DeclararNulidadTotal y
 * ConfigurarSegundaVuelta: recursos de nulidad (v_nulidades), mesas con su situación para el
 * cómputo (v_computo_mesas del CUS14), comunicaciones (RF102), cargos que van a segunda vuelta
 * con sus finalistas y empates, y el proceso de segunda vuelta (v_segunda_vuelta_procesos).
 */
@Service
public class NulidadesConsulta {

    static final List<String> CAUSALES_PARCIAL = List.of(
            "INSTALACION_IRREGULAR", "FRAUDE_MESA", "ADMISION_INDEBIDA", "ACTA_NO_AUTENTICA", "OTRA_CAUSAL");
    static final List<String> CAUSALES_TOTAL = List.of(
            "FRAUDE", "COHECHO", "SOBORNO", "INTIMIDACION", "VIOLENCIA", "PARTICIPACION_INSUFICIENTE");
    static final List<String> DESTINATARIOS = List.of(
            "SUNEDU", "ASAMBLEA_UNIVERSITARIA", "CONSEJO_UNIVERSITARIO", "PORTAL", "EL_PERUANO");

    private final ProcedimientoDao dao;
    private final ObjectMapper json;
    private volatile boolean instalada;

    public NulidadesConsulta(ProcedimientoDao dao, ObjectMapper json) {
        this.dao = dao;
        this.json = json;
    }

    /** Falla con un mensaje claro si falta ejecutar la migración del CUS15. */
    void verificarInstalacion() {
        if (instalada) {
            return;
        }
        if (dao.entero("""
                SELECT COUNT(*) FROM information_schema.routines
                 WHERE routine_schema = DATABASE() AND routine_name = 'sp_resolver_nulidad'
                """) == 0) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Faltan los cambios del CUS15: ejecute base-de-datos/14_nulidades_segunda_vuelta.sql en la base de datos.");
        }
        instalada = true;
    }

    // ─── Procesos ────────────────────────────────────────────────────────────

    /** Procesos con mesas desde la votación, y las segundas vueltas convocadas. */
    public List<Map<String, Object>> procesos() {
        verificarInstalacion();
        return dao.consultar("""
                SELECT p.id_proceso AS id, p.nombre, p.estado, p.tipo, p.id_proceso_padre, cp.estado AS estado_computo,
                       cp.resultado,
                       (SELECT COUNT(*) FROM nulidad_electoral n WHERE n.id_proceso = p.id_proceso AND n.estado = 'PRESENTADA') AS pendientes,
                       (SELECT COUNT(*) FROM cargo_electoral c WHERE c.id_proceso = p.id_proceso
                           AND c.estado_resultado IN ('SEGUNDA_VUELTA', 'EMPATE')) AS cargos_segunda_vuelta
                  FROM proceso_electoral p
                  LEFT JOIN computo_proceso cp ON cp.id_proceso = p.id_proceso
                 WHERE (p.estado IN ('VOTACION', 'CERRADO', 'FINALIZADO', 'ANULADO')
                        AND EXISTS (SELECT 1 FROM mesa_electoral m WHERE m.id_proceso = p.id_proceso))
                    OR p.tipo = 'SEGUNDA_VUELTA'
                 ORDER BY FIELD(p.estado, 'CERRADO', 'FINALIZADO', 'VOTACION', 'INSCRIPCION', 'CREADO', 'ANULADO'),
                          p.fecha_inicio DESC
                """);
    }

    public Map<String, Object> proceso(Integer idProceso) {
        verificarInstalacion();
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT p.id_proceso AS id, p.nombre, p.estado, p.tipo, p.id_proceso_padre, pp.nombre AS proceso_padre,
                       p.quorum_minimo, p.fecha_inicio, p.fecha_fin, p.fecha_cierre_real, p.motivo_anulacion,
                       cp.estado AS estado_computo, cp.resultado, cp.fecha_computo, cp.participacion_pct, cp.votaron,
                       cp.electores_habiles, cp.numero_resolucion AS resolucion_proclamacion, cp.fecha_proclamacion,
                       cp.fecha_publicacion
                  FROM proceso_electoral p
                  LEFT JOIN proceso_electoral pp ON pp.id_proceso = p.id_proceso_padre
                  LEFT JOIN computo_proceso cp   ON cp.id_proceso = p.id_proceso
                 WHERE p.id_proceso = ?
                """, idProceso);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Proceso electoral no encontrado.");
        }
        return filas.get(0);
    }

    // ─── Detalle del proceso (todas las pestañas) ───────────────────────────

    public Map<String, Object> detalle(Integer idProceso, Usuario usuario) {
        Map<String, Object> proceso = proceso(idProceso);
        String estado = texto(proceso.get("estado"));
        String etapa = texto(proceso.get("estadoComputo"));
        String tipo = texto(proceso.get("tipo"));
        boolean ceunp = usuario.getRol() == Rol.CEUNP;
        boolean antesDelComputo = "CERRADO".equals(estado) && (etapa.isEmpty() || "SESION_INSTALADA".equals(etapa));
        boolean computadoSinProclamar = "FINALIZADO".equals(estado) && "COMPUTADO".equals(etapa);

        List<Map<String, Object>> nulidades = nulidades(idProceso);
        long pendientes = nulidades.stream().filter(n -> "PRESENTADA".equals(texto(n.get("estado")))).count();
        boolean totalVigente = nulidades.stream().anyMatch(n -> "TOTAL".equals(texto(n.get("alcance")))
                && List.of("PRESENTADA", "FUNDADA").contains(texto(n.get("estado"))));
        boolean totalPendiente = nulidades.stream().anyMatch(n -> "TOTAL".equals(texto(n.get("alcance")))
                && "PRESENTADA".equals(texto(n.get("estado"))));

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("proceso", proceso);
        List<Map<String, Object>> general = dao.consultar("""
                SELECT electores_habiles, votaron, participacion_pct, quorum_minimo, alcanza_quorum
                  FROM v_quorum_proceso WHERE id_proceso = ?
                """, idProceso);
        respuesta.put("participacion", general.isEmpty() ? null : general.get(0));
        List<Map<String, Object>> mesas = mesas(idProceso);
        respuesta.put("mesas", mesas);
        respuesta.put("resumenMesas", resumenMesas(mesas));
        respuesta.put("nulidades", nulidades);
        respuesta.put("comunicaciones", dao.consultar("""
                SELECT c.id_nulidad, CONCAT(c.destinatario, '') AS destinatario, c.documento, c.fecha_envio, c.observacion,
                       c.fecha_registro, u.username AS registrado_por
                  FROM nulidad_comunicacion c
                  JOIN nulidad_electoral n ON n.id_nulidad = c.id_nulidad
                  LEFT JOIN usuario u ON u.id_usuario = c.id_usuario
                 WHERE n.id_proceso = ?
                 ORDER BY c.id_nulidad, FIELD(c.destinatario, 'SUNEDU', 'ASAMBLEA_UNIVERSITARIA', 'CONSEJO_UNIVERSITARIO', 'PORTAL', 'EL_PERUANO')
                """, idProceso));
        respuesta.put("personeros", dao.consultar("""
                SELECT pe.id_personero, CONCAT(d.apellidos, ', ', d.nombres) AS nombre, d.dni, CONCAT(pe.tipo, '') AS tipo,
                       l.nombre AS lista, pe.id_mesa, m.numero_mesa
                  FROM personero pe
                  JOIN docente d         ON d.id_docente = pe.id_docente
                  JOIN lista_electoral l ON l.id_lista = pe.id_lista
                  JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                  LEFT JOIN mesa_electoral m ON m.id_mesa = pe.id_mesa
                 WHERE c.id_proceso = ? AND pe.estado_acreditacion = 'ACREDITADO'
                 ORDER BY l.nombre, FIELD(pe.tipo, 'GENERAL', 'ALTERNO', 'MESA'), d.apellidos
                """, idProceso));

        // Segunda vuelta: cargos de esta elección que van a segunda vuelta, la segunda vuelta
        // convocada y, si el proceso es una segunda vuelta, su primera vuelta y sus empates.
        List<Map<String, Object>> dirimencias = dirimencias(idProceso);
        List<Map<String, Object>> cargos = cargos(idProceso, dirimencias);
        respuesta.put("cargos", cargos);
        respuesta.put("dirimencias", dirimencias);
        List<Map<String, Object>> hijos = dao.consultar("""
                SELECT id_proceso AS id, nombre, estado, fecha_inicio, fecha_fin, fecha_creacion, motivo_anulacion,
                       cargos, listas, padron, mesas, estado_computo
                  FROM v_segunda_vuelta_procesos WHERE id_proceso_padre = ? ORDER BY id_proceso DESC
                """, idProceso);
        for (Map<String, Object> h : hijos) {
            h.put("listasFinalistas", dao.consultar("""
                    SELECT c.nombre AS cargo, l.nombre AS lista, l.orden_cedula,
                           (SELECT COUNT(*) FROM candidato ca WHERE ca.id_lista = l.id_lista) AS candidatos
                      FROM lista_electoral l JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                     WHERE c.id_proceso = ? ORDER BY c.id_cargo, COALESCE(l.orden_cedula, 99), l.nombre
                    """, numero(h.get("id"))));
        }
        respuesta.put("segundasVueltas", hijos);
        Map<String, Object> vigente = hijos.stream().filter(h -> !"ANULADO".equals(texto(h.get("estado")))).findFirst().orElse(null);
        respuesta.put("segundaVuelta", vigente);

        int quorumPleno = parametro("CEUNP_QUORUM_PLENO", 5);
        int plazo = parametro("SEGUNDA_VUELTA_PLAZO_DIAS", 15);
        Map<String, Object> parametros = new LinkedHashMap<>();
        parametros.put("quorumPleno", quorumPleno);
        parametros.put("plazoSegundaVuelta", plazo);
        parametros.put("limiteSegundaVuelta", proceso.get("fechaComputo") instanceof LocalDateTime f && plazo > 0 ? f.plusDays(plazo) : null);
        respuesta.put("parametros", parametros);

        long porSegunda = cargos.stream().filter(c -> "SEGUNDA_VUELTA".equals(texto(c.get("estadoResultado")))).count();
        boolean empateSinDirimir = cargos.stream().anyMatch(c -> Boolean.TRUE.equals(c.get("empateSinDirimir")));
        boolean sinProclamar = List.of("COMPUTADO").contains(etapa);

        Map<String, Object> acciones = new LinkedHashMap<>();
        acciones.put("registrarParcial", ceunp && antesDelComputo);
        acciones.put("motivoNoParcial", antesDelComputo ? null
                : "VOTACION".equals(estado) ? "Concluya primero la votación del proceso (CUS14, Verificación previa)."
                : "ANULADO".equals(estado) ? "La elección está anulada."
                : "La nulidad parcial se plantea antes del cómputo (RN26); el cómputo ya se realizó.");
        acciones.put("registrarTotal", ceunp && !totalVigente && ("CERRADO".equals(estado) || computadoSinProclamar));
        acciones.put("motivoNoTotal", totalVigente ? "El proceso ya tiene un recurso de nulidad total pendiente o declarado."
                : "CERRADO".equals(estado) || computadoSinProclamar ? null
                : "VOTACION".equals(estado) ? "Concluya primero la votación del proceso."
                : "ANULADO".equals(estado) ? "La elección ya está anulada."
                : List.of("PROCLAMADO", "PUBLICADO").contains(etapa) ? "Los resultados ya fueron proclamados (RF94)."
                : "El proceso aún no llega a la votación.");
        acciones.put("formalizarParticipacion", ceunp && !totalVigente && "NULIDAD_TOTAL".equals(texto(proceso.get("resultado"))));
        acciones.put("resolver", ceunp);
        acciones.put("comunicar", ceunp);
        acciones.put("convocarSegundaVuelta", ceunp && "PRIMERA_VUELTA".equals(tipo) && "FINALIZADO".equals(estado)
                && porSegunda > 0 && vigente == null && !empateSinDirimir && !totalPendiente);
        acciones.put("motivoNoSegunda", porSegunda == 0 || !"FINALIZADO".equals(estado) || !"PRIMERA_VUELTA".equals(tipo) ? null
                : vigente != null ? null
                : empateSinDirimir ? "Hay listas empatadas por un cupo de la segunda vuelta: dirímalo por sorteo."
                : totalPendiente ? "Hay un recurso de nulidad total pendiente (RF94)." : null);
        acciones.put("dirimir", ceunp && (("SEGUNDA_VUELTA".equals(tipo) && sinProclamar && "FINALIZADO".equals(estado))
                || ("PRIMERA_VUELTA".equals(tipo) && "FINALIZADO".equals(estado) && vigente == null)));
        respuesta.put("acciones", acciones);

        List<String> avisos = new ArrayList<>();
        if (pendientes > 0) {
            avisos.add(pendientes + " recurso(s) de nulidad pendiente(s): "
                    + (antesDelComputo ? "impiden el cómputo (RF94)." : totalPendiente ? "la nulidad total pendiente impide proclamar (RF94)." : "resuélvalos."));
        }
        nulidades.stream()
                .filter(n -> "FUNDADA".equals(texto(n.get("estado"))) && "TOTAL".equals(texto(n.get("alcance")))
                        && numero(n.get("comunicacionesOficio")) < 3)
                .forEach(n -> avisos.add("Resolución " + n.get("numeroResolucion") + ": falta comunicarla a "
                        + (3 - numero(n.get("comunicacionesOficio"))) + " destinatario(s) (RF102)."));
        if (empateSinDirimir) {
            avisos.add("Hay un empate por el pase a la segunda vuelta: el Pleno debe dirimirlo por sorteo antes de convocarla.");
        }
        cargos.stream().filter(c -> "EMPATE".equals(texto(c.get("estadoResultado"))))
                .forEach(c -> avisos.add(c.get("cargo") + ": empate en la segunda vuelta; dirímalo antes de proclamar."));
        respuesta.put("avisos", avisos);
        respuesta.put("soloLectura", !ceunp);
        return respuesta;
    }

    /** Recursos de nulidad del proceso: primero los pendientes. */
    List<Map<String, Object>> nulidades(Integer idProceso) {
        return dao.consultar("""
                SELECT id_nulidad, alcance, id_mesa, numero_mesa, ubicacion, estado_mesa, causal, origen, id_personero,
                       personero, lista_personero, tipo_personero, sustento, pruebas, etapa, fecha_presentacion,
                       registrado_por, estado, numero_resolucion, fundamento_resolucion, miembros_pleno, votos_favor,
                       votos_contra, voto_dirimente, fecha_resolucion, resuelto_por, hash_integridad, resolucion_integra,
                       comunicaciones, comunicaciones_oficio, fecha_portal
                  FROM v_nulidades WHERE id_proceso = ?
                 ORDER BY (estado = 'PRESENTADA') DESC, id_nulidad DESC
                """, idProceso);
    }

    /** Mesas del proceso con su situación para el cómputo y su evaluación RF60 si no se instaló. */
    List<Map<String, Object>> mesas(Integer idProceso) {
        return dao.consultar("""
                SELECT v.id_mesa, v.numero_mesa, v.ubicacion, v.estado, v.total_electores, v.total_votantes,
                       v.estado_escrutinio, v.situacion, v.calificacion, v.resolucion_calificacion,
                       i.evaluacion_nulidad, i.fundamento_evaluacion,
                       (SELECT COUNT(*) FROM nulidad_electoral n WHERE n.id_mesa = v.id_mesa AND n.estado = 'PRESENTADA') AS recursos_pendientes,
                       (SELECT MAX(n.numero_resolucion) FROM nulidad_electoral n WHERE n.id_mesa = v.id_mesa AND n.estado = 'FUNDADA') AS resolucion_nulidad
                  FROM v_computo_mesas v
                  LEFT JOIN instalacion_mesa i ON i.id_mesa = v.id_mesa
                 WHERE v.id_proceso = ?
                 ORDER BY LENGTH(v.numero_mesa), v.numero_mesa
                """, idProceso);
    }

    static Map<String, Object> resumenMesas(List<Map<String, Object>> mesas) {
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("total", mesas.size());
        r.put("cerradas", mesas.stream().filter(m -> "CERRADA".equals(texto(m.get("estado")))).count());
        r.put("anuladas", mesas.stream().filter(m -> "ANULADA".equals(texto(m.get("estado")))).count());
        r.put("noInstaladas", mesas.stream().filter(m -> "NO_INSTALADA".equals(texto(m.get("estado")))).count());
        r.put("conRecurso", mesas.stream().filter(m -> numero(m.get("recursosPendientes")) > 0).count());
        return r;
    }

    /**
     * Cargos del proceso con su resultado y su ranking. Para un cargo en SEGUNDA_VUELTA marca las
     * dos listas finalistas con la misma regla que sp_crear_segunda_vuelta (RN33): pasan las de
     * más votos que la segunda del ranking y las empatadas con ella compiten por los cupos que
     * quedan; si son más que los cupos, decide el sorteo del Pleno (sp_dirimir_empate).
     */
    List<Map<String, Object>> cargos(Integer idProceso, List<Map<String, Object>> dirimencias) {
        List<Map<String, Object>> cargos = dao.consultar("""
                SELECT c.id_cargo, c.nombre AS cargo, CONCAT(c.estado_resultado, '') AS estado_resultado,
                       c.porcentaje_minimo_victoria, c.id_lista_ganadora, l.nombre AS lista_ganadora
                  FROM cargo_electoral c
                  LEFT JOIN lista_electoral l ON l.id_lista = c.id_lista_ganadora
                 WHERE c.id_proceso = ? ORDER BY c.id_cargo
                """, idProceso);
        for (Map<String, Object> c : cargos) {
            int idCargo = numero(c.get("idCargo"));
            List<Map<String, Object>> listas = dao.consultar("""
                    SELECT r.id_lista, l.nombre AS lista, l.orden_cedula, r.total_votos AS votos, r.porcentaje_validos, r.posicion
                      FROM resultado_electoral r JOIN lista_electoral l ON l.id_lista = r.id_lista
                     WHERE r.id_cargo = ? AND r.tipo_voto = 'VALIDO'
                     ORDER BY r.total_votos DESC, r.id_lista
                    """, idCargo);
            Map<String, Object> dirimencia = dirimencias.stream().filter(d -> numero(d.get("idCargo")) == idCargo).findFirst().orElse(null);
            String estado = texto(c.get("estadoResultado"));
            boolean empateSinDirimir = false;
            if (!listas.isEmpty()) {
                int max = numero(listas.get(0).get("votos"));
                long nMax = listas.stream().filter(l -> numero(l.get("votos")) == max).count();
                int v2 = nMax >= 2 ? max : listas.stream().mapToInt(l -> numero(l.get("votos"))).filter(v -> v < max).max().orElse(max);
                long arriba = listas.stream().filter(l -> numero(l.get("votos")) > v2).count();
                long empatadas = listas.stream().filter(l -> numero(l.get("votos")) == v2).count();
                long cupos = "SEGUNDA_VUELTA".equals(estado) ? 2 - arriba : 1;
                List<Integer> elegidas = dirimencia == null ? List.of() : enteros(dirimencia.get("listasElegidas"));
                if ("SEGUNDA_VUELTA".equals(estado)) {
                    empateSinDirimir = empatadas > cupos && dirimencia == null;
                    for (Map<String, Object> l : listas) {
                        int votos = numero(l.get("votos"));
                        boolean empatada = votos == v2 && empatadas > cupos;
                        l.put("empatada", empatada);
                        l.put("finalista", votos > v2 || (votos == v2 && (empatadas <= cupos || elegidas.contains(numero(l.get("idLista"))))));
                    }
                    c.put("cupos", cupos);
                } else if ("EMPATE".equals(estado) || (dirimencia != null && "EMPATE_SEGUNDA_VUELTA".equals(texto(dirimencia.get("motivo"))))) {
                    int top = max;
                    listas.forEach(l -> l.put("empatada", numero(l.get("votos")) == top));
                    empateSinDirimir = "EMPATE".equals(estado) && dirimencia == null;
                }
            }
            c.put("listas", listas);
            c.put("dirimencia", dirimencia);
            c.put("empateSinDirimir", empateSinDirimir);
        }
        return cargos;
    }

    List<Map<String, Object>> dirimencias(Integer idProceso) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT d.id_cargo, c.nombre AS cargo, CONCAT(d.motivo, '') AS motivo, d.semilla, d.cupos, d.listas_empatadas,
                       d.listas_elegidas, d.numero_resolucion, d.miembros_pleno, d.fundamento, d.fecha, d.hash_integridad,
                       u.username AS registrado_por
                  FROM dirimencia_empate d
                  JOIN cargo_electoral c ON c.id_cargo = d.id_cargo
                  LEFT JOIN usuario u ON u.id_usuario = d.id_usuario
                 WHERE d.id_proceso = ? ORDER BY d.id_cargo
                """, idProceso);
        for (Map<String, Object> d : filas) {
            d.put("listasEmpatadas", leerJson(d.get("listasEmpatadas")));
            d.put("listasElegidas", leerJson(d.get("listasElegidas")));
        }
        return filas;
    }

    // ─── Mesa y recurso ──────────────────────────────────────────────────────

    /** 4 mostrarMesaExcluida(): la mesa, sus votos (los que saldrían del cómputo) y sus recursos. */
    public Map<String, Object> detalleMesa(Integer idMesa) {
        verificarInstalacion();
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT v.id_proceso, v.id_mesa, v.numero_mesa, v.ubicacion, v.estado, v.total_electores, v.total_votantes,
                       v.estado_escrutinio, v.situacion, v.calificacion, v.resolucion_calificacion, v.observada,
                       v.conteo_cuadra, v.total_cuadra, v.fecha_entrega
                  FROM v_computo_mesas v WHERE v.id_mesa = ?
                """, idMesa);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Mesa no encontrada.");
        }
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mesa", filas.get(0));
        respuesta.put("conteo", dao.consultar("""
                SELECT x.id_cargo, c.nombre AS cargo, x.opcion, x.id_lista,
                       COALESCE(l.nombre, CASE x.opcion WHEN 'BLANCO' THEN 'Votos en blanco' WHEN 'NULO' THEN 'Votos nulos'
                                                        ELSE 'Impugnados sin resolver' END) AS lista,
                       x.votos
                  FROM v_computo_conteo_mesa x
                  JOIN cargo_electoral c ON c.id_cargo = x.id_cargo
                  LEFT JOIN lista_electoral l ON l.id_lista = x.id_lista
                 WHERE x.id_mesa = ?
                 ORDER BY x.id_cargo, FIELD(x.opcion, 'LISTA', 'BLANCO', 'NULO', 'IMPUGNADO'), COALESCE(l.orden_cedula, 999)
                """, idMesa));
        respuesta.put("recursos", dao.consultar("""
                SELECT id_nulidad, causal, origen, personero, estado, numero_resolucion, fecha_presentacion, fecha_resolucion
                  FROM v_nulidades WHERE id_mesa = ? ORDER BY id_nulidad DESC
                """, idMesa));
        return respuesta;
    }

    /** 9 mostrarResolucionNulidad(): el recurso, su resolución (contenido con huella) y sus comunicaciones. */
    public Map<String, Object> nulidad(Integer idNulidad) {
        verificarInstalacion();
        List<Map<String, Object>> filas = dao.consultar("SELECT * FROM v_nulidades WHERE id_nulidad = ?", idNulidad);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Recurso de nulidad no encontrado.");
        }
        Map<String, Object> n = filas.get(0);
        List<Map<String, Object>> contenido = dao.consultar("SELECT contenido_json FROM nulidad_electoral WHERE id_nulidad = ?", idNulidad);
        n.put("documento", contenido.isEmpty() ? null : leerJson(contenido.get(0).get("contenidoJson")));
        n.put("comunicaciones", dao.consultar("""
                SELECT CONCAT(destinatario, '') AS destinatario, documento, fecha_envio, observacion, fecha_registro
                  FROM nulidad_comunicacion WHERE id_nulidad = ?
                 ORDER BY FIELD(destinatario, 'SUNEDU', 'ASAMBLEA_UNIVERSITARIA', 'CONSEJO_UNIVERSITARIO', 'PORTAL', 'EL_PERUANO')
                """, idNulidad));
        return n;
    }

    /** Datos mínimos del recurso para las acciones. */
    Map<String, Object> recurso(Integer idNulidad) {
        verificarInstalacion();
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT id_nulidad, id_proceso, alcance, id_mesa, numero_mesa, causal, estado FROM v_nulidades WHERE id_nulidad = ?
                """, idNulidad);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Recurso de nulidad no encontrado.");
        }
        return filas.get(0);
    }

    Map<String, Object> cargo(Integer idCargo) {
        verificarInstalacion();
        List<Map<String, Object>> filas = dao.consultar(
                "SELECT id_cargo, id_proceso, nombre AS cargo, CONCAT(estado_resultado, '') AS estado_resultado FROM cargo_electoral WHERE id_cargo = ?",
                idCargo);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Cargo no encontrado.");
        }
        return filas.get(0);
    }

    // ─── Resolución del Pleno (común a la nulidad parcial y la total) ───────

    /** sp_resolver_nulidad: devuelve la fila con la decisión, el efecto y el token del QR. */
    Map<String, Object> resolver(Integer idNulidad, NulidadesDto.Resolucion datos, Usuario usuario) {
        ProcedimientoDao.Resultado r = dao.llamar("sp_resolver_nulidad", ProcedimientoDao.SIN_SALIDA, idNulidad, usuario.getId(),
                datos.decision().trim().toUpperCase(), datos.fundamento().trim(), datos.numeroResolucion().trim(),
                datos.miembrosPleno(), datos.votosFavor(), datos.votosContra(), Boolean.TRUE.equals(datos.votoDirimente()));
        if (r.filas().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "El procedimiento no devolvió resultados.");
        }
        return r.filas().get(0);
    }

    Map<String, Object> respuesta(String mensaje, Integer idProceso, Usuario usuario) {
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("mensaje", mensaje);
        r.put("detalle", detalle(idProceso, usuario));
        return r;
    }

    // ─── Utilidades ──────────────────────────────────────────────────────────

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

    private Object leerJson(Object contenido) {
        if (contenido == null) {
            return null;
        }
        try {
            return json.readValue(String.valueOf(contenido), new TypeReference<Object>() { });
        } catch (Exception e) {
            return null;
        }
    }

    private static List<Integer> enteros(Object valor) {
        List<Integer> r = new ArrayList<>();
        if (valor instanceof List<?> lista) {
            for (Object o : lista) {
                if (o instanceof Number n) {
                    r.add(n.intValue());
                }
            }
        }
        return r;
    }

    static String vacioANulo(String texto) {
        return texto == null || texto.isBlank() ? null : texto.trim();
    }

    static String texto(Object valor) {
        return valor == null ? "" : String.valueOf(valor);
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
