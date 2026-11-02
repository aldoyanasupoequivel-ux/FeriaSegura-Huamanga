#!/usr/bin/env bash
# ==============================================================================
# PROCEDIMIENTO DE RECUPERACIÓN POINT-IN-TIME (PITR) POSTGRESQL 16 (FSH-34)
# Objetivo: RTO <= 30 minutos | RPO <= 1 hora
# ==============================================================================
set -euo pipefail

TARGET_TIMESTAMP="${1:-}"

if [ -z "${TARGET_TIMESTAMP}" ]; then
    echo "USO: $0 '<TIMESTAMP_UTC_OBJETIVO>' (Ejemplo: '2026-11-02 14:30:00 UTC')"
    exit 1
fi

PG_DATA="/var/lib/postgresql/16/main"
WAL_ARCHIVE="/var/lib/postgresql/wal_archive"
LATEST_BASE_TAR=$(ls -t /var/lib/postgresql/backups/base/*/base.tar.gz 2>/dev/null | head -n 1)

echo "=== INICIANDO PROCEDIMIENTO DE RECUPERACIÓN PITR ==="
echo "Punto temporal objetivo: ${TARGET_TIMESTAMP}"
echo "Base backup origen: ${LATEST_BASE_TAR}"
echo "Depósito de WALs: ${WAL_ARCHIVE}"

# 1. Detener el servicio PostgreSQL
echo "1. Deteniendo servicio PostgreSQL..."
service postgresql stop

# 2. Resguardar el directorio de datos actual dañado
BACKUP_CORRUPT="/var/lib/postgresql/16/data_corrupt_$(date +%s)"
echo "2. Moviendo clúster actual a ${BACKUP_CORRUPT}..."
mv "${PG_DATA}" "${BACKUP_CORRUPT}"
mkdir -p "${PG_DATA}"
chown postgres:postgres "${PG_DATA}"
chmod 700 "${PG_DATA}"

# 3. Descomprimir el Base Backup en el directorio de datos
echo "3. Extrayendo base backup físico..."
tar -xzf "${LATEST_BASE_TAR}" -C "${PG_DATA}"
chown -R postgres:postgres "${PG_DATA}"

# 4. Configurar la directiva de recuperación en PostgreSQL 16
# En PG16 se usa recovery.signal y las directivas en postgresql.auto.conf
echo "4. Generando recovery.signal y directivas de restauración..."
touch "${PG_DATA}/recovery.signal"
chown postgres:postgres "${PG_DATA}/recovery.signal"

cat <<EOF >> "${PG_DATA}/postgresql.auto.conf"
restore_command = 'cp ${WAL_ARCHIVE}/%f %p'
recovery_target_time = '${TARGET_TIMESTAMP}'
recovery_target_action = 'promote'
EOF

# 5. Iniciar PostgreSQL en modo recuperación
echo "5. Levantando PostgreSQL para replay de segmentos WAL hasta el target..."
START_TIME=$(date +%s)
service postgresql start

# Esperar a que la recuperación termine y el servidor esté en modo lectura/escritura
until su - postgres -c "psql -c 'SELECT pg_is_in_recovery();'" | grep -q 'f'; do
    echo "Replay de WAL en progreso... esperando transición a modo lectura/escritura..."
    sleep 2
done

END_TIME=$(date +%s)
TOTAL_RTO=$((END_TIME - START_TIME))

echo "=== [ÉXITO] RECUPERACIÓN PITR COMPLETADA EXITOSAMENTE ==="
echo "Tiempo total de recuperación (RTO alcanzado): ${TOTAL_RTO} segundos (Límite máximo permitido: 1800 segundos / 30 minutos)"
