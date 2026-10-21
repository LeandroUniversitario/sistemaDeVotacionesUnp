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
import pe.unp.elecciones.electoral.votacion.VotacionDto.Voto;

/**
 * CUS10 · Registrar voto en el «TerminalVotacion» (actor: docente elector, que NO inicia sesión).
 *
 * El equipo de la cabina queda abierto con la sesión de la mesa en modo terminal; el docente solo
 * elige y confirma. El terminal nunca envía ni recibe datos del elector.
 *
 * <ul>
 *   <li>POST /api/sufragio/terminales {idMesa, nombre}  → conecta el equipo como terminal de la mesa</li>
 *   <li>GET  /api/sufragio/terminales/{id}               → LIBRE | HABILITADO (token y cédula) | EN_USO | FUERA_DE_SERVICIO</li>
 *   <li>POST /api/sufragio/terminales/{id}/voto          → 9 registrarVoto(opción) → cédula para imprimir</li>
 *   <li>POST /api/sufragio/terminales/{id}/liberar       → 13 liberarTerminal() tras confirmarImpresion()</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/sufragio/terminales")
@PreAuthorize("hasAnyRole('ADMIN', 'CEUNP', 'MIEMBRO_MESA')")
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
        acceso(idTerminal, authentication);
        return registrarVoto.estado(idTerminal);
    }

    @PostMapping("/{idTerminal}/voto")
    public Map<String, Object> votar(@PathVariable Integer idTerminal, @Valid @RequestBody Voto voto,
            Authentication authentication) {
        acceso(idTerminal, authentication);
        return registrarVoto.registrarVoto(idTerminal, voto.idHabilitacion(), voto.token(), voto.votos());
    }

    @PostMapping("/{idTerminal}/liberar")
    public Map<String, Object> liberar(@PathVariable Integer idTerminal, Authentication authentication) {
        Usuario usuario = acceso(idTerminal, authentication);
        return registrarVoto.liberarTerminal(idTerminal, usuario.getId());
    }

    private Usuario acceso(Integer idTerminal, Authentication authentication) {
        Integer idMesa = (Integer) consulta.terminal(idTerminal).get("idMesa");
        return VerificarElectorController.exigirAcceso(idMesa, authentication, dao, usuarioActual);
    }
}
