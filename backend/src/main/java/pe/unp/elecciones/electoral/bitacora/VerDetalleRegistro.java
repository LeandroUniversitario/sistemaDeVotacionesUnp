package pe.unp.elecciones.electoral.bitacora;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS19 · Control «VerDetalleRegistro». Mensajes del diagrama «Consultar bitácora»:
 * <ul>
 *   <li>6 seleccionarRegistro(id_log): el Admin elige una fila de la tabla</li>
 *   <li>7 obtenerDetalle(id_log): esta clase</li>
 *   <li>8 consultarDetalle(id_log) → LogAuditoria: sp_detalle_bitacora (valida el rol, trae el registro
 *       con sus vecinos de la cadena y comprueba su sello)</li>
 *   <li>9 mostrarDetalleJSON(detalle): detalle_json interpretado, más lo que hizo el mismo usuario
 *       alrededor de ese momento y lo registrado sobre el mismo docente</li>
 * </ul>
 */
@Service
public class VerDetalleRegistro {

    private final BitacoraConsulta consulta;
    private final ProcedimientoDao dao;
    private final ObjectMapper json;

    public VerDetalleRegistro(BitacoraConsulta consulta, ProcedimientoDao dao, ObjectMapper json) {
        this.consulta = consulta;
        this.dao = dao;
        this.json = json;
    }

    /** 7 obtenerDetalle(id_log) → 8 consultarDetalle(id_log) → 9 mostrarDetalleJSON(detalle). */
    public Map<String, Object> obtenerDetalle(Long idLog, Usuario admin) {
        consulta.verificarInstalacion();
        Map<String, Object> registro = dao.llamar("sp_detalle_bitacora", ProcedimientoDao.SIN_SALIDA, admin.getId(), idLog)
                .filas().get(0);

        Map<String, Object> r = new LinkedHashMap<>();
        r.put("registro", registro);
        Object texto = registro.get("detalleJson");
        r.put("detalle", null);
        r.put("detalleValido", texto == null);
        if (texto != null) {
            try {
                r.put("detalle", json.readValue(String.valueOf(texto), Object.class));
                r.put("detalleValido", true);
            } catch (JsonProcessingException e) {
                r.put("detalleValido", false);
            }
        }
        r.put("contexto", contexto(registro));
        r.put("mismoDocente", registro.get("idDocente") == null ? List.of() : dao.consultar("""
                SELECT v.id_log, v.fecha_hora, v.accion, v.etiqueta, v.criticidad, v.username, v.proceso
                  FROM v_bitacora v
                 WHERE v.id_docente = ? AND v.id_log <> ?
                 ORDER BY ABS(v.id_log - ?) LIMIT 12
                """, registro.get("idDocente"), idLog, idLog));
        return r;
    }

    /** Lo que hizo la misma cuenta media hora antes y después (o los registros vecinos si no tiene cuenta). */
    private List<Map<String, Object>> contexto(Map<String, Object> registro) {
        Object idLog = registro.get("idLog");
        if (registro.get("idUsuario") != null) {
            return dao.consultar("""
                    SELECT v.id_log, v.fecha_hora, v.accion, v.etiqueta, v.criticidad, v.username, v.ip_origen, v.proceso
                      FROM v_bitacora v
                     WHERE v.id_usuario = ? AND v.id_log <> ?
                       AND v.fecha_hora BETWEEN ? - INTERVAL 30 MINUTE AND ? + INTERVAL 30 MINUTE
                     ORDER BY v.id_log LIMIT 20
                    """, registro.get("idUsuario"), idLog, registro.get("fechaHora"), registro.get("fechaHora"));
        }
        return dao.consultar("""
                SELECT v.id_log, v.fecha_hora, v.accion, v.etiqueta, v.criticidad, v.username, v.ip_origen, v.proceso
                  FROM v_bitacora v
                 WHERE v.id_log BETWEEN ? - 5 AND ? + 5 AND v.id_log <> ?
                 ORDER BY v.id_log
                """, idLog, idLog, idLog);
    }
}
