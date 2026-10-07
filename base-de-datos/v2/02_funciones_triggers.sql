-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 02_funciones_triggers.sql  ·  Funciones y disparadores
-- Los triggers protegen las reglas aunque el INSERT/UPDATE venga del
-- backend (JPA) y no de un procedimiento almacenado.
-- =====================================================================
USE elecciones_unp;
-- Las rutinas guardan el sql_mode vigente al crearse: se fuerza modo estricto
-- (XAMPP viene sin STRICT y aceptaria valores invalidos en silencio).
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';

DROP FUNCTION IF EXISTS fn_parametro_decimal;
DROP FUNCTION IF EXISTS fn_tiene_cargo_excluyente;
DROP FUNCTION IF EXISTS fn_participacion_cargo;
DROP FUNCTION IF EXISTS fn_proceso_de_lista;

DROP TRIGGER IF EXISTS trg_docente_bi;
DROP TRIGGER IF EXISTS trg_docente_bu;
DROP TRIGGER IF EXISTS trg_proceso_bu;
DROP TRIGGER IF EXISTS trg_cargo_bi;
DROP TRIGGER IF EXISTS trg_cargo_bu;
DROP TRIGGER IF EXISTS trg_candidato_bi;
DROP TRIGGER IF EXISTS trg_personero_bi;
DROP TRIGGER IF EXISTS trg_miembro_mesa_bi;
DROP TRIGGER IF EXISTS trg_padron_bu;
DROP TRIGGER IF EXISTS trg_padron_bd;
DROP TRIGGER IF EXISTS trg_voto_bi;
DROP TRIGGER IF EXISTS trg_voto_bu;
DROP TRIGGER IF EXISTS trg_voto_bd;
DROP TRIGGER IF EXISTS trg_acta_bu;
DROP TRIGGER IF EXISTS trg_acta_bd;
DROP TRIGGER IF EXISTS trg_resultado_bu;
DROP TRIGGER IF EXISTS trg_resultado_bd;
DROP TRIGGER IF EXISTS trg_log_bu;
DROP TRIGGER IF EXISTS trg_log_bd;

DELIMITER $$

-- ---------------------------------------------------------------------
-- FUNCIONES
-- ---------------------------------------------------------------------

-- Lee un parámetro numérico (UIT, porcentajes, tamaños). Devuelve NULL si no existe.
CREATE FUNCTION fn_parametro_decimal(p_clave VARCHAR(80))
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
  DECLARE v_valor DECIMAL(12,2) DEFAULT NULL;
  SELECT CAST(valor AS DECIMAL(12,2)) INTO v_valor
    FROM parametro_global WHERE clave = p_clave LIMIT 1;
  RETURN v_valor;
END$$

-- RN20 / RN21: ¿el docente ejerce hoy un cargo que figura en el catálogo de excluidos?
CREATE FUNCTION fn_tiene_cargo_excluyente(p_id_docente INT)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
  DECLARE v_n INT DEFAULT 0;
  SELECT COUNT(*) INTO v_n
    FROM cargo_admin ca
    JOIN cargo_excluido_sorteo ce ON ce.nombre_cargo = ca.nombre_cargo AND ce.activo = 1
   WHERE ca.id_docente = p_id_docente
     AND ca.vigente = 1
     AND ca.fecha_inicio <= CURDATE()
     AND (ca.fecha_fin IS NULL OR ca.fecha_fin >= CURDATE());
  RETURN v_n > 0;
END$$

