package pe.unp.elecciones.electoral.inscripcion;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS03 · Lecturas compartidas por RegistrarDatosLista, ValidarCandidato y AgregarCandidato:
 * procesos en inscripción, cargos con sus listas y candidatos, y el estado del plazo (RN13).
 */
@Service
public class InscripcionConsulta {

    private static final String SELECT_PROCESO = """
            SELECT p.id_proceso AS id, p.nombre, p.estado, p.fecha_limite_inscripcion, p.fecha_inicio,
                   (p.estado = 'INSCRIPCION'
                    AND (p.fecha_limite_inscripcion IS NULL OR NOW() <= p.fecha_limite_inscripcion)) AS plazo_abierto,
                   (SELECT COUNT(*) FROM cargo_electoral c WHERE c.id_proceso = p.id_proceso) AS total_cargos,
                   (SELECT COUNT(*) FROM lista_electoral l JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                     WHERE c.id_proceso = p.id_proceso) AS total_listas
              FROM proceso_electoral p
            """;

    private final ProcedimientoDao dao;

    public InscripcionConsulta(ProcedimientoDao dao) {
        this.dao = dao;
    }

    /** Procesos que ya publicaron su convocatoria (de INSCRIPCION en adelante). */
    public List<Map<String, Object>> procesos() {
        return dao.consultar(SELECT_PROCESO + """
                 WHERE p.estado IN ('INSCRIPCION', 'VOTACION', 'CERRADO', 'FINALIZADO')
                 ORDER BY (p.estado = 'INSCRIPCION') DESC, p.fecha_creacion DESC
                """);
    }

