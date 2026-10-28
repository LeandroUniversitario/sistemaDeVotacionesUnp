# CUS18 · Administrar usuarios y parámetros

**Actor:** Administrador del sistema (rol ADMIN) · **Pantalla:** menú «Usuarios y parámetros» del Admin (`PantallaAdministrador`, boundary «PantallaAdministrador»), con tres pestañas: «Cuentas y roles», «Parámetros» y «Respaldo de la base». Reemplaza a las antiguas páginas «Usuarios» y «Parámetros».
**Módulo:** M01 Seguridad y administración · **Requisitos:** RF105 (UIT vigente para las multas), RF106 (plazo de justificación), RF58 (horario de instalación), requisitos no funcionales de seguridad (bloqueo por intentos, contraseñas, respaldo) · **Reglas:** RN28 (trazabilidad: nada se borra si tiene historia), RN35 (multas en porcentaje de la UIT), RN36 (quórum del Pleno), RN06-RN08 (jornada, mesas y horarios)
**Requiere:** sesión con rol ADMIN. Para asociar cuentas de miembro de mesa o personero conviene haber hecho el sorteo (CUS06) o la acreditación (CUS05), aunque no es obligatorio: el sistema solo lo advierte.
**Instalación:** en una base ya creada, ejecutar `base-de-datos/17_administracion_usuarios_parametros.sql` después de `16_resultados_verificacion.sql`. No hace falta recrear la base: el script solo agrega lo nuevo y se puede volver a ejecutar. `00_script_unico_elecciones_unp.sql` (sección 5h) ya lo incluye y `02_limpiar_datos_electorales.sql` conserva el historial de parámetros y el registro de respaldos. Los archivos de respaldo se guardan en la carpeta `respaldos/` del backend (variable `RESPALDO_DIR`), que está en `.gitignore` porque contienen datos personales.

## Correspondencia con el diagrama de colaboración («colaboration Administrar usuarios y parámetros», `diagramas/Sistema De Elecciones.mdl`)

| Mensaje del diagrama | Frontend | Backend |
|---|---|---|
| 1 `ingresarUsuario()` | Pestaña «Cuentas y roles», botón «Nueva cuenta»: rol, docente, nombre de usuario y contraseña | `POST /api/administracion/usuarios` → `AdministracionController.crear` |
| 1.1 `crearUsuario()` | «Crear cuenta» → «Confirmar» | `GestionarUsuarios.crear`: valida la contraseña con la política vigente o genera una provisional segura y la cifra con BCrypt |
| 2 `verificarDocente()` | Bloque «2 verificarDocente»: búsqueda en el padrón y tarjeta con estado, cuentas, mesa (CUS06) y personería (CUS05); verde, ámbar (advertencia) o rojo (error) | `GET /api/administracion/docentes?q=` y `GET /docentes/{id}/verificacion?rol=` → `sp_verificar_docente_usuario` · `fn_error_docente_usuario` |
| 3 `insertarUsuario()` | — | `sp_crear_usuario` (vuelve a aplicar `fn_error_docente_usuario` y escribe `CREAR_USUARIO` en la bitácora) |
| 4 `mostrarUsuario()` | Tarjeta «4 mostrarUsuario · contraseña provisional» (Copiar, Imprimir ficha de acceso) y la ficha de la cuenta con su actividad | `v_usuarios_admin`, `GET /usuarios/{id}/actividad` |
| 5 `modificarParametro()` | Pestaña «Parámetros»: «Modificar» en el parámetro, nuevo valor, vista previa de las multas y motivo | `PUT /api/administracion/parametros/{clave}` |
| 6 `actualizar()` | «Actualizar» → «Confirmar» | `ActualizarParametros.actualizar` |
| 7 `actualizarParametro()` | Validación local igual a la de la base (tipo, rango y coherencia de horarios) | `sp_actualizar_parametro` · `fn_validar_parametro` · `fn_jornada_en_curso`; `trg_parametro_global_bu` valida también los cambios hechos directamente en la base |
| 8 `registrarAuditoria()` | Tabla «8 registrarAuditoria · historial de cambios» (filtro por parámetro) e historial en la ficha del parámetro | `trg_parametro_global_au` → `parametro_historial`; `CAMBIO_PARAMETRO` en `log_auditoria` |
| 9 `confirmarCambio()` | Aviso «9 confirmarCambio»: valor anterior tachado → valor nuevo, N.º de historial y fecha | Fila de confirmación de `sp_actualizar_parametro` |
| 10 `solicitarRespaldo()` | Pestaña «Respaldo de la base»: «Generar respaldo», motivo opcional y «Confirmar» | `POST /api/administracion/respaldos` |
| 11 `generarRespaldo()` | — | `RespaldarBD.generar`: volcado lógico consistente de tablas, datos, funciones, vistas, procedimientos y triggers a un archivo `.sql` con su huella SHA-256 |
| 12 `registrarAuditoria()` | — | `sp_registrar_respaldo` → `respaldo_bd` y `GENERAR_RESPALDO` en la bitácora |
| 13 `mostrarRespaldo()` | Tarjeta «13 mostrarRespaldo»: tablas, filas, vistas, rutinas, triggers, tamaño y huella; «Descargar», «Verificar integridad» e «Imprimir constancia» | `v_respaldos`, `GET /respaldos/{id}/archivo`, `POST /respaldos/{id}/verificacion` |

