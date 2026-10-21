package pe.unp.elecciones.electoral.instalacion;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

/** CUS08 · Habilita la tarea que vigila el plazo de instalación (InstalarMesa.vigilarPlazo, RF58). */
@Configuration
@EnableScheduling
public class InstalacionConfig {
}
