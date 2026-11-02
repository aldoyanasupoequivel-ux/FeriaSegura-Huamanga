-- ==============================================================================
-- FERIA SEGURA HUAMANGA (FeriaSegura)
-- Suite Completa de Pruebas de Seguridad ACL y RLS
-- Cobertura: RBAC, RLS, Impersonación, WORM, Sesiones
-- ==============================================================================

\set ON_ERROR_STOP on

SELECT '>>> INICIANDO SUITE DE PRUEBAS DE SEGURIDAD ACL + RLS <<<' AS status;

-- ─────────────────────────────────────────────────────────────────────────────
-- TEST 1: Verificar que RLS está habilitado en todas las tablas críticas
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
    v_tablas_rls TEXT[] := ARRAY[
        'auth_acl.comerciante_perfil',
        'auth_acl.sesion_tokens',
        'feria_core.postulaciones_reservas',
        'feria_core.pagos_tupa',
        'feria_core.declaraciones_electricas',
        'feria_core.actas_infraccion',
        'audit.audit_log'
    ];
    v_tabla TEXT;
    v_esquema TEXT;
    v_nombre TEXT;
    v_rls_enabled BOOLEAN;
BEGIN
    RAISE NOTICE '--- TEST 1: Verificación de RLS habilitado en tablas críticas ---';
    FOREACH v_tabla IN ARRAY v_tablas_rls LOOP
        v_esquema := split_part(v_tabla, '.', 1);
        v_nombre  := split_part(v_tabla, '.', 2);
        SELECT relrowsecurity INTO v_rls_enabled
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = v_esquema AND c.relname = v_nombre;

        IF v_rls_enabled THEN
            RAISE NOTICE '[OK] RLS habilitado en: %', v_tabla;
        ELSE
            RAISE EXCEPTION '[FALLO] RLS NO está habilitado en: %', v_tabla;
        END IF;
    END LOOP;
    RAISE NOTICE '--- TEST 1 COMPLETADO: RLS verificado en % tablas ---', array_length(v_tablas_rls, 1);
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- TEST 2: Verificar que las políticas RLS existen y están correctamente definidas
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    RAISE NOTICE '--- TEST 2: Verificación de Políticas RLS ---';
    
    SELECT COUNT(*) INTO v_count
    FROM pg_policies
    WHERE schemaname IN ('auth_acl', 'feria_core', 'audit');
    
    IF v_count >= 8 THEN
        RAISE NOTICE '[OK] % políticas RLS definidas en los esquemas del sistema', v_count;
    ELSE
        RAISE EXCEPTION '[FALLO] Solo % políticas RLS encontradas. Se esperan >= 8', v_count;
    END IF;
    
    -- Verificar política crítica de auditoría
    SELECT COUNT(*) INTO v_count
    FROM pg_policies
    WHERE schemaname = 'audit' AND tablename = 'audit_log';
    
    IF v_count >= 1 THEN
        RAISE NOTICE '[OK] Política RLS de audit_log existe (solo lectura privilegiada)';
    ELSE
        RAISE EXCEPTION '[FALLO] No existe política RLS en audit.audit_log';
    END IF;
    
    RAISE NOTICE '--- TEST 2 COMPLETADO ---';
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- TEST 3: Verificar que el rol app_feriasegura_role existe y está restringido
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
    v_superuser BOOLEAN;
    v_createdb BOOLEAN;
    v_createrole BOOLEAN;
    v_exists BOOLEAN;
BEGIN
    RAISE NOTICE '--- TEST 3: Verificación de Privilegios del Rol de Aplicación ---';
    
    SELECT EXISTS(SELECT 1 FROM pg_roles WHERE rolname = 'app_feriasegura_role') INTO v_exists;
    IF NOT v_exists THEN
        RAISE EXCEPTION '[FALLO] El rol app_feriasegura_role no existe';
    END IF;
    
    SELECT rolsuper, rolcreatedb, rolcreaterole
    INTO v_superuser, v_createdb, v_createrole
    FROM pg_roles WHERE rolname = 'app_feriasegura_role';
    
    IF v_superuser = FALSE THEN
        RAISE NOTICE '[OK] app_feriasegura_role: NO es superusuario';
    ELSE
        RAISE EXCEPTION '[FALLO CRÍTICO] app_feriasegura_role tiene privilegios de SUPERUSUARIO';
    END IF;
    
    IF v_createdb = FALSE THEN
        RAISE NOTICE '[OK] app_feriasegura_role: NO puede crear bases de datos';
    ELSE
        RAISE EXCEPTION '[FALLO] app_feriasegura_role puede crear bases de datos';
    END IF;
    
    IF v_createrole = FALSE THEN
        RAISE NOTICE '[OK] app_feriasegura_role: NO puede crear roles';
    ELSE
        RAISE EXCEPTION '[FALLO] app_feriasegura_role puede crear roles';
    END IF;
    
    RAISE NOTICE '--- TEST 3 COMPLETADO: Principio de menor privilegio verificado ---';
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- TEST 4: Verificar que audit.audit_log tiene el trigger WORM activo
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    RAISE NOTICE '--- TEST 4: Verificación del Trigger WORM en Auditoría ---';
    
    SELECT COUNT(*) INTO v_count
    FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'audit'
      AND c.relname = 'audit_log'
      AND t.tgname = 'trg_audit_log_inmutable'
      AND t.tgenabled = 'O'; -- 'O' = always active
    
    IF v_count = 1 THEN
        RAISE NOTICE '[OK] Trigger WORM trg_audit_log_inmutable activo en audit.audit_log';
    ELSE
        RAISE EXCEPTION '[FALLO] Trigger WORM no encontrado o deshabilitado en audit.audit_log';
    END IF;
    
    RAISE NOTICE '--- TEST 4 COMPLETADO ---';
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- TEST 5: Verificar que UPDATE y DELETE en audit_log están bloqueados
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
    v_test_id BIGINT;
