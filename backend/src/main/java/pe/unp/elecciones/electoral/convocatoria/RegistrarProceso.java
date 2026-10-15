package pe.unp.elecciones.electoral.convocatoria;

import java.sql.Types;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.convocatoria.ConvocatoriaDto.DatosProceso;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS01 · Control «RegistrarProceso» del diagrama de colaboración.
 *
 * <pre>
 *  PantallaConvocatoria --2: guardarProceso(datos)--> RegistrarProceso
 *  RegistrarProceso     --3: insertar(nombre, fechas, quorum)--> ProcesoElectoral
 *  RegistrarProceso     --4: mostrarConfirmacion()--> PantallaConvocatoria
 * </pre>
 *
 * También gestiona el cronograma mientras la convocatoria sigue en CREADO.
 * Sin @Transactional a propósito: los procedimientos abren su propia transacción (ver ProcedimientoDao).
 */
@Service
public class RegistrarProceso {

    private final ProcedimientoDao dao;
    private final ConvocatoriaConsulta consulta;

    public RegistrarProceso(ProcedimientoDao dao, ConvocatoriaConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 2: guardarProceso(datos) */
    public Map<String, Object> guardarProceso(DatosProceso datos, Integer idUsuario) {
        validarCronograma(datos);
        Map<String, Object> enCurso = consulta.procesoEnCurso(null);
        if (enCurso != null) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Ya existe un proceso electoral en curso (" + enCurso.get("nombre") + ", "
                            + enCurso.get("estado") + "). Debe cerrarse antes de convocar uno nuevo.");
        }
        Integer idProceso = insertar(datos, idUsuario);
        return mostrarConfirmacion(idProceso, "Proceso electoral registrado. Ahora agregue los cargos a elegir.");
    }

    /** Modifica el cronograma (fechas, nombre y quórum) de una convocatoria aún no publicada. */
    public Map<String, Object> actualizarCronograma(Integer idProceso, DatosProceso datos, Integer idUsuario) {
        Map<String, Object> proceso = consulta.proceso(idProceso);
        if (!"CREADO".equals(proceso.get("estado"))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "La convocatoria ya fue publicada (estado " + proceso.get("estado")
                            + "); su cronograma no se puede modificar.");
        }
        validarCronograma(datos);
        dao.ejecutar("""
                UPDATE proceso_electoral
                   SET nombre = ?, fecha_convocatoria = ?, fecha_limite_inscripcion = ?,
                       fecha_inicio = ?, fecha_fin = ?, quorum_minimo = ?
                 WHERE id_proceso = ? AND estado = 'CREADO'
                """, datos.nombre().trim(), datos.fechaConvocatoria(), datos.fechaLimiteInscripcion(),
                datos.fechaInicio(), datos.fechaFin(), datos.quorumMinimo(), idProceso);

        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("fecha_convocatoria", datos.fechaConvocatoria());
        detalle.put("fecha_limite_inscripcion", datos.fechaLimiteInscripcion());
        detalle.put("fecha_inicio", datos.fechaInicio());
        detalle.put("fecha_fin", datos.fechaFin());
        detalle.put("quorum_minimo", datos.quorumMinimo());
        consulta.auditar(idUsuario, idProceso, "ACTUALIZAR_CRONOGRAMA", detalle);
        return mostrarConfirmacion(idProceso, "Cronograma actualizado.");
    }

    /** 3: insertar(nombre, fechas, quorum) sobre ProcesoElectoral (sp_crear_proceso, deja el estado en CREADO). */
    private Integer insertar(DatosProceso datos, Integer idUsuario) {
        ProcedimientoDao.Resultado resultado = dao.llamar("sp_crear_proceso", new int[] {Types.INTEGER},
                datos.nombre().trim(), datos.fechaInicio(), datos.fechaFin(), datos.quorumMinimo(),
                datos.fechaConvocatoria(), datos.fechaLimiteInscripcion(), idUsuario);
        Object id = resultado.salidas()[0];
        if (!(id instanceof Number numero)) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR,
                    "No se obtuvo el identificador del proceso registrado.");
        }
        return numero.intValue();
    }

    /** 4: mostrarConfirmacion() */
    private Map<String, Object> mostrarConfirmacion(Integer idProceso, String mensaje) {
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", mensaje);
        respuesta.putAll(consulta.detalle(idProceso));
        return respuesta;
    }

    /**
     * Reglas del cronograma:
     * convocatoria &lt; límite de inscripción &lt; inicio del sufragio &lt; fin del sufragio,
     * el sufragio debe ser futuro y la convocatoria debe estar entre 30 y 45 días antes (RN02).
     */
    static void validarCronograma(DatosProceso datos) {
        LocalDateTime ahora = LocalDateTime.now();
        if (datos.nombre() == null || datos.nombre().isBlank()) {
            throw badRequest("El nombre del proceso es obligatorio.");
        }
        if (!datos.fechaInicio().isAfter(ahora)) {
            throw badRequest("El inicio del sufragio debe ser una fecha y hora futura.");
        }
        if (!datos.fechaFin().isAfter(datos.fechaInicio())) {
            throw badRequest("El fin del sufragio debe ser posterior a su inicio.");
        }
        if (!datos.fechaFin().toLocalDate().equals(datos.fechaInicio().toLocalDate())) {
            throw badRequest("El sufragio se realiza en una sola jornada: inicio y fin deben ser el mismo día.");
        }
        if (!datos.fechaLimiteInscripcion().isAfter(datos.fechaConvocatoria().atStartOfDay())) {
            throw badRequest("La fecha límite de inscripción debe ser posterior a la convocatoria.");
        }
        if (!datos.fechaLimiteInscripcion().isBefore(datos.fechaInicio())) {
            throw badRequest("La fecha límite de inscripción debe ser anterior al inicio del sufragio.");
        }
        LocalDate diaSufragio = datos.fechaInicio().toLocalDate();
        long dias = ChronoUnit.DAYS.between(datos.fechaConvocatoria(), diaSufragio);
        if (dias < ConvocatoriaConsulta.DIAS_MINIMOS || dias > ConvocatoriaConsulta.DIAS_MAXIMOS) {
            throw badRequest("RN02: la convocatoria debe publicarse entre " + ConvocatoriaConsulta.DIAS_MINIMOS
                    + " y " + ConvocatoriaConsulta.DIAS_MAXIMOS + " días naturales antes del sufragio "
                    + "(actualmente hay " + dias + " días).");
        }
    }

    private static ResponseStatusException badRequest(String mensaje) {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, mensaje);
    }
}
