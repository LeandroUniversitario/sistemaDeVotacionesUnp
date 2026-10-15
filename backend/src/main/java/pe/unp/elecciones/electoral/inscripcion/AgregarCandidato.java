package pe.unp.elecciones.electoral.inscripcion;

import java.sql.Types;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.inscripcion.InscripcionDto.DatosCandidato;
import pe.unp.elecciones.electoral.service.Bitacora;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS03 · Control «AgregarCandidato» del diagrama de colaboración.
 *
 * <pre>
 *  PantallaInscripcion --10: grabarCandidato(id_docente, rol)--> AgregarCandidato
 *  AgregarCandidato    --11: insertar(id_lista, id_docente, rol)--> Candidato
 *  AgregarCandidato    --12: actualizarVistaListas()--> PantallaInscripcion
 * </pre>
 *
 * Antes de grabar vuelve a pasar por ValidarCandidato (la pantalla pudo quedar
 * desactualizada). La inserción la hace sp_inscribir_candidato, que repite las
 * reglas en la base de datos junto con el trigger trg_candidato_bi.
 */
@Service
public class AgregarCandidato {

    private final ProcedimientoDao dao;
    private final InscripcionConsulta consulta;
    private final ValidarCandidato validarCandidato;
    private final Bitacora bitacora;

    public AgregarCandidato(ProcedimientoDao dao, InscripcionConsulta consulta,
            ValidarCandidato validarCandidato, Bitacora bitacora) {
        this.dao = dao;
        this.consulta = consulta;
        this.validarCandidato = validarCandidato;
        this.bitacora = bitacora;
    }

    /** 10: grabarCandidato(id_docente, rol) */
    @SuppressWarnings("unchecked")
    public Map<String, Object> grabarCandidato(Integer idLista, DatosCandidato datos, Integer idUsuario) {
        Map<String, Object> validacion = validarCandidato.comprobarRequisitos(idLista, datos.idDocente(), datos.rol());
        if (!Boolean.TRUE.equals(validacion.get("apto"))) {
            String motivo = ((List<Map<String, Object>>) validacion.get("requisitos")).stream()
                    .filter(r -> ValidarCandidato.FALLA.equals(r.get("estado")))
                    .map(r -> String.valueOf(r.get("descripcion")))
                    .findFirst().orElse("no cumple los requisitos.");
            throw InscripcionConsulta.badRequest("No se puede inscribir al candidato: " + motivo);
        }
        Map<String, Object> rol = (Map<String, Object>) validacion.get("rol");
        Map<String, Object> docente = (Map<String, Object>) validacion.get("docente");

        insertar(idLista, datos.idDocente(), String.valueOf(rol.get("codigo")), vacioANull(datos.urlHojaVida()), idUsuario);

        Map<String, Object> lista = consulta.lista(idLista);
        return actualizarVistaListas(((Number) lista.get("idProceso")).intValue(),
                docente.get("nombre") + " inscrito como " + rol.get("etiqueta") + " en la lista «" + lista.get("nombre") + "».");
    }

    /** Quita a un candidato de una lista aún modificable (RN13: reemplazos dentro del plazo). */
    public Map<String, Object> quitarCandidato(Integer idCandidato, Integer idUsuario) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT ca.id_lista, ca.id_docente, ca.rol_en_lista, CONCAT(d.apellidos, ', ', d.nombres) AS docente
                  FROM candidato ca JOIN docente d ON d.id_docente = ca.id_docente
                 WHERE ca.id_candidato = ?
                """, idCandidato);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El candidato no existe.");
        }
        Map<String, Object> candidato = filas.get(0);
        Integer idLista = ((Number) candidato.get("idLista")).intValue();
        Map<String, Object> lista = consulta.lista(idLista);
        consulta.exigirListaModificable(lista);
        if (dao.entero("SELECT COUNT(*) FROM tacha WHERE id_candidato = ?", idCandidato) > 0) {
            throw InscripcionConsulta.badRequest("El candidato tiene tachas presentadas; se resuelven en CUS04.");
        }
        dao.ejecutar("DELETE FROM candidato WHERE id_candidato = ?", idCandidato);

        Integer idProceso = ((Number) lista.get("idProceso")).intValue();
        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("id_lista", idLista);
        detalle.put("id_docente", candidato.get("idDocente"));
        detalle.put("rol", candidato.get("rolEnLista"));
        bitacora.registrar(idUsuario, idProceso, "QUITAR_CANDIDATO", detalle);

        return actualizarVistaListas(idProceso, candidato.get("docente") + " fue retirado de la lista «"
                + lista.get("nombre") + "».");
    }

    /** 11: insertar(id_lista, id_docente, rol) en Candidato (sp_inscribir_candidato, registra INSCRIBIR_CANDIDATO). */
    private void insertar(Integer idLista, Integer idDocente, String rol, String urlHojaVida, Integer idUsuario) {
        ProcedimientoDao.Resultado resultado = dao.llamar("sp_inscribir_candidato", new int[] {Types.INTEGER},
                idLista, idDocente, rol, urlHojaVida, idUsuario);
        if (!(resultado.salidas()[0] instanceof Number)) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR,
                    "No se obtuvo el identificador del candidato inscrito.");
        }
    }

    /** 12: actualizarVistaListas() */
    private Map<String, Object> actualizarVistaListas(Integer idProceso, String mensaje) {
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", mensaje);
        respuesta.putAll(consulta.detalle(idProceso));
        return respuesta;
    }

    private static String vacioANull(String valor) {
        return valor == null || valor.isBlank() ? null : valor.trim();
    }
}
