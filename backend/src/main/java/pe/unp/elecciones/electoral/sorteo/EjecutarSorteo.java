package pe.unp.elecciones.electoral.sorteo;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS06 · Control «EjecutarSorteo» del diagrama de colaboración.
 *
 * <pre>
 *  PantallaSorteoMesa --7: generarAleatoriedad(semilla)--> EjecutarSorteo
 *  EjecutarSorteo     --seleccionarSeisMiembros()--> EjecutarSorteo
 *  EjecutarSorteo     --8: guardarResultados(lista_sorteados)--> GrabarMiembrosMesa
 * </pre>
 *
 * Algoritmo (RNF01, auditable y reproducible), idéntico al de sp_sortear_miembros_mesa:
 * <ol>
 *   <li>semilla de la mesa = SHA-256(semillaBase + "|" + numero_mesa)</li>
 *   <li>los elegibles de la mesa se ordenan por SHA-256(semillaMesa + "|" + dni)</li>
 *   <li>los 6 primeros: 1 Presidente, 2 Secretario, 3 Vocal (titulares), 4-6 Suplentes (RN19)</li>
 * </ol>
 * Con la misma semilla cualquiera puede repetir el cálculo y obtener los mismos miembros.
 */
@Service
public class EjecutarSorteo {

    private static final String[] ROLES = {"PRESIDENTE", "SECRETARIO", "VOCAL", "SUPLENTE", "SUPLENTE", "SUPLENTE"};
    private static final SecureRandom AZAR = new SecureRandom();

    private final ProcedimientoDao dao;
    private final SorteoConsulta consulta;

    public EjecutarSorteo(ProcedimientoDao dao, SorteoConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** Semilla definitiva de un sorteo y los datos para verificarla después. */
    public record Semilla(String semilla, String secretoServidor, String aporteOperador, String compromiso) {
    }

    /**
     * M2 · Compromiso del sorteo (commit-reveal). El servidor fija un secreto por ámbito y antes del
     * sorteo solo publica su SHA-256. Así el operador no puede probar semillas en la vista previa
     * hasta dar con el resultado que le conviene.
     */
    public String compromiso(String ambito) {
        String secreto = nuevoSecreto();
        dao.ejecutar("""
                INSERT IGNORE INTO sorteo_compromiso (ambito, secreto, compromiso) VALUES (?, ?, SHA2(?, 256))
                """, ambito, secreto, secreto);
        return String.valueOf(dao.consultar("SELECT compromiso FROM sorteo_compromiso WHERE ambito = ?", ambito)
                .get(0).get("compromiso"));
    }

    /**
     * 7: generarAleatoriedad(semilla). Semilla = SHA-256(secreto del servidor | aporte del operador).
     * El aporte puede ser público (por ejemplo, el número de una lotería acordado en el acto). Tras
     * usarse, el secreto se revela en la respuesta y se descarta: el siguiente sorteo usa uno nuevo.
     */
    public Semilla semillaDefinitiva(String ambito, String aporteOperador) {
        String aporte = aporteOperador == null ? "" : aporteOperador.trim();
        if (!aporte.isEmpty() && !aporte.matches("[\\p{Print}]{1,128}")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "La semilla solo admite caracteres imprimibles (máximo 128).");
        }
        String compromiso = compromiso(ambito);
        String secreto = String.valueOf(dao.consultar("SELECT secreto FROM sorteo_compromiso WHERE ambito = ?", ambito)
                .get(0).get("secreto"));
        dao.ejecutar("DELETE FROM sorteo_compromiso WHERE ambito = ?", ambito);
        return new Semilla(sha256(secreto + "|" + aporte), secreto, aporte, compromiso);
    }

    private static String nuevoSecreto() {
        byte[] bytes = new byte[32];
        AZAR.nextBytes(bytes);
        return HexFormat.of().formatHex(bytes);
    }

    /** Resultado del sorteo de todas las mesas pendientes, sin grabar (vista previa y control). */
    public List<Map<String, Object>> sortearMesasPendientes(Integer idProceso, String semillaBase) {
        List<Map<String, Object>> resultado = new ArrayList<>();
        for (Map<String, Object> mesa : consulta.mesas(idProceso)) {
            if (((Number) mesa.get("miembros")).intValue() > 0) {
                continue;   // RN19: una mesa sorteada no se vuelve a sortear
            }
            String numero = String.valueOf(mesa.get("numeroMesa"));
            String semillaMesa = sha256(semillaBase + "|" + numero);
            List<Map<String, Object>> elegibles = dao.consultar("""
                    SELECT DISTINCT id_docente, dni, docente FROM v_elegibles_sorteo
                     WHERE id_proceso = ? AND id_mesa = ?
                    """, idProceso, mesa.get("id"));

            Map<String, Object> fila = new LinkedHashMap<>();
            fila.put("idMesa", mesa.get("id"));
            fila.put("numeroMesa", numero);
            fila.put("semillaMesa", semillaMesa);
            fila.put("elegibles", elegibles.size());
            fila.put("miembros", seleccionarSeisMiembros(semillaMesa, elegibles));
            fila.put("suficientes", elegibles.size() >= 6);
            resultado.add(fila);
        }
        return resultado;
    }

    /** seleccionarSeisMiembros() — orden por SHA-256(semillaMesa|dni) y toma los 6 primeros. */
    private List<Map<String, Object>> seleccionarSeisMiembros(String semillaMesa, List<Map<String, Object>> elegibles) {
        List<Map<String, Object>> ordenados = new ArrayList<>(elegibles);
        ordenados.sort(Comparator.comparing(e -> sha256(semillaMesa + "|" + e.get("dni"))));
        List<Map<String, Object>> seis = new ArrayList<>();
        for (int i = 0; i < Math.min(6, ordenados.size()); i++) {
            Map<String, Object> e = ordenados.get(i);
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("ordenSorteo", i + 1);
            m.put("rol", ROLES[i]);
            m.put("titular", i < 3);
            m.put("idDocente", e.get("idDocente"));
            m.put("dni", e.get("dni"));
            m.put("docente", e.get("docente"));
            seis.add(m);
        }
        return seis;
    }

    /** SHA-256 en hexadecimal minúscula, igual que SHA2(texto, 256) de MariaDB. */
    static String sha256(String texto) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(md.digest(texto.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 no disponible", e);
        }
    }
}
