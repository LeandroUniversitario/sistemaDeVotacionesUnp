-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 06_demo_flujo_completo.sql  ·  OPCIONAL - prueba de punta a punta
--
-- Crea 60 docentes ficticios (DNI 90000001..90000060) y ejecuta una
-- elección completa de Rector usando SOLO los procedimientos almacenados.
-- Sirve para comprobar la instalación y para la sustentación.
--
-- Uso (pestaña SQL de phpMyAdmin, después de importar 01 a 05):
--     CALL sp_demo_flujo_completo();
-- Para dejar la base limpia otra vez, vuelve a importar 01 a 05.
-- =====================================================================
USE elecciones_unp;
-- Las rutinas guardan el sql_mode vigente al crearse: se fuerza modo estricto
-- (XAMPP viene sin STRICT y aceptaria valores invalidos en silencio).
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION';
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

DROP PROCEDURE IF EXISTS sp_demo_flujo_completo;

DELIMITER $$

CREATE PROCEDURE sp_demo_flujo_completo()
BEGIN
  DECLARE v_i        INT DEFAULT 1;
  DECLARE v_deps     INT DEFAULT 0;
  DECLARE v_off      INT;
  DECLARE v_dep      INT;
  DECLARE v_fac      INT;
  DECLARE v_dni      VARCHAR(8);
  DECLARE v_doc      INT;
  DECLARE v_proceso  INT;
  DECLARE v_cargo    INT;
  DECLARE v_lista_a  INT;
  DECLARE v_lista_b  INT;
  DECLARE v_lista_c  INT;
  DECLARE v_cand     INT;
  DECLARE v_cand_c   INT;
  DECLARE v_tacha    INT;
  DECLARE v_mesa     INT DEFAULT 0;
  DECLARE v_sig      INT;
  DECLARE v_token    CHAR(64);

  SELECT COUNT(*) INTO v_deps FROM departamento;
  IF v_deps = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Importe primero 05_datos_iniciales.sql (facultades y departamentos).';
  END IF;

  -- 1. Padrón docente de prueba ------------------------------------------------
  WHILE v_i <= 60 DO
    SET v_dni = CONCAT('9', LPAD(v_i, 7, '0'));
    IF NOT EXISTS (SELECT 1 FROM docente WHERE dni = v_dni) THEN
      SET v_off = v_i MOD v_deps;
      SELECT id_departamento, id_facultad INTO v_dep, v_fac
        FROM departamento ORDER BY id_departamento LIMIT v_off, 1;
      INSERT INTO docente (dni, nombres, apellidos, categoria, dedicacion, estado,
                           id_facultad, id_departamento, grado_academico)
      VALUES (v_dni, 'Docente', CONCAT('Demo ', LPAD(v_i, 3, '0')),
              ELT(1 + (v_i MOD 3), 'PRINCIPAL', 'ASOCIADO', 'AUXILIAR'),
              'TC', 'ACTIVO', v_fac, v_dep, IF(v_i MOD 3 = 0, 'DOCTOR', 'MAESTRO'));
    END IF;
    SET v_i = v_i + 1;
  END WHILE;

  -- Una autoridad vigente: no debe salir sorteada como miembro de mesa (RN20)
  SELECT id_docente INTO v_doc FROM docente WHERE dni = '90000060';
  IF NOT EXISTS (SELECT 1 FROM cargo_admin WHERE id_docente = v_doc AND vigente = 1) THEN
    INSERT INTO cargo_admin (id_docente, nombre_cargo, nivel, fecha_inicio)
    VALUES (v_doc, 'Decano', 'FACULTAD', CURDATE() - INTERVAL 1 YEAR);
  END IF;

  -- 2. Proceso y cargo ---------------------------------------------------------
  CALL sp_crear_proceso(CONCAT('DEMO Elección de Rector ', DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s')),
                        NOW() - INTERVAL 1 HOUR, NOW() + INTERVAL 6 HOUR,
                        60.00, CURDATE() - INTERVAL 35 DAY, NULL, NULL, v_proceso);
  CALL sp_agregar_cargo(v_proceso, 'Rector y Vicerrectores', 'UNIVERSIDAD', NULL,
                        'PRINCIPAL,ASOCIADO,AUXILIAR', 'PRINCIPAL', v_cargo);
  CALL sp_cambiar_estado_proceso(v_proceso, 'INSCRIPCION', NULL);

  -- 3. Tres listas (fórmulas de 3 docentes principales) -------------------------
  CALL sp_inscribir_lista(v_cargo, 'Lista A - Integridad Universitaria', 'A', NULL, NULL, v_lista_a);
  CALL sp_inscribir_lista(v_cargo, 'Lista B - Renovación Académica',     'B', NULL, NULL, v_lista_b);
  CALL sp_inscribir_lista(v_cargo, 'Lista C - Unidad Docente',           'C', NULL, NULL, v_lista_c);

  SELECT id_docente INTO v_doc FROM docente WHERE dni = '90000003';
  CALL sp_inscribir_candidato(v_lista_a, v_doc, 'RECTOR', NULL, NULL, v_cand);
  SELECT id_docente INTO v_doc FROM docente WHERE dni = '90000006';
  CALL sp_inscribir_candidato(v_lista_a, v_doc, 'VICERRECTOR_ACADEMICO', NULL, NULL, v_cand);
  SELECT id_docente INTO v_doc FROM docente WHERE dni = '90000009';
  CALL sp_inscribir_candidato(v_lista_a, v_doc, 'VICERRECTOR_INVESTIGACION', NULL, NULL, v_cand);

  SELECT id_docente INTO v_doc FROM docente WHERE dni = '90000012';
  CALL sp_inscribir_candidato(v_lista_b, v_doc, 'RECTOR', NULL, NULL, v_cand);
  SELECT id_docente INTO v_doc FROM docente WHERE dni = '90000015';
  CALL sp_inscribir_candidato(v_lista_b, v_doc, 'VICERRECTOR_ACADEMICO', NULL, NULL, v_cand);
  SELECT id_docente INTO v_doc FROM docente WHERE dni = '90000018';
  CALL sp_inscribir_candidato(v_lista_b, v_doc, 'VICERRECTOR_INVESTIGACION', NULL, NULL, v_cand);

  SELECT id_docente INTO v_doc FROM docente WHERE dni = '90000021';
  CALL sp_inscribir_candidato(v_lista_c, v_doc, 'RECTOR', NULL, NULL, v_cand_c);
  SELECT id_docente INTO v_doc FROM docente WHERE dni = '90000024';
  CALL sp_inscribir_candidato(v_lista_c, v_doc, 'VICERRECTOR_ACADEMICO', NULL, NULL, v_cand);
  SELECT id_docente INTO v_doc FROM docente WHERE dni = '90000027';
  CALL sp_inscribir_candidato(v_lista_c, v_doc, 'VICERRECTOR_INVESTIGACION', NULL, NULL, v_cand);

  -- 4. Tacha fundada contra el Rector de la Lista C: cae toda la lista (RN12) ----
  SELECT id_docente INTO v_doc FROM docente WHERE dni = '90000001';
  CALL sp_presentar_tacha(v_doc, v_cand_c, 'No acredita el grado de Doctor (RN09).', v_tacha);
  CALL sp_resolver_tacha(v_tacha, 'FUNDADA', 'Se verificó que no cumple el requisito.', NULL);

  CALL sp_validar_lista(v_lista_a, TRUE, NULL, NULL);
  CALL sp_validar_lista(v_lista_b, TRUE, NULL, NULL);

  -- 5. Sorteos, padrón y mesas -------------------------------------------------
  CALL sp_sortear_orden_cedula(v_cargo, 'DEMO-2026', NULL);
  CALL sp_generar_padron(v_proceso, NULL);
  CALL sp_crear_mesas(v_proceso, 30, 'Biblioteca Central', NULL);
  CALL sp_sortear_todas_las_mesas(v_proceso, 'DEMO-2026', NULL);

  -- 6. Día de la elección ------------------------------------------------------
  CALL sp_cambiar_estado_proceso(v_proceso, 'VOTACION', NULL);

  SET v_mesa = 0;
  instalar: LOOP
    SELECT MIN(id_mesa) INTO v_sig FROM mesa_electoral WHERE id_proceso = v_proceso AND id_mesa > v_mesa;
    IF v_sig IS NULL THEN
      LEAVE instalar;
    END IF;
    CALL sp_instalar_mesa(v_sig, NULL);
    SET v_mesa = v_sig;
  END LOOP;

  -- Asistencia de miembros: todos asisten salvo un vocal (recibirá multa OMISO_MESA)
  UPDATE miembro_mesa mm JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
     SET mm.asistio = 1 WHERE m.id_proceso = v_proceso;
  UPDATE miembro_mesa mm JOIN mesa_electoral m ON m.id_mesa = mm.id_mesa
     SET mm.asistio = 0
   WHERE m.id_proceso = v_proceso AND mm.rol = 'VOCAL' AND m.numero_mesa = '001';

  -- Votan todos menos 1 de cada 7 (omisos). 1 de cada 10 vota en blanco.
  SET v_i = 1;
  WHILE v_i <= 60 DO
    IF v_i MOD 7 <> 0 THEN
      SELECT id_docente INTO v_doc FROM docente WHERE dni = CONCAT('9', LPAD(v_i, 7, '0'));
      IF v_i MOD 10 = 0 THEN
        CALL sp_emitir_voto(v_proceso, v_cargo, v_doc, NULL, 'BLANCO', v_token);
      ELSEIF v_i MOD 5 < 3 THEN
        CALL sp_emitir_voto(v_proceso, v_cargo, v_doc, v_lista_a, 'VALIDO', v_token);
      ELSE
        CALL sp_emitir_voto(v_proceso, v_cargo, v_doc, v_lista_b, 'VALIDO', v_token);
      END IF;
    END IF;
    SET v_i = v_i + 1;
  END WHILE;

  -- 7. Cierre, cómputo y multas -------------------------------------------------
  SET v_mesa = 0;
  cerrar: LOOP
    SELECT MIN(id_mesa) INTO v_sig FROM mesa_electoral WHERE id_proceso = v_proceso AND id_mesa > v_mesa;
    IF v_sig IS NULL THEN
      LEAVE cerrar;
    END IF;
    CALL sp_cerrar_mesa(v_sig, NULL);
    SET v_mesa = v_sig;
  END LOOP;

  CALL sp_cambiar_estado_proceso(v_proceso, 'CERRADO', NULL);
  CALL sp_computar_resultados(v_proceso, NULL);
  CALL sp_generar_multas(v_proceso, NULL);

  -- 8. Resumen -----------------------------------------------------------------
  SELECT * FROM v_quorum_proceso  WHERE id_proceso = v_proceso;
  SELECT * FROM v_resultados_cargo WHERE id_proceso = v_proceso ORDER BY votos DESC;
  SELECT * FROM v_cuadre_votos    WHERE id_proceso = v_proceso;
  SELECT * FROM v_mesa_detalle    WHERE id_proceso = v_proceso;
  SELECT 'La última constancia emitida se verifica así:' AS nota, v_token AS token_de_ejemplo;
  CALL sp_verificar_constancia(v_token);
END$$

DELIMITER ;
