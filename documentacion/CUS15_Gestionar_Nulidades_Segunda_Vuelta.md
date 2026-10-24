# CUS15 · Gestionar nulidades y segunda vuelta

**Actor:** CEUNP (registra los recursos, los resuelve en Pleno, comunica, dirime empates y convoca la segunda vuelta); ADMIN solo consulta · **Pantalla:** menú «Nulidades y segunda vuelta» (`PantallaNulidades`, boundary «PantallaNulidades»)
**Caso de negocio:** CUN12 Gestionar nulidades · **Módulo:** M13 (RF100 a RF102) · **Reglas:** RN26, RN31, RN33, RN34, RN36, RF94, RF97 · **Reglamento:** Art. 64 (nulidad de mesa), Art. 65 (nulidad de la elección), Art. 66 (comunicación)
**Requiere:** el proceso con la votación concluida (CUS14, «Concluir votación»). La nulidad parcial se plantea antes del cómputo; la total, antes de la proclamación; la segunda vuelta, después del cómputo (CUS14).
**Instalación:** en una base ya creada, ejecutar `base-de-datos/14_nulidades_segunda_vuelta.sql` después de `13_computo_proclamacion.sql`. No hace falta recrear la base: el script solo agrega lo nuevo y se puede volver a ejecutar. `00_script_unico_elecciones_unp.sql` (sección 5e) ya lo incluye y `02_limpiar_datos_electorales.sql` ya vacía sus tablas.

## Correspondencia con el diagrama de colaboración («Colaboration - Gestionar nulidades y segunda vuelta», `diagramas/Sistema De Elecciones.mdl`)

| Mensaje del diagrama | Frontend | Backend |
|---|---|---|
| 1 `ingresarNulidadParcial(id_mesa, causal)` | Pestaña «Nulidad parcial» → «Plantear nulidad» en la mesa → causal, origen, personero, sustento → «Registrar recurso» → «Confirmar» | `POST /api/nulidades/procesos/{id}/parcial` → `DeclararNulidadParcial.registrar` → `sp_registrar_nulidad('PARCIAL')` |
| 2 `anularMesa(id_mesa, causal)` | Pestaña «Resolución del Pleno» → «Resolver en el Pleno» → «Fundada» → «Emitir resolución» | `POST /api/nulidades/{id}/resolucion` → `DeclararNulidadParcial.resolver` → `sp_resolver_nulidad` |
| 3 `actualizarEstado('ANULADA')` | La mesa aparece «Anulada» con su resolución | `mesa_electoral.estado` y `acta_electoral.estado` = ANULADA; la mesa sale de `v_computo_resultados` (CUS14) |
| 4 `mostrarMesaExcluida()` | «Ver» la mesa: votos tachados que salen del cómputo y sus recursos | `GET /api/nulidades/mesas/{id}` → `NulidadesConsulta.detalleMesa` |
| 5 `ingresarNulidadTotal(id_proceso, motivo)` | Pestaña «Nulidad total» → «Plantear nulidad total» (o «Formalizar nulidad (A1)») | `POST /api/nulidades/procesos/{id}/total` → `DeclararNulidadTotal.registrar` → `sp_registrar_nulidad('TOTAL')` |
| 6 `anularProceso(id_proceso, motivo)` | «Resolución del Pleno» → «Fundada» → «Emitir resolución» | `DeclararNulidadTotal.resolver` → `sp_resolver_nulidad` |
| 7 `actualizarEstado('ANULADO', motivo_anulacion)` | Aviso «Elección anulada» con el motivo | `proceso_electoral` = ANULADO (con sus mesas, actas y su segunda vuelta si no concluyó) |
| 8 `registrarComunicacion('SUNEDU, AU, CU')` | Pestaña «Comunicación»: «Registrar envío» por destinatario y «Publicar» en el portal | `POST /api/nulidades/{id}/comunicaciones` → `DeclararNulidadTotal.comunicar` → `sp_registrar_comunicacion_nulidad` |
| 9 `mostrarResolucionNulidad()` | Expediente: resolución, votación del Pleno, efecto y huella; «Imprimir resolución con QR» | `GET /api/nulidades/{id}` y `GET /api/publico/nulidad/{token}` |
| 10 `[sin minimo legal] convocarSegundaVuelta(id_proceso, fechas)` | Pestaña «Segunda vuelta» → fechas → «Convocar segunda vuelta» → «Confirmar» | `POST /api/nulidades/procesos/{id}/segunda-vuelta` → `ConfigurarSegundaVuelta.convocar` → `sp_convocar_segunda_vuelta` |
| 11 `crearSegundaVuelta(id_proceso, fechas)` | — | `sp_crear_segunda_vuelta` (redefinido en el CUS15) |
| 12 `insertar('SEGUNDA_VUELTA', id_proceso_padre)` | — | Nuevo `proceso_electoral` en CREADO |
| 13 `copiarDosMasVotadas(id_cargo)` | Tabla del cargo: «Pasa a la segunda vuelta» o «Elegida por sorteo» | Copia el cargo, sus categorías, las dos listas y sus candidatos |
| 14 `copiarPadron(id_proceso_nuevo)` | — | Copia el padrón de la primera vuelta |
| 15 `mostrarSegundaVuelta()` | Bloque «15 mostrarSegundaVuelta()»: proceso, fechas, padrón, listas finalistas, «Imprimir convocatoria» y «Abrir» | `v_segunda_vuelta_procesos` |

