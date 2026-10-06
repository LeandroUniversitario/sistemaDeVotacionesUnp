package pe.unp.elecciones.electoral.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import pe.unp.elecciones.electoral.domain.MesaSufragio;
import pe.unp.elecciones.electoral.repository.MesaSufragioRepository;

import java.util.List;

@Service
@Transactional
public class MesaService {

    private final MesaSufragioRepository mesaRepository;

    public MesaService(MesaSufragioRepository mesaRepository) {
        this.mesaRepository = mesaRepository;
    }

    public List<MesaSufragio> listarMesas() {
        return mesaRepository.findAll();
    }

    public MesaSufragio obtenerMesa(Integer mesaId) {
        return mesaRepository.findById(mesaId)
                .orElseThrow(() -> new RuntimeException("Mesa no encontrada"));
    }
}
