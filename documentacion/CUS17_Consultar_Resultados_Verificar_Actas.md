# CUS17 · Consultar resultados y verificar actas

**Actores:** Docente elector (consulta los resultados) y Personero de mesa (escanea el QR del acta y la coteja con su ejemplar); también CEUNP, ADMIN y miembros de mesa. El CEUNP atiende las discrepancias reportadas. Cualquier persona, sin sesión, consulta los resultados y verifica un documento en el portal público · **Pantalla:** menú «Resultados y verificar actas» (`PantallaResultados`, boundary «PantallaResultados») y el portal `/resultados` y `/verificar/{código}` (`PortalResultados`), enlazado desde la pantalla de inicio de sesión con «Consultar resultados y verificar actas»
**Módulos:** M07 (actas con QR) y M12 (portal de transparencia) · **Requisitos:** RF52 (QR en cada acta), RF55 (verificación pública de autenticidad), RF99 (resultados solo después de su publicación) · **Reglas:** RN15 (transparencia sin revelar el voto), RN26 (actas emitidas inalterables), RN28 (las actas no se modifican ni eliminan)
**Requiere:** un proceso con el cómputo publicado por el CEUNP (CUS14, `computo_proceso.estado = PUBLICADO`). Los procesos computados antes de CUS14 (cómputo heredado) se muestran si están FINALIZADOS o ANULADOS y tienen resultados.
**Instalación:** en una base ya creada, ejecutar `base-de-datos/16_resultados_verificacion.sql` después de `15_omisos_multas.sql`. No hace falta recrear la base: el script solo agrega lo nuevo y se puede volver a ejecutar. `00_script_unico_elecciones_unp.sql` (sección 5g) ya lo incluye y `02_limpiar_datos_electorales.sql` ya vacía sus tablas.

## Correspondencia con el diagrama de colaboración («Colaboration - Consultar resultados y verificar actas», `diagramas/Sistema De Elecciones.mdl`)

| Mensaje del diagrama | Frontend | Backend |
|---|---|---|
| 1 `seleccionarProceso()` | Selector «1 seleccionarProceso · proceso electoral» (procesos con resultados publicados, con su participación) | `GET /api/resultados/procesos` (o `/api/publico/consulta/procesos`) → `ConsultarResultados.procesos` → `v_resultados_procesos` |
| 2 `obtenerResultados()` | Al elegir el proceso; «Actualizar» | `GET /api/resultados/procesos/{id}` (o `/api/publico/consulta/procesos/{id}`) → `ConsultarResultados.obtenerResultados` |
| 3 `verificarComputoCerrado()` | Aviso verde «Resultados publicados · fecha · resolución» o el motivo por el que aún no hay resultados | `ResultadosConsulta.procesoConResultados` → `fn_resultados_disponibles` |
| 4 `consultarResultados()` | Pestañas «Resultados» (por cargo y lista) y «Resultados por mesa» | `ResultadosConsulta.detalle` → `v_computo_resultados` / `resultado_electoral` y `v_resultados_mesa` |
| 5 `devolverResultados()` | Tarjetas de resultado, participación, mesas y verificaciones | Respuesta con `cargos`, `mesas`, `documentos`, `nulidades`, `segundaVuelta` y `verificaciones` |
| 6 `mostrarResultados()` | Lista ganadora, barras con la línea del mínimo para ganar, válidos, blancos, nulos y emitidos; «Imprimir resultados» y «Imprimir resultados por mesa» | — |
| 7 `escanearQR` | Pestaña «Verificar acta»: cámara o pistola lectora, o la huella SHA-256 escrita; en el portal, el QR abre `/verificar/{token}` | — |
| 8 `verificarActa()` | «Verificar» | `POST /api/resultados/verificacion` (o `GET /api/publico/verificacion/{código}`) → `VerificarActa.verificar` |
| 9 `consultarPorToken()` | Bloque «9 consultarPorToken · contenido del documento digital» | `sp_localizar_documento` (token del QR o huella) dentro de `sp_verificar_documento` |
| 10 `recalcularHash()` | Bloque «10 recalcularHash()»: huella registrada al emitir y huella recalculada ahora | `sp_verificar_documento`: `SHA2(contenido_json, 256)` comparado con `hash_integridad` |
| 11 `mostrarAutenticidad()` | Resultado «Documento auténtico», «Documento alterado», «Documento anulado» o «Documento no encontrado»; «Imprimir constancia de verificación» y, con sesión, «Cotejar con mi ejemplar físico» | Fila de `sp_verificar_documento` registrada en `verificacion_documento` |

### Cambios que conviene hacer en el diagrama
- Después del 11 falta el cotejo del personero, que es para lo que escanea el QR: `cotejarActa(codigo, cifras_fisicas, observacion)` en el control `verificarActa`, que compara cada cifra del ejemplar impreso con el documento digital y, si difieren, reporta la discrepancia al CEUNP.
- Falta la atención de la discrepancia por el CEUNP: `atenderDiscrepancia(id_cotejo, decision, respuesta)` (aclarada o fundada).
- `consultarPorToken()` también recibe la huella SHA-256 impresa al pie del documento, para cuando el QR no se puede leer, y sirve para todos los documentos con QR (actas de instalación, sufragio y escrutinio, acta general de cómputo, resoluciones de proclamación, nulidad y multas, y constancia de voto), no solo para el acta de escrutinio.
- Conviene una entidad `VerificacionDocumento` que registre cada consulta (paso 10-11), porque el resultado de la verificación forma parte de la transparencia del proceso.

