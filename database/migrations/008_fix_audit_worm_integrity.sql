-- ==============================================================================
-- FERIA SEGURA HUAMANGA (FeriaSegura)
-- Migración 008: Corrección de Auditoría WORM y Aislamiento de Integridad
-- Descripción: Elimina la acción ON DELETE SET NULL de la FK fk_audit_usuario
--              que entraba en conflicto con el trigger de inmutabilidad WORM.
-- ==============================================================================

-- 1. Eliminar la restricción previa con ON DELETE SET NULL
ALTER TABLE audit.audit_log 
    DROP CONSTRAINT IF EXISTS fk_audit_usuario;

-- 2. Establecer la clave foránea como ON DELETE RESTRICT (o NO ACTION)
-- De esta forma, los registros históricos de auditoría no pueden ser alterados silenciosamente
-- por eventos de cascada sobre la tabla auth_acl.usuarios, preservando la inmutabilidad física.
ALTER TABLE audit.audit_log 
    ADD CONSTRAINT fk_audit_usuario 
    FOREIGN KEY (id_usuario_responsable) 
    REFERENCES auth_acl.usuarios(id_usuario) 
    ON DELETE RESTRICT;

COMMENT ON CONSTRAINT fk_audit_usuario ON audit.audit_log IS 
    'Garantiza que un usuario con eventos auditados no sea eliminado en cascada, protegiendo la inmutabilidad WORM.';
