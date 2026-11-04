package pe.unp.elecciones.electoral.controller;

import java.util.List;
import java.util.Map;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;

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
 * Operaciones del CEUNP sobre el ciclo del proceso que no tienen un CUS propio.
 *
 * <ul>
 *   <li>PATCH /api/procesos/{id}/estado: abrir la votación (INSCRIPCION → VOTACION) o cerrarla
 *       (VOTACION → CERRADO). Las reglas (RN06, RN32: mesas cerradas y escrutadas, impugnaciones
 *       resueltas) están en sp_cambiar_estado_proceso, no en Java.</li>
 *   <li>POST /api/listas/{id}/validar: calificación de listas (CUS03, actor CEUNP).</li>
 *   <li>GET /api/multas/mias: multas del docente con sesión.</li>
 * </ul>
 *
 * El cómputo, la segunda vuelta, la nulidad, el padrón y las multas se operan desde sus CUS
 * (computo/, nulidades/, padron/, multas/); los endpoints heredados que los duplicaban sin sus
 * reglas ni su actor se eliminaron.
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

    /** Cuerpo: {"estado": "VOTACION" | "CERRADO"} */
    @PatchMapping("/procesos/{idProceso}/estado")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> cambiarEstado(@PathVariable Integer idProceso, @Valid @RequestBody EstadoRequest request,
            Authentication authentication) {
        return procesoService.cambiarEstado(idProceso, request.estado(), usuarioActual.id(authentication));
    }

    /** Cuerpo: {"admitir": true} o {"admitir": false, "motivo": "..."} */
    @PostMapping("/listas/{idLista}/validar")
    @PreAuthorize("hasRole('CEUNP')")
    public List<Map<String, Object>> validarLista(@PathVariable Integer idLista, @RequestBody ValidarListaRequest request,
            Authentication authentication) {
        return procesoService.validarLista(idLista, request.admitir(), request.motivo(), usuarioActual.id(authentication));
    }

    /** Multas del docente que tiene la sesión abierta. */
    @GetMapping("/multas/mias")
    public List<Map<String, Object>> misMultas(Authentication authentication) {
        return procesoService.multasDeDocente(usuarioActual.idDocenteRequerido(authentication));
    }

    public record EstadoRequest(@NotBlank String estado) {
    }

    public record ValidarListaRequest(boolean admitir, String motivo) {
    }
}
