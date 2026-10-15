package pe.unp.elecciones.electoral.service;

import com.opencsv.CSVReader;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import pe.unp.elecciones.electoral.domain.*;
import pe.unp.elecciones.electoral.repository.*;

import java.io.InputStreamReader;
import java.text.Normalizer;
import java.util.*;
import java.util.regex.Pattern;

/**
 * Servicio de importación masiva de docentes.
 *
 * Según el diagrama de colaboraciones, ImportarDocentes solo ejecuta:
 *   2: leerDatos()           → lee el archivo Excel/CSV
 *   3: registrarMasivo(datos) → inserta/actualiza docentes
 *
 * Las facultades y departamentos NO se crean durante la importación;
 * deben existir previamente en la base de datos. Si una fila del archivo
 * referencia una facultad o departamento inexistente, se reporta como error.
 */
@Service
public class ImportacionDocenteService {

    private final DocenteRepository docenteRepository;
    private final FacultadRepository facultadRepository;
    private final DepartamentoRepository departamentoRepository;

    public ImportacionDocenteService(DocenteRepository docenteRepository,
                                      FacultadRepository facultadRepository,
                                      DepartamentoRepository departamentoRepository) {
        this.docenteRepository = docenteRepository;
        this.facultadRepository = facultadRepository;
        this.departamentoRepository = departamentoRepository;
    }

    /* ── leerDatos() ─────────────────────────────────────────────── */

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

    /* ── registrarMasivo(datos) ──────────────────────────────────── */

    @Transactional
    private Map<String, Object> registrarMasivo(List<Map<String, Object>> filas) {
        int insertados = 0, actualizados = 0;
        List<String> errores = new ArrayList<>();

        // Cargar catálogos existentes (solo lectura, nunca se modifican)
        List<Facultad> todasFacultades = facultadRepository.findAll();
        List<Departamento> todosDepartamentos = departamentoRepository.findAll();

        for (int i = 0; i < filas.size(); i++) {
            Map<String, Object> fila = filas.get(i);
            try {
                String dniRaw = limpiar(fila.get("DNI"));
                if (dniRaw == null || dniRaw.isBlank()) {
                    errores.add("Fila " + (i + 2) + ": DNI vacío, se omite.");
                    continue;
                }

                // Normalizar DNI a 8 dígitos (ej: "3681071" -> "03681071")
                String dniFormateado = dniRaw;
                if (dniRaw.matches("\\d+")) {
                    dniFormateado = String.format("%08d", Long.parseLong(dniRaw));
                }

                String nombres = limpiar(fila.get("Nombres"));
                String apellidos = limpiar(fila.get("Apellidos"));
                String categoriaStr = limpiar(fila.get("Categoría"));
                String dedicacion = limpiar(fila.get("Dedicación"));
                String estadoStr = limpiar(fila.get("Estado"));
                String facultadNombre = limpiar(fila.get("Facultad"));
                String departamentoNombre = limpiar(fila.get("Departamento"));

                CategoriaDocente categoria = parsarCategoria(categoriaStr);
                DocenteEstado estado = parsarEstado(estadoStr);

                // Buscar Facultad existente (NUNCA crear una nueva)
                Facultad facultadObj = buscarFacultad(facultadNombre, todasFacultades);
                if (facultadObj == null) {
                    errores.add("Fila " + (i + 2) + ": La facultad '" + facultadNombre
                            + "' no existe en el sistema. Registre la facultad antes de importar.");
                    continue;
                }
                Integer idFacultad = facultadObj.getId();

                // Buscar Departamento existente (NUNCA crear uno nuevo)
                Departamento dptoObj = buscarDepartamento(departamentoNombre, facultadObj, todosDepartamentos);
                if (dptoObj == null) {
                    errores.add("Fila " + (i + 2) + ": El departamento '" + departamentoNombre
                            + "' no existe en la facultad '" + facultadNombre
                            + "'. Registre el departamento antes de importar.");
                    continue;
                }
                Integer idDepartamento = dptoObj.getId();

                // Búsqueda inteligente de docente existente por DNI (buscando "03681071" Y "3681071")
                Optional<Docente> existing = buscarDocenteExistente(dniFormateado);

                if (existing.isPresent()) {
                    Docente d = existing.get();
                    d.setNombres(nombres);
                    d.setApellidos(apellidos);
                    d.setCategoria(categoria);
                    d.setDedicacion(dedicacion);
                    d.setEstado(estado);
                    d.setIdFacultad(idFacultad);
                    d.setIdDepartamento(idDepartamento);
                    docenteRepository.save(d);
                    actualizados++;
                } else {
                    Docente nuevo = new Docente(dniFormateado, nombres, apellidos, categoria, dedicacion, estado, idFacultad, idDepartamento);
                    docenteRepository.save(nuevo);
                    insertados++;
                }
            } catch (Exception e) {
                errores.add("Fila " + (i + 2) + ": " + e.getMessage());
            }
        }

        return Map.of(
            "insertados", insertados,
            "actualizados", actualizados,
            "errores", errores,
            "total", insertados + actualizados
        );
    }

