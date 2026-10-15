package pe.unp.elecciones.electoral.convocatoria;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.service.Bitacora;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS01 · Lecturas compartidas por los tres controles del caso de uso
 * (RegistrarProceso, AgregarCargo y PublicarConvocatoria): la convocatoria,
 * sus cargos, los catálogos de la pantalla y los requisitos para publicarla.
 */
@Service
public class ConvocatoriaConsulta {

    /** RN02: la convocatoria se publica entre 30 y 45 días naturales antes del sufragio. */
    static final int DIAS_MINIMOS = 30;
    static final int DIAS_MAXIMOS = 45;

    private static final String SELECT_PROCESO = """
            SELECT p.id_proceso AS id, p.nombre, p.tipo, p.estado, p.quorum_minimo,
                   DATE_FORMAT(p.fecha_convocatoria, '%Y-%m-%d') AS fecha_convocatoria,
                   p.fecha_limite_inscripcion, p.fecha_inicio, p.fecha_fin, p.fecha_creacion,
                   DATEDIFF(DATE(p.fecha_inicio), p.fecha_convocatoria) AS dias_anticipacion,
                   (SELECT COUNT(*) FROM cargo_electoral c WHERE c.id_proceso = p.id_proceso) AS total_cargos
              FROM proceso_electoral p
            """;

    private final ProcedimientoDao dao;
    private final Bitacora bitacora;

    public ConvocatoriaConsulta(ProcedimientoDao dao, Bitacora bitacora) {
        this.dao = dao;
        this.bitacora = bitacora;
    }

    /** Todas las convocatorias, la más reciente primero. */
    public List<Map<String, Object>> listar() {
        return dao.consultar(SELECT_PROCESO + " ORDER BY p.fecha_creacion DESC, p.id_proceso DESC");
    }

