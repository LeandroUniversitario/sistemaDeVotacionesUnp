package pe.unp.elecciones.electoral.instalacion;

import java.util.Map;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** CUS08 · Datos que envía la PantallaInstalacion. */
public final class InstalacionDto {

    private InstalacionDto() {
    }

    /** 1 escanearCredencialQR(token): contenido leído de la credencial (cámara o pistola lectora). */
    public record LecturaCredencial(
            @NotBlank(message = "Lea o ingrese el código QR.")
            @Size(max = 300, message = "El código leído es demasiado largo.")
            String codigo) {
    }

    /**
     * Llegada registrada a mano. Para marcar presente se exige el DNI que muestra la persona
     * (debe coincidir con el registrado, RN30); para marcar ausente no.
     */
    public record Asistencia(
            boolean presente,
            @Size(max = 12, message = "El DNI tiene 8 dígitos.")
            String dni) {
    }

    /** CUN07 flujo alterno: integrante de la comunidad universitaria que asume un cargo vacante. */
    public record Reemplazante(
            @NotBlank(message = "Indique el cargo: PRESIDENTE, SECRETARIO o VOCAL.")
            String cargo,
            @NotBlank(message = "Ingrese el DNI del reemplazante.")
            @Size(max = 12, message = "El DNI tiene 8 dígitos.")
            String dni) {
    }

    /** Estado de un material recibido. */
    public record ItemMaterial(
            @NotBlank(message = "Indique el estado del material.")
            String estado,
            @Size(max = 200, message = "La observación de un material admite hasta 200 caracteres.")
            String observacion) {
    }

    /** 5 ingresarMaterial(padron, actas, cedulas, anfora, cabina): RF57 y RF59. */
    public record Material(
            @NotNull(message = "Indique el material recibido.")
            Map<String, @Valid ItemMaterial> items,
            @Min(value = 0, message = "La cantidad de cédulas no puede ser negativa.")
            @Max(value = 100000, message = "La cantidad de cédulas es demasiado grande.")
            Integer cedulasRecibidas,
            boolean cedulasFirmadas,
            @Size(max = 500, message = "Las observaciones admiten hasta 500 caracteres.")
            String observaciones) {
    }

    /** RF58: motivo por el que la mesa no se instaló. */
    public record NoInstalacion(
            @NotBlank(message = "Indique el motivo.")
            @Size(min = 10, max = 255, message = "El motivo debe tener entre 10 y 255 caracteres.")
            String motivo) {
    }

    /** RF60: evaluación de nulidad de una mesa no instalada. */
    public record EvaluacionNulidad(
            @NotBlank(message = "Indique si procede la nulidad: PROCEDE o NO_PROCEDE.")
            String decision,
            @NotBlank(message = "Fundamente la evaluación.")
            @Size(min = 10, max = 500, message = "El fundamento debe tener entre 10 y 500 caracteres.")
            String fundamento) {
    }
}
