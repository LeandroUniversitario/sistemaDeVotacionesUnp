package pe.unp.elecciones.auth;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import java.util.HashSet;
import java.util.Optional;
import java.util.Set;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.domain.ParametroGlobal;
import pe.unp.elecciones.electoral.repository.ParametroGlobalRepository;

/** Auditoría B2 / A3: política única de contraseñas y claves provisionales aleatorias. */
class PoliticaPasswordTest {

    private ParametroGlobalRepository repo;
    private PoliticaPassword politica;

    @BeforeEach
    void preparar() {
        repo = mock(ParametroGlobalRepository.class);
        when(repo.findById("SEGURIDAD_PASSWORD_MIN"))
                .thenReturn(Optional.of(new ParametroGlobal("SEGURIDAD_PASSWORD_MIN", "10", "")));
        politica = new PoliticaPassword(repo);
    }

    @Test
    void usaElMinimoDelParametro() {
        assertEquals(10, politica.minimo());
        assertThrows(ResponseStatusException.class, () -> politica.validar("abc12345"));   // 8 < 10
        assertEquals("abcde12345", politica.validar("abcde12345"));
    }

    @Test
    void nuncaBajaDeOchoAunqueElParametroLoDiga() {
        when(repo.findById("SEGURIDAD_PASSWORD_MIN"))
                .thenReturn(Optional.of(new ParametroGlobal("SEGURIDAD_PASSWORD_MIN", "4", "")));
        assertEquals(8, politica.minimo());
        when(repo.findById("SEGURIDAD_PASSWORD_MIN"))
                .thenReturn(Optional.of(new ParametroGlobal("SEGURIDAD_PASSWORD_MIN", "xx", "")));
        assertEquals(8, politica.minimo());
    }

    @Test
    void exigeLetrasYNumerosSinEspaciosExteriores() {
        assertThrows(ResponseStatusException.class, () -> politica.validar("soloLetrasAqui"));
        assertThrows(ResponseStatusException.class, () -> politica.validar("1234567890"));
        assertThrows(ResponseStatusException.class, () -> politica.validar(" clave12345"));
        assertThrows(ResponseStatusException.class, () -> politica.validar(null));
    }

    @Test
    void laProvisionalCumpleLaPoliticaYNoSeRepite() {
        Set<String> vistas = new HashSet<>();
        for (int i = 0; i < 500; i++) {
            String clave = politica.generarProvisional();
            assertEquals(clave, politica.validar(clave));
            assertFalse(clave.matches("\\d{8}"), "no puede parecerse a un DNI");
            assertTrue(vistas.add(clave), "clave repetida: " + clave);
        }
    }
}
