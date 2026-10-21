package pe.unp.elecciones.electoral.votacion;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.credenciales.VerificarCredencial;
import pe.unp.elecciones.electoral.service.Bitacora;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS09 · Verificar elector (actor: miembro de mesa).
 *
 * <ol>
 *   <li>identificarElector(QR | DNI): el pase QR (CUS07) se comprueba con VerificarCredencial;
 *       el DNI se busca directamente en el padrón.</li>
 *   <li>consultarPadronMesa: el elector debe figurar en el padrón de ESTA mesa, que debe estar
 *       INSTALADA (CUS08) con el proceso en VOTACION y dentro del horario (RN04, RN06, RN07).</li>
 *   <li>validarNoVoto: no debe haber votado en todos sus cargos ni tener otra autorización pendiente (RN01).</li>
 *   <li>autorizarCabina: registra la autorización (vence en MINUTOS_AUTORIZACION_VOTO); sin ella
 *       EmitirVoto rechaza el voto.</li>
 * </ol>
 *
 * Todas las lecturas y autorizaciones quedan en la bitácora; ninguna guarda el sentido del voto.
 */
@Service
public class VerificarElector {

    private final VotacionConsulta consulta;
    private final VerificarCredencial verificarCredencial;
    private final ProcedimientoDao dao;
    private final Bitacora bitacora;

    public VerificarElector(VotacionConsulta consulta, VerificarCredencial verificarCredencial,
            ProcedimientoDao dao, Bitacora bitacora) {
        this.consulta = consulta;
        this.verificarCredencial = verificarCredencial;
        this.dao = dao;
        this.bitacora = bitacora;
    }

    /** Pantalla de la mesa: datos, totales y padrón con el estado de cada elector. */
    public Map<String, Object> tablero(Integer idMesa) {
        consulta.anularVencidas();
        Map<String, Object> mesa = consulta.mesa(idMesa);
        List<Map<String, Object>> electores = consulta.electoresDeMesa(idMesa);
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mesa", mesa);
        respuesta.put("resumen", consulta.resumen(electores));
        respuesta.put("electores", electores);
        respuesta.put("autorizaciones", consulta.autorizacionesDeMesa(idMesa));
        respuesta.put("minutosAutorizacion", consulta.minutosAutorizacion());
        return respuesta;
    }

