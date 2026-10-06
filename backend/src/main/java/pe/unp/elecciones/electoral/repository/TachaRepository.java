package pe.unp.elecciones.electoral.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import pe.unp.elecciones.electoral.domain.Tacha;
import pe.unp.elecciones.electoral.domain.TachaEstado;

public interface TachaRepository extends JpaRepository<Tacha, Integer> {
    List<Tacha> findByEstado(TachaEstado estado);
    List<Tacha> findByIdCandidato(Integer idCandidato);
}
