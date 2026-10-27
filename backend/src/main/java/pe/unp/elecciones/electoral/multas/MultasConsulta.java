package pe.unp.elecciones.electoral.multas;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Rol;
import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS16 · Lecturas compartidas por GenerarMultas y RegistrarJustificacion: omisos del proceso
 * (v_omisos_proceso: 1 solicitarReporteOmisos, 4 consultarNoVotaron, 5 consultarInasistentes),
 * parámetros (3 obtenerUIT, RF105), multas y su reporte (7 mostrarReporteMultas), descargos
 * (RF106) y el reporte de gestión por mesa (RF107).
 */
@Service
public class MultasConsulta {

    static final List<String> MEDIOS = List.of("CORREO_INSTITUCIONAL", "CEDULA_PERSONAL", "PORTAL_ELECTORAL");
    static final List<String> TIPOS = List.of("JUSTIFICACION", "EXONERACION");
    static final List<String> CAUSALES = List.of(
            "SALUD", "DUELO", "COMISION_SERVICIO", "LICENCIA", "CASO_FORTUITO", "FALLECIMIENTO", "ERROR_PADRON", "OTRA");
    static final List<String> DECISIONES = List.of("ADMITIDA", "DENEGADA");

    private final ProcedimientoDao dao;
    private final ObjectMapper json;
    private volatile boolean instalada;

    public MultasConsulta(ProcedimientoDao dao, ObjectMapper json) {
        this.dao = dao;
        this.json = json;
    }

