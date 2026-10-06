package pe.unp.elecciones.electoral.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "voto")
public class Voto {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_voto")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_proceso", nullable = false)
    private ProcesoElectoral proceso;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_cargo", nullable = false)
    private CargoElectoral cargo;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_lista_elegida")
    private ListaElectoral listaElegida;

    @Enumerated(EnumType.STRING)
    @Column(name = "tipo_voto", nullable = false)
    private TipoVoto tipo;

    @Column(name = "fecha_hora", nullable = false)
    private LocalDateTime fechaHora = LocalDateTime.now();

    public Voto() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public ProcesoElectoral getProceso() { return proceso; }
    public void setProceso(ProcesoElectoral proceso) { this.proceso = proceso; }
    public CargoElectoral getCargo() { return cargo; }
    public void setCargo(CargoElectoral cargo) { this.cargo = cargo; }
    public ListaElectoral getListaElegida() { return listaElegida; }
    public void setListaElegida(ListaElectoral listaElegida) { this.listaElegida = listaElegida; }
    public TipoVoto getTipo() { return tipo; }
    public void setTipo(TipoVoto tipo) { this.tipo = tipo; }
    public LocalDateTime getFechaHora() { return fechaHora; }
    public void setFechaHora(LocalDateTime fechaHora) { this.fechaHora = fechaHora; }
}
