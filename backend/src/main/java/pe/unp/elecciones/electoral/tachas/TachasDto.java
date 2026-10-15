package pe.unp.elecciones.electoral.tachas;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** CUS04 · Datos que envía la PantallaTachas. */
public final class TachasDto {

    private TachasDto() {
    }

    /**
     * 1/2: ingresarTacha(id_candidato, motivo) → enviarTacha(datos).
     * dniDenunciante solo lo usa el CEUNP al registrar una tacha recibida en mesa de partes;
     * el docente elector siempre tacha a nombre propio (se toma de su sesión).
     */
    public record DatosTacha(
            @NotNull(message = "Seleccione al candidato que desea tachar.")
            Integer idCandidato,
            @NotBlank(message = "La tacha debe estar fundamentada por escrito.")
            @Size(min = 20, max = 4000, message = "El fundamento debe tener entre 20 y 4000 caracteres.")
            String motivo,
            String dniDenunciante) {
    }

    /** 5/6: registrarResolucion(id_tacha, estado) → guardarResolucion(datos). */
    public record DatosResolucion(
            @NotBlank(message = "Indique si la tacha es FUNDADA o INFUNDADA.")
            String estado,
            @NotBlank(message = "La resolución debe estar fundamentada.")
            @Size(min = 20, max = 4000, message = "El fundamento de la resolución debe tener entre 20 y 4000 caracteres.")
            String resolucion) {
    }
}
