-- ==============================================================================
-- FERIA SEGURA HUAMANGA (FeriaSegura)
-- Migración 005: Funciones y Triggers del Negocio
-- Tareas Jira: FSH-4, FSH-13, FSH-16, FSH-29, FSH-30, FSH-31, FSH-37
-- ==============================================================================

-- 1. Función Trigger: Validación y Control Estricto de Potencia por Sector (FSH-30, FSH-16)
CREATE OR REPLACE FUNCTION feria_core.fn_validar_potencia_acumulada_sector()
RETURNS TRIGGER AS $$
DECLARE
    v_id_sector UUID;
    v_capacidad_maxima NUMERIC(6, 2);
    v_potencia_total_sector NUMERIC(6, 3);
    v_declaracion_id UUID;
BEGIN
    v_declaracion_id := COALESCE(NEW.id_declaracion, OLD.id_declaracion);

    -- 1.1 Localizar el sector correspondiente con bloqueo pesimista (FOR UPDATE)
    -- Esto serializa cualquier intento concurrente de agregar artefactos en el mismo sector
    SELECT s.id_sector, s.capacidad_kw_maxima
    INTO v_id_sector, v_capacidad_maxima
    FROM feria_core.declaraciones_electricas d
    JOIN feria_core.postulaciones_reservas r ON r.id_reserva = d.id_reserva
    JOIN feria_core.puestos p ON p.id_puesto = r.id_puesto
    JOIN feria_core.sectores s ON s.id_sector = p.id_sector
    WHERE d.id_declaracion = v_declaracion_id
    FOR UPDATE OF s;

    IF v_id_sector IS NULL THEN
        IF TG_OP = 'DELETE' THEN
            RETURN OLD;
        END IF;
        RAISE EXCEPTION 'DATOS_INCONSISTENTES: No se pudo identificar el sector asociado a la declaración eléctrica %', v_declaracion_id
            USING ERRCODE = 'data_exception';
    END IF;

    -- 1.2 Calcular la suma total acumulada de potencia en todos los puestos del sector
    -- Excluyendo el registro actual en modificación si es UPDATE o DELETE
    SELECT COALESCE(SUM(da.cantidad * da.potencia_unitaria_kw), 0.000)
    INTO v_potencia_total_sector
    FROM feria_core.detalles_artefactos da
    JOIN feria_core.declaraciones_electricas de ON de.id_declaracion = da.id_declaracion
    JOIN feria_core.postulaciones_reservas pr ON pr.id_reserva = de.id_reserva
    JOIN feria_core.puestos pu ON pu.id_puesto = pr.id_puesto
    WHERE pu.id_sector = v_id_sector
      AND pr.estado_reserva IN ('RESERVADA', 'EN_EVALUACION_PAGO', 'FORMALIZADA')
      AND da.id_detalle <> COALESCE(NEW.id_detalle, -1);

    -- 1.3 Sumar la nueva potencia que se intenta ingresar o actualizar
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        v_potencia_total_sector := v_potencia_total_sector + (NEW.cantidad * NEW.potencia_unitaria_kw);
    END IF;

    -- 1.4 Validar si excede la capacidad autorizada por Defensa Civil
    IF v_potencia_total_sector > v_capacidad_maxima THEN
        RAISE EXCEPTION 'SOBRECARGA_ELECTRICA_SECTOR: La potencia acumulada (%.3f kW) supera la capacidad máxima autorizada de %.2f kW fijada por Defensa Civil para este sector.',
            v_potencia_total_sector, v_capacidad_maxima
            USING ERRCODE = 'check_violation';
    END IF;

    -- 1.5 Si no supera la capacidad, actualizar la potencia calculada en el sector y estado de bloqueo
    UPDATE feria_core.sectores
    SET potencia_actual_calculada_kw = ROUND(v_potencia_total_sector, 2),
        suministro_electrico_bloqueado = (v_potencia_total_sector >= v_capacidad_maxima)
    WHERE id_sector = v_id_sector;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_control_potencia_sector ON feria_core.detalles_artefactos;
CREATE TRIGGER trg_control_potencia_sector
BEFORE INSERT OR UPDATE OR DELETE ON feria_core.detalles_artefactos
FOR EACH ROW
EXECUTE FUNCTION feria_core.fn_validar_potencia_acumulada_sector();

-- 2. Función Trigger: Actualización de la Suma de Potencia en la Declaración Individual
CREATE OR REPLACE FUNCTION feria_core.fn_actualizar_potencia_declaracion()
RETURNS TRIGGER AS $$
DECLARE
    v_declaracion_id UUID;
    v_total_kw NUMERIC(6, 3);
BEGIN
    v_declaracion_id := COALESCE(NEW.id_declaracion, OLD.id_declaracion);

    SELECT COALESCE(SUM(cantidad * potencia_unitaria_kw), 0.000)
    INTO v_total_kw
    FROM feria_core.detalles_artefactos
    WHERE id_declaracion = v_declaracion_id;

    UPDATE feria_core.declaraciones_electricas
    SET potencia_total_kw = v_total_kw
    WHERE id_declaracion = v_declaracion_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_actualizar_declaracion_total ON feria_core.detalles_artefactos;
