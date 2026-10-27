package pe.unp.elecciones.electoral.resultados;

import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** CUS17 · Datos que envía la PantallaResultados. */
public final class ResultadosDto {

    private ResultadosDto() {
    }

    /** 7 escanearQR → 8 verificarActa(): token del QR, enlace del QR o huella SHA-256. */
    public record Verificacion(
            @NotBlank(message = "Lea el QR o escriba el código del documento.")
            @Size(max = 300, message = "El código admite hasta 300 caracteres.")
            String codigo,
            String canal) {
    }

    /** Cifra anotada del ejemplar físico para una línea del documento digital. */
    public record Cifra(
            @NotBlank(message = "Falta la clave de la cifra.")
            String clave,
            @NotNull(message = "Anote todas las cifras del ejemplar físico.")
            @Min(value = 0, message = "Las cifras no pueden ser negativas.") @Max(value = 1_000_000, message = "Cifra fuera de rango.")
            Long fisico) {
    }

    /** Cotejo del ejemplar físico con el documento digital (RF55). */
    public record Cotejo(
            @NotBlank(message = "Indique el código del documento.")
            @Size(max = 300, message = "El código admite hasta 300 caracteres.")
            String codigo,
            Long idVerificacion,
            @NotEmpty(message = "Anote las cifras del ejemplar físico.")
            List<@Valid Cifra> cifras,
            @Size(max = 1000, message = "La observación admite hasta 1000 caracteres.")
            String observacion) {
    }

    /** El CEUNP atiende la discrepancia reportada. */
    public record Atencion(
            @NotBlank(message = "Indique si la discrepancia queda aclarada o es fundada.")
            String decision,
            @NotBlank(message = "Fundamente la respuesta.")
            @Size(min = 10, max = 1000, message = "La respuesta debe tener entre 10 y 1000 caracteres.")
            String respuesta) {
    }
}
