-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 04_procedimientos.sql  ·  Procedimientos almacenados (ciclo electoral completo)
--
-- Convenciones:
--   p_  parámetros      v_  variables locales
--   Todo procedimiento que modifica datos abre su transacción y, ante
--   cualquier error, hace ROLLBACK y relanza el mensaje (SQLSTATE 45000).
--   Los mensajes citan la regla de negocio (RNxx) que se incumple.
--
-- Índice
--   A. Utilitarios ........ sp_registrar_auditoria, sp_emitir_acta
--   B. Proceso ............ sp_crear_proceso, sp_agregar_cargo, sp_cambiar_estado_proceso, sp_anular_proceso
--   C. Listas ............. sp_inscribir_lista, sp_inscribir_candidato, sp_validar_lista,
--                           sp_presentar_tacha, sp_resolver_tacha, sp_sortear_orden_cedula
--   D. Padrón y mesas ..... sp_generar_padron, sp_crear_mesas, sp_sortear_miembros_mesa,
--                           sp_sortear_todas_las_mesas, sp_registrar_asistencia_miembro
--   E. Día de elección .... sp_instalar_mesa, sp_emitir_voto, sp_cerrar_mesa
--   F. Resultados ......... sp_computar_resultados, sp_crear_segunda_vuelta
--   G. Sanciones .......... sp_generar_multas, sp_actualizar_multa
--   H. Verificación QR .... sp_verificar_constancia, sp_verificar_acta
-- =====================================================================
USE elecciones_unp;
-- Las rutinas guardan el sql_mode vigente al crearse: se fuerza modo estricto
-- (XAMPP viene sin STRICT y aceptaria valores invalidos en silencio).
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

DROP PROCEDURE IF EXISTS sp_registrar_auditoria;
DROP PROCEDURE IF EXISTS sp_emitir_acta;
DROP PROCEDURE IF EXISTS sp_crear_proceso;
DROP PROCEDURE IF EXISTS sp_agregar_cargo;
DROP PROCEDURE IF EXISTS sp_cambiar_estado_proceso;
DROP PROCEDURE IF EXISTS sp_anular_proceso;
DROP PROCEDURE IF EXISTS sp_inscribir_lista;
DROP PROCEDURE IF EXISTS sp_inscribir_candidato;
DROP PROCEDURE IF EXISTS sp_validar_lista;
DROP PROCEDURE IF EXISTS sp_presentar_tacha;
DROP PROCEDURE IF EXISTS sp_resolver_tacha;
DROP PROCEDURE IF EXISTS sp_sortear_orden_cedula;
DROP PROCEDURE IF EXISTS sp_generar_padron;
DROP PROCEDURE IF EXISTS sp_crear_mesas;
DROP PROCEDURE IF EXISTS sp_sortear_miembros_mesa;
DROP PROCEDURE IF EXISTS sp_sortear_todas_las_mesas;
DROP PROCEDURE IF EXISTS sp_registrar_asistencia_miembro;
DROP PROCEDURE IF EXISTS sp_instalar_mesa;
DROP PROCEDURE IF EXISTS sp_emitir_voto;
DROP PROCEDURE IF EXISTS sp_cerrar_mesa;
DROP PROCEDURE IF EXISTS sp_computar_resultados;
DROP PROCEDURE IF EXISTS sp_crear_segunda_vuelta;
DROP PROCEDURE IF EXISTS sp_generar_multas;
DROP PROCEDURE IF EXISTS sp_actualizar_multa;
DROP PROCEDURE IF EXISTS sp_verificar_constancia;
DROP PROCEDURE IF EXISTS sp_verificar_acta;

DELIMITER $$

-- =====================================================================
-- A. UTILITARIOS
-- =====================================================================

-- Inserta una fila en la bitácora. No abre transacción: participa en la del llamador.
-- p_detalle_json debe ser JSON válido o NULL. Nunca registrar aquí la lista votada.
CREATE PROCEDURE sp_registrar_auditoria(
  IN p_id_usuario INT,
  IN p_id_docente INT,
  IN p_id_proceso INT,
  IN p_accion     VARCHAR(100),
  IN p_detalle_json LONGTEXT
)
BEGIN
  INSERT INTO log_auditoria (id_usuario, id_docente, id_proceso, accion, detalle_json)
  VALUES (p_id_usuario, p_id_docente, p_id_proceso, p_accion, p_detalle_json);
END$$

-- Emite un acta con su huella SHA-256 y un token de verificación (uso interno).
-- En la BD solo queda el hash del token; el token en claro va dentro del QR.
CREATE PROCEDURE sp_emitir_acta(
  IN  p_id_mesa   INT,
  IN  p_tipo      VARCHAR(12),
  IN  p_contenido LONGTEXT,
  OUT p_token     CHAR(64)
)
BEGIN
  SET p_token = SHA2(CONCAT(UUID(), RAND(), p_id_mesa, p_tipo, NOW(6)), 256);
  INSERT INTO acta_electoral (id_mesa, tipo, contenido_json, hash_integridad, token_qr_hash)
  VALUES (p_id_mesa, p_tipo, p_contenido, SHA2(p_contenido, 256), SHA2(p_token, 256));
END$$

-- =====================================================================
-- B. PROCESO ELECTORAL
-- =====================================================================

-- RF02: crea la convocatoria en estado CREADO.
CREATE PROCEDURE sp_crear_proceso(
  IN  p_nombre             VARCHAR(200),
  IN  p_fecha_inicio       DATETIME,
  IN  p_fecha_fin          DATETIME,
  IN  p_quorum_minimo      DECIMAL(5,2),     -- NULL = 60.00
  IN  p_fecha_convocatoria DATE,             -- puede ser NULL
  IN  p_limite_inscripcion DATETIME,         -- puede ser NULL
  IN  p_id_usuario         INT,
  OUT p_id_proceso         INT
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  IF p_fecha_fin <= p_fecha_inicio THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de fin debe ser posterior a la de inicio.';
  END IF;
  IF p_limite_inscripcion IS NOT NULL AND p_limite_inscripcion >= p_fecha_inicio THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El limite de inscripcion debe ser anterior al inicio del sufragio.';
  END IF;

  INSERT INTO proceso_electoral (nombre, fecha_inicio, fecha_fin, estado, tipo, quorum_minimo,
                                 fecha_convocatoria, fecha_limite_inscripcion)
  VALUES (p_nombre, p_fecha_inicio, p_fecha_fin, 'CREADO', 'PRIMERA_VUELTA',
          COALESCE(p_quorum_minimo, 60.00), p_fecha_convocatoria, p_limite_inscripcion);
  SET p_id_proceso = LAST_INSERT_ID();

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'CREAR_PROCESO',
       JSON_OBJECT('nombre', p_nombre));
  COMMIT;
END$$

