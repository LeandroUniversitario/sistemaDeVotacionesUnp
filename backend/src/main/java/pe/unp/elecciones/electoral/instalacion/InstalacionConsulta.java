package pe.unp.elecciones.electoral.instalacion;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Types;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS08 · Lecturas de la PantallaInstalacion: mesas, miembros, personeros, material,
 * horario de instalación (RN07) y requisitos que faltan para instalar.
 */
@Service
public class InstalacionConsulta {

    static final List<String> CARGOS = List.of("PRESIDENTE", "SECRETARIO", "VOCAL");

    private static final String SELECT_MESA = """
            SELECT m.id_mesa AS id, m.numero_mesa AS numero, m.ubicacion, m.estado, m.total_electores,
                   m.hora_instalacion, m.id_proceso, p.nombre AS proceso, p.estado AS estado_proceso,
                   p.fecha_inicio, p.fecha_fin,
                   (SELECT COUNT(*) FROM miembro_mesa mm WHERE mm.id_mesa = m.id_mesa) AS miembros,
                   (SELECT COUNT(*) FROM miembro_mesa mm WHERE mm.id_mesa = m.id_mesa AND mm.asistio = 1) AS presentes,
                   (SELECT COUNT(*) FROM asistencia_personero_mesa ap WHERE ap.id_mesa = m.id_mesa) AS personeros_presentes,
                   COALESCE(im.material_completo, 0) AS material_completo
              FROM mesa_electoral m
              JOIN proceso_electoral p ON p.id_proceso = m.id_proceso
              LEFT JOIN instalacion_mesa im ON im.id_mesa = m.id_mesa
            """;
    private static final String ORDEN_MESAS = " ORDER BY m.id_proceso DESC, LENGTH(m.numero_mesa), m.numero_mesa";

    private final ProcedimientoDao dao;
    private final ObjectMapper json;
    private volatile boolean instalada;

    public InstalacionConsulta(ProcedimientoDao dao, ObjectMapper json) {
        this.dao = dao;
        this.json = json;
    }

