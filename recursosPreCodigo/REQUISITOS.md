# Catálogo de Requerimientos de Software

## Proyecto: FeriaSegura Huamanga (FS-HMA-2026)
**Sistema Integrado de Gestión y Fiscalización del Comercio Ambulatorio**  
*Archivo Excel Oficial:* [`Catalogo-Requerimientos-FeriaSegura.xlsx`](file:///C:/Users/aldin/Documents/2026-II/ConstruccionyEvaluaciondeSoftwareFinalLabo/Catalogo-Requerimientos-FeriaSegura.xlsx)

---

## Equipo de Proyecto (Analistas / Desarrolladores)
* **Aldo Marcos Yanasupo Esquivel** (`AMYE`)
* **Jhover Erickson Vasquez Quispe** (`JEVQ`)
* **Edson Huaman Huacre** (`EHH`)
* **Erik Hernando Ayala Cisneros** (`EHAC`)

---

## 1. Parámetros e Información Adicional (Hoja: Información adicional)

### ¿Qué son las "Áreas"? (Cliente / Entidad Beneficiaria)
*En ingeniería de software, las **Áreas** NO son los estudiantes. Representan las gerencias o departamentos del **cliente (la Municipalidad Provincial de Huamanga)** que solicitan y usarán el sistema:*
* **Gerencia de Desarrollo Económico (`GDE`):** Autoriza las ferias y coordina la actividad comercial.
* **Subgerencia de Comercio y Mercados (`SCM`):** Administra el padrón de ambulantes y la asignación de puestos.
* **Subgerencia de Serenazgo y Fiscalización (`SSF`):** Realiza las inspecciones y operativos en vía pública con la policía municipal.
* **Subgerencia de Defensa Civil (`DC`):** Supervisa la seguridad técnica, aforos, vías de evacuación y límite de conexiones eléctricas.
* **Gerencia de Administración Tributaria / Rentas (`TR`):** Recauda y valida el pago de las tasas municipales (TUPA).

### Canal Autorizado (Usuarios Representantes de la Municipalidad)
* **Juan Pérez Flores (`JPF`):** Gerente de Desarrollo Económico.
* **María Quispe Alanya (`MQA`):** Jefa de Fiscalización y Serenazgo.
* **Carlos Mendoza Bendezú (`CMB`):** Inspector de Riesgos de Defensa Civil.
* **Rosa Gutiérrez Prado (`RGP`):** Responsable de Caja y Pagos TUPA.

### Analistas (Equipo de Estudiantes de Ingeniería)
* **Aldo Marcos Yanasupo Esquivel (`AMYE`):** Análisis de Catastro, Zonificación y Autenticación.
* **Jhover Erickson Vasquez Quispe (`JEVQ`):** Análisis de Asignación Concurrente y Control Eléctrico.
* **Edson Huaman Huacre (`EHH`):** Análisis de Pagos TUPA, Credenciales y Rendimiento.
* **Erik Hernando Ayala Cisneros (`EHAC`):** Análisis de Fiscalización Móvil, Actas y Arquitectura.

---

### Glosario Técnico: Cuadro de Tipo_Requerimiento
| Tipo / Código | Descripción / Significado Técnico | Aplicación en el Proyecto |
| :--- | :--- | :--- |
| **`BD:SP`** | **Procedimiento Almacenado (Stored Procedure):** Código que se ejecuta directamente dentro del motor de PostgreSQL para garantizar transacciones atómicas. | Asignación concurrente de puestos con bloqueo pesimista (`SELECT ... FOR UPDATE`). |
| **`BD:Job`** | **Tarea Programada (Cron Job):** Proceso automático que corre periódicamente en el servidor o BD. | Cancelación automática de reservas que no pagaron la tasa en 24 horas. |
| **`BD:Triggers`** | **Disparador Automático:** Función que salta inmediatamente antes o después de un `INSERT` o `UPDATE`. | 1) Bloquear puestos si superan los kW de luz permitidos.<br>2) Guardar eventos en la tabla de auditoría inmutable. |
| **`BD:Configuración`** | **Ajustes del Motor de BD:** Creación de índices optimizados, llaves foráneas y reglas de integridad. | Índices parciales sobre puestos disponibles y tokens QR para consultas < 500 ms. |
| **`BD:Script`** | **Scripts SQL:** Archivos ejecutables con código DDL/DML para crear tablas, cargar datos semilla o hacer backups. | Scripts de migraciones de tablas y respaldo automatizado diario (`pg_dump`). |
| **`BD:BI`** | **Business Intelligence en BD:** Vistas y consultas agregadas para análisis de datos. | Consultas consolidadas de ocupación por avenida y recaudación total. |
| **`Ap.Web:Formulario`** | **Formulario Web Interactivo:** Pantallas con inputs, validaciones y botones de envío. | Registro de comerciantes, carga de vouchers de pago y registro de actas de infracción. |
| **`Ap.Web:Componente`** | **Componente Web Visual:** Elementos visuales interactivos reutilizables en React. | Cuadrícula interactiva de puestos (verde/rojo) y lector con cámara para el código QR. |
| **`Ap.Web:Servicio`** | **Endpoints / API REST:** Controladores y rutas en el backend que procesan las peticiones. | Endpoints en NestJS que conectan el frontend con la base de datos PostgreSQL. |
| **`Reporte:PDF`** | **Documento Oficial Descargable:** Generación de formatos oficiales con diseño estricto y código QR. | Emisión de la Ficha de Autorización Municipal que el comerciante imprime para su puesto. |
| **`Reporte:BI`** | **Tablero de Control (Dashboard):** Pantalla de gráficos y KPIs en tiempo real. | Panel del Alcalde/Gerente con métricas de ocupación, pagos e infracciones. |
| **`Clases`** | **Código de Dominio / Lógica:** Clases TypeScript, modelos, DTOs y decoradores de seguridad. | DTOs con `class-validator`, guards de roles (RBAC) y servicios de autenticación JWT. |
| **`Arquitectura`** | **Infraestructura y Calidad:** Decisiones de estructura de software y despliegue. | Contenedores Docker, modularidad en NestJS y soporte de alta concurrencia. |

