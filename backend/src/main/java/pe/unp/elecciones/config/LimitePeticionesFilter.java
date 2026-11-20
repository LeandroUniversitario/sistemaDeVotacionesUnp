package pe.unp.elecciones.config;

import java.io.IOException;
import java.time.Clock;
import java.time.Duration;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Límite de peticiones por IP (auditoría M8 y A3).
 *
 * <ul>
 *   <li>Login: como mucho {@code app.limites.login-por-ip} intentos FALLIDOS por IP cada 15 minutos.
 *       El bloqueo por cuenta no frena a quien prueba una clave en muchas cuentas; este sí.</li>
 *   <li>Portal público (/api/publico/**): como mucho {@code app.limites.publico-por-ip} consultas por
 *       IP por minuto, porque no exige sesión.</li>
 *   <li>Cabina (/api/cabina/terminales/{id}/**): 300 peticiones por minuto por terminal y 3000 por IP.
 *       Antes eran 600 por IP para todas las cabinas: si un local salía a Internet con una sola IP (NAT),
 *       las cabinas se frenaban entre sí en medio de un voto (hallazgo C09-2 del recorrido del
 *       20/11/2026). El límite por terminal sigue cortando a quien pruebe secretos.</li>
 * </ul>
 *
 * Se guarda en memoria (una instancia del backend). Detrás de un proxy, el perfil prod respeta
 * X-Forwarded-For para que la IP sea la del cliente.
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 10)
public class LimitePeticionesFilter extends OncePerRequestFilter {

    private static final Duration VENTANA_LOGIN = Duration.ofMinutes(15);
    private static final Duration VENTANA_MINUTO = Duration.ofMinutes(1);
    private static final int MAX_CABINA_TERMINAL = 300;
    private static final int MAX_CABINA_IP = 3000;

    private final int maxLogin;
    private final int maxPublico;
    private final Clock reloj;
    private final Map<String, Deque<Long>> eventos = new ConcurrentHashMap<>();

    @Autowired
    public LimitePeticionesFilter(@Value("${app.limites.login-por-ip:20}") int maxLogin,
            @Value("${app.limites.publico-por-ip:120}") int maxPublico) {
        this(maxLogin, maxPublico, Clock.systemUTC());
    }

    LimitePeticionesFilter(int maxLogin, int maxPublico, Clock reloj) {
        this.maxLogin = maxLogin;
        this.maxPublico = maxPublico;
        this.reloj = reloj;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String ruta = request.getRequestURI();
        String ip = request.getRemoteAddr();

        if ("/api/auth/login".equals(ruta) && "POST".equalsIgnoreCase(request.getMethod())) {
            String clave = "login|" + ip;
            if (superado(clave, maxLogin, VENTANA_LOGIN)) {
                rechazar(response, "Demasiados intentos de inicio de sesión desde este equipo. Espere 15 minutos.");
                return;
            }
            chain.doFilter(request, response);
            if (response.getStatus() == HttpStatus.UNAUTHORIZED.value()) {
                registrar(clave);
            }
            return;
        }
        if (ruta.startsWith("/api/publico/")) {
            String clave = "publico|" + ip;
            if (superado(clave, maxPublico, VENTANA_MINUTO)) {
                rechazar(response, "Demasiadas consultas seguidas. Espere un minuto e intente de nuevo.");
                return;
            }
            registrar(clave);
        } else if (ruta.startsWith("/api/cabina/")) {
            String claveIp = "cabina|" + ip;
            String claveTerminal = "cabina-terminal|" + ip + "|" + terminalDe(ruta);
            if (superado(claveTerminal, MAX_CABINA_TERMINAL, VENTANA_MINUTO)
                    || superado(claveIp, MAX_CABINA_IP, VENTANA_MINUTO)) {
                rechazar(response, "Demasiadas peticiones del terminal. Espere un minuto.");
                return;
            }
            registrar(claveTerminal);
            registrar(claveIp);
        }
        chain.doFilter(request, response);
    }

    /** Id del terminal en /api/cabina/terminales/{id}/...; "?" si la ruta no lo trae. */
    static String terminalDe(String ruta) {
        String[] partes = ruta.split("/");
        // ["", "api", "cabina", "terminales", "{id}", ...]
        return partes.length > 4 && partes[4].matches("\\d{1,9}") ? partes[4] : "?";
    }

    /** true si la clave ya alcanzó el máximo dentro de la ventana (descarta los eventos vencidos). */
    boolean superado(String clave, int maximo, Duration ventana) {
        long limite = reloj.millis() - ventana.toMillis();
        Deque<Long> cola = eventos.get(clave);
        if (cola == null) {
            return false;
        }
        synchronized (cola) {
            while (!cola.isEmpty() && cola.peekFirst() < limite) {
                cola.pollFirst();
            }
            return cola.size() >= maximo;
        }
    }

    void registrar(String clave) {
        Deque<Long> cola = eventos.computeIfAbsent(clave, k -> new ArrayDeque<>());
        synchronized (cola) {
            cola.addLast(reloj.millis());
        }
        if (eventos.size() > 50_000) {
            eventos.clear();   // protección de memoria ante un barrido de IPs
        }
    }

    private static void rechazar(HttpServletResponse response, String mensaje) throws IOException {
        response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
        response.setHeader("Retry-After", "60");
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write("{\"status\":429,\"detail\":\"" + mensaje + "\"}");
    }
}
