-- ==============================================================================
-- FERIA SEGURA HUAMANGA (FeriaSegura)
-- Migración 001: Extensiones y Esquemas
-- Descripción: Creación de extensiones criptográficas y esquemas del sistema.
-- ==============================================================================

-- 1. Extensiones necesarias para UUIDs y funciones criptográficas seguras
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Esquemas independientes para aislamiento de dominios
CREATE SCHEMA IF NOT EXISTS auth_acl;
CREATE SCHEMA IF NOT EXISTS feria_core;
CREATE SCHEMA IF NOT EXISTS audit;

COMMENT ON SCHEMA auth_acl IS 'Autenticación centralizada, perfiles, roles, permisos y listas de control de acceso (ACL)';
COMMENT ON SCHEMA feria_core IS 'Dominio central ferial: catastro, puestos, reservas, control eléctrico, pagos TUPA y fiscalización';
COMMENT ON SCHEMA audit IS 'Bitácora inmutable de auditoría para trazabilidad de eventos críticos';
