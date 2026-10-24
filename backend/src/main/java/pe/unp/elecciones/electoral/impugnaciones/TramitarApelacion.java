package pe.unp.elecciones.electoral.impugnaciones;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Rol;
import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS13 · «TramitarApelacion» (control). Mensajes 10 y 12 a 14 del diagrama de colaboración:
 *
 *   10 [decision rechazada] apelarDecision(id_impugnacion)   → sp_apelar_impugnacion (RF81)
 *   12 resolverApelacion(id_impugnacion, decision)           → sp_resolver_apelacion
 *   13 actualizarDecisionCEUNP(decision, 'RESUELTA')         → ImpugnacionElectoral
 *   14 notificarFalloFinal()                                 → la respuesta y las pantallas de mesa y personero
 *
 * <p>RN23 / RN36: el CEUNP resuelve en segunda y última instancia, con quórum y por mayoría simple
 * (voto dirimente del Presidente en empate). El fallo es inapelable.
 */
@Service
public class TramitarApelacion {

    private final ProcedimientoDao dao;
    private final ImpugnacionesConsulta consulta;

    public TramitarApelacion(ProcedimientoDao dao, ImpugnacionesConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 10: apelarDecision(id_impugnacion). Apela un personero de la lista; el presidente puede elevarla a su pedido. */
    public Map<String, Object> apelarDecision(Long idImpugnacion, ImpugnacionesDto.Apelacion datos, Usuario usuario) {
        Map<String, Object> impugnacion = consulta.impugnacion(idImpugnacion);
        Integer idMesa = ImpugnacionesConsulta.numero(impugnacion.get("idMesa"));
        int idLista = ImpugnacionesConsulta.numero(impugnacion.get("idListaPersonero"));
        consulta.exigirAcceso(idMesa, usuario);

        Integer idPersonero = datos.idPersonero();
        if (usuario.getRol() == Rol.PERSONERO) {
            List<Map<String, Object>> propios = consulta.personerosDelDocente(usuario.getIdDocente()).stream()
                    .filter(p -> ImpugnacionesConsulta.numero(p.get("idLista")) == idLista).toList();
            if (propios.isEmpty()) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                        "RF81: apela un personero de la lista " + impugnacion.get("listaPersonero") + ".");
            }
            idPersonero = ImpugnacionesConsulta.numero(propios.get(0).get("idPersonero"));
        } else if (usuario.getRol() == Rol.MIEMBRO_MESA) {
            consulta.exigirPresidente(idMesa, usuario);
            if (idPersonero == null) {
                idPersonero = ImpugnacionesConsulta.numero(impugnacion.get("idPersonero"));
            }
        } else {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "RF81: apela el personero; la mesa eleva la apelación al CEUNP.");
        }

        dao.llamar("sp_apelar_impugnacion", ProcedimientoDao.SIN_SALIDA, idImpugnacion, usuario.getId(), idPersonero,
                datos.fundamento().trim());

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Apelación registrada. La impugnación N.º " + idImpugnacion
                + " se elevó al CEUNP, que resuelve en segunda y última instancia.");
        respuesta.put("impugnacion", consulta.impugnacion(idImpugnacion));
        respuesta.put("detalle", consulta.detalle(idMesa, usuario));
        return respuesta;
    }

    /** 11-12: registrarFalloCEUNP(id_impugnacion, decision) → resolverApelacion(id_impugnacion, decision). */
    public Map<String, Object> resolverApelacion(Long idImpugnacion, ImpugnacionesDto.FalloCeunp datos, Usuario usuario) {
        if (usuario.getRol() != Rol.CEUNP) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "RN23: las apelaciones las resuelve el CEUNP.");
        }
        consulta.impugnacion(idImpugnacion);
        boolean modifica = "MODIFICADA".equalsIgnoreCase(datos.decision());
        dao.llamar("sp_resolver_apelacion", ProcedimientoDao.SIN_SALIDA, idImpugnacion, usuario.getId(),
                datos.decision(), datos.numeroResolucion().trim(), datos.miembrosPleno(), datos.votosFavor(),
                datos.votosContra(), datos.votoDirimente(), modifica ? datos.opcion() : null,
                modifica && "LISTA".equalsIgnoreCase(datos.opcion()) ? datos.idLista() : null, datos.fundamento().trim());

        Map<String, Object> fallada = consulta.impugnacion(idImpugnacion);
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Fallo " + datos.numeroResolucion().trim() + ": el CEUNP "
                + (modifica ? "MODIFICÓ" : "CONFIRMÓ") + " la decisión de la mesa. La cédula va a "
                + ResolverImpugnacion.opcion(fallada) + ". El fallo es inapelable (RN36).");
        respuesta.put("impugnacion", fallada); // 14: notificarFalloFinal()
        return respuesta;
    }
}
