-- ==============================================================================
-- FERIA SEGURA HUAMANGA (FeriaSegura)
-- Migración 009: Row Level Security (RLS) Completo
-- Tareas Jira: FSH-23, FSH-24, FSH-27, FSH-36
-- Descripción: Habilita y define políticas RLS sobre tablas sensibles para
--              garantizar aislamiento estricto de datos por usuario autenticado.
--              Complementa el sistema RBAC y ACL de la migración 002.
-- ==============================================================================

-- ──────────────────────────────────────────────────────────────────────────────
-- FUNCIÓN AUXILIAR: Extraer el UUID del usuario actual de la sesión
-- La aplicación NestJS debe inyectar: SET LOCAL app.current_user_id = '<uuid>'
-- ──────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION auth_acl.fn_get_current_user_id()
RETURNS UUID
LANGUAGE plpgsql
STABLE SECURITY DEFINER
AS $$
BEGIN
    RETURN NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$;

COMMENT ON FUNCTION auth_acl.fn_get_current_user_id() IS
    'Extrae el UUID del usuario activo desde la variable de sesión app.current_user_id. '
    'Debe ser inyectada por el backend NestJS en cada transacción autenticada.';

-- ──────────────────────────────────────────────────────────────────────────────
-- FUNCIÓN AUXILIAR: Verificar si el usuario actual es FUNCIONARIO INTERNO
-- ──────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION auth_acl.fn_is_funcionario_interno()
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM auth_acl.funcionario_perfil
        WHERE id_funcionario = auth_acl.fn_get_current_user_id()
    );
END;
$$;

-- ──────────────────────────────────────────────────────────────────────────────
-- FUNCIÓN AUXILIAR: Verificar si el usuario actual tiene un área municipal específica
-- ──────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION auth_acl.fn_has_area(p_area VARCHAR)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM auth_acl.funcionario_perfil
        WHERE id_funcionario = auth_acl.fn_get_current_user_id()
          AND area_municipal = p_area
    );
END;
$$;

-- ──────────────────────────────────────────────────────────────────────────────
-- FUNCIÓN AUXILIAR: Verificar si el usuario actual tiene un permiso específico
-- ──────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION auth_acl.fn_has_permiso(p_codigo VARCHAR)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM auth_acl.usuario_roles ur
        JOIN auth_acl.rol_permisos rp ON rp.id_rol = ur.id_rol
        JOIN auth_acl.permisos pe ON pe.id_permiso = rp.id_permiso
        WHERE ur.id_usuario = auth_acl.fn_get_current_user_id()
          AND pe.codigo_permiso = p_codigo
    );
END;
$$;

-- ==============================================================================
-- SECCIÓN 1: RLS en tablas del esquema auth_acl
-- ==============================================================================

-- 1.1 Tabla: auth_acl.comerciante_perfil
-- Ya habilitada en roles_and_grants.sql, se redefine aquí como fuente autoritativa
ALTER TABLE auth_acl.comerciante_perfil ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS p_rls_comerciante_perfil ON auth_acl.comerciante_perfil;
CREATE POLICY p_rls_comerciante_perfil ON auth_acl.comerciante_perfil
    AS PERMISSIVE
    FOR ALL
    TO app_feriasegura_role
    USING (
        -- Funcionarios con área de administración ven todos los perfiles
        auth_acl.fn_has_area('ADMINISTRACION')
        OR
        -- Tesorería y Defensa Civil pueden ver perfiles de comerciantes
        auth_acl.fn_is_funcionario_interno()
        OR
        -- El comerciante solo ve y modifica su propio perfil
        id_comerciante = auth_acl.fn_get_current_user_id()
    )
    WITH CHECK (
        -- Solo el propio comerciante puede modificar su registro
        id_comerciante = auth_acl.fn_get_current_user_id()
        OR
        -- Administración puede modificar cualquier perfil (gestión censal)
        auth_acl.fn_has_area('ADMINISTRACION')
    );

COMMENT ON POLICY p_rls_comerciante_perfil ON auth_acl.comerciante_perfil IS
    'Aislamiento por propietario: comerciante ve solo su propio perfil. '
    'Funcionarios internos tienen visibilidad de lectura completa. '
    'Solo administración puede modificar perfiles de terceros.';

-- 1.2 Tabla: auth_acl.sesion_tokens  
-- Solo el propio usuario puede ver sus tokens (gestión de sesión)
ALTER TABLE auth_acl.sesion_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS p_rls_sesion_tokens ON auth_acl.sesion_tokens;
CREATE POLICY p_rls_sesion_tokens ON auth_acl.sesion_tokens
    AS PERMISSIVE
    FOR ALL
    TO app_feriasegura_role
    USING (
        id_usuario = auth_acl.fn_get_current_user_id()
        OR
        auth_acl.fn_has_area('ADMINISTRACION')
    )
    WITH CHECK (
        id_usuario = auth_acl.fn_get_current_user_id()
    );

-- ==============================================================================
-- SECCIÓN 2: RLS en tablas del esquema feria_core
-- ==============================================================================

-- 2.1 Tabla: feria_core.postulaciones_reservas
-- El comerciante solo ve sus reservas. Funcionarios ven todas.
ALTER TABLE feria_core.postulaciones_reservas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS p_rls_reservas_lectura ON feria_core.postulaciones_reservas;
CREATE POLICY p_rls_reservas_lectura ON feria_core.postulaciones_reservas
    AS PERMISSIVE
    FOR SELECT
    TO app_feriasegura_role
    USING (
        auth_acl.fn_is_funcionario_interno()
        OR
        id_comerciante = auth_acl.fn_get_current_user_id()
    );

