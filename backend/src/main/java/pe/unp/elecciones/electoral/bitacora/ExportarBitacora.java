package pe.unp.elecciones.electoral.bitacora;

import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS19 · Exportación de la bitácora a CSV con los mismos filtros de la pantalla (hasta
 * BITACORA_EXPORTACION_MAX registros). El archivo se abre en Excel (UTF-8 con BOM, separador «;»)
 * e incluye el sello SHA-256 de cada registro para cotejarlo después con la base. Cada exportación
 * queda en la bitácora con sus filtros (sp_registrar_exportacion_bitacora → EXPORTAR_BITACORA).
 */
@Service
public class ExportarBitacora {

    private static final DateTimeFormatter NOMBRE = DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss");
    private static final DateTimeFormatter FECHA = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static final String[] COLUMNAS = {"N.º", "Fecha y hora", "Código de acción", "Acción", "Módulo", "Caso de uso",
        "Criticidad", "Usuario", "Rol", "Docente de la cuenta", "Docente referido", "DNI", "Proceso", "IP de origen",
        "Navegador", "Detalle (JSON)", "Sello anterior (SHA-256)", "Sello del registro (SHA-256)"};

    private final BitacoraConsulta consulta;
    private final ProcedimientoDao dao;
    private final ObjectMapper json;

    public ExportarBitacora(BitacoraConsulta consulta, ProcedimientoDao dao, ObjectMapper json) {
        this.consulta = consulta;
        this.dao = dao;
        this.json = json;
    }

    public record Archivo(String nombre, byte[] contenido, int registros, boolean truncado) {
    }

    public Archivo csv(BitacoraDto.Filtros filtros, boolean ascendente, Usuario admin, String ip, String userAgent) {
        consulta.verificarInstalacion();
        consulta.validarRolAdministrador(admin.getId());
        int maximo = consulta.maximoExportacion();
        BitacoraConsulta.Condicion c = consulta.condicion(filtros);
        List<Object> a = new java.util.ArrayList<>(c.argumentos());
        a.add(maximo + 1);
        List<Map<String, Object>> filas = dao.consultar("SELECT v.* FROM v_bitacora v" + c.sql()
                + " ORDER BY v.id_log " + (ascendente ? "ASC" : "DESC") + " LIMIT ?", a.toArray());
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "No hay registros para exportar con los filtros aplicados.");
        }
        boolean truncado = filas.size() > maximo;
        if (truncado) {
            filas = filas.subList(0, maximo);
        }

        StringBuilder sb = new StringBuilder("﻿");
        linea(sb, (Object[]) COLUMNAS);
        for (Map<String, Object> f : filas) {
            Object fecha = f.get("fechaHora");
            linea(sb, f.get("idLog"), fecha instanceof LocalDateTime t ? t.format(FECHA) : fecha, f.get("accion"),
                    f.get("etiqueta"), f.get("modulo"), f.get("casoUso"), f.get("criticidad"),
                    f.get("username") == null ? "Sin cuenta" : f.get("username"), f.get("rol"), f.get("usuarioDocente"),
                    f.get("docente"), f.get("dniDocente"), f.get("proceso"), f.get("ipOrigen"), f.get("userAgent"),
                    f.get("detalleJson"), f.get("hashAnterior"), f.get("hashRegistro"));
        }

        Map<String, Object> descripcion = new java.util.LinkedHashMap<>(consulta.descripcion(filtros));
        descripcion.put("orden", ascendente ? "ASC" : "DESC");
        descripcion.put("truncado", truncado);
        String filtrosJson;
        try {
            filtrosJson = json.writeValueAsString(descripcion);
        } catch (JsonProcessingException e) {
            filtrosJson = "{}";
        }
        dao.llamar("sp_registrar_exportacion_bitacora", ProcedimientoDao.SIN_SALIDA, admin.getId(), "CSV", filas.size(),
                filtrosJson, ip, userAgent == null ? null : userAgent.substring(0, Math.min(userAgent.length(), 500)));

        String nombre = "bitacora_elecciones_unp_" + LocalDateTime.now().format(NOMBRE) + ".csv";
        return new Archivo(nombre, sb.toString().getBytes(StandardCharsets.UTF_8), filas.size(), truncado);
    }

    private static void linea(StringBuilder sb, Object... valores) {
        for (int i = 0; i < valores.length; i++) {
            if (i > 0) {
                sb.append(';');
            }
            sb.append(celda(valores[i]));
        }
        sb.append("\r\n");
    }

    /** Entre comillas; un valor que empieza con = + - @ se antepone con ' para que Excel no lo ejecute. */
    private static String celda(Object valor) {
        if (valor == null) {
            return "";
        }
        String v = String.valueOf(valor);
        if (!v.isEmpty() && "=+-@\t\r".indexOf(v.charAt(0)) >= 0) {
            v = "'" + v;
        }
        return "\"" + v.replace("\"", "\"\"") + "\"";
    }
}
