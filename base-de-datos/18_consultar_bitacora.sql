-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 18_consultar_bitacora.sql  ·  CUS19 Consultar bitácora
--                         (módulo M01 Seguridad y administración: consulta, detalle, integridad
--                          y exportación de la bitácora de auditoría; RN28 trazabilidad,
--                          RNF05 secreto del voto)
--
-- Diagrama de colaboración «Consultar bitácora» (modelo Rose, CUS19):
--   1 ingresarFiltros(usuario, accion, fecha_inicio, fecha_fin) -> PantallaBitacora (Admin)
--   2 buscarRegistros(filtros)       -> ConsultarBitacora (control)
--   3 validarRolAdministrador(id)    -> sp_validar_admin (Usuario)
--   4 consultar(filtros)             -> v_bitacora (LogAuditoria + catálogo bitacora_accion)
--   5 mostrarRegistros(lista)        -> PantallaBitacora: tabla paginada y resumen
--   6 seleccionarRegistro(id_log)    -> PantallaBitacora
--   7 obtenerDetalle(id_log)         -> VerDetalleRegistro (control)
--   8 consultarDetalle(id_log)       -> sp_detalle_bitacora (LogAuditoria: registro, vecinos y sello)
--   9 mostrarDetalleJSON(detalle)    -> PantallaBitacora: detalle_json legible
--
-- Qué agrega, sin duplicar lo que ya existe (log_auditoria, trg_log_bu y trg_log_bd se mantienen):
--   · El catálogo de acciones (bitacora_accion): nombre legible, módulo, caso de uso y criticidad
--     de cada código que escriben los procedimientos y el backend. Un código sin catálogo se
--     muestra igual, como «sin clasificar».
--   · El sello encadenado SHA-256 de cada registro (hash_anterior, hash_registro): lo calcula el
--     trigger trg_log_bi al insertar, así un registro alterado, borrado o insertado por fuera del
--     sistema se detecta al verificar la cadena (sp_verificar_bitacora). bitacora_cadena guarda el
--     último sello y el total, para detectar también los registros eliminados al final.
--   · La vista v_bitacora (registro con su usuario, rol, docente, proceso y acción catalogada),
--     el detalle (sp_detalle_bitacora), la verificación de la cadena y el registro de las
--     exportaciones (sp_registrar_exportacion_bitacora).
--   · El parámetro BITACORA_EXPORTACION_MAX (máximo de registros por exportación).
--
-- Uso: en una base ya creada, después de 17_administracion_usuarios_parametros.sql (CUS18). No borra
-- datos ni recrea la base. La primera vez sella los registros que ya existen, en su orden. Se puede
-- volver a ejecutar. 00_script_unico_elecciones_unp.sql (sección 5i) ya lo incluye.
-- =====================================================================
USE elecciones_unp;
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 1. Columnas e índices nuevos de log_auditoria (sin ADD COLUMN IF NOT EXISTS: MariaDB y MySQL)
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_tmp_cus19_columna;
DROP PROCEDURE IF EXISTS sp_tmp_cus19_indice;
DELIMITER $$
CREATE PROCEDURE sp_tmp_cus19_columna(IN p_tabla VARCHAR(64), IN p_columna VARCHAR(64), IN p_definicion VARCHAR(500))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema = DATABASE() AND table_name = p_tabla AND column_name = p_columna) THEN
    SET @sql_cus19 = CONCAT('ALTER TABLE ', p_tabla, ' ADD COLUMN ', p_columna, ' ', p_definicion);
    PREPARE st_cus19 FROM @sql_cus19;
    EXECUTE st_cus19;
    DEALLOCATE PREPARE st_cus19;
  END IF;
END$$
CREATE PROCEDURE sp_tmp_cus19_indice(IN p_tabla VARCHAR(64), IN p_indice VARCHAR(64), IN p_columnas VARCHAR(200))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.statistics
                  WHERE table_schema = DATABASE() AND table_name = p_tabla AND index_name = p_indice) THEN
    SET @sql_cus19 = CONCAT('ALTER TABLE ', p_tabla, ' ADD INDEX ', p_indice, ' (', p_columnas, ')');
    PREPARE st_cus19 FROM @sql_cus19;
    EXECUTE st_cus19;
    DEALLOCATE PREPARE st_cus19;
  END IF;
END$$
DELIMITER ;

CALL sp_tmp_cus19_columna('log_auditoria', 'hash_anterior',
     'CHAR(64) NULL COMMENT ''CUS19: sello del registro anterior (cadena SHA-256)'' AFTER detalle_json');
CALL sp_tmp_cus19_columna('log_auditoria', 'hash_registro',
     'CHAR(64) NULL COMMENT ''CUS19: SHA-256 del registro encadenado al anterior'' AFTER hash_anterior');
-- 4 consultar(filtros): búsquedas por usuario, proceso y dirección de origen dentro de un rango de fechas
CALL sp_tmp_cus19_indice('log_auditoria', 'ix_log_usuario_fecha', 'id_usuario, fecha_hora');
CALL sp_tmp_cus19_indice('log_auditoria', 'ix_log_proceso_fecha', 'id_proceso, fecha_hora');
CALL sp_tmp_cus19_indice('log_auditoria', 'ix_log_ip_fecha', 'ip_origen, fecha_hora');

DROP PROCEDURE IF EXISTS sp_tmp_cus19_columna;
DROP PROCEDURE IF EXISTS sp_tmp_cus19_indice;

-- ---------------------------------------------------------------------
-- 2. Tablas nuevas
-- ---------------------------------------------------------------------

