package pe.unp.elecciones.electoral.administracion;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS18 · Lecturas compartidas por GestionarUsuarios, ActualizarParametros y RespaldarBD:
 * cuentas (4 mostrarUsuario, v_usuarios_admin), docentes del padrón (2 verificarDocente),
 * parámetros y su historial (5 modificarParametro, 8 registrarAuditoria) y respaldos
 * (13 mostrarRespaldo, v_respaldos).
 */
@Service
public class AdministracionConsulta {

    static final List<String> ROLES = List.of("ADMIN", "CEUNP", "DOCENTE", "PERSONERO", "MIEMBRO_MESA");

    private final ProcedimientoDao dao;
    private final String directorioRespaldos;
    private volatile boolean instalada;

    public AdministracionConsulta(ProcedimientoDao dao,
            @Value("${app.respaldo.directorio:respaldos}") String directorioRespaldos) {
        this.dao = dao;
        this.directorioRespaldos = directorioRespaldos;
    }

    /** Falla con un mensaje claro si falta ejecutar la migración del CUS18. */
    void verificarInstalacion() {
        if (instalada) {
            return;
        }
        if (dao.entero("""
                SELECT COUNT(*) FROM information_schema.routines
                 WHERE routine_schema = DATABASE() AND routine_name = 'sp_registrar_respaldo'
                """) == 0) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Faltan los cambios del CUS18: ejecute base-de-datos/17_administracion_usuarios_parametros.sql en la base de datos.");
        }
        instalada = true;
    }

    // ─── Pantalla completa ───────────────────────────────────────────────────

    public Map<String, Object> detalle(Usuario admin) {
        verificarInstalacion();
        List<Map<String, Object>> usuarios = usuarios();
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("idAdmin", admin.getId());
        respuesta.put("usuarios", usuarios);
        respuesta.put("resumen", resumen(usuarios));
        respuesta.put("parametros", parametros());
        respuesta.put("historial", historial(null, 40));
        respuesta.put("respaldos", respaldos());
        respuesta.put("jornada", dao.consultar("""
                SELECT id_proceso AS id, nombre, fecha_inicio, fecha_fin FROM proceso_electoral
                 WHERE estado = 'VOTACION' ORDER BY fecha_inicio
                """));
        respuesta.put("politica", politica());
        respuesta.put("directorioRespaldos", directorioRespaldos);
        return respuesta;
    }

    /** Respuesta de una acción: mensaje y la pantalla actualizada. */
    Map<String, Object> respuesta(String mensaje, Usuario admin) {
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("mensaje", mensaje);
        r.put("detalle", detalle(admin));
        return r;
    }

    // ─── Cuentas ─────────────────────────────────────────────────────────────

    public List<Map<String, Object>> usuarios() {
        return dao.consultar("""
                SELECT * FROM v_usuarios_admin
                 ORDER BY FIELD(rol, 'ADMIN', 'CEUNP', 'MIEMBRO_MESA', 'PERSONERO', 'DOCENTE'), username
                """);
    }

    public Map<String, Object> usuario(Integer id) {
        verificarInstalacion();
        List<Map<String, Object>> filas = dao.consultar("SELECT * FROM v_usuarios_admin WHERE id_usuario = ?", id);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "La cuenta no existe.");
        }
        return filas.get(0);
    }

    private Map<String, Object> resumen(List<Map<String, Object>> usuarios) {
        Map<String, Object> porRol = new LinkedHashMap<>();
        ROLES.forEach(r -> porRol.put(r, 0L));
        long activos = 0;
        long bloqueadas = 0;
        long provisionales = 0;
        long sinAcceso = 0;
        for (Map<String, Object> u : usuarios) {
            porRol.merge(texto(u.get("rol")), 1L, (a, b) -> (Long) a + (Long) b);
            if (si(u.get("activo"))) {
                activos++;
            }
            if (si(u.get("bloqueada"))) {
                bloqueadas++;
            }
            if (si(u.get("debeCambiarPassword"))) {
                provisionales++;
            }
            if (u.get("ultimoAcceso") == null) {
                sinAcceso++;
            }
        }
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("total", usuarios.size());
        r.put("activos", activos);
        r.put("inactivos", usuarios.size() - activos);
        r.put("bloqueadas", bloqueadas);
        r.put("provisionales", provisionales);
        r.put("sinAcceso", sinAcceso);
        r.put("porRol", porRol);
        return r;
    }

    /** Lo que hizo la cuenta y lo que se hizo sobre ella, según la bitácora. */
    public Map<String, Object> actividad(Integer idUsuario) {
        Map<String, Object> usuario = usuario(idUsuario);
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("usuario", usuario);
        r.put("acciones", dao.consultar("""
                SELECT l.id_log, l.accion, l.id_proceso, p.nombre AS proceso, l.ip_origen, l.fecha_hora, l.detalle_json
                  FROM log_auditoria l LEFT JOIN proceso_electoral p ON p.id_proceso = l.id_proceso
                 WHERE l.id_usuario = ?
                 ORDER BY l.id_log DESC LIMIT 40
                """, idUsuario));
        r.put("administracion", dao.consultar("""
                SELECT l.id_log, l.accion, u.username AS realizado_por, l.fecha_hora, l.detalle_json
                  FROM log_auditoria l LEFT JOIN usuario u ON u.id_usuario = l.id_usuario
                 WHERE l.accion IN ('CREAR_USUARIO', 'ACTUALIZAR_USUARIO', 'ACTIVAR_USUARIO', 'DESACTIVAR_USUARIO',
                                    'RESTABLECER_PASSWORD', 'DESBLOQUEAR_USUARIO')
                   AND JSON_VALUE(l.detalle_json, '$.id_usuario') = ?
                 ORDER BY l.id_log DESC LIMIT 40
                """, String.valueOf(idUsuario)));
        return r;
    }

    // ─── 2 verificarDocente() ────────────────────────────────────────────────

    /** Docentes del padrón por DNI o nombre, con sus cuentas. */
    public List<Map<String, Object>> docentes(String texto) {
        verificarInstalacion();
        String q = texto == null ? "" : texto.trim();
        if (q.length() < 2) {
            return List.of();
        }
        String patron = "%" + q.replace("%", "").replace("_", "") + "%";
        return dao.consultar("""
                SELECT d.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS docente, d.nombres, d.apellidos,
                       CONCAT(d.estado, '') AS estado, CONCAT(d.categoria, '') AS categoria, f.nombre AS facultad,
                       (SELECT GROUP_CONCAT(CONCAT(u.username, ' (', u.rol, ')') ORDER BY u.id_usuario SEPARATOR ' · ')
                          FROM usuario u WHERE u.id_docente = d.id_docente) AS cuentas
                  FROM docente d JOIN facultad f ON f.id_facultad = d.id_facultad
                 WHERE d.dni LIKE ? OR CONCAT(d.apellidos, ' ', d.nombres) LIKE ? OR CONCAT(d.nombres, ' ', d.apellidos) LIKE ?
                 ORDER BY d.apellidos, d.nombres LIMIT 15
                """, patron, patron, patron);
    }

    public Map<String, Object> verificarDocente(Integer idDocente, String rol, Integer idUsuario) {
        verificarInstalacion();
        String r = rol == null ? "" : rol.trim().toUpperCase();
        if (!ROLES.contains(r)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Rol no válido.");
        }
        ProcedimientoDao.Resultado res = dao.llamar("sp_verificar_docente_usuario", ProcedimientoDao.SIN_SALIDA,
                idDocente, r, idUsuario);
        return res.filas().isEmpty() ? Map.of() : res.filas().get(0);
    }

    // ─── Parámetros ──────────────────────────────────────────────────────────

    public List<Map<String, Object>> parametros() {
        return dao.consultar("""
                SELECT * FROM v_parametros_admin
                 ORDER BY FIELD(grupo, 'MULTAS', 'JORNADA', 'CEUNP', 'SEGURIDAD', 'OTROS'), orden, clave
                """);
    }

    public Map<String, Object> parametro(String clave) {
        verificarInstalacion();
        List<Map<String, Object>> filas = dao.consultar("SELECT * FROM v_parametros_admin WHERE clave = ?", clave);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El parámetro no existe.");
        }
        return filas.get(0);
    }

    public List<Map<String, Object>> historial(String clave, int limite) {
        if (clave == null) {
            return dao.consultar("SELECT * FROM v_parametro_historial ORDER BY id_historial DESC LIMIT ?", limite);
        }
        return dao.consultar("SELECT * FROM v_parametro_historial WHERE clave = ? ORDER BY id_historial DESC LIMIT ?",
                clave, limite);
    }

    /** Parámetros de seguridad vigentes (los usa también el inicio de sesión). */
    public Map<String, Object> politica() {
        Map<String, Object> p = new LinkedHashMap<>();
        p.put("passwordMin", entero("SEGURIDAD_PASSWORD_MIN", 8));
        p.put("intentosMaximos", entero("SEGURIDAD_INTENTOS_MAXIMOS", 5));
        p.put("bloqueoMinutos", entero("SEGURIDAD_BLOQUEO_MINUTOS", 15));
        return p;
    }

    int entero(String clave, int porDefecto) {
        List<Map<String, Object>> filas = dao.consultar("SELECT valor FROM parametro_global WHERE clave = ?", clave);
        if (filas.isEmpty()) {
            return porDefecto;
        }
        try {
            return (int) Math.round(Double.parseDouble(texto(filas.get(0).get("valor"))));
        } catch (NumberFormatException e) {
            return porDefecto;
        }
    }

    // ─── Respaldos ───────────────────────────────────────────────────────────

    public List<Map<String, Object>> respaldos() {
        return dao.consultar("SELECT * FROM v_respaldos ORDER BY id_respaldo DESC LIMIT 50");
    }

    public Map<String, Object> respaldo(Integer id) {
        verificarInstalacion();
        List<Map<String, Object>> filas = dao.consultar("SELECT * FROM v_respaldos WHERE id_respaldo = ?", id);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El respaldo no existe.");
        }
        return filas.get(0);
    }

    // ─── Utilidades ──────────────────────────────────────────────────────────

    static String texto(Object valor) {
        return valor == null ? "" : String.valueOf(valor);
    }

    static boolean si(Object valor) {
        if (valor instanceof Boolean b) {
            return b;
        }
        if (valor instanceof Number n) {
            return n.intValue() != 0;
        }
        return "1".equals(texto(valor)) || "true".equalsIgnoreCase(texto(valor));
    }

    static String vacioANulo(String valor) {
        return valor == null || valor.isBlank() ? null : valor.trim();
    }
}
