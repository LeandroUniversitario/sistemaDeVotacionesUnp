package pe.unp.elecciones.electoral.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import pe.unp.elecciones.electoral.service.ImportacionDocenteService;

import java.util.Map;

@RestController
@RequestMapping("/api/docentes")
public class ImportacionDocenteController {

    private final ImportacionDocenteService importService;

    public ImportacionDocenteController(ImportacionDocenteService importService) {
        this.importService = importService;
    }

    @PostMapping("/importar")
    public ResponseEntity<?> importar(@RequestParam("archivo") MultipartFile archivo) {
        if (archivo.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "El archivo está vacío."));
        }
        String nombre = archivo.getOriginalFilename() != null ? archivo.getOriginalFilename().toLowerCase() : "";
        try {
            Map<String, Object> resultado;
            if (nombre.endsWith(".xlsx") || nombre.endsWith(".xls")) {
                resultado = importService.importarExcel(archivo);
            } else if (nombre.endsWith(".csv")) {
                resultado = importService.importarCsv(archivo);
            } else {
                return ResponseEntity.badRequest().body(Map.of("error", "Formato no soportado. Use .xlsx o .csv"));
            }
            return ResponseEntity.ok(resultado);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", "Error procesando archivo: " + e.getMessage()));
        }
    }

    @GetMapping("/plantilla-info")
    public ResponseEntity<?> plantillaInfo() {
        return ResponseEntity.ok(Map.of(
            "columnas", new String[]{"DNI", "Nombres", "Apellidos", "Categoría", "Dedicación", "Estado", "Facultad", "Departamento"},
            "categorias", new String[]{"PRINCIPAL", "ASOCIADO", "AUXILIAR"},
            "dedicaciones", new String[]{"DE", "TC", "TP"},
            "estados", new String[]{"ACTIVO", "LICENCIA", "SUSPENDIDO"}
        ));
    }
}
