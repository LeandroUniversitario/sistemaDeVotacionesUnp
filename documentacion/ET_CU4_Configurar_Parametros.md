# 📋 Especificación Textual de Caso de Uso

## CUS-04: Configurar Parámetros Globales

### 1. Ficha Técnica

| Campo | Descripción |
| :--- | :--- |
| **Código** | `CUS-04` |
| **Caso de Uso** | Configurar Parámetros Globales |
| **Actores** | Administrador |
| **Objetivo** | Ajustar los valores de los parámetros globales del sistema, tales como la Unidad Impositiva Tributaria (UIT) y los porcentajes de multas por omisión al sufragio o inasistencia a mesa de sufragio, manteniendo trazabilidad de dichos cambios. |
| **Precondiciones** | 1. El usuario debe haber iniciado sesión con rol `ADMIN`. |
| **Disparador** | El usuario selecciona la opción "Parámetros" en el menú lateral del Dashboard. |
| **Ruta de Acceso** | Dashboard $\rightarrow$ Módulo "Parámetros". |
| **Postcondición de Éxito** | Los valores actualizados se persisten en la base de datos y el sistema inserta un registro inmutable en la bitácora de auditoría detallando el cambio efectuado. |
| **Postcondición de Fallo** | El sistema rechaza el cambio si los valores ingresados son ilógicos o no numéricos, manteniendo las configuraciones previas intactas. |

---

### 2. Flujos Alternos

* **FA-01. Valor no numérico o negativo:**
  1. Si el administrador ingresa un texto no numérico o un número negativo, el sistema detiene el proceso y alerta: "El valor debe ser numérico" o "El valor no puede ser negativo".

* **FA-02. Porcentaje inválido:**
  1. Si se intenta asignar a un parámetro de tipo porcentaje (como multas) un valor que exceda el 100%, el sistema alerta "El porcentaje no puede superar 100".

---

### 3. Curso Normal de Eventos (Flujo Principal)

| Acción del Actor | Respuesta del Sistema |
| :--- | :--- |
| 1. Selecciona la opción "Parámetros" en el menú lateral. | 2. El sistema consulta (`GET /api/parametros`) y despliega el formulario con los parámetros actualmente vigentes (ej. UIT, MULTA_ELECTOR_OMISO_PCT). |
| 3. Modifica uno o más valores numéricos en los campos de texto y presiona "Guardar cambios". | 4. El sistema recibe la petición y procede a validar matemáticamente los datos (que sean numéricos, mayores a cero y que los porcentajes no excedan 100). |
| 5. Revisa el mensaje de confirmación. | 6. Una vez validados, el sistema persiste los nuevos valores. Paralelamente, registra automáticamente un evento del tipo `CAMBIO_PARAMETRO` en la auditoría, capturando tanto el valor anterior como el valor nuevo. Muestra el mensaje "Parámetros actualizados". |
