package pe.unp.elecciones.electoral.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import pe.unp.elecciones.electoral.domain.Departamento;

import java.util.Optional;

public interface DepartamentoRepository extends JpaRepository<Departamento, Integer> {
    Optional<Departamento> findByNombreContainingIgnoreCaseAndFacultadId(String nombre, Integer facultadId);
}
