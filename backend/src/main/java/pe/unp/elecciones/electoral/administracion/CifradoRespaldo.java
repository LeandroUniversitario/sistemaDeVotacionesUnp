package pe.unp.elecciones.electoral.administracion;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.GeneralSecurityException;
import java.security.SecureRandom;
import java.util.Arrays;

import javax.crypto.Cipher;
import javax.crypto.CipherInputStream;
import javax.crypto.CipherOutputStream;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.PBEKeySpec;
import javax.crypto.spec.SecretKeySpec;

/**
 * Cifrado de los respaldos de la base (auditoría B6 y C1): el archivo lleva hashes de contraseñas,
 * datos personales, participación y votos, así que nunca se escribe en claro.
 *
 * <p>Formato: "UNPRESP1" (8 bytes) | sal (16) | IV (12) | AES-256-GCM(SQL). La clave se deriva de
 * la variable RESPALDO_CLAVE con PBKDF2-HMAC-SHA256 (210 000 iteraciones). GCM autentica el
 * contenido: un archivo alterado no se descifra.
 *
 * <p>Para restaurar:
 * <pre>
 *   RESPALDO_CLAVE=... java -cp elecciones-backend.jar \
 *     -Dloader.main=pe.unp.elecciones.electoral.administracion.CifradoRespaldo \
 *     org.springframework.boot.loader.launch.PropertiesLauncher respaldo.sql.enc respaldo.sql
 *   mysql -u root elecciones_unp &lt; respaldo.sql
 * </pre>
 */
public final class CifradoRespaldo {

    private static final byte[] MAGICO = "UNPRESP1".getBytes(StandardCharsets.US_ASCII);
    private static final int ITERACIONES = 210_000;
    private static final SecureRandom AZAR = new SecureRandom();

    private CifradoRespaldo() {
    }

    /** Envuelve la salida: escribe la cabecera y devuelve un flujo que cifra lo que se le escriba. */
    public static OutputStream cifrar(OutputStream destino, char[] clave) throws IOException {
        try {
            byte[] sal = new byte[16];
            byte[] iv = new byte[12];
            AZAR.nextBytes(sal);
            AZAR.nextBytes(iv);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, llave(clave, sal), new GCMParameterSpec(128, iv));
            destino.write(MAGICO);
            destino.write(sal);
            destino.write(iv);
            return new CipherOutputStream(destino, cipher);
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException("No se pudo iniciar el cifrado del respaldo.", e);
        }
    }

    /** Flujo que descifra un respaldo cifrado con {@link #cifrar}. */
    public static InputStream descifrar(InputStream origen, char[] clave) throws IOException {
        byte[] magico = origen.readNBytes(MAGICO.length);
        if (!Arrays.equals(magico, MAGICO)) {
            throw new IOException("El archivo no es un respaldo cifrado del sistema.");
        }
        byte[] sal = origen.readNBytes(16);
        byte[] iv = origen.readNBytes(12);
        try {
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, llave(clave, sal), new GCMParameterSpec(128, iv));
            return new CipherInputStream(origen, cipher);
        } catch (GeneralSecurityException e) {
            throw new IOException("No se pudo iniciar el descifrado del respaldo.", e);
        }
    }

    private static SecretKeySpec llave(char[] clave, byte[] sal) throws GeneralSecurityException {
        PBEKeySpec spec = new PBEKeySpec(clave, sal, ITERACIONES, 256);
        byte[] bytes = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256").generateSecret(spec).getEncoded();
        spec.clearPassword();
        return new SecretKeySpec(bytes, "AES");
    }

    /** Herramienta de restauración: descifra {@code origen} en {@code destino} con RESPALDO_CLAVE. */
    public static void main(String[] args) throws IOException {
        if (args.length != 2) {
            System.err.println("Uso: CifradoRespaldo <respaldo.sql.enc> <salida.sql>  (con RESPALDO_CLAVE definida)");
            System.exit(2);
        }
        String clave = System.getenv("RESPALDO_CLAVE");
        if (clave == null || clave.isBlank()) {
            System.err.println("Defina la variable de entorno RESPALDO_CLAVE.");
            System.exit(2);
        }
        Path origen = Paths.get(args[0]);
        Path destino = Paths.get(args[1]);
        try (InputStream in = descifrar(Files.newInputStream(origen), clave.toCharArray());
                OutputStream out = Files.newOutputStream(destino)) {
            in.transferTo(out);
        }
        System.out.println("Respaldo descifrado en " + destino.toAbsolutePath());
    }
}
