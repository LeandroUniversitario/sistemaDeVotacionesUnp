package pe.unp.elecciones.basedatos;

import static org.junit.jupiter.api.Assertions.*;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;

/**
 * Pruebas contra la base real (auditoría M6). Solo corren si se define ELECCIONES_DB_URL, por ejemplo:
 * ELECCIONES_DB_URL=jdbc:mariadb://localhost:3306/elecciones_unp DB_USERNAME=elecciones DB_PASSWORD=... mvn test
 * Cada prueba trabaja en una transacción que se deshace al final.
 */
@EnabledIfEnvironmentVariable(named = "ELECCIONES_DB_URL", matches = ".+")
class ReglasBaseDatosTest {

    private static Connection conectar() throws SQLException {
        Connection c = DriverManager.getConnection(System.getenv("ELECCIONES_DB_URL"),
                System.getenv().getOrDefault("DB_USERNAME", "elecciones"),
                System.getenv().getOrDefault("DB_PASSWORD", "elecciones"));
        c.setAutoCommit(false);
        return c;
    }

    private static String texto(Connection c, String sql) throws SQLException {
        try (Statement s = c.createStatement(); ResultSet rs = s.executeQuery(sql)) {
            return rs.next() ? rs.getString(1) : null;
        }
    }

    /** C1: el voto no tiene id secuencial ni hora exacta. */
    @Test
    void votoSinIdSecuencialNiHoraExacta() throws SQLException {
        try (Connection c = conectar()) {
            assertEquals("binary(16)", texto(c, """
                    SELECT LOWER(COLUMN_TYPE) FROM information_schema.COLUMNS
                     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'voto' AND COLUMN_NAME = 'id_voto'"""));
            assertEquals("0", texto(c, "SELECT COUNT(*) FROM voto WHERE MINUTE(fecha_hora) <> 0 OR SECOND(fecha_hora) <> 0"));
            assertEquals("0", texto(c, """
                    SELECT COUNT(*) FROM padron_electoral
                     WHERE fecha_votacion IS NOT NULL AND (MINUTE(fecha_votacion) <> 0 OR SECOND(fecha_votacion) <> 0)"""));
        }
    }

    /** M3: no se acepta un quórum por debajo del mínimo legal (parámetro QUORUM_MINIMO_LEGAL_PCT). */
    @Test
    void quorumDebajoDelMinimoLegalSeRechaza() throws SQLException {
        try (Connection c = conectar(); Statement s = c.createStatement()) {
            double minimo = Double.parseDouble(texto(c, "SELECT COALESCE(fn_parametro_decimal('QUORUM_MINIMO_LEGAL_PCT'), 60)"));
            org.junit.jupiter.api.Assumptions.assumeTrue(minimo > 0, "el mínimo legal está en 0");
            double debajo = Math.max(0, minimo - 1);
            SQLException e = assertThrows(SQLException.class, () -> s.executeUpdate(
                    "INSERT INTO proceso_electoral (nombre, fecha_inicio, fecha_fin, quorum_minimo) "
                    + "VALUES ('prueba quorum', NOW() + INTERVAL 40 DAY, NOW() + INTERVAL 41 DAY, " + debajo + ")"));
            assertEquals("45000", e.getSQLState());
            assertTrue(e.getMessage().contains("RN31"));
            c.rollback();
        }
    }

    /** M3: RN02 (convocatoria entre 30 y 45 días antes) ahora también la valida la base. */
    @Test
    void convocatoriaFueraDeRN02SeRechaza() throws SQLException {
        try (Connection c = conectar(); Statement s = c.createStatement()) {
            SQLException e = assertThrows(SQLException.class, () -> s.executeUpdate("""
                    INSERT INTO proceso_electoral (nombre, fecha_inicio, fecha_fin, quorum_minimo, fecha_convocatoria)
                    VALUES ('prueba RN02', NOW() + INTERVAL 10 DAY, NOW() + INTERVAL 11 DAY, 100, CURDATE())"""));
            assertTrue(e.getMessage().contains("RN02"));
            c.rollback();
        }
    }

    /** M8: una consulta anónima con un código inexistente no escribe en la base. */
    @Test
    void verificacionAnonimaDeCodigoInexistenteNoEscribe() throws SQLException {
        try (Connection c = conectar()) {
            String antes = texto(c, "SELECT COUNT(*) FROM verificacion_documento");
            try (CallableStatement cs = c.prepareCall("{CALL sp_verificar_documento(?, 'WEB', NULL, '203.0.113.9')}")) {
                cs.setString(1, "codigo-que-no-existe-" + System.nanoTime());
                try {
                    cs.execute();
                } catch (SQLException ignorada) {
                    // un código inexistente puede responder con error de negocio; lo que importa es no escribir
                }
            }
            assertEquals(antes, texto(c, "SELECT COUNT(*) FROM verificacion_documento"));
            c.rollback();
        }
    }

    /** RN32: el proceso no se cierra con mesas abiertas (la regla vive en el procedimiento). */
    @Test
    void cierreConMesasAbiertasLoImpideElProcedimiento() throws SQLException {
        try (Connection c = conectar()) {
            String cuerpo = texto(c, """
                    SELECT ROUTINE_DEFINITION FROM information_schema.ROUTINES
                     WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_NAME = 'sp_cambiar_estado_proceso'""");
            assertNotNull(cuerpo);
            assertTrue(cuerpo.contains("RN32"), "sp_cambiar_estado_proceso debe validar RN32");
        }
    }
}
