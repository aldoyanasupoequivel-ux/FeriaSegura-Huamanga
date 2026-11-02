-- ==============================================================================
-- FERIA SEGURA HUAMANGA (FeriaSegura)
-- Migración 006: Índices y Optimizaciones de Rendimiento
-- Tareas Jira: FSH-14, FSH-29, FSH-32, FSH-33, FSH-36, FSH-37
-- ==============================================================================

-- 1. Regla de Oro (FSH-14, FSH-29): Un DNI solo puede tener 1 postulación/reserva activa por feria
-- Un índice único parcial en PostgreSQL impide que se registre más de una reserva activa
-- para el mismo comerciante en la misma feria, resolviendo la condición de carrera a nivel de motor.
CREATE UNIQUE INDEX IF NOT EXISTS idx_uniq_comerciante_reserva_activa_por_feria
ON feria_core.postulaciones_reservas (id_feria, id_comerciante)
WHERE estado_reserva IN ('RESERVADA', 'EN_EVALUACION_PAGO', 'FORMALIZADA');

-- 2. Optimización para Mapa de Disponibilidad de Puestos (FSH-32: < 500ms)
-- Índice compuesto sobre (id_sector, estado_puesto) con inclusión de columnas
-- para permitir Index-Only Scans sin tocar las páginas de datos de la tabla.
CREATE INDEX IF NOT EXISTS idx_puestos_disponibilidad_cuadricula
ON feria_core.puestos (id_sector, estado_puesto)
INCLUDE (codigo_puesto, posicion_fila, posicion_columna, ancho_metros, largo_metros, es_zona_riesgo);

-- 3. Optimización para Validación de Autorizaciones QR en Campo (FSH-33: < 500ms)
-- Localización instantánea de credencial por el UUID contenido en el código QR físico.
CREATE UNIQUE INDEX IF NOT EXISTS idx_credenciales_codigo_qr_lookup
ON feria_core.credenciales_autorizacion (codigo_qr_identificador)
INCLUDE (id_reserva, estado_autorizacion, fecha_emision);

-- 4. Optimización de Búsqueda de Comerciantes por DNI y Padrón Histórico (FSH-36)
CREATE INDEX IF NOT EXISTS idx_padron_historico_dni_lookup
ON feria_core.padron_historico (dni);

CREATE INDEX IF NOT EXISTS idx_comerciante_perfil_busqueda_dni
ON auth_acl.comerciante_perfil (dni);

-- 5. Índices sobre Claves Foráneas (Previene Sequential Scans en JOINs)
CREATE INDEX IF NOT EXISTS idx_fk_feria_creador 
ON feria_core.ferias (creado_por);

CREATE INDEX IF NOT EXISTS idx_fk_sectores_feria 
ON feria_core.sectores (id_feria);

CREATE INDEX IF NOT EXISTS idx_fk_puestos_sector 
ON feria_core.puestos (id_sector);

CREATE INDEX IF NOT EXISTS idx_fk_reservas_comerciante 
ON feria_core.postulaciones_reservas (id_comerciante);

CREATE INDEX IF NOT EXISTS idx_fk_reservas_puesto 
ON feria_core.postulaciones_reservas (id_puesto);

CREATE INDEX IF NOT EXISTS idx_fk_declaraciones_reserva 
ON feria_core.declaraciones_electricas (id_reserva);

CREATE INDEX IF NOT EXISTS idx_fk_detalles_declaracion 
ON feria_core.detalles_artefactos (id_declaracion);

CREATE INDEX IF NOT EXISTS idx_fk_pagos_reserva 
ON feria_core.pagos_tupa (id_reserva);

CREATE INDEX IF NOT EXISTS idx_fk_actas_puesto 
ON feria_core.actas_infraccion (id_puesto);

CREATE INDEX IF NOT EXISTS idx_fk_actas_comerciante 
ON feria_core.actas_infraccion (id_comerciante);

CREATE INDEX IF NOT EXISTS idx_fk_actas_fiscalizador 
ON feria_core.actas_infraccion (id_fiscalizador);

CREATE INDEX IF NOT EXISTS idx_fk_evidencias_acta 
ON feria_core.evidencias_fotograficas (id_acta);

-- 6. Índices para la Bitácora de Auditoría
CREATE INDEX IF NOT EXISTS idx_audit_log_fecha_hora 
ON audit.audit_log (fecha_hora DESC);

CREATE INDEX IF NOT EXISTS idx_audit_log_usuario 
ON audit.audit_log (id_usuario_responsable);

CREATE INDEX IF NOT EXISTS idx_audit_log_entidad 
ON audit.audit_log (esquema, tabla, id_registro_afectado);
