# CUS16 · Reportar omisos y multas

**Actor:** CEUNP (genera las multas, el Pleno las determina, notifica, resuelve descargos y registra pagos); ADMIN solo consulta; el DOCENTE consulta sus multas · **Pantalla:** menú «Omisos y multas» (`PantallaMultas`, boundary «PantallaMultas») y, para el docente, «Mis multas» (`MisMultas`)
**Caso de negocio:** CUN12 Aplicar multas por omisión · **Módulo:** M14 (RF103 a RF107) · **Reglas:** RN35, RN36, RN40 · **Reglamento:** Art. 67 (miembro de mesa que no asiste, 3 % de la UIT), Art. 68 (docente que no vota, 2.5 % de la UIT), Disposiciones Finales 2.ª y 5.ª (justificación)
**Requiere:** el proceso con la votación concluida (CERRADO, FINALIZADO o ANULADO) y todas sus mesas con el sufragio cerrado (CUS11). La UIT y los porcentajes se configuran en «Parámetros» (RF105).
**Instalación:** en una base ya creada, ejecutar `base-de-datos/15_omisos_multas.sql` después de `14_nulidades_segunda_vuelta.sql`. No hace falta recrear la base: el script solo agrega lo nuevo y se puede volver a ejecutar. `00_script_unico_elecciones_unp.sql` (sección 5f) ya lo incluye y `02_limpiar_datos_electorales.sql` ya vacía sus tablas.

## Correspondencia con el diagrama de colaboración («Colaboration - Reportar omisos y multas», `diagramas/Sistema De Elecciones.mdl`)

| Mensaje del diagrama | Frontend | Backend |
|---|---|---|
| 1 `solicitarReporteOmisos()` | Pestaña «Reporte de omisos»: parámetros, mesas instaladas, participación y relación de omisos con filtros; «Imprimir reporte» | `GET /api/multas/procesos/{id}` → `MultasConsulta.detalle` → `v_omisos_proceso` |
| 2 `generarMultas()` | «Generar multas» (o «Volver a generar multas») → «Confirmar» | `POST /api/multas/procesos/{id}/generar` → `GenerarMultas.generar` → `sp_generar_multas` |
| 3 `obtenerUIT()` | Bloque «3 obtenerUIT()» y la barra superior con UIT, porcentajes y montos | `MultasConsulta.parametros` → `parametro_global` (UIT, MULTA_ELECTOR_OMISO_PCT, MULTA_MIEMBRO_MESA_OMISO_PCT) |
| 4 `consultarNoVotaron()` | Filas «Omisión al sufragio» (Art. 68 · RF103) | `v_omisos_proceso`: elector hábil que no votó por ningún cargo y cuya mesa se instaló |
| 5 `consultarInasistentes()` | Filas «Inasistencia a la mesa» (Art. 67 · RF104) con el rol | `v_omisos_proceso`: miembro titular con `asistio = 0` |
| 6 `insertar()` | Tabla «6 insertar · multas generadas» con UIT y porcentaje de cada una | `multa` (upsert) y `reporte_multas` |
| 7 `mostrarReporteMultas()` | Pestaña «Multas y resolución»: «Emitir resolución del Pleno» → «Confirmar», «Imprimir resolución con QR», «Notificar multas pendientes» e «Imprimir cédulas» | `POST /procesos/{id}/resolucion` → `sp_emitir_resolucion_multas`; `POST /procesos/{id}/notificacion` → `sp_notificar_multas`; `GET /procesos/{id}/resolucion` |
| 8 `registrarJustificacion` | Pestaña «Descargos y pagos» → «Gestionar» la multa → «Registrar justificación» | `POST /api/multas/{id}/justificacion` → `RegistrarJustificacion.justificar` |
| 9 `justificar()` | Tipo, causal, sustento, documento, resolución, Pleno y decisión → «Resolver descargo» | `sp_registrar_justificacion` |
| 10 `actualizarEstado()` | La multa pasa a «Justificada» o «Exonerada» (o sigue «Pendiente» si se deniega) | `multa.estado_pago` |
| 11 `confirmar()` | «11 Confirmar» y la tabla «11 confirmar · descargos resueltos» con «Resolución» para imprimirla | Fila de confirmación que devuelve `sp_registrar_justificacion` |

