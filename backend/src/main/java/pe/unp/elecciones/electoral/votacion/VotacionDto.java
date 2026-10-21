package pe.unp.elecciones.electoral.votacion;

import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** CUS09 / CUS10 · Datos que envían la pantalla de mesa y la cabina de votación. */
public final class VotacionDto {

    private VotacionDto() {
    }

    /** CUS09: identificación del elector con su pase QR (codigo) o con su DNI. */
    public record SolicitudVerificacion(
            @Size(max = 8, message = "El DNI debe tener hasta 8 dígitos.")
            String dni,
            @Size(max = 300, message = "El código leído es demasiado largo.")
            String codigo) {
    }

    /** CUS09: el miembro de mesa habilita la cabina al elector verificado. */
    public record SolicitudAutorizacion(
            @NotNull(message = "Indique el elector a autorizar.")
            Integer idDocente,
            @NotBlank(message = "Indique cómo se identificó al elector: QR o DNI.")
            String metodo,
            Long idCredencial) {
    }

    /** CUS09: anulación de una autorización que no se usó (el elector se retiró, error de mesa…). */
    public record DatosAnulacion(
            @NotBlank(message = "Indique el motivo de la anulación.")
            @Size(min = 5, max = 255, message = "El motivo debe tener entre 5 y 255 caracteres.")
            String motivo) {
    }

    /** CUS10: una marca de la cédula. tipo = VALIDO (con listaId) o BLANCO. */
    public record Marca(
            @NotNull(message = "Falta el cargo de una marca.")
            Integer cargoId,
            @NotBlank(message = "Falta el tipo de voto de una marca.")
            String tipo,
            Integer listaId) {
    }

    /** CUS10: la cédula completa (una marca por cada cargo pendiente del elector). */
    public record Cedula(
            @NotNull(message = "Indique el proceso electoral.")
            Integer procesoId,
            @NotNull(message = "Marque una opción en cada cargo.")
            @Size(min = 1, max = 30, message = "Marque una opción en cada cargo.")
            List<@Valid Marca> votos) {
    }
}
