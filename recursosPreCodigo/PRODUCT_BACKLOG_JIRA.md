# GUÍA MAESTRA DEL LABORATORIO 03: SIMULACIÓN DE SPRINT EN JIRA

**Proyecto:** FeriaSegura Huamanga (FSH)  
**Curso:** Construcción y Evolución de Software (Semestre 2026-II)  
**Equipo de Desarrollo:**
* **Aldo Marcos Yanasupo Esquivel** (Product Owner / Dev 1)
* **Jhover Erickson Vasquez Quispe** (Scrum Master / Dev 2)
* **Edson Huaman Huacre** (Developer / Dev 3)
* **Erik Hernando Ayala Cisneros** (Developer / Dev 4)

---

# ACTIVIDAD A2: CONFIGURACIÓN DEL ESPACIO Y TABLERO EN JIRA

1. **Crear espacio:** Seleccionar plantilla **Scrum** (no Kanban).
2. **Datos del proyecto:**
   * **Nombre:** `FeriaSegura Huamanga – Equipo 01` *(o el número asignado)*
   * **Clave del espacio:** `FSH` *(las incidencias se numerarán como FSH-1, FSH-2, etc.)*
   * **Propietario:** Jhover Erickson Vasquez Quispe (Scrum Master).
3. **Acceso:** Invitar a los 3 integrantes y al docente con sus correos.
4. **Configuración de Columnas del Tablero:**
   * En la pestaña **Tablero**, agregar con el botón `+` la columna **`EN REVISIÓN`** entre `EN CURSO` y `LISTO`.
   * *Flujo de trabajo:*
     * `POR HACER`: Historia comprometida en el Sprint, aún sin iniciar.
     * `EN CURSO`: Se está desarrollando en su rama `feature/...`.
     * `EN REVISIÓN`: Pull Request abierto en GitHub esperando aprobación de un compañero.
     * `LISTO`: PR integrado a `main`, pruebas unitarias pasando y DoD cumplida.

---

# ACTIVIDAD A3: CONSTRUIR EL PRODUCT BACKLOG

## Paso 1: Crear las Tres Épicas del Sistema
En Jira (**Crear incidencia** > Tipo: **Épica**):

| Clave | Épica | Descripción |
| :---: | :--- | :--- |
| **`FSH-1`** | **Catastro y Zonificación de Vías** | Registro y administración de ferias, delimitación de avenidas y visualización de puestos numerados con estados en tiempo real. |
| **`FSH-2`** | **Registro, Postulación y Demanda Eléctrica** | Empadronamiento de comerciantes con DNI único, postulación concurrente a puestos y control de capacidad máxima de energía eléctrica (kW). |
| **`FSH-3`** | **Formalización y Fiscalización Móvil QR** | Validación de pagos de tasas TUPA, emisión de credencial oficial en PDF con código QR y fiscalización móvil en calle con actas de infracción. |

---

## Paso 2: Crear las Historias y la Tarea Técnica con Criterios Dado – Cuando – Entonces

### Tabla Resumen del Backlog