### Cambios que conviene hacer en el diagrama
- Entre el 6 y el 7 falta la resolución del Pleno que determina las multas (RN35, RN36): `emitirResolucion(id_proceso, nResolucion, miembros)` en `GenerarMultas`. Antes de ella las multas se pueden volver a generar; después quedan fijas.
- Falta la notificación al docente, de la que corre el plazo de justificación: `notificar(id_multa, medio, documento)`.
- `justificar()` necesita la decisión del Pleno (ADMITIDA o DENEGADA) y su número de resolución; la exoneración de oficio (RN40) es otra variante del mismo mensaje.
- Falta el registro del pago con el recibo de Tesorería: `registrarPago(id_multa, recibo)`. El sistema no cobra (CUN12).

## Flujo
1. **Reporte de omisos (RF103, RF104).** Con el sufragio cerrado, la pantalla muestra a los docentes que no votaron y a los miembros titulares de mesa que no asistieron, con la multa que les corresponde con la UIT vigente. No figuran los electores de mesas que no se instalaron, porque no pudieron votar (RF58). Quien asistió a la mesa y no votó (CUS10 A3) figura marcado para que el CEUNP evalúe su justificación.
2. **Generar multas (RN35).** `sp_generar_multas` inserta o recalcula las multas con la UIT y el porcentaje vigentes (2.5 % al omiso al sufragio, 3 % al miembro de mesa) y retira las pendientes que ya no corresponden. Se puede repetir mientras no haya resolución; si cambian la UIT, los porcentajes o los omisos, la pantalla avisa que el reporte está desactualizado y no deja emitir la resolución.
3. **Resolución del Pleno (RN36).** Con quórum (`CEUNP_QUORUM_PLENO`, 5) el Pleno determina las multas con un número de resolución único en todo el sistema. Se guarda su contenido en JSON con huella SHA-256 y un token para el QR. Desde ese momento las multas no se regeneran, no se agregan, no cambian de monto ni se eliminan.
4. **Notificación.** Todas las multas pendientes o una sola, por correo institucional, cédula personal (exige el número de cédula) o portal electoral. Se imprime una cédula de notificación por docente. La notificación registrada no se modifica.
5. **Descargo (RF106, RN40).** El docente presenta su justificación dentro de `MULTA_PLAZO_JUSTIFICACION_DIAS` (10) días de notificado; el Pleno la admite (multa JUSTIFICADA) o la deniega (sigue PENDIENTE). Solo hay una justificación por multa. Para lo no previsto, o cuando ya venció el plazo o se denegó la justificación, el CEUNP puede exonerar de oficio (multa EXONERADA). Cada decisión lleva su número de resolución y se imprime.
6. **Pago.** Se registra con el número de recibo de Tesorería (único) y la fecha. La multa pagada, justificada o exonerada no vuelve a PENDIENTE.
7. **Reportes de gestión (RF107).** Participación por mesa, mesas instaladas, asistencia de titulares y suplentes en función, incidencias por tipo, tiempo promedio de atención por elector, actas emitidas y entregadas, y multas por estado con lo recaudado. Se imprime.
8. **Mis multas (docente).** El docente ve sus multas determinadas por resolución, el monto y su cálculo, la notificación, el plazo para justificarse y el resultado del descargo o el pago.

