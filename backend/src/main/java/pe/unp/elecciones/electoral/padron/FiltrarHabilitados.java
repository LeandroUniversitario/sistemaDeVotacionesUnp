package pe.unp.elecciones.electoral.padron;

import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import pe.unp.elecciones.electoral.service.Bitacora;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS02 · Control «FiltrarHabilitados» del diagrama de colaboración.
 *
 * <pre>
 *  PantallaPadron      --6: procesarReglas()--> FiltrarHabilitados
 *  FiltrarHabilitados  --7: actualizarHabilitacion(estado)--> docente
 *  FiltrarHabilitados  --8: mostrarListaDepurada()--> PantallaPadron
 * </pre>
 *
 * Reglas (PadronConsulta.MOTIVO_SQL):
 *  - RN03: solo votan docentes en estado ACTIVO (fuera licencia, suspendidos e inactivos).
 *  - RN05: el elector se identifica con DNI de 8 dígitos.
 *  - Registro completo: nombres, apellidos y dedicación.
 */
@Service
public class FiltrarHabilitados {

    private final ProcedimientoDao dao;
    private final PadronConsulta consulta;
    private final Bitacora bitacora;

    public FiltrarHabilitados(ProcedimientoDao dao, PadronConsulta consulta, Bitacora bitacora) {
        this.dao = dao;
        this.consulta = consulta;
        this.bitacora = bitacora;
    }

    /** 6: procesarReglas() — evalúa a cada docente y actualiza su habilitación. */
    public Map<String, Object> procesarReglas(Integer idUsuario) {
        int habilitar = dao.entero("SELECT COUNT(*) FROM docente d WHERE d.habilitado_para_votar = 0 AND ("
                + PadronConsulta.MOTIVO_SQL + ") IS NULL");
        int inhabilitar = dao.entero("SELECT COUNT(*) FROM docente d WHERE d.habilitado_para_votar = 1 AND ("
                + PadronConsulta.MOTIVO_SQL + ") IS NOT NULL");

        actualizarHabilitacion();

        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("habilitados_nuevos", habilitar);
        detalle.put("inhabilitados_nuevos", inhabilitar);
        bitacora.registrar(idUsuario, null, "DEPURAR_PADRON", detalle);

        Map<String, Object> respuesta = mostrarListaDepurada();
        respuesta.put("cambios", Map.of("habilitados", habilitar, "inhabilitados", inhabilitar));
        respuesta.put("mensaje", "Padrón depurado: " + habilitar + " docentes rehabilitados y "
                + inhabilitar + " inhabilitados en esta depuración.");
        return respuesta;
    }

    /** 7: actualizarHabilitacion(estado) sobre docente. */
    private void actualizarHabilitacion() {
        dao.ejecutar("UPDATE docente d SET d.habilitado_para_votar = IF(("
                + PadronConsulta.MOTIVO_SQL + ") IS NULL, 1, 0)");
    }

    /** 8: mostrarListaDepurada() — también se usa al abrir la pantalla. */
    public Map<String, Object> mostrarListaDepurada() {
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("resumen", consulta.resumenDocentes());
        respuesta.put("motivos", consulta.motivosInhabilitacion());
        respuesta.put("docentes", consulta.listaDepurada());
        return respuesta;
    }
}
