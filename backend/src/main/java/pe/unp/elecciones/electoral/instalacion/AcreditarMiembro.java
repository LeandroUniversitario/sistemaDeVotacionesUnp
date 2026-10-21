package pe.unp.elecciones.electoral.instalacion;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.credenciales.VerificarCredencial;
import pe.unp.elecciones.electoral.service.Bitacora;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS08 · Acreditación de las personas que instalan la mesa (Art. 48, RN30).
 *
 * <p>Con el fotocheck QR (CUS07) se reutiliza VerificarCredencial: la credencial debe estar
 * VIGENTE, ser del mismo proceso y de esta mesa. Sin QR (lector averiado, credencial perdida)
 * se acredita con el DNI, que debe coincidir con el del docente sorteado o acreditado.
 */
@Service
public class AcreditarMiembro {

    private final ProcedimientoDao dao;
    private final InstalacionConsulta consulta;
    private final VerificarCredencial verificarCredencial;
    private final Bitacora bitacora;

    public AcreditarMiembro(ProcedimientoDao dao, InstalacionConsulta consulta,
            VerificarCredencial verificarCredencial, Bitacora bitacora) {
        this.dao = dao;
        this.consulta = consulta;
        this.verificarCredencial = verificarCredencial;
        this.bitacora = bitacora;
    }

    /** Lectura del fotocheck del miembro o de la credencial del personero. */
    @SuppressWarnings("unchecked")
    public Map<String, Object> porCredencial(Integer idMesa, String codigo, Integer idUsuario) {
        Map<String, Object> mesa = consulta.mesaEditable(idMesa);
        Map<String, Object> lectura = verificarCredencial.verificar(codigo, idUsuario);
        if (!Boolean.TRUE.equals(lectura.get("valida"))) {
            return rechazo(lectura, String.valueOf(lectura.get("mensaje")));
        }
        Map<String, Object> credencial = (Map<String, Object>) lectura.get("credencial");
        Map<String, Object> proceso = (Map<String, Object>) lectura.get("proceso");
        Map<String, Object> titular = (Map<String, Object>) lectura.get("titular");
        if (InstalacionConsulta.numero(proceso.get("id")) != InstalacionConsulta.numero(mesa.get("idProceso"))) {
            return rechazo(lectura, "La credencial es de otro proceso electoral (" + proceso.get("nombre") + ").");
        }
        String tipo = String.valueOf(credencial.get("tipo"));
        Integer idMesaCredencial = titular.get("idMesa") == null ? null : InstalacionConsulta.numero(titular.get("idMesa"));
        Integer idTitular = InstalacionConsulta.numero(titular.get("idTitular"));

        String mensaje;
        switch (tipo) {
            case "MIEMBRO_MESA" -> {
                if (!idMesa.equals(idMesaCredencial)) {
                    return rechazo(lectura, "El fotocheck corresponde a la mesa " + titular.get("numeroMesa")
                            + ", no a esta mesa.");
                }
                marcarMiembro(idMesa, idTitular, true, "QR", idUsuario, mesa);
                mensaje = titular.get("nombre") + " acreditado como " + String.valueOf(titular.get("funcion")).toLowerCase() + ".";
            }
            case "PERSONERO" -> {
                if (idMesaCredencial != null && !idMesa.equals(idMesaCredencial)) {
                    return rechazo(lectura, "El personero está acreditado para la mesa " + titular.get("numeroMesa") + ".");
                }
                marcarPersonero(idMesa, idTitular, true, "QR", idUsuario, mesa);
                mensaje = titular.get("nombre") + " registrado como personero de " + titular.get("lista") + ".";
            }
            default -> {
                return rechazo(lectura, "Es un pase de votación: para la instalación lea el fotocheck del miembro "
                        + "de mesa o la credencial del personero.");
            }
        }
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("aceptada", true);
        respuesta.put("tipo", tipo);
        respuesta.put("mensaje", mensaje);
        respuesta.put("titular", titular);
        respuesta.put("detalle", consulta.detalle(idMesa));
        return respuesta;
    }