### Cambios que conviene hacer en el diagrama
- El diagrama anula la mesa o el proceso en cuanto se ingresa el recurso. El reglamento exige que el Pleno lo resuelva (RN36): se agregó `resolverNulidad(id_nulidad, decision, nResolucion, miembros, votos)` entre el mensaje 1 y el 2, y entre el 5 y el 6. Solo la decisión FUNDADA dispara `anularMesa` o `anularProceso`.
- Falta el sorteo del Pleno para el empate por el pase a la segunda vuelta y el empate en ella (RF97): `dirimirEmpate(id_cargo, semilla, nResolucion)` en `ConfigurarSegundaVuelta`.
- `copiarDosMasVotadas` debe recibir las listas elegidas en el sorteo cuando dos o más empatan por el segundo cupo.

## Flujo
1. **Nulidad parcial (Art. 64).** Con el proceso CERRADO y antes del cómputo, el CEUNP elige la mesa y registra el recurso: causal (instalación irregular, fraude en la mesa, admisión indebida, acta no auténtica u otra), origen (de oficio o personero acreditado), sustento y pruebas. Mientras esté pendiente, el cómputo del CUS14 queda bloqueado (RF94).
2. **Nulidad total (Art. 65).** Con la votación concluida o con el cómputo hecho y sin proclamar, el CEUNP registra el recurso por fraude, cohecho, soborno, intimidación o violencia. Mientras esté pendiente no se puede proclamar ni convocar la segunda vuelta.
3. **A1 del CUS14.** Si el cómputo declaró la nulidad por participación insuficiente (RN31), «Formalizar nulidad (A1)» registra el recurso de oficio para que el Pleno emita su resolución y se comunique.
4. **Resolución del Pleno (RN36).** Con quórum (5 de 9) y mayoría simple; en empate decide el voto dirimente del Presidente. La decisión puede ser FUNDADA, INFUNDADA o IMPROCEDENTE, con número de resolución único en todo el sistema. Es inapelable y emite un documento con huella SHA-256 y QR.
   - FUNDADA parcial: la mesa y sus actas quedan ANULADAS y sus votos salen del cómputo.
   - FUNDADA total: el proceso, sus mesas y actas quedan ANULADOS, también su segunda vuelta si no concluyó; los recursos parciales pendientes pasan a IMPROCEDENTE.
