package pe.unp.elecciones.electoral.convocatoria;

import java.sql.Types;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.convocatoria.ConvocatoriaDto.DatosCargo;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS01 · Control «AgregarCargo» del diagrama de colaboración.
 *
 * <pre>
 *  PantallaConvocatoria --6: guardarCargo(datos_cargo)--> AgregarCargo
 *  AgregarCargo         --7: insertar(id_proceso, nombre, nivel)--> CargoElectoral
 *  AgregarCargo         --8: actualizarListaCargos()--> PantallaConvocatoria
 * </pre>
 *
 * Los cargos solo se agregan o quitan mientras la convocatoria está en CREADO.
 */
@Service
public class AgregarCargo {

    private static final Set<String> NIVELES = Set.of("UNIVERSIDAD", "FACULTAD", "DEPARTAMENTO");
    private static final List<String> CATEGORIAS = List.of("PRINCIPAL", "ASOCIADO", "AUXILIAR");

    private final ProcedimientoDao dao;
    private final ConvocatoriaConsulta consulta;

    public AgregarCargo(ProcedimientoDao dao, ConvocatoriaConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 6: guardarCargo(datos_cargo) */
    public Map<String, Object> guardarCargo(Integer idProceso, DatosCargo datos, Integer idUsuario) {
        exigirConvocatoriaEditable(idProceso);

        String nombre = datos.nombre().trim();
        String nivel = datos.nivel().trim().toUpperCase(Locale.ROOT);
        if (!NIVELES.contains(nivel)) {
            throw badRequest("Nivel inválido: use UNIVERSIDAD, FACULTAD o DEPARTAMENTO.");
        }
        Integer idJurisdiccion = "UNIVERSIDAD".equals(nivel) ? null : datos.idJurisdiccion();
        if (!"UNIVERSIDAD".equals(nivel) && idJurisdiccion == null) {
            throw badRequest("Seleccione la " + ("FACULTAD".equals(nivel) ? "facultad" : "el departamento")
                    + " a la que corresponde el cargo.");
        }
        String votan = categorias(datos.categoriasVotan(), "votar");
        String postulan = categorias(datos.categoriasPostulan(), "postular");

        int repetidos = dao.entero("""
                SELECT COUNT(*) FROM cargo_electoral
                 WHERE id_proceso = ? AND LOWER(nombre) = LOWER(?)
                   AND nivel_jurisdiccion = ? AND id_jurisdiccion <=> ?
                """, idProceso, nombre, nivel, idJurisdiccion);
        if (repetidos > 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "El cargo «" + nombre + "» ya está registrado en esta convocatoria para esa jurisdicción.");
        }

        Integer idCargo = insertar(idProceso, nombre, nivel, idJurisdiccion, votan, postulan);

        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("id_cargo", idCargo);
        detalle.put("nombre", nombre);
        detalle.put("nivel", nivel);
        detalle.put("id_jurisdiccion", idJurisdiccion);
        detalle.put("votan", votan);
        detalle.put("postulan", postulan);
        consulta.auditar(idUsuario, idProceso, "AGREGAR_CARGO", detalle);

        return actualizarListaCargos(idProceso, "Cargo «" + nombre + "» agregado.");
    }

    /** Quita un cargo mal registrado (solo en CREADO y si aún no tiene listas). */
    public Map<String, Object> quitarCargo(Integer idProceso, Integer idCargo, Integer idUsuario) {
        exigirConvocatoriaEditable(idProceso);
        List<Map<String, Object>> filas = dao.consultar(
                "SELECT nombre FROM cargo_electoral WHERE id_cargo = ? AND id_proceso = ?", idCargo, idProceso);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El cargo no pertenece a esta convocatoria.");
        }
        if (dao.entero("SELECT COUNT(*) FROM lista_electoral WHERE id_cargo = ?", idCargo) > 0) {
            throw badRequest("El cargo ya tiene listas inscritas y no se puede quitar.");
        }
        dao.ejecutar("DELETE FROM cargo_electoral WHERE id_cargo = ? AND id_proceso = ?", idCargo, idProceso);

        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("id_cargo", idCargo);
        detalle.put("nombre", filas.get(0).get("nombre"));
        consulta.auditar(idUsuario, idProceso, "QUITAR_CARGO", detalle);

        return actualizarListaCargos(idProceso, "Cargo «" + filas.get(0).get("nombre") + "» retirado.");
    }

    /** 7: insertar(id_proceso, nombre, nivel) sobre CargoElectoral (sp_agregar_cargo, RF03). */
    private Integer insertar(Integer idProceso, String nombre, String nivel, Integer idJurisdiccion,
            String votan, String postulan) {
        ProcedimientoDao.Resultado resultado = dao.llamar("sp_agregar_cargo", new int[] {Types.INTEGER},
                idProceso, nombre, nivel, idJurisdiccion, votan, postulan);
        Object id = resultado.salidas()[0];
        if (!(id instanceof Number numero)) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR,
                    "No se obtuvo el identificador del cargo registrado.");
        }
        return numero.intValue();
    }

    /** 8: actualizarListaCargos() */
    private Map<String, Object> actualizarListaCargos(Integer idProceso, String mensaje) {
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", mensaje);
        respuesta.putAll(consulta.detalle(idProceso));
        return respuesta;
    }

    private void exigirConvocatoriaEditable(Integer idProceso) {
        Map<String, Object> proceso = consulta.proceso(idProceso);
        if (!"CREADO".equals(proceso.get("estado"))) {
            throw badRequest("La convocatoria ya fue publicada (estado " + proceso.get("estado")
                    + "); sus cargos no se pueden modificar.");
        }
    }

    /** Normaliza la lista de categorías a 'PRINCIPAL,ASOCIADO,...'. Vacía o null = todas. */
    private static String categorias(List<String> valores, String accion) {
        if (valores == null || valores.isEmpty()) {
            return String.join(",", CATEGORIAS);
        }
        List<String> limpias = new ArrayList<>();
        for (String valor : valores) {
            String categoria = valor == null ? "" : valor.trim().toUpperCase(Locale.ROOT);
            if (!CATEGORIAS.contains(categoria)) {
                throw badRequest("Categoría docente inválida: " + valor + ".");
            }
            if (!limpias.contains(categoria)) {
                limpias.add(categoria);
            }
        }
        limpias.sort((a, b) -> CATEGORIAS.indexOf(a) - CATEGORIAS.indexOf(b));
        if (limpias.isEmpty()) {
            throw badRequest("Indique al menos una categoría que pueda " + accion + ".");
        }
        return String.join(",", limpias);
    }

    private static ResponseStatusException badRequest(String mensaje) {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, mensaje);
    }
}
