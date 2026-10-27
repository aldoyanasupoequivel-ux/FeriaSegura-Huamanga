-- ============================================================================
-- PROYECTO: FERIASEGURA HUAMANGA (FSH)
-- CURSO: CONSTRUCCIÓN Y EVOLUCIÓN DE SOFTWARE (2026-II)
-- INCIDENCIAS JIRA: FSH-7, FSH-28, FSH-36
-- DESCRIPCIÓN: Esquema Relacional de Base de Datos en PostgreSQL
-- ============================================================================

-- Eliminar tablas si existen (para reinicializaciones)
DROP TABLE IF EXISTS comerciantes CASCADE;
DROP TABLE IF EXISTS usuarios_internos CASCADE;

-- ----------------------------------------------------------------------------
-- 1. TABLA: comerciantes
-- Responsabilidad: Almacenar el padrón municipal de comerciantes ambulantes.
-- Regla de Negocio (FSH-36): DNI único de exactamente 8 dígitos numéricos.
-- ----------------------------------------------------------------------------
CREATE TABLE comerciantes (
    id SERIAL PRIMARY KEY,
    dni VARCHAR(8) NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    telefono VARCHAR(15),
    direccion VARCHAR(200),
    giro_comercial VARCHAR(100) NOT NULL,
    clave VARCHAR(255) NOT NULL,
    estado VARCHAR(20) DEFAULT 'EMPADRONADO',
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_comerciante_dni UNIQUE (dni),
    CONSTRAINT chk_comerciante_dni_longitud CHECK (LENGTH(dni) = 8 AND dni ~ '^[0-9]{8}$')
);

-- ----------------------------------------------------------------------------
-- 2. TABLA: usuarios_internos
-- Responsabilidad: Almacenar los funcionarios de la Municipalidad (FSH-22, FSH-23).
-- Roles: 'ADMINISTRADOR', 'FISCALIZADOR', 'DEFENSA_CIVIL', 'TESORERIA'.
-- ----------------------------------------------------------------------------
CREATE TABLE usuarios_internos (
    id SERIAL PRIMARY KEY,
    correo VARCHAR(120) NOT NULL,
    nombre_completo VARCHAR(150) NOT NULL,
    rol VARCHAR(30) NOT NULL,
    clave VARCHAR(255) NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_usuario_correo UNIQUE (correo),
    CONSTRAINT chk_usuario_rol CHECK (rol IN ('ADMINISTRADOR', 'FISCALIZADOR', 'DEFENSA_CIVIL', 'TESORERIA'))
);

-- ============================================================================
-- DATOS SEMILLA (SEEDS) PARA PRUEBAS Y DEMOSTRACIÓN (FSH-7)
-- ============================================================================

-- Comerciantes de prueba ya empadronados
INSERT INTO comerciantes (dni, nombres, apellidos, telefono, direccion, giro_comercial, clave, estado)
VALUES 
    ('45871234', 'Juan Carlos', 'Pérez Flores', '966123456', 'Jr. 28 de Julio 340, Huamanga', 'Artesanía y Retablos', 'comerciante123', 'EMPADRONADO'),
    ('72345678', 'María Elena', 'Quispe Alanya', '966789123', 'Av. Mariscal Cáceres 512, Huamanga', 'Gastronomía Tradicional', 'comerciante123', 'EMPADRONADO');

-- Usuarios internos de la Municipalidad Provincial de Huamanga
INSERT INTO usuarios_internos (correo, nombre_completo, rol, clave, activo)
VALUES 
    ('fiscalizador@mph.gob.pe', 'Carlos Mendoza (Serenazgo)', 'FISCALIZADOR', 'fiscalizador123', TRUE),
    ('admin@mph.gob.pe', 'Aldo Marcos (Gerencia Comercio)', 'ADMINISTRADOR', 'admin123', TRUE);
