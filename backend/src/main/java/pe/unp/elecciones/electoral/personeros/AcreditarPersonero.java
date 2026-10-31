package pe.unp.elecciones.electoral.personeros;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.personeros.PersonerosDto.DatosAcreditacion;
import pe.unp.elecciones.electoral.service.Bitacora;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS05 · Control «AcreditarPersonero» del diagrama de colaboración.
 *
 * <pre>
 *  PantallaPersoneros --6: guardarAcreditacion(datos)--> AcreditarPersonero
 *  AcreditarPersonero --7: insertar(id_lista, id_docente, tipo, estado)--> Personero
 *  AcreditarPersonero --8: notificarExito()--> PantallaPersoneros
 * </pre>
 *
 * Cupos por lista: un personero GENERAL, un ALTERNO y uno de MESA por cada mesa.
 * El CEUNP acredita directamente: el registro queda ACREDITADO con su fecha.
 * La credencial QR (RF51) se emite en CUS07.
 */
@Service
public class AcreditarPersonero {

    private static final Set<String> TIPOS = Set.of("GENERAL", "ALTERNO", "MESA");

    private final ProcedimientoDao dao;
    private final PersonerosConsulta consulta;
    private final ValidarPersonero validarPersonero;
    private final Bitacora bitacora;

    public AcreditarPersonero(ProcedimientoDao dao, PersonerosConsulta consulta,
            ValidarPersonero validarPersonero, Bitacora bitacora) {
        this.dao = dao;
        this.consulta = consulta;
        this.validarPersonero = validarPersonero;
        this.bitacora = bitacora;
    }

    /** 6: guardarAcreditacion(datos) */
    @SuppressWarnings("unchecked")
    public Map<String, Object> guardarAcreditacion(Integer idLista, DatosAcreditacion datos, Integer idUsuario) {
        String tipo = datos.tipo().trim().toUpperCase(Locale.ROOT);
        if (!TIPOS.contains(tipo)) {
            throw badRequest("Tipo de personero inválido: use GENERAL, ALTERNO o MESA.");
        }
        Integer idMesa = "MESA".equals(tipo) ? datos.idMesa() : null;
        if ("MESA".equals(tipo) && idMesa == null) {
            throw badRequest("Seleccione la mesa de sufragio del personero de mesa.");
        }

        Map<String, Object> validacion = validarPersonero.verificarRequisitos(idLista, datos.idDocente());
        if (!Boolean.TRUE.equals(validacion.get("apto"))) {
            String motivo = ((List<Map<String, Object>>) validacion.get("requisitos")).stream()
                    .filter(r -> ValidarPersonero.FALLA.equals(r.get("estado")))
                    .map(r -> String.valueOf(r.get("descripcion")))
                    .findFirst().orElse("no cumple los requisitos.");
            throw badRequest("No se puede acreditar: " + motivo);
        }
        Map<String, Object> cupos = (Map<String, Object>) validacion.get("cupos");
        if ("GENERAL".equals(tipo) && !Boolean.TRUE.equals(cupos.get("general"))) {
            throw badRequest("La lista ya tiene un personero GENERAL acreditado.");
        }
        if ("ALTERNO".equals(tipo) && !Boolean.TRUE.equals(cupos.get("alterno"))) {
            throw badRequest("La lista ya tiene un personero ALTERNO acreditado.");
        }
        if ("MESA".equals(tipo) && ((List<Map<String, Object>>) cupos.get("mesas")).stream()
                .noneMatch(m -> idMesa.equals(m.get("id")))) {
            throw badRequest("La mesa no está disponible: ya tiene personero de esta lista, está cerrada o no es del proceso.");
        }

        insertar(idLista, datos.idDocente(), tipo, idMesa);
        // Al acreditar, la cuenta del docente asume temporalmente el rol PERSONERO
        dao.ejecutar("UPDATE usuario SET rol = 'PERSONERO' WHERE id_docente = ? AND rol = 'DOCENTE'", datos.idDocente());

        Map<String, Object> lista = consulta.lista(idLista);
        Integer idProceso = ((Number) lista.get("idProceso")).intValue();
        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("id_lista", idLista);
        detalle.put("id_docente", datos.idDocente());
        detalle.put("tipo", tipo);
        detalle.put("id_mesa", idMesa);
        bitacora.registrar(idUsuario, idProceso, "ACREDITAR_PERSONERO", detalle);

        Map<String, Object> docente = (Map<String, Object>) validacion.get("docente");
        return notificarExito(idProceso, docente.get("nombre") + " acreditado como personero " + tipo
                + " de la lista «" + lista.get("nombre") + "».");
    }