-- RF03: agrega un cargo y define qué categorías votan y cuáles postulan.
-- Las listas de categorías van separadas por coma, p. ej. 'PRINCIPAL,ASOCIADO'. NULL = todas.
CREATE PROCEDURE sp_agregar_cargo(
  IN  p_id_proceso          INT,
  IN  p_nombre              VARCHAR(150),
  IN  p_nivel               VARCHAR(20),     -- UNIVERSIDAD / FACULTAD / DEPARTAMENTO
  IN  p_id_jurisdiccion     INT,             -- NULL si es UNIVERSIDAD
  IN  p_categorias_votan    VARCHAR(60),
  IN  p_categorias_postulan VARCHAR(60),
  OUT p_id_cargo            INT
)
BEGIN
  DECLARE v_estado  VARCHAR(20) DEFAULT NULL;
  DECLARE v_i       INT DEFAULT 1;
  DECLARE v_cat     VARCHAR(10);
  DECLARE v_votan   VARCHAR(60);
  DECLARE v_postula VARCHAR(60);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT estado INTO v_estado FROM proceso_electoral WHERE id_proceso = p_id_proceso;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;
  IF v_estado NOT IN ('CREADO','INSCRIPCION') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se agregan cargos con el proceso en CREADO o INSCRIPCION.';
  END IF;

  IF p_nivel IS NULL OR UPPER(p_nivel) NOT IN ('UNIVERSIDAD','FACULTAD','DEPARTAMENTO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nivel invalido: use UNIVERSIDAD, FACULTAD o DEPARTAMENTO.';
  END IF;

  INSERT INTO cargo_electoral (id_proceso, nombre, nivel_jurisdiccion, id_jurisdiccion)
  VALUES (p_id_proceso, p_nombre, UPPER(p_nivel), p_id_jurisdiccion);
  SET p_id_cargo = LAST_INSERT_ID();

  SET v_votan   = COALESCE(REPLACE(UPPER(p_categorias_votan), ' ', ''),   'PRINCIPAL,ASOCIADO,AUXILIAR');
  SET v_postula = COALESCE(REPLACE(UPPER(p_categorias_postulan), ' ', ''), 'PRINCIPAL,ASOCIADO,AUXILIAR');

  WHILE v_i <= 3 DO
    SET v_cat = ELT(v_i, 'PRINCIPAL', 'ASOCIADO', 'AUXILIAR');
    IF FIND_IN_SET(v_cat, v_votan) > 0 OR FIND_IN_SET(v_cat, v_postula) > 0 THEN
      INSERT INTO cargo_categoria_permitida (id_cargo, categoria, puede_votar, puede_postular)
      VALUES (p_id_cargo, v_cat, FIND_IN_SET(v_cat, v_votan) > 0, FIND_IN_SET(v_cat, v_postula) > 0);
    END IF;
    SET v_i = v_i + 1;
  END WHILE;

  COMMIT;
END$$

-- Máquina de estados: CREADO -> INSCRIPCION -> VOTACION -> CERRADO.
-- FINALIZADO solo lo pone sp_computar_resultados; ANULADO solo sp_anular_proceso.
CREATE PROCEDURE sp_cambiar_estado_proceso(
  IN p_id_proceso   INT,
  IN p_nuevo_estado VARCHAR(20),
  IN p_id_usuario   INT
)
BEGIN
  DECLARE v_estado VARCHAR(20) DEFAULT NULL;
  DECLARE v_nuevo  VARCHAR(20);
  DECLARE v_n      INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SET v_nuevo = UPPER(p_nuevo_estado);

  SELECT estado INTO v_estado FROM proceso_electoral WHERE id_proceso = p_id_proceso FOR UPDATE;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;

  IF v_nuevo IS NULL OR NOT ( (v_estado = 'CREADO'      AND v_nuevo = 'INSCRIPCION')
        OR (v_estado = 'INSCRIPCION' AND v_nuevo = 'VOTACION')
        OR (v_estado = 'VOTACION'    AND v_nuevo = 'CERRADO') ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Transicion no permitida. Orden: CREADO > INSCRIPCION > VOTACION > CERRADO.';
  END IF;

  IF v_nuevo = 'INSCRIPCION' THEN
    SELECT COUNT(*) INTO v_n FROM cargo_electoral WHERE id_proceso = p_id_proceso;
    IF v_n = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso no tiene cargos a elegir.';
    END IF;
  END IF;

  IF v_nuevo = 'VOTACION' THEN
    -- RN04: padrón aprobado
    SELECT COUNT(*) INTO v_n FROM padron_electoral WHERE id_proceso = p_id_proceso;
    IF v_n = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN04: falta generar el padron electoral.';
    END IF;
    -- cada cargo necesita al menos una lista admitida
    SELECT COUNT(*) INTO v_n
      FROM cargo_electoral c
     WHERE c.id_proceso = p_id_proceso
       AND NOT EXISTS (SELECT 1 FROM lista_electoral l
                        WHERE l.id_cargo = c.id_cargo AND l.estado = 'ADMITIDA');
    IF v_n > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hay cargos sin ninguna lista ADMITIDA.';
    END IF;
    -- RN18: orden de cédula sorteado
    SELECT COUNT(*) INTO v_n
      FROM lista_electoral l
      JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
     WHERE c.id_proceso = p_id_proceso AND l.estado = 'ADMITIDA' AND l.orden_cedula IS NULL;
    IF v_n > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN18: falta sortear el orden de las listas en la cedula.';
    END IF;
    -- RN19: mesas con sus 6 miembros
    SELECT COUNT(*) INTO v_n FROM mesa_electoral WHERE id_proceso = p_id_proceso AND estado <> 'ANULADA';
    IF v_n = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay mesas de sufragio creadas.';
    END IF;
    SELECT COUNT(*) INTO v_n
      FROM mesa_electoral m
     WHERE m.id_proceso = p_id_proceso AND m.estado <> 'ANULADA'
       AND (SELECT COUNT(*) FROM miembro_mesa mm WHERE mm.id_mesa = m.id_mesa) <> 6;
    IF v_n > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN19: hay mesas sin sus 3 titulares y 3 suplentes.';
    END IF;
  END IF;

  UPDATE proceso_electoral
     SET estado = v_nuevo,
         fecha_cierre_real = IF(v_nuevo = 'CERRADO', NOW(), fecha_cierre_real)
   WHERE id_proceso = p_id_proceso;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'CAMBIO_ESTADO_PROCESO',
       JSON_OBJECT('anterior', v_estado, 'nuevo', v_nuevo));
  COMMIT;
END$$

-- RN34: nulidad del proceso por causal. Anula también mesas y actas.
CREATE PROCEDURE sp_anular_proceso(
  IN p_id_proceso INT,
  IN p_motivo     VARCHAR(500),
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_estado VARCHAR(20) DEFAULT NULL;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT estado INTO v_estado FROM proceso_electoral WHERE id_proceso = p_id_proceso FOR UPDATE;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;
  IF v_estado IN ('FINALIZADO','ANULADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso ya esta FINALIZADO o ANULADO.';
  END IF;
  IF p_motivo IS NULL OR TRIM(p_motivo) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN34: la anulacion requiere un motivo.';
  END IF;

  UPDATE proceso_electoral
     SET estado = 'ANULADO', motivo_anulacion = p_motivo, fecha_cierre_real = COALESCE(fecha_cierre_real, NOW())
   WHERE id_proceso = p_id_proceso;
  UPDATE acta_electoral a
    JOIN mesa_electoral m ON m.id_mesa = a.id_mesa
     SET a.estado = 'ANULADA'
   WHERE m.id_proceso = p_id_proceso;
  UPDATE mesa_electoral SET estado = 'ANULADA' WHERE id_proceso = p_id_proceso;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'ANULAR_PROCESO',
       JSON_OBJECT('motivo', p_motivo, 'estado_anterior', v_estado));
  COMMIT;
END$$

-- =====================================================================
-- C. LISTAS, CANDIDATOS Y TACHAS
-- =====================================================================

-- CUN03: inscribe una lista (fórmula) para un cargo.
CREATE PROCEDURE sp_inscribir_lista(
  IN  p_id_cargo  INT,
  IN  p_nombre    VARCHAR(150),
  IN  p_simbolo   VARCHAR(100),
  IN  p_url_plan  VARCHAR(300),
  IN  p_id_usuario INT,
  OUT p_id_lista  INT
)
BEGIN
  DECLARE v_proceso INT DEFAULT NULL;
  DECLARE v_estado  VARCHAR(20) DEFAULT NULL;
  DECLARE v_limite  DATETIME DEFAULT NULL;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT p.id_proceso, p.estado, p.fecha_limite_inscripcion
    INTO v_proceso, v_estado, v_limite
    FROM cargo_electoral c
    JOIN proceso_electoral p ON p.id_proceso = c.id_proceso
   WHERE c.id_cargo = p_id_cargo;

  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cargo electoral no existe.';
  END IF;
  IF v_estado <> 'INSCRIPCION' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso no esta en etapa de INSCRIPCION.';
  END IF;
  IF v_limite IS NOT NULL AND NOW() > v_limite THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN13: vencio el plazo de inscripcion de listas.';
  END IF;

  INSERT INTO lista_electoral (id_cargo, nombre, simbolo, url_plan_gobierno, estado)
  VALUES (p_id_cargo, TRIM(p_nombre), p_simbolo, p_url_plan, 'INSCRITA');
  SET p_id_lista = LAST_INSERT_ID();

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'INSCRIBIR_LISTA',
       JSON_OBJECT('id_lista', p_id_lista, 'nombre', p_nombre));
  COMMIT;
END$$

-- RN10 / RN11 / RN13: agrega un integrante a la fórmula.
CREATE PROCEDURE sp_inscribir_candidato(
  IN  p_id_lista     INT,
  IN  p_id_docente   INT,
  IN  p_rol_en_lista VARCHAR(100),
  IN  p_url_hoja_vida VARCHAR(300),
  IN  p_id_usuario   INT,
  OUT p_id_candidato INT
)
BEGIN
  DECLARE v_proceso   INT DEFAULT NULL;
  DECLARE v_cargo     INT DEFAULT NULL;
  DECLARE v_estado    VARCHAR(20) DEFAULT NULL;
  DECLARE v_limite    DATETIME DEFAULT NULL;
  DECLARE v_lista_est VARCHAR(20) DEFAULT NULL;
  DECLARE v_nivel     VARCHAR(20) DEFAULT NULL;
  DECLARE v_jur       INT DEFAULT NULL;
  DECLARE v_doc_est   VARCHAR(20) DEFAULT NULL;
  DECLARE v_doc_cat   VARCHAR(10) DEFAULT NULL;
  DECLARE v_doc_fac   INT DEFAULT NULL;
  DECLARE v_doc_dep   INT DEFAULT NULL;
  DECLARE v_n         INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT p.id_proceso, p.estado, p.fecha_limite_inscripcion, l.estado,
         c.id_cargo, c.nivel_jurisdiccion, c.id_jurisdiccion
    INTO v_proceso, v_estado, v_limite, v_lista_est, v_cargo, v_nivel, v_jur
    FROM lista_electoral l
    JOIN cargo_electoral c   ON c.id_cargo = l.id_cargo
    JOIN proceso_electoral p ON p.id_proceso = c.id_proceso
   WHERE l.id_lista = p_id_lista;

  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La lista electoral no existe.';
  END IF;
  IF v_estado <> 'INSCRIPCION' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso no esta en etapa de INSCRIPCION.';
  END IF;
  IF v_limite IS NOT NULL AND NOW() > v_limite THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN13: vencio el plazo para modificar la lista.';
  END IF;
  IF v_lista_est <> 'INSCRITA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN12: la lista ya fue calificada; no admite nuevos candidatos.';
  END IF;

  SELECT estado, categoria, id_facultad, id_departamento
    INTO v_doc_est, v_doc_cat, v_doc_fac, v_doc_dep
    FROM docente WHERE id_docente = p_id_docente;

  IF v_doc_est IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El docente no existe.';
  END IF;
  IF v_doc_est <> 'ACTIVO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN09: solo un docente ACTIVO puede ser candidato.';
  END IF;
  IF (v_nivel = 'FACULTAD' AND v_doc_fac <> v_jur)
     OR (v_nivel = 'DEPARTAMENTO' AND v_doc_dep <> v_jur) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El docente no pertenece a la jurisdiccion del cargo.';
  END IF;

  -- RF03: categoría habilitada para postular (si el cargo tiene categorías configuradas)
  SELECT COUNT(*) INTO v_n FROM cargo_categoria_permitida WHERE id_cargo = v_cargo;
  IF v_n > 0 THEN
    SELECT COUNT(*) INTO v_n FROM cargo_categoria_permitida
     WHERE id_cargo = v_cargo AND categoria = v_doc_cat AND puede_postular = 1;
    IF v_n = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN09: la categoria del docente no puede postular a este cargo.';
    END IF;
  END IF;

  -- RN11 y RN20/21 los valida además el trigger trg_candidato_bi
  INSERT INTO candidato (id_lista, id_docente, rol_en_lista, url_hoja_vida, estado_validacion)
  VALUES (p_id_lista, p_id_docente, UPPER(TRIM(p_rol_en_lista)), p_url_hoja_vida, 'PENDIENTE');
  SET p_id_candidato = LAST_INSERT_ID();

  CALL sp_registrar_auditoria(p_id_usuario, p_id_docente, v_proceso, 'INSCRIBIR_CANDIDATO',
       JSON_OBJECT('id_lista', p_id_lista, 'rol', p_rol_en_lista));
  COMMIT;
END$$

-- CEUNP califica la lista completa (RN12: inscripción en bloque).
--   p_admitir = TRUE  -> lista ADMITIDA y candidatos APROBADO
--   p_admitir = FALSE -> lista EXCLUIDA y candidatos EXCLUIDO (requiere motivo)
CREATE PROCEDURE sp_validar_lista(
  IN p_id_lista   INT,
  IN p_admitir    BOOLEAN,
  IN p_motivo     VARCHAR(500),
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_proceso   INT DEFAULT NULL;
  DECLARE v_estado    VARCHAR(20) DEFAULT NULL;
  DECLARE v_lista_est VARCHAR(20) DEFAULT NULL;
  DECLARE v_n         INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT p.id_proceso, p.estado, l.estado INTO v_proceso, v_estado, v_lista_est
    FROM lista_electoral l
    JOIN cargo_electoral c   ON c.id_cargo = l.id_cargo
    JOIN proceso_electoral p ON p.id_proceso = c.id_proceso
   WHERE l.id_lista = p_id_lista
     FOR UPDATE;

  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La lista electoral no existe.';
  END IF;
  IF v_estado <> 'INSCRIPCION' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Las listas solo se califican en etapa de INSCRIPCION.';
  END IF;
  IF v_lista_est <> 'INSCRITA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La lista ya fue calificada.';
  END IF;

  IF p_admitir THEN
    SELECT COUNT(*) INTO v_n FROM candidato
     WHERE id_lista = p_id_lista AND estado_validacion <> 'EXCLUIDO';
    IF v_n = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN10: la lista no tiene candidatos inscritos.';
    END IF;
    SELECT COUNT(*) INTO v_n
      FROM tacha t JOIN candidato ca ON ca.id_candidato = t.id_candidato
     WHERE ca.id_lista = p_id_lista AND t.estado = 'PENDIENTE';
    IF v_n > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La lista tiene tachas PENDIENTES de resolver.';
    END IF;

    UPDATE candidato SET estado_validacion = 'APROBADO'
     WHERE id_lista = p_id_lista AND estado_validacion IN ('PENDIENTE','OBSERVADO');
    UPDATE lista_electoral SET estado = 'ADMITIDA', motivo_exclusion = NULL WHERE id_lista = p_id_lista;
  ELSE
    IF p_motivo IS NULL OR TRIM(p_motivo) = '' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La exclusion de una lista requiere un motivo.';
    END IF;
    UPDATE candidato SET estado_validacion = 'EXCLUIDO', motivo_exclusion = p_motivo
     WHERE id_lista = p_id_lista;
    UPDATE lista_electoral SET estado = 'EXCLUIDA', motivo_exclusion = p_motivo, orden_cedula = NULL
     WHERE id_lista = p_id_lista;
  END IF;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'VALIDAR_LISTA',
       JSON_OBJECT('id_lista', p_id_lista, 'admitida', IF(p_admitir, 'SI', 'NO'), 'motivo', p_motivo));
  COMMIT;
END$$

-- CUN04: un docente presenta una tacha contra un candidato (antes de la elección).
CREATE PROCEDURE sp_presentar_tacha(
  IN  p_id_docente_denunciante INT,
  IN  p_id_candidato INT,
  IN  p_motivo       TEXT,
  OUT p_id_tacha     INT
)
BEGIN
  DECLARE v_proceso INT DEFAULT NULL;
  DECLARE v_estado  VARCHAR(20) DEFAULT NULL;
  DECLARE v_doc_est VARCHAR(20) DEFAULT NULL;
  DECLARE v_cand_docente INT DEFAULT NULL;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT p.id_proceso, p.estado, ca.id_docente INTO v_proceso, v_estado, v_cand_docente
    FROM candidato ca
    JOIN lista_electoral l   ON l.id_lista = ca.id_lista
    JOIN cargo_electoral c   ON c.id_cargo = l.id_cargo
    JOIN proceso_electoral p ON p.id_proceso = c.id_proceso
   WHERE ca.id_candidato = p_id_candidato;

  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El candidato no existe.';
  END IF;
  IF v_estado <> 'INSCRIPCION' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Las tachas solo se presentan en etapa de INSCRIPCION.';
  END IF;

  SELECT estado INTO v_doc_est FROM docente WHERE id_docente = p_id_docente_denunciante;
  IF v_doc_est IS NULL OR v_doc_est <> 'ACTIVO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo un docente ACTIVO del padron puede presentar tachas.';
  END IF;
  IF v_cand_docente = p_id_docente_denunciante THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un candidato no puede tacharse a si mismo.';
  END IF;
  IF p_motivo IS NULL OR TRIM(p_motivo) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La tacha debe estar fundamentada por escrito.';
  END IF;

  INSERT INTO tacha (id_docente_denunciante, id_candidato, motivo)
  VALUES (p_id_docente_denunciante, p_id_candidato, p_motivo);
  SET p_id_tacha = LAST_INSERT_ID();

  CALL sp_registrar_auditoria(NULL, p_id_docente_denunciante, v_proceso, 'PRESENTAR_TACHA',
       JSON_OBJECT('id_tacha', p_id_tacha, 'id_candidato', p_id_candidato));
  COMMIT;
END$$

-- CEUNP resuelve la tacha. FUNDADA: el candidato queda EXCLUIDO y,
-- por RN12 (inscripción en bloque), toda su lista pasa a TACHADA.
CREATE PROCEDURE sp_resolver_tacha(
  IN p_id_tacha   INT,
  IN p_resultado  VARCHAR(10),      -- FUNDADA / INFUNDADA
  IN p_resolucion TEXT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_estado    VARCHAR(20) DEFAULT NULL;
  DECLARE v_candidato INT DEFAULT NULL;
  DECLARE v_lista     INT DEFAULT NULL;
  DECLARE v_proceso   INT DEFAULT NULL;
  DECLARE v_res       VARCHAR(10);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SET v_res = UPPER(p_resultado);

  SELECT t.estado, t.id_candidato, ca.id_lista INTO v_estado, v_candidato, v_lista
    FROM tacha t JOIN candidato ca ON ca.id_candidato = t.id_candidato
   WHERE t.id_tacha = p_id_tacha
     FOR UPDATE;

  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La tacha no existe.';
  END IF;
  IF v_estado <> 'PENDIENTE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La tacha ya fue resuelta.';
  END IF;
  IF v_res IS NULL OR v_res NOT IN ('FUNDADA','INFUNDADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El resultado debe ser FUNDADA o INFUNDADA.';
  END IF;

  SET v_proceso = fn_proceso_de_lista(v_lista);

  UPDATE tacha
     SET estado = v_res, fecha_resolucion = NOW(), resolucion = p_resolucion, id_usuario_resuelve = p_id_usuario
   WHERE id_tacha = p_id_tacha;

  IF v_res = 'FUNDADA' THEN
    UPDATE candidato
       SET estado_validacion = 'EXCLUIDO', motivo_exclusion = 'Tacha declarada fundada'
     WHERE id_candidato = v_candidato;
    UPDATE lista_electoral
       SET estado = 'TACHADA', orden_cedula = NULL, motivo_exclusion = 'Tacha fundada contra un integrante (RN12)'
     WHERE id_lista = v_lista;
  END IF;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'RESOLVER_TACHA',
       JSON_OBJECT('id_tacha', p_id_tacha, 'resultado', v_res));
  COMMIT;
END$$

-- RN18: sortea el orden de las listas ADMITIDAS en la cédula.
-- Reproducible: orden ascendente de SHA-256( semilla | id_lista ).
CREATE PROCEDURE sp_sortear_orden_cedula(
  IN p_id_cargo   INT,
  IN p_semilla    VARCHAR(128),     -- NULL = el sistema genera una
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_proceso INT DEFAULT NULL;
  DECLARE v_estado  VARCHAR(20) DEFAULT NULL;
  DECLARE v_semilla VARCHAR(128);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT p.id_proceso, p.estado INTO v_proceso, v_estado
    FROM cargo_electoral c JOIN proceso_electoral p ON p.id_proceso = c.id_proceso
   WHERE c.id_cargo = p_id_cargo;

  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cargo electoral no existe.';
  END IF;
  IF v_estado NOT IN ('CREADO','INSCRIPCION') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN18: la cedula solo se sortea antes de la VOTACION.';
  END IF;

  SET v_semilla = COALESCE(NULLIF(TRIM(p_semilla), ''), SHA2(CONCAT(UUID(), RAND()), 256));

  DROP TEMPORARY TABLE IF EXISTS tmp_orden_cedula;
  CREATE TEMPORARY TABLE tmp_orden_cedula (id_lista INT PRIMARY KEY, n INT NOT NULL);
  INSERT INTO tmp_orden_cedula (id_lista, n)
  SELECT l.id_lista,
         ROW_NUMBER() OVER (ORDER BY SHA2(CONCAT(v_semilla, '|', l.id_lista), 256))
    FROM lista_electoral l
   WHERE l.id_cargo = p_id_cargo AND l.estado = 'ADMITIDA';

  UPDATE lista_electoral SET orden_cedula = NULL WHERE id_cargo = p_id_cargo;
  UPDATE lista_electoral l
    JOIN tmp_orden_cedula t ON t.id_lista = l.id_lista
     SET l.orden_cedula = t.n;
  DROP TEMPORARY TABLE IF EXISTS tmp_orden_cedula;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'SORTEO_ORDEN_CEDULA',
       JSON_OBJECT('id_cargo', p_id_cargo, 'semilla', v_semilla));
  COMMIT;

  SELECT id_lista, nombre, orden_cedula FROM lista_electoral
   WHERE id_cargo = p_id_cargo AND estado = 'ADMITIDA' ORDER BY orden_cedula;
END$$

-- =====================================================================
-- D. PADRÓN ELECTORAL Y MESAS
-- =====================================================================

-- RF05 / RN03 / RN04: genera el padrón de cada cargo del proceso.
-- Incluye docentes ACTIVOS y habilitados, de la jurisdicción del cargo
-- y de una categoría con derecho a voto. Se puede regenerar mientras no haya mesas.
CREATE PROCEDURE sp_generar_padron(
  IN p_id_proceso INT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_estado VARCHAR(20) DEFAULT NULL;
  DECLARE v_n      INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT estado INTO v_estado FROM proceso_electoral WHERE id_proceso = p_id_proceso FOR UPDATE;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;
  IF v_estado NOT IN ('CREADO','INSCRIPCION') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN04: el padron no se modifica una vez iniciada la votacion.';
  END IF;
  SELECT COUNT(*) INTO v_n FROM mesa_electoral WHERE id_proceso = p_id_proceso;
  IF v_n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existen mesas: el padron no puede regenerarse.';
  END IF;

  DELETE FROM padron_electoral WHERE id_proceso = p_id_proceso;

  INSERT INTO padron_electoral (id_proceso, id_cargo, id_docente)
  SELECT c.id_proceso, c.id_cargo, d.id_docente
    FROM cargo_electoral c
    JOIN docente d
      ON ( c.nivel_jurisdiccion = 'UNIVERSIDAD'
        OR (c.nivel_jurisdiccion = 'FACULTAD'     AND d.id_facultad     = c.id_jurisdiccion)
        OR (c.nivel_jurisdiccion = 'DEPARTAMENTO' AND d.id_departamento = c.id_jurisdiccion) )
   WHERE c.id_proceso = p_id_proceso
     AND d.estado = 'ACTIVO'
     AND d.habilitado_para_votar = 1
     AND ( NOT EXISTS (SELECT 1 FROM cargo_categoria_permitida x WHERE x.id_cargo = c.id_cargo)
        OR EXISTS (SELECT 1 FROM cargo_categoria_permitida x
                    WHERE x.id_cargo = c.id_cargo AND x.categoria = d.categoria AND x.puede_votar = 1) );
  SET v_n = ROW_COUNT();

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'GENERAR_PADRON',
       JSON_OBJECT('registros', v_n));
  COMMIT;

  SELECT cargo, electores_habiles FROM v_participacion_cargo WHERE id_proceso = p_id_proceso;
END$$

-- Crea las mesas necesarias y reparte a los electores en bloques parejos,
-- ordenados por facultad y apellido. p_electores_por_mesa NULL = parámetro ELECTORES_POR_MESA.
CREATE PROCEDURE sp_crear_mesas(
  IN p_id_proceso         INT,
  IN p_electores_por_mesa INT,
  IN p_ubicacion          VARCHAR(200),    -- RN08; NULL = parámetro UBICACION_SUFRAGIO
  IN p_id_usuario         INT
)
BEGIN
  DECLARE v_estado  VARCHAR(20) DEFAULT NULL;
  DECLARE v_tam     INT;
  DECLARE v_total   INT DEFAULT 0;
  DECLARE v_mesas   INT DEFAULT 0;
  DECLARE v_bloque  INT DEFAULT 0;
  DECLARE v_i       INT DEFAULT 1;
  DECLARE v_id_mesa INT;
  DECLARE v_n       INT DEFAULT 0;
  DECLARE v_ubic    VARCHAR(200);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT estado INTO v_estado FROM proceso_electoral WHERE id_proceso = p_id_proceso FOR UPDATE;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;
  IF v_estado NOT IN ('CREADO','INSCRIPCION') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Las mesas se crean antes de iniciar la votacion.';
  END IF;
  SELECT COUNT(*) INTO v_n FROM mesa_electoral WHERE id_proceso = p_id_proceso;
  IF v_n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso ya tiene mesas creadas.';
  END IF;

  SET v_tam = COALESCE(p_electores_por_mesa, fn_parametro_decimal('ELECTORES_POR_MESA'), 200);
  IF v_tam < 6 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN19: una mesa necesita al menos 6 electores para el sorteo.';
  END IF;
  SET v_ubic = COALESCE(NULLIF(TRIM(p_ubicacion), ''),
                        (SELECT valor FROM parametro_global WHERE clave = 'UBICACION_SUFRAGIO'),
                        'Biblioteca Central');

  DROP TEMPORARY TABLE IF EXISTS tmp_elector;
  CREATE TEMPORARY TABLE tmp_elector (n INT PRIMARY KEY, id_docente INT NOT NULL);
  INSERT INTO tmp_elector (n, id_docente)
  SELECT ROW_NUMBER() OVER (ORDER BY d.id_facultad, d.apellidos, d.nombres, d.id_docente), d.id_docente
    FROM docente d
   WHERE d.id_docente IN (SELECT pe.id_docente FROM padron_electoral pe
                           WHERE pe.id_proceso = p_id_proceso AND pe.habilitado_para_votar = 1);

  SELECT COUNT(*) INTO v_total FROM tmp_elector;
  IF v_total = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN04: primero genere el padron electoral.';
  END IF;

  SET v_mesas  = CEIL(v_total / v_tam);
  SET v_bloque = CEIL(v_total / v_mesas);

  WHILE v_i <= v_mesas DO
    SELECT COUNT(*) INTO v_n FROM tmp_elector
     WHERE n > (v_i - 1) * v_bloque AND n <= v_i * v_bloque;

    INSERT INTO mesa_electoral (id_proceso, numero_mesa, ubicacion, total_electores)
    VALUES (p_id_proceso, LPAD(v_i, 3, '0'), v_ubic, v_n);
    SET v_id_mesa = LAST_INSERT_ID();

    UPDATE padron_electoral pe
      JOIN tmp_elector t ON t.id_docente = pe.id_docente
       SET pe.id_mesa = v_id_mesa
     WHERE pe.id_proceso = p_id_proceso
       AND t.n > (v_i - 1) * v_bloque AND t.n <= v_i * v_bloque;

    SET v_i = v_i + 1;
  END WHILE;
  DROP TEMPORARY TABLE IF EXISTS tmp_elector;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'CREAR_MESAS',
       JSON_OBJECT('mesas', v_mesas, 'electores', v_total));
  COMMIT;

  SELECT id_mesa, numero_mesa, ubicacion, total_electores
    FROM mesa_electoral WHERE id_proceso = p_id_proceso ORDER BY numero_mesa;
END$$

-- RF06 / RN19 / RN20 / RNF01: sortea los 6 miembros de una mesa.
--   Elegibles ..... vista v_elegibles_sorteo (sin autoridades, candidatos, personeros
--                   ni miembros de otra mesa); se prefieren los electores de la propia mesa.
--   Algoritmo ..... orden ascendente de SHA-256( semilla | DNI ). Cualquiera puede
--                   repetir el cálculo con la semilla guardada y obtener el mismo resultado.
--   Asignación .... 1 PRESIDENTE, 2 SECRETARIO, 3 VOCAL, 4-6 SUPLENTE.
-- No abre transacción propia para poder invocarse desde sp_sortear_todas_las_mesas.
CREATE PROCEDURE sp_sortear_miembros_mesa(
  IN p_id_mesa    INT,
  IN p_semilla    VARCHAR(128),     -- NULL = el sistema genera una
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_proceso   INT DEFAULT NULL;
  DECLARE v_estado    VARCHAR(20) DEFAULT NULL;
  DECLARE v_semilla   VARCHAR(128);
  DECLARE v_asignados INT DEFAULT 0;
  DECLARE v_n         INT DEFAULT 0;

  SELECT m.id_proceso, p.estado INTO v_proceso, v_estado
    FROM mesa_electoral m JOIN proceso_electoral p ON p.id_proceso = m.id_proceso
   WHERE m.id_mesa = p_id_mesa;

  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no existe.';
  END IF;
  IF v_estado NOT IN ('CREADO','INSCRIPCION') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El sorteo de mesas se realiza antes de la votacion.';
  END IF;
  SELECT COUNT(*) INTO v_n FROM miembro_mesa WHERE id_mesa = p_id_mesa;
  IF v_n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN19: la mesa ya fue sorteada (el cargo es irrenunciable).';
  END IF;

  SET v_semilla = COALESCE(NULLIF(TRIM(p_semilla), ''), SHA2(CONCAT(UUID(), RAND()), 256));
  SELECT COUNT(*) INTO v_asignados FROM padron_electoral WHERE id_mesa = p_id_mesa;

  DROP TEMPORARY TABLE IF EXISTS tmp_sorteo;
  CREATE TEMPORARY TABLE tmp_sorteo (n INT PRIMARY KEY, id_docente INT NOT NULL);
  INSERT INTO tmp_sorteo (n, id_docente)
  SELECT ROW_NUMBER() OVER (ORDER BY SHA2(CONCAT(v_semilla, '|', e.dni), 256)), e.id_docente
    FROM (SELECT DISTINCT id_docente, dni
            FROM v_elegibles_sorteo
           WHERE id_proceso = v_proceso
             AND (v_asignados = 0 OR id_mesa = p_id_mesa)) e;

  SELECT COUNT(*) INTO v_n FROM tmp_sorteo;
  IF v_n < 6 THEN
    DROP TEMPORARY TABLE IF EXISTS tmp_sorteo;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN19: no hay 6 docentes elegibles para sortear esta mesa.';
  END IF;

  INSERT INTO miembro_mesa (id_mesa, id_docente, rol, titular, orden_sorteo)
  SELECT p_id_mesa, t.id_docente,
         CASE t.n WHEN 1 THEN 'PRESIDENTE' WHEN 2 THEN 'SECRETARIO' WHEN 3 THEN 'VOCAL' ELSE 'SUPLENTE' END,
         IF(t.n <= 3, 1, 0),
         t.n
    FROM tmp_sorteo t
   WHERE t.n <= 6;
  DROP TEMPORARY TABLE IF EXISTS tmp_sorteo;

  UPDATE mesa_electoral SET semilla_sorteo = v_semilla, fecha_sorteo = NOW() WHERE id_mesa = p_id_mesa;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'SORTEO_MESA',
       JSON_OBJECT('id_mesa', p_id_mesa, 'semilla', v_semilla, 'algoritmo', 'ORDER BY SHA256(semilla|dni)'));
END$$

-- Sortea todas las mesas pendientes del proceso en una sola transacción.
-- La semilla de cada mesa se deriva de la base: SHA-256( base | numero_mesa ).
CREATE PROCEDURE sp_sortear_todas_las_mesas(
  IN p_id_proceso   INT,
  IN p_semilla_base VARCHAR(128),   -- NULL = el sistema genera una
  IN p_id_usuario   INT
)
BEGIN
  DECLARE v_fin     INT DEFAULT 0;
  DECLARE v_id_mesa INT;
  DECLARE v_numero  VARCHAR(30);
  DECLARE v_base    VARCHAR(128);
  DECLARE v_semilla VARCHAR(128);
  DECLARE cur_mesas CURSOR FOR
    SELECT m.id_mesa, m.numero_mesa
      FROM mesa_electoral m
     WHERE m.id_proceso = p_id_proceso
       AND NOT EXISTS (SELECT 1 FROM miembro_mesa mm WHERE mm.id_mesa = m.id_mesa)
     ORDER BY m.numero_mesa;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = 1;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SET v_base = COALESCE(NULLIF(TRIM(p_semilla_base), ''), SHA2(CONCAT(UUID(), RAND()), 256));

  SET v_fin = 0;
  OPEN cur_mesas;
  bucle: LOOP
    FETCH cur_mesas INTO v_id_mesa, v_numero;
    IF v_fin = 1 THEN
      LEAVE bucle;
    END IF;
    SET v_semilla = SHA2(CONCAT(v_base, '|', v_numero), 256);
    CALL sp_sortear_miembros_mesa(v_id_mesa, v_semilla, p_id_usuario);
    SET v_fin = 0;
  END LOOP;
  CLOSE cur_mesas;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'SORTEO_GENERAL_MESAS',
       JSON_OBJECT('semilla_base', v_base));
  COMMIT;

  SELECT numero_mesa, orden_sorteo, rol, docente, dni
    FROM v_miembros_mesa WHERE id_proceso = p_id_proceso ORDER BY numero_mesa, orden_sorteo;
