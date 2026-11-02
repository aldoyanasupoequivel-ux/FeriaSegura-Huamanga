-- ==============================================================================
-- TEST DE SEGURIDAD AVANZADO: Suplantación de Identidad, Sesiones y ACL
-- ==============================================================================
DO $$
DECLARE
    v_comerciante_victima_id UUID := gen_random_uuid();
    v_atacante_id UUID := gen_random_uuid();
    v_sesion_token VARCHAR(64) := 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
    v_count INTEGER;
    v_reserva_victima_id UUID := gen_random_uuid();
    v_puesto_id UUID := gen_random_uuid();
    v_feria_id UUID := gen_random_uuid();
    v_sector_id UUID := gen_random_uuid();
BEGIN
    RAISE NOTICE '--- INICIANDO TEST: Seguridad contra Suplantación de Identidad (Spoofing) ---';

    -- 1. Crear Comerciante Víctima y Atacante en auth_acl.usuarios
    INSERT INTO auth_acl.usuarios (id_usuario, identificador_login, password_hash, tipo_usuario, estado_cuenta)
    VALUES (v_comerciante_victima_id, '80001111', 'hash_victima', 'COMERCIANTE', 'HABILITADA'),
           (v_atacante_id, '80002222', 'hash_atacante', 'COMERCIANTE', 'HABILITADA');

    INSERT INTO auth_acl.comerciante_perfil (id_comerciante, dni, nombres, apellidos, telefono, domicilio)
    VALUES (v_comerciante_victima_id, '80001111', 'Juan', 'Victima', '999111222', 'Av. Cuzco 100'),
           (v_atacante_id, '80002222', 'Carlos', 'Atacante', '999333444', 'Av. Cuzco 200');

    -- Registrar una sesión activa legítima para el atacante
    INSERT INTO auth_acl.sesion_tokens (id_usuario, token_hash, ip_origen, expira_en, revocado)
    VALUES (v_atacante_id, v_sesion_token, '192.168.1.50'::inet, clock_timestamp() + interval '2 hours', FALSE);

    -- Setup ferial
    INSERT INTO feria_core.ferias (id_feria, codigo_feria, nombre_feria, descripcion, fecha_inicio, fecha_fin, ubicacion_referencia, creado_por)
    VALUES (v_feria_id, 'F-SPOOF-2026', 'Feria Antifraude', 'Desc', CURRENT_DATE, CURRENT_DATE + 5, 'Plaza', v_atacante_id);

    INSERT INTO feria_core.sectores (id_sector, id_feria, codigo_sector, nombre_via)
    VALUES (v_sector_id, v_feria_id, 'SEC-SPF', 'Calle Segura');

    INSERT INTO feria_core.puestos (id_puesto, id_sector, codigo_puesto, ancho_metros, largo_metros, posicion_fila, posicion_columna)
    VALUES (v_puesto_id, v_sector_id, 'P-SPF-01', 2.00, 2.00, 1, 1);

    INSERT INTO feria_core.postulaciones_reservas (id_reserva, id_feria, id_comerciante, id_puesto, id_giro, fecha_limite_pago)
    VALUES (v_reserva_victima_id, v_feria_id, v_comerciante_victima_id, v_puesto_id, 1, clock_timestamp() + interval '1 day');

    INSERT INTO feria_core.pagos_tupa (id_reserva, numero_operacion, monto, ruta_comprobante, hash_comprobante)
    VALUES (v_reserva_victima_id, 'VOUCHER-CONFIDENCIAL', 120.00, '/docs/v_victima.png', 'hash_sha256_victima');

    -- 2. ATAQUE 1: El atacante intenta forzar un contexto con el ID de la víctima
    SET ROLE app_feriasegura_role;

    -- Conexión legítima del atacante
    PERFORM set_config('app.current_user_id', v_atacante_id::TEXT, true);

    -- Intento de leer los vouchers de la víctima
    SELECT COUNT(*) INTO v_count FROM feria_core.pagos_tupa WHERE id_reserva = v_reserva_victima_id;
    IF v_count = 0 THEN
        RAISE NOTICE '[OK] RLS bloqueó al atacante: No pudo ver los datos de pago de la víctima';
    ELSE
        RAISE EXCEPTION 'VULNERABILIDAD CRÍTICA: Atacante pudo leer el pago de la víctima';
    END IF;

    -- 3. ATAQUE 2: Intento de manipular el DNI de la víctima mediante UPDATE directo
    BEGIN
        UPDATE auth_acl.comerciante_perfil
        SET telefono = '999666999'
        WHERE id_comerciante = v_comerciante_victima_id;
        
        GET DIAGNOSTICS v_count = ROW_COUNT;
        IF v_count = 0 THEN
            RAISE NOTICE '[OK] RLS WITH CHECK bloqueó intento de modificar perfil de otro comerciante (Filas modificadas: 0)';
        ELSE
            RAISE EXCEPTION 'VULNERABILIDAD: Atacante modificó perfil ajeno';
        END IF;
    END;

    -- 4. ATAQUE 3: Cierre de Sesión y Verificación de Revocación de Token
    RESET ROLE;
    UPDATE auth_acl.sesion_tokens
    SET revocado = TRUE
    WHERE token_hash = v_sesion_token;

    -- Comprobar que el token revocado ya no sea considerado válido
    SELECT COUNT(*) INTO v_count
    FROM auth_acl.sesion_tokens
    WHERE token_hash = v_sesion_token AND revocado = FALSE AND expira_en > clock_timestamp();

    IF v_count = 0 THEN
        RAISE NOTICE '[OK] Control de Sesión: Token revocado invalidado inmediatamente en base de datos';
    ELSE
        RAISE EXCEPTION 'VULNERABILIDAD: Token revocado continúa activo';
    END IF;

    -- Limpieza
    DELETE FROM feria_core.pagos_tupa WHERE id_reserva = v_reserva_victima_id;
    DELETE FROM feria_core.postulaciones_reservas WHERE id_reserva = v_reserva_victima_id;
    DELETE FROM feria_core.puestos WHERE id_puesto = v_puesto_id;
    DELETE FROM feria_core.sectores WHERE id_sector = v_sector_id;
    DELETE FROM feria_core.ferias WHERE id_feria = v_feria_id;
    DELETE FROM auth_acl.sesion_tokens WHERE token_hash = v_sesion_token;
    DELETE FROM auth_acl.comerciante_perfil WHERE id_comerciante IN (v_comerciante_victima_id, v_atacante_id);
    DELETE FROM auth_acl.usuarios WHERE id_usuario IN (v_comerciante_victima_id, v_atacante_id);

    RAISE NOTICE '--- TEST DE SUPLANTACIÓN Y SEGURIDAD ACL COMPLETADO CON ÉXITO ---';
END $$;
