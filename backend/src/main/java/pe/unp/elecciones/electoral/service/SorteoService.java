package pe.unp.elecciones.electoral.service;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

/**
 * Sorteos auditables (RF06, RF07, RN18, RN19, RN20, RNF01).
 * El algoritmo vive en la base de datos: orden ascendente de SHA-256(semilla | DNI).
 * Con la semilla guardada cualquiera puede repetir el sorteo y obtener el mismo resultado.
 */
@Service
public class SorteoService {

    private static final SecureRandom ALEATORIO = new SecureRandom();

    private final ProcedimientoDao dao;

    public SorteoService(ProcedimientoDao dao) {
        this.dao = dao;
    }

    /**
     * Deja el proceso listo en un solo paso:
     * genera el padrón si aún no existe, crea las mesas si aún no existen
     * y sortea los 3 titulares y 3 suplentes de cada mesa pendiente.
     */
    public Map<String, Object> generarMesasYMiembros(Integer idProceso, Integer electoresPorMesa,
            String ubicacion, String semilla, Integer idUsuario) {

        if (dao.entero("SELECT COUNT(*) FROM proceso_electoral WHERE id_proceso = ?", idProceso) == 0) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Proceso electoral no encontrado");
        }

        if (dao.entero("SELECT COUNT(*) FROM padron_electoral WHERE id_proceso = ?", idProceso) == 0) {
            dao.llamar("sp_generar_padron", ProcedimientoDao.SIN_SALIDA, idProceso, idUsuario);
        }

        if (dao.entero("SELECT COUNT(*) FROM mesa_electoral WHERE id_proceso = ?", idProceso) == 0) {
            dao.llamar("sp_crear_mesas", ProcedimientoDao.SIN_SALIDA,
                    idProceso, electoresPorMesa, ubicacion, idUsuario);
        }

        int pendientes = dao.entero("""
                SELECT COUNT(*) FROM mesa_electoral m
                 WHERE m.id_proceso = ?
                   AND NOT EXISTS (SELECT 1 FROM miembro_mesa mm WHERE mm.id_mesa = m.id_mesa)
                """, idProceso);
        if (pendientes == 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "RN19: todas las mesas de este proceso ya fueron sorteadas.");
        }

        String semillaBase = (semilla == null || semilla.isBlank()) ? nuevaSemilla() : semilla.trim();
        ProcedimientoDao.Resultado resultado = dao.llamar("sp_sortear_todas_las_mesas",
                ProcedimientoDao.SIN_SALIDA, idProceso, semillaBase, idUsuario);

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Sorteo realizado con éxito. Se sortearon " + pendientes + " mesas.");
        respuesta.put("fechaSorteo", LocalDateTime.now());
        respuesta.put("semilla", semillaBase);
        respuesta.put("algoritmo",
                "Semilla de mesa = SHA256(semilla|numero_mesa). Orden = SHA256(semilla_mesa|DNI) ascendente.");
        respuesta.put("mesasSorteadas", pendientes);
        respuesta.put("miembros", resultado.filas());
        return respuesta;
    }

    /** RN18: orden de las listas admitidas en la cédula. */
    public Map<String, Object> sortearOrdenCedula(Integer idCargo, String semilla, Integer idUsuario) {
        String semillaFinal = (semilla == null || semilla.isBlank()) ? nuevaSemilla() : semilla.trim();
        ProcedimientoDao.Resultado resultado = dao.llamar("sp_sortear_orden_cedula",
                ProcedimientoDao.SIN_SALIDA, idCargo, semillaFinal, idUsuario);

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Orden de cédula sorteado.");
        respuesta.put("fechaSorteo", LocalDateTime.now());
        respuesta.put("semilla", semillaFinal);
        respuesta.put("algoritmo", "Orden = SHA256(semilla|id_lista) ascendente.");
        respuesta.put("listas", resultado.filas());
        return respuesta;
    }

    public List<Map<String, Object>> elegibles(Integer idProceso) {
        return dao.consultar("""
                SELECT DISTINCT id_docente, dni, docente, id_mesa
                  FROM v_elegibles_sorteo WHERE id_proceso = ? ORDER BY docente
                """, idProceso);
    }

    private static String nuevaSemilla() {
        byte[] bytes = new byte[32];
        ALEATORIO.nextBytes(bytes);
        return HexFormat.of().formatHex(bytes);
    }
}
