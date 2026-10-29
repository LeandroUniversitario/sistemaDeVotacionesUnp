# CUS00 · Iniciar sesión

**Actor:** Usuario del sistema (`ADMIN`, `CEUNP`, `MIEMBRO_MESA`, `PERSONERO`, `DOCENTE`) · **Pantalla:** `PantallaLogin` (`LoginPage.jsx`, ruta raíz `/login` o `/` sin sesión activa)
**Módulo:** M01 Seguridad y autenticación · **Requisitos:** RF de autenticación por credenciales institucionales, generación de Token JWT, verificación de sesión previa, control de intentos fallidos con bloqueo temporal y cambio de contraseña provisional obligatorio.
**Reglas:** RN28 (auditoría obligatoria de accesos y fallos en bitácora), seguridad parametrizada (`SEGURIDAD_INTENTOS_MAXIMOS` y `SEGURIDAD_BLOQUEO_MINUTOS` de CUS18), contraseñas cifradas en BCrypt.

---

## 🖥️ Botones y Elementos de la Interfaz (`PantallaLogin`)

En la pantalla `LoginPage.jsx` existen las siguientes acciones/botones del usuario:
1. **Botón [ Ingresar al Sistema ] (`type="submit"`):** Inicia la autenticación con usuario y contraseña (validación de credenciales, hash BCrypt, auditoría y emisión de token).
2. **Botón [ Consultar resultados y verificar actas ] (`auth-portal-link`):** Enlace directo de navegación hacia la pantalla del portal público de transparencia electoral (`PortalResultados` / ruta `/resultados`), que pertenece al **CUS17**.

> **Nota metodológica según la teoría de RUP (Dr. Iván Iman Agurto):**  
> Cuando un botón en una pantalla tiene como único fin **navegar o abrir otro caso de uso** (en este caso, abrir el portal de resultados públicos), en el estándar RUP representa un enlace/navegación hacia otra interfaz (`Boundary`). Quien realmente consulta las entidades `ProcesoElectoral` y `ResultadoElectoral` es el controlador `: ConsultarResultados` dentro del propio **CUS17: Consultar resultados y verificar actas**.  
> Por tanto, en el diagrama de colaboraciones de `CUS00` se documenta la navegación hacia la pantalla de destino, manteniendo cada caso de uso delimitado en su objetivo.

---

## Correspondencia con el diagrama de colaboración («colaboracion - Iniciar Sesion», `diagramas/Sistema De Elecciones.mdl`)

| N.° | Mensaje del diagrama | Origen | Destino | Explicación en el Sistema |
|:---:|---|---|---|---|
| **1** | `abrirSistema()` | `: Usuario del sistema` | `: PantallaLogin` | El usuario ingresa a la aplicación web. `main.jsx` inicializa la SPA. |
| **2** | `verificarSesionGuardada(token)` | `: PantallaLogin` | `: VerificarSesion` | Si existe token en `sessionStorage`, consulta `/api/auth/me`. |
| **3** | `buscarPorUsername(username)` | `: VerificarSesion` | `: Usuario` | Valida el usuario en la BD contra la tabla `usuario`. |
| **4** | `mostrarResultadoSesion(username, rol)` | `: VerificarSesion` | `: PantallaLogin` | Si es válido, carga el `DashboardPage` según su rol. |
| **5** | `ingresarCredenciales` | `: Usuario del sistema` | `: PantallaLogin` | El usuario llena los campos de usuario y contraseña. |
| **6** | `validarCredenciales` | `: PantallaLogin` | `: ValidarCredenciales` | Se activa al hacer clic en el botón **[ Ingresar al Sistema ]** (`POST /api/auth/login`). |
| **7** | `buscarPorUsername(username)` | `: ValidarCredenciales` | `: Usuario` | Obtiene el hash BCrypt y valida estado `activo` e intentos. |
| **8** | `registrarAcceso` | `: ValidarCredenciales` | `: RegistrarAcceso` | Determina si el acceso fue exitoso o fallido. |
| **9** | `actualizarAcceso` | `: RegistrarAcceso` | `: Usuario` | Actualiza `ultimo_acceso`, reinicia intentos o bloquea. |
| **10** | `registraAuditoria` | `: RegistrarAcceso` | `: LogAuditoria` | Inserta en `log_auditoria` con IP y navegador. |
| **11** | `mostrarResultado(token, rol, mensaje)` | `: ValidarCredenciales` | `: PantallaLogin` | Emite el token y redirige, o muestra el mensaje de error. |
| **12** | `consultarResultados()` | `: Usuario del sistema` | `: PantallaLogin` | El usuario hace clic en el botón inferior **[ Consultar resultados y verificar actas ]**. |
| **13** | `abrirPortalResultados()` | `: PantallaLogin` | `: PantallaPortalResultados` | Redirige al navegador hacia la vista pública `/resultados`, iniciando el flujo del **CUS17**. |

