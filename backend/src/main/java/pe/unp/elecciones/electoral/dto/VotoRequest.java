package pe.unp.elecciones.electoral.dto;

public record VotoRequest(
    Integer procesoId,
    Integer cargoId,
    Integer listaElegidaId,
    String tipo // VALIDO, BLANCO, NULO
) {}
