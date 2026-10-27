# Guía de Contribución y Normas del Equipo (CONTRIBUTING.md)

**Proyecto:** FeriaSegura Huamanga (FSH)  
**Curso:** Construcción y Evolución de Software (Semestre 2026-II)  
**Equipo:** Aldo Marcos Yanasupo Esquivel, Jhover Erickson Vasquez Quispe, Edson Huaman Huacre, Erik Hernando Ayala Cisneros

---

## 1. Roles del Equipo (Scrum)
* **Product Owner (PO):** Aldo Marcos Yanasupo Esquivel
* **Scrum Master (SM):** Jhover Erickson Vasquez Quispe
* **Developers:** Edson Huaman Huacre, Erik Hernando Ayala Cisneros, Aldo Yanasupo, Jhover Vasquez

---

## 2. Definition of Ready (DoR) - Filtro de Entrada al Sprint
Una historia de usuario solo puede ingresar al Sprint Planning si cumple con los siguientes 4 criterios verificables:

| # | Criterio de la Definition of Ready del equipo | Cómo se verifica |
| :-: | :--- | :--- |
| **1** | Está redactada en el formato estricto: *Como [rol], quiero [acción], para [beneficio]* y asociada a una épica padre en Jira. | Revisión en Jira (campo Principal / Parent). |
| **2** | Tiene al menos dos criterios de aceptación en formato **Dado – Cuando – Entonces** (*Criterio 1: camino feliz* y *Criterio 2: caso borde*). | Campo Descripción de la incidencia en Jira. |
| **3** | No depende de otra historia que no esté terminada o incluida en el mismo Sprint. | Análisis de dependencias en el Backlog. |
| **4** | El equipo la entiende con claridad y su estimación con Planning Poker es de **8 story points o menos** (si tiene 13 o más, se divide previamente). | Votación registrada en Planning Poker. |

---

## 3. Definition of Done (DoD) - Filtro de Salida del Sprint
Una historia o tarea técnica solo se mueve a la columna **LISTO** en Jira cuando cumple el 100% de esta lista:

| # | Criterio de la Definition of Done del equipo | Cómo se verifica |
| :-: | :--- | :--- |
| **1** | El código está desarrollado en una rama con la clave de Jira e integrado a `main` exclusivamente mediante un Pull Request (PR). | Panel *Desarrollo* de la incidencia en Jira. |
| **2** | Cada criterio de aceptación tiene al menos una prueba unitaria automatizada, y todas pasan en verde (`npm test` / `jest`). | Ejecución del suite de pruebas en GitHub Actions. |
| **3** | La cobertura de pruebas del código nuevo de dominio es de al menos **80%**. | Reporte de cobertura generado por Jest (`jest --coverage`). |
| **4** | El código respeta el linter (ESLint / Prettier), no presenta *code smells* evidentes, nombres descriptivos y funciones cortas. | Linter sin errores y revisión de código. |
| **5** | El PR fue aprobado por al menos un compañero distinto al autor, con todos los comentarios de revisión atendidos y resueltos. | Estado *Approved* en GitHub. |
| **6** | Después del *merge*, la rama `main` sigue compilando y ejecutando todas las pruebas en verde. | Pipeline de CI exitoso sobre `main`. |
| **7** | Las clases, servicios y métodos públicos cuentan con documentación JSDoc y el `README.md` se actualizó si cambió la forma de uso o instalación. | Revisión en el Pull Request. |

---

## 4. Convención de Git y Flujo de Pull Requests (GitHub Flow)

### Paso 1: Partir siempre de `main` actualizada
```bash
git checkout main
git pull origin main
```

### Paso 2: Crear la rama con la clave de Jira
```bash
# Formato: feature/FSH-<numero>-<descripcion-corta>
git checkout -b feature/FSH-8-postular-puesto
```

### Paso 3: Commits pequeños y descriptivos (con TDD)
```bash
# Formato: FSH-<numero>: <mensaje claro>
git add .
git commit -m "FSH-8: Valida disponibilidad de puesto antes de reservar"
```

### Paso 4: Ejecutar pruebas localmente antes de subir
```bash
npm test
npm run test:cov
```

### Paso 5: Publicar la rama y abrir Pull Request
```bash
git push -u origin feature/FSH-8-postular-puesto
```
* Abrir el PR en GitHub hacia `main`.
* El título del PR debe comenzar con la clave: `FSH-8: Postular a puesto disponible`.
* Completar la plantilla `.github/pull_request_template.md`.
* Asignar a un compañero como **Reviewer**.
* En Jira, mover la tarjeta a la columna **EN REVISIÓN**.

### Paso 6: Revisión por pares (Code Review)
El revisor debe verificar:
* ¿Cada criterio de aceptación tiene su prueba unitaria?
* ¿Las pruebas siguen el patrón AAA (Arrange, Act, Assert)?
* ¿El código respeta principios SOLID y no duplica lógica?
* Si hay observaciones, solicitar cambios (*Request changes*). Si todo está conforme, aprobar (*Approve*).

### Paso 7: Integración (Merge)
* El autor realiza el **Squash and merge** o **Merge pull request** en GitHub.
* Se elimina la rama remota.
* En Jira, se mueve la tarjeta a la columna **LISTO**.
