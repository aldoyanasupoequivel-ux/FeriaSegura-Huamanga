-- ==============================================================================
-- FERIA SEGURA HUAMANGA (FeriaSegura)
-- Ejecutor Maestro de Suite Completa de Pruebas de Base de Datos
-- Cobertura: Integridad, Concurrencia, Seguridad ACL/RLS, Auditoría WORM
-- ==============================================================================

\set ON_ERROR_STOP on

SELECT '================================================================' AS sep;
SELECT '  FERIA SEGURA — SUITE COMPLETA DE PRUEBAS DE BASE DE DATOS   ' AS header;
SELECT '================================================================' AS sep;
SELECT clock_timestamp() AS inicio_suite;

-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE 1: PRUEBAS DE INTEGRIDAD Y REGLAS DE NEGOCIO
-- ─────────────────────────────────────────────────────────────────────────────
SELECT '>>> BLOQUE 1: Integridad — Unicidad DNI y Padrón Histórico <<<' AS test_group;
\ir test_unique_dni_and_padron.sql

SELECT '>>> BLOQUE 2: Concurrencia — Reserva Atómica de Puestos <<<' AS test_group;
\ir test_concurrency_reserva.sql

SELECT '>>> BLOQUE 3: Control Eléctrico — Potencia Máxima por Sector <<<' AS test_group;
\ir test_electrical_power_trigger.sql

SELECT '>>> BLOQUE 4: Auditoría — Inmutabilidad WORM <<<' AS test_group;
\ir test_audit_inmutability.sql

-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE 2: PRUEBAS DE SEGURIDAD ACL Y RLS
-- ─────────────────────────────────────────────────────────────────────────────
SELECT '>>> BLOQUE 5: Seguridad — ACL, RLS y Roles de Aplicación <<<' AS test_group;
\ir ../security/test_acl_enforcement.sql

SELECT '>>> BLOQUE 6: Seguridad — Defensa contra Suplantación de Identidad <<<' AS test_group;
\ir ../security/test_impersonation_defense.sql

SELECT '>>> BLOQUE 7: Seguridad — Auditoría WORM y FK RESTRICT <<<' AS test_group;
\ir ../security/test_audit_security.sql

-- ─────────────────────────────────────────────────────────────────────────────
-- RESULTADO FINAL
-- ─────────────────────────────────────────────────────────────────────────────
SELECT clock_timestamp() AS fin_suite;
SELECT '================================================================' AS sep;
SELECT '  TODAS LAS PRUEBAS PASARON EXITOSAMENTE — BASE DE DATOS OK   ' AS resultado_final;
SELECT '================================================================' AS sep;