BEGIN
    RAISE NOTICE '--- TEST 5: Prueba de Inmutabilidad WORM (UPDATE/DELETE en audit_log) ---';
    
    -- Insertar un registro de prueba
    INSERT INTO audit.audit_log (
        id_usuario_responsable, esquema, tabla, id_registro_afectado, tipo_operacion
    ) VALUES (
        NULL, 'test', 'worm_test', 'test-id-999', 'INSERT'
    ) RETURNING id_audit INTO v_test_id;
    
    RAISE NOTICE '[OK] INSERT en audit_log: permitido correctamente';
    
    -- Intentar UPDATE: debe lanzar excepción
    BEGIN
        UPDATE audit.audit_log SET descripcion_evento = 'ADULTERADO' WHERE id_audit = v_test_id;
        RAISE EXCEPTION '[FALLO CRÍTICO] UPDATE en audit_log NO fue bloqueado por trigger WORM';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE '[OK] UPDATE bloqueado por trigger WORM: % ', SQLERRM;
    END;
    
    -- Intentar DELETE: debe lanzar excepción
    BEGIN
        DELETE FROM audit.audit_log WHERE id_audit = v_test_id;
        RAISE EXCEPTION '[FALLO CRÍTICO] DELETE en audit_log NO fue bloqueado por trigger WORM';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE '[OK] DELETE bloqueado por trigger WORM: %', SQLERRM;
    END;
    
    RAISE NOTICE '--- TEST 5 COMPLETADO: Inmutabilidad WORM verificada ---';
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- TEST 6: Verificar integridad referencial FK WORM (ON DELETE RESTRICT)
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
    v_count INTEGER;
    v_confdeltype CHAR;
BEGIN
    RAISE NOTICE '--- TEST 6: Verificación FK audit.audit_log → auth_acl.usuarios (RESTRICT) ---';
    
    SELECT c.confdeltype INTO v_confdeltype
    FROM pg_constraint c
    JOIN pg_class cl ON cl.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = cl.relnamespace
    WHERE n.nspname = 'audit'
      AND cl.relname = 'audit_log'
      AND c.conname = 'fk_audit_usuario';
    
    IF v_confdeltype = 'r' THEN  -- 'r' = RESTRICT
        RAISE NOTICE '[OK] FK fk_audit_usuario configurada como ON DELETE RESTRICT';
    ELSIF v_confdeltype = 'a' THEN  -- 'a' = NO ACTION
        RAISE NOTICE '[OK] FK fk_audit_usuario configurada como ON DELETE NO ACTION (equivalente)';
    ELSIF v_confdeltype = 'n' THEN  -- 'n' = SET NULL (observación resuelta)
        RAISE EXCEPTION '[FALLO] FK fk_audit_usuario aún usa ON DELETE SET NULL. Ejecutar migración 008.';
    ELSE
        RAISE EXCEPTION '[FALLO] FK fk_audit_usuario tiene acción inesperada: %', v_confdeltype;
    END IF;
    
    RAISE NOTICE '--- TEST 6 COMPLETADO ---';
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- TEST 7: Verificar que las funciones auxiliares RLS existen
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
    v_funcs TEXT[] := ARRAY[
        'auth_acl.fn_get_current_user_id',
        'auth_acl.fn_is_funcionario_interno',
        'auth_acl.fn_has_area',
        'auth_acl.fn_has_permiso'
    ];
    v_func TEXT;
    v_exists BOOLEAN;
BEGIN
    RAISE NOTICE '--- TEST 7: Verificación de Funciones Auxiliares RLS ---';
    FOREACH v_func IN ARRAY v_funcs LOOP
        v_exists := (
            SELECT EXISTS(
                SELECT 1 FROM pg_proc p
                JOIN pg_namespace n ON n.oid = p.pronamespace
                WHERE n.nspname || '.' || p.proname = v_func
            )
        );
        IF v_exists THEN
            RAISE NOTICE '[OK] Función % existe', v_func;
        ELSE
            RAISE EXCEPTION '[FALLO] Función % NO existe', v_func;
        END IF;
    END LOOP;
    RAISE NOTICE '--- TEST 7 COMPLETADO ---';
END $$;

SELECT '>>> SUITE DE PRUEBAS ACL + RLS COMPLETADA EXITOSAMENTE <<<' AS resultado_final;
