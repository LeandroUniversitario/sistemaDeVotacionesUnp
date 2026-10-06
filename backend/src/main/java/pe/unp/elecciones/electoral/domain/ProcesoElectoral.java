package pe.unp.elecciones.electoral.domain;

import java.math.BigDecimal;
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
@Table(name = "proceso_electoral")
public class ProcesoElectoral {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_proceso")
    private Integer id;

    @Column(nullable = false, length = 200)
    private String nombre;

    @Column(name = "fecha_inicio", nullable = false)
    private LocalDateTime fechaInicio;

    @Column(name = "fecha_fin", nullable = false)
    private LocalDateTime fechaFin;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ProcesoEstado estado;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ProcesoTipo tipo;

    @Column(name = "id_proceso_padre")
    private Integer idProcesoPadre;

    @Column(name = "quorum_minimo", nullable = false, precision = 5, scale = 2)
    private BigDecimal quorumMinimo;

    protected ProcesoElectoral() {
    }

    public ProcesoElectoral(String nombre, LocalDateTime fechaInicio, LocalDateTime fechaFin,
                     ProcesoEstado estado, ProcesoTipo tipo, Integer idProcesoPadre,
                     BigDecimal quorumMinimo) {
        this.nombre = nombre;
        this.fechaInicio = fechaInicio;
        this.fechaFin = fechaFin;
        this.estado = estado;
        this.tipo = tipo;
        this.idProcesoPadre = idProcesoPadre;
        this.quorumMinimo = quorumMinimo;
    }

    public Integer getId() { return id; }
    public String getNombre() { return nombre; }
    public LocalDateTime getFechaInicio() { return fechaInicio; }
    public LocalDateTime getFechaFin() { return fechaFin; }
    public ProcesoEstado getEstado() { return estado; }
    public ProcesoTipo getTipo() { return tipo; }
    public Integer getIdProcesoPadre() { return idProcesoPadre; }
    public BigDecimal getQuorumMinimo() { return quorumMinimo; }
}
