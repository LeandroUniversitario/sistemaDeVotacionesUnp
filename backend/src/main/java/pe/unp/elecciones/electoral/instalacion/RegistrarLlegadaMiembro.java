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
 * CUS08 · «RegistrarLlegadaMiembro» (control). Mensajes 2 a 4 del diagrama de colaboración:
 *
 *   2 registrarLlegada(token)                         → valida la credencial QR (CUS07)
 *   3 actualizarAsistencia(id_docente, hora_llegada)  → MiembroMesa
 *   4 mostrarMiembroPresente()                        → la respuesta trae el detalle de la mesa
 *
 * <p>RF56: la llegada se registra con el escaneo de la credencial QR, con fecha y hora. Sin QR
 * (lector averiado, credencial perdida) se acepta el DNI, que debe coincidir con el del docente
 * (RN30). La misma lectura sirve para recibir las credenciales de los personeros (CUN07 paso 4)
 * y, si faltan titulares y suplentes, para registrar a un reemplazante (flujo alterno de CUN07).
 */
@Service
public class RegistrarLlegadaMiembro {

    private final ProcedimientoDao dao;
    private final InstalacionConsulta consulta;
    private final VerificarCredencial verificarCredencial;
    private final Bitacora bitacora;

    public RegistrarLlegadaMiembro(ProcedimientoDao dao, InstalacionConsulta consulta,
            VerificarCredencial verificarCredencial, Bitacora bitacora) {
        this.dao = dao;
        this.consulta = consulta;
        this.verificarCredencial = verificarCredencial;
        this.bitacora = bitacora;
    }

    /** 2: registrarLlegada(token) — fotocheck del miembro o credencial del personero. */
    @SuppressWarnings("unchecked")
    public Map<String, Object> registrarLlegada(Integer idMesa, String token, Integer idUsuario) {
        Map<String, Object> mesa = consulta.mesaEditable(idMesa);
        Map<String, Object> lectura = verificarCredencial.verificar(token, idUsuario);
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
                actualizarAsistencia(idMesa, idTitular, true, "QR", idUsuario, mesa);
                mensaje = "Llegada registrada: " + titular.get("nombre") + ", "
                        + String.valueOf(titular.get("funcion")).toLowerCase() + ".";
            }
            case "PERSONERO" -> {
                if (idMesaCredencial != null && !idMesa.equals(idMesaCredencial)) {
                    return rechazo(lectura, "El personero está acreditado para la mesa " + titular.get("numeroMesa") + ".");
                }
                registrarPersonero(idMesa, idTitular, true, "QR", idUsuario, mesa);
                mensaje = "Credencial de personero recibida: " + titular.get("nombre") + " (" + titular.get("lista") + ").";
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
        respuesta.put("detalle", consulta.detalle(idMesa)); // 4: mostrarMiembroPresente()
        return respuesta;
    }

