package pe.unp.elecciones.electoral.computo;

import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS14 · «VerificarActas» (control). Mensajes 2 a 5 del diagrama de colaboración y la
 * calificación del CEUNP (paso 7 y A3 de la tabla 39):
 *
 *   2 verificarActasEntregadas(idProceso) / 3 actasEntregadas(totalMesas) → v_computo_mesas (RF89)
 *   4 validarIntegridad(actas)                                            → sp_marcar_acta_dudosa (RF90)
 *   5 actasValidas(hashCorrecto)                                          → sp_comprobar_acta (QR y SHA-256)
 *   calificarMesa(idMesa, VALIDA | NULIDAD)                               → sp_calificar_mesa (RF94, RF95)
 */
@Service
public class VerificarActas {

    private final ProcedimientoDao dao;
    private final ComputoConsulta consulta;

    public VerificarActas(ProcedimientoDao dao, ComputoConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** Paso 3: el CEUNP marca como dudosa un acta (no coincide con su copia, enmendaduras, etc.). */
    public Map<String, Object> marcarDudosa(Integer idActa, ComputoDto.ActaDudosa datos, Usuario usuario) {
        Map<String, Object> acta = consulta.acta(idActa);
        dao.llamar("sp_marcar_acta_dudosa", ProcedimientoDao.SIN_SALIDA, idActa, usuario.getId(), datos.motivo().trim());
        return respuesta("Acta de " + nombreTipo(acta.get("tipo")) + " de la mesa " + acta.get("numeroMesa")
                + " marcada como dudosa. Compruebe su autenticidad con el QR del ejemplar físico.", acta, usuario);
    }

    /** 4-5: recalcula la huella SHA-256 y compara el QR leído del ejemplar físico. */
    public Map<String, Object> comprobar(Integer idActa, ComputoDto.Comprobacion datos, Usuario usuario) {
        Map<String, Object> acta = consulta.acta(idActa);
        ProcedimientoDao.Resultado r = dao.llamar("sp_comprobar_acta", ProcedimientoDao.SIN_SALIDA, idActa, usuario.getId(),
                SesionComputo.vacioANulo(datos.tokenQr()), SesionComputo.vacioANulo(datos.observacion()));
        Map<String, Object> fila = r.filas().isEmpty() ? Map.of() : r.filas().get(0);
        boolean autentica = "AUTENTICA".equals(ComputoConsulta.texto(fila.get("resultado")));
        String mensaje = autentica
                ? "Acta auténtica: la huella SHA-256 coincide" + (fila.get("qrCoincide") == null ? "" : " y el QR del ejemplar físico corresponde al acta") + "."
                : "Acta NO auténtica: " + (ComputoConsulta.numero(fila.get("huellaCoincide")) == 1 ? "el QR leído no corresponde al acta"
                        : "su contenido no coincide con la huella SHA-256") + ". Solo procede declarar la nulidad de la mesa (RF94).";
        Map<String, Object> respuesta = respuesta(mensaje, acta, usuario);
        respuesta.put("comprobacion", fila);
        return respuesta;
    }

    /** Paso 7 y A3: el CEUNP califica la mesa (VALIDA con la cédula física, o NULIDAD por resolución). */
    public Map<String, Object> calificarMesa(Integer idMesa, ComputoDto.Calificacion datos, Usuario usuario) {
        Map<String, Object> mesa = consulta.mesa(idMesa);
        String calificacion = datos.calificacion().trim().toUpperCase();
        dao.llamar("sp_calificar_mesa", ProcedimientoDao.SIN_SALIDA, idMesa, usuario.getId(), calificacion,
                datos.fundamento().trim(), SesionComputo.vacioANulo(datos.numeroResolucion()));
        String mensaje = "NULIDAD".equals(calificacion)
                ? "Nulidad de la mesa " + mesa.get("numeroMesa") + " declarada (" + datos.numeroResolucion().trim()
                        + "): sus votos no se computan."
                : "Mesa " + mesa.get("numeroMesa") + " calificada VÁLIDA: se computa con el conteo de la cédula física (RF84).";
        return respuesta(mensaje, mesa, usuario);
    }

    private Map<String, Object> respuesta(String mensaje, Map<String, Object> origen, Usuario usuario) {
        Integer idProceso = ComputoConsulta.numero(origen.get("idProceso"));
        Integer idMesa = ComputoConsulta.numero(origen.get("idMesa"));
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("mensaje", mensaje);
        r.put("mesa", consulta.detalleMesa(idMesa));
        r.put("detalle", consulta.detalle(idProceso, usuario));
        return r;
    }

    private static String nombreTipo(Object tipo) {
        return switch (ComputoConsulta.texto(tipo)) {
            case "INSTALACION" -> "instalación";
            case "SUFRAGIO" -> "sufragio";
            case "ESCRUTINIO" -> "escrutinio";
            default -> ComputoConsulta.texto(tipo).toLowerCase();
        };
    }
}
