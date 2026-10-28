package pe.unp.elecciones.electoral.administracion;

import java.nio.file.Path;
import java.util.List;
import java.util.Map;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;

import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import pe.unp.elecciones.auth.UsuarioActual;

/**
 * CUS18 · Administrar usuarios y parámetros (actor: Admin). Boundary «PantallaAdministrador».
 *
 * <ul>
 *   <li>GET / → cuentas, parámetros, historial, respaldos y política de seguridad</li>
 *   <li>GET /docentes?q= y GET /docentes/{id}/verificacion?rol= → 2 verificarDocente</li>
 *   <li>POST /usuarios → 1-4 ingresarUsuario, crearUsuario, insertarUsuario, mostrarUsuario · GestionarUsuarios</li>
 *   <li>PUT /usuarios/{id}, POST /usuarios/{id}/estado | /clave | /desbloqueo, DELETE /usuarios/{id}</li>
 *   <li>PUT /parametros/{clave} → 5-9 modificarParametro, actualizar, actualizarParametro, registrarAuditoria,
 *       confirmarCambio · ActualizarParametros</li>
 *   <li>POST /parametros/{clave}/restauracion → vuelve al valor anterior de un cambio del historial</li>
 *   <li>POST /respaldos → 10-13 solicitarRespaldo, generarRespaldo, registrarAuditoria, mostrarRespaldo · RespaldarBD</li>
 *   <li>GET /respaldos/{id}/archivo (descarga) y POST /respaldos/{id}/verificacion (huella SHA-256)</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/administracion")
@PreAuthorize("hasRole('ADMIN')")
public class AdministracionController {

    private final AdministracionConsulta consulta;
    private final GestionarUsuarios gestionarUsuarios;
    private final ActualizarParametros actualizarParametros;
    private final RespaldarBD respaldarBD;
    private final UsuarioActual usuarioActual;

    public AdministracionController(AdministracionConsulta consulta, GestionarUsuarios gestionarUsuarios,
            ActualizarParametros actualizarParametros, RespaldarBD respaldarBD, UsuarioActual usuarioActual) {
        this.consulta = consulta;
        this.gestionarUsuarios = gestionarUsuarios;
        this.actualizarParametros = actualizarParametros;
        this.respaldarBD = respaldarBD;
        this.usuarioActual = usuarioActual;
    }

    // ─── Consultas ───────────────────────────────────────────────────────────

    @GetMapping
    public Map<String, Object> detalle(Authentication authentication) {
        return consulta.detalle(usuarioActual.requerido(authentication));
    }

    @GetMapping("/usuarios/{id}/actividad")
    public Map<String, Object> actividad(@PathVariable Integer id) {
        return consulta.actividad(id);
    }

    @GetMapping("/docentes")
    public List<Map<String, Object>> docentes(@RequestParam(name = "q", required = false) String q) {
        return consulta.docentes(q);
    }

    /** 2 verificarDocente(): reglas para asociar la cuenta al docente con el rol elegido. */
    @GetMapping("/docentes/{id}/verificacion")
    public Map<String, Object> verificarDocente(@PathVariable Integer id, @RequestParam String rol,
            @RequestParam(required = false) Integer idUsuario) {
        return consulta.verificarDocente(id, rol, idUsuario);
    }

    @GetMapping("/parametros/{clave}/historial")
    public List<Map<String, Object>> historial(@PathVariable String clave) {
        consulta.parametro(clave);
        return consulta.historial(clave, 100);
    }

    // ─── 1-4 Cuentas ─────────────────────────────────────────────────────────

    @PostMapping("/usuarios")
    public Map<String, Object> crear(@Valid @RequestBody AdministracionDto.NuevoUsuario datos, Authentication authentication) {
        return gestionarUsuarios.crear(datos, usuarioActual.requerido(authentication));
    }

    @PutMapping("/usuarios/{id}")
    public Map<String, Object> editar(@PathVariable Integer id, @Valid @RequestBody AdministracionDto.EdicionUsuario datos,
            Authentication authentication) {
        return gestionarUsuarios.editar(id, datos, usuarioActual.requerido(authentication));
    }

    @PostMapping("/usuarios/{id}/estado")
    public Map<String, Object> estado(@PathVariable Integer id, @Valid @RequestBody AdministracionDto.Estado datos,
            Authentication authentication) {
        return gestionarUsuarios.cambiarEstado(id, datos, usuarioActual.requerido(authentication));
    }

    @PostMapping("/usuarios/{id}/clave")
    public Map<String, Object> clave(@PathVariable Integer id, @Valid @RequestBody(required = false) AdministracionDto.Clave datos,
            Authentication authentication) {
        return gestionarUsuarios.restablecerClave(id, datos, usuarioActual.requerido(authentication));
    }

    @PostMapping("/usuarios/{id}/desbloqueo")
    public Map<String, Object> desbloquear(@PathVariable Integer id, Authentication authentication) {
        return gestionarUsuarios.desbloquear(id, usuarioActual.requerido(authentication));
    }

    @DeleteMapping("/usuarios/{id}")
    public Map<String, Object> eliminar(@PathVariable Integer id, Authentication authentication) {
        return gestionarUsuarios.eliminar(id, usuarioActual.requerido(authentication));
    }

    // ─── 5-9 Parámetros ──────────────────────────────────────────────────────

    @PutMapping("/parametros/{clave}")
    public Map<String, Object> actualizar(@PathVariable String clave, @Valid @RequestBody AdministracionDto.CambioParametro datos,
            Authentication authentication, HttpServletRequest request) {
        return actualizarParametros.actualizar(clave, datos, usuarioActual.requerido(authentication), request.getRemoteAddr());
    }

    @PostMapping("/parametros/{clave}/restauracion")
    public Map<String, Object> restaurar(@PathVariable String clave, @Valid @RequestBody AdministracionDto.Restauracion datos,
            Authentication authentication, HttpServletRequest request) {
        return actualizarParametros.restaurar(clave, datos, usuarioActual.requerido(authentication), request.getRemoteAddr());
    }

    // ─── 10-13 Respaldo de la base de datos ─────────────────────────────────

    @PostMapping("/respaldos")
    public Map<String, Object> respaldar(@Valid @RequestBody(required = false) AdministracionDto.SolicitudRespaldo datos,
            Authentication authentication, HttpServletRequest request) {
        return respaldarBD.generar(datos, usuarioActual.requerido(authentication), request.getRemoteAddr());
    }

    @GetMapping("/respaldos/{id}/archivo")
    public ResponseEntity<Resource> descargar(@PathVariable Integer id, Authentication authentication, HttpServletRequest request) {
        Path ruta = respaldarBD.archivo(id, usuarioActual.requerido(authentication), request.getRemoteAddr());
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment().filename(ruta.getFileName().toString()).build().toString())
                .contentType(new MediaType("application", "sql"))
                .body(new FileSystemResource(ruta));
    }

    @PostMapping("/respaldos/{id}/verificacion")
    public Map<String, Object> verificarRespaldo(@PathVariable Integer id, Authentication authentication) {
        return respaldarBD.verificar(id, usuarioActual.requerido(authentication));
    }
}
