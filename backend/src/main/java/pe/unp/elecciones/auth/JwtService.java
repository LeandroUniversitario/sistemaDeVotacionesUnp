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
    private static final java.util.Set<String> SECRETOS_PUBLICADOS =
            java.util.Set.of("change-this-development-secret-with-at-least-32-bytes");

    private static final String EMITIDO_MS = "iat_ms";

    private final SecretKey signingKey;
    private final Duration expiration;

    public JwtService(
            @Value("${app.security.jwt-secret:}") String secret,
            @Value("${app.security.jwt-expiration:PT2H}") Duration expiration) {
        // A4: sin valor por defecto. Si falta JWT_SECRET (o es el valor de ejemplo que estuvo en el
        // repositorio), el backend no arranca: cualquiera que leyera el repo podría firmar un token de ADMIN.
        if (secret == null || secret.isBlank()) {
            throw new IllegalStateException("Defina la variable de entorno JWT_SECRET (al menos 32 bytes aleatorios).");
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
