-- ==============================================================================
-- TEST 3: Trigger de Control de Potencia Eléctrica Acumulada de 15 kW (FSH-4, FSH-16, FSH-30)
-- ==============================================================================
DO $$
DECLARE
    v_admin_id UUID := gen_random_uuid();
    v_comerciante_id UUID := gen_random_uuid();
    v_feria_id UUID := gen_random_uuid();
    v_sector_id UUID := gen_random_uuid();
    v_puesto_id UUID := gen_random_uuid();
    v_reserva_id UUID := gen_random_uuid();
    v_declaracion_id UUID := gen_random_uuid();
    v_artefacto_id INTEGER;
    v_potencia_calculada NUMERIC(6, 2);
BEGIN
    RAISE NOTICE '--- INICIANDO TEST: Control de Carga Eléctrica de 15 kW por Sector ---';

    -- 1. Setup inicial
    INSERT INTO auth_acl.usuarios (id_usuario, identificador_login, password_hash, tipo_usuario)
    VALUES (v_admin_id, 'admin_elec', 'hash', 'FUNCIONARIO_INTERNO'),
           (v_comerciante_id, '88880003', 'hash', 'COMERCIANTE');

    INSERT INTO auth_acl.comerciante_perfil (id_comerciante, dni, nombres, apellidos, telefono, domicilio)
    VALUES (v_comerciante_id, '88880003', 'Comerciante', 'Electrico', '999888777', 'Jr. Bellido');

    INSERT INTO feria_core.ferias (id_feria, codigo_feria, nombre_feria, descripcion, fecha_inicio, fecha_fin, ubicacion_referencia, creado_por)
    VALUES (v_feria_id, 'F-ELEC-2026', 'Feria Test Electrica', 'Desc', CURRENT_DATE, CURRENT_DATE + 3, 'Parque', v_admin_id);

    -- Sector configurado con el límite estricto de Defensa Civil de 15.00 kW
    INSERT INTO feria_core.sectores (id_sector, id_feria, codigo_sector, nombre_via, capacidad_kw_maxima)
    VALUES (v_sector_id, v_feria_id, 'SEC-ELEC', 'Av. Mariscal Caceres', 15.00);

    INSERT INTO feria_core.puestos (id_puesto, id_sector, codigo_puesto, ancho_metros, largo_metros, posicion_fila, posicion_columna, estado_puesto)
    VALUES (v_puesto_id, v_sector_id, 'P-ELEC-01', 2.00, 2.00, 1, 1, 'RESERVADO');

    INSERT INTO feria_core.postulaciones_reservas (id_reserva, id_feria, id_comerciante, id_puesto, id_giro, fecha_limite_pago, estado_reserva)
    VALUES (v_reserva_id, v_feria_id, v_comerciante_id, v_puesto_id, 1, clock_timestamp() + interval '1 day', 'RESERVADA');

    INSERT INTO feria_core.declaraciones_electricas (id_declaracion, id_reserva, requiere_servicio_luz)
    VALUES (v_declaracion_id, v_reserva_id, TRUE);

    SELECT id_artefacto INTO v_artefacto_id FROM feria_core.artefactos_catalogo LIMIT 1;

    -- 2. Declarar carga permitida: 14.00 kW (menor o igual a 15.00 kW)
    INSERT INTO feria_core.detalles_artefactos (id_declaracion, id_artefacto, cantidad, potencia_unitaria_kw)
    VALUES (v_declaracion_id, v_artefacto_id, 14, 1.000);

    SELECT potencia_actual_calculada_kw INTO v_potencia_calculada
    FROM feria_core.sectores WHERE id_sector = v_sector_id;

    IF v_potencia_calculada = 14.00 THEN
        RAISE NOTICE '[OK] Carga permitida (14.00 kW) registrada correctamente en el sector';
    ELSE
        RAISE EXCEPTION 'FALLO: La potencia calculada no coincide. Esperado: 14.00, Obtenido: %', v_potencia_calculada;
    END IF;

    -- 3. Intentar agregar un artefacto adicional de 2.00 kW (Total acumulado: 16.00 kW > 15.00 kW)
    -- El trigger debe abortar la transacción (FSH-30)
    BEGIN
        INSERT INTO feria_core.detalles_artefactos (id_declaracion, id_artefacto, cantidad, potencia_unitaria_kw)
        VALUES (v_declaracion_id, v_artefacto_id, 2, 1.000);

        RAISE EXCEPTION 'FALLO: El trigger permitió exceder el límite de 15 kW en el sector';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '[OK] Trigger de Defensa Civil (FSH-30) abortó correctamente la inserción que superaba los 15 kW';
    END;

    -- 4. Verificar que la potencia del sector no se corrompió y se mantuvo en 14.00 kW
    SELECT potencia_actual_calculada_kw INTO v_potencia_calculada
    FROM feria_core.sectores WHERE id_sector = v_sector_id;

    IF v_potencia_calculada = 14.00 THEN
        RAISE NOTICE '[OK] Integridad preservada: La potencia del sector continúa en 14.00 kW';
    ELSE
        RAISE EXCEPTION 'FALLO: Estado inconsistente tras error en trigger. Obtenido: %', v_potencia_calculada;
    END IF;

    -- Limpieza controlada respetando el trigger en cascada
    DELETE FROM feria_core.detalles_artefactos WHERE id_declaracion = v_declaracion_id;
    DELETE FROM feria_core.declaraciones_electricas WHERE id_declaracion = v_declaracion_id;
    DELETE FROM feria_core.postulaciones_reservas WHERE id_reserva = v_reserva_id;
    DELETE FROM feria_core.puestos WHERE id_puesto = v_puesto_id;
    DELETE FROM feria_core.sectores WHERE id_sector = v_sector_id;
    DELETE FROM feria_core.ferias WHERE id_feria = v_feria_id;
    DELETE FROM auth_acl.comerciante_perfil WHERE id_comerciante = v_comerciante_id;
    DELETE FROM auth_acl.usuarios WHERE id_usuario IN (v_admin_id, v_comerciante_id);

    RAISE NOTICE '--- TEST CONTROL DE POTENCIA COMPLETADO CON ÉXITO ---';
END $$;