-- RN31: % de participación de un cargo (votaron / habilitados * 100)
CREATE FUNCTION fn_participacion_cargo(p_id_cargo INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
  DECLARE v_hab INT DEFAULT 0;
  DECLARE v_vot INT DEFAULT 0;
  SELECT COUNT(*), COALESCE(SUM(ya_voto), 0) INTO v_hab, v_vot
    FROM padron_electoral
   WHERE id_cargo = p_id_cargo AND habilitado_para_votar = 1;
  IF v_hab = 0 THEN
    RETURN 0;
  END IF;
  RETURN ROUND(v_vot * 100 / v_hab, 2);
END$$

-- Proceso al que pertenece una lista
CREATE FUNCTION fn_proceso_de_lista(p_id_lista INT)
RETURNS INT
READS SQL DATA
BEGIN
  DECLARE v_id INT DEFAULT NULL;
  SELECT c.id_proceso INTO v_id
    FROM lista_electoral l
    JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
   WHERE l.id_lista = p_id_lista LIMIT 1;
  RETURN v_id;
END$$

-- ---------------------------------------------------------------------
-- DOCENTE: la facultad siempre es la del departamento; solo ACTIVO vota (RN03)
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_docente_bi BEFORE INSERT ON docente
FOR EACH ROW
BEGIN
  DECLARE v_fac INT DEFAULT NULL;
  SELECT id_facultad INTO v_fac FROM departamento WHERE id_departamento = NEW.id_departamento;
  IF v_fac IS NOT NULL THEN
    SET NEW.id_facultad = v_fac;
  END IF;
  IF NEW.estado <> 'ACTIVO' THEN
    SET NEW.habilitado_para_votar = 0;
  END IF;
END$$

CREATE TRIGGER trg_docente_bu BEFORE UPDATE ON docente
FOR EACH ROW
BEGIN
  DECLARE v_fac INT DEFAULT NULL;
  SELECT id_facultad INTO v_fac FROM departamento WHERE id_departamento = NEW.id_departamento;
  IF v_fac IS NOT NULL THEN
    SET NEW.id_facultad = v_fac;
  END IF;
  IF NEW.estado <> 'ACTIVO' THEN
    SET NEW.habilitado_para_votar = 0;
  END IF;
END$$

-- ---------------------------------------------------------------------
-- PROCESO: FINALIZADO y ANULADO son estados terminales (RN26 / RN34)
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_proceso_bu BEFORE UPDATE ON proceso_electoral
FOR EACH ROW
BEGIN
  IF OLD.estado IN ('FINALIZADO','ANULADO') AND NEW.estado <> OLD.estado THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Un proceso FINALIZADO o ANULADO no puede cambiar de estado.';
  END IF;
END$$

-- ---------------------------------------------------------------------
-- CARGO: valida que la jurisdicción exista según el nivel
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_cargo_bi BEFORE INSERT ON cargo_electoral
FOR EACH ROW
BEGIN
  IF NEW.nivel_jurisdiccion = 'UNIVERSIDAD' THEN
    SET NEW.id_jurisdiccion = NULL;
  ELSEIF NEW.nivel_jurisdiccion = 'FACULTAD'
     AND NOT EXISTS (SELECT 1 FROM facultad WHERE id_facultad = NEW.id_jurisdiccion) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'La facultad indicada como jurisdiccion del cargo no existe.';
  ELSEIF NEW.nivel_jurisdiccion = 'DEPARTAMENTO'
     AND NOT EXISTS (SELECT 1 FROM departamento WHERE id_departamento = NEW.id_jurisdiccion) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El departamento indicado como jurisdiccion del cargo no existe.';
  END IF;
END$$

CREATE TRIGGER trg_cargo_bu BEFORE UPDATE ON cargo_electoral
FOR EACH ROW
BEGIN
  IF NEW.nivel_jurisdiccion = 'UNIVERSIDAD' THEN
    SET NEW.id_jurisdiccion = NULL;
  ELSEIF NEW.nivel_jurisdiccion = 'FACULTAD'
     AND NOT EXISTS (SELECT 1 FROM facultad WHERE id_facultad = NEW.id_jurisdiccion) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'La facultad indicada como jurisdiccion del cargo no existe.';
  ELSEIF NEW.nivel_jurisdiccion = 'DEPARTAMENTO'
     AND NOT EXISTS (SELECT 1 FROM departamento WHERE id_departamento = NEW.id_jurisdiccion) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El departamento indicado como jurisdiccion del cargo no existe.';
  END IF;
END$$

-- ---------------------------------------------------------------------
-- CANDIDATO: RN11 (no puede estar en dos listas del mismo proceso)
--            y no puede ser personero ni miembro de mesa del proceso
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_candidato_bi BEFORE INSERT ON candidato
FOR EACH ROW
BEGIN
  DECLARE v_proceso INT;
  SET v_proceso = fn_proceso_de_lista(NEW.id_lista);

  IF EXISTS (SELECT 1
               FROM candidato ca
               JOIN lista_electoral l ON l.id_lista = ca.id_lista
               JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
              WHERE ca.id_docente = NEW.id_docente
                AND c.id_proceso = v_proceso
                AND ca.id_lista <> NEW.id_lista
                AND ca.estado_validacion <> 'EXCLUIDO') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN11: el docente ya es candidato en otra lista de este proceso.';
  END IF;

  IF EXISTS (SELECT 1
               FROM personero p
               JOIN lista_electoral l ON l.id_lista = p.id_lista
               JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
              WHERE p.id_docente = NEW.id_docente
                AND c.id_proceso = v_proceso
                AND p.estado_acreditacion <> 'REVOCADO') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN21: un personero no puede ser candidato en el mismo proceso.';
  END IF;

  IF EXISTS (SELECT 1
               FROM miembro_mesa mm
               JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
              WHERE mm.id_docente = NEW.id_docente
                AND m.id_proceso = v_proceso) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN20: un miembro de mesa no puede ser candidato en el mismo proceso.';
  END IF;
END$$

-- ---------------------------------------------------------------------
-- PERSONERO: RN21 (no candidato, no autoridad)
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_personero_bi BEFORE INSERT ON personero
FOR EACH ROW
BEGIN
  DECLARE v_proceso INT;
  SET v_proceso = fn_proceso_de_lista(NEW.id_lista);

  IF EXISTS (SELECT 1
               FROM candidato ca
               JOIN lista_electoral l ON l.id_lista = ca.id_lista
               JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
              WHERE ca.id_docente = NEW.id_docente
                AND c.id_proceso = v_proceso
                AND ca.estado_validacion <> 'EXCLUIDO') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN21: un candidato no puede ser personero en el mismo proceso.';
  END IF;

  IF fn_tiene_cargo_excluyente(NEW.id_docente) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN21: una autoridad vigente no puede ser personero.';
  END IF;

  IF NEW.id_mesa IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM mesa_electoral
                      WHERE id_mesa = NEW.id_mesa AND id_proceso = v_proceso) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'La mesa del personero no pertenece al proceso de su lista.';
  END IF;