END$$

-- Registra si un miembro de mesa se presentó (insumo de la multa OMISO_MESA, RN35).
CREATE PROCEDURE sp_registrar_asistencia_miembro(
  IN p_id_mesa    INT,
  IN p_id_docente INT,
  IN p_asistio    BOOLEAN
)
BEGIN
  UPDATE miembro_mesa SET asistio = p_asistio
   WHERE id_mesa = p_id_mesa AND id_docente = p_id_docente;
  IF ROW_COUNT() = 0 AND NOT EXISTS (SELECT 1 FROM miembro_mesa
                                      WHERE id_mesa = p_id_mesa AND id_docente = p_id_docente) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El docente no es miembro de esa mesa.';
  END IF;
END$$

-- =====================================================================
-- E. DÍA DE LA ELECCIÓN
-- =====================================================================

-- RN07 / RN28: instala la mesa y emite el Acta de Instalación.
-- Devuelve el token del QR del acta (solo se muestra esta vez).
CREATE PROCEDURE sp_instalar_mesa(
  IN p_id_mesa    INT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_proceso   INT DEFAULT NULL;
  DECLARE v_estado    VARCHAR(20) DEFAULT NULL;
  DECLARE v_mesa_est  VARCHAR(20) DEFAULT NULL;
  DECLARE v_numero    VARCHAR(30);
  DECLARE v_ubic      VARCHAR(200);
  DECLARE v_total     INT DEFAULT 0;
  DECLARE v_n         INT DEFAULT 0;
  DECLARE v_miembros  LONGTEXT;
  DECLARE v_contenido LONGTEXT;
  DECLARE v_token     CHAR(64);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET SESSION group_concat_max_len = 1000000;
  START TRANSACTION;

  SELECT m.id_proceso, p.estado, m.estado, m.numero_mesa, m.ubicacion, m.total_electores
    INTO v_proceso, v_estado, v_mesa_est, v_numero, v_ubic, v_total
    FROM mesa_electoral m JOIN proceso_electoral p ON p.id_proceso = m.id_proceso
   WHERE m.id_mesa = p_id_mesa
     FOR UPDATE;

  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no existe.';
  END IF;
  IF v_estado <> 'VOTACION' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN07: la mesa se instala con el proceso en VOTACION.';
  END IF;
  IF v_mesa_est <> 'PENDIENTE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa ya fue instalada, cerrada o anulada.';
  END IF;
  SELECT COUNT(*) INTO v_n FROM miembro_mesa WHERE id_mesa = p_id_mesa;
  IF v_n <> 6 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN19: la mesa no tiene sus 6 miembros sorteados.';
  END IF;

  SELECT CONCAT('[', GROUP_CONCAT(
           JSON_OBJECT('dni', d.dni,
                       'docente', CONCAT(d.apellidos, ', ', d.nombres),
                       'rol', CONCAT(mm.rol, ''),
                       'titular', mm.titular)
           ORDER BY mm.orden_sorteo SEPARATOR ','), ']')
    INTO v_miembros
    FROM miembro_mesa mm JOIN docente d ON d.id_docente = mm.id_docente
   WHERE mm.id_mesa = p_id_mesa;

  SET v_contenido = CONCAT(
      '{"tipo":"INSTALACION"',
      ',"id_proceso":', v_proceso,
      ',"mesa":', JSON_QUOTE(v_numero),
      ',"ubicacion":', JSON_QUOTE(v_ubic),
      ',"hora_instalacion":', JSON_QUOTE(DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s')),
      ',"total_electores":', v_total,
      ',"miembros":', COALESCE(v_miembros, '[]'),
      '}');

  UPDATE mesa_electoral SET estado = 'INSTALADA', hora_instalacion = NOW() WHERE id_mesa = p_id_mesa;
  CALL sp_emitir_acta(p_id_mesa, 'INSTALACION', v_contenido, v_token);

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'INSTALAR_MESA',
       JSON_OBJECT('id_mesa', p_id_mesa));
  COMMIT;

  SELECT p_id_mesa AS id_mesa, 'INSTALACION' AS acta, v_token AS token_qr;
END$$

-- CORAZÓN DEL SISTEMA  (RN01, RN04, RN06, RN25, RN27, RF08, RF09)
-- En UNA sola transacción:
--   1. bloquea la fila del padrón (FOR UPDATE) -> imposible el doble voto concurrente
--   2. marca que el docente votó (sabemos QUIÉN)
--   3. inserta el voto anónimo (sabemos QUÉ, sin saber de quién)
--   4. emite la constancia con token QR
-- Si algo falla, no queda ni la marca ni el voto ni la constancia.
-- p_tipo_voto: 'VALIDO' (con p_id_lista) o 'BLANCO' (p_id_lista NULL).
CREATE PROCEDURE sp_emitir_voto(
  IN  p_id_proceso INT,
  IN  p_id_cargo   INT,
  IN  p_id_docente INT,
  IN  p_id_lista   INT,
  IN  p_tipo_voto  VARCHAR(10),
  OUT p_token_constancia CHAR(64)
)
BEGIN
  DECLARE v_estado   VARCHAR(20) DEFAULT NULL;
  DECLARE v_inicio   DATETIME;
  DECLARE v_fin      DATETIME;
  DECLARE v_tipo     VARCHAR(10);
  DECLARE v_hab      INT DEFAULT NULL;
  DECLARE v_ya       INT DEFAULT NULL;
  DECLARE v_mesa     INT DEFAULT NULL;
  DECLARE v_mesa_est VARCHAR(20) DEFAULT NULL;
  DECLARE v_n        INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SET v_tipo = UPPER(TRIM(p_tipo_voto));

  -- Proceso abierto y dentro del horario de sufragio
  SELECT estado, fecha_inicio, fecha_fin INTO v_estado, v_inicio, v_fin
    FROM proceso_electoral WHERE id_proceso = p_id_proceso;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;
  IF v_estado <> 'VOTACION' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN06: el proceso no esta en VOTACION.';
  END IF;
  IF NOW() < v_inicio OR NOW() > v_fin THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN06: fuera del horario de sufragio.';
  END IF;

  -- Tipo de voto (RN25: en voto electrónico no existe el voto nulo)
  IF v_tipo IS NULL OR v_tipo NOT IN ('VALIDO','BLANCO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN25: el voto debe ser VALIDO (por una lista) o BLANCO.';
  END IF;
  IF v_tipo = 'BLANCO' AND p_id_lista IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un voto en BLANCO no lleva lista.';
  END IF;
  IF v_tipo = 'VALIDO' THEN
    SELECT COUNT(*) INTO v_n FROM lista_electoral
     WHERE id_lista = p_id_lista AND id_cargo = p_id_cargo AND estado = 'ADMITIDA';
    IF v_n = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La lista elegida no esta ADMITIDA para este cargo.';
    END IF;
  END IF;

  -- Padrón: bloqueo de fila
  SELECT habilitado_para_votar, ya_voto, id_mesa INTO v_hab, v_ya, v_mesa
    FROM padron_electoral
   WHERE id_proceso = p_id_proceso AND id_cargo = p_id_cargo AND id_docente = p_id_docente
     FOR UPDATE;

  IF v_hab IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN04: el docente no figura en el padron de este cargo.';
  END IF;
  IF v_hab = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN04: el docente no esta habilitado para votar.';
  END IF;
  IF v_ya = 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN01: el docente ya voto por este cargo.';
  END IF;

  -- RN07: su mesa debe estar instalada
  IF v_mesa IS NOT NULL THEN
    SELECT estado INTO v_mesa_est FROM mesa_electoral WHERE id_mesa = v_mesa;
    IF v_mesa_est <> 'INSTALADA' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN07: la mesa del elector no esta INSTALADA.';
    END IF;
  END IF;

  -- 2. quién votó
  UPDATE padron_electoral
     SET ya_voto = 1, fecha_votacion = NOW()
   WHERE id_proceso = p_id_proceso AND id_cargo = p_id_cargo AND id_docente = p_id_docente;

  -- 3. voto anónimo (sin id_docente)
  INSERT INTO voto (id_proceso, id_cargo, id_lista_elegida, tipo_voto, id_mesa)
  VALUES (p_id_proceso, p_id_cargo, IF(v_tipo = 'VALIDO', p_id_lista, NULL), v_tipo, v_mesa);

  -- 4. constancia de participación
  SET p_token_constancia = SHA2(CONCAT(UUID(), RAND(), p_id_docente, NOW(6)), 256);
  INSERT INTO constancia_voto (id_proceso, id_docente, id_cargo, token_qr_hash)
  VALUES (p_id_proceso, p_id_docente, p_id_cargo, SHA2(p_token_constancia, 256));

  -- Bitácora: registra que votó, jamás por quién (RNF05)
  CALL sp_registrar_auditoria(NULL, p_id_docente, p_id_proceso, 'EMITIR_VOTO',
       JSON_OBJECT('id_cargo', p_id_cargo));
  COMMIT;
END$$

-- RN27 / RN28: cierra la mesa y emite las actas de Sufragio y Escrutinio.
CREATE PROCEDURE sp_cerrar_mesa(
  IN p_id_mesa    INT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_proceso   INT DEFAULT NULL;
  DECLARE v_estado    VARCHAR(20) DEFAULT NULL;
  DECLARE v_mesa_est  VARCHAR(20) DEFAULT NULL;
  DECLARE v_numero    VARCHAR(30);
  DECLARE v_total     INT DEFAULT 0;
  DECLARE v_votaron   INT DEFAULT 0;
  DECLARE v_detalle   LONGTEXT;
  DECLARE v_contenido LONGTEXT;
  DECLARE v_token_suf CHAR(64);
  DECLARE v_token_esc CHAR(64);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET SESSION group_concat_max_len = 1000000;
  START TRANSACTION;

  SELECT m.id_proceso, p.estado, m.estado, m.numero_mesa, m.total_electores
    INTO v_proceso, v_estado, v_mesa_est, v_numero, v_total
    FROM mesa_electoral m JOIN proceso_electoral p ON p.id_proceso = m.id_proceso
   WHERE m.id_mesa = p_id_mesa
     FOR UPDATE;

  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no existe.';
  END IF;
  IF v_estado NOT IN ('VOTACION','CERRADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa solo se cierra durante o al termino de la votacion.';
  END IF;
  IF v_mesa_est <> 'INSTALADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se puede cerrar una mesa INSTALADA.';
  END IF;

  SELECT COUNT(DISTINCT id_docente) INTO v_votaron
    FROM padron_electoral WHERE id_mesa = p_id_mesa AND ya_voto = 1;

  -- La mesa deja de recibir votos antes de contar
  UPDATE mesa_electoral SET estado = 'CERRADA', hora_cierre = NOW() WHERE id_mesa = p_id_mesa;

  -- Acta de sufragio
  SET v_contenido = CONCAT(
      '{"tipo":"SUFRAGIO"',
      ',"id_proceso":', v_proceso,
      ',"mesa":', JSON_QUOTE(v_numero),
      ',"hora_cierre":', JSON_QUOTE(DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s')),
      ',"electores_habiles":', v_total,
      ',"electores_que_votaron":', v_votaron,
      ',"electores_omisos":', v_total - v_votaron,
      '}');
  CALL sp_emitir_acta(p_id_mesa, 'SUFRAGIO', v_contenido, v_token_suf);

  -- Acta de escrutinio (conteo por cargo y lista de los votos de esta mesa)
  SELECT CONCAT('[', GROUP_CONCAT(
           JSON_OBJECT('cargo', c.nombre,
                       'lista', COALESCE(l.nombre, CONCAT('VOTO ', x.tipo_voto)),
                       'tipo',  CONCAT(x.tipo_voto, ''),
                       'votos', x.n)
           ORDER BY c.id_cargo, x.n DESC SEPARATOR ','), ']')
    INTO v_detalle
    FROM (SELECT id_cargo, id_lista_elegida, tipo_voto, COUNT(*) AS n
            FROM voto WHERE id_mesa = p_id_mesa
           GROUP BY id_cargo, id_lista_elegida, tipo_voto) x
    JOIN cargo_electoral c ON c.id_cargo = x.id_cargo
    LEFT JOIN lista_electoral l ON l.id_lista = x.id_lista_elegida;

  SET v_contenido = CONCAT(
      '{"tipo":"ESCRUTINIO"',
      ',"id_proceso":', v_proceso,
      ',"mesa":', JSON_QUOTE(v_numero),
      ',"electores_que_votaron":', v_votaron,
      ',"resultados":', COALESCE(v_detalle, '[]'),
      '}');
  CALL sp_emitir_acta(p_id_mesa, 'ESCRUTINIO', v_contenido, v_token_esc);

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'CERRAR_MESA',
       JSON_OBJECT('id_mesa', p_id_mesa, 'votaron', v_votaron));
  COMMIT;

  SELECT p_id_mesa AS id_mesa, v_token_suf AS token_qr_sufragio, v_token_esc AS token_qr_escrutinio;
END$$

-- =====================================================================
-- F. RESULTADOS
-- =====================================================================

-- RN26 / RN27 / RN31 / RN32 / RN33: cómputo oficial e irreversible.
-- Requisitos: proceso CERRADO, todas las mesas cerradas y votos cuadrados.
-- Por cada cargo decide:
--   SIN_QUORUM ...... participación <= quórum mínimo
--   DESIERTO ........ hubo quórum pero ningún voto válido
--   ELEGIDO ......... una lista SUPERA el % mínimo de votos válidos (en 2.ª vuelta: la más votada)
--   SEGUNDA_VUELTA .. ninguna lista supera el % mínimo (o hay empate en 1.ª vuelta)
--   EMPATE .......... empate en segunda vuelta (lo resuelve el CEUNP)
-- El proceso queda FINALIZADO, o ANULADO si ningún cargo alcanzó el quórum.
CREATE PROCEDURE sp_computar_resultados(
  IN p_id_proceso INT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_estado   VARCHAR(20) DEFAULT NULL;
  DECLARE v_tipo     VARCHAR(20) DEFAULT NULL;
  DECLARE v_quorum   DECIMAL(5,2);
  DECLARE v_fin      INT DEFAULT 0;
  DECLARE v_cargo    INT;
  DECLARE v_pct_min  DECIMAL(5,2);
  DECLARE v_hab      INT DEFAULT 0;
  DECLARE v_vot      INT DEFAULT 0;
  DECLARE v_validos  INT DEFAULT 0;
  DECLARE v_top      INT DEFAULT 0;
  DECLARE v_empate   INT DEFAULT 0;
  DECLARE v_ganadora INT DEFAULT NULL;
  DECLARE v_result   VARCHAR(20);
  DECLARE v_n        INT DEFAULT 0;
  DECLARE cur_cargos CURSOR FOR
    SELECT id_cargo, porcentaje_minimo_victoria
      FROM cargo_electoral WHERE id_proceso = p_id_proceso ORDER BY id_cargo;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = 1;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT COUNT(*) INTO v_n FROM proceso_electoral WHERE id_proceso = p_id_proceso;
  IF v_n = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;
  SELECT estado, tipo, quorum_minimo INTO v_estado, v_tipo, v_quorum
    FROM proceso_electoral WHERE id_proceso = p_id_proceso FOR UPDATE;

  IF v_estado <> 'CERRADO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el computo requiere el proceso en estado CERRADO.';
  END IF;
  SELECT COUNT(*) INTO v_n FROM resultado_electoral WHERE id_proceso = p_id_proceso;
  IF v_n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el computo ya fue realizado y es irreversible.';
  END IF;
  -- RN32: todas las mesas deben haber cerrado y emitido sus actas
  SELECT COUNT(*) INTO v_n FROM mesa_electoral
   WHERE id_proceso = p_id_proceso AND estado = 'INSTALADA';
  IF v_n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN32: aun hay mesas instaladas sin cerrar.';
  END IF;
  -- RN27: votos en urna = electores que sufragaron
  SELECT COUNT(*) INTO v_n FROM v_cuadre_votos WHERE id_proceso = p_id_proceso AND diferencia <> 0;
  IF v_n > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN27: los votos no cuadran con el padron. Revise v_cuadre_votos.';
  END IF;

  -- Votos por lista, porcentaje sobre válidos y posición
  INSERT INTO resultado_electoral (id_proceso, id_cargo, id_lista, tipo_voto, total_votos, porcentaje_validos, posicion)
  SELECT x.id_proceso, x.id_cargo, x.id_lista, 'VALIDO', x.n,
         CASE WHEN SUM(x.n) OVER (PARTITION BY x.id_cargo) = 0 THEN 0
              ELSE ROUND(x.n * 100 / SUM(x.n) OVER (PARTITION BY x.id_cargo), 2) END,
         RANK() OVER (PARTITION BY x.id_cargo ORDER BY x.n DESC)
    FROM (SELECT c.id_proceso, c.id_cargo, l.id_lista, COUNT(v.id_voto) AS n
            FROM cargo_electoral c
            JOIN lista_electoral l ON l.id_cargo = c.id_cargo AND l.estado = 'ADMITIDA'
            LEFT JOIN voto v ON v.id_lista_elegida = l.id_lista AND v.tipo_voto = 'VALIDO'
           WHERE c.id_proceso = p_id_proceso
           GROUP BY c.id_proceso, c.id_cargo, l.id_lista) x;

  -- Blancos y nulos (id_lista NULL)
  INSERT INTO resultado_electoral (id_proceso, id_cargo, id_lista, tipo_voto, total_votos)
  SELECT c.id_proceso, c.id_cargo, NULL, 'BLANCO',
         (SELECT COUNT(*) FROM voto v WHERE v.id_cargo = c.id_cargo AND v.tipo_voto = 'BLANCO')
    FROM cargo_electoral c WHERE c.id_proceso = p_id_proceso;
  INSERT INTO resultado_electoral (id_proceso, id_cargo, id_lista, tipo_voto, total_votos)
  SELECT c.id_proceso, c.id_cargo, NULL, 'NULO',
         (SELECT COUNT(*) FROM voto v WHERE v.id_cargo = c.id_cargo AND v.tipo_voto = 'NULO')
    FROM cargo_electoral c WHERE c.id_proceso = p_id_proceso;

  -- Decisión por cargo (solo consultas con agregados: siempre devuelven una fila)
  SET v_fin = 0;
  OPEN cur_cargos;
  bucle: LOOP
    FETCH cur_cargos INTO v_cargo, v_pct_min;
    IF v_fin = 1 THEN
      LEAVE bucle;
    END IF;

    SELECT COUNT(*), COALESCE(SUM(ya_voto), 0) INTO v_hab, v_vot
      FROM padron_electoral WHERE id_cargo = v_cargo AND habilitado_para_votar = 1;

    SELECT COALESCE(SUM(total_votos), 0), COALESCE(MAX(total_votos), 0) INTO v_validos, v_top
      FROM resultado_electoral WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO';

    SELECT COUNT(*), MIN(id_lista) INTO v_empate, v_ganadora
      FROM resultado_electoral
     WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO' AND total_votos = v_top;

    IF v_hab = 0 OR (v_vot * 100 / v_hab) <= v_quorum THEN
      SET v_result = 'SIN_QUORUM';
    ELSEIF v_validos = 0 THEN
      SET v_result = 'DESIERTO';
    ELSEIF v_tipo = 'SEGUNDA_VUELTA' THEN
      SET v_result = IF(v_empate = 1, 'ELEGIDO', 'EMPATE');
    ELSEIF v_empate = 1 AND (v_top * 100 / v_validos) > v_pct_min THEN
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

  SELECT COUNT(*) INTO v_n FROM cargo_electoral
   WHERE id_proceso = p_id_proceso AND estado_resultado <> 'SIN_QUORUM';

  IF v_n = 0 THEN
    UPDATE proceso_electoral
       SET estado = 'ANULADO', motivo_anulacion = 'RN31: no se alcanzo el quorum minimo de participacion.'
     WHERE id_proceso = p_id_proceso;
  ELSE
    UPDATE proceso_electoral SET estado = 'FINALIZADO' WHERE id_proceso = p_id_proceso;
  END IF;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'COMPUTAR_RESULTADOS',
       JSON_OBJECT('cargos_con_quorum', v_n));
  COMMIT;

  SELECT c.nombre AS cargo, c.estado_resultado, l.nombre AS lista_ganadora,
         fn_participacion_cargo(c.id_cargo) AS participacion_pct
    FROM cargo_electoral c
    LEFT JOIN lista_electoral l ON l.id_lista = c.id_lista_ganadora
   WHERE c.id_proceso = p_id_proceso;
END$$

-- RN33: crea el proceso de segunda vuelta para los cargos en estado SEGUNDA_VUELTA.
-- Clona el cargo, sus categorías, las DOS listas más votadas (con sus candidatos) y el padrón.
-- El nuevo proceso nace en CREADO: faltan mesas, sorteo de miembros y sorteo de cédula.
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

    -- Las dos listas más votadas (agregados: no disparan el handler NOT FOUND)
    SELECT MIN(id_lista) INTO v_l1
      FROM resultado_electoral
     WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO' AND posicion = 1;
    SELECT MIN(id_lista) INTO v_l2
      FROM resultado_electoral
     WHERE id_cargo = v_cargo AND tipo_voto = 'VALIDO' AND id_lista <> v_l1
       AND total_votos = (SELECT MAX(r2.total_votos) FROM resultado_electoral r2
                           WHERE r2.id_cargo = v_cargo AND r2.tipo_voto = 'VALIDO' AND r2.id_lista <> v_l1);

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

-- =====================================================================
-- G. SANCIONES
-- =====================================================================

-- RN35: genera las multas del proceso (se puede ejecutar más de una vez sin duplicar).
--   OMISO_VOTACION .. habilitado en el padrón que no votó por ningún cargo
--   OMISO_MESA ...... miembro TITULAR con asistio = FALSE
-- Monto = UIT * porcentaje / 100, tomados de parametro_global.
CREATE PROCEDURE sp_generar_multas(
  IN p_id_proceso INT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_estado   VARCHAR(20) DEFAULT NULL;
  DECLARE v_uit      DECIMAL(12,2);
  DECLARE v_pct_elec DECIMAL(12,2);
  DECLARE v_pct_mesa DECIMAL(12,2);
  DECLARE v_n1       INT DEFAULT 0;
  DECLARE v_n2       INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT estado INTO v_estado FROM proceso_electoral WHERE id_proceso = p_id_proceso;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proceso electoral no existe.';
  END IF;
  IF v_estado NOT IN ('CERRADO','FINALIZADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN35: las multas se generan con la votacion ya cerrada.';
  END IF;

  SET v_uit      = fn_parametro_decimal('UIT');
  SET v_pct_elec = fn_parametro_decimal('MULTA_ELECTOR_OMISO_PCT');
  SET v_pct_mesa = fn_parametro_decimal('MULTA_MIEMBRO_MESA_OMISO_PCT');
  IF v_uit IS NULL OR v_pct_elec IS NULL OR v_pct_mesa IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Faltan parametros: UIT y porcentajes de multa.';
  END IF;

  INSERT INTO multa (id_docente, id_proceso, motivo, uit_referencia, porcentaje_uit, monto)
  SELECT x.id_docente, p_id_proceso, 'OMISO_VOTACION', v_uit, v_pct_elec, ROUND(v_uit * v_pct_elec / 100, 2)
    FROM (SELECT id_docente
            FROM padron_electoral
           WHERE id_proceso = p_id_proceso AND habilitado_para_votar = 1
           GROUP BY id_docente
          HAVING MAX(ya_voto) = 0) x
  ON DUPLICATE KEY UPDATE observacion = multa.observacion;
  SET v_n1 = ROW_COUNT();

  INSERT INTO multa (id_docente, id_proceso, motivo, uit_referencia, porcentaje_uit, monto)
  SELECT mm.id_docente, p_id_proceso, 'OMISO_MESA', v_uit, v_pct_mesa, ROUND(v_uit * v_pct_mesa / 100, 2)
    FROM miembro_mesa mm
    JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
   WHERE m.id_proceso = p_id_proceso AND mm.titular = 1 AND mm.asistio = 0
  ON DUPLICATE KEY UPDATE observacion = multa.observacion;
  SET v_n2 = ROW_COUNT();

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'GENERAR_MULTAS',
       JSON_OBJECT('omisos_votacion', v_n1, 'omisos_mesa', v_n2));
  COMMIT;

  SELECT motivo, COUNT(*) AS multas, SUM(monto) AS total_soles
    FROM multa WHERE id_proceso = p_id_proceso GROUP BY motivo;
END$$

-- Registra el pago o la exoneración de una multa.
CREATE PROCEDURE sp_actualizar_multa(
  IN p_id_multa    INT,
  IN p_estado_pago VARCHAR(12),     -- PAGADA / EXONERADA / PENDIENTE
  IN p_observacion VARCHAR(300),
  IN p_id_usuario  INT
)
BEGIN
  DECLARE v_proceso INT DEFAULT NULL;
  DECLARE v_docente INT DEFAULT NULL;
  DECLARE v_est     VARCHAR(12);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SET v_est = UPPER(p_estado_pago);

  SELECT id_proceso, id_docente INTO v_proceso, v_docente FROM multa WHERE id_multa = p_id_multa FOR UPDATE;
  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La multa no existe.';
  END IF;
  IF v_est IS NULL OR v_est NOT IN ('PENDIENTE','PAGADA','EXONERADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estado de pago invalido.';
  END IF;

  UPDATE multa
     SET estado_pago = v_est,
         fecha_pago  = IF(v_est = 'PAGADA', NOW(), NULL),
         observacion = COALESCE(p_observacion, observacion)
   WHERE id_multa = p_id_multa;

  CALL sp_registrar_auditoria(p_id_usuario, v_docente, v_proceso, 'ACTUALIZAR_MULTA',
       JSON_OBJECT('id_multa', p_id_multa, 'estado', v_est));
  COMMIT;
END$$

-- =====================================================================
-- H. VERIFICACIÓN POR QR
-- =====================================================================

-- Verifica una constancia de voto a partir del token del QR.
-- Informa que el docente participó; nunca por quién votó.
CREATE PROCEDURE sp_verificar_constancia(IN p_token CHAR(64))
BEGIN
  SELECT cv.id_constancia, p.nombre AS proceso, c.nombre AS cargo,
         CONCAT(d.nombres, ' ', d.apellidos) AS docente,
         cv.fecha_emision, cv.estado,
         CASE WHEN cv.estado = 'VIGENTE'
               AND (cv.fecha_expiracion IS NULL OR cv.fecha_expiracion >= NOW())
              THEN 1 ELSE 0 END AS es_valida
    FROM constancia_voto cv
    JOIN proceso_electoral p ON p.id_proceso = cv.id_proceso
    JOIN cargo_electoral c   ON c.id_cargo = cv.id_cargo
    JOIN docente d           ON d.id_docente = cv.id_docente
   WHERE cv.token_qr_hash = SHA2(p_token, 256);
END$$

-- Verifica un acta: recalcula el SHA-256 del contenido y lo compara con la huella guardada.
CREATE PROCEDURE sp_verificar_acta(IN p_token CHAR(64))
BEGIN
  SELECT a.id_acta, m.numero_mesa, a.tipo, a.fecha_emision, a.estado,
         a.hash_integridad,
         CASE WHEN SHA2(a.contenido_json, 256) = a.hash_integridad THEN 1 ELSE 0 END AS contenido_integro,
         a.contenido_json
    FROM acta_electoral a
    JOIN mesa_electoral m ON m.id_mesa = a.id_mesa
   WHERE a.token_qr_hash = SHA2(p_token, 256);
END$$

DELIMITER ;