| Clave | Tipo | Historia de Usuario / Tarea | Épica (*Parent*) |
| :---: | :---: | :--- | :---: |
| **`FSH-4`** | **Tarea** | Configurar el repositorio monorepo, pipeline de CI en GitHub Actions, contenedor Docker de PostgreSQL y entorno de pruebas unitarias con Jest y coverage. | — |
| **`FSH-5`** | **Historia** | Como Administrador Municipal, quiero registrar una feria con sus avenidas, sectores y puestos numerados (2x2 m), para organizar el espacio público disponible. | `FSH-1` |
| **`FSH-6`** | **Historia** | Como Administrador Municipal, quiero inhabilitar o bloquear puestos en zonas restringidas, para garantizar el acceso libre a hidrantes de bomberos y salidas de evacuación. | `FSH-1` |
| **`FSH-7`** | **Historia** | Como comerciante ambulante, quiero registrarme en el portal con mi DNI y datos de contacto, para empadronarme formalmente en el sistema. | `FSH-2` |
| **`FSH-8`** | **Historia** | Como comerciante empadronado, quiero postular a un puesto disponible en el mapa, para asegurar mi lugar de venta en la feria. | `FSH-2` |
| **`FSH-9`** | **Historia** | Como comerciante, quiero recibir un mensaje claro de advertencia si el puesto ya fue tomado por otro usuario o si ya cuento con una postulación activa, para respetar la regla de 1 puesto por DNI. | `FSH-2` |
| **`FSH-10`** | **Historia** | Como inspector de Defensa Civil, quiero que el sistema bloquee automáticamente solicitudes con energía cuando el sector supere los 15 kW, para prevenir sobrecargas eléctricas e incendios. | `FSH-2` |
| **`FSH-11`** | **Historia** | Como comerciante, quiero adjuntar el comprobante o número de operación de la tasa municipal TUPA, para validar mi derecho de uso de vía pública. | `FSH-3` |
| **`FSH-12`** | **Historia** | Como comerciante con pago aprobado, quiero descargar mi Ficha Municipal con Código QR único en formato PDF, para exhibirla obligatoriamente en mi puesto físico. | `FSH-3` |
| **`FSH-13`** | **Historia** | Como fiscalizador municipal, quiero escanear el código QR del puesto con mi celular, para verificar en tiempo real si el titular, puesto y giro comercial están autorizados. | `FSH-3` |
| **`FSH-14`** | **Historia** | Como fiscalizador municipal, quiero registrar un acta de infracción con motivo y evidencia fotográfica desde mi celular, para sancionar irregularidades detectadas en campo. | `FSH-3` |
| **`FSH-15`** | **Historia** | Como Administrador Municipal, quiero ver un reporte consolidado de puestos ocupados, demanda eléctrica acumulada, recaudación de pagos e infracciones por sector, para evaluar el estado integral de la feria. | `FSH-1` / `FSH-2` / `FSH-3` |

---

### Detalle de Criterios de Aceptación para Jira (Camino Feliz y Caso Borde)

#### `FSH-5`: Registrar feria y puestos numerados
> **Como** Administrador Municipal, **quiero** registrar una feria con sus avenidas, sectores y puestos numerados (2x2 m), **para** organizar el espacio público disponible.
* **Criterio 1 (camino feliz)**  
  *Dado* que el administrador ingresa al módulo de catastro con credenciales válidas  
  *Cuando* registra la feria en la Av. Mariscal Cáceres y genera 50 puestos de 2x2 m  
  *Entonces* los puestos se crean con códigos `PUESTO-01`, `PUESTO-02` hasta `PUESTO-50` con estado inicial `DISPONIBLE`
* **Criterio 2 (caso borde)**  
  *Dado* que ya existe registrado el `PUESTO-01` en ese sector  
  *Cuando* el administrador intenta crear manualmente otro puesto con el mismo código `PUESTO-01`  
  *Entonces* el sistema rechaza la operación e informa *"El código de puesto ya se encuentra registrado"*

---

#### `FSH-6`: Bloqueo de puestos por seguridad
> **Como** Administrador Municipal, **quiero** inhabilitar o bloquear puestos en zonas restringidas, **para** garantizar el acceso libre a hidrantes de bomberos y salidas de evacuación.
* **Criterio 1 (camino feliz)**  
  *Dado* un puesto `PUESTO-12` ubicado frente a una toma de agua para bomberos con estado `DISPONIBLE`  
  *Cuando* el administrador selecciona el puesto y activa la opción "Bloquear por Seguridad"  
  *Entonces* el estado cambia a `BLOQUEADO` y el puesto se muestra deshabilitado en el mapa
* **Criterio 2 (caso borde)**  
  *Dado* un puesto `PUESTO-05` que ya se encuentra en estado `ASIGNADO` a un comerciante  
  *Cuando* el administrador intenta bloquearlo directamente sin reubicar al comerciante  
  *Entonces* el sistema advierte *"No se puede bloquear un puesto asignado; debe reubicar al titular previamente"*

---

#### `FSH-7`: Empadronamiento de comerciante con DNI único
> **Como** comerciante ambulante, **quiero** registrarme en el portal con mi DNI y datos de contacto, **para** empadronarme formalmente en el sistema.
* **Criterio 1 (camino feliz)**  
  *Dado* un comerciante con DNI `45871234` de 8 dígitos numéricos no registrado previamente  
  *Cuando* completa sus nombres, apellidos, teléfono y giro comercial y presiona "Registrarme"  
  *Entonces* la cuenta se crea exitosamente con rol `COMERCIANTE` y le permite iniciar sesión