### Cambios que conviene hacer en el diagrama
- Al caso le faltan las demás operaciones sobre una cuenta: `editarUsuario()` (rol o docente), `cambiarEstado()` (activar o desactivar con motivo), `restablecerPassword()`, `desbloquear()` y `eliminarUsuario()` (solo sin actividad, RN28). Todas pasan por `GestionarUsuarios` y escriben la bitácora.
- `verificarDocente()` no solo comprueba que el docente exista: valida que esté ACTIVO, que los roles DOCENTE, PERSONERO y MIEMBRO_MESA tengan docente, que no tenga ya una cuenta con el mismo rol, y advierte si no fue sorteado (CUS06) o acreditado (CUS05).
- Entre 6 y 7 falta la validación del parámetro contra su definición (tipo, rango, coherencia) y el bloqueo durante la jornada. Conviene una entidad `ParametroDefinicion` (catálogo) y otra `ParametroHistorial` (paso 8), separada de `LogAuditoria`, porque guarda el valor anterior y el nuevo para poder restaurarlos.
- Después del 9 falta `restaurarParametro()`: vuelve al valor anterior de un cambio del historial, con su propio motivo.
- Después del 13 faltan `descargarRespaldo()` y `verificarRespaldo()` (recalcula la huella SHA-256 del archivo y la compara con la registrada). Conviene una entidad `RespaldoBD` para el paso 12.

## Flujo
1. **Crear una cuenta (1 a 4).** El Admin pulsa «Nueva cuenta», elige el rol (cada tarjeta dice para qué sirve y si requiere docente), busca al docente por DNI o apellidos y el sistema lo verifica. El nombre de usuario se sugiere a partir del docente y el rol (`jperez.mesa`, `jperez.personero`…). La contraseña la genera el sistema (10 caracteres sin letras ambiguas, con mayúsculas, minúsculas y dígitos) o la escribe el Admin; en ambos casos es provisional. Tras «Confirmar», la contraseña se muestra una sola vez para copiarla o imprimir la ficha de acceso.
2. **Gestionar una cuenta.** «Gestionar» abre la ficha: datos, intentos fallidos, si la contraseña es provisional, la actividad del usuario y lo que la administración hizo con la cuenta. Botones: «Editar rol o docente», «Restablecer contraseña», «Desbloquear» (si tiene intentos fallidos), «Desactivar» / «Activar», «Eliminar» e «Imprimir ficha». Todo pide confirmación.
3. **Primer ingreso.** Con la contraseña provisional, el titular entra a «Cambio de contraseña requerido» y debe elegir una nueva (con la longitud mínima vigente, letras y números, distinta de la provisional) antes de ver su panel.
4. **Modificar un parámetro (5 a 9).** En «Parámetros», agrupados en Multas, Jornada electoral, Pleno y plazos del CEUNP y Seguridad del acceso, el Admin pulsa «Modificar», escribe el valor (con la vista previa de las multas si es la UIT o un porcentaje) y el motivo, y confirma. El cambio rige desde ese momento y queda en el historial. Desde el historial del parámetro puede «Restaurar» el valor anterior a cualquier cambio.
5. **Respaldar la base (10 a 13).** «Generar respaldo» → motivo → «Confirmar». El backend genera el archivo sin detener el sistema, lo registra con su huella y lo muestra. «Descargar» baja el archivo; «Verificar integridad» confirma que no fue modificado; «Imprimir constancia» deja la huella en papel.

