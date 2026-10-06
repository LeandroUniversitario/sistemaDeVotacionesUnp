package pe.unp.elecciones.electoral.controller;

import java.util.List;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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

import pe.unp.elecciones.electoral.domain.Candidato;
import pe.unp.elecciones.electoral.domain.CargoElectoral;
import pe.unp.elecciones.electoral.domain.CategoriaPermitida;
import pe.unp.elecciones.electoral.domain.Docente;
import pe.unp.elecciones.electoral.domain.ListaElectoral;
import pe.unp.elecciones.electoral.domain.ProcesoElectoral;
import pe.unp.elecciones.electoral.domain.Tacha;
import pe.unp.elecciones.electoral.domain.TachaEstado;
import pe.unp.elecciones.electoral.dto.ElectoralRequest.CandidatoRequest;
import pe.unp.elecciones.electoral.dto.ElectoralRequest.CargoRequest;
import pe.unp.elecciones.electoral.dto.ElectoralRequest.CategoriaRequest;
import pe.unp.elecciones.electoral.dto.ElectoralRequest.DocenteRequest;
import pe.unp.elecciones.electoral.dto.ElectoralRequest.DocenteUpdateRequest;
import pe.unp.elecciones.electoral.dto.ElectoralRequest.ListaRequest;
import pe.unp.elecciones.electoral.dto.ElectoralRequest.ProcesoRequest;
import pe.unp.elecciones.electoral.dto.ElectoralRequest.ResolucionTachaRequest;
import pe.unp.elecciones.electoral.dto.ElectoralRequest.TachaRequest;
import pe.unp.elecciones.electoral.service.ElectoralService;

@RestController
@RequestMapping("/api")
public class ElectoralController {

    private final ElectoralService service;

    public ElectoralController(ElectoralService service) {
        this.service = service;
    }

    // ─── Docentes ────────────────────────────────────────────────────────────

    @GetMapping("/docentes")
    public List<Docente> docentes() {
        return service.listarDocentes();
    }

    @PostMapping("/docentes")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public Docente crearDocente(@Valid @RequestBody DocenteRequest request) {
        return service.crearDocente(request);
    }

    @PutMapping("/docentes/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public Docente actualizarDocente(
            @PathVariable Integer id,
            @RequestBody DocenteUpdateRequest request) {
        return service.actualizarDocente(id, request);
    }

    @DeleteMapping("/docentes/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void eliminarDocente(@PathVariable Integer id) {
        service.eliminarDocente(id);
    }

    // ─── Procesos Electorales ─────────────────────────────────────────────────

    @GetMapping("/procesos")
    public List<ProcesoElectoral> procesos() {
        return service.listarProcesos();
    }

    @PostMapping("/procesos")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public ProcesoElectoral crearProceso(@Valid @RequestBody ProcesoRequest request) {
        return service.crearProceso(request);
    }

    // ─── Cargos Electorales ───────────────────────────────────────────────────

    @GetMapping("/procesos/{idProceso}/cargos")
    public List<CargoElectoral> cargos(@PathVariable Integer idProceso) {
        return service.listarCargos(idProceso);
    }

    @PostMapping("/procesos/{idProceso}/cargos")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public CargoElectoral crearCargo(
            @PathVariable Integer idProceso,
            @Valid @RequestBody CargoRequest request) {
        return service.crearCargo(idProceso, request);
    }

    // ─── Listas Electorales ───────────────────────────────────────────────────

    @GetMapping("/cargos/{idCargo}/listas")
    public List<ListaElectoral> listas(@PathVariable Integer idCargo) {
        return service.listarListas(idCargo);
    }

    @PostMapping("/cargos/{idCargo}/listas")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public ListaElectoral crearLista(
            @PathVariable Integer idCargo,
            @Valid @RequestBody ListaRequest request) {
        return service.crearLista(idCargo, request);
    }

    // ─── Categorías Permitidas ────────────────────────────────────────────────

    @PostMapping("/cargos/{idCargo}/categorias-permitidas")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public CategoriaPermitida permitirCategoria(
            @PathVariable Integer idCargo,
            @Valid @RequestBody CategoriaRequest request) {
        return service.permitirCategoria(idCargo, request.categoria());
    }

    // ─── Candidatos ───────────────────────────────────────────────────────────

    @GetMapping("/listas/{idLista}/candidatos")
    public List<Candidato> candidatos(@PathVariable Integer idLista) {
        return service.listarCandidatos(idLista);
    }

    @PostMapping("/listas/{idLista}/candidatos")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public Candidato crearCandidato(
            @PathVariable Integer idLista,
            @Valid @RequestBody CandidatoRequest request) {
        return service.crearCandidato(idLista, request);
    }

    // ─── Tachas ───────────────────────────────────────────────────────────────

    @GetMapping("/tachas")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public List<Tacha> tachas(TachaEstado estado) {
        return service.listarTachas(estado);
    }

    @PostMapping("/tachas")
    public Tacha presentarTacha(@Valid @RequestBody TachaRequest request) {
        return service.presentarTacha(request);
    }

    @PostMapping("/tachas/{idTacha}/resolver")
    @PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
    public Tacha resolverTacha(
            @PathVariable Integer idTacha,
            @Valid @RequestBody ResolucionTachaRequest request) {
        return service.resolverTacha(idTacha, request.estado());
    }
}
