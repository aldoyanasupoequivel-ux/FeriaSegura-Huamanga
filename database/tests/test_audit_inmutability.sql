-- ==============================================================================
-- TEST 4: Bitácora de Auditoría Inmutable (WORM) y Triggers de Eventos (FSH-31)
-- ==============================================================================
DO $$
DECLARE
    v_admin_id UUID := gen_random_uuid();
    v_feria_id UUID := gen_random_uuid();
    v_sector_id UUID := gen_random_uuid();
    v_puesto_id UUID := gen_random_uuid();
    v_audit_id BIGINT;
    v_conteo_eventos INTEGER;
BEGIN
    RAISE NOTICE '--- INICIANDO TEST: Inmutabilidad de Auditoría (WORM) y Eventos Críticos ---';

    -- 1. Insertar un registro manual en la bitácora
    INSERT INTO audit.audit_log (
        esquema, tabla, id_registro_afectado, tipo_operacion, descripcion_evento
    ) VALUES (
        'feria_core', 'puestos', 'TEST-ID', 'INSERT', 'Evento de prueba inicial'
    ) RETURNING id_audit INTO v_audit_id;

    RAISE NOTICE '[OK] Registro de auditoría creado con ID %', v_audit_id;

    -- 2. Intentar MODIFICAR (UPDATE) el registro de auditoría (Debe ser rechazado por WORM)
    BEGIN
        UPDATE audit.audit_log
        SET descripcion_evento = 'Intento de alteración no autorizada'
        WHERE id_audit = v_audit_id;

        RAISE EXCEPTION 'FALLO: Se permitió modificar un registro en la bitácora de auditoría inmutable';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE '[OK] Trigger WORM bloqueó intento de UPDATE en audit.audit_log';
    END;

    -- 3. Intentar ELIMINAR (DELETE) el registro de auditoría (Debe ser rechazado por WORM)
    BEGIN
        DELETE FROM audit.audit_log
        WHERE id_audit = v_audit_id;

        RAISE EXCEPTION 'FALLO: Se permitió eliminar un registro de la bitácora de auditoría inmutable';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE '[OK] Trigger WORM bloqueó intento de DELETE en audit.audit_log';
    END;

    -- 4. Probar disparo automático de auditoría ante un evento crítico (Reasignación de puesto)
    INSERT INTO auth_acl.usuarios (id_usuario, identificador_login, password_hash, tipo_usuario)
    VALUES (v_admin_id, 'admin_aud', 'hash', 'FUNCIONARIO_INTERNO');

    INSERT INTO feria_core.ferias (id_feria, codigo_feria, nombre_feria, descripcion, fecha_inicio, fecha_fin, ubicacion_referencia, creado_por)
    VALUES (v_feria_id, 'F-AUD-2026', 'Feria Auditoria', 'Desc', CURRENT_DATE, CURRENT_DATE + 2, 'Jr. Cusco', v_admin_id);

    INSERT INTO feria_core.sectores (id_sector, id_feria, codigo_sector, nombre_via)
    VALUES (v_sector_id, v_feria_id, 'SEC-AUD', 'Jr. Cusco Cdra 2');

    INSERT INTO feria_core.puestos (id_puesto, id_sector, codigo_puesto, ancho_metros, largo_metros, posicion_fila, posicion_columna, estado_puesto)
    VALUES (v_puesto_id, v_sector_id, 'P-AUD-01', 2.00, 2.00, 1, 1, 'DISPONIBLE');

    -- Simular inyección de variables de contexto de sesión por parte de la aplicación (FSH-31)
    PERFORM set_config('app.current_user_id', v_admin_id::TEXT, true);
    PERFORM set_config('app.current_client_ip', '192.168.1.150', true);

    -- Ejecutar evento crítico: Bloquear puesto por zona de riesgo (hidrante)
    UPDATE feria_core.puestos
    SET estado_puesto = 'BLOQUEADO',
        motivo_bloqueo = 'HIDRANTE_BOMBEROS',
        bloqueado_por = v_admin_id
    WHERE id_puesto = v_puesto_id;

    -- Verificar que el trigger haya generado el registro de auditoría correspondiente
    SELECT COUNT(*) INTO v_conteo_eventos
    FROM audit.audit_log
    WHERE tabla = 'puestos'
      AND id_registro_afectado = v_puesto_id::TEXT
      AND tipo_operacion = 'REASIGNACION_PUESTO'
      AND id_usuario_responsable = v_admin_id;

    IF v_conteo_eventos >= 1 THEN
        RAISE NOTICE '[OK] Trigger de eventos críticos auditó correctamente la reasignación del puesto con usuario e IP';
    ELSE
        RAISE EXCEPTION 'FALLO: No se generó la traza de auditoría esperada para la reasignación del puesto';
    END IF;

    -- Limpieza de tablas operativas
    DELETE FROM feria_core.puestos WHERE id_puesto = v_puesto_id;
    DELETE FROM feria_core.sectores WHERE id_sector = v_sector_id;
    DELETE FROM feria_core.ferias WHERE id_feria = v_feria_id;

    -- El usuario auditado v_admin_id está protegido contra eliminación física por la FK RESTRICT de audit_log
    BEGIN
        DELETE FROM auth_acl.usuarios WHERE id_usuario = v_admin_id;
        RAISE EXCEPTION 'FALLO: Se permitió borrar un usuario con registros en audit_log';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE '[OK] Integridad WORM: La FK fk_audit_usuario (RESTRICT) impidió borrar un usuario con historial de auditoría';
    END;

    RAISE NOTICE '--- TEST AUDITORÍA INMUTABLE COMPLETADO CON ÉXITO ---';
END $$;
