package pe.unp.elecciones.electoral.controller;

import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/cargos-excluidos")
@PreAuthorize("hasAnyRole('ADMIN', 'CEUNP')")
public class CargoExcluidoController {

    private final JdbcTemplate jdbc;

    public CargoExcluidoController(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @GetMapping
    public List<Map<String, Object>> listar() {
        return jdbc.query("""
            SELECT ce.id_cargo_excluido AS id,
                   cc.id_catalogo_cargo AS idCatalogoCargo,
                   cc.nombre_cargo AS nombreCargo,
                   cc.nivel AS nivel,
                   (ce.activo = 1) AS activo
              FROM cargo_excluido_sorteo ce
              JOIN catalogo_cargo cc ON ce.id_catalogo_cargo = cc.id_catalogo_cargo
             ORDER BY FIELD(cc.nivel, 'UNIVERSIDAD', 'FACULTAD', 'DEPARTAMENTO'), cc.nombre_cargo
        """, (rs, rowNum) -> Map.of(
            "id", rs.getInt("id"),
            "idCatalogoCargo", rs.getInt("idCatalogoCargo"),
            "nombreCargo", rs.getString("nombreCargo"),
            "nivel", rs.getString("nivel"),
            "activo", rs.getBoolean("activo")
        ));
    }

    @PostMapping
    public Map<String, Object> crear(@RequestBody Map<String, Object> request) {
        String nombreCargo = (String) request.get("nombreCargo");
        String nivel = (String) request.get("nivel");
        Boolean activo = request.get("activo") != null ? (Boolean) request.get("activo") : true;

        if (nombreCargo == null || nombreCargo.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El nombre del cargo es requerido");
        }
        if (nivel == null || nivel.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El nivel es requerido");
        }
        nombreCargo = nombreCargo.trim();
        nivel = nivel.trim().toUpperCase();

        List<Integer> ids = jdbc.query("SELECT id_catalogo_cargo FROM catalogo_cargo WHERE LOWER(TRIM(nombre_cargo)) = LOWER(?)",
                (rs, rowNum) -> rs.getInt(1), nombreCargo);
        Integer idCatalogo;
        if (ids.isEmpty()) {
            jdbc.update("INSERT INTO catalogo_cargo (nombre_cargo, nivel, activo) VALUES (?, ?, ?)",
                    nombreCargo, nivel, activo ? 1 : 0);
            idCatalogo = jdbc.queryForObject("SELECT LAST_INSERT_ID()", Integer.class);
        } else {
            idCatalogo = ids.get(0);
        }

        jdbc.update("""
            INSERT INTO cargo_excluido_sorteo (id_catalogo_cargo, activo)
            VALUES (?, ?)
            ON DUPLICATE KEY UPDATE activo = VALUES(activo)
        """, idCatalogo, activo ? 1 : 0);

        Integer idExcluido = jdbc.queryForObject(
            "SELECT id_cargo_excluido FROM cargo_excluido_sorteo WHERE id_catalogo_cargo = ?",
            Integer.class, idCatalogo
        );

        return Map.of(
            "id", idExcluido,
            "idCatalogoCargo", idCatalogo,
            "nombreCargo", nombreCargo,
            "nivel", nivel,
            "activo", activo
        );
    }

    @PutMapping("/{id}")
    public Map<String, Object> actualizar(@PathVariable Integer id, @RequestBody Map<String, Object> request) {
        List<Map<String, Object>> rows = jdbc.queryForList(
            "SELECT ce.id_cargo_excluido, ce.id_catalogo_cargo, cc.nombre_cargo, cc.nivel, ce.activo " +
            "FROM cargo_excluido_sorteo ce JOIN catalogo_cargo cc ON ce.id_catalogo_cargo = cc.id_catalogo_cargo " +
            "WHERE ce.id_cargo_excluido = ?", id);

        if (rows.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Cargo excluido no encontrado");
        }

        Map<String, Object> current = rows.get(0);
        Integer idCatalogo = (Integer) current.get("id_catalogo_cargo");

        String nombreCargo = request.containsKey("nombreCargo") && request.get("nombreCargo") != null
            ? ((String) request.get("nombreCargo")).trim() : (String) current.get("nombre_cargo");
        String nivel = request.containsKey("nivel") && request.get("nivel") != null
            ? ((String) request.get("nivel")).trim().toUpperCase() : (String) current.get("nivel");
        Boolean activo = request.containsKey("activo") && request.get("activo") != null
            ? (Boolean) request.get("activo") : Boolean.TRUE.equals(current.get("activo"));

        jdbc.update("UPDATE catalogo_cargo SET nombre_cargo = ?, nivel = ? WHERE id_catalogo_cargo = ?",
            nombreCargo, nivel, idCatalogo);
        jdbc.update("UPDATE cargo_excluido_sorteo SET activo = ? WHERE id_cargo_excluido = ?",
            activo ? 1 : 0, id);

        return Map.of(
            "id", id,
            "idCatalogoCargo", idCatalogo,
            "nombreCargo", nombreCargo,
            "nivel", nivel,
            "activo", activo
        );
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void eliminar(@PathVariable Integer id) {
        jdbc.update("DELETE FROM cargo_excluido_sorteo WHERE id_cargo_excluido = ?", id);
    }
}

