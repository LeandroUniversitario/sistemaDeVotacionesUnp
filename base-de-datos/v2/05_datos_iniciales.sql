-- =====================================================================
-- SISTEMA DE ELECCIONES DOCENTES UNP  ·  BASE DE DATOS v2
-- 05_datos_iniciales.sql  ·  Parámetros, catálogos, usuario inicial,
--                            facultades y departamentos
-- =====================================================================
USE elecciones_unp;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- Parámetros globales (editables desde la pantalla Parámetros)
-- Las tres primeras claves son las que ya usa ParametrosController.java
-- ---------------------------------------------------------------------
INSERT INTO parametro_global (clave, valor, descripcion) VALUES
  ('UIT', '5150.00', 'Unidad Impositiva Tributaria (UIT) vigente en soles. Actualizar cada año.'),
  ('MULTA_ELECTOR_OMISO_PCT', '2.5', 'Porcentaje de multa para electores omisos (% de UIT) - RN35'),
  ('MULTA_MIEMBRO_MESA_OMISO_PCT', '3.0', 'Porcentaje de multa para miembros de mesa omisos (% de UIT) - RN35'),
  ('ELECTORES_POR_MESA', '200', 'Cantidad máxima de electores por mesa de sufragio'),
  ('UBICACION_SUFRAGIO', 'Biblioteca Central', 'Lugar de sufragio por defecto - RN08')
ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion);

-- ---------------------------------------------------------------------
-- RN20: cargos que impiden ser miembro de mesa (catálogo editable por el CEUNP).
-- cargo_admin.nombre_cargo debe escribirse igual que aquí.
-- ---------------------------------------------------------------------
INSERT INTO cargo_excluido_sorteo (nombre_cargo, nivel) VALUES
  ('Rector', 'UNIVERSIDAD'),
  ('Vicerrector Académico', 'UNIVERSIDAD'),
  ('Vicerrector de Investigación', 'UNIVERSIDAD'),
  ('Secretario General', 'UNIVERSIDAD'),
  ('Director de la Escuela de Posgrado', 'UNIVERSIDAD'),
  ('Miembro del CEUNP', 'UNIVERSIDAD'),
  ('Decano', 'FACULTAD'),
  ('Director de Escuela Profesional', 'FACULTAD'),
  ('Jefe de Departamento Académico', 'DEPARTAMENTO')
ON DUPLICATE KEY UPDATE nivel = VALUES(nivel);

-- ---------------------------------------------------------------------
-- Usuario administrador inicial
--   usuario: admin      contraseña: Admin2026*
-- El hash es BCrypt (compatible con BCryptPasswordEncoder del backend).
-- CAMBIA LA CONTRASEÑA en el primer ingreso (pantalla Cuenta).
-- ---------------------------------------------------------------------
INSERT INTO usuario (id_docente, username, password_hash, rol, activo)
SELECT NULL, 'admin', '$2a$10$Gjdc.v/mPodGrFSr3ojj6Ogjfi95wczcAli81wzZbaVMitWRCnq3y', 'ADMIN', TRUE
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM usuario WHERE username = 'admin');

-- =========================================================
-- 1. INSERTAR FACULTADES EN LA UNP
-- =========================================================
INSERT INTO facultad (nombre) VALUES 
('Facultad de Agronomía'),
('Facultad de Arquitectura y Urbanismo'),
('Facultad de Ciencias'),
('Facultad de Ciencias Administrativas'),
('Facultad de Ciencias Contables y Financieras'),
('Facultad de Ciencias de la Salud'),
('Facultad de Ciencias Sociales y Educación'),
('Facultad de Derecho y Ciencias Políticas'),
('Facultad de Economía'),
('Facultad de Ingeniería Civil'),
('Facultad de Ingeniería de Minas'),
('Facultad de Ingeniería Industrial'),
('Facultad de Ingeniería Pesquera'),
('Facultad de Zootecnia');

-- =========================================================
-- 2. INSERTAR DEPARTAMENTOS VINCULADOS A CADA FACULTAD
-- =========================================================

-- Facultad de Agronomía
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Agronomía'), 'Agronomía y Fitotecnia'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Agronomía'), 'Ingeniería Agrícola'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Agronomía'), 'Sanidad Vegetal'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Agronomía'), 'Suelos'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Agronomía'), 'Morfofisiología Vegetal');

-- Facultad de Arquitectura y Urbanismo
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Arquitectura y Urbanismo'), 'Arquitectura y Urbanismo');

-- Facultad de Ciencias
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias'), 'Matemática'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias'), 'Física'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias'), 'Estadística'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias'), 'Ciencias Biológicas'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias'), 'Ingeniería Electrónica y Telecomunicaciones');

-- Facultad de Ciencias Administrativas
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Administrativas'), 'Administración General'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Administrativas'), 'Administración Aplicada');

-- Facultad de Ciencias Contables y Financieras
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Contables y Financieras'), 'Contabilidad General'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Contables y Financieras'), 'Contabilidad Aplicada'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Contables y Financieras'), 'Finanzas, Tributación y Auditoría');

-- Facultad de Ciencias de la Salud
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias de la Salud'), 'Materno Infantil'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias de la Salud'), 'Morfofisiología Humana'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias de la Salud'), 'Clínico Quirúrgico'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias de la Salud'), 'Salud Pública'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias de la Salud'), 'Enfermería');

-- Facultad de Ciencias Sociales y Educación
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Sociales y Educación'), 'Educación'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Sociales y Educación'), 'Ciencias de la Comunicación'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ciencias Sociales y Educación'), 'Humanidades');

-- Facultad de Derecho y Ciencias Políticas
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Derecho y Ciencias Políticas'), 'Derecho'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Derecho y Ciencias Políticas'), 'Ciencias Políticas');

-- Facultad de Economía
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Economía'), 'Economía');

-- Facultad de Ingeniería Civil
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería Civil'), 'Ingeniería Civil');

-- Facultad de Ingeniería de Minas
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería de Minas'), 'Ingeniería de Minas'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería de Minas'), 'Ingeniería de Petróleo'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería de Minas'), 'Ingeniería Geológica'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería de Minas'), 'Ingeniería Química'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería de Minas'), 'Ingeniería Ambiental y Seguridad Industrial');

-- Facultad de Ingeniería Industrial
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería Industrial'), 'Ingeniería Industrial'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería Industrial'), 'Ingeniería Informática'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería Industrial'), 'Agroindustria e Industrias Alimentarias'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería Industrial'), 'Investigación de Operaciones'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería Industrial'), 'Ingeniería Mecatrónica');

-- Facultad de Ingeniería Pesquera
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Ingeniería Pesquera'), 'Ingeniería Pesquera');

-- Facultad de Zootecnia
INSERT INTO departamento (id_facultad, nombre) VALUES 
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Zootecnia'), 'Producción Animal'),
((SELECT id_facultad FROM facultad WHERE nombre = 'Facultad de Zootecnia'), 'Salud Animal');
