package pe.unp.elecciones.electoral.instalacion;

import java.util.List;
import java.util.Map;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Rol;
import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.auth.UsuarioActual;
import pe.unp.elecciones.electoral.instalacion.InstalacionDto.Asistencia;
import pe.unp.elecciones.electoral.instalacion.InstalacionDto.LecturaCredencial;
import pe.unp.elecciones.electoral.instalacion.InstalacionDto.Material;
import pe.unp.elecciones.electoral.instalacion.InstalacionDto.NoInstalacion;

/**
 * CUS08 · Instalar mesa (actores: miembro de mesa y CEUNP).
 *
 * <ul>
 *   <li>POST /mesas/{id}/acreditar                → lectura del fotocheck o de la credencial del personero</li>
 *   <li>POST /mesas/{id}/miembros/{d}/asistencia  → acreditación con DNI o inasistencia</li>
 *   <li>POST /mesas/{id}/personeros/{p}/asistencia</li>
 *   <li>PUT  /mesas/{id}/material                 → material electoral recibido</li>
 *   <li>POST /mesas/{id}/instalar                 → sp_instalar_mesa: acta de instalación</li>
 *   <li>POST /mesas/{id}/no-instalada             → sp_declarar_mesa_no_instalada (solo CEUNP)</li>
 * </ul>
 *
 * ADMIN solo consulta. Un MIEMBRO_MESA solo opera la mesa a la que fue sorteado.
 */
@RestController
@RequestMapping("/api/instalacion")
@PreAuthorize("hasAnyRole('ADMIN', 'CEUNP', 'MIEMBRO_MESA')")
public class InstalacionController {

    private final InstalacionConsulta consulta;
    private final AcreditarMiembro acreditarMiembro;
    private final RegistrarInstalacion registrarInstalacion;
    private final UsuarioActual usuarioActual;

    public InstalacionController(InstalacionConsulta consulta, AcreditarMiembro acreditarMiembro,
            RegistrarInstalacion registrarInstalacion, UsuarioActual usuarioActual) {
        this.consulta = consulta;
        this.acreditarMiembro = acreditarMiembro;
        this.registrarInstalacion = registrarInstalacion;
        this.usuarioActual = usuarioActual;
    }

    @GetMapping("/procesos")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public List<Map<String, Object>> procesos() {
        return consulta.procesos();
    }

    @GetMapping("/mesas")
    public List<Map<String, Object>> mesas(@RequestParam(required = false) Integer procesoId,
            Authentication authentication) {
        Usuario usuario = usuarioActual.requerido(authentication);
        if (usuario.getRol() == Rol.MIEMBRO_MESA) {
            return consulta.mesasDeMiembro(usuarioActual.idDocenteRequerido(authentication));
        }
        return consulta.mesas(procesoId);
    }

    @GetMapping("/mesas/{id}")
    public Map<String, Object> detalle(@PathVariable Integer id, Authentication authentication) {
        exigirAcceso(id, authentication);
        return consulta.detalle(id);
    }

    @PostMapping("/mesas/{id}/acreditar")
    @PreAuthorize("hasAnyRole('CEUNP', 'MIEMBRO_MESA')")
    public Map<String, Object> acreditar(@PathVariable Integer id, @Valid @RequestBody LecturaCredencial lectura,
            Authentication authentication) {
        Usuario usuario = exigirAcceso(id, authentication);
        return acreditarMiembro.porCredencial(id, lectura.codigo(), usuario.getId());
    }

    @PostMapping("/mesas/{id}/miembros/{idDocente}/asistencia")
    @PreAuthorize("hasAnyRole('CEUNP', 'MIEMBRO_MESA')")
    public Map<String, Object> asistenciaMiembro(@PathVariable Integer id, @PathVariable Integer idDocente,
            @Valid @RequestBody Asistencia asistencia, Authentication authentication) {
        Usuario usuario = exigirAcceso(id, authentication);
        return acreditarMiembro.asistenciaMiembro(id, idDocente, asistencia.presente(), asistencia.dni(), usuario.getId());
    }

    @PostMapping("/mesas/{id}/personeros/{idPersonero}/asistencia")
    @PreAuthorize("hasAnyRole('CEUNP', 'MIEMBRO_MESA')")
    public Map<String, Object> asistenciaPersonero(@PathVariable Integer id, @PathVariable Integer idPersonero,
            @Valid @RequestBody Asistencia asistencia, Authentication authentication) {
        Usuario usuario = exigirAcceso(id, authentication);
        return acreditarMiembro.asistenciaPersonero(id, idPersonero, asistencia.presente(), asistencia.dni(),
                usuario.getId());
    }

    @PutMapping("/mesas/{id}/material")
    @PreAuthorize("hasAnyRole('CEUNP', 'MIEMBRO_MESA')")
    public Map<String, Object> material(@PathVariable Integer id, @Valid @RequestBody Material material,
            Authentication authentication) {
        Usuario usuario = exigirAcceso(id, authentication);
        return registrarInstalacion.guardarMaterial(id, material.items(), material.observaciones(), usuario.getId());
    }

    @PostMapping("/mesas/{id}/instalar")
    @PreAuthorize("hasAnyRole('CEUNP', 'MIEMBRO_MESA')")
    public Map<String, Object> instalar(@PathVariable Integer id, Authentication authentication) {
        return registrarInstalacion.instalar(id, exigirAcceso(id, authentication));
    }

    @PostMapping("/mesas/{id}/no-instalada")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> noInstalada(@PathVariable Integer id, @Valid @RequestBody NoInstalacion datos,
            Authentication authentication) {
        return registrarInstalacion.declararNoInstalada(id, datos.motivo(), usuarioActual.id(authentication));
    }

    private Usuario exigirAcceso(Integer idMesa, Authentication authentication) {
        Usuario usuario = usuarioActual.requerido(authentication);
        if (usuario.getRol() == Rol.MIEMBRO_MESA && !consulta.esMiembro(idMesa, usuario.getIdDocente())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No es miembro de esta mesa.");
        }
        return usuario;
    }
}