## Flujo
1. **Seleccionar el proceso (RF99).** Solo aparecen los procesos con el cómputo publicado. El docente entra a «Resultados»; el personero y el miembro de mesa entran directamente a «Verificar acta».
2. **Resultados por cargo.** Para cada cargo: la lista ganadora con su credencial y candidatos, los votos y el porcentaje de cada lista sobre los válidos, con la línea del mínimo que exige el reglamento (primera vuelta: más del 50 % de los válidos), y los votos en blanco, nulos y emitidos. Si hubo nulidades publicadas o segunda vuelta, se informan.
3. **Resultados por mesa.** Por cargo: votos de cada lista, blancos y nulos de cada mesa, con su origen (acta de escrutinio o urna digital) y los botones de sus actas; cada botón verifica el acta al instante.
4. **Verificar un documento (RF52, RF55).** Se escanea el QR o se escribe la huella. El sistema localiza el documento, recalcula el SHA-256 de su contenido y lo compara con la huella guardada al emitirlo. Muestra el tipo de documento, proceso, mesa, fecha, estado, firmas, el contenido digital y la constancia de verificación para imprimir. Cada consulta queda registrada con el canal (QR, código, lista o portal).
5. **Cotejar el ejemplar físico (personero).** Con sesión, en un acta de instalación, sufragio, escrutinio, acta general de cómputo o resolución de proclamación, el personero anota las cifras de su ejemplar impreso y pulsa «Comparar». Si todas coinciden, «Registrar cotejo conforme»; si alguna difiere, describe la discrepancia y la reporta al CEUNP. Siempre confirma antes de registrar.
6. **Atender la discrepancia (CEUNP).** En «Cotejos» el CEUNP ve los cotejos del proceso por estado, abre el reportado, lo declara «Aclarada» (error de lectura o transcripción) o «Fundada» (procede revisar el acta en el cómputo o tramitar la nulidad, CUS15) con su respuesta, y confirma. El personero ve la respuesta en sus cotejos.

## Reglas
- **RF99:** sin cómputo publicado no hay resultados, ni en la pantalla ni en el portal ni por la API (`fn_resultados_disponibles`).
- **RN15:** ninguna consulta revela el voto de un docente. La verificación de una constancia de voto solo dice si es auténtica; la de la resolución de multas, solo sus totales.
- **RF55:** el resultado es `AUTENTICA` si la huella recalculada coincide y el documento está vigente, `ALTERADA` si no coincide, `ANULADA` si el documento fue anulado y `NO_ENCONTRADA` si el código no corresponde a ningún documento. El código aceptado es el token del QR o la huella SHA-256 (64 caracteres hexadecimales), aunque venga dentro de la URL del QR.
- **RN26 / RN28:** las verificaciones y los cotejos no se modifican ni se borran (`trg_verificacion_doc_bu`, `trg_verificacion_doc_bd`, `trg_cotejo_bd`). Un cotejo solo pasa de OBSERVADO a ATENDIDO, sin cambiar sus cifras (`trg_cotejo_bu`).
- **Cotejo:** no procede sobre la constancia de voto, la resolución de multas ni la de nulidad. Se exigen todas las cifras, enteras y no negativas. Si alguna difiere o el documento no está íntegro, la observación es obligatoria (10 caracteres como mínimo). Un mismo usuario no puede tener dos discrepancias pendientes sobre el mismo documento. Si quien coteja es personero acreditado, el cotejo queda a nombre del personero y su lista.
- **Atención:** solo el CEUNP, solo sobre un cotejo OBSERVADO, con decisión ACLARADA o FUNDADA y una respuesta de 10 caracteres como mínimo.
- El portal público no pide sesión; para cotejar hay que iniciar sesión («Inicie sesión para cotejar su ejemplar»).

## Endpoints
`/api/resultados` (con sesión):

| Método | Ruta | Uso |
|---|---|---|
| GET | `/procesos` | 1 seleccionarProceso: procesos con resultados publicados |
| GET | `/procesos/{id}` | 2-6 obtenerResultados: proceso, cargos, mesas, documentos, nulidades, segunda vuelta, verificaciones y, con sesión, los cotejos (todos para CEUNP y ADMIN, los propios para los demás) |
| POST | `/verificacion` `{codigo, canal}` | 8-11 verificarActa; canal `QR`, `CODIGO` o `LISTA` |
| POST | `/cotejos` `{codigo, idVerificacion, cifras:[{clave, fisico}], observacion}` | Cotejo del ejemplar físico |
| GET | `/cotejos?idProceso=` | Cotejos del proceso |
| POST | `/cotejos/{id}/atencion` `{decision, respuesta}` | Atención del CEUNP (solo CEUNP) |

