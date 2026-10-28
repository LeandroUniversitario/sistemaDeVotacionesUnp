package pe.unp.elecciones.electoral.administracion;

import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.security.DigestInputStream;
import java.security.DigestOutputStream;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.locks.ReentrantLock;
import java.util.regex.Pattern;

import javax.sql.DataSource;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.Bitacora;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS18 · «respaldarBD» (control). Mensajes 10 a 13 del diagrama de colaboración:
 *
 *   10 solicitarRespaldo()  → PantallaAdministrador
 *   11 generarRespaldo()    → generar(): vuelca la base a un archivo .sql con una lectura consistente
 *                             (tablas, datos, funciones, vistas, procedimientos y triggers)
 *   12 registrarAuditoria() → sp_registrar_respaldo: respaldo_bd con la huella SHA-256 y log_auditoria
 *   13 mostrarRespaldo()    → v_respaldos: archivo, tamaño, objetos, filas y huella
 *
 * <p>El archivo se restaura con phpMyAdmin (Importar, con la base elecciones_unp elegida) o con
 * {@code mysql -u root elecciones_unp < archivo.sql}. Los triggers se crean al final, después de los
 * datos, para que las reglas de la base no rechacen la carga. La huella permite comprobar después
 * que el archivo no fue alterado.
 */
@Service
public class RespaldarBD {

    private static final DateTimeFormatter NOMBRE = DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss");
    private static final Pattern DEFINER = Pattern.compile("\\s*DEFINER\\s*=\\s*(`[^`]*`|'[^']*'|[^\\s@]+)@(`[^`]*`|'[^']*'|[^\\s]+)",
            Pattern.CASE_INSENSITIVE);
    private static final Pattern ARCHIVO = Pattern.compile("^respaldo_elecciones_unp_\\d{8}_\\d{6}\\.sql$");
    private static final int FILAS_POR_INSERT = 200;

    private final DataSource dataSource;
    private final ProcedimientoDao dao;
    private final AdministracionConsulta consulta;
    private final Bitacora bitacora;
    private final Path directorio;
    private final ReentrantLock enCurso = new ReentrantLock();

    public RespaldarBD(DataSource dataSource, ProcedimientoDao dao, AdministracionConsulta consulta, Bitacora bitacora,
            @Value("${app.respaldo.directorio:respaldos}") String directorio) {
        this.dataSource = dataSource;
        this.dao = dao;
        this.consulta = consulta;
        this.bitacora = bitacora;
        this.directorio = Paths.get(directorio).toAbsolutePath().normalize();
    }

    /** Conteo de lo que lleva el archivo. */
    private static final class Conteo {
        int tablas;
        int vistas;
        int rutinas;
        int disparadores;
        long filas;
    }

    // ─── 11 generarRespaldo() → 12 registrarAuditoria() → 13 mostrarRespaldo() ──

