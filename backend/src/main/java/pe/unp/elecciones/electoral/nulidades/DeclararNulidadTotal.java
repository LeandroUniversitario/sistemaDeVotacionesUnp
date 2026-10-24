package pe.unp.elecciones.electoral.nulidades;

import java.sql.Types;
import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS15 · «DeclararNulidadTotal» (control). Mensajes 5 a 9 del diagrama de colaboración:
 *
 *   5 ingresarNulidadTotal(id_proceso, motivo) → sp_registrar_nulidad('TOTAL') (RF101, Art. 65)
 *   6 anularProceso(id_proceso, motivo)        → sp_resolver_nulidad: FUNDADA anula el proceso, sus mesas y actas
 *   7 actualizarEstado('ANULADO', motivo)      → estado ANULADO y, si había, la segunda vuelta en curso
 *   8 registrarComunicacion('SUNEDU, AU, CU')  → sp_registrar_comunicacion_nulidad (RF102, Art. 66)
 *   9 mostrarResolucionNulidad()               → NulidadesConsulta.nulidad (resolución con huella y QR)
 *
 * <p>También formaliza la nulidad por participación insuficiente que el cómputo detectó (A1 del CUS14).
 */
@Service
public class DeclararNulidadTotal {

    private static final Map<String, String> DESTINATARIO = Map.of(
            "SUNEDU", "a SUNEDU",
            "ASAMBLEA_UNIVERSITARIA", "a la Asamblea Universitaria",
            "CONSEJO_UNIVERSITARIO", "al Consejo Universitario",
            "PORTAL", "al portal electoral",
            "EL_PERUANO", "al diario oficial El Peruano");

    private final ProcedimientoDao dao;
    private final NulidadesConsulta consulta;

    public DeclararNulidadTotal(ProcedimientoDao dao, NulidadesConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 5 ingresarNulidadTotal(id_proceso, motivo). */
    public Map<String, Object> registrar(Integer idProceso, NulidadesDto.RecursoTotal datos, Usuario usuario) {
        consulta.proceso(idProceso);
        String causal = datos.causal().trim().toUpperCase();
        if (!NulidadesConsulta.CAUSALES_TOTAL.contains(causal)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Causal de nulidad total no válida (Art. 65).");
        }
        String origen = datos.origen().trim().toUpperCase();
        ProcedimientoDao.Resultado r = dao.llamar("sp_registrar_nulidad", new int[] {Types.INTEGER}, idProceso, usuario.getId(),
                "TOTAL", null, causal, origen, "PERSONERO".equals(origen) ? datos.idPersonero() : null,
                datos.sustento().trim(), NulidadesConsulta.vacioANulo(datos.pruebas()));
        Map<String, Object> respuesta = consulta.respuesta("Recurso de nulidad total N.º " + r.salidas()[0]
                + " registrado. Mientras esté pendiente no se puede proclamar ni convocar la segunda vuelta (RF94).",
                idProceso, usuario);
        respuesta.put("idNulidad", r.salidas()[0]);
        return respuesta;
    }

    /** 6-7 anularProceso / actualizarEstado('ANULADO', motivo): resolución del Pleno. */
    public Map<String, Object> resolver(Map<String, Object> recurso, NulidadesDto.Resolucion datos, Usuario usuario) {
        Integer idNulidad = NulidadesConsulta.numero(recurso.get("idNulidad"));
        Integer idProceso = NulidadesConsulta.numero(recurso.get("idProceso"));
        Map<String, Object> fila = consulta.resolver(idNulidad, datos, usuario);
        String decision = NulidadesConsulta.texto(fila.get("decision"));
        // El efecto lo redacta sp_resolver_nulidad: anulación del proceso (y de su segunda vuelta) o formalización de A1
        String mensaje = "Resolución " + fila.get("numeroResolucion") + ": nulidad total " + decision.toLowerCase() + ". "
                + NulidadesConsulta.texto(fila.get("efecto"));
        Map<String, Object> respuesta = new LinkedHashMap<>(consulta.respuesta(mensaje, idProceso, usuario));
        respuesta.put("tokenQr", fila.get("tokenQr"));
        respuesta.put("idNulidad", idNulidad);
        return respuesta;
    }

    /** 8 registrarComunicacion: oficio a SUNEDU, AU o CU, o publicación en el portal o El Peruano. */
    public Map<String, Object> comunicar(Integer idNulidad, NulidadesDto.Comunicacion datos, Usuario usuario) {
        Map<String, Object> recurso = consulta.recurso(idNulidad);
        String destinatario = datos.destinatario().trim().toUpperCase();
        if (!NulidadesConsulta.DESTINATARIOS.contains(destinatario)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Destinatario no válido.");
        }
        dao.llamar("sp_registrar_comunicacion_nulidad", ProcedimientoDao.SIN_SALIDA, idNulidad, usuario.getId(), destinatario,
                NulidadesConsulta.vacioANulo(datos.documento()), datos.fechaEnvio(), NulidadesConsulta.vacioANulo(datos.observacion()));
        String mensaje = "PORTAL".equals(destinatario)
                ? "Resolución publicada en el portal electoral (RF102)."
                : "Comunicación " + DESTINATARIO.get(destinatario) + " registrada (RF102).";
        Map<String, Object> respuesta = consulta.respuesta(mensaje, NulidadesConsulta.numero(recurso.get("idProceso")), usuario);
        respuesta.put("nulidad", consulta.nulidad(idNulidad));
        return respuesta;
    }
}
