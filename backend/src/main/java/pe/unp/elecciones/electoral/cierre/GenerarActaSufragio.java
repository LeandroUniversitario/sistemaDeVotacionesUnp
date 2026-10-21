package pe.unp.elecciones.electoral.cierre;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import org.springframework.stereotype.Service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS11 · «GenerarActaSufragio» (control). Mensajes 10 a 13 del diagrama de colaboración:
 *
 *   10 generarActa(datos)                          → sp_generar_acta_sufragio
 *   11 insertarActa('SUFRAGIO', hash, contenido)   → ActaElectoral (RF76, huella SHA-256)
 *   12 registrarFirmas(firmas)                     → FirmaActa (presidente, secretario y personeros)
 *   13 mostrarActaSufragio()                       → la respuesta trae el acta y el token del QR
 *
 * <p>Flujo A2: si el conteo de firmas de la lista física difiere del total del sistema, la
 * observación es obligatoria (lo valida el procedimiento).
 */
@Service
public class GenerarActaSufragio {

    private final ProcedimientoDao dao;
    private final CierreConsulta consulta;
    private final ObjectMapper json;

    public GenerarActaSufragio(ProcedimientoDao dao, CierreConsulta consulta, ObjectMapper json) {
        this.dao = dao;
        this.consulta = consulta;
        this.json = json;
    }

    /** 10: generarActa(datos). El token del QR del acta solo se devuelve aquí. */
    public Map<String, Object> generarActa(Integer idMesa, CierreDto.DatosActa datos, Usuario usuario) {
        consulta.mesa(idMesa);
        consulta.exigirPresidente(idMesa, usuario);
        String personeros;
        try {
            personeros = json.writeValueAsString(datos.personeros() == null ? List.of()
                    : datos.personeros().stream().filter(Objects::nonNull).distinct().toList());
        } catch (JsonProcessingException e) {
            throw new IllegalStateException(e);
        }
        String observaciones = datos.observaciones() == null || datos.observaciones().isBlank()
                ? null : datos.observaciones().trim();
        ProcedimientoDao.Resultado resultado = dao.llamar("sp_generar_acta_sufragio", ProcedimientoDao.SIN_SALIDA,
                idMesa, usuario.getId(), datos.cedulasNoUtilizadas(), datos.firmasListaFisica(), observaciones, personeros);
        Map<String, Object> fila = resultado.filas().isEmpty() ? Map.of() : resultado.filas().get(0);

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Se emitió y firmó el Acta de Sufragio. La mesa puede pasar al escrutinio (CUS12).");
        respuesta.put("idActa", fila.get("idActa"));
        respuesta.put("tokenQr", fila.get("tokenQr"));
        respuesta.put("detalle", consulta.detalle(idMesa)); // 13: mostrarActaSufragio()
        return respuesta;
    }
}
