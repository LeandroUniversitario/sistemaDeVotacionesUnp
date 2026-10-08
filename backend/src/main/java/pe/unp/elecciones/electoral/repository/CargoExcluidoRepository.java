package pe.unp.elecciones.electoral.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import pe.unp.elecciones.electoral.domain.CargoExcluido;

@Repository
public interface CargoExcluidoRepository extends JpaRepository<CargoExcluido, Integer> {
}
