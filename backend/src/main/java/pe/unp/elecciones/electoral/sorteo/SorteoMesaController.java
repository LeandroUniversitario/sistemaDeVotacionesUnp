package pe.unp.elecciones.electoral.sorteo;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.UsuarioActual;
import pe.unp.elecciones.electoral.sorteo.SorteoDto.DatosMesas;
import pe.unp.elecciones.electoral.sorteo.SorteoDto.DatosSemilla;

/**
 * CUS06 · Realizar sorteos (actor: CEUNP) — «PantallaSorteoMesa».
 *
 * <ul>
 *   <li>GET  /api/sorteo-mesas/procesos/{id}/elegibles      → FiltrarElegibles.obtenerUniverso       (1-5)</li>
 *   <li>POST /api/sorteo-mesas/procesos/{id}/vista-previa   → EjecutarSorteo (sin grabar)            (6-7)</li>
 *   <li>POST /api/sorteo-mesas/procesos/{id}/sortear        → EjecutarSorteo → GrabarMiembrosMesa    (6-12)</li>
 *   <li>POST /api/sorteo-mesas/procesos/{id}/mesas          → conformar mesas (requisito previo)</li>
 *   <li>POST /api/sorteo-mesas/cargos/{id}/orden-cedula     → sorteo del orden en la cédula (RN18)</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/sorteo-mesas")
@PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
public class SorteoMesaController {

    private final SorteoConsulta consulta;
    private final FiltrarElegibles filtrarElegibles;
    private final EjecutarSorteo ejecutarSorteo;
    private final GrabarMiembrosMesa grabarMiembrosMesa;
    private final PreparacionSorteo preparacion;
    private final UsuarioActual usuarioActual;

    public SorteoMesaController(SorteoConsulta consulta, FiltrarElegibles filtrarElegibles,
            EjecutarSorteo ejecutarSorteo, GrabarMiembrosMesa grabarMiembrosMesa,
            PreparacionSorteo preparacion, UsuarioActual usuarioActual) {
        this.consulta = consulta;
        this.filtrarElegibles = filtrarElegibles;
        this.ejecutarSorteo = ejecutarSorteo;
        this.grabarMiembrosMesa = grabarMiembrosMesa;
        this.preparacion = preparacion;
        this.usuarioActual = usuarioActual;
    }

    @GetMapping("/procesos")
    public List<Map<String, Object>> procesos() {
        return consulta.procesos();
    }

    @GetMapping("/procesos/{idProceso}")
    public Map<String, Object> detalle(@PathVariable Integer idProceso) {
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("proceso", consulta.proceso(idProceso));
        r.put("parametros", consulta.parametros());
        r.put("mesas", consulta.mesas(idProceso));
        r.put("miembros", consulta.miembros(idProceso));
        List<Map<String, Object>> cedula = consulta.cedula(idProceso);
        for (Map<String, Object> cargo : cedula) {
            // M2: el compromiso del sorteo de la cédula se publica antes de sortear
            if (!Boolean.TRUE.equals(cargo.get("sorteado")) && !((List<?>) cargo.get("listas")).isEmpty()) {
                cargo.put("compromiso", ejecutarSorteo.compromiso("CEDULA:" + cargo.get("id")));
            }
        }
        r.put("cedula", cedula);
        return r;
    }

    @PreAuthorize("hasRole('CEUNP')") // ADMIN solo consulta (actor del CUS: CEUNP)
    @PostMapping("/procesos/{idProceso}/mesas")
    public Map<String, Object> conformarMesas(@PathVariable Integer idProceso,
            @Valid @RequestBody DatosMesas datos, Authentication authentication) {
        return preparacion.conformarMesas(idProceso, datos.electoresPorMesa(), datos.ubicacion(),
                usuarioActual.id(authentication));
    }

    // ─── 1-5: solicitarSorteo(id_proceso) ────────────────────────────────────

    @GetMapping("/procesos/{idProceso}/elegibles")
    public Map<String, Object> elegibles(@PathVariable Integer idProceso) {
        return filtrarElegibles.obtenerUniverso(idProceso);
    }

    // ─── 6-12: ingresarSemilla(semilla) ──────────────────────────────────────

    /**
     * Vista previa: mesas pendientes y elegibles de cada una, sin miembros. Los miembros no se pueden
     * calcular antes de sortear porque la semilla incluye el secreto del servidor (M2, commit-reveal);
     * aquí solo se publica su compromiso SHA-256.
     */
    @PreAuthorize("hasRole('CEUNP')") // ADMIN solo consulta (actor del CUS: CEUNP)
    @PostMapping("/procesos/{idProceso}/vista-previa")
    public Map<String, Object> vistaPrevia(@PathVariable Integer idProceso, @Valid @RequestBody DatosSemilla datos) {
        exigirSorteable(idProceso);
        List<Map<String, Object>> mesas = ejecutarSorteo.sortearMesasPendientes(idProceso, "previa");
        mesas.forEach(m -> {
            m.remove("semillaMesa");
            m.put("miembros", List.of());
        });
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("compromiso", ejecutarSorteo.compromiso("MESAS:" + idProceso));
        r.put("mesas", mesas);
        return r;
    }

    @PreAuthorize("hasRole('CEUNP')") // ADMIN solo consulta (actor del CUS: CEUNP)
    @PostMapping("/procesos/{idProceso}/sortear")
    public Map<String, Object> sortear(@PathVariable Integer idProceso, @Valid @RequestBody DatosSemilla datos,
            Authentication authentication) {
        exigirSorteable(idProceso);
        List<Map<String, Object>> pendientes = ejecutarSorteo.sortearMesasPendientes(idProceso, "control");
        if (pendientes.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "RN19: todas las mesas ya fueron sorteadas; el cargo de miembro de mesa es irrenunciable.");
        }
        for (Map<String, Object> mesa : pendientes) {
            if (!Boolean.TRUE.equals(mesa.get("suficientes"))) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "RN19: la mesa " + mesa.get("numeroMesa")
                        + " solo tiene " + mesa.get("elegibles") + " docentes elegibles; se necesitan 6.");
            }
        }
        EjecutarSorteo.Semilla semilla = ejecutarSorteo.semillaDefinitiva("MESAS:" + idProceso, datos.semilla()); // 7
        List<Map<String, Object>> sorteados = ejecutarSorteo.sortearMesasPendientes(idProceso, semilla.semilla());
        Map<String, Object> r = new LinkedHashMap<>(grabarMiembrosMesa.guardarResultados(idProceso, semilla.semilla(),
                sorteados, usuarioActual.id(authentication)));                                          // 8
        r.put("secretoServidor", semilla.secretoServidor());
        r.put("aporteOperador", semilla.aporteOperador());
        r.put("compromiso", semilla.compromiso());
        return r;
    }

    @PreAuthorize("hasRole('CEUNP')") // ADMIN solo consulta (actor del CUS: CEUNP)
    @PostMapping("/cargos/{idCargo}/orden-cedula")
    public Map<String, Object> ordenCedula(@PathVariable Integer idCargo, @Valid @RequestBody DatosSemilla datos,
            Authentication authentication) {
        return preparacion.sortearCedula(idCargo, datos.semilla(), usuarioActual.id(authentication));
    }

    private void exigirSorteable(Integer idProceso) {
        Map<String, Object> proceso = consulta.proceso(idProceso);
        if (!Boolean.TRUE.equals(proceso.get("admiteSorteo"))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "El sorteo de mesas se realiza antes de la votación (proceso en " + proceso.get("estado") + ").");
        }
        if (consulta.mesas(idProceso).isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Primero conforme las mesas de sufragio.");
        }
    }
}
