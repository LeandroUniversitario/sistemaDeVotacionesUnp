package pe.unp.elecciones.auth;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;

import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.security.access.prepost.PreAuthorize;
import java.util.List;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private final AuthenticationManager authenticationManager;
    private final UsuarioRepository usuarioRepository;
    private final JwtService jwtService;
    private final UsuarioService usuarioService;

    public AuthController(
            AuthenticationManager authenticationManager,
            UsuarioRepository usuarioRepository,
            JwtService jwtService,
            UsuarioService usuarioService) {
        this.authenticationManager = authenticationManager;
        this.usuarioRepository = usuarioRepository;
        this.jwtService = jwtService;
        this.usuarioService = usuarioService;
    }

    @PostMapping("/login")
    public LoginResponse login(@Valid @RequestBody LoginRequest request) {
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.username(), request.password()));
            Usuario usuario = usuarioRepository.findByUsername(authentication.getName())
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.UNAUTHORIZED, "Usuario o contraseña inválidos"));
            return new LoginResponse(
                    jwtService.generateToken(usuario),
                    usuario.getUsername(),
                    usuario.getRol().name());
        } catch (BadCredentialsException exception) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED, "Usuario o contraseña inválidos");
        }
    }

    @GetMapping("/me")
    public MeResponse me(Authentication authentication) {
        Usuario usuario = usuarioRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED, "Usuario no disponible"));
        return new MeResponse(usuario.getId(), usuario.getUsername(), usuario.getRol().name());
    }

    @PatchMapping("/password")
    public void changePassword(
            @Valid @RequestBody ChangePasswordRequest request,
            Authentication authentication) {
        usuarioService.cambiarPassword(
                authentication.getName(), request.passwordActual(), request.passwordNueva());
    }

    @GetMapping("/users")
    @PreAuthorize("hasRole('ADMIN')")
    public List<UserResponse> users() {
        return usuarioService.listar().stream().map(AuthController::toResponse).toList();
    }

    @PostMapping("/users")
    @PreAuthorize("hasRole('ADMIN')")
    public UserResponse createUser(@Valid @RequestBody CreateUserRequest request) {
        return toResponse(usuarioService.crear(new UsuarioService.CrearUsuarioRequest(
                request.username(), request.password(), request.rol(), request.idDocente())));
    }

    @PatchMapping("/users/{id}/status")
    @PreAuthorize("hasRole('ADMIN')")
    public UserResponse updateStatus(
            @PathVariable Integer id,
            @Valid @RequestBody StatusRequest request) {
        return toResponse(usuarioService.cambiarEstado(id, request.activo()));
    }

    /** Editar rol de un usuario (ADMIN no puede cambiar su propio rol) */
    @PatchMapping("/users/{id}/rol")
    @PreAuthorize("hasRole('ADMIN')")
    public UserResponse updateRol(
            @PathVariable Integer id,
            @Valid @RequestBody RolRequest request,
            Authentication authentication) {
        return toResponse(usuarioService.cambiarRol(id, request.rol(), authentication.getName()));
    }

    /** Restablecer contraseña de un usuario (por el ADMIN, sin validar la anterior) */
    @PatchMapping("/users/{id}/password")
    @PreAuthorize("hasRole('ADMIN')")
    public void resetPassword(
            @PathVariable Integer id,
            @Valid @RequestBody ResetPasswordRequest request) {
        usuarioService.restablecerPassword(id, request.password());
    }

    @DeleteMapping("/users/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public void deleteUser(@PathVariable Integer id, Authentication authentication) {
        usuarioService.eliminar(id, authentication.getName());
    }

    private static UserResponse toResponse(Usuario usuario) {
        return new UserResponse(usuario.getId(), usuario.getUsername(), usuario.getRol().name(),
                usuario.getIdDocente(), usuario.isActivo());
    }

    public record LoginRequest(
            @NotBlank(message = "El usuario es obligatorio") String username,
            @NotBlank(message = "La contraseña es obligatoria") String password) {
    }

    public record LoginResponse(String token, String username, String rol) {
    }

    public record MeResponse(Integer id, String username, String rol) {
    }

    public record CreateUserRequest(
            @NotBlank String username,
            @NotBlank String password,
            @jakarta.validation.constraints.NotNull Rol rol,
            Integer idDocente) {
    }

    public record StatusRequest(boolean activo) {
    }

    public record RolRequest(@jakarta.validation.constraints.NotNull Rol rol) {
    }

    public record ResetPasswordRequest(@NotBlank String password) {
    }

    public record ChangePasswordRequest(
            @NotBlank String passwordActual,
            @NotBlank String passwordNueva) {
    }

    public record UserResponse(Integer id, String username, String rol, Integer idDocente, boolean activo) {
    }
}