END$$

-- ---------------------------------------------------------------------
-- MIEMBRO DE MESA: RN20 (ni candidato, ni personero, ni autoridad)
--                  y una sola mesa por proceso
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_miembro_mesa_bi BEFORE INSERT ON miembro_mesa
FOR EACH ROW
BEGIN
  DECLARE v_proceso INT DEFAULT NULL;
  SELECT id_proceso INTO v_proceso FROM mesa_electoral WHERE id_mesa = NEW.id_mesa;

  IF EXISTS (SELECT 1
               FROM miembro_mesa mm
               JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
              WHERE mm.id_docente = NEW.id_docente
                AND m.id_proceso = v_proceso
                AND mm.id_mesa <> NEW.id_mesa) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El docente ya es miembro de otra mesa en este proceso.';
  END IF;

  IF EXISTS (SELECT 1
               FROM candidato ca
               JOIN lista_electoral l ON l.id_lista = ca.id_lista
               JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
              WHERE ca.id_docente = NEW.id_docente
                AND c.id_proceso = v_proceso
                AND ca.estado_validacion <> 'EXCLUIDO') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN20: un candidato no puede ser miembro de mesa.';
  END IF;

  IF EXISTS (SELECT 1
               FROM personero p
               JOIN lista_electoral l ON l.id_lista = p.id_lista
               JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
              WHERE p.id_docente = NEW.id_docente
                AND c.id_proceso = v_proceso
                AND p.estado_acreditacion <> 'REVOCADO') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN20: un personero no puede ser miembro de mesa.';
  END IF;

  IF fn_tiene_cargo_excluyente(NEW.id_docente) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN20: una autoridad vigente no puede ser miembro de mesa.';
  END IF;
END$$

