package pe.unp.elecciones.electoral.personeros;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS05 · Control «ValidarPersonero» del diagrama de colaboración.
 *
 * <pre>
 *  PantallaPersoneros --2: verificarRequisitos(dni)--> ValidarPersonero
 *  ValidarPersonero   --3: consultarDocente(dni)--> docente
 *  ValidarPersonero   --4: mostrarDatosPersonero(docente)--> PantallaPersoneros
 * </pre>
 *
 * Requisitos (FALLA impide acreditar):
 *  - la lista sigue en carrera (INSCRITA o ADMITIDA) y el proceso está en INSCRIPCION o VOTACION;
 *  - docente ACTIVO del padrón;
 *  - RN21: no es candidato del proceso ni autoridad vigente (los repite trg_personero_bi);
 *  - RN20: no es miembro de mesa del proceso;
 *  - no es ya personero de esta u otra lista del proceso.
 * Además informa los cupos libres de la lista (GENERAL, ALTERNO y mesas).
 */
@Service
public class ValidarPersonero {

    static final String OK = "OK";
    static final String FALLA = "FALLA";

    private static final String SELECT_DOCENTE = """
            SELECT d.id_docente AS id, d.dni, d.nombres, d.apellidos, d.categoria, d.dedicacion, d.estado,
                   d.habilitado_para_votar AS habilitado, f.nombre AS facultad, dp.nombre AS departamento
              FROM docente d
              JOIN facultad f ON f.id_facultad = d.id_facultad
              JOIN departamento dp ON dp.id_departamento = d.id_departamento
            """;

    private final ProcedimientoDao dao;
    private final PersonerosConsulta consulta;

    public ValidarPersonero(ProcedimientoDao dao, PersonerosConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 2: verificarRequisitos(dni) */
    public Map<String, Object> verificarRequisitos(Integer idLista, String dni) {
        return evaluar(idLista, consultarDocente(dni));
    }

    /** Mismo análisis a partir del id (lo usa AcreditarPersonero antes de grabar). */
    public Map<String, Object> verificarRequisitos(Integer idLista, Integer idDocente) {
        List<Map<String, Object>> filas = dao.consultar(SELECT_DOCENTE + " WHERE d.id_docente = ?", idDocente);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El docente no existe.");
        }
        return evaluar(idLista, filas.get(0));
    }