## Reglas
- **Cuentas.** Nombre de usuario único (letras, números, punto, guion y guion bajo, 3 a 80). DOCENTE, PERSONERO y MIEMBRO_MESA requieren un docente ACTIVO; un docente tiene como máximo una cuenta por rol. Siempre queda al menos un ADMIN activo (`trg_usuario_admin_bu`, `trg_usuario_admin_bd`). El Admin no cambia su propio rol, no se desactiva, no se elimina ni restablece su propia contraseña desde aquí (la cambia en «Configuración»).
- **Desactivar** exige un motivo de 10 caracteres como mínimo; la cuenta no puede iniciar sesión y conserva su historia. **Eliminar** solo procede si la cuenta no tiene actividad en la bitácora (RN28); si la tiene, se desactiva.
- **Restablecer la contraseña** la deja provisional, quita el bloqueo y pone los intentos en cero. **Desbloquear** solo pone los intentos en cero.
- **Contraseñas:** longitud mínima `SEGURIDAD_PASSWORD_MIN` (8 por defecto), letras y números, sin espacios al inicio o al final. Tras `SEGURIDAD_INTENTOS_MAXIMOS` intentos fallidos (5) la cuenta se bloquea `SEGURIDAD_BLOQUEO_MINUTOS` minutos (15). Estos tres valores ya no están fijos en el código.
- **Parámetros.** Cada valor se valida contra su definición: tipo (decimal, entero, hora decimal, indicador 1/0 o texto), rango, y la hora de inicio de la instalación debe ser anterior a la hora límite. El motivo es obligatorio (10 caracteres) y el valor debe ser distinto del vigente. Durante una votación en curso no se cambian los parámetros de la jornada (electores por mesa, lugar y horarios). Los cambios hechos directamente en la base también se validan y quedan en el historial con origen «Directo en la base». Las multas ya determinadas no cambian: guardan la UIT y el porcentaje con que se calcularon.
- **Historial y respaldos** no se modifican ni se borran (`trg_param_hist_bu`, `trg_param_hist_bd`, `trg_respaldo_bu`, `trg_respaldo_bd`).
- **Respaldo.** Uno a la vez. El archivo se escribe primero como `.parcial` y se renombra al terminar. Solo se descargan o verifican archivos con el nombre `respaldo_elecciones_unp_AAAAMMDD_HHMMSS.sql` registrados en `respaldo_bd`. Descargar y verificar quedan en la bitácora (`DESCARGAR_RESPALDO`, `VERIFICAR_RESPALDO`).

## Endpoints
`/api/administracion` (solo ADMIN):

| Método | Ruta | Uso |
|---|---|---|
| GET | `/` | Cuentas, resumen por rol y estado, parámetros, historial, respaldos, jornada en curso y política de contraseñas |
| GET | `/usuarios/{id}/actividad` | Acciones del usuario y cambios que la administración hizo en la cuenta |
| GET | `/docentes?q=` | Búsqueda en el padrón (DNI, apellidos o nombres; hasta 15) |
| GET | `/docentes/{id}/verificacion?rol=&idUsuario=` | 2 verificarDocente |
| POST | `/usuarios` `{username, rol, idDocente, password, generarClave}` | 1-4 crear cuenta; devuelve la contraseña provisional |
| PUT | `/usuarios/{id}` `{rol, idDocente}` | Editar rol o docente |
| POST | `/usuarios/{id}/estado` `{activo, motivo}` | Activar o desactivar |
| POST | `/usuarios/{id}/clave` `{password}` (opcional) | Restablecer la contraseña (sin cuerpo, la genera) |
| POST | `/usuarios/{id}/desbloqueo` | Desbloquear |
| DELETE | `/usuarios/{id}` | Eliminar (solo sin actividad) |
| GET | `/parametros/{clave}/historial` | Historial del parámetro |
| PUT | `/parametros/{clave}` `{valor, motivo}` | 5-9 modificar parámetro |
| POST | `/parametros/{clave}/restauracion` `{idHistorial, motivo}` | Restaurar el valor anterior a un cambio |
| POST | `/respaldos` `{motivo}` | 10-13 generar respaldo |
| GET | `/respaldos/{id}/archivo` | Descargar el archivo `.sql` |
| POST | `/respaldos/{id}/verificacion` | Recalcular la huella: `INTEGRO`, `ALTERADO` o `NO_ENCONTRADO` |

