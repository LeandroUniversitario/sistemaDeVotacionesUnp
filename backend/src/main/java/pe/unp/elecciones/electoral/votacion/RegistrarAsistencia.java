package pe.unp.elecciones.electoral.votacion;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.service.Bitacora;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS09 · «RegistrarAsistencia» (capa de control).
 *
 * <ul>
 *   <li>6 registrarAsistencia(): asistencia con hora, en un registro separado del voto; bloquea un
 *       segundo ingreso (RF64). No marca al elector como votado.</li>
 *   <li>7 habilitarTerminal(): habilitación de un solo uso para ese elector en un terminal LIBRE (RF67).
 *       El elector pasa a HABILITADO.</li>
 *   <li>A5 suplantación, CUS10 A3 abandono del terminal y rehabilitación por el Presidente,
 *       CUS10 A4 terminal fuera de servicio.</li>
 * </ul>
 *
 * Solo SQL simple (sin procedimientos), por eso puede ir en una transacción de Spring.
 */
@Service
public class RegistrarAsistencia {

    private final VotacionConsulta consulta;
    private final ProcedimientoDao dao;
    private final Bitacora bitacora;
    private final TransactionTemplate transaccion;

    public RegistrarAsistencia(VotacionConsulta consulta, ProcedimientoDao dao, Bitacora bitacora,
            PlatformTransactionManager transactionManager) {
        this.consulta = consulta;
        this.dao = dao;
        this.bitacora = bitacora;
        this.transaccion = new TransactionTemplate(transactionManager);
    }

