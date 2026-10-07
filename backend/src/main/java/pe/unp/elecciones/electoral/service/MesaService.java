package pe.unp.elecciones.electoral.service;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

/**
 * Operación de las mesas de sufragio el día de la elección
 * (RN05, RN07, RN19, RN27, RN28).
 * Sin @Transactional a propósito (ver ProcedimientoDao).
 */
@Service
public class MesaService {

    private static final String SELECT_MESA = """
            SELECT m.id_mesa AS id, m.numero_mesa AS numero, m.ubicacion, m.estado,
                   m.total_electores, m.hora_instalacion, m.hora_cierre,
                   m.fecha_sorteo, m.semilla_sorteo,
                   m.id_proceso, p.nombre AS proceso, p.estado AS estado_proceso,
                   (SELECT COUNT(*) FROM miembro_mesa mm WHERE mm.id_mesa = m.id_mesa) AS miembros,
                   (SELECT COUNT(DISTINCT pe.id_docente) FROM padron_electoral pe
                     WHERE pe.id_mesa = m.id_mesa AND pe.ya_voto = 1) AS electores_que_votaron
              FROM mesa_electoral m
              JOIN proceso_electoral p ON p.id_proceso = m.id_proceso
            """;

    private final ProcedimientoDao dao;

    public MesaService(ProcedimientoDao dao) {
        this.dao = dao;
    }

    public List<Map<String, Object>> listarMesas(Integer idProceso) {
        if (idProceso == null) {
            return dao.consultar(SELECT_MESA + " ORDER BY m.id_proceso DESC, m.numero_mesa");
        }
        return dao.consultar(SELECT_MESA + " WHERE m.id_proceso = ? ORDER BY m.numero_mesa", idProceso);
    }

    /** Mesas en las que el docente es miembro (para el rol MIEMBRO_MESA). */
    public List<Map<String, Object>> listarMesasDeMiembro(Integer idDocente) {
        return dao.consultar(SELECT_MESA + """
                 WHERE EXISTS (SELECT 1 FROM miembro_mesa x
                                WHERE x.id_mesa = m.id_mesa AND x.id_docente = ?)
                 ORDER BY m.id_proceso DESC, m.numero_mesa
                """, idDocente);
    }