-- 4 consultar() · 5 mostrarRegistros(): catálogo de los códigos de acción de la bitácora. No tiene FK
-- con log_auditoria: un código nuevo sin catálogo se sigue registrando y se muestra «sin clasificar».
CREATE TABLE IF NOT EXISTS bitacora_accion (
  codigo      VARCHAR(100) NOT NULL PRIMARY KEY,
  etiqueta    VARCHAR(120) NOT NULL,
  descripcion VARCHAR(300) NULL,
  modulo      ENUM('SEGURIDAD','ADMINISTRACION','PREPARACION','JORNADA','ESCRUTINIO','RESULTADOS','RECURSOS','MULTAS')
              NOT NULL,
  caso_uso    VARCHAR(20)  NULL,             -- CUS que la registra (CUS01 … CUS19)
  criticidad  ENUM('BAJA','MEDIA','ALTA','CRITICA') NOT NULL DEFAULT 'BAJA',
  orden       INT NOT NULL DEFAULT 0,
  KEY ix_bitacora_accion_modulo (modulo, orden)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Sello vigente de la cadena: último registro sellado y total desde el último reinicio. Una sola
-- fila (id_cadena = 1). trg_log_bi la bloquea (FOR UPDATE) para encadenar en orden aunque haya
-- inserciones simultáneas, y sp_verificar_bitacora la compara con el último registro.
CREATE TABLE IF NOT EXISTS bitacora_cadena (
  id_cadena           TINYINT  NOT NULL PRIMARY KEY,
  ultimo_id_log       BIGINT   NULL,
  ultimo_hash         CHAR(64) NOT NULL,
  total_registros     BIGINT   NOT NULL DEFAULT 0,
  fecha_inicio        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,   -- inicio de la cadena (instalación o reinicio)
  fecha_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_bitacora_cadena_unica CHECK (id_cadena = 1),
  CONSTRAINT chk_bitacora_cadena_hash CHECK (ultimo_hash REGEXP '^[0-9a-f]{64}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 3. Catálogo de acciones y parámetro nuevo
-- ---------------------------------------------------------------------
INSERT INTO bitacora_accion (codigo, etiqueta, descripcion, modulo, caso_uso, criticidad, orden) VALUES
  -- Seguridad del acceso
  ('LOGIN_SUCCESS',                  'Inicio de sesión',                      'Ingreso correcto al sistema con usuario y contraseña.', 'SEGURIDAD', 'CUS01', 'BAJA', 10),
  ('LOGIN_FAILED',                   'Inicio de sesión fallido',              'Contraseña incorrecta, cuenta inactiva o bloqueada por intentos.', 'SEGURIDAD', 'CUS01', 'MEDIA', 20),
  -- Administración (CUS18) y bitácora (CUS19)
  ('CREAR_USUARIO',                  'Cuenta creada',                         'Alta de una cuenta con su rol y, si corresponde, su docente.', 'ADMINISTRACION', 'CUS18', 'MEDIA', 10),
  ('ACTUALIZAR_USUARIO',             'Rol o docente de la cuenta modificado', 'Cambio del rol o del docente asociado a la cuenta.', 'ADMINISTRACION', 'CUS18', 'ALTA', 20),
  ('ACTIVAR_USUARIO',                'Cuenta activada',                       'La cuenta vuelve a poder iniciar sesión.', 'ADMINISTRACION', 'CUS18', 'MEDIA', 30),
  ('DESACTIVAR_USUARIO',             'Cuenta desactivada',                    'La cuenta no puede iniciar sesión; conserva su historia.', 'ADMINISTRACION', 'CUS18', 'ALTA', 40),
  ('RESTABLECER_PASSWORD',           'Contraseña restablecida',               'El administrador asignó una contraseña provisional.', 'ADMINISTRACION', 'CUS18', 'ALTA', 50),
  ('DESBLOQUEAR_USUARIO',            'Cuenta desbloqueada',                   'Se pusieron en cero los intentos fallidos.', 'ADMINISTRACION', 'CUS18', 'MEDIA', 60),
  ('ELIMINAR_USUARIO',               'Cuenta eliminada',                      'Eliminación de una cuenta sin actividad (RN28).', 'ADMINISTRACION', 'CUS18', 'ALTA', 70),
  ('CAMBIO_PARAMETRO',               'Parámetro modificado',                  'Cambio o restauración de un parámetro del reglamento o del sistema.', 'ADMINISTRACION', 'CUS18', 'ALTA', 80),
  ('GENERAR_RESPALDO',               'Respaldo de la base generado',          'Copia completa de la base con su huella SHA-256.', 'ADMINISTRACION', 'CUS18', 'MEDIA', 90),
  ('DESCARGAR_RESPALDO',             'Respaldo de la base descargado',        'Descarga del archivo de respaldo (contiene datos personales).', 'ADMINISTRACION', 'CUS18', 'ALTA', 100),
  ('VERIFICAR_RESPALDO',             'Integridad del respaldo verificada',    'Se recalculó la huella SHA-256 del archivo de respaldo.', 'ADMINISTRACION', 'CUS18', 'BAJA', 110),
  ('VERIFICAR_BITACORA',             'Integridad de la bitácora verificada',  'Se recalcularon los sellos encadenados de todos los registros.', 'ADMINISTRACION', 'CUS19', 'BAJA', 120),
  ('EXPORTAR_BITACORA',              'Bitácora exportada',                    'Descarga de registros de la bitácora en un archivo CSV.', 'ADMINISTRACION', 'CUS19', 'MEDIA', 130),
  ('REINICIAR_BITACORA',             'Bitácora reiniciada',                   'Se vaciaron los datos electorales y la bitácora (02_limpiar_datos_electorales.sql).', 'ADMINISTRACION', 'CUS19', 'CRITICA', 140),
  -- Preparación del proceso (CUS01-CUS07)
  ('CREAR_PROCESO',                  'Proceso electoral creado',              'Registro de una convocatoria.', 'PREPARACION', 'CUS01', 'MEDIA', 10),
  ('PUBLICAR_CONVOCATORIA',          'Convocatoria publicada',                'La convocatoria y su cronograma quedan públicos.', 'PREPARACION', 'CUS01', 'ALTA', 20),
  ('ACTUALIZAR_CRONOGRAMA',          'Cronograma actualizado',                'Cambio de las fechas del cronograma electoral.', 'PREPARACION', 'CUS01', 'MEDIA', 30),
  ('AGREGAR_CARGO',                  'Cargo agregado al proceso',             'Se agregó un cargo a elegir.', 'PREPARACION', 'CUS01', 'MEDIA', 40),
  ('QUITAR_CARGO',                   'Cargo quitado del proceso',             'Se quitó un cargo a elegir.', 'PREPARACION', 'CUS01', 'MEDIA', 50),
  ('CAMBIO_ESTADO_PROCESO',          'Estado del proceso cambiado',           'El proceso pasó a otra etapa del cronograma.', 'PREPARACION', 'CUS01', 'ALTA', 60),
  ('ANULAR_PROCESO',                 'Proceso anulado',                       'El proceso electoral fue anulado.', 'PREPARACION', 'CUS01', 'CRITICA', 70),
  ('IMPORTAR_DOCENTES',              'Docentes importados',                   'Carga masiva del padrón de docentes desde Excel o CSV.', 'PREPARACION', 'CUS02', 'MEDIA', 80),
  ('DEPURAR_PADRON',                 'Padrón depurado',                       'Se filtraron los docentes habilitados para votar.', 'PREPARACION', 'CUS02', 'ALTA', 90),
  ('GENERAR_PADRON',                 'Padrón electoral generado',             'Padrón del proceso aprobado.', 'PREPARACION', 'CUS02', 'ALTA', 100),
  ('INSCRIBIR_LISTA',                'Lista inscrita',                        'Inscripción de una lista de candidatos.', 'PREPARACION', 'CUS03', 'MEDIA', 110),
  ('INSCRIBIR_CANDIDATO',            'Candidato inscrito',                    'Se agregó un candidato a una lista.', 'PREPARACION', 'CUS03', 'BAJA', 120),
  ('QUITAR_CANDIDATO',               'Candidato quitado',                     'Se quitó un candidato de una lista.', 'PREPARACION', 'CUS03', 'MEDIA', 130),
  ('RETIRAR_LISTA',                  'Lista retirada',                        'La lista se retiró del proceso.', 'PREPARACION', 'CUS03', 'ALTA', 140),
  ('VALIDAR_LISTA',                  'Lista calificada',                      'El CEUNP admitió u observó la lista.', 'PREPARACION', 'CUS03', 'ALTA', 150),
  ('PRESENTAR_TACHA',                'Tacha presentada',                      'Tacha contra una lista o un candidato.', 'PREPARACION', 'CUS04', 'MEDIA', 160),
  ('RESOLVER_TACHA',                 'Tacha resuelta',                        'El CEUNP declaró fundada o infundada la tacha.', 'PREPARACION', 'CUS04', 'ALTA', 170),
  ('ACREDITAR_PERSONERO',            'Personero acreditado',                  'Acreditación de un personero de lista.', 'PREPARACION', 'CUS05', 'MEDIA', 180),
  ('REVOCAR_PERSONERO',              'Personero revocado',                    'Se revocó la acreditación del personero.', 'PREPARACION', 'CUS05', 'ALTA', 190),
  ('CREAR_MESAS',                    'Mesas de sufragio creadas',             'Conformación de las mesas según el padrón.', 'PREPARACION', 'CUS06', 'MEDIA', 200),
  ('SORTEO_MESA',                    'Sorteo de miembros de una mesa',        'Sorteo de titulares y suplentes de una mesa.', 'PREPARACION', 'CUS06', 'ALTA', 210),
  ('SORTEO_GENERAL_MESAS',           'Sorteo general de miembros de mesa',    'Sorteo de los miembros de todas las mesas.', 'PREPARACION', 'CUS06', 'ALTA', 220),
  ('SORTEO_ORDEN_CEDULA',            'Sorteo del orden en la cédula',         'Orden de las listas en la cédula de votación.', 'PREPARACION', 'CUS06', 'ALTA', 230),
  ('EMITIR_CREDENCIAL',              'Credencial QR emitida',                 'Emisión de una credencial con código QR.', 'PREPARACION', 'CUS07', 'BAJA', 240),
  ('REVOCAR_CREDENCIAL',             'Credencial QR revocada',                'La credencial deja de ser válida.', 'PREPARACION', 'CUS07', 'ALTA', 250),
  ('VERIFICAR_CREDENCIAL',           'Credencial QR verificada',              'Lectura y comprobación de una credencial.', 'PREPARACION', 'CUS07', 'BAJA', 260),
  ('CONSULTA_PUBLICA_CREDENCIAL',    'Credencial QR consultada (pública)',    'Apertura de la página pública de una credencial al escanear su QR.', 'PREPARACION', 'CUS07', 'BAJA', 261),
  ('RECIBIR_CREDENCIAL_PERSONERO',   'Credencial de personero recibida',      'El personero recibió su credencial.', 'PREPARACION', 'CUS07', 'BAJA', 270),
  -- Jornada electoral (CUS08-CUS11)
  ('REGISTRAR_LLEGADA_MIEMBRO',      'Llegada de miembro de mesa',            'Registro de la hora de llegada del miembro.', 'JORNADA', 'CUS08', 'BAJA', 10),
  ('REGISTRAR_REEMPLAZANTE_MESA',    'Reemplazante de mesa registrado',       'Un elector reemplaza a un miembro ausente.', 'JORNADA', 'CUS08', 'MEDIA', 20),
  ('QUITAR_REEMPLAZANTE_MESA',       'Reemplazante de mesa quitado',          'Se quitó al reemplazante registrado.', 'JORNADA', 'CUS08', 'MEDIA', 30),
  ('VERIFICAR_MATERIAL_MESA',        'Material electoral verificado',         'Revisión del material de la mesa.', 'JORNADA', 'CUS08', 'BAJA', 40),
  ('INCIDENCIA_MESA',                'Incidencia de mesa',                    'Incidencia registrada durante la instalación o el sufragio.', 'JORNADA', 'CUS08', 'MEDIA', 50),
  ('INSTALAR_MESA',                  'Mesa instalada',                        'Acta de instalación de la mesa.', 'JORNADA', 'CUS08', 'ALTA', 60),
  ('MESA_NO_INSTALADA',              'Mesa no instalada',                     'Venció la hora límite sin instalar la mesa (RF58).', 'JORNADA', 'CUS08', 'ALTA', 70),
  ('IDENTIFICAR_ELECTOR',            'Elector identificado',                  'Identificación del elector en la mesa.', 'JORNADA', 'CUS09', 'BAJA', 80),
  ('VERIFICAR_ELECTOR',              'Elector verificado',                    'El elector figura en el padrón de la mesa.', 'JORNADA', 'CUS09', 'BAJA', 90),
  ('REGISTRAR_ASISTENCIA',           'Asistencia del elector registrada',     'El elector firmó la lista de la mesa.', 'JORNADA', 'CUS09', 'BAJA', 100),
  ('CONECTAR_TERMINAL',              'Terminal de votación conectada',        'Se habilitó una terminal para un elector.', 'JORNADA', 'CUS10', 'MEDIA', 110),
  ('LIBERAR_TERMINAL',               'Terminal de votación liberada',         'La terminal quedó libre.', 'JORNADA', 'CUS10', 'BAJA', 120),
  ('EMITIR_VOTO',                    'Voto emitido',                          'El elector votó. Nunca se registra por quién (RNF05).', 'JORNADA', 'CUS10', 'BAJA', 130),
  ('MARCAR_NO_VOTO',                 'Elector marcado sin votar',             'Elector ausente al cierre del sufragio.', 'JORNADA', 'CUS11', 'MEDIA', 140),
  ('CERRAR_MESA',                    'Mesa cerrada',                          'Cierre de la votación en la mesa.', 'JORNADA', 'CUS11', 'ALTA', 150),
  ('CERRAR_SUFRAGIO',                'Sufragio cerrado',                      'Cierre del sufragio de la mesa.', 'JORNADA', 'CUS11', 'ALTA', 160),
  ('EMITIR_ACTA_SUFRAGIO',           'Acta de sufragio emitida',              'Acta de sufragio con su huella SHA-256.', 'JORNADA', 'CUS11', 'ALTA', 170),
  -- Escrutinio (CUS12)
  ('CONTAR_CEDULAS',                 'Cédulas contadas',                      'Conteo de las cédulas de la mesa.', 'ESCRUTINIO', 'CUS12', 'MEDIA', 10),
  ('REGISTRAR_CONTEO_ESCRUTINIO',    'Conteo del escrutinio registrado',      'Conteo manual conciliado con el digital.', 'ESCRUTINIO', 'CUS12', 'ALTA', 20),
  ('EMITIR_ACTA_ESCRUTINIO',         'Acta de escrutinio emitida',            'Acta de escrutinio con su huella SHA-256.', 'ESCRUTINIO', 'CUS12', 'ALTA', 30),
  ('ENTREGAR_ACTAS',                 'Actas entregadas al CEUNP',             'Entrega de las actas de la mesa.', 'ESCRUTINIO', 'CUS12', 'ALTA', 40),
  ('EVALUAR_NULIDAD_MESA',           'Nulidad de mesa evaluada',              'Evaluación de causales de nulidad en la mesa.', 'ESCRUTINIO', 'CUS12', 'ALTA', 50),
  -- Impugnaciones y nulidades (CUS13, CUS15)
  ('REGISTRAR_IMPUGNACION',          'Impugnación registrada',                'Impugnación de un voto en la mesa.', 'RECURSOS', 'CUS13', 'MEDIA', 10),
  ('RESOLVER_IMPUGNACION_MESA',      'Impugnación resuelta por la mesa',      'Decisión de la mesa sobre la impugnación.', 'RECURSOS', 'CUS13', 'ALTA', 20),
  ('APELAR_IMPUGNACION',             'Impugnación apelada',                   'Apelación ante el CEUNP.', 'RECURSOS', 'CUS13', 'MEDIA', 30),
  ('RESOLVER_APELACION',             'Apelación resuelta',                    'Fallo del Pleno del CEUNP.', 'RECURSOS', 'CUS13', 'ALTA', 40),
  ('REGISTRAR_RECURSO_NULIDAD',      'Recurso de nulidad presentado',         'Pedido de nulidad parcial o total.', 'RECURSOS', 'CUS15', 'MEDIA', 50),
  ('DESESTIMAR_NULIDAD',             'Nulidad desestimada',                   'El Pleno declaró infundado o improcedente el recurso.', 'RECURSOS', 'CUS15', 'ALTA', 60),
  ('DECLARAR_NULIDAD_PARCIAL',       'Nulidad parcial declarada',             'Se anularon los votos de una mesa.', 'RECURSOS', 'CUS15', 'CRITICA', 70),
  ('DECLARAR_NULIDAD_TOTAL',         'Nulidad total declarada',               'La elección fue declarada nula.', 'RECURSOS', 'CUS15', 'CRITICA', 80),
  ('REGISTRAR_COMUNICACION_NULIDAD', 'Comunicación de nulidad registrada',    'Comunicación de la nulidad a los órganos de gobierno.', 'RECURSOS', 'CUS15', 'MEDIA', 90),
  ('DIRIMIR_EMPATE',                 'Empate dirimido',                       'Sorteo para dirimir un empate.', 'RECURSOS', 'CUS15', 'CRITICA', 100),
  -- Cómputo y resultados (CUS14, CUS17)
  ('INSTALAR_SESION_COMPUTO',        'Sesión de cómputo instalada',           'El Pleno instaló la sesión de cómputo.', 'RESULTADOS', 'CUS14', 'ALTA', 10),
  ('REGISTRAR_PERSONERO_COMPUTO',    'Personero en el cómputo',               'Asistencia de un personero al cómputo.', 'RESULTADOS', 'CUS14', 'BAJA', 20),
  ('MARCAR_ACTA_DUDOSA',             'Acta marcada como dudosa',              'El acta requiere comprobación.', 'RESULTADOS', 'CUS14', 'ALTA', 30),
  ('COMPROBAR_ACTA',                 'Acta comprobada',                       'Comprobación del acta contra su huella.', 'RESULTADOS', 'CUS14', 'MEDIA', 40),
  ('CALIFICAR_ACTA',                 'Acta calificada',                       'Calificación del acta en el cómputo.', 'RESULTADOS', 'CUS14', 'ALTA', 50),
  ('DECLARAR_NULIDAD_MESA',          'Mesa anulada en el cómputo',            'La calificación declaró nula la mesa.', 'RESULTADOS', 'CUS14', 'CRITICA', 60),
  ('COMPUTAR_RESULTADOS',            'Resultados computados',                 'Cómputo general de la elección.', 'RESULTADOS', 'CUS14', 'CRITICA', 70),
  ('PROCLAMAR_RESULTADOS',           'Resultados proclamados',                'Proclamación de las listas ganadoras.', 'RESULTADOS', 'CUS14', 'CRITICA', 80),
  ('PUBLICAR_RESULTADOS',            'Resultados publicados',                 'Publicación en el portal de resultados.', 'RESULTADOS', 'CUS14', 'CRITICA', 90),
  ('CREAR_SEGUNDA_VUELTA',           'Segunda vuelta convocada',              'Convocatoria a segunda vuelta (RN33).', 'RESULTADOS', 'CUS14', 'CRITICA', 100),
  ('REGISTRAR_COTEJO_ACTA',          'Acta cotejada conforme',                'El acta física coincide con la digital.', 'RESULTADOS', 'CUS17', 'BAJA', 110),
  ('REPORTAR_DISCREPANCIA_ACTA',     'Discrepancia de acta reportada',        'El acta física no coincide con la digital.', 'RESULTADOS', 'CUS17', 'ALTA', 120),
  ('ATENDER_DISCREPANCIA_ACTA',      'Discrepancia de acta atendida',         'El CEUNP atendió la discrepancia.', 'RESULTADOS', 'CUS17', 'ALTA', 130),
  -- Omisos y multas (CUS16)
  ('GENERAR_MULTAS',                 'Multas generadas',                      'Determinación de multas a omisos (RN35).', 'MULTAS', 'CUS16', 'ALTA', 10),
  ('ACTUALIZAR_MULTA',               'Multa actualizada',                     'Cambio del estado o del monto de la multa.', 'MULTAS', 'CUS16', 'ALTA', 20),
  ('EMITIR_RESOLUCION_MULTAS',       'Resolución de multas emitida',          'Resolución del Pleno con su huella y QR.', 'MULTAS', 'CUS16', 'ALTA', 30),
  ('NOTIFICAR_MULTAS',               'Multas notificadas',                    'Notificación a los multados.', 'MULTAS', 'CUS16', 'MEDIA', 40),
  ('JUSTIFICAR_MULTA',               'Multa justificada',                     'Se aceptó la justificación de la omisión.', 'MULTAS', 'CUS16', 'MEDIA', 50),
  ('DENEGAR_JUSTIFICACION',          'Justificación denegada',                'Se denegó la justificación.', 'MULTAS', 'CUS16', 'MEDIA', 60),
  ('EXONERAR_MULTA',                 'Multa exonerada',                       'Exoneración de la multa.', 'MULTAS', 'CUS16', 'ALTA', 70),
  ('REGISTRAR_PAGO_MULTA',           'Pago de multa registrado',              'Registro del recibo de pago.', 'MULTAS', 'CUS16', 'MEDIA', 80)
ON DUPLICATE KEY UPDATE etiqueta = VALUES(etiqueta), descripcion = VALUES(descripcion), modulo = VALUES(modulo),
  caso_uso = VALUES(caso_uso), criticidad = VALUES(criticidad), orden = VALUES(orden);

-- Máximo de registros por exportación (CSV). Su definición lo valida como los demás parámetros (CUS18).
INSERT INTO parametro_global (clave, valor, descripcion) VALUES
  ('BITACORA_EXPORTACION_MAX', '20000', 'Máximo de registros de la bitácora que se descargan en una exportación (CUS19)')
ON DUPLICATE KEY UPDATE descripcion = descripcion;

INSERT INTO parametro_definicion (clave, grupo, etiqueta, tipo, minimo, maximo, unidad, referencia, bloqueo_jornada, orden) VALUES
  ('BITACORA_EXPORTACION_MAX', 'SEGURIDAD', 'Registros por exportación de la bitácora', 'ENTERO', 100, 100000, 'registros', 'RN28', FALSE, 40)
ON DUPLICATE KEY UPDATE grupo = VALUES(grupo), etiqueta = VALUES(etiqueta), tipo = VALUES(tipo),
  minimo = VALUES(minimo), maximo = VALUES(maximo), unidad = VALUES(unidad), referencia = VALUES(referencia),
  bloqueo_jornada = VALUES(bloqueo_jornada), orden = VALUES(orden);

-- ---------------------------------------------------------------------
-- 4. Función del sello
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_hash_bitacora;

DELIMITER $$

-- SHA-256 de un registro encadenado al sello del anterior. Cubre todos los campos del registro;
-- cambiar cualquiera (o el orden de la cadena) cambia el sello.
CREATE FUNCTION fn_hash_bitacora(p_hash_anterior CHAR(64), p_id_usuario INT, p_id_docente INT, p_id_proceso INT,
                                 p_accion VARCHAR(100), p_ip VARCHAR(45), p_user_agent VARCHAR(500),
                                 p_fecha DATETIME, p_detalle LONGTEXT) RETURNS CHAR(64)
DETERMINISTIC NO SQL
BEGIN
  RETURN SHA2(CONCAT_WS('|',
           COALESCE(p_hash_anterior, ''), COALESCE(p_id_usuario, ''), COALESCE(p_id_docente, ''),
           COALESCE(p_id_proceso, ''), COALESCE(p_accion, ''), COALESCE(p_ip, ''), COALESCE(p_user_agent, ''),
           COALESCE(DATE_FORMAT(p_fecha, '%Y-%m-%d %H:%i:%s'), ''), COALESCE(p_detalle, '')), 256);
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- 5. Sellado de los registros existentes (solo la primera vez) y triggers
-- ---------------------------------------------------------------------
-- trg_log_bu impide modificar la bitácora; se quita un momento para escribir el sello de los
-- registros anteriores al CUS19, en su orden, y se vuelve a crear igual que antes.
DROP TRIGGER IF EXISTS trg_log_bi;
DROP TRIGGER IF EXISTS trg_log_bu;
DROP PROCEDURE IF EXISTS sp_tmp_cus19_sellar;

DELIMITER $$
CREATE PROCEDURE sp_tmp_cus19_sellar()
BEGIN
  DECLARE v_fin TINYINT DEFAULT 0;
  DECLARE v_id BIGINT;
  DECLARE v_usuario, v_docente, v_proceso INT;
  DECLARE v_accion VARCHAR(100);
  DECLARE v_ip VARCHAR(45);
  DECLARE v_ua VARCHAR(500);
  DECLARE v_fecha DATETIME;
  DECLARE v_detalle LONGTEXT;
  DECLARE v_prev CHAR(64) DEFAULT REPEAT('0', 64);
  DECLARE v_hash CHAR(64);
  DECLARE v_total BIGINT DEFAULT 0;
  DECLARE c_log CURSOR FOR
    SELECT id_log, id_usuario, id_docente, id_proceso, accion, ip_origen, user_agent, fecha_hora, detalle_json
      FROM log_auditoria ORDER BY id_log;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = 1;

  -- Solo si ningún registro tiene sello: en una reejecución la cadena ya existe y no se toca.
  IF NOT EXISTS (SELECT 1 FROM log_auditoria WHERE hash_registro IS NOT NULL) THEN
    START TRANSACTION;
    OPEN c_log;
    sellar: LOOP
      FETCH c_log INTO v_id, v_usuario, v_docente, v_proceso, v_accion, v_ip, v_ua, v_fecha, v_detalle;
      IF v_fin = 1 THEN
        LEAVE sellar;
      END IF;
      SET v_hash = fn_hash_bitacora(v_prev, v_usuario, v_docente, v_proceso, v_accion, v_ip, v_ua, v_fecha, v_detalle);
      UPDATE log_auditoria SET hash_anterior = v_prev, hash_registro = v_hash WHERE id_log = v_id;
      SET v_prev = v_hash;
      SET v_total = v_total + 1;
    END LOOP;
    CLOSE c_log;

    INSERT INTO bitacora_cadena (id_cadena, ultimo_id_log, ultimo_hash, total_registros, fecha_inicio, fecha_actualizacion)
    VALUES (1, (SELECT MAX(id_log) FROM log_auditoria), v_prev, v_total,
            COALESCE((SELECT MIN(fecha_hora) FROM log_auditoria), NOW()), NOW())
    ON DUPLICATE KEY UPDATE ultimo_id_log = VALUES(ultimo_id_log), ultimo_hash = VALUES(ultimo_hash),
      total_registros = VALUES(total_registros), fecha_inicio = VALUES(fecha_inicio),
      fecha_actualizacion = VALUES(fecha_actualizacion);
    COMMIT;
  END IF;
END$$
DELIMITER ;

CALL sp_tmp_cus19_sellar();
DROP PROCEDURE IF EXISTS sp_tmp_cus19_sellar;

DELIMITER $$

CREATE TRIGGER trg_log_bu BEFORE UPDATE ON log_auditoria
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La bitacora de auditoria es inmutable.';
END$$

-- Sello encadenado de cada registro nuevo. El FOR UPDATE sobre bitacora_cadena ordena las
-- inserciones simultáneas: cada una se encadena al sello vigente y lo reemplaza. Si la inserción
-- falla, el cambio del sello se deshace con ella.
CREATE TRIGGER trg_log_bi BEFORE INSERT ON log_auditoria
FOR EACH ROW
BEGIN
  DECLARE v_prev CHAR(64) DEFAULT NULL;

  IF NEW.fecha_hora IS NULL THEN
    SET NEW.fecha_hora = NOW();
  END IF;
  SELECT ultimo_hash INTO v_prev FROM bitacora_cadena WHERE id_cadena = 1 FOR UPDATE;
  SET NEW.hash_anterior = COALESCE(v_prev, REPEAT('0', 64));
  SET NEW.hash_registro = fn_hash_bitacora(NEW.hash_anterior, NEW.id_usuario, NEW.id_docente, NEW.id_proceso,
                                           NEW.accion, NEW.ip_origen, NEW.user_agent, NEW.fecha_hora, NEW.detalle_json);
  INSERT INTO bitacora_cadena (id_cadena, ultimo_hash, total_registros, fecha_inicio, fecha_actualizacion)
  VALUES (1, NEW.hash_registro, 1, NOW(), NOW())
  ON DUPLICATE KEY UPDATE ultimo_hash = NEW.hash_registro, total_registros = total_registros + 1,
                          fecha_actualizacion = NOW();
END$$

DROP TRIGGER IF EXISTS trg_log_ai$$
CREATE TRIGGER trg_log_ai AFTER INSERT ON log_auditoria
FOR EACH ROW
BEGIN
  UPDATE bitacora_cadena SET ultimo_id_log = NEW.id_log WHERE id_cadena = 1;
END$$

DELIMITER ;

-- Cadena vacía (instalación sin registros): sello inicial de ceros.
INSERT IGNORE INTO bitacora_cadena (id_cadena, ultimo_id_log, ultimo_hash, total_registros)
VALUES (1, NULL, REPEAT('0', 64), 0);

-- ---------------------------------------------------------------------
-- 6. Vista
-- ---------------------------------------------------------------------

-- 4 consultar(filtros) · 5 mostrarRegistros(lista): cada registro con su autor (cuenta, rol y
-- docente de la cuenta), el docente al que se refiere (elector, miembro, candidato), el proceso
-- y la acción catalogada. EMITIR_VOTO solo dice que el docente votó, nunca por quién (RNF05).
CREATE OR REPLACE VIEW v_bitacora AS
SELECT l.id_log,
       l.fecha_hora,
       l.accion,
       COALESCE(a.etiqueta, REPLACE(l.accion, '_', ' ')) AS etiqueta,
       a.descripcion                                     AS descripcion_accion,
       COALESCE(a.modulo, 'SIN_CLASIFICAR')              AS modulo,
       a.caso_uso,
       COALESCE(a.criticidad, 'MEDIA')                   AS criticidad,
       (a.codigo IS NOT NULL)                            AS catalogada,
       l.id_usuario,
       u.username,
       u.rol,
       CONCAT(du.apellidos, ', ', du.nombres)            AS usuario_docente,
       l.id_docente,
       CONCAT(d.apellidos, ', ', d.nombres)              AS docente,
       d.dni                                             AS dni_docente,
       l.id_proceso,
       p.nombre                                          AS proceso,
       l.ip_origen,
       l.user_agent,
       l.detalle_json,
       l.hash_anterior,
       l.hash_registro
  FROM log_auditoria l
  LEFT JOIN bitacora_accion a    ON a.codigo = l.accion
  LEFT JOIN usuario u            ON u.id_usuario = l.id_usuario
  LEFT JOIN docente du           ON du.id_docente = u.id_docente
  LEFT JOIN docente d            ON d.id_docente = l.id_docente
  LEFT JOIN proceso_electoral p  ON p.id_proceso = l.id_proceso;

-- ---------------------------------------------------------------------
-- 7. Procedimientos
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_detalle_bitacora;
DROP PROCEDURE IF EXISTS sp_verificar_bitacora;
DROP PROCEDURE IF EXISTS sp_registrar_exportacion_bitacora;

DELIMITER $$

-- 7 obtenerDetalle(id_log) → 8 consultarDetalle(id_log): el registro, el anterior y el siguiente de la
-- cadena, y si su sello es válido (contenido sin cambios y enlazado al registro anterior). Solo lectura.
CREATE PROCEDURE sp_detalle_bitacora(IN p_id_admin INT, IN p_id_log BIGINT)
BEGIN
  DECLARE v_ant BIGINT;
  DECLARE v_sig BIGINT;
  DECLARE v_hash_ant CHAR(64);

  -- 3 validarRolAdministrador()
  CALL sp_validar_admin(p_id_admin);
  IF NOT EXISTS (SELECT 1 FROM log_auditoria WHERE id_log = p_id_log) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS19: el registro de la bitácora no existe.';
  END IF;

  SELECT MAX(id_log) INTO v_ant FROM log_auditoria WHERE id_log < p_id_log;
  SELECT MIN(id_log) INTO v_sig FROM log_auditoria WHERE id_log > p_id_log;
  SELECT hash_registro INTO v_hash_ant FROM log_auditoria WHERE id_log = v_ant;

  SELECT v.*,
         v_ant AS id_anterior,
         v_sig AS id_siguiente,
         fn_hash_bitacora(l.hash_anterior, l.id_usuario, l.id_docente, l.id_proceso, l.accion,
                          l.ip_origen, l.user_agent, l.fecha_hora, l.detalle_json) AS hash_calculado,
         (l.hash_registro IS NOT NULL
          AND l.hash_registro = fn_hash_bitacora(l.hash_anterior, l.id_usuario, l.id_docente, l.id_proceso, l.accion,
                                                 l.ip_origen, l.user_agent, l.fecha_hora, l.detalle_json)) AS contenido_integro,
         -- El primero de la cadena se enlaza al sello inicial (ceros); los demás, al sello del anterior.
         (l.hash_anterior IS NOT NULL
          AND (l.hash_anterior = v_hash_ant OR (l.hash_anterior = REPEAT('0', 64)
               AND (v_ant IS NULL OR l.accion = 'REINICIAR_BITACORA')))) AS enlace_valido,
         (SELECT COUNT(*) FROM log_auditoria x
           WHERE x.id_usuario = l.id_usuario AND l.id_usuario IS NOT NULL) AS acciones_usuario,
         (SELECT COUNT(*) FROM log_auditoria x
           WHERE x.id_proceso = l.id_proceso AND l.id_proceso IS NOT NULL) AS acciones_proceso
    FROM v_bitacora v JOIN log_auditoria l ON l.id_log = v.id_log
   WHERE v.id_log = p_id_log;
END$$

-- Verifica la cadena completa: recalcula el sello de cada registro, comprueba que esté enlazado al
-- anterior y que el último coincida con bitacora_cadena (registros borrados al final). Devuelve las
-- anomalías (hasta 100) y el resumen en parámetros OUT, y registra VERIFICAR_BITACORA.
--   CONTENIDO_ALTERADO: el registro cambió después de sellarse.
--   ENLACE_ROTO:        falta el registro anterior (borrado) o se insertó uno por fuera de la cadena.
--   SIN_SELLO:          registro escrito sin el trigger trg_log_bi.
--   FINAL_ELIMINADO:    el último registro no es el que indica el sello vigente.
CREATE PROCEDURE sp_verificar_bitacora(IN p_id_admin INT, IN p_ip VARCHAR(45), IN p_user_agent VARCHAR(500),
                                       OUT p_estado VARCHAR(20), OUT p_registros BIGINT, OUT p_anomalias INT,
                                       OUT p_primer_id BIGINT, OUT p_hash_final CHAR(64), OUT p_id_log BIGINT)
BEGIN
  DECLARE v_fin TINYINT DEFAULT 0;
  DECLARE v_id BIGINT;
  DECLARE v_accion VARCHAR(100);
  DECLARE v_fecha DATETIME;
  DECLARE v_ant, v_hash, v_calc CHAR(64);
  DECLARE v_prev CHAR(64) DEFAULT REPEAT('0', 64);
  DECLARE v_alterados, v_rotos, v_sin_sello INT DEFAULT 0;
  DECLARE v_total BIGINT DEFAULT 0;
  DECLARE v_ultimo BIGINT DEFAULT NULL;
  DECLARE v_sello_id BIGINT;
  DECLARE v_sello_hash CHAR(64);
  DECLARE v_sello_total BIGINT;
  DECLARE v_sello_ok TINYINT DEFAULT 1;
  DECLARE v_inicio DATETIME(3) DEFAULT NOW(3);
  DECLARE c_log CURSOR FOR
    SELECT id_log, accion, fecha_hora, hash_anterior, hash_registro,
           fn_hash_bitacora(hash_anterior, id_usuario, id_docente, id_proceso, accion, ip_origen, user_agent,
                            fecha_hora, detalle_json)
      FROM log_auditoria ORDER BY id_log;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = 1;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    DROP TEMPORARY TABLE IF EXISTS tmp_bitacora_anomalia;
    RESIGNAL;
  END;

  -- 3 validarRolAdministrador()
  CALL sp_validar_admin(p_id_admin);

  DROP TEMPORARY TABLE IF EXISTS tmp_bitacora_anomalia;
  CREATE TEMPORARY TABLE tmp_bitacora_anomalia (
    id_log  BIGINT NOT NULL,
    tipo    VARCHAR(20) NOT NULL,
    accion  VARCHAR(100) NULL,
    fecha   DATETIME NULL,
    detalle VARCHAR(300) NOT NULL
  ) ENGINE=MEMORY;

  -- La cadena y su sello se leen en la misma instantánea: lo que se inserte mientras tanto no cuenta.
  START TRANSACTION WITH CONSISTENT SNAPSHOT;
  SELECT ultimo_id_log, ultimo_hash, total_registros INTO v_sello_id, v_sello_hash, v_sello_total
    FROM bitacora_cadena WHERE id_cadena = 1;

  OPEN c_log;
  recorrer: LOOP
    FETCH c_log INTO v_id, v_accion, v_fecha, v_ant, v_hash, v_calc;
    IF v_fin = 1 THEN
      LEAVE recorrer;
    END IF;
    SET v_total = v_total + 1;
    SET v_ultimo = v_id;
    IF v_hash IS NULL THEN
      SET v_sin_sello = v_sin_sello + 1;
      INSERT INTO tmp_bitacora_anomalia VALUES (v_id, 'SIN_SELLO', v_accion, v_fecha,
        'Registro sin sello: se escribió sin pasar por el trigger de la bitácora.');
    ELSE
      IF v_hash <> v_calc THEN
        SET v_alterados = v_alterados + 1;
        INSERT INTO tmp_bitacora_anomalia VALUES (v_id, 'CONTENIDO_ALTERADO', v_accion, v_fecha,
          'El contenido del registro cambió después de sellarse.');
      END IF;
      -- Un reinicio documentado (02_limpiar_datos_electorales.sql) empieza una cadena nueva.
      IF NOT (v_ant <=> v_prev) AND NOT (v_accion = 'REINICIAR_BITACORA' AND v_ant = REPEAT('0', 64)) THEN
        SET v_rotos = v_rotos + 1;
        INSERT INTO tmp_bitacora_anomalia VALUES (v_id, 'ENLACE_ROTO', v_accion, v_fecha,
          'No se enlaza con el registro anterior: falta un registro o se insertó uno por fuera de la cadena.');
      END IF;
      SET v_prev = v_hash;
    END IF;
  END LOOP;
  CLOSE c_log;
  COMMIT;

  IF v_total > 0 AND (v_sello_id IS NULL OR v_sello_id <> v_ultimo OR v_sello_hash <> v_prev) THEN
    SET v_sello_ok = 0;
    INSERT INTO tmp_bitacora_anomalia VALUES (COALESCE(v_sello_id, v_ultimo), 'FINAL_ELIMINADO', NULL, NULL,
      LEFT(CONCAT('El sello vigente indica el registro N.º ', COALESCE(v_sello_id, '—'), ' como último y la bitácora termina en el N.º ',
                  v_ultimo, ': se eliminaron o alteraron los registros finales.'), 300));
  ELSEIF v_total = 0 AND COALESCE(v_sello_total, 0) > 0 THEN
    SET v_sello_ok = 0;
    INSERT INTO tmp_bitacora_anomalia VALUES (COALESCE(v_sello_id, 0), 'FINAL_ELIMINADO', NULL, NULL,
      'El sello vigente registra entradas, pero la bitácora está vacía.');
  END IF;

  SET p_registros = v_total;
  SET p_anomalias = v_alterados + v_rotos + v_sin_sello + (1 - v_sello_ok);
  SET p_estado = IF(v_total = 0 AND p_anomalias = 0, 'VACIA', IF(p_anomalias = 0, 'INTEGRA', 'ALTERADA'));
  SET p_hash_final = IF(v_total = 0, NULL, v_prev);
  SELECT MIN(id_log) INTO p_primer_id FROM tmp_bitacora_anomalia WHERE tipo <> 'FINAL_ELIMINADO';
  IF p_primer_id IS NULL AND v_sello_ok = 0 THEN
    SET p_primer_id = v_ultimo;
  END IF;

  START TRANSACTION;
  INSERT INTO log_auditoria (id_usuario, accion, ip_origen, user_agent, detalle_json)
  VALUES (p_id_admin, 'VERIFICAR_BITACORA', p_ip, LEFT(p_user_agent, 500),
          JSON_OBJECT('resultado', p_estado, 'registros', v_total, 'contenido_alterado', v_alterados,
                      'enlaces_rotos', v_rotos, 'sin_sello', v_sin_sello, 'sello_vigente_coincide', v_sello_ok = 1,
                      'primer_registro_anomalo', p_primer_id, 'ultimo_registro', v_ultimo, 'hash_final', p_hash_final,
                      'duracion_ms', TIMESTAMPDIFF(MICROSECOND, v_inicio, NOW(3)) DIV 1000));
  SET p_id_log = LAST_INSERT_ID();
  COMMIT;

  SELECT id_log, tipo, accion, fecha, detalle FROM tmp_bitacora_anomalia ORDER BY id_log, tipo LIMIT 100;
  DROP TEMPORARY TABLE IF EXISTS tmp_bitacora_anomalia;
END$$

-- Deja constancia de una exportación: quién descargó cuántos registros, con qué filtros y desde dónde.
CREATE PROCEDURE sp_registrar_exportacion_bitacora(IN p_id_admin INT, IN p_formato VARCHAR(10), IN p_registros INT,
                                                   IN p_filtros LONGTEXT, IN p_ip VARCHAR(45), IN p_user_agent VARCHAR(500))
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  CALL sp_validar_admin(p_id_admin);
  IF p_filtros IS NOT NULL AND NOT JSON_VALID(p_filtros) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUS19: los filtros de la exportación no son un JSON válido.';
  END IF;

  START TRANSACTION;
  INSERT INTO log_auditoria (id_usuario, accion, ip_origen, user_agent, detalle_json)
  VALUES (p_id_admin, 'EXPORTAR_BITACORA', p_ip, LEFT(p_user_agent, 500),
          JSON_OBJECT('formato', p_formato, 'registros', p_registros,
                      'filtros', JSON_EXTRACT(COALESCE(p_filtros, '{}'), '$')));
  COMMIT;

  SELECT LAST_INSERT_ID() AS id_log;
END$$

DELIMITER ;
