package pe.unp.elecciones.electoral.escrutinio;

import java.sql.Types;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS12 · «ConciliarVotos» (control). Mensajes 6 a 8 del diagrama de colaboración:
 *
 *   6 compararConDigital(conteo)   → sp_registrar_conteo
 *   7 contarVotosDigitales()       → Voto (votos de la mesa, sin vínculo con el elector)
 *   8 mostrarCuadre()              → la respuesta trae el cuadre por cargo y opción (RF82, RF83)
 *
 * <p>Registrar otra vez el conteo es el recuento del flujo A3. También registra las
 * impugnaciones de los personeros (paso 4 de la tabla 38), que se cuentan como impugnadas
 * hasta su resolución en el CUS13 (A4).
 */
@Service
public class ConciliarVotos {

    private final ProcedimientoDao dao;
    private final EscrutinioConsulta consulta;
    private final ObjectMapper json;

    public ConciliarVotos(ProcedimientoDao dao, EscrutinioConsulta consulta, ObjectMapper json) {
        this.dao = dao;
        this.consulta = consulta;
        this.json = json;
    }

    /** 5 ingresarConteoManual(conteo_listas) → 6 compararConDigital(conteo). */
    public Map<String, Object> compararConDigital(Integer idMesa, EscrutinioDto.ConteoManual datos, Usuario usuario) {
        consulta.mesa(idMesa);
        consulta.exigirCargo(idMesa, usuario, "Ingresar el conteo por lista", "SECRETARIO", "PRESIDENTE");
        List<Map<String, Object>> filas = datos.conteo().stream().map(o -> {
            Map<String, Object> fila = new LinkedHashMap<>();
            fila.put("id_cargo", o.idCargo());
            fila.put("opcion", o.opcion());
            fila.put("id_lista", "LISTA".equals(o.opcion()) ? o.idLista() : null);
            fila.put("votos", o.votos());
            return fila;
        }).toList();
        String conteo;
        try {
            conteo = json.writeValueAsString(filas);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException(e);
        }
        ProcedimientoDao.Resultado resultado =
                dao.llamar("sp_registrar_conteo", ProcedimientoDao.SIN_SALIDA, idMesa, usuario.getId(), conteo);
        Map<String, Object> cuadre = resultado.filas().isEmpty() ? Map.of() : resultado.filas().get(0);

        boolean coincide = EscrutinioConsulta.numero(cuadre.get("conteoCuadra")) == 1;
        boolean totalOk = EscrutinioConsulta.numero(cuadre.get("totalCuadra")) == 1;
        int veces = EscrutinioConsulta.numero(cuadre.get("vecesConteo"));
        String mensaje;
        if (coincide && totalOk) {
            mensaje = "El conteo manual coincide con el conteo digital y con los electores que votaron. Puede confirmar el escrutinio.";
        } else if (coincide) {
            mensaje = "El conteo coincide con el digital, pero el total de votos no es igual al de electores que votaron (RF82): registre la observación.";
        } else if (veces < 2) {
            mensaje = "A3: el conteo manual difiere del digital. Revise las diferencias, recuente las cédulas y registre otra vez el conteo.";
        } else {
            mensaje = "A3: tras el recuento la diferencia persiste. Si se confirma, prevalece la cédula física y se detalla en el acta (RF84).";
        }
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", mensaje);
        respuesta.put("cuadre", cuadre); // 8: mostrarCuadre()
        respuesta.put("detalle", consulta.detalle(idMesa));
        return respuesta;
    }

    /** Paso 4 de la tabla 38: un personero presente impugna un voto (RN24, RF80). */
    public Map<String, Object> registrarImpugnacion(Integer idMesa, EscrutinioDto.Impugnacion datos, Usuario usuario) {
        consulta.mesa(idMesa);
        consulta.exigirCargo(idMesa, usuario, "Registrar la impugnación", "PRESIDENTE", "SECRETARIO");
        ProcedimientoDao.Resultado resultado = dao.llamar("sp_registrar_impugnacion", new int[] { Types.BIGINT },
                idMesa, usuario.getId(), datos.idPersonero(), datos.idCargo(), datos.motivo().trim());

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Impugnación N.º " + resultado.salidas()[0] + " registrada: aparte la cédula y cuéntela como impugnada (A4). "
                + "La resuelve la mesa por mayoría y, si se apela, el CEUNP (CUS13).");
        respuesta.put("idImpugnacion", resultado.salidas()[0]);
        respuesta.put("detalle", consulta.detalle(idMesa));
        return respuesta;
    }
}
