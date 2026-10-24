package pe.unp.elecciones.electoral.escrutinio;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import org.springframework.stereotype.Service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS12 · «GenerarActaEscrutinio» (control). Mensajes 10 a 13 del diagrama de colaboración:
 *
 *   10 crearActa(resultados)          → sp_generar_acta_escrutinio
 *   11 insertarActa(hash, contenido)  → ActaElectoral (tipo ESCRUTINIO, huella SHA-256, RF85)
 *   12 registrarFirmas(firmas)        → FirmaActa (miembros en funciones y personeros)
 *   13 mostrarActaGenerada()          → la respuesta trae el acta y el token del QR
 *
 * <p>Después, el paso 9 de la tabla 38: tres ejemplares y entrega al CEUNP (RF86, RF87).
 */
@Service
public class GenerarActaEscrutinio {

    private final ProcedimientoDao dao;
    private final EscrutinioConsulta consulta;
    private final ObjectMapper json;

    public GenerarActaEscrutinio(ProcedimientoDao dao, EscrutinioConsulta consulta, ObjectMapper json) {
        this.dao = dao;
        this.consulta = consulta;
        this.json = json;
    }

    /** 9 confirmarEscrutinio() → 10 crearActa(resultados). El token del QR solo se devuelve aquí. */
    public Map<String, Object> crearActa(Integer idMesa, EscrutinioDto.ConfirmarEscrutinio datos, Usuario usuario) {
        consulta.mesa(idMesa);
        consulta.exigirCargo(idMesa, usuario, "Confirmar el escrutinio", "PRESIDENTE");
        String personeros;
        try {
            personeros = json.writeValueAsString(datos.personeros() == null ? List.of()
                    : datos.personeros().stream().filter(Objects::nonNull).distinct().toList());
        } catch (JsonProcessingException e) {
            throw new IllegalStateException(e);
        }
        String observaciones = datos.observaciones() == null || datos.observaciones().isBlank()
                ? null : datos.observaciones().trim();
        ProcedimientoDao.Resultado resultado = dao.llamar("sp_generar_acta_escrutinio", ProcedimientoDao.SIN_SALIDA,
                idMesa, usuario.getId(), Boolean.TRUE.equals(datos.prevaleceFisica()), observaciones, personeros);
        Map<String, Object> fila = resultado.filas().isEmpty() ? Map.of() : resultado.filas().get(0);
        boolean observada = EscrutinioConsulta.numero(fila.get("observada")) == 1;

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Se emitió y firmó el Acta de Escrutinio" + (observada ? " (OBSERVADA, A5)" : "")
                + ". Imprima los tres ejemplares y entréguelos al CEUNP.");
        respuesta.put("idActa", fila.get("idActa"));
        respuesta.put("tokenQr", fila.get("tokenQr"));
        respuesta.put("detalle", consulta.detalle(idMesa)); // 13: mostrarActaGenerada()
        return respuesta;
    }

    /** Paso 9 de la tabla 38: entrega de los tres ejemplares, el padrón y el material al CEUNP (RF86, RF87). */
    public Map<String, Object> registrarEntrega(Integer idMesa, EscrutinioDto.Entrega datos, Usuario usuario) {
        consulta.mesa(idMesa);
        consulta.exigirCargo(idMesa, usuario, "Registrar la entrega de las actas", "PRESIDENTE");
        String observacion = datos.observacion() == null || datos.observacion().isBlank() ? null : datos.observacion().trim();
        ProcedimientoDao.Resultado resultado = dao.llamar("sp_registrar_entrega_actas", ProcedimientoDao.SIN_SALIDA,
                idMesa, usuario.getId(), datos.recibidoPor().trim(), datos.ejemplares(), datos.copiasPersoneros(),
                Boolean.TRUE.equals(datos.entregaPadron()), Boolean.TRUE.equals(datos.entregaMaterial()), observacion);
        Map<String, Object> fila = resultado.filas().isEmpty() ? Map.of() : resultado.filas().get(0);

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Entrega registrada. Cargo de entrega N.º " + fila.get("codigoCargo")
                + ": el escrutinio de la mesa terminó.");
        respuesta.put("codigoCargo", fila.get("codigoCargo"));
        respuesta.put("detalle", consulta.detalle(idMesa));
        return respuesta;
    }
}
