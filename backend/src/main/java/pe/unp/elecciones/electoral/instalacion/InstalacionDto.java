package pe.unp.elecciones.electoral.instalacion;

import java.util.Map;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** CUS08 · Datos que envía la PantallaInstalacion. */
public final class InstalacionDto {

    private InstalacionDto() {
    }

    /** Contenido leído del fotocheck del miembro o de la credencial del personero. */
    public record LecturaCredencial(
            @NotBlank(message = "Lea o ingrese el código QR.")
            @Size(max = 300, message = "El código leído es demasiado largo.")
            String codigo) {
    }

    /**
     * Acreditación manual. Para marcar presente se exige el DNI que muestra la persona
     * (debe coincidir con el registrado); para marcar ausente no.
     */
    public record Asistencia(
            boolean presente,
            @Size(max = 12, message = "El DNI tiene 8 dígitos.")
            String dni) {
    }

    /** Material recibido (código de MaterialElectoral → recibido) y observaciones. */
    public record Material(
            @NotNull(message = "Indique el material recibido.")
            Map<String, Boolean> items,
            @Size(max = 500, message = "Las observaciones admiten hasta 500 caracteres.")
            String observaciones) {
    }

    /** RN07: motivo por el que la mesa no se instaló. */
    public record NoInstalacion(
            @NotBlank(message = "Indique el motivo.")
            @Size(min = 10, max = 255, message = "El motivo debe tener entre 10 y 255 caracteres.")
            String motivo) {
    }
}
