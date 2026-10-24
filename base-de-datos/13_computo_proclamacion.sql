-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 13_computo_proclamacion.sql  ·  CUS14 Computar y proclamar resultados
--                                  (CUN11, módulo M12: RF89 a RF99)
--
-- Diagrama de colaboración «Computar y proclamar» (modelo Rose, CUS14):
--   0-1   solicitarComputo(idProceso) / ejecutarComputo(idProceso)
--   2-3   verificarActasEntregadas(idProceso) / actasEntregadas(totalMesas)  -> v_computo_mesas      (RF89, RN32)
--   4-5   validarIntegridad(actas) / actasValidas(hashCorrecto)              -> v_computo_actas,
--                                                                              sp_marcar_acta_dudosa,
--                                                                              sp_comprobar_acta     (RF90)
--   6-7   consolidarVotos(idCargo) / totalesPorLista(votos)                  -> v_computo_resultados (RF92)
--   8-9   calcularParticipacion(idCargo) / porcentajeParticipacion(porcentaje) -> v_participacion_cargo (RF93)
--   10-11 validarQuorum(porcentaje) / quorumValidado(estado)                 -> sp_ejecutar_computo  (RN31)
--   12-13 [quorum > 60%] registrarComputo(totales) / computoRegistrado(resultados)
--   14-15 determinarGanador(resultados) / ganadorOSegundaVuelta(idLista)     -> sp_ejecutar_computo  (RF96, RF97)
--   16-17 [supera minimo] acreditarGanadora(idLista) / listaAcreditada()     -> sp_proclamar_resultados (RF98)
--   18-19 mostrarResultados(resultados) / resultadosProclamados()            -> sp_publicar_resultados  (RF99)
--
-- Tabla 39 (CUS14) del informe v2.1:
--   1-3  verificación previa: mesas instaladas y no instaladas, sus tres actas y la autenticidad
--        de las actas dudosas (QR y huella SHA-256).
--   4    sesión de cómputo general con los personeros presentes (asistencia facultativa, RF91).
--   5-6  consolidación de los votos de las actas habilitadas y participación (> 60 %, RN31).
--   7    el CEUNP resuelve las nulidades pendientes y el cómputo se recalcula sin las mesas anuladas.
--   8    lista ganadora o segunda vuelta (RN33).
--   9    proclamación, acta general con QR y publicación.
--   A1   la participación no supera el 60 %: nulidad total (RN31, RN34).
--   A2   ninguna lista alcanza el mínimo legal: segunda vuelta entre las dos más votadas dentro de
--        15 días (sp_convocar_segunda_vuelta).
--   A3   un acta difiere del resultado consolidado: el CEUNP la califica (sp_calificar_mesa, RF95).
--
-- Insumos: el conteo oficial de cada mesa es el de la cédula física del acta de escrutinio
-- (CUS12, RF84) y las cédulas impugnadas suman a la opción que fijó la mesa o el CEUNP
-- (v_impugnacion_efecto, CUS13).
--
-- Uso: en una base ya creada, después de 12_impugnaciones_apelaciones.sql (CUS13). No borra
-- datos. Se puede volver a ejecutar. 00_script_unico_elecciones_unp.sql (sección 5d) ya lo incluye.
-- =====================================================================
USE elecciones_unp;
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 1. Tablas nuevas
-- ---------------------------------------------------------------------

