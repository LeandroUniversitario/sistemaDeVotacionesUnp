package pe.unp.elecciones.electoral.service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Component;

/**
 * Registra acciones de los casos de uso en log_auditoria (bitácora inmutable).
 * El detalle se guarda como JSON construido por la propia base de datos (JSON_OBJECT),
 * así los valores siempre quedan bien escapados.
 */
@Component
public class Bitacora {

    private final ProcedimientoDao dao;

    public Bitacora(ProcedimientoDao dao) {
        this.dao = dao;
    }

    public void registrar(Integer idUsuario, Integer idProceso, String accion, Map<String, Object> detalle) {
        StringBuilder json = new StringBuilder("JSON_OBJECT(");
        List<Object> argumentos = new ArrayList<>();
        argumentos.add(idUsuario);
        argumentos.add(idProceso);
        argumentos.add(accion);
        boolean primero = true;
        for (Map.Entry<String, Object> par : detalle.entrySet()) {
            if (!primero) {
                json.append(", ");
            }
            json.append("?, ?");
            argumentos.add(par.getKey());
            argumentos.add(par.getValue() == null ? null : String.valueOf(par.getValue()));
            primero = false;
        }
        json.append(")");
        dao.ejecutar("INSERT INTO log_auditoria (id_usuario, id_proceso, accion, detalle_json) VALUES (?, ?, ?, "
                + json + ")", argumentos.toArray());
    }
}
