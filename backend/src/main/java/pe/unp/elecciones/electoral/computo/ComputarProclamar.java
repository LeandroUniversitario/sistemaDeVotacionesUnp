package pe.unp.elecciones.electoral.computo;

import java.sql.Types;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS14 · «ComputarProclamar» (control). Mensajes 1 y 6 a 19 del diagrama de colaboración:
 *
 *   1  ejecutarComputo(idProceso)                          → sp_ejecutar_computo
 *   6  consolidarVotos(idCargo) / 7 totalesPorLista(votos) → v_computo_resultados (RF92)
 *   8  calcularParticipacion / 9 porcentajeParticipacion   → v_participacion_cargo (RF93)
 *   10 validarQuorum / 11 quorumValidado                   → RN31 (más del 60 %; si no, nulidad total A1)
 *   12 [quorum > 60%] registrarComputo / 13 computoRegistrado → resultado_electoral y acta general (huella y QR)
 *   14 determinarGanador / 15 ganadorOSegundaVuelta        → RF96, RF97 (A2: sp_convocar_segunda_vuelta)
 *   16 [supera minimo] acreditarGanadora / 17 listaAcreditada → sp_proclamar_resultados (RF98)
 *   18 mostrarResultados / 19 resultadosProclamados        → sp_publicar_resultados (RF99)
 *
 * <p>RN26: el cómputo es único e irreversible. Los tokens de los QR solo se devuelven al emitir el
 * acta general y la resolución de proclamación.
 */
@Service
public class ComputarProclamar {

    private static final Map<String, String> ESTADO = Map.of(
            "ELEGIDO", "lista ganadora",
            "SEGUNDA_VUELTA", "segunda vuelta",
            "SIN_QUORUM", "sin quórum",
            "DESIERTO", "desierto",
            "EMPATE", "empate");

    private final ProcedimientoDao dao;
    private final ComputoConsulta consulta;

    public ComputarProclamar(ProcedimientoDao dao, ComputoConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 1 ejecutarComputo(idProceso): mensajes 2 a 15 en una sola transacción (sp_ejecutar_computo). */
    public Map<String, Object> ejecutarComputo(Integer idProceso, Usuario usuario) {
        consulta.proceso(idProceso);
        ProcedimientoDao.Resultado r = dao.llamar("sp_ejecutar_computo", ProcedimientoDao.SIN_SALIDA, idProceso, usuario.getId());
        Map<String, Object> fila = primera(r);
        Map<String, Object> detalle = consulta.detalle(idProceso, usuario);

        String mensaje;
        if ("NULIDAD_TOTAL".equals(ComputoConsulta.texto(fila.get("resultado")))) {
            Map<String, Object> proceso = consulta.proceso(idProceso);
            mensaje = "A1: " + proceso.get("motivoAnulacion") + " Publique el acta general y comuníquela a SUNEDU, "
                    + "la Asamblea Universitaria y el Consejo Universitario.";
        } else {
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> cargos = (List<Map<String, Object>>) ((Map<String, Object>) detalle.get("resultados")).get("cargos");
            mensaje = "Cómputo oficial registrado con " + fila.get("mesasComputadas") + " mesa(s). "
                    + cargos.stream().map(c -> c.get("cargo") + ": " + ESTADO.getOrDefault(ComputoConsulta.texto(c.get("estadoResultado")),
                            ComputoConsulta.texto(c.get("estadoResultado")))
                            + (c.get("listaGanadora") != null ? " (" + c.get("listaGanadora") + ")" : ""))
                    .collect(Collectors.joining("; ")) + ".";
        }
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", mensaje);
        respuesta.put("resultado", fila.get("resultado"));
        respuesta.put("tokenQr", fila.get("tokenQr"));
        respuesta.put("detalle", detalle);
        return respuesta;
    }

    /** 16-17: el Presidente del CEUNP proclama y se acredita la lista ganadora de cada cargo (RF98). */
    public Map<String, Object> proclamar(Integer idProceso, ComputoDto.Proclamacion datos, Usuario usuario) {
        consulta.proceso(idProceso);
        ProcedimientoDao.Resultado r = dao.llamar("sp_proclamar_resultados", ProcedimientoDao.SIN_SALIDA, idProceso,
                usuario.getId(), datos.numeroResolucion().trim(), datos.miembrosPleno(), datos.presidente().trim(),
                SesionComputo.vacioANulo(datos.fundamento()));
        Map<String, Object> fila = primera(r);
        int proclamados = ComputoConsulta.numero(fila.get("cargosProclamados"));
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Resolución " + fila.get("numeroResolucion") + ": "
                + (proclamados == 0 ? "ningún cargo tiene lista ganadora; quedan pendientes de segunda vuelta o nueva elección."
                        : proclamados + " lista(s) proclamada(s) y acreditada(s). Publique los resultados en el portal (RF99)."));
        respuesta.put("tokenQr", fila.get("tokenQr"));
        respuesta.put("detalle", consulta.detalle(idProceso, usuario));
        return respuesta;
    }

    /** 18-19 mostrarResultados / resultadosProclamados: publicación en el portal (RF99). */
    public Map<String, Object> publicar(Integer idProceso, Usuario usuario) {
        consulta.proceso(idProceso);
        dao.llamar("sp_publicar_resultados", ProcedimientoDao.SIN_SALIDA, idProceso, usuario.getId());
        // Concluida la elección con la publicación oficial, los personeros concluyen sus funciones y retornan a DOCENTE
        dao.ejecutar("""
            UPDATE usuario u
              JOIN personero pe ON pe.id_docente = u.id_docente
              JOIN lista_electoral l ON l.id_lista = pe.id_lista
              JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
             WHERE c.id_proceso = ? AND u.rol = 'PERSONERO'
               SET u.rol = 'DOCENTE'
            """, idProceso);
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Resultados publicados en el portal electoral, por mesa y generales (RF99).");
        respuesta.put("detalle", consulta.detalle(idProceso, usuario));
        return respuesta;
    }

    /** A2 (RN33): segunda vuelta entre las dos listas más votadas dentro del plazo. */
    public Map<String, Object> convocarSegundaVuelta(Integer idProceso, ComputoDto.SegundaVuelta datos, Usuario usuario) {
        consulta.proceso(idProceso);
        if (!datos.fechaFin().isAfter(datos.fechaInicio())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La fecha de fin debe ser posterior a la de inicio.");
        }
        ProcedimientoDao.Resultado r = dao.llamar("sp_convocar_segunda_vuelta", new int[] {Types.INTEGER}, idProceso,
                datos.fechaInicio(), datos.fechaFin(), usuario.getId());
        if (!(r.salidas()[0] instanceof Number nuevo)) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "No se obtuvo el proceso de segunda vuelta.");
        }
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Segunda vuelta convocada (proceso N.º " + nuevo.intValue() + ") entre las dos listas más votadas. "
                + "Continúe su preparación en Convocatoria y cronograma.");
        respuesta.put("idProcesoNuevo", nuevo.intValue());
        respuesta.put("detalle", consulta.detalle(idProceso, usuario));
        return respuesta;
    }

    private static Map<String, Object> primera(ProcedimientoDao.Resultado r) {
        if (r.filas().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "El procedimiento no devolvió resultados.");
        }
        return r.filas().get(0);
    }
}
