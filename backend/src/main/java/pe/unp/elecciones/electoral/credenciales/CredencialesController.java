package pe.unp.elecciones.electoral.credenciales;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.UsuarioActual;
import pe.unp.elecciones.electoral.credenciales.CredencialesDto.AtencionSolicitud;
import pe.unp.elecciones.electoral.credenciales.CredencialesDto.DatosRevocacion;
import pe.unp.elecciones.electoral.credenciales.CredencialesDto.SolicitudEmision;
import pe.unp.elecciones.electoral.credenciales.CredencialesDto.SolicitudPropia;
import pe.unp.elecciones.electoral.credenciales.CredencialesDto.SolicitudRegeneracion;
import pe.unp.elecciones.electoral.credenciales.CredencialesDto.SolicitudVerificacion;
import pe.unp.elecciones.electoral.service.Bitacora;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS07 · Emitir credenciales y QR (actor: CEUNP).
 *
 * <ul>
 *   <li>POST /api/credenciales/procesos/{id}/emitir → 1: solicitarCredencial(id_docente) …
 *       GenerarTokenQR (2-4) → EmitirConstancia (4-6) → el LectorQR muestra la credencial (7)</li>
 *   <li>POST /api/credenciales/verificar           → lectura del QR en la jornada</li>
 *   <li>GET/POST /api/credenciales/mias            → credenciales del titular</li>
 *   <li>POST /api/credenciales/solicitar-regeneracion → solicitud al CEUNP para regenerar QR</li>
 *   <li>GET/POST /api/credenciales/solicitudes     → atención de solicitudes por el CEUNP</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/credenciales")
public class CredencialesController {

    private final CredencialesConsulta consulta;
    private final GenerarTokenQR generarTokenQR;
    private final EmitirConstancia emitirConstancia;
    private final VerificarCredencial verificarCredencial;
    private final UsuarioActual usuarioActual;
    private final ProcedimientoDao dao;
    private final Bitacora bitacora;

    public CredencialesController(CredencialesConsulta consulta, GenerarTokenQR generarTokenQR,
            EmitirConstancia emitirConstancia, VerificarCredencial verificarCredencial, UsuarioActual usuarioActual,
            ProcedimientoDao dao, Bitacora bitacora) {
        this.consulta = consulta;
        this.generarTokenQR = generarTokenQR;
        this.emitirConstancia = emitirConstancia;
        this.verificarCredencial = verificarCredencial;
        this.usuarioActual = usuarioActual;
        this.dao = dao;
        this.bitacora = bitacora;
    }

    // ─── CEUNP ───────────────────────────────────────────────────────────────

    @GetMapping("/procesos")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public List<Map<String, Object>> procesos() {
        return consulta.procesos();
    }

    @GetMapping("/procesos/{idProceso}")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public Map<String, Object> detalle(@PathVariable Integer idProceso,
            @RequestParam(name = "tipo", defaultValue = "ELECTOR") String tipo) {
        return consulta.detalle(idProceso, TipoCredencial.desdeTexto(tipo));
    }

    @GetMapping("/procesos/{idProceso}/historial")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public List<Map<String, Object>> historial(@PathVariable Integer idProceso) {
        return consulta.historial(idProceso);
    }

    /** 1: solicitarCredencial(id_docente) — uno o varios titulares del mismo tipo. */
    @PostMapping("/procesos/{idProceso}/emitir")
    @PreAuthorize("hasRole('CEUNP')")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> emitir(@PathVariable Integer idProceso, @Valid @RequestBody SolicitudEmision solicitud,
            Authentication authentication) {
        return generarTokenQR.emitirLote(idProceso, TipoCredencial.desdeTexto(solicitud.tipo()), solicitud.ids(),
                usuarioActual.id(authentication));
    }

    @PostMapping("/{idCredencial}/revocar")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> revocar(@PathVariable Long idCredencial, @Valid @RequestBody DatosRevocacion datos,
            Authentication authentication) {
        return emitirConstancia.revocar(idCredencial, datos.motivo(), usuarioActual.id(authentication));
    }

    // ─── Jornada: lectura del QR ─────────────────────────────────────────────

    @PostMapping("/verificar")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP', 'MIEMBRO_MESA')")
    public Map<String, Object> verificar(@Valid @RequestBody SolicitudVerificacion solicitud,
            Authentication authentication) {
        return verificarCredencial.verificar(solicitud.codigo(), usuarioActual.id(authentication));
    }

