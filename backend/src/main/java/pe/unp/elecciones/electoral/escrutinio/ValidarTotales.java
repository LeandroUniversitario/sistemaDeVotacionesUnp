package pe.unp.elecciones.electoral.escrutinio;

import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS12 · «ValidarTotales» (control). Mensajes 2 a 4 del diagrama de colaboración:
 *
 *   2 verificarTotal()                 → sp_contar_cedulas (abre el escrutinio: hora de inicio, RF85)
 *   3 contarVotantes()                 → PadronMesa (electores que votaron, del acta de sufragio)
 *   4 mostrarResultadoValidacion()     → la respuesta trae el cuadre de cédulas (RF77, RF78)
 *
 * <p>Flujos A1 (sobran cédulas: se retiran al azar y se destruyen sin abrirlas) y A2 (faltan
 * cédulas: se continúa); ambos exigen la observación. Sin @Transactional a propósito: el
 * procedimiento abre su transacción (ver ProcedimientoDao).
 */
@Service
public class ValidarTotales {

    private final ProcedimientoDao dao;
    private final EscrutinioConsulta consulta;

    public ValidarTotales(ProcedimientoDao dao, EscrutinioConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 1 ingresarTotalCedulas(total) → 2 verificarTotal(). */
    public Map<String, Object> verificarTotal(Integer idMesa, EscrutinioDto.TotalCedulas datos, Usuario usuario) {
        consulta.mesa(idMesa);
        consulta.exigirCargo(idMesa, usuario, "Contar las cédulas del ánfora", "PRESIDENTE");
        String observacion = datos.observacion() == null || datos.observacion().isBlank() ? null : datos.observacion().trim();
        ProcedimientoDao.Resultado resultado = dao.llamar("sp_contar_cedulas", ProcedimientoDao.SIN_SALIDA,
                idMesa, usuario.getId(), datos.totalCedulas(), Boolean.TRUE.equals(datos.destruidas()), observacion);
        Map<String, Object> validacion = resultado.filas().isEmpty() ? Map.of() : resultado.filas().get(0);

        String mensaje = switch (String.valueOf(validacion.get("resultado"))) {
            case "SOBRAN" -> "A1: se retiraron y destruyeron " + validacion.get("cedulasSobrantes")
                    + " cédula(s) sobrante(s). Se escrutan " + validacion.get("cedulasEscrutadas") + " cédulas.";
            case "FALTAN" -> "A2: faltan " + validacion.get("cedulasFaltantes") + " cédula(s); se continúa con "
                    + validacion.get("cedulasEscrutadas") + " y quedó la observación.";
            default -> "Las " + validacion.get("cedulasContadas") + " cédulas coinciden con los electores que votaron. "
                    + "Lea y clasifique cada cédula.";
        };
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", mensaje);
        respuesta.put("validacion", validacion); // 4: mostrarResultadoValidacion()
        respuesta.put("detalle", consulta.detalle(idMesa));
        return respuesta;
    }
}
