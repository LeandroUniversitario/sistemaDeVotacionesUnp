# CUS14 · Computar y proclamar resultados

**Actor:** CEUNP (verifica, instala la sesión, computa, proclama y publica); ADMIN solo consulta · **Pantalla:** menú «Cómputo y proclamación» (`PantallaComputo`, boundary «ComputoResultado»)
**Caso de negocio:** CUN11 Computar y proclamar · **Módulo:** M12 (RF89 a RF99) · **Reglas:** RN26, RN31, RN32, RN33, RN34, RN36 · **Fuente:** tabla 39 del informe v2.1
**Requiere:** mesas con el sufragio cerrado (CUS11), el escrutinio con su acta emitida y entregada al CEUNP (CUS12, RF87) y las impugnaciones resueltas (CUS13).
**Instalación:** en una base ya creada, ejecutar `base-de-datos/13_computo_proclamacion.sql` después de `12_impugnaciones_apelaciones.sql`. `00_script_unico_elecciones_unp.sql` (sección 5d) ya lo incluye y `02_limpiar_datos_electorales.sql` ya vacía sus tablas.

## Correspondencia con el diagrama de colaboración («Colaboration - Computar y proclamar», `diagramas/Sistema De Elecciones.mdl`)

| Mensaje del diagrama | Frontend | Backend |
|---|---|---|
| 0 `solicitarComputo(idProceso)` | `PantallaComputo`: selección del proceso, «Actualizar» | `GET /api/computo/procesos/{id}` → `ComputoConsulta.detalle` |
| 1 `ejecutarComputo(idProceso)` | Paso «Cómputo oficial» → «Ejecutar cómputo oficial» → «Confirmar cómputo» | `POST /api/computo/procesos/{id}/computo` → `ComputarProclamar.ejecutarComputo` → `sp_ejecutar_computo` |
| 2 `verificarActasEntregadas(idProceso)` | Paso «Verificación previa»: tabla de mesas con su entrega y sus actas | `v_computo_mesas` (columna `situacion`) |
| 3 `actasEntregadas(totalMesas)` | KPI «Mesas habilitadas» y aviso de mesas que impiden el cómputo | `resumenMesas` y `bloqueos` del detalle; `sp_ejecutar_computo` rechaza si alguna mesa no está HABILITADA, NO_INSTALADA o ANULADA (RN32) |
| 4 `validarIntegridad(actas)` | «Revisar» mesa → «Marcar dudosa» | `POST /api/computo/actas/{id}/dudosa` → `VerificarActas.marcarDudosa` → `sp_marcar_acta_dudosa` |
| 5 `actasValidas(hashCorrecto)` | «Comprobar autenticidad»: lector QR (pistola, cámara o pegar el enlace) o «Comprobar solo la huella» | `POST /api/computo/actas/{id}/comprobacion` → `sp_comprobar_acta` (recalcula SHA-256 y compara el QR) |
| 6 `consolidarVotos(idCargo)` | Paso «Consolidación»: tabla por cargo (actas, impugnados asignados, votos, digital) | `v_computo_conteo_mesa` y `v_computo_resultados` |
| 7 `totalesPorLista(votos)` | Votos y % de válidos por lista con la marca del mínimo | `ComputoConsulta.consolidado` (proyección) y `resultado_electoral` (oficial) |
| 8 `calcularParticipacion(idCargo)` | Tabla «Participación por cargo» y KPI | `v_participacion_cargo`, `v_quorum_proceso` |
| 9 `porcentajeParticipacion(porcentaje)` | Barra con la marca del 60 % | Igual |
| 10 `validarQuorum(porcentaje)` | Lista de requisitos del paso «Cómputo oficial» | `sp_ejecutar_computo`: SIN_QUORUM por cargo; si ningún cargo lo supera, nulidad total (A1) |
| 11 `quorumValidado(estado)` | Aviso de nulidad o de elección válida | `computo_proceso.resultado` (VALIDA o NULIDAD_TOTAL) |
| 12 `[quorum > 60%] registrarComputo(totales)` | — | `resultado_electoral` (VALIDO con % y puesto, BLANCO, NULO), acta general JSON con huella y token QR |
| 13 `computoRegistrado(resultados)` | Datos del cómputo, «Imprimir acta general (con QR)», «Verificar QR» | La respuesta trae `tokenQr` y el detalle |
| 14 `determinarGanador(resultados)` | Tabla «determinarGanador» | `cargo_electoral.estado_resultado` (ELEGIDO, SEGUNDA_VUELTA, EMPATE, SIN_QUORUM, DESIERTO) |
| 15 `ganadorOSegundaVuelta(idLista)` | Estado por cargo y bloque «A2 · Segunda vuelta» | `id_lista_ganadora`; A2 con `POST /segunda-vuelta` → `sp_convocar_segunda_vuelta` |
| 16 `[supera minimo] acreditarGanadora(idLista)` | Paso «Proclamación» → resolución, Pleno, Presidente → «Confirmar proclamación» | `POST /api/computo/procesos/{id}/proclamacion` → `ComputarProclamar.proclamar` → `sp_proclamar_resultados` |
| 17 `listaAcreditada()` | Tabla de listas proclamadas con su código, «Imprimir resolución» e «Imprimir credencial» | `proclamacion_cargo` (código de credencial único) |
| 18 `mostrarResultados(resultados)` | Paso «Publicación» → «Publicar resultados» → «Confirmar publicación» | `POST /api/computo/procesos/{id}/publicacion` → `sp_publicar_resultados` |
| 19 `resultadosProclamados()` | Confirmación, «Ver en el portal» y resultados por mesa | `GET /api/publico/procesos/{id}/resultados` y `/api/publico/resultados` (solo PUBLICADO, RF99) |

