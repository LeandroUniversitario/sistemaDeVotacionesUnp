package pe.unp.elecciones.electoral.bitacora;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS19 · Lecturas compartidas por ConsultarBitacora, VerDetalleRegistro, VerificarBitacora y
 * ExportarBitacora: filtros (1 ingresarFiltros), registros y resumen de v_bitacora
 * (4 consultar, 5 mostrarRegistros), catálogo de acciones y estado de la cadena de sellos.
 */
@Service
public class BitacoraConsulta {

    static final List<String> ROLES = List.of("ADMIN", "CEUNP", "DOCENTE", "PERSONERO", "MIEMBRO_MESA", "SIN_CUENTA");
    static final List<String> MODULOS = List.of("SEGURIDAD", "ADMINISTRACION", "PREPARACION", "JORNADA", "ESCRUTINIO",
            "RECURSOS", "RESULTADOS", "MULTAS", "SIN_CLASIFICAR");
    static final List<String> CRITICIDADES = List.of("BAJA", "MEDIA", "ALTA", "CRITICA");
    static final int TAMANO_MAXIMO = 200;

    private static final Pattern NUMERO_REGISTRO = Pattern.compile("^#?(\\d{1,18})$");
    private static final Pattern IP = Pattern.compile("^[0-9A-Fa-f:.]{1,45}$");

    private final ProcedimientoDao dao;
    private volatile boolean instalada;

    public BitacoraConsulta(ProcedimientoDao dao) {
        this.dao = dao;
    }

