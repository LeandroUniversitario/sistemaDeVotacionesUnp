package pe.unp.elecciones.electoral.credenciales;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.electoral.credenciales.GenerarTokenQR.TokenGenerado;
import pe.unp.elecciones.electoral.service.Bitacora;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS07 · Control «EmitirConstancia» del diagrama de colaboración.
 *
 * <pre>
 *  GenerarTokenQR   --4: guardarConstancia(token_hash)--> EmitirConstancia
 *  EmitirConstancia --5: insertar(token_qr_hash, id_docente)--> CredencialQR
 *  EmitirConstancia --6: renderizarQR(token_hash)--> LectorQR
 * </pre>
 *
 * La entidad del paso 5 es la tabla {@code credencial_qr} (base-de-datos/04_credenciales_qr.sql), no
 * {@code constancia_voto}: esa la crea sp_emitir_voto DESPUÉS de votar y tiene una fila
 * única por (proceso, docente, cargo); escribir ahí la credencial impediría votar.
 *
 * Reglas: una sola credencial VIGENTE por titular (emitir otra revoca la anterior), vence
 * al terminar el sufragio y cada emisión o revocación queda en la bitácora (sin el token).
 */
@Service
public class EmitirConstancia {

    /** Prefijo del contenido del QR: {@code SICEUNP|<letra del tipo>|<token>}. */
    public static final String PREFIJO_QR = "SICEUNP";

    private final ProcedimientoDao dao;
    private final Bitacora bitacora;

    public EmitirConstancia(ProcedimientoDao dao, Bitacora bitacora) {
        this.dao = dao;
        this.bitacora = bitacora;
    }

    /** 4: guardarConstancia(token_hash) — guarda la credencial y devuelve el QR para mostrarlo una vez. */
    @Transactional
    public Map<String, Object> guardarConstancia(TokenGenerado generado, Integer idUsuario) {
        Map<String, Object> titular = generado.titular();
        TipoCredencial tipo = generado.tipo();
        Integer idDocente = entero(titular.get("idDocente"));
        Integer idMesa = entero(titular.get("idMesa"));
        Integer idPersonero = tipo == TipoCredencial.PERSONERO ? entero(titular.get("idTitular")) : null;

        int reemplazadas = revocarVigente(generado.idProceso(), tipo, idDocente, idMesa, idPersonero,
                "Reemplazada por una nueva emisión");
        Map<String, Object> credencial = insertar(generado.tokenHash(), idDocente, generado.idProceso(), tipo,
                idMesa, idPersonero, idUsuario);

        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("id_credencial", credencial.get("idCredencial"));
        detalle.put("tipo", tipo.name());
        detalle.put("id_docente", idDocente);
        detalle.put("id_mesa", idMesa);
        detalle.put("id_personero", idPersonero);
        detalle.put("reemplaza_anterior", reemplazadas > 0);
        bitacora.registrar(idUsuario, generado.idProceso(), "EMITIR_CREDENCIAL", detalle);

        return renderizarQR(generado, credencial, reemplazadas > 0);
    }

