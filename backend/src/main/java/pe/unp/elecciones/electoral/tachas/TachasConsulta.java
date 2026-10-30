package pe.unp.elecciones.electoral.tachas;

import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/** CUS04 · Lecturas compartidas por RegistrarTacha y ResolverTacha. */
@Service
public class TachasConsulta {

    private final ProcedimientoDao dao;

    public TachasConsulta(ProcedimientoDao dao) {
        this.dao = dao;
    }

    /** Procesos con candidatos inscritos (la tacha solo se presenta en INSCRIPCION). */
    public List<Map<String, Object>> procesos() {
        return dao.consultar("""
                SELECT p.id_proceso AS id, p.nombre, p.estado, p.fecha_limite_inscripcion,
                       (p.estado = 'INSCRIPCION'
                        AND (p.fecha_limite_inscripcion IS NULL OR NOW() <= p.fecha_limite_inscripcion)) AS admite_tachas,
                       (SELECT COUNT(*) FROM tacha t
                          JOIN candidato ca ON ca.id_candidato = t.id_candidato
                          JOIN lista_electoral l ON l.id_lista = ca.id_lista
                          JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                         WHERE c.id_proceso = p.id_proceso AND t.estado = 'PENDIENTE') AS tachas_pendientes
                  FROM proceso_electoral p
                 WHERE p.estado IN ('INSCRIPCION', 'VOTACION', 'CERRADO', 'FINALIZADO')
                 ORDER BY (p.estado = 'INSCRIPCION') DESC, p.fecha_creacion DESC
                """);
    }

    /** Candidatos que aún pueden ser tachados (ni ellos ni su lista fuera de carrera). Información pública (RN15). */
    public List<Map<String, Object>> candidatos(Integer idProceso) {
        return dao.consultar("""
                SELECT ca.id_candidato AS id, ca.rol_en_lista, ca.estado_validacion, ca.url_hoja_vida,
                       CONCAT(d.apellidos, ', ', d.nombres) AS candidato, d.categoria,
                       l.id_lista, l.nombre AS lista, l.estado AS estado_lista, c.nombre AS cargo
                  FROM candidato ca
                  JOIN docente d ON d.id_docente = ca.id_docente
                  JOIN lista_electoral l ON l.id_lista = ca.id_lista
                  JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                 WHERE c.id_proceso = ? AND ca.estado_validacion <> 'EXCLUIDO'
                   AND l.estado NOT IN ('TACHADA', 'EXCLUIDA')
                 ORDER BY c.id_cargo, l.nombre, ca.id_candidato
                """, idProceso);
    }

    private static final String SELECT_TACHA = """
            SELECT v.id_tacha AS id, v.id_proceso, v.cargo, v.id_lista, v.lista, v.id_candidato,
                   v.rol_en_lista, v.candidato, v.denunciante, dd.dni AS dni_denunciante,
                   v.motivo, v.estado, v.fecha_presentacion, v.fecha_resolucion, v.resolucion,
                   ca.estado_validacion, l.estado AS estado_lista, u.username AS resuelto_por
              FROM v_tachas_detalle v
              JOIN tacha t ON t.id_tacha = v.id_tacha
              JOIN docente dd ON dd.id_docente = t.id_docente_denunciante
              JOIN candidato ca ON ca.id_candidato = v.id_candidato
              JOIN lista_electoral l ON l.id_lista = v.id_lista
              LEFT JOIN usuario u ON u.id_usuario = t.id_usuario_resuelve
            """;

    /** Todas las tachas de un proceso (CEUNP), las pendientes primero. */
    public List<Map<String, Object>> tachas(Integer idProceso) {
        return dao.consultar(SELECT_TACHA + """
                 WHERE v.id_proceso = ?
                 ORDER BY (v.estado = 'PENDIENTE') DESC, v.fecha_presentacion DESC
                """, idProceso);
    }

    /** Tachas presentadas por un docente (vista del docente elector). */
    public List<Map<String, Object>> tachasDe(Integer idDocente) {
        return dao.consultar(SELECT_TACHA + """
                 WHERE t.id_docente_denunciante = ?
                 ORDER BY v.fecha_presentacion DESC
                """, idDocente);
    }

    public Map<String, Object> tacha(Integer idTacha) {
        List<Map<String, Object>> filas = dao.consultar(SELECT_TACHA + " WHERE v.id_tacha = ?", idTacha);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "La tacha no existe.");
        }
        return filas.get(0);
    }
}
