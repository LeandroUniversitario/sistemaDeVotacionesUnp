package pe.unp.elecciones.electoral.service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.domain.Candidato;
import pe.unp.elecciones.electoral.domain.CargoElectoral;
import pe.unp.elecciones.electoral.domain.CategoriaPermitida;
import pe.unp.elecciones.electoral.domain.Docente;
import pe.unp.elecciones.electoral.domain.DocenteEstado;
import pe.unp.elecciones.electoral.domain.ListaElectoral;
import pe.unp.elecciones.electoral.domain.NivelJurisdiccion;
import pe.unp.elecciones.electoral.domain.ProcesoElectoral;
import pe.unp.elecciones.electoral.domain.ProcesoEstado;
import pe.unp.elecciones.electoral.domain.ProcesoTipo;
import pe.unp.elecciones.electoral.domain.Tacha;
import pe.unp.elecciones.electoral.domain.TachaEstado;
import pe.unp.elecciones.electoral.dto.ElectoralRequest.CandidatoRequest;
import pe.unp.elecciones.electoral.dto.ElectoralRequest.CargoRequest;
import pe.unp.elecciones.electoral.dto.ElectoralRequest.DocenteRequest;
import pe.unp.elecciones.electoral.dto.ElectoralRequest.DocenteUpdateRequest;
import pe.unp.elecciones.electoral.dto.ElectoralRequest.ListaRequest;
import pe.unp.elecciones.electoral.dto.ElectoralRequest.ProcesoRequest;
import pe.unp.elecciones.electoral.dto.ElectoralRequest.TachaRequest;
import pe.unp.elecciones.electoral.repository.CandidatoRepository;
import pe.unp.elecciones.electoral.repository.CargoElectoralRepository;
import pe.unp.elecciones.electoral.repository.CategoriaPermitidaRepository;
import pe.unp.elecciones.electoral.repository.DocenteRepository;
import pe.unp.elecciones.electoral.repository.ListaElectoralRepository;
import pe.unp.elecciones.electoral.repository.ProcesoElectoralRepository;
import pe.unp.elecciones.electoral.repository.TachaRepository;

@Service
public class ElectoralService {

    private final DocenteRepository docenteRepository;
    private final ProcesoElectoralRepository procesoRepository;
    private final CargoElectoralRepository cargoRepository;
    private final ListaElectoralRepository listaRepository;
    private final CandidatoRepository candidatoRepository;
    private final CategoriaPermitidaRepository categoriaRepository;
    private final TachaRepository tachaRepository;

