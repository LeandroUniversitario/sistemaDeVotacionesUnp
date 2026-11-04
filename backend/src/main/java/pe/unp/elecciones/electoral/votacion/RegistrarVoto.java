package pe.unp.elecciones.electoral.votacion;

import java.security.SecureRandom;
import java.sql.Types;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.service.Bitacora;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;
import pe.unp.elecciones.electoral.votacion.VotacionDto.Marca;

/**
 * CUS10 · Registrar voto («RegistrarVoto», capa de control) atendiendo al «TerminalVotacion».
 *
 * <ul>
 *   <li>El terminal toma la habilitación de un solo uso que dejó habilitarTerminal() y muestra la
 *       cédula (RF68). El docente no inicia sesión y el terminal nunca recibe datos del elector.</li>
 *   <li>9 registrarVoto(opción) → 10 crear(opción, mesa): en UNA transacción se llama
 *       sp_votar_habilitado por cada cargo (marca Votó, crea el Voto sin vínculo y emite la
 *       ConstanciaVoto) y se consume la habilitación. Si algo falla se revierte todo (A5).</li>
 *   <li>11 imprimirCedula(opción): la respuesta trae solo la elección, para la ImpresoraCedula.</li>
 *   <li>13 liberarTerminal(): el terminal borra la elección y vuelve a quedar libre (RNF07).</li>
 * </ul>
 *
 * La constancia (generarConstancia) no pasa por el terminal: la recoge la mesa para el elector.
 */
@Service
public class RegistrarVoto {

    private static final SecureRandom ALEATORIO = new SecureRandom();
    private static final long HORAS_CONSTANCIA = 3;

    private final VotacionConsulta consulta;
    private final ProcedimientoDao dao;
    private final Bitacora bitacora;
    private final TransactionTemplate transaccion;
    private final ObjectMapper json;

    public RegistrarVoto(VotacionConsulta consulta, ProcedimientoDao dao, Bitacora bitacora,
            PlatformTransactionManager transactionManager, ObjectMapper json) {
        this.consulta = consulta;
        this.dao = dao;
        this.bitacora = bitacora;
        this.transaccion = new TransactionTemplate(transactionManager);
        this.json = json;
    }

    // ─── Terminal ────────────────────────────────────────────────────────────

    /**
     * El equipo de la cabina se registra (o vuelve a conectarse) como terminal de la mesa.
     *
     * <p>C2/M1: se emite un secreto de dispositivo que solo se entrega aquí. La cabina lo usa en
     * /api/cabina/** en lugar de una sesión de persona; reconectar el equipo rota el secreto y deja
     * sin acceso al anterior. La habilitación (token de un solo uso) solo se entrega a ese secreto.
     */
    public Map<String, Object> registrarTerminal(Integer idMesa, String nombre, Integer idUsuario) {
        consulta.mesa(idMesa);
        String limpio = nombre.trim();
        String secreto = HexFormat.of().formatHex(aleatorio());
        dao.ejecutar("""
                INSERT INTO terminal_votacion (id_mesa, nombre, ultima_conexion, secreto_hash, id_usuario_conexion)
                VALUES (?, ?, NOW(), SHA2(?, 256), ?)
                ON DUPLICATE KEY UPDATE ultima_conexion = NOW(), secreto_hash = VALUES(secreto_hash),
                                        id_usuario_conexion = VALUES(id_usuario_conexion)
                """, idMesa, limpio, secreto, idUsuario);
        Integer idTerminal = (Integer) dao.consultar(
                "SELECT id_terminal FROM terminal_votacion WHERE id_mesa = ? AND nombre = ?", idMesa, limpio)
                .get(0).get("idTerminal");
        bitacora.registrar(idUsuario, (Integer) consulta.mesa(idMesa).get("idProceso"), "CONECTAR_TERMINAL",
                Map.of("id_mesa", idMesa, "id_terminal", idTerminal));
        Map<String, Object> respuesta = estado(idTerminal, false);
        respuesta.put("secreto", secreto);
        return respuesta;
    }