---

## 2. Catálogo de Requerimientos (Hoja: Catalogo de Requerimientos)

### A. REQUERIMIENTOS FUNCIONALES (Correlativos 1 al 10)

#### Módulo R1: Catastro y Zonificación
* **[1 R1] Registro y Validación de Comerciante**
  * *Nº Módulo:* 1 | *Correlat:* 1 | *Sol:* JPF | *Fecha:* 2026-Sep-20 | *Analista:* **AMYE**
  * *Atributos:* Prioridad: A | Dificultad: M | Visibilidad: V | Riesgo: M | *Dep:* -
  * *Descripción:* El sistema debe permitir registrar y validar de forma única a los comerciantes ambulantes capturando datos de identidad (DNI, nombres, apellidos, teléfono, giro comercial y domicilio).
  * *Obs/Recom:* `OAF:` Validar estructura y longitud de DNI (8 dígitos numéricos). `OCA:` Cruzar con padrón municipal previo para evitar cuentas duplicadas.
  * *Estado:* Aprobado | *Sistema:* Portal Web Comerciante | *Tipo:* Ap.Web:Formulario | *Clasif:* Funcional

* **[2 R1] Delimitación de Ferias y Puestos**
  * *Nº Módulo:* 2 | *Correlat:* 2 | *Sol:* JPF | *Fecha:* 2026-Sep-20 | *Analista:* **AMYE**
  * *Atributos:* Prioridad: A | Dificultad: A | Visibilidad: V | Riesgo: A | *Dep:* -
  * *Descripción:* El sistema debe permitir al Administrador Municipal delimitar ferias temporales, sectores por avenidas/cuadras y puestos individuales con dimensiones fijas (2x2 m) y estados en tiempo real (DISPONIBLE, RESERVADO, ASIGNADO, BLOQUEADO).
  * *Obs/Recom:* `OAF:` Cada puesto debe contar con un código alfanumérico único (ej. MC-A01). `OCA:` Permitir bloquear puestos por motivos de seguridad o acceso a hidrantes.
  * *Estado:* Aprobado | *Sistema:* Portal Web Administrador | *Tipo:* Ap.Web:Componente | *Clasif:* Funcional

