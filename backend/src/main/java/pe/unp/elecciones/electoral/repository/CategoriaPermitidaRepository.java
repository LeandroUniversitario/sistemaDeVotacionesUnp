package pe.unp.elecciones.electoral.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import pe.unp.elecciones.electoral.domain.CategoriaDocente;
import pe.unp.elecciones.electoral.domain.CategoriaPermitida;
import pe.unp.elecciones.electoral.domain.CategoriaPermitidaId;

public interface CategoriaPermitidaRepository extends JpaRepository<CategoriaPermitida, CategoriaPermitidaId> {
    boolean existsByIdCargoAndCategoria(Integer idCargo, CategoriaDocente categoria);
}
