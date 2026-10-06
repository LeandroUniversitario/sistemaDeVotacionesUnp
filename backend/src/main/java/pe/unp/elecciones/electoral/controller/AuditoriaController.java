package pe.unp.elecciones.electoral.controller;

import org.springframework.data.domain.Page;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import pe.unp.elecciones.electoral.domain.LogAuditoria;
import pe.unp.elecciones.electoral.service.AuditoriaService;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/auditoria")
@PreAuthorize("hasRole('ADMIN')")
public class AuditoriaController {

    private final AuditoriaService auditoriaService;

    public AuditoriaController(AuditoriaService auditoriaService) {
        this.auditoriaService = auditoriaService;
    }

    /**
     * Lista el log de auditoría con filtros opcionales — SOLO LECTURA.
     * No existen endpoints PUT, PATCH ni DELETE sobre este recurso.
     * Devuelve un PageResponse estable para serialización JSON predecible.
     */
    @GetMapping
    public PageResponse<LogAuditoria> listar(
            @RequestParam(required = false) String accion,
            @RequestParam(required = false) Integer idUsuario,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime desde,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime hasta,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "25") int size) {
        Page<LogAuditoria> result = auditoriaService.buscar(accion, idUsuario, desde, hasta, page, size);
        return new PageResponse<>(
                result.getContent(),
                result.getTotalElements(),
                result.getTotalPages(),
                result.getNumber(),
                result.getSize()
        );
    }

    /** Tipos de acción disponibles para el filtro en la UI */
    @GetMapping("/acciones")
    public String[] tiposAccion() {
        return new String[]{
            "LOGIN_OK", "LOGIN_FAIL", "CREAR_PROCESO", "IMPORTAR_PADRON",
            "APROBAR_PADRON", "CREAR_CANDIDATURA", "RESOLVER_TACHA",
            "EJECUTAR_SORTEO", "EMISION_VOTO", "CAMBIO_PASSWORD",
            "CREAR_USUARIO", "INACTIVAR_USUARIO", "CAMBIO_PARAMETRO"
        };
    }

    /** DTO de paginación con estructura JSON estable */
    public record PageResponse<T>(
            List<T> content,
            long totalElements,
            int totalPages,
            int number,
            int size
    ) {}
}
