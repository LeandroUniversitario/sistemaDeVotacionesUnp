package pe.unp.elecciones.electoral.controller;

import java.util.List;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import pe.unp.elecciones.electoral.service.ProcesoService;

/**
 * Consultas sin inicio de sesión (SecurityConfig permite /api/publico/**):
 * verificación de códigos QR y portal de transparencia (RN15).
 * Ninguna de estas consultas revela el sentido de un voto.
 */
@RestController
@RequestMapping("/api/publico")
public class PublicoController {

    private final ProcesoService procesoService;

    public PublicoController(ProcesoService procesoService) {
        this.procesoService = procesoService;
    }

    /** Destino del QR de la constancia de voto. */
    @GetMapping("/constancias/{token}")
    public Map<String, Object> verificarConstancia(@PathVariable String token) {
        return procesoService.verificarConstancia(token);
    }

    /** Destino del QR de un acta: recalcula el SHA-256 y lo compara con la huella guardada. */
    @GetMapping("/actas/{token}")
    public Map<String, Object> verificarActa(@PathVariable String token) {
        return procesoService.verificarActa(token);
    }

    @GetMapping("/procesos/{idProceso}/candidatos")
    public List<Map<String, Object>> candidatos(@PathVariable Integer idProceso) {
        return procesoService.candidatosPublicos(idProceso);
    }

    @GetMapping("/procesos/{idProceso}/resultados")
    public Map<String, Object> resultados(@PathVariable Integer idProceso) {
        return procesoService.resultados(idProceso);
    }
}
