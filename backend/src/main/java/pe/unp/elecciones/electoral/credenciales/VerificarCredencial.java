package pe.unp.elecciones.electoral.credenciales;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.springframework.stereotype.Service;

import pe.unp.elecciones.electoral.service.Bitacora;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS07 · Comprobación de una credencial leída con el LectorQR (cámara o pistola lectora).
 *
 * <p>Se calcula SHA-256 del token leído y se busca en credencial_qr. Además de que exista,
 * esté VIGENTE y no haya vencido, se vuelve a comprobar que el titular SIGA cumpliendo la
 * condición por la que se emitió (habilitado en el padrón, miembro de la mesa, personero
 * acreditado de una lista en carrera). Toda lectura queda en la bitácora, también las
 * fallidas, para detectar intentos con credenciales falsas.
 */
@Service
public class VerificarCredencial {

    /**
     * Formato {@code SICEUNP|E|<64 hex>}. Las pistolas lectoras escriben como un teclado y,
     * según la distribución del teclado, el separador "|" puede llegar cambiado o perderse:
     * por eso se acepta cualquier carácter (o ninguno) como separador y sin distinguir mayúsculas.
     */
    private static final Pattern FORMATO = Pattern.compile(
            "^\\s*SICEUNP.?([EMP]).?([0-9A-F]{64})\\s*$", Pattern.CASE_INSENSITIVE);

    private final ProcedimientoDao dao;
    private final CredencialesConsulta consulta;
    private final Bitacora bitacora;

    public VerificarCredencial(ProcedimientoDao dao, CredencialesConsulta consulta, Bitacora bitacora) {
        this.dao = dao;
        this.consulta = consulta;
        this.bitacora = bitacora;
    }

    public Map<String, Object> verificar(String codigo, Integer idUsuario) {
        consulta.verificarInstalacion();
        Matcher matcher = FORMATO.matcher(codigo == null ? "" : codigo);
        if (!matcher.matches()) {
            return registrar(idUsuario, null, null, resultado("FORMATO_INVALIDO",
                    "El código leído no es una credencial del sistema electoral."));
        }
        TipoCredencial tipoLeido = TipoCredencial.desdeLetra(matcher.group(1).charAt(0));
        String hash = GenerarTokenQR.calcularSHA256(matcher.group(2).toLowerCase(Locale.ROOT));

        List<Map<String, Object>> filas = dao.consultar("""
                SELECT cq.id_credencial, cq.id_proceso, cq.id_docente, cq.tipo, cq.id_mesa, cq.id_personero,
                       cq.estado, cq.fecha_emision, cq.fecha_expiracion, cq.fecha_revocacion, cq.motivo_revocacion,
                       cq.usos, cq.ultimo_uso, p.nombre AS proceso, p.estado AS estado_proceso
                  FROM credencial_qr cq JOIN proceso_electoral p ON p.id_proceso = cq.id_proceso
                 WHERE cq.token_qr_hash = ?
                """, hash);
        if (filas.isEmpty()) {
            return registrar(idUsuario, null, null, resultado("NO_REGISTRADA",
                    "Credencial no registrada: el QR es falso, fue alterado o pertenece a otro sistema."));
        }
        Map<String, Object> cq = filas.get(0);
        Long idCredencial = ((Number) cq.get("idCredencial")).longValue();
        Integer idProceso = ((Number) cq.get("idProceso")).intValue();
        TipoCredencial tipo = TipoCredencial.desdeTexto(String.valueOf(cq.get("tipo")));

        Map<String, Object> titular = datosTitular(cq, tipo);
        Map<String, Object> respuesta;
        if (tipo != tipoLeido) {
            respuesta = resultado("NO_REGISTRADA", "El tipo impreso en el QR no coincide con la credencial registrada.");
        } else if ("REVOCADA".equals(cq.get("estado"))) {
            respuesta = resultado("REVOCADA", "Credencial revocada el " + texto(cq.get("fechaRevocacion")) + ": "
                    + cq.get("motivoRevocacion") + ".");
        } else if (cq.get("fechaExpiracion") instanceof LocalDateTime vence && !vence.isAfter(LocalDateTime.now())) {
            respuesta = resultado("VENCIDA", "Credencial vencida el " + texto(vence) + " (fin del sufragio).");
        } else if (!CredencialesConsulta.ESTADOS_EMISION.contains(String.valueOf(cq.get("estadoProceso")))) {
            respuesta = resultado("VENCIDA", "El proceso electoral está " + cq.get("estadoProceso") + ".");
        } else if (titular == null) {
            respuesta = resultado("SIN_DERECHO", switch (tipo) {
                case ELECTOR -> "El docente ya no figura en el padrón definitivo del proceso.";
                case MIEMBRO_MESA -> "El docente ya no es miembro de la mesa.";
                case PERSONERO -> "La acreditación del personero ya no está vigente.";
            });
        } else if (!Boolean.TRUE.equals(titular.get("apto"))) {
            respuesta = resultado("SIN_DERECHO", String.valueOf(titular.get("motivo")));
        } else {
            respuesta = resultado("VALIDA", tipo.titulo() + " válida.");
            dao.ejecutar("UPDATE credencial_qr SET usos = usos + 1, ultimo_uso = NOW() WHERE id_credencial = ?",
                    idCredencial);
            cq.put("usos", ((Number) cq.get("usos")).intValue() + 1);
        }

        Map<String, Object> credencial = new LinkedHashMap<>();
        credencial.put("id", idCredencial);
        credencial.put("tipo", tipo.name());
        credencial.put("titulo", tipo.titulo());
        credencial.put("estado", cq.get("estado"));
        credencial.put("fechaEmision", cq.get("fechaEmision"));
        credencial.put("fechaExpiracion", cq.get("fechaExpiracion"));
        credencial.put("usos", cq.get("usos"));
        credencial.put("ultimoUsoAnterior", cq.get("ultimoUso"));
        respuesta.put("credencial", credencial);
        respuesta.put("proceso", Map.of("id", idProceso, "nombre", cq.get("proceso"), "estado", cq.get("estadoProceso")));
        if (titular != null) {
            respuesta.put("titular", titular);
        }
        return registrar(idUsuario, idProceso, idCredencial, respuesta);
    }

