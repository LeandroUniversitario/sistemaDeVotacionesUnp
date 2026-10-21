package pe.unp.elecciones.electoral.cierre;

import java.util.List;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** CUS11 · Datos que envía la PantallaCierreSufragio. */
public final class CierreDto {

    private CierreDto() {
    }

    /**
     * 9 ingresarObservaciones(cedulas_no_usadas, observaciones). Además, para el flujo A2, el conteo
     * de firmas de la lista física y, para el paso 7 de la tabla 37, los personeros que desean firmar.
     */
    public record DatosActa(
            @NotNull(message = "Indique la cantidad de cédulas no utilizadas.")
            @Min(value = 0, message = "La cantidad de cédulas no utilizadas no puede ser negativa.")
            @Max(value = 100000, message = "La cantidad de cédulas es demasiado grande.")
            Integer cedulasNoUtilizadas,
            @Min(value = 0, message = "El conteo de firmas no puede ser negativo.")
            @Max(value = 100000, message = "El conteo de firmas es demasiado grande.")
            Integer firmasListaFisica,
            @Size(max = 1000, message = "Las observaciones admiten hasta 1000 caracteres.")
            String observaciones,
            @Size(max = 50, message = "Demasiados personeros.")
            List<Integer> personeros) {
    }
}
