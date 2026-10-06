package pe.unp.elecciones.electoral.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import pe.unp.elecciones.electoral.domain.ParametroGlobal;

public interface ParametroGlobalRepository extends JpaRepository<ParametroGlobal, String> {
}
