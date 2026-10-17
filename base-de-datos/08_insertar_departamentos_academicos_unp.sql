-- ============================================================================
-- SCRIPT: 08_insertar_departamentos_academicos_unp.sql
-- SISTEMA DE ELECCIONES UNP - PADRÓN DOCENTE
-- ============================================================================
-- CONTEXTO ORGANIZACIONAL UNP:
-- En la Universidad Nacional de Piura (UNP):
--   1. Las Escuelas Profesionales (35) gestionan carreras y planes de estudio
--      de los alumnos.
--   2. Los Departamentos Académicos (44) agrupan a los profesores según sus
--      disciplinas de enseñanza e investigación (Ley Universitaria 30220).
--
-- Este script vacía la tabla y registra exactamente los 44 departamentos
-- académicos oficiales distribuidos en las 14 facultades de la UNP.
-- ============================================================================

USE elecciones_unp;

-- Desactivar verificación de llaves foráneas para reiniciar limpiamente la tabla
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE departamento;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. ASEGURAR LAS 14 FACULTADES
INSERT IGNORE INTO facultad (nombre) VALUES 
('Facultad de Ciencias Administrativas'),
('Facultad de Agronomía'),
('Facultad de Ciencias Contables y Financieras'),
('Facultad de Economía'),
('Facultad de Ingeniería Industrial'),
('Facultad de Ingeniería Pesquera'),
('Facultad de Ingeniería de Minas'),
('Facultad de Zootecnia'),
('Facultad de Ciencias de la Salud'),
('Facultad de Ciencias'),
('Facultad de Ciencias Sociales y Educación'),
('Facultad de Derecho y Ciencias Políticas'),
('Facultad de Ingeniería Civil'),
('Facultad de Arquitectura y Urbanismo');

-- 2. INSERTAR EXACTAMENTE LOS 44 DEPARTAMENTOS ACADÉMICOS

-- Facultad de Ciencias Administrativas (2 departamentos)
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Administrativas'), 'Administración General'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Administrativas'), 'Administración Aplicada');

-- Facultad de Agronomía (5 departamentos)
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Agronomía'), 'Agronomía y Fitotécnia'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Agronomía'), 'Ingeniería Agrícola'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Agronomía'), 'Sanidad Vegetal'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Agronomía'), 'Suelos'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Agronomía'), 'Morfofisiología Vegetal');

-- Facultad de Ciencias Contables y Financieras (3 departamentos)
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Contables y Financieras'), 'Contabilidad General'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Contables y Financieras'), 'Contabilidad Aplicada'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Contables y Financieras'), 'Finanzas, Tributación y Auditoría');

-- Facultad de Economía (1 departamento)
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Economía'), 'Economía');

-- Facultad de Ingeniería Industrial (5 departamentos)
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería Industrial'), 'Ingeniería Industrial'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería Industrial'), 'Ingeniería Informática'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería Industrial'), 'Agroindustria e Industrias Alimentarias'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería Industrial'), 'Investigación de Operaciones'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería Industrial'), 'Ingeniería Mecatrónica');

-- Facultad de Ingeniería Pesquera (1 departamento)
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería Pesquera'), 'Ingeniería Pesquera');

-- Facultad de Ingeniería de Minas (5 departamentos)
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería de Minas'), 'Ingeniería de Minas'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería de Minas'), 'Ingeniería de Petróleo'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería de Minas'), 'Ingeniería Geológica'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería de Minas'), 'Ingeniería Química'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería de Minas'), 'Ingeniería Ambiental y Seguridad Industrial');

-- Facultad de Zootecnia (2 departamentos)
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Zootecnia'), 'Producción Animal'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Zootecnia'), 'Salud Animal');

-- Facultad de Ciencias de la Salud (6 departamentos)
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias de la Salud'), 'Materno Infantil'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias de la Salud'), 'Morfofisiología Humana'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias de la Salud'), 'Clínico Quirúrgico'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias de la Salud'), 'Salud Pública'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias de la Salud'), 'Enfermería Materno Perinatal'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias de la Salud'), 'Enfermería del Adulto');

-- Facultad de Ciencias (5 departamentos)
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias'), 'Matemática'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias'), 'Física'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias'), 'Estadística'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias'), 'Ciencias Biológicas'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias'), 'Ingeniería Electrónica y Telecomunicaciones');

-- Facultad de Ciencias Sociales y Educación (3 departamentos)
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Sociales y Educación'), 'Educación'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Sociales y Educación'), 'Ciencias Sociales'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Sociales y Educación'), 'Ciencias de la Comunicación');

-- Facultad de Derecho y Ciencias Políticas (2 departamentos)
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Derecho y Ciencias Políticas'), 'Derecho'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Derecho y Ciencias Políticas'), 'Ciencias Políticas');

-- Facultad de Ingeniería Civil (2 departamentos)
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería Civil'), 'Ingeniería Civil'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería Civil'), 'Ingeniería Sanitaria y Medio Ambiente');

-- Facultad de Arquitectura y Urbanismo (2 departamentos)
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Arquitectura y Urbanismo'), 'Arquitectura'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Arquitectura y Urbanismo'), 'Urbanismo');

-- Fin del script: exactamente 44 departamentos
