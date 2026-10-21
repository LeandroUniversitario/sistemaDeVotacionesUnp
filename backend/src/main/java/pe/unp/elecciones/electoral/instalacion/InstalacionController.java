package pe.unp.elecciones.electoral.instalacion;

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
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Rol;
import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.auth.UsuarioActual;
import pe.unp.elecciones.electoral.instalacion.InstalacionDto.Asistencia;
import pe.unp.elecciones.electoral.instalacion.InstalacionDto.EvaluacionNulidad;
import pe.unp.elecciones.electoral.instalacion.InstalacionDto.LecturaCredencial;
import pe.unp.elecciones.electoral.instalacion.InstalacionDto.Material;
import pe.unp.elecciones.electoral.instalacion.InstalacionDto.NoInstalacion;
import pe.unp.elecciones.electoral.instalacion.InstalacionDto.Reemplazante;

/**
 * CUS08 · Instalar mesa (actor: Presidente de mesa; el CEUNP supervisa).
 *
 * <ul>
 *   <li>POST /mesas/{id}/llegada      → 1 escanearCredencialQR(token) · 2 registrarLlegada(token)
 *       → RegistrarLlegadaMiembro · 3 actualizarAsistencia(id_docente, hora_llegada) · 4 mostrarMiembroPresente()</li>
 *   <li>PUT  /mesas/{id}/material     → 5 ingresarMaterial(...) · 6 verificarMaterial(datos) → VerificarMaterial
 *       · 7 registrarMaterial(id_mesa, estado_material) · 8 mostrarEstadoMaterial()</li>
 *   <li>POST /mesas/{id}/instalar     → 9 confirmarInstalacion() · 10 instalarMesa(id_mesa) → InstalarMesa
 *       · 11 actualizarEstado('INSTALADA', hora_instalacion) · 12 insertarActa('INSTALACION', hash) · 13 mostrarActaInstalacion()</li>
 *   <li>Flujos alternos: llegada con DNI, reemplazantes, NO INSTALADA (RF58) y evaluación de nulidad (RF60).</li>
 * </ul>
 *
 * ADMIN solo consulta. Un MIEMBRO_MESA solo opera la mesa a la que fue sorteado.
 */
@RestController
@RequestMapping("/api/instalacion")
@PreAuthorize("hasAnyRole('ADMIN', 'CEUNP', 'MIEMBRO_MESA')")
public class InstalacionController {

    private final InstalacionConsulta consulta;
    private final RegistrarLlegadaMiembro registrarLlegadaMiembro;
    private final VerificarMaterial verificarMaterial;
    private final InstalarMesa instalarMesa;
    private final UsuarioActual usuarioActual;

    public InstalacionController(InstalacionConsulta consulta, RegistrarLlegadaMiembro registrarLlegadaMiembro,
            VerificarMaterial verificarMaterial, InstalarMesa instalarMesa, UsuarioActual usuarioActual) {
        this.consulta = consulta;
        this.registrarLlegadaMiembro = registrarLlegadaMiembro;
        this.verificarMaterial = verificarMaterial;
        this.instalarMesa = instalarMesa;
        this.usuarioActual = usuarioActual;
    }

    // ─── Consultas ───────────────────────────────────────────────────────────

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

    /** RF60: mesas no instaladas pendientes de evaluación (aviso al CEUNP). */
    @GetMapping("/alertas")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public List<Map<String, Object>> alertas() {
        return consulta.alertas();
    }

    // ─── 1-4 Llegada de miembros y personeros ────────────────────────────────

    @PostMapping("/mesas/{id}/llegada")
    @PreAuthorize("hasAnyRole('CEUNP', 'MIEMBRO_MESA')")
    public Map<String, Object> registrarLlegada(@PathVariable Integer id, @Valid @RequestBody LecturaCredencial lectura,
            Authentication authentication) {
        Usuario usuario = exigirAcceso(id, authentication);
        return registrarLlegadaMiembro.registrarLlegada(id, lectura.codigo(), usuario.getId());
    }

    @PostMapping("/mesas/{id}/miembros/{idDocente}/asistencia")
    @PreAuthorize("hasAnyRole('CEUNP', 'MIEMBRO_MESA')")
    public Map<String, Object> asistenciaMiembro(@PathVariable Integer id, @PathVariable Integer idDocente,
            @Valid @RequestBody Asistencia asistencia, Authentication authentication) {
        Usuario usuario = exigirAcceso(id, authentication);
        return registrarLlegadaMiembro.asistenciaMiembro(id, idDocente, asistencia.presente(), asistencia.dni(),
                usuario.getId());
    }

