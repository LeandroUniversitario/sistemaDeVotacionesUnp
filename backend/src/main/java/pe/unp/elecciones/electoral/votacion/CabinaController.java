package pe.unp.elecciones.electoral.votacion;

import java.util.Map;

import jakarta.validation.Valid;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import pe.unp.elecciones.electoral.votacion.VotacionDto.Voto;

/**
 * CUS10 · «TerminalVotacion»: lo que hace el equipo de la cabina (actor: docente elector, que NO
 * inicia sesión).
 *
 * <p>La cabina no usa la sesión de ninguna persona: se identifica con el secreto de dispositivo que
 * recibió al conectarla un miembro de la mesa (cabecera X-Terminal-Secreto). Solo con ese secreto se
 * entrega la habilitación de un solo uso y se acepta el voto (auditoría C2 y M1).
 *
 * <ul>
 *   <li>GET  /api/cabina/terminales/{id}         → LIBRE | HABILITADO (token y cédula) | EN_USO | FUERA_DE_SERVICIO</li>
 *   <li>POST /api/cabina/terminales/{id}/voto    → 9 registrarVoto(opción) → cédula para imprimir</li>
 *   <li>POST /api/cabina/terminales/{id}/liberar → 13 liberarTerminal() tras confirmarImpresion()</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/cabina/terminales")
public class CabinaController {

    static final String CABECERA = "X-Terminal-Secreto";

    private final RegistrarVoto registrarVoto;

    public CabinaController(RegistrarVoto registrarVoto) {
        this.registrarVoto = registrarVoto;
    }

    @GetMapping("/{idTerminal}")
    public Map<String, Object> estado(@PathVariable Integer idTerminal,
            @RequestHeader(name = CABECERA, required = false) String secreto) {
        registrarVoto.exigirSecreto(idTerminal, secreto);
        return registrarVoto.estado(idTerminal, true);
    }

    @PostMapping("/{idTerminal}/voto")
    public Map<String, Object> votar(@PathVariable Integer idTerminal, @Valid @RequestBody Voto voto,
            @RequestHeader(name = CABECERA, required = false) String secreto) {
        registrarVoto.exigirSecreto(idTerminal, secreto);
        return registrarVoto.registrarVoto(idTerminal, voto.idHabilitacion(), voto.token(), voto.votos());
    }

    @PostMapping("/{idTerminal}/liberar")
    public Map<String, Object> liberar(@PathVariable Integer idTerminal,
            @RequestHeader(name = CABECERA, required = false) String secreto) {
        registrarVoto.exigirSecreto(idTerminal, secreto);
        return registrarVoto.liberarTerminal(idTerminal);
    }
}
