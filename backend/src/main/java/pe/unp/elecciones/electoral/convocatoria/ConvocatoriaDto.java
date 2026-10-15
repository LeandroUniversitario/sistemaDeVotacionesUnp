package pe.unp.elecciones.electoral.convocatoria;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * CUS01 · Gestionar convocatoria y cronograma.
 * Datos que envía la PantallaConvocatoria (frontend) a los controles del caso de uso.
 */
public final class ConvocatoriaDto {

    private ConvocatoriaDto() {
    }

    /**
     * Mensaje 1/2 del diagrama de colaboración: ingresarDatosProceso() / guardarProceso(datos).
     * El cronograma son las cuatro fechas: convocatoria, límite de inscripción, inicio y fin del sufragio.
     */
    public record DatosProceso(
            @NotBlank(message = "El nombre del proceso es obligatorio.")
            @Size(max = 200, message = "El nombre no puede superar los 200 caracteres.")
            String nombre,
            @NotNull(message = "La fecha de convocatoria es obligatoria (RN02).")
            LocalDate fechaConvocatoria,
            @NotNull(message = "La fecha límite de inscripción de listas es obligatoria.")
            LocalDateTime fechaLimiteInscripcion,
            @NotNull(message = "La fecha de inicio del sufragio es obligatoria.")
            LocalDateTime fechaInicio,
            @NotNull(message = "La fecha de fin del sufragio es obligatoria.")
            LocalDateTime fechaFin,
            @NotNull(message = "El quórum mínimo es obligatorio.")
            @DecimalMin(value = "0", message = "El quórum mínimo no puede ser negativo.")
            @DecimalMax(value = "100", message = "El quórum mínimo no puede superar el 100%.")
            BigDecimal quorumMinimo) {
    }

    /**
     * Mensaje 5/6 del diagrama: ingresarCargo(nombre, nivel) / guardarCargo(datos_cargo).
     * nivel: UNIVERSIDAD | FACULTAD | DEPARTAMENTO. idJurisdiccion es la facultad o el
     * departamento (null para UNIVERSIDAD). Las categorías son PRINCIPAL, ASOCIADO, AUXILIAR (RF03).
     */
    public record DatosCargo(
            @NotBlank(message = "El nombre del cargo es obligatorio.")
            @Size(max = 150, message = "El nombre del cargo no puede superar los 150 caracteres.")
            String nombre,
            @NotBlank(message = "El nivel del cargo es obligatorio.")
            String nivel,
            Integer idJurisdiccion,
            List<String> categoriasVotan,
            List<String> categoriasPostulan) {
    }
}
