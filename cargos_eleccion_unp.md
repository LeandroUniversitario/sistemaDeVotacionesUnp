# Catálogo de Cargos de Elección (Ley Universitaria N° 30220 - UNP)

El Sistema de Control de Elecciones está diseñado de forma dinámica (con la entidad `Cargo` y `ProcesoElectoral`) justamente porque **las elecciones de docentes abarcan múltiples órganos de gobierno**, no solo el cargo de Rector. 

A continuación, se detalla la tabla con los cargos principales por los cuales un docente de la UNP puede emitir un voto y los filtros que el sistema debe aplicar al generar el **Padrón Electoral**.

| Cargo a Elegir | Nivel de Jurisdicción | Quiénes Votan (Padrón Electoral) | Requisito Básico del Candidato |
| :--- | :--- | :--- | :--- |
| **Rector y Vicerrectores** | Toda la Universidad | Todos los docentes ordinarios de la universidad (Principales, Asociados, Auxiliares). | Ser Docente Principal con grado de Doctor. |
| **Decano** | Facultad | Todos los docentes ordinarios pertenecientes a esa Facultad específica. | Ser Docente Principal con grado de Doctor. |
| **Representantes ante Asamblea Universitaria** | Toda la Universidad | Todos los docentes ordinarios de la universidad. (Se eligen representantes por cada categoría). | Ser docente ordinario de la categoría correspondiente. |
| **Representantes ante Consejo Universitario** | Toda la Universidad | Todos los docentes ordinarios de la universidad. | Ser Docente Principal o Asociado. |
| **Representantes ante Consejo de Facultad** | Facultad | Solo los docentes ordinarios pertenecientes a esa Facultad. | Ser docente ordinario de esa Facultad. |
| **Jefe de Departamento Académico** | Departamento Académico | Solo los docentes adscritos a ese Departamento Académico específico. | Ser Docente Principal (o Asociado si no hubiere). |

---

### ¿Cómo soporta el software esta complejidad? (Trazabilidad con el Diseño RUP)

1. **Requerimiento Funcional (RF03):** El sistema permite al Comité Electoral configurar reglas por cada cargo.
2. **Entidad `PadronElectoral`:** En lugar de tener un padrón único global, el sistema genera un sub-padrón por cada `Cargo`. 
   * *Ejemplo:* Si el Docente "Juan" pertenece a la Facultad de Minas, el sistema lo incluirá automáticamente en el `PadronElectoral` para **Rector**, y en el `PadronElectoral` para **Decano de Minas**, pero lo excluirá del padrón para **Decano de Sistemas**.
3. **Entidad `Docente`:** Incluye los campos `categoria` (Principal/Asociado/Auxiliar), `id_facultad` e `id_departamento`, los cuales son obligatorios para que el controlador (`PadronController`) pueda filtrar quién vota dónde.
