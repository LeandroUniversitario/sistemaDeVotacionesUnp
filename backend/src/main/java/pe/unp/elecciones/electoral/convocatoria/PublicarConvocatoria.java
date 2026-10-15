package pe.unp.elecciones.electoral.convocatoria;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS01 · Control «PublicarConvocatoria» del diagrama de colaboración.
 *
 * <pre>
 *  PantallaConvocatoria --10: cambiarEstado(id_proceso, estado)--> PublicarConvocatoria
 *  PublicarConvocatoria --11: actualizarEstado(...)--> ProcesoElectoral
 *  PublicarConvocatoria --12: notificarPublicacion()--> PantallaConvocatoria
 * </pre>
 *
 * Publicar la convocatoria lleva el proceso de CREADO a INSCRIPCION: desde ese
 * momento las listas pueden inscribirse (CUS03) y el cronograma queda congelado.
 */
@Service
public class PublicarConvocatoria {

    static final String ESTADO_PUBLICADA = "INSCRIPCION";

    private final ProcedimientoDao dao;
    private final ConvocatoriaConsulta consulta;

    public PublicarConvocatoria(ProcedimientoDao dao, ConvocatoriaConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 10: cambiarEstado(id_proceso, estado) */
    public Map<String, Object> cambiarEstado(Integer idProceso, String estado, Integer idUsuario) {
        String nuevo = estado == null ? ESTADO_PUBLICADA : estado.trim().toUpperCase(Locale.ROOT);
        if (!ESTADO_PUBLICADA.equals(nuevo)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Al publicar la convocatoria el proceso solo puede pasar a " + ESTADO_PUBLICADA + ".");
        }

        Map<String, Object> proceso = consulta.proceso(idProceso);
        int totalCargos = ((Number) proceso.get("totalCargos")).intValue();
        List<Map<String, Object>> requisitos = consulta.requisitosPublicacion(proceso, totalCargos);
        for (Map<String, Object> requisito : requisitos) {
            if (!Boolean.TRUE.equals(requisito.get("cumple"))) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "No se puede publicar: " + requisito.get("descripcion"));
            }
        }

        actualizarEstado(idProceso, nuevo, idUsuario);
        return notificarPublicacion(idProceso, idUsuario);
    }

    /** 11: actualizarEstado(...) sobre ProcesoElectoral (máquina de estados de sp_cambiar_estado_proceso). */
    private void actualizarEstado(Integer idProceso, String estado, Integer idUsuario) {
        dao.llamar("sp_cambiar_estado_proceso", ProcedimientoDao.SIN_SALIDA, idProceso, estado, idUsuario);
    }

    /** 12: notificarPublicacion() */
    private Map<String, Object> notificarPublicacion(Integer idProceso, Integer idUsuario) {
        Map<String, Object> detalle = consulta.detalle(idProceso);
        @SuppressWarnings("unchecked")
        Map<String, Object> proceso = (Map<String, Object>) detalle.get("proceso");

        Map<String, Object> bitacora = new LinkedHashMap<>();
        bitacora.put("nombre", proceso.get("nombre"));
        bitacora.put("fecha_convocatoria", proceso.get("fechaConvocatoria"));
        bitacora.put("fecha_limite_inscripcion", proceso.get("fechaLimiteInscripcion"));
        consulta.auditar(idUsuario, idProceso, "PUBLICAR_CONVOCATORIA", bitacora);

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Convocatoria publicada. El proceso «" + proceso.get("nombre")
                + "» pasó a INSCRIPCION: ya se pueden inscribir listas hasta la fecha límite.");
        respuesta.putAll(detalle);
        return respuesta;
    }
}
