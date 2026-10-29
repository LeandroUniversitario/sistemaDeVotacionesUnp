# CUS00 · Iniciar sesión

**Actor:** Usuario del sistema (`ADMIN`, `CEUNP`, `MIEMBRO_MESA`, `PERSONERO`, `DOCENTE` y público en general)
**Pantalla:** `PantallaLogin` (`LoginPage.jsx`, ruta raíz `/login` o `/` sin sesión activa) y `PantallaPortalResultados` (`PortalResultados.jsx` / ruta `/resultados`)
**Módulo:** M01 Seguridad y autenticación / M12 Portal de transparencia
**Metodología:** RUP (Fase de Elaboración · Análisis y Diseño) según estándar UNP (Dr. Iván Iman Agurto).
**Requisitos:** RF de autenticación institucional mediante credenciales, generación de Token JWT, verificación de sesión previa persistente, control de intentos fallidos con bloqueo temporal y enlace de transparencia pública sin autenticación.
**Reglas:** RN28 (auditoría obligatoria de accesos y fallos en bitácora), seguridad parametrizada (`SEGURIDAD_INTENTOS_MAXIMOS` y `SEGURIDAD_BLOQUEO_MINUTOS` de CUS18), contraseñas cifradas en BCrypt, RF99 (resultados públicos solo si el cómputo fue publicado).

---

## 🖥️ Botones y Elementos de la Interfaz (`PantallaLogin`)

En la pantalla `LoginPage.jsx` se encuentran las siguientes acciones/botones del usuario:
1. **Verificación de sesión guardada (Automática al abrir):** Si el navegador cuenta con un token en `sessionStorage`, comprueba la vigencia de la sesión sin pedir credenciales.
2. **Botón [ Ingresar al Sistema ] (`type="submit"`):** Envía usuario y contraseña al controlador `: ValidarCredenciales` para validar el hash BCrypt, actualizar el último acceso, registrar auditoría y emitir el token de sesión.
3. **Botón [ Consultar resultados y verificar actas ] (`auth-portal-link`):** Deriva a la interfaz `: PantallaPortalResultados` para que el público o personeros puedan consultar los procesos concluidos a través del controlador `: consultarResultados` consultando la entidad `: ProcesoElectoral`.

---

## Correspondencia con el Diagrama de Colaboración («colaboracion - Iniciar Sesion», `diagramas/Sistema De Elecciones.mdl`)

A continuación se detalla la equivalencia exacta de los **15 mensajes** del diagrama de colaboración diseñado en **Rational Rose** con los componentes reales del sistema:

| N.° | Mensaje del diagrama | Origen | Destino | Explicación en el Sistema |
|:---:|---|---|---|---|
| **1** | `abrirSistema()` | `: Usuario del sistema` | `: PantallaLogin` | El usuario accede a la URL base de la aplicación web. `main.jsx` inicializa la SPA. |
| **2** | `verificarSesionGuardada(token)` | `: PantallaLogin` | `: VerificarSesion` | `useEffect` en `main.jsx` lee `sessionStorage.getItem('accessToken')` y consulta `GET /api/auth/me`. |
| **3** | `buscarPorUsername(username)` | `: VerificarSesion` | `: Usuario` | Verifica la existencia y vigencia de la cuenta en la tabla `usuario`. |
| **4** | `mostrarResultadoSesion(username, rol)` | `: VerificarSesion` | `: PantallaLogin` | Si el token es válido, responde HTTP 200 con `MeResponse` y renderiza el `DashboardPage` según su rol. |
| **5** | `ingresarCredenciales` | `: Usuario del sistema` | `: PantallaLogin` | El usuario digita su nombre de usuario y contraseña en las cajas de texto correspondientes. |
| **6** | `validarCredenciales` | `: PantallaLogin` | `: ValidarCredenciales` | Se dispara al pulsar el botón **[ Ingresar al Sistema ]** realizando una petición HTTP `POST /api/auth/login`. *(Etiquetado en el diagrama como `validarCredendales`).* |
| **7** | `buscarPorUsername(username)` | `: ValidarCredenciales` | `: Usuario` | Consulta en la tabla `usuario` el `password_hash`, estado `activo` e intentos fallidos. |
| **8** | `registrarAcceso` | `: ValidarCredenciales` | `: RegistrarAcceso` | Delega el resultado: si fue exitoso invoca `registrarAccesoExitoso()`; si falló invoca `registrarIntentoFallido(...)`. |
| **9** | `actualizarAcceso` | `: RegistrarAcceso` | `: Usuario` | Actualiza en la tabla `usuario` las columnas `ultimo_acceso`, reinicia `intentos_fallidos = 0` (o incrementa y define `bloqueado_hasta`). |
| **10** | `registrarAuditoria` | `: RegistrarAcceso` | `: LogAuditoria` | Inserta en la tabla `log_auditoria` la acción `LOGIN_SUCCESS` o `LOGIN_FAILED` con la IP remota y el User-Agent. |
| **11** | `mostrarResultado(token, rol, mensaje)` | `: ValidarCredenciales` | `: PantallaLogin` | Si es exitoso, entrega el token JWT y enruta al dashboard; si falla, resalta los campos de error con el mensaje devuelto por el backend. |
| **12** | `consultarResultadosPublicos` | `: Usuario del sistema` | `: PantallaLogin` | El usuario hace clic en el botón secundario **[ Consultar resultados y verificar actas ]**. |
| **13** | `obtenerResultadosPublicos()` | `: PantallaPortalResultados` | `: consultarResultados` | La pantalla del portal público invoca a su controlador para cargar el catálogo de elecciones. |
| **14** | `leerProcesosConcluidos()` | `: consultarResultados` | `: ProcesoElectoral` | Consulta en la tabla `proceso_electoral` los procesos que tienen estado `CERRADO` o con cómputo `PUBLICADO` (`fn_resultados_disponibles`). |
| **15** | `mostrarResultados()` | `: consultarResultados` | `: PantallaPortalResultados` | Devuelve la lista de procesos con resultados disponibles para desplegarlos al ciudadano. |

