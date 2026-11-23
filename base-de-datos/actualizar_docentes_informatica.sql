-- =====================================================================
-- Actualización: Plana docente oficial de Ingeniería Informática (UNP)
-- Reemplaza los docentes anteriores por los 17 docentes oficiales
-- Departamento Académico de Ingeniería Informática (id_departamento = 38)
-- Facultad de Ingeniería Industrial (id_facultad = 12)
-- =====================================================================

START TRANSACTION;

-- 1. Eliminar usuarios asociados a los docentes anteriores del departamento 38
DELETE FROM usuario 
WHERE id_docente IN (SELECT id_docente FROM docente WHERE id_departamento = 38);

-- 2. Eliminar docentes del departamento 38
DELETE FROM docente WHERE id_departamento = 38;

-- 3. Insertar los 17 docentes oficiales
INSERT INTO docente (dni, nombres, apellidos, categoria, dedicacion, estado, habilitado_para_votar, id_facultad, id_departamento, grado_academico, email) VALUES
('02606057', 'Jorge', 'Alvarado Tabacchi', 'ASOCIADO', 'TC', 'ACTIVO', 1, 12, 38, 'MAESTRO', 'jalvaradot@unp.edu.pe'),
('02715290', 'Reucher Andrés', 'Correa Morocho', 'PRINCIPAL', 'DE', 'ACTIVO', 1, 12, 38, 'DOCTOR', 'rcorream@unp.edu.pe'),
('02817835', 'Pedro Antonio', 'Criollo Gonzales', 'PRINCIPAL', 'DE', 'ACTIVO', 1, 12, 38, 'DOCTOR', 'pcriollo@unp.edu.pe'),
('02635949', 'Wilfredo', 'Cruz Yarlequé', 'PRINCIPAL', 'DE', 'ACTIVO', 1, 12, 38, 'DOCTOR', 'wcruz@unp.edu.pe'),
('02775932', 'Héctor Wilmer', 'Fiestas Bancayán', 'PRINCIPAL', 'DE', 'ACTIVO', 1, 12, 38, 'DOCTOR', 'hfiestas@unp.edu.pe'),
('02867046', 'Iván Daniel', 'Imán Agurto', 'PRINCIPAL', 'DE', 'ACTIVO', 1, 12, 38, 'DOCTOR', 'iiman@unp.edu.pe'),
('40682528', 'Rolando Elías', 'Ipanaque Silva', 'AUXILIAR', 'TC', 'ACTIVO', 1, 12, 38, 'MAESTRO', 'ripanaque@unp.edu.pe'),
('02810146', 'Esther Yolanda', 'Lizana Puelles', 'ASOCIADO', 'TC', 'ACTIVO', 1, 12, 38, 'DOCTOR', 'elizana@unp.edu.pe'),
('42627674', 'Jonathan David', 'Nima Ramos', 'AUXILIAR', 'TP', 'ACTIVO', 1, 12, 38, 'MAESTRO', 'jnima@unp.edu.pe'),
('03691805', 'Hoower Augusto', 'Puicón Zapata', 'ASOCIADO', 'TC', 'ACTIVO', 1, 12, 38, 'DOCTOR', 'hpuicon@unp.edu.pe'),
('02600704', 'Rigo Félix', 'Requena Flores', 'PRINCIPAL', 'DE', 'ACTIVO', 1, 12, 38, 'DOCTOR', 'rrequena@unp.edu.pe'),
('42867712', 'Moisés David', 'Saavedra Arango', 'AUXILIAR', 'TC', 'ACTIVO', 1, 12, 38, 'DOCTOR', 'msaavedra@unp.edu.pe'),
('02849179', 'Luis Armando', 'Saavedra Yarlequé', 'ASOCIADO', 'TC', 'ACTIVO', 1, 12, 38, 'MAESTRO', 'lsaavedray@unp.edu.pe'),
('02887733', 'Arturo', 'Sandoval Rivera', 'ASOCIADO', 'DE', 'ACTIVO', 1, 12, 38, 'MAESTRO', 'asandoval@unp.edu.pe'),
('02786563', 'Jorge Luis', 'Sandoval Rivera', 'ASOCIADO', 'TC', 'ACTIVO', 1, 12, 38, 'DOCTOR', 'jsandoval@unp.edu.pe'),
('42813466', 'César', 'Silva More', 'AUXILIAR', 'TP', 'ACTIVO', 1, 12, 38, 'MAESTRO', 'csilva@unp.edu.pe'),
('06433589', 'Víctor Hugo', 'Valle Rios', 'ASOCIADO', 'TC', 'ACTIVO', 1, 12, 38, 'MAESTRO', 'vvalle@unp.edu.pe');

-- 4. Insertar las 17 cuentas de usuario (contraseña inicial: Docente2026)
INSERT INTO usuario (id_docente, username, password_hash, rol, activo, debe_cambiar_password)
SELECT id_docente,
  CASE dni
    WHEN '02606057' THEN 'jalvarado'
    WHEN '02715290' THEN 'rcorrea'
    WHEN '02817835' THEN 'pcriollo'
    WHEN '02635949' THEN 'wcruzy'
    WHEN '02775932' THEN 'hfiestasb'
    WHEN '02867046' THEN 'iiman'
    WHEN '40682528' THEN 'ripanaque'
    WHEN '02810146' THEN 'elizana'
    WHEN '42627674' THEN 'jnima'
    WHEN '03691805' THEN 'hpuicon'
    WHEN '02600704' THEN 'rrequenaf'
    WHEN '42867712' THEN 'msaavedra'
    WHEN '02849179' THEN 'lsaavedray'
    WHEN '02887733' THEN 'asandoval'
    WHEN '02786563' THEN 'jsandoval'
    WHEN '42813466' THEN 'csilva'
    WHEN '06433589' THEN 'vvalle'
  END,
  '$2a$10$PoKWP5YvcUJdR9IUVII7NOxeIPjQVPR64o9WUXGlOIAC0N9pB1azK',
  'DOCENTE',
  1,
  0
FROM docente
WHERE id_departamento = 38;

COMMIT;
