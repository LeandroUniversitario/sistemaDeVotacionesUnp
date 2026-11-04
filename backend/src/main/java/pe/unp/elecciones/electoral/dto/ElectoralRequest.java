package pe.unp.elecciones.electoral.dto;


import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import pe.unp.elecciones.electoral.domain.CategoriaDocente;
import pe.unp.elecciones.electoral.domain.DocenteEstado;

/**
 * DTOs de entrada (Request) para los endpoints del módulo electoral.
 * Cada record representa los datos que llegan desde el cliente via HTTP.
 */
public final class ElectoralRequest {

    private ElectoralRequest() {}

    public record DocenteRequest(
            @NotBlank String dni,
            @NotBlank String nombres,
            @NotBlank String apellidos,
            @NotNull CategoriaDocente categoria,
            @NotBlank String dedicacion,
            @NotNull Integer idFacultad,
            @NotNull Integer idDepartamento) {
    }

    /** Actualización parcial de docente: todos los campos son opcionales. */
    public record DocenteUpdateRequest(
            String nombres,
            String apellidos,
            CategoriaDocente categoria,
            String dedicacion,
            DocenteEstado estado,
            Integer idFacultad,
            Integer idDepartamento) {
    }
}
