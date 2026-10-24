package pe.unp.elecciones.electoral.nulidades;

import java.util.List;
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

import pe.unp.elecciones.auth.UsuarioActual;

/**
 * CUS15 · Gestionar nulidades y segunda vuelta (actor: CEUNP). Boundary «PantallaNulidades».
 *
 * <ul>
 *   <li>GET /procesos/{id} → recursos, mesas, comunicaciones, cargos y segunda vuelta</li>
 *   <li>POST /procesos/{id}/parcial → 1 ingresarNulidadParcial · DeclararNulidadParcial</li>
 *   <li>POST /procesos/{id}/total → 5 ingresarNulidadTotal · DeclararNulidadTotal</li>
 *   <li>POST /{id}/resolucion → 2-4 anularMesa o 6-7 anularProceso (según el alcance)</li>
 *   <li>POST /{id}/comunicaciones → 8 registrarComunicacion('SUNEDU, AU, CU')</li>
 *   <li>GET /{id} → 9 mostrarResolucionNulidad</li>
 *   <li>POST /procesos/{id}/segunda-vuelta → 10-15 ConfigurarSegundaVuelta</li>
 *   <li>POST /cargos/{id}/dirimencia → sorteo del Pleno ante un empate</li>
 * </ul>
 *
 * ADMIN solo consulta.
 */
@RestController
@RequestMapping("/api/nulidades")
@PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
public class NulidadesController {

    private final NulidadesConsulta consulta;
    private final DeclararNulidadParcial nulidadParcial;
    private final DeclararNulidadTotal nulidadTotal;
    private final ConfigurarSegundaVuelta segundaVuelta;
    private final UsuarioActual usuarioActual;

    public NulidadesController(NulidadesConsulta consulta, DeclararNulidadParcial nulidadParcial,
            DeclararNulidadTotal nulidadTotal, ConfigurarSegundaVuelta segundaVuelta, UsuarioActual usuarioActual) {
        this.consulta = consulta;
        this.nulidadParcial = nulidadParcial;
        this.nulidadTotal = nulidadTotal;
        this.segundaVuelta = segundaVuelta;
        this.usuarioActual = usuarioActual;
    }

    // ─── Consultas ───────────────────────────────────────────────────────────

    @GetMapping("/procesos")
    public List<Map<String, Object>> procesos() {
        return consulta.procesos();
    }

    @GetMapping("/procesos/{id}")
    public Map<String, Object> detalle(@PathVariable Integer id, Authentication authentication) {
        return consulta.detalle(id, usuarioActual.requerido(authentication));
    }

    /** 4 mostrarMesaExcluida(). */
    @GetMapping("/mesas/{id}")
    public Map<String, Object> mesa(@PathVariable Integer id) {
        return consulta.detalleMesa(id);
    }

    /** 9 mostrarResolucionNulidad(). */
    @GetMapping("/{id}")
    public Map<String, Object> nulidad(@PathVariable Integer id) {
        return consulta.nulidad(id);
    }

    // ─── 1-4 Nulidad parcial y 5-9 nulidad total ────────────────────────────

    @PostMapping("/procesos/{id}/parcial")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> ingresarNulidadParcial(@PathVariable Integer id, @Valid @RequestBody NulidadesDto.RecursoParcial datos,
            Authentication authentication) {
        return nulidadParcial.registrar(id, datos, usuarioActual.requerido(authentication));
    }

    @PostMapping("/procesos/{id}/total")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> ingresarNulidadTotal(@PathVariable Integer id, @Valid @RequestBody NulidadesDto.RecursoTotal datos,
            Authentication authentication) {
        return nulidadTotal.registrar(id, datos, usuarioActual.requerido(authentication));
    }

    @PostMapping("/{id}/resolucion")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> resolver(@PathVariable Integer id, @Valid @RequestBody NulidadesDto.Resolucion datos,
            Authentication authentication) {
        Map<String, Object> recurso = consulta.recurso(id);
        return "PARCIAL".equals(NulidadesConsulta.texto(recurso.get("alcance")))
                ? nulidadParcial.resolver(recurso, datos, usuarioActual.requerido(authentication))
                : nulidadTotal.resolver(recurso, datos, usuarioActual.requerido(authentication));
    }

    @PostMapping("/{id}/comunicaciones")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> registrarComunicacion(@PathVariable Integer id, @Valid @RequestBody NulidadesDto.Comunicacion datos,
            Authentication authentication) {
        return nulidadTotal.comunicar(id, datos, usuarioActual.requerido(authentication));
    }

    // ─── 10-15 Segunda vuelta y dirimencia de empates ───────────────────────

    @PostMapping("/procesos/{id}/segunda-vuelta")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> convocarSegundaVuelta(@PathVariable Integer id, @Valid @RequestBody NulidadesDto.SegundaVuelta datos,
            Authentication authentication) {
        return segundaVuelta.convocar(id, datos, usuarioActual.requerido(authentication));
    }

    @PostMapping("/cargos/{id}/dirimencia")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> dirimirEmpate(@PathVariable Integer id, @Valid @RequestBody NulidadesDto.Dirimencia datos,
            Authentication authentication) {
        return segundaVuelta.dirimir(id, datos, usuarioActual.requerido(authentication));
    }
}
