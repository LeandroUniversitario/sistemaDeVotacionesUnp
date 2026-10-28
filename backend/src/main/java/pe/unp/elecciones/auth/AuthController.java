package pe.unp.elecciones.auth;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;

import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.security.access.prepost.PreAuthorize;
import pe.unp.elecciones.electoral.service.AuditoriaService;
import jakarta.servlet.http.HttpServletRequest;
import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthenticationManager authenticationManager;
    private final UsuarioRepository usuarioRepository;
    private final JwtService jwtService;
    private final UsuarioService usuarioService;
    private final AuditoriaService auditoriaService;

    public AuthController(
            AuthenticationManager authenticationManager,
            UsuarioRepository usuarioRepository,
            JwtService jwtService,
            UsuarioService usuarioService,
            AuditoriaService auditoriaService) {
        this.authenticationManager = authenticationManager;
        this.usuarioRepository = usuarioRepository;
        this.jwtService = jwtService;
        this.usuarioService = usuarioService;
        this.auditoriaService = auditoriaService;
    }

    @PostMapping("/login")
    public LoginResponse login(@Valid @RequestBody LoginRequest request, HttpServletRequest requestHttp) {
        Usuario usuario = usuarioRepository.findByUsername(request.username()).orElse(null);

        if (usuario != null) {
            if (!usuario.isActivo()) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                        "Acceso denegado. Su cuenta se encuentra inactiva. Contacte con el Administrador o CEUNP");
            }
            if (usuario.getBloqueadoHasta() != null && usuario.getBloqueadoHasta().isAfter(LocalDateTime.now())) {
                throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                        "Cuenta bloqueada temporalmente por demasiados intentos fallidos. Intente nuevamente en "
                                + usuarioService.parametroEntero("SEGURIDAD_BLOQUEO_MINUTOS", 15) + " minutos");
            }
        }

        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.username(), request.password()));

            if (usuario == null) {
                usuario = usuarioRepository.findByUsername(authentication.getName()).orElseThrow();
            }

            usuario.registrarAccesoExitoso();
            usuarioRepository.save(usuario);
            auditoriaService.registrar(usuario.getId(), null, "LOGIN_SUCCESS",
                    requestHttp.getRemoteAddr(), requestHttp.getHeader("User-Agent"), null);

            return new LoginResponse(
                    jwtService.generateToken(usuario),
                    usuario.getUsername(),
                    usuario.getRol().name(),
                    usuario.isDebeCambiarPassword());

        } catch (BadCredentialsException exception) {
            if (usuario != null) {
                // CUS18: intentos y minutos de bloqueo parametrizados
                usuario.registrarIntentoFallido(usuarioService.parametroEntero("SEGURIDAD_INTENTOS_MAXIMOS", 5),
                        usuarioService.parametroEntero("SEGURIDAD_BLOQUEO_MINUTOS", 15));
                usuarioRepository.save(usuario);
                auditoriaService.registrar(usuario.getId(), null, "LOGIN_FAILED",
                        requestHttp.getRemoteAddr(), requestHttp.getHeader("User-Agent"), null);
            }
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                    "Credenciales incorrectas. Por favor, verifique su usuario y contrasena");
        }
    }

    @GetMapping("/me")
    public MeResponse me(Authentication authentication) {
        Usuario usuario = usuarioRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Usuario no disponible"));
        return new MeResponse(usuario.getId(), usuario.getUsername(), usuario.getRol().name(),
                usuario.getIdDocente(), usuario.isDebeCambiarPassword());
    }

    @PatchMapping("/password")
    public void changePassword(
            @Valid @RequestBody ChangePasswordRequest request,
            Authentication authentication) {
        usuarioService.cambiarPassword(authentication.getName(), request.passwordActual(), request.passwordNueva());
    }

    /**
     * Listado de cuentas (lo usa el resumen del ADMIN). La administración de las cuentas
     * está en el CUS18: /api/administracion/usuarios (AdministracionController).
     */
    @GetMapping("/users")
    @PreAuthorize("hasRole('ADMIN')")
    public List<UserResponse> users() {
        return usuarioService.listar().stream().map(AuthController::toResponse).toList();
    }

    private static UserResponse toResponse(Usuario u) {
        return new UserResponse(u.getId(), u.getUsername(), u.getRol().name(),
                u.getIdDocente(), u.isActivo(), u.isDebeCambiarPassword());
    }

    public record LoginRequest(
            @NotBlank(message = "El usuario es obligatorio") String username,
            @NotBlank(message = "La contrasena es obligatoria") String password) {}

    /** debeCambiarPassword=true: docente importado, debe elegir su clave antes de entrar al dashboard. */
    public record LoginResponse(String token, String username, String rol, boolean debeCambiarPassword) {}

    public record MeResponse(Integer id, String username, String rol, Integer idDocente, boolean debeCambiarPassword) {}

    public record ChangePasswordRequest(
            @NotBlank String passwordActual,
            @NotBlank String passwordNueva) {}

    public record UserResponse(Integer id, String username, String rol,
                               Integer idDocente, boolean activo, boolean debeCambiarPassword) {}
}