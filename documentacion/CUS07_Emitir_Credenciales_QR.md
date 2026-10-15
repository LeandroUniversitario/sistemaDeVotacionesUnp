# CUS07 · Emitir credenciales y QR

**Actor:** CEUNP · **Pantalla:** menú «Credenciales y QR» · **Requiere:** padrón definitivo (CUS02), mesas y miembros sorteados (CUS06), personeros acreditados (CUS05)
**Instalación:** en una base ya creada, ejecutar `base-de-datos/04_credenciales_qr.sql`. `base-de-datos/01_crear_base_de_datos.sql` ya incluye la tabla, y `02_limpiar_datos_electorales.sql` también la vacía.

## Correspondencia con el diagrama de colaboración

| Mensaje del diagrama | Frontend | Backend |
|---|---|---|
| 1 `solicitarCredencial(id_docente)` | `CredencialesPage.solicitarCredencial` (Emitir, Reemitir, Emitir seleccionadas, Emitir pendientes) | `POST /api/credenciales/procesos/{id}/emitir` `{tipo, ids}` |
| 2 `crearHash(id_docente)` | — | `GenerarTokenQR.crearHash` |
| `calcularSHA256()` (reflexivo) | — | `GenerarTokenQR.calcularSHA256` (token aleatorio de 256 bits, `SecureRandom`) |
| 3 `consultarDatos(id_docente)` | — | `GenerarTokenQR.consultarDatos` → `CredencialesConsulta.titular` (docente, función, mesa y si es apto) |
| 4 `guardarConstancia(token_hash)` | — | `EmitirConstancia.guardarConstancia` (transacción) |
| 5 `insertar(token_qr_hash, id_docente)` | — | `EmitirConstancia.insertar` → tabla `credencial_qr` |
| 6 `renderizarQR(token_hash)` | `LectorQR.jsx` (`CodigoQR`, `TarjetaCredencial`) dibuja el QR en el navegador | `EmitirConstancia.renderizarQR` arma el contenido `SICEUNP\|E\|<token>` |
| 7 `mostrarCredencialLista()` | `ListaCredencialesQR`: tarjetas, Imprimir (9 por A4) y PNG | — |

### Cambio que debes hacer en el diagrama
La entidad del mensaje 5 debe llamarse **CredencialQR** (tabla `credencial_qr`), no *ConstanciaVoto*. La tabla `constancia_voto` la llena `sp_emitir_voto` **después** de votar, con una fila única por (proceso, docente, cargo). Si la credencial se guardara ahí, al votar se duplicaría la clave y la constancia de voto ya no probaría que el docente votó.

## Seguridad
- El token es aleatorio (256 bits). En la base solo se guarda **SHA-256(token)**: con una copia de la base no se pueden fabricar credenciales, y un QR inventado no coincide con ningún hash.
- El QR se ve **una sola vez** (al emitirse). Si se pierde, se vuelve a emitir y la anterior queda REVOCADA.
- El QR se genera en el navegador (`frontend/src/lib/qrcode.js`, ISO/IEC 18004, corrección M). Se retiró el uso de `api.qrserver.com`, que mandaba a un servicio externo un contenido predecible (`VOTO-usuario`).
- Hay una sola credencial VIGENTE por titular (índice único `uq_credencial_vigente`). Las credenciales no se borran (trigger `trg_credencial_bd`): se revocan, con su motivo.
- Si en CUS05 se revoca a un personero, el trigger `trg_personero_au_credencial` revoca su credencial.
- Las credenciales vencen con `fecha_fin` del proceso.
- La bitácora registra `EMITIR_CREDENCIAL`, `REVOCAR_CREDENCIAL` y `VERIFICAR_CREDENCIAL`. Las lecturas fallidas también se registran, para detectar QR falsos. El token nunca se registra.

## Tipos y quién es apto

