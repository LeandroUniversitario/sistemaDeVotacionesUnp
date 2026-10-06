package pe.unp.elecciones.electoral.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "mesa_electoral")
public class MesaSufragio {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_mesa")
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_proceso", nullable = false)
    private ProcesoElectoral proceso;

    @Column(name = "numero_mesa", nullable = false, length = 30)
    private String numero;

    @Column(nullable = false, length = 200)
    private String ubicacion;

    @Column(name = "semilla_sorteo", nullable = false, length = 128)
    private String semillaSorteo;

    @Column(name = "fecha_sorteo")
    private LocalDateTime fechaSorteo;

    @Transient
    private MesaEstado estado = MesaEstado.PENDIENTE;

    @Transient
    private LocalDateTime horaInstalacion;

    @Transient
    private LocalDateTime horaCierre;

    @Transient
    private Integer totalElectores = 0;

    @OneToMany(mappedBy = "mesa", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<MiembroMesa> miembros;

    public MesaSufragio() {}

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }
    public String getNumero() { return numero; }
    public void setNumero(String numero) { this.numero = numero; }
    public ProcesoElectoral getProceso() { return proceso; }
    public void setProceso(ProcesoElectoral proceso) { this.proceso = proceso; }
    public MesaEstado getEstado() { return estado; }
    public void setEstado(MesaEstado estado) { this.estado = estado; }
    public LocalDateTime getHoraInstalacion() { return horaInstalacion; }
    public void setHoraInstalacion(LocalDateTime h) { this.horaInstalacion = h; }
    public LocalDateTime getHoraCierre() { return horaCierre; }
    public void setHoraCierre(LocalDateTime h) { this.horaCierre = h; }
    public Integer getTotalElectores() { return totalElectores; }
    public void setTotalElectores(Integer t) { this.totalElectores = t; }
    public List<MiembroMesa> getMiembros() { return miembros; }
    public void setMiembros(List<MiembroMesa> miembros) { this.miembros = miembros; }
    public String getUbicacion() { return ubicacion; }
    public void setUbicacion(String ubicacion) { this.ubicacion = ubicacion; }
    public String getSemillaSorteo() { return semillaSorteo; }
    public void setSemillaSorteo(String semillaSorteo) { this.semillaSorteo = semillaSorteo; }
    public LocalDateTime getFechaSorteo() { return fechaSorteo; }
    public void setFechaSorteo(LocalDateTime f) { this.fechaSorteo = f; }
}
