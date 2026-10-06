package pe.unp.elecciones.electoral.domain;

import jakarta.persistence.*;

@Entity
@Table(name = "facultad")
public class Facultad {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_facultad")
    private Integer id;

    @Column(nullable = false, unique = true)
    private String nombre;

    public Facultad() {}
    public Facultad(String nombre) { this.nombre = nombre; }

    public Integer getId() { return id; }
    public String getNombre() { return nombre; }
}
