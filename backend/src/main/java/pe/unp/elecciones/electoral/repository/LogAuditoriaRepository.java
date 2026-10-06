package pe.unp.elecciones.electoral.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import pe.unp.elecciones.electoral.domain.LogAuditoria;

import java.time.LocalDateTime;

public interface LogAuditoriaRepository extends JpaRepository<LogAuditoria, Long> {

    @Query("""
        SELECT l FROM LogAuditoria l
        WHERE (:accion IS NULL OR l.accion LIKE %:accion%)
        AND (:idUsuario IS NULL OR l.idUsuario = :idUsuario)
        AND (:desde IS NULL OR l.fechaHora >= :desde)
        AND (:hasta IS NULL OR l.fechaHora <= :hasta)
        ORDER BY l.fechaHora DESC
    """)
    Page<LogAuditoria> buscarFiltrado(
        @Param("accion") String accion,
        @Param("idUsuario") Integer idUsuario,
        @Param("desde") LocalDateTime desde,
        @Param("hasta") LocalDateTime hasta,
        Pageable pageable
    );
}
