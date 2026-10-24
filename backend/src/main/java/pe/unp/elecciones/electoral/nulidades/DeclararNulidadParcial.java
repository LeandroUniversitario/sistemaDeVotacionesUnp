package pe.unp.elecciones.electoral.nulidades;

import java.sql.Types;
import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS15 · «DeclararNulidadParcial» (control). Mensajes 1 a 4 del diagrama de colaboración:
 *
 *   1 ingresarNulidadParcial(id_mesa, causal) → sp_registrar_nulidad('PARCIAL') (RF100, Art. 64)
 *   2 anularMesa(id_mesa, causal)             → sp_resolver_nulidad: FUNDADA anula la mesa y sus actas
 *   3 actualizarEstado('ANULADA')             → la mesa ANULADA no suma en v_computo_resultados (CUS14)
 *   4 mostrarMesaExcluida()                   → NulidadesConsulta.detalleMesa
 *
 * <p>La nulidad parcial se plantea con el proceso CERRADO y antes del cómputo (RN26). Mientras un
 * recurso esté pendiente, el cómputo queda bloqueado (RF94, trg_computo_bu_cus15).
 */
@Service
public class DeclararNulidadParcial {

    private static final Map<String, String> DECISION = Map.of(
            "FUNDADA", "fundado", "INFUNDADA", "infundado", "IMPROCEDENTE", "improcedente");

    private final ProcedimientoDao dao;
    private final NulidadesConsulta consulta;

    public DeclararNulidadParcial(ProcedimientoDao dao, NulidadesConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 1 ingresarNulidadParcial(id_mesa, causal): registra el recurso de oficio o del personero. */
    public Map<String, Object> registrar(Integer idProceso, NulidadesDto.RecursoParcial datos, Usuario usuario) {
        consulta.proceso(idProceso);
        String causal = datos.causal().trim().toUpperCase();
        if (!NulidadesConsulta.CAUSALES_PARCIAL.contains(causal)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Causal de nulidad parcial no válida (Art. 64).");
        }
        String origen = datos.origen().trim().toUpperCase();
        ProcedimientoDao.Resultado r = dao.llamar("sp_registrar_nulidad", new int[] {Types.INTEGER}, idProceso, usuario.getId(),
                "PARCIAL", datos.idMesa(), causal, origen, "PERSONERO".equals(origen) ? datos.idPersonero() : null,
                datos.sustento().trim(), NulidadesConsulta.vacioANulo(datos.pruebas()));
        Map<String, Object> respuesta = consulta.respuesta("Recurso de nulidad parcial N.º " + r.salidas()[0]
                + " registrado. El cómputo queda en espera hasta que el Pleno lo resuelva (RF94).", idProceso, usuario);
        respuesta.put("idNulidad", r.salidas()[0]);
        return respuesta;
    }

    /** 2-4 Resolución del Pleno: si es FUNDADA la mesa se anula y se excluye del cómputo. */
    public Map<String, Object> resolver(Map<String, Object> recurso, NulidadesDto.Resolucion datos, Usuario usuario) {
        Integer idNulidad = NulidadesConsulta.numero(recurso.get("idNulidad"));
        Integer idProceso = NulidadesConsulta.numero(recurso.get("idProceso"));
        Map<String, Object> fila = consulta.resolver(idNulidad, datos, usuario);
        String decision = NulidadesConsulta.texto(fila.get("decision"));
        String mesa = NulidadesConsulta.texto(recurso.get("numeroMesa"));
        String mensaje = "Resolución " + fila.get("numeroResolucion") + ": recurso declarado "
                + DECISION.getOrDefault(decision, decision.toLowerCase()) + ". "
                + ("FUNDADA".equals(decision)
                        ? "La mesa " + mesa + " y sus actas quedan anuladas y se excluyen del cómputo (Art. 64)."
                        : "La mesa " + mesa + " se mantiene en el cómputo.");
        Map<String, Object> respuesta = new LinkedHashMap<>(consulta.respuesta(mensaje, idProceso, usuario));
        respuesta.put("tokenQr", fila.get("tokenQr"));
        respuesta.put("idNulidad", idNulidad);
        respuesta.put("mesa", consulta.detalleMesa(NulidadesConsulta.numero(recurso.get("idMesa"))));
        return respuesta;
    }
}
