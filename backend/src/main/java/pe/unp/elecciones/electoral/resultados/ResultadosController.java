package pe.unp.elecciones.electoral.resultados;

import java.util.List;
import java.util.Map;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import pe.unp.elecciones.auth.Rol;
import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.auth.UsuarioActual;

/**
 * CUS17 · Consultar resultados y verificar actas (actores: docente elector y personero de mesa;
 * también los miembros de mesa, el CEUNP y el ADMIN). Boundary «PantallaResultados».
 *
 * <ul>
 *   <li>GET /procesos → 1 seleccionarProceso</li>
 *   <li>GET /procesos/{id} → 2-6 obtenerResultados · ConsultarResultados</li>
 *   <li>POST /verificacion → 7-11 escanearQR, verificarActa · VerificarActa</li>
 *   <li>POST /cotejos → cotejo del ejemplar físico con el documento digital</li>
 *   <li>GET /cotejos → cotejos propios (todos para el CEUNP y el ADMIN)</li>
 *   <li>POST /cotejos/{id}/atencion → el CEUNP atiende la discrepancia</li>
 * </ul>
 *
 * Sin sesión: /api/publico/consulta/** y /api/publico/verificacion/{codigo} (PublicoController).
 */
@RestController
@RequestMapping("/api/resultados")
@PreAuthorize("isAuthenticated()")
public class ResultadosController {

    private final ConsultarResultados consultarResultados;
    private final VerificarActa verificarActa;
    private final ResultadosConsulta consulta;
    private final UsuarioActual usuarioActual;

    public ResultadosController(ConsultarResultados consultarResultados, VerificarActa verificarActa,
            ResultadosConsulta consulta, UsuarioActual usuarioActual) {
        this.consultarResultados = consultarResultados;
        this.verificarActa = verificarActa;
        this.consulta = consulta;
        this.usuarioActual = usuarioActual;
    }

    /** 1 seleccionarProceso(). */
    @GetMapping("/procesos")
    public List<Map<String, Object>> procesos() {
        return consultarResultados.procesos();
    }

    /** 2 obtenerResultados() … 6 mostrarResultados(). */
    @GetMapping("/procesos/{id}")
    public Map<String, Object> resultados(@PathVariable Integer id, Authentication authentication) {
        return consultarResultados.obtenerResultados(id, usuarioActual.requerido(authentication));
    }

    /** 7 escanearQR → 8 verificarActa() → 11 mostrarAutenticidad(). */
    @PostMapping("/verificacion")
    public Map<String, Object> verificar(@Valid @RequestBody ResultadosDto.Verificacion datos, Authentication authentication,
            HttpServletRequest request) {
        return verificarActa.verificar(datos.codigo(), datos.canal(), usuarioActual.requerido(authentication), request.getRemoteAddr());
    }

    @PostMapping("/cotejos")
    public Map<String, Object> cotejar(@Valid @RequestBody ResultadosDto.Cotejo datos, Authentication authentication) {
        return verificarActa.cotejar(datos, usuarioActual.requerido(authentication));
    }

    @GetMapping("/cotejos")
    public List<Map<String, Object>> cotejos(@RequestParam(required = false) Integer idProceso, Authentication authentication) {
        Usuario usuario = usuarioActual.requerido(authentication);
        boolean supervisa = usuario.getRol() == Rol.CEUNP || usuario.getRol() == Rol.ADMIN;
        return consulta.cotejos(idProceso, supervisa ? null : usuario.getId());
    }

    @PostMapping("/cotejos/{id}/atencion")
    @PreAuthorize("hasRole('CEUNP')")
    public Map<String, Object> atender(@PathVariable Integer id, @Valid @RequestBody ResultadosDto.Atencion datos,
            Authentication authentication) {
        return verificarActa.atender(id, datos, usuarioActual.requerido(authentication));
    }
}
