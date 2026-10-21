package pe.unp.elecciones.electoral.votacion;

import java.sql.Types;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.dao.DataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.service.ProcedimientoDao;
import pe.unp.elecciones.electoral.votacion.VotacionDto.Marca;

/**
 * CUS10 · Emitir voto (actor: docente elector), según secuencia_emitir_voto.puml.
 *
 * <ol>
 *   <li>iniciarVotacion / validarHabilitacion: el docente de la sesión debe tener una autorización
 *       de cabina vigente (CUS09) y cargos pendientes en el padrón.</li>
 *   <li>mostrarOpciones: cédula con las listas ADMITIDAS de cada cargo en el orden sorteado (RN18),
 *       más el voto en blanco.</li>
 *   <li>registrarVoto: por cada cargo se llama a sp_emitir_voto, que en una sola transacción bloquea
 *       la fila del padrón, marca que votó, inserta el voto anónimo y emite la constancia.</li>
 *   <li>mostrarConstancia: tokens de las constancias (prueban la participación, no el sentido del voto).</li>
 * </ol>
 *
 * Este servicio nunca escribe en la tabla voto ni guarda la relación docente - lista.
 * Sin @Transactional a propósito (ver ProcedimientoDao).
 */
@Service
public class EmitirVoto {

    private final VotacionConsulta consulta;
    private final ProcedimientoDao dao;

    public EmitirVoto(VotacionConsulta consulta, ProcedimientoDao dao) {
        this.consulta = consulta;
        this.dao = dao;
    }

