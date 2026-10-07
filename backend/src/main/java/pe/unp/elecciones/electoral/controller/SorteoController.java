package pe.unp.elecciones.electoral.controller;

import java.util.List;
import java.util.Map;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import pe.unp.elecciones.auth.UsuarioActual;
import pe.unp.elecciones.electoral.service.SorteoService;

@RestController
@RequestMapping("/api/sorteos")
@PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
public class SorteoController {

    private final SorteoService sorteoService;
    private final UsuarioActual usuarioActual;

    public SorteoController(SorteoService sorteoService, UsuarioActual usuarioActual) {
        this.sorteoService = sorteoService;
        this.usuarioActual = usuarioActual;
    }

    /** Genera padrón y mesas si faltan y sortea los miembros de mesa. */
    @PostMapping("/generar-mesas")
    public Map<String, Object> generarMesasYMiembros(
            @RequestParam Integer procesoId,
            @RequestParam(required = false) Integer electoresPorMesa,
            @RequestParam(required = false) String ubicacion,
            @RequestParam(required = false) String semilla,
            Authentication authentication) {
        return sorteoService.generarMesasYMiembros(procesoId, electoresPorMesa, ubicacion, semilla,
                usuarioActual.id(authentication));
    }

    /** RN18: sorteo del orden de las listas en la cédula. */
    @PostMapping("/orden-cedula")
    public Map<String, Object> sortearOrdenCedula(
            @RequestParam Integer cargoId,
            @RequestParam(required = false) String semilla,
            Authentication authentication) {
        return sorteoService.sortearOrdenCedula(cargoId, semilla, usuarioActual.id(authentication));
    }

    /** Docentes que pueden entrar al sorteo (sin autoridades, candidatos ni personeros). */
    @GetMapping("/elegibles")
    public List<Map<String, Object>> elegibles(@RequestParam Integer procesoId) {
        return sorteoService.elegibles(procesoId);
    }
}
