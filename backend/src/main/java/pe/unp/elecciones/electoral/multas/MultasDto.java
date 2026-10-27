package pe.unp.elecciones.electoral.multas;

import java.time.LocalDateTime;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** CUS16 · Datos que envía la PantallaMultas. */
public final class MultasDto {

    private MultasDto() {
    }

    /** 7 mostrarReporteMultas(): resolución del Pleno que determina las multas (RN35, RN36). */
    public record Resolucion(
            @NotBlank(message = "Indique el número de la resolución.")
            @Size(max = 40, message = "El número de resolución admite hasta 40 caracteres.")
            String numeroResolucion,
            @NotNull(message = "Indique los miembros presentes del Pleno.")
            @Min(value = 1, message = "Indique los miembros presentes del Pleno.") @Max(value = 9, message = "El Pleno del CEUNP tiene nueve miembros.")
            Integer miembrosPleno,
            @Size(max = 1000, message = "El fundamento admite hasta 1000 caracteres.")
            String fundamento) {
    }

    /** Notificación de las multas determinadas (una o todas las que faltan). */
    public record Notificacion(
            Integer idMulta,
            @NotBlank(message = "Elija el medio de notificación.")
            String medio,
            @Size(max = 80, message = "El documento admite hasta 80 caracteres.")
            String documento,
            LocalDateTime fecha) {
    }

    /** 8 registrarJustificacion → 9 justificar() (RF106) o exoneración de oficio (RN40). */
    public record Justificacion(
            @NotBlank(message = "Indique si es una justificación o una exoneración.")
            String tipo,
            @NotBlank(message = "Elija la causal.")
            String causal,
            @NotBlank(message = "Describa el sustento del descargo.")
            @Size(min = 10, max = 1000, message = "El sustento debe tener entre 10 y 1000 caracteres.")
            String sustento,
            @Size(max = 150, message = "El documento admite hasta 150 caracteres.")
            String documento,
            LocalDateTime fechaPresentacion,
            String decision,
            @NotBlank(message = "Fundamente la decisión del CEUNP.")
            @Size(min = 10, max = 1000, message = "El fundamento debe tener entre 10 y 1000 caracteres.")
            String fundamento,
            @NotBlank(message = "Indique el número de la resolución.")
            @Size(max = 40, message = "El número de resolución admite hasta 40 caracteres.")
            String numeroResolucion,
            @NotNull(message = "Indique los miembros presentes del Pleno.")
            @Min(value = 1, message = "Indique los miembros presentes del Pleno.") @Max(value = 9, message = "El Pleno del CEUNP tiene nueve miembros.")
            Integer miembrosPleno) {
    }

    /** Registro del pago con el recibo de Tesorería (el sistema no cobra la multa). */
    public record Pago(
            @NotBlank(message = "Indique el número del recibo.")
            @Size(min = 3, max = 40, message = "El número de recibo debe tener entre 3 y 40 caracteres.")
            String numeroRecibo,
            LocalDateTime fechaPago,
            @Size(max = 300, message = "La observación admite hasta 300 caracteres.")
            String observacion) {
    }
}
