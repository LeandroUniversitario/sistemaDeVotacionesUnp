package pe.unp.elecciones.electoral.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import pe.unp.elecciones.electoral.domain.CategoriaDocente;
import pe.unp.elecciones.electoral.domain.DocenteEstado;
import pe.unp.elecciones.electoral.domain.NivelJurisdiccion;
import pe.unp.elecciones.electoral.domain.ProcesoTipo;
import pe.unp.elecciones.electoral.domain.TachaEstado;

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

    public record ProcesoRequest(
            @NotBlank String nombre,
            @NotNull LocalDateTime fechaInicio,
            @NotNull LocalDateTime fechaFin,
            @NotNull ProcesoTipo tipo,
            Integer idProcesoPadre,
            @NotNull BigDecimal quorumMinimo) {
    }

    public record CargoRequest(
            @NotBlank String nombre,
            @NotNull NivelJurisdiccion nivelJurisdiccion,
            Integer idJurisdiccion) {
    }

    public record ListaRequest(
            @NotBlank String nombre,
            String simbolo) {
    }

    public record CategoriaRequest(@NotNull CategoriaDocente categoria) {
    }

    public record CandidatoRequest(
            @NotNull Integer idDocente,
            @NotBlank String rolEnLista) {
    }

    public record TachaRequest(
            @NotNull Integer idDocenteDenunciante,
            @NotNull Integer idCandidato,
            @NotBlank String motivo) {
    }

    public record ResolucionTachaRequest(@NotNull TachaEstado estado) {
    }
}
