package pe.unp.elecciones.electoral.administracion;

import java.security.SecureRandom;
import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS18 · «GestionarUsuarios» (control). Mensajes 1 a 4 del diagrama de colaboración:
 *
 *   1   ingresarUsuario()  → PantallaAdministrador (el Admin llena los datos de la cuenta)
 *   1.1 crearUsuario()     → crear()
 *   2   verificarDocente() → fn_error_docente_usuario: docente del padrón, activo y sin otra cuenta con el rol
 *   3   insertarUsuario()  → sp_crear_usuario (contraseña cifrada con BCrypt, provisional)
 *   4   mostrarUsuario()   → v_usuarios_admin y la contraseña provisional, que solo se muestra una vez
 *
 * <p>También edita el rol y el docente, activa o desactiva, desbloquea, restablece la contraseña y
 * elimina las cuentas sin actividad. La base garantiza que siempre quede un administrador activo.
 */
@Service
public class GestionarUsuarios {

    private static final String ALFABETO = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789";
    private static final SecureRandom AZAR = new SecureRandom();

    private final ProcedimientoDao dao;
    private final AdministracionConsulta consulta;
    private final PasswordEncoder passwordEncoder;

    public GestionarUsuarios(ProcedimientoDao dao, AdministracionConsulta consulta, PasswordEncoder passwordEncoder) {
        this.dao = dao;
        this.consulta = consulta;
        this.passwordEncoder = passwordEncoder;
    }

    /** 1.1 crearUsuario() → 2 verificarDocente() → 3 insertarUsuario() → 4 mostrarUsuario(). */
    public Map<String, Object> crear(AdministracionDto.NuevoUsuario datos, Usuario admin) {
        consulta.verificarInstalacion();
        String rol = rol(datos.rol());
        String clave = datos.generarClave() || AdministracionConsulta.vacioANulo(datos.password()) == null
                ? generarClave() : validarClave(datos.password());
        boolean provisional = true;
        ProcedimientoDao.Resultado r = dao.llamar("sp_crear_usuario", ProcedimientoDao.SIN_SALIDA, admin.getId(),
                datos.username().trim(), passwordEncoder.encode(clave), rol, datos.idDocente(), provisional);
        Map<String, Object> usuario = primera(r);
        Map<String, Object> respuesta = new LinkedHashMap<>(consulta.respuesta("Cuenta «" + usuario.get("username")
                + "» creada con el rol " + rol + ". Entregue la contraseña provisional: el usuario deberá cambiarla al ingresar.", admin));
        respuesta.put("usuario", usuario);
        respuesta.put("claveProvisional", clave);
        return respuesta;
    }

    /** Cambio de rol o de docente asociado (2 verificarDocente con la cuenta editada). */
    public Map<String, Object> editar(Integer idUsuario, AdministracionDto.EdicionUsuario datos, Usuario admin) {
        Map<String, Object> antes = consulta.usuario(idUsuario);
        String rol = rol(datos.rol());
        Map<String, Object> usuario = primera(dao.llamar("sp_actualizar_usuario", ProcedimientoDao.SIN_SALIDA,
                admin.getId(), idUsuario, rol, datos.idDocente()));
        String cambio = rol.equals(antes.get("rol")) ? "se actualizó el docente asociado"
                : "el rol cambió de " + antes.get("rol") + " a " + rol;
        Map<String, Object> respuesta = new LinkedHashMap<>(consulta.respuesta(
                "Cuenta «" + usuario.get("username") + "»: " + cambio + ". El cambio rige en su próximo inicio de sesión.", admin));
        respuesta.put("usuario", usuario);
        return respuesta;
    }

    public Map<String, Object> cambiarEstado(Integer idUsuario, AdministracionDto.Estado datos, Usuario admin) {
        consulta.usuario(idUsuario);
        Map<String, Object> usuario = primera(dao.llamar("sp_cambiar_estado_usuario", ProcedimientoDao.SIN_SALIDA,
                admin.getId(), idUsuario, datos.activo(), AdministracionConsulta.vacioANulo(datos.motivo())));
        Map<String, Object> respuesta = new LinkedHashMap<>(consulta.respuesta("Cuenta «" + usuario.get("username") + "» "
                + (datos.activo() ? "activada: ya puede iniciar sesión." : "desactivada: ya no podrá iniciar sesión; su historia se conserva."), admin));
        respuesta.put("usuario", usuario);
        return respuesta;
    }