### Cambios que conviene hacer en el diagrama
- Falta el control de la verificación previa (pasos 1 a 3 de la tabla 39). Se implementó como `VerificarActas` con los mensajes `marcarDudosa(idActa, motivo)`, `comprobarAutenticidad(idActa, qr)` y `calificarMesa(idMesa, calificacion)` (A3 y paso 7).
- Falta el control de la sesión de cómputo (paso 4, RF91). Se implementó como `SesionComputo` con `instalarSesion(lugar, miembros, personeros)` y `registrarPersonero(idPersonero)`.
- El mensaje 16 debe llevar los datos del Pleno que exige RN36: `acreditarGanadora(idLista, nResolucion, miembros, presidente)`.
- Falta el flujo alterno A2 hacia la convocatoria: `convocarSegundaVuelta(idProceso, fechaInicio, fechaFin)`.

## Flujo
1. **Verificación previa.** Si el proceso sigue en VOTACION, el CEUNP pulsa «Concluir votación» (todas las mesas cerradas o no instaladas). El sistema lista las mesas instaladas y no instaladas y las tres actas de cada una con su huella SHA-256.
2. El CEUNP marca como dudosa el acta que no coincide con su ejemplar físico y comprueba su autenticidad con el QR. Si no es auténtica, solo procede declarar la nulidad de la mesa.
3. Si el acta de escrutinio difiere del conteo digital u observada (A3), el CEUNP la califica: VÁLIDA (se computa la cédula física, RF84) o NULIDAD con número de resolución (paso 7). La mesa anulada no se computa.
4. **Sesión de cómputo.** El CEUNP la instala con quórum (5 de 9) y registra los personeros presentes; los que lleguen después se registran antes del cómputo.
5. **Consolidación.** Muestra los votos de las actas habilitadas, con las impugnadas asignadas por la mesa o el CEUNP, y la participación de cada cargo.
6. **Cómputo oficial.** Solo se habilita sin mesas pendientes. Registra los resultados, valida el quórum (más del 60 %), decide ganador o segunda vuelta y emite el acta general con QR. El proceso pasa a FINALIZADO, o a ANULADO si ningún cargo alcanza el quórum (A1).
7. **Proclamación.** El Presidente del CEUNP proclama en sesión del Pleno; cada lista ganadora recibe su código de credencial. Se emite la resolución con QR.
8. **Publicación.** Los resultados generales y por mesa se publican en el portal. Si la elección se anuló, se publica el acta general con la nulidad y se imprime la comunicación a SUNEDU, la Asamblea Universitaria y el Consejo Universitario.
9. **A2.** Si un cargo queda en SEGUNDA_VUELTA, el CEUNP la convoca dentro de 15 días desde el cómputo; se crea un proceso nuevo con las dos listas más votadas y el mismo padrón.