    public Map<String, Object> proceso(Integer idProceso) {
        List<Map<String, Object>> filas = dao.consultar(SELECT_PROCESO + " WHERE p.id_proceso = ?", idProceso);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "La convocatoria no existe.");
        }
        return filas.get(0);
    }

    /** Cargos del proceso con su jurisdicción y las categorías que votan / postulan (RF03). */
    public List<Map<String, Object>> cargos(Integer idProceso) {
        return dao.consultar("""
                SELECT c.id_cargo AS id, c.nombre, c.nivel_jurisdiccion, c.id_jurisdiccion,
                       CASE c.nivel_jurisdiccion
                            WHEN 'FACULTAD' THEN f.nombre
                            WHEN 'DEPARTAMENTO' THEN d.nombre
                       END AS jurisdiccion,
                       (SELECT GROUP_CONCAT(cp.categoria ORDER BY FIELD(cp.categoria, 'PRINCIPAL', 'ASOCIADO', 'AUXILIAR'))
                          FROM cargo_categoria_permitida cp
                         WHERE cp.id_cargo = c.id_cargo AND cp.puede_votar = 1) AS categorias_votan,
                       (SELECT GROUP_CONCAT(cp.categoria ORDER BY FIELD(cp.categoria, 'PRINCIPAL', 'ASOCIADO', 'AUXILIAR'))
                          FROM cargo_categoria_permitida cp
                         WHERE cp.id_cargo = c.id_cargo AND cp.puede_postular = 1) AS categorias_postulan,
                       (SELECT COUNT(*) FROM lista_electoral l WHERE l.id_cargo = c.id_cargo) AS total_listas
                  FROM cargo_electoral c
                  LEFT JOIN facultad f
                         ON c.nivel_jurisdiccion = 'FACULTAD' AND f.id_facultad = c.id_jurisdiccion
                  LEFT JOIN departamento d
                         ON c.nivel_jurisdiccion = 'DEPARTAMENTO' AND d.id_departamento = c.id_jurisdiccion
                 WHERE c.id_proceso = ?
                 ORDER BY FIELD(c.nivel_jurisdiccion, 'UNIVERSIDAD', 'FACULTAD', 'DEPARTAMENTO'), c.id_cargo
                """, idProceso);
    }

    /** Detalle completo que pinta la pantalla: proceso + cargos + requisitos para publicar. */
    public Map<String, Object> detalle(Integer idProceso) {
        Map<String, Object> proceso = proceso(idProceso);
        List<Map<String, Object>> cargos = cargos(idProceso);
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("proceso", proceso);
        respuesta.put("cargos", cargos);
        respuesta.put("editable", "CREADO".equals(proceso.get("estado")));
        respuesta.put("requisitos", requisitosPublicacion(proceso, cargos.size()));
        return respuesta;
    }

    /** Catálogos para los combos de la pantalla. */
    public Map<String, Object> catalogos() {
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("cargos", dao.consultar("""
                SELECT id_catalogo_cargo AS id, nombre_cargo AS nombre, nivel
                  FROM catalogo_cargo
                 WHERE activo = 1
                 ORDER BY FIELD(nivel, 'UNIVERSIDAD', 'FACULTAD', 'DEPARTAMENTO'), id_catalogo_cargo
                """));
        respuesta.put("facultades", dao.consultar(
                "SELECT id_facultad AS id, nombre FROM facultad ORDER BY nombre"));
        respuesta.put("departamentos", dao.consultar(
                "SELECT id_departamento AS id, id_facultad, nombre FROM departamento ORDER BY nombre"));
        return respuesta;
    }

    /** Otro proceso que ya esté en INSCRIPCION o VOTACION (solo puede haber uno en curso). */
    public Map<String, Object> procesoEnCurso(Integer excluirIdProceso) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT id_proceso AS id, nombre, estado
                  FROM proceso_electoral
                 WHERE estado IN ('INSCRIPCION', 'VOTACION') AND id_proceso <> ?
                 ORDER BY id_proceso LIMIT 1
                """, excluirIdProceso == null ? 0 : excluirIdProceso);
        return filas.isEmpty() ? null : filas.get(0);
    }

    /**
     * Requisitos que debe cumplir la convocatoria para pasar de CREADO a INSCRIPCION.
     * La pantalla los muestra como lista de verificación y PublicarConvocatoria los exige.
     */
    public List<Map<String, Object>> requisitosPublicacion(Map<String, Object> proceso, int totalCargos) {
        List<Map<String, Object>> requisitos = new ArrayList<>();

        requisitos.add(requisito("ESTADO", "La convocatoria está en estado CREADO.",
                "CREADO".equals(proceso.get("estado"))));

        Object dias = proceso.get("diasAnticipacion");
        boolean rn02 = dias instanceof Number n && n.intValue() >= DIAS_MINIMOS && n.intValue() <= DIAS_MAXIMOS;
        requisitos.add(requisito("RN02",
                "RN02: la convocatoria se publica entre " + DIAS_MINIMOS + " y " + DIAS_MAXIMOS
                        + " días antes del sufragio" + (dias == null ? "." : " (actual: " + dias + " días)."),
                rn02));

        boolean limite = proceso.get("fechaLimiteInscripcion") != null;
        requisitos.add(requisito("CRONOGRAMA", "El cronograma tiene fecha límite de inscripción de listas.", limite));

        Object inicio = proceso.get("fechaInicio");
        boolean futuro = inicio instanceof LocalDateTime fecha && fecha.isAfter(LocalDateTime.now());
        requisitos.add(requisito("FECHA_FUTURA", "El inicio del sufragio aún no ha pasado.", futuro));

        requisitos.add(requisito("CARGOS", "Hay al menos un cargo electoral registrado ("
                + totalCargos + " registrado" + (totalCargos == 1 ? "" : "s") + ").", totalCargos > 0));

        Object id = proceso.get("id");
        Map<String, Object> enCurso = procesoEnCurso(id instanceof Number n ? n.intValue() : null);
        requisitos.add(requisito("EXCLUSIVIDAD", enCurso == null
                ? "No hay otro proceso electoral en curso."
                : "Ya hay un proceso en curso: " + enCurso.get("nombre") + " (" + enCurso.get("estado") + ").",
                enCurso == null));
        return requisitos;
    }

    /** Registra una acción del caso de uso en la bitácora (log_auditoria). */
    public void auditar(Integer idUsuario, Integer idProceso, String accion, Map<String, Object> detalle) {
        bitacora.registrar(idUsuario, idProceso, accion, detalle);
    }

    private static Map<String, Object> requisito(String codigo, String descripcion, boolean cumple) {
        Map<String, Object> fila = new LinkedHashMap<>();
        fila.put("codigo", codigo);
        fila.put("descripcion", descripcion);
        fila.put("cumple", cumple);
        return fila;
    }
}
