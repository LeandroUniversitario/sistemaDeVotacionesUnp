package pe.unp.elecciones.electoral.resultados;

import java.sql.Types;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import pe.unp.elecciones.auth.Rol;
import pe.unp.elecciones.auth.Usuario;
import pe.unp.elecciones.electoral.service.ProcedimientoDao;

/**
 * CUS17 · «verificarActa» (control). Mensajes 7 a 11 del diagrama de colaboración:
 *
 *   7 escanearQR                → el personero lee el QR (cámara o pistola) o escribe el código o la huella
 *   8 verificarActa()           → sp_verificar_documento
 *   9 consultarPorToken()       → sp_localizar_documento: acta de mesa, acta general, proclamación, nulidad, multas o constancia
 *   10 recalcularHash()         → SHA2(contenido_json, 256) frente a la huella guardada
 *   11 mostrarAutenticidad()    → AUTENTICA, ALTERADA, ANULADA o NO_ENCONTRADA (RF55)
 *
 * <p>Después de verificar, el personero o el docente puede cotejar las cifras de su ejemplar físico
 * con las del documento digital; si no coinciden, la discrepancia queda reportada al CEUNP.
 */
@Service
public class VerificarActa {

    private static final Pattern CODIGO = Pattern.compile("[0-9a-fA-F]{64}");
    private static final List<String> SIN_COTEJO = List.of("CONSTANCIA_VOTO", "RESOLUCION_MULTAS", "RESOLUCION_NULIDAD");
    private static final Map<String, String> ETIQUETA = new LinkedHashMap<>();

    static {
        ETIQUETA.put("total_electores", "Electores de la mesa");
        ETIQUETA.put("electores_habiles", "Electores hábiles");
        ETIQUETA.put("cedulas_recibidas", "Cédulas recibidas");
        ETIQUETA.put("electores_que_votaron", "Electores que votaron");
        ETIQUETA.put("electores_omisos", "Electores que no votaron");
        ETIQUETA.put("cedulas_utilizadas", "Cédulas utilizadas");
        ETIQUETA.put("cedulas_no_utilizadas", "Cédulas no utilizadas");
        ETIQUETA.put("cedulas_contadas", "Cédulas contadas en el ánfora");
        ETIQUETA.put("cedulas_sobrantes_destruidas", "Cédulas sobrantes destruidas");
        ETIQUETA.put("cedulas_faltantes", "Cédulas faltantes");
        ETIQUETA.put("cedulas_escrutadas", "Cédulas escrutadas");
        ETIQUETA.put("actas_verificadas", "Actas verificadas");
    }

    private final ProcedimientoDao dao;
    private final ResultadosConsulta consulta;

    public VerificarActa(ProcedimientoDao dao, ResultadosConsulta consulta) {
        this.dao = dao;
        this.consulta = consulta;
    }