    /** 3: consultarDocente(dni) */
    private Map<String, Object> consultarDocente(String dni) {
        String limpio = dni == null ? "" : dni.trim();
        if (!limpio.matches("\\d{1,8}")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "RN05: ingrese un DNI válido (8 dígitos).");
        }
        String ocho = String.format("%08d", Long.parseLong(limpio));
        List<Map<String, Object>> filas = dao.consultar(SELECT_DOCENTE + " WHERE d.dni = ?", ocho);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                    "No hay ningún docente registrado con DNI " + ocho + ".");
        }
        return filas.get(0);
    }

    private Map<String, Object> evaluar(Integer idLista, Map<String, Object> docente) {
        Map<String, Object> lista = consulta.lista(idLista);
        Integer idProceso = ((Number) lista.get("idProceso")).intValue();
        Integer idDocente = ((Number) docente.get("id")).intValue();
        List<Map<String, Object>> requisitos = new ArrayList<>();

        boolean procesoOk = PersonerosConsulta.ESTADOS_ACREDITACION.contains(String.valueOf(lista.get("estadoProceso")));
        boolean listaOk = PersonerosConsulta.LISTAS_HABILES.contains(String.valueOf(lista.get("estado")));
        requisitos.add(req("LISTA", !procesoOk
                ? "El proceso está en " + lista.get("estadoProceso") + ": ya no se acreditan personeros."
                : listaOk ? "La lista «" + lista.get("nombre") + "» sigue en carrera (" + lista.get("estado") + ")."
                : "La lista está " + lista.get("estado") + " y no puede acreditar personeros.",
                procesoOk && listaOk ? OK : FALLA));

        boolean activo = "ACTIVO".equals(docente.get("estado"));
        requisitos.add(req("ACTIVO", activo
                ? "Docente en estado ACTIVO."
                : "El docente está en estado " + docente.get("estado") + ".", activo ? OK : FALLA));

        boolean candidato = dao.entero("""
                SELECT COUNT(*) FROM candidato ca
                  JOIN lista_electoral l ON l.id_lista = ca.id_lista
                  JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                 WHERE ca.id_docente = ? AND c.id_proceso = ? AND ca.estado_validacion <> 'EXCLUIDO'
                """, idDocente, idProceso) > 0;
        requisitos.add(req("RN21_CANDIDATO", candidato
                ? "RN21: es candidato en este proceso y no puede ser personero."
                : "RN21: no es candidato en este proceso.", candidato ? FALLA : OK));

        List<Map<String, Object>> autoridad = dao.consultar("""
                SELECT cc.nombre_cargo FROM cargo_admin ca
                  JOIN catalogo_cargo cc ON cc.id_catalogo_cargo = ca.id_catalogo_cargo
                  JOIN cargo_excluido_sorteo ce ON ce.id_catalogo_cargo = ca.id_catalogo_cargo AND ce.activo = 1
                 WHERE ca.id_docente = ? AND ca.vigente = 1 AND ca.fecha_inicio <= CURDATE()
                   AND (ca.fecha_fin IS NULL OR ca.fecha_fin >= CURDATE())
                 LIMIT 1
                """, idDocente);
        requisitos.add(req("RN21_AUTORIDAD", autoridad.isEmpty()
                ? "RN21: no ejerce un cargo de autoridad vigente."
                : "RN21: es autoridad vigente (" + autoridad.get(0).get("nombreCargo") + ") y no puede ser personero.",
                autoridad.isEmpty() ? OK : FALLA));

        boolean miembroMesa = dao.entero("""
                SELECT COUNT(*) FROM miembro_mesa mm JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
                 WHERE mm.id_docente = ? AND m.id_proceso = ?
                """, idDocente, idProceso) > 0;
        requisitos.add(req("RN20", miembroMesa
                ? "RN20: es miembro de mesa en este proceso y no puede ser personero."
                : "RN20: no es miembro de mesa en este proceso.", miembroMesa ? FALLA : OK));

        List<Map<String, Object>> yaPersonero = dao.consultar("""
                SELECT l.nombre, pe.tipo, pe.id_lista FROM personero pe
                  JOIN lista_electoral l ON l.id_lista = pe.id_lista
                  JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                 WHERE pe.id_docente = ? AND c.id_proceso = ? AND pe.estado_acreditacion <> 'REVOCADO'
                 LIMIT 1
                """, idDocente, idProceso);
        String unico;
        if (yaPersonero.isEmpty()) {
            unico = "No es personero de ninguna lista del proceso.";
        } else if (idLista.equals(yaPersonero.get(0).get("idLista"))) {
            unico = "Ya es personero " + yaPersonero.get(0).get("tipo") + " de esta lista.";
        } else {
            unico = "Ya es personero de la lista «" + yaPersonero.get(0).get("nombre") + "»: representa a una sola lista.";
        }
        requisitos.add(req("UNICO", unico, yaPersonero.isEmpty() ? OK : FALLA));

        return mostrarDatosPersonero(docente, requisitos, consulta.cupos(idLista, idProceso));
    }

    /** 4: mostrarDatosPersonero(docente) */
    private Map<String, Object> mostrarDatosPersonero(Map<String, Object> docente,
            List<Map<String, Object>> requisitos, Map<String, Object> cupos) {
        Map<String, Object> datos = new LinkedHashMap<>();
        datos.put("id", docente.get("id"));
        datos.put("dni", docente.get("dni"));
        datos.put("nombre", docente.get("apellidos") + ", " + docente.get("nombres"));
        datos.put("categoria", docente.get("categoria"));
        datos.put("dedicacion", docente.get("dedicacion"));
        datos.put("estado", docente.get("estado"));
        datos.put("facultad", docente.get("facultad"));
        datos.put("departamento", docente.get("departamento"));

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("docente", datos);
        respuesta.put("requisitos", requisitos);
        respuesta.put("apto", requisitos.stream().noneMatch(r -> FALLA.equals(r.get("estado"))));
        respuesta.put("cupos", cupos);
        return respuesta;
    }

    private static Map<String, Object> req(String codigo, String descripcion, String estado) {
        Map<String, Object> fila = new LinkedHashMap<>();
        fila.put("codigo", codigo);
        fila.put("descripcion", descripcion);
        fila.put("estado", estado);
        return fila;
    }
}
