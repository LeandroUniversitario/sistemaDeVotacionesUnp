package pe.unp.elecciones.electoral.inscripcion;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS03 · Control «ValidarCandidato» del diagrama de colaboración.
 *
 * <pre>
 *  PantallaInscripcion --6: comprobarRequisitos(dni)--> ValidarCandidato
 *  ValidarCandidato    --7: consultarDocente(dni)--> docente
 *  ValidarCandidato    --8: mostrarDatosCandidato(docente)--> PantallaInscripcion
 * </pre>
 *
 * Cada requisito se informa como OK, FALLA (impide la inscripción) o ADVERTENCIA
 * (dato no registrado: el CEUNP lo verifica al calificar la lista, RN09).
 * Las reglas FALLA coinciden con las que vuelven a aplicar sp_inscribir_candidato
 * y el trigger trg_candidato_bi, así la pantalla avisa antes de intentar grabar.
 */
@Service
public class ValidarCandidato {

    static final String OK = "OK";
    static final String FALLA = "FALLA";
    static final String ADVERTENCIA = "ADVERTENCIA";

    private final ProcedimientoDao dao;
    private final InscripcionConsulta consulta;

    public ValidarCandidato(ProcedimientoDao dao, InscripcionConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 6: comprobarRequisitos(dni) — para el rol indicado dentro de la lista. */
    public Map<String, Object> comprobarRequisitos(Integer idLista, String dni, String codigoRol) {
        Map<String, Object> docente = consultarDocente(dni);
        return evaluar(idLista, docente, codigoRol);
    }

    /** Mismo análisis partiendo del id del docente (lo usa AgregarCandidato antes de grabar). */
    public Map<String, Object> comprobarRequisitos(Integer idLista, Integer idDocente, String codigoRol) {
        List<Map<String, Object>> filas = dao.consultar(SELECT_DOCENTE + " WHERE d.id_docente = ?", idDocente);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El docente no existe.");
        }
        return evaluar(idLista, filas.get(0), codigoRol);
    }

    private static final String SELECT_DOCENTE = """
            SELECT d.id_docente AS id, d.dni, d.nombres, d.apellidos, d.categoria, d.dedicacion, d.estado,
                   d.habilitado_para_votar AS habilitado, d.grado_academico, d.fecha_categoria,
                   d.id_facultad, d.id_departamento, f.nombre AS facultad, dp.nombre AS departamento
              FROM docente d
              JOIN facultad f ON f.id_facultad = d.id_facultad
              JOIN departamento dp ON dp.id_departamento = d.id_departamento
            """;

