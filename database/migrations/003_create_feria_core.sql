-- ==============================================================================
-- FERIA SEGURA HUAMANGA (FeriaSegura)
-- Migración 003: Dominio Ferial Central
-- Tareas Jira: FSH-1, FSH-2, FSH-3, FSH-4, FSH-5, FSH-6, FSH-8, FSH-9,
--              FSH-13, FSH-14, FSH-15, FSH-16, FSH-17, FSH-18, FSH-19,
--              FSH-20, FSH-21, FSH-25, FSH-26, FSH-28, FSH-30
-- ==============================================================================

-- 1. Padrón Municipal Histórico (FSH-36)
CREATE TABLE IF NOT EXISTS feria_core.padron_historico (
    id_padron BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dni CHAR(8) NOT NULL,
    nombres_completos VARCHAR(200) NOT NULL,
    giro_historico VARCHAR(100) NULL,
    anio_registro SMALLINT NOT NULL,
    observaciones TEXT NULL,
    CONSTRAINT chk_padron_dni CHECK (dni ~ '^[0-9]{8}$')
);

-- 2. Catálogo de Giros Comerciales
CREATE TABLE IF NOT EXISTS feria_core.giros_comerciales (
    id_giro SERIAL PRIMARY KEY,
    nombre_giro VARCHAR(100) NOT NULL,
    requiere_inspeccion_sanitaria BOOLEAN NOT NULL DEFAULT FALSE,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_giros_nombre UNIQUE (nombre_giro)
);

-- 3. Ferias Temporales (FSH-1, FSH-8)
CREATE TABLE IF NOT EXISTS feria_core.ferias (
    id_feria UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo_feria VARCHAR(30) NOT NULL,
    nombre_feria VARCHAR(150) NOT NULL,
    descripcion TEXT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    ubicacion_referencia VARCHAR(255) NOT NULL,
    estado_feria VARCHAR(25) NOT NULL DEFAULT 'BORRADOR',
    creado_por UUID NOT NULL,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_ferias_codigo UNIQUE (codigo_feria),
    CONSTRAINT fk_ferias_creador FOREIGN KEY (creado_por) 
        REFERENCES auth_acl.usuarios(id_usuario) ON DELETE RESTRICT,
    CONSTRAINT chk_ferias_fechas CHECK (fecha_fin >= fecha_inicio),
    CONSTRAINT chk_ferias_estado CHECK (estado_feria IN ('BORRADOR', 'CONFIGURADA', 'CONVOCATORIA_ABIERTA', 'EN_EJECUCION', 'FINALIZADA'))
);

-- 4. Sectores o Vías Delimitadas (FSH-1, FSH-25, FSH-4, FSH-16)
CREATE TABLE IF NOT EXISTS feria_core.sectores (
    id_sector UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_feria UUID NOT NULL,
    codigo_sector VARCHAR(20) NOT NULL,
    nombre_via VARCHAR(150) NOT NULL,
    capacidad_kw_maxima NUMERIC(6, 2) NOT NULL DEFAULT 15.00,
    potencia_actual_calculada_kw NUMERIC(6, 2) NOT NULL DEFAULT 0.00,
    suministro_electrico_bloqueado BOOLEAN NOT NULL DEFAULT FALSE,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_sectores_feria_codigo UNIQUE (id_feria, codigo_sector),
    CONSTRAINT fk_sectores_feria FOREIGN KEY (id_feria) 
        REFERENCES feria_core.ferias(id_feria) ON DELETE RESTRICT,
    CONSTRAINT chk_sectores_capacidad_positiva CHECK (capacidad_kw_maxima > 0),
    CONSTRAINT chk_sectores_potencia_valida CHECK (potencia_actual_calculada_kw >= 0)
);

COMMENT ON COLUMN feria_core.sectores.capacidad_kw_maxima IS 'Límite de potencia eléctrica establecido por Defensa Civil (FSH-16)';

