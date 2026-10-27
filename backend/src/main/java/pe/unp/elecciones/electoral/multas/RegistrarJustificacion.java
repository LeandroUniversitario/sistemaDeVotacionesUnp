package pe.unp.elecciones.electoral.multas;

import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS16 · «RegistrarJustificacion» (control). Mensajes 8 a 11 del diagrama de colaboración:
 *
 *   8  registrarJustificacion → PantallaMultas (el CEUNP abre el descargo de la multa)
 *   9  justificar()           → sp_registrar_justificacion (RF106, Disp. Final 2.ª y 5.ª)
 *   10 actualizarEstado()     → multa JUSTIFICADA o EXONERADA; si se deniega sigue PENDIENTE
 *   11 confirmar()            → fila de confirmación y la multa actualizada
 *
 * <p>También registra el pago con el recibo de Tesorería: el sistema no cobra la multa (CUN12).
 */
@Service
public class RegistrarJustificacion {

    private final ProcedimientoDao dao;
    private final MultasConsulta consulta;

    public RegistrarJustificacion(ProcedimientoDao dao, MultasConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 9 justificar() → 10 actualizarEstado() → 11 confirmar(). */
    public Map<String, Object> justificar(Integer idMulta, MultasDto.Justificacion datos, Usuario usuario) {
        Map<String, Object> multa = consulta.multa(idMulta);
        String tipo = datos.tipo().trim().toUpperCase();
        String causal = datos.causal().trim().toUpperCase();
        String decision = "EXONERACION".equals(tipo) ? "ADMITIDA" : MultasConsulta.texto(datos.decision()).trim().toUpperCase();
        if (!MultasConsulta.TIPOS.contains(tipo)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El descargo es una justificación o una exoneración.");
        }
        if (!MultasConsulta.CAUSALES.contains(causal)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Causal del descargo no válida.");
        }
        if (!MultasConsulta.DECISIONES.contains(decision)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Indique si el CEUNP admite o deniega la justificación.");
        }
        ProcedimientoDao.Resultado r = dao.llamar("sp_registrar_justificacion", ProcedimientoDao.SIN_SALIDA, idMulta, usuario.getId(),
                tipo, causal, datos.sustento().trim(), MultasConsulta.vacioANulo(datos.documento()), datos.fechaPresentacion(),
                decision, datos.fundamento().trim(), datos.numeroResolucion().trim(), datos.miembrosPleno());
        if (r.filas().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "El procedimiento no devolvió resultados.");
        }
        Map<String, Object> fila = r.filas().get(0);
        String docente = MultasConsulta.texto(multa.get("docente"));
        String mensaje = "Resolución " + fila.get("numeroResolucion") + ": "
                + ("EXONERACION".equals(tipo) ? "se exonera la multa de " + docente + " (RN40)."
                   : "ADMITIDA".equals(decision) ? "se admite la justificación de " + docente + "; la multa queda justificada (RF106)."
                   : "se deniega la justificación de " + docente + "; la multa sigue pendiente.");
        Map<String, Object> respuesta = new LinkedHashMap<>(consulta.respuesta(mensaje,
                MultasConsulta.numero(multa.get("idProceso")), usuario));
        respuesta.put("confirmacion", fila);
        respuesta.put("multa", consulta.multa(idMulta));
        return respuesta;
    }

    /** Pago registrado con el número de recibo de Tesorería. */
    public Map<String, Object> pagar(Integer idMulta, MultasDto.Pago datos, Usuario usuario) {
        Map<String, Object> multa = consulta.multa(idMulta);
        dao.llamar("sp_registrar_pago_multa", ProcedimientoDao.SIN_SALIDA, idMulta, usuario.getId(), datos.numeroRecibo().trim(),
                datos.fechaPago(), MultasConsulta.vacioANulo(datos.observacion()));
        Map<String, Object> respuesta = new LinkedHashMap<>(consulta.respuesta("Pago registrado con el recibo "
                + datos.numeroRecibo().trim() + " (" + multa.get("docente") + ").", MultasConsulta.numero(multa.get("idProceso")), usuario));
        respuesta.put("multa", consulta.multa(idMulta));
        return respuesta;
    }
}
