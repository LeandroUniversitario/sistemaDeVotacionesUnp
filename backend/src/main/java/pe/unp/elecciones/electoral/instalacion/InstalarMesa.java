package pe.unp.elecciones.electoral.instalacion;

import java.util.LinkedHashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Rol;
import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS08 · «InstalarMesa» (control). Mensajes 10 a 13 del diagrama de colaboración:
 *
 *   10 instalarMesa(id_mesa)                                          → sp_instalar_mesa
 *   11 [antes de 12:00] actualizarEstado('INSTALADA', hora_instalacion) → MesaElectoral
 *   12 insertarActa('INSTALACION', hash)                               → ActaElectoral (RF59)
 *   13 mostrarActaInstalacion()                                        → la respuesta trae el acta
 *
 * <p>También cubre los flujos alternos: NO INSTALADA pasadas las 12:00 (RF58, automático cada
 * minuto o declarado por el CEUNP) y la evaluación de nulidad del CEUNP (RF60).
 * Sin @Transactional a propósito: cada procedimiento abre su transacción (ver ProcedimientoDao).
 */
@Service
public class InstalarMesa {

    private static final Logger log = LoggerFactory.getLogger(InstalarMesa.class);

    private final ProcedimientoDao dao;
    private final InstalacionConsulta consulta;
    private volatile boolean avisoMigracion;

    public InstalarMesa(ProcedimientoDao dao, InstalacionConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 10: instalarMesa(id_mesa). El token del QR del acta solo se devuelve aquí. */
    public Map<String, Object> instalarMesa(Integer idMesa, Usuario usuario) {
        Map<String, Object> detalle = consulta.detalle(idMesa);
        if (usuario.getRol() == Rol.MIEMBRO_MESA) {
            exigirPresidente(idMesa, usuario, detalle);
        }
        ProcedimientoDao.Resultado resultado =
                dao.llamar("sp_instalar_mesa", ProcedimientoDao.SIN_SALIDA, idMesa, usuario.getId());
        Map<String, Object> fila = resultado.filas().isEmpty() ? Map.of() : resultado.filas().get(0);

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Mesa instalada. Se emitió y firmó el Acta de Instalación; el sufragio está habilitado.");
        respuesta.put("idActa", fila.get("idActa"));
        respuesta.put("tokenQr", fila.get("tokenQr"));
        respuesta.put("detalle", consulta.detalle(idMesa)); // 13: mostrarActaInstalacion()
        return respuesta;
    }

    /**
     * El actor del CUS08 es el Presidente de mesa: entre los miembros, instala quien ejerce la
     * presidencia (titular o suplente). Si la asume un reemplazante sin cuenta, puede hacerlo
     * cualquier miembro presente. El CEUNP siempre puede instalar.
     */
    private void exigirPresidente(Integer idMesa, Usuario usuario, Map<String, Object> detalle) {
        if (!consulta.miembroPresente(idMesa, usuario.getIdDocente())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Registre primero su llegada (lea su fotocheck o ingrese su DNI) para instalar la mesa.");
        }
        @SuppressWarnings("unchecked")
        Map<String, Object> presidencia = ((java.util.List<Map<String, Object>>) detalle.get("conformacion")).get(0);
        Object idPresidente = presidencia.get("idDocente");
        boolean esReemplazante = "REEMPLAZANTE".equals(presidencia.get("origen"));
        if (idPresidente != null && !esReemplazante
                && InstalacionConsulta.numero(idPresidente) != InstalacionConsulta.numero(usuario.getIdDocente())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Instala la mesa el presidente en funciones: " + presidencia.get("nombre") + ".");
        }
    }

    /** RF58: el CEUNP declara NO INSTALADA una mesa (con control horario, vencido el plazo). */
    public Map<String, Object> declararNoInstalada(Integer idMesa, String motivo, Integer idUsuario) {
        consulta.mesa(idMesa);
        dao.llamar("sp_declarar_mesa_no_instalada", ProcedimientoDao.SIN_SALIDA, idMesa, idUsuario, motivo.trim());
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "La mesa quedó NO INSTALADA. Sus electores no podrán votar en ella; "
                + "los miembros que no llegaron figuran como inasistentes (RN35). Registre la evaluación de nulidad (RF60).");
        respuesta.put("detalle", consulta.detalle(idMesa));
        return respuesta;
    }

    /** RF60: evaluación de nulidad del CEUNP. */
    public Map<String, Object> evaluarNulidad(Integer idMesa, String decision, String fundamento, Integer idUsuario) {
        consulta.mesa(idMesa);
        String valor = decision == null ? "" : decision.trim().toUpperCase();
        dao.llamar("sp_evaluar_nulidad_mesa", ProcedimientoDao.SIN_SALIDA, idMesa, idUsuario, valor, fundamento.trim());
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "PROCEDE".equals(valor)
                ? "Evaluación registrada: procede la nulidad de la votación de esta mesa."
                : "Evaluación registrada: no procede la nulidad.");
        respuesta.put("detalle", consulta.detalle(idMesa));
        return respuesta;
    }

    /** RF58: cada minuto, las mesas pendientes cuyo plazo venció pasan a NO_INSTALADA. */
    @Scheduled(initialDelay = 30_000, fixedDelay = 60_000)
    public void vigilarPlazo() {
        try {
            int marcadas = consulta.aplicarPlazo();
            if (marcadas > 0) {
                log.info("RF58: {} mesa(s) marcadas como NO_INSTALADA por vencimiento del plazo.", marcadas);
            }
        } catch (RuntimeException e) {
            if (!avisoMigracion) {
                avisoMigracion = true;
                log.warn("CUS08: no se pudo revisar el plazo de instalación ({}). ¿Se ejecutó 09_instalacion_mesa.sql?",
                        e.getMessage());
            }
        }
    }
}
