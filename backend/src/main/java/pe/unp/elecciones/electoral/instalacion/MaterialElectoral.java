package pe.unp.elecciones.electoral.instalacion;

/**
 * CUS08 · Material electoral que recibe la mesa (RF57, CUN07 paso 2; Art. 48 y 49).
 * Mensaje 5 del diagrama: ingresarMaterial(padron, actas, cedulas, anfora, cabina).
 * Todo es obligatorio: la mesa no se instala si falta alguno.
 */
public enum MaterialElectoral {

    PADRON("Padrón de electores (lista de electores de la mesa)"),
    ACTAS("Actas electorales (instalación, sufragio y escrutinio)"),
    CEDULAS("Cédulas de sufragio"),
    CARTEL_CANDIDATOS("Cartel de candidatos"),
    ANFORA("Ánfora"),
    CABINA("Cabina o cámara secreta");

    private final String descripcion;

    MaterialElectoral(String descripcion) {
        this.descripcion = descripcion;
    }

    public String descripcion() {
        return descripcion;
    }

    /** RF57: estado en que se recibió cada material. */
    public enum Estado {
        CONFORME, OBSERVADO, NO_RECIBIDO
    }
}
