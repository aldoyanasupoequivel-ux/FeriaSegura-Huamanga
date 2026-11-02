#!/bin/sh
# ==============================================================================
# FERIA SEGURA HUAMANGA (FeriaSegura)
# Script de Inicialización de Base de Datos
# Descripción: Ejecuta las migraciones en orden estricto y los scripts de
#              seguridad. Se invoca automáticamente por docker-entrypoint-initdb.d
#              al crear el contenedor por primera vez.
# ==============================================================================

set -e  # Abortar en caso de cualquier error

export PGPASSWORD="${POSTGRES_PASSWORD}"

echo "============================================================"
echo " FeriaSegura Huamanga — Inicialización de Base de Datos"
echo " PostgreSQL $(psql --version)"
echo "============================================================"

# Función para ejecutar una migración (conexión por socket local del contenedor)
run_migration() {
    FILE="$1"
    LABEL="$2"
    echo ""
    echo ">>> Ejecutando: ${LABEL}"
    psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" -f "/migrations/${FILE}"
    echo "    [OK] ${LABEL} completada."
}

echo ""
echo "─────────────────────────────────────────────────────────"
echo " FASE 1: Infraestructura Base y Esquemas"
echo "─────────────────────────────────────────────────────────"
run_migration "001_create_extensions_and_schemas.sql"  "001 — Extensiones y Esquemas"

echo ""
echo "─────────────────────────────────────────────────────────"
echo " FASE 2: Autenticación Centralizada, RBAC y ACL"
echo "─────────────────────────────────────────────────────────"
run_migration "002_create_auth_and_acl.sql"             "002 — Auth y ACL"

echo ""
echo "─────────────────────────────────────────────────────────"
echo " FASE 3: Dominio Ferial Central"
echo "─────────────────────────────────────────────────────────"
run_migration "003_create_feria_core.sql"               "003 — Dominio Ferial"

echo ""
echo "─────────────────────────────────────────────────────────"
echo " FASE 4: Sistema de Auditoría WORM"
echo "─────────────────────────────────────────────────────────"
run_migration "004_create_audit_system.sql"             "004 — Auditoría WORM"

echo ""
echo "─────────────────────────────────────────────────────────"
echo " FASE 5: Funciones de Negocio y Triggers"
echo "─────────────────────────────────────────────────────────"
run_migration "005_create_functions_and_triggers.sql"   "005 — Funciones y Triggers"

echo ""
echo "─────────────────────────────────────────────────────────"
echo " FASE 6: Índices y Optimizaciones"
echo "─────────────────────────────────────────────────────────"
run_migration "006_create_indexes_and_optimizations.sql" "006 — Índices y Optimizaciones"

echo ""
echo "─────────────────────────────────────────────────────────"
echo " FASE 7: Datos Maestros (Seed)"
echo "─────────────────────────────────────────────────────────"
run_migration "007_seed_initial_data.sql"               "007 — Semilla de Datos Maestros"

echo ""
echo "─────────────────────────────────────────────────────────"
echo " FASE 8: Correcciones de Integridad WORM"
echo "─────────────────────────────────────────────────────────"
run_migration "008_fix_audit_worm_integrity.sql"        "008 — Corrección Integridad WORM"

echo ""
echo "─────────────────────────────────────────────────────────"
echo " FASE 9: Roles de Aplicación y Grants de Seguridad"
echo "─────────────────────────────────────────────────────────"
echo ">>> Aplicando roles y grants..."
psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" -f "/security/roles_and_grants.sql"
echo "    [OK] Roles y grants aplicados."

echo ""
echo "─────────────────────────────────────────────────────────"
echo " FASE 10: Row Level Security (RLS)"
echo "─────────────────────────────────────────────────────────"
run_migration "009_enable_row_level_security.sql"       "009 — Row Level Security"

echo ""
echo "============================================================"
echo " INICIALIZACIÓN COMPLETADA EXITOSAMENTE"
echo " Base de datos: ${POSTGRES_DB}"
echo " Migraciones aplicadas: 001 → 009"
echo " Seguridad RLS + RBAC: ACTIVA"
echo " Auditoría WORM: ACTIVA"
echo " Estado: LISTA PARA PRUEBAS"
echo "============================================================"