| Tipo | Titular | Apto si… |
|---|---|---|
| ELECTOR · pase de votación (RF62) | docente del padrón | está habilitado en el padrón y tiene mesa PENDIENTE o INSTALADA |
| MIEMBRO_MESA · fotocheck (RF56) | miembro sorteado | su mesa está PENDIENTE o INSTALADA (también guarda la huella en `miembro_mesa.qr_credencial_hash`) |
| PERSONERO · credencial (RF51) | personero ACREDITADO | su lista está INSCRITA o ADMITIDA y, si es de mesa, la mesa está activa (también guarda la huella en `personero.qr_credencial_hash`) |

Se emite con el proceso en CREADO, INSCRIPCION o VOTACION, mientras no haya terminado el sufragio.

## Verificación (jornada electoral)
`POST /api/credenciales/verificar` `{codigo}` (CEUNP, ADMIN, MIEMBRO_MESA). Funciona con pistola lectora (el lector «escribe» el texto y un Enter) o con la cámara si el navegador tiene `BarcodeDetector`. Acepta el separador cambiado o ausente y mayúsculas o minúsculas, por si la pistola usa otra distribución de teclado.

Comprueba que la credencial exista, esté VIGENTE y no haya vencido, y que el titular **siga** teniendo derecho. Por ejemplo, si un docente salió del padrón, su pase deja de valer aunque esté vigente. Resultados posibles: `VALIDA`, `REVOCADA`, `VENCIDA`, `SIN_DERECHO`, `NO_REGISTRADA`, `FORMATO_INVALIDO`. Al elector se le avisa si ya votó.

## Credenciales propias
Los menús «Mi pase de votación QR» (DOCENTE), «Fotocheck QR» (MIEMBRO_MESA) y «Credencial QR» (PERSONERO) muestran las credenciales a las que el docente tiene derecho. Desde ahí puede generarlas o regenerarlas («Perdí mi QR»), lo que revoca la anterior, y descargarlas en PNG o imprimirlas. El miembro de mesa tiene además «Verificar credencial QR».

## Endpoints

| Método | Ruta | Rol |
|---|---|---|
| GET | `/api/credenciales/procesos` | ADMIN, CEUNP |
| GET | `/api/credenciales/procesos/{id}?tipo=ELECTOR\|MIEMBRO_MESA\|PERSONERO` | ADMIN, CEUNP |
| GET | `/api/credenciales/procesos/{id}/historial` | ADMIN, CEUNP |
| POST | `/api/credenciales/procesos/{id}/emitir` `{tipo, ids}` (hasta 1000; ids = id_docente, o id_personero en PERSONERO) | CEUNP |
| POST | `/api/credenciales/{idCredencial}/revocar` `{motivo}` | CEUNP |
| POST | `/api/credenciales/verificar` `{codigo}` | ADMIN, CEUNP, MIEMBRO_MESA |
| GET / POST | `/api/credenciales/mias` · `{idProceso, tipo, idTitular}` | DOCENTE, MIEMBRO_MESA, PERSONERO |

## Archivos
- BD: `base-de-datos/04_credenciales_qr.sql` (y la misma tabla al final de `01_crear_base_de_datos.sql`)
- Backend: `backend/src/main/java/pe/unp/elecciones/electoral/credenciales/` (`CredencialesController`, `GenerarTokenQR`, `EmitirConstancia`, `VerificarCredencial`, `CredencialesConsulta`, `CredencialesDto`, `TipoCredencial`)
- Frontend: `frontend/src/lib/qrcode.js`, `frontend/src/pages/credenciales/` (`CredencialesPage`, `LectorQR`, `VerificarCredencialPanel`, `MisCredencialesPage`, `credenciales.css`)

## Prueba rápida
1. Ejecutar `04_credenciales_qr.sql` (o reimportar `01_crear_base_de_datos.sql`). Tener el padrón aprobado, las mesas sorteadas y los personeros acreditados.
2. «Credenciales y QR» → pestaña Electores → «Emitir pendientes» → «Emitir» → «Imprimir».
3. Pestaña «Verificar QR»: escanear un pase (o pegar su contenido) → «Credencial válida».
4. «Reemitir» a ese docente y volver a leer el QR anterior → «Credencial revocada».
5. Entrar como docente → «Mi pase de votación QR» → muestra la credencial vigente y permite generar otra.
