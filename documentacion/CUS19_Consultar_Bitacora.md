# CUS19 · Consultar bitácora

**Actor:** Administrador del sistema (rol ADMIN) · **Pantalla:** menú «Bitácora» del Admin (`PantallaBitacora`, boundary «PantallaBitacora»), con tres pestañas: «Registros», «Resumen de actividad» e «Integridad». Reemplaza a la antigua página `BitacoraPage`.
**Módulo:** M01 Seguridad y administración · **Requisitos:** trazabilidad de las acciones críticas, bitácora inalterable, secreto del voto · **Reglas:** RN28 (trazabilidad: nada se borra si tiene historia), RNF05 (la bitácora nunca registra por quién se votó)
**Requiere:** sesión con rol ADMIN y cuenta activa. Cada consulta vuelve a validar el rol en la base (`sp_validar_admin`).
**Instalación:** en una base ya creada, ejecutar `base-de-datos/18_consultar_bitacora.sql` después de `17_administracion_usuarios_parametros.sql`. No hace falta recrear la base: el script solo agrega lo nuevo, sella los registros que ya existen (la primera vez) y se puede volver a ejecutar. `00_script_unico_elecciones_unp.sql` (sección 5i) ya lo incluye. `02_limpiar_datos_electorales.sql` vacía la bitácora, reinicia la cadena de sellos y deja como primer registro `REINICIAR_BITACORA`.

## Correspondencia con el diagrama de colaboración («Colaboration Consultar bitácora», `diagramas/Sistema De Elecciones.mdl`)

| Mensaje del diagrama | Frontend | Backend |
|---|---|---|
| 1 `ingresarFiltros(usuario, accion, fecha_inicio, fecha_fin)` | Panel «1 ingresarFiltros»: texto libre, usuario, acción (agrupada por módulo), fecha inicial y final; periodo (hoy, 24 h, 7 y 30 días), módulo y criticidad; «Más filtros»: rol, proceso, IP y docente referido; vistas rápidas | `GET /api/bitacora/registros?…` · `BitacoraConsulta.filtros` (valida y normaliza) |
| 2 `buscarRegistros(filtros)` | «Buscar» (o cualquier chip, vista rápida o página) | `ConsultarBitacora.buscarRegistros` |
| 3 `validarRolAdministrador(id_usuario)` | — | `sp_validar_admin` (ADMIN activo en la base, además de `@PreAuthorize`) |
| 4 `consultar(filtros)` | — | `v_bitacora` (registro + usuario, rol, docente, proceso y acción catalogada), paginada en el orden de la cadena |
| 5 `mostrarRegistros(lista)` | Tabla paginada (25 a 200 por página, más recientes o más antiguos primero), indicadores y pestaña «Resumen de actividad» | Página, total y resumen del resultado (por módulo, criticidad, acción, cuenta, día y hora) |
| 6 `seleccionarRegistro(id_log)` | Fila o botón «Ver» | `GET /api/bitacora/registros/{id}` |
| 7 `obtenerDetalle(id_log)` | — | `VerDetalleRegistro.obtenerDetalle` |
| 8 `consultarDetalle(id_log)` | — | `sp_detalle_bitacora`: registro, anterior y siguiente de la cadena, sello recalculado |
| 9 `mostrarDetalleJSON(detalle)` | Ficha «9 mostrarDetalleJSON»: datos, detalle en vista «Legible» o «JSON», sellos y su validez, contexto de la cuenta (±30 min) y del docente | `detalle_json` interpretado con Jackson; contexto con `v_bitacora` |

### Cambios que conviene hacer en el diagrama
- Falta la **verificación de integridad**: `verificarIntegridad()` → control `VerificarBitacora` → `LogAuditoria` (recalcula el sello SHA-256 encadenado de cada registro) → `mostrarResultado()`. Conviene una entidad `BitacoraCadena` (sello vigente) y el atributo `hash_registro` en `LogAuditoria`.
- Falta **exportar**: `exportarRegistros(filtros)` → control `ExportarBitacora` → `registrarAuditoria()` (la exportación queda en la bitácora).
- `ingresarFiltros` admite más criterios que los cuatro del diagrama (módulo, criticidad, rol, proceso, IP, docente y texto libre); conviene una entidad `BitacoraAccion` (catálogo de acciones con su módulo, caso de uso y criticidad).
- `consultarDetalle` también devuelve el registro anterior y el siguiente de la cadena (navegación) y valida el sello del registro.

## Flujo
1. **Buscar (1 a 5).** El Admin abre «Bitácora». La tabla muestra los registros más recientes. Puede escribir un texto (acción, usuario, docente, DNI, proceso, IP, contenido del detalle o `#N.º`), elegir la cuenta, la acción, el rango de fechas, el periodo, los módulos y las criticidades, o usar una vista rápida («Inicios de sesión fallidos», «Críticas y altas», «Cambios de administración», «Jornada electoral», «Sin cuenta»). Si no hay coincidencias se muestra «No se encontraron registros» con la opción de quitar los filtros (flujo alterno FA-01).
2. **Ver el detalle (6 a 9).** Al elegir un registro se abre su ficha: acción y descripción, módulo, caso de uso y criticidad, usuario y rol, docente referido, proceso, IP y navegador, el detalle JSON (legible o en bruto) y sus dos sellos con la indicación de si el contenido cambió y si está enlazado al registro anterior. Botones: «‹ N.º anterior» y «N.º siguiente ›», «Copiar JSON», «Descargar JSON», «Imprimir ficha», y filtros por la misma acción, cuenta, proceso, docente o IP.
3. **Resumen de actividad.** Totales del resultado filtrado: cuentas, procesos, IP, acciones fuera de horario (antes de 07:00 o desde 20:00), barras por módulo, criticidad, acción y cuenta, actividad por día y por hora, y las cuentas con inicios de sesión fallidos en las últimas 24 horas. Cada barra filtra la tabla.
4. **Verificar la integridad.** «Verificar integridad» → «Confirmar». El sistema recalcula todos los sellos y muestra «Bitácora íntegra» o «Bitácora alterada» con cada anomalía (registro, tipo y explicación) y el botón «Ver» del registro. «Imprimir constancia» deja el resultado y el sello final en papel. Las verificaciones anteriores se listan debajo.
5. **Exportar e imprimir.** «Exportar CSV» descarga los registros filtrados (hasta `BITACORA_EXPORTACION_MAX`, 20 000 por defecto) con su sello; «Imprimir reporte» imprime la página actual con el resumen y los filtros.

