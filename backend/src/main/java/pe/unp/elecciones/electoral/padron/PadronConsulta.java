package pe.unp.elecciones.electoral.padron;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS02 · Lecturas compartidas por los controles del caso de uso
 * (ImportarDocentes, FiltrarHabilitados y AprobarPadron).
 */
@Service
public class PadronConsulta {

    /**
     * Reglas de depuración (procesarReglas). Devuelve el motivo por el que el docente
     * NO puede votar, o NULL si está habilitado. Se usa tanto para actualizar la
     * habilitación como para mostrar la lista depurada, así ambas coinciden siempre.
     */
    static final String MOTIVO_SQL = """
            CASE
              WHEN d.estado <> 'ACTIVO'
                   THEN CONCAT('RN03: docente en estado ', d.estado)
              WHEN d.dni NOT REGEXP '^[0-9]{8}$'
                   THEN 'RN05: DNI inválido (debe tener 8 dígitos)'
              WHEN TRIM(d.nombres) = '' OR TRIM(d.apellidos) = ''
                   THEN 'Datos incompletos: nombres o apellidos'
              WHEN TRIM(d.dedicacion) = ''
                   THEN 'Datos incompletos: dedicación'
              ELSE NULL
            END""";

    /** Estados del proceso en los que el padrón aún puede (re)generarse (sp_generar_padron). */
    static final List<String> ESTADOS_EDITABLES = List.of("CREADO", "INSCRIPCION");

    private final ProcedimientoDao dao;

    public PadronConsulta(ProcedimientoDao dao) {
        this.dao = dao;
    }

    // ─── Docentes ─────────────────────────────────────────────────────────────

    /** Totales del registro de docentes y fechas de la última importación / depuración. */
    public Map<String, Object> resumenDocentes() {
        Map<String, Object> resumen = new LinkedHashMap<>(dao.consultar("""
                SELECT COUNT(*) AS total,
                       COALESCE(SUM(habilitado_para_votar = 1), 0) AS habilitados,
                       COALESCE(SUM(habilitado_para_votar = 0), 0) AS inhabilitados,
                       COALESCE(SUM(estado = 'ACTIVO'), 0) AS activos,
                       COALESCE(SUM(estado = 'LICENCIA'), 0) AS licencia,
                       COALESCE(SUM(estado = 'SUSPENDIDO'), 0) AS suspendidos,
                       COALESCE(SUM(estado = 'INACTIVO'), 0) AS inactivos
                  FROM docente
                """).get(0));
        resumen.put("ultimaImportacion", ultimaAccion("IMPORTAR_DOCENTES"));
        resumen.put("ultimaDepuracion", ultimaAccion("DEPURAR_PADRON"));
        resumen.put("depuracionVigente", depuracionVigente());
        return resumen;
    }

    /** Lista depurada: cada docente con su habilitación y el motivo si no puede votar. */
    public List<Map<String, Object>> listaDepurada() {
        return dao.consultar("""
                SELECT d.id_docente AS id, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS docente,
                       d.categoria, d.dedicacion, d.estado, f.nombre AS facultad, dp.nombre AS departamento,
                       d.habilitado_para_votar AS habilitado,
                       """ + MOTIVO_SQL + """
                 AS motivo
                  FROM docente d
                  JOIN facultad f ON f.id_facultad = d.id_facultad
                  JOIN departamento dp ON dp.id_departamento = d.id_departamento
                 ORDER BY d.habilitado_para_votar, d.apellidos, d.nombres
                """);
    }

    /** Agrupa a los inhabilitados por motivo, para el resumen de la depuración. */
    public List<Map<String, Object>> motivosInhabilitacion() {
        return dao.consultar("SELECT motivo, COUNT(*) AS total FROM (SELECT " + MOTIVO_SQL
                + " AS motivo FROM docente d) x WHERE motivo IS NOT NULL GROUP BY motivo ORDER BY total DESC");
    }

    /** Fecha y hora de la última vez que se ejecutó una acción, o null. */
    public LocalDateTime ultimaAccion(String accion) {
        List<Map<String, Object>> filas = dao.consultar(
                "SELECT MAX(fecha_hora) AS fecha FROM log_auditoria WHERE accion = ?", accion);
        Object fecha = filas.isEmpty() ? null : filas.get(0).get("fecha");
        return fecha instanceof LocalDateTime f ? f : null;
    }

    /** La depuración es vigente si se hizo después de la última importación. */
    public boolean depuracionVigente() {
        LocalDateTime depuracion = ultimaAccion("DEPURAR_PADRON");
        LocalDateTime importacion = ultimaAccion("IMPORTAR_DOCENTES");
        return depuracion != null && (importacion == null || !depuracion.isBefore(importacion));
    }

    // ─── Procesos y padrón ────────────────────────────────────────────────────

    private static final String SELECT_PROCESO = """
            SELECT p.id_proceso AS id, p.nombre, p.estado, p.fecha_inicio,
                   (SELECT COUNT(*) FROM cargo_electoral c WHERE c.id_proceso = p.id_proceso) AS total_cargos,
                   (SELECT COUNT(*) FROM padron_electoral pe WHERE pe.id_proceso = p.id_proceso) AS registros_padron,
                   (SELECT COUNT(DISTINCT pe.id_docente) FROM padron_electoral pe
                     WHERE pe.id_proceso = p.id_proceso) AS electores_padron,
                   (SELECT MAX(pe.fecha_generacion) FROM padron_electoral pe
                     WHERE pe.id_proceso = p.id_proceso) AS fecha_padron,
                   (SELECT COUNT(*) FROM mesa_electoral m WHERE m.id_proceso = p.id_proceso) AS total_mesas
              FROM proceso_electoral p
            """;

