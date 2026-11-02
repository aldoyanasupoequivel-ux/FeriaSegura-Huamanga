# FERIA SEGURA HUAMANGA (FeriaSegura)
## Arquitectura de Base de Datos PostgreSQL y Sistema de Autenticación Centralizada ACL

Este documento contiene la especificación técnica completa, el modelo de datos físico, los mecanismos de concurrencia y las instrucciones de despliegue para la base de datos de **FeriaSegura Huamanga**.

---

## 1. Cobertura de Requerimientos de Jira

| Clave | Tarea / Historia de Jira | Solución Técnica Implementada en PostgreSQL |
| :--- | :--- | :--- |
| **FSH-1** | Zonificación y Catastro Urbano | Esquema `feria_core` con `ferias`, `sectores` y `puestos`. |
| **FSH-2** | Empadronamiento de Comerciantes | Tablas `auth_acl.comerciante_perfil` y `feria_core.padron_historico`. |
| **FSH-3** | Asignación y Reserva de Puestos | `postulaciones_reservas` con función atómica `sp_reservar_puesto_atomico`. |
| **FSH-4** | Control de Seguridad Eléctrica | `declaraciones_electricas`, `artefactos_catalogo` y `detalles_artefactos`. |
| **FSH-5** | Formalización y Pagos TUPA | `pagos_tupa` y credencial oficial con QR `credenciales_autorizacion`. |
| **FSH-6** | Fiscalización en Campo | `actas_infraccion`, `motivos_infraccion` y `evidencias_fotograficas`. |
| **FSH-9** | Bloqueo de Puestos en Riesgo | Puestos con estado `BLOQUEADO` y motivo `HIDRANTE_BOMBEROS` / `SALIDA_EVACUACION`. |
| **FSH-14 / FSH-29** | Regla de Equidad (1 Puesto por DNI) | Índice parcial único `idx_uniq_comerciante_reserva_activa_por_feria`. |
| **FSH-16 / FSH-30** | Límite Eléctrico de 15 kW por Sector | Trigger transaccional `fn_validar_potencia_acumulada_sector` con `FOR UPDATE` sobre el sector. |
| **FSH-22 / FSH-24** | Login Unificado y Cierre de Sesión | Tabla central `auth_acl.usuarios` y revocación de tokens en `auth_acl.sesion_tokens`. |
| **FSH-23 / FSH-27** | Asignación de Roles y ACL | Tablas `roles`, `permisos`, `usuario_roles`, `rol_permisos` y `recurso_acl`. |
| **FSH-26 / FSH-28** | Dimensiones Reglamentarias 2x2m | Restricción estricta `CHECK (ancho_metros = 2.00 AND largo_metros = 2.00)`. |
| **FSH-31** | Auditoría Inmutable (WORM) | Esquema `audit`, tabla `audit_log`, trigger que bloquea `UPDATE`/`DELETE` y auditoría de eventos. |
| **FSH-32** | Consulta de Cuadrícula en < 500 ms | Índice compuesto cubierto `idx_puestos_disponibilidad_cuadricula` (Index-Only Scan). |
| **FSH-33** | Validación de QR en < 500 ms | Índice único cubierto `idx_credenciales_codigo_qr_lookup` (búsqueda en < 5 ms). |
| **FSH-36** | Validación y Unicidad de DNI | Restricciones `CHECK (dni ~ '^[0-9]{8}$')` y `UNIQUE(dni)`. |
| **FSH-37** | Concurrencia y Pool de Conexiones | `max_connections=200`, transacciones pesimistas `SELECT ... FOR UPDATE` para evitar deadlocks. |

---

## 2. Estructura de Esquemas y Tablas