    /** La cabina presenta su secreto de dispositivo; si no coincide con el vigente, no opera. */
    public void exigirSecreto(Integer idTerminal, String secreto) {
        if (secreto == null || !secreto.matches("[0-9a-fA-F]{64}") || dao.entero("""
                SELECT COUNT(*) FROM terminal_votacion
                 WHERE id_terminal = ? AND secreto_hash IS NOT NULL AND secreto_hash = SHA2(?, 256)
                """, idTerminal, secreto.toLowerCase(Locale.ROOT)) == 0) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                    "Este equipo ya no está conectado como terminal. Un miembro de la mesa debe volver a conectarlo.");
        }
    }

    /**
     * Estado del terminal. Si la mesa lo habilitó y aún nadie tomó la habilitación, y quien consulta
     * es la propia cabina (paraCabina, autenticada con su secreto), se genera aquí el token de un solo
     * uso (solo se entrega una vez) y la cédula con los cargos pendientes. La mesa ve solo el estado.
     */
    public Map<String, Object> estado(Integer idTerminal, boolean paraCabina) {
        Map<String, Object> terminal = consulta.terminal(idTerminal);
        Integer idMesa = (Integer) terminal.get("idMesa");
        dao.ejecutar("UPDATE terminal_votacion SET ultima_conexion = NOW() WHERE id_terminal = ?", idTerminal);
        Map<String, Object> mesa = consulta.mesa(idMesa);

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("terminal", Map.of("id", idTerminal, "nombre", terminal.get("nombre")));
        respuesta.put("mesa", Map.of("id", idMesa, "numero", mesa.get("numero"), "ubicacion", mesa.get("ubicacion"),
                "proceso", mesa.get("proceso"), "estado", mesa.get("estado")));
        if (VotacionConsulta.numero(terminal.get("activo")) == 0) {
            respuesta.put("estado", "FUERA_DE_SERVICIO");
            return respuesta;
        }
        List<Map<String, Object>> pendientes = dao.consultar("""
                SELECT h.id_habilitacion, h.token_hash, a.id_proceso, a.id_docente
                  FROM habilitacion_terminal h JOIN asistencia_elector a ON a.id_asistencia = h.id_asistencia
                 WHERE h.id_terminal = ? AND h.estado = 'PENDIENTE'
                """, idTerminal);
        if (pendientes.isEmpty()) {
            respuesta.put("estado", "LIBRE");
            respuesta.put("motivoMesa", VotacionConsulta.motivoNoAtiende(mesa));
            return respuesta;
        }
        Map<String, Object> h = pendientes.get(0);
        Long idHabilitacion = ((Number) h.get("idHabilitacion")).longValue();
        respuesta.put("idHabilitacion", idHabilitacion);
        if (!paraCabina) {
            respuesta.put("estado", h.get("tokenHash") == null ? "HABILITADO" : "EN_USO");
            return respuesta;
        }
        if (h.get("tokenHash") != null) {
            // Ya la tomó este terminal (por ejemplo, se recargó la página): el token no se vuelve a entregar.
            respuesta.put("estado", "EN_USO");
            respuesta.put("mensaje", "La habilitación ya fue tomada. Si la cédula se perdió, la mesa debe anularla y rehabilitar al elector.");
            return respuesta;
        }
        String token = HexFormat.of().formatHex(aleatorio());
        int tomada = dao.ejecutar("""
                UPDATE habilitacion_terminal SET token_hash = SHA2(?, 256), fecha_entrega = NOW()
                 WHERE id_habilitacion = ? AND estado = 'PENDIENTE' AND token_hash IS NULL
                """, token, idHabilitacion);
        if (tomada == 0) {
            respuesta.put("estado", "EN_USO");
            return respuesta;
        }
        respuesta.put("estado", "HABILITADO");
        respuesta.put("token", token);
        respuesta.put("cargos", cedula((Integer) h.get("idProceso"), (Integer) h.get("idDocente")));
        return respuesta;
    }

    private static byte[] aleatorio() {
        byte[] bytes = new byte[32];
        ALEATORIO.nextBytes(bytes);
        return bytes;
    }

    /** RF68: listas ADMITIDAS en el orden sorteado, con símbolo y fotografía del candidato a Rector. */
    private List<Map<String, Object>> cedula(Integer idProceso, Integer idDocente) {
        List<Map<String, Object>> pendientes = cargosPendientes(idProceso, idDocente);
        if (pendientes.isEmpty()) {
            return List.of();
        }
        List<Object> ids = pendientes.stream().map(c -> c.get("idCargo")).collect(Collectors.toList());
        String marcas = String.join(",", Collections.nCopies(ids.size(), "?"));
        List<Map<String, Object>> listas = dao.consultar("""
                SELECT l.id_lista, l.id_cargo, l.nombre, l.simbolo, l.orden_cedula
                  FROM lista_electoral l
                 WHERE l.estado = 'ADMITIDA' AND l.id_cargo IN (%s)
                 ORDER BY l.id_cargo, l.orden_cedula IS NULL, l.orden_cedula, l.nombre
                """.formatted(marcas), ids.toArray());
        List<Map<String, Object>> candidatos = dao.consultar("""
                SELECT ca.id_lista, ca.rol_en_lista, CONCAT(d.nombres, ' ', d.apellidos) AS nombre, ca.url_foto
                  FROM candidato ca
                  JOIN docente d ON d.id_docente = ca.id_docente
                  JOIN lista_electoral l ON l.id_lista = ca.id_lista
                 WHERE l.estado = 'ADMITIDA' AND ca.estado_validacion = 'APROBADO' AND l.id_cargo IN (%s)
                 ORDER BY ca.id_lista, ca.id_candidato
                """.formatted(marcas), ids.toArray());
        Map<Object, List<Map<String, Object>>> porLista = candidatos.stream()
                .collect(Collectors.groupingBy(c -> c.get("idLista")));
        listas.forEach(l -> l.put("candidatos", porLista.getOrDefault(l.get("idLista"), List.of())));
        Map<Object, List<Map<String, Object>>> porCargo = listas.stream()
                .collect(Collectors.groupingBy(l -> l.get("idCargo")));
        return pendientes.stream().map(c -> {
            Map<String, Object> cargo = new LinkedHashMap<>();
            cargo.put("idCargo", c.get("idCargo"));
            cargo.put("cargo", c.get("cargo"));
            cargo.put("listas", porCargo.getOrDefault(c.get("idCargo"), List.of()));
            return cargo;
        }).toList();
    }

    private List<Map<String, Object>> cargosPendientes(Integer idProceso, Integer idDocente) {
        return dao.consultar("""
                SELECT pe.id_cargo, c.nombre AS cargo
                  FROM padron_electoral pe JOIN cargo_electoral c ON c.id_cargo = pe.id_cargo
                 WHERE pe.id_proceso = ? AND pe.id_docente = ? AND pe.habilitado_para_votar = 1 AND pe.ya_voto = 0
                 ORDER BY pe.id_cargo
                """, idProceso, idDocente);
    }

    // ─── 9 registrarVoto(opción) ─────────────────────────────────────────────

    public Map<String, Object> registrarVoto(Integer idTerminal, Long idHabilitacion, String token, List<Marca> marcas) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT h.estado, a.id_proceso, a.id_docente, a.id_mesa
                  FROM habilitacion_terminal h JOIN asistencia_elector a ON a.id_asistencia = h.id_asistencia
                 WHERE h.id_habilitacion = ? AND h.id_terminal = ?
                """, idHabilitacion, idTerminal);
        if (filas.isEmpty() || !"PENDIENTE".equals(filas.get(0).get("estado"))) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "RF67: el terminal no tiene una habilitación vigente.");
        }
        Integer idProceso = (Integer) filas.get(0).get("idProceso");
        Integer idDocente = (Integer) filas.get(0).get("idDocente");
        Integer idMesa = (Integer) filas.get(0).get("idMesa");

        Map<Integer, String> nombresCargo = new LinkedHashMap<>();
        cargosPendientes(idProceso, idDocente)
                .forEach(c -> nombresCargo.put((Integer) c.get("idCargo"), String.valueOf(c.get("cargo"))));
        Map<Integer, Marca> porCargo = new HashMap<>();
        for (Marca marca : marcas) {
            if (porCargo.put(marca.cargoId(), marca) != null || !nombresCargo.containsKey(marca.cargoId())) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La cédula no corresponde a los cargos del elector.");
            }
            validarMarca(marca, nombresCargo.get(marca.cargoId()));
        }
        List<String> faltan = nombresCargo.entrySet().stream()
                .filter(e -> !porCargo.containsKey(e.getKey())).map(Map.Entry::getValue).toList();
        if (!faltan.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Marque una opción (una lista o voto en blanco) en: " + String.join(", ", faltan) + ".");
        }

        // 10 crear(opción, mesa): todos los cargos y el consumo de la habilitación, o nada (A5)
        List<Map<String, Object>> tokens = transaccion.execute(estado -> {
            List<Map<String, Object>> emitidas = new ArrayList<>();
            for (Map.Entry<Integer, String> cargo : nombresCargo.entrySet()) {
                Marca marca = porCargo.get(cargo.getKey());
                String tipo = marca.tipo().trim().toUpperCase(Locale.ROOT);
                ProcedimientoDao.Resultado r = dao.llamar("sp_votar_habilitado", new int[] {Types.VARCHAR},
                        idHabilitacion, token.toLowerCase(Locale.ROOT), cargo.getKey(),
                        "VALIDO".equals(tipo) ? marca.listaId() : null, tipo);
                emitidas.add(Map.of("idCargo", cargo.getKey(), "cargo", cargo.getValue(), "token", r.salidas()[0]));
            }
            dao.ejecutar("""
                    UPDATE habilitacion_terminal SET estado = 'CONSUMIDA', fecha_cierre = NOW()
                     WHERE id_habilitacion = ? AND estado = 'PENDIENTE'
                    """, idHabilitacion);
            return emitidas;
        });

        guardarConstancia(idProceso, idDocente, idMesa, tokens);

        // 11 imprimirCedula(opción): solo la elección, sin datos del elector
        List<Map<String, Object>> cedula = new ArrayList<>();
        for (Map.Entry<Integer, String> cargo : nombresCargo.entrySet()) {
            Marca marca = porCargo.get(cargo.getKey());
            Map<String, Object> linea = new LinkedHashMap<>();
            linea.put("cargo", cargo.getValue());
            if ("BLANCO".equalsIgnoreCase(marca.tipo().trim())) {
                linea.put("opcion", "VOTO EN BLANCO");
            } else {
                Map<String, Object> lista = dao.consultar(
                        "SELECT nombre, simbolo, orden_cedula FROM lista_electoral WHERE id_lista = ?", marca.listaId()).get(0);
                linea.put("opcion", lista.get("nombre"));
                linea.put("simbolo", lista.get("simbolo"));
                linea.put("orden", lista.get("ordenCedula"));
            }
            cedula.add(linea);
        }
        Map<String, Object> mesa = consulta.mesa(idMesa);
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Voto registrado. Retire su cédula impresa, revísela y deposítela en el ánfora.");
        respuesta.put("proceso", mesa.get("proceso"));
        respuesta.put("mesa", mesa.get("numero"));
        respuesta.put("cedula", cedula);
        return respuesta;
    }

    private static void validarMarca(Marca marca, String cargo) {
        String tipo = marca.tipo() == null ? "" : marca.tipo().trim().toUpperCase(Locale.ROOT);
        switch (tipo) {
            case "VALIDO" -> {
                if (marca.listaId() == null) {
                    throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Elija una lista para " + cargo + ".");
                }
            }
            case "BLANCO" -> {
                if (marca.listaId() != null) {
                    throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Un voto en blanco no lleva lista.");
                }
            }
            case "NULO" -> throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "RN25 / D12: el terminal no registra voto nulo; puede votar en blanco.");
            default -> throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "El voto debe ser por una lista o en blanco.");
        }
    }

    /** 13 liberarTerminal(): tras confirmarImpresion() el terminal borra la elección y queda libre. */
    public Map<String, Object> liberarTerminal(Integer idTerminal) {
        Map<String, Object> terminal = consulta.terminal(idTerminal);
        Integer idMesa = (Integer) terminal.get("idMesa");
        Integer idUsuario = (Integer) dao.consultar(
                "SELECT id_usuario_conexion FROM terminal_votacion WHERE id_terminal = ?", idTerminal).get(0).get("idUsuarioConexion");
        bitacora.registrar(idUsuario, (Integer) consulta.mesa(idMesa).get("idProceso"), "LIBERAR_TERMINAL",
                Map.of("id_mesa", idMesa, "id_terminal", idTerminal));
        return estado(idTerminal, true);
    }

    // ─── 12 generarConstancia(): se entrega en la mesa, no en el terminal ─────

    private void guardarConstancia(Integer idProceso, Integer idDocente, Integer idMesa, List<Map<String, Object>> tokens) {
        dao.ejecutar("DELETE FROM constancia_pendiente WHERE fecha_emision < NOW() - INTERVAL ? HOUR", HORAS_CONSTANCIA);
        dao.ejecutar("""
                INSERT INTO constancia_pendiente (id_proceso, id_docente, id_mesa, cargos_json) VALUES (?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE id_mesa = VALUES(id_mesa), cargos_json = VALUES(cargos_json), fecha_emision = NOW()
                """, idProceso, idDocente, idMesa, aJson(tokens));
    }

    private String aJson(Object valor) {
        try {
            return json.writeValueAsString(valor);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("No se pudo guardar la constancia.", e);
        }
    }

    /** Constancia del elector que acaba de votar, para que la mesa la imprima y se la entregue. */
    public Map<String, Object> constancia(Integer idMesa, Integer idDocente) {
        Map<String, Object> mesa = consulta.mesa(idMesa);
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT cargos_json, fecha_emision FROM constancia_pendiente
                 WHERE id_proceso = ? AND id_docente = ? AND id_mesa = ?
                   AND fecha_emision >= NOW() - INTERVAL ? HOUR
                """, mesa.get("idProceso"), idDocente, idMesa, HORAS_CONSTANCIA);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                    "No hay constancia por entregar: ya se entregó o pasaron más de " + HORAS_CONSTANCIA + " horas.");
        }
        Map<String, Object> elector = consulta.electorEnMesa(idMesa, null, idDocente);
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("fechaEmision", filas.get(0).get("fechaEmision"));
        respuesta.put("idMesa", idMesa);
        try {
            respuesta.put("cargos", json.readValue(String.valueOf(filas.get(0).get("cargosJson")),
                    new TypeReference<List<Map<String, Object>>>() { }));
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("La constancia guardada no es legible.", e);
        }
        respuesta.put("proceso", mesa.get("proceso"));
        respuesta.put("mesa", Map.of("numero", mesa.get("numero"), "ubicacion", mesa.get("ubicacion")));
        respuesta.put("elector", Map.of("nombre", elector.get("nombre"), "dni", elector.get("dni")));
        return respuesta;
    }

    /** La mesa confirma que entregó la constancia: se borra el token pendiente. */
    public void constanciaEntregada(Integer idMesa, Integer idDocente) {
        dao.ejecutar("DELETE FROM constancia_pendiente WHERE id_proceso = ? AND id_docente = ? AND id_mesa = ?",
                consulta.mesa(idMesa).get("idProceso"), idDocente, idMesa);
    }
}
