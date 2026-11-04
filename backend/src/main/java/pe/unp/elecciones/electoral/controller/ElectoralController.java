package pe.unp.elecciones.electoral.controller;

import java.util.List;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import pe.unp.elecciones.electoral.domain.Docente;
import pe.unp.elecciones.electoral.domain.ProcesoElectoral;
import pe.unp.elecciones.electoral.dto.ElectoralRequest.DocenteRequest;
import pe.unp.elecciones.electoral.dto.ElectoralRequest.DocenteUpdateRequest;
import pe.unp.elecciones.electoral.service.ElectoralService;

/**
 * Mantenimiento de docentes y listado de procesos (panel del CEUNP).
 *
 * El listado de docentes trae DNI y correo de toda la planta: solo lo ven CEUNP y ADMIN.
 */
@RestController
@RequestMapping("/api")
public class ElectoralController {

    private final ElectoralService service;

    public ElectoralController(ElectoralService service) {
        this.service = service;
    }

    @GetMapping("/docentes")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public List<Docente> docentes() {
        return service.listarDocentes();
    }

    @PostMapping("/docentes")
    @PreAuthorize("hasRole('CEUNP')")
    public Docente crearDocente(@Valid @RequestBody DocenteRequest request) {
        return service.crearDocente(request);
    }

    @PutMapping("/docentes/{id}")
    @PreAuthorize("hasRole('CEUNP')")
    public Docente actualizarDocente(@PathVariable Integer id, @RequestBody DocenteUpdateRequest request) {
        return service.actualizarDocente(id, request);
    }

    @DeleteMapping("/docentes/{id}")
    @PreAuthorize("hasRole('CEUNP')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void eliminarDocente(@PathVariable Integer id) {
        service.eliminarDocente(id);
    }

    @GetMapping("/procesos")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public List<ProcesoElectoral> procesos() {
        return service.listarProcesos();
    }
}
