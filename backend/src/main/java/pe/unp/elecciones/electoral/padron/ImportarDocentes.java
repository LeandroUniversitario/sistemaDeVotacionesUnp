package pe.unp.elecciones.electoral.padron;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.service.Bitacora;
import pe.unp.elecciones.electoral.service.ImportacionDocenteService;

/**
 * CUS02 · Control «ImportarDocentes» del diagrama de colaboración.
 *
 * <pre>
 *  PantallaPadron    --2: leerDatos()--> ImportarDocentes
 *  ImportarDocentes  --3: registrarMasivo(datos)--> docente
 *  ImportarDocentes  --4: mostrarImportados()--> PantallaPadron
 * </pre>
 *
 * La lectura del Excel/CSV y el registro masivo (UPSERT por DNI) los hace
 * ImportacionDocenteService; aquí se valida el archivo, se deja constancia en la
 * bitácora y se arma la respuesta para la pantalla.
 */
@Service
public class ImportarDocentes {

    private static final long TAMANO_MAXIMO = 5L * 1024 * 1024;

    private final ImportacionDocenteService importacion;
    private final PadronConsulta consulta;
    private final Bitacora bitacora;

    public ImportarDocentes(ImportacionDocenteService importacion, PadronConsulta consulta, Bitacora bitacora) {
        this.importacion = importacion;
        this.consulta = consulta;
        this.bitacora = bitacora;
    }

    /** 2: leerDatos() — lee el archivo y delega 3: registrarMasivo(datos). */
    public Map<String, Object> leerDatos(MultipartFile archivo, Integer idUsuario) {
        if (archivo == null || archivo.isEmpty()) {
            throw badRequest("Seleccione un archivo con el padrón de docentes.");
        }
        if (archivo.getSize() > TAMANO_MAXIMO) {
            throw badRequest("El archivo supera los 5 MB permitidos.");
        }
        String nombre = archivo.getOriginalFilename() == null ? "" : archivo.getOriginalFilename();
        String minusculas = nombre.toLowerCase(Locale.ROOT);

        Map<String, Object> resultado;
        try {
            if (minusculas.endsWith(".xlsx")) {
                resultado = importacion.importarExcel(archivo);
            } else if (minusculas.endsWith(".csv")) {
                resultado = importacion.importarCsv(archivo);
            } else {
                throw badRequest("Formato no soportado. Use un archivo Excel (.xlsx) o CSV.");
            }
        } catch (ResponseStatusException e) {
            throw e;
        } catch (Exception e) {
            throw badRequest("No se pudo leer el archivo: " + e.getMessage());
        }

        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("archivo", nombre);
        detalle.put("insertados", resultado.get("insertados"));
        detalle.put("actualizados", resultado.get("actualizados"));
        detalle.put("errores", resultado.get("errores") instanceof List<?> l ? l.size() : 0);
        bitacora.registrar(idUsuario, null, "IMPORTAR_DOCENTES", detalle);

        return mostrarImportados(nombre, resultado);
    }

    /** 4: mostrarImportados() */
    private Map<String, Object> mostrarImportados(String archivo, Map<String, Object> resultado) {
        int insertados = PadronConsulta.numero(resultado.get("insertados"));
        int actualizados = PadronConsulta.numero(resultado.get("actualizados"));
        int usuariosCreados = PadronConsulta.numero(resultado.get("usuariosCreados"));
        Object errores = resultado.get("errores");
        int conError = errores instanceof List<?> l ? l.size() : 0;

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Archivo «" + archivo + "» procesado: " + insertados + " docentes nuevos, "
                + actualizados + " actualizados" + (conError > 0 ? " y " + conError + " filas con error." : "."));
        respuesta.put("archivo", archivo);
        respuesta.put("insertados", insertados);
        respuesta.put("actualizados", actualizados);
        respuesta.put("usuariosCreados", usuariosCreados);
        respuesta.put("errores", errores == null ? List.of() : errores);
        respuesta.put("resumen", consulta.resumenDocentes());
        return respuesta;
    }

    private static ResponseStatusException badRequest(String mensaje) {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, mensaje);
    }
}
