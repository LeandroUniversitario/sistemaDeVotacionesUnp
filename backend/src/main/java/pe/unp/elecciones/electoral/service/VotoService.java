package pe.unp.elecciones.electoral.service;

import java.sql.Types;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.dto.VotoRequest;

/**
 * Emisión del voto (RF08, RF09, RN01, RN04, RN06, RN25).
 *
 * Toda la operación ocurre dentro de sp_emitir_voto, en una sola transacción:
 * bloquea la fila del padrón, marca que el docente votó, inserta el voto
 * anónimo y emite la constancia. Este servicio nunca escribe en la tabla voto
 * ni guarda la relación docente - lista.
 *
 * Sin @Transactional a propósito (ver ProcedimientoDao).
 */
@Service
public class VotoService {

    private final ProcedimientoDao dao;

    public VotoService(ProcedimientoDao dao) {
        this.dao = dao;
    }

    /**
     * @param idDocente docente autenticado; se toma de la sesión, nunca del cuerpo de la petición
     */
    public Map<String, Object> registrarVoto(VotoRequest request, Integer idDocente) {
        if (request == null || request.procesoId() == null || request.cargoId() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Debe indicar el proceso y el cargo por el que vota.");
        }
        String tipo = request.tipo() == null ? "" : request.tipo().trim().toUpperCase();
        Integer idLista = "VALIDO".equals(tipo) ? request.listaElegidaId() : null;

        ProcedimientoDao.Resultado resultado = dao.llamar("sp_emitir_voto", new int[] {Types.VARCHAR},
                request.procesoId(), request.cargoId(), idDocente, idLista, tipo);

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Voto registrado exitosamente");
        respuesta.put("tokenConstancia", resultado.salidas()[0]);
        return respuesta;
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
