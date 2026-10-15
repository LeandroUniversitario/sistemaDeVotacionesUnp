package pe.unp.elecciones.electoral.credenciales;

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

import pe.unp.elecciones.auth.UsuarioActual;
import pe.unp.elecciones.electoral.credenciales.CredencialesDto.DatosRevocacion;
import pe.unp.elecciones.electoral.credenciales.CredencialesDto.SolicitudEmision;
import pe.unp.elecciones.electoral.credenciales.CredencialesDto.SolicitudPropia;
import pe.unp.elecciones.electoral.credenciales.CredencialesDto.SolicitudVerificacion;

/**
 * CUS07 · Emitir credenciales y QR (actor: CEUNP).
 *
 * <ul>
 *   <li>POST /api/credenciales/procesos/{id}/emitir → 1: solicitarCredencial(id_docente) …
 *       GenerarTokenQR (2-4) → EmitirConstancia (4-6) → el LectorQR muestra la credencial (7)</li>
 *   <li>POST /api/credenciales/verificar           → lectura del QR en la jornada</li>
 *   <li>GET/POST /api/credenciales/mias            → el docente genera su propia credencial</li>
 * </ul>
 *
 * El token en claro solo aparece en la respuesta de una emisión; ninguna consulta lo devuelve.
 */
@RestController
@RequestMapping("/api/credenciales")
public class CredencialesController {

    private final CredencialesConsulta consulta;
    private final GenerarTokenQR generarTokenQR;
    private final EmitirConstancia emitirConstancia;
    private final VerificarCredencial verificarCredencial;
    private final UsuarioActual usuarioActual;

    public CredencialesController(CredencialesConsulta consulta, GenerarTokenQR generarTokenQR,
            EmitirConstancia emitirConstancia, VerificarCredencial verificarCredencial, UsuarioActual usuarioActual) {
        this.consulta = consulta;
        this.generarTokenQR = generarTokenQR;
        this.emitirConstancia = emitirConstancia;
        this.verificarCredencial = verificarCredencial;
        this.usuarioActual = usuarioActual;
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
}
