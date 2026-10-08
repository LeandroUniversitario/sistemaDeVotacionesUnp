# 📋 Especificación Textual de Caso de Uso

## CUS-01: Iniciar Sesión y Cargar Perfil

### 1. Ficha Técnica

| Campo | Descripción |
| :--- | :--- |
| **Código** | `CUS-01` |
| **Caso de Uso** | Iniciar Sesión y Cargar Perfil |
| **Actores** | Administrador del Sistema, Comité Electoral (CEUNP), Presidente de Mesa, Secretario de Mesa, Docente Elector y Personero |
| **Objetivo** | Autenticar la identidad del usuario mediante sus credenciales institucionales (`username` o correo y `password`), validar su estado de cuenta y cargar dinámicamente el menú y la matriz de permisos RBAC según el rol asignado (`ADMIN`, `CEUNP`, `MIEMBRO_MESA`, `DOCENTE`, etc.). |
| **Precondiciones** | 1. El usuario debe estar previamente registrado en la tabla `usuario` de la base de datos.<br>2. El servidor backend y los servicios API REST deben estar operativos en la red local o web. |
| **Disparador** | El usuario abre la aplicación en el navegador o ejecuta la ruta del sistema. |
| **Ruta de Acceso** | `http://localhost:5173/login` (o IP local de la red electoral) |
| **Postcondición de Éxito** | El backend genera un Token de sesión cifrado (JWT), establece la sesión segura, carga los datos del usuario (junto a los de su perfil o docente vinculado) y redirige al Dashboard correspondiente según su rol. |
| **Postcondición de Fallo** | El sistema deniega el acceso, mantiene la pantalla de Login, resalta las alertas de error correspondientes y no emite ningún Token de autorización. |

---

### 2. Flujos Alternos

* **FA-01. Credenciales incorrectas (Usuario o Contraseña inválidos):**
  1. El backend verifica la contraseña contra el hash `BCrypt` almacenado en la base de datos y detecta que no coinciden.
  2. Retorna un código de respuesta HTTP `401 Unauthorized`.
  3. El frontend resalta el campo de contraseña en rojo y muestra el mensaje: *"Credenciales incorrectas. Por favor, verifique su usuario y contraseña"*.
  4. El sistema registra el intento fallido en la bitácora de auditoría (`LOGIN_FAILED`).

* **FA-02. Campos obligatorios vacíos:**
  1. Si el usuario presiona el botón **"Iniciar Sesión"** sin llenar el usuario o la contraseña, el cliente (frontend) detiene la petición REST.
  2. Muestra un texto de advertencia debajo de cada caja de texto: *"Este campo es obligatorio"*.

* **FA-03. Usuario inactivo o deshabilitado (`activo = FALSE`):**
  1. El backend valida que las credenciales son correctas, pero verifica que la columna `activo` está en `0` (usuario dado de baja).
  2. Retorna un código HTTP `403 Forbidden`.
  3. Muestra en pantalla una alerta destacada: *"Acceso denegado. Su cuenta se encuentra inactiva. Contacte con el Administrador o CEUNP"*.

* **FA-04. Bloqueo temporal por intentos fallidos consecutivos:**
  1. Si el usuario acumula 5 intentos fallidos consecutivos en menos de 5 minutos, el sistema bloquea temporalmente la cuenta por 15 minutos para prevenir ataques de fuerza bruta.
  2. Muestra el mensaje: *"Cuenta bloqueada temporalmente por demasiados intentos fallidos. Intente nuevamente en 15 minutos"*.

---

### 3. Curso Normal de Eventos (Flujo Principal)

| N.° | Acción del Actor | Respuesta del Sistema |
| :---: | :--- | :--- |
| **1** | Ingresa a la URL del sistema en el navegador (`http://localhost:5173/login`). | **2.** Despliega la pantalla de inicio de sesión con el logotipo institucional (SICEUNP / UNP), los campos de texto `Usuario / Correo` y `Contraseña`, y el botón `Iniciar Sesión`. |
| **3** | Ingresa sus credenciales (`username` y `password`) y hace clic en **"Iniciar Sesión"**. | **4.** Captura la información y envía una solicitud HTTP `POST` al endpoint del backend `/api/auth/login` con el cuerpo de la petición cifrado (HTTPS/TLS). |
| -- | -- | **5.** El backend consulta la tabla `usuario`, obtiene el `password_hash`, la bandera `activo` y efectúa el `JOIN` con la tabla `docente` (si `id_docente` no es `NULL`). |
| -- | -- | **6.** Verifica la validez del hash `BCrypt`. Si es correcto, genera un **JSON Web Token (JWT)** firmado que incluye el `username`, el `rol` y el `id_usuario`. |
| -- | -- | **7.** Retorna la respuesta HTTP `200 OK` enviando el Token JWT y el objeto de perfil del usuario. |
| -- | -- | **8.** El frontend almacena de forma segura el Token JWT en el almacenamiento de sesión, decodifica el `rol` y **enruta automáticamente al usuario a su módulo asignado**: |
| -- | -- | 🔹 **`ADMIN`:** Redirige al Dashboard técnico / Creación de Proceso (`/dashboard/crear-proceso`). |
| -- | -- | 🔹 **`CEUNP`:** Redirige a la bandeja de Candidaturas y Gestión Electoral (`/dashboard/candidaturas`). |
| -- | -- | 🔹 **`MIEMBRO_MESA` (Secretario/Presidente):** Redirige al Módulo de Instalación y Verificación de Electores (`/dashboard/mesa`). |
| -- | -- | 🔹 **`DOCENTE`:** Redirige al Módulo de Consulta de Padrón o Terminal de Votación. |
| -- | -- | **9.** Registra la entrada exitosa en la bitácora (`log_auditoria` con acción `LOGIN_SUCCESS`, `ip_origen` y `fecha_hora`). |