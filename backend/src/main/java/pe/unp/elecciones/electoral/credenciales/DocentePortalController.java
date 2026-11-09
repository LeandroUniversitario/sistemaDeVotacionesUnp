package pe.unp.elecciones.electoral.credenciales;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.auth.UsuarioActual;
import pe.unp.elecciones.electoral.inscripcion.InscripcionConsulta;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS07 - Portal del Docente: Mi Pase de Votacion QR.
 *
 * Rutas accesibles solo por DOCENTE (y MIEMBRO_MESA / PERSONERO para sus
 * propias credenciales):
 * GET /api/docente/mi-pase -> estado electoral del docente autenticado
 * GET /api/docente/mi-pase/historial -> historial de credenciales QR emitidas
 * POST /api/docente/mi-pase/{idProceso} -> genera la credencial QR del docente
 */
@RestController
@RequestMapping("/api/docente")
@PreAuthorize("hasAnyRole('DOCENTE', 'MIEMBRO_MESA', 'PERSONERO')")
public class DocentePortalController {

  private final UsuarioActual usuarioActual;
  private final ProcedimientoDao dao;
  private final GenerarTokenQR generarTokenQR;
  private final InscripcionConsulta inscripcionConsulta;

  public DocentePortalController(UsuarioActual usuarioActual,
      ProcedimientoDao dao,
      GenerarTokenQR generarTokenQR,
      InscripcionConsulta inscripcionConsulta) {
    this.usuarioActual = usuarioActual;
    this.dao = dao;
    this.generarTokenQR = generarTokenQR;
    this.inscripcionConsulta = inscripcionConsulta;
  }

  /**
   * CUS-DOCENTE: Lista todos los procesos con inscripción abierta/en votación
   * y sus fórmulas/listas inscritas. Solo lectura para DOCENTE.
   */
  @GetMapping("/listas-postulantes")
  public List<Map<String, Object>> listasPostulantes() {
    return inscripcionConsulta.procesos().stream()
        .filter(p -> {
          Object estado = p.get("estado");
          return "INSCRIPCION".equals(estado) || "VOTACION".equals(estado);
        })
        .toList();
  }

  /**
   * Detalle de fórmulas e integrantes de un proceso para docentes.
   */
  @GetMapping("/listas-postulantes/{idProceso}")
  public Map<String, Object> listasPostulantesPorProceso(@PathVariable Integer idProceso) {
    return inscripcionConsulta.detalle(idProceso);
  }

  /**
   * Estado electoral completo del docente autenticado:
   * datos personales, habilitacion, mesas asignadas y credenciales QR vigentes.
   */
  @GetMapping("/mi-pase")
  public Map<String, Object> miPase(Authentication authentication) {
    Integer idDocente = usuarioActual.idDocenteRequerido(authentication);
    return consultarEstadoElectoral(idDocente);
  }

  /**
   * Historial completo de credenciales QR del docente autenticado.
   */
  @GetMapping("/mi-pase/historial")
  public List<Map<String, Object>> historial(Authentication authentication) {
    Integer idDocente = usuarioActual.idDocenteRequerido(authentication);
    return dao.consultar("""
        SELECT cq.id_credencial, p.nombre AS proceso, cq.tipo, cq.fecha_emision,
               cq.fecha_expiracion, cq.usos, cq.ultimo_uso, cq.estado,
               CASE WHEN cq.estado = 'VIGENTE' AND cq.fecha_expiracion > NOW()
                    THEN TRUE ELSE FALSE END AS activa
          FROM credencial_qr cq
          JOIN proceso_electoral p ON p.id_proceso = cq.id_proceso
         WHERE cq.id_docente = ? AND cq.tipo = 'ELECTOR'
         ORDER BY cq.fecha_emision DESC
        """, idDocente);
  }

