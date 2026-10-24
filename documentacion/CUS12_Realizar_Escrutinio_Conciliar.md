# CUS12 · Realizar escrutinio y conciliar

**Actores:** Presidente de mesa (cuenta las cédulas, confirma el escrutinio y registra la entrega), Secretario de mesa (ingresa el conteo por lista). El CEUNP supervisa y puede operar, y el ADMIN solo consulta. · **Pantalla:** menú «Realizar escrutinio» (MIEMBRO_MESA) y «Escrutinio y conciliación» (CEUNP)
**Caso de negocio:** CUN09 Realizar escrutinio y levantar actas · **Módulo:** M11 (RF77 a RF87) · **Reglas:** RN24 a RN28 · **Fuente:** tabla 38 del informe v2.1
**Requiere:** mesa CERRADA y acta de sufragio emitida (CUS11). El proceso tiene que estar en VOTACION o CERRADO.
**Instalación:** en una base ya creada, ejecutar `base-de-datos/11_escrutinio_conciliacion.sql` después de `10_cerrar_sufragio.sql`. `00_script_unico_elecciones_unp.sql` (sección 5b) y `01_crear_base_de_datos.sql` (al final) ya lo incluyen, y `02_limpiar_datos_electorales.sql` vacía sus tablas. El script no borra datos y se puede volver a ejecutar.

## Correspondencia con el diagrama de colaboración («Colaboracion - Realizar escrutinio y conciliar»)

| Mensaje del diagrama | Frontend | Backend |
|---|---|---|
| 1 `ingresarTotalCedulas(total)` | `PantallaEscrutinio`, paso 1: «Cédulas contadas en el ánfora» → «Verificar total e iniciar escrutinio» → «Confirmar e iniciar» | `POST /api/escrutinio/mesas/{id}/cedulas` |
| 2 `verificarTotal()` | — | `ValidarTotales.verificarTotal` → `sp_contar_cedulas` |
| 3 `contarVotantes()` | — | `sp_contar_cedulas` lee los electores que votaron (acta de sufragio de CUS11) |
| 4 `mostrarResultadoValidacion()` | Aviso «coinciden / A1 sobran / A2 faltan» e indicador «Cédulas del ánfora» | La respuesta trae `COINCIDE`, `SOBRAN` o `FALTAN` y el detalle |
| 5 `ingresarConteoManual(conteo_listas)` | Paso 2: una tarjeta por cargo con votos por lista, en blanco, nulos e impugnados → «Registrar conteo y conciliar» | `POST /api/escrutinio/mesas/{id}/conteo` |
| 6 `compararConDigital(conteo)` | — | `ConciliarVotos.compararConDigital` → `sp_registrar_conteo` |
| 7 `contarVotosDigitales()` | — | `sp_registrar_conteo` cuenta la tabla `voto` de la mesa por cargo y opción |
| 8 `mostrarCuadre()` | Tabla «Cuadre con el conteo digital»: manual, digital y diferencia por opción | `detalle.cargos[].conteo` |
| 9 `confirmarEscrutinio()` | Paso 3: observaciones, prevalece la cédula física (A3) y personeros que firman → «Confirmar escrutinio y generar acta» → «Confirmar y firmar» | `POST /api/escrutinio/mesas/{id}/acta` |
| 10 `crearActa(resultados)` | — | `GenerarActaEscrutinio.crearActa` → `sp_generar_acta_escrutinio` |
| 11 `insertarActa(hash, contenido)` | — | `sp_generar_acta_escrutinio` → `sp_emitir_acta('ESCRUTINIO')` → `acta_electoral` (huella SHA-256 y token del QR) |
| 12 `registrarFirmas(firmas)` | — | `sp_generar_acta_escrutinio` → `firma_acta` |
| 13 `mostrarActaGenerada()` | `ActaVista`: resultados, firmas, QR, «Imprimir tres ejemplares» y «Copia para personero» (`ActaEscrutinio.js`) | La respuesta trae el acta y el token del QR, que se entrega una sola vez |
| Paso 9 de la tabla 38 | Paso 4: ejemplares, quién recibe, copias, padrón y material → «Registrar entrega al CEUNP» → «Imprimir cargo de entrega» | `POST /api/escrutinio/mesas/{id}/entrega` → `GenerarActaEscrutinio.registrarEntrega` → `sp_registrar_entrega_actas` |