-- ComputoGeneral del informe: una fila por proceso. Guarda la sesión de cómputo (RF91), el
-- cómputo con su acta general (RF92, huella SHA-256 y QR), la proclamación (RF98) y la
-- publicación en el portal (RF99).
CREATE TABLE IF NOT EXISTS computo_proceso (
  id_proceso              INT PRIMARY KEY,
  estado                  ENUM('SESION_INSTALADA','COMPUTADO','PROCLAMADO','PUBLICADO') NOT NULL DEFAULT 'SESION_INSTALADA',
  -- 4: sesión de cómputo general (RF91)
  lugar_sesion            VARCHAR(200) NOT NULL,
  miembros_ceunp          TINYINT NOT NULL,            -- miembros del Pleno presentes (RN36: quórum)
  observaciones_sesion    VARCHAR(1000) NULL,
  fecha_sesion            DATETIME NOT NULL,
  id_usuario_sesion       INT NULL,
  -- 5-8: cómputo y acta general de sufragios (RF92, RF93, RF96)
  fecha_computo           DATETIME NULL,
  mesas_total             INT NULL,
  mesas_computadas        INT NULL,
  mesas_no_instaladas     INT NULL,
  mesas_anuladas          INT NULL,
  actas_verificadas       INT NULL,
  electores_habiles       INT NULL,
  votaron                 INT NULL,
  participacion_pct       DECIMAL(5,2) NULL,
  resultado               ENUM('VALIDA','NULIDAD_TOTAL') NULL,
  contenido_json          LONGTEXT NULL,
  hash_integridad         CHAR(64) NULL,
  token_qr_hash           CHAR(64) NULL,
  id_usuario_computo      INT NULL,
  -- 9: proclamación por el Presidente del CEUNP (RF98)
  numero_resolucion       VARCHAR(40) NULL,
  miembros_pleno          TINYINT NULL,
  presidente_ceunp        VARCHAR(150) NULL,
  fundamento_proclamacion VARCHAR(1000) NULL,
  fecha_proclamacion      DATETIME NULL,
  contenido_proclamacion  LONGTEXT NULL,
  hash_proclamacion       CHAR(64) NULL,
  token_proclamacion_hash CHAR(64) NULL,
  id_usuario_proclamacion INT NULL,
  -- publicación en el portal (RF99)
  fecha_publicacion       DATETIME NULL,
  id_usuario_publicacion  INT NULL,
  UNIQUE KEY uq_computo_token (token_qr_hash),
  UNIQUE KEY uq_computo_token_proclamacion (token_proclamacion_hash),
  UNIQUE KEY uq_computo_resolucion (numero_resolucion),
  CONSTRAINT chk_computo_json CHECK (contenido_json IS NULL OR JSON_VALID(contenido_json)),
  CONSTRAINT chk_computo_proclamacion_json CHECK (contenido_proclamacion IS NULL OR JSON_VALID(contenido_proclamacion)),
  CONSTRAINT chk_computo_acta CHECK (estado = 'SESION_INSTALADA'
    OR (fecha_computo IS NOT NULL AND contenido_json IS NOT NULL AND hash_integridad IS NOT NULL AND resultado IS NOT NULL)),
  CONSTRAINT chk_computo_publicado CHECK (estado <> 'PUBLICADO' OR fecha_publicacion IS NOT NULL),
  CONSTRAINT fk_computo_proceso      FOREIGN KEY (id_proceso)              REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_computo_u_sesion     FOREIGN KEY (id_usuario_sesion)       REFERENCES usuario(id_usuario),
  CONSTRAINT fk_computo_u_computo    FOREIGN KEY (id_usuario_computo)      REFERENCES usuario(id_usuario),
  CONSTRAINT fk_computo_u_proclama   FOREIGN KEY (id_usuario_proclamacion) REFERENCES usuario(id_usuario),
  CONSTRAINT fk_computo_u_publica    FOREIGN KEY (id_usuario_publicacion)  REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- RF91: personeros acreditados presentes en la sesión de cómputo (asistencia facultativa)
CREATE TABLE IF NOT EXISTS computo_personero (
  id_proceso    INT NOT NULL,
  id_personero  INT NOT NULL,
  hora_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_usuario    INT NULL,
  PRIMARY KEY (id_proceso, id_personero),
  CONSTRAINT fk_cpers_computo   FOREIGN KEY (id_proceso)   REFERENCES computo_proceso(id_proceso),
  CONSTRAINT fk_cpers_personero FOREIGN KEY (id_personero) REFERENCES personero(id_personero),
  CONSTRAINT fk_cpers_usuario   FOREIGN KEY (id_usuario)   REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- RF90: acta marcada como dudosa y comprobación de su autenticidad (QR y huella SHA-256)
CREATE TABLE IF NOT EXISTS verificacion_acta (
  id_acta                 INT PRIMARY KEY,
  id_proceso              INT NOT NULL,
  id_mesa                 INT NOT NULL,
  motivo_duda             VARCHAR(500) NOT NULL,
  fecha_marca             DATETIME NOT NULL,
  id_usuario_marca        INT NULL,
  resultado               ENUM('AUTENTICA','NO_AUTENTICA') NULL,
  hash_recalculado        CHAR(64) NULL,
  huella_coincide         BOOLEAN NULL,
  qr_coincide             BOOLEAN NULL,                -- NULL: no se leyó el QR del ejemplar físico
  observacion_comprobacion VARCHAR(500) NULL,
  fecha_comprobacion      DATETIME NULL,
  id_usuario_comprobacion INT NULL,
  KEY ix_verificacion_mesa (id_mesa),
  CONSTRAINT chk_verificacion_resultado CHECK (resultado IS NULL OR (fecha_comprobacion IS NOT NULL AND hash_recalculado IS NOT NULL)),
  CONSTRAINT fk_verif_acta      FOREIGN KEY (id_acta)                 REFERENCES acta_electoral(id_acta),
  CONSTRAINT fk_verif_proceso   FOREIGN KEY (id_proceso)              REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_verif_mesa      FOREIGN KEY (id_mesa)                 REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_verif_u_marca   FOREIGN KEY (id_usuario_marca)        REFERENCES usuario(id_usuario),
  CONSTRAINT fk_verif_u_comprob FOREIGN KEY (id_usuario_comprobacion) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- A3 / RF95 y paso 7: calificación del CEUNP de la mesa cuya acta difiere del consolidado
-- (VALIDA: se computa con la cédula física) o nulidad de su votación (NULIDAD, RF94 y RF100).
CREATE TABLE IF NOT EXISTS calificacion_mesa (
  id_mesa           INT PRIMARY KEY,
  id_proceso        INT NOT NULL,
  calificacion      ENUM('VALIDA','NULIDAD') NOT NULL,
  motivo_revision   VARCHAR(300) NULL,               -- por qué se revisó (diferencias del acta)
  fundamento        VARCHAR(1000) NOT NULL,
  numero_resolucion VARCHAR(40) NULL,
  fecha             DATETIME NOT NULL,
  id_usuario        INT NULL,
  UNIQUE KEY uq_calificacion_resolucion (numero_resolucion),
  CONSTRAINT chk_calificacion_nulidad CHECK (calificacion <> 'NULIDAD' OR numero_resolucion IS NOT NULL),
  CONSTRAINT fk_calif_mesa    FOREIGN KEY (id_mesa)    REFERENCES mesa_electoral(id_mesa),
  CONSTRAINT fk_calif_proceso FOREIGN KEY (id_proceso) REFERENCES proceso_electoral(id_proceso),
  CONSTRAINT fk_calif_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 16-17 acreditarGanadora(idLista) / listaAcreditada(): una credencial por cargo proclamado (RF98)
CREATE TABLE IF NOT EXISTS proclamacion_cargo (
  id_cargo           INT PRIMARY KEY,
  id_proceso         INT NOT NULL,
  id_lista           INT NOT NULL,
  votos              INT NOT NULL,
  porcentaje_validos DECIMAL(5,2) NULL,
  codigo_credencial  CHAR(12) NOT NULL,
  fecha_proclamacion DATETIME NOT NULL,
  UNIQUE KEY uq_proclamacion_codigo (codigo_credencial),
  CONSTRAINT fk_procl_cargo   FOREIGN KEY (id_cargo, id_proceso) REFERENCES cargo_electoral(id_cargo, id_proceso),
  CONSTRAINT fk_procl_lista   FOREIGN KEY (id_lista)             REFERENCES lista_electoral(id_lista)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 2. Parámetros (editables en la pantalla Parámetros)
-- ---------------------------------------------------------------------
INSERT INTO parametro_global (clave, valor, descripcion) VALUES
  ('SEGUNDA_VUELTA_PLAZO_DIAS', '15',
   'Días desde el cómputo dentro de los que debe realizarse la segunda vuelta (RN33, Art. 63)'),
  ('CEUNP_QUORUM_PLENO', '5',
   'Miembros del Pleno del CEUNP necesarios para resolver una apelación (RN36)')
ON DUPLICATE KEY UPDATE descripcion = descripcion;

-- ---------------------------------------------------------------------
-- 3. Triggers
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_computo_bu;
DROP TRIGGER IF EXISTS trg_computo_bd;
DROP TRIGGER IF EXISTS trg_verificacion_bu;
DROP TRIGGER IF EXISTS trg_verificacion_bd;
DROP TRIGGER IF EXISTS trg_calificacion_bu;
DROP TRIGGER IF EXISTS trg_calificacion_bd;
DROP TRIGGER IF EXISTS trg_proclamacion_bu;
DROP TRIGGER IF EXISTS trg_proclamacion_bd;
DROP TRIGGER IF EXISTS trg_cpersonero_bi;

DELIMITER $$

-- RN26: el cómputo es irreversible. Cada etapa solo avanza (sesión > cómputo > proclamación >
-- publicación) y lo registrado en una etapa ya no cambia.
CREATE TRIGGER trg_computo_bu BEFORE UPDATE ON computo_proceso
FOR EACH ROW
BEGIN
  IF OLD.estado = 'PUBLICADO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF99: los resultados ya se publicaron; el cómputo no cambia.';
  END IF;
  IF NOT (NEW.lugar_sesion <=> OLD.lugar_sesion) OR NOT (NEW.miembros_ceunp <=> OLD.miembros_ceunp)
     OR NOT (NEW.fecha_sesion <=> OLD.fecha_sesion) OR NOT (NEW.id_proceso <=> OLD.id_proceso) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF91: los datos de la sesión de cómputo no se modifican.';
  END IF;
  IF OLD.estado <> 'SESION_INSTALADA' AND (NOT (NEW.contenido_json <=> OLD.contenido_json)
     OR NOT (NEW.hash_integridad <=> OLD.hash_integridad) OR NOT (NEW.token_qr_hash <=> OLD.token_qr_hash)
     OR NOT (NEW.fecha_computo <=> OLD.fecha_computo) OR NOT (NEW.resultado <=> OLD.resultado)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el cómputo oficial y su acta general son irreversibles.';
  END IF;
  IF OLD.estado IN ('PROCLAMADO','PUBLICADO') AND (NOT (NEW.numero_resolucion <=> OLD.numero_resolucion)
     OR NOT (NEW.contenido_proclamacion <=> OLD.contenido_proclamacion) OR NOT (NEW.hash_proclamacion <=> OLD.hash_proclamacion)
     OR NOT (NEW.fecha_proclamacion <=> OLD.fecha_proclamacion)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF98: la proclamación ya fue registrada.';
  END IF;
  IF FIELD(NEW.estado, 'SESION_INSTALADA','COMPUTADO','PROCLAMADO','PUBLICADO')
     < FIELD(OLD.estado, 'SESION_INSTALADA','COMPUTADO','PROCLAMADO','PUBLICADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el cómputo no retrocede de etapa.';
  END IF;
END$$

-- La limpieza de datos usa TRUNCATE (02_limpiar_datos_electorales.sql).
CREATE TRIGGER trg_computo_bd BEFORE DELETE ON computo_proceso
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN26: el registro del cómputo no se elimina.';
END$$

-- Los personeros se registran en la sesión antes del cómputo
CREATE TRIGGER trg_cpersonero_bi BEFORE INSERT ON computo_personero
FOR EACH ROW
BEGIN
  IF (SELECT estado FROM computo_proceso WHERE id_proceso = NEW.id_proceso) <> 'SESION_INSTALADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF91: el cómputo ya se realizó; no se registran más asistentes.';
  END IF;
END$$

-- RF90: la comprobación de un acta dudosa se registra una sola vez
CREATE TRIGGER trg_verificacion_bu BEFORE UPDATE ON verificacion_acta
FOR EACH ROW
BEGIN
  IF OLD.resultado IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: la autenticidad de esta acta ya fue comprobada.';
  END IF;
  IF NOT (NEW.motivo_duda <=> OLD.motivo_duda) OR NOT (NEW.id_acta <=> OLD.id_acta) OR NOT (NEW.fecha_marca <=> OLD.fecha_marca) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: la marca de acta dudosa no se modifica.';
  END IF;
END$$

CREATE TRIGGER trg_verificacion_bd BEFORE DELETE ON verificacion_acta
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: la verificación de un acta no se elimina.';
END$$

-- RF95 / RN36: la calificación del CEUNP es inapelable
CREATE TRIGGER trg_calificacion_bu BEFORE UPDATE ON calificacion_mesa
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: la calificación del acta por el CEUNP es inapelable.';
END$$

CREATE TRIGGER trg_calificacion_bd BEFORE DELETE ON calificacion_mesa
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: la calificación del acta por el CEUNP es inapelable.';
END$$

CREATE TRIGGER trg_proclamacion_bu BEFORE UPDATE ON proclamacion_cargo
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF98: la acreditación de la lista ganadora no se modifica.';
END$$

CREATE TRIGGER trg_proclamacion_bd BEFORE DELETE ON proclamacion_cargo
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF98: la acreditación de la lista ganadora no se elimina.';
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- 4. Vistas
-- ---------------------------------------------------------------------

-- 4-5 validarIntegridad(actas): cada acta con su huella recalculada y su verificación (RF90)
CREATE OR REPLACE VIEW v_computo_actas AS
SELECT m.id_proceso, a.id_mesa, m.numero_mesa, a.id_acta, a.tipo, a.estado, a.fecha_emision,
       a.hash_integridad,
       IF(SHA2(a.contenido_json, 256) = a.hash_integridad, 1, 0) AS integra,
       IF(v.id_acta IS NULL, 0, 1) AS dudosa,
       v.motivo_duda, v.fecha_marca, v.resultado AS comprobacion, v.huella_coincide, v.qr_coincide,
       v.observacion_comprobacion, v.fecha_comprobacion
  FROM acta_electoral a
  JOIN mesa_electoral m ON m.id_mesa = a.id_mesa
  LEFT JOIN verificacion_acta v ON v.id_acta = a.id_acta;

-- 2-3 verificarActasEntregadas(idProceso) / actasEntregadas(totalMesas) (RF89, RN32).
-- situacion: por qué una mesa entra o no al cómputo. Solo HABILITADA se computa; NO_INSTALADA y
-- ANULADA no tienen votos que computar. Las demás impiden el cómputo hasta resolverse.
CREATE OR REPLACE VIEW v_computo_mesas AS
SELECT x.*,
       CASE
         WHEN x.estado = 'ANULADA' THEN 'ANULADA'
         WHEN x.estado = 'NO_INSTALADA' THEN 'NO_INSTALADA'
         WHEN x.estado = 'PENDIENTE' THEN 'SIN_INSTALAR'
         WHEN x.estado = 'INSTALADA' THEN 'EN_SUFRAGIO'
         WHEN x.estado_escrutinio IS NULL OR x.estado_escrutinio IN ('CEDULAS_CONTADAS','CONTEO_REGISTRADO') THEN 'ESCRUTINIO_PENDIENTE'
         WHEN x.estado_escrutinio = 'ACTA_EMITIDA' THEN 'ACTAS_SIN_ENTREGAR'
         WHEN x.actas_vigentes < 3 THEN 'ACTAS_INCOMPLETAS'
         WHEN x.actas_alteradas > 0 OR x.actas_no_autenticas > 0 THEN 'ACTA_NO_AUTENTICA'
         WHEN x.actas_dudosas > 0 THEN 'ACTA_DUDOSA'
         WHEN x.impugnaciones_pendientes > 0 THEN 'IMPUGNACIONES_PENDIENTES'
         WHEN x.requiere_calificacion = 1 AND x.calificacion IS NULL THEN 'POR_CALIFICAR'
         ELSE 'HABILITADA'
       END AS situacion
  FROM (SELECT m.id_proceso, m.id_mesa, m.numero_mesa, m.ubicacion, m.estado, m.total_electores,
               e.estado AS estado_escrutinio, e.total_votantes, e.cedulas_escrutadas, e.observada,
               e.prevalece_fisica, e.conteo_cuadra, e.total_cuadra, e.fecha_entrega, e.recibido_por, e.codigo_cargo,
               (SELECT COUNT(DISTINCT a.tipo) FROM acta_electoral a
                 WHERE a.id_mesa = m.id_mesa AND a.estado = 'VIGENTE') AS actas_vigentes,
               (SELECT COUNT(*) FROM acta_electoral a
                 WHERE a.id_mesa = m.id_mesa AND a.estado = 'VIGENTE'
                   AND SHA2(a.contenido_json, 256) <> a.hash_integridad) AS actas_alteradas,
               (SELECT COUNT(*) FROM verificacion_acta v WHERE v.id_mesa = m.id_mesa AND v.resultado IS NULL) AS actas_dudosas,
               (SELECT COUNT(*) FROM verificacion_acta v WHERE v.id_mesa = m.id_mesa AND v.resultado = 'NO_AUTENTICA') AS actas_no_autenticas,
               (SELECT COUNT(*) FROM impugnacion_electoral i WHERE i.id_mesa = m.id_mesa) AS impugnaciones,
               (SELECT COUNT(*) FROM v_impugnacion_efecto i
                 WHERE i.id_mesa = m.id_mesa
                   AND (i.situacion IN ('PENDIENTE_MESA','EN_APELACION')
                        OR (i.situacion = 'APELABLE'
                            AND COALESCE((SELECT CAST(g.valor AS DECIMAL(8,2)) FROM parametro_global g
                                           WHERE g.clave = 'IMPUGNACION_PLAZO_APELACION_HORAS'), 24) > 0))) AS impugnaciones_pendientes,
               IF(e.observada = 1 OR e.conteo_cuadra = 0 OR e.total_cuadra = 0, 1, 0) AS requiere_calificacion,
               c.calificacion, c.motivo_revision, c.fundamento AS fundamento_calificacion,
               c.numero_resolucion AS resolucion_calificacion, c.fecha AS fecha_calificacion
          FROM mesa_electoral m
          LEFT JOIN escrutinio_mesa e   ON e.id_mesa = m.id_mesa
          LEFT JOIN calificacion_mesa c ON c.id_mesa = m.id_mesa) x;

-- 6-7 consolidarVotos(idCargo) por mesa. Votos de la cédula física (acta de escrutinio, RF84)
-- más las cédulas impugnadas que la mesa o el CEUNP asignaron a la opción (CUS13). La fila
-- IMPUGNADO trae las cédulas cuya impugnación aún no tiene opción.
CREATE OR REPLACE VIEW v_computo_conteo_mesa AS
SELECT m.id_proceso, k.id_mesa, m.numero_mesa, k.id_cargo, k.opcion, k.id_lista,
       k.votos_manual AS votos_acta,
       (SELECT COUNT(*) FROM v_impugnacion_efecto i
         WHERE i.id_mesa = k.id_mesa AND i.id_cargo = k.id_cargo AND i.opcion_vigente = k.opcion
           AND (k.opcion <> 'LISTA' OR i.id_lista_vigente = k.id_lista)) AS impugnados_asignados,
       k.votos_manual
       + (SELECT COUNT(*) FROM v_impugnacion_efecto i
           WHERE i.id_mesa = k.id_mesa AND i.id_cargo = k.id_cargo AND i.opcion_vigente = k.opcion
             AND (k.opcion <> 'LISTA' OR i.id_lista_vigente = k.id_lista)) AS votos,
       k.votos_digital
  FROM escrutinio_conteo k
  JOIN mesa_electoral m  ON m.id_mesa = k.id_mesa
  JOIN escrutinio_mesa e ON e.id_mesa = k.id_mesa AND e.estado IN ('ACTA_EMITIDA','ENTREGADA')
 WHERE k.opcion <> 'IMPUGNADO'
UNION ALL
SELECT m.id_proceso, k.id_mesa, m.numero_mesa, k.id_cargo, k.opcion, NULL,
       k.votos_manual, 0,
       (SELECT COUNT(*) FROM v_impugnacion_efecto i
         WHERE i.id_mesa = k.id_mesa AND i.id_cargo = k.id_cargo AND i.opcion_vigente = 'IMPUGNADO'),
       0
  FROM escrutinio_conteo k
  JOIN mesa_electoral m  ON m.id_mesa = k.id_mesa
  JOIN escrutinio_mesa e ON e.id_mesa = k.id_mesa AND e.estado IN ('ACTA_EMITIDA','ENTREGADA')
 WHERE k.opcion = 'IMPUGNADO';

-- 7 totalesPorLista(votos): consolidado por cargo y opción de las actas de las mesas no anuladas
CREATE OR REPLACE VIEW v_computo_resultados AS
SELECT c.id_proceso, c.id_cargo, c.nombre AS cargo, x.opcion, x.id_lista,
       COALESCE(l.nombre, CASE x.opcion WHEN 'BLANCO' THEN 'Votos en blanco' WHEN 'NULO' THEN 'Votos nulos'
                                        ELSE 'Impugnados sin resolver' END) AS lista,
       l.orden_cedula,
       COUNT(DISTINCT x.id_mesa) AS mesas,
       SUM(x.votos_acta) AS votos_actas,
       SUM(x.impugnados_asignados) AS impugnados_asignados,
       SUM(x.votos) AS votos,
       SUM(x.votos_digital) AS votos_digital
  FROM v_computo_conteo_mesa x
  JOIN mesa_electoral m  ON m.id_mesa = x.id_mesa AND m.estado <> 'ANULADA'
  JOIN cargo_electoral c ON c.id_cargo = x.id_cargo
  LEFT JOIN lista_electoral l ON l.id_lista = x.id_lista
 GROUP BY c.id_proceso, c.id_cargo, c.nombre, x.opcion, x.id_lista, l.nombre, l.orden_cedula;

-- RF99: resultados publicados en el portal (solo después de la publicación)
CREATE OR REPLACE VIEW v_portal_resultados AS
SELECT p.id_proceso, p.nombre AS proceso, p.tipo, p.estado AS estado_proceso,
       cp.resultado, cp.participacion_pct, cp.electores_habiles, cp.votaron,
       cp.numero_resolucion, cp.fecha_computo, cp.fecha_proclamacion, cp.fecha_publicacion
  FROM computo_proceso cp
  JOIN proceso_electoral p ON p.id_proceso = cp.id_proceso
 WHERE cp.estado = 'PUBLICADO';

-- ---------------------------------------------------------------------
-- 5. Procedimientos
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_instalar_sesion_computo;
DROP PROCEDURE IF EXISTS sp_registrar_personero_computo;
DROP PROCEDURE IF EXISTS sp_marcar_acta_dudosa;
DROP PROCEDURE IF EXISTS sp_comprobar_acta;
DROP PROCEDURE IF EXISTS sp_calificar_mesa;
DROP PROCEDURE IF EXISTS sp_ejecutar_computo;
DROP PROCEDURE IF EXISTS sp_proclamar_resultados;
DROP PROCEDURE IF EXISTS sp_publicar_resultados;
DROP PROCEDURE IF EXISTS sp_convocar_segunda_vuelta;
DROP PROCEDURE IF EXISTS sp_verificar_acta_computo;

DELIMITER $$

-- Paso 4 de la tabla 39 (RF91): el CEUNP instala la sesión de cómputo general con quórum
-- (RN36, CEUNP_QUORUM_PLENO) y registra a los personeros acreditados presentes.
-- p_personeros: arreglo JSON de id_personero, p. ej. [3, 7]. Puede ir vacío.
CREATE PROCEDURE sp_instalar_sesion_computo(
  IN p_id_proceso    INT,
  IN p_id_usuario    INT,
  IN p_lugar         VARCHAR(200),
  IN p_miembros      INT,
  IN p_observaciones VARCHAR(1000),
  IN p_personeros    LONGTEXT
)
BEGIN
  DECLARE v_estado   VARCHAR(20) DEFAULT NULL;
  DECLARE v_quorum   INT;
  DECLARE v_lugar    VARCHAR(200);
  DECLARE v_pers     LONGTEXT;
  DECLARE v_n        INT DEFAULT 0;
  DECLARE v_validos  INT DEFAULT 0;
  DECLARE v_msg      VARCHAR(255);
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
  IF EXISTS (SELECT 1 FROM computo_proceso WHERE id_proceso = p_id_proceso) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF91: la sesión de cómputo de este proceso ya fue instalada.';
  END IF;
  IF v_estado <> 'CERRADO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN32: la sesión de cómputo se instala con la votación del proceso concluida (CERRADO).';
  END IF;
  SET v_lugar = NULLIF(TRIM(p_lugar), '');
  IF v_lugar IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF91: indique el lugar de la sesión de cómputo.';
  END IF;
  SET v_quorum = COALESCE(ROUND((SELECT CAST(valor AS DECIMAL(6,2)) FROM parametro_global WHERE clave = 'CEUNP_QUORUM_PLENO')), 5);
  IF p_miembros IS NULL OR p_miembros < v_quorum OR p_miembros > 9 THEN
    SET v_msg = CONCAT('RN36: el Pleno del CEUNP sesiona con quórum de ', v_quorum, ' de sus 9 miembros.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  SET v_pers = IF(p_personeros IS NULL OR TRIM(p_personeros) = '', '[]', p_personeros);
  IF JSON_VALID(v_pers) = 0 OR JSON_TYPE(v_pers) <> 'ARRAY' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lista de personeros presentes no válida.';
  END IF;
  SET v_n = JSON_LENGTH(v_pers);
  SELECT COUNT(*) INTO v_validos
    FROM personero pe
    JOIN lista_electoral l ON l.id_lista = pe.id_lista
    JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
   WHERE c.id_proceso = p_id_proceso AND pe.estado_acreditacion = 'ACREDITADO'
     AND JSON_CONTAINS(v_pers, CAST(pe.id_personero AS CHAR));
  IF v_validos <> v_n THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF91: solo asisten a la sesión los personeros acreditados del proceso.';
  END IF;

  INSERT INTO computo_proceso (id_proceso, estado, lugar_sesion, miembros_ceunp, observaciones_sesion, fecha_sesion, id_usuario_sesion)
  VALUES (p_id_proceso, 'SESION_INSTALADA', v_lugar, p_miembros, NULLIF(TRIM(p_observaciones), ''), NOW(), p_id_usuario);

  INSERT INTO computo_personero (id_proceso, id_personero, id_usuario)
  SELECT p_id_proceso, pe.id_personero, p_id_usuario
    FROM personero pe
    JOIN lista_electoral l ON l.id_lista = pe.id_lista
    JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
   WHERE c.id_proceso = p_id_proceso AND JSON_CONTAINS(v_pers, CAST(pe.id_personero AS CHAR));

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'INSTALAR_SESION_COMPUTO',
       JSON_OBJECT('lugar', v_lugar, 'miembros', p_miembros, 'personeros', v_n));
  COMMIT;
END$$

-- RF91: un personero acreditado llega a la sesión ya instalada (antes del cómputo)
CREATE PROCEDURE sp_registrar_personero_computo(
  IN p_id_proceso   INT,
  IN p_id_usuario   INT,
  IN p_id_personero INT
)
BEGIN
  DECLARE v_estado VARCHAR(20) DEFAULT NULL;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT estado INTO v_estado FROM computo_proceso WHERE id_proceso = p_id_proceso FOR UPDATE;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF91: instale primero la sesión de cómputo.';
  END IF;
  IF v_estado <> 'SESION_INSTALADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF91: el cómputo ya se realizó; no se registran más asistentes.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM personero pe
                   JOIN lista_electoral l ON l.id_lista = pe.id_lista
                   JOIN cargo_electoral c ON c.id_cargo = l.id_cargo
                  WHERE pe.id_personero = p_id_personero AND c.id_proceso = p_id_proceso
                    AND pe.estado_acreditacion = 'ACREDITADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF91: solo asisten a la sesión los personeros acreditados del proceso.';
  END IF;
  IF EXISTS (SELECT 1 FROM computo_personero WHERE id_proceso = p_id_proceso AND id_personero = p_id_personero) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF91: el personero ya figura como asistente.';
  END IF;

  INSERT INTO computo_personero (id_proceso, id_personero, id_usuario) VALUES (p_id_proceso, p_id_personero, p_id_usuario);
  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'REGISTRAR_PERSONERO_COMPUTO',
       JSON_OBJECT('id_personero', p_id_personero));
  COMMIT;
END$$

-- Paso 3 de la tabla 39 (RF90): el CEUNP marca un acta como dudosa antes del cómputo.
CREATE PROCEDURE sp_marcar_acta_dudosa(
  IN p_id_acta    INT,
  IN p_id_usuario INT,
  IN p_motivo     VARCHAR(500)
)
BEGIN
  DECLARE v_mesa     INT DEFAULT NULL;
  DECLARE v_proceso  INT;
  DECLARE v_estado   VARCHAR(20);
  DECLARE v_acta_est VARCHAR(10);
  DECLARE v_tipo     VARCHAR(12);
  DECLARE v_motivo   VARCHAR(500);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT a.id_mesa, m.id_proceso, p.estado, a.estado, a.tipo INTO v_mesa, v_proceso, v_estado, v_acta_est, v_tipo
    FROM acta_electoral a
    JOIN mesa_electoral m    ON m.id_mesa = a.id_mesa
    JOIN proceso_electoral p ON p.id_proceso = m.id_proceso
   WHERE a.id_acta = p_id_acta
     FOR UPDATE;
  IF v_mesa IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El acta no existe.';
  END IF;
  IF v_estado NOT IN ('VOTACION','CERRADO')
     OR EXISTS (SELECT 1 FROM computo_proceso WHERE id_proceso = v_proceso AND estado <> 'SESION_INSTALADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN32: las actas se verifican antes del cómputo.';
  END IF;
  IF v_acta_est <> 'VIGENTE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: el acta está anulada.';
  END IF;
  IF EXISTS (SELECT 1 FROM verificacion_acta WHERE id_acta = p_id_acta) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: el acta ya está marcada como dudosa.';
  END IF;
  SET v_motivo = NULLIF(TRIM(p_motivo), '');
  IF v_motivo IS NULL OR CHAR_LENGTH(v_motivo) < 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: indique por qué el acta es dudosa (al menos 10 caracteres).';
  END IF;

  INSERT INTO verificacion_acta (id_acta, id_proceso, id_mesa, motivo_duda, fecha_marca, id_usuario_marca)
  VALUES (p_id_acta, v_proceso, v_mesa, v_motivo, NOW(), p_id_usuario);

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'MARCAR_ACTA_DUDOSA',
       JSON_OBJECT('id_acta', p_id_acta, 'id_mesa', v_mesa, 'tipo', v_tipo));
  COMMIT;
END$$

-- Paso 3 de la tabla 39 (RF90): comprobación de la autenticidad del acta dudosa. Recalcula la
-- huella SHA-256 del contenido y, si se leyó el QR del ejemplar físico (token o URL de
-- verificación), comprueba que corresponde al acta. AUTENTICA si todo coincide.
CREATE PROCEDURE sp_comprobar_acta(
  IN p_id_acta     INT,
  IN p_id_usuario  INT,
  IN p_token_qr    VARCHAR(300),
  IN p_observacion VARCHAR(500)
)
BEGIN
  DECLARE v_proceso   INT DEFAULT NULL;
  DECLARE v_resultado VARCHAR(12) DEFAULT NULL;
  DECLARE v_hash      CHAR(64);
  DECLARE v_guardado  CHAR(64);
  DECLARE v_token_h   CHAR(64);
  DECLARE v_token     VARCHAR(64);
  DECLARE v_huella    INT;
  DECLARE v_qr        INT DEFAULT NULL;
  DECLARE v_final     VARCHAR(12);
  DECLARE v_n         INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT COUNT(*) INTO v_n FROM verificacion_acta WHERE id_acta = p_id_acta;
  IF v_n = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: marque primero el acta como dudosa.';
  END IF;
  SELECT v.id_proceso, v.resultado, SHA2(a.contenido_json, 256), a.hash_integridad, a.token_qr_hash
    INTO v_proceso, v_resultado, v_hash, v_guardado, v_token_h
    FROM verificacion_acta v JOIN acta_electoral a ON a.id_acta = v.id_acta
   WHERE v.id_acta = p_id_acta
     FOR UPDATE;
  IF v_resultado IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: la autenticidad de esta acta ya fue comprobada.';
  END IF;
  IF EXISTS (SELECT 1 FROM computo_proceso WHERE id_proceso = v_proceso AND estado <> 'SESION_INSTALADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN32: las actas se verifican antes del cómputo.';
  END IF;

  SET v_huella = IF(v_hash = v_guardado, 1, 0);
  IF p_token_qr IS NOT NULL AND TRIM(p_token_qr) <> '' THEN
    SET v_token = LOWER(REGEXP_SUBSTR(p_token_qr, '[0-9a-fA-F]{64}'));
    IF v_token IS NULL OR v_token = '' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: el código QR leído no es un código de acta válido.';
    END IF;
    SET v_qr = IF(SHA2(v_token, 256) = v_token_h, 1, 0);
  END IF;
  SET v_final = IF(v_huella = 1 AND COALESCE(v_qr, 1) = 1, 'AUTENTICA', 'NO_AUTENTICA');

  UPDATE verificacion_acta
     SET resultado = v_final, hash_recalculado = v_hash, huella_coincide = v_huella, qr_coincide = v_qr,
         observacion_comprobacion = NULLIF(TRIM(p_observacion), ''), fecha_comprobacion = NOW(),
         id_usuario_comprobacion = p_id_usuario
   WHERE id_acta = p_id_acta;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, 'COMPROBAR_ACTA',
       JSON_OBJECT('id_acta', p_id_acta, 'resultado', v_final, 'huella', v_huella, 'qr', v_qr));
  COMMIT;

  SELECT p_id_acta AS id_acta, v_final AS resultado, v_huella AS huella_coincide, v_qr AS qr_coincide,
         v_hash AS hash_recalculado, v_guardado AS hash_integridad;
END$$

-- Paso 7 y A3 de la tabla 39 (RF94, RF95, RF100): el CEUNP califica la mesa cuya acta difiere del
-- consolidado (VALIDA: se computa con la cédula física, RF84) o declara la nulidad de su
-- votación (NULIDAD: la mesa y sus actas quedan ANULADAS y salen del cómputo). Un acta no
-- auténtica solo admite NULIDAD. La nulidad lleva el número de resolución del CEUNP.
CREATE PROCEDURE sp_calificar_mesa(
  IN p_id_mesa           INT,
  IN p_id_usuario        INT,
  IN p_calificacion      VARCHAR(10),
  IN p_fundamento        VARCHAR(1000),
  IN p_numero_resolucion VARCHAR(40)
)
BEGIN
  DECLARE v_proceso   INT DEFAULT NULL;
  DECLARE v_estado    VARCHAR(20);
  DECLARE v_mesa_est  VARCHAR(20);
  DECLARE v_calif     VARCHAR(10);
  DECLARE v_fund      VARCHAR(1000);
  DECLARE v_res       VARCHAR(40);
  DECLARE v_requiere  INT DEFAULT 0;
  DECLARE v_no_aut    INT DEFAULT 0;
  DECLARE v_esc       VARCHAR(20);
  DECLARE v_motivo    VARCHAR(300);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT m.id_proceso, p.estado, m.estado INTO v_proceso, v_estado, v_mesa_est
    FROM mesa_electoral m JOIN proceso_electoral p ON p.id_proceso = m.id_proceso
   WHERE m.id_mesa = p_id_mesa
     FOR UPDATE;
  IF v_proceso IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa no existe.';
  END IF;
  IF v_estado <> 'CERRADO'
     OR EXISTS (SELECT 1 FROM computo_proceso WHERE id_proceso = v_proceso AND estado <> 'SESION_INSTALADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF94: las actas y nulidades se resuelven con la votación concluida y antes del cómputo.';
  END IF;
  IF EXISTS (SELECT 1 FROM calificacion_mesa WHERE id_mesa = p_id_mesa) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el CEUNP ya calificó esta mesa; su decisión es inapelable.';
  END IF;
  IF v_mesa_est <> 'CERRADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF95: solo se califica una mesa que cerró su sufragio y entregó sus actas.';
  END IF;

  SET v_calif = UPPER(TRIM(p_calificacion));
  IF v_calif IS NULL OR v_calif NOT IN ('VALIDA','NULIDAD') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF95: la calificación es VALIDA o NULIDAD.';
  END IF;
  SET v_fund = NULLIF(TRIM(p_fundamento), '');
  IF v_fund IS NULL OR CHAR_LENGTH(v_fund) < 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF95: fundamente la decisión del CEUNP (al menos 10 caracteres).';
  END IF;
  SET v_res = NULLIF(TRIM(p_numero_resolucion), '');

  SELECT estado_escrutinio, requiere_calificacion, actas_no_autenticas + actas_alteradas,
         CONCAT_WS('; ',
           IF(conteo_cuadra = 0, 'el conteo manual difiere del digital (prevalece la cédula física)', NULL),
           IF(total_cuadra = 0, 'los votos no igualan a los electores que votaron', NULL),
           IF(observada = 1, 'acta con observaciones', NULL),
           IF(actas_no_autenticas + actas_alteradas > 0, 'acta no auténtica', NULL))
    INTO v_esc, v_requiere, v_no_aut, v_motivo
    FROM v_computo_mesas WHERE id_mesa = p_id_mesa;

  IF v_calif = 'VALIDA' THEN
    IF v_no_aut > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF90: el acta no es auténtica; solo procede declarar la nulidad de la mesa.';
    END IF;
    IF v_esc IS NULL OR v_esc NOT IN ('ACTA_EMITIDA','ENTREGADA') THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF95: la mesa aún no emite su acta de escrutinio (CUS12).';
    END IF;
    IF v_requiere = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A3: el acta coincide con el conteo; no requiere calificación.';
    END IF;
  ELSE
    IF v_res IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN34: la nulidad se declara por resolución del CEUNP; indique su número.';
    END IF;
  END IF;
  IF v_res IS NOT NULL AND (EXISTS (SELECT 1 FROM calificacion_mesa WHERE numero_resolucion = v_res)
       OR EXISTS (SELECT 1 FROM computo_proceso WHERE numero_resolucion = v_res)
       OR EXISTS (SELECT 1 FROM impugnacion_electoral WHERE numero_resolucion = v_res)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;

  INSERT INTO calificacion_mesa (id_mesa, id_proceso, calificacion, motivo_revision, fundamento, numero_resolucion, fecha, id_usuario)
  VALUES (p_id_mesa, v_proceso, v_calif, NULLIF(v_motivo, ''), v_fund, v_res, NOW(), p_id_usuario);

  IF v_calif = 'NULIDAD' THEN
    -- RF100: la votación de la mesa se excluye del cómputo
    UPDATE acta_electoral SET estado = 'ANULADA' WHERE id_mesa = p_id_mesa;
    UPDATE mesa_electoral SET estado = 'ANULADA' WHERE id_mesa = p_id_mesa;
  END IF;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, v_proceso, IF(v_calif = 'NULIDAD', 'DECLARAR_NULIDAD_MESA', 'CALIFICAR_ACTA'),
       JSON_OBJECT('id_mesa', p_id_mesa, 'calificacion', v_calif, 'resolucion', v_res));
  COMMIT;

  SELECT p_id_mesa AS id_mesa, v_calif AS calificacion;
END$$

-- Mensajes 1 a 15 del diagrama: ejecutarComputo(idProceso). Cómputo oficial e irreversible (RN26).
--   2-3   todas las mesas instaladas entregaron sus tres actas, o fueron declaradas no instaladas
--         o anuladas; no quedan actas dudosas, impugnaciones ni calificaciones pendientes (RN32)
--   4-5   la huella SHA-256 de cada acta coincide (RF90)
--   6-7   consolida los votos de las actas habilitadas (RF92)
--   8-11  participación por cargo sobre el padrón y quórum (> quorum_minimo, RN31)
--   12-15 registra el cómputo y determina el resultado de cada cargo:
--           SIN_QUORUM .... participación <= quórum
--           DESIERTO ...... hubo quórum pero ningún voto válido
--           ELEGIDO ....... una lista SUPERA el % mínimo de votos válidos (2.ª vuelta: 50 % + 1, RF97)
--           SEGUNDA_VUELTA  ninguna lista lo supera o hay empate (RF96, A2)
--           EMPATE ........ empate en segunda vuelta (lo resuelve el CEUNP)
-- El proceso queda FINALIZADO, o ANULADO si ningún cargo alcanzó el quórum (A1, RN31 y RN34).
-- Emite el acta general de sufragios (contenido JSON, huella SHA-256 y QR). Devuelve el token.
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
  DECLARE v_top       INT DEFAULT 0;
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

  -- 12-13: [quorum > 60%] registrarComputo(totales) -> computoRegistrado(resultados)
  INSERT INTO resultado_electoral (id_proceso, id_cargo, id_lista, tipo_voto, total_votos, porcentaje_validos, posicion)
  SELECT x.id_proceso, x.id_cargo, x.id_lista, 'VALIDO', x.n,
         CASE WHEN SUM(x.n) OVER (PARTITION BY x.id_cargo) = 0 THEN 0
              ELSE ROUND(x.n * 100 / SUM(x.n) OVER (PARTITION BY x.id_cargo), 2) END,
         RANK() OVER (PARTITION BY x.id_cargo ORDER BY x.n DESC)
    FROM (SELECT c.id_proceso, c.id_cargo, l.id_lista, COALESCE(t.votos, 0) AS n
            FROM cargo_electoral c
            JOIN lista_electoral l ON l.id_cargo = c.id_cargo AND l.estado = 'ADMITIDA'
            LEFT JOIN tmp_computo_cus14 t ON t.id_cargo = c.id_cargo AND t.opcion = 'LISTA' AND t.clave = l.id_lista
           WHERE c.id_proceso = p_id_proceso) x;

  INSERT INTO resultado_electoral (id_proceso, id_cargo, id_lista, tipo_voto, total_votos)
  SELECT c.id_proceso, c.id_cargo, NULL, o.opcion, COALESCE(t.votos, 0)
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
      SET v_result = IF(v_empate = 1 AND v_top * 2 > v_validos, 'ELEGIDO', 'EMPATE');
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

  -- 12: emitirActaGeneral(totales): acta general de sufragios docentes (RF92)
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
                                                       ',"porcentaje":', COALESCE(r.porcentaje_validos, 0),
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
                                  ORDER BY LENGTH(m.numero_mesa), m.numero_mesa SEPARATOR ','), ']')
    INTO v_det_mesas
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

  SET v_token = SHA2(CONCAT(UUID(), RAND(), p_id_proceso, 'COMPUTO', NOW(6)), 256);
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

-- Mensajes 16 y 17 del diagrama y paso 9 de la tabla 39 (RF98): el Presidente del CEUNP proclama
-- los resultados en sesión del Pleno (RN36: quórum) y se acredita la lista ganadora de cada cargo
-- ELEGIDO con un código de credencial. Emite la resolución de proclamación con huella y QR.
CREATE PROCEDURE sp_proclamar_resultados(
  IN p_id_proceso        INT,
  IN p_id_usuario        INT,
  IN p_numero_resolucion VARCHAR(40),
  IN p_miembros_pleno    INT,
  IN p_presidente        VARCHAR(150),
  IN p_fundamento        VARCHAR(1000)
)
BEGIN
  DECLARE v_comp     VARCHAR(20) DEFAULT NULL;
  DECLARE v_estado   VARCHAR(20);
  DECLARE v_nombre   VARCHAR(200);
  DECLARE v_res      VARCHAR(40);
  DECLARE v_pres     VARCHAR(150);
  DECLARE v_quorum   INT;
  DECLARE v_hash_c   CHAR(64);
  DECLARE v_ahora    DATETIME;
  DECLARE v_procl    LONGTEXT;
  DECLARE v_sin      LONGTEXT;
  DECLARE v_contenido LONGTEXT;
  DECLARE v_token    CHAR(64);
  DECLARE v_n        INT DEFAULT 0;
  DECLARE v_msg      VARCHAR(255);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET SESSION group_concat_max_len = 1000000;
  START TRANSACTION;
  SELECT cp.estado, p.estado, p.nombre, cp.hash_integridad INTO v_comp, v_estado, v_nombre, v_hash_c
    FROM computo_proceso cp JOIN proceso_electoral p ON p.id_proceso = cp.id_proceso
   WHERE cp.id_proceso = p_id_proceso
     FOR UPDATE;
  IF v_comp IS NULL OR v_comp = 'SESION_INSTALADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF98: realice primero el cómputo oficial.';
  END IF;
  IF v_comp IN ('PROCLAMADO','PUBLICADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF98: los resultados ya fueron proclamados.';
  END IF;
  IF v_estado = 'ANULADO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A1 (RN31): la elección fue declarada nula; no hay resultados que proclamar. Publique el acta general.';
  END IF;
  SET v_res = NULLIF(TRIM(p_numero_resolucion), '');
  IF v_res IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF98: indique el número de la resolución de proclamación.';
  END IF;
  IF EXISTS (SELECT 1 FROM computo_proceso WHERE numero_resolucion = v_res)
     OR EXISTS (SELECT 1 FROM calificacion_mesa WHERE numero_resolucion = v_res)
     OR EXISTS (SELECT 1 FROM impugnacion_electoral WHERE numero_resolucion = v_res) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN36: el número de resolución ya fue usado.';
  END IF;
  SET v_quorum = COALESCE(ROUND((SELECT CAST(valor AS DECIMAL(6,2)) FROM parametro_global WHERE clave = 'CEUNP_QUORUM_PLENO')), 5);
  IF p_miembros_pleno IS NULL OR p_miembros_pleno < v_quorum OR p_miembros_pleno > 9 THEN
    SET v_msg = CONCAT('RN36: el Pleno del CEUNP proclama con quórum de ', v_quorum, ' de sus 9 miembros.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  SET v_pres = NULLIF(TRIM(p_presidente), '');
  IF v_pres IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF98: indique el nombre del Presidente del CEUNP que proclama.';
  END IF;

  SET v_ahora = NOW();
  -- 16: acreditarGanadora(idLista) -> 17 listaAcreditada()
  INSERT INTO proclamacion_cargo (id_cargo, id_proceso, id_lista, votos, porcentaje_validos, codigo_credencial, fecha_proclamacion)
  SELECT c.id_cargo, c.id_proceso, c.id_lista_ganadora, r.total_votos, r.porcentaje_validos,
         UPPER(LEFT(SHA2(CONCAT(c.id_cargo, '|', c.id_lista_ganadora, '|', v_res, '|', UUID()), 256), 12)), v_ahora
    FROM cargo_electoral c
    JOIN resultado_electoral r ON r.id_cargo = c.id_cargo AND r.id_lista = c.id_lista_ganadora AND r.tipo_voto = 'VALIDO'
   WHERE c.id_proceso = p_id_proceso AND c.estado_resultado = 'ELEGIDO';
  SET v_n = ROW_COUNT();

  SELECT CONCAT('[', GROUP_CONCAT(CONCAT('{"id_cargo":', pc.id_cargo,
                                         ',"cargo":', JSON_QUOTE(c.nombre),
                                         ',"id_lista":', pc.id_lista,
                                         ',"lista":', JSON_QUOTE(l.nombre),
                                         ',"votos":', pc.votos,
                                         ',"porcentaje":', COALESCE(pc.porcentaje_validos, 0),
                                         ',"codigo_credencial":', JSON_QUOTE(pc.codigo_credencial),
                                         ',"candidatos":[',
                                         COALESCE((SELECT GROUP_CONCAT(JSON_OBJECT('rol', ca.rol_en_lista,
                                                                  'nombre', CONCAT(d.nombres, ' ', d.apellidos), 'dni', d.dni)
                                                          ORDER BY ca.id_candidato SEPARATOR ',')
                                                     FROM candidato ca JOIN docente d ON d.id_docente = ca.id_docente
                                                    WHERE ca.id_lista = pc.id_lista AND ca.estado_validacion = 'APROBADO'), ''),
                                         ']}') ORDER BY pc.id_cargo SEPARATOR ','), ']')
    INTO v_procl
    FROM proclamacion_cargo pc
    JOIN cargo_electoral c ON c.id_cargo = pc.id_cargo
    JOIN lista_electoral l ON l.id_lista = pc.id_lista
   WHERE pc.id_proceso = p_id_proceso;

  SELECT CONCAT('[', GROUP_CONCAT(JSON_OBJECT('id_cargo', c.id_cargo, 'cargo', c.nombre,
                                              'estado_resultado', CONCAT(c.estado_resultado, ''))
                                  ORDER BY c.id_cargo SEPARATOR ','), ']')
    INTO v_sin
    FROM cargo_electoral c
   WHERE c.id_proceso = p_id_proceso AND c.estado_resultado <> 'ELEGIDO';

  SET v_contenido = CONCAT(
      '{"tipo":"PROCLAMACION"',
      ',"id_proceso":', p_id_proceso,
      ',"proceso":', JSON_QUOTE(v_nombre),
      ',"resolucion":', JSON_QUOTE(v_res),
      ',"fecha":', JSON_QUOTE(DATE_FORMAT(v_ahora, '%Y-%m-%d %H:%i:%s')),
      ',"presidente_ceunp":', JSON_QUOTE(v_pres),
      ',"miembros_pleno":', p_miembros_pleno,
      ',"hash_acta_general":', JSON_QUOTE(v_hash_c),
      ',"proclamados":', COALESCE(v_procl, '[]'),
      ',"sin_proclamar":', COALESCE(v_sin, '[]'),
      ',"fundamento":', IF(NULLIF(TRIM(p_fundamento), '') IS NULL, 'null', JSON_QUOTE(TRIM(p_fundamento))),
      '}');
  SET v_token = SHA2(CONCAT(UUID(), RAND(), p_id_proceso, 'PROCLAMACION', NOW(6)), 256);

  UPDATE computo_proceso
     SET estado = 'PROCLAMADO', numero_resolucion = v_res, miembros_pleno = p_miembros_pleno, presidente_ceunp = v_pres,
         fundamento_proclamacion = NULLIF(TRIM(p_fundamento), ''), fecha_proclamacion = v_ahora,
         contenido_proclamacion = v_contenido, hash_proclamacion = SHA2(v_contenido, 256),
         token_proclamacion_hash = SHA2(v_token, 256), id_usuario_proclamacion = p_id_usuario
   WHERE id_proceso = p_id_proceso;

  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'PROCLAMAR_RESULTADOS',
       JSON_OBJECT('resolucion', v_res, 'cargos_proclamados', v_n));
  COMMIT;

  SELECT p_id_proceso AS id_proceso, v_res AS numero_resolucion, v_n AS cargos_proclamados, v_token AS token_qr;
END$$

-- Mensajes 18 y 19 del diagrama (RF99): publica en el portal los resultados por mesa y generales.
-- Se publica tras la proclamación o, si la elección se anuló por falta de quórum (A1), el acta
-- general con la nulidad para su comunicación (RN34).
CREATE PROCEDURE sp_publicar_resultados(
  IN p_id_proceso INT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_comp   VARCHAR(20) DEFAULT NULL;
  DECLARE v_estado VARCHAR(20);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT cp.estado, p.estado INTO v_comp, v_estado
    FROM computo_proceso cp JOIN proceso_electoral p ON p.id_proceso = cp.id_proceso
   WHERE cp.id_proceso = p_id_proceso
     FOR UPDATE;
  IF v_comp IS NULL OR v_comp = 'SESION_INSTALADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF99: los resultados se publican después del cómputo oficial.';
  END IF;
  IF v_comp = 'PUBLICADO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF99: los resultados ya están publicados en el portal.';
  END IF;
  IF v_comp = 'COMPUTADO' AND v_estado <> 'ANULADO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RF99: proclame primero los resultados (RF98).';
  END IF;

  UPDATE computo_proceso SET estado = 'PUBLICADO', fecha_publicacion = NOW(), id_usuario_publicacion = p_id_usuario
   WHERE id_proceso = p_id_proceso;
  CALL sp_registrar_auditoria(p_id_usuario, NULL, p_id_proceso, 'PUBLICAR_RESULTADOS',
       JSON_OBJECT('estado_proceso', v_estado));
  COMMIT;
END$$

-- A2 de la tabla 39 (RN33, RF96): convoca la segunda vuelta entre las dos listas más votadas
-- dentro del plazo (SEGUNDA_VUELTA_PLAZO_DIAS, 15) contado desde el cómputo. Valida y delega
-- en sp_crear_segunda_vuelta, que clona cargos, listas y padrón (no abre otra transacción aquí).
CREATE PROCEDURE sp_convocar_segunda_vuelta(
  IN  p_id_proceso       INT,
  IN  p_fecha_inicio     DATETIME,
  IN  p_fecha_fin        DATETIME,
  IN  p_id_usuario       INT,
  OUT p_id_proceso_nuevo INT
)
BEGIN
  DECLARE v_comp    VARCHAR(20) DEFAULT NULL;
  DECLARE v_fecha   DATETIME;
  DECLARE v_plazo   INT;
  DECLARE v_msg     VARCHAR(255);

  SELECT estado, fecha_computo INTO v_comp, v_fecha FROM computo_proceso WHERE id_proceso = p_id_proceso;
  IF v_comp IS NULL OR v_comp = 'SESION_INSTALADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN33: la segunda vuelta se convoca después del cómputo oficial.';
  END IF;
  IF p_fecha_inicio IS NULL OR p_fecha_fin IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Indique fecha de inicio y de fin de la segunda vuelta.';
  END IF;
  SET v_plazo = COALESCE(ROUND((SELECT CAST(valor AS DECIMAL(6,2)) FROM parametro_global WHERE clave = 'SEGUNDA_VUELTA_PLAZO_DIAS')), 15);
  IF p_fecha_inicio <= NOW() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN33: la segunda vuelta debe programarse en una fecha futura.';
  END IF;
  IF v_plazo > 0 AND p_fecha_inicio > v_fecha + INTERVAL v_plazo DAY THEN
    SET v_msg = CONCAT('RN33: la segunda vuelta se realiza dentro de los ', v_plazo, ' días siguientes al cómputo (hasta el ',
                       DATE_FORMAT(v_fecha + INTERVAL v_plazo DAY, '%d/%m/%Y'), ').');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  CALL sp_crear_segunda_vuelta(p_id_proceso, p_fecha_inicio, p_fecha_fin, p_id_usuario, p_id_proceso_nuevo);
END$$

-- Destino del QR del acta general y de la resolución de proclamación: recalcula el SHA-256.
CREATE PROCEDURE sp_verificar_acta_computo(IN p_token CHAR(64))
BEGIN
  SELECT cp.id_proceso, p.nombre AS proceso, 'COMPUTO_GENERAL' AS tipo, cp.fecha_computo AS fecha_emision,
         cp.estado, cp.resultado, cp.hash_integridad,
         IF(SHA2(cp.contenido_json, 256) = cp.hash_integridad, 1, 0) AS contenido_integro, cp.contenido_json
    FROM computo_proceso cp JOIN proceso_electoral p ON p.id_proceso = cp.id_proceso
   WHERE cp.token_qr_hash = SHA2(p_token, 256)
  UNION ALL
  SELECT cp.id_proceso, p.nombre, 'PROCLAMACION', cp.fecha_proclamacion,
         cp.estado, cp.resultado, cp.hash_proclamacion,
         IF(SHA2(cp.contenido_proclamacion, 256) = cp.hash_proclamacion, 1, 0), cp.contenido_proclamacion
    FROM computo_proceso cp JOIN proceso_electoral p ON p.id_proceso = cp.id_proceso
   WHERE cp.token_proclamacion_hash = SHA2(p_token, 256);
END$$

DELIMITER ;

SELECT 'CUS14 instalado: cómputo y proclamación (sp_instalar_sesion_computo, sp_ejecutar_computo, sp_proclamar_resultados, sp_publicar_resultados).' AS estado;
