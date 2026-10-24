package pe.unp.elecciones.electoral.impugnaciones;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** CUS13 · Datos que envía la PantallaImpugnaciones. */
public final class ImpugnacionesDto {

    private ImpugnacionesDto() {
    }

    /** 1 ingresarImpugnacion(id_mesa, motivo): el personero de mesa y el cargo de la cédula. */
    public record NuevaImpugnacion(
            Integer idPersonero,
            Integer idCargo,
            @NotBlank(message = "Indique el motivo de la impugnación.")
            @Size(min = 10, max = 1000, message = "El motivo debe tener entre 10 y 1000 caracteres.")
            String motivo) {
    }

    /** 6 registrarDecisionMesa(id_impugnacion, decision), con la votación de los miembros (RN23). */
    public record DecisionMesa(
            @NotBlank(message = "Indique la decisión de la mesa: ACEPTADA o RECHAZADA.")
            String decision,
            @NotNull(message = "Indique cuántos miembros votaron a favor.")
            @Min(value = 0, message = "Los votos no pueden ser negativos.") @Max(value = 3, message = "La mesa tiene tres miembros.")
            Integer votosFavor,
            @NotNull(message = "Indique cuántos miembros votaron en contra.")
            @Min(value = 0, message = "Los votos no pueden ser negativos.") @Max(value = 3, message = "La mesa tiene tres miembros.")
            Integer votosContra,
            @NotBlank(message = "Indique a qué opción va la cédula.")
            String opcion,
            Integer idLista,
            @NotBlank(message = "Fundamente la decisión de la mesa.")
            @Size(min = 10, max = 1000, message = "El fundamento debe tener entre 10 y 1000 caracteres.")
            String fundamento) {
    }

    /** 10 [decision rechazada] apelarDecision(id_impugnacion). */
    public record Apelacion(
            Integer idPersonero,
            @NotBlank(message = "Fundamente la apelación.")
            @Size(min = 10, max = 1000, message = "El fundamento debe tener entre 10 y 1000 caracteres.")
            String fundamento) {
    }

    /** 11 registrarFalloCEUNP(id_impugnacion, decision), con la votación del Pleno (RN36). */
    public record FalloCeunp(
            @NotBlank(message = "Indique el fallo: CONFIRMADA o MODIFICADA.")
            String decision,
            @NotBlank(message = "Indique el número de la resolución.")
            @Size(max = 40, message = "El número de resolución admite hasta 40 caracteres.")
            String numeroResolucion,
            @NotNull(message = "Indique los miembros presentes del Pleno.")
            @Min(value = 1, message = "Indique los miembros presentes del Pleno.") @Max(value = 30, message = "Demasiados miembros.")
            Integer miembrosPleno,
            @NotNull(message = "Indique los votos a favor de la apelación.") @Min(0) @Max(30)
            Integer votosFavor,
            @NotNull(message = "Indique los votos en contra de la apelación.") @Min(0) @Max(30)
            Integer votosContra,
            String votoDirimente,
            String opcion,
            Integer idLista,
            @NotBlank(message = "Fundamente el fallo.")
            @Size(min = 10, max = 1000, message = "El fundamento debe tener entre 10 y 1000 caracteres.")
            String fundamento) {
    }
}
