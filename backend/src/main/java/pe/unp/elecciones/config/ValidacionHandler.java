package pe.unp.elecciones.config;

import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * Devuelve al frontend el mensaje de la primera validación que falló (@NotBlank, @NotNull...)
 * en el campo "detail", en lugar del genérico "Invalid request content".
 */
@RestControllerAdvice
@Order(Ordered.HIGHEST_PRECEDENCE)
public class ValidacionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ProblemDetail validacion(MethodArgumentNotValidException exception) {
        FieldError error = exception.getBindingResult().getFieldError();
        String mensaje = error != null && error.getDefaultMessage() != null
                ? error.getDefaultMessage()
                : "Los datos enviados no son válidos.";
        return ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, mensaje);
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ProblemDetail formato(HttpMessageNotReadableException exception) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST,
                "Formato de datos inválido. Revise las fechas (aaaa-mm-dd / aaaa-mm-ddThh:mm:ss) y los números.");
    }
}