-- 5. Puestos Comerciales (FSH-1, FSH-9, FSH-26, FSH-28)
CREATE TABLE IF NOT EXISTS feria_core.puestos (
    id_puesto UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_sector UUID NOT NULL,
    codigo_puesto VARCHAR(30) NOT NULL,
    ancho_metros NUMERIC(3, 2) NOT NULL DEFAULT 2.00,
    largo_metros NUMERIC(3, 2) NOT NULL DEFAULT 2.00,
    posicion_fila SMALLINT NOT NULL,
    posicion_columna SMALLINT NOT NULL,
    estado_puesto VARCHAR(20) NOT NULL DEFAULT 'DISPONIBLE',
    es_zona_riesgo BOOLEAN NOT NULL DEFAULT FALSE,
    motivo_bloqueo VARCHAR(50) NULL,
    bloqueado_por UUID NULL,
    version_lock BIGINT NOT NULL DEFAULT 0,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_puestos_sector_codigo UNIQUE (id_sector, codigo_puesto),
    CONSTRAINT uq_puestos_sector_coordenadas UNIQUE (id_sector, posicion_fila, posicion_columna),
    CONSTRAINT fk_puestos_sector FOREIGN KEY (id_sector) 
        REFERENCES feria_core.sectores(id_sector) ON DELETE RESTRICT,
    CONSTRAINT fk_puestos_bloqueador FOREIGN KEY (bloqueado_por) 
        REFERENCES auth_acl.usuarios(id_usuario) ON DELETE SET NULL,
    CONSTRAINT chk_puestos_dimensiones_2x2 CHECK (ancho_metros = 2.00 AND largo_metros = 2.00),
    CONSTRAINT chk_puestos_estado CHECK (estado_puesto IN ('DISPONIBLE', 'RESERVADO', 'ASIGNADO', 'BLOQUEADO')),
    CONSTRAINT chk_puestos_motivo_bloqueo CHECK (motivo_bloqueo IS NULL OR motivo_bloqueo IN ('HIDRANTE_BOMBEROS', 'SALIDA_EVACUACION', 'ZONA_ELECTRICA_CRITICA', 'DECISION_MUNICIPAL')),
    CONSTRAINT chk_puestos_coordenadas CHECK (posicion_fila >= 0 AND posicion_columna >= 0)
);

COMMENT ON TABLE feria_core.puestos IS 'Puestos comerciales de dimensiones 2x2m conforme a FSH-26 y FSH-28';

-- 6. Postulaciones y Reservas (FSH-3, FSH-13, FSH-14, FSH-29)
CREATE TABLE IF NOT EXISTS feria_core.postulaciones_reservas (
    id_reserva UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_feria UUID NOT NULL,
    id_comerciante UUID NOT NULL,
    id_puesto UUID NOT NULL,
    id_giro INTEGER NOT NULL,
    fecha_reserva TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    fecha_limite_pago TIMESTAMPTZ NOT NULL,
    estado_reserva VARCHAR(25) NOT NULL DEFAULT 'RESERVADA',
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT fk_reservas_feria FOREIGN KEY (id_feria) 
        REFERENCES feria_core.ferias(id_feria) ON DELETE RESTRICT,
    CONSTRAINT fk_reservas_comerciante FOREIGN KEY (id_comerciante) 
        REFERENCES auth_acl.comerciante_perfil(id_comerciante) ON DELETE RESTRICT,
    CONSTRAINT fk_reservas_puesto FOREIGN KEY (id_puesto) 
        REFERENCES feria_core.puestos(id_puesto) ON DELETE RESTRICT,
    CONSTRAINT fk_reservas_giro FOREIGN KEY (id_giro) 
        REFERENCES feria_core.giros_comerciales(id_giro) ON DELETE RESTRICT,
    CONSTRAINT chk_reservas_estado CHECK (estado_reserva IN ('RESERVADA', 'EN_EVALUACION_PAGO', 'FORMALIZADA', 'EXPIRADA', 'CANCELADA'))
);

