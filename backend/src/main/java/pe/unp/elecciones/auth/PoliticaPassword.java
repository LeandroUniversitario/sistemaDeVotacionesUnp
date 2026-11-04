package pe.unp.elecciones.auth;

import java.security.SecureRandom;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.repository.ParametroGlobalRepository;

/**
 * Política única de contraseñas (auditoría B2). La aplican el cambio de clave propio, el CUS18
 * (cuentas creadas o restablecidas por el ADMIN) y la importación de docentes:
 * longitud mínima del parámetro SEGURIDAD_PASSWORD_MIN, letras y números, sin espacios al inicio
 * ni al final. Las claves provisionales se generan con SecureRandom (auditoría A3: nunca el DNI).
 */
@Component
public class PoliticaPassword {

    private static final String ALFABETO = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789";
    private static final SecureRandom AZAR = new SecureRandom();

    private final ParametroGlobalRepository parametros;

    public PoliticaPassword(ParametroGlobalRepository parametros) {
        this.parametros = parametros;
    }

    public int minimo() {
        return parametros.findById("SEGURIDAD_PASSWORD_MIN").map(p -> {
            try {
                return Math.max(8, (int) Math.round(Double.parseDouble(p.getValor().trim())));
            } catch (NumberFormatException e) {
                return 8;
            }
        }).orElse(8);
    }

    /** Lanza 400 con el motivo si la clave no cumple la política; si cumple, la devuelve. */
    public String validar(String clave) {
        int minimo = minimo();
        if (clave == null || clave.length() < minimo) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "La contraseña debe tener al menos " + minimo + " caracteres.");
        }
        if (!clave.equals(clave.trim())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La contraseña no puede empezar ni terminar con espacios.");
        }
        if (!clave.matches(".*\\p{L}.*") || !clave.matches(".*[0-9].*")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La contraseña debe combinar letras y números.");
        }
        return clave;
    }

    /** Clave provisional aleatoria: al menos 10 caracteres sin letras que se confundan, con mayúscula, minúscula y número. */
    public String generarProvisional() {
        int largo = Math.max(10, minimo());
        while (true) {
            StringBuilder sb = new StringBuilder(largo);
            for (int i = 0; i < largo; i++) {
                sb.append(ALFABETO.charAt(AZAR.nextInt(ALFABETO.length())));
            }
            String clave = sb.toString();
            if (clave.matches(".*[A-Z].*") && clave.matches(".*[a-z].*") && clave.matches(".*[0-9].*")) {
                return clave;
            }
        }
    }
}
