package pe.unp.elecciones.electoral.domain;

import jakarta.persistence.*;
import java.io.Serializable;
import java.util.Objects;

@Entity
@Table(name = "miembro_mesa")
@IdClass(MiembroMesa.MiembroId.class)
public class MiembroMesa {

    /** Clave primaria compuesta: (id_mesa, id_docente) */
    public static class MiembroId implements Serializable {
        private Integer mesa;
        private Integer docente;

        public MiembroId() {}
        public MiembroId(Integer mesa, Integer docente) {
            this.mesa = mesa;
            this.docente = docente;
        }

        @Override public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof MiembroId m)) return false;
            return Objects.equals(mesa, m.mesa) && Objects.equals(docente, m.docente);
        }
        @Override public int hashCode() { return Objects.hash(mesa, docente); }
    }

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_mesa", nullable = false)
    private MesaSufragio mesa;

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_docente", nullable = false)
    private Docente docente;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RolMiembro rol; // PRESIDENTE, SECRETARIO, VOCAL, SUPLENTE

    @Column(nullable = false)
    private Boolean titular = false;

    public MiembroMesa() {}

    public MesaSufragio getMesa() { return mesa; }
    public void setMesa(MesaSufragio mesa) { this.mesa = mesa; }
    public Docente getDocente() { return docente; }
    public void setDocente(Docente docente) { this.docente = docente; }
    public RolMiembro getRol() { return rol; }
    public void setRol(RolMiembro rol) { this.rol = rol; }
    public Boolean getTitular() { return titular; }
    public void setTitular(Boolean titular) { this.titular = titular; }
}