#### Módulo R2: Registro y Postulación
* **[1 R2] Asignación Concurrente y Transaccional de Puestos**
  * *Nº Módulo:* 1 | *Correlat:* 3 | *Sol:* JPF | *Fecha:* 2026-Sep-20 | *Analista:* **JEVQ**
  * *Atributos:* Prioridad: A | Dificultad: A | Visibilidad: V | Riesgo: A | *Dep:* 1 R1, 2 R1
  * *Descripción:* El sistema debe procesar la postulación y asignación de puestos de forma atómica y concurrente mediante transacciones en base de datos para impedir asignaciones duplicadas de un mismo puesto.
  * *Obs/Recom:* `OAF:` Implementar bloqueo pesimista en PostgreSQL (SELECT ... FOR UPDATE). `OCA:` Límite estricto de 1 puesto por DNI para erradicar el acaparamiento y reventa.
  * *Estado:* Aprobado | *Sistema:* Portal Web Comerciante / BD | *Tipo:* BD:SP | *Clasif:* Funcional

* **[2 R2] Declaración y Control de Demanda Eléctrica**
  * *Nº Módulo:* 2 | *Correlat:* 4 | *Sol:* CMB | *Fecha:* 2026-Sep-21 | *Analista:* **JEVQ**
  * *Atributos:* Prioridad: A | Dificultad: M | Visibilidad: V | Riesgo: A | *Dep:* 1 R2
  * *Descripción:* El sistema debe registrar la declaración de necesidad de suministro eléctrico y la lista de artefactos a conectar por puesto, calculando la potencia acumulada por sector en kW.
  * *Obs/Recom:* `OAF:` Disparador (Trigger) en BD que verifique si la potencia acumulada supera la capacidad máxima del sector fijada por Defensa Civil. `OCA:` Bloquear solicitudes con luz en cuadras saturadas.
  * *Estado:* Aprobado | *Sistema:* Portal Web Comerciante / BD | *Tipo:* BD:Triggers | *Clasif:* Funcional

#### Módulo R3: Formalización y Pagos TUPA
* **[1 R3] Gestión y Validación de Pagos TUPA**
  * *Nº Módulo:* 1 | *Correlat:* 5 | *Sol:* RGP | *Fecha:* 2026-Sep-22 | *Analista:* **EHH**
  * *Atributos:* Prioridad: A | Dificultad: M | Visibilidad: V | Riesgo: M | *Dep:* 1 R2
  * *Descripción:* El sistema debe gestionar la recepción, registro y validación del comprobante de pago de la tasa municipal TUPA por derecho de uso temporal de la vía pública.
  * *Obs/Recom:* `OAF:` Carga de archivo digital (voucher/recibo) y validación por personal de Tesorería. `OCA:` Ninguna postulación pasa a estado APROBADO sin validación de pago.
  * *Estado:* Aprobado | *Sistema:* Portal Web Administrador | *Tipo:* Ap.Web:Formulario | *Clasif:* Funcional

* **[2 R3] Emisión de Ficha de Autorización con Código QR**
  * *Nº Módulo:* 2 | *Correlat:* 6 | *Sol:* JPF | *Fecha:* 2026-Sep-22 | *Analista:* **EHH**
  * *Atributos:* Prioridad: A | Dificultad: M | Visibilidad: V | Riesgo: M | *Dep:* 1 R3
  * *Descripción:* El sistema debe generar automáticamente una Ficha de Autorización Municipal en formato PDF descargable que incluya datos del titular, puesto asignado, giro comercial y un código QR criptográfico único.
  * *Obs/Recom:* `OAF:` El código QR debe codificar un token que enlaza al endpoint público de validación oficial. `OCA:` La credencial debe ser visible obligatoriamente en el puesto físico.
  * *Estado:* Aprobado | *Sistema:* Portal Web Comerciante | *Tipo:* Reporte:PDF | *Clasif:* Funcional

#### Módulo R4: Fiscalización y Control en Campo
* **[1 R4] Fiscalización e Inspección Móvil con Lector QR**
  * *Nº Módulo:* 1 | *Correlat:* 7 | *Sol:* MQA | *Fecha:* 2026-Sep-23 | *Analista:* **EHAC**
  * *Atributos:* Prioridad: A | Dificultad: M | Visibilidad: V | Riesgo: M | *Dep:* 2 R3
  * *Descripción:* El sistema debe proveer una interfaz web responsiva (móvil) para que inspectores y Serenazgo escaneen el código QR del puesto y consulten en tiempo real la validez del permiso, titular y giro.
  * *Obs/Recom:* `OAF:` Optimizado para cámaras de smartphones con alertas visuales inmediatas (Verde: Conforme, Rojo: Inconsistencia/No Autorizado). `OCA:` Permite fiscalizar sin papeles en la calle.
  * *Estado:* Aprobado | *Sistema:* Web Móvil Fiscalizador | *Tipo:* Ap.Web:Componente | *Clasif:* Funcional

