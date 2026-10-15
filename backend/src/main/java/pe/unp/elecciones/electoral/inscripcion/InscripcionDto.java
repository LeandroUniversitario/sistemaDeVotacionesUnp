package pe.unp.elecciones.electoral.inscripcion;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/** CUS03 · Datos que envía la PantallaInscripcion. */
public final class InscripcionDto {

    private InscripcionDto() {
    }

    private static final String URL = "^$|^https?://.+";

    /** 1/2: ingresarDatosLista(nombre, cargo) → guardarLista(datos). */
    public record DatosLista(
            @NotNull(message = "Seleccione el cargo al que postula la lista.")
            Integer idCargo,
            @NotBlank(message = "El nombre de la lista es obligatorio.")
            @Size(max = 150, message = "El nombre de la lista no puede superar los 150 caracteres.")
            String nombre,
            @Size(max = 100, message = "El símbolo no puede superar los 100 caracteres.")
            String simbolo,
            @Size(max = 300, message = "La URL del plan de gobierno es demasiado larga.")
            @Pattern(regexp = URL, message = "El plan de gobierno debe ser un enlace http(s).")
            String urlPlanGobierno) {
    }

    /** 9/10: confirmarCandidato() → grabarCandidato(id_docente, rol). */
    public record DatosCandidato(
            @NotNull(message = "Indique el docente candidato.")
            Integer idDocente,
            @NotBlank(message = "Indique el rol del candidato en la lista.")
            String rol,
            @Size(max = 300, message = "La URL de la hoja de vida es demasiado larga.")
            @Pattern(regexp = URL, message = "La hoja de vida debe ser un enlace http(s).")
            String urlHojaVida) {
    }
}
