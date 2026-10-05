-- ==========================================================
-- SCRIPT DE BASE DE DATOS: SISTEMA DE ELECCIONES UNP
-- Motor: PostgreSQL | Alineado con RCU N° 0462-CU-2019
-- ==========================================================

-- ==========================================
-- MÓDULO: PADRÓN Y UNIVERSIDAD
-- ==========================================

CREATE TABLE facultad (
    id_facultad SERIAL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL
);

CREATE TABLE departamento (
    id_departamento SERIAL PRIMARY KEY,
    id_facultad INT NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    FOREIGN KEY (id_facultad) REFERENCES facultad(id_facultad)
);

CREATE TABLE docente (
    id_docente SERIAL PRIMARY KEY,
    dni VARCHAR(8) UNIQUE NOT NULL,
    nombres VARCHAR(255) NOT NULL,
    apellidos VARCHAR(255) NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    dedicacion VARCHAR(50) NOT NULL,
    estado VARCHAR(50) NOT NULL DEFAULT 'ACTIVO',
    id_facultad INT NOT NULL,
    id_departamento INT NOT NULL,
    FOREIGN KEY (id_facultad) REFERENCES facultad(id_facultad),
    FOREIGN KEY (id_departamento) REFERENCES departamento(id_departamento)
);

CREATE TABLE cargo_admin (
    id_cargo_admin SERIAL PRIMARY KEY,
    id_docente INT NOT NULL,
    nombre_cargo VARCHAR(255) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    vigente BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (id_docente) REFERENCES docente(id_docente)
);

CREATE TABLE cargo_excluido_sorteo (
    id_cargo_excluido SERIAL PRIMARY KEY,
    nombre_cargo VARCHAR(255) NOT NULL,
    nivel VARCHAR(50) NOT NULL
);

-- ==========================================
-- MÓDULO: PROCESO ELECTORAL
-- ==========================================

CREATE TABLE proceso_electoral (
    id_proceso SERIAL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    fecha_inicio TIMESTAMP NOT NULL,
    fecha_fin TIMESTAMP NOT NULL,
    estado VARCHAR(50) NOT NULL DEFAULT 'CREADO',
    tipo VARCHAR(50) NOT NULL DEFAULT 'PRIMERA_VUELTA',
    id_proceso_padre INT,
    quorum_minimo DECIMAL(5,2) NOT NULL DEFAULT 60.00,
    FOREIGN KEY (id_proceso_padre) REFERENCES proceso_electoral(id_proceso)
);

CREATE TABLE cargo_electoral (
    id_cargo SERIAL PRIMARY KEY,
    id_proceso INT NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    nivel_jurisdiccion VARCHAR(50) NOT NULL,
    id_jurisdiccion INT,
    categorias_permitidas VARCHAR(255) NOT NULL,
    FOREIGN KEY (id_proceso) REFERENCES proceso_electoral(id_proceso)
);

-- Lista o Fórmula (Ej: un candidato a Rector + 2 Vicerrectores)
CREATE TABLE lista_electoral (
    id_lista SERIAL PRIMARY KEY,
    id_cargo INT NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    simbolo VARCHAR(255),
    orden_cedula INT,
    estado VARCHAR(50) NOT NULL DEFAULT 'INSCRITA',
    fecha_inscripcion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_cargo) REFERENCES cargo_electoral(id_cargo)
);

-- Candidatos individuales dentro de una lista
CREATE TABLE candidato (
    id_candidato SERIAL PRIMARY KEY,
    id_lista INT NOT NULL,
    id_docente INT NOT NULL,
    rol_en_lista VARCHAR(100) NOT NULL,
    estado_validacion VARCHAR(50) DEFAULT 'PENDIENTE',
    fecha_inscripcion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_lista) REFERENCES lista_electoral(id_lista),
    FOREIGN KEY (id_docente) REFERENCES docente(id_docente)
);

