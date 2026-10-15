package pe.unp.elecciones.electoral.personeros;

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
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import pe.unp.elecciones.auth.UsuarioActual;
import pe.unp.elecciones.electoral.personeros.PersonerosDto.DatosAcreditacion;
import pe.unp.elecciones.electoral.personeros.PersonerosDto.DatosRevocacion;

/**
 * CUS05 · Acreditar personeros (actor: CEUNP).
 *
 * <ul>
 *   <li>GET  /api/personeros/listas/{id}/validar?dni=   → ValidarPersonero.verificarRequisitos   (1-4)</li>
 *   <li>POST /api/personeros/listas/{id}                → AcreditarPersonero.guardarAcreditacion (5-8)</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/personeros")
@PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
public class PersonerosController {

    private final PersonerosConsulta consulta;
    private final ValidarPersonero validarPersonero;
    private final AcreditarPersonero acreditarPersonero;
    private final UsuarioActual usuarioActual;

    public PersonerosController(PersonerosConsulta consulta, ValidarPersonero validarPersonero,
            AcreditarPersonero acreditarPersonero, UsuarioActual usuarioActual) {
        this.consulta = consulta;
        this.validarPersonero = validarPersonero;
        this.acreditarPersonero = acreditarPersonero;
        this.usuarioActual = usuarioActual;
    }

    @GetMapping("/procesos")
    public List<Map<String, Object>> procesos() {
        return consulta.procesos();
    }

    @GetMapping("/procesos/{idProceso}")
    public Map<String, Object> detalle(@PathVariable Integer idProceso) {
        return consulta.detalle(idProceso);
    }

    // ─── 1-4: solicitarAcreditacion(id_lista, dni) ───────────────────────────

    @GetMapping("/listas/{idLista}/validar")
    public Map<String, Object> validar(@PathVariable Integer idLista, @RequestParam("dni") String dni) {
        return validarPersonero.verificarRequisitos(idLista, dni);
    }

    // ─── 5-8: confirmarAcreditacion(tipo, id_mesa) ───────────────────────────

    @PostMapping("/listas/{idLista}")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> acreditar(@PathVariable Integer idLista,
            @Valid @RequestBody DatosAcreditacion datos, Authentication authentication) {
        return acreditarPersonero.guardarAcreditacion(idLista, datos, usuarioActual.id(authentication));
    }

    @PostMapping("/{idPersonero}/revocar")
    public Map<String, Object> revocar(@PathVariable Integer idPersonero,
            @Valid @RequestBody DatosRevocacion datos, Authentication authentication) {
        return acreditarPersonero.revocar(idPersonero, datos.motivo(), usuarioActual.id(authentication));
    }
}
