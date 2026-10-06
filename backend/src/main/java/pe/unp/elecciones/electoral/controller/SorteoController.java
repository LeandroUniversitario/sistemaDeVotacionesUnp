package pe.unp.elecciones.electoral.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;
import java.time.LocalDateTime;

@RestController
@RequestMapping("/api/sorteos")
public class SorteoController {

    @PostMapping("/generar-mesas")
    public ResponseEntity<?> generarMesasYMiembros(@RequestParam Long procesoId) {
        // En una implementación real, este método:
        // 1. Obtiene el padrón de docentes habilitados.
        // 2. Los divide en grupos (ej. 200 por mesa).
        // 3. Crea las entidades MesaSufragio.
        // 4. Selecciona aleatoriamente (con semilla) 6 docentes (3 titulares, 3 suplentes) sin parentesco ni incompatibilidades.
        // 5. Los registra como MiembroMesa.
        
        // Simulación de respuesta exitosa para el frontend
        return ResponseEntity.ok(Map.of(
            "mensaje", "Sorteo realizado con éxito. Se generaron 15 mesas.",
            "fechaSorteo", LocalDateTime.now(),
            "semilla", "8f93a1c2b5d4e6"
        ));
    }
}
