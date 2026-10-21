package pe.unp.elecciones.electoral.cierre;

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
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Rol;
import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.auth.UsuarioActual;
import pe.unp.elecciones.electoral.cierre.CierreDto.DatosActa;

/**
 * CUS11 · Cerrar sufragio (actor: Presidente de mesa; el CEUNP supervisa).
 *
 * <ul>
 *   <li>POST /mesas/{id}/cerrar   → 1 solicitarCierre(id_mesa) · 2 cerrarVotacion(id_mesa) → CerrarVotacion
 *       · 3 actualizarEstado('CERRADA', hora_cierre) · 4 mostrarTotalVotantes(total)</li>
 *   <li>POST /mesas/{id}/ausentes → 5 confirmarAusentes() · 6 marcarAusentes(id_mesa) → MarcarAusentes
 *       · 7 actualizarNoVoto(id_mesa) · 8 mostrarListaNoVoto()</li>
 *   <li>POST /mesas/{id}/acta     → 9 ingresarObservaciones(cedulas_no_usadas, observaciones)
 *       · 10 generarActa(datos) → GenerarActaSufragio · 11 insertarActa('SUFRAGIO', hash, contenido)
 *       · 12 registrarFirmas(firmas) · 13 mostrarActaSufragio()</li>
 * </ul>
 *
 * ADMIN solo consulta. Un MIEMBRO_MESA solo ve su mesa y solo el presidente en funciones la cierra.
 */
@RestController
@RequestMapping("/api/cierre")
@PreAuthorize("hasAnyRole('ADMIN', 'CEUNP', 'MIEMBRO_MESA')")
public class CierreController {

    private final CierreConsulta consulta;
    private final CerrarVotacion cerrarVotacion;
    private final MarcarAusentes marcarAusentes;
    private final GenerarActaSufragio generarActaSufragio;
    private final UsuarioActual usuarioActual;

    public CierreController(CierreConsulta consulta, CerrarVotacion cerrarVotacion, MarcarAusentes marcarAusentes,
            GenerarActaSufragio generarActaSufragio, UsuarioActual usuarioActual) {
        this.consulta = consulta;
        this.cerrarVotacion = cerrarVotacion;
        this.marcarAusentes = marcarAusentes;
        this.generarActaSufragio = generarActaSufragio;
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

    // ─── 1-4 Cerrar la votación ──────────────────────────────────────────────

    @PostMapping("/mesas/{id}/cerrar")
    @PreAuthorize("hasAnyRole('CEUNP', 'MIEMBRO_MESA')")
    public Map<String, Object> solicitarCierre(@PathVariable Integer id, Authentication authentication) {
        return cerrarVotacion.cerrarVotacion(id, exigirAcceso(id, authentication));
    }

    // ─── 5-8 Marcar NO VOTÓ ──────────────────────────────────────────────────

    @PostMapping("/mesas/{id}/ausentes")
    @PreAuthorize("hasAnyRole('CEUNP', 'MIEMBRO_MESA')")
    public Map<String, Object> confirmarAusentes(@PathVariable Integer id, Authentication authentication) {
        return marcarAusentes.marcarAusentes(id, exigirAcceso(id, authentication));
    }

    // ─── 9-13 Acta de sufragio ───────────────────────────────────────────────

    @PostMapping("/mesas/{id}/acta")
    @PreAuthorize("hasAnyRole('CEUNP', 'MIEMBRO_MESA')")
    public Map<String, Object> ingresarObservaciones(@PathVariable Integer id, @Valid @RequestBody DatosActa datos,
            Authentication authentication) {
        return generarActaSufragio.generarActa(id, datos, exigirAcceso(id, authentication));
    }

    private Usuario exigirAcceso(Integer idMesa, Authentication authentication) {
        Usuario usuario = usuarioActual.requerido(authentication);
        if (usuario.getRol() == Rol.MIEMBRO_MESA && !consulta.esMiembro(idMesa, usuario.getIdDocente())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No es miembro de esta mesa.");
        }
        return usuario;
    }
}
