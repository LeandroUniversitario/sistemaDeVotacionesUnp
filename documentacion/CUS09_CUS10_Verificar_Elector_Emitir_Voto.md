# CUS09 · Verificar elector con QR y CUS10 · Registrar voto

**Fuente:** colaboración «Verificar elector y emitir voto» del modelo Rose (`diagramas/Sistema De Elecciones.mdl`), tablas 35 y 36 y sección 5.4.1 del informe v2.1, RF61 a RF73, decisiones D12 y D14.
**Actores:** Secretario de mesa (CUS09), Docente elector (CUS10, **no inicia sesión**), Presidente de mesa (rehabilitación).
**Requiere:** mesa INSTALADA (CUS08), pase QR (CUS07).
**Instalación:** en una base ya creada, ejecutar `base-de-datos/06_verificar_elector_emitir_voto.sql`. `01_crear_base_de_datos.sql` ya lo incluye y `02_limpiar_datos_electorales.sql` vacía sus tablas.

## Correspondencia con el diagrama de colaboración
| N.° | Mensaje | Frontend | Backend |
|---|---|---|---|
| 1 | escanearQR() | `PantallaVerificacion` (EscanerQR o búsqueda por DNI, A1) | `POST /api/sufragio/mesas/{id}/verificar` |
| 2 | verificar(token) | — | `VerificarElector.verificar` → `VerificarCredencial` (CUS07) |
| 3 | consultarHabilitacion() | — | `VotacionConsulta.electorEnMesa` (PadronMesa) |
| 4 | mostrarDatosYFoto() | ficha con nombres y fotografía | `docente.url_foto` |
| 5 | confirmarConDNI() | «Confirmar con DNI y habilitar terminal» | `POST /api/sufragio/mesas/{id}/asistencias` |
| 6 | registrarAsistencia() | — | `RegistrarAsistencia.confirmar` → `asistencia_elector` (RF64) |
| 7 | habilitarTerminal() | elige un terminal libre | `habilitacion_terminal` de un solo uso (RF67) |
| 8 | elegirOpcion() | `TerminalVotacion` (cédula, corregir y confirmar, A1) | `GET /api/sufragio/terminales/{id}` entrega el token y la cédula una sola vez |
| 9 | registrarVoto(opción) | «Confirmar voto» (sin datos del elector) | `POST /api/sufragio/terminales/{id}/voto` → `RegistrarVoto` |
| 10 | crear(opción, mesa) | — | `sp_votar_habilitado` por cargo + consumo de la habilitación, en **una** transacción (A5) |
| — | generarConstancia() | la mesa la imprime: botón «Constancia» | `GET/DELETE /api/sufragio/mesas/{id}/constancias/{docente}` |
| 11 | imprimirCedula(opción) | `ImpresoraCedula.imprimirCedula` | respuesta del voto: solo la elección |
| 12 | confirmarImpresion() | «Sí, retiré mi cédula» / «Reimprimir cédula» (A2) | — |
| 13 | liberarTerminal() | borra la elección de la memoria | `POST /api/sufragio/terminales/{id}/liberar` |

## Estados del elector (sección 5.4.1)
Pendiente → **Habilitado** (asistencia y terminal asignado) → **Votó** (se marca solo dentro de la transacción del voto). Si abandona o algo falla: **Habilitado sin votar**, y solo el Presidente puede rehabilitar el terminal. Además: Inhabilitado.

## Flujos alternos implementados
- **CUS09 A1/A2:** si el QR no se lee o no es válido, se alerta, se registra la incidencia `QR_INVALIDO` y se verifica por DNI.
- **CUS09 A3:** el elector no figura (`NO_FIGURA`) o es de otra mesa (`OTRA_MESA`, se indica cuál): no vota.
- **CUS09 A4:** si la asistencia ya está registrada, se bloquea con incidencia `YA_REGISTRADO`, salvo rehabilitación.
- **CUS09 A5:** «El DNI no corresponde»: se rechaza el ingreso con motivo (incidencia `SUPLANTACION`).
- **CUS10 A1:** «Corregir» antes de confirmar.
- **CUS10 A2:** «Reimprimir cédula» desde la memoria temporal hasta confirmar la impresión.
- **CUS10 A3:** la mesa anula la habilitación (incidencia `ABANDONO_TERMINAL`) y el Presidente puede rehabilitar (`REHABILITACION`).
- **CUS10 A4:** terminal «Fuera de servicio» (`FALLA_TERMINAL`). Si la página del terminal se recarga a mitad del voto, el token no se vuelve a entregar: la mesa anula y rehabilita en otro terminal.
- **CUS10 A5:** si falla un cargo o el servidor, se revierte todo y el elector sigue Habilitado.

