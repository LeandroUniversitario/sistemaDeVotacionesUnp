package pe.unp.elecciones.electoral.controller;

import java.util.List;
import java.util.Map;

import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import pe.unp.elecciones.auth.UsuarioActual;
import pe.unp.elecciones.electoral.service.VotoService;

@RestController
@RequestMapping("/api/votos")
public class VotoController {

    private final VotoService votoService;
    private final UsuarioActual usuarioActual;

    public VotoController(VotoService votoService, UsuarioActual usuarioActual) {
        this.votoService = votoService;
        this.usuarioActual = usuarioActual;
    }

    /** Cargos pendientes y ya votados del docente en los procesos en votación. */
    @GetMapping("/mis-cargos")
    public List<Map<String, Object>> misCargos(Authentication authentication) {
        return votoService.cargosDelElector(usuarioActual.idDocenteRequerido(authentication));
    }

    @GetMapping("/mis-constancias")
    public List<Map<String, Object>> misConstancias(Authentication authentication) {
        return votoService.constanciasDelElector(usuarioActual.idDocenteRequerido(authentication));
    }
}