* **Criterio 2 (caso borde)**  
  *Dado* que el DNI `45871234` ya tiene una cuenta registrada en el sistema  
  *Cuando* otra persona intenta registrarse con ese mismo número de DNI  
  *Entonces* el sistema impide el registro e informa *"El DNI ingresado ya cuenta con un registro activo"*

---

#### `FSH-8`: Postulación a puesto disponible
> **Como** comerciante empadronado, **quiero** postular a un puesto disponible en el mapa, **para** asegurar mi lugar de venta en la feria.
* **Criterio 1 (camino feliz)**  
  *Dado* el `PUESTO-08` con estado `DISPONIBLE`  
  *Cuando* el comerciante autenticado lo selecciona y confirma su postulación  
  *Entonces* el puesto cambia a estado `RESERVADO` a su nombre con un plazo de 24 horas para pago
* **Criterio 2 (caso borde)**  
  *Dado* dos comerciantes intentando postular al `PUESTO-08` en el mismo milisegundo  
  *Cuando* el sistema procesa ambas peticiones concurrentes mediante bloqueo pesimista en base de datos  
  *Entonces* el primer comerciante obtiene la reserva y al segundo se le informa *"El puesto acaba de ser seleccionado por otro usuario; por favor elija otro puesto"*

---

#### `FSH-9`: Control anti-acaparamiento (1 puesto por DNI)
> **Como** comerciante, **quiero** recibir un mensaje claro de advertencia si intento postular a más de un espacio, **para** respetar la regla de 1 puesto por DNI y evitar conflictos.
* **Criterio 1 (camino feliz)**  
  *Dado* un comerciante que no tiene ninguna postulación previa  
  *Cuando* postula a un puesto disponible  
  *Entonces* el sistema aprueba la reserva sin restricciones
* **Criterio 2 (caso borde)**  
  *Dado* un comerciante que ya tiene el `PUESTO-08` en estado `RESERVADO` o `ASIGNADO`  
  *Cuando* intenta postular a un segundo puesto `PUESTO-15`  
  *Entonces* el sistema bloquea la acción con el mensaje *"Límite alcanzado: Solo se permite una postulación por número de DNI"*

---

#### `FSH-10`: Control de sobrecarga eléctrica (tope 15 kW por sector)
> **Como** inspector de Defensa Civil, **quiero** que el sistema bloquee automáticamente solicitudes con energía cuando el sector supere los 15 kW, **para** prevenir sobrecargas eléctricas e incendios.
* **Criterio 1 (camino feliz)**  
  *Dado* un sector con carga eléctrica acumulada de 12 kW sobre un límite de 15 kW  
  *Cuando* un comerciante postula solicitando luz con artefactos que suman 1.5 kW  
  *Entonces* el sistema acepta la solicitud y actualiza la carga acumulada del sector a 13.5 kW
* **Criterio 2 (caso borde)**  
  *Dado* un sector con carga acumulada de 14.5 kW  
  *Cuando* un comerciante postula solicitando luz con artefactos que suman 1.0 kW (totalizaría 15.5 kW)  
  *Entonces* el sistema rechaza la opción eléctrica con el mensaje *"Capacidad eléctrica máxima del sector alcanzada por normas de Defensa Civil. Solo puede postular en modalidad sin fluido eléctrico"*

---

#### `FSH-11`: Carga y validación de pagos TUPA
> **Como** comerciante, **quiero** adjuntar el comprobante o número de operación de la tasa municipal TUPA, **para** validar mi derecho de uso de vía pública.
* **Criterio 1 (camino feliz)**  
  *Dado* un puesto en estado `RESERVADO`  
  *Cuando* el comerciante sube la imagen de su voucher de pago e ingresa el código de operación  
  *Entonces* la solicitud pasa al estado `PAGO_EN_REVISION` para el personal de Tesorería
* **Criterio 2 (caso borde)**  
  *Dado* que el comerciante no sube el comprobante de pago dentro de las 24 horas de vigencia  
  *Cuando* expira el plazo límite  
  *Entonces* el sistema cancela automáticamente la reserva y el puesto vuelve a estado `DISPONIBLE`

---

#### `FSH-12`: Emisión de Ficha Municipal con Código QR en PDF
> **Como** comerciante con pago aprobado, **quiero** descargar mi Ficha Municipal con Código QR único en formato PDF, **para** exhibirla obligatoriamente en mi puesto físico.
* **Criterio 1 (camino feliz)**  
  *Dado* que la solicitud del comerciante está en estado `APROBADO`  
  *Cuando* hace clic en "Descargar Autorización"  
  *Entonces* se descarga un documento PDF oficial con sello municipal, datos del titular, número de puesto y un código QR criptográfico firmado