    @PostMapping("/mesas/{id}/personeros/{idPersonero}/asistencia")
    @PreAuthorize("hasAnyRole('CEUNP', 'MIEMBRO_MESA')")
    public Map<String, Object> asistenciaPersonero(@PathVariable Integer id, @PathVariable Integer idPersonero,
            @Valid @RequestBody Asistencia asistencia, Authentication authentication) {
        Usuario usuario = exigirAcceso(id, authentication);
        return registrarLlegadaMiembro.asistenciaPersonero(id, idPersonero, asistencia.presente(), asistencia.dni(),
                usuario.getId());
    }

    @PostMapping("/mesas/{id}/reemplazantes")
    @PreAuthorize("hasAnyRole('CEUNP', 'MIEMBRO_MESA')")
    public Map<String, Object> registrarReemplazante(@PathVariable Integer id, @Valid @RequestBody Reemplazante datos,
            Authentication authentication) {
        Usuario usuario = exigirPresente(id, authentication);
        return registrarLlegadaMiembro.registrarReemplazante(id, datos.cargo(), datos.dni(), usuario.getId());
    }

    @DeleteMapping("/mesas/{id}/reemplazantes/{cargo}")
    @PreAuthorize("hasAnyRole('CEUNP', 'MIEMBRO_MESA')")
    public Map<String, Object> quitarReemplazante(@PathVariable Integer id, @PathVariable String cargo,
            Authentication authentication) {
        Usuario usuario = exigirPresente(id, authentication);
        return registrarLlegadaMiembro.quitarReemplazante(id, cargo, usuario.getId());
    }

    // ─── 5-8 Material ────────────────────────────────────────────────────────

    @PutMapping("/mesas/{id}/material")
    @PreAuthorize("hasAnyRole('CEUNP', 'MIEMBRO_MESA')")
    public Map<String, Object> ingresarMaterial(@PathVariable Integer id, @Valid @RequestBody Material material,
            Authentication authentication) {
        Usuario usuario = exigirPresente(id, authentication);
        return verificarMaterial.verificarMaterial(id, material, usuario.getId());
    }

    // ─── 9-13 Instalación y flujos alternos ──────────────────────────────────

    @PostMapping("/mesas/{id}/instalar")
    @PreAuthorize("hasAnyRole('CEUNP', 'MIEMBRO_MESA')")
    public Map<String, Object> confirmarInstalacion(@PathVariable Integer id, Authentication authentication) {
        return instalarMesa.instalarMesa(id, exigirAcceso(id, authentication));
    }

    @PostMapping("/mesas/{id}/no-instalada")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> noInstalada(@PathVariable Integer id, @Valid @RequestBody NoInstalacion datos,
            Authentication authentication) {
        return instalarMesa.declararNoInstalada(id, datos.motivo(), usuarioActual.id(authentication));
    }

    @PostMapping("/mesas/{id}/evaluacion-nulidad")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> evaluarNulidad(@PathVariable Integer id, @Valid @RequestBody EvaluacionNulidad datos,
            Authentication authentication) {
        return instalarMesa.evaluarNulidad(id, datos.decision(), datos.fundamento(), usuarioActual.id(authentication));
    }

    private Usuario exigirAcceso(Integer idMesa, Authentication authentication) {
        Usuario usuario = usuarioActual.requerido(authentication);
        if (usuario.getRol() == Rol.MIEMBRO_MESA && !consulta.esMiembro(idMesa, usuario.getIdDocente())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No es miembro de esta mesa.");
        }
        return usuario;
    }

    /** El miembro de mesa que registra material o reemplazantes debe haber registrado su llegada. */
    private Usuario exigirPresente(Integer idMesa, Authentication authentication) {
        Usuario usuario = exigirAcceso(idMesa, authentication);
        if (usuario.getRol() == Rol.MIEMBRO_MESA && !consulta.miembroPresente(idMesa, usuario.getIdDocente())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Registre primero su llegada (lea su fotocheck o ingrese su DNI).");
        }
        return usuario;
    }
}
