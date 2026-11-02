-- ==============================================================================
-- TEST 2: Control de Concurrencia y Regla de Equidad 1 Puesto por DNI (FSH-14, FSH-29)
-- ==============================================================================
DO $$
DECLARE
    v_admin_id UUID := gen_random_uuid();
    v_comerciante_1_id UUID := gen_random_uuid();
    v_comerciante_2_id UUID := gen_random_uuid();
    v_feria_id UUID := gen_random_uuid();
    v_sector_id UUID := gen_random_uuid();
    v_puesto_1_id UUID := gen_random_uuid();
    v_puesto_2_id UUID := gen_random_uuid();
    v_id_giro INTEGER;
    v_reserva_1_id UUID;
BEGIN
    RAISE NOTICE '--- INICIANDO TEST: Concurrencia y Regla 1 Puesto por DNI ---';

    -- 1. Setup: Crear Admin, 2 Comerciantes, 1 Feria, 1 Sector y 2 Puestos
    INSERT INTO auth_acl.usuarios (id_usuario, identificador_login, password_hash, tipo_usuario)
    VALUES (v_admin_id, 'admin_test', 'hash', 'FUNCIONARIO_INTERNO');

    INSERT INTO auth_acl.usuarios (id_usuario, identificador_login, password_hash, tipo_usuario)
    VALUES (v_comerciante_1_id, '88880001', 'hash', 'COMERCIANTE'),
           (v_comerciante_2_id, '88880002', 'hash', 'COMERCIANTE');

    INSERT INTO auth_acl.comerciante_perfil (id_comerciante, dni, nombres, apellidos, telefono, domicilio)
    VALUES (v_comerciante_1_id, '88880001', 'Comerciante 1', 'Test', '999111222', 'Direccion 1'),
           (v_comerciante_2_id, '88880002', 'Comerciante 2', 'Test', '999333444', 'Direccion 2');

    INSERT INTO feria_core.ferias (id_feria, codigo_feria, nombre_feria, descripcion, fecha_inicio, fecha_fin, ubicacion_referencia, estado_feria, creado_por)
    VALUES (v_feria_id, 'F-TEST-2026', 'Feria Test Concurrencia', 'Desc', CURRENT_DATE, CURRENT_DATE + 5, 'Plaza Mayor', 'CONVOCATORIA_ABIERTA', v_admin_id);

    INSERT INTO feria_core.sectores (id_sector, id_feria, codigo_sector, nombre_via, capacidad_kw_maxima)
    VALUES (v_sector_id, v_feria_id, 'SEC-TEST', 'Calle Test', 15.00);

    INSERT INTO feria_core.puestos (id_puesto, id_sector, codigo_puesto, ancho_metros, largo_metros, posicion_fila, posicion_columna, estado_puesto)
    VALUES (v_puesto_1_id, v_sector_id, 'P-TEST-01', 2.00, 2.00, 1, 1, 'DISPONIBLE'),
           (v_puesto_2_id, v_sector_id, 'P-TEST-02', 2.00, 2.00, 1, 2, 'DISPONIBLE');

    SELECT id_giro INTO v_id_giro FROM feria_core.giros_comerciales LIMIT 1;

    -- 2. Comerciante 1 reserva Puesto 1 de forma exitosa
    v_reserva_1_id := feria_core.sp_reservar_puesto_atomico(v_comerciante_1_id, v_feria_id, v_puesto_1_id, v_id_giro);
    RAISE NOTICE '[OK] Comerciante 1 reservó exitosamente Puesto 1 (Reserva ID: %)', v_reserva_1_id;

    -- 3. Intento simultáneo/posterior: Comerciante 2 intenta reservar el mismo Puesto 1 (debe fallar)
    BEGIN
        PERFORM feria_core.sp_reservar_puesto_atomico(v_comerciante_2_id, v_feria_id, v_puesto_1_id, v_id_giro);
        RAISE EXCEPTION 'FALLO: Se permitió reservar un puesto que ya estaba RESERVADO';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '[OK] Bloqueo de concurrencia: Comerciante 2 fue rechazado al intentar reservar puesto ya ocupado';
    END;

    -- 4. Regla de Equidad (FSH-14): Comerciante 1 intenta reservar un segundo puesto (Puesto 2) en la misma feria (debe fallar)
    BEGIN
        PERFORM feria_core.sp_reservar_puesto_atomico(v_comerciante_1_id, v_feria_id, v_puesto_2_id, v_id_giro);
        RAISE EXCEPTION 'FALLO: Se permitió a un mismo comerciante mantener 2 reservas activas en la misma feria';
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE '[OK] Regla de Equidad (FSH-14): Índice único bloqueó segundo intento de reserva para el mismo DNI';
    END;

    -- Limpieza controlada
    DELETE FROM feria_core.postulaciones_reservas WHERE id_feria = v_feria_id;
    DELETE FROM feria_core.puestos WHERE id_sector = v_sector_id;
    DELETE FROM feria_core.sectores WHERE id_feria = v_feria_id;
    DELETE FROM feria_core.ferias WHERE id_feria = v_feria_id;
    DELETE FROM auth_acl.comerciante_perfil WHERE id_comerciante IN (v_comerciante_1_id, v_comerciante_2_id);
    DELETE FROM auth_acl.usuarios WHERE id_usuario IN (v_admin_id, v_comerciante_1_id, v_comerciante_2_id);

    RAISE NOTICE '--- TEST CONCURRENCIA Y EQUIDAD COMPLETADO CON ÉXITO ---';
END $$;
