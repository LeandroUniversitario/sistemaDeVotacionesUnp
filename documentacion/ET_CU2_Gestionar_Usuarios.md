# 📋 Especificación Textual de Caso de Uso

## CUS-02: Gestionar Usuarios y Roles

### 1. Ficha Técnica

| Campo | Descripción |
| :--- | :--- |
| **Código** | `CUS-02` |
| **Caso de Uso** | Gestionar Usuarios y Roles |
| **Actores** | Administrador |
| **Objetivo** | Administrar las cuentas de acceso al sistema, permitiendo crear nuevos usuarios, modificar sus roles, restablecer contraseñas, cambiar su estado (activo/inactivo) y eliminarlos, asegurando la continuidad administrativa del sistema. |
| **Precondiciones** | 1. El usuario debe haber iniciado sesión con rol `ADMIN`. |
| **Disparador** | El usuario selecciona la opción "Usuarios" desde el menú lateral del Dashboard. |
| **Ruta de Acceso** | Dashboard $\rightarrow$ Módulo "Usuarios". |
| **Postcondición de Éxito** | El sistema registra o actualiza la información del usuario en la base de datos de manera correcta y muestra el cambio reflejado en la tabla principal. |
| **Postcondición de Fallo** | El sistema aborta la operación y muestra un mensaje de alerta si las validaciones de negocio no se cumplen, manteniendo la información sin cambios. |

---

### 2. Flujos Alternos

* **FA-01. Intento de eliminar o degradar al último administrador:**
  1. Si la acción dejaría al sistema sin al menos un rol `ADMIN` activo, el sistema bloquea la acción y muestra el error "Debe existir al menos un administrador activo".

* **FA-02. Nombre de usuario duplicado:**
  1. Al intentar crear un usuario con un nombre ya existente, el sistema muestra el error "El nombre de usuario ya existe".

* **FA-03. Cambio de rol o eliminación propia:**
  1. Si el administrador intenta cambiar su propio rol o eliminar su propia cuenta, el sistema muestra el error "No puedes cambiar tu propio rol" o "No puedes eliminar tu propia cuenta".

* **FA-04. Rol que requiere asociación a docente:**
  1. Si se selecciona el rol `DOCENTE`, `PERSONERO` o `MIEMBRO_MESA` y no se selecciona un docente del padrón, el sistema indica "Este rol requiere asociar un docente".

---

### 3. Curso Normal de Eventos (Flujo Principal)

| Acción del Actor | Respuesta del Sistema |
| :--- | :--- |
| 1. Selecciona la opción "Usuarios" en el menú lateral. | 2. El sistema procesa la solicitud (`GET /api/auth/users`) y muestra la lista de todos los usuarios registrados con su nombre, rol, estado y opciones de acción. |
| 3. Para crear: Hace clic en "Nuevo Usuario", completa los datos solicitados (usuario, contraseña, rol, docente asociado) y presiona "Guardar". | 4. El sistema valida los datos (ej. formato del usuario, longitud de contraseña), encripta la clave y guarda el nuevo registro, actualizando la lista en pantalla. |
| 5. Para editar estado/rol/password: Utiliza los botones de acción en la fila de un usuario específico. | 6. El sistema procesa la solicitud específica, evalúa las reglas de negocio (ej. validación del último `ADMIN`) y aplica el cambio en la base de datos. |
| 7. Para eliminar: Presiona el botón de eliminar y confirma la acción. | 8. El sistema valida que no sea el propio usuario activo ni el último `ADMIN`, y procede a eliminar el registro. |
