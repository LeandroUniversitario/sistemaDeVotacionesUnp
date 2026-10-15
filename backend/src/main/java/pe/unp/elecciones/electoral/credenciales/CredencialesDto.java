package pe.unp.elecciones.electoral.credenciales;

import java.util.List;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** CUS07 · Datos que envía la PantallaCredenciales. */
public final class CredencialesDto {

    /** Máximo de credenciales por solicitud (la respuesta trae un QR por cada una). */
    public static final int MAXIMO_POR_LOTE = 1000;

    private CredencialesDto() {
    }

    /**
     * 1: solicitarCredencial(id_docente), individual o en lote.
     * {@code ids} son los titulares: id_docente para ELECTOR y MIEMBRO_MESA, id_personero para PERSONERO.
     */
    public record SolicitudEmision(
            @NotBlank(message = "Indique el tipo de credencial: ELECTOR, MIEMBRO_MESA o PERSONERO.")
            String tipo,
            @NotNull(message = "Seleccione al menos un titular.")
            @Size(min = 1, max = MAXIMO_POR_LOTE, message = "Seleccione entre 1 y 1000 titulares por emisión.")
            List<Integer> ids) {
    }

    /** El propio docente solicita (o vuelve a generar) su credencial. */
    public record SolicitudPropia(
            @NotNull(message = "Indique el proceso electoral.")
            Integer idProceso,
            @NotBlank(message = "Indique el tipo de credencial.")
            String tipo,
            @NotNull(message = "Indique la credencial a generar.")
            Integer idTitular) {
    }

    /** Revocación de una credencial vigente (queda en la bitácora). */
    public record DatosRevocacion(
            @NotBlank(message = "Indique el motivo de la revocación.")
            @Size(min = 10, max = 255, message = "El motivo debe tener entre 10 y 255 caracteres.")
            String motivo) {
    }

    /** Contenido leído del código QR (cámara o pistola lectora). */
    public record SolicitudVerificacion(
            @NotBlank(message = "Lea o ingrese el código QR.")
            @Size(max = 300, message = "El código leído es demasiado largo.")
            String codigo) {
    }
}