    /** Llegada registrada con DNI (presente) o inasistencia (ausente). */
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
        actualizarAsistencia(idMesa, idDocente, presente, "DNI", idUsuario, mesa);
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
        registrarPersonero(idMesa, idPersonero, presente, "DNI", idUsuario, mesa);
        return consulta.detalle(idMesa);
    }

    /**
     * CUN07 flujo alterno: si faltan titulares y suplentes para un cargo, lo asume otro integrante
     * de la comunidad universitaria (docente activo, identificado con su DNI).
     */
    public Map<String, Object> registrarReemplazante(Integer idMesa, String cargo, String dni, Integer idUsuario) {
        Map<String, Object> mesa = consulta.mesaEditable(idMesa);
        Integer idProceso = InstalacionConsulta.numero(mesa.get("idProceso"));
        String cargoNormalizado = cargo == null ? "" : cargo.trim().toUpperCase();
        if (!InstalacionConsulta.CARGOS.contains(cargoNormalizado)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El cargo debe ser PRESIDENTE, SECRETARIO o VOCAL.");
        }
        Map<String, Object> propuesta = InstalacionConsulta.conformacion(consulta.miembros(idMesa), List.of(), false)
                .stream().filter(c -> cargoNormalizado.equals(c.get("cargo"))).findFirst().orElseThrow();
        if (!Boolean.TRUE.equals(propuesta.get("vacante"))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El cargo de " + cargoNormalizado.toLowerCase()
                    + " lo asume " + propuesta.get("nombre") + ": solo se registra un reemplazante si faltan titulares y suplentes.");
        }

        List<Map<String, Object>> docentes = dao.consultar("""
                SELECT id_docente, CONCAT(apellidos, ', ', nombres) AS nombre, estado
                  FROM docente WHERE dni = ?
                """, normalizarDni(dni));
        if (docentes.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                    "El DNI no corresponde a ningún docente de la UNP (integrante de la comunidad universitaria).");
        }
        Map<String, Object> docente = docentes.get(0);
        Integer idDocente = InstalacionConsulta.numero(docente.get("idDocente"));
        if (!"ACTIVO".equals(String.valueOf(docente.get("estado")))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    docente.get("nombre") + " no está ACTIVO (" + docente.get("estado") + ").");
        }
        if (consulta.esMiembro(idMesa, idDocente)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    docente.get("nombre") + " ya es miembro de esta mesa: registre su llegada en la tabla de miembros.");
        }
        if (dao.entero("""
                SELECT COUNT(*) FROM miembro_mesa mm JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
                 WHERE m.id_proceso = ? AND mm.id_docente = ?
                """, idProceso, idDocente) > 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    docente.get("nombre") + " es miembro de otra mesa de este proceso.");
        }
        if (dao.entero("""
                SELECT COUNT(*) FROM candidato ca
                  JOIN lista_electoral l ON l.id_lista = ca.id_lista
                  JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                 WHERE c.id_proceso = ? AND ca.id_docente = ? AND ca.estado_validacion <> 'EXCLUIDO'
                """, idProceso, idDocente) > 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "RN20: " + docente.get("nombre") + " es candidato en este proceso y no puede ser miembro de mesa.");
        }
        if (dao.entero("""
                SELECT COUNT(*) FROM personero pe
                  JOIN lista_electoral l ON l.id_lista = pe.id_lista
                  JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                 WHERE c.id_proceso = ? AND pe.id_docente = ? AND pe.estado_acreditacion = 'ACREDITADO'
                """, idProceso, idDocente) > 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    docente.get("nombre") + " es personero de una lista y no puede ser miembro de mesa.");
        }
        if (dao.entero("SELECT COUNT(*) FROM reemplazo_mesa WHERE id_mesa = ? AND id_docente = ?", idMesa, idDocente) > 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    docente.get("nombre") + " ya reemplaza otro cargo en esta mesa.");
        }

        dao.ejecutar("""
                INSERT INTO reemplazo_mesa (id_mesa, cargo, id_docente, hora_acreditacion, id_usuario)
                VALUES (?, ?, ?, NOW(), ?)
                ON DUPLICATE KEY UPDATE id_docente = VALUES(id_docente), hora_acreditacion = NOW(), id_usuario = VALUES(id_usuario)
                """, idMesa, cargoNormalizado, idDocente, idUsuario);
        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("id_mesa", idMesa);
        detalle.put("cargo", cargoNormalizado);
        detalle.put("id_docente", idDocente);
        bitacora.registrar(idUsuario, idProceso, "REGISTRAR_REEMPLAZANTE_MESA", detalle);
        return consulta.detalle(idMesa);
    }

    public Map<String, Object> quitarReemplazante(Integer idMesa, String cargo, Integer idUsuario) {
        Map<String, Object> mesa = consulta.mesaEditable(idMesa);
        String cargoNormalizado = cargo == null ? "" : cargo.trim().toUpperCase();
        if (dao.ejecutar("DELETE FROM reemplazo_mesa WHERE id_mesa = ? AND cargo = ?", idMesa, cargoNormalizado) == 0) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "No hay reemplazante registrado para ese cargo.");
        }
        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("id_mesa", idMesa);
        detalle.put("cargo", cargoNormalizado);
        bitacora.registrar(idUsuario, InstalacionConsulta.numero(mesa.get("idProceso")), "QUITAR_REEMPLAZANTE_MESA", detalle);
        return consulta.detalle(idMesa);
    }

    /** 3: actualizarAsistencia(id_docente, hora_llegada). */
    private void actualizarAsistencia(Integer idMesa, Integer idDocente, boolean presente, String metodo,
            Integer idUsuario, Map<String, Object> mesa) {
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
        bitacora.registrar(idUsuario, InstalacionConsulta.numero(mesa.get("idProceso")), "REGISTRAR_LLEGADA_MIEMBRO", detalle);
    }

    private void registrarPersonero(Integer idMesa, Integer idPersonero, boolean presente, String metodo,
            Integer idUsuario, Map<String, Object> mesa) {
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
        bitacora.registrar(idUsuario, InstalacionConsulta.numero(mesa.get("idProceso")), "RECIBIR_CREDENCIAL_PERSONERO", detalle);
    }

    /** RN30: el DNI que se muestra debe ser el del docente registrado. */
    private static void exigirMismoDni(String dni, String esperado, String deQuien) {
        if (!normalizarDni(dni).equals(esperado)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "RN30: el DNI no coincide con el " + deQuien + ". No se registró la llegada.");
        }
    }

    private static String normalizarDni(String dni) {
        String limpio = dni == null ? "" : dni.trim();
        if (!limpio.matches("\\d{1,8}")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Ingrese el DNI (hasta 8 dígitos) que presenta la persona.");
        }
        return String.format("%08d", Long.parseLong(limpio));
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