    /** Acreditación manual con DNI (presente) o registro de inasistencia (ausente). */
    public Map<String, Object> asistenciaMiembro(Integer idMesa, Integer idDocente, boolean presente, String dni,
            Integer idUsuario) {
        Map<String, Object> mesa = consulta.mesaEditable(idMesa);
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT d.dni FROM miembro_mesa mm JOIN docente d ON d.id_docente = mm.id_docente
                 WHERE mm.id_mesa = ? AND mm.id_docente = ?
                """, idMesa, idDocente);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El docente no es miembro de esta mesa.");
        }
        if (presente) {
            exigirMismoDni(dni, String.valueOf(filas.get(0).get("dni")), "del miembro sorteado");
        }
        marcarMiembro(idMesa, idDocente, presente, "DNI", idUsuario, mesa);
        return consulta.detalle(idMesa);
    }

    public Map<String, Object> asistenciaPersonero(Integer idMesa, Integer idPersonero, boolean presente, String dni,
            Integer idUsuario) {
        Map<String, Object> mesa = consulta.mesaEditable(idMesa);
        Map<String, Object> personero = consulta.personeros(idMesa, InstalacionConsulta.numero(mesa.get("idProceso")))
                .stream().filter(p -> idPersonero.equals(InstalacionConsulta.numero(p.get("idPersonero"))))
                .findFirst()
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "El personero no está acreditado para esta mesa (CUS05)."));
        if (presente) {
            exigirMismoDni(dni, String.valueOf(personero.get("dni")), "del personero acreditado");
        }
        marcarPersonero(idMesa, idPersonero, presente, "DNI", idUsuario, mesa);
        return consulta.detalle(idMesa);
    }

    private void marcarMiembro(Integer idMesa, Integer idDocente, boolean presente, String metodo, Integer idUsuario,
            Map<String, Object> mesa) {
        if (presente) {
            dao.ejecutar("""
                    UPDATE miembro_mesa SET asistio = 1, hora_acreditacion = NOW(), metodo_acreditacion = ?
                     WHERE id_mesa = ? AND id_docente = ?
                    """, metodo, idMesa, idDocente);
        } else {
            dao.ejecutar("""
                    UPDATE miembro_mesa SET asistio = 0, hora_acreditacion = NULL, metodo_acreditacion = NULL
                     WHERE id_mesa = ? AND id_docente = ?
                    """, idMesa, idDocente);
        }
        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("id_mesa", idMesa);
        detalle.put("id_docente", idDocente);
        detalle.put("presente", presente);
        detalle.put("metodo", presente ? metodo : null);
        bitacora.registrar(idUsuario, InstalacionConsulta.numero(mesa.get("idProceso")), "ACREDITAR_MIEMBRO_MESA", detalle);
    }

    private void marcarPersonero(Integer idMesa, Integer idPersonero, boolean presente, String metodo, Integer idUsuario,
            Map<String, Object> mesa) {
        if (presente) {
            dao.ejecutar("""
                    INSERT INTO asistencia_personero_mesa (id_mesa, id_personero, hora_acreditacion, metodo, id_usuario)
                    VALUES (?, ?, NOW(), ?, ?)
                    ON DUPLICATE KEY UPDATE hora_acreditacion = NOW(), metodo = VALUES(metodo), id_usuario = VALUES(id_usuario)
                    """, idMesa, idPersonero, metodo, idUsuario);
        } else {
            dao.ejecutar("DELETE FROM asistencia_personero_mesa WHERE id_mesa = ? AND id_personero = ?",
                    idMesa, idPersonero);
        }
        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("id_mesa", idMesa);
        detalle.put("id_personero", idPersonero);
        detalle.put("presente", presente);
        detalle.put("metodo", presente ? metodo : null);
        bitacora.registrar(idUsuario, InstalacionConsulta.numero(mesa.get("idProceso")), "ACREDITAR_PERSONERO_MESA", detalle);
    }

    /** RN30: el DNI que se muestra debe ser el del docente registrado. */
    private static void exigirMismoDni(String dni, String esperado, String deQuien) {
        String limpio = dni == null ? "" : dni.trim();
        if (!limpio.matches("\\d{1,8}")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Ingrese el DNI (hasta 8 dígitos) que presenta la persona.");
        }
        if (!String.format("%08d", Long.parseLong(limpio)).equals(esperado)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "RN30: el DNI no coincide con el " + deQuien + ". No se acreditó.");
        }
    }

    private static Map<String, Object> rechazo(Map<String, Object> lectura, String mensaje) {
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("aceptada", false);
        respuesta.put("resultado", lectura.get("resultado"));
        respuesta.put("mensaje", mensaje);
        if (lectura.get("titular") != null) {
            respuesta.put("titular", lectura.get("titular"));
        }
        return respuesta;
    }
}
