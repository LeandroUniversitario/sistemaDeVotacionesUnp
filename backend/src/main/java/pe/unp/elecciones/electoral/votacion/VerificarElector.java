package pe.unp.elecciones.electoral.votacion;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.credenciales.VerificarCredencial;
import pe.unp.elecciones.electoral.service.Bitacora;

/**
 * CUS09 · Verificar elector con QR («VerificarElector», capa de control).
 *
 * <ol>
 *   <li>2 verificar(token): el pase QR (CUS07) se valida con VerificarCredencial (vigente, no revocado).
 *       A1: si el QR no se puede leer, se busca por DNI. A2: código inválido → alerta e incidencia.</li>
 *   <li>3 consultarHabilitacion(): PadronMesa de ESTA mesa, habilitado y sin voto previo (RF63).
 *       A3: no figura u otra mesa → no vota (RN30) e incidencia. A4: ya registrado → bloquea e incidencia.</li>
 *   <li>4 mostrarDatosYFoto(): nombres y fotografía del padrón para comparar con el DNI (RF62).</li>
 * </ol>
 *
 * La confirmación (5) y el registro de asistencia (6, 7) están en RegistrarAsistencia.
 */
@Service
public class VerificarElector {

    private final VotacionConsulta consulta;
    private final VerificarCredencial verificarCredencial;
    private final Bitacora bitacora;

    public VerificarElector(VotacionConsulta consulta, VerificarCredencial verificarCredencial, Bitacora bitacora) {
        this.consulta = consulta;
        this.verificarCredencial = verificarCredencial;
        this.bitacora = bitacora;
    }

    /** PantallaVerificacion: mesa, totales, padrón, terminales e incidencias. */
    public Map<String, Object> tablero(Integer idMesa, Integer idDocenteUsuario, boolean supervisor) {
        Map<String, Object> mesa = consulta.mesa(idMesa);
        List<Map<String, Object>> electores = consulta.electoresDeMesa(idMesa);
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mesa", mesa);
        respuesta.put("resumen", consulta.resumen(electores));
        respuesta.put("electores", electores);
        respuesta.put("terminales", consulta.terminales(idMesa));
        respuesta.put("incidencias", consulta.incidencias(idMesa));
        respuesta.put("puedeRehabilitar", supervisor || consulta.esPresidente(idMesa, idDocenteUsuario));
        return respuesta;
    }

    /** 1 escanearQR() → 2 verificar(token) → 3 consultarHabilitacion() → 4 mostrarDatosYFoto(). */
    public Map<String, Object> verificar(Integer idMesa, String dni, String codigo, Integer idUsuario) {
        Map<String, Object> mesa = consulta.mesa(idMesa);
        VotacionConsulta.exigirQueAtienda(mesa);
        boolean porQR = codigo != null && !codigo.isBlank();
        if (!porQR && (dni == null || dni.isBlank())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Escanee el QR o digite el DNI del elector.");
        }
        Map<String, Object> ficha = porQR ? porQR(mesa, codigo, idUsuario) : porDni(mesa, normalizarDni(dni), idUsuario);
        ficha.put("metodo", porQR ? "QR" : "DNI");
        ficha.put("terminalesLibres", consulta.terminales(idMesa).stream()
                .filter(t -> "LIBRE".equals(t.get("estadoTerminal"))).toList());

        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("id_mesa", idMesa);
        detalle.put("metodo", ficha.get("metodo"));
        detalle.put("resultado", ficha.get("resultado"));
        if (ficha.get("elector") instanceof Map<?, ?> elector) {
            detalle.put("id_docente", elector.get("idDocente"));
        }
        bitacora.registrar(idUsuario, (Integer) mesa.get("idProceso"), "VERIFICAR_ELECTOR", detalle);
        return ficha;
    }

    private Map<String, Object> porDni(Map<String, Object> mesa, String dni, Integer idUsuario) {
        Map<String, Object> elector = consulta.electorEnMesa((Integer) mesa.get("id"), dni, null);
        if (elector == null) {
            return noFigura(mesa, dni, null, idUsuario);
        }
        return evaluar(mesa, elector, null, idUsuario);
    }

    private Map<String, Object> porQR(Map<String, Object> mesa, String codigo, Integer idUsuario) {
        Integer idMesa = (Integer) mesa.get("id");
        Integer idProceso = (Integer) mesa.get("idProceso");
        Map<String, Object> lectura = verificarCredencial.verificar(codigo, idUsuario);
        if (!Boolean.TRUE.equals(lectura.get("valida"))) {
            return qrInvalido(idProceso, idMesa, String.valueOf(lectura.get("mensaje")), idUsuario);
        }
        Map<?, ?> credencial = (Map<?, ?>) lectura.get("credencial");
        if (!"ELECTOR".equals(credencial.get("tipo"))) {
            return qrInvalido(idProceso, idMesa,
                    "El QR es un " + credencial.get("titulo") + ", no un pase de votación.", idUsuario);
        }
        Map<?, ?> proceso = (Map<?, ?>) lectura.get("proceso");
        if (!idProceso.equals(proceso.get("id"))) {
            return qrInvalido(idProceso, idMesa,
                    "El pase es del proceso «" + proceso.get("nombre") + "», no del proceso de esta mesa.", idUsuario);
        }
        Integer idDocente = ((Number) ((Map<?, ?>) lectura.get("titular")).get("idTitular")).intValue();
        Map<String, Object> elector = consulta.electorEnMesa(idMesa, null, idDocente);
        if (elector == null) {
            return noFigura(mesa, null, idDocente, idUsuario);
        }
        return evaluar(mesa, elector, ((Number) credencial.get("id")).longValue(), idUsuario);
    }