DROP POLICY IF EXISTS p_rls_reservas_insercion ON feria_core.postulaciones_reservas;
CREATE POLICY p_rls_reservas_insercion ON feria_core.postulaciones_reservas
    AS PERMISSIVE
    FOR INSERT
    TO app_feriasegura_role
    WITH CHECK (
        -- El comerciante solo puede crear reservas a su propio nombre
        id_comerciante = auth_acl.fn_get_current_user_id()
    );

DROP POLICY IF EXISTS p_rls_reservas_actualizacion ON feria_core.postulaciones_reservas;
CREATE POLICY p_rls_reservas_actualizacion ON feria_core.postulaciones_reservas
    AS PERMISSIVE
    FOR UPDATE
    TO app_feriasegura_role
    USING (
        -- Solo funcionarios pueden cambiar el estado de una reserva
        auth_acl.fn_is_funcionario_interno()
    );

-- 2.2 Tabla: feria_core.pagos_tupa (Vouchers - alta confidencialidad)
ALTER TABLE feria_core.pagos_tupa ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS p_rls_pagos_tupa ON feria_core.pagos_tupa;
CREATE POLICY p_rls_pagos_tupa ON feria_core.pagos_tupa
    AS PERMISSIVE
    FOR ALL
    TO app_feriasegura_role
    USING (
        -- Tesorería y Administración pueden ver todos los comprobantes
        auth_acl.fn_has_area('TESORERIA')
        OR auth_acl.fn_has_area('ADMINISTRACION')
        OR
        -- El comerciante solo ve sus propios comprobantes
        EXISTS (
            SELECT 1 FROM feria_core.postulaciones_reservas r
            WHERE r.id_reserva = pagos_tupa.id_reserva
              AND r.id_comerciante = auth_acl.fn_get_current_user_id()
        )
    )
    WITH CHECK (
        -- Solo el propio comerciante puede subir su comprobante
        EXISTS (
            SELECT 1 FROM feria_core.postulaciones_reservas r
            WHERE r.id_reserva = pagos_tupa.id_reserva
              AND r.id_comerciante = auth_acl.fn_get_current_user_id()
        )
    );

-- 2.3 Tabla: feria_core.declaraciones_electricas
-- Comerciante declara solo sus propios artefactos. Defensa Civil monitorea todos.
ALTER TABLE feria_core.declaraciones_electricas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS p_rls_declaraciones_electricas ON feria_core.declaraciones_electricas;
CREATE POLICY p_rls_declaraciones_electricas ON feria_core.declaraciones_electricas
    AS PERMISSIVE
    FOR ALL
    TO app_feriasegura_role
    USING (
        -- Defensa Civil y Administración pueden ver todas las declaraciones
        auth_acl.fn_has_area('DEFENSA_CIVIL')
        OR auth_acl.fn_has_area('ADMINISTRACION')
        OR
        -- El comerciante solo ve y modifica su propia declaración
        EXISTS (
            SELECT 1 FROM feria_core.postulaciones_reservas r
            WHERE r.id_reserva = declaraciones_electricas.id_reserva
              AND r.id_comerciante = auth_acl.fn_get_current_user_id()
        )
    )
    WITH CHECK (
        -- Solo el comerciante propietario puede crear/modificar su declaración
        EXISTS (
            SELECT 1 FROM feria_core.postulaciones_reservas r
            WHERE r.id_reserva = declaraciones_electricas.id_reserva
              AND r.id_comerciante = auth_acl.fn_get_current_user_id()
        )
    );

-- 2.4 Tabla: feria_core.actas_infraccion
-- Los fiscalizadores acceden a todas. El comerciante solo ve sus propias actas.
ALTER TABLE feria_core.actas_infraccion ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS p_rls_actas_infraccion ON feria_core.actas_infraccion;
CREATE POLICY p_rls_actas_infraccion ON feria_core.actas_infraccion
    AS PERMISSIVE
    FOR ALL
    TO app_feriasegura_role
    USING (
        auth_acl.fn_is_funcionario_interno()
        OR
        id_comerciante = auth_acl.fn_get_current_user_id()
    )
    WITH CHECK (
        -- Solo fiscalizadores pueden levantar actas
        auth_acl.fn_has_area('FISCALIZACION')
    );

-- ==============================================================================
-- SECCIÓN 3: RLS en tabla de auditoría (solo lectura para privilegiados)
-- ==============================================================================
ALTER TABLE audit.audit_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS p_rls_audit_log ON audit.audit_log;
CREATE POLICY p_rls_audit_log ON audit.audit_log
    AS PERMISSIVE
    FOR SELECT
    TO app_feriasegura_role
    USING (
        -- Solo administración puede consultar la bitácora completa
        auth_acl.fn_has_area('ADMINISTRACION')
        OR
        -- Cada usuario puede ver eventos que lo involucran directamente
        id_usuario_responsable = auth_acl.fn_get_current_user_id()
    );

-- ==============================================================================
-- SECCIÓN 4: Índices de soporte para las funciones RLS (evitar Seq Scan en RLS)
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_rls_funcionario_id
    ON auth_acl.funcionario_perfil (id_funcionario, area_municipal);

CREATE INDEX IF NOT EXISTS idx_rls_reservas_comerciante_id
    ON feria_core.postulaciones_reservas (id_comerciante, id_reserva);

CREATE INDEX IF NOT EXISTS idx_rls_sesion_tokens_usuario
    ON auth_acl.sesion_tokens (id_usuario);

COMMENT ON INDEX idx_rls_funcionario_id IS
    'Índice de soporte para evaluar políticas RLS que consultan área_municipal del funcionario activo';
COMMENT ON INDEX idx_rls_reservas_comerciante_id IS
    'Índice de soporte para evaluar políticas RLS sobre pagos_tupa y declaraciones_electricas';
