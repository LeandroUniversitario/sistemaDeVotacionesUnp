package pe.unp.elecciones.electoral.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import pe.unp.elecciones.electoral.domain.ListaElectoral;

public interface ListaElectoralRepository extends JpaRepository<ListaElectoral, Integer> {
    List<ListaElectoral> findByIdCargo(Integer idCargo);
}
