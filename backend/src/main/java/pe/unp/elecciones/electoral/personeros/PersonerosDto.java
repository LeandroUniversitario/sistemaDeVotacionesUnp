package pe.unp.elecciones.electoral.personeros;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** CUS05 · Datos que envía la PantallaPersoneros. */
public final class PersonerosDto {

    private PersonerosDto() {
    }

    /** 5/6: confirmarAcreditacion(tipo, id_mesa) → guardarAcreditacion(datos). */
    public record DatosAcreditacion(
            @NotNull(message = "Indique el docente a acreditar.")
            Integer idDocente,
            @NotBlank(message = "Indique el tipo de personero: GENERAL, ALTERNO o MESA.")
            String tipo,
            Integer idMesa) {
    }

    /** Revocación de una acreditación (queda en la bitácora). */
    public record DatosRevocacion(
            @NotBlank(message = "Indique el motivo de la revocación.")
            @Size(min = 10, max = 500, message = "El motivo debe tener entre 10 y 500 caracteres.")
            String motivo) {
    }
}
