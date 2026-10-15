package pe.unp.elecciones.electoral.tachas;

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
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import pe.unp.elecciones.auth.Rol;
import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.auth.UsuarioActual;
import pe.unp.elecciones.electoral.tachas.TachasDto.DatosResolucion;
import pe.unp.elecciones.electoral.tachas.TachasDto.DatosTacha;

/**
 * CUS04 · Gestionar tachas.
 * Actores: Docente elector (presenta la tacha a nombre propio) y CEUNP (la resuelve).
 *
 * <ul>
 *   <li>POST /api/gestion-tachas                     → RegistrarTacha.enviarTacha       (1-4)</li>
 *   <li>POST /api/gestion-tachas/{id}/resolucion     → ResolverTacha.guardarResolucion  (5-9)</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/gestion-tachas")
public class TachasController {

    private final TachasConsulta consulta;
    private final RegistrarTacha registrarTacha;
    private final ResolverTacha resolverTacha;
    private final UsuarioActual usuarioActual;

    public TachasController(TachasConsulta consulta, RegistrarTacha registrarTacha,
            ResolverTacha resolverTacha, UsuarioActual usuarioActual) {
        this.consulta = consulta;
        this.registrarTacha = registrarTacha;
        this.resolverTacha = resolverTacha;
        this.usuarioActual = usuarioActual;
    }

    // ─── Consultas ────────────────────────────────────────────────────────────

    @GetMapping("/procesos")
    public List<Map<String, Object>> procesos() {
        return consulta.procesos();
    }

    @GetMapping("/procesos/{idProceso}/candidatos")
    public List<Map<String, Object>> candidatos(@PathVariable Integer idProceso) {
        return consulta.candidatos(idProceso);
    }

    /** CEUNP / ADMIN: todas las tachas del proceso. */
    @GetMapping("/procesos/{idProceso}/tachas")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public List<Map<String, Object>> tachas(@PathVariable Integer idProceso) {
        return consulta.tachas(idProceso);
    }

    /** Docente elector: las tachas que presentó. */
    @GetMapping("/mias")
    public List<Map<String, Object>> mias(Authentication authentication) {
        return consulta.tachasDe(usuarioActual.idDocenteRequerido(authentication));
    }

    // ─── 1-4: Presentar tacha ────────────────────────────────────────────────

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> presentar(@Valid @RequestBody DatosTacha datos, Authentication authentication) {
        Usuario usuario = usuarioActual.requerido(authentication);
        boolean esCeunp = usuario.getRol() == Rol.CEUNP || usuario.getRol() == Rol.ADMIN;
        Integer idDenunciante;
        if (esCeunp && datos.dniDenunciante() != null && !datos.dniDenunciante().isBlank()) {
            // Tacha recibida en mesa de partes: el CEUNP la registra a nombre del docente.
            idDenunciante = registrarTacha.docentePorDni(datos.dniDenunciante());
        } else {
            idDenunciante = usuarioActual.idDocenteRequerido(authentication);
        }
        return registrarTacha.enviarTacha(datos, idDenunciante);
    }

    // ─── 5-9: Resolver tacha ─────────────────────────────────────────────────

    @PostMapping("/{idTacha}/resolucion")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public Map<String, Object> resolver(@PathVariable Integer idTacha,
            @Valid @RequestBody DatosResolucion datos, Authentication authentication) {
        return resolverTacha.guardarResolucion(idTacha, datos, usuarioActual.id(authentication));
    }
}
