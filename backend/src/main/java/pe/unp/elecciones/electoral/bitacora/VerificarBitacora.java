package pe.unp.elecciones.electoral.bitacora;

import java.sql.Types;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS19 · Verificación de la integridad de la bitácora (paso que el diagrama no tiene; ver la
 * documentación del caso). sp_verificar_bitacora recalcula el sello SHA-256 de cada registro, comprueba
 * que cada uno esté enlazado al anterior y que el último coincida con el sello vigente
 * (bitacora_cadena). Detecta registros alterados, borrados o insertados por fuera del sistema.
 * La verificación queda en la bitácora (VERIFICAR_BITACORA).
 */
@Service
public class VerificarBitacora {

    private static final int[] SALIDAS = {Types.VARCHAR, Types.BIGINT, Types.INTEGER, Types.BIGINT, Types.CHAR, Types.BIGINT};

    private final BitacoraConsulta consulta;
    private final ProcedimientoDao dao;

    public VerificarBitacora(BitacoraConsulta consulta, ProcedimientoDao dao) {
        this.consulta = consulta;
        this.dao = dao;
    }

    public Map<String, Object> verificar(Usuario admin, String ip, String userAgent) {
        consulta.verificarInstalacion();
        long inicio = System.currentTimeMillis();
        ProcedimientoDao.Resultado res = dao.llamar("sp_verificar_bitacora", SALIDAS, admin.getId(), ip,
                userAgent == null ? null : userAgent.substring(0, Math.min(userAgent.length(), 500)));
        Object[] s = res.salidas();

        Map<String, Object> v = new LinkedHashMap<>();
        v.put("estado", s[0]);
        v.put("registros", s[1]);
        v.put("anomalias", s[2]);
        v.put("primerIdAnomalo", s[3]);
        v.put("hashFinal", s[4]);
        v.put("idLog", s[5]);
        v.put("fecha", LocalDateTime.now());
        v.put("duracionMs", System.currentTimeMillis() - inicio);
        v.put("detalle", res.filas());

        String estado = String.valueOf(s[0]);
        String mensaje = switch (estado) {
            case "INTEGRA" -> "Bitácora íntegra: los " + s[1] + " registros conservan su sello y la cadena está completa.";
            case "VACIA" -> "La bitácora no tiene registros que verificar.";
            default -> "Bitácora alterada: se encontraron " + s[2] + " anomalía(s) desde el registro N.º " + s[3]
                    + ". Revise el detalle y conserve un respaldo de la base antes de cualquier cambio.";
        };
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("mensaje", mensaje);
        r.put("verificacion", v);
        r.put("cadena", consulta.cadena());
        return r;
    }
}