-- 7. Pagos y Validación TUPA (FSH-5, FSH-17, FSH-18)
CREATE TABLE IF NOT EXISTS feria_core.pagos_tupa (
    id_pago UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_reserva UUID NOT NULL,
    numero_operacion VARCHAR(50) NOT NULL,
    monto NUMERIC(8, 2) NOT NULL,
    ruta_comprobante VARCHAR(500) NOT NULL,
    hash_comprobante VARCHAR(64) NOT NULL,
    fecha_subida TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    estado_pago VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    observaciones_tesoreria TEXT NULL,
    validado_por UUID NULL,
    fecha_validacion TIMESTAMPTZ NULL,
    CONSTRAINT uq_pagos_reserva UNIQUE (id_reserva),
    CONSTRAINT fk_pagos_reserva FOREIGN KEY (id_reserva) 
        REFERENCES feria_core.postulaciones_reservas(id_reserva) ON DELETE RESTRICT,
    CONSTRAINT fk_pagos_validador FOREIGN KEY (validado_por) 
        REFERENCES auth_acl.funcionario_perfil(id_funcionario) ON DELETE RESTRICT,
    CONSTRAINT chk_pagos_monto CHECK (monto > 0),
    CONSTRAINT chk_pagos_estado CHECK (estado_pago IN ('PENDIENTE', 'VALIDADO', 'RECHAZADO'))
);

-- 8. Credenciales Municipales con Código QR Único (FSH-5, FSH-19, FSH-20, FSH-33)
CREATE TABLE IF NOT EXISTS feria_core.credenciales_autorizacion (
    id_autorizacion UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_reserva UUID NOT NULL,
    codigo_qr_identificador UUID NOT NULL DEFAULT gen_random_uuid(),
    firma_digital_qr TEXT NOT NULL,
    estado_autorizacion VARCHAR(20) NOT NULL DEFAULT 'APROBADA',
    fecha_emision TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    emitido_por UUID NOT NULL,
    CONSTRAINT uq_credenciales_reserva UNIQUE (id_reserva),
    CONSTRAINT uq_credenciales_qr UNIQUE (codigo_qr_identificador),
    CONSTRAINT fk_credenciales_reserva FOREIGN KEY (id_reserva) 
        REFERENCES feria_core.postulaciones_reservas(id_reserva) ON DELETE RESTRICT,
    CONSTRAINT fk_credenciales_emisor FOREIGN KEY (emitido_por) 
        REFERENCES auth_acl.funcionario_perfil(id_funcionario) ON DELETE RESTRICT,
    CONSTRAINT chk_credenciales_estado CHECK (estado_autorizacion IN ('PENDIENTE', 'APROBADA', 'VENCIDA', 'ANULADA'))
);

-- 9. Declaración Jurada Eléctrica (FSH-4, FSH-15, FSH-16)
CREATE TABLE IF NOT EXISTS feria_core.declaraciones_electricas (
    id_declaracion UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_reserva UUID NOT NULL,
    requiere_servicio_luz BOOLEAN NOT NULL DEFAULT TRUE,
    potencia_total_kw NUMERIC(6, 3) NOT NULL DEFAULT 0.000,
    fecha_declaracion TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_declaraciones_reserva UNIQUE (id_reserva),
    CONSTRAINT fk_declaraciones_reserva FOREIGN KEY (id_reserva) 
        REFERENCES feria_core.postulaciones_reservas(id_reserva) ON DELETE RESTRICT,
    CONSTRAINT chk_declaraciones_potencia_positiva CHECK (potencia_total_kw >= 0)
);

-- 10. Catálogo de Artefactos Eléctricos
CREATE TABLE IF NOT EXISTS feria_core.artefactos_catalogo (
    id_artefacto SERIAL PRIMARY KEY,
    nombre_artefacto VARCHAR(100) NOT NULL,
    potencia_referencial_watts NUMERIC(6, 2) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_artefactos_nombre UNIQUE (nombre_artefacto),
    CONSTRAINT chk_artefactos_potencia CHECK (potencia_referencial_watts > 0)
);