---

## 🔎 Verificación del Diagrama de Rational Rose frente al Sistema

El diagrama documentado en Rational Rose se encuentra **muy bien modelado y guarda coherencia con la arquitectura del sistema**:

1. **Separación de responsabilidades:**
   - **Boundary:** `PantallaLogin` concentra la interacción visual con el usuario (formulario, mensajes de alerta y botones).
   - **Controles:**
     - `VerificarSesion`: Administra la validación pasiva de tokens JWT existentes (`/api/auth/me`).
     - `ValidarCredenciales`: Gestiona la autenticación activa con usuario y contraseña (`/api/auth/login`).
     - `RegistrarAcceso`: Encapsula la actualización del estado de seguridad del usuario y el registro en auditoría.
   - **Entidades:** `Usuario` (tabla `usuario`) y `LogAuditoria` (tabla `log_auditoria`).
2. **Observaciones menores del diagrama:**
   - **Mensaje 6 (`validarCredendales`):** En el diagrama original de Rational Rose se observa una errata tipográfica en la etiqueta (`Credendales` en lugar de `Credenciales`). En el código y la documentación se normaliza a `validarCredenciales`.
   - **Parámetros configurables de seguridad (CUS18):** El bloqueo temporal por intentos fallidos (mensaje 8) ya no utiliza valores fijos quemados en código; ahora lee los parámetros institucionales `SEGURIDAD_INTENTOS_MAXIMOS` (por defecto 5) y `SEGURIDAD_BLOQUEO_MINUTOS` (por defecto 15 minutos).
   - **Separación de responsabilidades:** El cambio obligatorio de contraseña provisional para cuentas recién creadas es un caso de uso posterior e independiente (`CUS21: Cambiar contraseña`), que se ejecuta únicamente tras completar con éxito este inicio de sesión.

---

## Flujos de Ejecución

### Flujo 1: Ingreso de usuario nuevo (Mensajes 5 al 11)
1. El usuario ingresa su nombre de usuario y contraseña y hace clic en **«Iniciar Sesión»**.
2. El sistema envía las credenciales mediante `POST /api/auth/login`.
3. El backend busca el usuario:
   * Si la cuenta tiene `activo = FALSE`, rechaza con HTTP 403: *"Acceso denegado. Su cuenta se encuentra inactiva. Contacte con el Administrador o CEUNP"*.
   * Si la cuenta está temporalmente bloqueada (`bloqueado_hasta > NOW()`), rechaza con HTTP 401 informando los minutos restantes de bloqueo.
4. El backend valida el hash BCrypt:
   * **Credenciales incorrectas:** Incrementa `intentos_fallidos`, registra `LOGIN_FAILED` en la bitácora y responde HTTP 401. Si alcanza el límite de intentos, establece `bloqueado_hasta = NOW() + minutos`.
   * **Credenciales correctas:** Reinicia `intentos_fallidos = 0`, actualiza `ultimo_acceso = NOW()`, registra `LOGIN_SUCCESS` en la bitácora y genera el Token JWT firmado.
