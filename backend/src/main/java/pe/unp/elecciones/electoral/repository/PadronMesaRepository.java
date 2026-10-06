package pe.unp.elecciones.electoral.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import pe.unp.elecciones.electoral.domain.PadronMesa;

import java.util.List;
import java.util.Optional;

public interface PadronMesaRepository extends JpaRepository<PadronMesa, PadronMesa.PadronId> {

    @Query("SELECT p FROM PadronMesa p WHERE p.proceso.id = :procesoId")
    List<PadronMesa> findByProcesoId(@Param("procesoId") Integer procesoId);

    @Query("SELECT p FROM PadronMesa p WHERE p.docente.dni = :dni AND p.proceso.id = :procesoId")
    Optional<PadronMesa> findByDocenteDniAndProcesoId(@Param("dni") String dni, @Param("procesoId") Integer procesoId);
}