    public Map<String, Object> generar(AdministracionDto.SolicitudRespaldo datos, Usuario admin, String ip) {
        consulta.verificarInstalacion();
        if (!enCurso.tryLock()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Ya se está generando un respaldo; espere a que termine.");
        }
        Path temporal = null;
        try {
            Files.createDirectories(directorio);
            LocalDateTime inicio = LocalDateTime.now().withNano(0);
            String nombre = "respaldo_elecciones_unp_" + NOMBRE.format(inicio) + ".sql";
            Path destino = directorio.resolve(nombre);
            if (Files.exists(destino)) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "Ya existe un respaldo de este segundo; vuelva a intentarlo.");
            }
            temporal = directorio.resolve(nombre + ".parcial");
            MessageDigest sha = MessageDigest.getInstance("SHA-256");
            Conteo conteo = new Conteo();
            try (OutputStream archivo = Files.newOutputStream(temporal);
                    DigestOutputStream conHuella = new DigestOutputStream(archivo, sha);
                    Writer out = new BufferedWriter(new OutputStreamWriter(conHuella, StandardCharsets.UTF_8), 1 << 16);
                    Connection cn = dataSource.getConnection()) {
                volcar(cn, out, conteo, admin, inicio, datos == null ? null : datos.motivo());
            }
            Files.move(temporal, destino, StandardCopyOption.ATOMIC_MOVE);
            temporal = null;
            String hash = HexFormat.of().formatHex(sha.digest());
            LocalDateTime fin = LocalDateTime.now().withNano(0);
            ProcedimientoDao.Resultado r = dao.llamar("sp_registrar_respaldo", ProcedimientoDao.SIN_SALIDA, admin.getId(), nombre,
                    datos == null ? null : AdministracionConsulta.vacioANulo(datos.motivo()), conteo.tablas, conteo.vistas,
                    conteo.rutinas, conteo.disparadores, conteo.filas, Files.size(destino), hash, ip, inicio, fin);
            Map<String, Object> respaldo = r.filas().isEmpty() ? Map.of() : r.filas().get(0);
            Map<String, Object> respuesta = new LinkedHashMap<>(consulta.respuesta("Respaldo generado: " + nombre + " ("
                    + conteo.tablas + " tablas, " + conteo.filas + " filas, " + conteo.vistas + " vistas, " + conteo.rutinas
                    + " rutinas y " + conteo.disparadores + " triggers). Guárdelo fuera del servidor.", admin));
            respuesta.put("respaldo", respaldo);
            return respuesta;
        } catch (IOException e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR,
                    "No se pudo escribir el respaldo en " + directorio + ": " + e.getMessage());
        } catch (SQLException e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "No se pudo leer la base de datos: " + e.getMessage());
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        } finally {
            if (temporal != null) {
                try {
                    Files.deleteIfExists(temporal);
                } catch (IOException ignorado) {
                    // el archivo parcial se puede borrar a mano
                }
            }
            enCurso.unlock();
        }
    }

    /** Archivo del respaldo para descargarlo; la descarga queda en la bitácora. */
    public Path archivo(Integer idRespaldo, Usuario admin, String ip) {
        Map<String, Object> respaldo = consulta.respaldo(idRespaldo);
        Path ruta = ruta(respaldo);
        if (!Files.isRegularFile(ruta)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                    "El archivo del respaldo ya no está en el servidor (" + respaldo.get("nombreArchivo") + ").");
        }
        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("id_respaldo", idRespaldo);
        detalle.put("archivo", respaldo.get("nombreArchivo"));
        detalle.put("ip", ip);
        bitacora.registrar(admin.getId(), null, "DESCARGAR_RESPALDO", detalle);
        return ruta;
    }

    /** Recalcula la huella SHA-256 del archivo y la compara con la registrada al generarlo. */
    public Map<String, Object> verificar(Integer idRespaldo, Usuario admin) {
        Map<String, Object> respaldo = consulta.respaldo(idRespaldo);
        Path ruta = ruta(respaldo);
        String registrada = AdministracionConsulta.texto(respaldo.get("hashSha256"));
        String calculada = null;
        long tamano = -1;
        String resultado;
        if (!Files.isRegularFile(ruta)) {
            resultado = "NO_ENCONTRADO";
        } else {
            try (InputStream in = new DigestInputStream(Files.newInputStream(ruta), MessageDigest.getInstance("SHA-256"))) {
                byte[] buffer = new byte[1 << 16];
                while (in.read(buffer) != -1) {
                    // solo se lee para calcular la huella
                }
                calculada = HexFormat.of().formatHex(((DigestInputStream) in).getMessageDigest().digest());
                tamano = Files.size(ruta);
            } catch (IOException e) {
                throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "No se pudo leer el respaldo: " + e.getMessage());
            } catch (NoSuchAlgorithmException e) {
                throw new IllegalStateException(e);
            }
            resultado = registrada.equalsIgnoreCase(calculada) ? "INTEGRO" : "ALTERADO";
        }
        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("id_respaldo", idRespaldo);
        detalle.put("archivo", respaldo.get("nombreArchivo"));
        detalle.put("resultado", resultado);
        bitacora.registrar(admin.getId(), null, "VERIFICAR_RESPALDO", detalle);

        Map<String, Object> verificacion = new LinkedHashMap<>();
        verificacion.put("idRespaldo", idRespaldo);
        verificacion.put("resultado", resultado);
        verificacion.put("hashRegistrado", registrada);
        verificacion.put("hashCalculado", calculada);
        verificacion.put("tamanoRegistrado", respaldo.get("tamanoBytes"));
        verificacion.put("tamanoActual", tamano < 0 ? null : tamano);
        verificacion.put("fecha", LocalDateTime.now().withNano(0));
        String mensaje = switch (resultado) {
            case "INTEGRO" -> "Respaldo íntegro: la huella SHA-256 del archivo coincide con la registrada al generarlo.";
            case "ALTERADO" -> "Respaldo alterado: la huella del archivo ya no coincide con la registrada. No lo use para restaurar.";
            default -> "El archivo del respaldo ya no está en el servidor.";
        };
        Map<String, Object> respuesta = new LinkedHashMap<>(consulta.respuesta(mensaje, admin));
        respuesta.put("verificacion", verificacion);
        return respuesta;
    }

    private Path ruta(Map<String, Object> respaldo) {
        String nombre = AdministracionConsulta.texto(respaldo.get("nombreArchivo"));
        if (!ARCHIVO.matcher(nombre).matches()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Nombre de archivo de respaldo no válido.");
        }
        return directorio.resolve(nombre);
    }

    // ─── Volcado ─────────────────────────────────────────────────────────────

    private void volcar(Connection cn, Writer out, Conteo conteo, Usuario admin, LocalDateTime inicio, String motivo)
            throws SQLException, IOException {
        boolean autoCommit = cn.getAutoCommit();
        try (Statement st = cn.createStatement()) {
            cn.setAutoCommit(true);
            st.execute("SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ");
            st.execute("START TRANSACTION WITH CONSISTENT SNAPSHOT");
            try {
                String base = unValor(st, "SELECT DATABASE()");
                String version = unValor(st, "SELECT VERSION()");
                List<String> tablas = new ArrayList<>();
                List<String> vistas = new ArrayList<>();
                try (ResultSet rs = st.executeQuery("SHOW FULL TABLES")) {
                    while (rs.next()) {
                        ("VIEW".equalsIgnoreCase(rs.getString(2)) ? vistas : tablas).add(rs.getString(1));
                    }
                }

                out.write("-- =====================================================================\n");
                out.write("-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  RESPALDO DE LA BASE DE DATOS (CUS18)\n");
                out.write("-- Base: " + base + " · MariaDB/MySQL " + version + "\n");
                out.write("-- Generado: " + inicio + " por " + admin.getUsername() + "\n");
                if (AdministracionConsulta.vacioANulo(motivo) != null) {
                    out.write("-- Motivo: " + motivo.trim().replaceAll("[\\r\\n]+", " ") + "\n");
                }
                out.write("-- Contiene: " + tablas.size() + " tablas con sus datos, funciones, " + vistas.size()
                        + " vistas, procedimientos y triggers.\n");
                out.write("-- Restaurar: phpMyAdmin > base elecciones_unp > Importar, o\n");
                out.write("--            mysql -u root elecciones_unp < este_archivo.sql\n");
                out.write("-- ATENCIÓN: reemplaza las tablas, vistas y rutinas de la base en la que se importa.\n");
                out.write("-- =====================================================================\n");
                out.write("SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;\n");
                out.write("SET @cus18_fk = @@FOREIGN_KEY_CHECKS, @cus18_uc = @@UNIQUE_CHECKS;\n");
                out.write("SET FOREIGN_KEY_CHECKS = 0, UNIQUE_CHECKS = 0;\n");
                out.write("SET SESSION sql_mode = 'NO_AUTO_VALUE_ON_ZERO,NO_ENGINE_SUBSTITUTION';\n");
                out.write("SET time_zone = '+00:00';\n\n");
                st.execute("SET SESSION time_zone = '+00:00'");

                // 1. Tablas y datos
                for (String tabla : tablas) {
                    out.write("-- ---------------------------------------------------------------------\n");
                    out.write("-- Tabla " + tabla + "\n");
                    out.write("-- ---------------------------------------------------------------------\n");
                    out.write("DROP TABLE IF EXISTS " + id(tabla) + ";\n");
                    out.write(segunda(st, "SHOW CREATE TABLE " + id(tabla)) + ";\n\n");
                    conteo.filas += datos(cn, out, tabla);
                    conteo.tablas++;
                }

                // Rutinas, separadas por tipo para crearlas en orden
                List<String[]> rutinas = new ArrayList<>();
                try (ResultSet rs = st.executeQuery("""
                        SELECT routine_name, routine_type FROM information_schema.routines
                         WHERE routine_schema = DATABASE() ORDER BY routine_type, routine_name
                        """)) {
                    while (rs.next()) {
                        rutinas.add(new String[] { rs.getString(1), rs.getString(2) });
                    }
                }

                // 2. Funciones (las usan las vistas y los triggers)
                out.write("-- =====================================================================\n-- Funciones\n");
                out.write("-- =====================================================================\nDELIMITER $$\n");
                for (String[] r : rutinas) {
                    if ("FUNCTION".equals(r[1])) {
                        out.write("DROP FUNCTION IF EXISTS " + id(r[0]) + "$$\n");
                        out.write(creacion(st, "SHOW CREATE FUNCTION " + id(r[0])));
                        conteo.rutinas++;
                    }
                }
                out.write("DELIMITER ;\n\n");

                // 3. Vistas, en orden de dependencia
                out.write("-- =====================================================================\n-- Vistas\n");
                out.write("-- =====================================================================\n");
                Map<String, String> definiciones = new LinkedHashMap<>();
                for (String vista : vistas) {
                    definiciones.put(vista, sinDefiner(segunda(st, "SHOW CREATE VIEW " + id(vista))));
                }
                for (String vista : ordenarVistas(definiciones)) {
                    out.write("DROP VIEW IF EXISTS " + id(vista) + ";\n");
                    out.write(definiciones.get(vista) + ";\n\n");
                    conteo.vistas++;
                }

                // 4. Procedimientos
                out.write("-- =====================================================================\n-- Procedimientos\n");
                out.write("-- =====================================================================\nDELIMITER $$\n");
                for (String[] r : rutinas) {
                    if ("PROCEDURE".equals(r[1])) {
                        out.write("DROP PROCEDURE IF EXISTS " + id(r[0]) + "$$\n");
                        out.write(creacion(st, "SHOW CREATE PROCEDURE " + id(r[0])));
                        conteo.rutinas++;
                    }
                }
                out.write("DELIMITER ;\n\n");

                // 5. Triggers al final: la carga de los datos no pasa por las reglas de la base
                out.write("-- =====================================================================\n-- Triggers\n");
                out.write("-- =====================================================================\nDELIMITER $$\n");
                List<String> triggers = new ArrayList<>();
                try (ResultSet rs = st.executeQuery("""
                        SELECT trigger_name FROM information_schema.triggers
                         WHERE trigger_schema = DATABASE() ORDER BY event_object_table, action_timing, event_manipulation, action_order
                        """)) {
                    while (rs.next()) {
                        triggers.add(rs.getString(1));
                    }
                }
                for (String trigger : triggers) {
                    out.write("DROP TRIGGER IF EXISTS " + id(trigger) + "$$\n");
                    out.write(creacion(st, "SHOW CREATE TRIGGER " + id(trigger)));
                    conteo.disparadores++;
                }
                out.write("DELIMITER ;\n\n");
                out.write("SET SESSION sql_mode = DEFAULT;\n");
                out.write("SET FOREIGN_KEY_CHECKS = @cus18_fk, UNIQUE_CHECKS = @cus18_uc;\n");
                out.write("-- Fin del respaldo: " + conteo.tablas + " tablas, " + conteo.filas + " filas.\n");
                out.flush();
            } finally {
                st.execute("COMMIT");
                st.execute("SET SESSION time_zone = DEFAULT");
            }
        } finally {
            cn.setAutoCommit(autoCommit);
        }
    }

    /** INSERT de todas las filas (sin las columnas generadas, que la base recalcula). */
    private long datos(Connection cn, Writer out, String tabla) throws SQLException, IOException {
        List<String> columnas = new ArrayList<>();
        try (var ps = cn.prepareStatement("""
                SELECT column_name FROM information_schema.columns
                 WHERE table_schema = DATABASE() AND table_name = ? AND extra NOT LIKE '%GENERATED%'
                 ORDER BY ordinal_position
                """)) {
            ps.setString(1, tabla);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    columnas.add(rs.getString(1));
                }
            }
        }
        StringBuilder lista = new StringBuilder();
        for (String c : columnas) {
            lista.append(lista.isEmpty() ? "" : ", ").append(id(c));
        }
        long filas = 0;
        try (Statement st = cn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY)) {
            st.setFetchSize(500);
            try (ResultSet rs = st.executeQuery("SELECT " + lista + " FROM " + id(tabla))) {
                ResultSetMetaData meta = rs.getMetaData();
                int n = meta.getColumnCount();
                int enLote = 0;
                while (rs.next()) {
                    out.write(enLote == 0 ? "INSERT INTO " + id(tabla) + " (" + lista + ") VALUES\n  (" : ",\n  (");
                    for (int i = 1; i <= n; i++) {
                        if (i > 1) {
                            out.write(", ");
                        }
                        out.write(valor(rs, meta, i));
                    }
                    out.write(")");
                    filas++;
                    if (++enLote == FILAS_POR_INSERT) {
                        out.write(";\n");
                        enLote = 0;
                    }
                }
                if (enLote > 0) {
                    out.write(";\n");
                }
            }
        }
        if (filas > 0) {
            out.write("\n");
        }
        return filas;
    }

    private static String valor(ResultSet rs, ResultSetMetaData meta, int i) throws SQLException {
        int tipo = meta.getColumnType(i);
        switch (tipo) {
            case Types.BINARY, Types.VARBINARY, Types.LONGVARBINARY, Types.BLOB -> {
                byte[] bytes = rs.getBytes(i);
                return bytes == null ? "NULL" : bytes.length == 0 ? "''" : "0x" + HexFormat.of().formatHex(bytes);
            }
            case Types.BIT, Types.BOOLEAN -> {
                Object o = rs.getObject(i);
                if (o == null) {
                    return "NULL";
                }
                if (o instanceof Boolean b) {
                    return b ? "1" : "0";
                }
                if (o instanceof byte[] bytes) {
                    return "0x" + HexFormat.of().formatHex(bytes);
                }
                return String.valueOf(o);
            }
            case Types.TINYINT, Types.SMALLINT, Types.INTEGER, Types.BIGINT, Types.DECIMAL, Types.NUMERIC,
                    Types.FLOAT, Types.REAL, Types.DOUBLE -> {
                String s = rs.getString(i);
                return s == null ? "NULL" : s;
            }
            default -> {
                String s = rs.getString(i);
                return s == null ? "NULL" : cadena(s);
            }
        }
    }

    static String cadena(String s) {
        StringBuilder sb = new StringBuilder(s.length() + 2).append('\'');
        for (int k = 0; k < s.length(); k++) {
            char c = s.charAt(k);
            switch (c) {
                case '\0' -> sb.append("\\0");
                case '\'' -> sb.append("\\'");
                case '\\' -> sb.append("\\\\");
                case '\n' -> sb.append("\\n");
                case '\r' -> sb.append("\\r");
                case '\u001a' -> sb.append("\\Z");
                default -> sb.append(c);
            }
        }
        return sb.append('\'').toString();
    }

    /** Una vista que usa otra va después de ella. */
    static List<String> ordenarVistas(Map<String, String> definiciones) {
        Set<String> listas = new LinkedHashSet<>();
        Set<String> visitando = new LinkedHashSet<>();
        for (String vista : definiciones.keySet()) {
            visitar(vista, definiciones, listas, visitando);
        }
        return new ArrayList<>(listas);
    }

    private static void visitar(String vista, Map<String, String> def, Set<String> listas, Set<String> visitando) {
        if (listas.contains(vista) || !visitando.add(vista)) {
            return;
        }
        String cuerpo = def.get(vista);
        int as = cuerpo.toUpperCase().indexOf(" AS ");
        String consulta = as < 0 ? cuerpo : cuerpo.substring(as);
        for (String otra : def.keySet()) {
            if (!otra.equals(vista) && consulta.contains("`" + otra + "`")) {
                visitar(otra, def, listas, visitando);
            }
        }
        visitando.remove(vista);
        listas.add(vista);
    }

    /** Rutina o trigger con el sql_mode con que se creó, para que se comporte igual al restaurarlo. */
    private static String creacion(Statement st, String sql) throws SQLException {
        try (ResultSet rs = st.executeQuery(sql)) {
            if (!rs.next()) {
                throw new SQLException("Sin resultado: " + sql);
            }
            String modo = rs.getString(2) == null ? "" : rs.getString(2);
            return "SET SESSION sql_mode = " + cadena(modo) + "$$\n" + sinDefiner(rs.getString(3)) + "$$\n\n";
        }
    }

    static String sinDefiner(String sql) {
        return DEFINER.matcher(sql).replaceFirst("");
    }

    private static String id(String nombre) {
        return "`" + nombre.replace("`", "``") + "`";
    }

    private static String unValor(Statement st, String sql) throws SQLException {
        return columna(st, sql, 1);
    }

    private static String segunda(Statement st, String sql) throws SQLException {
        return columna(st, sql, 2);
    }

    private static String columna(Statement st, String sql, int columna) throws SQLException {
        try (ResultSet rs = st.executeQuery(sql)) {
            if (!rs.next()) {
                throw new SQLException("Sin resultado: " + sql);
            }
            return rs.getString(columna);
        }
    }
}
