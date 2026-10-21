package pe.unp.elecciones.electoral.votacion;

import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** CUS09 / CUS10 · Datos que envían la PantallaVerificacion y el TerminalVotacion. */
public final class VotacionDto {

    private VotacionDto() {
    }

    /** 1-2 escanearQR() / verificar(token); A1: búsqueda por DNI si el QR no se puede leer. */
    public record SolicitudVerificacion(
            @Size(max = 8, message = "El DNI debe tener hasta 8 dígitos.")
            String dni,
            @Size(max = 300, message = "El código leído es demasiado largo.")
            String codigo) {
    }

    /** 5 confirmarConDNI() → 6 registrarAsistencia() → 7 habilitarTerminal(). */
    public record Confirmacion(
            @NotNull(message = "Indique el elector.")
            Integer idDocente,
            @NotBlank(message = "Indique cómo se identificó al elector: QR o DNI.")
            String metodo,
            Long idCredencial,
            @NotNull(message = "Elija el terminal que se habilitará.")
            Integer idTerminal) {
    }

    /** CUS09 A5: el DNI no corresponde al elector (suplantación). */
    public record Rechazo(
            Integer idDocente,
            @Size(max = 8, message = "El DNI debe tener hasta 8 dígitos.")
            String dni,
            @NotBlank(message = "Indique el motivo del rechazo.")
            @Size(min = 5, max = 255, message = "El motivo debe tener entre 5 y 255 caracteres.")
            String motivo) {
    }

    /** CUS10 A3/A5: el Presidente autoriza la rehabilitación del terminal para el elector. */
    public record Rehabilitacion(
            @NotNull(message = "Indique el elector.")
            Integer idDocente,
            @NotNull(message = "Elija el terminal que se habilitará.")
            Integer idTerminal,
            @NotBlank(message = "Indique el motivo de la rehabilitación.")
            @Size(min = 5, max = 255, message = "El motivo debe tener entre 5 y 255 caracteres.")
            String motivo) {
    }

    /** CUS10 A3: el elector abandona el terminal sin confirmar (o se anula por error de mesa). */
    public record Anulacion(
            @NotBlank(message = "Indique el motivo.")
            @Size(min = 5, max = 255, message = "El motivo debe tener entre 5 y 255 caracteres.")
            String motivo) {
    }

    /** CUS10 A4: terminal fuera de servicio o de nuevo operativo. */
    public record EstadoTerminal(boolean activo) {
    }

    /** El equipo de la cabina se registra como terminal de una mesa. */
    public record RegistroTerminal(
            @NotNull(message = "Indique la mesa.")
            Integer idMesa,
            @NotBlank(message = "Indique el nombre del terminal (por ejemplo: Cabina 1).")
            @Size(max = 40, message = "El nombre del terminal tiene hasta 40 caracteres.")
            String nombre) {
    }

    /** Una marca de la cédula. tipo = VALIDO (con listaId) o BLANCO. */
    public record Marca(
            @NotNull(message = "Falta el cargo de una marca.")
            Integer cargoId,
            @NotBlank(message = "Falta el tipo de voto de una marca.")
            String tipo,
            Integer listaId) {
    }

    /** 9 registrarVoto(opción): la habilitación de un solo uso y la opción, sin datos del elector. */
    public record Voto(
            @NotNull(message = "Falta la habilitación del terminal.")
            Long idHabilitacion,
            @NotBlank(message = "Falta la habilitación del terminal.")
            @Size(min = 64, max = 64, message = "La habilitación del terminal no es válida.")
            String token,
            @NotNull(message = "Marque una opción en cada cargo.")
            @Size(min = 1, max = 30, message = "Marque una opción en cada cargo.")
            List<@Valid Marca> votos) {
    }
}
