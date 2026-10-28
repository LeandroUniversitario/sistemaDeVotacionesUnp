package pe.unp.elecciones.electoral.controller;

import jakarta.annotation.PostConstruct;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import pe.unp.elecciones.electoral.domain.ParametroGlobal;
import pe.unp.elecciones.electoral.repository.ParametroGlobalRepository;

import java.util.List;

/**
 * Lista los parámetros globales. Su modificación es del CUS18 (PUT /api/administracion/parametros/{clave},
 * ActualizarParametros): valida el tipo y el rango, bloquea los de la jornada durante la votación,
 * exige el motivo y guarda el historial.
 */
@RestController
@RequestMapping("/api/parametros")
public class ParametrosController {

    private static final String UIT              = "UIT";
    private static final String MULTA_ELECTOR    = "MULTA_ELECTOR_OMISO_PCT";
    private static final String MULTA_MIEMBRO    = "MULTA_MIEMBRO_MESA_OMISO_PCT";

    private final ParametroGlobalRepository repo;

    public ParametrosController(ParametroGlobalRepository repo) {
        this.repo = repo;
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
}
