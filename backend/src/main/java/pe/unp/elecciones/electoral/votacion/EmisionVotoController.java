package pe.unp.elecciones.electoral.votacion;

import java.util.Map;

import jakarta.validation.Valid;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import pe.unp.elecciones.auth.UsuarioActual;
import pe.unp.elecciones.electoral.votacion.VotacionDto.Cedula;

/**
 * CUS10 · Emitir voto (actor: docente elector; los miembros de mesa y personeros también votan).
 *
 * <ul>
 *   <li>GET  /api/sufragio/cedula → validarHabilitacion + mostrarOpciones</li>
 *   <li>POST /api/sufragio/votar  → registrarVoto + mostrarConstancia</li>
 * </ul>
 *
 * El voto es personal (RN01): el docente se toma de la sesión, nunca del cuerpo de la petición.
 */
@RestController
@RequestMapping("/api/sufragio")
@PreAuthorize("hasAnyRole('DOCENTE', 'MIEMBRO_MESA', 'PERSONERO')")
public class EmisionVotoController {

    private final EmitirVoto emitirVoto;
    private final UsuarioActual usuarioActual;

    public EmisionVotoController(EmitirVoto emitirVoto, UsuarioActual usuarioActual) {
        this.emitirVoto = emitirVoto;
        this.usuarioActual = usuarioActual;
    }

    @GetMapping("/cedula")
    public Map<String, Object> cedula(Authentication authentication) {
        return emitirVoto.cedula(usuarioActual.idDocenteRequerido(authentication));
    }

    @PostMapping("/votar")
    public Map<String, Object> votar(@Valid @RequestBody Cedula cedula, Authentication authentication) {
        return emitirVoto.votar(usuarioActual.idDocenteRequerido(authentication), cedula.procesoId(), cedula.votos());
    }
}
