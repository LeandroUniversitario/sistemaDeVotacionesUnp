package pe.unp.elecciones.electoral.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.domain.Docente;
import pe.unp.elecciones.electoral.domain.DocenteEstado;
import pe.unp.elecciones.electoral.domain.ProcesoElectoral;
import pe.unp.elecciones.electoral.dto.ElectoralRequest.DocenteRequest;
import pe.unp.elecciones.electoral.dto.ElectoralRequest.DocenteUpdateRequest;
import pe.unp.elecciones.electoral.repository.CandidatoRepository;
import pe.unp.elecciones.electoral.repository.DocenteRepository;
import pe.unp.elecciones.electoral.repository.ProcesoElectoralRepository;

/**
 * Mantenimiento de docentes (CEUNP) y listado de procesos.
 *
 * Las altas de procesos, cargos, listas, candidatos y tachas por JPA se eliminaron: saltaban la
 * bitácora y reglas como RN02. Esas operaciones viven en sus CUS (convocatoria/, inscripcion/,
 * tachas/), que usan procedimientos almacenados con bitácora.
 */
@Service
public class ElectoralService {

    private final DocenteRepository docenteRepository;
    private final ProcesoElectoralRepository procesoRepository;
    private final CandidatoRepository candidatoRepository;

    public ElectoralService(DocenteRepository docenteRepository, ProcesoElectoralRepository procesoRepository,
            CandidatoRepository candidatoRepository) {
        this.docenteRepository = docenteRepository;
        this.procesoRepository = procesoRepository;
        this.candidatoRepository = candidatoRepository;
    }

    // ─── Docentes ────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<Docente> listarDocentes() {
        return docenteRepository.findAll();
    }

    @Transactional
    public Docente crearDocente(DocenteRequest request) {
        if (!request.dni().matches("\\d{8}")) {
            throw badRequest("El DNI debe contener exactamente 8 dígitos");
        }
        if (docenteRepository.existsByDni(request.dni())) {
            throw badRequest("Ya existe un docente con ese DNI");
        }
        Docente docente = new Docente(
                request.dni(), request.nombres(), request.apellidos(),
                request.categoria(), request.dedicacion(), DocenteEstado.ACTIVO,
                request.idFacultad(), request.idDepartamento());
        return docenteRepository.save(docente);
    }

    @Transactional
    public Docente actualizarDocente(Integer id, DocenteUpdateRequest request) {
        Docente docente = docenteRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Docente no encontrado"));
        if (request.nombres()   != null) docente.setNombres(request.nombres());
        if (request.apellidos() != null) docente.setApellidos(request.apellidos());
        if (request.categoria() != null) docente.setCategoria(request.categoria());
        if (request.dedicacion() != null) docente.setDedicacion(request.dedicacion());
        if (request.estado()    != null) docente.setEstado(request.estado());
        if (request.idFacultad() != null) docente.setIdFacultad(request.idFacultad());
        if (request.idDepartamento() != null) docente.setIdDepartamento(request.idDepartamento());
        return docenteRepository.save(docente);
    }

    @Transactional
    public void eliminarDocente(Integer id) {
        if (!docenteRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Docente no encontrado");
        }
        if (candidatoRepository.existsByIdDocente(id)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                "El docente tiene candidaturas registradas y no puede ser eliminado");
        }
        docenteRepository.deleteById(id);
    }

    // ─── Procesos Electorales ─────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<ProcesoElectoral> listarProcesos() {
        return procesoRepository.findAll();
    }

    private ResponseStatusException badRequest(String message) {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
    }
}
