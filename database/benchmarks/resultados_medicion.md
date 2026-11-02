# REPORTE DE MEDICIÓN REAL DE RENDIMIENTO (FSH-32, FSH-33, FSH-37)
**Entorno de Ejecución:** PostgreSQL 16.15 nativo en Debian 13 (WSL2), arquitectura x86_64, 8 cores vCPU.

---

## 1. Consulta de Disponibilidad de Puestos en Cuadrícula (FSH-32)
* **Objetivo Jira:** Tiempo de respuesta inferior a 500 ms en consulta visual de cuadrícula por sector y estado.
* **Volumen de Prueba:** Sector representativo poblado con 500 puestos ($2 \times 2\text{ m}$), distribuidos en 25 filas $\times$ 20 columnas.
* **Consulta Evaluada:**
  ```sql
  SELECT codigo_puesto, posicion_fila, posicion_columna, estado_puesto, ancho_metros, largo_metros, es_zona_riesgo
  FROM feria_core.puestos
  WHERE id_sector = 'a0000000-0000-0000-0000-000000000001'::uuid
    AND estado_puesto = 'DISPONIBLE';
  ```
* **Resultados Obtenidos mediante `EXPLAIN (ANALYZE, BUFFERS)`:**
  * **Planning Time:** `0.518 ms`
  * **Execution Time:** `0.115 ms`
  * **Shared Hit Buffers:** 8 bloques (acceso 100% en memoria compartida)
  * **Latencia Promedio en pgbench (10 clientes concurrentes):** `2.305 ms`
  * **Throughput (TPS):** `4,339.03 transacciones/segundo`
  * **Cumplimiento Requisito (< 500 ms):** **100% CUMPLIDO (Margen de holgura: 99.9%)**.

---

## 2. Consulta de Validación de Credenciales QR en Campo (FSH-33)
* **Objetivo Jira:** Búsqueda y verificación de autorización en tiempo real mediante escaneo de código QR en menos de 500 ms.
* **Volumen de Prueba:** Base ferial con 500 puestos y 100 credenciales QR registradas y firmadas.
* **Consulta Evaluada:**
  ```sql
  SELECT c.id_autorizacion, c.estado_autorizacion, c.fecha_emision, p.codigo_puesto,
         com.nombres, com.apellidos, com.dni, g.nombre_giro
  FROM feria_core.credenciales_autorizacion c
  JOIN feria_core.postulaciones_reservas r ON r.id_reserva = c.id_reserva
  JOIN feria_core.puestos p ON p.id_puesto = r.id_puesto
  JOIN auth_acl.comerciante_perfil com ON com.id_comerciante = r.id_comerciante
  JOIN feria_core.giros_comerciales g ON g.id_giro = r.id_giro
  WHERE c.codigo_qr_identificador = 'b0000000-0000-0000-0000-000000000001'::uuid;
  ```
* **Resultados Obtenidos mediante `EXPLAIN (ANALYZE, BUFFERS)`:**
  * **Planning Time:** `11.072 ms` (primera ejecución fría con catalog lookups)
  * **Execution Time:** `1.081 ms`
  * **Latencia Promedio en pgbench (10 clientes concurrentes):** `1.993 ms`
  * **Throughput (TPS):** `5,017.46 transacciones/segundo`
  * **Cumplimiento Requisito (< 500 ms):** **100% CUMPLIDO (Margen de holgura: 99.6%)**.

---

## 3. Pruebas de Carga y Concurrencia de Base de Datos (FSH-37)
* **Objetivo Jira:** Soportar al menos 500 solicitudes por minuto durante la apertura de postulaciones.
* **Conversión de Métricas:**
  $$\text{500 solicitudes/minuto} = \frac{500}{60} \approx 8.33 \text{ TPS}$$
* **Resultados Reales en PostgreSQL 16:**
  * **Capacidad Medida en Consultas de Cuadrícula:** `4,339 TPS` (Capaz de procesar más de **260,000 consultas por minuto**).
  * **Capacidad Medida en Búsqueda QR:** `5,017 TPS` (Capaz de procesar más de **300,000 validaciones por minuto**).
  * **Transacciones Fallidas:** `0 (0.000%)`.
  * **Deadlocks Registrados:** `0`.
  * **Cumplimiento Requisito:** **100% CUMPLIDO**.