5. **Comunicación (RF102, Art. 66).** Cada resolución fundada se comunica por oficio a SUNEDU, la Asamblea Universitaria y el Consejo Universitario, y se publica en el portal (y si corresponde en El Peruano). Se imprimen los tres oficios. El portal público la muestra en `/api/publico/nulidades`.
6. **Segunda vuelta (RN33).** Si un cargo quedó en SEGUNDA_VUELTA, pasan las dos listas más votadas. Si varias empatan por el segundo cupo, el Pleno lo dirime por sorteo: anuncia una semilla pública y el sistema ordena las listas por `SHA2(semilla|cargo|lista)`, de modo que cualquiera puede repetirlo. Luego se convoca dentro de los 15 días del cómputo.
7. **Empate en la segunda vuelta (RF97).** Si las dos finalistas empatan, el cargo queda en EMPATE; el Pleno lo dirime por sorteo, la lista elegida queda ganadora y se proclama en el CUS14.

## Reglas
- **RF100:** la nulidad parcial solo procede sobre una mesa que funcionó y cerró su sufragio, con el proceso CERRADO y antes del cómputo. La mesa no instalada se evalúa en el CUS08 (RF60). Un solo recurso pendiente por mesa. El personero de mesa solo pide la nulidad de su mesa; los personeros generales y alternos, de cualquiera.
- **RF101:** un solo recurso de nulidad total pendiente o declarado por proceso. Solo procede antes de la proclamación. La causal de participación insuficiente solo existe si el cómputo la determinó (A1), se declara de oficio y solo puede ser FUNDADA.
- **RF94:** los recursos pendientes bloquean el cómputo (`trg_computo_bu_cus15`); un recurso total pendiente bloquea la proclamación y la creación de la segunda vuelta (`trg_proceso_bi_cus15`). La pantalla del CUS14 muestra ese bloqueo.
- **RN36:** quórum `CEUNP_QUORUM_PLENO` (5), votos a favor y en contra que no superan a los presentes, mayoría simple o voto dirimente. Un recurso resuelto no se modifica ni se borra (triggers).
- **RN34:** el número de resolución es único frente a las resoluciones de impugnaciones (CUS13), calificación de mesas, proclamación (CUS14), nulidades y sorteos (`fn_resolucion_en_uso`).
- **Sustracción de la materia:** si la mesa o la elección ya estaban anuladas, el recurso solo puede declararse IMPROCEDENTE.
- **RF102:** solo se comunican resoluciones FUNDADAS, una vez por destinatario, con fecha entre la resolución y hoy; el oficio exige número de documento.
- **RN33:** se convoca solo una segunda vuelta vigente por elección, dentro de `SEGUNDA_VUELTA_PLAZO_DIAS` (15) y sin empate por dirimir. La nulidad total de la primera vuelta anula la segunda que no concluyó; si ya concluyó, la nulidad se plantea sobre esa segunda vuelta.
- **RN26:** el cambio FINALIZADO → ANULADO solo lo hace `sp_resolver_nulidad` (`trg_proceso_bu` redefinido con la variable de sesión `@cus15_nulidad_total`).
- Los tokens del QR solo se devuelven al emitir la resolución. La pantalla los guarda en la sesión del navegador para reimprimir con QR; en otro navegador la reimpresión lleva la huella SHA-256.