    /** Falla con un mensaje claro si falta ejecutar la migración del CUS08. */
    void verificarInstalacion() {
        if (instalada) {
            return;
        }
        int existe = dao.entero("""
                SELECT COUNT(*) FROM information_schema.tables
                 WHERE table_schema = DATABASE() AND table_name = 'instalacion_mesa'
                """);
        if (existe == 0) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Falta la tabla instalacion_mesa: ejecute base-de-datos/09_instalacion_mesa.sql en la base de datos.");
        }
        instalada = true;
    }

    // ─── Procesos y mesas ────────────────────────────────────────────────────

    public List<Map<String, Object>> procesos() {
        verificarInstalacion();
        return dao.consultar("""
                SELECT p.id_proceso AS id, p.nombre, p.estado, p.fecha_inicio, p.fecha_fin,
                       COUNT(m.id_mesa) AS mesas,
                       COALESCE(SUM(m.estado = 'INSTALADA' OR m.estado = 'CERRADA'), 0) AS instaladas,
                       COALESCE(SUM(m.estado = 'PENDIENTE'), 0) AS pendientes,
                       COALESCE(SUM(m.estado = 'NO_INSTALADA'), 0) AS no_instaladas
                  FROM proceso_electoral p
                  LEFT JOIN mesa_electoral m ON m.id_proceso = p.id_proceso
                 WHERE p.estado <> 'ANULADO'
                 GROUP BY p.id_proceso, p.nombre, p.estado, p.fecha_inicio, p.fecha_fin
                 ORDER BY (p.estado = 'VOTACION') DESC, p.fecha_inicio DESC
                """);
    }

    public List<Map<String, Object>> mesas(Integer idProceso) {
        verificarInstalacion();
        if (idProceso == null) {
            return dao.consultar(SELECT_MESA + " WHERE p.estado <> 'ANULADO'" + ORDEN_MESAS);
        }
        return dao.consultar(SELECT_MESA + " WHERE m.id_proceso = ?" + ORDEN_MESAS, idProceso);
    }

    /** Mesas en las que el docente fue sorteado (rol MIEMBRO_MESA). */
    public List<Map<String, Object>> mesasDeMiembro(Integer idDocente) {
        verificarInstalacion();
        return dao.consultar(SELECT_MESA + """
                 WHERE p.estado <> 'ANULADO'
                   AND EXISTS (SELECT 1 FROM miembro_mesa x WHERE x.id_mesa = m.id_mesa AND x.id_docente = ?)
                """ + ORDEN_MESAS, idDocente);
    }

    public Map<String, Object> mesa(Integer idMesa) {
        verificarInstalacion();
        List<Map<String, Object>> filas = dao.consultar(SELECT_MESA + " WHERE m.id_mesa = ?", idMesa);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Mesa no encontrada.");
        }
        return filas.get(0);
    }

    /** La mesa admite acreditaciones y registro de material: proceso en VOTACION y mesa PENDIENTE. */
    Map<String, Object> mesaEditable(Integer idMesa) {
        Map<String, Object> mesa = mesa(idMesa);
        if (!"VOTACION".equals(String.valueOf(mesa.get("estadoProceso")))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "RN07: la instalación se realiza el día de la elección, con el proceso en VOTACION (hoy está "
                            + mesa.get("estadoProceso") + ").");
        }
        if (!"PENDIENTE".equals(String.valueOf(mesa.get("estado")))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "La mesa está " + mesa.get("estado") + ": su instalación ya terminó.");
        }
        return mesa;
    }

    public boolean esMiembro(Integer idMesa, Integer idDocente) {
        return idDocente != null && dao.entero(
                "SELECT COUNT(*) FROM miembro_mesa WHERE id_mesa = ? AND id_docente = ?", idMesa, idDocente) > 0;
    }

    public boolean miembroPresente(Integer idMesa, Integer idDocente) {
        return idDocente != null && dao.entero(
                "SELECT COUNT(*) FROM miembro_mesa WHERE id_mesa = ? AND id_docente = ? AND asistio = 1",
                idMesa, idDocente) > 0;
    }

    // ─── Detalle de la mesa ──────────────────────────────────────────────────

    public Map<String, Object> detalle(Integer idMesa) {
        Map<String, Object> mesa = mesa(idMesa);
        Integer idProceso = numero(mesa.get("idProceso"));
        String estado = String.valueOf(mesa.get("estado"));
        boolean pendiente = "PENDIENTE".equals(estado);
        boolean enVotacion = "VOTACION".equals(String.valueOf(mesa.get("estadoProceso")));

        List<Map<String, Object>> miembros = miembros(idMesa);
        List<Map<String, Object>> conformacion = conformacion(miembros, !pendiente);
        Map<String, Object> registro = registro(idMesa);
        List<Map<String, Object>> material = material(registro);
        Map<String, Object> ventana = ventana(idProceso);

        boolean cargosCubiertos = conformacion.stream().noneMatch(c -> Boolean.TRUE.equals(c.get("vacante")));
        boolean materialCompleto = verdadero(mesa.get("materialCompleto"));
        List<Map<String, Object>> requisitos = new ArrayList<>();
        requisitos.add(requisito("PROCESO", "Proceso electoral en VOTACION", enVotacion,
                enVotacion ? null : "El proceso está " + mesa.get("estadoProceso") + "."));
        requisitos.add(requisito("HORARIO", "Dentro del horario de instalación (RN07)",
                Boolean.TRUE.equals(ventana.get("abierta")), String.valueOf(ventana.get("mensaje"))));
        requisitos.add(requisito("SORTEO", "Mesa con sus 6 miembros sorteados (RN19)", miembros.size() == 6,
                miembros.size() == 6 ? null : "La mesa tiene " + miembros.size() + " miembro(s); complete el sorteo (CUS06)."));
        requisitos.add(requisito("CONFORMACION", "Presidente, secretario y vocal presentes", cargosCubiertos,
                cargosCubiertos ? null : "Acredite a los miembros; un suplente presente reemplaza al titular ausente."));
        requisitos.add(requisito("MATERIAL", "Material electoral obligatorio recibido", materialCompleto,
                materialCompleto ? null : "Marque el material recibido y guárdelo."));

        boolean cumple = requisitos.stream().allMatch(r -> Boolean.TRUE.equals(r.get("cumplido")));
        boolean puedeDeclarar = pendiente && enVotacion
                && (!Boolean.TRUE.equals(ventana.get("control")) || Boolean.TRUE.equals(ventana.get("vencida")));

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mesa", mesa);
        respuesta.put("ventana", ventana);
        respuesta.put("miembros", miembros);
        respuesta.put("conformacion", conformacion);
        respuesta.put("personeros", personeros(idMesa, idProceso));
        respuesta.put("material", material);
        respuesta.put("observaciones", registro == null ? null : registro.get("observaciones"));
        respuesta.put("registro", registro);
        respuesta.put("requisitos", requisitos);
        respuesta.put("editable", pendiente && enVotacion);
        respuesta.put("puedeInstalar", pendiente && cumple);
        respuesta.put("puedeDeclararNoInstalada", puedeDeclarar);
        respuesta.put("acta", acta(idMesa));
        return respuesta;
    }

    List<Map<String, Object>> miembros(Integer idMesa) {
        return dao.consultar("""
                SELECT mm.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS nombre, d.categoria,
                       f.nombre AS facultad, mm.rol, mm.titular, mm.orden_sorteo, mm.asistio,
                       mm.hora_acreditacion, mm.metodo_acreditacion, mm.rol_instalacion,
                       (SELECT COUNT(*) FROM credencial_qr cq
                         WHERE cq.tipo = 'MIEMBRO_MESA' AND cq.id_mesa = mm.id_mesa
                           AND cq.id_docente = mm.id_docente AND cq.estado = 'VIGENTE') AS credencial_vigente
                  FROM miembro_mesa mm
                  JOIN docente d ON d.id_docente = mm.id_docente
                  LEFT JOIN facultad f ON f.id_facultad = d.id_facultad
                 WHERE mm.id_mesa = ?
                 ORDER BY mm.orden_sorteo, mm.titular DESC
                """, idMesa);
    }

    /**
     * Quién ejerce cada cargo. Antes de instalar es una propuesta con la misma regla que
     * sp_instalar_mesa (titular presente o el primer suplente presente según el sorteo);
     * después de instalar es lo que quedó registrado en rol_instalacion.
     */
    static List<Map<String, Object>> conformacion(List<Map<String, Object>> miembros, boolean registrada) {
        List<Map<String, Object>> cargos = new ArrayList<>();
        Set<Object> usados = new HashSet<>();
        for (String cargo : CARGOS) {
            Map<String, Object> titular = miembros.stream()
                    .filter(m -> verdadero(m.get("titular")) && cargo.equals(m.get("rol")))
                    .findFirst().orElse(null);
            Map<String, Object> ejerce;
            if (registrada) {
                ejerce = miembros.stream().filter(m -> cargo.equals(m.get("rolInstalacion"))).findFirst().orElse(null);
            } else if (titular != null && verdadero(titular.get("asistio"))) {
                ejerce = titular;
            } else {
                ejerce = miembros.stream()
                        .filter(m -> !verdadero(m.get("titular"))
                                && verdadero(m.get("asistio"))
                                && !usados.contains(m.get("idDocente")))
                        .findFirst().orElse(null);
            }
            Map<String, Object> fila = new LinkedHashMap<>();
            fila.put("cargo", cargo);
            fila.put("vacante", ejerce == null);
            if (ejerce != null) {
                usados.add(ejerce.get("idDocente"));
                boolean reemplazo = !verdadero(ejerce.get("titular"));
                fila.put("idDocente", ejerce.get("idDocente"));
                fila.put("nombre", ejerce.get("nombre"));
                fila.put("dni", ejerce.get("dni"));
                fila.put("reemplazo", reemplazo);
                if (reemplazo && titular != null) {
                    fila.put("reemplazaA", titular.get("nombre"));
                }
            }
            if (titular != null) {
                fila.put("titular", titular.get("nombre"));
            }
            cargos.add(fila);
        }
        return cargos;
    }

    /** Personeros que pueden presenciar la instalación: los de esta mesa y los generales o alternos. */
    List<Map<String, Object>> personeros(Integer idMesa, Integer idProceso) {
        return dao.consultar("""
                SELECT pe.id_personero, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS nombre, pe.tipo, pe.id_mesa,
                       l.nombre AS lista, c.nombre AS cargo,
                       ap.hora_acreditacion, ap.metodo, (ap.id_personero IS NOT NULL) AS presente
                  FROM personero pe
                  JOIN lista_electoral l ON l.id_lista = pe.id_lista
                  JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                  JOIN docente d ON d.id_docente = pe.id_docente
                  LEFT JOIN asistencia_personero_mesa ap ON ap.id_personero = pe.id_personero AND ap.id_mesa = ?
                 WHERE c.id_proceso = ?
                   AND ((pe.estado_acreditacion = 'ACREDITADO' AND l.estado IN ('INSCRITA', 'ADMITIDA')
                         AND (pe.tipo <> 'MESA' OR pe.id_mesa = ?))
                        OR ap.id_personero IS NOT NULL)
                 ORDER BY (ap.id_personero IS NULL), FIELD(pe.tipo, 'MESA', 'GENERAL', 'ALTERNO'), l.nombre, d.apellidos
                """, idMesa, idProceso, idMesa);
    }

    Map<String, Object> registro(Integer idMesa) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT im.estado, im.material_json, im.material_completo, im.observaciones, im.fecha_inicio,
                       im.fecha_actualizacion, im.hora_instalacion, im.motivo_no_instalacion,
                       u.username AS registrado_por, uc.username AS cerrado_por
                  FROM instalacion_mesa im
                  LEFT JOIN usuario u ON u.id_usuario = im.id_usuario_registro
                  LEFT JOIN usuario uc ON uc.id_usuario = im.id_usuario_cierre
                 WHERE im.id_mesa = ?
                """, idMesa);
        return filas.isEmpty() ? null : filas.get(0);
    }

    /** Lista completa del material con lo que se marcó como recibido. */
    List<Map<String, Object>> material(Map<String, Object> registro) {
        Map<String, Boolean> recibido = Map.of();
        if (registro != null && registro.get("materialJson") != null) {
            try {
                recibido = json.readValue(String.valueOf(registro.remove("materialJson")),
                        new TypeReference<Map<String, Boolean>>() { });
            } catch (Exception e) {
                recibido = Map.of();
            }
        } else if (registro != null) {
            registro.remove("materialJson");
        }
        List<Map<String, Object>> items = new ArrayList<>();
        for (MaterialElectoral m : MaterialElectoral.values()) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("codigo", m.name());
            item.put("descripcion", m.descripcion());
            item.put("obligatorio", m.obligatorio());
            item.put("recibido", Boolean.TRUE.equals(recibido.get(m.name())));
            items.add(item);
        }
        return items;
    }

    /** Acta de instalación emitida (sin el token del QR, que solo se entrega al instalar). */
    Map<String, Object> acta(Integer idMesa) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT id_acta, fecha_emision, estado, hash_integridad, contenido_json
                  FROM acta_electoral WHERE id_mesa = ? AND tipo = 'INSTALACION'
                """, idMesa);
        if (filas.isEmpty()) {
            return null;
        }
        Map<String, Object> acta = filas.get(0);
        try {
            acta.put("contenido", json.readValue(String.valueOf(acta.remove("contenidoJson")),
                    new TypeReference<Map<String, Object>>() { }));
        } catch (Exception e) {
            acta.put("contenido", null);
        }
        acta.put("firmas", dao.consultar("""
                SELECT f.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS nombre, f.rol,
                       f.fecha_firma, f.firma_digital
                  FROM firma_acta f JOIN docente d ON d.id_docente = f.id_docente
                 WHERE f.id_acta = ?
                 ORDER BY FIELD(SUBSTRING_INDEX(f.rol, ' ', 1), 'PRESIDENTE', 'SECRETARIO', 'VOCAL', 'PERSONERO'), f.id_firma
                """, acta.get("idActa")));
        return acta;
    }

    // ─── Horario de instalación (RN07) ──────────────────────────────────────

    /** Resultado de sp_ventana_instalacion más las horas configuradas, para mostrarlas. */
    Map<String, Object> ventana(Integer idProceso) {
        Object[] salida = dao.llamar("sp_ventana_instalacion",
                new int[] {Types.INTEGER, Types.INTEGER, Types.INTEGER, Types.VARCHAR}, idProceso).salidas();
        Map<String, String> parametros = new LinkedHashMap<>();
        dao.consultar("""
                SELECT clave, valor FROM parametro_global
                 WHERE clave IN ('INSTALACION_HORA_INICIO', 'INSTALACION_HORA_LIMITE')
                """).forEach(f -> parametros.put(String.valueOf(f.get("clave")), String.valueOf(f.get("valor"))));

        Map<String, Object> ventana = new LinkedHashMap<>();
        ventana.put("abierta", numero(salida[0]) == 1);
        ventana.put("vencida", numero(salida[1]) == 1);
        ventana.put("control", numero(salida[2]) == 1);
        ventana.put("mensaje", salida[3]);
        ventana.put("horaInicio", hora(parametros.get("INSTALACION_HORA_INICIO"), "09:00"));
        ventana.put("horaLimite", hora(parametros.get("INSTALACION_HORA_LIMITE"), "12:00"));
        ventana.put("ahora", dao.consultar("SELECT NOW() AS ahora").get(0).get("ahora"));
        return ventana;
    }

    /** 9 → "09:00", 9.5 → "09:30". */
    static String hora(String valor, String defecto) {
        try {
            BigDecimal horas = new BigDecimal(valor.trim());
            int minutos = horas.multiply(BigDecimal.valueOf(60)).setScale(0, RoundingMode.HALF_UP).intValue();
            return String.format("%02d:%02d", minutos / 60, minutos % 60);
        } catch (RuntimeException e) {
            return defecto;
        }
    }

    private static Map<String, Object> requisito(String codigo, String texto, boolean cumplido, String detalle) {
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("codigo", codigo);
        r.put("texto", texto);
        r.put("cumplido", cumplido);
        r.put("detalle", detalle);
        return r;
    }

    static boolean verdadero(Object valor) {
        if (valor instanceof Boolean b) {
            return b;
        }
        if (valor instanceof Number n) {
            return n.intValue() != 0;
        }
        return valor != null && "1".equals(String.valueOf(valor));
    }

    static int numero(Object valor) {
        if (valor instanceof Number n) {
            return n.intValue();
        }
        if (valor instanceof Boolean b) {
            return b ? 1 : 0;
        }
        return 0;
    }
}