Se retiraron `POST/PATCH/DELETE /api/auth/users` y `PUT /api/parametros/{clave}`, que no validaban ni dejaban historial. Se mantienen `GET /api/auth/users`, `GET /api/parametros` y `PATCH /api/auth/password`.

## Base de datos (`17_administracion_usuarios_parametros.sql`)
- Columnas nuevas en `usuario`: `id_usuario_creador`, `fecha_actualizacion` y `motivo_estado`.
- Tablas: `parametro_definicion` (grupo, etiqueta, tipo, mínimo, máximo, unidad, norma, bloqueo durante la jornada y orden), `parametro_historial` (valor anterior y nuevo, motivo, origen PANTALLA, RESTAURACION o BASE_DATOS, usuario, IP y fecha) y `respaldo_bd` (archivo, motivo, tablas, vistas, rutinas, triggers, filas, tamaño, huella SHA-256, usuario, IP, inicio y fin).
- Parámetros nuevos: `SEGURIDAD_INTENTOS_MAXIMOS` (5), `SEGURIDAD_BLOQUEO_MINUTOS` (15) y `SEGURIDAD_PASSWORD_MIN` (8). Los 16 parámetros tienen su definición.
- Funciones: `fn_jornada_en_curso`, `fn_validar_parametro` y `fn_error_docente_usuario`.
- Vistas: `v_usuarios_admin`, `v_parametros_admin`, `v_parametro_historial` y `v_respaldos`.
- Procedimientos: `sp_validar_admin`, `sp_verificar_docente_usuario`, `sp_crear_usuario`, `sp_actualizar_usuario`, `sp_cambiar_estado_usuario`, `sp_restablecer_password`, `sp_desbloquear_usuario`, `sp_eliminar_usuario`, `sp_actualizar_parametro` y `sp_registrar_respaldo`.
- Triggers: `trg_usuario_admin_bu`, `trg_usuario_admin_bd`, `trg_parametro_global_bu`, `trg_parametro_global_au`, `trg_param_hist_bu`, `trg_param_hist_bd`, `trg_respaldo_bu` y `trg_respaldo_bd`.
- Bitácora: `CREAR_USUARIO`, `ACTUALIZAR_USUARIO`, `ACTIVAR_USUARIO`, `DESACTIVAR_USUARIO`, `RESTABLECER_PASSWORD`, `DESBLOQUEAR_USUARIO`, `ELIMINAR_USUARIO`, `CAMBIO_PARAMETRO` y `GENERAR_RESPALDO` (base); `DESCARGAR_RESPALDO` y `VERIFICAR_RESPALDO` (backend).

### Restaurar un respaldo
Verificar primero su integridad en la pantalla. Luego, en phpMyAdmin, elegir la base `elecciones_unp` e «Importar» el archivo, o ejecutar `mysql -u root elecciones_unp < respaldo_elecciones_unp_AAAAMMDD_HHMMSS.sql`. El archivo desactiva las llaves foráneas durante la carga, reemplaza tablas, vistas y rutinas, y crea los triggers al final para que las reglas no rechacen los datos. Se probó restaurando un respaldo en una base vacía: las filas de todas las tablas coinciden con el original.

