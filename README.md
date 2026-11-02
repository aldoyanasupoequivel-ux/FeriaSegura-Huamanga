# FeriaSegura Huamanga (FSH)
**Sistema de Gestión, Carga Eléctrica y Fiscalización QR para Ferias Municipales**  
*Curso:* Construcción y Evolución de Software (Semestre 2026-II)  
*Municipalidad Provincial de Huamanga - Ayacucho, Perú*

---

## 👥 Equipo de Desarrollo (Scrum)
* **Aldo Marcos Yanasupo Esquivel** (`AE`) - Product Owner / Developer
* **Jhover Erickson Vasquez Quispe** (`JQ`) - Scrum Master / Developer
* **Edson Huaman Huacre** (`EH`) - Developer
* **Erik Hernando Ayala Cisneros** (`EC`) - Developer

---

## 🚀 Alcance del Sprint 1 (Entregable Actual)

### 📌 Historias e Incidencias Cubiertas:
* **`FSH-7`**: Configuración del repositorio base, contenedor Docker con PostgreSQL y suite de pruebas unitarias.
* **`FSH-28`**: Modelo de Base de Datos relacional en PostgreSQL con esquema `auth_acl` y `feria_core`, migraciones, RLS y tests de inmutabilidad.
* **`FSH-24`**: Inicio de sesión unificado de Comerciante empadronado con DNI (8 dígitos) y contraseña.
* **`FSH-22`**: Inicio de sesión unificado de funcionarios municipales (Fiscalizador de Serenazgo, Administrador MPH, Tesorería, Defensa Civil).
* **`FSH-10` / `FSH-36`**: Validación de formato, unicidad y empadronamiento de comerciantes con DNI único.

---

## 🏛️ Aplicación de Principios de Ingeniería de Software

### 1. Principios SOLID
* **S (Single Responsibility Principle):**
  * `ValidadorDni`: Su única responsabilidad es verificar que el DNI cumpla la regla de 8 dígitos numéricos peruanos.
  * `ControladorAccesoACL`: Su única responsabilidad es administrar la matriz de roles y evaluar si un usuario tiene permisos sobre un recurso.
  * `AlmacenUsuarios`: Su única responsabilidad es la persistencia en memoria y búsqueda de usuarios.
  * `ServicioAutenticacion`: Su única responsabilidad es orquestar el flujo de autenticación y empadronamiento.
* **D (Dependency Inversion Principle):**
  * El servicio de autenticación recibe por inyección de dependencias el almacén y el evaluador ACL, sin acoplamiento rígido.

### 2. Control de Acceso Centralizado con ACL (Access Control List)
* **Eliminación de la selección manual de roles:** El usuario no clasifica su rol en la UI (lo cual representaba un riesgo de seguridad y mala práctica de UX). Existe un **único formulario de acceso** que acepta DNI o usuario institucional.
* **Determinación automática y permisos por ACL:** Al autenticar la identidad y contraseña, el sistema consulta el catálogo de roles y permisos (alineado con `auth_acl.roles` y `auth_acl.permisos` de la base de datos PostgreSQL) y autoriza únicamente las acciones correspondientes a cada perfil:
  * **Comerciante:** Postulación, consulta de cuadrícula, reserva de puestos, declaración de artefactos eléctricos y comprobantes TUPA.
  * **Fiscalizador:** Escaneo de credenciales QR y registro de actas de infracción en campo.
  * **Administrador MPH:** Administración total de catastro, ferias, sectores y usuarios.

### 3. TDD (Test-Driven Development)
* Suite de **15 pruebas unitarias automatizadas** (`pruebas.js`) ejecutables con el motor nativo de Node.js.
* Cobertura de caminos felices, casos borde, reglas de unicidad y evaluación estricta de permisos ACL.
* **100% de pruebas en verde cumpliendo la Definition of Done (DoD).**

---

## 💻 Instrucciones de Uso y Ejecución

### 1. Ejecutar las Pruebas Unitarias (TDD)
```bash
npm test
# o directamente:
node pruebas.js
```

### 2. Ver la Interfaz Web (Portal de Acceso Centralizado)
Simplemente abre el archivo **`index.html`** en cualquier navegador web o ejecuta en PowerShell:
```powershell
Start-Process index.html
```

### 3. Credenciales Demo de Prueba (para evaluación y sustentación):
* **Comerciante Empadronado:** DNI `45871234` | Clave: `123456`
* **Fiscalizador de Serenazgo:** Usuario: `fiscalizador` | Clave: `123456`
* **Administrador MPH:** Usuario: `admin` | Clave: `admin123`
