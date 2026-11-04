package pe.unp.elecciones.electoral.service;

import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;


/**
 * Consultas del docente sobre su participación (cargos pendientes y constancias).
 * El voto se emite solo en el terminal de la cabina (CUS10, RegistrarVoto), nunca con la sesión
 * del docente.
 */
@Service
public class VotoService {

    private final ProcedimientoDao dao;

    public VotoService(ProcedimientoDao dao) {
        this.dao = dao;
    }

    /** Cargos por los que el docente puede votar en los procesos que están en VOTACION. */
    public List<Map<String, Object>> cargosDelElector(Integer idDocente) {
        return dao.consultar("""
                SELECT pe.id_proceso, p.nombre AS proceso, pe.id_cargo, c.nombre AS cargo,
                       pe.habilitado_para_votar AS habilitado, pe.ya_voto,
                       m.id_mesa, m.numero_mesa, m.ubicacion, m.estado AS estado_mesa
                  FROM padron_electoral pe
                  JOIN proceso_electoral p ON p.id_proceso = pe.id_proceso
                  JOIN cargo_electoral c   ON c.id_cargo = pe.id_cargo
                  LEFT JOIN mesa_electoral m ON m.id_mesa = pe.id_mesa
                 WHERE pe.id_docente = ? AND p.estado = 'VOTACION'
                 ORDER BY pe.id_proceso, pe.id_cargo
                """, idDocente);
    }

    /** Constancias de participación del docente (no revelan el sentido del voto). */
    public List<Map<String, Object>> constanciasDelElector(Integer idDocente) {
        return dao.consultar("""
                SELECT cv.id_constancia, p.nombre AS proceso, c.nombre AS cargo,
                       cv.fecha_emision, cv.estado
                  FROM constancia_voto cv
                  JOIN proceso_electoral p ON p.id_proceso = cv.id_proceso
                  JOIN cargo_electoral c   ON c.id_cargo = cv.id_cargo
                 WHERE cv.id_docente = ?
                 ORDER BY cv.fecha_emision DESC
                """, idDocente);
    }
}
