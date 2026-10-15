package pe.unp.elecciones.electoral.sorteo;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;

/** CUS06 · Datos que envía la PantallaSorteoMesa. */
public final class SorteoDto {

    private SorteoDto() {
    }

    /** 6: ingresarSemilla(semilla). Vacía = el sistema genera una semilla aleatoria y la muestra. */
    public record DatosSemilla(
            @Size(max = 128, message = "La semilla no puede superar los 128 caracteres.")
            String semilla) {
    }

    /** Conformación de mesas (paso previo al sorteo). */
    public record DatosMesas(
            @Min(value = 6, message = "RN19: cada mesa necesita al menos 6 electores para el sorteo.")
            @Max(value = 1000, message = "Máximo 1000 electores por mesa.")
            Integer electoresPorMesa,
            @Size(max = 200, message = "La ubicación no puede superar los 200 caracteres.")
            String ubicacion) {
    }
}
