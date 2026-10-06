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
@Table(name = "candidato")
public class Candidato {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_candidato")
    private Integer id;

    @Column(name = "id_lista", nullable = false)
    private Integer idLista;

    @Column(name = "id_docente", nullable = false)
    private Integer idDocente;

    @Column(name = "rol_en_lista", nullable = false, length = 100)
    private String rolEnLista;

    @Enumerated(EnumType.STRING)
    @Column(name = "estado_validacion", nullable = false)
    private CandidatoEstado estadoValidacion;

    @Column(name = "fecha_inscripcion", nullable = false)
    private LocalDateTime fechaInscripcion;

    protected Candidato() {
    }

    public Candidato(Integer idLista, Integer idDocente, String rolEnLista) {
        this.idLista = idLista;
        this.idDocente = idDocente;
        this.rolEnLista = rolEnLista;
        this.estadoValidacion = CandidatoEstado.PENDIENTE;
        this.fechaInscripcion = LocalDateTime.now();
    }

    public void excluir() {
        this.estadoValidacion = CandidatoEstado.EXCLUIDO;
    }

    public Integer getId() { return id; }
    public Integer getIdLista() { return idLista; }
    public Integer getIdDocente() { return idDocente; }
    public String getRolEnLista() { return rolEnLista; }
    public CandidatoEstado getEstadoValidacion() { return estadoValidacion; }
    public LocalDateTime getFechaInscripcion() { return fechaInscripcion; }
}
