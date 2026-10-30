package pe.unp.elecciones.electoral.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "docente")
public class Docente {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_docente")
    private Integer id;

    @Column(nullable = false, unique = true, length = 8)
    private String dni;

    @Column(nullable = false, length = 100)
    private String nombres;

    @Column(nullable = false, length = 150)
    private String apellidos;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CategoriaDocente categoria;

    @Column(nullable = false, length = 80)
    private String dedicacion;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DocenteEstado estado;

    @Column(name = "id_facultad", nullable = false)
    private Integer idFacultad;

    @Column(name = "id_departamento", nullable = false)
    private Integer idDepartamento;

    @Column(name = "habilitado_para_votar", nullable = false)
    private boolean habilitadoParaVotar = true;

    @Column(name = "grado_academico", length = 50)
    private String gradoAcademico;

    @Column(name = "fecha_ingreso")
    private java.time.LocalDate fechaIngreso;

    @Column(name = "fecha_categoria")
    private java.time.LocalDate fechaCategoria;

    @Column(name = "email", length = 150)
    private String email;

    @Column(name = "url_foto", length = 300)
    private String urlFoto;

    protected Docente() {
    }

    public Docente(String dni, String nombres, String apellidos, CategoriaDocente categoria,
            String dedicacion, DocenteEstado estado, Integer idFacultad, Integer idDepartamento) {
        this.dni = dni;
        this.nombres = nombres;
        this.apellidos = apellidos;
        this.categoria = categoria;
        this.dedicacion = dedicacion;
        this.estado = estado;
        this.idFacultad = idFacultad;
        this.idDepartamento = idDepartamento;
        // Regla: solo ACTIVO puede votar
        this.habilitadoParaVotar = (estado == DocenteEstado.ACTIVO);
    }

    public Integer getId() { return id; }
    public String getDni() { return dni; }
    public String getNombres() { return nombres; }
    public void setNombres(String nombres) { this.nombres = nombres; }
    public String getApellidos() { return apellidos; }
    public void setApellidos(String apellidos) { this.apellidos = apellidos; }
    public CategoriaDocente getCategoria() { return categoria; }
    public void setCategoria(CategoriaDocente categoria) { this.categoria = categoria; }
    public String getDedicacion() { return dedicacion; }
    public void setDedicacion(String dedicacion) { this.dedicacion = dedicacion; }
    public DocenteEstado getEstado() { return estado; }
    public void setEstado(DocenteEstado estado) {
        this.estado = estado;
        // Regla automática: solo ACTIVO puede votar
        this.habilitadoParaVotar = (estado == DocenteEstado.ACTIVO);
    }
    public boolean isHabilitadoParaVotar() { return habilitadoParaVotar; }
    public void setHabilitadoParaVotar(boolean habilitadoParaVotar) { this.habilitadoParaVotar = habilitadoParaVotar; }
    public Integer getIdFacultad() { return idFacultad; }
    public void setIdFacultad(Integer idFacultad) { this.idFacultad = idFacultad; }
    public Integer getIdDepartamento() { return idDepartamento; }
    public String getGradoAcademico() { return gradoAcademico; }
    public void setGradoAcademico(String gradoAcademico) { this.gradoAcademico = gradoAcademico; }
    public java.time.LocalDate getFechaIngreso() { return fechaIngreso; }
    public void setFechaIngreso(java.time.LocalDate fechaIngreso) { this.fechaIngreso = fechaIngreso; }
    public java.time.LocalDate getFechaCategoria() { return fechaCategoria; }
    public void setFechaCategoria(java.time.LocalDate fechaCategoria) { this.fechaCategoria = fechaCategoria; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getUrlFoto() { return urlFoto; }
    public void setUrlFoto(String urlFoto) { this.urlFoto = urlFoto; }
    public void setIdDepartamento(Integer idDepartamento) { this.idDepartamento = idDepartamento; }
}
