package pe.unp.elecciones.electoral.impugnaciones;

import java.sql.Types;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Rol;
import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS13 · «RegistrarImpugnacion» (control). Mensajes 2 a 5 del diagrama de colaboración:
 *
 *   2 registrarImpugnacion(datos)
 *   3 verificarAcreditacion(id_personero)          → Personero (RN24: solo personeros de mesa)
 *   4 insertar(id_personero, id_mesa, motivo)      → ImpugnacionElectoral (sp_registrar_impugnacion, CUS12)
 *   5 confirmarRegistro()                          → la respuesta trae la impugnación registrada
 *
 * <p>El procedimiento lo crea el CUS12 (11_escrutinio_conciliacion.sql), que es donde la cédula
 * se cuenta como IMPUGNADO. Lo ingresa el propio personero o, a pedido suyo, un miembro de la mesa.
 */
@Service
public class RegistrarImpugnacion {

    private final ProcedimientoDao dao;
    private final ImpugnacionesConsulta consulta;

    public RegistrarImpugnacion(ProcedimientoDao dao, ImpugnacionesConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 2: registrarImpugnacion(datos). */
    public Map<String, Object> registrarImpugnacion(Integer idMesa, ImpugnacionesDto.NuevaImpugnacion datos, Usuario usuario) {
        consulta.mesa(idMesa);
        if (!consulta.registroDisponible()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "El registro de impugnaciones es parte del escrutinio: ejecute base-de-datos/11_escrutinio_conciliacion.sql (CUS12).");
        }
        Integer idPersonero = verificarAcreditacion(idMesa, datos.idPersonero(), usuario);
        ProcedimientoDao.Resultado resultado = dao.llamar("sp_registrar_impugnacion", new int[] {Types.BIGINT},
                idMesa, usuario.getId(), idPersonero, datos.idCargo(), datos.motivo().trim());
        Long id = resultado.salidas()[0] instanceof Number n ? n.longValue() : null;

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Impugnación N.º " + id + " registrada. La cédula se cuenta como IMPUGNADA hasta que la mesa la resuelva.");
        respuesta.put("idImpugnacion", id); // 5: confirmarRegistro()
        respuesta.put("detalle", consulta.detalle(idMesa, usuario));
        return respuesta;
    }

    /**
     * 3: verificarAcreditacion(id_personero). El personero impugna en su nombre y debe estar presente
     * en la mesa; un miembro de la mesa lo registra a pedido de un personero presente.
     */
    private Integer verificarAcreditacion(Integer idMesa, Integer idPersonero, Usuario usuario) {
        List<Integer> presentes = consulta.personerosDeMesa(idMesa).stream()
                .map(p -> ImpugnacionesConsulta.numero(p.get("idPersonero"))).toList();
        if (usuario.getRol() == Rol.PERSONERO) {
            List<Integer> propios = consulta.personerosDelDocente(usuario.getIdDocente()).stream()
                    .map(p -> ImpugnacionesConsulta.numero(p.get("idPersonero"))).filter(presentes::contains).toList();
            if (propios.isEmpty()) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                        "RN24: impugna un personero acreditado y presente en esta mesa (CUS08).");
            }
            if (idPersonero == null) {
                return propios.get(0);
            }
            if (!propios.contains(idPersonero)) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Un personero impugna solo en su nombre.");
            }
            return idPersonero;
        }
        if (usuario.getRol() == Rol.MIEMBRO_MESA) {
            if (idPersonero == null) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Indique el personero que impugna.");
            }
            if (!presentes.contains(idPersonero)) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "RN24: solo impugna un personero presente en la mesa.");
            }
            return idPersonero;
        }
        throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                "RN24: impugna el personero; la mesa lo registra a su pedido.");
    }
}
