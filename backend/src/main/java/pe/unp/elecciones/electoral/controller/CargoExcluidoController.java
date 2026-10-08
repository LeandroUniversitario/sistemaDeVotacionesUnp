package pe.unp.elecciones.electoral.controller;

import java.util.List;

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
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.domain.CargoExcluido;
import pe.unp.elecciones.electoral.repository.CargoExcluidoRepository;

@RestController
@RequestMapping("/api/cargos-excluidos")
@PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
public class CargoExcluidoController {

    private final CargoExcluidoRepository repository;

    public CargoExcluidoController(CargoExcluidoRepository repository) {
        this.repository = repository;
    }

    @GetMapping
    public List<CargoExcluido> listar() {
        return repository.findAll();
    }

    @PostMapping
    public CargoExcluido crear(@RequestBody CargoExcluido request) {
        if (request.getNombreCargo() == null || request.getNombreCargo().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El nombre del cargo es requerido");
        }
        if (request.getNivel() == null || request.getNivel().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El nivel es requerido");
        }
        
        CargoExcluido cargo = new CargoExcluido(request.getNombreCargo(), request.getNivel(), request.getActivo());
        return repository.save(cargo);
    }

    @PutMapping("/{id}")
    public CargoExcluido actualizar(@PathVariable Integer id, @RequestBody CargoExcluido request) {
        CargoExcluido cargo = repository.findById(id)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Cargo excluido no encontrado"));
            
        if (request.getNombreCargo() != null && !request.getNombreCargo().isBlank()) {
            cargo.setNombreCargo(request.getNombreCargo());
        }
        if (request.getNivel() != null && !request.getNivel().isBlank()) {
            cargo.setNivel(request.getNivel());
        }
        if (request.getActivo() != null) {
            cargo.setActivo(request.getActivo());
        }
        
        return repository.save(cargo);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void eliminar(@PathVariable Integer id) {
        repository.deleteById(id);
    }
}
