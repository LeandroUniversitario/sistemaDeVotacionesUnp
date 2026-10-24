package pe.unp.elecciones.electoral.nulidades;

import java.sql.Types;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS15 · «ConfigurarSegundaVuelta» (control). Mensajes 10 a 15 del diagrama de colaboración:
 *
 *   10 [sin minimo legal] convocarSegundaVuelta(id_proceso, fechas) → sp_convocar_segunda_vuelta (RN33, 15 días)
 *   11 crearSegundaVuelta(id_proceso, fechas)    → sp_crear_segunda_vuelta
 *   12 insertar('SEGUNDA_VUELTA', id_proceso_padre) · 13 copiarDosMasVotadas(id_cargo) · 14 copiarPadron(id_proceso_nuevo)
 *   15 mostrarSegundaVuelta()                    → v_segunda_vuelta_procesos
 *
 * <p>Si dos o más listas empatan por un cupo, o empatan en la propia segunda vuelta, el Pleno lo
 * dirime por sorteo verificable (sp_dirimir_empate).
 */
@Service
public class ConfigurarSegundaVuelta {

    private final ProcedimientoDao dao;
    private final NulidadesConsulta consulta;

    public ConfigurarSegundaVuelta(ProcedimientoDao dao, NulidadesConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 10-15 convocarSegundaVuelta(id_proceso, fechas). */
    public Map<String, Object> convocar(Integer idProceso, NulidadesDto.SegundaVuelta datos, Usuario usuario) {
        consulta.proceso(idProceso);
        if (!datos.fechaFin().isAfter(datos.fechaInicio())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La fecha de fin debe ser posterior a la de inicio.");
        }
        ProcedimientoDao.Resultado r = dao.llamar("sp_convocar_segunda_vuelta", new int[] {Types.INTEGER}, idProceso,
                datos.fechaInicio(), datos.fechaFin(), usuario.getId());
        if (!(r.salidas()[0] instanceof Number nuevo)) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "No se obtuvo el proceso de segunda vuelta.");
        }
        Map<String, Object> respuesta = consulta.respuesta("Segunda vuelta configurada (proceso N.º " + nuevo.intValue()
                + "): se copiaron las listas finalistas con sus candidatos y el padrón. Continúe su preparación en "
                + "Convocatoria y cronograma.", idProceso, usuario);
        respuesta.put("idProcesoNuevo", nuevo.intValue());
        return respuesta;
    }

    /** Sorteo del Pleno: pase a la segunda vuelta o empate en ella. */
    public Map<String, Object> dirimir(Integer idCargo, NulidadesDto.Dirimencia datos, Usuario usuario) {
        Map<String, Object> cargo = consulta.cargo(idCargo);
        ProcedimientoDao.Resultado r = dao.llamar("sp_dirimir_empate", ProcedimientoDao.SIN_SALIDA, idCargo, usuario.getId(),
                datos.semilla().trim(), datos.numeroResolucion().trim(), datos.miembrosPleno(),
                NulidadesConsulta.vacioANulo(datos.fundamento()));
        if (r.filas().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "El procedimiento no devolvió resultados.");
        }
        Map<String, Object> fila = r.filas().get(0);
        String mensaje = "Sorteo registrado (" + datos.numeroResolucion().trim() + "). " + cargo.get("cargo") + ": "
                + ("PASE_A_SEGUNDA_VUELTA".equals(NulidadesConsulta.texto(fila.get("motivo")))
                        ? "pasa(n) a la segunda vuelta " + fila.get("listas") + ". Ya puede convocarla."
                        : "queda elegida " + fila.get("listas") + ". Ya puede proclamar en Cómputo y proclamación.");
        Map<String, Object> respuesta = consulta.respuesta(mensaje, NulidadesConsulta.numero(cargo.get("idProceso")), usuario);
        respuesta.put("sorteo", fila);
        return respuesta;
    }
}
