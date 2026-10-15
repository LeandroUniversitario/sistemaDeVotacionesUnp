package pe.unp.elecciones.electoral.convocatoria;

import java.util.List;
import java.util.Map;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import pe.unp.elecciones.auth.UsuarioActual;
import pe.unp.elecciones.electoral.convocatoria.ConvocatoriaDto.DatosCargo;
import pe.unp.elecciones.electoral.convocatoria.ConvocatoriaDto.DatosProceso;

/**
 * CUS01 · Gestionar convocatoria y cronograma (actor: CEUNP).
 *
 * Punto de entrada HTTP de la «PantallaConvocatoria». Cada endpoint delega en el
 * control del diagrama de colaboración que le corresponde:
 *
 * <ul>
 *   <li>POST   /api/convocatorias                       → RegistrarProceso.guardarProceso</li>
 *   <li>PUT    /api/convocatorias/{id}/cronograma       → RegistrarProceso.actualizarCronograma</li>
 *   <li>POST   /api/convocatorias/{id}/cargos           → AgregarCargo.guardarCargo</li>
 *   <li>DELETE /api/convocatorias/{id}/cargos/{idCargo} → AgregarCargo.quitarCargo</li>
 *   <li>POST   /api/convocatorias/{id}/publicar         → PublicarConvocatoria.cambiarEstado</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/convocatorias")
@PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
public class ConvocatoriaController {

    private final ConvocatoriaConsulta consulta;
    private final RegistrarProceso registrarProceso;
    private final AgregarCargo agregarCargo;
    private final PublicarConvocatoria publicarConvocatoria;
    private final UsuarioActual usuarioActual;

    public ConvocatoriaController(ConvocatoriaConsulta consulta, RegistrarProceso registrarProceso,
            AgregarCargo agregarCargo, PublicarConvocatoria publicarConvocatoria, UsuarioActual usuarioActual) {
        this.consulta = consulta;
        this.registrarProceso = registrarProceso;
        this.agregarCargo = agregarCargo;
        this.publicarConvocatoria = publicarConvocatoria;
        this.usuarioActual = usuarioActual;
    }

    // ─── Consultas ────────────────────────────────────────────────────────────

    @GetMapping
    public List<Map<String, Object>> listar() {
        return consulta.listar();
    }

    @GetMapping("/catalogos")
    public Map<String, Object> catalogos() {
        return consulta.catalogos();
    }

    @GetMapping("/{idProceso}")
    public Map<String, Object> detalle(@PathVariable Integer idProceso) {
        return consulta.detalle(idProceso);
    }

    // ─── 1-4: Registrar proceso y cronograma ─────────────────────────────────

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> registrar(@Valid @RequestBody DatosProceso datos, Authentication authentication) {
        return registrarProceso.guardarProceso(datos, usuarioActual.id(authentication));
    }

    @PutMapping("/{idProceso}/cronograma")
    public Map<String, Object> actualizarCronograma(
            @PathVariable Integer idProceso,
            @Valid @RequestBody DatosProceso datos,
            Authentication authentication) {
        return registrarProceso.actualizarCronograma(idProceso, datos, usuarioActual.id(authentication));
    }

    // ─── 5-8: Cargos electorales ──────────────────────────────────────────────

    @PostMapping("/{idProceso}/cargos")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> agregarCargo(
            @PathVariable Integer idProceso,
            @Valid @RequestBody DatosCargo datos,
            Authentication authentication) {
        return agregarCargo.guardarCargo(idProceso, datos, usuarioActual.id(authentication));
    }

    @DeleteMapping("/{idProceso}/cargos/{idCargo}")
    public Map<String, Object> quitarCargo(
            @PathVariable Integer idProceso,
            @PathVariable Integer idCargo,
            Authentication authentication) {
        return agregarCargo.quitarCargo(idProceso, idCargo, usuarioActual.id(authentication));
    }

    // ─── 9-12: Publicar convocatoria ─────────────────────────────────────────

    @PostMapping("/{idProceso}/publicar")
    public Map<String, Object> publicar(@PathVariable Integer idProceso, Authentication authentication) {
        return publicarConvocatoria.cambiarEstado(idProceso, PublicarConvocatoria.ESTADO_PUBLICADA,
                usuarioActual.id(authentication));
    }
}
