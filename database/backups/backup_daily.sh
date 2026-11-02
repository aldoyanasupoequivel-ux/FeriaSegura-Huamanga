#!/usr/bin/env bash
# ==============================================================================
# FERIA SEGURA HUAMANGA - Respaldo Diario Automatizado (FSH-34)
# ==============================================================================
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/var/lib/postgresql/backups/daily}"
DB_NAME="${DB_NAME:-feriasegura_db}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_backup_${TIMESTAMP}.dump"
LOG_FILE="${BACKUP_DIR}/backup_execution.log"

mkdir -p "${BACKUP_DIR}"

echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] INICIANDO RESPALDO DIARIO: Base de datos ${DB_NAME}" | tee -a "${LOG_FILE}"

# Ejecutar pg_dump en formato binario comprimido con checksums
pg_dump -U postgres -d "${DB_NAME}" -F c -b -v -f "${BACKUP_FILE}" 2>> "${LOG_FILE}"

# Verificar integridad del archivo generado mediante pg_restore --list
if pg_restore -l "${BACKUP_FILE}" > /dev/null 2>&1; then
    BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [ÉXITO] Respaldo verificado correctamente. Archivo: ${BACKUP_FILE} (${BACKUP_SIZE})" | tee -a "${LOG_FILE}"
else
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [ERROR] El archivo de respaldo generado no pasó la prueba de integridad." | tee -a "${LOG_FILE}"
    exit 1
fi

# Rotación de respaldos: Conservar los últimos 7 días
find "${BACKUP_DIR}" -name "${DB_NAME}_backup_*.dump" -type f -mtime +7 -delete
echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Rotación completada. Respaldos antiguos depurados." | tee -a "${LOG_FILE}"
