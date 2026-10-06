package pe.unp.elecciones.electoral.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import pe.unp.elecciones.electoral.domain.MesaSufragio;

import java.util.Optional;

public interface MesaSufragioRepository extends JpaRepository<MesaSufragio, Integer> {
    Optional<MesaSufragio> findByNumero(String numero);
}
