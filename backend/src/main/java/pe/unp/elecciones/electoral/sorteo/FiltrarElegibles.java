package pe.unp.elecciones.electoral.sorteo;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;

import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS06 · Control «FiltrarElegibles» del diagrama de colaboración.
 *
 * <pre>
 *  PantallaSorteoMesa --2: obtenerUniverso()--> FiltrarElegibles
 *  FiltrarElegibles   --3: consultarHabilitados()--> docente
 *  FiltrarElegibles   --4: excluirImpedidos()--> CargoExcluidoSorteo
 *  FiltrarElegibles   --5: mostrarElegibles()--> PantallaSorteoMesa
 * </pre>
 *
 * El universo es el padrón habilitado del proceso. RN20 excluye a las autoridades
 * vigentes (cargos marcados en CargoExcluidoSorteo), a candidatos y a personeros.
 * Es la misma regla de la vista v_elegibles_sorteo que usa sp_sortear_miembros_mesa.
 */
@Service
public class FiltrarElegibles {

    private final ProcedimientoDao dao;
    private final SorteoConsulta consulta;

    public FiltrarElegibles(ProcedimientoDao dao, SorteoConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 2: obtenerUniverso() */
    public Map<String, Object> obtenerUniverso(Integer idProceso) {
        Map<String, Object> proceso = consulta.proceso(idProceso);
        int habilitados = consultarHabilitados(idProceso);
        List<Map<String, Object>> impedidos = excluirImpedidos(idProceso);
        return mostrarElegibles(proceso, habilitados, impedidos);
    }

    /** 3: consultarHabilitados() — docentes del padrón aprobado (CUS02). */
    private int consultarHabilitados(Integer idProceso) {
        return dao.entero("""
                SELECT COUNT(DISTINCT pe.id_docente) FROM padron_electoral pe
                 WHERE pe.id_proceso = ? AND pe.habilitado_para_votar = 1
                """, idProceso);
    }

    /** 4: excluirImpedidos() — RN20, con el motivo de cada exclusión. */
    private List<Map<String, Object>> excluirImpedidos(Integer idProceso) {
        return dao.consultar("""
                SELECT x.id_docente, x.dni, x.docente, x.numero_mesa, x.motivo
                  FROM (
                    SELECT d.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS docente,
                           MAX(m.numero_mesa) AS numero_mesa,
                           CASE
                             WHEN d.estado <> 'ACTIVO' THEN CONCAT('Docente en estado ', d.estado)
                             WHEN fn_tiene_cargo_excluyente(d.id_docente) THEN CONCAT('RN20: autoridad vigente (',
                                  (SELECT cc.nombre_cargo FROM cargo_admin ca
                                     JOIN catalogo_cargo cc ON cc.id_catalogo_cargo = ca.id_catalogo_cargo
                                     JOIN cargo_excluido_sorteo ce ON ce.id_catalogo_cargo = ca.id_catalogo_cargo AND ce.activo = 1
                                    WHERE ca.id_docente = d.id_docente AND ca.vigente = 1 LIMIT 1), ')')
                             WHEN EXISTS (SELECT 1 FROM candidato ca
                                            JOIN lista_electoral l ON l.id_lista = ca.id_lista
                                            JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                                           WHERE ca.id_docente = d.id_docente AND c.id_proceso = ?
                                             AND ca.estado_validacion <> 'EXCLUIDO') THEN 'RN20: es candidato'
                             WHEN EXISTS (SELECT 1 FROM personero p
                                            JOIN lista_electoral l ON l.id_lista = p.id_lista
                                            JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                                           WHERE p.id_docente = d.id_docente AND c.id_proceso = ?
                                             AND p.estado_acreditacion <> 'REVOCADO') THEN 'RN20: es personero'
                             ELSE NULL
                           END AS motivo
                      FROM padron_electoral pe
                      JOIN docente d ON d.id_docente = pe.id_docente
                      LEFT JOIN mesa_electoral m ON m.id_mesa = pe.id_mesa
                     WHERE pe.id_proceso = ? AND pe.habilitado_para_votar = 1
                     GROUP BY d.id_docente, d.dni, d.apellidos, d.nombres, d.estado
                  ) x
                 WHERE x.motivo IS NOT NULL
                 ORDER BY x.motivo, x.docente
                """, idProceso, idProceso, idProceso);
    }

    /** 5: mostrarElegibles() */
    private Map<String, Object> mostrarElegibles(Map<String, Object> proceso, int habilitados,
            List<Map<String, Object>> impedidos) {
        int yaMiembros = dao.entero("""
                SELECT COUNT(*) FROM miembro_mesa mm JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
                 WHERE m.id_proceso = ?
                """, proceso.get("id"));
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("habilitados", habilitados);
        respuesta.put("impedidos", impedidos);
        respuesta.put("yaMiembros", yaMiembros);
        respuesta.put("elegibles", Math.max(0, habilitados - impedidos.size() - yaMiembros));
        respuesta.put("mesas", consulta.mesas(((Number) proceso.get("id")).intValue()));
        return respuesta;
    }
}
