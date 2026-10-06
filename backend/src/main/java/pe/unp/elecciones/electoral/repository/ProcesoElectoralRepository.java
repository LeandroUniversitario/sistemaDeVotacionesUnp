package pe.unp.elecciones.electoral.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import pe.unp.elecciones.electoral.domain.ProcesoElectoral;
import pe.unp.elecciones.electoral.domain.ProcesoEstado;

import java.util.List;

public interface ProcesoElectoralRepository extends JpaRepository<ProcesoElectoral, Integer> {

    /** Detecta si existe algún proceso en estado INSCRIPCION o VOTACION actualmente */
    boolean existsByEstadoIn(List<ProcesoEstado> estados);
}