5. El frontend recibe el token y enruta al actor según su rol y estado de contraseña.

### Flujo 2: Restauración de sesión activa (Mensajes 1 al 4)
1. El usuario abre la página o presiona F5 (recarga del navegador).
2. `main.jsx` detecta que existe un token en el almacenamiento de sesión (`sessionStorage`).
3. Envía una petición `GET /api/auth/me` enviando el token en la cabecera `Authorization: Bearer <token>`.
4. El backend valida criptográficamente el token y busca al usuario en la base de datos.
5. Si es válido, retorna los datos del perfil y el frontend entra directamente al panel sin pedir credenciales nuevamente. Si es inválido o caducó, se limpia el almacenamiento y se muestra la pantalla de Login.

---

## Endpoints del Caso de Uso

| Método | Ruta | Acceso | Descripción |
|---|---|---|---|
| `POST` | `/api/auth/login` | Público | Autentica al usuario, genera el JWT y registra auditoría. |
| `GET` | `/api/auth/me` | Autenticado | Verifica el token activo y obtiene el perfil del usuario actual. |
| `PATCH` | `/api/auth/password` | Autenticado | Permite al usuario cambiar su propia contraseña. |

---

## Archivos del Código Fuente

- **Backend:**
  - `backend/src/main/java/pe/unp/elecciones/auth/AuthController.java` (Endpoints REST `/api/auth/login` y `/api/auth/me`).
  - `backend/src/main/java/pe/unp/elecciones/auth/UsuarioService.java` (Lógica de autenticación, verificación de parámetros de seguridad y contraseñas).
  - `backend/src/main/java/pe/unp/elecciones/auth/Usuario.java` (Entidad de dominio con métodos de acceso exitoso, intentos fallidos y bloqueo).
  - `backend/src/main/java/pe/unp/elecciones/auth/UsuarioRepository.java` (Acceso a datos JPA para la tabla `usuario`).
  - `backend/src/main/java/pe/unp/elecciones/auth/JwtService.java` y `JwtAuthenticationFilter.java` (Generación y validación de tokens JWT).
  - `backend/src/main/java/pe/unp/elecciones/electoral/service/AuditoriaService.java` (Registro inmutable en `log_auditoria`).
- **Frontend:**
  - `frontend/src/main.jsx` (Componente raíz, verificación de sesión previa y enrutamiento principal).
  - `frontend/src/pages/LoginPage.jsx` (Pantalla de login con formulario de usuario, contraseña, alternador de visibilidad y manejo de errores).
  - `frontend/src/api/apiClient.js` (Interceptor de peticiones HTTP con inyección de cabecera Bearer).
  - `frontend/src/pages/CambiarPasswordObligatorioPage.jsx` (Pantalla obligatoria para docentes con primer ingreso).
  - `frontend/src/pages/DashboardPage.jsx` (Bandeja principal según la matriz de roles).

---

## Estructura en Base de Datos

* **Tabla `usuario`:**
  * `username` (único, hasta 80 caracteres).
  * `password_hash` (hash criptográfico generado con algoritmo BCrypt).
  * `rol` (`ADMIN`, `CEUNP`, `DOCENTE`, `PERSONERO`, `MIEMBRO_MESA`).
  * `activo` (booleano, control de vigencia de la cuenta).
  * `intentos_fallidos` (contador acumulado de intentos fallidos consecutivos).
  * `bloqueado_hasta` (`DATETIME`, timestamp de expiración del bloqueo preventivo).
  * `ultimo_acceso` (`DATETIME`, fecha y hora del último login exitoso).
  * `debe_cambiar_password` (booleano, indica si la clave es provisional).
* **Tabla `log_auditoria`:**
  * Registro de eventos `LOGIN_SUCCESS` y `LOGIN_FAILED` con `id_usuario`, `ip_origen`, `user_agent` y encadenamiento hash SHA-256 (CUS19).

