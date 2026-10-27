package pe.unp.elecciones.electoral.multas;

import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS16 · «GenerarMultas» (control). Mensajes 2 a 7 del diagrama de colaboración:
 *
 *   2 generarMultas()         → sp_generar_multas
 *   3 obtenerUIT()            → UIT y porcentajes de parametro_global (RF105)
 *   4 consultarNoVotaron()    → v_omisos_proceso: elector hábil que no votó y cuya mesa se instaló (RF103, Art. 68)
 *   5 consultarInasistentes() → v_omisos_proceso: miembro titular que no asistió (RF104, Art. 67)
 *   6 insertar()              → multa: 2.5 % y 3 % de la UIT (RN35)
 *   7 mostrarReporteMultas()  → sp_emitir_resolucion_multas: el Pleno determina las multas (RN36)
 *
 * <p>Después de la resolución, las multas se notifican a cada docente. El sistema no las cobra (CUN12).
 */
@Service
public class GenerarMultas {

    private static final Map<String, String> MEDIO = Map.of(
            "CORREO_INSTITUCIONAL", "por correo institucional",
            "CEDULA_PERSONAL", "por cédula personal",
            "PORTAL_ELECTORAL", "en el portal electoral");

    private final ProcedimientoDao dao;
    private final MultasConsulta consulta;

    public GenerarMultas(ProcedimientoDao dao, MultasConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 2-6 generarMultas(): genera o, antes de la resolución, recalcula las multas del proceso. */
    public Map<String, Object> generar(Integer idProceso, Usuario usuario) {
        consulta.proceso(idProceso);
        dao.llamar("sp_generar_multas", ProcedimientoDao.SIN_SALIDA, idProceso, usuario.getId());
        Map<String, Object> respuesta = consulta.respuesta("", idProceso, usuario);
        @SuppressWarnings("unchecked")
        Map<String, Object> resumen = (Map<String, Object>) ((Map<String, Object>) respuesta.get("detalle")).get("resumen");
        respuesta.put("mensaje", "Multas generadas: " + resumen.get("omisosVotacion") + " omiso(s) al sufragio y "
                + resumen.get("omisosMesa") + " miembro(s) de mesa inasistente(s), por S/ " + resumen.get("montoTotal")
                + ". El Pleno debe emitir la resolución que las determina (RN36).");
        return respuesta;
    }

    /** 7 mostrarReporteMultas(): resolución del Pleno con huella SHA-256; devuelve el token del QR. */
    public Map<String, Object> emitirResolucion(Integer idProceso, MultasDto.Resolucion datos, Usuario usuario) {
        consulta.proceso(idProceso);
        ProcedimientoDao.Resultado r = dao.llamar("sp_emitir_resolucion_multas", ProcedimientoDao.SIN_SALIDA, idProceso,
                usuario.getId(), datos.numeroResolucion().trim(), datos.miembrosPleno(), MultasConsulta.vacioANulo(datos.fundamento()));
        if (r.filas().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "El procedimiento no devolvió resultados.");
        }
        Map<String, Object> fila = r.filas().get(0);
        Map<String, Object> respuesta = consulta.respuesta("Resolución " + fila.get("numeroResolucion") + " emitida: se determinan "
                + fila.get("omisosVotacion") + " multa(s) por omisión al sufragio y " + fila.get("omisosMesa")
                + " por inasistencia a la mesa, por S/ " + fila.get("montoTotal") + ". Notifíquelas a los docentes.", idProceso, usuario);
        respuesta.put("tokenQr", fila.get("tokenQr"));
        respuesta.put("resolucion", consulta.resolucion(idProceso));
        return respuesta;
    }

    /** Notificación de una multa o de todas las que faltan. */
    public Map<String, Object> notificar(Integer idProceso, MultasDto.Notificacion datos, Usuario usuario) {
        consulta.proceso(idProceso);
        String medio = datos.medio().trim().toUpperCase();
        if (!MultasConsulta.MEDIOS.contains(medio)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Medio de notificación no válido.");
        }
        ProcedimientoDao.Resultado r = dao.llamar("sp_notificar_multas", ProcedimientoDao.SIN_SALIDA, idProceso, datos.idMulta(),
                usuario.getId(), medio, MultasConsulta.vacioANulo(datos.documento()), datos.fecha());
        Object n = r.filas().isEmpty() ? 0 : r.filas().get(0).get("notificadas");
        return consulta.respuesta(n + " multa(s) notificada(s) " + MEDIO.get(medio) + ".", idProceso, usuario);
    }
}