-- ---------------------------------------------------------------------
-- PADRÓN: nadie "des-vota"; solo se marca el voto con el proceso en VOTACION
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_padron_bu BEFORE UPDATE ON padron_electoral
FOR EACH ROW
BEGIN
  DECLARE v_estado VARCHAR(20) DEFAULT NULL;

  IF OLD.ya_voto = 1 AND (NEW.ya_voto = 0
        OR NEW.id_docente <> OLD.id_docente
        OR NEW.id_cargo   <> OLD.id_cargo
        OR NEW.id_proceso <> OLD.id_proceso) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN01: no se puede revertir ni reasignar un registro de padron que ya voto.';
  END IF;

  IF OLD.ya_voto = 0 AND NEW.ya_voto = 1 THEN
    SELECT estado INTO v_estado FROM proceso_electoral WHERE id_proceso = NEW.id_proceso;
    IF v_estado <> 'VOTACION' THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN06: solo se registra el sufragio con el proceso en VOTACION.';
    END IF;
    IF NEW.habilitado_para_votar = 0 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN04: el docente no esta habilitado en el padron.';
    END IF;
    IF NEW.fecha_votacion IS NULL THEN
      SET NEW.fecha_votacion = NOW();
    END IF;
  END IF;
END$$

CREATE TRIGGER trg_padron_bd BEFORE DELETE ON padron_electoral
FOR EACH ROW
BEGIN
  IF OLD.ya_voto = 1 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No se puede eliminar del padron a un docente que ya voto.';
  END IF;
END$$

-- ---------------------------------------------------------------------
-- VOTO: solo durante la votación, con hora truncada, e inmutable (RN26)
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_voto_bi BEFORE INSERT ON voto
FOR EACH ROW
BEGIN
  DECLARE v_estado VARCHAR(20) DEFAULT NULL;
  SELECT estado INTO v_estado FROM proceso_electoral WHERE id_proceso = NEW.id_proceso;
  IF v_estado IS NULL OR v_estado <> 'VOTACION' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN06: solo se aceptan votos con el proceso en VOTACION.';
  END IF;

  IF NEW.id_lista_elegida IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM lista_electoral
                      WHERE id_lista = NEW.id_lista_elegida AND estado = 'ADMITIDA') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Solo se puede votar por listas ADMITIDAS.';
  END IF;

  -- Secreto del voto: se guarda solo la hora (sin minutos ni segundos) para que no
  -- se pueda cruzar con padron_electoral.fecha_votacion ni con la bitácora.
  SET NEW.fecha_hora = DATE_FORMAT(NOW(), '%Y-%m-%d %H:00:00');
END$$

CREATE TRIGGER trg_voto_bu BEFORE UPDATE ON voto
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: los votos son inmutables.';
END$$

CREATE TRIGGER trg_voto_bd BEFORE DELETE ON voto
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: los votos no se pueden eliminar.';
END$$

-- ---------------------------------------------------------------------
-- ACTAS: el contenido y su huella no cambian; solo se puede ANULAR (RN28)
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_acta_bu BEFORE UPDATE ON acta_electoral
FOR EACH ROW
BEGIN
  IF NEW.contenido_json  <> OLD.contenido_json
     OR NEW.hash_integridad <> OLD.hash_integridad
     OR NEW.token_qr_hash   <> OLD.token_qr_hash
     OR NEW.id_mesa <> OLD.id_mesa
     OR NEW.tipo    <> OLD.tipo
     OR NEW.fecha_emision <> OLD.fecha_emision THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RN28: el contenido de un acta emitida no se puede modificar.';
  END IF;
END$$

CREATE TRIGGER trg_acta_bd BEFORE DELETE ON acta_electoral
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN28: las actas no se eliminan, se anulan.';
END$$

-- ---------------------------------------------------------------------
-- RESULTADOS: cómputo irreversible (RN26)
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_resultado_bu BEFORE UPDATE ON resultado_electoral
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el computo oficial es irreversible.';
END$$

CREATE TRIGGER trg_resultado_bd BEFORE DELETE ON resultado_electoral
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el computo oficial es irreversible.';
END$$

-- ---------------------------------------------------------------------
-- BITÁCORA: registro inmutable
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_log_bu BEFORE UPDATE ON log_auditoria
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La bitacora de auditoria es inmutable.';
END$$

CREATE TRIGGER trg_log_bd BEFORE DELETE ON log_auditoria
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La bitacora de auditoria es inmutable.';
END$$

DELIMITER ;