    /** Contraseña provisional (generada o escrita por el Admin); también levanta el bloqueo. */
    public Map<String, Object> restablecerClave(Integer idUsuario, AdministracionDto.Clave datos, Usuario admin) {
        consulta.usuario(idUsuario);
        String clave = datos == null || AdministracionConsulta.vacioANulo(datos.password()) == null
                ? generarClave() : validarClave(datos.password());
        Map<String, Object> usuario = primera(dao.llamar("sp_restablecer_password", ProcedimientoDao.SIN_SALIDA,
                admin.getId(), idUsuario, passwordEncoder.encode(clave)));
        Map<String, Object> respuesta = new LinkedHashMap<>(consulta.respuesta("Contraseña de «" + usuario.get("username")
                + "» restablecida. Entregue la contraseña provisional: deberá cambiarla al ingresar.", admin));
        respuesta.put("usuario", usuario);
        respuesta.put("claveProvisional", clave);
        return respuesta;
    }

    public Map<String, Object> desbloquear(Integer idUsuario, Usuario admin) {
        consulta.usuario(idUsuario);
        Map<String, Object> usuario = primera(dao.llamar("sp_desbloquear_usuario", ProcedimientoDao.SIN_SALIDA,
                admin.getId(), idUsuario));
        Map<String, Object> respuesta = new LinkedHashMap<>(consulta.respuesta(
                "Cuenta «" + usuario.get("username") + "» desbloqueada: los intentos fallidos volvieron a cero.", admin));
        respuesta.put("usuario", usuario);
        return respuesta;
    }

    /** Solo cuentas sin actividad registrada (RN28); las demás se desactivan. */
    public Map<String, Object> eliminar(Integer idUsuario, Usuario admin) {
        consulta.usuario(idUsuario);
        Map<String, Object> fila = primera(dao.llamar("sp_eliminar_usuario", ProcedimientoDao.SIN_SALIDA, admin.getId(), idUsuario));
        return consulta.respuesta("Cuenta «" + fila.get("username") + "» eliminada.", admin);
    }

    // ─── Contraseñas ─────────────────────────────────────────────────────────

    /** Contraseña escrita por el Admin: longitud mínima del parámetro, letras y números. */
    String validarClave(String clave) {
        int minimo = consulta.entero("SEGURIDAD_PASSWORD_MIN", 8);
        if (clave.length() < minimo) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "La contraseña debe tener al menos " + minimo + " caracteres.");
        }
        if (!clave.matches(".*[A-Za-z].*") || !clave.matches(".*[0-9].*")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La contraseña debe combinar letras y números.");
        }
        if (clave.isBlank() || !clave.equals(clave.trim())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La contraseña no puede empezar ni terminar con espacios.");
        }
        return clave;
    }

    /** Provisional: al menos 10 caracteres sin letras ni números que se confundan, con mayúscula, minúscula y número. */
    String generarClave() {
        int largo = Math.max(10, consulta.entero("SEGURIDAD_PASSWORD_MIN", 8));
        while (true) {
            StringBuilder sb = new StringBuilder(largo);
            for (int i = 0; i < largo; i++) {
                sb.append(ALFABETO.charAt(AZAR.nextInt(ALFABETO.length())));
            }
            String clave = sb.toString();
            if (clave.matches(".*[A-Z].*") && clave.matches(".*[a-z].*") && clave.matches(".*[0-9].*")) {
                return clave;
            }
        }
    }

    private static String rol(String rol) {
        String r = rol == null ? "" : rol.trim().toUpperCase();
        if (!AdministracionConsulta.ROLES.contains(r)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Rol no válido.");
        }
        return r;
    }

    private static Map<String, Object> primera(ProcedimientoDao.Resultado r) {
        if (r.filas().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "El procedimiento no devolvió resultados.");
        }
        return r.filas().get(0);
    }
}