Público (sin sesión): `GET /api/publico/consulta/procesos`, `GET /api/publico/consulta/procesos/{id}` y `GET /api/publico/verificacion/{código}` (canal `PORTAL`).

## Base de datos (`16_resultados_verificacion.sql`)
- Tablas: `verificacion_documento` (código consultado en hash, método TOKEN o HUELLA, canal, documento, proceso, mesa, resultado, usuario, rol, IP y fecha) y `cotejo_acta` (documento, huella, integridad, usuario, rol, personero, cifras en JSON, líneas, diferencias, observación, estado CONFORME, OBSERVADO o ATENDIDO, y la decisión, respuesta y fecha del CEUNP).
- Función: `fn_resultados_disponibles`.
- Vistas: `v_resultados_procesos`, `v_resultados_mesa`, `v_documentos_verificables` y `v_cotejos_acta`.
- Procedimientos: `sp_localizar_documento`, `sp_verificar_documento`, `sp_registrar_cotejo_acta` y `sp_atender_cotejo_acta`.
- Triggers: `trg_verificacion_doc_bu`, `trg_verificacion_doc_bd`, `trg_cotejo_bu` y `trg_cotejo_bd`.
- Bitácora: `REGISTRAR_COTEJO_ACTA`, `REPORTAR_DISCREPANCIA_ACTA` y `ATENDER_DISCREPANCIA_ACTA`.

## Archivos
- Backend: `backend/src/main/java/pe/unp/elecciones/electoral/resultados/` (`ResultadosController`, `ConsultarResultados`, `VerificarActa`, `ResultadosConsulta`, `ResultadosDto`); `PublicoController` con el portal; `AuditoriaController` con las acciones nuevas.
- Frontend: `frontend/src/pages/resultados/` (`PantallaResultados.jsx`, `PortalResultados.jsx`, `ReporteResultados.js` con las impresiones, `resultados.css`), con el estilo de `mesa/mesa-ejecutivo.css` e `impugnaciones/impugnaciones.css`. `main.jsx` abre el portal en `/resultados` y `/verificar/{código}`; `LoginPage.jsx` lo enlaza; menú en `DashboardPage.jsx` para ADMIN, CEUNP (grupo RESULTADOS), miembro de mesa, personero y docente.
- Los QR de las actas de instalación, cómputo, nulidad, multas y de la constancia de voto apuntan ahora a `/verificar/{token}` del portal; «Ver en el portal» de la pantalla de cómputo abre `/resultados?proceso={id}`.

## Botones de la pantalla
- **Generales:** selección del proceso, «Actualizar» y las pestañas «Resultados», «Resultados por mesa», «Verificar acta» y, con sesión, «Cotejos» (se marca en ámbar si el CEUNP tiene discrepancias por atender). En el portal, «Iniciar sesión».
- **Resultados:** «Imprimir resultados».
- **Resultados por mesa:** cargos, búsqueda de mesa, «Imprimir resultados por mesa» y un botón por cada acta de la mesa (verifica el acta).
- **Verificar acta:** «Verificar», «Usar cámara», «Imprimir constancia de verificación», «Ver resultados del proceso», «Cotejar con mi ejemplar físico», «Comparar», «Registrar cotejo conforme» o «Reportar discrepancia al CEUNP», «Confirmar», «Volver», «Cancelar», «Imprimir cotejo», «Ver mis cotejos», y «Verificar» en cada documento de la tabla «Documentos con QR del proceso».
- **Cotejos:** tarjetas por estado (filtran la tabla), «Ver» / «Atender», «Aclarada» / «Fundada», «Registrar respuesta», «Confirmar», «Volver», «Imprimir cotejo» y «Cerrar».
- Cada acción que no se puede deshacer pide confirmación.

## Prueba rápida (verificada con MariaDB, la API y el navegador)
1. Ejecutar `16_resultados_verificacion.sql` sobre la base existente (o crearla con `00`). Llevar un proceso hasta «Publicar resultados» (CUS11 a CUS14).
2. Sin sesión, abrir `/resultados` (o «Consultar resultados y verificar actas» en el inicio de sesión): la lista ganadora, las barras, los totales y los resultados por mesa.
3. Abrir el QR de la resolución de proclamación (`/verificar/{token}`): «Documento auténtico», con las dos huellas iguales. Un código inexistente: «Documento no encontrado». Si se altera el contenido de un acta en la base: «Documento alterado».
4. Como personero: «Verificar acta» con la huella del acta de escrutinio de su mesa → «Cotejar con mi ejemplar físico» → cifras iguales → «Comparar» → «Registrar cotejo conforme» → «Confirmar»: cotejo Conforme. Repetir con una cifra distinta: exige la descripción y queda «Discrepancia reportada». Un segundo reporte pendiente sobre la misma acta se rechaza.
5. Como docente: «Resultados» y «Resultados por mesa»; el botón de un acta la verifica.
6. Como CEUNP: «Cotejos» → «Atender» → «Aclarada» con la respuesta → «Registrar respuesta» → «Confirmar»: el cotejo queda «Atendido por el CEUNP» y el personero ve la respuesta.
