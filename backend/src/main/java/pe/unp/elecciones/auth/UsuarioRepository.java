package pe.unp.elecciones.auth;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UsuarioRepository extends JpaRepository<Usuario, Integer> {
    Optional<Usuario> findByUsername(String username);
    boolean existsByUsername(String username);
    long countByRolAndActivo(Rol rol, boolean activo);
    /** Permite verificar si un docente ya tiene cuenta antes de crear una nueva. */
    Optional<Usuario> findByIdDocente(Integer idDocente);
}