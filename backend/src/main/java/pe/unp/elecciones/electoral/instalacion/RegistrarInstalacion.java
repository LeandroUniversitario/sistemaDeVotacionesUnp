package pe.unp.elecciones.electoral.instalacion;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import pe.unp.elecciones.auth.Rol;
import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.Bitacora;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS08 · Registro del material, instalación de la mesa y declaración de NO INSTALADA.
 *
 * <p>Las reglas de la instalación las valida sp_instalar_mesa dentro de una transacción
 * (horario RN07, 6 miembros RN19, cargos cubiertos, material obligatorio) y emite el acta
 * con su huella SHA-256 (RN28). Sin @Transactional a propósito (ver ProcedimientoDao).
 */
@Service
public class RegistrarInstalacion {

    private final ProcedimientoDao dao;
    private final InstalacionConsulta consulta;
    private final Bitacora bitacora;
    private final ObjectMapper json;

    public RegistrarInstalacion(ProcedimientoDao dao, InstalacionConsulta consulta, Bitacora bitacora,
            ObjectMapper json) {
        this.dao = dao;
        this.consulta = consulta;
        this.bitacora = bitacora;
        this.json = json;
    }

    public Map<String, Object> guardarMaterial(Integer idMesa, Map<String, Boolean> items, String observaciones,
            Integer idUsuario) {
        Map<String, Object> mesa = consulta.mesaEditable(idMesa);
        for (String codigo : items.keySet()) {
            try {
                MaterialElectoral.valueOf(codigo);
            } catch (IllegalArgumentException e) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Material desconocido: " + codigo);
            }
        }
        Map<String, Boolean> recibido = new LinkedHashMap<>();
        List<String> faltantes = new ArrayList<>();
        for (MaterialElectoral m : MaterialElectoral.values()) {
            boolean ok = Boolean.TRUE.equals(items.get(m.name()));
            recibido.put(m.name(), ok);
            if (m.obligatorio() && !ok) {
                faltantes.add(m.name());
            }
        }
        String obs = observaciones == null || observaciones.isBlank() ? null : observaciones.trim();
        String materialJson;
        try {
            materialJson = json.writeValueAsString(recibido);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException(e);
        }
        dao.ejecutar("""
                INSERT INTO instalacion_mesa (id_mesa, material_json, material_completo, observaciones,
                                              id_usuario_registro, fecha_actualizacion)
                VALUES (?, ?, ?, ?, ?, NOW())
                ON DUPLICATE KEY UPDATE material_json = VALUES(material_json),
                                        material_completo = VALUES(material_completo),
                                        observaciones = VALUES(observaciones),
                                        fecha_actualizacion = NOW()
                """, idMesa, materialJson, faltantes.isEmpty(), obs, idUsuario);

        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("id_mesa", idMesa);
        detalle.put("completo", faltantes.isEmpty());
        detalle.put("faltantes", String.join(",", faltantes));
        bitacora.registrar(idUsuario, InstalacionConsulta.numero(mesa.get("idProceso")), "REGISTRAR_MATERIAL_MESA", detalle);
        return consulta.detalle(idMesa);
    }

    /** Instala la mesa y emite el Acta de Instalación. El token del QR del acta solo se devuelve aquí. */
    public Map<String, Object> instalar(Integer idMesa, Usuario usuario) {
        consulta.mesa(idMesa);
        if (usuario.getRol() == Rol.MIEMBRO_MESA && !consulta.miembroPresente(idMesa, usuario.getIdDocente())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Acredítese primero (lea su fotocheck o registre su DNI) para instalar la mesa.");
        }
        ProcedimientoDao.Resultado resultado =
                dao.llamar("sp_instalar_mesa", ProcedimientoDao.SIN_SALIDA, idMesa, usuario.getId());
        Map<String, Object> fila = resultado.filas().isEmpty() ? Map.of() : resultado.filas().get(0);

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Mesa instalada. Se emitió y firmó el Acta de Instalación; el sufragio está habilitado.");
        respuesta.put("idActa", fila.get("idActa"));
        respuesta.put("tokenQr", fila.get("tokenQr"));
        respuesta.put("detalle", consulta.detalle(idMesa));
        return respuesta;
    }

    /** RN07: vencido el plazo, el CEUNP deja constancia de que la mesa no se instaló. */
    public Map<String, Object> declararNoInstalada(Integer idMesa, String motivo, Integer idUsuario) {
        consulta.mesa(idMesa);
        dao.llamar("sp_declarar_mesa_no_instalada", ProcedimientoDao.SIN_SALIDA, idMesa, idUsuario, motivo.trim());
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "La mesa quedó NO INSTALADA. Sus electores no podrán votar en ella; "
                + "los miembros que no se acreditaron figuran como inasistentes (RN35).");
        respuesta.put("detalle", consulta.detalle(idMesa));
        return respuesta;
    }
}
