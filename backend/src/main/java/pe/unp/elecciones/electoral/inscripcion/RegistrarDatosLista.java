package pe.unp.elecciones.electoral.inscripcion;

import java.sql.Types;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.inscripcion.InscripcionDto.DatosLista;
import pe.unp.elecciones.electoral.service.Bitacora;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS03 · Control «RegistrarDatosLista» del diagrama de colaboración.
 *
 * <pre>
 *  PantallaInscripcion --2: guardarLista(datos)--> RegistrarDatosLista
 *  RegistrarDatosLista --3: insertarLista(nombre, cargo)--> ListaElectoral
 *  RegistrarDatosLista --4: mostrarConfirmacionLista()--> PantallaInscripcion
 * </pre>
 *
 * sp_inscribir_lista exige el proceso en INSCRIPCION y dentro del plazo (RN13) y deja la
 * lista en estado INSCRITA hasta que el CEUNP la califique.
 */
@Service
public class RegistrarDatosLista {

    private final ProcedimientoDao dao;
    private final InscripcionConsulta consulta;
    private final Bitacora bitacora;

    public RegistrarDatosLista(ProcedimientoDao dao, InscripcionConsulta consulta, Bitacora bitacora) {
        this.dao = dao;
        this.consulta = consulta;
        this.bitacora = bitacora;
    }

    /** 2: guardarLista(datos) */
    public Map<String, Object> guardarLista(DatosLista datos, Integer idUsuario) {
        List<Map<String, Object>> cargo = dao.consultar(
                "SELECT id_proceso, nombre FROM cargo_electoral WHERE id_cargo = ?", datos.idCargo());
        if (cargo.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El cargo electoral no existe.");
        }
        String nombre = datos.nombre().trim().replaceAll("\\s+", " ");
        if (dao.entero("SELECT COUNT(*) FROM lista_electoral WHERE id_cargo = ? AND LOWER(nombre) = LOWER(?)",
                datos.idCargo(), nombre) > 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Ya existe una lista llamada «" + nombre + "» para " + cargo.get(0).get("nombre") + ".");
        }
        String simbolo = vacioANull(datos.simbolo());
        if (simbolo != null && dao.entero(
                "SELECT COUNT(*) FROM lista_electoral WHERE id_cargo = ? AND LOWER(simbolo) = LOWER(?)",
                datos.idCargo(), simbolo) > 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "RN17: el símbolo «" + simbolo + "» ya lo usa otra lista del mismo cargo.");
        }

        Integer idLista = insertarLista(datos.idCargo(), nombre, simbolo, vacioANull(datos.urlPlanGobierno()), idUsuario);
        Integer idProceso = ((Number) cargo.get(0).get("idProceso")).intValue();
        return mostrarConfirmacionLista(idProceso, idLista, "Lista «" + nombre + "» inscrita para "
                + cargo.get(0).get("nombre") + ". Ahora registre a sus candidatos.");
    }

    /** Retira una lista mal registrada (solo INSCRITA, dentro del plazo y sin tachas). */
    public Map<String, Object> retirarLista(Integer idLista, Integer idUsuario) {
        Map<String, Object> lista = consulta.lista(idLista);
        consulta.exigirListaModificable(lista);
        if (dao.entero("""
                SELECT COUNT(*) FROM tacha t JOIN candidato ca ON ca.id_candidato = t.id_candidato
                 WHERE ca.id_lista = ?
                """, idLista) > 0) {
            throw InscripcionConsulta.badRequest("La lista tiene tachas presentadas y no puede retirarse.");
        }
        if (dao.entero("SELECT COUNT(*) FROM personero WHERE id_lista = ?", idLista) > 0) {
            throw InscripcionConsulta.badRequest("La lista tiene personeros registrados y no puede retirarse.");
        }
        dao.ejecutar("DELETE FROM lista_electoral WHERE id_lista = ? AND estado = 'INSCRITA'", idLista);

        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("id_lista", idLista);
        detalle.put("nombre", lista.get("nombre"));
        Integer idProceso = ((Number) lista.get("idProceso")).intValue();
        bitacora.registrar(idUsuario, idProceso, "RETIRAR_LISTA", detalle);

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Lista «" + lista.get("nombre") + "» retirada.");
        respuesta.putAll(consulta.detalle(idProceso));
        return respuesta;
    }

    /** 3: insertarLista(nombre, cargo) en ListaElectoral (sp_inscribir_lista, registra INSCRIBIR_LISTA). */
    private Integer insertarLista(Integer idCargo, String nombre, String simbolo, String urlPlan, Integer idUsuario) {
        ProcedimientoDao.Resultado resultado = dao.llamar("sp_inscribir_lista", new int[] {Types.INTEGER},
                idCargo, nombre, simbolo, urlPlan, idUsuario);
        Object id = resultado.salidas()[0];
        if (!(id instanceof Number numero)) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR,
                    "No se obtuvo el identificador de la lista inscrita.");
        }
        return numero.intValue();
    }

    /** 4: mostrarConfirmacionLista() */
    private Map<String, Object> mostrarConfirmacionLista(Integer idProceso, Integer idLista, String mensaje) {
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", mensaje);
        respuesta.put("idLista", idLista);
        respuesta.putAll(consulta.detalle(idProceso));
        return respuesta;
    }

    private static String vacioANull(String valor) {
        return valor == null || valor.isBlank() ? null : valor.trim();
    }
}
