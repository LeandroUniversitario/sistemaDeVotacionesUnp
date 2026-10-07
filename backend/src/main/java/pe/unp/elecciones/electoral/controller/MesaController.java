package pe.unp.elecciones.electoral.controller;

import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Rol;
import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.auth.UsuarioActual;
import pe.unp.elecciones.electoral.service.MesaService;

@RestController
@RequestMapping("/api/mesas")
@PreAuthorize("hasAnyRole('ADMIN', 'CEUNP', 'MIEMBRO_MESA')")
public class MesaController {

    private final MesaService mesaService;
    private final UsuarioActual usuarioActual;

    public MesaController(MesaService mesaService, UsuarioActual usuarioActual) {
        this.mesaService = mesaService;
        this.usuarioActual = usuarioActual;
    }

    /** ADMIN y CEUNP ven todas las mesas; un miembro de mesa solo las suyas. */
    @GetMapping
    public List<Map<String, Object>> listarMesas(
            @RequestParam(required = false) Integer procesoId,
            Authentication authentication) {
        Usuario usuario = usuarioActual.requerido(authentication);
        if (usuario.getRol() == Rol.MIEMBRO_MESA) {
            return mesaService.listarMesasDeMiembro(usuario.getIdDocente());
        }
        return mesaService.listarMesas(procesoId);
    }

    @GetMapping("/{id}")
    public Map<String, Object> obtenerMesa(@PathVariable Integer id, Authentication authentication) {
        exigirAcceso(id, authentication);
        return mesaService.obtenerMesa(id);
    }

    @GetMapping("/{id}/miembros")
    public List<Map<String, Object>> miembros(@PathVariable Integer id, Authentication authentication) {
        exigirAcceso(id, authentication);
        return mesaService.miembros(id);
    }

    @GetMapping("/{id}/actas")
    public List<Map<String, Object>> actas(@PathVariable Integer id, Authentication authentication) {
        exigirAcceso(id, authentication);
        return mesaService.actas(id);
    }

    @PostMapping("/{id}/instalar")
    public Map<String, Object> instalar(@PathVariable Integer id, Authentication authentication) {
        Usuario usuario = exigirAcceso(id, authentication);
        return mesaService.instalar(id, usuario.getId());
    }

    @PostMapping("/{id}/cerrar")
    public Map<String, Object> cerrar(@PathVariable Integer id, Authentication authentication) {
        Usuario usuario = exigirAcceso(id, authentication);
        return mesaService.cerrar(id, usuario.getId());
    }

    @GetMapping("/{id}/verificar-elector")
    public Map<String, Object> verificarElector(
            @PathVariable Integer id,
            @RequestParam String dni,
            Authentication authentication) {
        exigirAcceso(id, authentication);
        return mesaService.verificarElector(id, dni);
    }

    /** El frontend lo llama "asistencia": deja constancia de que el elector fue identificado con su DNI. */
    @PostMapping("/{id}/asistencia")
    public Map<String, Object> registrarIdentificacion(
            @PathVariable Integer id,
            @RequestBody DniRequest request,
            Authentication authentication) {
        Usuario usuario = exigirAcceso(id, authentication);
        return mesaService.registrarIdentificacionElector(id, request.dni(), usuario.getId());
    }

    /** Asistencia de los propios miembros de mesa (la registra el CEUNP). */
    @PostMapping("/{id}/miembros/{idDocente}/asistencia")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public List<Map<String, Object>> asistenciaMiembro(
            @PathVariable Integer id,
            @PathVariable Integer idDocente,
            @RequestBody AsistenciaRequest request) {
        return mesaService.registrarAsistenciaMiembro(id, idDocente, request.asistio());
    }

    /** Un MIEMBRO_MESA solo opera la mesa a la que fue sorteado. */
    private Usuario exigirAcceso(Integer idMesa, Authentication authentication) {
        Usuario usuario = usuarioActual.requerido(authentication);
        if (usuario.getRol() == Rol.MIEMBRO_MESA && !mesaService.esMiembro(idMesa, usuario.getIdDocente())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No es miembro de esta mesa.");
        }
        return usuario;
    }

    public record DniRequest(String dni) {
    }

    public record AsistenciaRequest(boolean asistio) {
    }
}
