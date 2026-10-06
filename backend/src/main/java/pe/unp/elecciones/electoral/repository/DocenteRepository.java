package pe.unp.elecciones.electoral.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import pe.unp.elecciones.electoral.domain.Docente;

import java.util.Optional;

public interface DocenteRepository extends JpaRepository<Docente, Integer> {
    boolean existsByDni(String dni);
    Optional<Docente> findByDni(String dni);
}