Paso 4 de la tabla 38 (un personero impugna un voto): botón «Registrar impugnación» del paso 2 → `POST /api/escrutinio/mesas/{id}/impugnaciones` → `ConciliarVotos.registrarImpugnacion` → `sp_registrar_impugnacion`.

### Cambios que conviene hacer en el diagrama
- Falta un mensaje para la impugnación del paso 4: `registrarImpugnacion(personero, cargo, motivo)`.
- Falta el paso 9 de la tabla 38 después del mensaje 13: `registrarEntrega(recibido_por, ejemplares)`.
- El mensaje 6 debe decir que el conteo se compara **por opción y por cargo**, y que se vuelve a enviar en cada recuento (A3).

## Flujos alternos (tabla 38)
- **A1 · Sobran cédulas (RN27):** el presidente marca que retiró al azar las sobrantes y que las destruyó sin abrirlas, y escribe la observación. Se escrutan tantas cédulas como electores votaron.
- **A2 · Faltan cédulas:** la observación es obligatoria y se escrutan las que hay. Para conciliar, el sistema admite que falten en el conteo manual hasta ese número de votos.
- **A3 · El conteo manual difiere del digital:** la tabla de cuadre marca las opciones con diferencia. Hay que recontar y registrar el conteo otra vez. Si la diferencia sigue, el presidente confirma que **prevalece la cédula física** (RF84) y explica la diferencia en la observación. El acta lleva el conteo manual y el digital.
- **A4 · Votos impugnados:** cada impugnación registrada suma un voto «impugnado» en su cargo. El conteo de impugnados tiene que ser igual al número de impugnaciones, y esas cédulas faltan en su opción digital hasta que se resuelvan en el CUS13.
- **A5 · Acta con observaciones:** si hay observación de cédulas o del escrutinio, el acta se emite marcada **OBSERVADA**.

## Reglas del escrutinio
- **RF77 y RF78:** se compara el total de cédulas con los electores que votaron (acta de sufragio).
- **RF79:** ningún cargo puede sumar más votos que cédulas escrutadas, y cada cargo tiene que estar en el conteo.
- **RF82:** el total del conteo manual de cada cargo tiene que ser igual a los electores que votaron. Si no lo es, hace falta una observación.
- **RF83:** un cargo **cuadra** cuando ninguna opción tiene más votos manuales que digitales y los votos que faltan, descontadas las impugnadas, no pasan de las cédulas faltantes (A2). Los votos digitales solo se muestran después de registrar el conteo manual, para que no influyan en él.
- **RF85:** el acta guarda la hora de inicio y de fin, las cédulas (contadas, sobrantes, faltantes y escrutadas), los recuentos, los resultados por cargo y opción (manual, digital y diferencia), las impugnaciones, los miembros, las observaciones y la marca OBSERVADA, con su huella SHA-256 y su QR. Firman el presidente, el secretario y el vocal en funciones (titular, suplente o reemplazante) y los personeros presentes que lo deseen.
- **RF86 y RF87:** se imprimen tres ejemplares (CEUNP, ONPE y local de votación) y se registra la entrega al CEUNP (exige los 3 ejemplares), con quién recibe, las copias para personeros y si se entregan el padrón y el material. Si falta el padrón o el material, la observación es obligatoria. El sistema genera un código de cargo de entrega.
- **RN26:** el escrutinio es ininterrumpido e irreversible. Las cédulas contadas no cambian, y una vez emitida el acta no cambian el escrutinio ni el conteo (triggers `trg_escrutinio_bu`, `trg_escrutinio_bd`, `trg_conteo_bi`, `trg_conteo_bu` y `trg_conteo_bd`). Una impugnación nueva antes del acta obliga a registrar el conteo otra vez.
- **Actores:** cuenta las cédulas, confirma el escrutinio y registra la entrega el **presidente en funciones**. El conteo lo ingresa el secretario o el presidente. La impugnación la registra el presidente o el secretario, y el personero tiene que estar presente en la mesa (RN24). El CEUNP siempre puede operar. Un miembro solo ve su mesa.

### Fuera de alcance
- **CUS13:** la resolución de las impugnaciones (decisión de la mesa, apelación y fallo del CEUNP). El CUS12 solo las registra como `PRESENTADA`, les agrega el cargo y las enlaza al acta de escrutinio.
- **RF88:** versionar un acta firmada. Aquí el acta solo se puede anular (RN28).

