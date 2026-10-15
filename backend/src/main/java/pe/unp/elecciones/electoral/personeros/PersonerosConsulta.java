package pe.unp.elecciones.electoral.personeros;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/** CUS05 · Lecturas compartidas por ValidarPersonero y AcreditarPersonero. */
@Service
public class PersonerosConsulta {

    /** Estados del proceso en que se acredita: antes y durante la jornada electoral. */
    static final Set<String> ESTADOS_ACREDITACION = Set.of("INSCRIPCION", "VOTACION");
    /** Listas que siguen en carrera (una lista tachada o excluida no tiene personeros). */
    static final Set<String> LISTAS_HABILES = Set.of("INSCRITA", "ADMITIDA");

    private final ProcedimientoDao dao;

    public PersonerosConsulta(ProcedimientoDao dao) {
        this.dao = dao;
    }

    public List<Map<String, Object>> procesos() {
        return dao.consultar("""
                SELECT p.id_proceso AS id, p.nombre, p.estado,
                       (p.estado IN ('INSCRIPCION', 'VOTACION')) AS admite_acreditacion,
                       (SELECT COUNT(*) FROM personero pe
                          JOIN lista_electoral l ON l.id_lista = pe.id_lista
                          JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                         WHERE c.id_proceso = p.id_proceso AND pe.estado_acreditacion = 'ACREDITADO') AS acreditados
                  FROM proceso_electoral p
                 WHERE p.estado IN ('INSCRIPCION', 'VOTACION', 'CERRADO', 'FINALIZADO')
                 ORDER BY (p.estado IN ('INSCRIPCION', 'VOTACION')) DESC, p.fecha_creacion DESC
                """);
    }

    /** Proceso, sus mesas y sus listas con los personeros de cada una. */
    public Map<String, Object> detalle(Integer idProceso) {
        List<Map<String, Object>> proceso = dao.consultar(
                "SELECT id_proceso AS id, nombre, estado FROM proceso_electoral WHERE id_proceso = ?", idProceso);
        if (proceso.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El proceso electoral no existe.");
        }
        List<Map<String, Object>> mesas = dao.consultar("""
                SELECT id_mesa AS id, numero_mesa, ubicacion, estado
                  FROM mesa_electoral WHERE id_proceso = ? AND estado <> 'ANULADA'
                 ORDER BY LENGTH(numero_mesa), numero_mesa
                """, idProceso);
        List<Map<String, Object>> listas = dao.consultar("""
                SELECT l.id_lista AS id, l.nombre, l.estado, c.nombre AS cargo
                  FROM lista_electoral l JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                 WHERE c.id_proceso = ?
                 ORDER BY FIELD(l.estado, 'ADMITIDA', 'INSCRITA', 'TACHADA', 'EXCLUIDA'), c.id_cargo, l.nombre
                """, idProceso);
        List<Map<String, Object>> personeros = dao.consultar("""
                SELECT pe.id_personero AS id, pe.id_lista, pe.id_docente, d.dni,
                       CONCAT(d.apellidos, ', ', d.nombres) AS docente, d.categoria,
                       pe.tipo, pe.id_mesa, m.numero_mesa, pe.estado_acreditacion, pe.fecha_acreditacion
                  FROM personero pe
                  JOIN docente d ON d.id_docente = pe.id_docente
                  JOIN lista_electoral l ON l.id_lista = pe.id_lista
                  JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                  LEFT JOIN mesa_electoral m ON m.id_mesa = pe.id_mesa
                 WHERE c.id_proceso = ?
                 ORDER BY FIELD(pe.tipo, 'GENERAL', 'ALTERNO', 'MESA'), LENGTH(m.numero_mesa), m.numero_mesa
                """, idProceso);
        for (Map<String, Object> lista : listas) {
            lista.put("habil", LISTAS_HABILES.contains(String.valueOf(lista.get("estado"))));
            lista.put("personeros", personeros.stream().filter(p -> p.get("idLista").equals(lista.get("id"))).toList());
        }
        Map<String, Object> respuesta = new LinkedHashMap<>();
        Map<String, Object> p = proceso.get(0);
        p.put("admiteAcreditacion", ESTADOS_ACREDITACION.contains(String.valueOf(p.get("estado"))));
        respuesta.put("proceso", p);
        respuesta.put("mesas", mesas);
        respuesta.put("listas", listas);
        return respuesta;
    }

    /** Lista con su proceso; 404 si no existe. */
    public Map<String, Object> lista(Integer idLista) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT l.id_lista AS id, l.nombre, l.estado, c.id_proceso, p.estado AS estado_proceso
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
     * Cupos de la lista: un personero GENERAL, un ALTERNO y uno por mesa.
     * Solo cuentan las acreditaciones vigentes (no revocadas).
     */
    public Map<String, Object> cupos(Integer idLista, Integer idProceso) {
        int general = dao.entero("""
                SELECT COUNT(*) FROM personero
                 WHERE id_lista = ? AND tipo = 'GENERAL' AND estado_acreditacion <> 'REVOCADO'
                """, idLista);
        int alterno = dao.entero("""
                SELECT COUNT(*) FROM personero
                 WHERE id_lista = ? AND tipo = 'ALTERNO' AND estado_acreditacion <> 'REVOCADO'
                """, idLista);
        List<Map<String, Object>> mesasLibres = dao.consultar("""
                SELECT m.id_mesa AS id, m.numero_mesa, m.ubicacion
                  FROM mesa_electoral m
                 WHERE m.id_proceso = ? AND m.estado IN ('PENDIENTE', 'INSTALADA')
                   AND NOT EXISTS (SELECT 1 FROM personero pe
                                    WHERE pe.id_lista = ? AND pe.id_mesa = m.id_mesa
                                      AND pe.estado_acreditacion <> 'REVOCADO')
                 ORDER BY LENGTH(m.numero_mesa), m.numero_mesa
                """, idProceso, idLista);
        Map<String, Object> cupos = new LinkedHashMap<>();
        cupos.put("general", general == 0);
        cupos.put("alterno", alterno == 0);
        cupos.put("mesas", mesasLibres);
        return cupos;
    }
}
