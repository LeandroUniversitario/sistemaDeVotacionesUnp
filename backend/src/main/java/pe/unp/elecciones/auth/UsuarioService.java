package pe.unp.elecciones.auth;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class UsuarioService {
    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;

    public UsuarioService(UsuarioRepository usuarioRepository, PasswordEncoder passwordEncoder) {
        this.usuarioRepository = usuarioRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional(readOnly = true)
    public List<Usuario> listar() {
        return usuarioRepository.findAll();
    }

    @Transactional
    public Usuario crear(CrearUsuarioRequest request) {
        String username = request.username().trim();
        if (username.length() < 3 || username.length() > 80) {
            throw badRequest("El usuario debe tener entre 3 y 80 caracteres");
        }

        if (!username.matches("[A-Za-z0-9._-]+")) {
            throw badRequest("El usuario solo puede contener letras, números, punto, guion y guion bajo");
        }
        if (request.password().length() < 8) {
            throw badRequest("La contraseña debe tener al menos 8 caracteres");
        }
        if (usuarioRepository.existsByUsername(username)) {
            throw badRequest("El nombre de usuario ya existe");
        }
        if (requiereDocente(request.rol()) && request.idDocente() == null) {
            throw badRequest("Este rol requiere asociar un docente");
        }
        return usuarioRepository.save(new Usuario(
                username,
                passwordEncoder.encode(request.password()),
                request.rol(),
                request.idDocente()));
    }

    @Transactional
    public void cambiarPassword(String username, String passwordActual, String passwordNueva) {
        if (passwordNueva == null || passwordNueva.length() < 8) {
            throw badRequest("La nueva contraseña debe tener al menos 8 caracteres");
        }
        Usuario usuario = usuarioRepository.findByUsername(username)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED, "Usuario no disponible"));
        if (!passwordEncoder.matches(passwordActual, usuario.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La contraseña actual no es correcta");
        }
        usuario.cambiarPassword(passwordEncoder.encode(passwordNueva));
        usuarioRepository.save(usuario);
    }

    @Transactional
    public Usuario cambiarEstado(Integer id, boolean activo) {
        Usuario usuario = buscar(id);
        if (!activo && usuario.getRol() == Rol.ADMIN
                && usuarioRepository.countByRolAndActivo(Rol.ADMIN, true) <= 1) {
            throw badRequest("Debe existir al menos un administrador activo");
        }
        usuario.cambiarEstado(activo);
        return usuarioRepository.save(usuario);
    }

    @Transactional
    public void eliminar(Integer id, String usuarioActual) {
        Usuario usuario = buscar(id);
        if (usuario.getUsername().equals(usuarioActual)) {
            throw badRequest("No puedes eliminar tu propia cuenta");
        }
        if (usuario.getRol() == Rol.ADMIN && usuario.isActivo()
                && usuarioRepository.countByRolAndActivo(Rol.ADMIN, true) <= 1) {
            throw badRequest("Debe existir al menos un administrador activo");
        }
        usuarioRepository.delete(usuario);
    }

    @Transactional
    public Usuario cambiarRol(Integer id, Rol nuevoRol, String usuarioActual) {
        Usuario usuario = buscar(id);
        // No puede cambiar su propio rol
        if (usuario.getUsername().equals(usuarioActual)) {
            throw badRequest("No puedes cambiar tu propio rol");
        }
        // Si se degrada el único ADMIN activo
        if (usuario.getRol() == Rol.ADMIN && nuevoRol != Rol.ADMIN && usuario.isActivo()
                && usuarioRepository.countByRolAndActivo(Rol.ADMIN, true) <= 1) {
            throw badRequest("Debe existir al menos un administrador activo");
        }
        usuario.cambiarRol(nuevoRol);
        return usuarioRepository.save(usuario);
    }

    @Transactional
    public void restablecerPassword(Integer id, String nuevaPassword) {
        if (nuevaPassword == null || nuevaPassword.length() < 8) {
            throw badRequest("La nueva contraseña debe tener al menos 8 caracteres");
        }
        Usuario usuario = buscar(id);
        usuario.cambiarPassword(passwordEncoder.encode(nuevaPassword));
        usuarioRepository.save(usuario);
    }

    private boolean requiereDocente(Rol rol) {
        return rol == Rol.DOCENTE || rol == Rol.PERSONERO || rol == Rol.MIEMBRO_MESA;
    }

    private Usuario buscar(Integer id) {
        return usuarioRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Usuario no encontrado"));
    }

    private ResponseStatusException badRequest(String message) {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
    }

    public record CrearUsuarioRequest(
            String username,
            String password,
            Rol rol,
            Integer idDocente) {
    }
}
