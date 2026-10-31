package pe.unp.elecciones.electoral.sorteo;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS06 · Control «GrabarMiembrosMesa» del diagrama de colaboración.
 *
 * <pre>
 *  EjecutarSorteo     --8: guardarResultados(lista_sorteados)--> GrabarMiembrosMesa
 *  GrabarMiembrosMesa --9: actualizarSemilla(semilla)--> MesaElectoral
 *  GrabarMiembrosMesa --10: insertar(id_docente, rol, titular)--> MiembroMesa
 *  GrabarMiembrosMesa --11: registrarAuditoria(accion)--> LogAuditoria
 *  GrabarMiembrosMesa --12: confirmarAsignacion()--> PantallaSorteoMesa
 * </pre>
 *
 * Los pasos 9, 10 y 11 los ejecuta sp_sortear_todas_las_mesas en una sola transacción
 * (trg_miembro_mesa_bi vuelve a validar RN20). Después se compara lo grabado con la
 * lista calculada por EjecutarSorteo: deben coincidir uno a uno.
 */
@Service
public class GrabarMiembrosMesa {

    private final ProcedimientoDao dao;
    private final SorteoConsulta consulta;

    public GrabarMiembrosMesa(ProcedimientoDao dao, SorteoConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 8: guardarResultados(lista_sorteados); el usuario queda en la bitácora (11: registrarAuditoria). */
    public Map<String, Object> guardarResultados(Integer idProceso, String semillaBase,
            List<Map<String, Object>> listaSorteados, Integer idUsuario) {
        dao.llamar("sp_sortear_todas_las_mesas", ProcedimientoDao.SIN_SALIDA, idProceso, semillaBase, idUsuario);
        // Elevar automáticamente la cuenta de los docentes sorteados a MIEMBRO_MESA
        dao.ejecutar("""
            UPDATE usuario u
              JOIN miembro_mesa mm ON mm.id_docente = u.id_docente
              JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
               SET u.rol = 'MIEMBRO_MESA'
             WHERE m.id_proceso = ? AND u.rol = 'DOCENTE'
            """, idProceso);
        return confirmarAsignacion(idProceso, semillaBase, listaSorteados);
    }

    /** 12: confirmarAsignacion() — devuelve los miembros grabados y si coinciden con el cálculo. */
    @SuppressWarnings("unchecked")
    private Map<String, Object> confirmarAsignacion(Integer idProceso, String semillaBase,
            List<Map<String, Object>> listaSorteados) {
        List<Map<String, Object>> grabados = consulta.miembros(idProceso);
        boolean coincide = true;
        int mesas = 0;
        for (Map<String, Object> mesa : listaSorteados) {
            mesas++;
            for (Map<String, Object> esperado : (List<Map<String, Object>>) mesa.get("miembros")) {
                boolean encontrado = grabados.stream().anyMatch(g -> Objects.equals(g.get("idMesa"), mesa.get("idMesa"))
                        && Objects.equals(g.get("idDocente"), esperado.get("idDocente"))
                        && ((Number) g.get("ordenSorteo")).intValue() == ((Number) esperado.get("ordenSorteo")).intValue());
                coincide &= encontrado;
            }
        }
        if (mesas == 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "No había mesas pendientes de sorteo.");
        }
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Sorteo realizado: " + mesas + " mesa" + (mesas == 1 ? "" : "s") + " con "
                + (mesas * 6) + " miembros (3 titulares y 3 suplentes por mesa, RN19).");
        respuesta.put("semillaBase", semillaBase);
        respuesta.put("verificado", coincide);
        respuesta.put("mesas", consulta.mesas(idProceso));
        respuesta.put("miembros", grabados);
        return respuesta;
    }
}
