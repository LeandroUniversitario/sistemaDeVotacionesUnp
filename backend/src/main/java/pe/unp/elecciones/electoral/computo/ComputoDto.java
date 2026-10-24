package pe.unp.elecciones.electoral.computo;

import java.time.LocalDateTime;
import java.util.List;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** CUS14 · Datos que envía la PantallaComputo. */
public final class ComputoDto {

    private ComputoDto() {
    }

    /** Paso 4 de la tabla 39 (RF91): sesión de cómputo general con quórum del Pleno (RN36). */
    public record Sesion(
            @NotBlank(message = "Indique el lugar de la sesión de cómputo.")
            @Size(max = 200, message = "El lugar admite hasta 200 caracteres.")
            String lugar,
            @NotNull(message = "Indique los miembros del CEUNP presentes.")
            @Min(value = 1, message = "Indique los miembros del CEUNP presentes.") @Max(value = 9, message = "El Pleno del CEUNP tiene nueve miembros.")
            Integer miembrosCeunp,
            @Size(max = 1000, message = "Las observaciones admiten hasta 1000 caracteres.")
            String observaciones,
            List<Integer> personeros) {
    }

    /** RF91: personero que llega a la sesión ya instalada. */
    public record Personero(
            @NotNull(message = "Elija el personero.")
            Integer idPersonero) {
    }

    /** 4 validarIntegridad(actas): el CEUNP marca un acta como dudosa (paso 3, RF90). */
    public record ActaDudosa(
            @NotBlank(message = "Indique por qué el acta es dudosa.")
            @Size(min = 10, max = 500, message = "El motivo debe tener entre 10 y 500 caracteres.")
            String motivo) {
    }

    /** 5 actasValidas(hashCorrecto): comprobación con el QR del ejemplar físico y la huella SHA-256. */
    public record Comprobacion(
            @Size(max = 300, message = "El código leído admite hasta 300 caracteres.")
            String tokenQr,
            @Size(max = 500, message = "La observación admite hasta 500 caracteres.")
            String observacion) {
    }

    /** A3 (RF95) y paso 7 (RF94): calificación del CEUNP de la mesa cuya acta difiere o es nula. */
    public record Calificacion(
            @NotBlank(message = "Indique la calificación: VALIDA o NULIDAD.")
            String calificacion,
            @NotBlank(message = "Fundamente la decisión del CEUNP.")
            @Size(min = 10, max = 1000, message = "El fundamento debe tener entre 10 y 1000 caracteres.")
            String fundamento,
            @Size(max = 40, message = "El número de resolución admite hasta 40 caracteres.")
            String numeroResolucion) {
    }

    /** 16 acreditarGanadora(idLista): proclamación por el Presidente del CEUNP en sesión del Pleno (RF98). */
    public record Proclamacion(
            @NotBlank(message = "Indique el número de la resolución de proclamación.")
            @Size(max = 40, message = "El número de resolución admite hasta 40 caracteres.")
            String numeroResolucion,
            @NotNull(message = "Indique los miembros presentes del Pleno.")
            @Min(value = 1, message = "Indique los miembros presentes del Pleno.") @Max(value = 9, message = "El Pleno del CEUNP tiene nueve miembros.")
            Integer miembrosPleno,
            @NotBlank(message = "Indique el nombre del Presidente del CEUNP.")
            @Size(max = 150, message = "El nombre admite hasta 150 caracteres.")
            String presidente,
            @Size(max = 1000, message = "El fundamento admite hasta 1000 caracteres.")
            String fundamento) {
    }

    /** A2 (RN33): fechas de la segunda vuelta, dentro de los 15 días siguientes al cómputo. */
    public record SegundaVuelta(
            @NotNull(message = "Indique la fecha de inicio de la segunda vuelta.")
            LocalDateTime fechaInicio,
            @NotNull(message = "Indique la fecha de fin de la segunda vuelta.")
            LocalDateTime fechaFin) {
    }
}
