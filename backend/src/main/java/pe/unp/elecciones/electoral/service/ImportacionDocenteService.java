package pe.unp.elecciones.electoral.service;

import com.opencsv.CSVReader;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import pe.unp.elecciones.auth.Rol;
import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.auth.UsuarioRepository;
import pe.unp.elecciones.electoral.domain.CategoriaDocente;
import pe.unp.elecciones.electoral.domain.Departamento;
import pe.unp.elecciones.electoral.domain.Docente;
import pe.unp.elecciones.electoral.domain.DocenteEstado;
import pe.unp.elecciones.electoral.domain.Facultad;
import pe.unp.elecciones.electoral.repository.DepartamentoRepository;
import pe.unp.elecciones.electoral.repository.DocenteRepository;
import pe.unp.elecciones.electoral.repository.FacultadRepository;

import java.io.InputStreamReader;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.regex.Pattern;

/**
 * Servicio de importacion masiva de docentes.
 *
 * Segun el diagrama de colaboraciones, ImportarDocentes solo ejecuta:
 *   2: leerDatos()            -> lee el archivo Excel/CSV
 *   3: registrarMasivo(datos) -> inserta/actualiza docentes
 *
 * Las facultades y departamentos NO se crean durante la importacion;
 * deben existir previamente en la base de datos.
 *
 * NUEVO: tras registrar cada docente, crea automaticamente su cuenta
 * de usuario con rol DOCENTE si no la tiene todavia:
 *   - Username: inicial primer nombre + primer apellido (sin tildes)
 *   - Password inicial: DNI (BCrypt) con debeCambiarPassword=true
 */
@Service
public class ImportacionDocenteService {

    private final DocenteRepository docenteRepository;
    private final FacultadRepository facultadRepository;
    private final DepartamentoRepository departamentoRepository;
    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;

    public ImportacionDocenteService(DocenteRepository docenteRepository,
                                      FacultadRepository facultadRepository,
                                      DepartamentoRepository departamentoRepository,
                                      UsuarioRepository usuarioRepository,
                                      PasswordEncoder passwordEncoder) {
        this.docenteRepository = docenteRepository;
        this.facultadRepository = facultadRepository;
        this.departamentoRepository = departamentoRepository;
        this.usuarioRepository = usuarioRepository;
        this.passwordEncoder = passwordEncoder;
    }

    /* ═══ leerDatos() ═══ */

    @Transactional
    public Map<String, Object> importarExcel(MultipartFile file) throws Exception {
        List<Map<String, Object>> filas = leerExcel(file);
        return registrarMasivo(filas);
    }

    @Transactional
    public Map<String, Object> importarCsv(MultipartFile file) throws Exception {
        List<Map<String, Object>> filas = leerCsv(file);
        return registrarMasivo(filas);
    }

    /* ═══ registrarMasivo(datos) ═══ */

