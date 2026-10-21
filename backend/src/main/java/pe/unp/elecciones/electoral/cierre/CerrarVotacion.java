package pe.unp.elecciones.electoral.cierre;

import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS11 · «CerrarVotacion» (control). Mensajes 2 a 4 del diagrama de colaboración:
 *
 *   2 cerrarVotacion(id_mesa)                     → sp_cerrar_votacion
 *   3 actualizarEstado('CERRADA', hora_cierre)    → MesaElectoral (bloquea verificaciones y terminales)
 *   4 mostrarTotalVotantes(total)                 → la respuesta trae el total (RF74)
 *
 * <p>Precondición y A1 de la tabla 37: son las 15:00 (fecha_fin del proceso) o ya votaron todos,
 * y ningún elector sigue votando en un terminal. Sin @Transactional a propósito: el
 * procedimiento abre su transacción (ver ProcedimientoDao).
 */
@Service
public class CerrarVotacion {

    private final ProcedimientoDao dao;
    private final CierreConsulta consulta;

    public CerrarVotacion(ProcedimientoDao dao, CierreConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 2: cerrarVotacion(id_mesa). */
    public Map<String, Object> cerrarVotacion(Integer idMesa, Usuario usuario) {
        consulta.mesa(idMesa);
        consulta.exigirPresidente(idMesa, usuario);
        ProcedimientoDao.Resultado resultado =
                dao.llamar("sp_cerrar_votacion", ProcedimientoDao.SIN_SALIDA, idMesa, usuario.getId());
        Map<String, Object> total = resultado.filas().isEmpty() ? Map.of() : resultado.filas().get(0);

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Sufragio cerrado: votaron " + total.get("totalVotaron") + " de "
                + total.get("totalElectores") + " electores. La mesa ya no verifica electores y sus terminales quedaron deshabilitados.");
        respuesta.put("total", total); // 4: mostrarTotalVotantes(total)
        respuesta.put("detalle", consulta.detalle(idMesa));
        return respuesta;
    }
}