    /**
     * 7: insertar(id_lista, id_docente, tipo, estado) en Personero.
     * Si el docente tuvo antes una acreditación revocada en esta lista, se reactiva
     * (la tabla admite un solo registro por lista y docente).
     */
    private void insertar(Integer idLista, Integer idDocente, String tipo, Integer idMesa) {
        int revocado = dao.entero("""
                SELECT COUNT(*) FROM personero
                 WHERE id_lista = ? AND id_docente = ? AND estado_acreditacion = 'REVOCADO'
                """, idLista, idDocente);
        if (revocado > 0) {
            dao.ejecutar("""
                    UPDATE personero
                       SET tipo = ?, id_mesa = ?, estado_acreditacion = 'ACREDITADO',
                           fecha_acreditacion = NOW(), qr_credencial_hash = NULL
                     WHERE id_lista = ? AND id_docente = ?
                    """, tipo, idMesa, idLista, idDocente);
        } else {
            // trg_personero_bi vuelve a validar RN21 y que la mesa sea del proceso
            dao.ejecutar("""
                    INSERT INTO personero (id_lista, id_docente, tipo, id_mesa, estado_acreditacion, fecha_acreditacion)
                    VALUES (?, ?, ?, ?, 'ACREDITADO', NOW())
                    """, idLista, idDocente, tipo, idMesa);
        }
    }

    /** Revoca una acreditación vigente (queda el registro como REVOCADO). */
    public Map<String, Object> revocar(Integer idPersonero, String motivo, Integer idUsuario) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT pe.id_lista, pe.tipo, pe.estado_acreditacion, c.id_proceso, p.estado AS estado_proceso,
                       CONCAT(d.apellidos, ', ', d.nombres) AS docente, l.nombre AS lista
                  FROM personero pe
                  JOIN docente d ON d.id_docente = pe.id_docente
                  JOIN lista_electoral l ON l.id_lista = pe.id_lista
                  JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                  JOIN proceso_electoral p ON p.id_proceso = c.id_proceso
                 WHERE pe.id_personero = ?
                """, idPersonero);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El personero no existe.");
        }
        Map<String, Object> pe = filas.get(0);
        if ("REVOCADO".equals(pe.get("estadoAcreditacion"))) {
            throw badRequest("La acreditación ya estaba revocada.");
        }
        if (!PersonerosConsulta.ESTADOS_ACREDITACION.contains(String.valueOf(pe.get("estadoProceso")))) {
            throw badRequest("El proceso ya terminó; las acreditaciones no se modifican.");
        }
        dao.ejecutar("UPDATE personero SET estado_acreditacion = 'REVOCADO', qr_credencial_hash = NULL WHERE id_personero = ?",
                idPersonero);
        // Si ya no le quedan otras personerías acreditadas, su cuenta retorna al rol DOCENTE
        Integer idDocenteRev = dao.entero("SELECT id_docente FROM personero WHERE id_personero = ?", idPersonero);
        int activas = dao.entero("SELECT COUNT(*) FROM personero WHERE id_docente = ? AND estado_acreditacion = 'ACREDITADO'", idDocenteRev);
        if (activas == 0) {
            dao.ejecutar("UPDATE usuario SET rol = 'DOCENTE' WHERE id_docente = ? AND rol = 'PERSONERO'", idDocenteRev);
        }

        Integer idProceso = ((Number) pe.get("idProceso")).intValue();
        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("id_personero", idPersonero);
        detalle.put("motivo", motivo.trim());
        bitacora.registrar(idUsuario, idProceso, "REVOCAR_PERSONERO", detalle);

        return notificarExito(idProceso, "Acreditación de " + pe.get("docente") + " (personero " + pe.get("tipo")
                + ", lista «" + pe.get("lista") + "») revocada.");
    }

    /** 8: notificarExito() */
    private Map<String, Object> notificarExito(Integer idProceso, String mensaje) {
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", mensaje);
        respuesta.putAll(consulta.detalle(idProceso));
        return respuesta;
    }

    private static ResponseStatusException badRequest(String mensaje) {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, mensaje);
    }
}
