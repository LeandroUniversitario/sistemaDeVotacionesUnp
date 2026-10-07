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
        if (exception instanceof DataIntegrityViolationException
                || (sql != null && sql.getSQLState() != null && sql.getSQLState().startsWith("23"))) {
            return ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT,
                    "La operación no respeta una restricción de la base de datos "
                            + "(dato duplicado, valor fuera de rango o registro en uso).");
        }
        return ProblemDetail.forStatusAndDetail(HttpStatus.INTERNAL_SERVER_ERROR,
                "Error de base de datos. Revise el registro del servidor.");
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
