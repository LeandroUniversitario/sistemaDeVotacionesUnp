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

import pe.unp.elecciones.electoral.instalacion.InstalacionDto.ItemMaterial;
import pe.unp.elecciones.electoral.service.Bitacora;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS08 · «VerificarMaterial» (control). Mensajes 6 a 8 del diagrama de colaboración:
 *
 *   6 verificarMaterial(datos)                    → valida el estado de cada material (RF57)
 *   7 registrarMaterial(id_mesa, estado_material) → instalacion_mesa (datos de instalación de la mesa)
 *   8 mostrarEstadoMaterial()                     → la respuesta trae el detalle de la mesa
 */
@Service
public class VerificarMaterial {

    private final ProcedimientoDao dao;
    private final InstalacionConsulta consulta;
    private final Bitacora bitacora;
    private final ObjectMapper json;

    public VerificarMaterial(ProcedimientoDao dao, InstalacionConsulta consulta, Bitacora bitacora, ObjectMapper json) {
        this.dao = dao;
        this.consulta = consulta;
        this.bitacora = bitacora;
        this.json = json;
    }

    /** 6: verificarMaterial(datos). */
    public Map<String, Object> verificarMaterial(Integer idMesa, InstalacionDto.Material datos, Integer idUsuario) {
        Map<String, Object> mesa = consulta.mesaEditable(idMesa);
        for (String codigo : datos.items().keySet()) {
            try {
                MaterialElectoral.valueOf(codigo);
            } catch (IllegalArgumentException e) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Material desconocido: " + codigo);
            }
        }
        Map<String, Map<String, Object>> estadoMaterial = new LinkedHashMap<>();
        List<String> faltantes = new ArrayList<>();
        List<String> observados = new ArrayList<>();
        for (MaterialElectoral m : MaterialElectoral.values()) {
            ItemMaterial item = datos.items().get(m.name());
            MaterialElectoral.Estado estado;
            try {
                estado = item == null ? MaterialElectoral.Estado.NO_RECIBIDO
                        : MaterialElectoral.Estado.valueOf(item.estado().trim().toUpperCase());
            } catch (IllegalArgumentException e) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "Estado desconocido para " + m.descripcion() + ": use CONFORME, OBSERVADO o NO_RECIBIDO.");
            }
            String observacion = item == null || item.observacion() == null || item.observacion().isBlank()
                    ? null : item.observacion().trim();
            if (estado == MaterialElectoral.Estado.OBSERVADO && observacion == null) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "Describa la observación de: " + m.descripcion() + ".");
            }
            if (estado == MaterialElectoral.Estado.NO_RECIBIDO) {
                faltantes.add(m.name());
            } else if (estado == MaterialElectoral.Estado.OBSERVADO) {
                observados.add(m.name());
            }
            Map<String, Object> valor = new LinkedHashMap<>();
            valor.put("estado", estado.name());
            valor.put("observacion", observacion);
            estadoMaterial.put(m.name(), valor);
        }
        Integer cedulas = datos.cedulasRecibidas();
        if (cedulas != null && cedulas > 0 && estadoMaterial.get(MaterialElectoral.CEDULAS.name()).get("estado")
                .equals(MaterialElectoral.Estado.NO_RECIBIDO.name())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Indicó cédulas recibidas pero marcó las cédulas como no recibidas.");
        }
        boolean firmadas = datos.cedulasFirmadas() && cedulas != null && cedulas > 0;
        registrarMaterial(idMesa, estadoMaterial, faltantes.isEmpty(), cedulas, firmadas, datos.observaciones(), idUsuario);

        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("id_mesa", idMesa);
        detalle.put("completo", faltantes.isEmpty());
        detalle.put("faltantes", String.join(",", faltantes));
        detalle.put("observados", String.join(",", observados));
        detalle.put("cedulas", cedulas);
        bitacora.registrar(idUsuario, InstalacionConsulta.numero(mesa.get("idProceso")), "VERIFICAR_MATERIAL_MESA", detalle);
        return consulta.detalle(idMesa); // 8: mostrarEstadoMaterial()
    }

    /** 7: registrarMaterial(id_mesa, estado_material). */
    private void registrarMaterial(Integer idMesa, Map<String, Map<String, Object>> estadoMaterial, boolean completo,
            Integer cedulas, boolean firmadas, String observaciones, Integer idUsuario) {
        String obs = observaciones == null || observaciones.isBlank() ? null : observaciones.trim();
        String materialJson;
        try {
            materialJson = json.writeValueAsString(estadoMaterial);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException(e);
        }
        dao.ejecutar("""
                INSERT INTO instalacion_mesa (id_mesa, material_json, material_completo, cedulas_recibidas,
                                              cedulas_firmadas, observaciones, id_usuario_registro, fecha_actualizacion)
                VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
                ON DUPLICATE KEY UPDATE material_json = VALUES(material_json),
                                        material_completo = VALUES(material_completo),
                                        cedulas_recibidas = VALUES(cedulas_recibidas),
                                        cedulas_firmadas = VALUES(cedulas_firmadas),
                                        observaciones = VALUES(observaciones),
                                        id_usuario_registro = VALUES(id_usuario_registro),
                                        fecha_actualizacion = NOW()
                """, idMesa, materialJson, completo, cedulas, firmadas, obs, idUsuario);
    }
}
