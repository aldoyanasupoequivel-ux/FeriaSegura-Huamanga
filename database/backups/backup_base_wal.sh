#!/usr/bin/env bash
# ==============================================================================
# FERIA SEGURA HUAMANGA - Base Backup Físico para PITR (FSH-34, FSH-35)
# ==============================================================================
set -euo pipefail

BASE_BACKUP_DIR="${BASE_BACKUP_DIR:-/var/lib/postgresql/backups/base}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TARGET_DIR="${BASE_BACKUP_DIR}/base_${TIMESTAMP}"
LOG_FILE="${BASE_BACKUP_DIR}/base_backup.log"

mkdir -p "${TARGET_DIR}"

echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] INICIANDO BASE BACKUP FÍSICO CON pg_basebackup" | tee -a "${LOG_FILE}"

# Ejecutar pg_basebackup con inclusión de WAL (-X stream) y formato tar comprimido
pg_basebackup -U postgres -D "${TARGET_DIR}" -F t -z -X stream -P 2>> "${LOG_FILE}"

echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [ÉXITO] Base backup completado en ${TARGET_DIR}" | tee -a "${LOG_FILE}"
ls -lh "${TARGET_DIR}" | tee -a "${LOG_FILE}"
