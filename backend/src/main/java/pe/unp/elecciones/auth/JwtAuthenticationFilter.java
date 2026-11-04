package pe.unp.elecciones.auth;

import java.io.IOException;
import java.util.List;
import java.util.Set;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import io.jsonwebtoken.JwtException;

/**
 * Autenticación por JWT.
 *
 * <ul>
 *   <li>A4: además de firma y expiración, exige cuenta activa y que el token sea posterior al último
 *       cambio de clave o desactivación (JwtService.isValid). Un token revocado responde 401.</li>
 *   <li>A3: mientras la cuenta tenga debe_cambiar_password, el backend solo atiende el cambio de
 *       clave, /me y la renovación; el resto responde 403 (antes solo lo exigía el frontend).</li>
 * </ul>
 */
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    /** Rutas permitidas a una cuenta que aún debe cambiar su contraseña. */
    private static final Set<String> PERMITIDAS_CAMBIO_CLAVE = Set.of("/api/auth/password", "/api/auth/me");

    private final JwtService jwtService;
    private final UsuarioRepository usuarioRepository;

    public JwtAuthenticationFilter(JwtService jwtService, UsuarioRepository usuarioRepository) {
        this.jwtService = jwtService;
        this.usuarioRepository = usuarioRepository;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String authorization = request.getHeader("Authorization");
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        String token = authorization.substring(7);
        Usuario usuario;
        try {
            String username = jwtService.extractUsername(token);
            usuario = usuarioRepository.findByUsername(username).orElse(null);
            if (usuario == null || !jwtService.isValid(token, usuario)) {
                response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Sesión vencida o revocada. Inicie sesión de nuevo.");
                return;
            }
        } catch (JwtException | IllegalArgumentException exception) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Token inválido o expirado");
            return;
        }

        if (usuario.isDebeCambiarPassword() && !PERMITIDAS_CAMBIO_CLAVE.contains(request.getRequestURI())) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "Debe cambiar su contraseña provisional antes de usar el sistema.");
            return;
        }

        if (SecurityContextHolder.getContext().getAuthentication() == null) {
            UserDetails userDetails = User.withUsername(usuario.getUsername())
                    .password(usuario.getPasswordHash())
                    .authorities(List.of(new SimpleGrantedAuthority("ROLE_" + usuario.getRol().name())))
                    .build();
            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
            authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
            SecurityContextHolder.getContext().setAuthentication(authentication);
        }
        filterChain.doFilter(request, response);
    }
}
