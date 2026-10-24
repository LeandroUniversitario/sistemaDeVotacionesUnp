package pe.unp.elecciones.electoral.impugnaciones;

import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS13 · «ResolverImpugnacion» (control). Mensajes 7 a 9 del diagrama de colaboración:
 *
 *   7 resolverEnMesa(datos)                 → sp_resolver_impugnacion_mesa
 *   8 actualizarDecisionMesa(decision)      → ImpugnacionElectoral (decision_mesa, opción de la cédula)
 *   9 notificarDecision()                   → la respuesta y la pantalla del personero
 *
 * <p>RN23: primera instancia de los miembros de mesa por mayoría simple. Registra la decisión el
 * presidente en funciones. Sin @Transactional: el procedimiento abre su transacción.
 */
@Service
public class ResolverImpugnacion {

    private final ProcedimientoDao dao;
    private final ImpugnacionesConsulta consulta;

    public ResolverImpugnacion(ProcedimientoDao dao, ImpugnacionesConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 7: resolverEnMesa(datos). */
    public Map<String, Object> resolverEnMesa(Long idImpugnacion, ImpugnacionesDto.DecisionMesa datos, Usuario usuario) {
        Map<String, Object> impugnacion = consulta.impugnacion(idImpugnacion);
        Integer idMesa = ImpugnacionesConsulta.numero(impugnacion.get("idMesa"));
        consulta.exigirAcceso(idMesa, usuario);
        consulta.exigirPresidente(idMesa, usuario);
        dao.llamar("sp_resolver_impugnacion_mesa", ProcedimientoDao.SIN_SALIDA, idImpugnacion, usuario.getId(),
                datos.decision(), datos.votosFavor(), datos.votosContra(), datos.opcion(),
                "LISTA".equalsIgnoreCase(datos.opcion()) ? datos.idLista() : null, datos.fundamento().trim());

        Map<String, Object> resuelta = consulta.impugnacion(idImpugnacion);
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "ACEPTADA".equals(resuelta.get("decisionMesa"))
                ? "La mesa declaró FUNDADA la impugnación N.º " + idImpugnacion + " (" + resuelta.get("votosMesaFavor") + " a "
                        + resuelta.get("votosMesaContra") + "). La cédula va a " + opcion(resuelta) + "."
                : "La mesa declaró INFUNDADA la impugnación N.º " + idImpugnacion + " (" + resuelta.get("votosMesaContra") + " a "
                        + resuelta.get("votosMesaFavor") + "). La cédula va a " + opcion(resuelta)
                        + ". El personero puede apelar ante el CEUNP.");
        respuesta.put("impugnacion", resuelta); // 9: notificarDecision()
        respuesta.put("detalle", consulta.detalle(idMesa, usuario));
        return respuesta;
    }

    static String opcion(Map<String, Object> i) {
        Object op = i.get("opcionVigente");
        if ("LISTA".equals(op)) {
            return "la lista " + i.get("listaVigente");
        }
        return "IMPUGNADO".equals(op) ? "IMPUGNADO (en apelación)" : "voto " + op;
    }
}
