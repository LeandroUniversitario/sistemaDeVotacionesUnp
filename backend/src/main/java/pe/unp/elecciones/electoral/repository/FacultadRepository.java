package pe.unp.elecciones.electoral.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import pe.unp.elecciones.electoral.domain.Facultad;

import java.util.Optional;

public interface FacultadRepository extends JpaRepository<Facultad, Integer> {
    Optional<Facultad> findByNombreContainingIgnoreCase(String nombre);
}