    /** 1-3: identifica al elector con el QR leído o con el DNI digitado. */
    public Map<String, Object> verificar(Integer idMesa, String dni, String codigo, Integer idUsuario) {
        consulta.anularVencidas();
        Map<String, Object> mesa = consulta.mesa(idMesa);
        boolean porQR = codigo != null && !codigo.isBlank();
        if (!porQR && (dni == null || dni.isBlank())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Lea el pase QR o digite el DNI del elector.");
        }
        Map<String, Object> ficha = porQR ? porQR(mesa, codigo, idUsuario) : porDni(mesa, normalizarDni(dni));
        ficha.put("metodo", porQR ? "QR" : "DNI");
        ficha.put("mesa", Map.of("id", mesa.get("id"), "numero", mesa.get("numero"), "estado", mesa.get("estado")));

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

    private Map<String, Object> porDni(Map<String, Object> mesa, String dni) {
        Integer idMesa = (Integer) mesa.get("id");
        Map<String, Object> elector = consulta.electorEnMesa(idMesa, dni, null);
        if (elector == null) {
            return noFigura(mesa, dni, null);
        }
        return evaluar(mesa, elector, null);
    }

    private Map<String, Object> porQR(Map<String, Object> mesa, String codigo, Integer idUsuario) {
        Map<String, Object> lectura = verificarCredencial.verificar(codigo, idUsuario);
        if (!Boolean.TRUE.equals(lectura.get("valida"))) {
            return ficha("CREDENCIAL_INVALIDA", false, String.valueOf(lectura.get("mensaje")));
        }
        Map<?, ?> credencial = (Map<?, ?>) lectura.get("credencial");
        if (!"ELECTOR".equals(credencial.get("tipo"))) {
            return ficha("CREDENCIAL_INVALIDA", false,
                    "El QR es un " + credencial.get("titulo") + ", no un pase de votación. Pida el pase o el DNI.");
        }
        Map<?, ?> proceso = (Map<?, ?>) lectura.get("proceso");
        if (!mesa.get("idProceso").equals(proceso.get("id"))) {
            return ficha("CREDENCIAL_INVALIDA", false,
                    "El pase es del proceso «" + proceso.get("nombre") + "», no del proceso de esta mesa.");
        }
        Map<?, ?> titular = (Map<?, ?>) lectura.get("titular");
        Integer idDocente = ((Number) titular.get("idTitular")).intValue();
        Map<String, Object> elector = consulta.electorEnMesa((Integer) mesa.get("id"), null, idDocente);
        if (elector == null) {
            return noFigura(mesa, null, idDocente);
        }
        return evaluar(mesa, elector, ((Number) credencial.get("id")).longValue());
    }

    /** El docente no está en el padrón de esta mesa: se le indica su mesa, si la tiene. */
    private Map<String, Object> noFigura(Map<String, Object> mesa, String dni, Integer idDocente) {
        Map<String, Object> otra = consulta.mesaAsignada((Integer) mesa.get("idProceso"), dni, idDocente);
        if (otra == null) {
            return ficha("NO_FIGURA", false, "RN04: el elector no figura en el padrón del proceso.");
        }
        Map<String, Object> ficha = ficha("OTRA_MESA", false,
                "El elector vota en la mesa " + otra.get("numeroMesa") + " (" + otra.get("ubicacion") + ").");
        ficha.put("mesaAsignada", otra);
        return ficha;
    }

    /** 3: validarNoVoto — decide si el miembro de mesa puede autorizar la cabina. */
    private Map<String, Object> evaluar(Map<String, Object> mesa, Map<String, Object> elector, Long idCredencial) {
        String motivoMesa = VotacionConsulta.motivoNoAtiende(mesa);
        Map<String, Object> ficha;
        switch (String.valueOf(elector.get("estadoElector"))) {
            case "INHABILITADO" -> ficha = ficha("INHABILITADO", false,
                    "RN04: el docente no está habilitado para votar en este proceso.");
            case "VOTO" -> ficha = ficha("YA_VOTO", false,
                    "RN01: el elector ya votó en todos sus cargos.");
            case "AUTORIZADO" -> ficha = ficha("AUTORIZADO", false,
                    "El elector ya tiene la cabina habilitada. Si no la usará, anule la autorización.");
            default -> ficha = motivoMesa != null
                    ? ficha("MESA_NO_ATIENDE", false, motivoMesa)
                    : ficha("APTO", true, "Identidad verificada. Puede habilitar la cabina de votación.");
        }
        ficha.put("elector", elector);
        if (idCredencial != null) {
            ficha.put("idCredencial", idCredencial);
        }
        return ficha;
    }

    /** 4: autorizarCabina — el elector verificado pasa a votar. */
    public Map<String, Object> autorizar(Integer idMesa, Integer idDocente, String metodo, Long idCredencial,
            Integer idUsuario) {
        consulta.anularVencidas();
        Map<String, Object> mesa = consulta.mesa(idMesa);
        String motivoMesa = VotacionConsulta.motivoNoAtiende(mesa);
        if (motivoMesa != null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, motivoMesa);
        }
        String forma = metodo == null ? "" : metodo.trim().toUpperCase(Locale.ROOT);
        if (!forma.equals("QR") && !forma.equals("DNI")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Indique cómo se identificó al elector: QR o DNI.");
        }
        Map<String, Object> elector = consulta.electorEnMesa(idMesa, null, idDocente);
        if (elector == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "RN04: el elector no figura en el padrón de esta mesa.");
        }
        switch (String.valueOf(elector.get("estadoElector"))) {
            case "INHABILITADO" -> throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "RN04: el docente no está habilitado para votar.");
            case "VOTO" -> throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "RN01: el elector ya votó.");
            case "AUTORIZADO" -> throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "El elector ya tiene una autorización pendiente.");
            default -> { }
        }
        Integer idProceso = (Integer) mesa.get("idProceso");
        if (forma.equals("QR")) {
            if (idCredencial == null || dao.entero("""
                    SELECT COUNT(*) FROM credencial_qr
                     WHERE id_credencial = ? AND id_docente = ? AND id_proceso = ?
                       AND tipo = 'ELECTOR' AND estado = 'VIGENTE' AND fecha_expiracion > NOW()
                    """, idCredencial, idDocente, idProceso) == 0) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "El pase QR ya no es válido para este elector. Vuelva a leerlo o use el DNI.");
            }
        } else {
            idCredencial = null;
        }

        dao.ejecutar("""
                INSERT INTO autorizacion_voto
                       (id_proceso, id_mesa, id_docente, metodo, id_credencial, id_usuario_mesa, fecha_expiracion)
                VALUES (?, ?, ?, ?, ?, ?, NOW() + INTERVAL ? MINUTE)
                """, idProceso, idMesa, idDocente, forma, idCredencial, idUsuario, consulta.minutosAutorizacion());

        Map<String, Object> autorizacion = consulta.autorizacionPendiente(idProceso, idDocente);
        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("id_mesa", idMesa);
        detalle.put("id_docente", idDocente);
        detalle.put("metodo", forma);
        detalle.put("id_autorizacion", autorizacion == null ? null : autorizacion.get("idAutorizacion"));
        bitacora.registrar(idUsuario, idProceso, "AUTORIZAR_VOTO", detalle);

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", elector.get("nombre") + " puede pasar a la cabina de votación.");
        respuesta.put("autorizacion", autorizacion);
        respuesta.put("elector", consulta.electorEnMesa(idMesa, null, idDocente));
        return respuesta;
    }

    /** Anula una autorización que no se usó (el elector se retiró o se autorizó por error). */
    public Map<String, Object> anular(Integer idMesa, Long idAutorizacion, String motivo, Integer idUsuario) {
        consulta.verificarInstalacion();
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT id_proceso, id_docente, estado FROM autorizacion_voto
                 WHERE id_autorizacion = ? AND id_mesa = ?
                """, idAutorizacion, idMesa);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "La autorización no existe en esta mesa.");
        }
        if (!"PENDIENTE".equals(filas.get(0).get("estado"))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Solo se anula una autorización PENDIENTE (esta está " + filas.get(0).get("estado") + ").");
        }
        dao.ejecutar("""
                UPDATE autorizacion_voto SET estado = 'ANULADA', motivo_anulacion = ?
                 WHERE id_autorizacion = ? AND estado = 'PENDIENTE'
                """, motivo.trim(), idAutorizacion);

        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("id_mesa", idMesa);
        detalle.put("id_autorizacion", idAutorizacion);
        detalle.put("id_docente", filas.get(0).get("idDocente"));
        detalle.put("motivo", motivo.trim());
        bitacora.registrar(idUsuario, (Integer) filas.get(0).get("idProceso"), "ANULAR_AUTORIZACION_VOTO", detalle);
        return tablero(idMesa);
    }

    private static Map<String, Object> ficha(String resultado, boolean apto, String mensaje) {
        Map<String, Object> ficha = new LinkedHashMap<>();
        ficha.put("resultado", resultado);
        ficha.put("apto", apto);
        ficha.put("mensaje", mensaje);
        return ficha;
    }

    private static String normalizarDni(String dni) {
        String limpio = dni == null ? "" : dni.trim();
        if (limpio.matches("\\d{1,8}")) {
            return String.format("%08d", Long.parseLong(limpio));
        }
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El DNI debe tener hasta 8 dígitos.");
    }
}
