package pe.unp.elecciones.electoral.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import pe.unp.elecciones.electoral.domain.MesaSufragio;
import pe.unp.elecciones.electoral.service.MesaService;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/mesas")
public class MesaController {

    private final MesaService mesaService;

    public MesaController(MesaService mesaService) {
        this.mesaService = mesaService;
    }

    @GetMapping
    public List<MesaSufragio> listarMesas() {
        return mesaService.listarMesas();
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> obtenerMesa(@PathVariable Integer id) {
        try {
            MesaSufragio mesa = mesaService.obtenerMesa(id);
            return ResponseEntity.ok(mesa);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}