## Decisiones y supuestos
- **Sin voto nulo** en el terminal (D12 / RN25): solo una lista o voto en blanco.
- **El terminal es el equipo de la cabina** abierto con la cuenta de la mesa en «Terminal de votación». El terminal nunca recibe ni envía datos del elector (RF69). La cédula impresa no lleva datos del elector (RNF07).
- **Constancia:** `sp_votar_habilitado` la emite y el backend guarda el token **solo en memoria** (3 horas) para que la mesa la imprima y la entregue. No pasa por el terminal, para no juntar identidad y voto en la cabina.
- **Rehabilitación:** la autoriza el Presidente que ejerce en la mesa. Si existe `miembro_mesa.rol_instalacion` (CUS08) se usa; si no, el presidente titular. El CEUNP y el ADMIN también pueden.
- **Fotografías:** se agregan `docente.url_foto` y `candidato.url_foto` (URL de la imagen). Si no hay foto se muestran las iniciales o el símbolo de la lista. Cargar las fotos no es parte de estos casos de uso.
- **El voto con la sesión del docente se deshabilitó:** `POST /api/votos` responde 403 (D14).
- Firma y huella (RF65) y atención preferente (RF72) quedan fuera, porque no tienen paso en la colaboración.

## Endpoints
| Método | Ruta | Uso |
|---|---|---|
| GET | `/api/sufragio/mesas`, `/api/sufragio/mesas/{id}` | mesas y tablero (padrón, terminales, incidencias) |
| POST | `/api/sufragio/mesas/{id}/verificar` `{codigo}` o `{dni}` | 1-4 |
| POST | `/api/sufragio/mesas/{id}/asistencias` `{idDocente, metodo, idCredencial, idTerminal}` | 5-7 |
| POST | `/api/sufragio/mesas/{id}/rechazos` `{dni, idDocente, motivo}` | A5 |
| POST | `/api/sufragio/mesas/{id}/habilitaciones/{h}/anular` `{motivo}` | abandono |
| POST | `/api/sufragio/mesas/{id}/rehabilitaciones` `{idDocente, idTerminal, motivo}` | Presidente |
| PUT | `/api/sufragio/mesas/{id}/terminales/{t}` `{activo}` | fuera de servicio |
| GET / DELETE | `/api/sufragio/mesas/{id}/constancias/{idDocente}` | constancia por entregar |
| POST | `/api/sufragio/terminales` `{idMesa, nombre}` | conectar el equipo |
| GET | `/api/sufragio/terminales/{id}` | LIBRE / HABILITADO (token y cédula) / EN_USO / FUERA_DE_SERVICIO |
| POST | `/api/sufragio/terminales/{id}/voto` `{idHabilitacion, token, votos}` | 9-11 |
| POST | `/api/sufragio/terminales/{id}/liberar` | 13 |

Roles: ADMIN, CEUNP y MIEMBRO_MESA. Un miembro de mesa solo opera su mesa.

## Archivos
- BD: `06_verificar_elector_emitir_voto.sql` (tablas `asistencia_elector`, `terminal_votacion`, `habilitacion_terminal`, `incidencia_mesa`; procedimiento `sp_votar_habilitado`)
- Backend `electoral/votacion/`: `VerificarElector`, `RegistrarAsistencia`, `RegistrarVoto`, `VotacionConsulta`, `VotacionDto`, `VerificarElectorController`, `TerminalVotacionController`
- Frontend `pages/votacion/`: `PantallaVerificacion.jsx`, `TerminalVotacion.jsx`, `ImpresoraCedula.js`, `votacion.css`

## Prueba rápida
1. Ejecutar el script 06. Tener un proceso en VOTACION con la mesa INSTALADA.
2. En el equipo de la cabina, con la cuenta de un miembro de mesa: «Terminal de votación» → elegir la mesa → «Conectar terminal».
3. En el equipo de mesa: «Verificar elector» → escanear el QR (o «Buscar por DNI») → comparar la foto → «Confirmar con DNI y habilitar terminal».
4. En el terminal aparece la cédula. Elegir una opción → «Continuar» → «Confirmar voto» → se imprime la cédula → «Sí, retiré mi cédula». El terminal queda libre.
5. En la mesa: el elector aparece como «Votó» → «Constancia» para imprimirla y entregarla.
