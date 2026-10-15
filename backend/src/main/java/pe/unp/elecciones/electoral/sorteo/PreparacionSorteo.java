package pe.unp.elecciones.electoral.sorteo;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS06 · Operaciones que acompañan al sorteo de miembros de mesa:
 * <ul>
 *   <li>Conformar las mesas a partir del padrón (sp_crear_mesas): requisito previo del sorteo.</li>
 *   <li>Sortear el orden de las listas en la cédula de cada cargo (RN18, sp_sortear_orden_cedula).</li>
 * </ul>
 */
@Service
public class PreparacionSorteo {

    private final ProcedimientoDao dao;
    private final SorteoConsulta consulta;
    private final EjecutarSorteo ejecutarSorteo;

    public PreparacionSorteo(ProcedimientoDao dao, SorteoConsulta consulta, EjecutarSorteo ejecutarSorteo) {
        this.dao = dao;
        this.consulta = consulta;
        this.ejecutarSorteo = ejecutarSorteo;
    }

    /** Reparte el padrón en mesas de hasta N electores, en la ubicación indicada (RN08). */
    public Map<String, Object> conformarMesas(Integer idProceso, Integer electoresPorMesa, String ubicacion,
            Integer idUsuario) {
        Map<String, Object> proceso = consulta.proceso(idProceso);
        if (((Number) proceso.get("electoresPadron")).intValue() == 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "RN04: el proceso aún no tiene padrón aprobado (CUS02).");
        }
        dao.llamar("sp_crear_mesas", ProcedimientoDao.SIN_SALIDA, idProceso, electoresPorMesa,
                ubicacion == null || ubicacion.isBlank() ? null : ubicacion.trim(), idUsuario);
        List<Map<String, Object>> mesas = consulta.mesas(idProceso);
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Se conformaron " + mesas.size() + " mesa" + (mesas.size() == 1 ? "" : "s")
                + " de sufragio. Ya puede realizar el sorteo de sus miembros.");
        respuesta.put("mesas", mesas);
        return respuesta;
    }

    /** RN18: sortea el orden de las listas ADMITIDAS de un cargo en la cédula. */
    public Map<String, Object> sortearCedula(Integer idCargo, String semilla, Integer idUsuario) {
        List<Map<String, Object>> cargo = dao.consultar(
                "SELECT id_proceso, nombre FROM cargo_electoral WHERE id_cargo = ?", idCargo);
        if (cargo.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El cargo electoral no existe.");
        }
        int admitidas = dao.entero(
                "SELECT COUNT(*) FROM lista_electoral WHERE id_cargo = ? AND estado = 'ADMITIDA'", idCargo);
        if (admitidas == 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "RN18: el cargo no tiene listas ADMITIDAS; califique las listas antes de sortear la cédula.");
        }
        String usada = ejecutarSorteo.generarAleatoriedad(semilla);
        dao.llamar("sp_sortear_orden_cedula", ProcedimientoDao.SIN_SALIDA, idCargo, usada, idUsuario);

        Integer idProceso = ((Number) cargo.get(0).get("idProceso")).intValue();
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Orden de la cédula sorteado para " + cargo.get(0).get("nombre") + " ("
                + admitidas + " lista" + (admitidas == 1 ? "" : "s") + ").");
        respuesta.put("semilla", usada);
        respuesta.put("cargos", consulta.cedula(idProceso));
        return respuesta;
    }
}
