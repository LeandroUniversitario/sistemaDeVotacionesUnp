package pe.unp.elecciones.electoral.credenciales;

import java.util.Locale;

import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

/**
 * CUS07 · Tipos de credencial QR.
 *
 * <p>La letra es la que viaja en el código QR ({@code SICEUNP|E|<token>}); se usa una
 * sola letra para que el contenido sea corto y lo lean bien las pistolas lectoras.
 */
public enum TipoCredencial {

    /** Pase de votación del docente habilitado en el padrón (RF62). */
    ELECTOR('E', "Pase de votación"),
    /** Fotocheck digital del miembro de mesa sorteado (RF56). */
    MIEMBRO_MESA('M', "Fotocheck de miembro de mesa"),
    /** Credencial del personero acreditado (RF51). */
    PERSONERO('P', "Credencial de personero");

    private final char letra;
    private final String titulo;

    TipoCredencial(char letra, String titulo) {
        this.letra = letra;
        this.titulo = titulo;
    }

    public char letra() {
        return letra;
    }

    public String titulo() {
        return titulo;
    }

    public static TipoCredencial desdeTexto(String texto) {
        if (texto != null) {
            String valor = texto.trim().toUpperCase(Locale.ROOT);
            for (TipoCredencial tipo : values()) {
                if (tipo.name().equals(valor)) {
                    return tipo;
                }
            }
        }
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                "Tipo de credencial inválido: use ELECTOR, MIEMBRO_MESA o PERSONERO.");
    }

    /** Tipo a partir de la letra leída del QR (sin distinguir mayúsculas); null si no corresponde. */
    public static TipoCredencial desdeLetra(char letra) {
        char valor = Character.toUpperCase(letra);
        for (TipoCredencial tipo : values()) {
            if (tipo.letra == valor) {
                return tipo;
            }
        }
        return null;
    }
}
