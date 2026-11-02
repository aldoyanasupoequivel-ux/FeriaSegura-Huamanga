-- ==============================================================================
-- FERIA SEGURA HUAMANGA (FeriaSegura)
-- Migración 004: Sistema de Auditoría Inmutable
-- Tareas Jira: FSH-31 (Bitácora de auditoría inmutable mediante triggers)
-- ==============================================================================

-- 1. Tabla Central de Auditoría
CREATE TABLE IF NOT EXISTS audit.audit_log (
    id_audit BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fecha_hora TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    id_usuario_responsable UUID NULL,
    ip_cliente INET NULL,
    esquema VARCHAR(63) NOT NULL,
    tabla VARCHAR(63) NOT NULL,
    id_registro_afectado TEXT NOT NULL,
    tipo_operacion VARCHAR(30) NOT NULL,
    datos_anteriores JSONB NULL,
    datos_nuevos JSONB NULL,
    descripcion_evento TEXT NULL,
    CONSTRAINT fk_audit_usuario FOREIGN KEY (id_usuario_responsable) 
        REFERENCES auth_acl.usuarios(id_usuario) ON DELETE SET NULL,
    CONSTRAINT chk_audit_operacion CHECK (tipo_operacion IN (
        'INSERT', 'UPDATE', 'DELETE', 
        'APROBACION_PAGO', 'REASIGNACION_PUESTO', 'ANULACION_INFRACCION', 'ASIGNACION_ROL'
    ))
);

COMMENT ON TABLE audit.audit_log IS 'Bitácora inmutable de eventos críticos (FSH-31). Modelo WORM.';

-- 2. Función Trigger para Bloquear Modificaciones y Eliminaciones (Garantía WORM)
CREATE OR REPLACE FUNCTION audit.fn_proteger_inmutabilidad_audit_log()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'OPERACION_PROHIBIDA: La bitácora de auditoría es inmutable (WORM). No se permite modificar (UPDATE) ni eliminar (DELETE) registros existentes.'
        USING ERRCODE = 'insufficient_privilege';
END;
$$ LANGUAGE plpgsql;

-- 3. Disparador de Inmutabilidad
DROP TRIGGER IF EXISTS trg_audit_log_inmutable ON audit.audit_log;
CREATE TRIGGER trg_audit_log_inmutable
BEFORE UPDATE OR DELETE ON audit.audit_log
FOR EACH ROW
EXECUTE FUNCTION audit.fn_proteger_inmutabilidad_audit_log();

-- 4. Función Genérica para Registrar Eventos Críticos desde Triggers
CREATE OR REPLACE FUNCTION audit.fn_auditar_eventos_criticos()
RETURNS TRIGGER AS $$
DECLARE
    v_usuario_id UUID;
    v_ip_cliente INET;
    v_tipo_evento VARCHAR(30);
    v_id_registro TEXT;
    v_desc TEXT;
BEGIN
    -- Extraer usuario e IP de la sesión de PostgreSQL inyectadas por la app
    BEGIN
        v_usuario_id := NULLIF(current_setting('app.current_user_id', true), '')::UUID;
    EXCEPTION WHEN OTHERS THEN
        v_usuario_id := NULL;
    END;

    BEGIN
        v_ip_cliente := NULLIF(current_setting('app.current_client_ip', true), '')::INET;
    EXCEPTION WHEN OTHERS THEN
        v_ip_cliente := NULL;
    END;

    v_tipo_evento := TG_OP;
    v_desc := NULL;

    -- Clasificación específica de eventos críticos descritos en FSH-31
    IF TG_TABLE_NAME = 'pagos_tupa' THEN
        v_id_registro := COALESCE(NEW.id_pago, OLD.id_pago)::TEXT;
        IF TG_OP = 'UPDATE' AND NEW.estado_pago = 'VALIDADO' AND OLD.estado_pago <> 'VALIDADO' THEN
            v_tipo_evento := 'APROBACION_PAGO';
            v_desc := 'Aprobación de solicitud y formalización de pago TUPA por Tesorería';
        END IF;

    ELSIF TG_TABLE_NAME = 'puestos' THEN
        v_id_registro := COALESCE(NEW.id_puesto, OLD.id_puesto)::TEXT;
        IF TG_OP = 'UPDATE' AND NEW.estado_puesto <> OLD.estado_puesto THEN
            v_tipo_evento := 'REASIGNACION_PUESTO';
            v_desc := format('Cambio de estado de puesto de [%s] a [%s]', OLD.estado_puesto, NEW.estado_puesto);
        END IF;

    ELSIF TG_TABLE_NAME = 'actas_infraccion' THEN
        v_id_registro := COALESCE(NEW.id_acta, OLD.id_acta)::TEXT;
        IF TG_OP = 'UPDATE' AND NEW.estado_acta = 'ANULADA' AND OLD.estado_acta <> 'ANULADA' THEN
            v_tipo_evento := 'ANULACION_INFRACCION';
            v_desc := format('Anulación de acta de infracción por funcionario: %s', COALESCE(NEW.motivo_anulacion, 'Sin motivo especificado'));
        END IF;

    ELSIF TG_TABLE_NAME = 'usuario_roles' THEN
        v_id_registro := format('%s:%s', COALESCE(NEW.id_usuario, OLD.id_usuario), COALESCE(NEW.id_rol, OLD.id_rol));
        IF TG_OP = 'INSERT' THEN
            v_tipo_evento := 'ASIGNACION_ROL';
            v_desc := 'Asignación de nuevo rol a usuario interno';
        END IF;
    ELSE
        v_id_registro := 'DESCONOCIDO';
    END IF;

    -- Inserción inmutable en la bitácora
    INSERT INTO audit.audit_log (
        id_usuario_responsable,
        ip_cliente,
        esquema,
        tabla,
        id_registro_afectado,
        tipo_operacion,
        datos_anteriores,
        datos_nuevos,
        descripcion_evento
    ) VALUES (
        v_usuario_id,
        v_ip_cliente,
        TG_TABLE_SCHEMA,
        TG_TABLE_NAME,
        v_id_registro,
        v_tipo_evento,
        CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) ELSE NULL END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) ELSE NULL END,
        v_desc
    );

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;