    public Map<String, Object> obtenerMesa(Integer idMesa) {
        List<Map<String, Object>> filas = dao.consultar(SELECT_MESA + " WHERE m.id_mesa = ?", idMesa);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Mesa no encontrada");
        }
        return filas.get(0);
    }

    public boolean esMiembro(Integer idMesa, Integer idDocente) {
        if (idDocente == null) {
            return false;
        }
        return dao.entero("SELECT COUNT(*) FROM miembro_mesa WHERE id_mesa = ? AND id_docente = ?",
                idMesa, idDocente) > 0;
    }

    public List<Map<String, Object>> miembros(Integer idMesa) {
        obtenerMesa(idMesa);
        return dao.consultar("""
                SELECT id_docente, dni, docente, facultad, rol, titular, orden_sorteo, asistio
                  FROM v_miembros_mesa WHERE id_mesa = ? ORDER BY orden_sorteo
                """, idMesa);
    }

    /** RN07 / RN28: instala la mesa y emite el acta de instalación. */
    public Map<String, Object> instalar(Integer idMesa, Integer idUsuario) {
        ProcedimientoDao.Resultado resultado =
                dao.llamar("sp_instalar_mesa", ProcedimientoDao.SIN_SALIDA, idMesa, idUsuario);
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Mesa instalada. Se emitió el acta de instalación.");
        respuesta.put("mesa", obtenerMesa(idMesa));
        respuesta.put("actas", resultado.filas());
        return respuesta;
    }

    /** RN27 / RN28: cierra la mesa y emite las actas de sufragio y escrutinio. */
    public Map<String, Object> cerrar(Integer idMesa, Integer idUsuario) {
        ProcedimientoDao.Resultado resultado =
                dao.llamar("sp_cerrar_mesa", ProcedimientoDao.SIN_SALIDA, idMesa, idUsuario);
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Mesa cerrada. Se emitieron las actas de sufragio y escrutinio.");
        respuesta.put("mesa", obtenerMesa(idMesa));
        respuesta.put("actas", resultado.filas());
        return respuesta;
    }

    /** RN04 / RN05 / RN30: comprueba que el DNI pertenece al padrón de la mesa. */
    public Map<String, Object> verificarElector(Integer idMesa, String dni) {
        obtenerMesa(idMesa);
        String dniNormalizado = normalizarDni(dni);
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT d.id_docente, d.dni, d.nombres, d.apellidos, d.categoria,
                       MIN(pe.id_proceso)            AS id_proceso,
                       MIN(pe.habilitado_para_votar) AS habilitado,
                       COUNT(*)                      AS cargos,
                       SUM(pe.ya_voto)               AS cargos_votados
                  FROM padron_electoral pe
                  JOIN docente d ON d.id_docente = pe.id_docente
                 WHERE pe.id_mesa = ? AND d.dni = ?
                 GROUP BY d.id_docente, d.dni, d.nombres, d.apellidos, d.categoria
                """, idMesa, dniNormalizado);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                    "RN04: el DNI no figura en el padrón de esta mesa.");
        }
        Map<String, Object> fila = filas.get(0);
        int cargos = numero(fila.get("cargos"));
        int votados = numero(fila.get("cargosVotados"));

        Map<String, Object> elector = new LinkedHashMap<>();
        elector.put("idDocente", fila.get("idDocente"));
        elector.put("idProceso", fila.get("idProceso"));
        elector.put("dni", fila.get("dni"));
        elector.put("nombres", fila.get("nombres"));
        elector.put("apellidos", fila.get("apellidos"));
        elector.put("categoria", fila.get("categoria"));
        elector.put("habilitado", numero(fila.get("habilitado")) == 1);
        elector.put("cargos", cargos);
        elector.put("cargosVotados", votados);
        elector.put("yaVoto", cargos > 0 && votados >= cargos);
        return elector;
    }

    /**
     * RN05: el miembro de mesa deja constancia de que identificó al elector con su DNI.
     * Solo registra el hecho en la bitácora; el voto lo marca sp_emitir_voto.
     */
    public Map<String, Object> registrarIdentificacionElector(Integer idMesa, String dni, Integer idUsuario) {
        Map<String, Object> mesa = obtenerMesa(idMesa);
        if (!"INSTALADA".equals(String.valueOf(mesa.get("estado")))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "RN07: la mesa debe estar INSTALADA para atender electores.");
        }
        Map<String, Object> elector = verificarElector(idMesa, dni);
        if (!Boolean.TRUE.equals(elector.get("habilitado"))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "RN04: el docente no está habilitado para votar.");
        }
        if (Boolean.TRUE.equals(elector.get("yaVoto"))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "RN01: el docente ya votó.");
        }
        dao.llamar("sp_registrar_auditoria", ProcedimientoDao.SIN_SALIDA,
                idUsuario, elector.get("idDocente"), elector.get("idProceso"),
                "IDENTIFICAR_ELECTOR", "{\"id_mesa\":" + idMesa + "}");

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Elector identificado. Puede pasar a la cabina de votación.");
        respuesta.put("elector", elector);
        return respuesta;
    }

    /** Asistencia de un miembro de mesa (insumo de la multa OMISO_MESA, RN35). */
    public List<Map<String, Object>> registrarAsistenciaMiembro(Integer idMesa, Integer idDocente, boolean asistio) {
        dao.llamar("sp_registrar_asistencia_miembro", ProcedimientoDao.SIN_SALIDA, idMesa, idDocente, asistio);
        return miembros(idMesa);
    }

    /** Actas emitidas por la mesa (sin el token del QR, que solo se entrega al emitirlas). */
    public List<Map<String, Object>> actas(Integer idMesa) {
        obtenerMesa(idMesa);
        return dao.consultar("""
                SELECT id_acta, tipo, fecha_emision, estado, hash_integridad, contenido_json
                  FROM acta_electoral WHERE id_mesa = ? ORDER BY id_acta
                """, idMesa);
    }

    private static int numero(Object valor) {
        if (valor instanceof Number n) {
            return n.intValue();
        }
        if (valor instanceof Boolean b) {
            return b ? 1 : 0;
        }
        return 0;
    }

    private static String normalizarDni(String dni) {
        String limpio = dni == null ? "" : dni.trim();
        if (limpio.matches("\\d{1,8}")) {
            return String.format("%08d", Long.parseLong(limpio));
        }
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El DNI debe tener hasta 8 dígitos.");
    }
}
