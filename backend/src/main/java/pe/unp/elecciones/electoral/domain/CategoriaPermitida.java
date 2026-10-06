package pe.unp.elecciones.electoral.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;

@Entity
@Table(name = "cargo_categoria_permitida")
@IdClass(CategoriaPermitidaId.class)
public class CategoriaPermitida {

    @Id
    @Column(name = "id_cargo")
    private Integer idCargo;

    @Id
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CategoriaDocente categoria;

    protected CategoriaPermitida() {
    }

    public CategoriaPermitida(Integer idCargo, CategoriaDocente categoria) {
        this.idCargo = idCargo;
        this.categoria = categoria;
    }

    public Integer getIdCargo() { return idCargo; }
    public CategoriaDocente getCategoria() { return categoria; }
}
