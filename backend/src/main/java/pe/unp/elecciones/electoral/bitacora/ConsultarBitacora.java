package pe.unp.elecciones.electoral.bitacora;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;

import pe.unp.elecciones.auth.Usuario;

/**
 * CUS19 · Control «ConsultarBitacora». Mensajes del diagrama «Consultar bitácora»:
 * <ul>
 *   <li>2 buscarRegistros(filtros): recibe los filtros de la PantallaBitacora</li>
 *   <li>3 validarRolAdministrador(id_usuario) → Usuario: sp_validar_admin (ADMIN activo en la base)</li>
 *   <li>4 consultar(filtros) → LogAuditoria: v_bitacora, paginada en el orden de la cadena</li>
 *   <li>5 mostrarRegistros(lista): página, total y resumen del resultado</li>
 * </ul>
 * Solo lectura: la bitácora no se modifica ni se borra (trg_log_bu, trg_log_bd).
 */
@Service
public class ConsultarBitacora {

    private final BitacoraConsulta consulta;

    public ConsultarBitacora(BitacoraConsulta consulta) {
        this.consulta = consulta;
    }

    /** Datos fijos de la pantalla: catálogo, cuentas, procesos, sello de la cadena y alertas. */
    public Map<String, Object> pantalla(Usuario admin) {
        consulta.verificarInstalacion();
        consulta.validarRolAdministrador(admin.getId());
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("idAdmin", admin.getId());
        r.put("acciones", consulta.acciones());
        r.put("usuarios", consulta.usuarios());
        r.put("procesos", consulta.procesos());
        r.put("cadena", consulta.cadena());
        r.put("alertas", consulta.alertas());
        r.put("exportacionMax", consulta.maximoExportacion());
        r.put("tamanoMaximo", BitacoraConsulta.TAMANO_MAXIMO);
        return r;
    }

    /** 2 buscarRegistros(filtros) → 3 validarRolAdministrador → 4 consultar → 5 mostrarRegistros(lista). */
    public Map<String, Object> buscarRegistros(BitacoraDto.Filtros filtros, int pagina, int tamano, boolean ascendente,
            boolean conResumen, Usuario admin) {
        consulta.verificarInstalacion();
        consulta.validarRolAdministrador(admin.getId());
        int t = Math.max(10, Math.min(tamano, BitacoraConsulta.TAMANO_MAXIMO));
        BitacoraConsulta.Condicion c = consulta.condicion(filtros);
        long total = consulta.contar(c);
        int paginas = (int) Math.max(1, (total + t - 1) / t);
        int p = Math.max(0, Math.min(pagina, paginas - 1));
        List<Map<String, Object>> registros = consulta.registros(c, ascendente, t, (long) p * t);

        Map<String, Object> r = new LinkedHashMap<>();
        r.put("registros", registros);
        r.put("total", total);
        r.put("pagina", p);
        r.put("tamano", t);
        r.put("paginas", paginas);
        r.put("orden", ascendente ? "ASC" : "DESC");
        r.put("filtros", consulta.descripcion(filtros));
        if (conResumen) {
            r.put("resumen", consulta.resumen(c));
        }
        return r;
    }
}
