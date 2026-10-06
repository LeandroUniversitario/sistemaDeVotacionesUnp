package pe.unp.elecciones.electoral.domain;

import jakarta.persistence.*;
import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.Objects;

@Entity
@Table(name = "padron_electoral")
@IdClass(PadronMesa.PadronId.class)
public class PadronMesa {

    /** Clave primaria compuesta: (id_proceso, id_cargo, id_docente) */
    public static class PadronId implements Serializable {
        private Integer proceso;
        private Integer cargo;
        private Integer docente;

        public PadronId() {}
        public PadronId(Integer proceso, Integer cargo, Integer docente) {
            this.proceso = proceso;
            this.cargo = cargo;
            this.docente = docente;
        }

        @Override public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof PadronId p)) return false;
            return Objects.equals(proceso, p.proceso) && Objects.equals(cargo, p.cargo) && Objects.equals(docente, p.docente);
        }
        @Override public int hashCode() { return Objects.hash(proceso, cargo, docente); }
    }

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_proceso", nullable = false)
    private ProcesoElectoral proceso;

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_cargo", nullable = false)
    private CargoElectoral cargo;

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_docente", nullable = false)
    private Docente docente;

    @Column(name = "habilitado_para_votar")
    private Boolean habilitadoParaVotar = true;

    @Column(name = "ya_voto")
    private Boolean yaVoto = false;

    @Column(name = "fecha_votacion")
    private LocalDateTime fechaVotacion;

    @Column(name = "motivo_inhabilitacion")
    private String motivoInhabilitacion;

    public PadronMesa() {}

    public ProcesoElectoral getProceso() { return proceso; }
    public void setProceso(ProcesoElectoral proceso) { this.proceso = proceso; }
    public CargoElectoral getCargo() { return cargo; }
    public void setCargo(CargoElectoral cargo) { this.cargo = cargo; }
    public Docente getDocente() { return docente; }
    public void setDocente(Docente docente) { this.docente = docente; }
    public Boolean getHabilitado() { return habilitadoParaVotar; }
    public void setHabilitado(Boolean h) { this.habilitadoParaVotar = h; }
    public Boolean getYaVoto() { return yaVoto; }
    public void setYaVoto(Boolean yaVoto) { this.yaVoto = yaVoto; }
    public LocalDateTime getFechaVotacion() { return fechaVotacion; }
    public void setFechaVotacion(LocalDateTime f) { this.fechaVotacion = f; }
    public String getMotivoInhabilitacion() { return motivoInhabilitacion; }
    public void setMotivoInhabilitacion(String m) { this.motivoInhabilitacion = m; }
}
