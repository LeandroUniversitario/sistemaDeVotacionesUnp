package pe.unp.elecciones.electoral.domain;

import jakarta.persistence.*;

@Entity
@Table(name = "parametro_global")
public class ParametroGlobal {

    @Id
    @Column(name = "clave", length = 80)
    private String clave;

    @Column(name = "valor", nullable = false, length = 255)
    private String valor;

    @Column(name = "descripcion", length = 500)
    private String descripcion;

    public ParametroGlobal() {}

    public ParametroGlobal(String clave, String valor, String descripcion) {
        this.clave = clave;
        this.valor = valor;
        this.descripcion = descripcion;
    }

    public String getClave() { return clave; }
    public String getValor() { return valor; }
    public void setValor(String valor) { this.valor = valor; }
    public String getDescripcion() { return descripcion; }
}
