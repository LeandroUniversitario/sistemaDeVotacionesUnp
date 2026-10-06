package pe.unp.elecciones.electoral.domain;

import jakarta.persistence.*;

@Entity
@Table(name = "departamento")
public class Departamento {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_departamento")
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_facultad", nullable = false)
    private Facultad facultad;

    @Column(nullable = false)
    private String nombre;

    public Departamento() {}
    public Departamento(Facultad facultad, String nombre) {
        this.facultad = facultad;
        this.nombre = nombre;
    }

    public Integer getId() { return id; }
    public Facultad getFacultad() { return facultad; }
    public String getNombre() { return nombre; }
}
