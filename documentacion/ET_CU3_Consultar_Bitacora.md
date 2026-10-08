# 📋 Especificación Textual de Caso de Uso

## CUS-03: Consultar Bitácora de Auditoría

### 1. Ficha Técnica

| Campo | Descripción |
| :--- | :--- |
| **Código** | `CUS-03` |
| **Caso de Uso** | Consultar Bitácora de Auditoría |
| **Actores** | Administrador |
| **Objetivo** | Proveer una interfaz de solo lectura para visualizar, buscar y filtrar el historial inmutable de acciones críticas ejecutadas por todos los usuarios dentro del sistema, garantizando la transparencia y trazabilidad del proceso electoral. |
| **Precondiciones** | 1. El usuario debe haber iniciado sesión con rol `ADMIN`. |
| **Disparador** | El usuario selecciona la opción "Bitácora" en el menú lateral del Dashboard. |
| **Ruta de Acceso** | Dashboard $\rightarrow$ Módulo "Bitácora". |
| **Postcondición de Éxito** | El sistema despliega correctamente la lista de eventos de auditoría según los parámetros de paginación y filtros solicitados por el administrador. |
| **Postcondición de Fallo** | N/A (Se trata de una operación de solo lectura, los fallos estarían limitados a problemas de red o caída de la base de datos). |

---

### 2. Flujos Alternos

* **FA-01. Búsqueda sin resultados:**
  1. Si los filtros aplicados (por ejemplo, buscar por una acción específica en un rango de fechas donde no hubo actividad) no devuelven coincidencias, el sistema muestra una tabla de datos vacía o un mensaje informativo indicando que no se encontraron registros.

---

### 3. Curso Normal de Eventos (Flujo Principal)

| Acción del Actor | Respuesta del Sistema |
| :--- | :--- |
| 1. Selecciona la opción "Bitácora" en el menú lateral. | 2. El sistema realiza una solicitud paginada inicial (`GET /api/auditoria`) y devuelve la primera página de eventos ordenados descendentemente por fecha. |
| 3. Visualiza la tabla con las columnas principales: Fecha, Acción, Usuario, IP, Navegador y Detalles. | 4. El sistema muestra los controles de paginación calculando automáticamente el número de páginas según la respuesta del backend (`totalElements`, `totalPages`). |
| 5. Opcionalmente, ingresa criterios de filtro (tipo de acción, ID de usuario, o rango de fechas) y hace clic en "Buscar". | 6. El sistema envía los parámetros al backend, filtra los registros en la base de datos y devuelve el subconjunto de datos actualizando la vista en pantalla. |
| 7. Navega por las páginas usando los botones "Siguiente" o "Anterior". | 8. El sistema consulta y muestra la página solicitada (`page=N`). |