## Endpoints (`/api/nulidades`, ADMIN y CEUNP; las acciones solo CEUNP)
| Método | Ruta | Uso |
|---|---|---|
| GET | `/procesos` | Procesos con mesas desde la votación y segundas vueltas, con sus recursos pendientes |
| GET | `/procesos/{id}` | Detalle: proceso, participación, mesas, recursos, comunicaciones, personeros, cargos con finalistas y empates, sorteos, segundas vueltas, parámetros, acciones habilitadas y avisos |
| GET | `/mesas/{id}` | 4 mostrarMesaExcluida: mesa, votos y recursos |
| GET | `/{idNulidad}` | 9 mostrarResolucionNulidad: recurso, resolución (JSON con huella) y comunicaciones |
| POST | `/procesos/{id}/parcial` `{idMesa, causal, origen, idPersonero, sustento, pruebas}` | 1 ingresarNulidadParcial; devuelve `idNulidad` |
| POST | `/procesos/{id}/total` `{causal, origen, idPersonero, sustento, pruebas}` | 5 ingresarNulidadTotal; devuelve `idNulidad` |
| POST | `/{idNulidad}/resolucion` `{decision, fundamento, numeroResolucion, miembrosPleno, votosFavor, votosContra, votoDirimente}` | 2-3 o 6-7 según el alcance; devuelve `tokenQr` |
| POST | `/{idNulidad}/comunicaciones` `{destinatario, documento, fechaEnvio, observacion}` | 8 registrarComunicacion (SUNEDU, ASAMBLEA_UNIVERSITARIA, CONSEJO_UNIVERSITARIO, PORTAL, EL_PERUANO) |
| POST | `/procesos/{id}/segunda-vuelta` `{fechaInicio, fechaFin}` | 10-15; devuelve `idProcesoNuevo` |
| POST | `/cargos/{id}/dirimencia` `{semilla, numeroResolucion, miembrosPleno, fundamento}` | Sorteo del Pleno (pase a la segunda vuelta o empate en ella) |

Públicos (sin sesión): `GET /api/publico/nulidad/{token}` (verifica la resolución recalculando su SHA-256) y `GET /api/publico/nulidades` (resoluciones fundadas publicadas en el portal).

CUS14: `GET /api/computo/procesos/{id}` agrega a `bloqueos` los recursos pendientes antes del cómputo, y `acciones.motivoNoProclama` cuando hay una nulidad total pendiente.

## Base de datos (`14_nulidades_segunda_vuelta.sql`)
- Tablas: `nulidad_electoral` (recurso y resolución con contenido JSON, huella y token del QR), `nulidad_comunicacion` (un envío por destinatario) y `dirimencia_empate` (sorteo por cargo: semilla, listas empatadas y elegidas, resolución y huella).
- Función: `fn_resolucion_en_uso(numero)`.
- Vistas: `v_nulidades`, `v_portal_nulidades` y `v_segunda_vuelta_procesos`.
- Procedimientos: `sp_registrar_nulidad`, `sp_resolver_nulidad`, `sp_registrar_comunicacion_nulidad`, `sp_dirimir_empate`, `sp_crear_segunda_vuelta` (redefinido: respeta los empates y el sorteo) y `sp_verificar_resolucion_nulidad`.
- Triggers: `trg_proceso_bu` (redefinido), `trg_proceso_bi_cus15`, `trg_nulidad_bu`, `trg_nulidad_bd`, `trg_ncom_bu`, `trg_ncom_bd`, `trg_dirimencia_bu`, `trg_dirimencia_bd`, `trg_computo_bu_cus15`, `trg_calificacion_bi_cus15` y `trg_impugnacion_bu_cus15`.
- Parámetros que usa: `CEUNP_QUORUM_PLENO` (5) y `SEGUNDA_VUELTA_PLAZO_DIAS` (15).
- Bitácora: `REGISTRAR_RECURSO_NULIDAD`, `DECLARAR_NULIDAD_PARCIAL`, `DECLARAR_NULIDAD_TOTAL`, `DESESTIMAR_NULIDAD`, `REGISTRAR_COMUNICACION_NULIDAD`, `DIRIMIR_EMPATE` y `CREAR_SEGUNDA_VUELTA`.

