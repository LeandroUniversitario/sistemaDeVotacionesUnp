package pe.unp.elecciones.electoral.votacion;

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
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Rol;
import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.auth.UsuarioActual;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;
import pe.unp.elecciones.electoral.votacion.VotacionDto.DatosAnulacion;
import pe.unp.elecciones.electoral.votacion.VotacionDto.SolicitudAutorizacion;
import pe.unp.elecciones.electoral.votacion.VotacionDto.SolicitudVerificacion;

/**
 * CUS09 · Verificar elector (actor: miembro de mesa; CEUNP y ADMIN supervisan).
 *
 * <ul>
 *   <li>GET  /api/sufragio/mesas                                  → mesas que puede atender</li>
 *   <li>GET  /api/sufragio/mesas/{id}                             → tablero: mesa, totales, padrón y autorizaciones</li>
 *   <li>POST /api/sufragio/mesas/{id}/verificar {dni | codigo}    → identificarElector (QR o DNI)</li>
 *   <li>POST /api/sufragio/mesas/{id}/autorizaciones              → autorizarCabina</li>
 *   <li>POST /api/sufragio/mesas/{id}/autorizaciones/{a}/anular   → anula una autorización sin usar</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/sufragio/mesas")
@PreAuthorize("hasAnyRole('ADMIN', 'CEUNP', 'MIEMBRO_MESA')")
public class VerificarElectorController {

    private final VerificarElector verificarElector;
    private final VotacionConsulta consulta;
    private final UsuarioActual usuarioActual;
    private final ProcedimientoDao dao;

    public VerificarElectorController(VerificarElector verificarElector, VotacionConsulta consulta,
            UsuarioActual usuarioActual, ProcedimientoDao dao) {
        this.verificarElector = verificarElector;
        this.consulta = consulta;
        this.usuarioActual = usuarioActual;
        this.dao = dao;
    }

    @GetMapping
    public List<Map<String, Object>> mesas(Authentication authentication) {
        Usuario usuario = usuarioActual.requerido(authentication);
        consulta.verificarInstalacion();
        return consulta.mesas(usuario.getRol() == Rol.MIEMBRO_MESA ? miembro(usuario) : null);
    }

    @GetMapping("/{idMesa}")
    public Map<String, Object> tablero(@PathVariable Integer idMesa, Authentication authentication) {
        exigirAcceso(idMesa, authentication);
        return verificarElector.tablero(idMesa);
    }

    @PostMapping("/{idMesa}/verificar")
    public Map<String, Object> verificar(@PathVariable Integer idMesa,
            @Valid @RequestBody SolicitudVerificacion solicitud, Authentication authentication) {
        Usuario usuario = exigirAcceso(idMesa, authentication);
        return verificarElector.verificar(idMesa, solicitud.dni(), solicitud.codigo(), usuario.getId());
    }

    @PostMapping("/{idMesa}/autorizaciones")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> autorizar(@PathVariable Integer idMesa,
            @Valid @RequestBody SolicitudAutorizacion solicitud, Authentication authentication) {
        Usuario usuario = exigirAcceso(idMesa, authentication);
        return verificarElector.autorizar(idMesa, solicitud.idDocente(), solicitud.metodo(),
                solicitud.idCredencial(), usuario.getId());
    }

    @PostMapping("/{idMesa}/autorizaciones/{idAutorizacion}/anular")
    public Map<String, Object> anular(@PathVariable Integer idMesa, @PathVariable Long idAutorizacion,
            @Valid @RequestBody DatosAnulacion datos, Authentication authentication) {
        Usuario usuario = exigirAcceso(idMesa, authentication);
        return verificarElector.anular(idMesa, idAutorizacion, datos.motivo(), usuario.getId());
    }

    /** Un MIEMBRO_MESA solo opera la mesa a la que fue sorteado (igual que MesaController). */
    private Usuario exigirAcceso(Integer idMesa, Authentication authentication) {
        Usuario usuario = usuarioActual.requerido(authentication);
        if (usuario.getRol() == Rol.MIEMBRO_MESA && dao.entero(
                "SELECT COUNT(*) FROM miembro_mesa WHERE id_mesa = ? AND id_docente = ?",
                idMesa, miembro(usuario)) == 0) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No es miembro de esta mesa.");
        }
        return usuario;
    }

    private static Integer miembro(Usuario usuario) {
        if (usuario.getIdDocente() == null) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Esta cuenta no está asociada a un docente.");
        }
        return usuario.getIdDocente();
    }
}
