package pe.unp.elecciones.electoral.nulidades;

import java.time.LocalDateTime;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** CUS15 · Datos que envía la PantallaNulidades. */
public final class NulidadesDto {

    private NulidadesDto() {
    }

    /** 1 ingresarNulidadParcial(id_mesa, causal) (RF100, Art. 64). */
    public record RecursoParcial(
            @NotNull(message = "Elija la mesa.")
            Integer idMesa,
            @NotBlank(message = "Elija la causal de nulidad.")
            String causal,
            @NotBlank(message = "Indique si la nulidad es de oficio o a pedido de un personero.")
            String origen,
            Integer idPersonero,
            @NotBlank(message = "Sustente el recurso de nulidad.")
            @Size(min = 10, max = 1000, message = "El sustento debe tener entre 10 y 1000 caracteres.")
            String sustento,
            @Size(max = 500, message = "Las pruebas admiten hasta 500 caracteres.")
            String pruebas) {
    }

    /** 5 ingresarNulidadTotal(id_proceso, motivo) (RF101, Art. 65). */
    public record RecursoTotal(
            @NotBlank(message = "Elija la causal de nulidad.")
            String causal,
            @NotBlank(message = "Indique si la nulidad es de oficio o a pedido de un personero.")
            String origen,
            Integer idPersonero,
            @NotBlank(message = "Sustente el recurso de nulidad.")
            @Size(min = 10, max = 1000, message = "El sustento debe tener entre 10 y 1000 caracteres.")
            String sustento,
            @Size(max = 500, message = "Las pruebas admiten hasta 500 caracteres.")
            String pruebas) {
    }

    /** Resolución del Pleno: quórum y mayoría simple con voto dirimente del Presidente (RN36). */
    public record Resolucion(
            @NotBlank(message = "Indique la decisión: FUNDADA, INFUNDADA o IMPROCEDENTE.")
            String decision,
            @NotBlank(message = "Fundamente la resolución del CEUNP.")
            @Size(min = 10, max = 1000, message = "El fundamento debe tener entre 10 y 1000 caracteres.")
            String fundamento,
            @NotBlank(message = "Indique el número de la resolución.")
            @Size(max = 40, message = "El número de resolución admite hasta 40 caracteres.")
            String numeroResolucion,
            @NotNull(message = "Indique los miembros presentes del Pleno.")
            @Min(value = 1, message = "Indique los miembros presentes del Pleno.") @Max(value = 9, message = "El Pleno del CEUNP tiene nueve miembros.")
            Integer miembrosPleno,
            @NotNull(message = "Indique los votos a favor de la decisión.")
            @Min(value = 0, message = "Los votos no pueden ser negativos.") @Max(value = 9, message = "El Pleno del CEUNP tiene nueve miembros.")
            Integer votosFavor,
            @NotNull(message = "Indique los votos en contra de la decisión.")
            @Min(value = 0, message = "Los votos no pueden ser negativos.") @Max(value = 9, message = "El Pleno del CEUNP tiene nueve miembros.")
            Integer votosContra,
            Boolean votoDirimente) {
    }

    /** 8 registrarComunicacion('SUNEDU, AU, CU') y publicación (RF102, Art. 66). */
    public record Comunicacion(
            @NotBlank(message = "Elija el destinatario.")
            String destinatario,
            @Size(max = 80, message = "El documento admite hasta 80 caracteres.")
            String documento,
            LocalDateTime fechaEnvio,
            @Size(max = 500, message = "La observación admite hasta 500 caracteres.")
            String observacion) {
    }

    /** 10 convocarSegundaVuelta(id_proceso, fechas) (RN33, dentro de 15 días del cómputo). */
    public record SegundaVuelta(
            @NotNull(message = "Indique la fecha de inicio de la segunda vuelta.")
            LocalDateTime fechaInicio,
            @NotNull(message = "Indique la fecha de fin de la segunda vuelta.")
            LocalDateTime fechaFin) {
    }

    /** Sorteo del Pleno para dirimir un empate (pase a la segunda vuelta o empate en ella). */
    public record Dirimencia(
            @NotBlank(message = "Indique la semilla pública del sorteo.")
            @Size(min = 4, max = 100, message = "La semilla debe tener entre 4 y 100 caracteres.")
            String semilla,
            @NotBlank(message = "Indique el número de la resolución.")
            @Size(max = 40, message = "El número de resolución admite hasta 40 caracteres.")
            String numeroResolucion,
            @NotNull(message = "Indique los miembros presentes del Pleno.")
            @Min(value = 1, message = "Indique los miembros presentes del Pleno.") @Max(value = 9, message = "El Pleno del CEUNP tiene nueve miembros.")
            Integer miembrosPleno,
            @Size(max = 1000, message = "El fundamento admite hasta 1000 caracteres.")
            String fundamento) {
    }
}
