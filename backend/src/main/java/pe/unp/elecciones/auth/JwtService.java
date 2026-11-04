package pe.unp.elecciones.auth;

import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Date;

import javax.crypto.SecretKey;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;

@Service
public class JwtService {
    private static final org.slf4j.Logger LOG = org.slf4j.LoggerFactory.getLogger(JwtService.class);
    private static final java.util.Set<String> SECRETOS_PUBLICADOS =
            java.util.Set.of("change-this-development-secret-with-at-least-32-bytes");

    private static final String EMITIDO_MS = "iat_ms";

    private final SecretKey signingKey;
    private final Duration expiration;

    @org.springframework.beans.factory.annotation.Autowired
    public JwtService(
            @Value("${app.security.jwt-secret:}") String secret,
            @Value("${app.security.jwt-expiration:PT2H}") Duration expiration,
            @Value("${app.security.jwt-secret-obligatorio:false}") boolean secretoObligatorio) {
        // A4: nunca un valor fijo en el código o en el repositorio. Si falta JWT_SECRET, en desarrollo se
        // genera uno aleatorio al arrancar (las sesiones caducan al reiniciar el backend); en el perfil
        // prod es obligatorio y el backend no arranca sin él.
        if (secret == null || secret.isBlank()) {
            if (secretoObligatorio) {
                throw new IllegalStateException("Defina la variable de entorno JWT_SECRET (al menos 32 bytes aleatorios).");
            }
            byte[] azar = new byte[48];
            new java.security.SecureRandom().nextBytes(azar);
            secret = java.util.HexFormat.of().formatHex(azar);
            LOG.warn("JWT_SECRET no está definido: se generó una clave aleatoria para esta ejecución. "
                    + "Las sesiones se cierran al reiniciar el backend. En producción defina JWT_SECRET.");
        }
        if (SECRETOS_PUBLICADOS.contains(secret)) {
            throw new IllegalStateException("JWT_SECRET usa un valor publicado en el repositorio; genere uno nuevo.");
        }
        if (secret.getBytes(StandardCharsets.UTF_8).length < 32) {
            throw new IllegalStateException("JWT_SECRET debe tener al menos 32 bytes.");
        }
        this.signingKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.expiration = expiration;
    }

    JwtService(String secret, Duration expiration) {
        this(secret, expiration, true);
    }

    public String generateToken(Usuario usuario) {
        Date issuedAt = new Date();
        Date expiresAt = new Date(issuedAt.getTime() + expiration.toMillis());
        return Jwts.builder()
                .subject(usuario.getUsername())
                .claim("role", usuario.getRol().name())
                .issuedAt(issuedAt)
                .claim(EMITIDO_MS, issuedAt.getTime())   // iat solo guarda segundos; la revocación necesita milisegundos
                .expiration(expiresAt)
                .signWith(signingKey)
                .compact();
    }

    public String extractUsername(String token) {
        return parseClaims(token).getSubject();
    }

    /**
     * A4: el token vale si la firma y la expiración son correctas, la cuenta está activa y fue emitido
     * después del último cambio de clave o desactivación (usuario.token_valido_desde).
     */
    public boolean isValid(String token, Usuario usuario) {
        Claims claims = parseClaims(token);
        if (!claims.getSubject().equals(usuario.getUsername()) || !claims.getExpiration().after(new Date())
                || !usuario.isActivo()) {
            return false;
        }
        java.time.LocalDateTime desde = usuario.getTokenValidoDesde();
        if (desde == null) {
            return true;
        }
        long revocadoEn = desde.atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli();
        Long emitido = claims.get(EMITIDO_MS, Long.class);
        if (emitido == null) {
            // token sin milisegundos: se exige un segundo completo posterior a la revocación
            return claims.getIssuedAt() != null && claims.getIssuedAt().getTime() >= revocadoEn - (revocadoEn % 1000) + 1000;
        }
        return emitido > revocadoEn;
    }

    public Duration expiracion() {
        return expiration;
    }

    private Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith(signingKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
