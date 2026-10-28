package pe.unp.elecciones.auth;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;

@Entity
@Table(name = "usuario")
public class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_usuario")
    private Integer id;

    @Column(name = "id_docente")
    private Integer idDocente;

    @Column(name = "username", nullable = false, unique = true, length = 80)
    private String username;

    @Column(name = "password_hash", nullable = false, length = 255)
    private String passwordHash;

    @Enumerated(EnumType.STRING)
    @Column(name = "rol", nullable = false)
    private Rol rol;

    @Column(name = "activo", nullable = false)
    private boolean activo;

    @Column(name = "intentos_fallidos", nullable = false)
    private int intentosFallidos;

    @Column(name = "bloqueado_hasta")
    private LocalDateTime bloqueadoHasta;

    @Column(name = "ultimo_acceso")
    private LocalDateTime ultimoAcceso;

    /**
     * TRUE cuando la cuenta fue creada masivamente (importacion) y el docente
     * debe elegir su propia contrasena al primer inicio de sesion.
     */
    @Column(name = "debe_cambiar_password", nullable = false)
    private boolean debeCambiarPassword = false;

    protected Usuario() {
    }

    public Usuario(String username, String passwordHash, Rol rol, Integer idDocente) {
        this.username = username;
        this.passwordHash = passwordHash;
        this.rol = rol;
        this.idDocente = idDocente;
        this.activo = true;
        this.intentosFallidos = 0;
        this.debeCambiarPassword = false;
    }

    void cambiarPassword(String passwordHash) {
        this.passwordHash = passwordHash;
        this.debeCambiarPassword = false; // limpia el flag al cambiar la clave
    }

    /** CUS18: intentos y minutos de bloqueo salen de los parámetros SEGURIDAD_INTENTOS_MAXIMOS y SEGURIDAD_BLOQUEO_MINUTOS. */
    public void registrarIntentoFallido(int intentosMaximos, int minutosBloqueo) {
        this.intentosFallidos++;
        if (this.intentosFallidos >= intentosMaximos) {
            this.bloqueadoHasta = LocalDateTime.now().plusMinutes(minutosBloqueo);
        }
    }

    public void registrarAccesoExitoso() {
        this.intentosFallidos = 0;
        this.bloqueadoHasta = null;
        this.ultimoAcceso = LocalDateTime.now();
    }

    public Integer getId()                      { return id; }
    public String getUsername()                 { return username; }
    public Integer getIdDocente()               { return idDocente; }
    public String getPasswordHash()             { return passwordHash; }
    public Rol getRol()                         { return rol; }
    public boolean isActivo()                   { return activo; }
    public int getIntentosFallidos()            { return intentosFallidos; }
    public LocalDateTime getBloqueadoHasta()    { return bloqueadoHasta; }
    public LocalDateTime getUltimoAcceso()      { return ultimoAcceso; }
    public boolean isDebeCambiarPassword()      { return debeCambiarPassword; }

    public void setDebeCambiarPassword(boolean debeCambiarPassword) {
        this.debeCambiarPassword = debeCambiarPassword;
    }
}