package pe.unp.elecciones.electoral.domain;

public class CargoExcluido {

    private Integer id;
    private String nombreCargo;
    private String nivel;
    private Boolean activo;

    protected CargoExcluido() {}

    public CargoExcluido(String nombreCargo, String nivel, Boolean activo) {
        this.nombreCargo = nombreCargo;
        this.nivel = nivel;
        this.activo = activo != null ? activo : true;
    }

    public Integer getId() { return id; }
    public String getNombreCargo() { return nombreCargo; }
    public void setNombreCargo(String nombreCargo) { this.nombreCargo = nombreCargo; }
    public String getNivel() { return nivel; }
    public void setNivel(String nivel) { this.nivel = nivel; }
    public Boolean getActivo() { return activo; }
    public void setActivo(Boolean activo) { this.activo = activo; }
}