* **[2 R4] Registro de Actas de Infracción y Sanciones**
  * *Nº Módulo:* 2 | *Correlat:* 8 | *Sol:* MQA | *Fecha:* 2026-Sep-23 | *Analista:* **EHAC**
  * *Atributos:* Prioridad: M | Dificultad: M | Visibilidad: V | Riesgo: M | *Dep:* 1 R4
  * *Descripción:* El sistema debe permitir a los fiscalizadores registrar actas de observación e infracción en tiempo real desde el móvil, seleccionando el tipo de falta y adjuntando evidencia fotográfica.
  * *Obs/Recom:* `OAF:` Tipificar faltas (pirotécnicos no autorizados, invasión de calzada, cables expuestos). `OCA:` Notificar al módulo de administración para revocación o sanción.
  * *Estado:* Aprobado | *Sistema:* Web Móvil Fiscalizador | *Tipo:* Ap.Web:Formulario | *Clasif:* Funcional

#### Módulo R5: Seguridad y Auditoría
* **[1 R5] Control de Acceso Basado en Roles (RBAC)**
  * *Nº Módulo:* 1 | *Correlat:* 9 | *Sol:* JPF | *Fecha:* 2026-Sep-24 | *Analista:* **AMYE**
  * *Atributos:* Prioridad: A | Dificultad: M | Visibilidad: O | Riesgo: A | *Dep:* -
  * *Descripción:* El sistema debe implementar control de acceso basado en roles (RBAC) para perfiles COMERCIANTE, ADMINISTRADOR_MUNICIPAL y FISCALIZADOR, restringiendo vistas y endpoints de API.
  * *Obs/Recom:* `OAF:` Implementar Guards y decoradores de roles en NestJS. `OCA:` Comerciante solo visualiza sus trámites; fiscalizador no puede reasignar puestos.
  * *Estado:* Aprobado | *Sistema:* Todos los Sistemas | *Tipo:* Clases | *Clasif:* Funcional

* **[2 R5] Auditoría y Trazabilidad Inmutable**
  * *Nº Módulo:* 2 | *Correlat:* 10 | *Sol:* JPF | *Fecha:* 2026-Sep-24 | *Analista:* **JEVQ**
  * *Atributos:* Prioridad: A | Dificultad: M | Visibilidad: O | Riesgo: A | *Dep:* 1 R1, 1 R2, 1 R3
  * *Descripción:* El sistema debe registrar una bitácora inmutable de auditoría para cada evento crítico (aprobaciones, reasignaciones de puestos, anulaciones de infracciones) con usuario, fecha/hora e IP.
  * *Obs/Recom:* `OAF:` Implementar triggers en PostgreSQL sobre tabla audit_log con permisos restringidos de solo inserción. `OCA:` Transparencia total ante quejas vecinales o auditoría municipal.
  * *Estado:* Aprobado | *Sistema:* BD Transaccional | *Tipo:* BD:Triggers | *Clasif:* Funcional

---

### B. REQUERIMIENTOS NO FUNCIONALES (Correlativos 11 al 20)

#### Módulo R6: Calidad, Rendimiento y Seguridad
* **[1 R6] Soporte de Alta Concurrencia**
  * *Nº Módulo:* 1 | *Correlat:* 11 | *Sol:* JPF | *Fecha:* 2026-Sep-25 | *Analista:* **EHH**
  * *Atributos:* Prioridad: A | Dificultad: A | Visibilidad: O | Riesgo: A | *Dep:* 1 R2
  * *Descripción:* El sistema debe soportar una concurrencia mínima de 500 solicitudes por minuto durante la primera hora de apertura de postulaciones, manteniendo un tiempo de respuesta promedio inferior a 2 segundos.
  * *Obs/Recom:* `OAF:` Configurar pool de conexiones en NestJS/PostgreSQL y pruebas de estrés con k6/JMeter. `OCA:` Evitar caídas del portal que generen descontento o aglomeraciones presenciales.
  * *Estado:* Aprobado | *Sistema:* Portal Web Comerciante | *Tipo:* Arquitectura | *Clasif:* No Funcional