---

## 🏛️ Objetos del Diagrama en Rational Rose (Arquitectura BCE)

### 1. Actor:
* `: Usuario del sistema` (Representa a cualquier usuario: Administrador, CEUNP, Miembro de Mesa, Personero, Docente o ciudadano).

### 2. Boundaries (Fronteras / Pantallas):
* `: PantallaLogin` (Interfaz de acceso institucional `LoginPage.jsx`).
* `: PantallaPortalResultados` (Interfaz pública de consulta de resultados y actas `PortalResultados.jsx`).

### 3. Controls (Controladores de lógica):
* `: VerificarSesion` (Servicio de validación de token JWT activo).
* `: ValidarCredenciales` (Servicio de autenticación contra hash BCrypt).
* `: RegistrarAcceso` (Servicio de actualización de accesos, intentos fallidos y bitácora).
* `: consultarResultados` (Servicio de consulta de procesos y actas públicas).

### 4. Entities (Entidades de Base de Datos):
* `: Usuario` (Tabla `usuario`).
* `: LogAuditoria` (Tabla `log_auditoria`).
* `: ProcesoElectoral` (Tabla `proceso_electoral`).

---

## Flujos de Ejecución

### Flujo 1: Ingreso interactivo con credenciales (Mensajes 5 al 11)
1. El usuario ingresa su `username` y `password` y pulsa **[ Ingresar al Sistema ]**.
2. `PantallaLogin` envía `POST /api/auth/login` al controlador `: ValidarCredenciales`.
3. El controlador consulta la entidad `: Usuario`:
   * Si la cuenta no está activa, rechaza con HTTP 403 (*Cuenta inactiva*).
   * Si la cuenta está temporalmente bloqueada (`bloqueado_hasta > NOW()`), rechaza con HTTP 401 indicando el tiempo de espera restante.
4. Se verifica el hash BCrypt:
   * **Contraseña errónea:** Incrementa `intentos_fallidos`, registra `LOGIN_FAILED` en `: LogAuditoria` y rechaza con HTTP 401. Si alcanza el tope, bloquea la cuenta.
   * **Contraseña correcta:** Restablece `intentos_fallidos = 0`, actualiza `ultimo_acceso`, registra `LOGIN_SUCCESS` en `: LogAuditoria` y genera el token JWT.
5. El usuario es redirigido a su panel de control según su rol.

### Flujo 2: Restauración de sesión previa (Mensajes 1 al 4)
1. El usuario abre el sistema en el navegador o recarga la página ($F5$).
2. `PantallaLogin` lee el token guardado en `sessionStorage` y consulta `GET /api/auth/me`.
3. `: VerificarSesion` comprueba la firma del token y busca la cuenta en `: Usuario`.
4. Si sigue vigente, retorna los datos de la sesión y entra de inmediato al sistema sin solicitar credenciales.

### Flujo 3: Consulta pública de resultados sin sesión (Mensajes 12 al 15)
1. En la pantalla de inicio de sesión, el usuario presiona el botón **[ Consultar resultados y verificar actas ]**.
2. El sistema navega hacia la pantalla `: PantallaPortalResultados` (ruta `/resultados`).
3. La pantalla llama al controlador `: consultarResultados` (`GET /api/publico/consulta/procesos`).
4. El controlador lee de la entidad `: ProcesoElectoral` los procesos que cuentan con resultados oficiales publicados.
5. Se muestra el catálogo de procesos electorales en pantalla para su consulta y verificación mediante código QR.

---

## Endpoints REST del Caso de Uso

| Método | Endpoint | Acceso | Función |
|---|---|---|---|
| `POST` | `/api/auth/login` | Público | Autentica usuario, valida hash BCrypt, genera JWT y audita. |
| `GET` | `/api/auth/me` | Autenticado | Verifica token activo y recupera perfil y rol del usuario. |
| `GET` | `/api/publico/consulta/procesos` | Público | Obtiene los procesos electorales con resultados publicados. |

---

## Archivos del Código Fuente

* **Frontend:**
  * `frontend/src/pages/LoginPage.jsx` (Pantalla de inicio de sesión con ambos botones).
  * `frontend/src/main.jsx` (Detección de sesión activa y rutas públicas).
  * `frontend/src/pages/resultados/PortalResultados.jsx` (Pantalla pública de resultados).
* **Backend:**
  * `backend/src/main/java/pe/unp/elecciones/auth/AuthController.java` (Endpoints de autenticación).
  * `backend/src/main/java/pe/unp/elecciones/auth/UsuarioService.java` (Lógica de validación).
  * `backend/src/main/java/pe/unp/elecciones/auth/Usuario.java` (Entidad de dominio de cuentas).
  * `backend/src/main/java/pe/unp/elecciones/electoral/controller/PublicoController.java` (Endpoint público de resultados).
  * `backend/src/main/java/pe/unp/elecciones/electoral/resultados/ConsultarResultados.java` (Servicio de consulta de procesos).
  * `backend/src/main/java/pe/unp/elecciones/electoral/service/AuditoriaService.java` (Registro en `log_auditoria`).
