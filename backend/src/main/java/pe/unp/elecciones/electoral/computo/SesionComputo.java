package pe.unp.elecciones.electoral.computo;

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
 * CUS14 · «SesionComputo» (control). Pasos 1 y 4 de la tabla 39, previos al mensaje 1
 * ejecutarComputo(idProceso) del diagrama:
 *
 *   concluirVotacion(idProceso)   → sp_cambiar_estado_proceso(VOTACION → CERRADO) (RN32)
 *   instalarSesion(datos)         → sp_instalar_sesion_computo (RF91, quórum del Pleno RN36)
 *   registrarPersonero(id)        → sp_registrar_personero_computo (asistencia facultativa)
 */
@Service
public class SesionComputo {

    private final ProcedimientoDao dao;
    private final ComputoConsulta consulta;

    public SesionComputo(ProcedimientoDao dao, ComputoConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** Paso 1: la votación concluye cuando todas las mesas cerraron su sufragio o no se instalaron. */
    public Map<String, Object> concluirVotacion(Integer idProceso, Usuario usuario) {
        Map<String, Object> proceso = consulta.proceso(idProceso);
        if (!"VOTACION".equals(ComputoConsulta.texto(proceso.get("estado")))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "RN32: solo se concluye la votación de un proceso en VOTACION.");
        }
        List<Map<String, Object>> abiertas = dao.consultar("""
                SELECT numero_mesa, estado FROM mesa_electoral
                 WHERE id_proceso = ? AND estado IN ('INSTALADA', 'PENDIENTE')
                 ORDER BY LENGTH(numero_mesa), numero_mesa
                """, idProceso);
        if (!abiertas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "RN32: la votación concluye con todas las mesas cerradas. "
                    + abiertas.stream().map(m -> "Mesa " + m.get("numeroMesa")
                            + ("INSTALADA".equals(m.get("estado")) ? " con el sufragio abierto (CUS11)" : " sin instalar (CUS08)"))
                    .collect(Collectors.joining("; ")) + ".");
        }
        dao.llamar("sp_cambiar_estado_proceso", ProcedimientoDao.SIN_SALIDA, idProceso, "CERRADO", usuario.getId());
        return respuesta("Votación concluida: el proceso pasó a CERRADO. Verifique las actas e instale la sesión de cómputo.",
                idProceso, usuario);
    }

    /** Paso 4 (RF91): sesión de cómputo general con quórum y los personeros presentes. */
    public Map<String, Object> instalarSesion(Integer idProceso, ComputoDto.Sesion datos, Usuario usuario) {
        consulta.proceso(idProceso);
        String personeros = datos.personeros() == null ? "[]"
                : datos.personeros().stream().distinct().map(String::valueOf).collect(Collectors.joining(",", "[", "]"));
        dao.llamar("sp_instalar_sesion_computo", ProcedimientoDao.SIN_SALIDA, idProceso, usuario.getId(),
                datos.lugar().trim(), datos.miembrosCeunp(), vacioANulo(datos.observaciones()), personeros);
        int presentes = datos.personeros() == null ? 0 : (int) datos.personeros().stream().distinct().count();
        return respuesta("Sesión de cómputo instalada en " + datos.lugar().trim() + " con " + datos.miembrosCeunp()
                + " miembros del CEUNP y " + presentes + " personero(s) presentes.", idProceso, usuario);
    }

    /** RF91: un personero acreditado llega a la sesión ya instalada (antes del cómputo). */
    public Map<String, Object> registrarPersonero(Integer idProceso, ComputoDto.Personero datos, Usuario usuario) {
        consulta.proceso(idProceso);
        dao.llamar("sp_registrar_personero_computo", ProcedimientoDao.SIN_SALIDA, idProceso, usuario.getId(),
                datos.idPersonero());
        return respuesta("Personero registrado en la sesión de cómputo.", idProceso, usuario);
    }

    private Map<String, Object> respuesta(String mensaje, Integer idProceso, Usuario usuario) {
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("mensaje", mensaje);
        r.put("detalle", consulta.detalle(idProceso, usuario));
        return r;
    }

    static String vacioANulo(String texto) {
        return texto == null || texto.isBlank() ? null : texto.trim();
    }
}
