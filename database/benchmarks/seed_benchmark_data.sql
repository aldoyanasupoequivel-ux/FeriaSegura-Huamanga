-- ==============================================================================
-- BENCHMARK FSH-32 & FSH-33: Medición de Rendimiento con EXPLAIN (ANALYZE, BUFFERS)
-- ==============================================================================

DO $$
DECLARE
    v_admin_id UUID := gen_random_uuid();
    v_feria_id UUID := gen_random_uuid();
    v_sector_id UUID := 'a0000000-0000-0000-0000-000000000001';
    v_comerciante_id UUID;
    v_puesto_id UUID;
    v_reserva_id UUID;
    v_qr_id UUID;
    r INTEGER;
    c INTEGER;
    i INTEGER := 1;
BEGIN
    INSERT INTO auth_acl.usuarios (id_usuario, identificador_login, password_hash, tipo_usuario)
    VALUES (v_admin_id, 'admin_bench', 'hash', 'FUNCIONARIO_INTERNO')
    ON CONFLICT (identificador_login) DO NOTHING;

    INSERT INTO auth_acl.funcionario_perfil (id_funcionario, dni, nombres, apellidos, cargo, area_municipal)
    VALUES (v_admin_id, '71009988', 'Admin', 'Emisor', 'Jefe Catastro', 'ADMINISTRACION')
    ON CONFLICT (id_funcionario) DO NOTHING;

    INSERT INTO feria_core.ferias (id_feria, codigo_feria, nombre_feria, descripcion, fecha_inicio, fecha_fin, ubicacion_referencia, creado_por)
    VALUES (v_feria_id, 'F-BENCH-2026', 'Feria Benchmark Huamanga', 'Feria representativa', CURRENT_DATE, CURRENT_DATE + 7, 'Parque Central', v_admin_id)
    ON CONFLICT (codigo_feria) DO NOTHING;

    INSERT INTO feria_core.sectores (id_sector, id_feria, codigo_sector, nombre_via, capacidad_kw_maxima)
    VALUES (v_sector_id, v_feria_id, 'SEC-BENCH', 'Av. Independencia', 15.00)
    ON CONFLICT DO NOTHING;

    -- Generar cuadrícula de 500 puestos (25 filas x 20 columnas)
    FOR r IN 1..25 LOOP
        FOR c IN 1..20 LOOP
            v_puesto_id := gen_random_uuid();
            INSERT INTO feria_core.puestos (
                id_puesto, id_sector, codigo_puesto, ancho_metros, largo_metros, posicion_fila, posicion_columna, estado_puesto
            ) VALUES (
                v_puesto_id,
                v_sector_id,
                format('P-BENCH-%s-%s', r, c),
                2.00,
                2.00,
                r,
                c,
                CASE WHEN (r + c) % 3 = 0 THEN 'RESERVADO'
                     WHEN (r + c) % 5 = 0 THEN 'BLOQUEADO'
                     ELSE 'DISPONIBLE' END
            );

            -- Crear 100 credenciales QR autorizadas para pruebas de fiscalización
            IF (r + c) % 5 = 0 AND i <= 100 THEN
                v_comerciante_id := gen_random_uuid();
                INSERT INTO auth_acl.usuarios (id_usuario, identificador_login, password_hash, tipo_usuario)
                VALUES (v_comerciante_id, format('7700%s', lpad(i::text, 4, '0')), 'hash', 'COMERCIANTE');

                INSERT INTO auth_acl.comerciante_perfil (id_comerciante, dni, nombres, apellidos, telefono, domicilio)
                VALUES (v_comerciante_id, format('7700%s', lpad(i::text, 4, '0')), format('Comerciante %s', i), 'Test', '999888111', 'Direccion');

                v_reserva_id := gen_random_uuid();
                INSERT INTO feria_core.postulaciones_reservas (id_reserva, id_feria, id_comerciante, id_puesto, id_giro, fecha_limite_pago, estado_reserva)
                VALUES (v_reserva_id, v_feria_id, v_comerciante_id, v_puesto_id, 1, clock_timestamp() + interval '1 day', 'FORMALIZADA');

                -- Credencial QR conocida para el test
                IF i = 1 THEN
                    v_qr_id := 'b0000000-0000-0000-0000-000000000001';
                ELSE
                    v_qr_id := gen_random_uuid();
                END IF;

                INSERT INTO feria_core.credenciales_autorizacion (id_autorizacion, id_reserva, codigo_qr_identificador, firma_digital_qr, estado_autorizacion, emitido_por)
                VALUES (gen_random_uuid(), v_reserva_id, v_qr_id, 'hmac_sha256_firma_valida_huamanga', 'APROBADA', v_admin_id);

                i := i + 1;
            END IF;
        END LOOP;
    END LOOP;

    ANALYZE feria_core.puestos;
    ANALYZE feria_core.credenciales_autorizacion;
END $$;
