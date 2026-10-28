package pe.unp.elecciones.electoral.administracion;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** CUS18 · Datos que envía la PantallaAdministrador. */
public final class AdministracionDto {

    private AdministracionDto() {
    }

    /**
     * 1 ingresarUsuario → 1.1 crearUsuario(). Sin contraseña (o con generarClave) el sistema genera
     * una provisional; en ambos casos el usuario la cambia al primer ingreso.
     */
    public record NuevoUsuario(
            @NotBlank(message = "Indique el nombre de usuario.")
            @Size(min = 3, max = 80, message = "El nombre de usuario debe tener entre 3 y 80 caracteres.")
            String username,
            @NotBlank(message = "Elija el rol de la cuenta.")
            String rol,
            Integer idDocente,
            @Size(max = 72, message = "La contraseña admite hasta 72 caracteres.")
            String password,
            boolean generarClave) {
    }

    /** Cambio de rol o del docente asociado. */
    public record EdicionUsuario(
            @NotBlank(message = "Elija el rol de la cuenta.")
            String rol,
            Integer idDocente) {
    }

    /** Activar o desactivar la cuenta; desactivar exige el motivo. */
    public record Estado(
            @NotNull(message = "Indique si la cuenta queda activa o inactiva.")
            Boolean activo,
            @Size(max = 300, message = "El motivo admite hasta 300 caracteres.")
            String motivo) {
    }

    /** Restablecer la contraseña: sin valor, el sistema genera una provisional. */
    public record Clave(
            @Size(max = 72, message = "La contraseña admite hasta 72 caracteres.")
            String password) {
    }

    /** 5 modificarParametro → 6 actualizar(). */
    public record CambioParametro(
            @NotBlank(message = "Indique el nuevo valor.")
            @Size(max = 255, message = "El valor admite hasta 255 caracteres.")
            String valor,
            @NotBlank(message = "Indique el motivo del cambio.")
            @Size(min = 10, max = 500, message = "El motivo debe tener entre 10 y 500 caracteres.")
            String motivo) {
    }

    /** Volver al valor que tenía el parámetro antes de un cambio del historial. */
    public record Restauracion(
            @NotNull(message = "Elija el cambio del historial.")
            Long idHistorial,
            @NotBlank(message = "Indique el motivo de la restauración.")
            @Size(min = 10, max = 500, message = "El motivo debe tener entre 10 y 500 caracteres.")
            String motivo) {
    }

    /** 10 solicitarRespaldo(). */
    public record SolicitudRespaldo(
            @Size(max = 300, message = "El motivo admite hasta 300 caracteres.")
            String motivo) {
    }
}
