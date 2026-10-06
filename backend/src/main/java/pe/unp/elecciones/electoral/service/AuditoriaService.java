package pe.unp.elecciones.electoral.service;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import pe.unp.elecciones.electoral.domain.LogAuditoria;
import pe.unp.elecciones.electoral.repository.LogAuditoriaRepository;

import java.time.LocalDateTime;

@Service
public class AuditoriaService {

    private final LogAuditoriaRepository repo;

    public AuditoriaService(LogAuditoriaRepository repo) {
        this.repo = repo;
    }

    /**
     * Registra un evento de auditoría. Método central — INSERT ONLY.
     * NUNCA exponer update/delete sobre este registro.
     */
    @Transactional
    public void registrar(Integer idUsuario, Integer idProceso, String accion,
                          String ipOrigen, String userAgent, String detalleJson) {
        // VALIDACION CRÍTICA: nunca registrar votos individuales con candidato elegido
        if (accion != null && accion.toUpperCase().contains("VOTO") && detalleJson != null
                && (detalleJson.contains("id_lista_elegida") || detalleJson.contains("tipo_voto"))) {
            // Sustituir por evento técnico sin detalle del voto
            detalleJson = "{\"evento\":\"EMISION_VOTO\",\"privacidad\":\"dato_omitido\"}";
        }
        repo.save(new LogAuditoria(idUsuario, idProceso, accion, ipOrigen, userAgent, detalleJson));
    }

    /**
     * Consulta paginada con filtros — solo lectura.
     */
    @Transactional(readOnly = true)
    public Page<LogAuditoria> buscar(String accion, Integer idUsuario,
                                      LocalDateTime desde, LocalDateTime hasta,
                                      int page, int size) {
        PageRequest pageable = PageRequest.of(page, size, Sort.by("fechaHora").descending());
        return repo.buscarFiltrado(accion, idUsuario, desde, hasta, pageable);
    }
}