## Reglas
- **RN32:** el cómputo se hace con el proceso CERRADO y con todas las mesas en situación HABILITADA, NO_INSTALADA o ANULADA. Bloquean: sufragio abierto, escrutinio pendiente, actas sin entregar o incompletas, acta dudosa sin comprobar, acta no auténtica sin nulidad, impugnaciones pendientes o en plazo de apelación y acta por calificar.
- **RF90:** un acta se marca dudosa una sola vez (motivo de 10 caracteres o más) y se comprueba una sola vez. El QR leído puede ser el token o el enlace completo de verificación.
- **RF95 / RF94:** la calificación VÁLIDA solo procede en un acta que difiere y es auténtica; la NULIDAD exige número de resolución único (también frente a las resoluciones de impugnaciones y de proclamación). La decisión es inapelable (RN36).
- **RN36:** la sesión y la proclamación exigen el quórum del Pleno (`CEUNP_QUORUM_PLENO`, 5).
- **RN31 / RN34:** un cargo con participación de 60 % o menos queda SIN_QUORUM; si ninguno lo supera, nulidad total del proceso.
- **RF96 / RF97 / RN33:** gana la lista con más del mínimo del cargo (`porcentaje_minimo_victoria`); si no, o hay empate, SEGUNDA_VUELTA. En segunda vuelta gana la mitad más uno; si no, EMPATE. Plazo: `SEGUNDA_VUELTA_PLAZO_DIAS` (15).
- **RN26:** cómputo único e irreversible. Los triggers impiden retroceder de etapa, cambiar el acta general, la proclamación o las credenciales, y registrar personeros después del cómputo.
- **RF99:** el portal público solo muestra resultados con el cómputo en PUBLICADO. Un proceso computado con el cómputo heredado (`sp_computar_resultados`, sin CUS14) se sigue mostrando como antes.
- Los tokens del QR solo se devuelven al emitir el acta general y la resolución. La pantalla los guarda en la sesión del navegador para reimprimir con QR; en otro navegador la reimpresión lleva la huella SHA-256.

## Endpoints (`/api/computo`, ADMIN y CEUNP; las acciones solo CEUNP)
| Método | Ruta | Uso |
|---|---|---|
| GET | `/procesos` | Procesos con mesas en votación, cerrados o computados |
| GET | `/procesos/{id}` | Detalle: mesas, actas, consolidado, participación, sesión, personeros, resultados, proclamados, acciones habilitadas y bloqueos |
| GET | `/procesos/{id}/resultados-mesa` | Resultados por mesa |
| GET | `/mesas/{id}` | Actas, conteo e impugnaciones de una mesa |
| POST | `/procesos/{id}/concluir-votacion` | VOTACION → CERRADO |
| POST | `/procesos/{id}/sesion` `{lugar, miembrosCeunp, observaciones, personeros[]}` | Instala la sesión (RF91) |
| POST | `/procesos/{id}/sesion/personeros` `{idPersonero}` | Registra un personero que llega |
| POST | `/actas/{id}/dudosa` `{motivo}` | Marca el acta dudosa |
| POST | `/actas/{id}/comprobacion` `{tokenQr, observacion}` | Comprueba la autenticidad |
| POST | `/mesas/{id}/calificacion` `{calificacion, fundamento, numeroResolucion}` | VALIDA o NULIDAD |
| POST | `/procesos/{id}/computo` | Cómputo oficial; devuelve `tokenQr` |
| POST | `/procesos/{id}/proclamacion` `{numeroResolucion, miembrosPleno, presidente, fundamento}` | Proclamación; devuelve `tokenQr` |
| POST | `/procesos/{id}/publicacion` | Publicación en el portal |
| POST | `/procesos/{id}/segunda-vuelta` `{fechaInicio, fechaFin}` | A2; devuelve `idProcesoNuevo` |

Públicos (sin sesión): `GET /api/publico/computo/{token}` (verifica el acta general o la resolución), `GET /api/publico/resultados` y `GET /api/publico/procesos/{id}/resultados` (con la proclamación y los resultados por mesa). `POST /api/procesos/{id}/computo` (heredado) usa ahora `sp_ejecutar_computo` cuando el CUS14 está instalado.

