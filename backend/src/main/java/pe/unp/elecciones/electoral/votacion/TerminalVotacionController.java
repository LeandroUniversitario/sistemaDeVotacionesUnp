package pe.unp.elecciones.electoral.votacion;

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

import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.auth.UsuarioActual;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;
import pe.unp.elecciones.electoral.votacion.VotacionDto.RegistroTerminal;

/**
 * CUS10 · Conexión y supervisión de los terminales de la mesa (actor: miembro de mesa; CEUNP supervisa).
 *
 * <ul>
 *   <li>POST /api/sufragio/terminales {idMesa, nombre} → conecta el equipo y emite su secreto de dispositivo</li>
 *   <li>GET  /api/sufragio/terminales/{id}              → LIBRE | HABILITADO | EN_USO | FUERA_DE_SERVICIO (sin token)</li>
 * </ul>
 *
 * El voto y la liberación del terminal ya no se aceptan con la sesión de una persona: los hace solo
 * el equipo de la cabina con su secreto (CabinaController, /api/cabina/**). Así nadie de la mesa puede
 * tomar la habilitación del elector desde otro equipo (auditoría C2).
 */
@RestController
@RequestMapping("/api/sufragio/terminales")
@PreAuthorize("hasAnyRole('CEUNP', 'MIEMBRO_MESA')")
public class TerminalVotacionController {

    private final RegistrarVoto registrarVoto;
    private final VotacionConsulta consulta;
    private final UsuarioActual usuarioActual;
    private final ProcedimientoDao dao;

    public TerminalVotacionController(RegistrarVoto registrarVoto, VotacionConsulta consulta,
            UsuarioActual usuarioActual, ProcedimientoDao dao) {
        this.registrarVoto = registrarVoto;
        this.consulta = consulta;
        this.usuarioActual = usuarioActual;
        this.dao = dao;
    }

    @PostMapping
    public Map<String, Object> conectar(@Valid @RequestBody RegistroTerminal datos, Authentication authentication) {
        Usuario usuario = VerificarElectorController.exigirAcceso(datos.idMesa(), authentication, dao, usuarioActual);
        return registrarVoto.registrarTerminal(datos.idMesa(), datos.nombre(), usuario.getId());
    }

    @GetMapping("/{idTerminal}")
    public Map<String, Object> estado(@PathVariable Integer idTerminal, Authentication authentication) {
        Integer idMesa = (Integer) consulta.terminal(idTerminal).get("idMesa");
        VerificarElectorController.exigirAcceso(idMesa, authentication, dao, usuarioActual);
        return registrarVoto.estado(idTerminal, false);
    }
}
