-- ==============================================================================
-- TEST DE SEGURIDAD: Auditoría WORM, Privilegios Mínimos y Triggers
-- ==============================================================================
DO $$
DECLARE
    v_error_capturado BOOLEAN;
BEGIN
    RAISE NOTICE '--- INICIANDO TEST: Seguridad de Auditoría y Privilegios Mínimos ---';

    -- Conexión como rol de aplicación ordinaria
    SET ROLE app_feriasegura_role;

    -- 1. Intento de TRUNCATE en la tabla audit.audit_log (Debe fallar por falta de privilegios DDL)
    BEGIN
        EXECUTE 'TRUNCATE TABLE audit.audit_log';
        RAISE EXCEPTION 'FALLO: Se permitió a app_feriasegura_role ejecutar TRUNCATE en audit.audit_log';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE '[OK] Privilegios Mínimos: TRUNCATE denegado para app_feriasegura_role';
    END;

    -- 2. Intento de UPDATE en audit.audit_log (Debe fallar por REVOKE y Trigger WORM)
    BEGIN
        EXECUTE 'UPDATE audit.audit_log SET descripcion_evento = ''alteracion'' WHERE id_audit = 1';
        RAISE EXCEPTION 'FALLO: Se permitió a app_feriasegura_role ejecutar UPDATE en audit.audit_log';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE '[OK] WORM Activo: UPDATE denegado para app_feriasegura_role';
    END;

    -- 3. Intento de DELETE en audit.audit_log (Debe fallar por REVOKE y Trigger WORM)
    BEGIN
        EXECUTE 'DELETE FROM audit.audit_log WHERE id_audit = 1';
        RAISE EXCEPTION 'FALLO: Se permitió a app_feriasegura_role ejecutar DELETE en audit.audit_log';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE '[OK] WORM Activo: DELETE denegado para app_feriasegura_role';
    END;

    -- 4. Intento de DROP o ALTER de Triggers por parte de la app (Debe fallar)
    BEGIN
        EXECUTE 'DROP TRIGGER trg_audit_log_inmutable ON audit.audit_log';
        RAISE EXCEPTION 'FALLO: Se permitió a la aplicación alterar triggers de auditoría';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE '[OK] Privilegios Mínimos: La aplicación no es propietaria de la tabla y no puede alterar triggers';
    END;

    RESET ROLE;
    RAISE NOTICE '--- TEST DE SEGURIDAD DE AUDITORÍA COMPLETADO CON ÉXITO ---';
END $$;