### Esquema `auth_acl`
- `usuarios`: Núcleo de autenticación único (ID, identificador de login, hash de clave, tipo, estado).
- `comerciante_perfil`: DNI (8 dígitos), nombres, apellidos, teléfono, domicilio, estado de padrón.
- `funcionario_perfil`: DNI, nombres, apellidos, cargo, dependencia municipal.
- `roles`, `permisos`, `usuario_roles`, `rol_permisos`: Control de acceso basado en roles (RBAC).
- `recurso_acl`: Control de acceso a nivel de fila y objeto.
- `sesion_tokens`: Registro de sesiones activas e invalidación por cierre de sesión.

### Esquema `feria_core`
- `padron_historico`: Padrón anterior municipal para contraste de registros duplicados.
- `giros_comerciales`: Catálogo de rubros permitidos en ferias temporales.
- `ferias`: Configuración general del evento ferial y fechas de vigencia.
- `sectores`: Delimitación de vías con límite eléctrico fijado por Defensa Civil (15.00 kW).
- `puestos`: Cuadrícula de puestos (2x2 m), estados (`DISPONIBLE`, `RESERVADO`, `ASIGNADO`, `BLOQUEADO`).
- `postulaciones_reservas`: Asignación atómica de puestos por comerciante.
- `pagos_tupa`: Registro del voucher de pago TUPA y validación por Tesorería.
- `credenciales_autorizacion`: Credencial oficial con identificador UUID y firma para código QR.
- `declaraciones_electricas` y `detalles_artefactos`: Declaración jurada de artefactos eléctricos.
- `motivos_infraccion`, `actas_infraccion`, `evidencias_fotograficas`: Fiscalización en vía pública.

### Esquema `audit`
- `audit_log`: Bitácora protegida bajo el estándar WORM (Write Once, Read Many). Los intentos de modificación o eliminación son rechazados a nivel de motor.

---

## 3. Instrucciones de Despliegue Local con Docker

### Paso 1: Iniciar el contenedor de PostgreSQL 16
```powershell
cd c:\Users\Erick\Desktop\feriasegura\database\docker
docker-compose up -d
```
*Las migraciones ubicadas en `../database/migrations` se ejecutarán automáticamente en orden numérico correlativo.*

### Paso 2: Ejecutar manualmente las migraciones (si se usa un PostgreSQL nativo)
```bash
psql -U feriasegura_user -d feriasegura_db -f database/migrations/001_create_extensions_and_schemas.sql
psql -U feriasegura_user -d feriasegura_db -f database/migrations/002_create_auth_and_acl.sql
psql -U feriasegura_user -d feriasegura_db -f database/migrations/003_create_feria_core.sql
psql -U feriasegura_user -d feriasegura_db -f database/migrations/004_create_audit_system.sql
psql -U feriasegura_user -d feriasegura_db -f database/migrations/005_create_functions_and_triggers.sql
psql -U feriasegura_user -d feriasegura_db -f database/migrations/006_create_indexes_and_optimizations.sql
psql -U feriasegura_user -d feriasegura_db -f database/migrations/007_seed_initial_data.sql
```

---

## 4. Ejecución de la Suite de Pruebas

Para validar la integridad referencial, el bloqueo de DNI duplicados, la regla de 1 puesto por DNI, el trigger de 15 kW y la inmutabilidad de la auditoría:

```bash
docker exec -it feriasegura_postgres psql -U feriasegura_user -d feriasegura_db -f /tests/run_all_tests.sql
```
O localmente:
```bash
psql -U feriasegura_user -d feriasegura_db -f database/tests/run_all_tests.sql
```

### Pruebas Individuales Disponibles:
1. `test_unique_dni_and_padron.sql`: Formato exacto de 8 dígitos y unicidad de DNI.
2. `test_concurrency_reserva.sql`: Reserva atómica con bloqueo pesimista y bloqueo de segunda reserva.
3. `test_electrical_power_trigger.sql`: Rechazo transaccional cuando la carga supera los 15 kW.
4. `test_audit_inmutability.sql`: Protección WORM ante `UPDATE`/`DELETE` y auditoría de eventos.
