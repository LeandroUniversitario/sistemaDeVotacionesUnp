package pe.unp.elecciones.electoral.votacion;

import java.util.List;
import java.util.Map;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Rol;
import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.auth.UsuarioActual;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;
import pe.unp.elecciones.electoral.votacion.VotacionDto.Anulacion;
import pe.unp.elecciones.electoral.votacion.VotacionDto.Confirmacion;
import pe.unp.elecciones.electoral.votacion.VotacionDto.EstadoTerminal;
import pe.unp.elecciones.electoral.votacion.VotacionDto.Rechazo;
import pe.unp.elecciones.electoral.votacion.VotacionDto.Rehabilitacion;
import pe.unp.elecciones.electoral.votacion.VotacionDto.SolicitudVerificacion;

/**
 * CUS09 · Verificar elector con QR (actor: Secretario de mesa; CEUNP y ADMIN supervisan).
 * Atiende a la «PantallaVerificacion».
 *
 * <ul>
 *   <li>GET  /api/sufragio/mesas                                     → mesas que puede atender</li>
 *   <li>GET  /api/sufragio/mesas/{id}                                → padrón, terminales e incidencias</li>
 *   <li>POST /api/sufragio/mesas/{id}/verificar {codigo | dni}       → 1-4 escanearQR … mostrarDatosYFoto</li>
 *   <li>POST /api/sufragio/mesas/{id}/asistencias                    → 5-7 confirmarConDNI, registrarAsistencia, habilitarTerminal</li>
 *   <li>POST /api/sufragio/mesas/{id}/rechazos                       → A5 suplantación</li>
 *   <li>POST /api/sufragio/mesas/{id}/habilitaciones/{h}/anular      → CUS10 A3 abandono del terminal</li>
 *   <li>POST /api/sufragio/mesas/{id}/rehabilitaciones               → CUS10 A3/A5, solo el Presidente</li>
 *   <li>PUT  /api/sufragio/mesas/{id}/terminales/{t} {activo}        → CUS10 A4 terminal fuera de servicio</li>
 *   <li>GET/DELETE /api/sufragio/mesas/{id}/constancias/{docente}    → constancia del elector que votó</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/sufragio/mesas")
@PreAuthorize("hasAnyRole('ADMIN', 'CEUNP', 'MIEMBRO_MESA')")
public class VerificarElectorController {

    private final VerificarElector verificarElector;
    private final RegistrarAsistencia registrarAsistencia;
    private final RegistrarVoto registrarVoto;
    private final VotacionConsulta consulta;
    private final UsuarioActual usuarioActual;
    private final ProcedimientoDao dao;

    public VerificarElectorController(VerificarElector verificarElector, RegistrarAsistencia registrarAsistencia,
            RegistrarVoto registrarVoto, VotacionConsulta consulta, UsuarioActual usuarioActual, ProcedimientoDao dao) {
        this.verificarElector = verificarElector;
        this.registrarAsistencia = registrarAsistencia;
        this.registrarVoto = registrarVoto;
        this.consulta = consulta;
        this.usuarioActual = usuarioActual;
        this.dao = dao;
    }

    @GetMapping
    public List<Map<String, Object>> mesas(Authentication authentication) {
        Usuario usuario = usuarioActual.requerido(authentication);
        return consulta.mesas(usuario.getRol() == Rol.MIEMBRO_MESA ? docente(usuario) : null);
    }

    @GetMapping("/{idMesa}")
    public Map<String, Object> tablero(@PathVariable Integer idMesa, Authentication authentication) {
        Usuario usuario = exigirAcceso(idMesa, authentication, dao, usuarioActual);
        return verificarElector.tablero(idMesa, usuario.getIdDocente(), usuario.getRol() != Rol.MIEMBRO_MESA);
    }

    @PostMapping("/{idMesa}/verificar")
    public Map<String, Object> verificar(@PathVariable Integer idMesa,
            @Valid @RequestBody SolicitudVerificacion solicitud, Authentication authentication) {
        Usuario usuario = exigirAcceso(idMesa, authentication, dao, usuarioActual);
        return verificarElector.verificar(idMesa, solicitud.dni(), solicitud.codigo(), usuario.getId());
    }

    @PostMapping("/{idMesa}/asistencias")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> confirmar(@PathVariable Integer idMesa, @Valid @RequestBody Confirmacion datos,
            Authentication authentication) {
        Usuario usuario = exigirAcceso(idMesa, authentication, dao, usuarioActual);
        return registrarAsistencia.confirmar(idMesa, datos.idDocente(), datos.metodo(), datos.idCredencial(),
                datos.idTerminal(), usuario.getId());
    }

    @PostMapping("/{idMesa}/rechazos")
    public Map<String, Object> rechazar(@PathVariable Integer idMesa, @Valid @RequestBody Rechazo datos,
            Authentication authentication) {
        Usuario usuario = exigirAcceso(idMesa, authentication, dao, usuarioActual);
        return registrarAsistencia.rechazar(idMesa, datos.idDocente(), datos.dni(), datos.motivo(), usuario.getId());
    }

    @PostMapping("/{idMesa}/habilitaciones/{idHabilitacion}/anular")
    public Map<String, Object> anular(@PathVariable Integer idMesa, @PathVariable Long idHabilitacion,
            @Valid @RequestBody Anulacion datos, Authentication authentication) {
        Usuario usuario = exigirAcceso(idMesa, authentication, dao, usuarioActual);
        return registrarAsistencia.anularHabilitacion(idMesa, idHabilitacion, datos.motivo(), usuario.getId());
    }

    @PostMapping("/{idMesa}/rehabilitaciones")
    public Map<String, Object> rehabilitar(@PathVariable Integer idMesa, @Valid @RequestBody Rehabilitacion datos,
            Authentication authentication) {
        Usuario usuario = exigirAcceso(idMesa, authentication, dao, usuarioActual);
        if (usuario.getRol() == Rol.MIEMBRO_MESA && !consulta.esPresidente(idMesa, usuario.getIdDocente())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Solo el Presidente de mesa autoriza la rehabilitación del terminal.");
        }
        return registrarAsistencia.rehabilitar(idMesa, datos.idDocente(), datos.idTerminal(), datos.motivo(), usuario.getId());
    }

    @PutMapping("/{idMesa}/terminales/{idTerminal}")
    public List<Map<String, Object>> estadoTerminal(@PathVariable Integer idMesa, @PathVariable Integer idTerminal,
            @RequestBody EstadoTerminal datos, Authentication authentication) {
        Usuario usuario = exigirAcceso(idMesa, authentication, dao, usuarioActual);
        return registrarAsistencia.cambiarEstadoTerminal(idMesa, idTerminal, datos.activo(), usuario.getId());
    }

    @GetMapping("/{idMesa}/constancias/{idDocente}")
    public Map<String, Object> constancia(@PathVariable Integer idMesa, @PathVariable Integer idDocente,
            Authentication authentication) {
        exigirAcceso(idMesa, authentication, dao, usuarioActual);
        return registrarVoto.constancia(idMesa, idDocente);
    }

    @DeleteMapping("/{idMesa}/constancias/{idDocente}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void constanciaEntregada(@PathVariable Integer idMesa, @PathVariable Integer idDocente,
            Authentication authentication) {
        exigirAcceso(idMesa, authentication, dao, usuarioActual);
        registrarVoto.constanciaEntregada(idMesa, idDocente);
    }

    /** Un MIEMBRO_MESA solo opera la mesa a la que fue sorteado (igual que MesaController). */
    static Usuario exigirAcceso(Integer idMesa, Authentication authentication, ProcedimientoDao dao,
            UsuarioActual usuarioActual) {
        Usuario usuario = usuarioActual.requerido(authentication);
        if (usuario.getRol() == Rol.MIEMBRO_MESA && dao.entero(
                "SELECT COUNT(*) FROM miembro_mesa WHERE id_mesa = ? AND id_docente = ?",
                idMesa, docente(usuario)) == 0) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No es miembro de esta mesa.");
        }
        return usuario;
    }

    static Integer docente(Usuario usuario) {
        if (usuario.getIdDocente() == null) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Esta cuenta no está asociada a un docente.");
        }
        return usuario.getIdDocente();
    }
}
