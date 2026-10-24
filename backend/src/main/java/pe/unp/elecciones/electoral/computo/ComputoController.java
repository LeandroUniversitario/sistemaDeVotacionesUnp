package pe.unp.elecciones.electoral.computo;

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
 * CUS14 · Computar y proclamar resultados (actor: CEUNP). Boundary «ComputoResultado».
 *
 * <ul>
 *   <li>GET /procesos/{id} → 0 solicitarComputo(idProceso): verificación previa, consolidado,
 *       participación, sesión, acta general, proclamación y publicación</li>
 *   <li>POST /procesos/{id}/concluir-votacion, /sesion, /sesion/personeros → SesionComputo (pasos 1 y 4)</li>
 *   <li>POST /actas/{id}/dudosa, /actas/{id}/comprobacion, /mesas/{id}/calificacion → VerificarActas
 *       (2-5 y A3)</li>
 *   <li>POST /procesos/{id}/computo → 1 ejecutarComputo(idProceso) · 2-15 → ComputarProclamar</li>
 *   <li>POST /procesos/{id}/proclamacion → 16 acreditarGanadora · 17 listaAcreditada</li>
 *   <li>POST /procesos/{id}/publicacion → 18 mostrarResultados · 19 resultadosProclamados</li>
 *   <li>POST /procesos/{id}/segunda-vuelta → A2 (RN33)</li>
 * </ul>
 *
 * ADMIN solo consulta.
 */
@RestController
@RequestMapping("/api/computo")
@PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
public class ComputoController {

    private final ComputoConsulta consulta;
    private final SesionComputo sesionComputo;
    private final VerificarActas verificarActas;
    private final ComputarProclamar computarProclamar;
    private final UsuarioActual usuarioActual;

    public ComputoController(ComputoConsulta consulta, SesionComputo sesionComputo, VerificarActas verificarActas,
            ComputarProclamar computarProclamar, UsuarioActual usuarioActual) {
        this.consulta = consulta;
        this.sesionComputo = sesionComputo;
        this.verificarActas = verificarActas;
        this.computarProclamar = computarProclamar;
        this.usuarioActual = usuarioActual;
    }

    // ─── Consultas ───────────────────────────────────────────────────────────

    @GetMapping("/procesos")
    public List<Map<String, Object>> procesos() {
        return consulta.procesos();
    }

    /** 0 solicitarComputo(idProceso): todo lo que muestra la pantalla del CEUNP. */
    @GetMapping("/procesos/{id}")
    public Map<String, Object> solicitarComputo(@PathVariable Integer id, Authentication authentication) {
        return consulta.detalle(id, usuarioActual.requerido(authentication));
    }

    @GetMapping("/procesos/{id}/resultados-mesa")
    public List<Map<String, Object>> resultadosPorMesa(@PathVariable Integer id) {
        consulta.proceso(id);
        return consulta.resultadosPorMesa(id);
    }

    @GetMapping("/mesas/{id}")
    public Map<String, Object> mesa(@PathVariable Integer id) {
        return consulta.detalleMesa(id);
    }

    // ─── Pasos 1 y 4: votación concluida y sesión de cómputo ────────────────

    @PostMapping("/procesos/{id}/concluir-votacion")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> concluirVotacion(@PathVariable Integer id, Authentication authentication) {
        return sesionComputo.concluirVotacion(id, usuarioActual.requerido(authentication));
    }

    @PostMapping("/procesos/{id}/sesion")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> instalarSesion(@PathVariable Integer id, @Valid @RequestBody ComputoDto.Sesion datos,
            Authentication authentication) {
        return sesionComputo.instalarSesion(id, datos, usuarioActual.requerido(authentication));
    }

    @PostMapping("/procesos/{id}/sesion/personeros")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> registrarPersonero(@PathVariable Integer id, @Valid @RequestBody ComputoDto.Personero datos,
            Authentication authentication) {
        return sesionComputo.registrarPersonero(id, datos, usuarioActual.requerido(authentication));
    }

    // ─── 2-5 Verificación de actas y A3 calificación ────────────────────────

    @PostMapping("/actas/{id}/dudosa")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> marcarDudosa(@PathVariable Integer id, @Valid @RequestBody ComputoDto.ActaDudosa datos,
            Authentication authentication) {
        return verificarActas.marcarDudosa(id, datos, usuarioActual.requerido(authentication));
    }

    @PostMapping("/actas/{id}/comprobacion")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> validarIntegridad(@PathVariable Integer id, @Valid @RequestBody ComputoDto.Comprobacion datos,
            Authentication authentication) {
        return verificarActas.comprobar(id, datos, usuarioActual.requerido(authentication));
    }

    @PostMapping("/mesas/{id}/calificacion")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> calificarMesa(@PathVariable Integer id, @Valid @RequestBody ComputoDto.Calificacion datos,
            Authentication authentication) {
        return verificarActas.calificarMesa(id, datos, usuarioActual.requerido(authentication));
    }

    // ─── 1-15 Cómputo, 16-17 proclamación, 18-19 publicación ────────────────

    @PostMapping("/procesos/{id}/computo")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> ejecutarComputo(@PathVariable Integer id, Authentication authentication) {
        return computarProclamar.ejecutarComputo(id, usuarioActual.requerido(authentication));
    }

    @PostMapping("/procesos/{id}/proclamacion")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> acreditarGanadora(@PathVariable Integer id, @Valid @RequestBody ComputoDto.Proclamacion datos,
            Authentication authentication) {
        return computarProclamar.proclamar(id, datos, usuarioActual.requerido(authentication));
    }

    @PostMapping("/procesos/{id}/publicacion")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> mostrarResultados(@PathVariable Integer id, Authentication authentication) {
        return computarProclamar.publicar(id, usuarioActual.requerido(authentication));
    }

    @PostMapping("/procesos/{id}/segunda-vuelta")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> convocarSegundaVuelta(@PathVariable Integer id, @Valid @RequestBody ComputoDto.SegundaVuelta datos,
            Authentication authentication) {
        return computarProclamar.convocarSegundaVuelta(id, datos, usuarioActual.requerido(authentication));
    }
}