* **Criterio 2 (caso borde)**  
  *Dado* que la solicitud está en estado `PAGO_EN_REVISION` o `RESERVADO`  
  *Cuando* el comerciante intenta acceder al enlace de descarga  
  *Entonces* el sistema bloquea la descarga e informa *"La credencial solo está disponible cuando el pago ha sido validado"*

---

#### `FSH-13`: Fiscalización móvil con lector QR
> **Como** fiscalizador municipal, **quiero** escanear el código QR del puesto con mi celular, **para** verificar en tiempo real si el titular, puesto y giro comercial están autorizados.
* **Criterio 1 (camino feliz)**  
  *Dado* un fiscalizador que enfoca con la cámara de su smartphone el código QR de un puesto autorizado  
  *Cuando* la aplicación decodifica el token  
  *Entonces* la pantalla muestra un marco verde con estado `AUTORIZADO`, nombre del titular, DNI, giro de venta y estado de servicio eléctrico
* **Criterio 2 (caso borde)**  
  *Dado* que se escanea un código QR adulterado, vencido o no registrado en la base de datos  
  *Cuando* el sistema consulta al servidor  
  *Entonces* la pantalla emite una alerta visual en rojo con el mensaje *"AUTORIZACIÓN NO VÁLIDA O INEXISTENTE"*

---

#### `FSH-14`: Registro móvil de actas de infracción
> **Como** fiscalizador municipal, **quiero** registrar un acta de infracción con motivo y evidencia fotográfica desde mi celular, **para** sancionar irregularidades detectadas en campo.
* **Criterio 1 (camino feliz)**  
  *Dado* que el fiscalizador detecta una infracción en el puesto (ej. venta no autorizada de pirotécnicos)  
  *Cuando* selecciona el tipo de falta, escribe una observación y toma una fotografía como evidencia  
  *Entonces* el acta se guarda de inmediato vinculada al expediente del comerciante y notifica a la administración municipal
* **Criterio 2 (caso borde)**  
  *Dado* que el fiscalizador intenta registrar un acta sin seleccionar un tipo de falta tipificada  
  *Cuando* presiona el botón "Guardar Acta"  
  *Entonces* el sistema le exige seleccionar obligatoriamente al menos una infracción del catálogo municipal

---

#### `FSH-15`: Reporte consolidado de la feria (Candidata a dividir en A4)
> **Como** Administrador Municipal, **quiero** ver un reporte consolidado de puestos ocupados, demanda eléctrica acumulada, recaudación de pagos e infracciones por sector, **para** evaluar el estado integral de la feria.
* **Criterio 1 (camino feliz)**  
  *Dado* que el administrador accede al módulo general de reportes  
  *Cuando* consulta un sector de la feria  
  *Entonces* visualiza un resumen consolidado con porcentaje de ocupación, total de kW consumidos, monto total recaudado y cantidad de actas de infracción
* **Criterio 2 (caso borde)**  
  *Dado* un sector recién creado sin puestos asignados ni datos de pago  
  *Cuando* el administrador genera el reporte  
  *Entonces* el sistema muestra el reporte con métricas en cero sin generar errores de división o consulta

---

## Paso 3: Orden del Backlog en Jira (Priorización)

En la pestaña **Backlog**, arrastrar las tarjetas en este orden de prioridad:
1. ⬆️ **`FSH-4`** (Tarea: Setup del repositorio, CI, Docker y pruebas Jest)
2. ⬆️ **`FSH-5`** (Creación de ferias y puestos numerados)
3. ⬆️ **`FSH-6`** (Bloqueo de puestos en zonas de hidrantes)
4. ⬆️ **`FSH-7`** (Empadronamiento de comerciantes con DNI único)
5. ⬆️ **`FSH-10`** (Regla de tope de 15 kW por sector)
6. ⬆️ **`FSH-8`** (Postulación a puestos disponibles)
7. ⬆️ **`FSH-9`** (Control de concurrencia y 1 puesto por DNI)
8. ⬆️ **`FSH-11`** (Carga y validación de pago TUPA)
9. ⬆️ **`FSH-12`** (Emisión de Ficha Municipal con QR en PDF)
10. ⬆️ **`FSH-13`** (Lector QR móvil para Serenazgo)
11. ⬆️ **`FSH-14`** (Registro de actas de infracción en campo)
12. ⬇️ **`FSH-15`** (Reporte consolidado general — candidata a A4)

