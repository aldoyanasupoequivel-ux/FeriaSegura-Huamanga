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
* **`FSH-7`**: Configuración del repositorio base y suite de pruebas unitarias.
* **`FSH-24`**: Inicio de sesión de Comerciante empadronado con DNI (8 dígitos) y contraseña.
* **`FSH-22`**: Inicio de sesión de usuarios municipales internos (Fiscalizador de Serenazgo y Administrador MPH) con usuario institucional.
* **`FSH-10` / `FSH-36`**: Validación de formato, unicidad y empadronamiento de comerciantes con DNI único.

---

## 🏛️ Aplicación de Principios de Ingeniería de Software

### 1. Principios SOLID
* **S (Single Responsibility Principle):**
  * `ValidadorDni`: Su única responsabilidad es verificar que el DNI cumpla la regla de 8 dígitos numéricos peruanos.
  * `AlmacenUsuarios`: Su única responsabilidad es la persistencia en memoria y búsqueda de usuarios.
  * `ServicioAutenticacion`: Su única responsabilidad es orquestar los flujos de login y registro.
* **D (Dependency Inversion Principle):**
  * El servicio de autenticación no depende de una base de datos acoplada rígidamente; recibe la abstracción del almacén por inyección de dependencias.

### 2. TDD (Test-Driven Development)
* Suite de 12 pruebas unitarias automatizadas (`pruebas.js`) ejecutables con el motor nativo de Node.js.
* Cobertura de caminos felices y casos borde (letras en DNI, longitud errónea, contraseñas incorrectas, DNI no empadronado, control de duplicados).
* **100% de pruebas en verde cumpliendo la Definition of Done (DoD).**

---

## 💻 Instrucciones de Uso y Ejecución

### 1. Ejecutar las Pruebas Unitarias (TDD)
```bash
npm test
# o directamente:
node pruebas.js
```

### 2. Ver la Interfaz Web (Portal de Login)
Simplemente abre el archivo **`index.html`** en cualquier navegador web o ejecuta en PowerShell:
```powershell
Start-Process index.html
```

### 3. Credenciales Demo de Prueba:
* **Comerciante Empadronado:** DNI `45871234` | Clave: `123456`
* **Fiscalizador de Serenazgo:** Usuario: `fiscalizador` | Clave: `123456`
* **Administrador MPH:** Usuario: `admin` | Clave: `admin123`