-- Tachas (Cuestionamientos escritos antes de la elección)
CREATE TABLE tacha (
    id_tacha SERIAL PRIMARY KEY,
    id_docente_denunciante INT NOT NULL,
    id_candidato INT NOT NULL,
    motivo TEXT NOT NULL,
    estado VARCHAR(50) NOT NULL DEFAULT 'PENDIENTE',
    fecha_presentacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_resolucion TIMESTAMP,
    FOREIGN KEY (id_docente_denunciante) REFERENCES docente(id_docente),
    FOREIGN KEY (id_candidato) REFERENCES candidato(id_candidato)
);

-- Personeros (Fiscalizadores de cada lista)
CREATE TABLE personero (
    id_personero SERIAL PRIMARY KEY,
    id_lista INT NOT NULL,
    id_docente INT NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    id_mesa INT,
    FOREIGN KEY (id_lista) REFERENCES lista_electoral(id_lista),
    FOREIGN KEY (id_docente) REFERENCES docente(id_docente)
);

-- ==========================================
-- MÓDULO: CONTROL DE VOTO Y MESAS
-- ==========================================

CREATE TABLE padron_electoral (
    id_cargo INT NOT NULL,
    id_docente INT NOT NULL,
    habilitado_para_votar BOOLEAN DEFAULT TRUE,
    ya_voto BOOLEAN DEFAULT FALSE,
    fecha_firma_digital TIMESTAMP,
    PRIMARY KEY (id_cargo, id_docente),
    FOREIGN KEY (id_cargo) REFERENCES cargo_electoral(id_cargo),
    FOREIGN KEY (id_docente) REFERENCES docente(id_docente)
);

CREATE TABLE mesa_electoral (
    id_mesa SERIAL PRIMARY KEY,
    id_proceso INT NOT NULL,
    numero_mesa VARCHAR(20) NOT NULL,
    ubicacion VARCHAR(255) NOT NULL,
    FOREIGN KEY (id_proceso) REFERENCES proceso_electoral(id_proceso)
);

-- FK diferida del personero (mesa se crea después)
ALTER TABLE personero ADD FOREIGN KEY (id_mesa) REFERENCES mesa_electoral(id_mesa);

CREATE TABLE miembro_mesa (
    id_mesa INT NOT NULL,
    id_docente INT NOT NULL,
    rol VARCHAR(50) NOT NULL,
    PRIMARY KEY (id_mesa, id_docente),
    FOREIGN KEY (id_mesa) REFERENCES mesa_electoral(id_mesa),
    FOREIGN KEY (id_docente) REFERENCES docente(id_docente)
);

-- Voto (Urna Virtual - 100% anónimo: sin docente, sin IP)
CREATE TABLE voto (
    id_voto SERIAL PRIMARY KEY,
    id_cargo INT NOT NULL,
    id_lista_elegida INT,
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_cargo) REFERENCES cargo_electoral(id_cargo),
    FOREIGN KEY (id_lista_elegida) REFERENCES lista_electoral(id_lista)
);

-- Actas Electorales (Instalación, Sufragio, Escrutinio)
CREATE TABLE acta_electoral (
    id_acta SERIAL PRIMARY KEY,
    id_mesa INT NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    contenido_json TEXT,
    hash_integridad VARCHAR(64) NOT NULL,
    token_qr VARCHAR(255) UNIQUE NOT NULL,
    fecha_emision TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    firmado_por VARCHAR(500),
    FOREIGN KEY (id_mesa) REFERENCES mesa_electoral(id_mesa)
);

-- ==========================================
-- MÓDULO: AUDITORÍA Y SEGURIDAD
-- ==========================================

CREATE TABLE log_auditoria (
    id_log SERIAL PRIMARY KEY,
    id_docente INT NOT NULL,
    id_cargo INT NOT NULL,
    ip_origen VARCHAR(45) NOT NULL,
    user_agent VARCHAR(500),
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accion VARCHAR(50) NOT NULL DEFAULT 'VOTO_EMITIDO',
    FOREIGN KEY (id_docente) REFERENCES docente(id_docente),
    FOREIGN KEY (id_cargo) REFERENCES cargo_electoral(id_cargo)
);