---

# ACTIVIDAD A4: REFINAMIENTO Y ESTIMACIÓN CON PLANNING POKER

## Paso 1: Verificación de la Definition of Ready (DoR)
Antes de estimar, se verifica que cada historia cumpla:
1. Formato *Como - quiero - para* asociada a una épica.
2. Al menos dos criterios de aceptación en *Dado - Cuando - Entonces* (camino feliz y caso borde).
3. No depende de otra historia que no esté terminada o incluida en el mismo Sprint.
4. El equipo la entiende lo suficiente y su estimación es de 8 puntos o menos.

---

## Paso 2: Rondas de Planning Poker con Discusión y Consenso
*(Requisito de rúbrica: Registrar en tabla al menos 2 historias con más de una ronda de votación y la discusión que las hizo converger)*

| Ronda | Dev 1 (Aldo) | Dev 2 (Jhover) | Dev 3 (Edson) | Dev 4 (Erik) | Discusión del Equipo |
| :---: | :---: | :---: | :---: | :---: | :--- |
| **FSH-8 (Ronda 1)** | 3 | 5 | 5 | 13 | Dev 4 votó 13 pensando que incluía el frontend del mapa interactivo completo y pasarelas de pago. El PO (Aldo) aclara que en esta historia solo se construye la lógica de dominio del backend y el bloqueo pesimista en PostgreSQL. Dev 1 votó 3 porque ya existe la entidad Puesto, pero Dev 2 y 3 recuerdan que las pruebas de concurrencia simultánea tienen casos borde complejos. |
| **FSH-8 (Ronda 2)** | 5 | 5 | 5 | 5 | **Consenso: 5 puntos.** |
| **FSH-10 (Ronda 1)** | 2 | 5 | 3 | 8 | Dev 4 votó 8 asumiendo que se integraba con medidores de luz IoT físicos en tiempo real. Dev 2 (Scrum Master) aclara que es un cálculo de reglas de negocio en base de datos basado en los artefactos declarados por el comerciante frente al tope de 15 kW. Dev 1 votó 2 pensando que era solo un campo `if`, pero Dev 3 recuerda que hay que escribir un Trigger o servicio que sume la potencia de todos los puestos del sector. |
| **FSH-10 (Ronda 2)** | 3 | 3 | 3 | 3 | **Consenso: 3 puntos.** |

---

## Paso 3: División de la Historia Grande (FSH-15)
Al estimar **`FSH-15`** (Reporte consolidado), el equipo votó **13 / ?** porque viola la **I (Independiente)** y la **S (Pequeña)** de INVEST al depender de 3 épicas a la vez. Se divide en dos historias verticales e independientes:

* **`FSH-15a` (Historia - 3 puntos):**  
  > *Como Administrador Municipal, quiero consultar el reporte de ocupación de puestos y total recaudado por sector, para evaluar el avance comercial de la feria.*  
  *(Depende solo de Catastro y Pagos).*
* **`FSH-15b` (Historia - 3 puntos):**  
  > *Como Jefe de Serenazgo, quiero consultar el consolidado de actas de infracción registradas por sector, para planificar los operativos en las zonas con más faltas.*  
  *(Depende solo de Fiscalización).*

---

## Tabla Completa de Estimaciones Finales (Story Points)