## Archivos
- Backend: `backend/src/main/java/pe/unp/elecciones/electoral/administracion/` (`AdministracionController`, `GestionarUsuarios`, `ActualizarParametros`, `RespaldarBD`, `AdministracionConsulta`, `AdministracionDto`). Cambios en `auth/AuthController` (intentos y bloqueo parametrizados; se quitaron las altas y cambios sin validación), `auth/UsuarioService`, `auth/Usuario`, `electoral/controller/ParametrosController` (solo lectura) y `AuditoriaController` (acciones nuevas). `application.yml`: `app.respaldo.directorio`.
- Frontend: `frontend/src/pages/administracion/` (`PantallaAdministrador.jsx`, `ReporteAdministracion.js` con la ficha de acceso, los parámetros vigentes y la constancia de respaldo, `administracion.css`). `DashboardPage.jsx`: entrada «Usuarios y parámetros» en el menú del Admin. `CambiarPasswordObligatorioPage.jsx`: textos para la contraseña provisional. Se eliminaron `UsuariosPage.jsx` y `ParametrosPage.jsx`.

## Botones de la pantalla
- **Generales:** «Actualizar», pestañas «Cuentas y roles», «Parámetros» y «Respaldo de la base» (se marcan en ámbar si hay cuentas bloqueadas o si no hay respaldo de la última semana).
- **Cuentas y roles:** «Nueva cuenta», tarjetas de rol (en el alta y como filtro), búsqueda de docente, «Cambiar docente», «Generar provisional segura» / «Escribirla», «Crear cuenta», filtros por estado y búsqueda, «Gestionar» / «Cerrar». En la contraseña provisional: «Copiar», «Imprimir ficha de acceso» y «Ya la entregué · ocultar». En la ficha: «Editar rol o docente» → «Guardar cambios», «Restablecer contraseña» → «Restablecer», «Desbloquear», «Desactivar» / «Activar», «Eliminar», «Imprimir ficha» y «Cerrar».
- **Parámetros:** «Imprimir parámetros», «Modificar» / «Cerrar» en cada parámetro, «Actualizar», «Descartar», «Restaurar» en el historial del parámetro y el filtro del historial general.
- **Respaldo:** «Generar respaldo» → «Generar», y en cada respaldo «Descargar», «Verificar integridad» e «Imprimir constancia».
- Cada acción que cambia datos pide confirmación («Volver» / «Confirmar»).

## Prueba rápida (verificada con MariaDB, la API y el navegador)
1. Ejecutar `17_administracion_usuarios_parametros.sql` sobre la base existente (o crearla con `00`). Para tener docentes, `03_demo_flujo_completo.sql` y `CALL sp_demo_flujo_completo();`. Entrar como `admin`.
2. «Nueva cuenta» → «Miembro de mesa» → buscar «Demo 001» → la verificación advierte que no fue sorteado → «Crear cuenta» → «Confirmar»: aparece la contraseña provisional. Repetir con el mismo docente y rol: «el docente ya tiene una cuenta con el rol MIEMBRO_MESA» y el botón queda deshabilitado.
3. En la ficha: «Desactivar» con motivo → «Activar» → «Restablecer contraseña» (nueva provisional) → «Editar rol o docente» a Docente elector. En la propia cuenta del Admin, «Desactivar» y «Eliminar» están deshabilitados. Una cuenta CEUNP recién creada sin actividad se elimina.
4. Cerrar sesión y entrar con la cuenta nueva y su contraseña provisional: pide el cambio; tras cambiarla entra a su panel. Cinco contraseñas erradas bloquean la cuenta 15 minutos; «Desbloquear» la libera.
5. «Parámetros» → UIT → valor 0: «No puede ser menor que 1». Valor 5600 con motivo: la vista previa muestra S/ 140.00 y S/ 168.00; «Confirmar» → «9 confirmarCambio». En su historial, «Restaurar» vuelve a 5150. Con un proceso en votación, los parámetros de la jornada aparecen bloqueados.
6. «Respaldo de la base» → «Generar respaldo» → «Confirmar»: 54 tablas, 34 vistas, 86 rutinas y 77 triggers. «Verificar integridad»: íntegro. Si se edita el archivo en el servidor: alterado. «Descargar» baja el `.sql`.