    @Transactional
    private Map<String, Object> registrarMasivo(List<Map<String, Object>> filas) {
        int insertados = 0, actualizados = 0, usuariosCreados = 0;
        List<String> errores = new ArrayList<>();

        List<Facultad> todasFacultades = facultadRepository.findAll();
        List<Departamento> todosDepartamentos = departamentoRepository.findAll();

        for (int i = 0; i < filas.size(); i++) {
            Map<String, Object> fila = filas.get(i);
            try {
                String dniRaw            = obtenerCampo(fila, "DNI", "dni");
                if (dniRaw == null || dniRaw.isBlank()) {
                    errores.add("Fila " + (i + 2) + ": DNI vacio, se omite.");
                    continue;
                }

                String dniFormateado = dniRaw;
                if (dniRaw.matches("\\d+")) {
                    dniFormateado = String.format("%08d", Long.parseLong(dniRaw));
                }

                String nombres           = obtenerCampo(fila, "Nombres", "nombres", "Nombre", "nombre");
                String apellidos         = obtenerCampo(fila, "Apellidos", "apellidos", "Apellido", "apellido");
                String categoriaS        = obtenerCampo(fila, "Categoria", "Categoría", "categoria", "categoría");
                String dedicacion        = obtenerCampo(fila, "Dedicacion", "Dedicación", "dedicacion", "dedicación");
                String estadoS           = obtenerCampo(fila, "Estado", "estado");
                String facultadNombre    = obtenerCampo(fila, "Facultad", "facultad");
                String departamentoNombre = obtenerCampo(fila, "Departamento", "departamento");

                if (nombres.isBlank() || apellidos.isBlank()) {
                    errores.add("Fila " + (i + 2) + ": Nombres o Apellidos vacios, se omite.");
                    continue;
                }

                CategoriaDocente categoria = parsarCategoria(categoriaS);
                DocenteEstado    estado    = parsarEstado(estadoS);

                Facultad facultadObj = buscarFacultad(facultadNombre, todasFacultades);
                if (facultadObj == null) {
                    errores.add("Fila " + (i + 2) + ": La facultad '" + facultadNombre + "' no existe. Registrela antes de importar.");
                    continue;
                }

                Departamento dptoObj = buscarDepartamento(departamentoNombre, facultadObj, todosDepartamentos);
                if (dptoObj == null) {
                    errores.add("Fila " + (i + 2) + ": El departamento '" + departamentoNombre
                            + "' no existe en la facultad '" + facultadNombre
                            + "'. Registre el departamento antes de importar.");
                    continue;
                }

                Optional<Docente> existing = buscarDocenteExistente(dniFormateado);
                Docente docenteGuardado;

                if (existing.isPresent()) {
                    Docente d = existing.get();
                    d.setNombres(nombres);
                    d.setApellidos(apellidos);
                    d.setCategoria(categoria);
                    d.setDedicacion(dedicacion);
                    d.setEstado(estado);
                    d.setIdFacultad(facultadObj.getId());
                    d.setIdDepartamento(dptoObj.getId());
                    docenteGuardado = docenteRepository.save(d);
                    actualizados++;
                } else {
                    Docente nuevo = new Docente(dniFormateado, nombres, apellidos, categoria,
                            dedicacion, estado, facultadObj.getId(), dptoObj.getId());
                    docenteGuardado = docenteRepository.save(nuevo);
                    insertados++;
                }

                // Crear usuario automaticamente si no existe todavia
                boolean yaTieneUsuario = usuarioRepository.findByIdDocente(docenteGuardado.getId()).isPresent();
                if (!yaTieneUsuario) {
                    String baseUsername  = generarUsernameBase(docenteGuardado.getNombres(), docenteGuardado.getApellidos());
                    String usernameFinal = resolverUsernameUnico(baseUsername);
                    String passwordHash  = passwordEncoder.encode(docenteGuardado.getDni());

                    Usuario nuevoUsuario = new Usuario(usernameFinal, passwordHash, Rol.DOCENTE, docenteGuardado.getId());
                    nuevoUsuario.setDebeCambiarPassword(true);
                    usuarioRepository.save(nuevoUsuario);
                    usuariosCreados++;
                }

            } catch (Exception e) {
                errores.add("Fila " + (i + 2) + ": " + e.getMessage());
            }
        }

        Map<String, Object> resultado = new LinkedHashMap<>();
        resultado.put("insertados",      insertados);
        resultado.put("actualizados",    actualizados);
        resultado.put("usuariosCreados", usuariosCreados);
        resultado.put("errores",         errores);
        resultado.put("total",           insertados + actualizados);
        return resultado;
    }

    /* ═══ Generacion de usernames ═══ */

    /**
     * Genera el username base: inicial del primer nombre + primer apellido sin tildes.
     * Ejemplo: "Juan Carlos" + "Perez Ramos" -> "jperez"
     */
    private String generarUsernameBase(String nombres, String apellidos) {
        String primerNombre   = nombres.trim().split("\\s+")[0];
        String primerApellido = apellidos.trim().split("\\s+")[0];
        String base = (primerNombre.substring(0, 1) + primerApellido).toLowerCase();
        return Normalizer.normalize(base, Normalizer.Form.NFD)
                .replaceAll("\\p{InCombiningDiacriticalMarks}+", "")
                .replaceAll("[^a-z0-9]", "");
    }

    /** Resuelve colisiones: si "jperez" ya existe prueba "jperez2", "jperez3", etc. */
    private String resolverUsernameUnico(String base) {
        if (base.isBlank()) base = "docente";
        String username = base;
        int contador = 2;
        while (usuarioRepository.existsByUsername(username)) {
            username = base + contador;
            contador++;
        }
        return username;
    }

    /* ═══ Busquedas de catalogos ═══ */

    private Optional<Docente> buscarDocenteExistente(String dniFormateado) {
        Optional<Docente> opt = docenteRepository.findByDni(dniFormateado);
        if (opt.isPresent()) return opt;
        if (dniFormateado.matches("\\d+")) {
            String dniSinCero = String.valueOf(Long.parseLong(dniFormateado));
            opt = docenteRepository.findByDni(dniSinCero);
            if (opt.isPresent()) return opt;
        }
        return Optional.empty();
    }

    private Facultad buscarFacultad(String nombreOriginal, List<Facultad> facultades) {
        if (nombreOriginal == null || nombreOriginal.isBlank()) return null;
        String normBusqueda = normalizar(nombreOriginal);

        // 1. Prioridad: Coincidencia EXACTA
        for (Facultad f : facultades) {
            if (normalizar(f.getNombre()).equals(normBusqueda)) {
                return f;
            }
        }

        // 2. Coincidencia parcial (priorizar la más larga/específica)
        Facultad mejorCoincidencia = null;
        int maxLen = 0;
        for (Facultad f : facultades) {
            String normF = normalizar(f.getNombre());
            if (normF.contains(normBusqueda) || normBusqueda.contains(normF)) {
                if (normF.length() > maxLen) {
                    mejorCoincidencia = f;
                    maxLen = normF.length();
                }
            }
        }
        return mejorCoincidencia;
    }

