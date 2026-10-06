package pe.unp.elecciones.electoral.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import pe.unp.elecciones.electoral.dto.VotoRequest;
import pe.unp.elecciones.electoral.service.VotoService;

import java.util.Map;

@RestController
@RequestMapping("/api/votos")
public class VotoController {

    private final VotoService votoService;

    public VotoController(VotoService votoService) {
        this.votoService = votoService;
    }

    @PostMapping
    public ResponseEntity<?> emitirVoto(@RequestBody VotoRequest request) {
        try {
            votoService.registrarVoto(request);
            return ResponseEntity.ok(Map.of("mensaje", "Voto registrado exitosamente"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}