    /** 7: consultarDocente(dni) */
    private Map<String, Object> consultarDocente(String dni) {
        String limpio = dni == null ? "" : dni.trim();
        if (!limpio.matches("\\d{1,8}")) {
            throw InscripcionConsulta.badRequest("RN05: ingrese un DNI válido (8 dígitos).");
        }
        String ocho = String.format("%08d", Long.parseLong(limpio));
        List<Map<String, Object>> filas = dao.consultar(SELECT_DOCENTE + " WHERE d.dni = ?", ocho);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                    "No hay ningún docente registrado con DNI " + ocho + ".");
        }
        return filas.get(0);
    }

    private Map<String, Object> evaluar(Integer idLista, Map<String, Object> docente, String codigoRol) {
        Map<String, Object> lista = consulta.lista(idLista);
        String nombreCargo = (String) lista.get("cargo");
        Integer idCargo = ((Number) lista.get("idCargo")).intValue();
        Integer idProceso = ((Number) lista.get("idProceso")).intValue();
        Integer idDocente = ((Number) docente.get("id")).intValue();
        RolesCargo.Rol rol = RolesCargo.buscar(nombreCargo, codigoRol);

        List<Map<String, Object>> requisitos = new ArrayList<>();

        // Lista abierta (RN12 / RN13)
        boolean listaAbierta = "INSCRIPCION".equals(lista.get("estadoProceso"))
                && !InscripcionConsulta.plazoVencido(lista.get("fechaLimiteInscripcion"))
                && "INSCRITA".equals(lista.get("estado"));
        requisitos.add(req("LISTA", "RN12/RN13: la lista admite candidatos (inscrita y dentro del plazo).",
                listaAbierta ? OK : FALLA));

        // Rol de la fórmula (RN10)
        if (rol == null) {
            requisitos.add(req("ROL", "RN10: el rol indicado no corresponde al cargo «" + nombreCargo + "».", FALLA));
        } else {
            int ocupado = dao.entero("""
                    SELECT COUNT(*) FROM candidato
                     WHERE id_lista = ? AND rol_en_lista = ? AND estado_validacion <> 'EXCLUIDO'
                    """, idLista, rol.codigo());
            requisitos.add(req("ROL", ocupado == 0
                    ? "RN10: el rol «" + rol.etiqueta() + "» está libre en la lista."
                    : "RN10: la lista ya tiene un candidato a «" + rol.etiqueta() + "».", ocupado == 0 ? OK : FALLA));
        }

        // Estado del docente (RN09 / RN03)
        boolean activo = "ACTIVO".equals(docente.get("estado"));
        requisitos.add(req("ACTIVO", activo
                ? "RN09: docente ordinario en estado ACTIVO."
                : "RN09: el docente está en estado " + docente.get("estado") + " y no puede postular.", activo ? OK : FALLA));
        boolean habilitado = Boolean.TRUE.equals(docente.get("habilitado"))
                || (docente.get("habilitado") instanceof Number n && n.intValue() == 1);
        requisitos.add(req("HABILITADO", habilitado
                ? "Figura como habilitado en el padrón de docentes (CUS02)."
                : "No está habilitado en el padrón de docentes (CUS02).", habilitado ? OK : FALLA));

        // Jurisdicción del cargo
        String nivel = String.valueOf(lista.get("nivelJurisdiccion"));
        Object jurisdiccion = lista.get("idJurisdiccion");
        boolean enJurisdiccion = switch (nivel) {
            case "FACULTAD" -> jurisdiccion != null && jurisdiccion.equals(docente.get("idFacultad"));
            case "DEPARTAMENTO" -> jurisdiccion != null && jurisdiccion.equals(docente.get("idDepartamento"));
            default -> true;
        };
        requisitos.add(req("JURISDICCION", enJurisdiccion
                ? "Pertenece a la jurisdicción del cargo."
                : "No pertenece a la " + nivel.toLowerCase() + " del cargo (es de " + docente.get("facultad") + ").",
                enJurisdiccion ? OK : FALLA));

        // RF03: categoría que puede postular
        int configuradas = dao.entero("SELECT COUNT(*) FROM cargo_categoria_permitida WHERE id_cargo = ?", idCargo);
        boolean categoriaOk = configuradas == 0 || dao.entero("""
                SELECT COUNT(*) FROM cargo_categoria_permitida
                 WHERE id_cargo = ? AND categoria = ? AND puede_postular = 1
                """, idCargo, docente.get("categoria")) > 0;
        requisitos.add(req("CATEGORIA", categoriaOk
                ? "RF03: la categoría " + docente.get("categoria") + " puede postular a este cargo."
                : "RF03: la categoría " + docente.get("categoria") + " no puede postular a este cargo.",
                categoriaOk ? OK : FALLA));

        // Duplicados (RN11)
        boolean enEstaLista = dao.entero(
                "SELECT COUNT(*) FROM candidato WHERE id_lista = ? AND id_docente = ?", idLista, idDocente) > 0;
        List<Map<String, Object>> otraLista = dao.consultar("""
                SELECT l.nombre FROM candidato ca
                  JOIN lista_electoral l ON l.id_lista = ca.id_lista
                  JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                 WHERE ca.id_docente = ? AND c.id_proceso = ? AND ca.id_lista <> ?
                   AND ca.estado_validacion <> 'EXCLUIDO'
                 LIMIT 1
                """, idDocente, idProceso, idLista);
        String rn11;
        if (enEstaLista) {
            rn11 = "Ya está inscrito en esta lista.";
        } else if (!otraLista.isEmpty()) {
            rn11 = "RN11: ya es candidato en la lista «" + otraLista.get(0).get("nombre") + "» de este proceso.";
        } else {
            rn11 = "RN11: no es candidato en otra lista del proceso.";
        }
        requisitos.add(req("RN11", rn11, enEstaLista || !otraLista.isEmpty() ? FALLA : OK));

        // RN21 / RN20: personero o miembro de mesa del mismo proceso
        boolean personero = dao.entero("""
                SELECT COUNT(*) FROM personero p
                  JOIN lista_electoral l ON l.id_lista = p.id_lista
                  JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                 WHERE p.id_docente = ? AND c.id_proceso = ? AND p.estado_acreditacion <> 'REVOCADO'
                """, idDocente, idProceso) > 0;
        requisitos.add(req("RN21", personero
                ? "RN21: es personero en este proceso y no puede ser candidato."
                : "RN21: no es personero en este proceso.", personero ? FALLA : OK));
        boolean miembroMesa = dao.entero("""
                SELECT COUNT(*) FROM miembro_mesa mm JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
                 WHERE mm.id_docente = ? AND m.id_proceso = ?
                """, idDocente, idProceso) > 0;
        requisitos.add(req("RN20", miembroMesa
                ? "RN20: es miembro de mesa en este proceso y no puede ser candidato."
                : "RN20: no es miembro de mesa en este proceso.", miembroMesa ? FALLA : OK));

        // RN09: grado académico y antigüedad en la categoría para el rol
        if (rol != null && !rol.gradosRequeridos().isEmpty()) {
            Object grado = docente.get("gradoAcademico");
            String requerido = String.join(" o ", rol.gradosRequeridos());
            if (grado == null) {
                requisitos.add(req("GRADO", "RN09: grado académico no registrado; se exige " + requerido
                        + " (el CEUNP lo verifica al calificar).", ADVERTENCIA));
            } else {
                boolean gradoOk = rol.gradosRequeridos().contains(String.valueOf(grado));
                requisitos.add(req("GRADO", "RN09: grado " + grado + (gradoOk ? " cumple" : " no cumple")
                        + " (se exige " + requerido + ").", gradoOk ? OK : FALLA));
            }
        }
        if (rol != null && rol.aniosCategoria() > 0) {
            Object fecha = docente.get("fechaCategoria");
            LocalDate desde = fecha instanceof java.sql.Date d ? d.toLocalDate()
                    : fecha instanceof LocalDate ld ? ld : null;
            if (desde == null) {
                requisitos.add(req("ANTIGUEDAD", "RN09: fecha de ingreso a la categoría no registrada; se exigen "
                        + rol.aniosCategoria() + " años (el CEUNP lo verifica al calificar).", ADVERTENCIA));
            } else {
                long anios = ChronoUnit.YEARS.between(desde, LocalDate.now());
                boolean antiguedadOk = anios >= rol.aniosCategoria();
                requisitos.add(req("ANTIGUEDAD", "RN09: " + anios + " años en la categoría (se exigen "
                        + rol.aniosCategoria() + ").", antiguedadOk ? OK : FALLA));
            }
        }

        return mostrarDatosCandidato(docente, rol, requisitos);
    }

    /** 8: mostrarDatosCandidato(docente) */
    private Map<String, Object> mostrarDatosCandidato(Map<String, Object> docente, RolesCargo.Rol rol,
            List<Map<String, Object>> requisitos) {
        boolean apto = requisitos.stream().noneMatch(r -> FALLA.equals(r.get("estado")));
        Map<String, Object> datos = new LinkedHashMap<>();
        datos.put("id", docente.get("id"));
        datos.put("dni", docente.get("dni"));
        datos.put("nombre", docente.get("apellidos") + ", " + docente.get("nombres"));
        datos.put("categoria", docente.get("categoria"));
        datos.put("dedicacion", docente.get("dedicacion"));
        datos.put("estado", docente.get("estado"));
        datos.put("gradoAcademico", docente.get("gradoAcademico"));
        datos.put("facultad", docente.get("facultad"));
        datos.put("departamento", docente.get("departamento"));

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("docente", datos);
        respuesta.put("rol", rol == null ? null : Map.of("codigo", rol.codigo(), "etiqueta", rol.etiqueta()));
        respuesta.put("requisitos", requisitos);
        respuesta.put("apto", apto);
        return respuesta;
    }

    private static Map<String, Object> req(String codigo, String descripcion, String estado) {
        Map<String, Object> fila = new LinkedHashMap<>();
        fila.put("codigo", codigo);
        fila.put("descripcion", descripcion);
        fila.put("estado", estado);
        return fila;
    }
}
