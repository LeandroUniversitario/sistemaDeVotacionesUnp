package pe.unp.elecciones.electoral.service;

import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.jdbc.core.CallableStatementCallback;
import org.springframework.jdbc.core.CallableStatementCreator;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.ResultSetExtractor;
import org.springframework.stereotype.Repository;

/**
 * Acceso a los procedimientos almacenados y vistas de la base de datos v2.
 *
 * IMPORTANTE: los procedimientos abren y confirman su propia transacción
 * (START TRANSACTION ... COMMIT). Por eso los servicios que usan esta clase
 * NO llevan @Transactional: una transacción de Spring abierta sobre la misma
 * conexión sería confirmada implícitamente por el START TRANSACTION.
 *
 * Las filas se devuelven como mapas con claves en camelCase
 * (numero_mesa -> numeroMesa) para que el JSON sea uniforme con el resto de la API.
 */
@Repository
public class ProcedimientoDao {

    /** Usar cuando el procedimiento no tiene parámetros OUT. */
    public static final int[] SIN_SALIDA = new int[0];

    private final JdbcTemplate jdbc;

    public ProcedimientoDao(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /**
     * @param salidas valores de los parámetros OUT, en orden
     * @param filas   primer conjunto de resultados que devuelve el procedimiento (puede estar vacío)
     */
    public record Resultado(Object[] salidas, List<Map<String, Object>> filas) {
    }

    /**
     * Ejecuta CALL nombre(entradas..., salidas...).
     * Los parámetros OUT siempre van al final, como en 04_procedimientos.sql.
     */
    public Resultado llamar(String nombre, int[] tiposSalida, Object... entradas) {
        final Object[] valores = entradas == null ? new Object[0] : entradas;
        final int total = valores.length + tiposSalida.length;
        final String sql = "{call " + nombre + "("
                + String.join(",", Collections.nCopies(total, "?")) + ")}";

        CallableStatementCreator creador = conexion -> {
            CallableStatement cs = conexion.prepareCall(sql);
            for (int i = 0; i < valores.length; i++) {
                if (valores[i] == null) {
                    cs.setNull(i + 1, Types.NULL);
                } else {
                    cs.setObject(i + 1, valores[i]);
                }
            }
            for (int j = 0; j < tiposSalida.length; j++) {
                cs.registerOutParameter(valores.length + j + 1, tiposSalida[j]);
            }
            return cs;
        };

        CallableStatementCallback<Resultado> lector = cs -> {
            List<Map<String, Object>> filas = new ArrayList<>();
            boolean primero = true;
            boolean hayResultSet = cs.execute();
            while (hayResultSet || cs.getUpdateCount() != -1) {
                if (hayResultSet) {
                    try (ResultSet rs = cs.getResultSet()) {
                        if (primero) {
                            filas = leerFilas(rs);
                            primero = false;
                        }
                    }
                }
                hayResultSet = cs.getMoreResults();
            }
            Object[] salidas = new Object[tiposSalida.length];
            for (int j = 0; j < tiposSalida.length; j++) {
                salidas[j] = cs.getObject(valores.length + j + 1);
            }
            return new Resultado(salidas, filas);
        };

        return jdbc.execute(creador, lector);
    }

    /** SELECT que devuelve varias filas (tablas o vistas). */
    public List<Map<String, Object>> consultar(String sql, Object... argumentos) {
        ResultSetExtractor<List<Map<String, Object>>> extractor = this::leerFilas;
        return jdbc.query(sql, extractor, argumentos);
    }

    /** SELECT COUNT(*) u otro entero. Devuelve 0 si el resultado es NULL. */
    public int entero(String sql, Object... argumentos) {
        Integer valor = jdbc.queryForObject(sql, Integer.class, argumentos);
        return valor == null ? 0 : valor;
    }

    private List<Map<String, Object>> leerFilas(ResultSet rs) throws SQLException {
        List<Map<String, Object>> filas = new ArrayList<>();
        ResultSetMetaData meta = rs.getMetaData();
        int columnas = meta.getColumnCount();
        while (rs.next()) {
            Map<String, Object> fila = new LinkedHashMap<>();
            for (int i = 1; i <= columnas; i++) {
                Object valor = rs.getObject(i);
                if (valor instanceof Timestamp timestamp) {
                    valor = timestamp.toLocalDateTime();
                }
                fila.put(aCamelCase(meta.getColumnLabel(i)), valor);
            }
            filas.add(fila);
        }
        return filas;
    }

    static String aCamelCase(String nombre) {
        StringBuilder sb = new StringBuilder();
        boolean mayuscula = false;
        for (char c : nombre.toCharArray()) {
            if (c == '_') {
                mayuscula = true;
            } else if (mayuscula) {
                sb.append(Character.toUpperCase(c));
                mayuscula = false;
            } else {
                sb.append(c);
            }
        }
        return sb.toString();
    }
}