    /** 5: insertar(token_qr_hash, id_docente) en CredencialQR. */
    private Map<String, Object> insertar(String tokenQrHash, Integer idDocente, Integer idProceso,
            TipoCredencial tipo, Integer idMesa, Integer idPersonero, Integer idUsuario) {
        try {
            dao.ejecutar("""
                    INSERT INTO credencial_qr (id_proceso, id_docente, tipo, id_mesa, id_personero,
                                               token_qr_hash, fecha_expiracion, id_usuario_emisor)
                    SELECT ?, ?, ?, ?, ?, ?, p.fecha_fin, ?
                      FROM proceso_electoral p WHERE p.id_proceso = ?
                    """, idProceso, idDocente, tipo.name(), idMesa, idPersonero, tokenQrHash, idUsuario, idProceso);
        } catch (DuplicateKeyException e) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Otra emisión para el mismo titular se registró al mismo tiempo; actualice la lista.");
        }
        // RF56 / RF51: las tablas de la mesa y del personero guardan la huella vigente
        if (tipo == TipoCredencial.MIEMBRO_MESA) {
            dao.ejecutar("UPDATE miembro_mesa SET qr_credencial_hash = ? WHERE id_mesa = ? AND id_docente = ?",
                    tokenQrHash, idMesa, idDocente);
        } else if (tipo == TipoCredencial.PERSONERO) {
            dao.ejecutar("UPDATE personero SET qr_credencial_hash = ? WHERE id_personero = ?",
                    tokenQrHash, idPersonero);
        }
        return dao.consultar("""
                SELECT id_credencial, fecha_emision, fecha_expiracion
                  FROM credencial_qr WHERE token_qr_hash = ?
                """, tokenQrHash).get(0);
    }

    /** 6: renderizarQR(token_hash) — contenido del QR y datos impresos de la credencial (LectorQR la dibuja). */
    private static Map<String, Object> renderizarQR(TokenGenerado generado, Map<String, Object> credencial,
            boolean reemplazo) {
        Map<String, Object> titular = generado.titular();
        Map<String, Object> qr = new LinkedHashMap<>();
        qr.put("idCredencial", credencial.get("idCredencial"));
        qr.put("tipo", generado.tipo().name());
        qr.put("titulo", generado.tipo().titulo());
        qr.put("qr", contenidoQR(generado.tipo(), generado.token()));
        for (String campo : List.of("idTitular", "idDocente", "dni", "nombre", "categoria", "facultad",
                "funcion", "numeroMesa", "ubicacion")) {
            qr.put(campo, titular.get(campo));
        }
        qr.put("fechaEmision", credencial.get("fechaEmision"));
        qr.put("fechaExpiracion", credencial.get("fechaExpiracion"));
        qr.put("reemplazaAnterior", reemplazo);
        return qr;
    }

    static String contenidoQR(TipoCredencial tipo, String token) {
        return PREFIJO_QR + "|" + tipo.letra() + "|" + token;
    }

    /** Revoca a pedido del CEUNP una credencial vigente. */
    @Transactional
    public Map<String, Object> revocar(Long idCredencial, String motivo, Integer idUsuario) {
        List<Map<String, Object>> filas = dao.consultar("""
                SELECT cq.id_proceso, cq.tipo, cq.estado, cq.token_qr_hash,
                       CONCAT(d.apellidos, ', ', d.nombres) AS nombre
                  FROM credencial_qr cq JOIN docente d ON d.id_docente = cq.id_docente
                 WHERE cq.id_credencial = ?
                """, idCredencial);
        if (filas.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "La credencial no existe.");
        }
        Map<String, Object> fila = filas.get(0);
        if (!"VIGENTE".equals(fila.get("estado"))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La credencial ya estaba revocada.");
        }
        dao.ejecutar("""
                UPDATE credencial_qr
                   SET estado = 'REVOCADA', fecha_revocacion = NOW(), motivo_revocacion = ?
                 WHERE id_credencial = ? AND estado = 'VIGENTE'
                """, motivo.trim(), idCredencial);
        limpiarHuella(String.valueOf(fila.get("tokenQrHash")));

        TipoCredencial tipo = TipoCredencial.desdeTexto(String.valueOf(fila.get("tipo")));
        Integer idProceso = entero(fila.get("idProceso"));
        Map<String, Object> detalle = new LinkedHashMap<>();
        detalle.put("id_credencial", idCredencial);
        detalle.put("tipo", tipo.name());
        detalle.put("motivo", motivo.trim());
        bitacora.registrar(idUsuario, idProceso, "REVOCAR_CREDENCIAL", detalle);

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", tipo.titulo() + " de " + fila.get("nombre") + " revocada: el QR ya no es válido.");
        return respuesta;
    }

    /** Revoca la credencial VIGENTE del titular (si la hay) antes de emitir otra. */
    private int revocarVigente(Integer idProceso, TipoCredencial tipo, Integer idDocente, Integer idMesa,
            Integer idPersonero, String motivo) {
        // Misma clave que uq_credencial_vigente: (proceso, docente, tipo, personero | mesa | 0)
        String condicion = " WHERE id_proceso = ? AND id_docente = ? AND tipo = ? AND estado = 'VIGENTE'";
        List<Object> args = new ArrayList<>(List.of(idProceso, idDocente, tipo.name()));
        if (tipo == TipoCredencial.MIEMBRO_MESA) {
            condicion += " AND id_mesa = ?";
            args.add(idMesa);
        } else if (tipo == TipoCredencial.PERSONERO) {
            condicion += " AND id_personero = ?";
            args.add(idPersonero);
        }
        List<Map<String, Object>> vigentes = dao.consultar(
                "SELECT token_qr_hash FROM credencial_qr" + condicion + " FOR UPDATE", args.toArray());
        for (Map<String, Object> vigente : vigentes) {
            limpiarHuella(String.valueOf(vigente.get("tokenQrHash")));
        }
        args.add(0, motivo);
        return dao.ejecutar("UPDATE credencial_qr SET estado = 'REVOCADA', fecha_revocacion = NOW(),"
                + " motivo_revocacion = ?" + condicion, args.toArray());
    }

    private void limpiarHuella(String tokenQrHash) {
        dao.ejecutar("UPDATE miembro_mesa SET qr_credencial_hash = NULL WHERE qr_credencial_hash = ?", tokenQrHash);
        dao.ejecutar("UPDATE personero SET qr_credencial_hash = NULL WHERE qr_credencial_hash = ?", tokenQrHash);
    }

    private static Integer entero(Object valor) {
        return valor == null ? null : ((Number) valor).intValue();
    }
}
