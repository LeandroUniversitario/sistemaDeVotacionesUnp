package pe.unp.elecciones.electoral.multas;

import java.util.List;
import java.util.Map;

import jakarta.validation.Valid;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import pe.unp.elecciones.auth.UsuarioActual;

/**
 * CUS16 · Reportar omisos y multas (actor: CEUNP). Boundary «PantallaMultas».
 *
 * <ul>
 *   <li>GET /procesos/{id} → 1 solicitarReporteOmisos: omisos, multas, reporte, descargos y gestión (RF107)</li>
 *   <li>POST /procesos/{id}/generar → 2-6 generarMultas · GenerarMultas</li>
 *   <li>POST /procesos/{id}/resolucion → 7 mostrarReporteMultas (resolución del Pleno con QR)</li>
 *   <li>POST /procesos/{id}/notificacion → notificación de las multas determinadas</li>
 *   <li>POST /{id}/justificacion → 8-11 registrarJustificacion · RegistrarJustificacion</li>
 *   <li>POST /{id}/pago → pago con recibo (el sistema no cobra)</li>
 * </ul>
 *
 * ADMIN solo consulta. El docente ve sus multas en GET /api/multas/mias (ProcesoController).
 */
@RestController
@RequestMapping("/api/multas")
@PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
public class MultasController {

    private final MultasConsulta consulta;
    private final GenerarMultas generarMultas;
    private final RegistrarJustificacion registrarJustificacion;
    private final UsuarioActual usuarioActual;

    public MultasController(MultasConsulta consulta, GenerarMultas generarMultas,
            RegistrarJustificacion registrarJustificacion, UsuarioActual usuarioActual) {
        this.consulta = consulta;
        this.generarMultas = generarMultas;
        this.registrarJustificacion = registrarJustificacion;
        this.usuarioActual = usuarioActual;
    }

    // ─── Consultas ───────────────────────────────────────────────────────────

    @GetMapping("/procesos")
    public List<Map<String, Object>> procesos() {
        return consulta.procesos();
    }

    /** 1 solicitarReporteOmisos(). */
    @GetMapping("/procesos/{id}")
    public Map<String, Object> detalle(@PathVariable Integer id, Authentication authentication) {
        return consulta.detalle(id, usuarioActual.requerido(authentication));
    }

    /** 7 mostrarReporteMultas(): resolución con su contenido para imprimir. */
    @GetMapping("/procesos/{id}/resolucion")
    public Map<String, Object> resolucion(@PathVariable Integer id) {
        return consulta.resolucion(id);
    }

    @GetMapping("/{id:\\d+}")
    public Map<String, Object> multa(@PathVariable Integer id) {
        return consulta.multa(id);
    }

    // ─── 2-7 Generar y determinar las multas ────────────────────────────────

    @PostMapping("/procesos/{id}/generar")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> generar(@PathVariable Integer id, Authentication authentication) {
        return generarMultas.generar(id, usuarioActual.requerido(authentication));
    }

    @PostMapping("/procesos/{id}/resolucion")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> emitirResolucion(@PathVariable Integer id, @Valid @RequestBody MultasDto.Resolucion datos,
            Authentication authentication) {
        return generarMultas.emitirResolucion(id, datos, usuarioActual.requerido(authentication));
    }

    @PostMapping("/procesos/{id}/notificacion")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> notificar(@PathVariable Integer id, @Valid @RequestBody MultasDto.Notificacion datos,
            Authentication authentication) {
        return generarMultas.notificar(id, datos, usuarioActual.requerido(authentication));
    }

    // ─── 8-11 Justificación, exoneración y pago ─────────────────────────────

    @PostMapping("/{id:\\d+}/justificacion")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> justificar(@PathVariable Integer id, @Valid @RequestBody MultasDto.Justificacion datos,
            Authentication authentication) {
        return registrarJustificacion.justificar(id, datos, usuarioActual.requerido(authentication));
    }

    @PostMapping("/{id:\\d+}/pago")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> pagar(@PathVariable Integer id, @Valid @RequestBody MultasDto.Pago datos,
            Authentication authentication) {
        return registrarJustificacion.pagar(id, datos, usuarioActual.requerido(authentication));
    }
}