| Clave | Resumen de la Incidencia | Puntos | Justificación Técnica Breve |
| :---: | :--- | :---: | :--- |
| **`FSH-4`** | Configurar repositorio, CI y pruebas | **2** | Tarea técnica conocida, configuración inicial con Jest y GitHub Actions. |
| **`FSH-5`** | Registrar feria y puestos numerados | **2** | Creación de entidad y generación masiva de registros en BD. |
| **`FSH-6`** | Bloqueo de puestos por seguridad | **1** | Método consultor que actualiza un estado a `BLOQUEADO`. |
| **`FSH-7`** | Empadronamiento de comerciantes (DNI único) | **3** | Formulario con validación estricta de DNI y manejo de duplicados. |
| **`FSH-10`**| Control de sobrecarga eléctrica (15 kW) | **3** | Lógica de cálculo acumulativo de potencia y validación de tope. |
| **`FSH-8`** | Postulación concurrente a puesto | **5** | Transacciones ACID, bloqueo pesimista en PostgreSQL y pruebas concurrentes. |
| **`FSH-9`** | Control anti-acaparamiento (1 puesto x DNI) | **2** | Regla de negocio con validación condicional y mensaje claro al usuario. |
| **`FSH-11`**| Carga y validación de pagos TUPA | **3** | Subida de archivos (voucher) y flujo de cambio de estado. |
| **`FSH-12`**| Emisión de Ficha con Código QR en PDF | **3** | Librería de generación de PDF e incrustación de QR firmado. |
| **`FSH-13`**| Fiscalización móvil con lector QR | **5** | Componente visual móvil, acceso a cámara y consulta REST API. |
| **`FSH-14`**| Registro móvil de actas con fotos | **3** | Formulario móvil con captura de fotos y tipificación de faltas. |
| **`FSH-15a`**| Reporte de ocupación y recaudación | **3** | Consultas agrupadas (GROUP BY) en base de datos. |
| **`FSH-15b`**| Consolidado de infracciones por sector | **3** | Vista analítica de actas registradas por inspector. |

---

# ACTIVIDAD A5: DEFINITION OF DONE Y PLANIFICACIÓN DEL SPRINT 1

## Paso 1: Definition of Done (DoD) Acordada
Publicada en `CONTRIBUTING.md` y en la descripción del espacio de Jira:
1. Código en rama `feature/FSH-XX-descripcion` e integrado a `main` mediante PR.
2. Cada criterio de aceptación tiene al menos una prueba unitaria pasando en verde.
3. Cobertura de código nuevo >= 80% en pruebas automatizadas.
4. Código respeta ESLint/Prettier y no presenta *code smells* evidentes.
5. PR aprobado por al menos un compañero distinto al autor con comentarios resueltos.
6. `main` compila y ejecuta todas las pruebas en verde tras el merge.
7. Clases y métodos documentados con JSDoc.

---

## Paso 2: Cálculo de Capacidad del Equipo (Sprint de 2 semanas)

| Integrante | Rol | Horas efectivas por semana | Semanas | Horas disponibles |
| :--- | :--- | :---: | :---: | :---: |
| **Dev 1 (Aldo Yanasupo)** | Product Owner / Dev | 5 h | 2 | 10 h |
| **Dev 2 (Jhover Vasquez)** | Scrum Master / Dev | 5 h | 2 | 10 h |
| **Dev 3 (Edson Huaman)** | Developer | 6 h | 2 | 12 h |
| **Dev 4 (Erik Ayala)** | Developer | 6 h | 2 | 12 h |
| **Total del Equipo** | | | | **44 horas** |
| **Compromiso (~75%)** | *(Margen para imprevistos y revisiones)* | | | **~33 horas** |

---

## Paso 3: Sprint Planning del Sprint 1

### 1. Objetivo del Sprint 1 (*Sprint Goal*):
> *"Permitir que la municipalidad configure el catastro de puestos en la avenida y que un comerciante empadronado pueda postular a un espacio con control de carga eléctrica de forma concurrente, con la lógica de dominio validada por pruebas unitarias."*

### 2. Historias seleccionadas para el Sprint 1:
Se arrastran al Sprint 1 las incidencias que cumplen directamente el objetivo (**Total: 18 Story Points**):
* **`FSH-4`** (2 pts) - Setup del repositorio, CI y entorno de pruebas.
* **`FSH-5`** (2 pts) - Configuración de feria y puestos numerados.
* **`FSH-6`** (1 pto) - Bloqueo de puestos por seguridad/hidrantes.
* **`FSH-7`** (3 pts) - Empadronamiento de comerciantes con DNI único.
* **`FSH-10`** (3 pts) - Control de sobrecarga eléctrica (tope 15 kW).
* **`FSH-8`** (5 pts) - Postulación concurrente a puesto disponible.
* **`FSH-9`** (2 pts) - Control anti-acaparamiento (1 puesto por DNI).

*(Las historias de pagos TUPA, emisión de PDF QR y fiscalización móvil quedan para el Sprint 2).*

> **💡 Pregunta clave del docente:**  
> *¿Por qué `FSH-11` o `FSH-13` (Fiscalización con QR) no entran al Sprint 1 aunque el equipo tuviese horas libres?*  
> **Respuesta:** Porque el compromiso de Scrum se basa en el **Objetivo del Sprint**, no en llenar la capacidad al 100%. Meter historias de fiscalización desconectaría el foco del equipo, que en el Sprint 1 es consolidar el núcleo de catastro y postulación segura.

