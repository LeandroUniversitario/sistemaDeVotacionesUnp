package pe.unp.elecciones.electoral.escrutinio;

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

/**
 * CUS12 · Realizar escrutinio y conciliar (actores: Presidente y Secretario de mesa; los
 * personeros fiscalizan; el CEUNP supervisa y puede operar; ADMIN solo consulta).
 *
 * <ul>
 *   <li>POST /mesas/{id}/cedulas       → 1 ingresarTotalCedulas(total) · 2 verificarTotal() → ValidarTotales
 *       · 3 contarVotantes() · 4 mostrarResultadoValidacion()</li>
 *   <li>POST /mesas/{id}/impugnaciones → paso 4 de la tabla 38 (RN24, RF80; se resuelve en el CUS13)</li>
 *   <li>POST /mesas/{id}/conteo        → 5 ingresarConteoManual(conteo_listas) · 6 compararConDigital(conteo)
 *       → ConciliarVotos · 7 contarVotosDigitales() · 8 mostrarCuadre()</li>
 *   <li>POST /mesas/{id}/acta          → 9 confirmarEscrutinio() · 10 crearActa(resultados) → GenerarActaEscrutinio
 *       · 11 insertarActa(hash, contenido) · 12 registrarFirmas(firmas) · 13 mostrarActaGenerada()</li>
 *   <li>POST /mesas/{id}/entrega       → paso 9 de la tabla 38: tres ejemplares y entrega al CEUNP (RF86, RF87)</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/escrutinio")
@PreAuthorize("hasAnyRole('ADMIN', 'CEUNP', 'MIEMBRO_MESA')")
public class EscrutinioController {

    private final EscrutinioConsulta consulta;
    private final ValidarTotales validarTotales;
    private final ConciliarVotos conciliarVotos;
    private final GenerarActaEscrutinio generarActa;
    private final UsuarioActual usuarioActual;

    public EscrutinioController(EscrutinioConsulta consulta, ValidarTotales validarTotales, ConciliarVotos conciliarVotos,
            GenerarActaEscrutinio generarActa, UsuarioActual usuarioActual) {
        this.consulta = consulta;
        this.validarTotales = validarTotales;
        this.conciliarVotos = conciliarVotos;
        this.generarActa = generarActa;
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

    // ─── 1-4 Cédulas del ánfora ──────────────────────────────────────────────

    @PostMapping("/mesas/{id}/cedulas")
    @PreAuthorize("hasAnyRole('CEUNP', 'MIEMBRO_MESA')")
    public Map<String, Object> ingresarTotalCedulas(@PathVariable Integer id, @Valid @RequestBody EscrutinioDto.TotalCedulas datos,
            Authentication authentication) {
        return validarTotales.verificarTotal(id, datos, exigirAcceso(id, authentication));
    }

    // ─── Paso 4: impugnaciones de los personeros ─────────────────────────────

    @PostMapping("/mesas/{id}/impugnaciones")
    @PreAuthorize("hasAnyRole('CEUNP', 'MIEMBRO_MESA')")
    public Map<String, Object> registrarImpugnacion(@PathVariable Integer id, @Valid @RequestBody EscrutinioDto.Impugnacion datos,
            Authentication authentication) {
        return conciliarVotos.registrarImpugnacion(id, datos, exigirAcceso(id, authentication));
    }

    // ─── 5-8 Conteo manual y conciliación ────────────────────────────────────

    @PostMapping("/mesas/{id}/conteo")
    @PreAuthorize("hasAnyRole('CEUNP', 'MIEMBRO_MESA')")
    public Map<String, Object> ingresarConteoManual(@PathVariable Integer id, @Valid @RequestBody EscrutinioDto.ConteoManual datos,
            Authentication authentication) {
        return conciliarVotos.compararConDigital(id, datos, exigirAcceso(id, authentication));
    }

    // ─── 9-13 Acta de escrutinio ─────────────────────────────────────────────

    @PostMapping("/mesas/{id}/acta")
    @PreAuthorize("hasAnyRole('CEUNP', 'MIEMBRO_MESA')")
    public Map<String, Object> confirmarEscrutinio(@PathVariable Integer id, @Valid @RequestBody EscrutinioDto.ConfirmarEscrutinio datos,
            Authentication authentication) {
        return generarActa.crearActa(id, datos, exigirAcceso(id, authentication));
    }

    // ─── Paso 9: entrega al CEUNP ────────────────────────────────────────────

    @PostMapping("/mesas/{id}/entrega")
    @PreAuthorize("hasAnyRole('CEUNP', 'MIEMBRO_MESA')")
    public Map<String, Object> registrarEntrega(@PathVariable Integer id, @Valid @RequestBody EscrutinioDto.Entrega datos,
            Authentication authentication) {
        return generarActa.registrarEntrega(id, datos, exigirAcceso(id, authentication));
    }

    private Usuario exigirAcceso(Integer idMesa, Authentication authentication) {
        Usuario usuario = usuarioActual.requerido(authentication);
        if (usuario.getRol() == Rol.MIEMBRO_MESA && !consulta.esMiembro(idMesa, usuario.getIdDocente())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No es miembro de esta mesa.");
        }
        return usuario;
    }
}