    /** 5 confirmarConDNI() → 6 registrarAsistencia() → 7 habilitarTerminal(). */
    public Map<String, Object> confirmar(Integer idMesa, Integer idDocente, String metodo, Long idCredencial,
            Integer idTerminal, Integer idUsuario) {
        Map<String, Object> mesa = consulta.mesa(idMesa);
        VotacionConsulta.exigirQueAtienda(mesa);
        Integer idProceso = (Integer) mesa.get("idProceso");
        String forma = metodo == null ? "" : metodo.trim().toUpperCase(Locale.ROOT);
        if (!forma.equals("QR") && !forma.equals("DNI")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Indique cómo se identificó al elector: QR o DNI.");
        }
        Map<String, Object> elector = consulta.electorEnMesa(idMesa, null, idDocente);
        if (elector == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "RN30: el elector no figura en el padrón de esta mesa.");
        }
        switch (String.valueOf(elector.get("estadoElector"))) {
            case "PENDIENTE" -> { }
            case "INHABILITADO" -> throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "RN04: el docente no está habilitado para votar.");
            case "VOTO" -> throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "RN01: el elector ya votó.");
            default -> throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "RF64: la asistencia del elector ya fue registrada.");
        }
        if (forma.equals("QR")) {
            if (idCredencial == null || dao.entero("""
                    SELECT COUNT(*) FROM credencial_qr
                     WHERE id_credencial = ? AND id_docente = ? AND id_proceso = ?
                       AND tipo = 'ELECTOR' AND estado = 'VIGENTE' AND fecha_expiracion > NOW()
                    """, idCredencial, idDocente, idProceso) == 0) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "El pase QR ya no es válido. Verifique al elector por su DNI.");
            }
        } else {
            idCredencial = null;
        }
        exigirTerminalLibre(idMesa, idTerminal);

        final Long credencial = idCredencial;
        Long idHabilitacion = transaccion.execute(estado -> {
            dao.ejecutar("""
                    INSERT INTO asistencia_elector (id_proceso, id_mesa, id_docente, metodo, id_credencial, id_usuario_mesa)
                    VALUES (?, ?, ?, ?, ?, ?)
                    """, idProceso, idMesa, idDocente, forma, credencial, idUsuario);
            Long idAsistencia = idAsistencia(idProceso, idDocente);
            return habilitarTerminal(idAsistencia, idTerminal, false, idUsuario);
        });

        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("id_mesa", idMesa);
        detalle.put("id_docente", idDocente);
        detalle.put("metodo", forma);
        detalle.put("id_terminal", idTerminal);
        detalle.put("id_habilitacion", idHabilitacion);
        bitacora.registrar(idUsuario, idProceso, "REGISTRAR_ASISTENCIA", detalle);
        return respuesta(idMesa, idDocente, elector.get("nombre") + " puede pasar al terminal "
                + consulta.terminal(idTerminal).get("nombre") + ".");
    }

    /** CUS09 A5: el DNI no corresponde al elector. Se rechaza el ingreso y se registra el motivo (RF66). */
    public Map<String, Object> rechazar(Integer idMesa, Integer idDocente, String dni, String motivo, Integer idUsuario) {
        Map<String, Object> mesa = consulta.mesa(idMesa);
        String detalle = (dni == null || dni.isBlank() ? "" : "DNI presentado " + VerificarElector.normalizarDni(dni) + ". ")
                + motivo.trim();
        consulta.registrarIncidencia((Integer) mesa.get("idProceso"), idMesa, idDocente, "SUPLANTACION", detalle, idUsuario);
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Ingreso rechazado. Se registró la incidencia de suplantación.");
        respuesta.put("incidencias", consulta.incidencias(idMesa));
        return respuesta;
    }

    /** CUS10 A3: el elector abandona el terminal sin confirmar. Queda HABILITADO_SIN_VOTAR. */
    public Map<String, Object> anularHabilitacion(Integer idMesa, Long idHabilitacion, String motivo, Integer idUsuario) {
        Map<String, Object> mesa = consulta.mesa(idMesa);
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT h.estado, a.id_docente FROM habilitacion_terminal h
                  JOIN asistencia_elector a ON a.id_asistencia = h.id_asistencia
                 WHERE h.id_habilitacion = ? AND a.id_mesa = ?
                """, idHabilitacion, idMesa);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "La habilitación no existe en esta mesa.");
        }
        int cambios = dao.ejecutar("""
                UPDATE habilitacion_terminal SET estado = 'ANULADA', fecha_cierre = NOW(), motivo_anulacion = ?
                 WHERE id_habilitacion = ? AND estado = 'PENDIENTE'
                """, motivo.trim(), idHabilitacion);
        if (cambios == 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La habilitación ya fue usada o anulada.");
        }
        Integer idDocente = (Integer) filas.get(0).get("idDocente");
        consulta.registrarIncidencia((Integer) mesa.get("idProceso"), idMesa, idDocente, "ABANDONO_TERMINAL",
                motivo.trim(), idUsuario);
        return respuesta(idMesa, idDocente, "Se anuló la habilitación. El elector queda como «habilitado sin votar».");
    }

    /** CUS10 A3 / A5: el Presidente autoriza la rehabilitación del terminal para un elector que no votó. */
    public Map<String, Object> rehabilitar(Integer idMesa, Integer idDocente, Integer idTerminal, String motivo,
            Integer idUsuario) {
        Map<String, Object> mesa = consulta.mesa(idMesa);
        VotacionConsulta.exigirQueAtienda(mesa);
        Map<String, Object> elector = consulta.electorEnMesa(idMesa, null, idDocente);
        if (elector == null || !"HABILITADO_SIN_VOTAR".equals(elector.get("estadoElector"))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Solo se rehabilita a un elector con asistencia registrada que aún no votó y sin terminal habilitado.");
        }
        exigirTerminalLibre(idMesa, idTerminal);
        Long idAsistencia = ((Number) elector.get("idAsistencia")).longValue();
        Long idHabilitacion = transaccion.execute(estado -> habilitarTerminal(idAsistencia, idTerminal, true, idUsuario));
        consulta.registrarIncidencia((Integer) mesa.get("idProceso"), idMesa, idDocente, "REHABILITACION",
                motivo.trim() + " (habilitación " + idHabilitacion + ")", idUsuario);
        return respuesta(idMesa, idDocente, "Terminal rehabilitado para " + elector.get("nombre") + ".");
    }

    /** CUS10 A4: el terminal falla (fuera de servicio) o vuelve a operar. */
    public List<Map<String, Object>> cambiarEstadoTerminal(Integer idMesa, Integer idTerminal, boolean activo,
            Integer idUsuario) {
        Map<String, Object> terminal = consulta.terminal(idTerminal);
        if (!idMesa.equals(terminal.get("idMesa"))) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El terminal no es de esta mesa.");
        }
        if (!activo && dao.entero("SELECT COUNT(*) FROM habilitacion_terminal WHERE id_terminal = ? AND estado = 'PENDIENTE'",
                idTerminal) > 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "El terminal tiene un elector habilitado: anule primero esa habilitación y rehabilítelo en otro terminal.");
        }
        dao.ejecutar("UPDATE terminal_votacion SET activo = ? WHERE id_terminal = ?", activo, idTerminal);
        if (!activo) {
            consulta.registrarIncidencia((Integer) consulta.mesa(idMesa).get("idProceso"), idMesa, null, "FALLA_TERMINAL",
                    "Terminal " + terminal.get("nombre") + " fuera de servicio.", idUsuario);
        }
        return consulta.terminales(idMesa);
    }

    private void exigirTerminalLibre(Integer idMesa, Integer idTerminal) {
        Map<String, Object> terminal = consulta.terminales(idMesa).stream()
                .filter(t -> idTerminal != null && idTerminal.equals(t.get("idTerminal"))).findFirst()
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "El terminal no es de esta mesa."));
        if (!"LIBRE".equals(terminal.get("estadoTerminal"))) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "El terminal " + terminal.get("nombre") + " no está libre (" + terminal.get("estadoTerminal") + ").");
        }
    }

    /** 7 habilitarTerminal(): el token se genera cuando el terminal la toma (RegistrarVoto). */
    private Long habilitarTerminal(Long idAsistencia, Integer idTerminal, boolean rehabilitacion, Integer idUsuario) {
        dao.ejecutar("""
                INSERT INTO habilitacion_terminal (id_asistencia, id_terminal, rehabilitacion, id_usuario_mesa)
                VALUES (?, ?, ?, ?)
                """, idAsistencia, idTerminal, rehabilitacion, idUsuario);
        return ((Number) dao.consultar("""
                SELECT id_habilitacion FROM habilitacion_terminal WHERE id_asistencia = ? AND estado = 'PENDIENTE'
                """, idAsistencia).get(0).get("idHabilitacion")).longValue();
    }

    private Long idAsistencia(Integer idProceso, Integer idDocente) {
        return ((Number) dao.consultar("SELECT id_asistencia FROM asistencia_elector WHERE id_proceso = ? AND id_docente = ?",
                idProceso, idDocente).get(0).get("idAsistencia")).longValue();
    }

    private Map<String, Object> respuesta(Integer idMesa, Integer idDocente, String mensaje) {
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", mensaje);
        respuesta.put("elector", consulta.electorEnMesa(idMesa, null, idDocente));
        respuesta.put("terminales", consulta.terminales(idMesa));
        return respuesta;
    }
}
