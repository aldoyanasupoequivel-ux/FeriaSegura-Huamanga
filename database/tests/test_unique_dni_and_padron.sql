-- ==============================================================================
-- TEST 1: Validación y Unicidad de DNI de Comerciantes (FSH-36)
-- ==============================================================================
DO $$
DECLARE
    v_user_id UUID;
    v_error_capturado BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '--- INICIANDO TEST: Validación de DNI y Unicidad ---';

    -- 1. Intentar registrar DNI con menos de 8 dígitos (debe fallar por CHECK)
    BEGIN
        v_user_id := gen_random_uuid();
        INSERT INTO auth_acl.usuarios (id_usuario, identificador_login, password_hash, tipo_usuario)
        VALUES (v_user_id, '12345', 'hash_test', 'COMERCIANTE');

        INSERT INTO auth_acl.comerciante_perfil (id_comerciante, dni, nombres, apellidos, telefono, domicilio)
        VALUES (v_user_id, '12345', 'Nombre', 'Apellido', '966000111', 'Calle Test');

        RAISE EXCEPTION 'FALLO: Se permitió DNI con formato inválido';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '[OK] Restricción CHECK bloqueó correctamente DNI inválido (12345)';
    END;

    -- 2. Registrar comerciante válido
    v_user_id := gen_random_uuid();
    INSERT INTO auth_acl.usuarios (id_usuario, identificador_login, password_hash, tipo_usuario)
    VALUES (v_user_id, '70809010', 'hash_test_valido', 'COMERCIANTE');

    INSERT INTO auth_acl.comerciante_perfil (id_comerciante, dni, nombres, apellidos, telefono, domicilio)
    VALUES (v_user_id, '70809010', 'Erick', 'Vasquez', '966123456', 'Jr. 28 de Julio 123');

    RAISE NOTICE '[OK] Comerciante con DNI válido (70809010) registrado exitosamente';

    -- 3. Intentar duplicar el mismo DNI en otro usuario (debe fallar por UNIQUE)
    BEGIN
        DECLARE
            v_user_id_duplicado UUID := gen_random_uuid();
        BEGIN
            INSERT INTO auth_acl.usuarios (id_usuario, identificador_login, password_hash, tipo_usuario)
            VALUES (v_user_id_duplicado, '70809010_otro', 'hash_test', 'COMERCIANTE');

            INSERT INTO auth_acl.comerciante_perfil (id_comerciante, dni, nombres, apellidos, telefono, domicilio)
            VALUES (v_user_id_duplicado, '70809010', 'Otro', 'Nombre', '966999888', 'Otra Calle');

            RAISE EXCEPTION 'FALLO: Se permitió duplicar DNI existente';
        END;
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE '[OK] Restricción UNIQUE bloqueó correctamente duplicado de DNI';
    END;

    -- Limpieza de datos de prueba
    DELETE FROM auth_acl.comerciante_perfil WHERE dni = '70809010';
    DELETE FROM auth_acl.usuarios WHERE identificador_login IN ('12345', '70809010', '70809010_otro');

    RAISE NOTICE '--- TEST DNI Y UNICIDAD COMPLETADO CON ÉXITO ---';
END $$;
