package pe.unp.elecciones.auth;

import static org.junit.jupiter.api.Assertions.*;

import java.time.Duration;
import java.time.LocalDateTime;

import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

/** Auditoría A4: secreto obligatorio y revocación de tokens. */
class JwtServiceTest {

    private static final String SECRETO = "0123456789abcdef0123456789abcdef-prueba";

    private static Usuario usuario() {
        return new Usuario("jsuarez", "hash", Rol.DOCENTE, 1);
    }

    @Test
    void noArrancaSinSecretoNiConElSecretoPublicado() {
        assertThrows(IllegalStateException.class, () -> new JwtService("", Duration.ofHours(2)));
        assertThrows(IllegalStateException.class, () -> new JwtService("corto", Duration.ofHours(2)));
        assertThrows(IllegalStateException.class,
                () -> new JwtService("change-this-development-secret-with-at-least-32-bytes", Duration.ofHours(2)));
    }

    @Test
    void enDesarrolloSinSecretoGeneraUnoAleatorio() {
        JwtService a = new JwtService("", Duration.ofHours(2), false);
        JwtService b = new JwtService(null, Duration.ofHours(2), false);
        Usuario u = usuario();
        assertTrue(a.isValid(a.generateToken(u), u));
        // cada arranque tiene su propia clave: un token de una ejecución no sirve en otra
        assertThrows(io.jsonwebtoken.security.SignatureException.class, () -> b.extractUsername(a.generateToken(u)));
    }

    @Test
    void tokenValidoParaSuUsuario() {
        JwtService jwt = new JwtService(SECRETO, Duration.ofHours(2));
        Usuario u = usuario();
        String token = jwt.generateToken(u);
        assertEquals("jsuarez", jwt.extractUsername(token));
        assertTrue(jwt.isValid(token, u));
    }

    @Test
    void tokenFirmadoConOtraClaveSeRechaza() {
        JwtService atacante = new JwtService("otro-secreto-de-al-menos-32-bytes-xxxxxx", Duration.ofHours(2));
        JwtService servidor = new JwtService(SECRETO, Duration.ofHours(2));
        String falso = atacante.generateToken(usuario());
        assertThrows(io.jsonwebtoken.security.SignatureException.class, () -> servidor.extractUsername(falso));
    }

    @Test
    void tokenEmitidoAntesDeLaRevocacionDejaDeValer() {
        JwtService jwt = new JwtService(SECRETO, Duration.ofHours(2));
        Usuario u = usuario();
        String token = jwt.generateToken(u);
        ReflectionTestUtils.setField(u, "tokenValidoDesde", LocalDateTime.now().plusSeconds(5));
        assertFalse(jwt.isValid(token, u));
    }

    @Test
    void revocacionEnElMismoSegundoTambienCuenta() throws InterruptedException {
        JwtService jwt = new JwtService(SECRETO, Duration.ofHours(2));
        Usuario u = usuario();
        String anterior = jwt.generateToken(u);
        Thread.sleep(2);
        ReflectionTestUtils.setField(u, "tokenValidoDesde", LocalDateTime.now());
        Thread.sleep(2);
        String nuevo = jwt.generateToken(u);
        assertFalse(jwt.isValid(anterior, u), "el token emitido milisegundos antes de revocar no debe valer");
        assertTrue(jwt.isValid(nuevo, u), "el token emitido después de revocar sí vale");
    }

    @Test
    void cuentaDesactivadaInvalidaElToken() {
        JwtService jwt = new JwtService(SECRETO, Duration.ofHours(2));
        Usuario u = usuario();
        String token = jwt.generateToken(u);
        ReflectionTestUtils.setField(u, "activo", false);
        assertFalse(jwt.isValid(token, u));
    }
}
