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
@Table(name = "cargo_electoral")
public class CargoElectoral {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_cargo")
    private Integer id;

    @Column(name = "id_proceso", nullable = false)
    private Integer idProceso;

    @Column(nullable = false, length = 150)
    private String nombre;

    @Enumerated(EnumType.STRING)
    @Column(name = "nivel_jurisdiccion", nullable = false)
    private NivelJurisdiccion nivelJurisdiccion;

    @Column(name = "id_jurisdiccion")
    private Integer idJurisdiccion;

    protected CargoElectoral() {
    }

    public CargoElectoral(Integer idProceso, String nombre, NivelJurisdiccion nivelJurisdiccion,
                   Integer idJurisdiccion) {
        this.idProceso = idProceso;
        this.nombre = nombre;
        this.nivelJurisdiccion = nivelJurisdiccion;
        this.idJurisdiccion = idJurisdiccion;
    }

    public Integer getId() { return id; }
    public Integer getIdProceso() { return idProceso; }
    public String getNombre() { return nombre; }
    public NivelJurisdiccion getNivelJurisdiccion() { return nivelJurisdiccion; }
    public Integer getIdJurisdiccion() { return idJurisdiccion; }
}