  /**
   * Genera la credencial QR del docente para un proceso.
   * Solo funciona si el docente esta en el padron habilitado.
   */
  @PostMapping("/mi-pase/{idProceso}")
  @ResponseStatus(HttpStatus.CREATED)
  public Map<String, Object> generarPase(
      @PathVariable Integer idProceso,
      Authentication authentication) {
    Integer idDocente = usuarioActual.idDocenteRequerido(authentication);
    Usuario usuario = usuarioActual.requerido(authentication);

    List<Map<String, Object>> padron = dao.consultar("""
        SELECT d.habilitado_para_votar
          FROM padron_electoral pe
          JOIN docente d ON d.id_docente = pe.id_docente
         WHERE pe.id_proceso = ? AND pe.id_docente = ?
         LIMIT 1
        """, idProceso, idDocente);

    if (padron.isEmpty()) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN,
          "No figura en el padron electoral de este proceso. Contacte al CEUNP.");
    }

    Object habilitado = padron.get(0).get("habilitadoParaVotar");
    if (habilitado == null) {
      habilitado = padron.get(0).get("habilitado_para_votar");
    }
    if (habilitado == null || habilitado.equals(0) || habilitado.equals(false)
        || "0".equals(habilitado.toString()) || "false".equalsIgnoreCase(habilitado.toString())) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN,
          "Su habilitacion para votar esta suspendida en este proceso. Consulte al CEUNP.");
    }

    return generarTokenQR.emitirPropia(idProceso, TipoCredencial.ELECTOR,
        idDocente, idDocente, usuario.getId());
  }

  /* ═══ Logica de consulta del estado electoral ═══ */

  private Map<String, Object> consultarEstadoElectoral(Integer idDocente) {
    List<Map<String, Object>> docRows = dao.consultar("""
        SELECT d.id_docente, d.dni, d.nombres, d.apellidos,
               d.categoria, d.dedicacion, d.estado,
               d.habilitado_para_votar,
               f.nombre AS facultad,
               dp.nombre AS departamento,
               CASE
                 WHEN d.estado != 'ACTIVO' THEN CONCAT('Estado: ', d.estado)
                 WHEN d.habilitado_para_votar = 0 THEN 'Inhabilitado por depuracion del padron'
                 ELSE NULL
               END AS motivo_inhabilitacion
          FROM docente d
          JOIN facultad f  ON f.id_facultad = d.id_facultad
          JOIN departamento dp ON dp.id_departamento = d.id_departamento
         WHERE d.id_docente = ?
        """, idDocente);

    if (docRows.isEmpty()) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Docente no encontrado.");
    }
    Map<String, Object> docente = new LinkedHashMap<>(docRows.get(0));

    List<Map<String, Object>> procesosConPadron = dao.consultar("""
        SELECT DISTINCT p.id_proceso, p.nombre AS proceso, p.estado AS estado_proceso,
               p.fecha_inicio, p.fecha_fin,
               m.numero_mesa,
               m.ubicacion AS local_votacion,
               NULL AS aula,
               (SELECT COUNT(*) FROM credencial_qr cq
                 WHERE cq.id_proceso = p.id_proceso
                   AND cq.id_docente = ?
                   AND cq.tipo = 'ELECTOR'
                   AND cq.estado = 'VIGENTE'
                   AND cq.fecha_expiracion > NOW()
               ) AS tiene_credencial_vigente,
               (SELECT cq2.id_credencial FROM credencial_qr cq2
                 WHERE cq2.id_proceso = p.id_proceso
                   AND cq2.id_docente = ?
                   AND cq2.tipo = 'ELECTOR'
                   AND cq2.estado = 'VIGENTE'
                 ORDER BY cq2.fecha_emision DESC LIMIT 1
               ) AS id_credencial_vigente,
               (SELECT cq3.codigo_qr FROM credencial_qr cq3
                 WHERE cq3.id_proceso = p.id_proceso
                   AND cq3.id_docente = ?
                   AND cq3.tipo = 'ELECTOR'
                   AND cq3.estado = 'VIGENTE'
                 ORDER BY cq3.fecha_emision DESC LIMIT 1
               ) AS codigo_qr_vigente,
               (SELECT cq4.fecha_emision FROM credencial_qr cq4
                 WHERE cq4.id_proceso = p.id_proceso
                   AND cq4.id_docente = ?
                   AND cq4.tipo = 'ELECTOR'
                   AND cq4.estado = 'VIGENTE'
                 ORDER BY cq4.fecha_emision DESC LIMIT 1
               ) AS fecha_emision_vigente,
               (SELECT cq5.fecha_expiracion FROM credencial_qr cq5
                 WHERE cq5.id_proceso = p.id_proceso
                   AND cq5.id_docente = ?
                   AND cq5.tipo = 'ELECTOR'
                   AND cq5.estado = 'VIGENTE'
                 ORDER BY cq5.fecha_emision DESC LIMIT 1
               ) AS fecha_expiracion_vigente,
               mm.rol AS es_miembro_mesa
          FROM padron_electoral pe
          JOIN proceso_electoral p ON p.id_proceso = pe.id_proceso
          LEFT JOIN mesa_electoral m ON m.id_mesa = pe.id_mesa
          LEFT JOIN miembro_mesa mm ON mm.id_docente = ? AND mm.id_mesa = m.id_mesa
         WHERE pe.id_docente = ?
           AND p.estado NOT IN ('ANULADO', 'FINALIZADO')
         ORDER BY p.fecha_inicio DESC
        """, idDocente, idDocente, idDocente, idDocente, idDocente, idDocente, idDocente);

    for (Map<String, Object> proc : procesosConPadron) {
      Object idCred = proc.get("idCredencialVigente");
      if (idCred == null)
        idCred = proc.get("id_credencial_vigente");
      Object qrCode = proc.get("codigoQrVigente");
      if (qrCode == null)
        qrCode = proc.get("codigo_qr_vigente");
      if (idCred != null && qrCode != null) {
        Map<String, Object> credVigente = new LinkedHashMap<>();
        credVigente.put("idCredencial", idCred);
        credVigente.put("qr", qrCode);
        credVigente.put("codigoQr", qrCode);
        credVigente.put("tipo", "ELECTOR");
        credVigente.put("titulo", "Pase de Votación");
        credVigente.put("dni", docente.get("dni"));
        credVigente.put("nombre", docente.get("nombres") + " " + docente.get("apellidos"));
        credVigente.put("categoria", docente.get("categoria"));
        credVigente.put("facultad", docente.get("facultad"));
        credVigente.put("funcion", "Elector");
        credVigente.put("numeroMesa",
            proc.get("numeroMesa") != null ? proc.get("numeroMesa") : proc.get("numero_mesa"));
        credVigente.put("ubicacion",
            proc.get("localVotacion") != null ? proc.get("localVotacion") : proc.get("local_votacion"));
        credVigente.put("fechaEmision", proc.get("fechaEmisionVigente") != null ? proc.get("fechaEmisionVigente")
            : proc.get("fecha_emision_vigente"));
        credVigente.put("fechaExpiracion",
            proc.get("fechaExpiracionVigente") != null ? proc.get("fechaExpiracionVigente")
                : proc.get("fecha_expiracion_vigente"));
        proc.put("credencialVigente", credVigente);
      }
    }

    docente.put("procesos", procesosConPadron);
    return docente;
  }
}