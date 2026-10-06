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
@Table(name = "tacha")
public class Tacha {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_tacha")
    private Integer id;

    @Column(name = "id_docente_denunciante", nullable = false)
    private Integer idDocenteDenunciante;

    @Column(name = "id_candidato", nullable = false)
    private Integer idCandidato;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String motivo;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TachaEstado estado;

    @Column(name = "fecha_presentacion", nullable = false)
    private LocalDateTime fechaPresentacion;

    @Column(name = "fecha_resolucion")
    private LocalDateTime fechaResolucion;

    protected Tacha() {
    }

    public Tacha(Integer idDocenteDenunciante, Integer idCandidato, String motivo) {
        this.idDocenteDenunciante = idDocenteDenunciante;
        this.idCandidato = idCandidato;
        this.motivo = motivo;
        this.estado = TachaEstado.PENDIENTE;
        this.fechaPresentacion = LocalDateTime.now();
    }

    public void resolver(TachaEstado resultado) {
        this.estado = resultado;
        this.fechaResolucion = LocalDateTime.now();
    }

    public Integer getId() { return id; }
    public Integer getIdDocenteDenunciante() { return idDocenteDenunciante; }
    public Integer getIdCandidato() { return idCandidato; }
    public String getMotivo() { return motivo; }
    public TachaEstado getEstado() { return estado; }
    public LocalDateTime getFechaPresentacion() { return fechaPresentacion; }
    public LocalDateTime getFechaResolucion() { return fechaResolucion; }
}
