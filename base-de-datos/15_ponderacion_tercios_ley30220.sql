-- =====================================================================
-- Migración: Ponderación Estamentaria por Tercios (Art. 66 y 71 Ley 30220)
-- Docentes: 2/3 (66.67%) | Estudiantes: 1/3 (33.33%)
-- CUS14 · Computar y proclamar resultados
-- =====================================================================

USE elecciones_unp;
-- Misma collation que el resto de la base; si no, el SP falla con "Illegal mix of collations".
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 0. Columnas del desglose estamentario en resultado_electoral
--    (las usan sp_ejecutar_computo y ComputoConsulta.java)
ALTER TABLE resultado_electoral
  ADD COLUMN IF NOT EXISTS votos_docentes    INT          NULL AFTER total_votos,
  ADD COLUMN IF NOT EXISTS votos_estudiantes INT          NULL AFTER votos_docentes,
  ADD COLUMN IF NOT EXISTS pct_docente       DECIMAL(5,2) NULL AFTER porcentaje_validos,
  ADD COLUMN IF NOT EXISTS pct_estudiante    DECIMAL(5,2) NULL AFTER pct_docente,
  ADD COLUMN IF NOT EXISTS pct_ponderado     DECIMAL(5,2) NULL AFTER pct_estudiante;

-- 1. Tabla para registrar los votos válidos del estamento estudiantil por lista
CREATE TABLE IF NOT EXISTS computo_estudiantil (
  id_proceso INT NOT NULL,
  id_cargo INT NOT NULL,
  id_lista INT NOT NULL,
  votos_estudiantes INT NOT NULL DEFAULT 0,
  fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_usuario INT NOT NULL,
  PRIMARY KEY (id_proceso, id_cargo, id_lista),
  CONSTRAINT fk_comp_est_proceso FOREIGN KEY (id_proceso) REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_comp_est_cargo FOREIGN KEY (id_cargo) REFERENCES cargo_electoral(id_cargo),
  CONSTRAINT fk_comp_est_lista FOREIGN KEY (id_lista) REFERENCES lista_electoral(id_lista),
  CONSTRAINT fk_comp_est_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Procedimiento para registrar o actualizar los votos de estudiantes
DELIMITER $$

DROP PROCEDURE IF EXISTS sp_registrar_votos_estudiantiles$$
CREATE PROCEDURE sp_registrar_votos_estudiantiles(
  IN p_id_proceso INT,
  IN p_id_cargo INT,
  IN p_id_lista INT,
  IN p_votos_estudiantes INT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_estado VARCHAR(20);
  
  SELECT estado INTO v_estado FROM proceso_electoral WHERE id_proceso = p_id_proceso;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;
  IF v_estado IN ('FINALIZADO', 'ANULADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: no se pueden modificar votos tras el cierre definitivo.';
  END IF;
  IF p_votos_estudiantes IS NULL OR p_votos_estudiantes < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cantidad de votos estudiantiles no puede ser negativa.';
  END IF;
  -- Solo listas ADMITIDAS del cargo y del proceso (una lista TACHADA o EXCLUIDA no recibe votos).
  IF NOT EXISTS (SELECT 1 FROM lista_electoral l JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                  WHERE l.id_lista = p_id_lista AND l.id_cargo = p_id_cargo
                    AND c.id_proceso = p_id_proceso AND l.estado = 'ADMITIDA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se registran votos estudiantiles para listas ADMITIDAS del cargo.';
  END IF;

  INSERT INTO computo_estudiantil (id_proceso, id_cargo, id_lista, votos_estudiantes, fecha_registro, id_usuario)
  VALUES (p_id_proceso, p_id_cargo, p_id_lista, p_votos_estudiantes, NOW(), p_id_usuario)
  ON DUPLICATE KEY UPDATE
    votos_estudiantes = VALUES(votos_estudiantes),
    fecha_registro = VALUES(fecha_registro),
    id_usuario = VALUES(id_usuario);

  -- Queda en la bitácora quién registró o cambió la cifra (CUS19).
  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'REGISTRAR_VOTOS_ESTUDIANTILES',
       JSON_OBJECT('id_cargo', p_id_cargo, 'id_lista', p_id_lista, 'votos_estudiantes', p_votos_estudiantes));
END$$

DROP PROCEDURE IF EXISTS sp_obtener_votos_estudiantiles$$
CREATE PROCEDURE sp_obtener_votos_estudiantiles(
  IN p_id_proceso INT
)
BEGIN
  SELECT ce.id_proceso, ce.id_cargo, ce.id_lista, l.nombre AS lista, ce.votos_estudiantes, ce.fecha_registro
    FROM computo_estudiantil ce
    JOIN lista_electoral l ON l.id_lista = ce.id_lista
   WHERE ce.id_proceso = p_id_proceso
   ORDER BY ce.id_cargo, l.orden_cedula;
END$$

-- 3. Procedimiento principal de cómputo actualizado con ponderación legal por tercios
DROP PROCEDURE IF EXISTS sp_ejecutar_computo$$
CREATE PROCEDURE sp_ejecutar_computo(
  IN p_id_proceso INT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_estado    VARCHAR(20) DEFAULT NULL;
  DECLARE v_tipo      VARCHAR(20);
  DECLARE v_nombre    VARCHAR(200);
  DECLARE v_quorum    DECIMAL(5,2);
  DECLARE v_comp      VARCHAR(20) DEFAULT NULL;
  DECLARE v_lugar     VARCHAR(200);
  DECLARE v_miembros  INT;
  DECLARE v_sesion    DATETIME;
  DECLARE v_fin       INT DEFAULT 0;
  DECLARE v_cargo     INT;
  DECLARE v_pct_min   DECIMAL(5,2);
  DECLARE v_hab       INT DEFAULT 0;
  DECLARE v_vot       INT DEFAULT 0;
  DECLARE v_validos   INT DEFAULT 0;
  DECLARE v_top_pct   DECIMAL(5,2) DEFAULT 0;
  DECLARE v_empate    INT DEFAULT 0;
  DECLARE v_ganadora  INT DEFAULT NULL;
  DECLARE v_result    VARCHAR(20);
  DECLARE v_n         INT DEFAULT 0;
  DECLARE v_txt       VARCHAR(200);
  DECLARE v_msg       VARCHAR(255);
  DECLARE v_mesas     INT DEFAULT 0;
  DECLARE v_computadas INT DEFAULT 0;
  DECLARE v_no_inst   INT DEFAULT 0;
  DECLARE v_anuladas  INT DEFAULT 0;
  DECLARE v_actas     INT DEFAULT 0;
  DECLARE v_dudosas   INT DEFAULT 0;
  DECLARE v_p_hab     INT DEFAULT 0;
  DECLARE v_p_vot     INT DEFAULT 0;
  DECLARE v_p_pct     DECIMAL(5,2) DEFAULT 0;
  DECLARE v_con_q     INT DEFAULT 0;
  DECLARE v_resultado VARCHAR(15);
  DECLARE v_ahora     DATETIME;
  DECLARE v_cargos    LONGTEXT;
  DECLARE v_det_mesas LONGTEXT;
  DECLARE v_pers      LONGTEXT;
  DECLARE v_contenido LONGTEXT;
  DECLARE v_token     CHAR(64);
  DECLARE cur_cargos CURSOR FOR
    SELECT id_cargo, porcentaje_minimo_victoria
      FROM cargo_electoral WHERE id_proceso = p_id_proceso ORDER BY id_cargo;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = 1;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET SESSION group_concat_max_len = 4000000;
  CREATE TEMPORARY TABLE IF NOT EXISTS tmp_computo_cus14 (
    id_cargo INT NOT NULL, opcion VARCHAR(12) NOT NULL, id_lista INT NULL, votos INT NOT NULL,
    clave INT NOT NULL, PRIMARY KEY (id_cargo, opcion, clave)) ENGINE=MEMORY;
  DELETE FROM tmp_computo_cus14;

  START TRANSACTION;

  SELECT estado, tipo, nombre, quorum_minimo INTO v_estado, v_tipo, v_nombre, v_quorum
    FROM proceso_electoral WHERE id_proceso = p_id_proceso FOR UPDATE;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;
  SELECT estado, lugar_sesion, miembros_ceunp, fecha_sesion INTO v_comp, v_lugar, v_miembros, v_sesion
    FROM computo_proceso WHERE id_proceso = p_id_proceso FOR UPDATE;
  IF v_comp IS NOT NULL AND v_comp <> 'SESION_INSTALADA'
     OR EXISTS (SELECT 1 FROM resultado_electoral WHERE id_proceso = p_id_proceso) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el cómputo ya fue realizado y es irreversible.';
  END IF;
  IF v_estado <> 'CERRADO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN32: el cómputo requiere la votación del proceso concluida (CERRADO).';
  END IF;
  IF v_comp IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF91: instale primero la sesión de cómputo general.';
  END IF;

  -- 2-3: verificarActasEntregadas(idProceso) -> actasEntregadas(totalMesas)
  SELECT COUNT(*), MIN(CONCAT('mesa ', numero_mesa, ': ', REPLACE(LOWER(situacion), '_', ' ')))
    INTO v_n, v_txt
    FROM v_computo_mesas
   WHERE id_proceso = p_id_proceso AND situacion NOT IN ('HABILITADA','NO_INSTALADA','ANULADA');
  IF v_n > 0 THEN
    SET v_msg = CONCAT('RN32: ', v_n, ' mesa(s) impiden el cómputo (', v_txt, '). Revise la verificación previa.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  SELECT COUNT(*), COALESCE(SUM(situacion = 'HABILITADA'), 0), COALESCE(SUM(situacion = 'NO_INSTALADA'), 0),
         COALESCE(SUM(situacion = 'ANULADA'), 0)
    INTO v_mesas, v_computadas, v_no_inst, v_anuladas
    FROM v_computo_mesas WHERE id_proceso = p_id_proceso;

  -- 4-5: validarIntegridad(actas) -> actasValidas(hashCorrecto)
  SELECT COUNT(*), COALESCE(SUM(integra = 0), 0), COALESCE(SUM(dudosa), 0) INTO v_actas, v_n, v_dudosas
    FROM v_computo_actas WHERE id_proceso = p_id_proceso AND estado = 'VIGENTE';
  IF v_n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: hay actas cuya huella SHA-256 no coincide con su contenido.';
  END IF;

  -- 6-7: consolidarVotos(idCargo) -> totalesPorLista(votos)
  INSERT INTO tmp_computo_cus14 (id_cargo, opcion, id_lista, votos, clave)
  SELECT id_cargo, opcion, id_lista, votos, COALESCE(id_lista, 0)
    FROM v_computo_resultados WHERE id_proceso = p_id_proceso;
  IF EXISTS (SELECT 1 FROM tmp_computo_cus14 WHERE opcion = 'IMPUGNADO' AND votos > 0) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS13: hay cédulas impugnadas sin opción asignada.';
  END IF;

  -- 12-13: [quorum > 60%] registrarComputo(totales) con ponderación legal Art. 66 Ley 30220
  INSERT INTO resultado_electoral (id_proceso, id_cargo, id_lista, tipo_voto, total_votos, votos_docentes, votos_estudiantes, porcentaje_validos, pct_docente, pct_estudiante, pct_ponderado, posicion)
  SELECT 
    sub.id_proceso,
    sub.id_cargo,
    sub.id_lista,
    'VALIDO',
    sub.n_doc AS total_votos,   -- votos reales de las mesas (docentes); los estudiantiles van aparte
    sub.n_doc AS votos_docentes,
    sub.n_est AS votos_estudiantes,
    sub.pct_pond AS porcentaje_validos,
    sub.pct_doc AS pct_docente,
    sub.pct_est AS pct_estudiante,
    sub.pct_pond AS pct_ponderado,
    RANK() OVER (PARTITION BY sub.id_cargo ORDER BY sub.pct_pond DESC, sub.n_doc DESC, sub.n_est DESC) AS posicion
  FROM (
    SELECT 
      c.id_proceso, 
      c.id_cargo, 
      l.id_lista,
      COALESCE(t.votos, 0) AS n_doc,
      COALESCE(ce.votos_estudiantes, 0) AS n_est,
      CASE 
        WHEN SUM(COALESCE(t.votos, 0)) OVER (PARTITION BY c.id_cargo) = 0 THEN 0.00
        ELSE ROUND(COALESCE(t.votos, 0) * 100.0 / SUM(COALESCE(t.votos, 0)) OVER (PARTITION BY c.id_cargo), 2)
      END AS pct_doc,
      CASE 
        WHEN SUM(COALESCE(ce.votos_estudiantes, 0)) OVER (PARTITION BY c.id_cargo) = 0 THEN 0.00
        ELSE ROUND(COALESCE(ce.votos_estudiantes, 0) * 100.0 / SUM(COALESCE(ce.votos_estudiantes, 0)) OVER (PARTITION BY c.id_cargo), 2)
      END AS pct_est,
      CASE
        WHEN SUM(COALESCE(ce.votos_estudiantes, 0)) OVER (PARTITION BY c.id_cargo) > 0 THEN
          ROUND(
            (CASE 
               WHEN SUM(COALESCE(t.votos, 0)) OVER (PARTITION BY c.id_cargo) = 0 THEN 0.00
               ELSE (COALESCE(t.votos, 0) * 100.0 / SUM(COALESCE(t.votos, 0)) OVER (PARTITION BY c.id_cargo))
             END * (2.0 / 3.0)) +
            (CASE 
               WHEN SUM(COALESCE(ce.votos_estudiantes, 0)) OVER (PARTITION BY c.id_cargo) = 0 THEN 0.00
               ELSE (COALESCE(ce.votos_estudiantes, 0) * 100.0 / SUM(COALESCE(ce.votos_estudiantes, 0)) OVER (PARTITION BY c.id_cargo))
             END * (1.0 / 3.0)),
            2
          )
        ELSE
          CASE 
            WHEN SUM(COALESCE(t.votos, 0)) OVER (PARTITION BY c.id_cargo) = 0 THEN 0.00
            ELSE ROUND(COALESCE(t.votos, 0) * 100.0 / SUM(COALESCE(t.votos, 0)) OVER (PARTITION BY c.id_cargo), 2)
          END
      END AS pct_pond
    FROM cargo_electoral c
    JOIN lista_electoral l ON l.id_cargo = c.id_cargo AND l.estado = 'ADMITIDA'
    LEFT JOIN tmp_computo_cus14 t ON t.id_cargo = c.id_cargo AND t.opcion = 'LISTA' AND t.clave = l.id_lista
    LEFT JOIN computo_estudiantil ce ON ce.id_cargo = c.id_cargo AND ce.id_lista = l.id_lista AND ce.id_proceso = p_id_proceso
    WHERE c.id_proceso = p_id_proceso
  ) sub;

  INSERT INTO resultado_electoral (id_proceso, id_cargo, id_lista, tipo_voto, total_votos, votos_docentes, votos_estudiantes)
  SELECT c.id_proceso, c.id_cargo, NULL, o.opcion, COALESCE(t.votos, 0), COALESCE(t.votos, 0), 0
    FROM cargo_electoral c
    CROSS JOIN (SELECT 'BLANCO' AS opcion UNION ALL SELECT 'NULO') o
    LEFT JOIN tmp_computo_cus14 t ON t.id_cargo = c.id_cargo AND t.opcion = o.opcion AND t.clave = 0
   WHERE c.id_proceso = p_id_proceso;

  -- 8-11 y 14-15: calcularParticipacion -> validarQuorum -> determinarGanador -> ganadorOSegundaVuelta
  SET v_fin = 0;
  OPEN cur_cargos;
  bucle: LOOP
    FETCH cur_cargos INTO v_cargo, v_pct_min;
    IF v_fin = 1 THEN
      LEAVE bucle;
    END IF;

    SELECT COUNT(*), COALESCE(SUM(ya_voto), 0) INTO v_hab, v_vot
      FROM padron_electoral WHERE id_cargo = v_cargo AND habilitado_para_votar = 1;
    SELECT COALESCE(SUM(total_votos), 0), COALESCE(MAX(pct_ponderado), 0) INTO v_validos, v_top_pct
      FROM resultado_electoral WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO';
    SELECT COUNT(*), MIN(id_lista) INTO v_empate, v_ganadora
      FROM resultado_electoral
     WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO' AND pct_ponderado = v_top_pct;

    IF v_hab = 0 OR (v_vot * 100 / v_hab) <= v_quorum THEN
      SET v_result = 'SIN_QUORUM';
    ELSEIF v_validos = 0 THEN
      SET v_result = 'DESIERTO';
    ELSEIF v_tipo = 'SEGUNDA_VUELTA' THEN
      SET v_result = IF(v_empate = 1 AND v_top_pct > 50.00, 'ELEGIDO', 'EMPATE');
    ELSEIF v_empate = 1 AND v_top_pct > v_pct_min THEN
      SET v_result = 'ELEGIDO';
    ELSE
      SET v_result = 'SEGUNDA_VUELTA';
    END IF;

    UPDATE cargo_electoral
       SET estado_resultado  = v_result,
           id_lista_ganadora = IF(v_result = 'ELEGIDO', v_ganadora, NULL)
     WHERE id_cargo = v_cargo;
    SET v_fin = 0;
  END LOOP;
  CLOSE cur_cargos;

  SELECT COUNT(*) INTO v_con_q FROM cargo_electoral
   WHERE id_proceso = p_id_proceso AND estado_resultado <> 'SIN_QUORUM';
  SELECT electores_habiles, votaron, participacion_pct INTO v_p_hab, v_p_vot, v_p_pct
    FROM v_quorum_proceso WHERE id_proceso = p_id_proceso;

  -- 8: [participacion <= 60%] anularProceso(motivo) (A1)
  IF v_con_q = 0 THEN
    SET v_resultado = 'NULIDAD_TOTAL';
    UPDATE proceso_electoral
       SET estado = 'ANULADO',
           motivo_anulacion = CONCAT('RN31: la participación (', v_p_pct, ' %) no superó el quórum mínimo de ',
                                     v_quorum, ' %. Nulidad total de la elección (RN34).')
     WHERE id_proceso = p_id_proceso;
  ELSE
    SET v_resultado = 'VALIDA';
    UPDATE proceso_electoral SET estado = 'FINALIZADO' WHERE id_proceso = p_id_proceso;
  END IF;

  -- 12: emitirActaGeneral(totales): acta general de sufragios con desglose estamentario (RF92)
  SELECT CONCAT('[', GROUP_CONCAT(z.j ORDER BY z.id_cargo SEPARATOR ','), ']') INTO v_cargos
    FROM (SELECT c.id_cargo,
                 CONCAT('{"id_cargo":', c.id_cargo,
                        ',"cargo":', JSON_QUOTE(c.nombre),
                        ',"electores":', pc.electores_habiles,
                        ',"votaron":', pc.votaron,
                        ',"participacion":', pc.participacion_pct,
                        ',"alcanza_quorum":', IF(pc.alcanza_quorum = 1, 'true', 'false'),
                        ',"porcentaje_minimo":', c.porcentaje_minimo_victoria,
                        ',"validos":', (SELECT COALESCE(SUM(r.total_votos), 0) FROM resultado_electoral r
                                         WHERE r.id_cargo = c.id_cargo AND r.tipo_voto = 'VALIDO'),
                        ',"validos_estudiantes":', (SELECT COALESCE(SUM(r.votos_estudiantes), 0) FROM resultado_electoral r
                                         WHERE r.id_cargo = c.id_cargo AND r.tipo_voto = 'VALIDO'),
                        ',"ponderado":', IF((SELECT COALESCE(SUM(r.votos_estudiantes), 0) FROM resultado_electoral r
                                         WHERE r.id_cargo = c.id_cargo AND r.tipo_voto = 'VALIDO') > 0, 'true', 'false'),
                        ',"blancos":', (SELECT COALESCE(SUM(r.total_votos), 0) FROM resultado_electoral r
                                         WHERE r.id_cargo = c.id_cargo AND r.tipo_voto = 'BLANCO'),
                        ',"nulos":', (SELECT COALESCE(SUM(r.total_votos), 0) FROM resultado_electoral r
                                       WHERE r.id_cargo = c.id_cargo AND r.tipo_voto = 'NULO'),
                        ',"emitidos":', (SELECT COALESCE(SUM(r.total_votos), 0) FROM resultado_electoral r
                                          WHERE r.id_cargo = c.id_cargo),
                        ',"estado_resultado":', JSON_QUOTE(c.estado_resultado),
                        ',"id_lista_ganadora":', COALESCE(c.id_lista_ganadora, 'null'),
                        ',"lista_ganadora":', IF(g.nombre IS NULL, 'null', JSON_QUOTE(g.nombre)),
                        ',"opciones":[',
                        COALESCE((SELECT GROUP_CONCAT(CONCAT('{"id_lista":', r.id_lista,
                                                       ',"lista":', JSON_QUOTE(l.nombre),
                                                       ',"orden":', COALESCE(l.orden_cedula, 'null'),
                                                       ',"votos":', r.total_votos,
                                                       ',"votos_docentes":', COALESCE(r.votos_docentes, r.total_votos),
                                                       ',"votos_estudiantes":', COALESCE(r.votos_estudiantes, 0),
                                                       ',"porcentaje":', COALESCE(r.porcentaje_validos, 0),
                                                       ',"pct_docente":', COALESCE(r.pct_docente, r.porcentaje_validos, 0),
                                                       ',"pct_estudiante":', COALESCE(r.pct_estudiante, 0),
                                                       ',"pct_ponderado":', COALESCE(r.pct_ponderado, r.porcentaje_validos, 0),
                                                       ',"posicion":', COALESCE(r.posicion, 'null'), '}')
                                                ORDER BY r.posicion, l.orden_cedula SEPARATOR ',')
                                    FROM resultado_electoral r JOIN lista_electoral l ON l.id_lista = r.id_lista
                                   WHERE r.id_cargo = c.id_cargo AND r.tipo_voto = 'VALIDO'), ''),
                        ']}') AS j
            FROM cargo_electoral c
            JOIN v_participacion_cargo pc ON pc.id_cargo = c.id_cargo
            LEFT JOIN lista_electoral g   ON g.id_lista = c.id_lista_ganadora
           WHERE c.id_proceso = p_id_proceso) z;

  SELECT CONCAT('[', GROUP_CONCAT(JSON_OBJECT('mesa', m.numero_mesa, 'ubicacion', m.ubicacion,
                                              'situacion', m.situacion, 'electores', m.total_electores,
                                              'votaron', m.total_votantes, 'calificacion', m.calificacion,
                                              'resolucion', m.resolucion_calificacion, 'codigo_entrega', m.codigo_cargo)
                                  ORDER BY m.numero_mesa SEPARATOR ','), ']') INTO v_det_mesas
    FROM v_computo_mesas m WHERE m.id_proceso = p_id_proceso;

  SELECT CONCAT('[', GROUP_CONCAT(JSON_OBJECT('personero', CONCAT(d.apellidos, ', ', d.nombres), 'dni', d.dni,
                                              'lista', l.nombre, 'tipo', CONCAT(pe.tipo, ''))
                                  ORDER BY l.nombre, d.apellidos SEPARATOR ','), ']')
    INTO v_pers
    FROM computo_personero cp
    JOIN personero pe      ON pe.id_personero = cp.id_personero
    JOIN docente d         ON d.id_docente = pe.id_docente
    JOIN lista_electoral l ON l.id_lista = pe.id_lista
   WHERE cp.id_proceso = p_id_proceso;

  SET v_ahora = NOW();
  SET v_contenido = CONCAT(
      '{"tipo":"COMPUTO_GENERAL"',
      ',"id_proceso":', p_id_proceso,
      ',"proceso":', JSON_QUOTE(v_nombre),
      ',"vuelta":', JSON_QUOTE(v_tipo),
      ',"fecha_computo":', JSON_QUOTE(DATE_FORMAT(v_ahora, '%Y-%m-%d %H:%i:%s')),
      ',"sesion":{"lugar":', JSON_QUOTE(v_lugar), ',"miembros_ceunp":', v_miembros,
      ',"inicio":', JSON_QUOTE(DATE_FORMAT(v_sesion, '%Y-%m-%d %H:%i:%s')),
      ',"personeros":', COALESCE(v_pers, '[]'), '}',
      ',"mesas":{"total":', v_mesas, ',"computadas":', v_computadas, ',"no_instaladas":', v_no_inst,
      ',"anuladas":', v_anuladas, '}',
      ',"actas_verificadas":', v_actas,
      ',"actas_dudosas":', v_dudosas,
      ',"participacion":{"electores":', COALESCE(v_p_hab, 0), ',"votaron":', COALESCE(v_p_vot, 0),
      ',"porcentaje":', COALESCE(v_p_pct, 0), ',"quorum_minimo":', v_quorum, '}',
      ',"resultado":', JSON_QUOTE(v_resultado),
      ',"cargos":', COALESCE(v_cargos, '[]'),
      ',"detalle_mesas":', COALESCE(v_det_mesas, '[]'),
      IF(v_resultado = 'NULIDAD_TOTAL',
         ',"comunicar_a":["SUNEDU","Asamblea Universitaria","Consejo Universitario"]', ''),
      '}');

  SET v_token = LOWER(HEX(fn_bytes_aleatorios(32)));

  UPDATE computo_proceso
     SET estado = 'COMPUTADO', fecha_computo = v_ahora, mesas_total = v_mesas, mesas_computadas = v_computadas,
         mesas_no_instaladas = v_no_inst, mesas_anuladas = v_anuladas, actas_verificadas = v_actas,
         electores_habiles = COALESCE(v_p_hab, 0), votaron = COALESCE(v_p_vot, 0), participacion_pct = COALESCE(v_p_pct, 0),
         resultado = v_resultado, contenido_json = v_contenido, hash_integridad = SHA2(v_contenido, 256),
         token_qr_hash = SHA2(v_token, 256), id_usuario_computo = p_id_usuario
   WHERE id_proceso = p_id_proceso;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'COMPUTAR_RESULTADOS',
       JSON_OBJECT('cus', 'CUS14', 'mesas_computadas', v_computadas, 'cargos_con_quorum', v_con_q, 'resultado', v_resultado));
  COMMIT;

  -- 13: mostrarResultados(resultados)
  SELECT p_id_proceso AS id_proceso, v_resultado AS resultado, v_token AS token_qr, v_computadas AS mesas_computadas,
         IF(v_resultado = 'VALIDA', 'FINALIZADO', 'ANULADO') AS estado_proceso;
END$$


-- 4. Segunda vuelta y desempate: con ponderación el orden lo da el porcentaje ponderado
--    (pct_ponderado; sin votos estudiantiles es el % de válidos docentes), no los votos docentes.
DROP PROCEDURE IF EXISTS sp_dirimir_empate$$
CREATE PROCEDURE sp_dirimir_empate(
  IN p_id_cargo          INT,
  IN p_id_usuario        INT,
  IN p_semilla           VARCHAR(100),
  IN p_numero_resolucion VARCHAR(40),
  IN p_miembros_pleno    INT,
  IN p_fundamento        VARCHAR(1000)
)
BEGIN
  DECLARE v_proceso  INT DEFAULT NULL;
  DECLARE v_cargo_n  VARCHAR(150);
  DECLARE v_result   VARCHAR(20);
  DECLARE v_tipo     VARCHAR(20);
  DECLARE v_estado   VARCHAR(20);
  DECLARE v_comp     VARCHAR(20);
  DECLARE v_motivo   VARCHAR(25);
  DECLARE v_semilla  VARCHAR(100);
  DECLARE v_res      VARCHAR(40);
  DECLARE v_quorum   INT;
  DECLARE v_max DECIMAL(9,4);
  DECLARE v_v2 DECIMAL(9,4);
  DECLARE v_n        INT DEFAULT 0;
  DECLARE v_arriba   INT DEFAULT 0;
  DECLARE v_empat    INT DEFAULT 0;
  DECLARE v_cupos    INT;
  DECLARE v_ganadora INT;
  DECLARE v_listas   LONGTEXT;
  DECLARE v_elegidas LONGTEXT;
  DECLARE v_nombres  VARCHAR(500);
  DECLARE v_msg      VARCHAR(255);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET SESSION group_concat_max_len = 100000;
  START TRANSACTION;
  SELECT c.id_proceso, c.nombre, CONCAT(c.estado_resultado, ''), p.tipo, p.estado
    INTO v_proceso, v_cargo_n, v_result, v_tipo, v_estado
    FROM cargo_electoral c JOIN proceso_electoral p ON p.id_proceso = c.id_proceso
   WHERE c.id_cargo = p_id_cargo FOR UPDATE;
  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cargo no existe.';
  END IF;
  SELECT estado INTO v_comp FROM computo_proceso WHERE id_proceso = v_proceso;
  IF v_tipo = 'SEGUNDA_VUELTA' AND v_result = 'EMPATE' THEN
    SET v_motivo = 'EMPATE_SEGUNDA_VUELTA';
    IF v_estado <> 'FINALIZADO' OR COALESCE(v_comp, '') <> 'COMPUTADO' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF98: el empate se dirime después del cómputo y antes de la proclamación.';
    END IF;
  ELSEIF v_tipo = 'PRIMERA_VUELTA' AND v_result = 'SEGUNDA_VUELTA' THEN
    SET v_motivo = 'PASE_A_SEGUNDA_VUELTA';
    IF v_estado <> 'FINALIZADO' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN33: el pase a la segunda vuelta se dirime con la primera vuelta computada.';
    END IF;
    IF EXISTS (SELECT 1 FROM proceso_electoral WHERE id_proceso_padre = v_proceso AND estado <> 'ANULADO') THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN33: la segunda vuelta ya fue convocada.';
    END IF;
  ELSE
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF97: el cargo no tiene un empate que dirimir.';
  END IF;
  IF EXISTS (SELECT 1 FROM dirimencia_empate WHERE id_cargo = p_id_cargo) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el empate de este cargo ya fue dirimido.';
  END IF;

  -- Listas empatadas y cupos en disputa (con agregados, como sp_crear_segunda_vuelta)
  SELECT MAX(COALESCE(pct_ponderado, porcentaje_validos)) INTO v_max FROM resultado_electoral WHERE id_cargo = p_id_cargo AND tipo_voto = 'VALIDO';
  IF v_motivo = 'EMPATE_SEGUNDA_VUELTA' THEN
    SET v_v2 = v_max;
    SET v_cupos = 1;
  ELSE
    SELECT COUNT(*) INTO v_n FROM resultado_electoral WHERE id_cargo = p_id_cargo AND tipo_voto = 'VALIDO' AND COALESCE(pct_ponderado, porcentaje_validos) = v_max;
    SET v_v2 = v_max;
    IF v_n < 2 THEN
      SELECT COALESCE(MAX(COALESCE(pct_ponderado, porcentaje_validos)), v_max) INTO v_v2
        FROM resultado_electoral WHERE id_cargo = p_id_cargo AND tipo_voto = 'VALIDO' AND COALESCE(pct_ponderado, porcentaje_validos) < v_max;
    END IF;
    SELECT COUNT(*) INTO v_arriba FROM resultado_electoral WHERE id_cargo = p_id_cargo AND tipo_voto = 'VALIDO' AND COALESCE(pct_ponderado, porcentaje_validos) > v_v2;
    SET v_cupos = 2 - v_arriba;
  END IF;
  SELECT COUNT(*), CONCAT('[', GROUP_CONCAT(JSON_OBJECT('id_lista', r.id_lista, 'lista', l.nombre, 'votos', r.total_votos)
                                            ORDER BY r.id_lista SEPARATOR ','), ']')
    INTO v_empat, v_listas
    FROM resultado_electoral r JOIN lista_electoral l ON l.id_lista = r.id_lista
   WHERE r.id_cargo = p_id_cargo AND r.tipo_voto = 'VALIDO' AND COALESCE(r.pct_ponderado, r.porcentaje_validos) = v_v2;
  IF v_empat <= v_cupos OR v_cupos < 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF97: no hay listas empatadas que dirimir en este cargo.';
  END IF;

  SET v_semilla = NULLIF(TRIM(p_semilla), '');
  IF v_semilla IS NULL OR CHAR_LENGTH(v_semilla) < 4 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Indique la semilla pública del sorteo (al menos 4 caracteres).';
  END IF;
  SET v_res = NULLIF(TRIM(p_numero_resolucion), '');
  IF v_res IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: indique el número de la resolución del CEUNP.';
  END IF;
  IF fn_resolucion_en_uso(v_res) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;
  SET v_quorum = COALESCE(ROUND((SELECT CAST(valor AS DECIMAL(6,2)) FROM parametro_global WHERE clave = 'CEUNP_QUORUM_PLENO')), 5);
  IF p_miembros_pleno IS NULL OR p_miembros_pleno < v_quorum OR p_miembros_pleno > 9 THEN
    SET v_msg = CONCAT('RN36: el Pleno del CEUNP resuelve con quórum de ', v_quorum, ' de sus 9 miembros.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  -- Sorteo: orden por SHA-256 de la semilla con el cargo y la lista
  SELECT CONCAT('[', GROUP_CONCAT(x.id_lista ORDER BY x.orden SEPARATOR ','), ']'),
         GROUP_CONCAT(x.nombre ORDER BY x.orden SEPARATOR ' y '), MIN(IF(x.orden = 1, x.id_lista, NULL))
    INTO v_elegidas, v_nombres, v_ganadora
    FROM (SELECT r.id_lista, l.nombre,
                 ROW_NUMBER() OVER (ORDER BY SHA2(CONCAT(v_semilla, '|', p_id_cargo, '|', r.id_lista), 256)) AS orden
            FROM resultado_electoral r JOIN lista_electoral l ON l.id_lista = r.id_lista
           WHERE r.id_cargo = p_id_cargo AND r.tipo_voto = 'VALIDO' AND COALESCE(r.pct_ponderado, r.porcentaje_validos) = v_v2) x
   WHERE x.orden <= v_cupos;

  INSERT INTO dirimencia_empate (id_cargo, id_proceso, motivo, semilla, cupos, listas_empatadas, listas_elegidas,
                                 numero_resolucion, miembros_pleno, fundamento, fecha, id_usuario, hash_integridad)
  VALUES (p_id_cargo, v_proceso, v_motivo, v_semilla, v_cupos, v_listas, v_elegidas, v_res, p_miembros_pleno,
          NULLIF(TRIM(p_fundamento), ''), NOW(), p_id_usuario,
          SHA2(CONCAT(v_semilla, '|', p_id_cargo, '|', v_listas, '|', v_elegidas, '|', v_res), 256));
  IF v_motivo = 'EMPATE_SEGUNDA_VUELTA' THEN
    UPDATE cargo_electoral SET estado_resultado = 'ELEGIDO', id_lista_ganadora = v_ganadora WHERE id_cargo = p_id_cargo;
  END IF;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'DIRIMIR_EMPATE',
       JSON_OBJECT('id_cargo', p_id_cargo, 'motivo', v_motivo, 'semilla', v_semilla, 'elegidas', v_elegidas, 'resolucion', v_res));
  COMMIT;

  SELECT p_id_cargo AS id_cargo, v_cargo_n AS cargo, v_motivo AS motivo, v_cupos AS cupos, v_empat AS empatadas,
         v_elegidas AS listas_elegidas, v_nombres AS listas;
END$$

DROP PROCEDURE IF EXISTS sp_crear_segunda_vuelta$$
CREATE PROCEDURE sp_crear_segunda_vuelta(
  IN  p_id_proceso_padre INT,
  IN  p_fecha_inicio     DATETIME,
  IN  p_fecha_fin        DATETIME,
  IN  p_id_usuario       INT,
  OUT p_id_proceso_nuevo INT
)
BEGIN
  DECLARE v_estado   VARCHAR(20) DEFAULT NULL;
  DECLARE v_tipo     VARCHAR(20) DEFAULT NULL;
  DECLARE v_nombre   VARCHAR(200);
  DECLARE v_quorum   DECIMAL(5,2);
  DECLARE v_fin      INT DEFAULT 0;
  DECLARE v_cargo    INT;
  DECLARE v_c_nombre VARCHAR(150);
  DECLARE v_c_nivel  VARCHAR(20);
  DECLARE v_c_jur    INT;
  DECLARE v_c_pct    DECIMAL(5,2);
  DECLARE v_cargo_nuevo INT;
  DECLARE v_l1       INT DEFAULT NULL;
  DECLARE v_l2       INT DEFAULT NULL;
  DECLARE v_lista_vieja INT;
  DECLARE v_lista_nueva INT;
  DECLARE v_i        INT;
  DECLARE v_n        INT DEFAULT 0;
  DECLARE v_max DECIMAL(9,4);
  DECLARE v_v2 DECIMAL(9,4);
  DECLARE v_arriba   INT;
  DECLARE v_empat    INT;
  DECLARE v_elegidas LONGTEXT;
  DECLARE v_msg      VARCHAR(255);
  DECLARE cur_cargos CURSOR FOR
    SELECT id_cargo, nombre, nivel_jurisdiccion, id_jurisdiccion, porcentaje_minimo_victoria
      FROM cargo_electoral
     WHERE id_proceso = p_id_proceso_padre AND estado_resultado = 'SEGUNDA_VUELTA'
     ORDER BY id_cargo;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = 1;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT COUNT(*) INTO v_n FROM proceso_electoral WHERE id_proceso = p_id_proceso_padre;
  IF v_n = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso de primera vuelta no existe.';
  END IF;
  SELECT estado, tipo, nombre, quorum_minimo INTO v_estado, v_tipo, v_nombre, v_quorum
    FROM proceso_electoral WHERE id_proceso = p_id_proceso_padre;

  IF v_estado <> 'FINALIZADO' OR v_tipo <> 'PRIMERA_VUELTA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN33: se requiere una primera vuelta FINALIZADA.';
  END IF;
  SELECT COUNT(*) INTO v_n FROM cargo_electoral
   WHERE id_proceso = p_id_proceso_padre AND estado_resultado = 'SEGUNDA_VUELTA';
  IF v_n = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN33: ningun cargo de este proceso requiere segunda vuelta.';
  END IF;
  SELECT COUNT(*) INTO v_n FROM proceso_electoral
   WHERE id_proceso_padre = p_id_proceso_padre AND estado <> 'ANULADO';
  IF v_n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe una segunda vuelta vigente para este proceso.';
  END IF;
  IF p_fecha_fin <= p_fecha_inicio THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de fin debe ser posterior a la de inicio.';
  END IF;

  INSERT INTO proceso_electoral (nombre, fecha_inicio, fecha_fin, estado, tipo, id_proceso_padre, quorum_minimo)
  VALUES (LEFT(CONCAT(v_nombre, ' - Segunda vuelta'), 200), p_fecha_inicio, p_fecha_fin,
          'CREADO', 'SEGUNDA_VUELTA', p_id_proceso_padre, v_quorum);
  SET p_id_proceso_nuevo = LAST_INSERT_ID();

  DROP TEMPORARY TABLE IF EXISTS tmp_candidato_sv;
  CREATE TEMPORARY TABLE tmp_candidato_sv (
    id_docente INT NOT NULL, rol_en_lista VARCHAR(100) NOT NULL, url_hoja_vida VARCHAR(300) NULL);

  SET v_fin = 0;
  OPEN cur_cargos;
  bucle: LOOP
    FETCH cur_cargos INTO v_cargo, v_c_nombre, v_c_nivel, v_c_jur, v_c_pct;
    IF v_fin = 1 THEN
      LEAVE bucle;
    END IF;

    INSERT INTO cargo_electoral (id_proceso, nombre, nivel_jurisdiccion, id_jurisdiccion, porcentaje_minimo_victoria)
    VALUES (p_id_proceso_nuevo, v_c_nombre, v_c_nivel, v_c_jur, v_c_pct);
    SET v_cargo_nuevo = LAST_INSERT_ID();

    INSERT INTO cargo_categoria_permitida (id_cargo, categoria, puede_votar, puede_postular)
    SELECT v_cargo_nuevo, categoria, puede_votar, puede_postular
      FROM cargo_categoria_permitida WHERE id_cargo = v_cargo;

    -- 13 copiarDosMasVotadas(id_cargo). Con agregados (no disparan el handler NOT FOUND):
    -- v_v2 = votos de la segunda lista del ranking; las que tienen más pasan directo y las que
    -- tienen v_v2 compiten por los cupos restantes.
    SELECT MAX(COALESCE(pct_ponderado, porcentaje_validos)) INTO v_max FROM resultado_electoral WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO';
    SELECT COUNT(*) INTO v_n FROM resultado_electoral WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO' AND COALESCE(pct_ponderado, porcentaje_validos) = v_max;
    SET v_v2 = v_max;
    IF v_n < 2 THEN
      SELECT COALESCE(MAX(COALESCE(pct_ponderado, porcentaje_validos)), v_max) INTO v_v2
        FROM resultado_electoral WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO' AND COALESCE(pct_ponderado, porcentaje_validos) < v_max;
    END IF;
    SELECT COUNT(*) INTO v_arriba FROM resultado_electoral WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO' AND COALESCE(pct_ponderado, porcentaje_validos) > v_v2;
    SELECT COUNT(*) INTO v_empat FROM resultado_electoral WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO' AND COALESCE(pct_ponderado, porcentaje_validos) = v_v2;
    SET v_elegidas = NULL;
    IF v_empat > 2 - v_arriba THEN
      SELECT MAX(listas_elegidas) INTO v_elegidas FROM dirimencia_empate
       WHERE id_cargo = v_cargo AND motivo = 'PASE_A_SEGUNDA_VUELTA';
      IF v_elegidas IS NULL THEN
        SET v_msg = CONCAT('RN33: en ', v_c_nombre, ' hay ', v_empat, ' listas empatadas por ', 2 - v_arriba,
                           ' cupo(s) de la segunda vuelta; el Pleno debe dirimirlo por sorteo (CUS15).');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
      END IF;
    END IF;
    SELECT MIN(id_lista), IF(COUNT(*) > 1, MAX(id_lista), NULL) INTO v_l1, v_l2
      FROM resultado_electoral
     WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO'
       AND (COALESCE(pct_ponderado, porcentaje_validos) > v_v2
            OR (COALESCE(pct_ponderado, porcentaje_validos) = v_v2 AND (v_elegidas IS NULL OR JSON_CONTAINS(v_elegidas, CAST(id_lista AS CHAR)))));

    SET v_i = 1;
    WHILE v_i <= 2 DO
      SET v_lista_vieja = IF(v_i = 1, v_l1, v_l2);
      IF v_lista_vieja IS NOT NULL THEN
        INSERT INTO lista_electoral (id_cargo, nombre, simbolo, estado, url_plan_gobierno)
        SELECT v_cargo_nuevo, nombre, simbolo, 'ADMITIDA', url_plan_gobierno
          FROM lista_electoral WHERE id_lista = v_lista_vieja;
        SET v_lista_nueva = LAST_INSERT_ID();

        DELETE FROM tmp_candidato_sv;
        INSERT INTO tmp_candidato_sv (id_docente, rol_en_lista, url_hoja_vida)
        SELECT id_docente, rol_en_lista, url_hoja_vida
          FROM candidato WHERE id_lista = v_lista_vieja AND estado_validacion = 'APROBADO';
        INSERT INTO candidato (id_lista, id_docente, rol_en_lista, url_hoja_vida, estado_validacion)
        SELECT v_lista_nueva, id_docente, rol_en_lista, url_hoja_vida, 'APROBADO'
          FROM tmp_candidato_sv;
      END IF;
      SET v_i = v_i + 1;
    END WHILE;

    -- Mismo padrón de la primera vuelta, sin marcas de voto ni mesa
    INSERT INTO padron_electoral (id_proceso, id_cargo, id_docente, habilitado_para_votar, motivo_inhabilitacion)
    SELECT p_id_proceso_nuevo, v_cargo_nuevo, id_docente, habilitado_para_votar, motivo_inhabilitacion
      FROM padron_electoral WHERE id_cargo = v_cargo;

    SET v_fin = 0;
  END LOOP;
  CLOSE cur_cargos;
  DROP TEMPORARY TABLE IF EXISTS tmp_candidato_sv;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso_nuevo, 'CREAR_SEGUNDA_VUELTA',
       JSON_OBJECT('id_proceso_padre', p_id_proceso_padre));
  COMMIT;
END$$

DELIMITER ;
