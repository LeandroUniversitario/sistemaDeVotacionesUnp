package pe.unp.elecciones.electoral.controller;

import java.util.List;
import java.util.Map;

import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import pe.unp.elecciones.auth.UsuarioActual;
import pe.unp.elecciones.electoral.dto.VotoRequest;
import pe.unp.elecciones.electoral.service.VotoService;
import pe.unp.elecciones.electoral.votacion.EmitirVoto;

@RestController
@RequestMapping("/api/votos")
public class VotoController {

    private final VotoService votoService;
    private final UsuarioActual usuarioActual;
    private final EmitirVoto emitirVoto;

    public VotoController(VotoService votoService, UsuarioActual usuarioActual, EmitirVoto emitirVoto) {
        this.votoService = votoService;
        this.usuarioActual = usuarioActual;
        this.emitirVoto = emitirVoto;
    }

    /**
     * El voto es personal (RN01): vota el docente de la sesión.
     * Los errores de regla de negocio los traduce ErrorBdHandler.
     * Igual que POST /api/sufragio/votar (CUS10), exige la cabina habilitada por la mesa (CUS09).
     */
    @PostMapping
    public Map<String, Object> emitirVoto(@RequestBody VotoRequest request, Authentication authentication) {
        Integer idDocente = usuarioActual.idDocenteRequerido(authentication);
        if (request != null && request.procesoId() != null) {
            emitirVoto.exigirAutorizacion(request.procesoId(), idDocente);
        }
        Map<String, Object> respuesta = votoService.registrarVoto(request, idDocente);
        emitirVoto.cerrarAutorizacionSiTermino(request.procesoId(), idDocente);
        return respuesta;
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
