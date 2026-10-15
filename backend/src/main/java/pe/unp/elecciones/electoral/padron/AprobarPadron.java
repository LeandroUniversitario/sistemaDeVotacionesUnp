package pe.unp.elecciones.electoral.padron;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS02 · Control «AprobarPadron» del diagrama de colaboración.
 *
 * <pre>
 *  PantallaPadron --10: generarDefinitivo(id_proceso)--> AprobarPadron
 *  AprobarPadron  --11: insertar(id_proceso, id_docente)--> PadronElectoral
 *  AprobarPadron  --12: notificarExito()--> PantallaPadron
 * </pre>
 *
 * El padrón definitivo (RN04) se genera con sp_generar_padron: por cada cargo del
 * proceso inserta a los docentes habilitados de su jurisdicción cuya categoría puede
 * votar (RF03). Puede regenerarse mientras el proceso esté en CREADO o INSCRIPCION
 * y todavía no existan mesas de sufragio.
 */
@Service
public class AprobarPadron {

    private final ProcedimientoDao dao;
    private final PadronConsulta consulta;

    public AprobarPadron(ProcedimientoDao dao, PadronConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 10: generarDefinitivo(id_proceso) */
    public Map<String, Object> generarDefinitivo(Integer idProceso, Integer idUsuario) {
        Map<String, Object> detalle = consulta.detalleProceso(idProceso);
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> requisitos = (List<Map<String, Object>>) detalle.get("requisitos");
        for (Map<String, Object> requisito : requisitos) {
            if (!Boolean.TRUE.equals(requisito.get("cumple"))) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "No se puede aprobar el padrón: " + requisito.get("descripcion"));
            }
        }
        insertar(idProceso, idUsuario);
        return notificarExito(idProceso);
    }

    /** 11: insertar(id_proceso, id_docente) en PadronElectoral (sp_generar_padron, registra GENERAR_PADRON). */
    private void insertar(Integer idProceso, Integer idUsuario) {
        dao.llamar("sp_generar_padron", ProcedimientoDao.SIN_SALIDA, idProceso, idUsuario);
    }

    /** 12: notificarExito() */
    private Map<String, Object> notificarExito(Integer idProceso) {
        Map<String, Object> detalle = consulta.detalleProceso(idProceso);
        @SuppressWarnings("unchecked")
        Map<String, Object> proceso = (Map<String, Object>) detalle.get("proceso");
        int registros = PadronConsulta.numero(proceso.get("registrosPadron"));
        int electores = PadronConsulta.numero(proceso.get("electoresPadron"));

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Padrón definitivo aprobado para «" + proceso.get("nombre") + "»: "
                + electores + " electores con " + registros + " registros de votación.");
        respuesta.putAll(detalle);
        return respuesta;
    }
}