    public Map<String, Object> proceso(Integer idProceso) {
        List<Map<String, Object>> filas = dao.consultar(SELECT_PROCESO + " WHERE p.id_proceso = ?", idProceso);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El proceso electoral no existe.");
        }
        return filas.get(0);
    }

    /** Vista completa del proceso: cargos → listas → candidatos, con los roles que faltan (RN10). */
    public Map<String, Object> detalle(Integer idProceso) {
        Map<String, Object> proceso = proceso(idProceso);

        List<Map<String, Object>> cargos = dao.consultar("""
                SELECT c.id_cargo AS id, c.nombre, c.nivel_jurisdiccion,
                       CASE c.nivel_jurisdiccion
                            WHEN 'FACULTAD' THEN f.nombre
                            WHEN 'DEPARTAMENTO' THEN dp.nombre
                       END AS jurisdiccion,
                       (SELECT GROUP_CONCAT(cp.categoria ORDER BY FIELD(cp.categoria, 'PRINCIPAL', 'ASOCIADO', 'AUXILIAR'))
                          FROM cargo_categoria_permitida cp
                         WHERE cp.id_cargo = c.id_cargo AND cp.puede_postular = 1) AS categorias_postulan
                  FROM cargo_electoral c
                  LEFT JOIN facultad f ON c.nivel_jurisdiccion = 'FACULTAD' AND f.id_facultad = c.id_jurisdiccion
                  LEFT JOIN departamento dp ON c.nivel_jurisdiccion = 'DEPARTAMENTO' AND dp.id_departamento = c.id_jurisdiccion
                 WHERE c.id_proceso = ?
                 ORDER BY FIELD(c.nivel_jurisdiccion, 'UNIVERSIDAD', 'FACULTAD', 'DEPARTAMENTO'), c.id_cargo
                """, idProceso);

        List<Map<String, Object>> listas = dao.consultar("""
                SELECT l.id_lista AS id, l.id_cargo, l.nombre, l.simbolo, l.url_plan_gobierno, l.estado,
                       l.fecha_inscripcion, l.motivo_exclusion,
                       (SELECT COUNT(*) FROM tacha t JOIN candidato ca ON ca.id_candidato = t.id_candidato
                         WHERE ca.id_lista = l.id_lista) AS total_tachas
                  FROM lista_electoral l
                  JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                 WHERE c.id_proceso = ?
                 ORDER BY l.fecha_inscripcion, l.id_lista
                """, idProceso);

        List<Map<String, Object>> candidatos = dao.consultar("""
                SELECT ca.id_candidato AS id, ca.id_lista, ca.id_docente, d.dni,
                       CONCAT(d.apellidos, ', ', d.nombres) AS docente, d.categoria, d.grado_academico,
                       ca.rol_en_lista, ca.estado_validacion, ca.url_hoja_vida, ca.fecha_inscripcion,
                       (SELECT COUNT(*) FROM tacha t WHERE t.id_candidato = ca.id_candidato) AS total_tachas
                  FROM candidato ca
                  JOIN docente d ON d.id_docente = ca.id_docente
                  JOIN lista_electoral l ON l.id_lista = ca.id_lista
                  JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                 WHERE c.id_proceso = ?
                 ORDER BY ca.id_candidato
                """, idProceso);

        for (Map<String, Object> cargo : cargos) {
            String nombreCargo = (String) cargo.get("nombre");
            List<Map<String, Object>> roles = RolesCargo.comoMapa(nombreCargo);
            cargo.put("roles", roles);
            List<Map<String, Object>> listasCargo = new ArrayList<>();
            for (Map<String, Object> lista : listas) {
                if (!lista.get("idCargo").equals(cargo.get("id"))) {
                    continue;
                }
                List<Map<String, Object>> deLista = candidatos.stream()
                        .filter(c -> c.get("idLista").equals(lista.get("id")))
                        .toList();
                lista.put("candidatos", deLista);
                Set<String> cubiertos = deLista.stream()
                        .filter(c -> !"EXCLUIDO".equals(c.get("estadoValidacion")))
                        .map(c -> String.valueOf(c.get("rolEnLista")))
                        .collect(Collectors.toSet());
                List<String> faltan = roles.stream()
                        .map(r -> String.valueOf(r.get("codigo")))
                        .filter(r -> !cubiertos.contains(r))
                        .toList();
                lista.put("rolesFaltantes", faltan);
                lista.put("completa", faltan.isEmpty());
                listasCargo.add(lista);
            }
            cargo.put("listas", listasCargo);
        }

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("proceso", proceso);
        respuesta.put("cargos", cargos);
        return respuesta;
    }

    /** Lista con su cargo y proceso; lanza 404 si no existe. */
    public Map<String, Object> lista(Integer idLista) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT l.id_lista AS id, l.nombre, l.estado, l.id_cargo, c.nombre AS cargo,
                       c.nivel_jurisdiccion, c.id_jurisdiccion, c.id_proceso,
                       p.estado AS estado_proceso, p.fecha_limite_inscripcion
                  FROM lista_electoral l
                  JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                  JOIN proceso_electoral p ON p.id_proceso = c.id_proceso
                 WHERE l.id_lista = ?
                """, idLista);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "La lista electoral no existe.");
        }
        return filas.get(0);
    }

    /**
     * RN13: la lista solo se modifica con el proceso en INSCRIPCION, dentro del plazo
     * y mientras el CEUNP no la haya calificado (estado INSCRITA).
     */
    public void exigirListaModificable(Map<String, Object> lista) {
        if (!"INSCRIPCION".equals(lista.get("estadoProceso"))) {
            throw badRequest("El proceso no está en etapa de INSCRIPCION.");
        }
        if (plazoVencido(lista.get("fechaLimiteInscripcion"))) {
            throw badRequest("RN13: venció el plazo de inscripción de listas.");
        }
        if (!"INSCRITA".equals(lista.get("estado"))) {
            throw badRequest("RN12: la lista ya fue calificada (" + lista.get("estado") + ") y no admite cambios.");
        }
    }

    static boolean plazoVencido(Object limite) {
        return limite instanceof LocalDateTime fecha && LocalDateTime.now().isAfter(fecha);
    }

    static ResponseStatusException badRequest(String mensaje) {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, mensaje);
    }
}
