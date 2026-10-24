package pe.unp.elecciones.electoral.computo;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Rol;
import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS14 · Lecturas compartidas por SesionComputo, VerificarActas y ComputarProclamar:
 * mesas y su situación para el cómputo (v_computo_mesas), actas con su huella (v_computo_actas),
 * consolidado provisional (v_computo_resultados), participación (v_participacion_cargo), sesión,
 * acta general, proclamación y publicación (computo_proceso).
 */
@Service
public class ComputoConsulta {

    /** Situaciones de v_computo_mesas que no impiden el cómputo. */
    static final List<String> SIN_BLOQUEO = List.of("HABILITADA", "NO_INSTALADA", "ANULADA");

    private static final String SELECT_PROCESO = """
            SELECT p.id_proceso AS id, p.nombre, p.estado, p.tipo, p.id_proceso_padre, p.quorum_minimo,
                   p.fecha_inicio, p.fecha_fin, p.fecha_cierre_real, p.motivo_anulacion,
                   cp.estado AS estado_computo
              FROM proceso_electoral p
              LEFT JOIN computo_proceso cp ON cp.id_proceso = p.id_proceso
            """;

    private final ProcedimientoDao dao;
    private final ObjectMapper json;
    private volatile boolean instalada;

    public ComputoConsulta(ProcedimientoDao dao, ObjectMapper json) {
        this.dao = dao;
        this.json = json;
    }

