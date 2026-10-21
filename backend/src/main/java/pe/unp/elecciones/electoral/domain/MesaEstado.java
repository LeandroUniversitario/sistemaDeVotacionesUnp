package pe.unp.elecciones.electoral.domain;

public enum MesaEstado {
    PENDIENTE,
    INSTALADA,
    CERRADA,
    ANULADA,
    NO_INSTALADA   // CUS08 / RN07: no se instaló dentro del plazo
}
