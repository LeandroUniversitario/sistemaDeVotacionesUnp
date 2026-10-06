package pe.unp.elecciones.electoral.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "log_auditoria")
public class LogAuditoria {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_log")
    private Long id;

    @Column(name = "id_usuario")
    private Integer idUsuario;

    @Column(name = "id_proceso")
    private Integer idProceso;

    @Column(nullable = false, length = 100)
    private String accion;

    @Column(name = "ip_origen", length = 45)
    private String ipOrigen;

    @Column(name = "user_agent", length = 500)
    private String userAgent;

    @Column(name = "fecha_hora", nullable = false)
    private LocalDateTime fechaHora = LocalDateTime.now();

    @Column(name = "detalle_json", columnDefinition = "JSON")
    private String detalleJson;

    public LogAuditoria() {}

    public LogAuditoria(Integer idUsuario, Integer idProceso, String accion,
                         String ipOrigen, String userAgent, String detalleJson) {
        this.idUsuario = idUsuario;
        this.idProceso = idProceso;
        this.accion = accion;
        this.ipOrigen = ipOrigen;
        this.userAgent = userAgent;
        this.detalleJson = detalleJson;
        this.fechaHora = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public Integer getIdUsuario() { return idUsuario; }
    public Integer getIdProceso() { return idProceso; }
    public String getAccion() { return accion; }
    public String getIpOrigen() { return ipOrigen; }
    public String getUserAgent() { return userAgent; }
    public LocalDateTime getFechaHora() { return fechaHora; }
    public String getDetalleJson() { return detalleJson; }
}