    /** 1-2: estado del elector en cada proceso en VOTACION y, si está autorizado, su cédula. */
    public Map<String, Object> cedula(Integer idDocente) {
        consulta.anularVencidas();
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT pe.id_proceso, p.nombre AS proceso, p.fecha_inicio, p.fecha_fin,
                       pe.id_cargo, c.nombre AS cargo, c.nivel_jurisdiccion,
                       pe.habilitado_para_votar AS habilitado, pe.ya_voto,
                       pe.id_mesa, m.numero_mesa, m.ubicacion, m.estado AS estado_mesa
                  FROM padron_electoral pe
                  JOIN proceso_electoral p ON p.id_proceso = pe.id_proceso
                  JOIN cargo_electoral c   ON c.id_cargo = pe.id_cargo
                  LEFT JOIN mesa_electoral m ON m.id_mesa = pe.id_mesa
                 WHERE pe.id_docente = ? AND p.estado = 'VOTACION'
                 ORDER BY pe.id_proceso, c.id_cargo
                """, idDocente);

        Map<Integer, List<Map<String, Object>>> porProceso = filas.stream().collect(Collectors.groupingBy(
                f -> (Integer) f.get("idProceso"), LinkedHashMap::new, Collectors.toList()));
        List<Map<String, Object>> procesos = new ArrayList<>();
        porProceso.forEach((idProceso, cargos) -> procesos.add(estadoProceso(idProceso, idDocente, cargos)));

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("elector", datosDocente(idDocente));
        respuesta.put("procesos", procesos);
        return respuesta;
    }

    private Map<String, Object> estadoProceso(Integer idProceso, Integer idDocente, List<Map<String, Object>> cargos) {
        Map<String, Object> primera = cargos.get(0);
        Map<String, Object> proceso = new LinkedHashMap<>();
        proceso.put("idProceso", idProceso);
        proceso.put("proceso", primera.get("proceso"));
        proceso.put("fechaInicio", primera.get("fechaInicio"));
        proceso.put("fechaFin", primera.get("fechaFin"));
        proceso.put("mesa", primera.get("idMesa") == null ? null : Map.of(
                "id", primera.get("idMesa"), "numero", primera.get("numeroMesa"),
                "ubicacion", primera.get("ubicacion"), "estado", primera.get("estadoMesa")));

        List<Map<String, Object>> pendientes = cargos.stream()
                .filter(c -> VotacionConsulta.numero(c.get("habilitado")) == 1 && VotacionConsulta.numero(c.get("yaVoto")) == 0)
                .toList();
        proceso.put("cargosVotados", cargos.stream()
                .filter(c -> VotacionConsulta.numero(c.get("yaVoto")) == 1)
                .map(c -> Map.of("idCargo", c.get("idCargo"), "cargo", c.get("cargo")))
                .toList());

        Map<String, Object> autorizacion = consulta.autorizacionPendiente(idProceso, idDocente);
        proceso.put("autorizacion", autorizacion);
        String estado;
        String mensaje;
        if (pendientes.isEmpty()) {
            boolean voto = cargos.stream().anyMatch(c -> VotacionConsulta.numero(c.get("yaVoto")) == 1);
            estado = voto ? "VOTO" : "INHABILITADO";
            mensaje = voto ? "Ya votó en todos sus cargos. Gracias por participar."
                    : "RN04: no está habilitado para votar en este proceso. Consulte al CEUNP.";
        } else if (primera.get("idMesa") == null) {
            estado = "SIN_MESA";
            mensaje = "No tiene mesa de sufragio asignada. Consulte al CEUNP.";
        } else if (autorizacion == null) {
            estado = "SIN_AUTORIZACION";
            mensaje = "Acérquese a la mesa " + primera.get("numeroMesa") + " (" + primera.get("ubicacion")
                    + ") con su pase QR o su DNI. El miembro de mesa habilitará su cabina.";
        } else {
            estado = "HABILITADO";
            mensaje = "Su cabina está habilitada. Marque una opción por cada cargo y confirme.";
            proceso.put("cargos", cargosConListas(pendientes));
        }
        proceso.put("estado", estado);
        proceso.put("mensaje", mensaje);
        return proceso;
    }

    /** 2: mostrarOpciones — listas ADMITIDAS con sus candidatos aprobados, en el orden de la cédula. */
    private List<Map<String, Object>> cargosConListas(List<Map<String, Object>> pendientes) {
        List<Object> ids = pendientes.stream().map(c -> c.get("idCargo")).collect(Collectors.toList());
        String marcas = String.join(",", java.util.Collections.nCopies(ids.size(), "?"));
        List<Map<String, Object>> listas = dao.consultar("""
                SELECT l.id_lista, l.id_cargo, l.nombre, l.simbolo, l.orden_cedula, l.url_plan_gobierno
                  FROM lista_electoral l
                 WHERE l.estado = 'ADMITIDA' AND l.id_cargo IN (%s)
                 ORDER BY l.id_cargo, l.orden_cedula IS NULL, l.orden_cedula, l.nombre
                """.formatted(marcas), ids.toArray());
        List<Map<String, Object>> candidatos = dao.consultar("""
                SELECT ca.id_lista, ca.rol_en_lista, CONCAT(d.apellidos, ', ', d.nombres) AS nombre
                  FROM candidato ca
                  JOIN docente d ON d.id_docente = ca.id_docente
                  JOIN lista_electoral l ON l.id_lista = ca.id_lista
                 WHERE l.estado = 'ADMITIDA' AND ca.estado_validacion = 'APROBADO' AND l.id_cargo IN (%s)
                 ORDER BY ca.id_lista, ca.id_candidato
                """.formatted(marcas), ids.toArray());
        Map<Object, List<Map<String, Object>>> candidatosPorLista = candidatos.stream()
                .collect(Collectors.groupingBy(c -> c.get("idLista")));
        listas.forEach(l -> l.put("candidatos", candidatosPorLista.getOrDefault(l.get("idLista"), List.of())));
        Map<Object, List<Map<String, Object>>> listasPorCargo = listas.stream()
                .collect(Collectors.groupingBy(l -> l.get("idCargo")));

        return pendientes.stream().map(c -> {
            Map<String, Object> cargo = new LinkedHashMap<>();
            cargo.put("idCargo", c.get("idCargo"));
            cargo.put("cargo", c.get("cargo"));
            cargo.put("nivel", c.get("nivelJurisdiccion"));
            cargo.put("listas", listasPorCargo.getOrDefault(c.get("idCargo"), List.of()));
            return cargo;
        }).toList();
    }

    /** 3: registrarVoto — una marca por cada cargo pendiente; devuelve la constancia. */
    public Map<String, Object> votar(Integer idDocente, Integer idProceso, List<Marca> marcas) {
        consulta.anularVencidas();
        Map<String, Object> autorizacion = exigirAutorizacion(idProceso, idDocente);

        List<Map<String, Object>> pendientes = dao.consultar("""
                SELECT pe.id_cargo, c.nombre AS cargo
                  FROM padron_electoral pe JOIN cargo_electoral c ON c.id_cargo = pe.id_cargo
                 WHERE pe.id_proceso = ? AND pe.id_docente = ?
                   AND pe.habilitado_para_votar = 1 AND pe.ya_voto = 0
                 ORDER BY pe.id_cargo
                """, idProceso, idDocente);
        Map<Integer, String> nombresCargo = new LinkedHashMap<>();
        pendientes.forEach(p -> nombresCargo.put((Integer) p.get("idCargo"), String.valueOf(p.get("cargo"))));

        Map<Integer, Marca> porCargo = new HashMap<>();
        for (Marca marca : marcas) {
            if (porCargo.put(marca.cargoId(), marca) != null) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Hay más de una marca para el mismo cargo.");
            }
            if (!nombresCargo.containsKey(marca.cargoId())) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "RN01: uno de los cargos ya fue votado o no le corresponde. Actualice la cédula.");
            }
            validarMarca(marca, nombresCargo.get(marca.cargoId()));
        }
        List<String> faltan = nombresCargo.entrySet().stream()
                .filter(e -> !porCargo.containsKey(e.getKey())).map(Map.Entry::getValue).toList();
        if (!faltan.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Marque una opción (una lista o voto en blanco) en: " + String.join(", ", faltan) + ".");
        }

        List<Map<String, Object>> constancias = new ArrayList<>();
        String error = null;
        for (Map.Entry<Integer, String> cargo : nombresCargo.entrySet()) {
            Marca marca = porCargo.get(cargo.getKey());
            String tipo = marca.tipo().trim().toUpperCase(Locale.ROOT);
            try {
                ProcedimientoDao.Resultado resultado = dao.llamar("sp_emitir_voto", new int[] {Types.VARCHAR},
                        idProceso, cargo.getKey(), idDocente, "VALIDO".equals(tipo) ? marca.listaId() : null, tipo);
                Map<String, Object> constancia = new LinkedHashMap<>();
                constancia.put("idCargo", cargo.getKey());
                constancia.put("cargo", cargo.getValue());
                constancia.put("token", resultado.salidas()[0]);
                constancias.add(constancia);
            } catch (DataAccessException e) {
                if (constancias.isEmpty()) {
                    throw e;   // nada se grabó: ErrorBdHandler traduce la regla de negocio
                }
                error = "Se registraron " + constancias.size() + " de " + nombresCargo.size()
                        + " votos. Falló el cargo " + cargo.getValue() + ": " + mensajeBd(e)
                        + " Su cabina sigue habilitada para los cargos restantes.";
                break;
            }
        }
        boolean completo = cerrarAutorizacionSiTermino(idProceso, idDocente);

        Map<String, Object> constancia = new LinkedHashMap<>();
        constancia.put("proceso", dao.consultar("SELECT nombre FROM proceso_electoral WHERE id_proceso = ?", idProceso)
                .get(0).get("nombre"));
        constancia.put("elector", datosDocente(idDocente));
        constancia.put("mesa", Map.of("numero", autorizacion.get("numeroMesa"), "ubicacion", autorizacion.get("ubicacion")));
        constancia.put("fechaEmision", LocalDateTime.now());
        constancia.put("cargos", constancias);

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", error == null ? "Su voto fue registrado. Gracias por participar." : error);
        respuesta.put("completo", completo);
        respuesta.put("error", error);
        respuesta.put("constancia", constancia);
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
                    "RN25: en el voto electrónico no existe el voto nulo; puede votar en blanco.");
            default -> throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "El voto debe ser por una lista (VALIDO) o en BLANCO.");
        }
    }

    // ─── Compuerta de la autorización (también la usa POST /api/votos) ──────────

    /** El docente no vota sin pasar por su mesa (CUS09). */
    public Map<String, Object> exigirAutorizacion(Integer idProceso, Integer idDocente) {
        consulta.anularVencidas();
        Map<String, Object> autorizacion = consulta.autorizacionPendiente(idProceso, idDocente);
        if (autorizacion == null) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "No tiene la cabina habilitada: acérquese a su mesa con su pase QR o DNI (CUS09 Verificar elector).");
        }
        if (!VotacionConsulta.MESA_INSTALADA.equals(autorizacion.get("estadoMesa"))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "RN07: su mesa ya no está INSTALADA.");
        }
        return autorizacion;
    }

    /** Si ya no quedan cargos pendientes, la autorización queda USADA. Devuelve true en ese caso. */
    public boolean cerrarAutorizacionSiTermino(Integer idProceso, Integer idDocente) {
        int pendientes = dao.entero("""
                SELECT COUNT(*) FROM padron_electoral
                 WHERE id_proceso = ? AND id_docente = ? AND habilitado_para_votar = 1 AND ya_voto = 0
                """, idProceso, idDocente);
        if (pendientes > 0) {
            return false;
        }
        dao.ejecutar("""
                UPDATE autorizacion_voto SET estado = 'USADA', fecha_uso = NOW()
                 WHERE id_proceso = ? AND id_docente = ? AND estado = 'PENDIENTE'
                """, idProceso, idDocente);
        return true;
    }

    private Map<String, Object> datosDocente(Integer idDocente) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT d.id_docente, d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS nombre, d.categoria
                  FROM docente d WHERE d.id_docente = ?
                """, idDocente);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Docente no encontrado.");
        }
        return filas.get(0);
    }

    private static String mensajeBd(DataAccessException e) {
        Throwable causa = e.getMostSpecificCause();
        String mensaje = causa.getMessage() == null ? "" : causa.getMessage();
        return mensaje.replaceFirst("^\\(conn=\\d+\\)\\s*", "").trim();
    }
}
