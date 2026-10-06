package pe.unp.elecciones.electoral.controller;

import jakarta.annotation.PostConstruct;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import pe.unp.elecciones.electoral.domain.ParametroGlobal;
import pe.unp.elecciones.electoral.repository.ParametroGlobalRepository;
import pe.unp.elecciones.electoral.service.AuditoriaService;

import jakarta.servlet.http.HttpServletRequest;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/parametros")
public class ParametrosController {

    private static final String UIT              = "UIT";
    private static final String MULTA_ELECTOR    = "MULTA_ELECTOR_OMISO_PCT";
    private static final String MULTA_MIEMBRO    = "MULTA_MIEMBRO_MESA_OMISO_PCT";

    private final ParametroGlobalRepository repo;
    private final AuditoriaService auditoria;

    public ParametrosController(ParametroGlobalRepository repo, AuditoriaService auditoria) {
        this.repo     = repo;
        this.auditoria = auditoria;
    }

    /** Inicializa los parámetros con valores por defecto si no existen */
    @PostConstruct
    public void inicializar() {
        if (!repo.existsById(UIT)) {
            repo.save(new ParametroGlobal(UIT, "5150.00",
                "Unidad Impositiva Tributaria (UIT) vigente en soles"));
        }
        if (!repo.existsById(MULTA_ELECTOR)) {
            repo.save(new ParametroGlobal(MULTA_ELECTOR, "2.5",
                "Porcentaje de multa para electores omisos (% de UIT)"));
        }
        if (!repo.existsById(MULTA_MIEMBRO)) {
            repo.save(new ParametroGlobal(MULTA_MIEMBRO, "3.0",
                "Porcentaje de multa para miembros de mesa omisos (% de UIT)"));
        }
    }

    /** GET /api/parametros — todos los parámetros actuales */
    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public List<ParametroGlobal> listar() {
        return repo.findAll();
    }

    /** PUT /api/parametros — actualiza uno o más parámetros con trazabilidad */
    @PutMapping
    @PreAuthorize("hasRole('ADMIN')")
    public List<ParametroGlobal> actualizar(
            @RequestBody Map<String, String> cambios,
            HttpServletRequest httpRequest) {

        for (Map.Entry<String, String> entry : cambios.entrySet()) {
            String clave = entry.getKey();
            String valor = entry.getValue();

            ParametroGlobal param = repo.findById(clave)
                .orElseThrow(() -> new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Parámetro desconocido: " + clave));

            // Validación numérica
            try {
                BigDecimal bd = new BigDecimal(valor);
                if (bd.compareTo(BigDecimal.ZERO) < 0) {
                    throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "El valor de " + clave + " no puede ser negativo");
                }
                // Porcentajes: máximo 100
                if ((clave.equals(MULTA_ELECTOR) || clave.equals(MULTA_MIEMBRO))
                        && bd.compareTo(new BigDecimal("100")) > 0) {
                    throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "El porcentaje de " + clave + " no puede superar 100");
                }
            } catch (NumberFormatException e) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "El valor de " + clave + " debe ser numérico");
            }

            String valorAnterior = param.getValor();
            param.setValor(valor);
            repo.save(param);

            // Bitácora inmutable del cambio
            auditoria.registrar(null, null, "CAMBIO_PARAMETRO",
                httpRequest.getRemoteAddr(), httpRequest.getHeader("User-Agent"),
                String.format("{\"clave\":\"%s\",\"anterior\":\"%s\",\"nuevo\":\"%s\"}",
                    clave, valorAnterior, valor));
        }

        return repo.findAll();
    }
}
