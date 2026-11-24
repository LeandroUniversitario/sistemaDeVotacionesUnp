-- =====================================================================
-- 16_correcciones_recorrido_24_11.sql
-- Correcciones del segundo recorrido completo (24/11/2026). No borra registros.
--   * RF76: cuadre de cédulas en el acta de sufragio (hallazgo N6).
--   * Catálogo de la bitácora: acciones de regeneración de QR y de votos estudiantiles (N14).
-- Uso: después de 15_ponderacion_tercios_ley30220.sql
--   mysql -u root elecciones_unp < base-de-datos/16_correcciones_recorrido_24_11.sql
-- =====================================================================
USE elecciones_unp;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

INSERT IGNORE INTO bitacora_accion (codigo, etiqueta, descripcion, modulo, caso_uso, criticidad, orden) VALUES
  ('SOLICITAR_REGENERACION_QR',      'Regeneración de QR solicitada',         'Un docente pidió al CEUNP un nuevo código QR para su credencial.', 'PREPARACION', 'CUS07', 'MEDIA', 262),
  ('APROBAR_REGENERACION_QR',        'Regeneración de QR aprobada',           'El CEUNP aprobó la solicitud y emitió un nuevo QR.', 'PREPARACION', 'CUS07', 'ALTA', 263),
  ('RECHAZAR_REGENERACION_QR',       'Regeneración de QR rechazada',          'El CEUNP rechazó la solicitud de un nuevo QR.', 'PREPARACION', 'CUS07', 'MEDIA', 264),
  ('REGISTRAR_VOTOS_ESTUDIANTILES',  'Votos estudiantiles registrados',       'El CEUNP registró o cambió los votos del estamento estudiantil de una lista (Art. 66 Ley 30220).', 'RESULTADOS', 'CUS14', 'ALTA', 735);

