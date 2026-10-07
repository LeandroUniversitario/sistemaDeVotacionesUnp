package pe.unp.elecciones.auth;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

/**
 * Resuelve el usuario autenticado (JWT) hacia su fila en la tabla usuario.
 * Los procedimientos almacenados reciben el id del usuario para la bitácora
 * y el id del docente para el voto.
 */
@Component
public class UsuarioActual {

    private final UsuarioRepository usuarioRepository;

    public UsuarioActual(UsuarioRepository usuarioRepository) {
        this.usuarioRepository = usuarioRepository;
    }

    public Usuario requerido(Authentication authentication) {
        if (authentication == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Sesión no disponible");
        }
        return usuarioRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED, "Usuario no disponible"));
    }

    public Integer id(Authentication authentication) {
        return requerido(authentication).getId();
    }

    /** Docente asociado a la cuenta; falla si la cuenta no pertenece a un docente. */
    public Integer idDocenteRequerido(Authentication authentication) {
        Integer idDocente = requerido(authentication).getIdDocente();
        if (idDocente == null) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Esta cuenta no está asociada a un docente.");
        }
        return idDocente;
    }
}
