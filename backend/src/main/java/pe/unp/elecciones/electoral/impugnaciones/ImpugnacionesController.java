package pe.unp.elecciones.electoral.impugnaciones;

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

import pe.unp.elecciones.auth.Rol;
import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.auth.UsuarioActual;

/**
 * CUS13 · Gestionar impugnaciones y apelaciones (actores: Personero de mesa, Presidente de mesa y CEUNP).
 *
 * <ul>
 *   <li>POST /mesas/{id}/impugnaciones → 1 ingresarImpugnacion(id_mesa, motivo) · 2 registrarImpugnacion(datos)
 *       → RegistrarImpugnacion · 3 verificarAcreditacion(id_personero) · 4 insertar(...) · 5 confirmarRegistro()</li>
 *   <li>POST /{id}/decision-mesa → 6 registrarDecisionMesa(id_impugnacion, decision) · 7 resolverEnMesa(datos)
 *       → ResolverImpugnacion · 8 actualizarDecisionMesa(decision) · 9 notificarDecision()</li>
 *   <li>POST /{id}/apelacion → 10 [decision rechazada] apelarDecision(id_impugnacion) → TramitarApelacion</li>
 *   <li>POST /{id}/fallo → 11 registrarFalloCEUNP(id_impugnacion, decision) · 12 resolverApelacion(...)
 *       → TramitarApelacion · 13 actualizarDecisionCEUNP(decision, 'RESUELTA') · 14 notificarFalloFinal()</li>
 * </ul>
 *
 * ADMIN solo consulta. Un MIEMBRO_MESA ve su mesa; un PERSONERO, las mesas que fiscaliza.
 */
@RestController
@RequestMapping("/api/impugnaciones")
@PreAuthorize("hasAnyRole('ADMIN', 'CEUNP', 'MIEMBRO_MESA', 'PERSONERO')")
public class ImpugnacionesController {

    private final ImpugnacionesConsulta consulta;
    private final RegistrarImpugnacion registrarImpugnacion;
    private final ResolverImpugnacion resolverImpugnacion;
    private final TramitarApelacion tramitarApelacion;
    private final UsuarioActual usuarioActual;

    public ImpugnacionesController(ImpugnacionesConsulta consulta, RegistrarImpugnacion registrarImpugnacion,
            ResolverImpugnacion resolverImpugnacion, TramitarApelacion tramitarApelacion, UsuarioActual usuarioActual) {
        this.consulta = consulta;
        this.registrarImpugnacion = registrarImpugnacion;
        this.resolverImpugnacion = resolverImpugnacion;
        this.tramitarApelacion = tramitarApelacion;
        this.usuarioActual = usuarioActual;
    }

    // ─── Consultas ───────────────────────────────────────────────────────────

    @GetMapping("/procesos")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public List<Map<String, Object>> procesos() {
        return consulta.procesos();
    }

    @GetMapping("/mesas")
    public List<Map<String, Object>> mesas(@RequestParam(required = false) Integer procesoId, Authentication authentication) {
        Usuario usuario = usuarioActual.requerido(authentication);
        if (usuario.getRol() == Rol.MIEMBRO_MESA) {
            return consulta.mesasDeMiembro(usuarioActual.idDocenteRequerido(authentication));
        }
        if (usuario.getRol() == Rol.PERSONERO) {
            return consulta.mesasDePersonero(usuarioActual.idDocenteRequerido(authentication));
        }
        return consulta.mesas(procesoId);
    }

    @GetMapping("/mesas/{id}")
    public Map<String, Object> detalle(@PathVariable Integer id, Authentication authentication) {
        Usuario usuario = usuarioActual.requerido(authentication);
        consulta.mesa(id);
        consulta.exigirAcceso(id, usuario);
        return consulta.detalle(id, usuario);
    }

    /** Bandeja del CEUNP: impugnaciones del proceso y apelaciones por resolver. */
    @GetMapping("/bandeja")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public Map<String, Object> bandeja(@RequestParam Integer procesoId) {
        List<Map<String, Object>> impugnaciones = consulta.bandeja(procesoId);
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("impugnaciones", impugnaciones);
        respuesta.put("resumen", ImpugnacionesConsulta.resumen(impugnaciones));
        respuesta.put("quorumPleno", consulta.parametro("CEUNP_QUORUM_PLENO", 5));
        respuesta.put("cargos", consulta.cargosConListas(procesoId));
        return respuesta;
    }

    @GetMapping("/{id}")
    public Map<String, Object> impugnacion(@PathVariable Long id, Authentication authentication) {
        Usuario usuario = usuarioActual.requerido(authentication);
        Map<String, Object> impugnacion = consulta.impugnacion(id);
        consulta.exigirAcceso(ImpugnacionesConsulta.numero(impugnacion.get("idMesa")), usuario);
        return impugnacion;
    }

    // ─── 1-5 Registrar la impugnación ───────────────────────────────────────

    @PostMapping("/mesas/{id}/impugnaciones")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyRole('MIEMBRO_MESA', 'PERSONERO')")
    public Map<String, Object> ingresarImpugnacion(@PathVariable Integer id,
            @Valid @RequestBody ImpugnacionesDto.NuevaImpugnacion datos, Authentication authentication) {
        Usuario usuario = usuarioActual.requerido(authentication);
        consulta.mesa(id);
        consulta.exigirAcceso(id, usuario);
        return registrarImpugnacion.registrarImpugnacion(id, datos, usuario);
    }

    // ─── 6-9 Decisión de la mesa (primera instancia) ────────────────────────

    @PostMapping("/{id}/decision-mesa")
    @PreAuthorize("hasRole('MIEMBRO_MESA')")
    public Map<String, Object> registrarDecisionMesa(@PathVariable Long id,
            @Valid @RequestBody ImpugnacionesDto.DecisionMesa datos, Authentication authentication) {
        return resolverImpugnacion.resolverEnMesa(id, datos, usuarioActual.requerido(authentication));
    }

    // ─── 10 Apelación ───────────────────────────────────────────────────────

    @PostMapping("/{id}/apelacion")
    @PreAuthorize("hasAnyRole('MIEMBRO_MESA', 'PERSONERO')")
    public Map<String, Object> apelarDecision(@PathVariable Long id,
            @Valid @RequestBody ImpugnacionesDto.Apelacion datos, Authentication authentication) {
        return tramitarApelacion.apelarDecision(id, datos, usuarioActual.requerido(authentication));
    }

    // ─── 11-14 Fallo del CEUNP (segunda y última instancia) ─────────────────

    @PostMapping("/{id}/fallo")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> registrarFalloCeunp(@PathVariable Long id,
            @Valid @RequestBody ImpugnacionesDto.FalloCeunp datos, Authentication authentication) {
        return tramitarApelacion.resolverApelacion(id, datos, usuarioActual.requerido(authentication));
    }
}
