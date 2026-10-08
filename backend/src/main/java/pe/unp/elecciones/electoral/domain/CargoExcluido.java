package pe.unp.elecciones.electoral.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "cargo_excluido_sorteo")
public class CargoExcluido {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_cargo_excluido")
    private Integer id;

    @Column(name = "nombre_cargo", nullable = false, length = 150, unique = true)
    private String nombreCargo;

    @Column(nullable = false, length = 80)
    private String nivel;

    @Column(nullable = false)
    private Boolean activo;

    protected CargoExcluido() {}

    public CargoExcluido(String nombreCargo, String nivel, Boolean activo) {
        this.nombreCargo = nombreCargo;
        this.nivel = nivel;
        this.activo = activo != null ? activo : true;
    }

    public Integer getId() { return id; }
    public String getNombreCargo() { return nombreCargo; }
    public void setNombreCargo(String nombreCargo) { this.nombreCargo = nombreCargo; }
    public String getNivel() { return nivel; }
    public void setNivel(String nivel) { this.nivel = nivel; }
    public Boolean getActivo() { return activo; }
    public void setActivo(Boolean activo) { this.activo = activo; }
}
