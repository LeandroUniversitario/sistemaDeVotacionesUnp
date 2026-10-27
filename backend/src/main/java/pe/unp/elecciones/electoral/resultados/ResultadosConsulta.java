package pe.unp.elecciones.electoral.resultados;

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
 * CUS17 · Lecturas compartidas por ConsultarResultados y VerificarActa: procesos con resultados
 * (1 seleccionarProceso), 3 verificarComputoCerrado (fn_resultados_disponibles), 4 consultarResultados
 * (resultados por cargo y por mesa), documentos verificables con su huella (RF52, RF55) y cotejos.
 * Ninguna consulta revela el sentido del voto de un docente.
 */
@Service
public class ResultadosConsulta {

    static final List<String> CANALES = List.of("QR", "CODIGO", "LISTA", "PORTAL");
    static final List<String> DECISIONES = List.of("ACLARADA", "FUNDADA");

    private final ProcedimientoDao dao;
    private final ObjectMapper json;
    private volatile boolean instalada;

    public ResultadosConsulta(ProcedimientoDao dao, ObjectMapper json) {
        this.dao = dao;
        this.json = json;
    }

    /** Falla con un mensaje claro si falta ejecutar la migración del CUS17. */
    void verificarInstalacion() {
        if (instalada) {
            return;
        }
        if (dao.entero("""
                SELECT COUNT(*) FROM information_schema.routines
                 WHERE routine_schema = DATABASE() AND routine_name = 'sp_verificar_documento'
                """) == 0) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Faltan los cambios del CUS17: ejecute base-de-datos/16_resultados_verificacion.sql en la base de datos.");
        }
        instalada = true;
    }

    // ─── 1 seleccionarProceso() ──────────────────────────────────────────────

    public List<Map<String, Object>> procesos() {
        verificarInstalacion();
        return dao.consultar("""
                SELECT id_proceso AS id, proceso AS nombre, tipo, estado_proceso, id_proceso_padre, proceso_padre, origen,
                       resultado, electores_habiles, votaron, participacion_pct, numero_resolucion, fecha_computo,
                       fecha_proclamacion, fecha_publicacion, cargos, mesas
                  FROM v_resultados_procesos
                 ORDER BY COALESCE(fecha_publicacion, fecha_computo) DESC, id_proceso DESC
                """);
    }

    // ─── 3 verificarComputoCerrado() ─────────────────────────────────────────

    /** RF99 / RN26: el proceso debe tener el cómputo publicado (o computado con el cómputo heredado). */
    Map<String, Object> procesoConResultados(Integer idProceso) {
        verificarInstalacion();
        List<Map<String, Object>> filas = dao.consultar(
                "SELECT * FROM v_resultados_procesos WHERE id_proceso = ?", idProceso);
        if (!filas.isEmpty()) {
            return filas.get(0);
        }
        List<Map<String, Object>> proceso = dao.consultar("""
                SELECT p.nombre, p.estado, cp.estado AS estado_computo
                  FROM proceso_electoral p LEFT JOIN computo_proceso cp ON cp.id_proceso = p.id_proceso
                 WHERE p.id_proceso = ?
                """, idProceso);
        if (proceso.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Proceso electoral no encontrado.");
        }
        Object computo = proceso.get(0).get("estadoComputo");
        String motivo = computo == null
                ? "RN26: los resultados de «" + proceso.get(0).get("nombre") + "» se muestran después del cómputo oficial."
                : "RF99: el CEUNP aún no publica los resultados de «" + proceso.get(0).get("nombre")
                        + "» (cómputo " + String.valueOf(computo).toLowerCase().replace('_', ' ') + ").";
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, motivo);
    }

    // ─── 4 consultarResultados() · 5 devolverResultados() ───────────────────

    public Map<String, Object> detalle(Integer idProceso, Usuario usuario) {
        Map<String, Object> proceso = procesoConResultados(idProceso);
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("proceso", proceso);
        respuesta.put("cargos", cargos(idProceso));
        respuesta.put("mesas", mesas(idProceso));
        respuesta.put("documentos", documentos(idProceso));
        respuesta.put("nulidades", dao.consultar("""
                SELECT id_nulidad, alcance, numero_mesa, causal, numero_resolucion, fundamento_resolucion,
                       fecha_resolucion, fecha_publicacion
                  FROM v_portal_nulidades WHERE id_proceso = ? ORDER BY fecha_resolucion
                """, idProceso));
        respuesta.put("segundaVuelta", dao.consultar("""
                SELECT id_proceso AS id, nombre, estado, fecha_inicio, fecha_fin
                  FROM proceso_electoral WHERE id_proceso_padre = ? ORDER BY id_proceso
                """, idProceso));
        respuesta.put("verificaciones", resumenVerificaciones(idProceso));
        if (usuario != null) {
            boolean supervisa = usuario.getRol() == Rol.CEUNP || usuario.getRol() == Rol.ADMIN;
            respuesta.put("cotejos", supervisa ? cotejos(idProceso, null) : cotejos(idProceso, usuario.getId()));
            respuesta.put("puedeAtender", usuario.getRol() == Rol.CEUNP);
            respuesta.put("supervisa", supervisa);
        }
        return respuesta;
    }

    /** Resultados por cargo: listas con votos, porcentaje y posición; blancos, nulos y proclamación. */
    private List<Map<String, Object>> cargos(Integer idProceso) {
        List<Map<String, Object>> cargos = dao.consultar("""
                SELECT c.id_cargo, c.nombre AS cargo, c.nivel_jurisdiccion AS nivel, c.porcentaje_minimo_victoria, c.estado_resultado, c.id_lista_ganadora,
                       g.nombre AS lista_ganadora, pc.electores_habiles, pc.votaron, pc.participacion_pct, pc.alcanza_quorum,
                       pr.votos AS votos_proclamados, pr.porcentaje_validos AS porcentaje_proclamado, pr.codigo_credencial
                  FROM cargo_electoral c
                  LEFT JOIN v_participacion_cargo pc ON pc.id_cargo = c.id_cargo
                  LEFT JOIN lista_electoral g        ON g.id_lista = c.id_lista_ganadora
                  LEFT JOIN proclamacion_cargo pr    ON pr.id_cargo = c.id_cargo
                 WHERE c.id_proceso = ? ORDER BY c.id_cargo
                """, idProceso);
        List<Map<String, Object>> detalle = dao.consultar("""
                SELECT r.id_cargo, r.id_lista, l.nombre AS lista, l.simbolo, l.orden_cedula, r.tipo_voto, r.total_votos AS votos,
                       r.porcentaje_validos, r.posicion,
                       (SELECT GROUP_CONCAT(CONCAT(ca.rol_en_lista, ': ', d.nombres, ' ', d.apellidos)
                                            ORDER BY ca.id_candidato SEPARATOR ' | ')
                          FROM candidato ca JOIN docente d ON d.id_docente = ca.id_docente
                         WHERE ca.id_lista = r.id_lista AND ca.estado_validacion = 'APROBADO') AS formula
                  FROM resultado_electoral r
                  LEFT JOIN lista_electoral l ON l.id_lista = r.id_lista
                 WHERE r.id_proceso = ?
                 ORDER BY r.id_cargo, (r.id_lista IS NULL), r.total_votos DESC, l.orden_cedula
                """, idProceso);
        for (Map<String, Object> c : cargos) {
            List<Map<String, Object>> listas = new ArrayList<>();
            long validos = 0;
            long blancos = 0;
            long nulos = 0;
            for (Map<String, Object> r : detalle) {
                if (!c.get("idCargo").equals(r.get("idCargo"))) {
                    continue;
                }
                long votos = r.get("votos") instanceof Number n ? n.longValue() : 0;
                switch (String.valueOf(r.get("tipoVoto"))) {
                    case "VALIDO" -> {
                        validos += votos;
                        r.put("ganadora", r.get("idLista") != null && r.get("idLista").equals(c.get("idListaGanadora")));
                        listas.add(r);
                    }
                    case "BLANCO" -> blancos += votos;
                    default -> nulos += votos;
                }
            }
            c.put("listas", listas);
            c.put("validos", validos);
            c.put("blancos", blancos);
            c.put("nulos", nulos);
            c.put("emitidos", validos + blancos + nulos);
        }
        return cargos;
    }

    /** Resultados por mesa (RF99), agrupados por mesa y cargo. */
    private List<Map<String, Object>> mesas(Integer idProceso) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT x.id_mesa, x.numero_mesa, x.estado_mesa, x.id_cargo, x.cargo, x.opcion, x.id_lista, x.lista,
                       x.votos, x.fuente, m.ubicacion, m.total_electores,
                       (SELECT COUNT(DISTINCT pe.id_docente) FROM padron_electoral pe
                         WHERE pe.id_mesa = x.id_mesa AND pe.ya_voto = 1) AS votaron
                  FROM v_resultados_mesa x
                  JOIN mesa_electoral m ON m.id_mesa = x.id_mesa
                 WHERE x.id_proceso = ?
                 ORDER BY LENGTH(x.numero_mesa), x.numero_mesa, x.id_cargo,
                          FIELD(x.opcion, 'LISTA', 'BLANCO', 'NULO'), COALESCE(x.orden_cedula, 999)
                """, idProceso);
        Map<Object, Map<String, Object>> mesas = new LinkedHashMap<>();
        for (Map<String, Object> f : filas) {
            Map<String, Object> mesa = mesas.computeIfAbsent(f.get("idMesa"), k -> {
                Map<String, Object> m = new LinkedHashMap<>();
                m.put("idMesa", f.get("idMesa"));
                m.put("numeroMesa", f.get("numeroMesa"));
                m.put("ubicacion", f.get("ubicacion"));
                m.put("estadoMesa", f.get("estadoMesa"));
                m.put("electores", f.get("totalElectores"));
                m.put("votaron", f.get("votaron"));
                m.put("fuente", f.get("fuente"));
                m.put("cargos", new ArrayList<Map<String, Object>>());
                return m;
            });
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> cargos = (List<Map<String, Object>>) mesa.get("cargos");
            Map<String, Object> cargo = cargos.stream().filter(c -> c.get("idCargo").equals(f.get("idCargo"))).findFirst()
                    .orElseGet(() -> {
                        Map<String, Object> c = new LinkedHashMap<>();
                        c.put("idCargo", f.get("idCargo"));
                        c.put("cargo", f.get("cargo"));
                        c.put("opciones", new ArrayList<Map<String, Object>>());
                        c.put("total", 0L);
                        cargos.add(c);
                        return c;
                    });
            Map<String, Object> opcion = new LinkedHashMap<>();
            opcion.put("opcion", f.get("opcion"));
            opcion.put("idLista", f.get("idLista"));
            opcion.put("lista", f.get("lista"));
            opcion.put("votos", f.get("votos"));
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> opciones = (List<Map<String, Object>>) cargo.get("opciones");
            opciones.add(opcion);
            cargo.put("total", (Long) cargo.get("total") + (f.get("votos") instanceof Number n ? n.longValue() : 0));
        }
        return new ArrayList<>(mesas.values());
    }

    /** RF52: documentos del proceso con QR y huella, con su integridad recalculada. */
    List<Map<String, Object>> documentos(Integer idProceso) {
        return dao.consultar("""
                SELECT tipo_documento, id_documento, id_mesa, numero_mesa, numero_resolucion, fecha_emision, estado,
                       hash_integridad, integra, firmas, verificaciones, cotejos, observados
                  FROM v_documentos_verificables WHERE id_proceso = ?
                 ORDER BY (id_mesa IS NOT NULL), LENGTH(numero_mesa), numero_mesa,
                          FIELD(tipo_documento, 'COMPUTO_GENERAL', 'PROCLAMACION', 'RESOLUCION_NULIDAD', 'RESOLUCION_MULTAS',
                                'ACTA_INSTALACION', 'ACTA_SUFRAGIO', 'ACTA_ESCRUTINIO')
                """, idProceso);
    }

    Map<String, Object> resumenVerificaciones(Integer idProceso) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT COUNT(*) AS total,
                       COALESCE(SUM(resultado = 'AUTENTICA'), 0) AS autenticas,
                       COALESCE(SUM(resultado = 'ALTERADA'), 0) AS alteradas,
                       COALESCE(SUM(resultado = 'ANULADA'), 0) AS anuladas,
                       COUNT(DISTINCT CONCAT(tipo_documento, '-', id_documento)) AS documentos,
                       MAX(fecha) AS ultima
                  FROM verificacion_documento WHERE id_proceso = ?
                """, idProceso);
        return filas.isEmpty() ? Map.of() : filas.get(0);
    }

    /** Cotejos del proceso: todos para el CEUNP y el ADMIN; los propios para los demás. */
    public List<Map<String, Object>> cotejos(Integer idProceso, Integer idUsuario) {
        verificarInstalacion();
        StringBuilder sql = new StringBuilder("""
                SELECT id_cotejo, id_proceso, proceso, tipo_documento, id_documento, id_mesa, numero_mesa, hash_integridad,
                       contenido_integro, lineas, diferencias, observacion, estado, fecha, username, rol, registrado_por,
                       lista_personero, tipo_personero, decision, respuesta, fecha_respuesta, atendido_por, cifras_json
                  FROM v_cotejos_acta WHERE 1 = 1
                """);
        List<Object> args = new ArrayList<>();
        if (idProceso != null) {
            sql.append(" AND id_proceso = ?");
            args.add(idProceso);
        }
        if (idUsuario != null) {
            sql.append(" AND id_usuario = ?");
            args.add(idUsuario);
        }
        sql.append(" ORDER BY FIELD(estado, 'OBSERVADO', 'ATENDIDO', 'CONFORME'), fecha DESC");
        List<Map<String, Object>> filas = dao.consultar(sql.toString(), args.toArray());
        for (Map<String, Object> f : filas) {
            f.put("cifras", leerJson(f.remove("cifrasJson")));
        }
        return filas;
    }

    // ─── Utilidades ──────────────────────────────────────────────────────────

    Object leerJson(Object contenido) {
        if (contenido == null) {
            return null;
        }
        try {
            return json.readValue(String.valueOf(contenido), new TypeReference<Object>() { });
        } catch (Exception e) {
            return null;
        }
    }

    String escribirJson(Object valor) {
        try {
            return json.writeValueAsString(valor);
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "No se pudo preparar el cotejo.");
        }
    }

    static String vacioANulo(String texto) {
        return texto == null || texto.isBlank() ? null : texto.trim();
    }
}
