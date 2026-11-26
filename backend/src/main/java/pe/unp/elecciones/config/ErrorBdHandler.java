package pe.unp.elecciones.config;

import java.sql.SQLException;

import org.springframework.dao.DataAccessException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.transaction.TransactionSystemException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * Traduce los errores de la base de datos a respuestas HTTP legibles.
 *
 * Los procedimientos almacenados y los triggers rechazan las operaciones que
 * incumplen una regla de negocio con SIGNAL SQLSTATE '45000' y un mensaje que
 * cita la regla (por ejemplo "RN01: el docente ya voto por este cargo.").
 * Ese mensaje llega al frontend en el campo "detail".
 */
@RestControllerAdvice
public class ErrorBdHandler {

    private static final String ESTADO_REGLA_NEGOCIO = "45000";

    @ExceptionHandler({DataAccessException.class, TransactionSystemException.class})
    public ProblemDetail manejar(RuntimeException exception) {
        SQLException sql = buscarSqlException(exception);

        if (sql != null && ESTADO_REGLA_NEGOCIO.equals(sql.getSQLState())) {
            return ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, limpiar(sql.getMessage()));
        }
        String especifico = mensajeEspecifico(sql, exception);
        if (especifico != null) {
            HttpStatus estado = sql != null && sql.getSQLState() != null && sql.getSQLState().startsWith("23")
                    ? HttpStatus.CONFLICT
                    : sql != null && sql.getSQLState() != null && sql.getSQLState().startsWith("08")
                            ? HttpStatus.SERVICE_UNAVAILABLE : HttpStatus.INTERNAL_SERVER_ERROR;
            return ProblemDetail.forStatusAndDetail(estado, especifico);
        }
        if (exception instanceof DataIntegrityViolationException) {
            return ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT,
                    "La operación no respeta una restricción de la base de datos "
                            + "(dato duplicado, valor fuera de rango o registro en uso).");
        }
        return ProblemDetail.forStatusAndDetail(HttpStatus.INTERNAL_SERVER_ERROR,
                "Error de base de datos" + (sql != null ? " (código " + sql.getErrorCode() + ")" : "")
                        + ". Revise el registro del servidor.");
    }

    /**
     * Mensaje concreto según el código de error de MariaDB/MySQL, para que el usuario sepa qué
     * falló en lugar de un error genérico.
     */
    private static String mensajeEspecifico(SQLException sql, RuntimeException exception) {
        if (sql == null) {
            return exception instanceof org.springframework.jdbc.CannotGetJdbcConnectionException
                    ? "No hay conexión con la base de datos: verifique que MySQL/MariaDB (XAMPP) esté encendido."
                    : null;
        }
        String msg = limpiar(sql.getMessage());
        String estado = sql.getSQLState() == null ? "" : sql.getSQLState();
        if (estado.startsWith("08")) {
            return "Se perdió la conexión con la base de datos: verifique que MySQL/MariaDB (XAMPP) esté encendido y vuelva a intentarlo.";
        }
        return switch (sql.getErrorCode()) {
            case 1062 -> "Ya existe un registro con ese dato (valor duplicado" + entreComillas(msg, "for key") + ").";
            case 1451 -> "No se puede eliminar o cambiar: el registro está en uso por otros datos del sistema"
                    + tabla(msg) + ".";
            case 1452 -> "El dato relacionado no existe (por ejemplo, el docente, la mesa o la lista ya no está registrado)"
                    + tabla(msg) + ".";
            case 1048 -> "Falta un dato obligatorio" + entreComillas(msg, "Column") + ".";
            case 1406 -> "Un texto es demasiado largo para el campo" + entreComillas(msg, "column") + ".";
            case 1264, 1366 -> "Un valor no es válido o está fuera de rango para el campo" + entreComillas(msg, "column") + ".";
            case 1146 -> "Falta una tabla en la base de datos" + entreComillas(msg, "Table")
                    + ": aplique los scripts pendientes de la carpeta base-de-datos.";
            case 1054 -> "Falta una columna en la base de datos" + entreComillas(msg, "column")
                    + ": aplique los scripts pendientes de la carpeta base-de-datos.";
            case 1305 -> "Falta un procedimiento o función en la base de datos: aplique los scripts pendientes de la carpeta base-de-datos.";
            case 1205, 1213 -> "La base de datos está ocupada con otra operación (bloqueo): espere unos segundos y vuelva a intentarlo.";
            case 1267, 1271 -> "Conflicto de intercalación (collation) en la base de datos: ejecute los scripts con SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci.";
            default -> null;
        };
    }

    /** Extrae el nombre entre comillas que sigue a la palabra indicada (p. ej. for key 'uk_dni'). */
    private static String entreComillas(String mensaje, String despuesDe) {
        if (mensaje == null) return "";
        java.util.regex.Matcher m = java.util.regex.Pattern
                .compile(java.util.regex.Pattern.quote(despuesDe) + "\\s*['`]([^'`]+)['`]", java.util.regex.Pattern.CASE_INSENSITIVE)
                .matcher(mensaje);
        return m.find() ? ": " + m.group(1) : "";
    }

    /** Tabla de una restricción de clave foránea: «... CONSTRAINT `fk` FOREIGN KEY ... REFERENCES `tabla` ...». */
    private static String tabla(String mensaje) {
        if (mensaje == null) return "";
        java.util.regex.Matcher m = java.util.regex.Pattern.compile("`([^`]+)`, CONSTRAINT").matcher(mensaje);
        return m.find() ? " (tabla " + m.group(1).replaceAll(".*/", "") + ")" : "";
    }

    private static SQLException buscarSqlException(Throwable throwable) {
        Throwable actual = throwable;
        int profundidad = 0;
        while (actual != null && profundidad < 20) {
            if (actual instanceof SQLException sqlException) {
                return sqlException;
            }
            actual = actual.getCause();
            profundidad++;
        }
        return null;
    }

    /** El driver de MariaDB antepone "(conn=123) " al mensaje. */
    private static String limpiar(String mensaje) {
        if (mensaje == null) {
            return "La operación fue rechazada por una regla de negocio.";
        }
        return mensaje.replaceFirst("^\\(conn=\\d+\\)\\s*", "").trim();
    }
}
