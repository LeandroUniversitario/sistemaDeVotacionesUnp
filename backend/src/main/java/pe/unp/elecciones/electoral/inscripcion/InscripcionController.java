package pe.unp.elecciones.electoral.inscripcion;

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
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import pe.unp.elecciones.auth.UsuarioActual;
import pe.unp.elecciones.electoral.inscripcion.InscripcionDto.DatosCandidato;
import pe.unp.elecciones.electoral.inscripcion.InscripcionDto.DatosLista;

/**
 * CUS03 · Gestionar inscripción de listas (actor: Lista / Candidato, registrado por el CEUNP).
 *
 * Punto de entrada HTTP de la «PantallaInscripcion»:
 * <ul>
 *   <li>POST   /api/inscripcion/listas                         → RegistrarDatosLista.guardarLista  (1-4)</li>
 *   <li>GET    /api/inscripcion/listas/{id}/validar?dni=&rol=  → ValidarCandidato.comprobarRequisitos (5-8)</li>
 *   <li>POST   /api/inscripcion/listas/{id}/candidatos         → AgregarCandidato.grabarCandidato   (9-12)</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/inscripcion")
@PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
public class InscripcionController {

    private final InscripcionConsulta consulta;
    private final RegistrarDatosLista registrarDatosLista;
    private final ValidarCandidato validarCandidato;
    private final AgregarCandidato agregarCandidato;
    private final UsuarioActual usuarioActual;

    public InscripcionController(InscripcionConsulta consulta, RegistrarDatosLista registrarDatosLista,
            ValidarCandidato validarCandidato, AgregarCandidato agregarCandidato, UsuarioActual usuarioActual) {
        this.consulta = consulta;
        this.registrarDatosLista = registrarDatosLista;
        this.validarCandidato = validarCandidato;
        this.agregarCandidato = agregarCandidato;
        this.usuarioActual = usuarioActual;
    }

    // ─── Consultas ────────────────────────────────────────────────────────────

    @GetMapping("/procesos")
    public List<Map<String, Object>> procesos() {
        return consulta.procesos();
    }

    @GetMapping("/procesos/{idProceso}")
    public Map<String, Object> detalle(@PathVariable Integer idProceso) {
        return consulta.detalle(idProceso);
    }

    // ─── 1-4: Lista ───────────────────────────────────────────────────────────

    @PostMapping("/listas")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> guardarLista(@Valid @RequestBody DatosLista datos, Authentication authentication) {
        return registrarDatosLista.guardarLista(datos, usuarioActual.id(authentication));
    }

    @DeleteMapping("/listas/{idLista}")
    public Map<String, Object> retirarLista(@PathVariable Integer idLista, Authentication authentication) {
        return registrarDatosLista.retirarLista(idLista, usuarioActual.id(authentication));
    }

    // ─── 5-8: Buscar y validar candidato ─────────────────────────────────────

    @GetMapping("/listas/{idLista}/validar")
    public Map<String, Object> validar(@PathVariable Integer idLista,
            @RequestParam("dni") String dni, @RequestParam("rol") String rol) {
        return validarCandidato.comprobarRequisitos(idLista, dni, rol);
    }

    // ─── 9-12: Grabar candidato ──────────────────────────────────────────────

    @PostMapping("/listas/{idLista}/candidatos")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> grabarCandidato(@PathVariable Integer idLista,
            @Valid @RequestBody DatosCandidato datos, Authentication authentication) {
        return agregarCandidato.grabarCandidato(idLista, datos, usuarioActual.id(authentication));
    }

    @DeleteMapping("/candidatos/{idCandidato}")
    public Map<String, Object> quitarCandidato(@PathVariable Integer idCandidato, Authentication authentication) {
        return agregarCandidato.quitarCandidato(idCandidato, usuarioActual.id(authentication));
    }
}
