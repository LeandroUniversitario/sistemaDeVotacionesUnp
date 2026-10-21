package pe.unp.elecciones.electoral.cierre;

import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS11 · «MarcarAusentes» (control). Mensajes 6 a 8 del diagrama de colaboración:
 *
 *   6 marcarAusentes(id_mesa)      → sp_marcar_ausentes
 *   7 actualizarNoVoto(id_mesa)    → PadronMesa (padron_electoral.no_voto, RF75)
 *   8 mostrarListaNoVoto()         → la respuesta trae la lista de electores marcados
 */
@Service
public class MarcarAusentes {

    private final ProcedimientoDao dao;
    private final CierreConsulta consulta;

    public MarcarAusentes(ProcedimientoDao dao, CierreConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 6: marcarAusentes(id_mesa). */
    public Map<String, Object> marcarAusentes(Integer idMesa, Usuario usuario) {
        consulta.mesa(idMesa);
        consulta.exigirPresidente(idMesa, usuario);
        ProcedimientoDao.Resultado resultado =
                dao.llamar("sp_marcar_ausentes", ProcedimientoDao.SIN_SALIDA, idMesa, usuario.getId());
        Object marcados = resultado.filas().isEmpty() ? 0 : resultado.filas().get(0).get("marcados");

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", marcados + " elector(es) quedaron marcados NO VOTÓ en el padrón de la mesa.");
        respuesta.put("detalle", consulta.detalle(idMesa)); // 8: mostrarListaNoVoto() (detalle.noVotaron)
        return respuesta;
    }
}
