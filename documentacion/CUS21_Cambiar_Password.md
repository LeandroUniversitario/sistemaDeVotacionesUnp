# CUS21 · Cambiar contraseña

**Actor:** Usuario del sistema (`ADMIN`, `CEUNP`, `MIEMBRO_MESA`, `PERSONERO`, `DOCENTE`)
**Pantalla:** `PantallaCambiarPassword` (`CambiarPasswordObligatorioPage.jsx`)
**Módulo:** M01 Seguridad y administración de accesos
**Metodología:** RUP (Fase de Elaboración · Análisis y Diseño) según estándar UNP (Dr. Iván Iman Agurto).
**Principio de diseño del docente:** Cada **Controlador** representa la acción que desencadena un **botón / evento de la interfaz**, el cual interactúa directamente con la frontera (`Boundary`) y las entidades (`Entity`) de la base de datos.

---

## 🖥️ Botones y Elementos de la Interfaz (`PantallaCambiarPassword`)

En la pantalla `CambiarPasswordObligatorioPage.jsx` existen las siguientes acciones/botones directos del usuario:

1. **Carga inicial de la pantalla:** Evalúa la sesión activa y carga los parámetros de longitud mínima de clave.
2. **Botón [ Establecer mi contraseña y continuar ] (`type="submit"`):** Valida la contraseña actual, comprueba la longitud mínima y la confirmación, cifra con BCrypt, actualiza la entidad `Usuario`, quita el flag `debe_cambiar_password = 0` y registra la auditoría.
3. **Botón [ Cerrar sesión ] (`text-button`):** Limpia el token y aborta la sesión actual.

---

## Correspondencia con el Diagrama de Colaboraciones («colaboracion - Cambiar Password»)

| N.° | Mensaje del diagrama | Origen | Destino | Explicación en el Sistema |
|:---:|---|---|---|---|
| **1** | `gestionarCambioPassword()` | `: Usuario` | `: PantallaCambiarPassword` | El usuario visualiza la pantalla de cambio obligatorio al ingresar con su contraseña provisional o desde su cuenta. |
| **2** | `leerParametroMinimo()` | `: PantallaCambiarPassword` | `: ConsultarSeguridad` | Al cargar la pantalla, consulta la regla de seguridad vigente (`SEGURIDAD_PASSWORD_MIN = 8`). |
| **3** | `obtenerParametro()` | `: ConsultarSeguridad` | `: ParametroGlobal` | Consulta en la tabla `parametro_global` el valor de longitud mínima para validación. |
| **4** | `mostrarPolitica()` | `: ConsultarSeguridad` | `: PantallaCambiarPassword` | Muestra en pantalla el texto de ayuda: *"Nueva contraseña (mín. 8 caracteres, letras y números)"*. |
| **5** | `cambiarPassword(objDatos)` | `: PantallaCambiarPassword` | `: CambiarPassword` | Se activa al hacer clic en el botón **[ Establecer mi contraseña y continuar ]** enviando `{ passwordActual, passwordNueva, confirmar }`. |
| **6** | `verificarPasswordActual(objDatos)` | `: CambiarPassword` | `: Usuario` | Valida que la contraseña actual coincida con el hash BCrypt de la cuenta en la tabla `usuario`. |
| **7** | `actualizarPassword(hash)` | `: CambiarPassword` | `: Usuario` | Guarda el nuevo hash cifrado, pone `debe_cambiar_password = 0` y actualiza `fecha_actualizacion = NOW()`. |
| **8** | `registrarAuditoria()` | `: CambiarPassword` | `: LogAuditoria` | Inserta en la tabla `log_auditoria` el evento `CAMBIO_PASSWORD` con el usuario, IP y fecha/hora. |
| **9** | `mostrarExito()` | `: CambiarPassword` | `: PantallaCambiarPassword` | Devuelve confirmación a la pantalla y permite avanzar al Dashboard. |
| **10** | `cerrarSesion()` | `: PantallaCambiarPassword` | `: CerrarSesion` | Se activa al hacer clic en el botón inferior **[ Cerrar sesión ]**. |
| **11** | `invalidarToken()` | `: CerrarSesion` | `: SesionActiva` | Limpia la sesión activa en el cliente (`sessionStorage`) y en `sesion_activa`. |
| **12** | `redireccionarLogin()` | `: CerrarSesion` | `: PantallaCambiarPassword` | Retorna al usuario a la pantalla inicial de inicio de sesión (`LoginPage`). |

---

## 🏛️ Objetos del Diagrama en Rational Rose (Arquitectura BCE)

### 1. Actor:
* `: Usuario` (Estereotipo Actor)

### 2. Boundary (Frontera / Pantalla):
* `: PantallaCambiarPassword` (Estereotipo Boundary - representa `CambiarPasswordObligatorioPage.jsx`)

### 3. Controles (Controladores vinculados a los botones):
* `: ConsultarSeguridad` (Carga inicial y políticas de contraseña)
* `: CambiarPassword` (Acción del botón **Establecer mi contraseña y continuar**)
* `: CerrarSesion` (Acción del botón **Cerrar sesión**)

### 4. Entities (Entidades de Base de Datos):
* `: Usuario` (Tabla `usuario`)
* `: ParametroGlobal` (Tabla `parametro_global`)
* `: LogAuditoria` (Tabla `log_auditoria`)
* `: SesionActiva` (Tabla `sesion_activa`)

---

## 📐 Estructura Gráfica del Diagrama (Colaboraciones)

```
                       [ : ConsultarSeguridad ] -------- (3: obtenerParametro) --------> [ : ParametroGlobal ]
                           ^              |
    (2: leerParametroMinimo)               (4: mostrarPolitica)
                           |              v
[: Usuario] -- (1: gestionar) --> [ : PantallaCambiarPassword ] 
                                  |                     |
     (5: cambiarPassword) --------+                     +-------- (10: cerrarSesion)
     |                                                                   |
     v                                                                   v
[ : CambiarPassword ]                                             [ : CerrarSesion ]
   |           |    |                                                    |
   |           |    +------ (9: mostrarExito) ---> [ Pantalla ]          +--> (11: invalidar) --> [ : SesionActiva ]
   |           v                                                         |
   |   (7: actualizarPassword)                                           +--> (12: redireccionar) --> [ Pantalla ]
   v           v
(6: verificar) [ : Usuario ]
   |
   +-------------- (8: registrarAuditoria) -----------------------------> [ : LogAuditoria ]
```

---

## Endpoints REST Asociados

| Método | Endpoint | Controlador Backend | Descripción |
|---|---|---|---|
| `GET` | `/api/auth/me` | `AuthController.me` | Verifica el estado del usuario y la bandera `debeCambiarPassword`. |
| `PATCH` | `/api/auth/password` | `AuthController.changePassword` | Valida credenciales, aplica regla de negocio y actualiza la clave en BD. |

---

## Archivos del Código Fuente

* **Frontend:** `frontend/src/pages/CambiarPasswordObligatorioPage.jsx`
* **Backend:**
  * `backend/src/main/java/pe/unp/elecciones/auth/AuthController.java`
  * `backend/src/main/java/pe/unp/elecciones/auth/UsuarioService.java`
  * `backend/src/main/java/pe/unp/elecciones/auth/Usuario.java`
