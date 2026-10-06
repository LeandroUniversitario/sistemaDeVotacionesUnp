package pe.unp.elecciones.electoral.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import pe.unp.elecciones.electoral.domain.*;
import pe.unp.elecciones.electoral.dto.VotoRequest;
import pe.unp.elecciones.electoral.repository.CargoElectoralRepository;
import pe.unp.elecciones.electoral.repository.ListaElectoralRepository;
import pe.unp.elecciones.electoral.repository.ProcesoElectoralRepository;
import pe.unp.elecciones.electoral.repository.VotoRepository;

import java.time.LocalDateTime;

@Service
@Transactional
public class VotoService {

    private final VotoRepository votoRepository;
    private final ProcesoElectoralRepository procesoRepository;
    private final CargoElectoralRepository cargoRepository;
    private final ListaElectoralRepository listaRepository;

    public VotoService(VotoRepository votoRepository, ProcesoElectoralRepository procesoRepository, 
                       CargoElectoralRepository cargoRepository, ListaElectoralRepository listaRepository) {
        this.votoRepository = votoRepository;
        this.procesoRepository = procesoRepository;
        this.cargoRepository = cargoRepository;
        this.listaRepository = listaRepository;
    }

    public void registrarVoto(VotoRequest request) {
        ProcesoElectoral proceso = procesoRepository.findById(request.procesoId())
                .orElseThrow(() -> new RuntimeException("Proceso no encontrado"));
        CargoElectoral cargo = cargoRepository.findById(request.cargoId())
                .orElseThrow(() -> new RuntimeException("Cargo no encontrado"));

        ListaElectoral lista = null;
        if (request.listaElegidaId() != null) {
            lista = listaRepository.findById(request.listaElegidaId())
                    .orElseThrow(() -> new RuntimeException("Lista no encontrada"));
        }

        Voto voto = new Voto();
        voto.setProceso(proceso);
        voto.setCargo(cargo);
        voto.setListaElegida(lista);
        voto.setTipo(TipoVoto.valueOf(request.tipo()));
        voto.setFechaHora(LocalDateTime.now());

        votoRepository.save(voto);
    }
}