CREATE TRIGGER trg_actualizar_declaracion_total
AFTER INSERT OR UPDATE OR DELETE ON feria_core.detalles_artefactos
FOR EACH ROW
EXECUTE FUNCTION feria_core.fn_actualizar_potencia_declaracion();

-- 3. Procedimiento Almacenado: Reserva Atómica de Puesto con Concurrencia Pesimista (FSH-13, FSH-29, FSH-37)
CREATE OR REPLACE FUNCTION feria_core.sp_reservar_puesto_atomico(
    p_id_comerciante UUID,
    p_id_feria UUID,
    p_id_puesto UUID,
    p_id_giro INTEGER,
    p_minutos_vigencia INTEGER DEFAULT 1440 -- 24 horas para adjuntar comprobante TUPA
)
RETURNS UUID AS $$
DECLARE
    v_estado_actual VARCHAR(20);
    v_puesto_feria_id UUID;
    v_id_reserva UUID;
BEGIN
    -- 3.1 Bloqueo pesimista sobre el puesto para serializar accesos concurrentes sobre la misma casilla
    SELECT p.estado_puesto, s.id_feria
    INTO v_estado_actual, v_puesto_feria_id
    FROM feria_core.puestos p
    JOIN feria_core.sectores s ON s.id_sector = p.id_sector
    WHERE p.id_puesto = p_id_puesto
    FOR UPDATE OF p;

    IF v_estado_actual IS NULL THEN
        RAISE EXCEPTION 'PUESTO_NO_ENCONTRADO: El puesto solicitado (%) no existe.', p_id_puesto
            USING ERRCODE = 'no_data_found';
    END IF;

    IF v_puesto_feria_id <> p_id_feria THEN
        RAISE EXCEPTION 'FERIA_INCORRECTA: El puesto no pertenece a la feria indicada.'
            USING ERRCODE = 'data_exception';
    END IF;

    -- 3.2 Verificar que el puesto se encuentre verdaderamente disponible
    IF v_estado_actual <> 'DISPONIBLE' THEN
        RAISE EXCEPTION 'PUESTO_NO_DISPONIBLE: El puesto ya no se encuentra disponible (Estado actual: %).', v_estado_actual
            USING ERRCODE = 'check_violation';
    END IF;

    -- 3.3 Registrar la nueva reserva
    -- Nota: El índice único parcial sobre (id_feria, id_comerciante) garantizará a nivel de motor
    -- que este DNI no tenga otra reserva o asignación activa en la misma feria (FSH-14, FSH-29)
    INSERT INTO feria_core.postulaciones_reservas (
        id_feria,
        id_comerciante,
        id_puesto,
        id_giro,
        fecha_reserva,
        fecha_limite_pago,
        estado_reserva
    ) VALUES (
        p_id_feria,
        p_id_comerciante,
        p_id_puesto,
        p_id_giro,
        clock_timestamp(),
        clock_timestamp() + (p_minutos_vigencia || ' minutes')::INTERVAL,
        'RESERVADA'
    ) RETURNING id_reserva INTO v_id_reserva;

    -- 3.4 Actualizar el puesto a RESERVADO e incrementar version_lock
    UPDATE feria_core.puestos
    SET estado_puesto = 'RESERVADO',
        version_lock = version_lock + 1,
        actualizado_en = clock_timestamp()
    WHERE id_puesto = p_id_puesto;

    RETURN v_id_reserva;
END;
$$ LANGUAGE plpgsql;

-- 4. Triggers de Auditoría para Eventos Críticos (FSH-31)
DROP TRIGGER IF EXISTS trg_audit_pagos_tupa ON feria_core.pagos_tupa;
CREATE TRIGGER trg_audit_pagos_tupa
AFTER UPDATE ON feria_core.pagos_tupa
FOR EACH ROW
EXECUTE FUNCTION audit.fn_auditar_eventos_criticos();

DROP TRIGGER IF EXISTS trg_audit_puestos ON feria_core.puestos;
CREATE TRIGGER trg_audit_puestos
AFTER UPDATE ON feria_core.puestos
FOR EACH ROW
EXECUTE FUNCTION audit.fn_auditar_eventos_criticos();

DROP TRIGGER IF EXISTS trg_audit_actas ON feria_core.actas_infraccion;
CREATE TRIGGER trg_audit_actas
AFTER UPDATE ON feria_core.actas_infraccion
FOR EACH ROW
EXECUTE FUNCTION audit.fn_auditar_eventos_criticos();

DROP TRIGGER IF EXISTS trg_audit_roles ON auth_acl.usuario_roles;
CREATE TRIGGER trg_audit_roles
AFTER INSERT ON auth_acl.usuario_roles
FOR EACH ROW
EXECUTE FUNCTION audit.fn_auditar_eventos_criticos();
