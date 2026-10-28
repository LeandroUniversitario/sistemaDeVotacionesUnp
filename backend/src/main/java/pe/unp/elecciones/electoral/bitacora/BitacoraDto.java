package pe.unp.elecciones.electoral.bitacora;

import java.time.LocalDateTime;

/** CUS19 · Datos que envía la PantallaBitacora. */
public final class BitacoraDto {

    private BitacoraDto() {
    }

    /**
     * 1 ingresarFiltros(usuario, accion, fecha_inicio, fecha_fin) y los demás criterios de la pantalla.
     * Todos son opcionales; modulo y criticidad aceptan varios valores separados por comas.
     *
     * @param texto      busca en la acción, el usuario, el docente, el DNI, el proceso, la IP y el detalle
     *                   («#123» busca el registro N.º 123)
     * @param idUsuario  cuenta que realizó la acción; 0 = acciones sin cuenta (sistema o elector)
     * @param idDocente  docente al que se refiere el registro (elector, miembro de mesa, candidato)
     * @param desde      fecha (AAAA-MM-DD) o fecha y hora (AAAA-MM-DDTHH:MM); sin hora, desde las 00:00
     * @param hasta      fecha o fecha y hora; sin hora, hasta las 23:59:59
     */
    public record Filtros(
            String texto,
            Integer idUsuario,
            String rol,
            String accion,
            String modulo,
            String criticidad,
            Integer idProceso,
            Integer idDocente,
            String ip,
            LocalDateTime desde,
            LocalDateTime hasta) {

        public static Filtros vacios() {
            return new Filtros(null, null, null, null, null, null, null, null, null, null, null);
        }
    }
}