CREATE TABLE constancia_voto (
    id_constancia SERIAL PRIMARY KEY,
    id_docente INT NOT NULL,
    id_cargo INT NOT NULL,
    token_qr VARCHAR(255) UNIQUE NOT NULL,
    fecha_emision TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_docente) REFERENCES docente(id_docente),
    FOREIGN KEY (id_cargo) REFERENCES cargo_electoral(id_cargo)
);

CREATE TABLE usuario (
    id_usuario SERIAL PRIMARY KEY,
    id_docente INT,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    rol VARCHAR(50) NOT NULL,
    FOREIGN KEY (id_docente) REFERENCES docente(id_docente)
);

CREATE TABLE sesion_activa (
    id_sesion SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL,
    token VARCHAR(255) UNIQUE NOT NULL,
    fecha_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion TIMESTAMP NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
);

-- ==========================================================
-- PROCEDIMIENTOS ALMACENADOS (STORED PROCEDURES)
-- ==========================================================

-- SP principal: Emitir voto de forma transaccional y atómica
CREATE OR REPLACE FUNCTION emitir_voto_transaccional(
    p_id_cargo INT,
    p_id_docente INT,
    p_id_lista INT,
    p_ip_origen VARCHAR,
    p_user_agent VARCHAR
) RETURNS VOID AS $$
BEGIN
    -- 1. Verificar si el docente está habilitado para votar
    IF NOT EXISTS (
        SELECT 1 FROM padron_electoral
        WHERE id_cargo = p_id_cargo
        AND id_docente = p_id_docente
        AND habilitado_para_votar = TRUE
    ) THEN
        RAISE EXCEPTION 'El docente no está habilitado para votar en este cargo.';
    END IF;

    -- 2. Verificar si ya votó (Seguridad antifraude)
    IF EXISTS (
        SELECT 1 FROM padron_electoral
        WHERE id_cargo = p_id_cargo
        AND id_docente = p_id_docente
        AND ya_voto = TRUE
    ) THEN
        RAISE EXCEPTION 'El docente ya emitió su voto para este cargo.';
    END IF;

    -- 3. Marcar como que ya votó en el Padrón (Firma de asistencia)
    UPDATE padron_electoral
    SET ya_voto = TRUE, fecha_firma_digital = CURRENT_TIMESTAMP
    WHERE id_cargo = p_id_cargo AND id_docente = p_id_docente;

    -- 4. Insertar el Voto (100% anónimo: apunta a LISTA, sin docente, sin IP)
    INSERT INTO voto (id_cargo, id_lista_elegida)
    VALUES (p_id_cargo, p_id_lista);

    -- 5. Registrar auditoría (sin lista elegida: solo quién, dónde, cuándo)
    INSERT INTO log_auditoria (id_docente, id_cargo, ip_origen, user_agent, accion)
    VALUES (p_id_docente, p_id_cargo, p_ip_origen, p_user_agent, 'VOTO_EMITIDO');

    -- 6. Generar constancia de voto con token QR único
    INSERT INTO constancia_voto (id_docente, id_cargo, token_qr)
    VALUES (p_id_docente, p_id_cargo, gen_random_uuid()::VARCHAR);

END;
$$ LANGUAGE plpgsql;

-- Vista: Verificar quórum en tiempo real
CREATE OR REPLACE VIEW vista_quorum AS
SELECT
    pe.id_proceso,
    ce.id_cargo,
    ce.nombre AS cargo,
    COUNT(p.id_docente) AS total_padron,
    SUM(CASE WHEN p.ya_voto = TRUE THEN 1 ELSE 0 END) AS total_votaron,
    ROUND(
        (SUM(CASE WHEN p.ya_voto = TRUE THEN 1 ELSE 0 END)::DECIMAL / COUNT(p.id_docente)) * 100, 2
    ) AS porcentaje_participacion,
    pe.quorum_minimo
FROM padron_electoral p
JOIN cargo_electoral ce ON p.id_cargo = ce.id_cargo
JOIN proceso_electoral pe ON ce.id_proceso = pe.id_proceso
GROUP BY pe.id_proceso, ce.id_cargo, ce.nombre, pe.quorum_minimo;
