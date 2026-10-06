package pe.unp.elecciones.electoral.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import pe.unp.elecciones.electoral.domain.Candidato;

public interface CandidatoRepository extends JpaRepository<Candidato, Integer> {
    List<Candidato> findByIdLista(Integer idLista);
    boolean existsByIdListaAndIdDocente(Integer idLista, Integer idDocente);
    boolean existsByIdDocente(Integer idDocente);
}
