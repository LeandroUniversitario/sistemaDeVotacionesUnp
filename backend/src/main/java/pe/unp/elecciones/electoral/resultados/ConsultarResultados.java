package pe.unp.elecciones.electoral.resultados;

import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;

import pe.unp.elecciones.auth.Usuario;

/**
 * CUS17 · «consultarResultados» (control). Mensajes 1 a 6 del diagrama de colaboración:
 *
 *   1 seleccionarProceso()        → procesos con resultados que se pueden consultar (v_resultados_procesos)
 *   2 obtenerResultados()         → obtenerResultados(idProceso)
 *   3 verificarComputoCerrado()   → fn_resultados_disponibles: cómputo PUBLICADO (RF99) o cómputo heredado (RN26)
 *   4 consultarResultados()       → resultado_electoral, proclamacion_cargo y v_resultados_mesa
 *   5 devolverResultados()        → resultados generales, por cargo y por mesa, y documentos verificables
 *   6 mostrarResultados()         → PantallaResultados
 *
 * <p>Lo usan el docente, el personero, los miembros de mesa, el CEUNP y el ADMIN con sesión, y el
 * portal público sin sesión (sin los cotejos).
 */
@Service
public class ConsultarResultados {

    private final ResultadosConsulta consulta;

    public ConsultarResultados(ResultadosConsulta consulta) {
        this.consulta = consulta;
    }

    /** 1 seleccionarProceso(). */
    public List<Map<String, Object>> procesos() {
        return consulta.procesos();
    }

    /** 2 obtenerResultados() → 3 verificarComputoCerrado() → 4 consultarResultados() → 5 devolverResultados(). */
    public Map<String, Object> obtenerResultados(Integer idProceso, Usuario usuario) {
        return consulta.detalle(idProceso, usuario);
    }
}