    // ─── Credenciales propias (docente, miembro de mesa, personero) ─────────

    @GetMapping("/mias")
    @PreAuthorize("hasAnyRole('DOCENTE', 'MIEMBRO_MESA', 'PERSONERO')")
    public List<Map<String, Object>> mias(Authentication authentication) {
        return consulta.misCredenciales(usuarioActual.idDocenteRequerido(authentication));
    }

    @PostMapping("/mias")
    @PreAuthorize("hasAnyRole('DOCENTE', 'MIEMBRO_MESA', 'PERSONERO')")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> generarPropia(@Valid @RequestBody SolicitudPropia solicitud,
            Authentication authentication) {
        return generarTokenQR.emitirPropia(solicitud.idProceso(), TipoCredencial.desdeTexto(solicitud.tipo()),
                solicitud.idTitular(), usuarioActual.idDocenteRequerido(authentication),
                usuarioActual.id(authentication));
    }

    // ─── Solicitudes de regeneración de QR (CUS07) ──────────────────────────

    @GetMapping("/solicitud-vigente")
    @PreAuthorize("hasAnyRole('DOCENTE', 'MIEMBRO_MESA', 'PERSONERO')")
    public Map<String, Object> solicitudVigente(@RequestParam Integer idProceso, @RequestParam String tipo,
            Authentication authentication) {
        Integer idDocente = usuarioActual.idDocenteRequerido(authentication);
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT id_solicitud, id_proceso, id_docente, tipo, id_titular, motivo, estado,
                       fecha_solicitud, fecha_atencion, observacion_atencion
                  FROM solicitud_regeneracion_qr
                 WHERE id_proceso = ? AND id_docente = ? AND tipo = ?
                 ORDER BY fecha_solicitud DESC
                 LIMIT 1
                """, idProceso, idDocente, tipo);
        return filas.isEmpty() ? Map.of("tieneSolicitud", false) : Map.of("tieneSolicitud", true, "solicitud", filas.get(0));
    }

    @PostMapping("/solicitar-regeneracion")
    @PreAuthorize("hasAnyRole('DOCENTE', 'MIEMBRO_MESA', 'PERSONERO')")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> solicitarRegeneracion(@Valid @RequestBody SolicitudRegeneracion solicitud,
            Authentication authentication) {
        Integer idDocente = usuarioActual.idDocenteRequerido(authentication);
        Integer idUsuario = usuarioActual.id(authentication);

        int pendientes = dao.entero("""
                SELECT COUNT(*) FROM solicitud_regeneracion_qr
                 WHERE id_proceso = ? AND id_docente = ? AND tipo = ? AND estado = 'PENDIENTE'
                """, solicitud.idProceso(), idDocente, solicitud.tipo());
        if (pendientes > 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Ya tiene una solicitud de regeneración de QR pendiente de evaluación por el CEUNP.");
        }

        Integer idTitular = solicitud.idTitular();
        if (idTitular == null) {
            idTitular = idDocente;
        }

        dao.ejecutar("""
                INSERT INTO solicitud_regeneracion_qr (id_proceso, id_docente, tipo, id_titular, motivo, estado)
                VALUES (?, ?, ?, ?, ?, 'PENDIENTE')
                """, solicitud.idProceso(), idDocente, solicitud.tipo(), idTitular, solicitud.motivo());

        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("id_proceso", solicitud.idProceso());
        detalle.put("id_docente", idDocente);
        detalle.put("tipo", solicitud.tipo());
        detalle.put("motivo", solicitud.motivo());
        bitacora.registrar(idUsuario, solicitud.idProceso(), "SOLICITAR_REGENERACION_QR", detalle);

        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("mensaje", "Solicitud de regeneración de QR enviada exitosamente al CEUNP. El comité evaluará su pedido.");
        resp.put("estado", "PENDIENTE");
        return resp;
    }

    @GetMapping("/procesos/{idProceso}/solicitudes")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public List<Map<String, Object>> listarSolicitudes(@PathVariable Integer idProceso) {
        return dao.consultar("""
                SELECT s.id_solicitud, s.id_proceso, s.id_docente, s.tipo, s.id_titular, s.motivo, s.estado,
                       s.fecha_solicitud, s.fecha_atencion, s.observacion_atencion,
                       d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS nombre_docente,
                       d.categoria, f.nombre AS facultad,
                       u.username AS atendido_por
                  FROM solicitud_regeneracion_qr s
                  JOIN docente d ON d.id_docente = s.id_docente
                  LEFT JOIN facultad f ON f.id_facultad = d.id_facultad
                  LEFT JOIN usuario u ON u.id_usuario = s.id_usuario_atencion
                 WHERE s.id_proceso = ?
                 ORDER BY (s.estado = 'PENDIENTE') DESC, s.fecha_solicitud DESC
                """, idProceso);
    }

    @PostMapping("/solicitudes/{idSolicitud}/aprobar")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> aprobarSolicitud(@PathVariable Integer idSolicitud, Authentication authentication) {
        Integer idAdmin = usuarioActual.id(authentication);
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT id_solicitud, id_proceso, id_docente, tipo, id_titular, estado
                  FROM solicitud_regeneracion_qr
                 WHERE id_solicitud = ?
                """, idSolicitud);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Solicitud no encontrada.");
        }
        Map<String, Object> sol = filas.get(0);
        if (!"PENDIENTE".equals(sol.get("estado"))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Esta solicitud ya fue atendida.");
        }

        Integer idProceso = ((Number) sol.get("idProceso")).intValue();
        TipoCredencial tipo = TipoCredencial.desdeTexto((String) sol.get("tipo"));
        Integer idTitular = ((Number) (sol.get("idTitular") != null ? sol.get("idTitular") : sol.get("idDocente"))).intValue();

        // Regenerar emitiendo una nueva credencial (revoca automáticamente la anterior)
        GenerarTokenQR.TokenGenerado generado = generarTokenQR.crearHash(idProceso, tipo, idTitular);
        Map<String, Object> nuevaCredencial = emitirConstancia.guardarConstancia(generado, idAdmin);

        dao.ejecutar("""
                UPDATE solicitud_regeneracion_qr
                   SET estado = 'APROBADA', fecha_atencion = NOW(), id_usuario_atencion = ?
                 WHERE id_solicitud = ?
                """, idAdmin, idSolicitud);

        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("id_solicitud", idSolicitud);
        detalle.put("id_proceso", idProceso);
        detalle.put("tipo", tipo.name());
        detalle.put("id_docente", sol.get("idDocente"));
        detalle.put("resultado", "APROBADA");
        bitacora.registrar(idAdmin, idProceso, "APROBAR_REGENERACION_QR", detalle);

        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("mensaje", "Solicitud aprobada y nuevo QR emitido exitosamente para el titular.");
        resp.put("credencial", nuevaCredencial);
        return resp;
    }

    @PostMapping("/solicitudes/{idSolicitud}/rechazar")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> rechazarSolicitud(@PathVariable Integer idSolicitud,
            @RequestBody(required = false) AtencionSolicitud atencion, Authentication authentication) {
        Integer idAdmin = usuarioActual.id(authentication);
        String obs = atencion != null && atencion.observacion() != null ? atencion.observacion().trim() : "Solicitud denegada por el CEUNP.";

        List<Map<String, Object>> filas = dao.consultar("""
                SELECT id_solicitud, id_proceso, id_docente, tipo, estado
                  FROM solicitud_regeneracion_qr
                 WHERE id_solicitud = ?
                """, idSolicitud);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Solicitud no encontrada.");
        }
        Map<String, Object> sol = filas.get(0);
        if (!"PENDIENTE".equals(sol.get("estado"))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Esta solicitud ya fue atendida.");
        }

        dao.ejecutar("""
                UPDATE solicitud_regeneracion_qr
                   SET estado = 'RECHAZADA', fecha_atencion = NOW(), id_usuario_atencion = ?, observacion_atencion = ?
                 WHERE id_solicitud = ?
                """, idAdmin, obs, idSolicitud);

        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("id_solicitud", idSolicitud);
        detalle.put("observacion", obs);
        bitacora.registrar(idAdmin, ((Number) sol.get("idProceso")).intValue(), "RECHAZAR_REGENERACION_QR", detalle);

        return Map.of("mensaje", "Solicitud rechazada.", "idSolicitud", idSolicitud);
    }
}
