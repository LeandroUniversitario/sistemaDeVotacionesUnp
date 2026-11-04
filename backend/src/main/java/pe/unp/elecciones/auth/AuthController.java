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
import java.util.Map;
import java.util.LinkedHashMap;
import pe.unp.elecciones.electoral.domain.Docente;
import pe.unp.elecciones.electoral.domain.Facultad;
import pe.unp.elecciones.electoral.domain.Departamento;
import pe.unp.elecciones.electoral.repository.DocenteRepository;
import pe.unp.elecciones.electoral.repository.FacultadRepository;
import pe.unp.elecciones.electoral.repository.DepartamentoRepository;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthenticationManager authenticationManager;
    private final UsuarioRepository usuarioRepository;
    private final JwtService jwtService;
    private final UsuarioService usuarioService;
    private final AuditoriaService auditoriaService;
    private final DocenteRepository docenteRepository;
    private final FacultadRepository facultadRepository;
    private final DepartamentoRepository departamentoRepository;

    public AuthController(
            AuthenticationManager authenticationManager,
            UsuarioRepository usuarioRepository,
            JwtService jwtService,
            UsuarioService usuarioService,
            AuditoriaService auditoriaService,
            DocenteRepository docenteRepository,
            FacultadRepository facultadRepository,
            DepartamentoRepository departamentoRepository) {
        this.authenticationManager = authenticationManager;
        this.usuarioRepository = usuarioRepository;
        this.jwtService = jwtService;
        this.usuarioService = usuarioService;
        this.auditoriaService = auditoriaService;
        this.docenteRepository = docenteRepository;
        this.facultadRepository = facultadRepository;
        this.departamentoRepository = departamentoRepository;
    }

    @PostMapping("/login")
    public LoginResponse login(@Valid @RequestBody LoginRequest request, HttpServletRequest requestHttp) {
        Usuario usuario = usuarioRepository.findByUsername(request.username()).orElse(null);

        // B1: un solo mensaje para cuenta inexistente, inactiva, bloqueada o clave incorrecta, para no
        // revelar qué cuentas existen. El motivo real queda en la bitácora.
        if (usuario != null && (!usuario.isActivo()
                || (usuario.getBloqueadoHasta() != null && usuario.getBloqueadoHasta().isAfter(LocalDateTime.now())))) {
            auditoriaService.registrar(usuario.getId(), null, usuario.isActivo() ? "LOGIN_BLOQUEADO" : "LOGIN_INACTIVO",
                    requestHttp.getRemoteAddr(), requestHttp.getHeader("User-Agent"), null);
            throw credencialesInvalidas();
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
            throw credencialesInvalidas();
        }
    }

    private static ResponseStatusException credencialesInvalidas() {
        return new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                "No se pudo iniciar sesión. Verifique su usuario y contraseña; si el problema continúa, "
                        + "su cuenta puede estar bloqueada temporalmente o inactiva: contacte al CEUNP.");
    }

    /**
     * A4: renovación de la sesión. Con un token vigente (el filtro ya comprobó firma, expiración,
     * cuenta activa y revocación) se emite uno nuevo, para que las sesiones de la jornada (8:00 a
     * 15:00, RN06) no se corten a las 2 horas.
     */
    @PostMapping("/renovar")
    public LoginResponse renovar(Authentication authentication) {
        Usuario usuario = usuarioRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Usuario no disponible"));
        return new LoginResponse(jwtService.generateToken(usuario), usuario.getUsername(), usuario.getRol().name(),
                usuario.isDebeCambiarPassword());
    }

    @GetMapping("/me")
    public Map<String, Object> me(Authentication authentication) {
        Usuario usuario = usuarioRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Usuario no disponible"));
        
        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("id", usuario.getId());
        resp.put("username", usuario.getUsername());
        resp.put("rol", usuario.getRol().name());
        resp.put("idDocente", usuario.getIdDocente());
        resp.put("debeCambiarPassword", usuario.isDebeCambiarPassword());
        resp.put("activo", usuario.isActivo());
        boolean bloqueada = usuario.getBloqueadoHasta() != null && usuario.getBloqueadoHasta().isAfter(java.time.LocalDateTime.now());
        resp.put("bloqueada", bloqueada);
        resp.put("ultimoAcceso", usuario.getUltimoAcceso());

        if (usuario.getIdDocente() != null) {
            docenteRepository.findById(usuario.getIdDocente()).ifPresent(d -> {
                resp.put("dni", d.getDni());
                resp.put("nombres", d.getNombres());
                resp.put("apellidos", d.getApellidos());
                resp.put("nombreCompleto", d.getNombres() + " " + d.getApellidos());
                resp.put("categoria", d.getCategoria() != null ? d.getCategoria().name() : null);
                resp.put("dedicacion", d.getDedicacion());
                resp.put("estadoDocente", d.getEstado() != null ? d.getEstado().name() : null);
                resp.put("gradoAcademico", d.getGradoAcademico());
                resp.put("email", d.getEmail());
                resp.put("fechaIngreso", d.getFechaIngreso());
                resp.put("fechaCategoria", d.getFechaCategoria());
                resp.put("habilitadoParaVotar", d.isHabilitadoParaVotar());

                if (d.getIdFacultad() != null) {
                    facultadRepository.findById(d.getIdFacultad())
                            .ifPresent(f -> resp.put("facultad", f.getNombre()));
                }
                if (d.getIdDepartamento() != null) {
                    departamentoRepository.findById(d.getIdDepartamento())
                            .ifPresent(dep -> resp.put("departamento", dep.getNombre()));
                }
            });
        }

        return resp;
    }

    /**
     * Cambio de la clave propia. Revoca todos los tokens anteriores (trg_usuario_revocar_bu) y devuelve
     * uno nuevo para que esta sesión continúe.
     */
    @PatchMapping("/password")
    public LoginResponse changePassword(
            @Valid @RequestBody ChangePasswordRequest request,
            Authentication authentication,
            HttpServletRequest requestHttp) {
        usuarioService.cambiarPassword(authentication.getName(), request.passwordActual(), request.passwordNueva(),
                requestHttp.getRemoteAddr(), requestHttp.getHeader("User-Agent"));
        Usuario usuario = usuarioRepository.findByUsername(authentication.getName()).orElseThrow();
        return new LoginResponse(jwtService.generateToken(usuario), usuario.getUsername(), usuario.getRol().name(),
                usuario.isDebeCambiarPassword());
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