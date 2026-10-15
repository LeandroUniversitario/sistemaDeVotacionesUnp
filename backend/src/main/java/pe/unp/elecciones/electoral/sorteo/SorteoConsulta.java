package pe.unp.elecciones.electoral.sorteo;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/** CUS06 · Lecturas compartidas por FiltrarElegibles, EjecutarSorteo y GrabarMiembrosMesa. */
@Service
public class SorteoConsulta {

    /** Los sorteos (mesas y cédula) se hacen antes de la votación. */
    static final Set<String> ESTADOS_SORTEO = Set.of("CREADO", "INSCRIPCION");

    private final ProcedimientoDao dao;

    public SorteoConsulta(ProcedimientoDao dao) {
        this.dao = dao;
    }

    public List<Map<String, Object>> procesos() {
        return dao.consultar("""
                SELECT p.id_proceso AS id, p.nombre, p.estado, p.fecha_inicio,
                       (SELECT COUNT(*) FROM mesa_electoral m WHERE m.id_proceso = p.id_proceso) AS total_mesas
                  FROM proceso_electoral p
                 WHERE p.estado <> 'ANULADO'
                 ORDER BY (p.estado IN ('CREADO', 'INSCRIPCION')) DESC, p.fecha_creacion DESC
                """);
    }

    public Map<String, Object> proceso(Integer idProceso) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT p.id_proceso AS id, p.nombre, p.estado, p.fecha_inicio,
                       (SELECT COUNT(DISTINCT pe.id_docente) FROM padron_electoral pe
                         WHERE pe.id_proceso = p.id_proceso AND pe.habilitado_para_votar = 1) AS electores_padron
                  FROM proceso_electoral p WHERE p.id_proceso = ?
                """, idProceso);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El proceso electoral no existe.");
        }
        Map<String, Object> p = filas.get(0);
        p.put("admiteSorteo", ESTADOS_SORTEO.contains(String.valueOf(p.get("estado"))));
        return p;
    }

    /** Mesas del proceso con su estado de sorteo y cuántos elegibles tiene cada una. */
    public List<Map<String, Object>> mesas(Integer idProceso) {
        return dao.consultar("""
                SELECT v.id_mesa AS id, v.numero_mesa, v.ubicacion, v.estado, v.total_electores,
                       v.fecha_sorteo, IF(v.semilla_sorteo = 'PENDIENTE', NULL, v.semilla_sorteo) AS semilla,
                       v.miembros,
                       (SELECT COUNT(DISTINCT e.id_docente) FROM v_elegibles_sorteo e
                         WHERE e.id_proceso = v.id_proceso AND e.id_mesa = v.id_mesa) AS elegibles
                  FROM v_mesa_detalle v
                 WHERE v.id_proceso = ? AND v.estado <> 'ANULADA'
                 ORDER BY v.numero_mesa
                """, idProceso);
    }

    public List<Map<String, Object>> miembros(Integer idProceso) {
        return dao.consultar("""
                SELECT id_mesa, numero_mesa, orden_sorteo, rol, titular, id_docente, dni, docente, facultad
                  FROM v_miembros_mesa WHERE id_proceso = ?
                 ORDER BY numero_mesa, orden_sorteo
                """, idProceso);
    }

    /** Parámetros por defecto para conformar mesas (RN08 y tamaño de mesa). */
    public Map<String, Object> parametros() {
        Map<String, Object> p = new LinkedHashMap<>();
        p.put("electoresPorMesa", 200);
        p.put("ubicacion", "Biblioteca Central");
        for (Map<String, Object> fila : dao.consultar(
                "SELECT clave, valor FROM parametro_global WHERE clave IN ('ELECTORES_POR_MESA', 'UBICACION_SUFRAGIO')")) {
            if ("ELECTORES_POR_MESA".equals(fila.get("clave"))) {
                try {
                    p.put("electoresPorMesa", (int) Double.parseDouble(String.valueOf(fila.get("valor"))));
                } catch (NumberFormatException ignorado) {
                    // se mantiene el valor por defecto
                }
            } else {
                p.put("ubicacion", fila.get("valor"));
            }
        }
        return p;
    }

    /** RN18: cargos con sus listas admitidas (y cuántas siguen sin calificar). */
    public List<Map<String, Object>> cedula(Integer idProceso) {
        List<Map<String, Object>> cargos = dao.consultar("""
                SELECT c.id_cargo AS id, c.nombre,
                       (SELECT COUNT(*) FROM lista_electoral l WHERE l.id_cargo = c.id_cargo AND l.estado = 'INSCRITA') AS por_calificar
                  FROM cargo_electoral c WHERE c.id_proceso = ? ORDER BY c.id_cargo
                """, idProceso);
        List<Map<String, Object>> listas = dao.consultar("""
                SELECT l.id_lista AS id, l.id_cargo, l.nombre, l.simbolo, l.orden_cedula
                  FROM lista_electoral l JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                 WHERE c.id_proceso = ? AND l.estado = 'ADMITIDA'
                 ORDER BY (l.orden_cedula IS NULL), l.orden_cedula, l.nombre
                """, idProceso);
        for (Map<String, Object> cargo : cargos) {
            List<Map<String, Object>> deCargo = listas.stream().filter(l -> l.get("idCargo").equals(cargo.get("id"))).toList();
            cargo.put("listas", deCargo);
            cargo.put("sorteado", !deCargo.isEmpty() && deCargo.stream().allMatch(l -> l.get("ordenCedula") != null));
        }
        return cargos;
    }
}