    public ElectoralService(
            DocenteRepository docenteRepository,
            ProcesoElectoralRepository procesoRepository,
            CargoElectoralRepository cargoRepository,
            ListaElectoralRepository listaRepository,
            CandidatoRepository candidatoRepository,
            CategoriaPermitidaRepository categoriaRepository,
            TachaRepository tachaRepository) {
        this.docenteRepository = docenteRepository;
        this.procesoRepository = procesoRepository;
        this.cargoRepository = cargoRepository;
        this.listaRepository = listaRepository;
        this.candidatoRepository = candidatoRepository;
        this.categoriaRepository = categoriaRepository;
        this.tachaRepository = tachaRepository;
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

    @Transactional
    public ProcesoElectoral crearProceso(ProcesoRequest request) {
        validarFechas(request);
        validarQuorum(request.quorumMinimo());
        // ETAPA 4: Exclusividad — no puede haber otro proceso en INSCRIPCION o VOTACION
        if (procesoRepository.existsByEstadoIn(List.of(ProcesoEstado.INSCRIPCION, ProcesoEstado.VOTACION))) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                "Ya existe un proceso electoral en curso. Finaliza o cancela el proceso activo antes de crear uno nuevo.");
        }
        ProcesoElectoral proceso = new ProcesoElectoral(
                request.nombre(), request.fechaInicio(), request.fechaFin(),
                ProcesoEstado.CREADO, request.tipo(), request.idProcesoPadre(),
                request.quorumMinimo());
        return procesoRepository.save(proceso);
    }

    // ─── Cargos Electorales ───────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<CargoElectoral> listarCargos(Integer idProceso) {
        if (!procesoRepository.existsById(idProceso)) {
            throw notFound("Proceso electoral no encontrado");
        }
        return cargoRepository.findByIdProceso(idProceso);
    }

    @Transactional
    public CargoElectoral crearCargo(Integer idProceso, CargoRequest request) {
        if (!procesoRepository.existsById(idProceso)) {
            throw notFound("Proceso electoral no encontrado");
        }
        if (request.nivelJurisdiccion() == NivelJurisdiccion.UNIVERSIDAD
                && request.idJurisdiccion() != null) {
            throw badRequest("Un cargo universitario no puede tener jurisdicción específica");
        }
        if (request.nivelJurisdiccion() != NivelJurisdiccion.UNIVERSIDAD
                && request.idJurisdiccion() == null) {
            throw badRequest("La jurisdicción específica es obligatoria para facultad o departamento");
        }
        CargoElectoral cargo = new CargoElectoral(
                idProceso, request.nombre(), request.nivelJurisdiccion(), request.idJurisdiccion());
        return cargoRepository.save(cargo);
    }

    // ─── Listas Electorales ───────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<ListaElectoral> listarListas(Integer idCargo) {
        if (!cargoRepository.existsById(idCargo)) {
            throw notFound("Cargo electoral no encontrado");
        }
        return listaRepository.findByIdCargo(idCargo);
    }

    @Transactional
    public ListaElectoral crearLista(Integer idCargo, ListaRequest request) {
        if (!cargoRepository.existsById(idCargo)) {
            throw notFound("Cargo electoral no encontrado");
        }
        return listaRepository.save(new ListaElectoral(idCargo, request.nombre(), request.simbolo()));
    }

    // ─── Categorías Permitidas ────────────────────────────────────────────────

    @Transactional
    public CategoriaPermitida permitirCategoria(Integer idCargo,
            pe.unp.elecciones.electoral.domain.CategoriaDocente categoria) {
        if (!cargoRepository.existsById(idCargo)) {
            throw notFound("Cargo electoral no encontrado");
        }
        if (categoriaRepository.existsByIdCargoAndCategoria(idCargo, categoria)) {
            throw badRequest("La categoría ya está permitida para este cargo");
        }
        return categoriaRepository.save(new CategoriaPermitida(idCargo, categoria));
    }

    // ─── Candidatos ───────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<Candidato> listarCandidatos(Integer idLista) {
        if (!listaRepository.existsById(idLista)) {
            throw notFound("Lista electoral no encontrada");
        }
        return candidatoRepository.findByIdLista(idLista);
    }

    @Transactional
    public Candidato crearCandidato(Integer idLista, CandidatoRequest request) {
        ListaElectoral lista = listaRepository.findById(idLista)
                .orElseThrow(() -> notFound("Lista electoral no encontrada"));
        Docente docente = docenteRepository.findById(request.idDocente())
                .orElseThrow(() -> notFound("Docente no encontrado"));
        if (docente.getEstado() != DocenteEstado.ACTIVO) {
            throw badRequest("Solo un docente activo puede integrar una lista");
        }
        if (!categoriaRepository.existsByIdCargoAndCategoria(
                lista.getIdCargo(), docente.getCategoria())) {
            throw badRequest("La categoría del docente no está permitida para este cargo");
        }
        if (candidatoRepository.existsByIdListaAndIdDocente(idLista, request.idDocente())) {
            throw badRequest("El docente ya integra esta lista");
        }
        return candidatoRepository.save(new Candidato(idLista, request.idDocente(), request.rolEnLista()));
    }

    // ─── Tachas ───────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<Tacha> listarTachas(TachaEstado estado) {
        return estado == null ? tachaRepository.findAll() : tachaRepository.findByEstado(estado);
    }

    @Transactional
    public Tacha presentarTacha(TachaRequest request) {
        docenteRepository.findById(request.idDocenteDenunciante())
                .orElseThrow(() -> notFound("Docente denunciante no encontrado"));
        candidatoRepository.findById(request.idCandidato())
                .orElseThrow(() -> notFound("Candidato no encontrado"));
        return tachaRepository.save(
                new Tacha(request.idDocenteDenunciante(), request.idCandidato(), request.motivo()));
    }

    @Transactional
    public Tacha resolverTacha(Integer idTacha, TachaEstado resultado) {
        if (resultado == TachaEstado.PENDIENTE) {
            throw badRequest("Una tacha resuelta debe ser fundada o infundada");
        }
        Tacha tacha = tachaRepository.findById(idTacha)
                .orElseThrow(() -> notFound("Tacha no encontrada"));
        if (tacha.getEstado() != TachaEstado.PENDIENTE) {
            throw badRequest("La tacha ya fue resuelta");
        }
        tacha.resolver(resultado);
        if (resultado == TachaEstado.FUNDADA) {
            Candidato candidato = candidatoRepository.findById(tacha.getIdCandidato())
                    .orElseThrow(() -> notFound("Candidato no encontrado"));
            candidato.excluir();
            candidatoRepository.save(candidato);
        }
        return tachaRepository.save(tacha);
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private void validarFechas(ProcesoRequest request) {
        LocalDateTime ahora = LocalDateTime.now();

        // inicio debe ser posterior a la fecha actual del servidor
        if (!request.fechaInicio().isAfter(ahora)) {
            throw badRequest("La fecha y hora de inicio debe ser posterior a la fecha/hora actual del servidor.");
        }
        // fin debe ser estrictamente posterior al inicio
        if (!request.fechaFin().isAfter(request.fechaInicio())) {
            throw badRequest("La fecha de fin debe ser posterior a la fecha de inicio.");
        }
        // Duración sugerida: 6 horas (advertencia, no bloqueo)
        long horas = ChronoUnit.HOURS.between(request.fechaInicio(), request.fechaFin());
        if (horas < 4 || horas > 12) {
            // no bloqueamos, pero registramos en detalle (lo puede revisar el frontend)
        }
        // Segunda vuelta requiere proceso padre
        if (request.tipo() == ProcesoTipo.SEGUNDA_VUELTA && request.idProcesoPadre() == null) {
            throw badRequest("La segunda vuelta debe indicar el proceso electoral padre.");
        }
    }

    private void validarQuorum(BigDecimal quorum) {
        if (quorum.compareTo(BigDecimal.ZERO) < 0 || quorum.compareTo(new BigDecimal("100")) > 0) {
            throw badRequest("El quórum mínimo debe estar entre 0 y 100");
        }
    }

    private ResponseStatusException badRequest(String message) {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
    }

    private ResponseStatusException notFound(String message) {
        return new ResponseStatusException(HttpStatus.NOT_FOUND, message);
    }
}