    /** Falla con un mensaje claro si falta ejecutar la migración del CUS16. */
    void verificarInstalacion() {
        if (instalada) {
            return;
        }
        if (dao.entero("""
                SELECT COUNT(*) FROM information_schema.routines
                 WHERE routine_schema = DATABASE() AND routine_name = 'sp_emitir_resolucion_multas'
                """) == 0) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Faltan los cambios del CUS16: ejecute base-de-datos/15_omisos_multas.sql en la base de datos.");
        }
        instalada = true;
    }

    // ─── Procesos ────────────────────────────────────────────────────────────

    /** Procesos que ya tuvieron mesas en la jornada, con el avance de sus multas. */
    public List<Map<String, Object>> procesos() {
        verificarInstalacion();
        return dao.consultar("""
                SELECT p.id_proceso AS id, p.nombre, p.estado, p.tipo, r.estado AS estado_reporte, r.numero_resolucion,
                       (SELECT COUNT(*) FROM multa mu WHERE mu.id_proceso = p.id_proceso) AS multas,
                       (SELECT COUNT(*) FROM multa mu WHERE mu.id_proceso = p.id_proceso AND mu.estado_pago = 'PENDIENTE') AS pendientes
                  FROM proceso_electoral p
                  LEFT JOIN reporte_multas r ON r.id_proceso = p.id_proceso
                 WHERE p.estado IN ('VOTACION', 'CERRADO', 'FINALIZADO', 'ANULADO')
                   AND EXISTS (SELECT 1 FROM mesa_electoral m WHERE m.id_proceso = p.id_proceso)
                 ORDER BY FIELD(p.estado, 'CERRADO', 'FINALIZADO', 'VOTACION', 'ANULADO'), p.fecha_inicio DESC
                """);
    }

    public Map<String, Object> proceso(Integer idProceso) {
        verificarInstalacion();
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT p.id_proceso AS id, p.nombre, p.estado, p.tipo, p.id_proceso_padre, pp.nombre AS proceso_padre,
                       p.fecha_inicio, p.fecha_fin, p.fecha_cierre_real, p.motivo_anulacion, cp.estado AS estado_computo
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
        boolean ceunp = usuario.getRol() == Rol.CEUNP;

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("proceso", proceso);
        List<Map<String, Object>> general = dao.consultar("""
                SELECT electores_habiles, votaron, participacion_pct, quorum_minimo, alcanza_quorum
                  FROM v_quorum_proceso WHERE id_proceso = ?
                """, idProceso);
        respuesta.put("participacion", general.isEmpty() ? null : general.get(0));

        // 3 obtenerUIT() (RF105)
        Map<String, Object> parametros = parametros();
        respuesta.put("parametros", parametros);

        // Mesas: el reporte exige el sufragio cerrado en todas (CUS11)
        List<Map<String, Object>> mesas = dao.consultar("""
                SELECT id_mesa, numero_mesa, ubicacion, estado, hora_instalacion, hora_cierre, electores, votaron, asistieron,
                       titulares_presentes, titulares_ausentes, suplentes_en_funcion, incidencias, atencion_promedio_seg,
                       actas_emitidas, estado_escrutinio, fecha_entrega, recibido_por
                  FROM v_reporte_gestion_mesas WHERE id_proceso = ?
                 ORDER BY LENGTH(numero_mesa), numero_mesa
                """, idProceso);
        long abiertas = mesas.stream().filter(m -> List.of("PENDIENTE", "INSTALADA").contains(texto(m.get("estado")))).count();
        long instaladas = mesas.stream().filter(m -> m.get("horaInstalacion") != null).count();
        Map<String, Object> rm = new LinkedHashMap<>();
        rm.put("total", mesas.size());
        rm.put("instaladas", instaladas);
        rm.put("noInstaladas", mesas.stream().filter(m -> m.get("horaInstalacion") == null).count());
        rm.put("abiertas", abiertas);
        rm.put("actasEntregadas", mesas.stream().filter(m -> m.get("fechaEntrega") != null).count());
        respuesta.put("resumenMesas", rm);

        // 1 solicitarReporteOmisos(): omisos según el padrón y las mesas, con el monto vigente
        List<Map<String, Object>> omisos = omisos(idProceso, parametros);
        respuesta.put("omisos", omisos);

        // 6 insertar() / 7 mostrarReporteMultas(): multas generadas y su reporte
        List<Map<String, Object>> multas = multas(idProceso);
        respuesta.put("multas", multas);
        Map<String, Object> reporte = reporte(idProceso);
        respuesta.put("reporte", reporte);
        String estadoReporte = reporte == null ? "" : texto(reporte.get("estado"));
        boolean resuelto = "RESUELTO".equals(estadoReporte);

        Set<String> claveOmisos = new HashSet<>();
        omisos.forEach(o -> claveOmisos.add(o.get("idDocente") + "|" + o.get("motivo")));
        Set<String> claveMultas = new HashSet<>();
        multas.forEach(m -> claveMultas.add(m.get("idDocente") + "|" + m.get("motivo")));
        BigDecimal uit = decimal(parametros.get("uit"));
        boolean otraUit = reporte != null && uit != null && decimal(reporte.get("uitReferencia")) != null
                && decimal(reporte.get("uitReferencia")).compareTo(uit) != 0;
        boolean desactualizado = reporte != null && !resuelto && (!claveOmisos.equals(claveMultas) || otraUit);
        respuesta.put("desactualizado", desactualizado);

        respuesta.put("resumen", resumen(multas));
        respuesta.put("descargos", dao.consultar("""
                SELECT j.id_justificacion, j.id_multa, CONCAT(j.tipo, '') AS tipo, CONCAT(j.causal, '') AS causal, j.sustento,
                       j.documento, j.fecha_presentacion, j.decision, j.fundamento, j.numero_resolucion, j.miembros_pleno,
                       j.fecha_resolucion, u.username AS registrado_por, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS docente,
                       mu.motivo, mu.monto, mu.estado_pago
                  FROM multa_justificacion j
                  JOIN multa mu  ON mu.id_multa = j.id_multa
                  JOIN docente d ON d.id_docente = mu.id_docente
                  LEFT JOIN usuario u ON u.id_usuario = j.id_usuario
                 WHERE mu.id_proceso = ?
                 ORDER BY j.id_justificacion DESC
                """, idProceso));

        // RF107: reporte de gestión
        respuesta.put("gestion", mesas);
        respuesta.put("incidencias", dao.consultar("""
                SELECT CONCAT(i.tipo, '') AS tipo, COUNT(*) AS total
                  FROM incidencia_mesa i WHERE i.id_proceso = ?
                 GROUP BY i.tipo ORDER BY total DESC
                """, idProceso));

        boolean concluido = List.of("CERRADO", "FINALIZADO", "ANULADO").contains(estado);
        Map<String, Object> acciones = new LinkedHashMap<>();
        boolean puedeGenerar = concluido && abiertas == 0 && instaladas > 0 && !resuelto;
        acciones.put("generar", ceunp && puedeGenerar);
        acciones.put("motivoNoGenerar", puedeGenerar ? null
                : resuelto ? "Las multas ya fueron determinadas por la Resolución " + reporte.get("numeroResolucion") + "."
                : !concluido ? "Las multas se generan con la votación concluida (CUS14, «Concluir votación»)."
                : instaladas == 0 ? "Ninguna mesa del proceso se instaló: no hubo sufragio que omitir."
                : abiertas + " mesa(s) aún no cierran su sufragio (CUS11).");
        acciones.put("emitirResolucion", ceunp && "GENERADO".equals(estadoReporte) && !desactualizado);
        long sinNotificar = multas.stream().filter(m -> m.get("fechaNotificacion") == null).count();
        acciones.put("notificar", ceunp && resuelto && sinNotificar > 0);
        acciones.put("descargo", ceunp && resuelto);
        acciones.put("pagar", ceunp && resuelto);
        respuesta.put("acciones", acciones);

        List<String> avisos = new ArrayList<>();
        if (reporte == null && puedeGenerar) {
            avisos.add("El reporte de omisos está listo: genere las multas para que el Pleno las determine (RF103, RF104).");
        }
        if (desactualizado) {
            avisos.add(otraUit ? "La UIT o los porcentajes cambiaron desde que se generaron las multas: vuelva a generarlas antes de la resolución (RF105)."
                    : "El reporte generado no coincide con los omisos actuales: vuelva a generar las multas.");
        } else if ("GENERADO".equals(estadoReporte)) {
            avisos.add("Multas generadas sin resolución: el Pleno debe emitir la resolución que las determina (RN36).");
        }
        if (resuelto && sinNotificar > 0) {
            avisos.add(sinNotificar + " multa(s) sin notificar al docente.");
        }
        long asistieron = multas.stream().filter(m -> numero(m.get("asistioSinVotar")) == 1 && "PENDIENTE".equals(texto(m.get("estadoPago")))).count();
        if (asistieron > 0) {
            avisos.add(asistieron + " omiso(s) asistieron a la mesa y no votaron (CUS10 A3): el CEUNP resuelve si los justifica (Disp. Final 5.ª).");
        }
        respuesta.put("avisos", avisos);
        respuesta.put("soloLectura", !ceunp);
        return respuesta;
    }

    Map<String, Object> parametros() {
        Map<String, Object> p = new LinkedHashMap<>();
        BigDecimal uit = decimalParametro("UIT");
        BigDecimal pe = decimalParametro("MULTA_ELECTOR_OMISO_PCT");
        BigDecimal pm = decimalParametro("MULTA_MIEMBRO_MESA_OMISO_PCT");
        p.put("uit", uit);
        p.put("pctElector", pe);
        p.put("pctMiembro", pm);
        p.put("montoElector", monto(uit, pe));
        p.put("montoMiembro", monto(uit, pm));
        p.put("quorumPleno", parametro("CEUNP_QUORUM_PLENO", 5));
        p.put("plazoJustificacion", parametro("MULTA_PLAZO_JUSTIFICACION_DIAS", 10));
        return p;
    }

    /** 4 consultarNoVotaron() y 5 consultarInasistentes(), con el monto que tendría la multa hoy. */
    List<Map<String, Object>> omisos(Integer idProceso, Map<String, Object> parametros) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT o.id_docente, o.motivo, o.id_mesa, m.numero_mesa, o.rol_mesa, o.asistio_sin_votar, d.dni,
                       CONCAT(d.apellidos, ', ', d.nombres) AS docente, f.nombre AS facultad, dp.nombre AS departamento,
                       CONCAT(d.categoria, '') AS categoria, d.email
                  FROM v_omisos_proceso o
                  JOIN docente d  ON d.id_docente = o.id_docente
                  JOIN facultad f ON f.id_facultad = d.id_facultad
                  LEFT JOIN departamento dp  ON dp.id_departamento = d.id_departamento
                  LEFT JOIN mesa_electoral m ON m.id_mesa = o.id_mesa
                 WHERE o.id_proceso = ?
                 ORDER BY FIELD(o.motivo, 'OMISO_MESA', 'OMISO_VOTACION'), d.apellidos, d.nombres
                """, idProceso);
        for (Map<String, Object> o : filas) {
            o.put("montoEstimado", "OMISO_MESA".equals(texto(o.get("motivo"))) ? parametros.get("montoMiembro") : parametros.get("montoElector"));
        }
        return filas;
    }

    List<Map<String, Object>> multas(Integer idProceso) {
        return dao.consultar("""
                SELECT id_multa, id_docente, dni, docente, facultad, departamento, categoria, email, motivo, id_mesa, numero_mesa,
                       rol_mesa, asistio_sin_votar, uit_referencia, porcentaje_uit, monto, estado_pago, fecha_generacion,
                       fecha_notificacion, medio_notificacion, documento_notificacion, fecha_pago, numero_recibo, observacion,
                       descargos, tipo_descargo, decision_descargo, resolucion_descargo, limite_justificacion
                  FROM v_multas_detalle WHERE id_proceso = ?
                 ORDER BY FIELD(motivo, 'OMISO_MESA', 'OMISO_VOTACION'), docente
                """, idProceso);
    }

    /** Reporte del proceso sin el contenido (la resolución completa se pide aparte). */
    Map<String, Object> reporte(Integer idProceso) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT r.id_reporte, r.estado, r.uit_referencia, r.pct_elector, r.pct_miembro, r.omisos_votacion, r.omisos_mesa,
                       r.monto_total, r.veces_generado, r.fecha_generacion, ug.username AS generado_por, r.numero_resolucion,
                       r.fundamento, r.miembros_pleno, r.fecha_resolucion, ur.username AS resuelto_por, r.hash_integridad,
                       IF(r.contenido_json IS NULL, NULL, IF(SHA2(r.contenido_json, 256) = r.hash_integridad, 1, 0)) AS resolucion_integra
                  FROM reporte_multas r
                  LEFT JOIN usuario ug ON ug.id_usuario = r.id_usuario_generacion
                  LEFT JOIN usuario ur ON ur.id_usuario = r.id_usuario_resolucion
                 WHERE r.id_proceso = ?
                """, idProceso);
        return filas.isEmpty() ? null : filas.get(0);
    }

    static Map<String, Object> resumen(List<Map<String, Object>> multas) {
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("total", multas.size());
        r.put("omisosVotacion", multas.stream().filter(m -> "OMISO_VOTACION".equals(texto(m.get("motivo")))).count());
        r.put("omisosMesa", multas.stream().filter(m -> "OMISO_MESA".equals(texto(m.get("motivo")))).count());
        for (String estado : List.of("PENDIENTE", "PAGADA", "JUSTIFICADA", "EXONERADA")) {
            List<Map<String, Object>> grupo = multas.stream().filter(m -> estado.equals(texto(m.get("estadoPago")))).toList();
            String clave = estado.toLowerCase();
            r.put(clave, grupo.size());
            r.put("monto" + Character.toUpperCase(clave.charAt(0)) + clave.substring(1), suma(grupo));
        }
        r.put("montoTotal", suma(multas));
        r.put("notificadas", multas.stream().filter(m -> m.get("fechaNotificacion") != null).count());
        return r;
    }

    // ─── Multa y resolución ──────────────────────────────────────────────────

    /** Multa con sus descargos (9 justificar · 11 confirmar). */
    public Map<String, Object> multa(Integer idMulta) {
        verificarInstalacion();
        List<Map<String, Object>> filas = dao.consultar("SELECT * FROM v_multas_detalle WHERE id_multa = ?", idMulta);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Multa no encontrada.");
        }
        Map<String, Object> m = filas.get(0);
        m.put("descargosLista", dao.consultar("""
                SELECT j.id_justificacion, CONCAT(j.tipo, '') AS tipo, CONCAT(j.causal, '') AS causal, j.sustento, j.documento,
                       j.fecha_presentacion, j.decision, j.fundamento, j.numero_resolucion, j.miembros_pleno, j.fecha_resolucion,
                       u.username AS registrado_por
                  FROM multa_justificacion j LEFT JOIN usuario u ON u.id_usuario = j.id_usuario
                 WHERE j.id_multa = ? ORDER BY j.id_justificacion
                """, idMulta));
        return m;
    }

    /** 7 mostrarReporteMultas(): la resolución con su contenido (huella SHA-256) para imprimir. */
    public Map<String, Object> resolucion(Integer idProceso) {
        verificarInstalacion();
        Map<String, Object> r = reporte(idProceso);
        if (r == null || !"RESUELTO".equals(texto(r.get("estado")))) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El proceso aún no tiene resolución de multas.");
        }
        List<Map<String, Object>> contenido = dao.consultar("SELECT contenido_json FROM reporte_multas WHERE id_proceso = ?", idProceso);
        r.put("documento", contenido.isEmpty() ? null : leerJson(contenido.get(0).get("contenidoJson")));
        return r;
    }

    Map<String, Object> respuesta(String mensaje, Integer idProceso, Usuario usuario) {
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("mensaje", mensaje);
        r.put("detalle", detalle(idProceso, usuario));
        return r;
    }

    // ─── Utilidades ──────────────────────────────────────────────────────────

    int parametro(String clave, int porDefecto) {
        BigDecimal valor = decimalParametro(clave);
        return valor == null ? porDefecto : valor.setScale(0, RoundingMode.HALF_UP).intValue();
    }

    private BigDecimal decimalParametro(String clave) {
        List<Map<String, Object>> filas = dao.consultar("SELECT valor FROM parametro_global WHERE clave = ?", clave);
        if (filas.isEmpty()) {
            return null;
        }
        try {
            return new BigDecimal(String.valueOf(filas.get(0).get("valor")).trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private static BigDecimal monto(BigDecimal uit, BigDecimal pct) {
        return uit == null || pct == null ? null : uit.multiply(pct).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
    }

    private static BigDecimal suma(List<Map<String, Object>> filas) {
        return filas.stream().map(f -> decimal(f.get("monto"))).filter(v -> v != null).reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private static BigDecimal decimal(Object valor) {
        if (valor instanceof BigDecimal b) {
            return b;
        }
        if (valor instanceof Number n) {
            return new BigDecimal(n.toString());
        }
        return null;
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