* **[2 R6] Optimización de Consultas e Índices**
  * *Nº Módulo:* 2 | *Correlat:* 12 | *Sol:* JPF | *Fecha:* 2026-Sep-25 | *Analista:* **EHAC**
  * *Atributos:* Prioridad: A | Dificultad: M | Visibilidad: O | Riesgo: M | *Dep:* 2 R1, 1 R4
  * *Descripción:* Las consultas del mapa de disponibilidad de puestos y la validación en calle de códigos QR deben ejecutarse en un tiempo no mayor a 500 milisegundos.
  * *Obs/Recom:* `OAF:` Crear índices parciales en PostgreSQL (WHERE estado = 'DISPONIBLE') e índices únicos sobre tokens QR. `OCA:` Vital para la fluidez operativa de los fiscalizadores en campo.
  * *Estado:* Aprobado | *Sistema:* BD Transaccional | *Tipo:* BD:Configuración | *Clasif:* No Funcional

* **[3 R6] Autenticación y Cifrado Robusto**
  * *Nº Módulo:* 3 | *Correlat:* 13 | *Sol:* JPF | *Fecha:* 2026-Sep-25 | *Analista:* **AMYE**
  * *Atributos:* Prioridad: A | Dificultad: M | Visibilidad: O | Riesgo: A | *Dep:* 1 R5
  * *Descripción:* El sistema debe autenticar usuarios mediante tokens JWT y cifrar contraseñas con el algoritmo bcrypt (factor de costo >= 10), transmitiendo toda la información bajo protocolo HTTPS (TLS 1.3).
  * *Obs/Recom:* `OAF:` Implementar Passport JWT en NestJS y cabeceras de seguridad con Helmet. `OCA:` Protección de la privacidad de los datos de comerciantes según normativa nacional.
  * *Estado:* Aprobado | *Sistema:* Backend / API | *Tipo:* Clases | *Clasif:* No Funcional

* **[4 R6] Prevención de Inyecciones y Manipulación**
  * *Nº Módulo:* 4 | *Correlat:* 14 | *Sol:* JPF | *Fecha:* 2026-Sep-25 | *Analista:* **JEVQ**
  * *Atributos:* Prioridad: A | Dificultad: M | Visibilidad: O | Riesgo: A | *Dep:* -
  * *Descripción:* El backend debe implementar validación estricta de DTOs y consultas parametrizadas mediante ORM para mitigar vulnerabilidades de Inyección SQL (SQLi) y Cross-Site Scripting (XSS).
  * *Obs/Recom:* `OAF:` Configurar ValidationPipe con whitelist: true en NestJS y esquemas tipados con class-validator. `RCA:` Auditoría de código previa a despliegue en producción.
  * *Estado:* Aprobado | *Sistema:* Backend / API | *Tipo:* Clases | *Clasif:* No Funcional

* **[5 R6] Diseño Adaptativo y Mobile-First**
  * *Nº Módulo:* 5 | *Correlat:* 15 | *Sol:* MQA | *Fecha:* 2026-Sep-26 | *Analista:* **EHH**
  * *Atributos:* Prioridad: A | Dificultad: M | Visibilidad: V | Riesgo: M | *Dep:* 1 R4, 2 R4
  * *Descripción:* La interfaz de fiscalización móvil debe aplicar diseño Mobile-First y soportar operación ergonómica en pantallas táctiles con botones táctiles de al menos 48x48 px y alto contraste solar.
  * *Obs/Recom:* `OAF:` Utilizar diseño responsivo CSS y prueba en emulador de dispositivos de baja gama. `OCA:` Los fiscalizadores usan teléfonos corporativos bajo condiciones de intemperie.
  * *Estado:* Aprobado | *Sistema:* Web Móvil Fiscalizador | *Tipo:* Ap.Web:Componente | *Clasif:* No Funcional

