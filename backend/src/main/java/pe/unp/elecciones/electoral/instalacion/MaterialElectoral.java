package pe.unp.elecciones.electoral.instalacion;

/**
 * CUS08 · Material electoral que la mesa recibe antes de instalarse (Art. 45).
 * Sin el material obligatorio la mesa no se puede instalar.
 */
public enum MaterialElectoral {

    PADRON_MESA("Padrón de electores de la mesa", true),
    TERMINAL_VOTACION("Terminal de votación operativo", true),
    CABINA_SECRETA("Cámara secreta acondicionada", true),
    ANFORA("Ánfora para las cédulas impresas", true),
    FORMATOS_ACTA("Formatos de acta (instalación, sufragio y escrutinio)", true),
    LECTOR_QR("Lector de códigos QR (pistola o cámara)", false),
    UTILES("Útiles electorales (lapiceros, tampón, sellos)", false),
    CARTEL("Cartel de identificación de la mesa", false);

    private final String descripcion;
    private final boolean obligatorio;

    MaterialElectoral(String descripcion, boolean obligatorio) {
        this.descripcion = descripcion;
        this.obligatorio = obligatorio;
    }

    public String descripcion() {
        return descripcion;
    }

    public boolean obligatorio() {
        return obligatorio;
    }
}
