package pe.unp.elecciones.electoral.bitacora;

import java.util.Map;

import jakarta.servlet.http.HttpServletRequest;

import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import pe.unp.elecciones.auth.UsuarioActual;

/**
 * CUS19 · Consultar bitácora (actor: Admin). Boundary «PantallaBitacora». Solo lectura: no hay
 * PUT, PATCH ni DELETE; la base rechaza cualquier cambio a log_auditoria.
 *
 * <ul>
 *   <li>GET / → catálogo de acciones, cuentas, procesos, sello de la cadena y alertas de 24 horas</li>
 *   <li>GET /registros?filtros&pagina&tamano&orden → 1-5 ingresarFiltros, buscarRegistros,
 *       validarRolAdministrador, consultar, mostrarRegistros · ConsultarBitacora</li>
 *   <li>GET /registros/{id} → 6-9 seleccionarRegistro, obtenerDetalle, consultarDetalle,
 *       mostrarDetalleJSON · VerDetalleRegistro</li>
 *   <li>POST /verificacion → verifica la cadena de sellos SHA-256 · VerificarBitacora</li>
 *   <li>GET /exportacion?filtros → archivo CSV con los registros filtrados · ExportarBitacora</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/bitacora")
@PreAuthorize("hasRole('ADMIN')")
public class BitacoraController {

    private final BitacoraConsulta consulta;
    private final ConsultarBitacora consultarBitacora;
    private final VerDetalleRegistro verDetalleRegistro;
    private final VerificarBitacora verificarBitacora;
    private final ExportarBitacora exportarBitacora;
    private final UsuarioActual usuarioActual;

    public BitacoraController(BitacoraConsulta consulta, ConsultarBitacora consultarBitacora,
            VerDetalleRegistro verDetalleRegistro, VerificarBitacora verificarBitacora, ExportarBitacora exportarBitacora,
            UsuarioActual usuarioActual) {
        this.consulta = consulta;
        this.consultarBitacora = consultarBitacora;
        this.verDetalleRegistro = verDetalleRegistro;
        this.verificarBitacora = verificarBitacora;
        this.exportarBitacora = exportarBitacora;
        this.usuarioActual = usuarioActual;
    }

    @GetMapping
    public Map<String, Object> pantalla(Authentication authentication) {
        return consultarBitacora.pantalla(usuarioActual.requerido(authentication));
    }

    /**
     * 1 ingresarFiltros(usuario, accion, fecha_inicio, fecha_fin) → 2 buscarRegistros(filtros).
     * Filtros: texto, idUsuario, rol, accion, modulo, criticidad, idProceso, idDocente, ip, desde, hasta.
     */
    @GetMapping("/registros")
    public Map<String, Object> registros(@RequestParam Map<String, String> parametros,
            @RequestParam(defaultValue = "0") int pagina, @RequestParam(defaultValue = "25") int tamano,
            @RequestParam(defaultValue = "DESC") String orden, @RequestParam(defaultValue = "true") boolean resumen,
            Authentication authentication) {
        return consultarBitacora.buscarRegistros(consulta.filtros(parametros), pagina, tamano,
                "ASC".equalsIgnoreCase(orden), resumen, usuarioActual.requerido(authentication));
    }

    /** 6 seleccionarRegistro(id_log) → 7 obtenerDetalle → 8 consultarDetalle → 9 mostrarDetalleJSON. */
    @GetMapping("/registros/{id}")
    public Map<String, Object> detalle(@PathVariable Long id, Authentication authentication) {
        return verDetalleRegistro.obtenerDetalle(id, usuarioActual.requerido(authentication));
    }

    @PostMapping("/verificacion")
    public Map<String, Object> verificar(Authentication authentication, HttpServletRequest request) {
        return verificarBitacora.verificar(usuarioActual.requerido(authentication), request.getRemoteAddr(),
                request.getHeader(HttpHeaders.USER_AGENT));
    }

    @GetMapping("/exportacion")
    public ResponseEntity<byte[]> exportar(@RequestParam Map<String, String> parametros,
            @RequestParam(defaultValue = "DESC") String orden, Authentication authentication, HttpServletRequest request) {
        ExportarBitacora.Archivo archivo = exportarBitacora.csv(consulta.filtros(parametros), "ASC".equalsIgnoreCase(orden),
                usuarioActual.requerido(authentication), request.getRemoteAddr(), request.getHeader(HttpHeaders.USER_AGENT));
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment().filename(archivo.nombre()).build().toString())
                .header("X-Registros", String.valueOf(archivo.registros()))
                .header("X-Truncado", String.valueOf(archivo.truncado()))
                .header(HttpHeaders.ACCESS_CONTROL_EXPOSE_HEADERS, "Content-Disposition, X-Registros, X-Truncado")
                .contentType(new MediaType("text", "csv", java.nio.charset.StandardCharsets.UTF_8))
                .body(archivo.contenido());
    }
}