## Base de datos (`13_computo_proclamacion.sql`)
- Tablas: `computo_proceso` (sesión, cómputo con acta general, proclamación y publicación), `computo_personero`, `verificacion_acta`, `calificacion_mesa` y `proclamacion_cargo`.
- Vistas: `v_computo_actas`, `v_computo_mesas`, `v_computo_conteo_mesa`, `v_computo_resultados` y `v_portal_resultados`.
- Procedimientos: `sp_instalar_sesion_computo`, `sp_registrar_personero_computo`, `sp_marcar_acta_dudosa`, `sp_comprobar_acta`, `sp_calificar_mesa`, `sp_ejecutar_computo`, `sp_proclamar_resultados`, `sp_publicar_resultados`, `sp_convocar_segunda_vuelta` y `sp_verificar_acta_computo`.
- Triggers: `trg_computo_bu`, `trg_computo_bd`, `trg_cpersonero_bi`, `trg_verificacion_bu`, `trg_verificacion_bd`, `trg_calificacion_bu`, `trg_calificacion_bd`, `trg_proclamacion_bu` y `trg_proclamacion_bd`.
- Parámetros: `SEGUNDA_VUELTA_PLAZO_DIAS` (15) y `CEUNP_QUORUM_PLENO` (5, del CUS13).
- Bitácora: `INSTALAR_SESION_COMPUTO`, `REGISTRAR_PERSONERO_COMPUTO`, `MARCAR_ACTA_DUDOSA`, `COMPROBAR_ACTA`, `CALIFICAR_ACTA`, `DECLARAR_NULIDAD_MESA`, `COMPUTAR_RESULTADOS`, `PROCLAMAR_RESULTADOS`, `PUBLICAR_RESULTADOS` y `CREAR_SEGUNDA_VUELTA`.

## Archivos
- Backend: `backend/src/main/java/pe/unp/elecciones/electoral/computo/` (`ComputoController`, `SesionComputo`, `VerificarActas`, `ComputarProclamar`, `ComputoConsulta`, `ComputoDto`); `ProcesoService` y `PublicoController` para el portal.
- Frontend: `frontend/src/pages/computo/` (`PantallaComputo.jsx`, `ActaComputo.js`, `computo.css`, con el estilo ejecutivo de `mesa/mesa-ejecutivo.css`). Menú en `DashboardPage.jsx`.

## Botones de la pantalla
- **Generales:** selección del proceso, «Actualizar» y las seis pestañas (Verificación previa, Sesión de cómputo, Consolidación, Cómputo oficial, Proclamación, Publicación), que se marcan en verde al completarse.
- **Verificación previa:** «Concluir votación», «Imprimir verificación», «Revisar» (por mesa), «Marcar dudosa», «Comprobar autenticidad» (lector QR, «Usar cámara», «Verificar» y «Comprobar solo la huella»), «Calificar acta válida» y «Declarar nulidad de la mesa».
- **Sesión:** selección de personeros presentes, «Instalar sesión» y «Registrar llegada».
- **Consolidación:** «Imprimir resultados por mesa».
- **Cómputo oficial:** «Ejecutar cómputo oficial», «Imprimir acta general (con QR)», «Verificar QR», «Imprimir comunicación de nulidad» (A1) y «Convocar segunda vuelta» (A2).
- **Proclamación:** «Proclamar resultados», «Imprimir resolución», «Imprimir credencial» por lista y «Verificar QR».
- **Publicación:** «Publicar resultados», «Ver en el portal» e «Imprimir resultados por mesa».
- Cada acción que no se puede deshacer pide confirmación.

## Prueba rápida (verificada con MariaDB 10.11 y el navegador)
1. Ejecutar `13_computo_proclamacion.sql` (o crear la base con `00`). Tener un proceso en VOTACION con sus mesas cerradas, escrutadas y con actas entregadas (CUS11 y CUS12).
2. CEUNP: «Cómputo y proclamación» → «Concluir votación». Una mesa con impugnaciones pendientes aparece como bloqueo hasta resolverlas (CUS13).
3. «Revisar» una mesa → «Marcar dudosa» el acta de escrutinio → «Comprobar autenticidad» con su QR: auténtica. Con el QR de otra acta: NO auténtica; entonces «Calificar acta válida» se rechaza y «Declarar nulidad» con resolución anula la mesa.
4. En una mesa con el acta observada o que difiere, «Calificar acta válida».
5. «Sesión de cómputo»: con 4 miembros el sistema exige quórum; con 5 se instala. «Registrar llegada» de otro personero.
6. «Cómputo oficial» → «Ejecutar cómputo oficial»: el proceso pasa a FINALIZADO. Intentar de nuevo: RN26.
7. «Proclamación» con 4 miembros: exige quórum; con 5 proclama y entrega la credencial. «Publicación» → el portal ya muestra los resultados (antes respondía RF99).
8. Con menos del 60 % de participación, el cómputo declara la nulidad total (A1) y se publica sin proclamar. Con un cargo sin mínimo, «Convocar segunda vuelta» dentro de 15 días crea el proceso nuevo; fuera del plazo se rechaza.