    /** 8-11 verificarActa(): consulta por el token o la huella, recalcula el hash y registra la consulta. */
    public Map<String, Object> verificar(String entrada, String canal, Usuario usuario, String ip) {
        consulta.verificarInstalacion();
        String c = canal == null ? "QR" : canal.trim().toUpperCase();
        ProcedimientoDao.Resultado r = dao.llamar("sp_verificar_documento", ProcedimientoDao.SIN_SALIDA,
                codigo(entrada), ResultadosConsulta.CANALES.contains(c) ? c : "QR",
                usuario == null ? null : usuario.getId(), ip);
        if (r.filas().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "El procedimiento no devolvió resultados.");
        }
        Map<String, Object> fila = new LinkedHashMap<>(r.filas().get(0));
        Object contenido = consulta.leerJson(fila.remove("contenidoJson"));
        String tipo = fila.get("tipoDocumento") == null ? null : String.valueOf(fila.get("tipoDocumento"));
        fila.put("contenido", contenido);
        List<Map<String, Object>> cifras = tipo == null || SIN_COTEJO.contains(tipo) ? List.of() : cifras(contenido);
        fila.put("cifras", cifras);
        fila.put("puedeCotejar", usuario != null && !cifras.isEmpty() && !"NO_ENCONTRADA".equals(fila.get("resultado")));
        fila.put("mensaje", mensaje(fila));
        return fila;
    }

    /** Cotejo del ejemplar físico: compara cada cifra anotada con la del documento digital. */
    public Map<String, Object> cotejar(ResultadosDto.Cotejo datos, Usuario usuario) {
        consulta.verificarInstalacion();
        String codigo = codigo(datos.codigo());
        if (codigo == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "CUS17: el código del documento no es válido.");
        }
        // 9 consultarPorToken() sin registrar otra verificación
        ProcedimientoDao.Resultado ubicado = dao.llamar("sp_localizar_documento",
                new int[] {Types.VARCHAR, Types.INTEGER, Types.VARCHAR}, codigo);
        Object tipo = ubicado.salidas()[0];
        Object id = ubicado.salidas()[1];
        if (tipo == null || id == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "CUS17: el documento no existe o el código no es válido.");
        }
        if (SIN_COTEJO.contains(String.valueOf(tipo))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "CUS17: el cotejo de cifras se hace sobre las actas, el acta general y la resolución de proclamación.");
        }
        List<Map<String, Object>> digitales = cifras(contenido(String.valueOf(tipo), ((Number) id).intValue()));
        if (digitales.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "CUS17: el documento no tiene cifras que cotejar.");
        }
        Map<String, Long> anotadas = new LinkedHashMap<>();
        datos.cifras().forEach(x -> anotadas.put(x.clave(), x.fisico()));
        List<Map<String, Object>> lineas = new ArrayList<>();
        for (Map<String, Object> d : digitales) {
            Long fisico = anotadas.get(String.valueOf(d.get("clave")));
            if (fisico == null) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "CUS17: anote la cifra «" + d.get("etiqueta") + "» de su ejemplar físico.");
            }
            Map<String, Object> l = new LinkedHashMap<>(d);
            l.put("fisico", fisico);
            l.put("coincide", ((Number) d.get("digital")).longValue() == fisico);
            lineas.add(l);
        }
        ProcedimientoDao.Resultado r = dao.llamar("sp_registrar_cotejo_acta", ProcedimientoDao.SIN_SALIDA, codigo,
                datos.idVerificacion(), usuario.getId(), consulta.escribirJson(lineas),
                ResultadosConsulta.vacioANulo(datos.observacion()));
        if (r.filas().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "El procedimiento no devolvió resultados.");
        }
        Map<String, Object> fila = r.filas().get(0);
        long diferencias = ((Number) fila.get("diferencias")).longValue();
        boolean integro = ((Number) fila.get("contenidoIntegro")).intValue() == 1;
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("cotejo", fila);
        respuesta.put("lineas", lineas);
        respuesta.put("mensaje", "CONFORME".equals(fila.get("estado"))
                ? "Cotejo conforme: las " + fila.get("lineas") + " cifras de su ejemplar coinciden con el documento digital."
                : (diferencias > 0 ? diferencias + " de " + fila.get("lineas") + " cifra(s) no coinciden" : "El documento digital no está íntegro")
                        + (integro ? "" : " y su huella no coincide")
                        + ". La discrepancia quedó reportada al CEUNP (cotejo N.º " + fila.get("idCotejo") + ").");
        respuesta.put("cotejos", consulta.cotejos(((Number) fila.get("idProceso")).intValue(), usuario.getId()));
        return respuesta;
    }

    /** El CEUNP atiende la discrepancia reportada. */
    public Map<String, Object> atender(Integer idCotejo, ResultadosDto.Atencion datos, Usuario usuario) {
        consulta.verificarInstalacion();
        if (usuario.getRol() != Rol.CEUNP) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "CUS17: solo el CEUNP atiende las discrepancias reportadas.");
        }
        String decision = datos.decision().trim().toUpperCase();
        if (!ResultadosConsulta.DECISIONES.contains(decision)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "CUS17: indique si la discrepancia queda aclarada o es fundada.");
        }
        List<Map<String, Object>> cotejo = dao.consultar("SELECT id_proceso FROM cotejo_acta WHERE id_cotejo = ?", idCotejo);
        if (cotejo.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "CUS17: el cotejo no existe.");
        }
        dao.llamar("sp_atender_cotejo_acta", ProcedimientoDao.SIN_SALIDA, idCotejo, usuario.getId(), decision, datos.respuesta().trim());
        Integer idProceso = ((Number) cotejo.get(0).get("idProceso")).intValue();
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("mensaje", "Discrepancia del cotejo N.º " + idCotejo + " atendida: "
                + ("FUNDADA".equals(decision)
                        ? "fundada. Revise el acta en el cómputo (CUS14) o, si corresponde, tramite la nulidad (CUS15)."
                        : "aclarada.") + " El usuario verá la respuesta del CEUNP.");
        respuesta.put("cotejos", consulta.cotejos(idProceso, null));
        return respuesta;
    }

    // ─── 9 consultarPorToken() · cifras del documento ───────────────────────

    /** Token del QR o huella: acepta también el enlace completo del QR (toma el último código de 64 caracteres). */
    static String codigo(String entrada) {
        if (entrada == null) {
            return null;
        }
        Matcher m = CODIGO.matcher(entrada.trim());
        String ultimo = null;
        while (m.find()) {
            ultimo = m.group();
        }
        return ultimo == null ? null : ultimo.toLowerCase();
    }

    private Object contenido(String tipo, int id) {
        String sql = switch (tipo) {
            case "COMPUTO_GENERAL" -> "SELECT contenido_json FROM computo_proceso WHERE id_proceso = ?";
            case "PROCLAMACION" -> "SELECT contenido_proclamacion AS contenido_json FROM computo_proceso WHERE id_proceso = ?";
            default -> "SELECT contenido_json FROM acta_electoral WHERE id_acta = ?";
        };
        List<Map<String, Object>> filas = dao.consultar(sql, id);
        return filas.isEmpty() ? null : consulta.leerJson(filas.get(0).get("contenidoJson"));
    }

    /**
     * Cifras que se pueden cotejar con el ejemplar físico: totales del acta y votos por cargo y opción.
     * Reconoce las actas de instalación, sufragio y escrutinio (CUS08, CUS11, CUS12 y el cierre heredado),
     * el acta general de cómputo y la resolución de proclamación (CUS14).
     */
    @SuppressWarnings("unchecked")
    static List<Map<String, Object>> cifras(Object contenido) {
        List<Map<String, Object>> lineas = new ArrayList<>();
        if (!(contenido instanceof Map<?, ?> doc)) {
            return lineas;
        }
        for (Map.Entry<String, String> e : ETIQUETA.entrySet()) {
            if (doc.get(e.getKey()) instanceof Number n) {
                lineas.add(linea(e.getKey(), e.getValue(), "Totales", n));
            }
        }
        if (doc.get("participacion") instanceof Map<?, ?> p) {
            agregar(lineas, "participacion.electores", "Electores hábiles", "Participación", p.get("electores"));
            agregar(lineas, "participacion.votaron", "Electores que votaron", "Participación", p.get("votaron"));
        }
        if (doc.get("mesas") instanceof Map<?, ?> m) {
            agregar(lineas, "mesas.total", "Mesas", "Mesas", m.get("total"));
            agregar(lineas, "mesas.computadas", "Mesas computadas", "Mesas", m.get("computadas"));
        }
        // Acta de escrutinio: CUS12 (opciones con conteo manual) o cierre heredado (lista y votos)
        if (doc.get("resultados") instanceof List<?> resultados) {
            for (Object o : resultados) {
                if (!(o instanceof Map<?, ?> r)) {
                    continue;
                }
                String cargo = String.valueOf(r.get("cargo"));
                if (r.get("opciones") instanceof List<?> opciones) {
                    for (Object x : opciones) {
                        if (x instanceof Map<?, ?> op && !"IMPUGNADO".equals(op.get("opcion"))) {
                            agregar(lineas, "esc|" + cargo + "|" + op.get("opcion") + "|" + op.get("id_lista"),
                                    String.valueOf(op.get("nombre")), cargo, op.get("manual"));
                        }
                    }
                    agregar(lineas, "esc|" + cargo + "|IMPUGNADO", "Votos impugnados", cargo, r.get("impugnados"));
                } else {
                    agregar(lineas, "esc|" + cargo + "|" + r.get("lista"), String.valueOf(r.get("lista")), cargo, r.get("votos"));
                }
            }
        }
        // Acta general de cómputo
        if (doc.get("cargos") instanceof List<?> cargos) {
            for (Object o : cargos) {
                if (!(o instanceof Map<?, ?> c)) {
                    continue;
                }
                String cargo = String.valueOf(c.get("cargo"));
                if (c.get("opciones") instanceof List<?> opciones) {
                    for (Object x : opciones) {
                        if (x instanceof Map<?, ?> op) {
                            agregar(lineas, "cmp|" + cargo + "|" + op.get("id_lista"), String.valueOf(op.get("lista")), cargo, op.get("votos"));
                        }
                    }
                }
                agregar(lineas, "cmp|" + cargo + "|BLANCO", "Votos en blanco", cargo, c.get("blancos"));
                agregar(lineas, "cmp|" + cargo + "|NULO", "Votos nulos", cargo, c.get("nulos"));
            }
        }
        // Resolución de proclamación
        if (doc.get("proclamados") instanceof List<?> proclamados) {
            for (Object o : proclamados) {
                if (o instanceof Map<?, ?> p) {
                    agregar(lineas, "pro|" + p.get("cargo") + "|" + p.get("id_lista"),
                            "Votos de " + p.get("lista"), String.valueOf(p.get("cargo")), p.get("votos"));
                }
            }
        }
        return lineas;
    }

    private static void agregar(List<Map<String, Object>> lineas, String clave, String etiqueta, String grupo, Object valor) {
        if (valor instanceof Number n) {
            lineas.add(linea(clave, etiqueta, grupo, n));
        }
    }

    private static Map<String, Object> linea(String clave, String etiqueta, String grupo, Number valor) {
        Map<String, Object> l = new LinkedHashMap<>();
        l.put("clave", clave);
        l.put("grupo", grupo);
        l.put("etiqueta", etiqueta);
        l.put("digital", valor.longValue());
        return l;
    }

    private static String mensaje(Map<String, Object> f) {
        return switch (String.valueOf(f.get("resultado"))) {
            case "AUTENTICA" -> "Documento auténtico: la huella SHA-256 recalculada coincide con la registrada al emitirlo.";
            case "ALTERADA" -> "ALERTA: el contenido del documento no coincide con su huella SHA-256. Repórtelo al CEUNP.";
            case "ANULADA" -> "El documento es íntegro, pero ya no tiene efecto (mesa anulada, acta anulada o constancia revocada o vencida).";
            default -> "No existe un documento con ese código. Revise que el QR o la huella estén completos.";
        };
    }
}
