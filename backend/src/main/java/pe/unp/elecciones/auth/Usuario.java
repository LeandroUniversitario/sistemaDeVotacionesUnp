package pe.unp.elecciones.auth;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

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

    protected Usuario() {
    }

    Usuario(String username, String passwordHash, Rol rol, Integer idDocente) {
        this.username = username;
        this.passwordHash = passwordHash;
        this.rol = rol;
        this.idDocente = idDocente;
        this.activo = true;
    }

    void cambiarEstado(boolean activo) {
        this.activo = activo;
    }

    void cambiarPassword(String passwordHash) {
        this.passwordHash = passwordHash;
    }

    void cambiarRol(Rol nuevoRol) {
        this.rol = nuevoRol;
    }

    public Integer getId() {
        return id;
    }

    public String getUsername() {
        return username;
    }

    public Integer getIdDocente() {
        return idDocente;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public Rol getRol() {
        return rol;
    }

    public boolean isActivo() {
        return activo;
    }
}