    /** Falla con un mensaje claro si falta ejecutar la migración del CUS14. */
    void verificarInstalacion() {
        if (instalada) {
            return;
        }
        if (dao.entero("""
                SELECT COUNT(*) FROM information_schema.routines
                 WHERE routine_schema = DATABASE() AND routine_name = 'sp_ejecutar_computo'
                """) == 0) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Faltan los cambios del CUS14: ejecute base-de-datos/13_computo_proclamacion.sql en la base de datos.");
        }
        instalada = true;
    }

    // ─── Procesos ────────────────────────────────────────────────────────────

    /** Procesos con mesas: en votación, por computar o ya computados. */
    public List<Map<String, Object>> procesos() {
        verificarInstalacion();
        return dao.consultar("""
                SELECT p.id_proceso AS id, p.nombre, p.estado, p.tipo, cp.estado AS estado_computo,
                       COUNT(m.id_mesa) AS mesas,
                       COALESCE(SUM(m.estado = 'CERRADA'), 0) AS mesas_cerradas,
                       cp.participacion_pct, cp.resultado, cp.fecha_computo, cp.fecha_publicacion
                  FROM proceso_electoral p
                  JOIN mesa_electoral m ON m.id_proceso = p.id_proceso
                  LEFT JOIN computo_proceso cp ON cp.id_proceso = p.id_proceso
                 WHERE p.estado IN ('VOTACION', 'CERRADO', 'FINALIZADO', 'ANULADO')
                 GROUP BY p.id_proceso, p.nombre, p.estado, p.tipo, cp.estado, cp.participacion_pct, cp.resultado,
                          cp.fecha_computo, cp.fecha_publicacion, p.fecha_inicio
                 ORDER BY FIELD(p.estado, 'CERRADO', 'VOTACION', 'FINALIZADO', 'ANULADO'), p.fecha_inicio DESC
                """);
    }

    public Map<String, Object> proceso(Integer idProceso) {
        verificarInstalacion();
        List<Map<String, Object>> filas = dao.consultar(SELECT_PROCESO + " WHERE p.id_proceso = ?", idProceso);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Proceso electoral no encontrado.");
        }
        return filas.get(0);
    }

    // ─── 2-3 verificarActasEntregadas / actasEntregadas ─────────────────────

    List<Map<String, Object>> mesas(Integer idProceso) {
        return dao.consultar("""
                SELECT id_mesa, numero_mesa, ubicacion, estado, total_electores, estado_escrutinio, total_votantes,
                       cedulas_escrutadas, observada, prevalece_fisica, conteo_cuadra, total_cuadra, fecha_entrega,
                       recibido_por, codigo_cargo, actas_vigentes, actas_alteradas, actas_dudosas, actas_no_autenticas,
                       impugnaciones, impugnaciones_pendientes, requiere_calificacion, calificacion, motivo_revision,
                       fundamento_calificacion, resolucion_calificacion, fecha_calificacion, situacion
                  FROM v_computo_mesas WHERE id_proceso = ?
                 ORDER BY LENGTH(numero_mesa), numero_mesa
                """, idProceso);
    }

    /** Mesa con el proceso al que pertenece (para las acciones de verificación). */
    Map<String, Object> mesa(Integer idMesa) {
        verificarInstalacion();
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT id_proceso, id_mesa, numero_mesa, ubicacion, estado, total_electores, estado_escrutinio,
                       total_votantes, observada, prevalece_fisica, conteo_cuadra, total_cuadra, actas_vigentes,
                       actas_alteradas, actas_dudosas, actas_no_autenticas, impugnaciones, impugnaciones_pendientes,
                       requiere_calificacion, calificacion, motivo_revision, fundamento_calificacion,
                       resolucion_calificacion, fecha_calificacion, situacion
                  FROM v_computo_mesas WHERE id_mesa = ?
                """, idMesa);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Mesa no encontrada.");
        }
        return filas.get(0);
    }

    /** Detalle de una mesa: sus actas, su conteo por opción y sus impugnaciones (verificación previa). */
    public Map<String, Object> detalleMesa(Integer idMesa) {
        Map<String, Object> mesa = mesa(idMesa);
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mesa", mesa);
        respuesta.put("actas", dao.consultar("""
                SELECT id_acta, tipo, estado, fecha_emision, hash_integridad, integra, dudosa, motivo_duda, fecha_marca,
                       comprobacion, huella_coincide, qr_coincide, observacion_comprobacion, fecha_comprobacion
                  FROM v_computo_actas WHERE id_mesa = ?
                 ORDER BY FIELD(tipo, 'INSTALACION', 'SUFRAGIO', 'ESCRUTINIO'), id_acta
                """, idMesa));
        respuesta.put("conteo", dao.consultar("""
                SELECT x.id_cargo, c.nombre AS cargo, x.opcion, x.id_lista,
                       COALESCE(l.nombre, CASE x.opcion WHEN 'BLANCO' THEN 'Votos en blanco' WHEN 'NULO' THEN 'Votos nulos'
                                                        ELSE 'Impugnados sin resolver' END) AS lista,
                       l.orden_cedula, x.votos_acta, x.impugnados_asignados, x.votos, x.votos_digital
                  FROM v_computo_conteo_mesa x
                  JOIN cargo_electoral c ON c.id_cargo = x.id_cargo
                  LEFT JOIN lista_electoral l ON l.id_lista = x.id_lista
                 WHERE x.id_mesa = ?
                 ORDER BY x.id_cargo, FIELD(x.opcion, 'LISTA', 'BLANCO', 'NULO', 'IMPUGNADO'), COALESCE(l.orden_cedula, 999)
                """, idMesa));
        respuesta.put("impugnaciones", dao.consultar("""
                SELECT e.situacion, COUNT(*) AS cedulas
                  FROM v_impugnacion_efecto e WHERE e.id_mesa = ?
                 GROUP BY e.situacion
                """, idMesa));
        return respuesta;
    }

    Map<String, Object> acta(Integer idActa) {
        verificarInstalacion();
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT id_proceso, id_mesa, numero_mesa, id_acta, tipo, estado, hash_integridad, integra, dudosa,
                       motivo_duda, comprobacion, huella_coincide, qr_coincide
                  FROM v_computo_actas WHERE id_acta = ?
                """, idActa);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Acta no encontrada.");
        }
        return filas.get(0);
    }

    // ─── Detalle del proceso (todas las etapas) ─────────────────────────────

    public Map<String, Object> detalle(Integer idProceso, Usuario usuario) {
        Map<String, Object> proceso = proceso(idProceso);
        String estado = texto(proceso.get("estado"));
        Map<String, Object> computo = computo(idProceso);
        String etapa = computo == null ? null : texto(computo.get("estado"));
        boolean ceunp = usuario.getRol() == Rol.CEUNP;

        List<Map<String, Object>> mesas = mesas(idProceso);
        Map<String, Object> resumen = resumenMesas(mesas);
        List<String> bloqueos = new ArrayList<>();
        for (Map<String, Object> m : mesas) {
            if (!SIN_BLOQUEO.contains(texto(m.get("situacion")))) {
                bloqueos.add("Mesa " + m.get("numeroMesa") + ": " + SITUACION.getOrDefault(texto(m.get("situacion")),
                        texto(m.get("situacion"))) + ".");
            }
        }
        boolean antesDelComputo = "CERRADO".equals(estado) && (etapa == null || "SESION_INSTALADA".equals(etapa));

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("proceso", proceso);
        respuesta.put("computo", computo);
        respuesta.put("mesas", mesas);
        respuesta.put("resumenMesas", resumen);
        respuesta.put("actas", dao.consultar("""
                SELECT id_acta, id_mesa, numero_mesa, tipo, estado, fecha_emision, hash_integridad, integra, dudosa,
                       motivo_duda, comprobacion, huella_coincide, qr_coincide, fecha_comprobacion
                  FROM v_computo_actas WHERE id_proceso = ?
                 ORDER BY LENGTH(numero_mesa), numero_mesa, FIELD(tipo, 'INSTALACION', 'SUFRAGIO', 'ESCRUTINIO')
                """, idProceso));
        respuesta.put("participacion", participacion(idProceso));
        respuesta.put("consolidado", consolidado(idProceso));
        respuesta.put("personeros", personeros(idProceso));
        respuesta.put("resultados", etapa == null || "SESION_INSTALADA".equals(etapa) ? null : resultados(idProceso));
        respuesta.put("proclamados", dao.consultar("""
                SELECT pc.id_cargo, c.nombre AS cargo, pc.id_lista, l.nombre AS lista, l.simbolo, pc.votos,
                       pc.porcentaje_validos, pc.codigo_credencial, pc.fecha_proclamacion
                  FROM proclamacion_cargo pc
                  JOIN cargo_electoral c ON c.id_cargo = pc.id_cargo
                  JOIN lista_electoral l ON l.id_lista = pc.id_lista
                 WHERE pc.id_proceso = ? ORDER BY pc.id_cargo
                """, idProceso));
        List<Map<String, Object>> hijos = dao.consultar(
                "SELECT id_proceso AS id, nombre, estado, fecha_inicio, fecha_fin FROM proceso_electoral WHERE id_proceso_padre = ?",
                idProceso);
        respuesta.put("segundaVuelta", hijos.isEmpty() ? null : hijos.get(0));
        respuesta.put("bloqueos", bloqueos);

        int quorumPleno = parametro("CEUNP_QUORUM_PLENO", 5);
        int plazo = parametro("SEGUNDA_VUELTA_PLAZO_DIAS", 15);
        Map<String, Object> parametros = new LinkedHashMap<>();
        parametros.put("quorumPleno", quorumPleno);
        parametros.put("plazoSegundaVuelta", plazo);
        parametros.put("limiteSegundaVuelta", computo != null && computo.get("fechaComputo") instanceof LocalDateTime f && plazo > 0
                ? f.plusDays(plazo) : null);
        respuesta.put("parametros", parametros);

        long porSegunda = dao.entero("""
                SELECT COUNT(*) FROM cargo_electoral WHERE id_proceso = ? AND estado_resultado = 'SEGUNDA_VUELTA'
                """, idProceso);
        boolean computado = etapa != null && !"SESION_INSTALADA".equals(etapa);
        boolean pendientesMesa = mesas.stream().anyMatch(m -> List.of("INSTALADA", "PENDIENTE").contains(texto(m.get("estado"))));

        Map<String, Object> acciones = new LinkedHashMap<>();
        acciones.put("concluirVotacion", ceunp && "VOTACION".equals(estado));
        acciones.put("motivoNoConcluye", !"VOTACION".equals(estado) ? null
                : pendientesMesa ? "Hay mesas en sufragio o sin instalar: ciérrelas (CUS11) o registre su no instalación (CUS08)." : null);
        acciones.put("instalarSesion", ceunp && "CERRADO".equals(estado) && etapa == null);
        acciones.put("registrarPersonero", ceunp && "SESION_INSTALADA".equals(etapa));
        acciones.put("verificarActas", ceunp && antesDelComputo);
        acciones.put("ejecutarComputo", ceunp && "CERRADO".equals(estado) && "SESION_INSTALADA".equals(etapa) && bloqueos.isEmpty());
        acciones.put("proclamar", ceunp && "COMPUTADO".equals(etapa) && !"ANULADO".equals(estado));
        acciones.put("publicar", ceunp && ("PROCLAMADO".equals(etapa) || ("COMPUTADO".equals(etapa) && "ANULADO".equals(estado))));
        acciones.put("convocarSegundaVuelta", ceunp && computado && porSegunda > 0 && hijos.isEmpty());
        respuesta.put("acciones", acciones);
        respuesta.put("soloLectura", !ceunp);
        return respuesta;
    }

    /** Sesión, cómputo, proclamación y publicación del proceso; null si la sesión no se instaló. */
    Map<String, Object> computo(Integer idProceso) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT cp.estado, cp.lugar_sesion, cp.miembros_ceunp, cp.observaciones_sesion, cp.fecha_sesion,
                       us.username AS sesion_instalada_por,
                       cp.fecha_computo, cp.mesas_total, cp.mesas_computadas, cp.mesas_no_instaladas, cp.mesas_anuladas,
                       cp.actas_verificadas, cp.electores_habiles, cp.votaron, cp.participacion_pct, cp.resultado,
                       cp.hash_integridad, IF(SHA2(cp.contenido_json, 256) = cp.hash_integridad, 1, 0) AS acta_integra,
                       cp.contenido_json, uc.username AS computado_por,
                       cp.numero_resolucion, cp.miembros_pleno, cp.presidente_ceunp, cp.fundamento_proclamacion,
                       cp.fecha_proclamacion, cp.hash_proclamacion, cp.contenido_proclamacion, up.username AS proclamado_por,
                       cp.fecha_publicacion, ub.username AS publicado_por
                  FROM computo_proceso cp
                  LEFT JOIN usuario us ON us.id_usuario = cp.id_usuario_sesion
                  LEFT JOIN usuario uc ON uc.id_usuario = cp.id_usuario_computo
                  LEFT JOIN usuario up ON up.id_usuario = cp.id_usuario_proclamacion
                  LEFT JOIN usuario ub ON ub.id_usuario = cp.id_usuario_publicacion
                 WHERE cp.id_proceso = ?
                """, idProceso);
        if (filas.isEmpty()) {
            return null;
        }
        Map<String, Object> c = filas.get(0);
        c.put("acta", leerJson(c.remove("contenidoJson")));
        c.put("proclamacion", leerJson(c.remove("contenidoProclamacion")));
        return c;
    }

    /** Personeros acreditados del proceso y si asisten a la sesión de cómputo (RF91). */
    List<Map<String, Object>> personeros(Integer idProceso) {
        return dao.consultar("""
                SELECT pe.id_personero, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS nombre, CONCAT(pe.tipo, '') AS tipo,
                       l.id_lista, l.nombre AS lista, c.nombre AS cargo, m.numero_mesa,
                       IF(cp.id_personero IS NULL, 0, 1) AS presente, cp.hora_registro
                  FROM personero pe
                  JOIN docente d         ON d.id_docente = pe.id_docente
                  JOIN lista_electoral l ON l.id_lista = pe.id_lista
                  JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                  LEFT JOIN mesa_electoral m ON m.id_mesa = pe.id_mesa
                  LEFT JOIN computo_personero cp ON cp.id_proceso = c.id_proceso AND cp.id_personero = pe.id_personero
                 WHERE c.id_proceso = ? AND pe.estado_acreditacion = 'ACREDITADO'
                 ORDER BY presente DESC, FIELD(pe.tipo, 'GENERAL', 'ALTERNO', 'MESA'), l.nombre, d.apellidos
                """, idProceso);
    }

    // ─── 8-9 calcularParticipacion / porcentajeParticipacion ────────────────

    Map<String, Object> participacion(Integer idProceso) {
        Map<String, Object> respuesta = new LinkedHashMap<>();
        List<Map<String, Object>> general = dao.consultar("""
                SELECT electores_habiles, votaron, participacion_pct, quorum_minimo, alcanza_quorum
                  FROM v_quorum_proceso WHERE id_proceso = ?
                """, idProceso);
        respuesta.put("general", general.isEmpty() ? null : general.get(0));
        respuesta.put("cargos", dao.consultar("""
                SELECT id_cargo, cargo, electores_habiles, votaron, faltan, participacion_pct, quorum_minimo, alcanza_quorum
                  FROM v_participacion_cargo WHERE id_proceso = ? ORDER BY id_cargo
                """, idProceso));
        return respuesta;
    }

    // ─── 6-7 consolidarVotos / totalesPorLista ──────────────────────────────

    /**
     * Consolidado provisional de las actas de las mesas no anuladas, con la proyección de RN31 y
     * RN33. El resultado oficial lo fija sp_ejecutar_computo (mensajes 12 a 15).
     */
    List<Map<String, Object>> consolidado(Integer idProceso) {
        List<Map<String, Object>> cargos = dao.consultar("""
                SELECT c.id_cargo, c.nombre AS cargo, c.porcentaje_minimo_victoria, c.estado_resultado,
                       pc.electores_habiles, pc.votaron, pc.participacion_pct, pc.alcanza_quorum
                  FROM cargo_electoral c
                  JOIN v_participacion_cargo pc ON pc.id_cargo = c.id_cargo
                 WHERE c.id_proceso = ? ORDER BY c.id_cargo
                """, idProceso);
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT id_cargo, opcion, id_lista, lista, orden_cedula, mesas, votos_actas, impugnados_asignados, votos, votos_digital
                  FROM v_computo_resultados WHERE id_proceso = ?
                 ORDER BY id_cargo, FIELD(opcion, 'LISTA', 'BLANCO', 'NULO', 'IMPUGNADO'), votos DESC
                """, idProceso);
        String tipo = texto(proceso(idProceso).get("tipo"));
        for (Map<String, Object> c : cargos) {
            int idCargo = numero(c.get("idCargo"));
            List<Map<String, Object>> listas = dao.consultar("""
                    SELECT id_lista, nombre AS lista, simbolo, orden_cedula FROM lista_electoral
                     WHERE id_cargo = ? AND estado = 'ADMITIDA' ORDER BY COALESCE(orden_cedula, 999), nombre
                    """, idCargo);
            int validos = 0;
            int blancos = 0;
            int nulos = 0;
            int impugnados = 0;
            int mesas = 0;
            for (Map<String, Object> f : filas) {
                if (numero(f.get("idCargo")) != idCargo) {
                    continue;
                }
                int votos = numero(f.get("votos"));
                mesas = Math.max(mesas, numero(f.get("mesas")));
                switch (texto(f.get("opcion"))) {
                    case "LISTA" -> {
                        validos += votos;
                        for (Map<String, Object> l : listas) {
                            if (numero(l.get("idLista")) == numero(f.get("idLista"))) {
                                l.put("votos", votos);
                                l.put("votosActas", numero(f.get("votosActas")));
                                l.put("impugnadosAsignados", numero(f.get("impugnadosAsignados")));
                                l.put("votosDigital", numero(f.get("votosDigital")));
                            }
                        }
                    }
                    case "BLANCO" -> blancos += votos;
                    case "NULO" -> nulos += votos;
                    default -> impugnados += votos;
                }
            }
            int top = 0;
            for (Map<String, Object> l : listas) {
                l.putIfAbsent("votos", 0);
                l.putIfAbsent("votosActas", 0);
                l.putIfAbsent("impugnadosAsignados", 0);
                l.putIfAbsent("votosDigital", 0);
                top = Math.max(top, numero(l.get("votos")));
                l.put("porcentaje", porcentaje(numero(l.get("votos")), validos));
            }
            listas.sort((a, b) -> numero(b.get("votos")) - numero(a.get("votos")));
            int empatados = 0;
            for (Map<String, Object> l : listas) {
                if (numero(l.get("votos")) == top) {
                    empatados++;
                }
            }
            double minimo = c.get("porcentajeMinimoVictoria") instanceof Number n ? n.doubleValue() : 50;
            String proyeccion;
            if (numero(c.get("alcanzaQuorum")) != 1) {
                proyeccion = "SIN_QUORUM";
            } else if (validos == 0) {
                proyeccion = "DESIERTO";
            } else if ("SEGUNDA_VUELTA".equals(tipo)) {
                proyeccion = empatados == 1 && top * 2 > validos ? "ELEGIDO" : "EMPATE";
            } else if (empatados == 1 && top * 100.0 / validos > minimo) {
                proyeccion = "ELEGIDO";
            } else {
                proyeccion = "SEGUNDA_VUELTA";
            }
            c.put("listas", listas);
            c.put("validos", validos);
            c.put("blancos", blancos);
            c.put("nulos", nulos);
            c.put("impugnados", impugnados);
            c.put("emitidos", validos + blancos + nulos + impugnados);
            c.put("mesasComputables", mesas);
            c.put("proyeccion", proyeccion);
            c.put("listaPuntera", top > 0 && empatados == 1 ? listas.get(0).get("lista") : null);
        }
        return cargos;
    }

    // ─── 13 computoRegistrado(resultados) ───────────────────────────────────

    Map<String, Object> resultados(Integer idProceso) {
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("cargos", dao.consultar("""
                SELECT c.id_cargo, c.nombre AS cargo, CONCAT(c.estado_resultado, '') AS estado_resultado,
                       c.id_lista_ganadora, l.nombre AS lista_ganadora, c.porcentaje_minimo_victoria,
                       pc.electores_habiles, pc.votaron, pc.participacion_pct
                  FROM cargo_electoral c
                  JOIN v_participacion_cargo pc ON pc.id_cargo = c.id_cargo
                  LEFT JOIN lista_electoral l ON l.id_lista = c.id_lista_ganadora
                 WHERE c.id_proceso = ? ORDER BY c.id_cargo
                """, idProceso));
        respuesta.put("detalle", dao.consultar("""
                SELECT r.id_cargo, r.id_lista, COALESCE(l.nombre, CASE r.tipo_voto WHEN 'BLANCO' THEN 'Votos en blanco'
                                                                    ELSE 'Votos nulos' END) AS lista,
                       CONCAT(r.tipo_voto, '') AS tipo_voto, r.total_votos, r.porcentaje_validos, r.posicion, l.orden_cedula
                  FROM resultado_electoral r
                  LEFT JOIN lista_electoral l ON l.id_lista = r.id_lista
                 WHERE r.id_proceso = ?
                 ORDER BY r.id_cargo, (r.id_lista IS NULL), r.posicion, r.tipo_voto
                """, idProceso));
        return respuesta;
    }

    /** Resultados por mesa (insumo del portal, RF99). */
    List<Map<String, Object>> resultadosPorMesa(Integer idProceso) {
        return dao.consultar("""
                SELECT x.id_mesa, x.numero_mesa, c.nombre AS cargo, x.opcion,
                       COALESCE(l.nombre, CASE x.opcion WHEN 'BLANCO' THEN 'Votos en blanco' WHEN 'NULO' THEN 'Votos nulos'
                                                        ELSE 'Impugnados' END) AS lista,
                       x.votos, m.estado AS estado_mesa
                  FROM v_computo_conteo_mesa x
                  JOIN mesa_electoral m  ON m.id_mesa = x.id_mesa
                  JOIN cargo_electoral c ON c.id_cargo = x.id_cargo
                  LEFT JOIN lista_electoral l ON l.id_lista = x.id_lista
                 WHERE x.id_proceso = ? AND m.estado <> 'ANULADA'
                 ORDER BY LENGTH(x.numero_mesa), x.numero_mesa, x.id_cargo,
                          FIELD(x.opcion, 'LISTA', 'BLANCO', 'NULO', 'IMPUGNADO'), COALESCE(l.orden_cedula, 999)
                """, idProceso);
    }

    // ─── Utilidades ──────────────────────────────────────────────────────────

    static final Map<String, String> SITUACION = Map.ofEntries(
            Map.entry("HABILITADA", "habilitada para el cómputo"),
            Map.entry("NO_INSTALADA", "no instalada"),
            Map.entry("ANULADA", "anulada"),
            Map.entry("SIN_INSTALAR", "sin instalar (registre su no instalación, CUS08)"),
            Map.entry("EN_SUFRAGIO", "sufragio abierto (CUS11)"),
            Map.entry("ESCRUTINIO_PENDIENTE", "escrutinio pendiente (CUS12)"),
            Map.entry("ACTAS_SIN_ENTREGAR", "actas sin entregar al CEUNP (RF87)"),
            Map.entry("ACTAS_INCOMPLETAS", "faltan actas (instalación, sufragio y escrutinio)"),
            Map.entry("ACTA_NO_AUTENTICA", "acta no auténtica: declare la nulidad de la mesa"),
            Map.entry("ACTA_DUDOSA", "acta dudosa por comprobar (RF90)"),
            Map.entry("IMPUGNACIONES_PENDIENTES", "impugnaciones o apelaciones pendientes (CUS13)"),
            Map.entry("POR_CALIFICAR", "acta que difiere: el CEUNP debe calificarla (RF95)"));

    static Map<String, Object> resumenMesas(List<Map<String, Object>> mesas) {
        Map<String, Object> r = new LinkedHashMap<>();
        Map<String, Integer> porSituacion = new TreeMap<>();
        for (Map<String, Object> m : mesas) {
            porSituacion.merge(texto(m.get("situacion")), 1, Integer::sum);
        }
        r.put("total", mesas.size());
        r.put("habilitadas", porSituacion.getOrDefault("HABILITADA", 0));
        r.put("noInstaladas", porSituacion.getOrDefault("NO_INSTALADA", 0));
        r.put("anuladas", porSituacion.getOrDefault("ANULADA", 0));
        r.put("bloqueadas", mesas.size() - porSituacion.getOrDefault("HABILITADA", 0)
                - porSituacion.getOrDefault("NO_INSTALADA", 0) - porSituacion.getOrDefault("ANULADA", 0));
        r.put("entregadas", mesas.stream().filter(m -> "ENTREGADA".equals(texto(m.get("estadoEscrutinio")))).count());
        r.put("porSituacion", porSituacion);
        return r;
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

    private Object leerJson(Object contenido) {
        if (contenido == null) {
            return null;
        }
        try {
            return json.readValue(String.valueOf(contenido), new TypeReference<Map<String, Object>>() { });
        } catch (Exception e) {
            return null;
        }
    }

    private static BigDecimal porcentaje(int votos, int total) {
        if (total == 0) {
            return BigDecimal.ZERO;
        }
        return BigDecimal.valueOf(votos * 100.0 / total).setScale(2, RoundingMode.HALF_UP);
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