## Reglas
- **Solo lectura.** No hay pantallas ni endpoints para modificar o borrar registros; la base lo impide (`trg_log_bu`, `trg_log_bd`). Las únicas escrituras de este caso son los registros de la propia consulta sensible: `VERIFICAR_BITACORA` y `EXPORTAR_BITACORA`.
- **Sello encadenado.** Al insertarse, cada registro guarda `hash_anterior` (el sello vigente) y `hash_registro = SHA-256(hash_anterior | usuario | docente | proceso | acción | IP | navegador | fecha | detalle)` (`trg_log_bi`, `fn_hash_bitacora`). `bitacora_cadena` guarda el último sello y el total; se bloquea con `FOR UPDATE` para encadenar en orden las inserciones simultáneas. La verificación detecta: contenido alterado, enlace roto (registro borrado o insertado por fuera de la cadena), registro sin sello y registros finales eliminados.
- **Secreto del voto.** `EMITIR_VOTO` solo dice que el docente votó por un cargo; la ficha lo recuerda (RNF05).
- **Filtros.** Fechas como `AAAA-MM-DD` (día completo) o `AAAA-MM-DDTHH:MM`; la fecha inicial no puede ser posterior a la final. Rol, módulo, criticidad, acción e IP se validan; `idUsuario=0` son las acciones sin cuenta (sistema o elector).
- **Exportación.** CSV en UTF-8 con BOM y separador «;» (se abre en Excel). Las celdas que empiezan con `= + - @` se anteponen con `'` para que Excel no las ejecute. Si se supera el máximo, se exportan los primeros y la pantalla lo advierte.
- Un código de acción nuevo que no esté en `bitacora_accion` se registra y se muestra igual, como «sin clasificar».

## Endpoints
`/api/bitacora` (solo ADMIN):

| Método | Ruta | Uso |
|---|---|---|
| GET | `/` | Catálogo de acciones con su uso, cuentas, procesos, sello de la cadena, verificaciones y alertas de 24 horas |
| GET | `/registros?texto&idUsuario&rol&accion&modulo&criticidad&idProceso&idDocente&ip&desde&hasta&pagina&tamano&orden&resumen` | 1-5 buscar y mostrar registros (con resumen) |
| GET | `/registros/{id}` | 6-9 detalle del registro |
| POST | `/verificacion` | Verificar la cadena de sellos: `INTEGRA`, `ALTERADA` o `VACIA` y las anomalías |
| GET | `/exportacion?…filtros&orden` | Archivo CSV (cabeceras `X-Registros` y `X-Truncado`) |

Se mantiene `GET /api/auditoria` (lo usa el contador del resumen del Admin).

## Base de datos (`18_consultar_bitacora.sql`)
- Columnas nuevas en `log_auditoria`: `hash_anterior` y `hash_registro`; índices por usuario, proceso e IP con la fecha.
- Tablas: `bitacora_accion` (96 códigos con etiqueta, descripción, módulo, caso de uso y criticidad) y `bitacora_cadena` (sello vigente).
- Parámetro nuevo: `BITACORA_EXPORTACION_MAX` (20 000, grupo Seguridad del CUS18, de 100 a 100 000).
- Función: `fn_hash_bitacora`. Triggers: `trg_log_bi` (sella) y `trg_log_ai` (último N.º); `trg_log_bu` se recrea igual.
- Vista: `v_bitacora`.
- Procedimientos: `sp_detalle_bitacora`, `sp_verificar_bitacora` y `sp_registrar_exportacion_bitacora`.

## Pruebas realizadas
- MariaDB 10.11: `00` completo + demo (`sp_demo_flujo_completo`), y `18` sobre una base con registros previos, dos veces seguidas: sella los existentes en orden y la verificación da «íntegra».
- Inserciones por procedimientos, por `Bitacora.java` y por JPA (inicio de sesión) quedan selladas.
- Modificar un registro y borrar otro con los triggers quitados: la verificación marca «contenido alterado» y «enlace roto» en el registro correcto.
- `02_limpiar_datos_electorales.sql`: la cadena vuelve a empezar con `REINICIAR_BITACORA` y sigue íntegra.
- Backend: filtros combinados, errores de validación (rol, fecha), registro inexistente, verificación y exportación CSV.
- Frontend: búsqueda, detalle, resumen, verificación íntegra y alterada en el navegador, sin errores de consola.

## Observación
`EMITIR_VOTO` guarda el docente y la hora exacta, y los votos se numeran en el mismo orden. Aunque `voto.fecha_hora` se trunca a la hora, quien tenga acceso directo a la base podría correlacionar por orden de inserción. No lo cambia este caso de uso; conviene revisarlo en el de emisión del voto.