-- 11. Detalle de Artefactos Declarados (FSH-4, FSH-15, FSH-30)
CREATE TABLE IF NOT EXISTS feria_core.detalles_artefactos (
    id_detalle BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_declaracion UUID NOT NULL,
    id_artefacto INTEGER NOT NULL,
    cantidad SMALLINT NOT NULL,
    potencia_unitaria_kw NUMERIC(6, 3) NOT NULL,
    potencia_subtotal_kw NUMERIC(6, 3) GENERATED ALWAYS AS (cantidad * potencia_unitaria_kw) STORED,
    CONSTRAINT fk_detalles_declaracion FOREIGN KEY (id_declaracion) 
        REFERENCES feria_core.declaraciones_electricas(id_declaracion) ON DELETE CASCADE,
    CONSTRAINT fk_detalles_artefacto FOREIGN KEY (id_artefacto) 
        REFERENCES feria_core.artefactos_catalogo(id_artefacto) ON DELETE RESTRICT,
    CONSTRAINT chk_detalles_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_detalles_potencia_unitaria CHECK (potencia_unitaria_kw > 0)
);

-- 12. Motivos de Infracción Tipificados (FSH-6, FSH-21)
CREATE TABLE IF NOT EXISTS feria_core.motivos_infraccion (
    id_motivo SERIAL PRIMARY KEY,
    codigo_normativo VARCHAR(30) NOT NULL,
    descripcion_motivo VARCHAR(255) NOT NULL,
    gravedad VARCHAR(20) NOT NULL,
    monto_sancion_uit_porcentaje NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    CONSTRAINT uq_motivos_codigo UNIQUE (codigo_normativo),
    CONSTRAINT chk_motivos_gravedad CHECK (gravedad IN ('LEVE', 'GRAVE', 'MUY_GRAVE'))
);

-- 13. Actas de Infracción Levantadas en Campo (FSH-6, FSH-20, FSH-21)
CREATE TABLE IF NOT EXISTS feria_core.actas_infraccion (
    id_acta UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_acta_correlativo VARCHAR(50) NOT NULL,
    id_puesto UUID NOT NULL,
    id_comerciante UUID NOT NULL,
    id_motivo INTEGER NOT NULL,
    id_fiscalizador UUID NOT NULL,
    fecha_hora_infraccion TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    observaciones_campo TEXT NOT NULL,
    estado_acta VARCHAR(20) NOT NULL DEFAULT 'REGISTRADA',
    motivo_anulacion TEXT NULL,
    anulado_por UUID NULL,
    fecha_anulacion TIMESTAMPTZ NULL,
    CONSTRAINT uq_actas_correlativo UNIQUE (numero_acta_correlativo),
    CONSTRAINT fk_actas_puesto FOREIGN KEY (id_puesto) 
        REFERENCES feria_core.puestos(id_puesto) ON DELETE RESTRICT,
    CONSTRAINT fk_actas_comerciante FOREIGN KEY (id_comerciante) 
        REFERENCES auth_acl.comerciante_perfil(id_comerciante) ON DELETE RESTRICT,
    CONSTRAINT fk_actas_motivo FOREIGN KEY (id_motivo) 
        REFERENCES feria_core.motivos_infraccion(id_motivo) ON DELETE RESTRICT,
    CONSTRAINT fk_actas_fiscalizador FOREIGN KEY (id_fiscalizador) 
        REFERENCES auth_acl.funcionario_perfil(id_funcionario) ON DELETE RESTRICT,
    CONSTRAINT fk_actas_anulador FOREIGN KEY (anulado_por) 
        REFERENCES auth_acl.funcionario_perfil(id_funcionario) ON DELETE RESTRICT,
    CONSTRAINT chk_actas_estado CHECK (estado_acta IN ('REGISTRADA', 'NOTIFICADA', 'EN_DESCARGO', 'PAGADA', 'ANULADA'))
);

-- 14. Evidencias Fotográficas Adjuntas al Acta (FSH-6, FSH-21)
CREATE TABLE IF NOT EXISTS feria_core.evidencias_fotograficas (
    id_evidencia BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_acta UUID NOT NULL,
    ruta_archivo_foto VARCHAR(500) NOT NULL,
    hash_archivo_sha256 VARCHAR(64) NOT NULL,
    capturado_en TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT fk_evidencias_acta FOREIGN KEY (id_acta) 
        REFERENCES feria_core.actas_infraccion(id_acta) ON DELETE CASCADE
);