## Endpoints (`/api/escrutinio`)
| Método | Ruta | Rol |
|---|---|---|
| GET | `/procesos` | ADMIN, CEUNP |
| GET | `/mesas?procesoId=` · `/mesas/{id}` | ADMIN, CEUNP, MIEMBRO_MESA (solo su mesa) |
| POST | `/mesas/{id}/cedulas` `{totalCedulas, destruidas, observacion}` | CEUNP, presidente en funciones |
| POST | `/mesas/{id}/impugnaciones` `{idPersonero, idCargo, motivo}` | CEUNP, presidente o secretario |
| POST | `/mesas/{id}/conteo` `{conteo:[{idCargo, opcion: LISTA·BLANCO·NULO·IMPUGNADO, idLista, votos}]}` | CEUNP, secretario o presidente |
| POST | `/mesas/{id}/acta` `{prevaleceFisica, observaciones, personeros:[idPersonero]}` | CEUNP, presidente en funciones |
| POST | `/mesas/{id}/entrega` `{recibidoPor, ejemplares: 3, copiasPersoneros, entregaPadron, entregaMaterial, observacion}` | CEUNP, presidente en funciones |

Los errores de negocio de los procedimientos (SQLSTATE 45000) llegan como HTTP 400 con su mensaje.

## Base de datos (`11_escrutinio_conciliacion.sql`)
- `impugnacion_electoral` + `id_cargo` (cargo de la cédula impugnada).
- Tabla `escrutinio_mesa` (una fila por mesa): avance (`CEDULAS_CONTADAS`, `CONTEO_REGISTRADO`, `ACTA_EMITIDA`, `ENTREGADA`), horas, cédulas (A1 y A2), recuentos, cuadre, prevalencia, observaciones, acta y datos de la entrega.
- Tabla `escrutinio_conteo`: conteo manual y digital por mesa, cargo y opción.
- `sp_contar_cedulas`, `sp_registrar_impugnacion`, `sp_registrar_conteo` (recibe el conteo en JSON; compatible con MariaDB 10.4, sin `JSON_TABLE`), `sp_generar_acta_escrutinio` y `sp_registrar_entrega_actas`.
- Bitácora: `CONTAR_CEDULAS`, `REGISTRAR_IMPUGNACION`, `REGISTRAR_CONTEO_ESCRUTINIO`, `EMITIR_ACTA_ESCRUTINIO` y `ENTREGAR_ACTAS`.

## Archivos
- Backend: `backend/src/main/java/pe/unp/elecciones/electoral/escrutinio/` (`EscrutinioController`, `ValidarTotales`, `ConciliarVotos`, `GenerarActaEscrutinio`, `EscrutinioConsulta`, `EscrutinioDto`)
- Frontend: `frontend/src/pages/escrutinio/` (`PantallaEscrutinio.jsx`, `ActaEscrutinio.js`, `escrutinio.css`). Además: menú y sección en `DashboardPage.jsx`, botón «Ir al escrutinio» en `MiembroMesaPage.jsx` y «Continuar con el escrutinio» en el acta de `PantallaCierreSufragio.jsx`.

## Prueba rápida
1. Ejecutar `11_escrutinio_conciliacion.sql` (o importar el script único). Tener una mesa CERRADA con su acta de sufragio emitida (CUS11).
2. Presidente: en «Realizar escrutinio», ingresar las cédulas del ánfora. Para A1, ingresar más que los votantes, marcar la destrucción y escribir la observación. Pulsar «Verificar total e iniciar escrutinio» y confirmar.
3. Si un personero presente impugna un voto, pulsar «Registrar impugnación» y elegir personero, cargo y motivo.
4. Secretario (o presidente): ingresar los votos de cada lista, en blanco y nulos, y pulsar «Registrar conteo y conciliar». Se muestra el cuadre con el conteo digital. Para A3, ingresar números distintos, registrar el recuento y luego marcar que prevalece la cédula física.
5. Presidente: en el paso 3, marcar los personeros que firman y pulsar «Confirmar escrutinio y generar acta». Si hubo observaciones, el acta sale OBSERVADA.
6. Pulsar «Imprimir tres ejemplares». El QR abre `/api/publico/actas/{token}`, que verifica la huella.
7. En el paso 4, marcar los tres ejemplares, escribir quién recibe y pulsar «Registrar entrega al CEUNP». Luego «Imprimir cargo de entrega».
