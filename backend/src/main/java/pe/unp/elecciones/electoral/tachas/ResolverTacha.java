package pe.unp.elecciones.electoral.tachas;

import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.service.ProcedimientoDao;
import pe.unp.elecciones.electoral.tachas.TachasDto.DatosResolucion;

/**
 * CUS04 · Control «ResolverTacha» del diagrama de colaboración.
 *
 * <pre>
 *  PantallaTachas --6: guardarResolucion(datos)--> ResolverTacha
 *  ResolverTacha  --7: actualizarEstado(estado, fecha_res)--> Tacha
 *  ResolverTacha  --8: actualizarValidacion('EXCLUIDO')--> Candidato   (solo si es FUNDADA)
 *  ResolverTacha  --9: notificarFallo()--> PantallaTachas
 * </pre>
 *
 * Los pasos 7 y 8 los hace sp_resolver_tacha en una sola transacción. Si la tacha es
 * FUNDADA, además la lista completa queda TACHADA y sale de la cédula (RN12).
 */
@Service
public class ResolverTacha {

    private static final Set<String> RESULTADOS = Set.of("FUNDADA", "INFUNDADA");

    private final ProcedimientoDao dao;
    private final TachasConsulta consulta;

    public ResolverTacha(ProcedimientoDao dao, TachasConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 6: guardarResolucion(datos) */
    public Map<String, Object> guardarResolucion(Integer idTacha, DatosResolucion datos, Integer idUsuario) {
        String estado = datos.estado().trim().toUpperCase(Locale.ROOT);
        if (!RESULTADOS.contains(estado)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El fallo debe ser FUNDADA o INFUNDADA.");
        }
        Map<String, Object> tacha = consulta.tacha(idTacha);
        if (!"PENDIENTE".equals(tacha.get("estado"))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "La tacha N.º " + idTacha + " ya fue resuelta como " + tacha.get("estado") + ".");
        }
        actualizarEstadoYValidacion(idTacha, estado, datos.resolucion().trim(), idUsuario);
        return notificarFallo(idTacha);
    }

    /**
     * 7: actualizarEstado(estado, fecha_res) en Tacha y
     * 8: actualizarValidacion('EXCLUIDO') en Candidato — ambos en sp_resolver_tacha.
     */
    private void actualizarEstadoYValidacion(Integer idTacha, String estado, String resolucion, Integer idUsuario) {
        dao.llamar("sp_resolver_tacha", ProcedimientoDao.SIN_SALIDA, idTacha, estado, resolucion, idUsuario);
    }

    /** 9: notificarFallo() */
    private Map<String, Object> notificarFallo(Integer idTacha) {
        Map<String, Object> tacha = consulta.tacha(idTacha);
        boolean fundada = "FUNDADA".equals(tacha.get("estado"));
        String mensaje = fundada
                ? "Tacha N.º " + idTacha + " declarada FUNDADA: " + tacha.get("candidato")
                        + " queda EXCLUIDO y la lista «" + tacha.get("lista") + "» queda TACHADA (RN12)."
                : "Tacha N.º " + idTacha + " declarada INFUNDADA: " + tacha.get("candidato")
                        + " continúa en la lista «" + tacha.get("lista") + "».";
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", mensaje);
        respuesta.put("tacha", tacha);
        return respuesta;
    }
}
