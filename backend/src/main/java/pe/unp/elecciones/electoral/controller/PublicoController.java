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

    /** Destino del QR del acta general de cómputo y de la resolución de proclamación (CUS14). */
    @GetMapping("/computo/{token}")
    public Map<String, Object> verificarActaComputo(@PathVariable String token) {
        return procesoService.verificarActaComputo(token);
    }

    /** RF99: procesos con resultados publicados por el CEUNP. */
    @GetMapping("/resultados")
    public List<Map<String, Object>> resultadosPublicados() {
        return procesoService.resultadosPublicados();
    }

    /** RF99: resultados generales y por mesa, solo después de su publicación. */
    @GetMapping("/procesos/{idProceso}/resultados")
    public Map<String, Object> resultados(@PathVariable Integer idProceso) {
        return procesoService.resultadosPublicos(idProceso);
    }

    /** RF102: resoluciones de nulidad publicadas por el CEUNP (CUS15). */
    @GetMapping("/nulidades")
    public List<Map<String, Object>> nulidadesPublicadas() {
        return procesoService.nulidadesPublicadas();
    }

    /** Destino del QR de una resolución de nulidad: recalcula el SHA-256 de su contenido. */
    @GetMapping("/nulidad/{token}")
    public Map<String, Object> verificarResolucionNulidad(@PathVariable String token) {
        return procesoService.verificarResolucionNulidad(token);
    }

    /** Destino del QR de la resolución que determina las multas (CUS16): totales y huella, sin la relación de docentes. */
    @GetMapping("/multas/{token}")
    public Map<String, Object> verificarResolucionMultas(@PathVariable String token) {
        return procesoService.verificarResolucionMultas(token);
    }
}