DELIMITER $$
DROP PROCEDURE IF EXISTS sp_generar_acta_sufragio$$
CREATE PROCEDURE sp_generar_acta_sufragio(
  IN p_id_mesa               INT,
  IN p_id_usuario            INT,
  IN p_cedulas_no_utilizadas INT,
  IN p_firmas_lista_fisica   INT,
  IN p_observaciones         VARCHAR(1000),
  IN p_personeros            LONGTEXT
)
BEGIN
  DECLARE v_proceso    INT DEFAULT NULL;
  DECLARE v_nombre     VARCHAR(200);
  DECLARE v_numero     VARCHAR(30);
  DECLARE v_ubic       VARCHAR(200);
  DECLARE v_hora_inst  DATETIME;
  DECLARE v_cierre     VARCHAR(20) DEFAULT NULL;
  DECLARE v_hora       DATETIME;
  DECLARE v_anticipado INT;
  DECLARE v_electores  INT;
  DECLARE v_votaron    INT;
  DECLARE v_no_votaron INT;
  DECLARE v_sin_votar  INT;
  DECLARE v_cedulas    INT;
  DECLARE v_obs        VARCHAR(1000);
  DECLARE v_personeros LONGTEXT;
  DECLARE v_n          INT DEFAULT 0;
  DECLARE v_validos    INT DEFAULT 0;
  DECLARE v_no_voto    LONGTEXT;
  DECLARE v_miembros   LONGTEXT;
  DECLARE v_contenido  LONGTEXT;
  DECLARE v_token      CHAR(64);
  DECLARE v_id_acta    INT;
  DECLARE v_hash       CHAR(64);
  DECLARE v_ahora      DATETIME;
  DECLARE v_msg        VARCHAR(255);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET SESSION group_concat_max_len = 1000000;
  START TRANSACTION;

  SELECT m.id_proceso, p.nombre, m.numero_mesa, m.ubicacion, m.hora_instalacion,
         c.estado, c.hora_cierre, c.cierre_anticipado, c.total_electores, c.total_votaron,
         c.total_no_votaron, c.asistieron_sin_votar, c.cedulas_recibidas
    INTO v_proceso, v_nombre, v_numero, v_ubic, v_hora_inst,
         v_cierre, v_hora, v_anticipado, v_electores, v_votaron,
         v_no_votaron, v_sin_votar, v_cedulas
    FROM mesa_electoral m
    JOIN proceso_electoral p ON p.id_proceso = m.id_proceso
    LEFT JOIN cierre_mesa c  ON c.id_mesa = m.id_mesa
   WHERE m.id_mesa = p_id_mesa
     FOR UPDATE;

  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no existe.';
  END IF;
  IF v_cierre IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cierre primero el sufragio de la mesa.';
  END IF;
  IF v_cierre = 'ACTA_EMITIDA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN28: el acta de sufragio de esta mesa ya fue emitida.';
  END IF;
  IF v_cierre <> 'AUSENTES_MARCADOS' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF75: marque primero NO VOTO a los electores que no votaron.';
  END IF;

  -- 9: ingresarObservaciones(cedulas_no_usadas, observaciones)
  IF p_cedulas_no_utilizadas IS NULL OR p_cedulas_no_utilizadas < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF76: indique la cantidad de cédulas no utilizadas.';
  END IF;
  IF v_cedulas IS NOT NULL AND p_cedulas_no_utilizadas > v_cedulas THEN
    SET v_msg = CONCAT('RF76: las cédulas no utilizadas (', p_cedulas_no_utilizadas,
                       ') no pueden superar las recibidas en la instalación (', v_cedulas, ').');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  IF p_firmas_lista_fisica IS NOT NULL AND p_firmas_lista_fisica < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El conteo de firmas de la lista física no puede ser negativo.';
  END IF;
  SET v_obs = NULLIF(TRIM(p_observaciones), '');
  -- RF76 (cuadre): votantes + cédulas no utilizadas deben sumar las cédulas recibidas en la instalación;
  -- si no cuadran, la diferencia se explica en las observaciones del acta.
  IF v_cedulas IS NOT NULL AND v_votaron + p_cedulas_no_utilizadas <> v_cedulas AND v_obs IS NULL THEN
    SET v_msg = CONCAT('RF76: ', v_votaron, ' votantes más ', p_cedulas_no_utilizadas, ' cédulas no utilizadas suman ',
                       v_votaron + p_cedulas_no_utilizadas, ' y se recibieron ', v_cedulas,
                       ' cédulas. Corrija la cantidad o explique la diferencia en las observaciones.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  -- A2: el total del sistema difiere del conteo de firmas en la lista física
  IF p_firmas_lista_fisica IS NOT NULL AND p_firmas_lista_fisica <> v_votaron AND v_obs IS NULL THEN
    SET v_msg = CONCAT('A2: la lista física tiene ', p_firmas_lista_fisica, ' firmas y el sistema registra ',
                       v_votaron, ' votantes. Registre la observación.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  -- Personeros que firman: deben estar presentes en la mesa (CUS08)
  SET v_personeros = IF(p_personeros IS NULL OR TRIM(p_personeros) = '', '[]', p_personeros);
  IF JSON_VALID(v_personeros) = 0 OR JSON_TYPE(v_personeros) <> 'ARRAY' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lista de personeros firmantes no válida.';
  END IF;
  SET v_n = JSON_LENGTH(v_personeros);
  SELECT COUNT(*) INTO v_validos
    FROM asistencia_personero_mesa ap
   WHERE ap.id_mesa = p_id_mesa AND JSON_CONTAINS(v_personeros, CAST(ap.id_personero AS CHAR));
  IF v_validos <> v_n THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo firman el acta los personeros presentes en la mesa.';
  END IF;

  -- Firman el presidente y el secretario en funciones
  SELECT COUNT(*) INTO v_n FROM (
    SELECT rol_instalacion AS cargo FROM miembro_mesa
     WHERE id_mesa = p_id_mesa AND rol_instalacion IN ('PRESIDENTE', 'SECRETARIO')
    UNION
    SELECT cargo FROM reemplazo_mesa WHERE id_mesa = p_id_mesa AND cargo IN ('PRESIDENTE', 'SECRETARIO')) f;
  IF v_n < 2 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no registra presidente y secretario en funciones (CUS08).';
  END IF;

  -- RF75: lista de electores con la marca NO VOTÓ
  SELECT CONCAT('[', GROUP_CONCAT(
           JSON_OBJECT('dni', x.dni, 'docente', x.docente, 'asistio', x.asistio)
           ORDER BY x.docente SEPARATOR ','), ']')
    INTO v_no_voto
    FROM (SELECT d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS docente,
                 (a.id_asistencia IS NOT NULL) AS asistio
            FROM padron_electoral pe
            JOIN docente d ON d.id_docente = pe.id_docente
            LEFT JOIN asistencia_elector a ON a.id_proceso = pe.id_proceso AND a.id_docente = pe.id_docente
           WHERE pe.id_mesa = p_id_mesa AND pe.no_voto = 1
           GROUP BY d.dni, d.apellidos, d.nombres, a.id_asistencia) x;

  SELECT CONCAT('[', GROUP_CONCAT(
           JSON_OBJECT('dni', f.dni, 'docente', f.docente, 'cargo', f.cargo, 'origen', f.origen)
           ORDER BY FIELD(f.cargo, 'PRESIDENTE', 'SECRETARIO', 'VOCAL') SEPARATOR ','), ']')
    INTO v_miembros
    FROM (SELECT d.dni, CONCAT(d.apellidos, ', ', d.nombres) AS docente, CONCAT(mm.rol_instalacion, '') AS cargo,
                 IF(mm.titular = 1, 'TITULAR', 'SUPLENTE') AS origen
            FROM miembro_mesa mm JOIN docente d ON d.id_docente = mm.id_docente
           WHERE mm.id_mesa = p_id_mesa AND mm.rol_instalacion IS NOT NULL
          UNION ALL
          SELECT d.dni, CONCAT(d.apellidos, ', ', d.nombres), CONCAT(r.cargo, ''), 'REEMPLAZANTE'
            FROM reemplazo_mesa r JOIN docente d ON d.id_docente = r.id_docente
           WHERE r.id_mesa = p_id_mesa) f;

  -- 10: generarActa(datos). RF76: votantes, cédulas no utilizadas, hora de cierre y observaciones
  SET v_ahora = NOW();
  SET v_contenido = CONCAT(
      '{"tipo":"SUFRAGIO"',
      ',"id_proceso":', v_proceso,
      ',"proceso":', JSON_QUOTE(v_nombre),
      ',"mesa":', JSON_QUOTE(v_numero),
      ',"ubicacion":', JSON_QUOTE(v_ubic),
      ',"hora_instalacion":', IF(v_hora_inst IS NULL, 'null', JSON_QUOTE(DATE_FORMAT(v_hora_inst, '%Y-%m-%d %H:%i:%s'))),
      ',"hora_cierre":', JSON_QUOTE(DATE_FORMAT(v_hora, '%Y-%m-%d %H:%i:%s')),
      ',"cierre_anticipado":', IF(v_anticipado = 1, 'true', 'false'),
      ',"total_electores":', v_electores,
      ',"electores_que_votaron":', v_votaron,
      ',"electores_que_no_votaron":', v_no_votaron,
      ',"asistieron_sin_votar":', v_sin_votar,
      ',"cedulas_recibidas":', IF(v_cedulas IS NULL, 'null', v_cedulas),
      ',"cedulas_no_utilizadas":', p_cedulas_no_utilizadas,
      ',"firmas_lista_fisica":', IF(p_firmas_lista_fisica IS NULL, 'null', p_firmas_lista_fisica),
      ',"diferencia_lista_fisica":', IF(p_firmas_lista_fisica IS NULL, 'null', p_firmas_lista_fisica - v_votaron),
      ',"miembros":', COALESCE(v_miembros, '[]'),
      ',"no_votaron":', COALESCE(v_no_voto, '[]'),
      ',"observaciones":', IF(v_obs IS NULL, 'null', JSON_QUOTE(v_obs)),
      '}');

  -- 11: insertarActa('SUFRAGIO', hash, contenido)
  CALL sp_emitir_acta(p_id_mesa, 'SUFRAGIO', v_contenido, v_token);
  SELECT id_acta, hash_integridad INTO v_id_acta, v_hash
    FROM acta_electoral WHERE id_mesa = p_id_mesa AND tipo = 'SUFRAGIO';

  -- 12: registrarFirmas(firmas): presidente y secretario en funciones, y personeros que lo desean
  INSERT INTO firma_acta (id_acta, id_docente, rol, firma_digital, fecha_firma)
  SELECT v_id_acta, mm.id_docente,
         CONCAT(mm.rol_instalacion, ' DE MESA', IF(mm.titular = 1, '', ' (SUPLENTE)')),
         SHA2(CONCAT(v_hash, '|', d.dni, '|', mm.rol_instalacion), 256), v_ahora
    FROM miembro_mesa mm JOIN docente d ON d.id_docente = mm.id_docente
   WHERE mm.id_mesa = p_id_mesa AND mm.rol_instalacion IN ('PRESIDENTE', 'SECRETARIO');

  INSERT INTO firma_acta (id_acta, id_docente, rol, firma_digital, fecha_firma)
  SELECT v_id_acta, r.id_docente, CONCAT(r.cargo, ' DE MESA (REEMPLAZANTE)'),
         SHA2(CONCAT(v_hash, '|', d.dni, '|', r.cargo), 256), v_ahora
    FROM reemplazo_mesa r JOIN docente d ON d.id_docente = r.id_docente
   WHERE r.id_mesa = p_id_mesa AND r.cargo IN ('PRESIDENTE', 'SECRETARIO');

  INSERT IGNORE INTO firma_acta (id_acta, id_docente, rol, firma_digital, fecha_firma)
  SELECT v_id_acta, pe.id_docente, LEFT(CONCAT('PERSONERO ', pe.tipo, ' - ', l.nombre), 80),
         SHA2(CONCAT(v_hash, '|', d.dni, '|PERSONERO'), 256), v_ahora
    FROM asistencia_personero_mesa ap
    JOIN personero pe      ON pe.id_personero = ap.id_personero
    JOIN lista_electoral l ON l.id_lista = pe.id_lista
    JOIN docente d         ON d.id_docente = pe.id_docente
   WHERE ap.id_mesa = p_id_mesa AND JSON_CONTAINS(v_personeros, CAST(ap.id_personero AS CHAR));

  UPDATE cierre_mesa
     SET estado = 'ACTA_EMITIDA', cedulas_no_utilizadas = p_cedulas_no_utilizadas,
         firmas_lista_fisica = p_firmas_lista_fisica, observaciones = v_obs, id_acta = v_id_acta,
         fecha_acta = v_ahora, id_usuario_acta = p_id_usuario
   WHERE id_mesa = p_id_mesa;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'EMITIR_ACTA_SUFRAGIO',
       JSON_OBJECT('id_mesa', p_id_mesa, 'id_acta', v_id_acta, 'votaron', v_votaron));
  COMMIT;

  -- 13: mostrarActaSufragio()
  SELECT p_id_mesa AS id_mesa, v_id_acta AS id_acta, 'SUFRAGIO' AS acta, v_token AS token_qr;
END$$
DELIMITER ;
