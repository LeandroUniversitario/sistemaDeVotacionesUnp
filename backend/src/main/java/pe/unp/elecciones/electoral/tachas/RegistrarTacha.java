package pe.unp.elecciones.electoral.tachas;

import java.sql.Types;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.service.ProcedimientoDao;
import pe.unp.elecciones.electoral.tachas.TachasDto.DatosTacha;

/**
 * CUS04 · Control «RegistrarTacha» del diagrama de colaboración.
 *
 * <pre>
 *  PantallaTachas --2: enviarTacha(datos)--> RegistrarTacha
 *  RegistrarTacha --3: insertar(id_denunciante, id_candidato, motivo)--> Tacha
 *  RegistrarTacha --4: confirmarRecepcion()--> PantallaTachas
 * </pre>
 *
 * sp_presentar_tacha exige: proceso en INSCRIPCION, denunciante docente ACTIVO,
 * que no se tache a sí mismo y que la tacha esté fundamentada por escrito.
 * Aquí se añade: el candidato no debe estar ya excluido y el mismo docente no puede
 * repetir una tacha pendiente contra el mismo candidato.
 */
@Service
public class RegistrarTacha {

    private final ProcedimientoDao dao;
    private final TachasConsulta consulta;

    public RegistrarTacha(ProcedimientoDao dao, TachasConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 2: enviarTacha(datos) a nombre del docente indicado. */
    public Map<String, Object> enviarTacha(DatosTacha datos, Integer idDenunciante) {
        List<Map<String, Object>> candidato = dao.consultar("""
                SELECT ca.estado_validacion, ca.id_docente, CONCAT(d.apellidos, ', ', d.nombres) AS nombre,
                       l.estado AS estado_lista, l.nombre AS lista
                  FROM candidato ca
                  JOIN docente d ON d.id_docente = ca.id_docente
                  JOIN lista_electoral l ON l.id_lista = ca.id_lista
                 WHERE ca.id_candidato = ?
                """, datos.idCandidato());
        if (candidato.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El candidato no existe.");
        }
        List<Map<String, Object>> proc = dao.consultar("""
                SELECT p.estado, p.fecha_limite_inscripcion
                  FROM candidato ca
                  JOIN lista_electoral l ON l.id_lista = ca.id_lista
                  JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                  JOIN proceso_electoral p ON p.id_proceso = c.id_proceso
                 WHERE ca.id_candidato = ?
                """, datos.idCandidato());
        if (!proc.isEmpty()) {
            String est = (String) proc.get(0).get("estado");
            if (!"INSCRIPCION".equals(est)) {
                throw badRequest("Las tachas solo se pueden presentar en etapa de INSCRIPCION.");
            }
            Object limite = proc.get(0).get("fechaLimiteInscripcion");
            if (limite == null) limite = proc.get(0).get("fecha_limite_inscripcion");
            if (limite instanceof java.time.LocalDateTime f && java.time.LocalDateTime.now().isAfter(f)) {
                throw badRequest("RN13: Venció el plazo para presentar tachas en este proceso electoral.");
            }
        }

        if ("EXCLUIDO".equals(candidato.get(0).get("estadoValidacion"))) {
            throw badRequest("El candidato ya fue excluido; no procede una nueva tacha.");
        }
        Object estadoLista = candidato.get(0).get("estadoLista");
        if ("TACHADA".equals(estadoLista) || "EXCLUIDA".equals(estadoLista)) {
            throw badRequest("La lista «" + candidato.get(0).get("lista") + "» ya está " + estadoLista
                    + " y salió de la contienda (RN12); no procede una nueva tacha.");
        }
        if (dao.entero("""
                SELECT COUNT(*) FROM tacha
                 WHERE id_docente_denunciante = ? AND id_candidato = ? AND estado = 'PENDIENTE'
                """, idDenunciante, datos.idCandidato()) > 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Ya presentó una tacha contra este candidato y está pendiente de resolución.");
        }

        Integer idTacha = insertar(idDenunciante, datos.idCandidato(), datos.motivo().trim());
        return confirmarRecepcion(idTacha);
    }

    /** Busca al denunciante por DNI (tacha recibida por el CEUNP en mesa de partes). */
    public Integer docentePorDni(String dni) {
        String limpio = dni == null ? "" : dni.trim();
        if (!limpio.matches("\\d{1,8}")) {
            throw badRequest("RN05: ingrese el DNI del docente denunciante (8 dígitos).");
        }
        List<Map<String, Object>> filas = dao.consultar("SELECT id_docente FROM docente WHERE dni = ?",
                String.format("%08d", Long.parseLong(limpio)));
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "No hay ningún docente con ese DNI.");
        }
        return ((Number) filas.get(0).get("idDocente")).intValue();
    }

    /** 3: insertar(id_denunciante, id_candidato, motivo) en Tacha (sp_presentar_tacha, registra PRESENTAR_TACHA). */
    private Integer insertar(Integer idDenunciante, Integer idCandidato, String motivo) {
        ProcedimientoDao.Resultado resultado = dao.llamar("sp_presentar_tacha", new int[] {Types.INTEGER},
                idDenunciante, idCandidato, motivo);
        Object id = resultado.salidas()[0];
        if (!(id instanceof Number numero)) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR,
                    "No se obtuvo el número de la tacha registrada.");
        }
        return numero.intValue();
    }

    /** 4: confirmarRecepcion() */
    private Map<String, Object> confirmarRecepcion(Integer idTacha) {
        Map<String, Object> tacha = consulta.tacha(idTacha);
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Tacha N.º " + idTacha + " recibida contra " + tacha.get("candidato")
                + " (lista «" + tacha.get("lista") + "»). El CEUNP la resolverá y se le notificará el fallo.");
        respuesta.put("tacha", tacha);
        return respuesta;
    }

    private static ResponseStatusException badRequest(String mensaje) {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, mensaje);
    }
}
