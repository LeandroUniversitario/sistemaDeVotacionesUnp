package pe.unp.elecciones.electoral.credenciales;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

/**
 * CUS07 · Control «GenerarTokenQR» del diagrama de colaboración.
 *
 * <pre>
 *  PantallaCredenciales --2: crearHash(id_docente)--> GenerarTokenQR
 *  GenerarTokenQR       --   calcularSHA256()     --> GenerarTokenQR   (reflexivo)
 *  GenerarTokenQR       --3: consultarDatos(id_docente)--> Docente
 *  GenerarTokenQR       --4: guardarConstancia(token_hash)--> EmitirConstancia
 * </pre>
 *
 * El token es un número aleatorio de 256 bits (SecureRandom) escrito en hexadecimal.
 * Solo viaja en el QR; en la base se guarda SHA-256(token), así que una copia de la base
 * no permite fabricar credenciales y un QR inventado no coincide con ningún hash.
 */
@Service
public class GenerarTokenQR {

    /** Bytes aleatorios del token (256 bits). */
    static final int BYTES_TOKEN = 32;
    private static final Logger LOG = LoggerFactory.getLogger(GenerarTokenQR.class);
    private static final SecureRandom ALEATORIO = new SecureRandom();

    private final CredencialesConsulta consulta;
    private final EmitirConstancia emitirConstancia;

    public GenerarTokenQR(CredencialesConsulta consulta, EmitirConstancia emitirConstancia) {
        this.consulta = consulta;
        this.emitirConstancia = emitirConstancia;
    }

    /** Token recién generado: el claro (para el QR) y su hash (para la base). */
    public record TokenGenerado(String token, String tokenHash, TipoCredencial tipo, Integer idProceso,
            Map<String, Object> titular) {
    }

    /**
     * 1-7 para un lote de titulares. Cada titular se emite en su propia transacción:
     * si uno no es apto, los demás se emiten igual y el rechazo se informa.
     */
    public Map<String, Object> emitirLote(Integer idProceso, TipoCredencial tipo, List<Integer> ids, Integer idUsuario) {
        consulta.verificarInstalacion();
        Map<String, Object> proceso = consulta.proceso(idProceso);
        exigirAdmision(proceso);

        List<Map<String, Object>> emitidas = new ArrayList<>();
        List<Map<String, Object>> rechazadas = new ArrayList<>();
        for (Integer idTitular : new LinkedHashSet<>(ids)) {
            if (idTitular == null) {
                continue;
            }
            try {
                TokenGenerado generado = crearHash(idProceso, tipo, idTitular);
                emitidas.add(emitirConstancia.guardarConstancia(generado, idUsuario));
            } catch (ResponseStatusException e) {
                rechazadas.add(rechazo(idTitular, e.getReason()));
            } catch (RuntimeException e) {
                // Un error de BD en un titular no debe perder los QR ya emitidos (sus tokens
                // solo existen en esta respuesta): se informa y se sigue con el resto.
                LOG.error("No se pudo emitir la credencial {} {} del proceso {}", tipo, idTitular, idProceso, e);
                rechazadas.add(rechazo(idTitular, "Error al guardar la credencial; intente de nuevo."));
            }
        }
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("proceso", proceso);
        respuesta.put("tipo", tipo.name());
        respuesta.put("emitidas", emitidas);
        respuesta.put("rechazadas", rechazadas);
        respuesta.put("mensaje", emitidas.size() + " credencial(es) emitida(s)"
                + (rechazadas.isEmpty() ? "." : "; " + rechazadas.size() + " rechazada(s)."));
        return respuesta;
    }

    /** El docente genera (o vuelve a generar) una credencial propia. */
    public Map<String, Object> emitirPropia(Integer idProceso, TipoCredencial tipo, Integer idTitular,
            Integer idDocente, Integer idUsuario) {
        consulta.verificarInstalacion();
        exigirAdmision(consulta.proceso(idProceso));
        Map<String, Object> titular = consulta.titular(idProceso, tipo, idTitular);
        if (!idDocente.equals(((Number) titular.get("idDocente")).intValue())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Solo puede generar sus propias credenciales.");
        }
        return emitirConstancia.guardarConstancia(crearHash(idProceso, tipo, idTitular), idUsuario);
    }

    /** 2: crearHash(id_docente) — valida al titular, genera el token y calcula su hash. */
    public TokenGenerado crearHash(Integer idProceso, TipoCredencial tipo, Integer idTitular) {
        Map<String, Object> titular = consultarDatos(idProceso, tipo, idTitular);
        if (!Boolean.TRUE.equals(titular.get("apto"))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    titular.get("nombre") + ": " + titular.get("motivo"));
        }
        String token = generarToken();
        return new TokenGenerado(token, calcularSHA256(token), tipo, idProceso, titular);
    }

    /** 3: consultarDatos(id_docente) — datos del docente y de su función en el proceso. */
    public Map<String, Object> consultarDatos(Integer idProceso, TipoCredencial tipo, Integer idTitular) {
        return consulta.titular(idProceso, tipo, idTitular);
    }

    /** calcularSHA256() — huella hexadecimal (64 caracteres, minúsculas) del token. */
    public static String calcularSHA256(String texto) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(texto.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 no disponible en la JVM", e);
        }
    }

    /** Token aleatorio de 256 bits en hexadecimal (64 caracteres, minúsculas). */
    static String generarToken() {
        byte[] bytes = new byte[BYTES_TOKEN];
        ALEATORIO.nextBytes(bytes);
        return HexFormat.of().formatHex(bytes);
    }

    private static Map<String, Object> rechazo(Integer idTitular, String motivo) {
        Map<String, Object> rechazo = new LinkedHashMap<>();
        rechazo.put("idTitular", idTitular);
        rechazo.put("motivo", motivo);
        return rechazo;
    }

    private static void exigirAdmision(Map<String, Object> proceso) {
        if (!Boolean.TRUE.equals(proceso.get("admiteEmision"))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, String.valueOf(proceso.get("motivoNoAdmite")));
        }
    }
}