* **[6 R6] Arquitectura Modular y Desacoplada**
  * *Nº Módulo:* 6 | *Correlat:* 16 | *Sol:* JPF | *Fecha:* 2026-Sep-26 | *Analista:* **EHAC**
  * *Atributos:* Prioridad: A | Dificultad: A | Visibilidad: O | Riesgo: M | *Dep:* -
  * *Descripción:* El backend debe estructurarse bajo arquitectura modular con inyección de dependencias (NestJS) y separación en capas (Clean Architecture), facilitando la evolución del software.
  * *Obs/Recom:* `OAF:` Desacoplamiento entre controladores, servicios y repositorios. Cobertura de pruebas unitarias >= 70% con Jest. `OCA:` Facilita incorporar nuevos módulos a futuro sin reescribir código.
  * *Estado:* Aprobado | *Sistema:* Backend / API | *Tipo:* Arquitectura | *Clasif:* No Funcional

* **[7 R6] Respaldo y Recuperación de Datos (Disaster Recovery)**
  * *Nº Módulo:* 7 | *Correlat:* 17 | *Sol:* JPF | *Fecha:* 2026-Sep-26 | *Analista:* **AMYE**
  * *Atributos:* Prioridad: A | Dificultad: M | Visibilidad: O | Riesgo: A | *Dep:* -
  * *Descripción:* La base de datos debe contar con respaldo automatizado diario (pg_dump) y bitácora de transacciones (WAL archiving) garantizando un RPO <= 1 hora y RTO <= 30 minutos.
  * *Obs/Recom:* `OAF:` Cron job de backup nocturno y almacenamiento seguro en volumen secundario persistente. `OCA:` Plan de continuidad ante fallas imprevistas de hardware.
  * *Estado:* Aprobado | *Sistema:* BD Transaccional | *Tipo:* BD:Script | *Clasif:* No Funcional

* **[8 R6] Disponibilidad Continua del Servicio**
  * *Nº Módulo:* 8 | *Correlat:* 18 | *Sol:* JPF | *Fecha:* 2026-Sep-26 | *Analista:* **JEVQ**
  * *Atributos:* Prioridad: A | Dificultad: M | Visibilidad: O | Riesgo: A | *Dep:* -
  * *Descripción:* El sistema debe garantizar una disponibilidad continua del servicio del 99.5% durante los periodos de registro y ejecución de la feria municipal.
  * *Obs/Recom:* `OAF:` Despliegue en contenedores Docker con reinicio automático de políticas (restart: always) y monitoreo de salud (healthcheck). `OCA:` Servicio crítico para la ciudadanía.
  * *Estado:* Aprobado | *Sistema:* Todos los Sistemas | *Tipo:* Arquitectura | *Clasif:* No Funcional

* **[9 R6] Compatibilidad Multiplataforma y Navegadores**
  * *Nº Módulo:* 9 | *Correlat:* 19 | *Sol:* JPF | *Fecha:* 2026-Sep-27 | *Analista:* **EHH**
  * *Atributos:* Prioridad: M | Dificultad: B | Visibilidad: V | Riesgo: B | *Dep:* -
  * *Descripción:* Las aplicaciones web deben operar con total consistencia en las dos últimas versiones estables de Google Chrome, Mozilla Firefox, Microsoft Edge y Safari móvil.
  * *Obs/Recom:* `OAF:` Pruebas de compatibilidad cross-browser y cumplimiento de estándares W3C en HTML5/CSS3. `OCA:` Garantizar accesibilidad desde cualquier teléfono o laptop del usuario.
  * *Estado:* Aprobado | *Sistema:* Todos los Portales Web | *Tipo:* Ap.Web:Componente | *Clasif:* No Funcional

* **[10 R6] Trazabilidad y Gestión de Logs**
  * *Nº Módulo:* 10 | *Correlat:* 20 | *Sol:* JPF | *Fecha:* 2026-Sep-27 | *Analista:* **EHAC**
  * *Atributos:* Prioridad: M | Dificultad: B | Visibilidad: O | Riesgo: B | *Dep:* -
  * *Descripción:* El sistema debe registrar logs estructurados en formato JSON con niveles de severidad (INFO, WARN, ERROR) y marcas de tiempo UTC para trazabilidad operativa.
  * *Obs/Recom:* `OAF:` Integrar Logger de NestJS o Winston con rotación de archivos diarios. `OCA:` Diagnóstico rápido de incidencias o intentos de acceso no autorizados.
  * *Estado:* Aprobado | *Sistema:* Backend / API | *Tipo:* Clases | *Clasif:* No Funcional
