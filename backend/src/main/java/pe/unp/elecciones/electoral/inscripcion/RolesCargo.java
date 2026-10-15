package pe.unp.elecciones.electoral.inscripcion;

import java.text.Normalizer;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * CUS03 · Roles que debe cubrir la lista (fórmula) de cada cargo.
 *
 * RN10: para Rector la lista es una fórmula de tres: Rector, Vicerrector Académico y
 * Vicerrector de Investigación. Los demás cargos se inscriben con un solo titular.
 * También define los requisitos de RN09 (grado y antigüedad en la categoría) que
 * ValidarCandidato comprueba para cada rol.
 */
public final class RolesCargo {

    private RolesCargo() {
    }

    /** Requisitos académicos de un rol (Ley 30220, art. 61, 65 y 69). */
    public record Rol(String codigo, String etiqueta, List<String> gradosRequeridos, int aniosCategoria) {
    }

    private static final Rol RECTOR = new Rol("RECTOR", "Rector", List.of("DOCTOR"), 5);
    private static final Rol VR_ACADEMICO =
            new Rol("VICERRECTOR_ACADEMICO", "Vicerrector Académico", List.of("DOCTOR"), 5);
    private static final Rol VR_INVESTIGACION =
            new Rol("VICERRECTOR_INVESTIGACION", "Vicerrector de Investigación", List.of("DOCTOR"), 5);
    private static final Rol DECANO = new Rol("DECANO", "Decano", List.of("DOCTOR", "MAESTRO"), 3);

    /** Roles de la fórmula según el nombre del cargo electoral. */
    public static List<Rol> roles(String nombreCargo) {
        String n = normalizar(nombreCargo);
        if (n.contains("vicerrector") && n.contains("investigacion")) {
            return List.of(VR_INVESTIGACION);
        }
        if (n.contains("vicerrector")) {
            return List.of(VR_ACADEMICO);
        }
        if (n.contains("decano")) {
            return List.of(DECANO);
        }
        if (n.contains("jefe") && n.contains("departamento")) {
            return List.of(new Rol("JEFE_DEPARTAMENTO", "Jefe de Departamento", List.of(), 0));
        }
        if (n.contains("posgrado")) {
            return List.of(new Rol("DIRECTOR_POSGRADO", "Director de Posgrado", List.of("DOCTOR"), 0));
        }
        if (n.contains("director") && n.contains("escuela")) {
            return List.of(new Rol("DIRECTOR_ESCUELA", "Director de Escuela", List.of(), 0));
        }
        if (n.matches(".*\\brector\\b.*")) {   // palabra completa: «Director» no es «Rector»
            return List.of(RECTOR, VR_ACADEMICO, VR_INVESTIGACION);
        }
        return List.of(new Rol("TITULAR", nombreCargo == null ? "Titular" : nombreCargo, List.of(), 0));
    }

    public static Rol buscar(String nombreCargo, String codigoRol) {
        String codigo = codigoRol == null ? "" : codigoRol.trim().toUpperCase(Locale.ROOT);
        return roles(nombreCargo).stream().filter(r -> r.codigo().equals(codigo)).findFirst().orElse(null);
    }

    /** Forma serializable para la pantalla. */
    public static List<Map<String, Object>> comoMapa(String nombreCargo) {
        return roles(nombreCargo).stream().map(r -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("codigo", r.codigo());
            m.put("etiqueta", r.etiqueta());
            return m;
        }).toList();
    }

    private static String normalizar(String texto) {
        if (texto == null) {
            return "";
        }
        return Normalizer.normalize(texto, Normalizer.Form.NFD)
                .replaceAll("\\p{InCombiningDiacriticalMarks}+", "")
                .toLowerCase(Locale.ROOT);
    }
}
