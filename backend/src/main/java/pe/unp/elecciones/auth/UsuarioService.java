package pe.unp.elecciones.auth;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.repository.ParametroGlobalRepository;
import pe.unp.elecciones.electoral.service.AuditoriaService;

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
    private final PoliticaPassword politica;
    private final AuditoriaService auditoriaService;

    public UsuarioService(UsuarioRepository usuarioRepository, PasswordEncoder passwordEncoder,
            ParametroGlobalRepository parametros, PoliticaPassword politica, AuditoriaService auditoriaService) {
        this.politica = politica;
        this.auditoriaService = auditoriaService;
        this.usuarioRepository = usuarioRepository;
        this.passwordEncoder = passwordEncoder;
        this.parametros = parametros;
    }

    @Transactional(readOnly = true)
    public List<Usuario> listar() {
        return usuarioRepository.findAll();
    }

    /**
     * Cambio de la clave propia con la política única (B2). Fallar la clave actual cuenta como intento
     * fallido y puede bloquear la cuenta, igual que en el login.
     */
    @Transactional(noRollbackFor = ResponseStatusException.class)
    public void cambiarPassword(String username, String passwordActual, String passwordNueva, String ip, String agente) {
        Usuario usuario = usuarioRepository.findByUsername(username)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED, "Usuario no disponible"));
        if (!passwordEncoder.matches(passwordActual, usuario.getPasswordHash())) {
            usuario.registrarIntentoFallido(parametroEntero("SEGURIDAD_INTENTOS_MAXIMOS", 5),
                    parametroEntero("SEGURIDAD_BLOQUEO_MINUTOS", 15));
            usuarioRepository.save(usuario);
            auditoriaService.registrar(usuario.getId(), null, "CAMBIO_CLAVE_FALLIDO", ip, agente, null);
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La contraseña actual no es correcta");
        }
        politica.validar(passwordNueva);
        if (passwordEncoder.matches(passwordNueva, usuario.getPasswordHash())) {
            throw badRequest("La nueva contraseña debe ser distinta de la actual");
        }
        usuario.cambiarPassword(passwordEncoder.encode(passwordNueva));
        usuarioRepository.save(usuario);
        auditoriaService.registrar(usuario.getId(), null, "CAMBIO_CLAVE", ip, agente, null);
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
