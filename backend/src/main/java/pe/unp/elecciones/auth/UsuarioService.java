package pe.unp.elecciones.auth;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.repository.ParametroGlobalRepository;

/**
 * Cuenta propia: listado y cambio de la contraseña del usuario que inició sesión.
 * La administración de las cuentas (crear, editar, activar, desbloquear, restablecer y
 * eliminar) es del CUS18: pe.unp.elecciones.electoral.administracion.GestionarUsuarios.
 */
@Service
public class UsuarioService {
    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;
    private final ParametroGlobalRepository parametros;

    public UsuarioService(UsuarioRepository usuarioRepository, PasswordEncoder passwordEncoder,
            ParametroGlobalRepository parametros) {
        this.usuarioRepository = usuarioRepository;
        this.passwordEncoder = passwordEncoder;
        this.parametros = parametros;
    }

    @Transactional(readOnly = true)
    public List<Usuario> listar() {
        return usuarioRepository.findAll();
    }

    @Transactional
    public void cambiarPassword(String username, String passwordActual, String passwordNueva) {
        int minimo = parametroEntero("SEGURIDAD_PASSWORD_MIN", 8);
        if (passwordNueva == null || passwordNueva.length() < minimo) {
            throw badRequest("La nueva contraseña debe tener al menos " + minimo + " caracteres");
        }
        Usuario usuario = usuarioRepository.findByUsername(username)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED, "Usuario no disponible"));
        if (!passwordEncoder.matches(passwordActual, usuario.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La contraseña actual no es correcta");
        }
        if (passwordEncoder.matches(passwordNueva, usuario.getPasswordHash())) {
            throw badRequest("La nueva contraseña debe ser distinta de la actual");
        }
        usuario.cambiarPassword(passwordEncoder.encode(passwordNueva));
        usuarioRepository.save(usuario);
    }

    /** CUS18: valor entero de un parámetro de seguridad (parametro_global). */
    public int parametroEntero(String clave, int porDefecto) {
        return parametros.findById(clave).map(p -> {
            try {
                return (int) Math.round(Double.parseDouble(p.getValor().trim()));
            } catch (NumberFormatException e) {
                return porDefecto;
            }
        }).orElse(porDefecto);
    }

    private ResponseStatusException badRequest(String message) {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
    }
}