    /**
     * Busca docente existente probando tanto el DNI normalizado a 8 dígitos ("03681071")
     * como su variante sin ceros a la izquierda ("3681071").
     */
    private Optional<Docente> buscarDocenteExistente(String dniFormateado) {
        // 1. Buscar con DNI exacto de 8 dígitos
        Optional<Docente> opt = docenteRepository.findByDni(dniFormateado);
        if (opt.isPresent()) return opt;

        // 2. Buscar con DNI sin cero a la izquierda
        if (dniFormateado.matches("\\d+")) {
            String dniSinCero = String.valueOf(Long.parseLong(dniFormateado));
            opt = docenteRepository.findByDni(dniSinCero);
            if (opt.isPresent()) return opt;
        }

        return Optional.empty();
    }

    /**
     * Busca una facultad existente por nombre (comparación flexible sin tildes).
     * Retorna null si no se encuentra — NUNCA crea una nueva.
     */
    private Facultad buscarFacultad(String nombreOriginal, List<Facultad> facultades) {
        if (nombreOriginal == null || nombreOriginal.isBlank()) return null;
        String normBusqueda = normalizar(nombreOriginal);
        for (Facultad f : facultades) {
            if (normalizar(f.getNombre()).equals(normBusqueda) ||
                normalizar(f.getNombre()).contains(normBusqueda) ||
                normBusqueda.contains(normalizar(f.getNombre()))) {
                return f;
            }
        }
        return null;
    }

    /**
     * Busca un departamento existente por nombre dentro de una facultad (comparación flexible sin tildes).
     * Retorna null si no se encuentra — NUNCA crea uno nuevo.
     */
    private Departamento buscarDepartamento(String nombreOriginal, Facultad facultad, List<Departamento> departamentos) {
        if (nombreOriginal == null || nombreOriginal.isBlank()) return null;
        String normBusqueda = normalizar(nombreOriginal);
        for (Departamento d : departamentos) {
            if (d.getFacultad().getId().equals(facultad.getId())) {
                if (normalizar(d.getNombre()).equals(normBusqueda) ||
                    normalizar(d.getNombre()).contains(normBusqueda) ||
                    normBusqueda.contains(normalizar(d.getNombre()))) {
                    return d;
                }
            }
        }
        return null;
    }

    private String normalizar(String input) {
        if (input == null) return "";
        String temp = Normalizer.normalize(input, Normalizer.Form.NFD);
        Pattern pattern = Pattern.compile("\\p{InCombiningDiacriticalMarks}+");
        return pattern.matcher(temp).replaceAll("").toLowerCase().trim();
    }

    /* ── Lectores de archivos ────────────────────────────────────── */

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

    /* ── Utilitarios ─────────────────────────────────────────────── */

    private String cellValue(Cell cell) {
        if (cell == null) return "";
        return switch (cell.getCellType()) {
            case STRING -> cell.getStringCellValue().trim();
            case NUMERIC -> {
                double v = cell.getNumericCellValue();
                yield v == Math.floor(v) ? String.valueOf((long) v) : String.valueOf(v);
            }
            case BOOLEAN -> String.valueOf(cell.getBooleanCellValue());
            default -> "";
        };
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
            case "INACTIVO"  -> DocenteEstado.INACTIVO;
            default           -> DocenteEstado.ACTIVO;
        };
    }
}