## Reglas
- **RF103:** omiso al sufragio = elector hábil del padrón que no votó por ningún cargo, en una mesa que se instaló. 2.5 % de la UIT (Art. 68).
- **RF104:** miembro de mesa omiso = titular sorteado que no se presentó (CUS08). 3 % de la UIT (Art. 67). El suplente que no fue convocado no se multa.
- **RF105:** UIT y porcentajes son parámetros. Cada multa guarda la UIT y el porcentaje con que se calculó.
- **Generación:** solo con el proceso CERRADO, FINALIZADO o ANULADO, sin mesas en PENDIENTE o INSTALADA y con al menos una mesa instalada.
- **RN35:** antes de la resolución el pago o el descargo se rechazan; después, las multas quedan fijas (`trg_multa_bi_cus16`, `trg_multa_bu_cus16`, `trg_multa_bd_cus16`). Solo `sp_generar_multas` retira, antes de la resolución, una multa pendiente que ya no corresponde.
- **RN36:** la resolución de multas y la de cada descargo exigen quórum y un número de resolución que no se haya usado en impugnaciones, calificación de mesas, proclamación, nulidades, sorteos, multas ni descargos (`fn_resolucion_en_uso` y triggers `_cus16`). Son inapelables: no se modifican ni se borran.
- **RF106:** una justificación por multa, solo si está PENDIENTE y dentro del plazo, que corre desde la notificación (o desde la resolución si aún no se notificó); la fecha de presentación no puede ser futura.
- **RN40:** la exoneración de oficio procede sobre cualquier multa pendiente y siempre es ADMITIDA.
- **Pago:** recibo único, fecha entre la resolución y hoy; `sp_actualizar_multa` (PATCH de multas del 00) solo registra pagos y exige el recibo.
- Los tokens del QR solo se devuelven al emitir la resolución. La pantalla los guarda en la sesión del navegador para reimprimir con QR; en otro navegador la reimpresión lleva la huella SHA-256. El QR abre `/api/publico/multas/{token}`, que devuelve solo totales (no la relación de docentes).

## Endpoints (`/api/multas`, ADMIN y CEUNP; las acciones solo CEUNP)
| Método | Ruta | Uso |
|---|---|---|
| GET | `/procesos` | Procesos con la votación concluida, con el estado del reporte, su resolución y las multas pendientes |
| GET | `/procesos/{id}` | Detalle: proceso, participación, parámetros, resumen de mesas, omisos, multas, reporte, desactualizado, resumen por estado, descargos, gestión por mesa, incidencias, acciones habilitadas y avisos |
| GET | `/procesos/{id}/resolucion` | 7 mostrarReporteMultas: resolución con su contenido JSON |
| GET | `/{idMulta}` | Multa con sus descargos |
| POST | `/procesos/{id}/generar` | 2-6 generarMultas |
| POST | `/procesos/{id}/resolucion` `{numeroResolucion, miembrosPleno, fundamento}` | 7 resolución del Pleno; devuelve `tokenQr` |
| POST | `/procesos/{id}/notificacion` `{idMulta, medio, documento, fecha}` | Notificación (sin `idMulta`, todas las pendientes) |
| POST | `/{idMulta}/justificacion` `{tipo, causal, sustento, documento, fechaPresentacion, decision, fundamento, numeroResolucion, miembrosPleno}` | 8-11 justificación o exoneración |
| POST | `/{idMulta}/pago` `{numeroRecibo, fechaPago, observacion}` | Pago con recibo de Tesorería |

Docente: `GET /api/multas/mias` (sus multas ya determinadas). Público (sin sesión): `GET /api/publico/multas/{token}` (verifica la resolución recalculando su SHA-256).

## Base de datos (`15_omisos_multas.sql`)
- `multa`: estado `JUSTIFICADA` y columnas `id_mesa`, `rol_mesa`, `asistio_sin_votar`, `fecha_notificacion`, `medio_notificacion`, `documento_notificacion`, `numero_recibo`, `fecha_actualizacion` e `id_usuario_actualizacion`.
- Tablas: `reporte_multas` (uno por proceso: totales, UIT, veces generado y la resolución con contenido JSON, huella y token del QR) y `multa_justificacion` (justificación o exoneración con causal, sustento, decisión y resolución).
- Función: `fn_resolucion_en_uso` (redefinida, incluye multas y descargos).
- Vistas: `v_omisos_proceso`, `v_multas_detalle` (redefinida, conserva sus columnas) y `v_reporte_gestion_mesas` (RF107).
- Procedimientos: `sp_generar_multas` (redefinido, misma firma), `sp_emitir_resolucion_multas`, `sp_notificar_multas`, `sp_registrar_justificacion`, `sp_registrar_pago_multa`, `sp_actualizar_multa` (redefinido) y `sp_verificar_resolucion_multas`.
- Triggers: `trg_multa_bi_cus16`, `trg_multa_bu_cus16`, `trg_multa_bd_cus16`, `trg_rmultas_bu`, `trg_rmultas_bd`, `trg_mjust_bu`, `trg_mjust_bd`, `trg_computo_bu_cus16`, `trg_calificacion_bi_cus16` y `trg_impugnacion_bu_cus16`.
- Parámetros que usa: `UIT`, `MULTA_ELECTOR_OMISO_PCT`, `MULTA_MIEMBRO_MESA_OMISO_PCT`, `MULTA_PLAZO_JUSTIFICACION_DIAS` (nuevo, 10) y `CEUNP_QUORUM_PLENO` (5).
- Bitácora: `GENERAR_MULTAS`, `EMITIR_RESOLUCION_MULTAS`, `NOTIFICAR_MULTAS`, `JUSTIFICAR_MULTA`, `DENEGAR_JUSTIFICACION`, `EXONERAR_MULTA` y `REGISTRAR_PAGO_MULTA`.