---

### 3. Descomposición de Historias en Subtareas (Máximo 4 horas por subtarea)

En Jira, dentro de cada historia del Sprint 1, crear las siguientes subtareas:

* **Para `FSH-4` (Setup):**
  * Subtarea 4.1: Configurar monorepo y contenedor Docker de PostgreSQL (3 h)
  * Subtarea 4.2: Configurar Jest con reporte de cobertura y GitHub Actions (3 h)
* **Para `FSH-5` (Puestos numerados):**
  * Subtarea 5.1: Escribir pruebas unitarias de creación masiva de puestos (2 h)
  * Subtarea 5.2: Implementar servicio de catastro y validación de códigos duplicados (3 h)
  * Subtarea 5.3: Abrir y atender PR en GitHub (1 h)
* **Para `FSH-6` (Bloqueo de puestos):**
  * Subtarea 6.1: Escribir pruebas unitarias del método de bloqueo de puestos (1 h)
  * Subtarea 6.2: Implementar cambio de estado a BLOQUEADO y validación de puestos asignados (2 h)
  * Subtarea 6.3: Abrir y atender PR en GitHub (1 h)
* **Para `FSH-7` (Empadronamiento):**
  * Subtarea 7.1: Escribir pruebas unitarias para validación de DNI de 8 dígitos (2 h)
  * Subtarea 7.2: Implementar registro de usuario y control de DNI duplicado (3 h)
  * Subtarea 7.3: Abrir y atender PR en GitHub (1 h)
* **Para `FSH-10` (Demanda eléctrica):**
  * Subtarea 10.1: Escribir pruebas unitarias para el cálculo de potencia y tope de 15 kW (2 h)
  * Subtarea 10.2: Implementar regla de negocio de rechazo por sobrecarga de sector (3 h)
  * Subtarea 10.3: Abrir y atender PR en GitHub (1 h)
* **Para `FSH-8` (Postulación concurrente):**
  * Subtarea 8.1: Escribir pruebas unitarias de reserva de puesto y casos borde (3 h)
  * Subtarea 8.2: Implementar servicio de asignación con bloqueo transaccional en PostgreSQL (4 h)
  * Subtarea 8.3: Abrir y atender PR en GitHub (1 h)
* **Para `FSH-9` (Anti-acaparamiento):**
  * Subtarea 9.1: Escribir pruebas de validación de 1 puesto máximo por DNI (2 h)
  * Subtarea 9.2: Implementar mensaje de error ante intento de segunda reserva (2 h)
  * Subtarea 9.3: Abrir y atender PR en GitHub (1 h)

**Total de horas estimadas en subtareas:** **35 horas** *(Calza perfectamente con la capacidad comprometida de ~33 a 35 horas del equipo).*

---

# ACTIVIDAD A6: VINCULACIÓN JIRA-GITHUB Y FLUJO DE TRABAJO

1. **Vincular Jira con GitHub:** El Scrum Master instala la app **GitHub for Jira** en Atlassian y conecta el repositorio `FeriaSegura-Huamanga`.
2. **Proteger la rama `main` en GitHub:**
   * En GitHub > *Settings* > *Branches* > *Add branch ruleset* (o *Branch protection rule*).
   * Marcar: `Require a pull request before merging` con al menos **1 approval requerida**.
   * Bloquear push directo a `main`.
3. **Flujo de desarrollo por integrante (Requisito de 1 PR por miembro):**
   * **Dev 1 (Aldo):** Toma `FSH-5`, crea rama `feature/FSH-5-registro-puestos`, abre PR, es revisado por Dev 2 y hace merge.
   * **Dev 2 (Jhover):** Toma `FSH-6`, crea rama `feature/FSH-6-bloqueo-puestos`, abre PR, es revisado por Dev 3 y hace merge.
   * **Dev 3 (Edson):** Toma `FSH-7`, crea rama `feature/FSH-7-empadronamiento-comerciante`, abre PR, es revisado por Dev 4 y hace merge.
   * **Dev 4 (Erik):** Toma `FSH-10`, crea rama `feature/FSH-10-control-electrico`, abre PR, es revisado por Dev 1 y hace merge.