    /** Falla con un mensaje claro si falta ejecutar la migración del CUS19. */
    void verificarInstalacion() {
        if (instalada) {
            return;
        }
        if (dao.entero("""
                SELECT COUNT(*) FROM information_schema.routines
                 WHERE routine_schema = DATABASE() AND routine_name = 'sp_verificar_bitacora'
                """) == 0) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Faltan los cambios del CUS19: ejecute base-de-datos/18_consultar_bitacora.sql en la base de datos.");
        }
        instalada = true;
    }

    /** 3 validarRolAdministrador(id_usuario): la cuenta debe ser ADMIN y estar activa en la base. */
    void validarRolAdministrador(Integer idUsuario) {
        dao.llamar("sp_validar_admin", ProcedimientoDao.SIN_SALIDA, idUsuario);
    }

    // ─── 1 ingresarFiltros() ─────────────────────────────────────────────────

    /** Normaliza y valida los filtros que llegan como parámetros de la URL. */
    public BitacoraDto.Filtros filtros(Map<String, String> p) {
        String rol = mayusculas(p.get("rol"));
        if (rol != null && !ROLES.contains(rol)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Rol no válido.");
        }
        String modulo = lista(p.get("modulo"), MODULOS, "Módulo no válido.");
        String criticidad = lista(p.get("criticidad"), CRITICIDADES, "Criticidad no válida.");
        String ip = vacioANulo(p.get("ip"));
        if (ip != null && !IP.matcher(ip).matches()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La dirección IP solo admite números, puntos y dos puntos.");
        }
        String accion = mayusculas(p.get("accion"));
        if (accion != null && !accion.matches("^[A-Z0-9_]{1,100}$")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Código de acción no válido.");
        }
        LocalDateTime desde = fecha(p.get("desde"), false);
        LocalDateTime hasta = fecha(p.get("hasta"), true);
        if (desde != null && hasta != null && desde.isAfter(hasta)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La fecha inicial es posterior a la fecha final.");
        }
        String texto = vacioANulo(p.get("texto"));
        if (texto != null && texto.length() > 120) {
            texto = texto.substring(0, 120);
        }
        return new BitacoraDto.Filtros(texto, entero(p.get("idUsuario"), "Usuario no válido."), rol, accion, modulo,
                criticidad, entero(p.get("idProceso"), "Proceso no válido."), entero(p.get("idDocente"), "Docente no válido."),
                ip, desde, hasta);
    }

    /** Filtros aplicados, para la bitácora de una exportación y para el encabezado de los reportes. */
    Map<String, Object> descripcion(BitacoraDto.Filtros f) {
        Map<String, Object> d = new LinkedHashMap<>();
        poner(d, "texto", f.texto());
        poner(d, "idUsuario", f.idUsuario());
        poner(d, "rol", f.rol());
        poner(d, "accion", f.accion());
        poner(d, "modulo", f.modulo());
        poner(d, "criticidad", f.criticidad());
        poner(d, "idProceso", f.idProceso());
        poner(d, "idDocente", f.idDocente());
        poner(d, "ip", f.ip());
        poner(d, "desde", f.desde() == null ? null : f.desde().toString());
        poner(d, "hasta", f.hasta() == null ? null : f.hasta().toString());
        return d;
    }

    // ─── 4 consultar(filtros) ────────────────────────────────────────────────

    /** Cláusula WHERE sobre v_bitacora (alias v) y sus argumentos, en orden. */
    record Condicion(String sql, List<Object> argumentos) {
    }

    Condicion condicion(BitacoraDto.Filtros f) {
        StringBuilder w = new StringBuilder(" WHERE 1 = 1");
        List<Object> a = new ArrayList<>();
        if (f.texto() != null) {
            var numero = NUMERO_REGISTRO.matcher(f.texto());
            String patron = "%" + f.texto().replace("\\", "").replace("%", "\\%").replace("_", "\\_") + "%";
            w.append(" AND (v.accion LIKE ? OR v.etiqueta LIKE ? OR v.username LIKE ? OR v.usuario_docente LIKE ?"
                    + " OR v.docente LIKE ? OR v.dni_docente LIKE ? OR v.proceso LIKE ? OR v.ip_origen LIKE ?"
                    + " OR v.detalle_json LIKE ?");
            for (int i = 0; i < 9; i++) {
                a.add(patron);
            }
            if (numero.matches()) {
                w.append(" OR v.id_log = ?");
                a.add(Long.parseLong(numero.group(1)));
            }
            w.append(")");
        }
        if (f.idUsuario() != null) {
            if (f.idUsuario() == 0) {
                w.append(" AND v.id_usuario IS NULL");
            } else {
                w.append(" AND v.id_usuario = ?");
                a.add(f.idUsuario());
            }
        }
        if (f.rol() != null) {
            if ("SIN_CUENTA".equals(f.rol())) {
                w.append(" AND v.id_usuario IS NULL");
            } else {
                w.append(" AND v.rol = ?");
                a.add(f.rol());
            }
        }
        if (f.accion() != null) {
            w.append(" AND v.accion = ?");
            a.add(f.accion());
        }
        en(w, a, "v.modulo", f.modulo());
        en(w, a, "v.criticidad", f.criticidad());
        if (f.idProceso() != null) {
            w.append(" AND v.id_proceso = ?");
            a.add(f.idProceso());
        }
        if (f.idDocente() != null) {
            w.append(" AND v.id_docente = ?");
            a.add(f.idDocente());
        }
        if (f.ip() != null) {
            w.append(" AND v.ip_origen LIKE ?");
            a.add(f.ip() + "%");
        }
        if (f.desde() != null) {
            w.append(" AND v.fecha_hora >= ?");
            a.add(f.desde());
        }
        if (f.hasta() != null) {
            w.append(" AND v.fecha_hora <= ?");
            a.add(f.hasta());
        }
        return new Condicion(w.toString(), a);
    }

    /** Página de registros, del más reciente al más antiguo (o al revés), en el orden de la cadena. */
    List<Map<String, Object>> registros(Condicion c, boolean ascendente, int limite, long desplazamiento) {
        List<Object> a = new ArrayList<>(c.argumentos());
        a.add(limite);
        a.add(desplazamiento);
        return dao.consultar("""
                SELECT v.id_log, v.fecha_hora, v.accion, v.etiqueta, v.modulo, v.caso_uso, v.criticidad, v.catalogada,
                       v.id_usuario, v.username, v.rol, v.usuario_docente, v.id_docente, v.docente, v.dni_docente,
                       v.id_proceso, v.proceso, v.ip_origen, v.user_agent, LEFT(v.detalle_json, 400) AS detalle_json,
                       CHAR_LENGTH(v.detalle_json) AS largo_detalle, LEFT(v.hash_registro, 12) AS sello
                  FROM v_bitacora v
                """ + c.sql() + " ORDER BY v.id_log " + (ascendente ? "ASC" : "DESC") + " LIMIT ? OFFSET ?", a.toArray());
    }

    long contar(Condicion c) {
        List<Map<String, Object>> filas = dao.consultar("SELECT COUNT(*) AS total FROM v_bitacora v" + c.sql(),
                c.argumentos().toArray());
        return numero(filas.get(0).get("total"));
    }

    /** 5 mostrarRegistros(lista): totales del resultado filtrado para el panel de resumen. */
    Map<String, Object> resumen(Condicion c) {
        Object[] a = c.argumentos().toArray();
        Map<String, Object> r = new LinkedHashMap<>(dao.consultar("""
                SELECT COUNT(*) AS total,
                       COUNT(DISTINCT v.id_usuario) AS usuarios,
                       COUNT(DISTINCT v.ip_origen) AS ips,
                       COUNT(DISTINCT v.id_proceso) AS procesos,
                       SUM(v.id_usuario IS NULL) AS sin_cuenta,
                       MIN(v.fecha_hora) AS primero,
                       MAX(v.fecha_hora) AS ultimo
                  FROM v_bitacora v
                """ + c.sql(), a).get(0));
        r.put("porCriticidad", conteo("v.criticidad", c, 10));
        r.put("porModulo", conteo("v.modulo", c, 20));
        r.put("topAcciones", dao.consultar("""
                SELECT v.accion, MAX(v.etiqueta) AS etiqueta, MAX(v.criticidad) AS criticidad, COUNT(*) AS total
                  FROM v_bitacora v
                """ + c.sql() + " GROUP BY v.accion ORDER BY total DESC, v.accion LIMIT 10", a));
        r.put("topUsuarios", dao.consultar("""
                SELECT v.id_usuario, COALESCE(MAX(v.username), 'Sin cuenta (sistema o elector)') AS username,
                       MAX(v.rol) AS rol, COUNT(*) AS total, MAX(v.fecha_hora) AS ultimo
                  FROM v_bitacora v
                """ + c.sql() + " GROUP BY v.id_usuario ORDER BY total DESC LIMIT 8", a));
        r.put("porDia", dao.consultar("""
                SELECT DATE(v.fecha_hora) AS dia, COUNT(*) AS total,
                       SUM(v.criticidad IN ('ALTA', 'CRITICA')) AS relevantes
                  FROM v_bitacora v
                """ + c.sql() + " GROUP BY DATE(v.fecha_hora) ORDER BY dia DESC LIMIT 31", a));
        r.put("porHora", dao.consultar("""
                SELECT HOUR(v.fecha_hora) AS hora, COUNT(*) AS total
                  FROM v_bitacora v
                """ + c.sql() + " GROUP BY HOUR(v.fecha_hora) ORDER BY hora", a));
        return r;
    }

    private List<Map<String, Object>> conteo(String columna, Condicion c, int limite) {
        return dao.consultar("SELECT " + columna + " AS valor, COUNT(*) AS total FROM v_bitacora v" + c.sql()
                + " GROUP BY " + columna + " ORDER BY total DESC LIMIT " + limite, c.argumentos().toArray());
    }

    // ─── Datos de la pantalla ────────────────────────────────────────────────

    /** Catálogo de acciones con su uso, más los códigos registrados que no están en el catálogo. */
    List<Map<String, Object>> acciones() {
        return dao.consultar("""
                SELECT a.codigo, a.etiqueta, a.descripcion, a.modulo, a.caso_uso, a.criticidad, 1 AS catalogada,
                       (SELECT COUNT(*) FROM log_auditoria l WHERE l.accion = a.codigo) AS total
                  FROM bitacora_accion a
                UNION ALL
                SELECT l.accion, REPLACE(l.accion, '_', ' '), NULL, 'SIN_CLASIFICAR', NULL, 'MEDIA', 0, COUNT(*)
                  FROM log_auditoria l
                 WHERE NOT EXISTS (SELECT 1 FROM bitacora_accion a WHERE a.codigo = l.accion)
                 GROUP BY l.accion
                 ORDER BY FIELD(modulo, 'SEGURIDAD', 'ADMINISTRACION', 'PREPARACION', 'JORNADA', 'ESCRUTINIO',
                                'RECURSOS', 'RESULTADOS', 'MULTAS', 'SIN_CLASIFICAR'), etiqueta
                """);
    }

    /** Cuentas que se pueden elegir en el filtro de usuario, con cuántas acciones registró cada una. */
    List<Map<String, Object>> usuarios() {
        return dao.consultar("""
                SELECT u.id_usuario, u.username, u.rol, u.activo,
                       (SELECT COUNT(*) FROM log_auditoria l WHERE l.id_usuario = u.id_usuario) AS total
                  FROM usuario u
                 ORDER BY FIELD(u.rol, 'ADMIN', 'CEUNP', 'MIEMBRO_MESA', 'PERSONERO', 'DOCENTE'), u.username
                """);
    }

    List<Map<String, Object>> procesos() {
        return dao.consultar("""
                SELECT p.id_proceso, p.nombre, CONCAT(p.estado, '') AS estado,
                       (SELECT COUNT(*) FROM log_auditoria l WHERE l.id_proceso = p.id_proceso) AS total
                  FROM proceso_electoral p
                 ORDER BY p.id_proceso DESC
                """);
    }

    /** Sello vigente de la cadena y la última verificación registrada. */
    Map<String, Object> cadena() {
        Map<String, Object> r = new LinkedHashMap<>();
        List<Map<String, Object>> sello = dao.consultar("SELECT * FROM bitacora_cadena WHERE id_cadena = 1");
        r.put("sello", sello.isEmpty() ? null : sello.get(0));
        r.put("sinSello", dao.entero("SELECT COUNT(*) FROM log_auditoria WHERE hash_registro IS NULL"));
        List<Map<String, Object>> ultima = dao.consultar("""
                SELECT v.id_log, v.fecha_hora, v.username, v.detalle_json,
                       (SELECT COUNT(*) FROM log_auditoria x WHERE x.id_log > v.id_log) AS registros_despues
                  FROM v_bitacora v
                 WHERE v.accion = 'VERIFICAR_BITACORA'
                 ORDER BY v.id_log DESC LIMIT 1
                """);
        r.put("ultimaVerificacion", ultima.isEmpty() ? null : ultima.get(0));
        r.put("verificaciones", dao.consultar("""
                SELECT v.id_log, v.fecha_hora, v.username, v.ip_origen, v.detalle_json
                  FROM v_bitacora v WHERE v.accion = 'VERIFICAR_BITACORA'
                 ORDER BY v.id_log DESC LIMIT 15
                """));
        return r;
    }

    /** Señales de seguridad de las últimas 24 horas, sin importar los filtros. */
    Map<String, Object> alertas() {
        Map<String, Object> r = new LinkedHashMap<>(dao.consultar("""
                SELECT COALESCE(SUM(l.accion = 'LOGIN_FAILED'), 0) AS fallidos,
                       COALESCE(SUM(l.accion = 'LOGIN_SUCCESS'), 0) AS ingresos,
                       COALESCE(SUM(a.criticidad = 'CRITICA'), 0) AS criticas,
                       COUNT(*) AS total
                  FROM log_auditoria l LEFT JOIN bitacora_accion a ON a.codigo = l.accion
                 WHERE l.fecha_hora >= NOW() - INTERVAL 1 DAY
                """).get(0));
        r.put("cuentasConFallos", dao.consultar("""
                SELECT l.id_usuario, u.username, COUNT(*) AS fallidos, MAX(l.fecha_hora) AS ultimo,
                       COUNT(DISTINCT l.ip_origen) AS ips, (u.bloqueado_hasta IS NOT NULL AND u.bloqueado_hasta > NOW()) AS bloqueada
                  FROM log_auditoria l LEFT JOIN usuario u ON u.id_usuario = l.id_usuario
                 WHERE l.accion = 'LOGIN_FAILED' AND l.fecha_hora >= NOW() - INTERVAL 1 DAY
                 GROUP BY l.id_usuario, u.username, u.bloqueado_hasta
                 ORDER BY fallidos DESC LIMIT 5
                """));
        return r;
    }

    int maximoExportacion() {
        List<Map<String, Object>> filas = dao.consultar(
                "SELECT valor FROM parametro_global WHERE clave = 'BITACORA_EXPORTACION_MAX'");
        try {
            return filas.isEmpty() ? 20000 : (int) Math.round(Double.parseDouble(String.valueOf(filas.get(0).get("valor"))));
        } catch (NumberFormatException e) {
            return 20000;
        }
    }

    // ─── Utilidades ──────────────────────────────────────────────────────────

    private static void en(StringBuilder w, List<Object> a, String columna, String valores) {
        if (valores == null) {
            return;
        }
        String[] partes = valores.split(",");
        w.append(" AND ").append(columna).append(" IN (").append(String.join(", ", java.util.Collections.nCopies(partes.length, "?")))
                .append(")");
        a.addAll(Arrays.asList(partes));
    }

    private static String lista(String valor, List<String> permitidos, String error) {
        String v = mayusculas(valor);
        if (v == null) {
            return null;
        }
        List<String> partes = Arrays.stream(v.split(",")).map(String::trim).filter(s -> !s.isEmpty()).distinct().toList();
        if (partes.isEmpty()) {
            return null;
        }
        if (!permitidos.containsAll(partes)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, error);
        }
        return String.join(",", partes);
    }

    private static LocalDateTime fecha(String valor, boolean finDelDia) {
        String v = vacioANulo(valor);
        if (v == null) {
            return null;
        }
        try {
            if (v.length() == 10) {
                LocalDate d = LocalDate.parse(v);
                return finDelDia ? d.atTime(23, 59, 59) : d.atStartOfDay();
            }
            LocalDateTime t = LocalDateTime.parse(v.length() == 16 ? v + ":00" : v);
            return finDelDia && v.length() == 16 ? t.withSecond(59) : t;
        } catch (DateTimeParseException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Fecha no válida: " + v + " (use AAAA-MM-DD o AAAA-MM-DDTHH:MM).");
        }
    }

    private static Integer entero(String valor, String error) {
        String v = vacioANulo(valor);
        if (v == null) {
            return null;
        }
        try {
            int n = Integer.parseInt(v);
            if (n < 0) {
                throw new NumberFormatException();
            }
            return n;
        } catch (NumberFormatException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, error);
        }
    }

    private static void poner(Map<String, Object> m, String clave, Object valor) {
        if (valor != null) {
            m.put(clave, valor);
        }
    }

    private static String mayusculas(String valor) {
        String v = vacioANulo(valor);
        return v == null ? null : v.toUpperCase();
    }

    static String vacioANulo(String valor) {
        return valor == null || valor.isBlank() ? null : valor.trim();
    }

    static long numero(Object valor) {
        return valor instanceof Number n ? n.longValue() : valor == null ? 0 : Long.parseLong(String.valueOf(valor));
    }
}
