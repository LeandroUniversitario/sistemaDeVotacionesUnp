package pe.unp.elecciones.electoral.administracion;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS18 · «actualizarParametros» (control). Mensajes 5 a 9 del diagrama de colaboración:
 *
 *   5 modificarParametro()  → PantallaAdministrador (el Admin elige el parámetro, el valor y el motivo)
 *   6 actualizar()          → actualizar()
 *   7 actualizarParametro() → sp_actualizar_parametro: tipo, rango, coherencia (fn_validar_parametro) y
 *                             bloqueo durante la jornada electoral (fn_jornada_en_curso)
 *   8 registrarAuditoria()  → parametro_historial (trg_parametro_global_au) y log_auditoria CAMBIO_PARAMETRO
 *   9 confirmarCambio()     → valor anterior y nuevo
 *
 * <p>El valor anterior de cualquier cambio del historial se puede restaurar, con su propio motivo.
 */
@Service
public class ActualizarParametros {

    private final ProcedimientoDao dao;
    private final AdministracionConsulta consulta;

    public ActualizarParametros(ProcedimientoDao dao, AdministracionConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 6 actualizar() → 7 actualizarParametro() → 8 registrarAuditoria() → 9 confirmarCambio(). */
    public Map<String, Object> actualizar(String clave, AdministracionDto.CambioParametro datos, Usuario admin, String ip) {
        consulta.parametro(clave);
        return aplicar(clave, datos.valor(), datos.motivo(), "PANTALLA", admin, ip);
    }

    /** Vuelve al valor que el parámetro tenía antes del cambio elegido del historial. */
    public Map<String, Object> restaurar(String clave, AdministracionDto.Restauracion datos, Usuario admin, String ip) {
        consulta.parametro(clave);
        List<Map<String, Object>> filas = dao.consultar(
                "SELECT valor_anterior FROM parametro_historial WHERE id_historial = ? AND clave = ?", datos.idHistorial(), clave);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El cambio no pertenece al historial de este parámetro.");
        }
        Object anterior = filas.get(0).get("valorAnterior");
        if (anterior == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Ese cambio no tiene un valor anterior que restaurar.");
        }
        return aplicar(clave, String.valueOf(anterior), datos.motivo(), "RESTAURACION", admin, ip);
    }

    private Map<String, Object> aplicar(String clave, String valor, String motivo, String origen, Usuario admin, String ip) {
        ProcedimientoDao.Resultado r = dao.llamar("sp_actualizar_parametro", ProcedimientoDao.SIN_SALIDA, admin.getId(),
                clave, valor.trim(), motivo.trim(), origen, ip);
        if (r.filas().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "El procedimiento no devolvió resultados.");
        }
        Map<String, Object> confirmacion = r.filas().get(0);
        String mensaje = ("RESTAURACION".equals(origen) ? "Valor restaurado. " : "Parámetro actualizado. ")
                + "«" + confirmacion.get("etiqueta") + "»: " + confirmacion.get("valorAnterior") + " → "
                + confirmacion.get("valorNuevo") + ". El cambio quedó en el historial y en la bitácora.";
        Map<String, Object> respuesta = new LinkedHashMap<>(consulta.respuesta(mensaje, admin));
        respuesta.put("confirmacion", confirmacion);
        return respuesta;
    }
}