    public List<Map<String, Object>> procesos() {
        return dao.consultar(SELECT_PROCESO
                + " WHERE p.estado <> 'ANULADO' ORDER BY p.fecha_creacion DESC, p.id_proceso DESC");
    }

    public Map<String, Object> proceso(Integer idProceso) {
        List<Map<String, Object>> filas = dao.consultar(SELECT_PROCESO + " WHERE p.id_proceso = ?", idProceso);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El proceso electoral no existe.");
        }
        return filas.get(0);
    }

    /**
     * Electores por cargo: «previstos» son los que entrarían al padrón con los datos
     * actuales (mismas reglas que sp_generar_padron) y «enPadron» los ya aprobados.
     */
    public List<Map<String, Object>> electoresPorCargo(Integer idProceso) {
        return dao.consultar("""
                SELECT c.id_cargo, c.nombre AS cargo, c.nivel_jurisdiccion,
                       CASE c.nivel_jurisdiccion
                            WHEN 'FACULTAD' THEN f.nombre
                            WHEN 'DEPARTAMENTO' THEN dp.nombre
                       END AS jurisdiccion,
                       (SELECT COUNT(*)
                          FROM docente d
                         WHERE d.estado = 'ACTIVO' AND d.habilitado_para_votar = 1
                           AND ( c.nivel_jurisdiccion = 'UNIVERSIDAD'
                              OR (c.nivel_jurisdiccion = 'FACULTAD'     AND d.id_facultad     = c.id_jurisdiccion)
                              OR (c.nivel_jurisdiccion = 'DEPARTAMENTO' AND d.id_departamento = c.id_jurisdiccion) )
                           AND ( NOT EXISTS (SELECT 1 FROM cargo_categoria_permitida x WHERE x.id_cargo = c.id_cargo)
                              OR EXISTS (SELECT 1 FROM cargo_categoria_permitida x
                                          WHERE x.id_cargo = c.id_cargo AND x.categoria = d.categoria
                                            AND x.puede_votar = 1) )) AS previstos,
                       (SELECT COUNT(*) FROM padron_electoral pe
                         WHERE pe.id_cargo = c.id_cargo AND pe.habilitado_para_votar = 1) AS en_padron
                  FROM cargo_electoral c
                  LEFT JOIN facultad f
                         ON c.nivel_jurisdiccion = 'FACULTAD' AND f.id_facultad = c.id_jurisdiccion
                  LEFT JOIN departamento dp
                         ON c.nivel_jurisdiccion = 'DEPARTAMENTO' AND dp.id_departamento = c.id_jurisdiccion
                 WHERE c.id_proceso = ?
                 ORDER BY FIELD(c.nivel_jurisdiccion, 'UNIVERSIDAD', 'FACULTAD', 'DEPARTAMENTO'), c.id_cargo
                """, idProceso);
    }

    /** Padrón definitivo del proceso (vista v_padron_detalle). */
    public List<Map<String, Object>> padron(Integer idProceso) {
        proceso(idProceso);
        return dao.consultar("""
                SELECT id_cargo, cargo, id_docente, dni, docente, categoria, facultad,
                       habilitado_para_votar AS habilitado, ya_voto, numero_mesa
                  FROM v_padron_detalle
                 WHERE id_proceso = ?
                 ORDER BY cargo, docente
                """, idProceso);
    }

    /** Detalle para la pantalla: proceso, electores por cargo y requisitos para aprobar. */
    public Map<String, Object> detalleProceso(Integer idProceso) {
        Map<String, Object> proceso = proceso(idProceso);
        List<Map<String, Object>> cargos = electoresPorCargo(idProceso);
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("proceso", proceso);
        respuesta.put("cargos", cargos);
        respuesta.put("requisitos", requisitosAprobacion(proceso, cargos));
        return respuesta;
    }

    /** Requisitos para generar el padrón definitivo; AprobarPadron los exige todos. */
    public List<Map<String, Object>> requisitosAprobacion(Map<String, Object> proceso, List<Map<String, Object>> cargos) {
        List<Map<String, Object>> requisitos = new ArrayList<>();
        Object estado = proceso.get("estado");
        requisitos.add(requisito("ESTADO",
                "El proceso está en CREADO o INSCRIPCION (estado actual: " + estado + ").",
                ESTADOS_EDITABLES.contains(String.valueOf(estado))));
        requisitos.add(requisito("CARGOS", "El proceso tiene cargos a elegir (CUS01).", !cargos.isEmpty()));
        requisitos.add(requisito("DEPURADO",
                "El padrón de docentes se depuró después de la última importación.", depuracionVigente()));
        int mesas = numero(proceso.get("totalMesas"));
        requisitos.add(requisito("SIN_MESAS", mesas == 0
                ? "Aún no hay mesas de sufragio (el padrón puede regenerarse)."
                : "Ya existen " + mesas + " mesas: el padrón no puede regenerarse.", mesas == 0));
        boolean todosConElectores = !cargos.isEmpty()
                && cargos.stream().allMatch(c -> numero(c.get("previstos")) > 0);
        requisitos.add(requisito("ELECTORES", "Cada cargo tiene al menos un elector habilitado.", todosConElectores));
        return requisitos;
    }

    static int numero(Object valor) {
        return valor instanceof Number n ? n.intValue() : 0;
    }

    private static Map<String, Object> requisito(String codigo, String descripcion, boolean cumple) {
        Map<String, Object> fila = new LinkedHashMap<>();
        fila.put("codigo", codigo);
        fila.put("descripcion", descripcion);
        fila.put("cumple", cumple);
        return fila;
    }
}
