package pe.unp.elecciones.electoral.controller;

import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.UsuarioActual;
import pe.unp.elecciones.electoral.dto.VotoRequest;
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

    /**
     * Ya no se vota con la sesión del docente: según CUS09/CUS10 (decisión D14 del informe) el docente
     * no inicia sesión y vota en el terminal que habilita el Secretario de mesa
     * (POST /api/sufragio/terminales/{id}/voto).
     */
    @PostMapping
    public Map<String, Object> emitirVoto(@RequestBody VotoRequest request, Authentication authentication) {
        throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                "D14: el voto se emite en el terminal de la mesa, habilitado por el Secretario tras verificar QR y DNI.");
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
