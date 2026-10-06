package pe.unp.elecciones.electoral.domain;

import java.io.Serializable;

public class CategoriaPermitidaId implements Serializable {

    private Integer idCargo;
    private CategoriaDocente categoria;

    public CategoriaPermitidaId() {
    }

    public CategoriaPermitidaId(Integer idCargo, CategoriaDocente categoria) {
        this.idCargo = idCargo;
        this.categoria = categoria;
    }

    @Override
    public boolean equals(Object object) {
        if (this == object) return true;
        if (!(object instanceof CategoriaPermitidaId other)) return false;
        return idCargo.equals(other.idCargo) && categoria == other.categoria;
    }

    @Override
    public int hashCode() {
        return 31 * idCargo.hashCode() + categoria.hashCode();
    }
}
