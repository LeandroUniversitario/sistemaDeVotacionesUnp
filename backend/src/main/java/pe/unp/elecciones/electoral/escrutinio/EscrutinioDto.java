package pe.unp.elecciones.electoral.escrutinio;

import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/** CUS12 · Datos que envía la PantallaEscrutinio. */
public final class EscrutinioDto {

    private EscrutinioDto() {
    }

    /**
     * 1 ingresarTotalCedulas(total). Para el flujo A1, la confirmación de que las cédulas
     * sobrantes se retiraron al azar y se destruyeron sin abrirlas; A1 y A2 piden observación.
     */
    public record TotalCedulas(
            @NotNull(message = "Ingrese el total de cédulas contadas en el ánfora.")
            @Min(value = 0, message = "El total de cédulas no puede ser negativo.")
            @Max(value = 100000, message = "El total de cédulas es demasiado grande.")
            Integer totalCedulas,
            Boolean destruidas,
            @Size(max = 1000, message = "La observación admite hasta 1000 caracteres.")
            String observacion) {
    }

    /** Paso 4 de la tabla 38: un personero presente impugna un voto (RN24, RF80). */
    public record Impugnacion(
            @NotNull(message = "Elija al personero que impugna.")
            Integer idPersonero,
            @NotNull(message = "Elija el cargo de la cédula impugnada.")
            Integer idCargo,
            @NotBlank(message = "Indique el motivo de la impugnación.")
            @Size(max = 1000, message = "El motivo admite hasta 1000 caracteres.")
            String motivo) {
    }

    /** Una opción del conteo manual de un cargo: LISTA (con idLista), BLANCO, NULO o IMPUGNADO. */
    public record OpcionConteo(
            @NotNull(message = "Falta el cargo de una opción del conteo.")
            Integer idCargo,
            @NotNull(message = "Falta la opción del conteo.")
            @Pattern(regexp = "LISTA|BLANCO|NULO|IMPUGNADO", message = "La opción debe ser LISTA, BLANCO, NULO o IMPUGNADO.")
            String opcion,
            Integer idLista,
            @NotNull(message = "Ingrese los votos de cada opción (0 si no hay).")
            @Min(value = 0, message = "Los votos no pueden ser negativos.")
            @Max(value = 100000, message = "La cantidad de votos es demasiado grande.")
            Integer votos) {
    }

    /** 5 ingresarConteoManual(conteo_listas). */
    public record ConteoManual(
            @NotEmpty(message = "Registre el conteo de la mesa.")
            @Size(max = 500, message = "Demasiadas opciones en el conteo.")
            List<@Valid OpcionConteo> conteo) {
    }

    /**
     * 9 confirmarEscrutinio(). A3: si el conteo manual difiere del digital tras el recuento,
     * se confirma que prevalece la cédula física (RF84). Los personeros presentes firman si desean.
     */
    public record ConfirmarEscrutinio(
            Boolean prevaleceFisica,
            @Size(max = 1000, message = "Las observaciones admiten hasta 1000 caracteres.")
            String observaciones,
            @Size(max = 50, message = "Demasiados personeros.")
            List<Integer> personeros) {
    }

    /** Paso 9 de la tabla 38 (RF86, RF87): entrega de los tres ejemplares y del material al CEUNP. */
    public record Entrega(
            @NotBlank(message = "Indique quién recibe las actas por el CEUNP.")
            @Size(max = 150, message = "El nombre de quien recibe admite hasta 150 caracteres.")
            String recibidoPor,
            @NotNull(message = "Indique los ejemplares del acta que se entregan.")
            Integer ejemplares,
            @Min(value = 0, message = "Las copias no pueden ser negativas.")
            @Max(value = 50, message = "Demasiadas copias.")
            Integer copiasPersoneros,
            Boolean entregaPadron,
            Boolean entregaMaterial,
            @Size(max = 500, message = "La observación admite hasta 500 caracteres.")
            String observacion) {
    }
}
