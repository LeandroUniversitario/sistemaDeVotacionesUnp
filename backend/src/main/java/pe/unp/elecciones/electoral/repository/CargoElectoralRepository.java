package pe.unp.elecciones.electoral.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import pe.unp.elecciones.electoral.domain.CargoElectoral;

public interface CargoElectoralRepository extends JpaRepository<CargoElectoral, Integer> {
    List<CargoElectoral> findByIdProceso(Integer idProceso);
}
