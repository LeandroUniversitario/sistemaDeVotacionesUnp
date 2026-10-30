package pe.unp.elecciones.electoral.padron;

import java.util.List;
import java.util.Map;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import pe.unp.elecciones.auth.UsuarioActual;

/**
 * CUS02 · Gestionar padrón electoral (actor: CEUNP).
 *
 * Punto de entrada HTTP de la «PantallaPadron»:
 * <ul>
 *   <li>POST /api/padron/importar                  → ImportarDocentes.leerDatos          (1-4)</li>
 *   <li>POST /api/padron/depurar                   → FiltrarHabilitados.procesarReglas   (5-8)</li>
 *   <li>POST /api/padron/procesos/{id}/aprobar     → AprobarPadron.generarDefinitivo     (9-12)</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/padron")
@PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
public class PadronController {

    private final PadronConsulta consulta;
    private final ImportarDocentes importarDocentes;
    private final FiltrarHabilitados filtrarHabilitados;
    private final AprobarPadron aprobarPadron;
    private final UsuarioActual usuarioActual;

    public PadronController(PadronConsulta consulta, ImportarDocentes importarDocentes,
            FiltrarHabilitados filtrarHabilitados, AprobarPadron aprobarPadron, UsuarioActual usuarioActual) {
        this.consulta = consulta;
        this.importarDocentes = importarDocentes;
        this.filtrarHabilitados = filtrarHabilitados;
        this.aprobarPadron = aprobarPadron;
        this.usuarioActual = usuarioActual;
    }

    // ─── 1-4: Importar docentes ──────────────────────────────────────────────

    @GetMapping("/resumen")
    public Map<String, Object> resumen() {
        return consulta.resumenDocentes();
    }

    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/importar")
    public Map<String, Object> importar(@RequestParam("archivo") MultipartFile archivo, Authentication authentication) {
        return importarDocentes.leerDatos(archivo, usuarioActual.id(authentication));
    }

    // ─── 5-8: Depurar padrón ─────────────────────────────────────────────────

    @GetMapping("/depurado")
    public Map<String, Object> listaDepurada() {
        return filtrarHabilitados.mostrarListaDepurada();
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    @PostMapping("/depurar")
    public Map<String, Object> depurar(Authentication authentication) {
        return filtrarHabilitados.procesarReglas(usuarioActual.id(authentication));
    }

    // ─── 9-12: Aprobar padrón definitivo por proceso ─────────────────────────

    @GetMapping("/procesos")
    public List<Map<String, Object>> procesos() {
        return consulta.procesos();
    }

    @GetMapping("/procesos/{idProceso}")
    public Map<String, Object> detalleProceso(@PathVariable Integer idProceso) {
        return consulta.detalleProceso(idProceso);
    }

    @GetMapping("/procesos/{idProceso}/electores")
    public List<Map<String, Object>> electores(@PathVariable Integer idProceso) {
        return consulta.padron(idProceso);
    }

    @PostMapping("/procesos/{idProceso}/aprobar")
    public Map<String, Object> aprobar(@PathVariable Integer idProceso, Authentication authentication) {
        return aprobarPadron.generarDefinitivo(idProceso, usuarioActual.id(authentication));
    }
}
