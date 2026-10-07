package pe.unp.elecciones.electoral.controller;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import pe.unp.elecciones.auth.UsuarioActual;
import pe.unp.elecciones.electoral.service.ProcesoService;

/**
 * Operaciones del CEUNP sobre el ciclo electoral.
 * Complementa a ElectoralController (altas de procesos, cargos, listas, candidatos y tachas).
 */
@RestController
@RequestMapping("/api")
public class ProcesoController {

    private final ProcesoService procesoService;
    private final UsuarioActual usuarioActual;

    public ProcesoController(ProcesoService procesoService, UsuarioActual usuarioActual) {
        this.procesoService = procesoService;
        this.usuarioActual = usuarioActual;
    }

    // ─── Estados ──────────────────────────────────────────────────────────────

    @GetMapping("/procesos/{idProceso}")
    public Map<String, Object> obtener(@PathVariable Integer idProceso) {
        return procesoService.obtener(idProceso);
    }

    /** Cuerpo: {"estado": "INSCRIPCION" | "VOTACION" | "CERRADO"} */
    @PatchMapping("/procesos/{idProceso}/estado")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public Map<String, Object> cambiarEstado(
            @PathVariable Integer idProceso,
            @Valid @RequestBody EstadoRequest request,
            Authentication authentication) {
        return procesoService.cambiarEstado(idProceso, request.estado(), usuarioActual.id(authentication));
    }

    @PostMapping("/procesos/{idProceso}/anular")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public Map<String, Object> anular(
            @PathVariable Integer idProceso,
            @Valid @RequestBody MotivoRequest request,
            Authentication authentication) {
        return procesoService.anular(idProceso, request.motivo(), usuarioActual.id(authentication));
    }

    // ─── Padrón y participación ───────────────────────────────────────────────

    @PostMapping("/procesos/{idProceso}/padron")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public Map<String, Object> generarPadron(@PathVariable Integer idProceso, Authentication authentication) {
        return procesoService.generarPadron(idProceso, usuarioActual.id(authentication));
    }

    @GetMapping("/procesos/{idProceso}/padron")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public List<Map<String, Object>> padron(@PathVariable Integer idProceso) {
        return procesoService.padron(idProceso);
    }

    @GetMapping("/procesos/{idProceso}/participacion")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public Map<String, Object> participacion(@PathVariable Integer idProceso) {
        return procesoService.participacion(idProceso);
    }

    // ─── Listas y cédula ──────────────────────────────────────────────────────

    /** Cédula de votación: la usa la terminal del elector. */
    @GetMapping("/procesos/{idProceso}/listas")
    public List<Map<String, Object>> cedula(@PathVariable Integer idProceso) {
        return procesoService.cedula(idProceso);
    }

    /** Cuerpo: {"admitir": true} o {"admitir": false, "motivo": "..."} */
    @PostMapping("/listas/{idLista}/validar")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public List<Map<String, Object>> validarLista(
            @PathVariable Integer idLista,
            @RequestBody ValidarListaRequest request,
            Authentication authentication) {
        return procesoService.validarLista(idLista, request.admitir(), request.motivo(),
                usuarioActual.id(authentication));
    }

    // ─── Resultados ───────────────────────────────────────────────────────────

    @PostMapping("/procesos/{idProceso}/computo")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public Map<String, Object> computar(@PathVariable Integer idProceso, Authentication authentication) {
        return procesoService.computarResultados(idProceso, usuarioActual.id(authentication));
    }

    @GetMapping("/procesos/{idProceso}/resultados")
    public Map<String, Object> resultados(@PathVariable Integer idProceso) {
        return procesoService.resultados(idProceso);
    }

    @PostMapping("/procesos/{idProceso}/segunda-vuelta")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public Map<String, Object> segundaVuelta(
            @PathVariable Integer idProceso,
            @Valid @RequestBody SegundaVueltaRequest request,
            Authentication authentication) {
        return procesoService.crearSegundaVuelta(idProceso, request.fechaInicio(), request.fechaFin(),
                usuarioActual.id(authentication));
    }

    // ─── Multas ───────────────────────────────────────────────────────────────

    @PostMapping("/procesos/{idProceso}/multas")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public Map<String, Object> generarMultas(@PathVariable Integer idProceso, Authentication authentication) {
        return procesoService.generarMultas(idProceso, usuarioActual.id(authentication));
    }

    @GetMapping("/procesos/{idProceso}/multas")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public List<Map<String, Object>> multas(@PathVariable Integer idProceso) {
        return procesoService.multas(idProceso);
    }

    /** Multas del docente que tiene la sesión abierta. */
    @GetMapping("/multas/mias")
    public List<Map<String, Object>> misMultas(Authentication authentication) {
        return procesoService.multasDeDocente(usuarioActual.idDocenteRequerido(authentication));
    }

    /** Cuerpo: {"estadoPago": "PAGADA" | "EXONERADA" | "PENDIENTE", "observacion": "..."} */
    @PatchMapping("/multas/{idMulta}")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public List<Map<String, Object>> actualizarMulta(
            @PathVariable Integer idMulta,
            @Valid @RequestBody MultaRequest request,
            Authentication authentication) {
        return procesoService.actualizarMulta(idMulta, request.estadoPago(), request.observacion(),
                usuarioActual.id(authentication));
    }

    // ─── DTOs ─────────────────────────────────────────────────────────────────

    public record EstadoRequest(@NotBlank String estado) {
    }

    public record MotivoRequest(@NotBlank String motivo) {
    }

    public record ValidarListaRequest(boolean admitir, String motivo) {
    }

    public record SegundaVueltaRequest(@NotNull LocalDateTime fechaInicio, @NotNull LocalDateTime fechaFin) {
    }

    public record MultaRequest(@NotBlank String estadoPago, String observacion) {
    }
}