## Archivos
- Backend: `backend/src/main/java/pe/unp/elecciones/electoral/nulidades/` (`NulidadesController`, `DeclararNulidadParcial`, `DeclararNulidadTotal`, `ConfigurarSegundaVuelta`, `NulidadesConsulta`, `NulidadesDto`); `ProcesoService` y `PublicoController` para el portal; `computo/ComputoConsulta` para los bloqueos del CUS14.
- Frontend: `frontend/src/pages/nulidades/` (`PantallaNulidades.jsx`, `ResolucionNulidad.js`, `nulidades.css`, con el estilo ejecutivo de `mesa/mesa-ejecutivo.css` y las impresiones de `computo/ActaComputo.js`). Menú en `DashboardPage.jsx` (grupo RESULTADOS). `PantallaComputo.jsx` muestra el motivo cuando no se puede proclamar.

## Botones de la pantalla
- **Generales:** selección del proceso, «Actualizar» y las cinco pestañas (Nulidad parcial, Nulidad total, Resolución del Pleno, Comunicación, Segunda vuelta) con el número de recursos o cargos de cada una; la pestaña se marca en ámbar si hay algo pendiente.
- **Nulidad parcial:** «Ver» (mesa y votos que se excluyen), «Plantear nulidad», causales, «De oficio» / «A pedido de personero», «Registrar recurso», «Confirmar» y «Expediente» en los recursos de la mesa.
- **Nulidad total:** «Plantear nulidad total», «Formalizar nulidad (A1)» y la tabla de recursos.
- **Resolución del Pleno:** «Resolver» o «Ver» por recurso, «Resolver en el Pleno», «Fundada» / «Infundada» / «Improcedente», casilla del voto dirimente, «Emitir resolución», «Confirmar», «Cargo del recurso», «Imprimir resolución con QR» y «Comunicar y publicar».
- **Comunicación:** «Registrar envío» por destinatario, «Publicar» en el portal, «Imprimir oficios» (uno por SUNEDU, AU y CU) y «Resolución».
- **Segunda vuelta:** «Dirimir por sorteo», «Realizar sorteo», «Acta del sorteo», «Convocar segunda vuelta», «Imprimir convocatoria» y «Abrir» (la segunda vuelta).
- Cada acción que no se puede deshacer pide confirmación.

## Prueba rápida (verificada con MariaDB 10.11, la API y el navegador)
1. Ejecutar `14_nulidades_segunda_vuelta.sql` sobre la base existente (o crearla con `00`). Tener un proceso con la votación concluida y la sesión de cómputo instalada (CUS14).
2. «Nulidades y segunda vuelta» → «Nulidad parcial» → «Plantear nulidad» en una mesa a pedido de un personero. En «Cómputo y proclamación» aparece el bloqueo y «Ejecutar cómputo» se rechaza (RF94). Un segundo recurso sobre la misma mesa se rechaza.
3. «Resolución del Pleno» con 4 miembros: exige quórum. Con 6 miembros y 3 a 3: exige el voto dirimente; al marcarlo se emite FUNDADA, la mesa queda anulada y sus votos aparecen tachados. Volver a resolver: RN36. Repetir un número de resolución: RN36.
4. Ejecutar el cómputo (CUS14): se computan las demás mesas. Un recurso parcial después del cómputo se rechaza (RN26).
5. En otro proceso computado, «Plantear nulidad total» por cohecho: el CUS14 no deja proclamar. Resolverla FUNDADA: el proceso pasa a ANULADO con sus mesas. En «Comunicación» registrar los tres oficios y «Publicar»; «Imprimir oficios» genera tres hojas. El QR de la resolución abre `/api/publico/nulidad/{token}` con `contenidoIntegro = 1`.
6. Con participación menor al 60 % (A1), «Formalizar nulidad (A1)»: a pedido de personero o como INFUNDADA se rechaza; de oficio y FUNDADA se emite la resolución.
7. Con un cargo en segunda vuelta y dos listas empatadas por el segundo cupo, «Convocar» no aparece hasta «Dirimir por sorteo»; tras el sorteo se convoca y la segunda vuelta copia la lista ganadora del sorteo. Con las finalistas empatadas en la segunda vuelta, el sorteo deja al cargo ELEGIDO y ya se puede proclamar.