## Archivos
- Backend: `backend/src/main/java/pe/unp/elecciones/electoral/multas/` (`MultasController`, `GenerarMultas`, `RegistrarJustificacion`, `MultasConsulta`, `MultasDto`); `PublicoController` y `ProcesoService` para la verificación pública y «Mis multas»; `AuditoriaController` con las acciones nuevas.
- Frontend: `frontend/src/pages/multas/` (`PantallaMultas.jsx`, `MisMultas.jsx`, `ReporteMultas.js` con las impresiones, `multas.css`), con el estilo ejecutivo de `mesa/mesa-ejecutivo.css`. Menú en `DashboardPage.jsx` («Omisos y multas» en el grupo RESULTADOS del CEUNP y «Mis multas» del docente).

## Botones de la pantalla
- **Generales:** selección del proceso, «Actualizar» y las cuatro pestañas (Reporte de omisos, Multas y resolución, Descargos y pagos, Reportes de gestión) con su número; la pestaña se marca en ámbar si hay algo pendiente.
- **Reporte de omisos:** «Imprimir reporte», «Generar multas» / «Volver a generar multas», «Confirmar», filtros por motivo y búsqueda por DNI, docente o facultad.
- **Multas y resolución:** «Emitir resolución del Pleno», «Emitir resolución», «Confirmar», «Imprimir resolución con QR», «Notificar multas pendientes», «Notificar» por multa, medio de notificación, «Registrar notificación», «Imprimir cédulas», filtros por motivo y estado, «Gestionar» / «Ver».
- **Descargos y pagos:** tarjetas por estado (filtran la tabla), «Gestionar», «Registrar justificación», «Justificación del docente» / «Exoneración de oficio», causales, «Admitir» / «Denegar», «Resolver descargo», «11 Confirmar», «Registrar pago», «Confirmar», «Cerrar», y en los descargos resueltos «Multa» y «Resolución».
- **Reportes de gestión:** «Imprimir reporte de gestión».
- **Mis multas (docente):** tarjetas de resumen y una ficha por multa con su estado, plazo y resolución.
- Cada acción que no se puede deshacer pide confirmación.

## Prueba rápida (verificada con MariaDB, la API y el navegador)
1. Ejecutar `15_omisos_multas.sql` sobre la base existente (o crearla con `00` y `CALL sp_demo_flujo_completo();`, que ya genera las multas del proceso de demostración).
2. «Omisos y multas» → «Reporte de omisos»: 8 omisos al sufragio y 1 vocal inasistente. «Volver a generar multas» → «Confirmar». Si una mesa no se instaló, sus electores no aparecen.
3. «Multas y resolución» → «Emitir resolución del Pleno» con 4 miembros: exige quórum. Con 5 se emite; «Volver a generar» ya no aparece y el QR abre `/api/publico/multas/{token}` con `contenidoIntegro = 1`.
4. «Notificar multas pendientes» por correo institucional: todas quedan notificadas con el plazo de 10 días. «Imprimir cédulas» genera una hoja por docente.
5. «Descargos y pagos»: admitir una justificación por salud (Justificada), registrar el pago de otra con recibo (Pagada) y exonerar una tercera por error del padrón (Exonerada). Repetir un número de resolución ya usado: «RN36: el número de resolución ya fue usado». Una segunda justificación sobre la misma multa o fuera de plazo se rechaza.
6. «Reportes de gestión» muestra la participación por mesa, incidencias y multas por estado; «Imprimir reporte de gestión».
7. Entrar como docente con multa: «Mis multas» muestra la multa, la resolución y el plazo, o el resultado del descargo.
