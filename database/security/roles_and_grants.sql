-- ==============================================================================
-- FERIA SEGURA HUAMANGA (FeriaSegura)
-- Roles, Permisos y Políticas de Menor Privilegio
-- Seguridad: Autenticación, RLS y Auditoría WORM
-- ==============================================================================

-- 1. Crear el Rol de Conexión de la Aplicación (NO SUPERUSUARIO)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_feriasegura_role') THEN
        CREATE ROLE app_feriasegura_role WITH LOGIN PASSWORD 'app_secure_password_huamanga' NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT;
    END IF;
END $$;

-- 2. Conceder uso estricto sobre esquemas
GRANT USAGE ON SCHEMA auth_acl TO app_feriasegura_role;
GRANT USAGE ON SCHEMA feria_core TO app_feriasegura_role;
GRANT USAGE ON SCHEMA audit TO app_feriasegura_role;

-- 3. Conceder permisos DML de negocio en tablas operativas
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA auth_acl TO app_feriasegura_role;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA feria_core TO app_feriasegura_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA auth_acl TO app_feriasegura_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA feria_core TO app_feriasegura_role;

-- 4. SEGURIDAD DE AUDITORÍA WORM (FSH-31)
-- La aplicación solo puede INSERTAR y LEER la bitácora.
-- Se REVOCA expresamente UPDATE, DELETE y TRUNCATE para impedir adulteración de trazas.
REVOKE UPDATE, DELETE, TRUNCATE ON audit.audit_log FROM app_feriasegura_role;
GRANT INSERT, SELECT ON audit.audit_log TO app_feriasegura_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA audit TO app_feriasegura_role;

-- 5. HABILITAR ROW LEVEL SECURITY (RLS) EN TABLAS PRIVADAS DEL COMERCIANTE
-- Aislamiento de datos: Comprobantes de pago y declaraciones eléctricas
ALTER TABLE feria_core.pagos_tupa ENABLE ROW LEVEL SECURITY;
ALTER TABLE feria_core.declaraciones_electricas ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth_acl.comerciante_perfil ENABLE ROW LEVEL SECURITY;

-- 5.1 Política RLS en Comerciante Perfil
DROP POLICY IF EXISTS p_comerciante_perfil_isolation ON auth_acl.comerciante_perfil;
CREATE POLICY p_comerciante_perfil_isolation ON auth_acl.comerciante_perfil
FOR ALL
TO app_feriasegura_role
USING (
    -- Funcionarios internos tienen visibilidad de gestión
    EXISTS (
        SELECT 1 FROM auth_acl.funcionario_perfil fp
        WHERE fp.id_funcionario = NULLIF(current_setting('app.current_user_id', true), '')::UUID
    )
    OR
    -- El comerciante solo ve su propio registro
    id_comerciante = NULLIF(current_setting('app.current_user_id', true), '')::UUID
)
WITH CHECK (
    id_comerciante = NULLIF(current_setting('app.current_user_id', true), '')::UUID
);

-- 5.2 Política RLS en Pagos TUPA (Vouchers privados)
DROP POLICY IF EXISTS p_pagos_tupa_isolation ON feria_core.pagos_tupa;
CREATE POLICY p_pagos_tupa_isolation ON feria_core.pagos_tupa
FOR ALL
TO app_feriasegura_role
USING (
    -- Tesorería y administradores pueden revisar los pagos de todas las solicitudes
    EXISTS (
        SELECT 1 FROM auth_acl.funcionario_perfil fp
        WHERE fp.id_funcionario = NULLIF(current_setting('app.current_user_id', true), '')::UUID
          AND fp.area_municipal IN ('TESORERIA', 'ADMINISTRACION')
    )
    OR
    -- El comerciante solo accede a los comprobantes de sus propias reservas
    EXISTS (
        SELECT 1 FROM feria_core.postulaciones_reservas r
        WHERE r.id_reserva = pagos_tupa.id_reserva
          AND r.id_comerciante = NULLIF(current_setting('app.current_user_id', true), '')::UUID
    )
);