    /** A2: código inválido o revocado → alerta, verificar por DNI e incidencia. */
    private Map<String, Object> qrInvalido(Integer idProceso, Integer idMesa, String motivo, Integer idUsuario) {
        consulta.registrarIncidencia(idProceso, idMesa, null, "QR_INVALIDO", motivo, idUsuario);
        return ficha("QR_INVALIDO", false, motivo + " Verifique al elector por su DNI.");
    }

    /** A3: no figura en el padrón de esta mesa; si es de otra mesa, se indica sin habilitarlo. */
    private Map<String, Object> noFigura(Map<String, Object> mesa, String dni, Integer idDocente, Integer idUsuario) {
        Integer idProceso = (Integer) mesa.get("idProceso");
        Map<String, Object> otra = consulta.mesaAsignada(idProceso, dni, idDocente);
        if (otra == null) {
            consulta.registrarIncidencia(idProceso, (Integer) mesa.get("id"), idDocente, "NO_FIGURA",
                    dni == null ? "No figura en el padrón." : "DNI " + dni + " no figura en el padrón.", idUsuario);
            return ficha("NO_FIGURA", false, "RN30: el elector no figura en el padrón del proceso. No vota.");
        }
        consulta.registrarIncidencia(idProceso, (Integer) mesa.get("id"), (Integer) otra.get("idDocente"), "OTRA_MESA",
                "Vota en la mesa " + otra.get("numeroMesa") + ".", idUsuario);
        Map<String, Object> ficha = ficha("OTRA_MESA", false,
                otra.get("nombre") + " vota en la mesa " + otra.get("numeroMesa") + " (" + otra.get("ubicacion") + ").");
        ficha.put("mesaAsignada", otra);
        return ficha;
    }

    /** 3 consultarHabilitacion(): RF63 y A4. */
    private Map<String, Object> evaluar(Map<String, Object> mesa, Map<String, Object> elector, Long idCredencial,
            Integer idUsuario) {
        Integer idProceso = (Integer) mesa.get("idProceso");
        Integer idMesa = (Integer) mesa.get("id");
        Integer idDocente = (Integer) elector.get("idDocente");
        Map<String, Object> ficha = switch (String.valueOf(elector.get("estadoElector"))) {
            case "PENDIENTE" -> ficha("APTO", true,
                    "Compare los nombres y la fotografía con el DNI y con el rostro del elector antes de confirmar.");
            case "INHABILITADO" -> {
                consulta.registrarIncidencia(idProceso, idMesa, idDocente, "INHABILITADO",
                        "Inhabilitado en el padrón.", idUsuario);
                yield ficha("INHABILITADO", false, "RN04: el docente no está habilitado para votar. No vota.");
            }
            case "VOTO" -> {
                consulta.registrarIncidencia(idProceso, idMesa, idDocente, "YA_REGISTRADO",
                        "Intentó ingresar después de votar.", idUsuario);
                yield ficha("YA_VOTO", false, "RN01: el elector ya votó. Se registró la incidencia.");
            }
            case "HABILITADO" -> ficha("HABILITADO", false,
                    "El elector ya tiene habilitado el terminal " + elector.get("terminal") + ".");
            default -> {
                consulta.registrarIncidencia(idProceso, idMesa, idDocente, "YA_REGISTRADO",
                        "Asistencia ya registrada y sin voto.", idUsuario);
                yield ficha("YA_REGISTRADO", false,
                        "A4: la asistencia ya fue registrada y el elector no votó. Solo el Presidente puede rehabilitar el terminal.");
            }
        };
        ficha.put("elector", elector);
        if (idCredencial != null) {
            ficha.put("idCredencial", idCredencial);
        }
        return ficha;
    }

    private static Map<String, Object> ficha(String resultado, boolean apto, String mensaje) {
        Map<String, Object> ficha = new LinkedHashMap<>();
        ficha.put("resultado", resultado);
        ficha.put("apto", apto);
        ficha.put("mensaje", mensaje);
        return ficha;
    }

    static String normalizarDni(String dni) {
        String limpio = dni == null ? "" : dni.trim();
        if (limpio.matches("\\d{1,8}")) {
            return String.format("%08d", Long.parseLong(limpio));
        }
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El DNI debe tener hasta 8 dígitos.");
    }
}
