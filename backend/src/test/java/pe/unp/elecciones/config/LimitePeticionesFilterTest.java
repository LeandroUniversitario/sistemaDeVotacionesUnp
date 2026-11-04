package pe.unp.elecciones.config;

import static org.junit.jupiter.api.Assertions.*;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import jakarta.servlet.http.HttpServletResponse;

/** Auditoría M8: límites por IP en login, portal público y cabina. */
class LimitePeticionesFilterTest {

    /** Reloj que se adelanta a mano. */
    static class RelojManual extends Clock {
        long ms = 1_000_000L;
        @Override public ZoneId getZone() { return ZoneOffset.UTC; }
        @Override public Clock withZone(ZoneId zone) { return this; }
        @Override public Instant instant() { return Instant.ofEpochMilli(ms); }
    }

    private static int login(LimitePeticionesFilter f, String ip, int estadoDelControlador) throws Exception {
        MockHttpServletRequest req = new MockHttpServletRequest("POST", "/api/auth/login");
        req.setRemoteAddr(ip);
        MockHttpServletResponse res = new MockHttpServletResponse();
        f.doFilter(req, res, new MockFilterChain() {
            @Override public void doFilter(jakarta.servlet.ServletRequest a, jakarta.servlet.ServletResponse b) {
                ((HttpServletResponse) b).setStatus(estadoDelControlador);
            }
        });
        return res.getStatus();
    }

    private static int publico(LimitePeticionesFilter f, String ip) throws Exception {
        MockHttpServletRequest req = new MockHttpServletRequest("GET", "/api/publico/procesos");
        req.setRemoteAddr(ip);
        MockHttpServletResponse res = new MockHttpServletResponse();
        f.doFilter(req, res, new MockFilterChain());
        return res.getStatus();
    }

    @Test
    void bloqueaLoginTrasNFallosYSoloParaEsaIp() throws Exception {
        RelojManual reloj = new RelojManual();
        LimitePeticionesFilter f = new LimitePeticionesFilter(3, 100, reloj);
        for (int i = 0; i < 3; i++) {
            assertEquals(401, login(f, "10.0.0.1", 401));
        }
        assertEquals(429, login(f, "10.0.0.1", 200));
        assertEquals(200, login(f, "10.0.0.2", 200));   // otra IP no se ve afectada
        reloj.ms += 15 * 60_000L + 1;                   // vence la ventana
        assertEquals(200, login(f, "10.0.0.1", 200));
    }

    @Test
    void losLoginsCorrectosNoCuentan() throws Exception {
        LimitePeticionesFilter f = new LimitePeticionesFilter(2, 100, new RelojManual());
        for (int i = 0; i < 10; i++) {
            assertEquals(200, login(f, "10.0.0.3", 200));
        }
    }

    @Test
    void limitaElPortalPublicoPorMinuto() throws Exception {
        RelojManual reloj = new RelojManual();
        LimitePeticionesFilter f = new LimitePeticionesFilter(20, 5, reloj);
        for (int i = 0; i < 5; i++) {
            assertEquals(200, publico(f, "10.0.0.4"));
        }
        assertEquals(429, publico(f, "10.0.0.4"));
        reloj.ms += 60_001;
        assertEquals(200, publico(f, "10.0.0.4"));
    }
}
