package pe.unp.elecciones.electoral.domain;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "lista_electoral")
public class ListaElectoral {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_lista")
    private Integer id;

    @Column(name = "id_cargo", nullable = false)
    private Integer idCargo;

    @Column(nullable = false, length = 150)
    private String nombre;

    @Column(length = 100)
    private String simbolo;

    @Column(name = "orden_cedula")
    private Integer ordenCedula;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ListaEstado estado;

    @Column(name = "fecha_inscripcion", nullable = false)
    private LocalDateTime fechaInscripcion;

    protected ListaElectoral() {
    }

    public ListaElectoral(Integer idCargo, String nombre, String simbolo) {
        this.idCargo = idCargo;
        this.nombre = nombre;
        this.simbolo = simbolo;
        this.estado = ListaEstado.INSCRITA;
        this.fechaInscripcion = LocalDateTime.now();
    }

    public Integer getId() { return id; }
    public Integer getIdCargo() { return idCargo; }
    public String getNombre() { return nombre; }
    public String getSimbolo() { return simbolo; }
    public Integer getOrdenCedula() { return ordenCedula; }
    public ListaEstado getEstado() { return estado; }
    public LocalDateTime getFechaInscripcion() { return fechaInscripcion; }
}
