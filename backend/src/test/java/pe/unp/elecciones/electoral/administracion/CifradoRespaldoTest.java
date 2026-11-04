package pe.unp.elecciones.electoral.administracion;

import static org.junit.jupiter.api.Assertions.*;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;

import org.junit.jupiter.api.Test;

/** Auditoría B6: los respaldos se guardan cifrados (AES-256-GCM). */
class CifradoRespaldoTest {

    private static final String SQL = "INSERT INTO docente VALUES (1,'40112233','Ana','Ruiz');\n".repeat(200);

    private static byte[] cifrar(String texto, String clave) throws IOException {
        ByteArrayOutputStream destino = new ByteArrayOutputStream();
        try (OutputStream out = CifradoRespaldo.cifrar(destino, clave.toCharArray())) {
            out.write(texto.getBytes(StandardCharsets.UTF_8));
        }
        return destino.toByteArray();
    }

    @Test
    void idaYVuelta() throws IOException {
        byte[] cifrado = cifrar(SQL, "clave-de-respaldo-larga");
        String visible = new String(cifrado, StandardCharsets.ISO_8859_1);
        assertFalse(visible.contains("40112233"), "el DNI no debe verse en el archivo");
        try (InputStream in = CifradoRespaldo.descifrar(new ByteArrayInputStream(cifrado), "clave-de-respaldo-larga".toCharArray())) {
            assertEquals(SQL, new String(in.readAllBytes(), StandardCharsets.UTF_8));
        }
    }

    @Test
    void claveIncorrectaOArchivoAlteradoFallan() throws IOException {
        byte[] cifrado = cifrar(SQL, "clave-de-respaldo-larga");
        assertThrows(IOException.class, () -> {
            try (InputStream in = CifradoRespaldo.descifrar(new ByteArrayInputStream(cifrado), "otra-clave-cualquiera".toCharArray())) {
                in.readAllBytes();
            }
        });
        cifrado[cifrado.length - 20] ^= 1;
        assertThrows(IOException.class, () -> {
            try (InputStream in = CifradoRespaldo.descifrar(new ByteArrayInputStream(cifrado), "clave-de-respaldo-larga".toCharArray())) {
                in.readAllBytes();
            }
        });
    }

    @Test
    void dosCifradosDelMismoTextoSonDistintos() throws IOException {
        assertFalse(java.util.Arrays.equals(cifrar(SQL, "clave-de-respaldo-larga"), cifrar(SQL, "clave-de-respaldo-larga")));
    }
}