    private Departamento buscarDepartamento(String nombreOriginal, Facultad facultad, List<Departamento> departamentos) {
        if (nombreOriginal == null || nombreOriginal.isBlank() || facultad == null) return null;
        String normBusqueda = normalizar(nombreOriginal);

        // 1. Prioridad: Coincidencia EXACTA dentro de la facultad
        for (Departamento d : departamentos) {
            if (d.getFacultad().getId().equals(facultad.getId())) {
                if (normalizar(d.getNombre()).equals(normBusqueda)) {
                    return d;
                }
            }
        }

        // 2. Coincidencia parcial dentro de la facultad (priorizar la más larga/específica)
        Departamento mejorCoincidencia = null;
        int maxLen = 0;
        for (Departamento d : departamentos) {
            if (d.getFacultad().getId().equals(facultad.getId())) {
                String normD = normalizar(d.getNombre());
                if (normD.contains(normBusqueda) || normBusqueda.contains(normD)) {
                    if (normD.length() > maxLen) {
                        mejorCoincidencia = d;
                        maxLen = normD.length();
                    }
                }
            }
        }
        return mejorCoincidencia;
    }

    private String normalizar(String input) {
        if (input == null) return "";
        String temp = Normalizer.normalize(input, Normalizer.Form.NFD);
        Pattern pattern = Pattern.compile("\\p{InCombiningDiacriticalMarks}+");
        return pattern.matcher(temp).replaceAll("").toLowerCase().trim();
    }

    /* ═══ Lectores de archivos ═══ */

    private List<Map<String, Object>> leerExcel(MultipartFile file) throws Exception {
        List<Map<String, Object>> rows = new ArrayList<>();
        try (Workbook wb = new XSSFWorkbook(file.getInputStream())) {
            Sheet sheet = wb.getSheetAt(0);
            Row header = sheet.getRow(0);
            if (header == null) return rows;
            List<String> cols = new ArrayList<>();
            for (Cell c : header) cols.add(c.getStringCellValue().trim());
            for (int r = 1; r <= sheet.getLastRowNum(); r++) {
                Row row = sheet.getRow(r);
                if (row == null) continue;
                Map<String, Object> map = new LinkedHashMap<>();
                boolean vacia = true;
                for (int c = 0; c < cols.size(); c++) {
                    Cell cell = row.getCell(c, Row.MissingCellPolicy.RETURN_BLANK_AS_NULL);
                    String val = cellValue(cell);
                    if (!val.isBlank()) vacia = false;
                    map.put(cols.get(c), val);
                }
                if (!vacia) rows.add(map);
            }
        }
        return rows;
    }

    private List<Map<String, Object>> leerCsv(MultipartFile file) throws Exception {
        List<Map<String, Object>> rows = new ArrayList<>();
        try (CSVReader reader = new CSVReader(new InputStreamReader(file.getInputStream(), "UTF-8"))) {
            String[] header = reader.readNext();
            if (header == null) return rows;
            String[] line;
            while ((line = reader.readNext()) != null) {
                Map<String, Object> map = new LinkedHashMap<>();
                for (int i = 0; i < header.length && i < line.length; i++) {
                    map.put(header[i].trim(), line[i].trim());
                }
                rows.add(map);
            }
        }
        return rows;
    }

    /* ═══ Utilitarios ═══ */

    private String cellValue(Cell cell) {
        if (cell == null) return "";
        return switch (cell.getCellType()) {
            case STRING  -> cell.getStringCellValue().trim();
            case NUMERIC -> {
                double v = cell.getNumericCellValue();
                yield v == Math.floor(v) ? String.valueOf((long) v) : String.valueOf(v);
            }
            case BOOLEAN -> String.valueOf(cell.getBooleanCellValue());
            default      -> "";
        };
    }

    private String obtenerCampo(Map<String, Object> fila, String... nombresPosibles) {
        if (fila == null) return "";
        for (String nombre : nombresPosibles) {
            Object v = fila.get(nombre);
            if (v != null && !v.toString().trim().isEmpty()) {
                return v.toString().trim();
            }
        }
        for (String pos : nombresPosibles) {
            String normPos = normalizar(pos);
            for (Map.Entry<String, Object> entry : fila.entrySet()) {
                if (normalizar(entry.getKey()).equals(normPos)) {
                    Object v = entry.getValue();
                    if (v != null && !v.toString().trim().isEmpty()) {
                        return v.toString().trim();
                    }
                }
            }
        }
        return "";
    }

    private String limpiar(Object v) {
        return v == null ? "" : v.toString().trim();
    }

    private CategoriaDocente parsarCategoria(String s) {
        if (s == null) return CategoriaDocente.AUXILIAR;
        return switch (s.toUpperCase().trim()) {
            case "PRINCIPAL" -> CategoriaDocente.PRINCIPAL;
            case "ASOCIADO"  -> CategoriaDocente.ASOCIADO;
            default          -> CategoriaDocente.AUXILIAR;
        };
    }

    private DocenteEstado parsarEstado(String s) {
        if (s == null) return DocenteEstado.ACTIVO;
        return switch (s.toUpperCase().trim()) {
            case "LICENCIA"   -> DocenteEstado.LICENCIA;
            case "SUSPENDIDO" -> DocenteEstado.SUSPENDIDO;
            case "INACTIVO"   -> DocenteEstado.INACTIVO;
            default           -> DocenteEstado.ACTIVO;
        };
    }
}