    /** Datos actuales del titular (null si ya no figura) y observaciones para quien verifica. */
    private Map<String, Object> datosTitular(Map<String, Object> cq, TipoCredencial tipo) {
        Integer idProceso = ((Number) cq.get("idProceso")).intValue();
        Integer idTitular = tipo == TipoCredencial.PERSONERO
                ? ((Number) cq.get("idPersonero")).intValue()
                : ((Number) cq.get("idDocente")).intValue();
        List<Map<String, Object>> filas = consulta.titulares(idProceso, tipo, idTitular, null);
        if (tipo == TipoCredencial.MIEMBRO_MESA) {
            // el fotocheck es de una mesa concreta
            filas = filas.stream().filter(f -> f.get("idMesa").equals(cq.get("idMesa"))).toList();
        }
        if (filas.isEmpty()) {
            return null;
        }
        Map<String, Object> titular = new LinkedHashMap<>(filas.get(0));
        titular.remove("credencial");
        List<String> observaciones = new ArrayList<>();
        if (tipo == TipoCredencial.ELECTOR) {
            int cargos = numero(titular.get("cargos"));
            int votados = numero(titular.get("cargosVotados"));
            if (cargos > 0 && votados >= cargos) {
                observaciones.add("El elector ya votó en todos sus cargos.");
            } else if (votados > 0) {
                observaciones.add("El elector ya votó en " + votados + " de " + cargos + " cargos.");
            }
        }
        if (cq.get("ultimoUso") != null) {
            observaciones.add("Última lectura válida: " + texto(cq.get("ultimoUso")) + ".");
        }
        titular.put("observaciones", observaciones);
        return titular;
    }

    private Map<String, Object> registrar(Integer idUsuario, Integer idProceso, Long idCredencial,
            Map<String, Object> respuesta) {
        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("resultado", respuesta.get("resultado"));
        detalle.put("id_credencial", idCredencial);
        bitacora.registrar(idUsuario, idProceso, "VERIFICAR_CREDENCIAL", detalle);
        return respuesta;
    }

    private static Map<String, Object> resultado(String resultado, String mensaje) {
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("valida", "VALIDA".equals(resultado));
        respuesta.put("resultado", resultado);
        respuesta.put("mensaje", mensaje);
        return respuesta;
    }

    private static final DateTimeFormatter FORMATO_FECHA = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    private static String texto(Object fecha) {
        return fecha instanceof LocalDateTime f ? f.format(FORMATO_FECHA) : String.valueOf(fecha);
    }

    private static int numero(Object valor) {
        return valor instanceof Number n ? n.intValue() : 0;
    }
}
