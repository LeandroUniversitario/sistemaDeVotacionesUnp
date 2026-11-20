# Hallazgos del recorrido completo de una elección · 20/11/2026

Recorrido hecho operando el sistema que corre en la PC (backend :8080, frontend :5173, MariaDB XAMPP `elecciones_unp`) con los 1 100 docentes ya importados. Cada paso se comparó con:

- Diagrama de clases `Diagrama de Clases UNP - relaciones y operaciones.drawio` (Drive y `diagramas/clases_drawio`, mismo archivo).
- Diagramas de colaboración `TODOS_LOS_DIAGRAMAS_COLABORACION_UNP - corregido segun el sistema.drawio` (Drive, versión del 19/11).
- Diagramas de secuencia `diagramas/secuencia_drawio/TODOS_LOS_DIAGRAMAS_SECUENCIA_UNP.drawio`.
- La guía `GUIA_RECORRIDO_COMPLETO_SISTEMA.md` (archivos del proyecto, 01/11/2026).

No se modificó código. Cada hallazgo indica su tipo:

- **PROG∉DIAG**: está en el programa y no en los diagramas.
- **DIAG∉PROG**: está en los diagramas y no en el programa.
- **FALLA**: error o comportamiento incorrecto del flujo.
- **GUIA**: la guía de recorrido ya no coincide con el sistema.
- **NOTA**: observación menor o de nombres.

Severidad: 🔴 alta (bloquea o da un resultado incorrecto) · 🟠 media · 🟢 baja.

---

## 0. Estado inicial encontrado

| Dato | Valor |
|---|---|
| Docentes | 1 100 (953 ACTIVO y habilitados, 27 INACTIVO, 66 LICENCIA, 54 SUSPENDIDO) |
| Cuentas | `admin` (ADMIN), `JeremySuarez` (CEUNP), 1 100 DOCENTE con cambio de clave pendiente |
| Proceso 1 | «Elección de Rector y Vicerrectores UNP 2027-2031», INSCRIPCION, sufragio 06/12/2026 09:00-15:00, quórum 60 %, límite de inscripción 20/11/2026 18:00 |
| Cargo | Rector y Vicerrectores (Fórmula), nivel UNIVERSIDAD |
| Listas | Lista A «Integridad Universitaria» INSCRITA, 3 candidatos PENDIENTE |
| Padrón del proceso | 85 electores (aprobado el 03/11, antes de importar los 1 000 docentes nuevos) |

---

## 1. Hallazgos generales (estructura)

| # | Tipo | Sev. | Hallazgo | Evidencia |
|---|---|---|---|---|
| G1 | PROG∉DIAG | 🟠 | Las tablas `constancia_pendiente` y `sorteo_compromiso` existen en la BD pero no tienen clase en el diagrama de clases (el diagrama dice «Clases = tablas de la BD»). | `information_schema.tables` vs. clases del drawio |
| G2 | PROG∉DIAG | 🟢 | Columnas de la BD que no figuran en su clase: `usuario.token_valido_desde`, `terminal_votacion.id_usuario_conexion`, `terminal_votacion.secreto_hash`, `respaldo_bd.hash_sha256`. | comparación automática de columnas |
| G3 | NOTA | 🟢 | Las fronteras («boundary») de los diagramas de colaboración usan nombres que no existen en el frontend: `PantallaLogin` (es `LoginPage.jsx`), `PantallaConvocatoria` (`ConvocatoriaPage.jsx`), `PantallaPadron` (`PadronPage.jsx`), `PantallaInscripcion` (`InscripcionPage.jsx`), `PantallaTachas` (carpeta `tachas/`), `PantallaPersoneros` (`PersonerosPage.jsx`), `PantallaSorteoMesa` (carpeta `sorteo/`), `PantallaCredenciales` (`CredencialesPage.jsx`), `PantallaInstalacion` (`InstalacionMesaPage.jsx`), `ComputoResultado` (`PantallaComputo.jsx`), `PantallaCalificacion` (no hay pantalla propia: se califica dentro de `InscripcionPage.jsx`), `PantallaCambiarPassword` (`CambiarPasswordObligatorioPage.jsx` y `CuentaPage.jsx`), `PantallaPortalResultados`. Los demás CUS (09 a 19) sí coinciden con el código. | nombres de archivos de `frontend/src/pages` |
| G4 | DIAG∉PROG | 🟢 | Controles del diagrama sin clase Java con ese nombre: CUS00 `VerificarSesion`, `ValidarCredenciales`, `RegistrarAcceso` (todo vive en `AuthController`/`UsuarioService`); CUS20 `RevisarExpediente`, `CalificarLista` (la calificación es `POST /api/listas/{id}/validar` en `ProcesoController`); CUS21 `ConsultarSeguridad`, `CambiarPassword`, `CerrarSesion` (en `AuthController` y `PoliticaPassword`). Los controles de CUS01 a CUS19 sí existen como clases. | `backend/src/main/java/**` |
| G5 | GUIA | 🔴 | La guía dice que al importar el Excel la contraseña inicial de cada docente es su DNI. Ya no es así: desde la corrección de auditoría A3 la clave provisional es **aleatoria** y se muestra una sola vez al ADMIN en el resultado de la importación. Con el DNI ningún docente puede entrar; hay que restablecer la clave desde CUS18 o guardar la lista que mostró la importación. | `ImportacionDocenteService.java:49-50, 192-203`; login de `jsuarez` con `03681072` → 401 |
| G6 | GUIA | 🟠 | La guía usa la cuenta `ceunp`; en esta base la cuenta CEUNP es `JeremySuarez` y la clave de `admin` ya no es la del script (`Admin2026*`). | tabla `usuario` |
| G7 | FALLA | 🟠 | El padrón aprobado del proceso 1 quedó con 85 electores aunque después se importaron 1 000 docentes más (hoy hay 953 habilitados). Nada avisa en el proceso de que el padrón quedó desactualizado frente a la base docente. | `padron_electoral` (85 docentes distintos) vs. `docente` |

---

## 2. Recorrido por caso de uso

Cuentas usadas: `admin` y `JeremySuarez` (CEUNP) con la clave que indicó el usuario. Para cada docente que participa, el ADMIN restableció su clave desde CUS18 (`POST /api/administracion/usuarios/{id}/clave`) y el docente la cambió en su primer ingreso (CUS21). Todas las acciones se hicieron contra la API del backend (la misma que usa el frontend). Hora local de Piura (UTC−5).

### CUS01 · Convocatoria y cronograma

El proceso 1 ya estaba publicado (INSCRIPCION), así que no se creó uno nuevo: el sistema solo admite un proceso en curso.

| # | Tipo | Sev. | Hallazgo |
|---|---|---|---|
| C01-1 | FALLA | 🔴 | **`PATCH /api/procesos/1/estado` pasó el proceso a VOTACION el 20/11 a las 11:31 aunque el sufragio estaba fijado para el 06/12 09:00 y el plazo de inscripción seguía abierto hasta las 18:00 de ese día.** El cambio de estado valida padrón, listas admitidas, orden de cédula y mesas, pero no compara con las fechas del cronograma. Se puede abrir la votación 16 días antes y con la inscripción todavía abierta. |
| C01-2 | PROG∉DIAG | 🟠 | *(Corregido el 20/11: la primera versión decía que no había botón.)* La pantalla «Convocatoria y cronograma» sí tiene el botón **«Abrir la votación»** (`PATCH /api/procesos/{id}/estado`), pero el diagrama de colaboración de CUS01 no lo modela: termina en `publicarConvocatoria`. |
| C01-3 | NOTA | 🟢 | `PUT /api/convocatorias/{id}/cronograma` exige reenviar el nombre del proceso aunque solo se cambien fechas; si falta, responde «El nombre del proceso es obligatorio». Una vez publicado, el cronograma queda congelado (correcto), por lo que para simular el día de la elección hay que mover las fechas por SQL. |

### CUS02 · Padrón electoral

| Paso | Resultado |
|---|---|
| Estado del padrón del proceso 1 | La pantalla muestra «previstos 953 / en padrón 85» y el requisito DEPURADO en falla (la última importación es posterior a la depuración). Bien resuelto. |
| Depurar (ADMIN) | 953 habilitados, 147 inhabilitados (66 LICENCIA, 54 SUSPENDIDO, 27 INACTIVO), motivo RN03 en cada uno. |
| Aprobar (CEUNP) | Se volvió a aprobar sin borrar nada: «953 electores con 953 registros de votación». |

| # | Tipo | Sev. | Hallazgo |
|---|---|---|---|
| C02-1 | NOTA | 🟢 | El hallazgo G7 queda mitigado: la pantalla del padrón sí avisa (previstos vs. en padrón y requisito DEPURADO). Lo que falta es el aviso en el resto del sistema: el proceso puede seguir con el padrón viejo si nadie entra a esa pantalla. |
| C02-2 | DIAG∉PROG | 🟢 | El diagrama pone `Administrador` en importar/depurar y `CEUNP` en aprobar. En el programa el CEUNP también puede depurar (`/api/padron/depurar` admite ADMIN y CEUNP). |

### CUS03 · Inscripción de listas

Se inscribieron la Lista B «Renovación Académica» (Farfán, Espinoza, Requena) y la Lista C «Unidad Docente» (Zevallos, Roman, Silva). Rechazos comprobados: 03681004 (GRADO MAESTRO), 03681014 (LICENCIA y no habilitado), 03681072 (categoría AUXILIAR, grado y antigüedad de 3 años), 03681001 (RN11, ya está en la Lista A) y un segundo Rector en la misma lista (RN10). La validación del servidor repite las reglas al grabar (no basta con saltarse la pantalla).

| # | Tipo | Sev. | Hallazgo |
|---|---|---|---|
| C03-1 | DIAG∉PROG | 🟠 | El actor del diagrama de colaboración CUS03 es «Lista / Candidato», pero en el programa solo el CEUNP inscribe (todos los endpoints de `/api/inscripcion` son `hasRole('CEUNP')`). Las listas no tienen acceso propio. |
| C03-2 | NOTA | 🟢 | Si el cuerpo JSON llega con una codificación inválida, el mensaje es «Formato de datos inválido. Revise las fechas (aaaa-mm-dd…) y los números», que confunde cuando el problema es un texto con tildes. |

### CUS04 · Tachas

`jsuarez` presentó la tacha contra Walter Zevallos (Lista C, Rector) y quedó PENDIENTE. Una segunda tacha suya contra el mismo candidato se rechazó (409). Con la tacha pendiente, calificar la Lista C se rechazó («La lista tiene tachas PENDIENTES»). El CEUNP la declaró FUNDADA: Zevallos EXCLUIDO y la Lista C TACHADA (RN12).

| # | Tipo | Sev. | Hallazgo |
|---|---|---|---|
| C04-1 | FALLA | 🔴 | **En esta base, al declarar FUNDADA la tacha, los otros dos candidatos de la Lista C (Katia Roman y Nestor Silva) se quedaron en PENDIENTE.** Por eso siguen contando como «candidatos» en todo el proceso: el sorteo los excluyó por RN20 (8 impedidos en vez de 6) y no se pudo acreditar a Katia Roman como personero (RN21). La causa es que la BD local no tenía aplicada `base-de-datos/migracion_20261112_credenciales_qr.sql`, que trae la versión corregida de `sp_resolver_tacha` (excluye a todo el bloque). Ver G8. |
| C04-2 | DIAG∉PROG | 🟠 | El diagrama CUS04 solo actualiza `Tacha` y `Candidato`. El programa también cambia `ListaElectoral` a TACHADA y quita su orden de cédula (RN12). Falta la entidad ListaElectoral en el diagrama. |
| C04-3 | PROG∉DIAG | 🟢 | El ADMIN también puede presentar tachas en nombre de un docente (en el controlador `esCeunp` incluye a ADMIN). No está en el diagrama ni en la guía. |

### CUS20 · Calificar listas

Lista A y Lista B → ADMITIDA (sus candidatos pasan a APROBADO). Lista C → «La lista ya fue calificada».

| # | Tipo | Sev. | Hallazgo |
|---|---|---|---|
| C20-1 | NOTA | 🟢 | Para la Lista C (TACHADA) el mensaje «La lista ya fue calificada» es impreciso: no fue calificada, cayó por tacha. |
| C20-2 | NOTA | 🟢 | No existe la pantalla `PantallaCalificacion` ni los controles `RevisarExpediente`/`CalificarLista`: es una acción dentro de Inscripción (ver G3/G4). |

### CUS06 · Sorteos

Orden de cédula con aporte `CEDULA-2026`: 1.º Lista A, 2.º Lista B. Mesas con 200 electores máximo en «Biblioteca Central»: **5 mesas** (191, 191, 191, 191, 189). Universo: 953 habilitados, 8 impedidos por RN20, 945 elegibles. Sorteo con aporte `UNP-2026`: 30 miembros (3 titulares y 3 suplentes por mesa), todos pasaron a MIEMBRO_MESA. Mesa 001: presidenta Paola Palacios (`ppalacios`), secretaria Susana Sernaqué (`ssernaque`), vocal `respinoza2`.

| # | Tipo | Sev. | Hallazgo |
|---|---|---|---|
| C06-1 | PROG∉DIAG | 🟠 | El sorteo ahora es de compromiso y revelación: el servidor genera un secreto, publica un `compromiso` (SHA-256) antes del sorteo y la semilla final combina el secreto con el aporte del operador. El diagrama CUS06 solo muestra `ingresarSemilla → generarAleatoriedad`, sin el compromiso ni la tabla `sorteo_compromiso` (G1). |
| C06-2 | GUIA | 🟠 | La guía dice que la semilla `UNP-2026` da siempre la misma mesa (gtalledo, zchunga, cbenites) y que la «Vista previa» muestra los nombres. Ya no: la vista previa solo devuelve el compromiso y la lista vacía, y el resultado cambia en cada sorteo porque interviene el secreto del servidor. |
| C06-3 | FALLA | 🟠 | Consecuencia de C04-1: 2 docentes de una lista TACHADA quedaron fuera del sorteo de miembros de mesa como si fueran candidatos. |

### CUS05 · Personeros

Acreditados: Lista A GENERAL `jsuarez`, MESA 001 `lpena`, MESA 002 `lyarleque`; Lista B GENERAL `kdioses`, MESA 001 `jlucano`, MESA 002 `mchero`. Todos pasaron a rol PERSONERO. Rechazos comprobados: miembro de mesa (RN20), candidato (RN21), docente en LICENCIA, segundo GENERAL, lista TACHADA, mismo docente en otro tipo, segundo personero de la misma lista en una mesa.

| # | Tipo | Sev. | Hallazgo |
|---|---|---|---|
| C05-1 | FALLA | 🟠 | Katia Roman (candidata de la Lista C ya TACHADA) fue rechazada como personero de la Lista B por «RN21: es candidato». Mismo origen que C04-1. |

### CUS07 · Credenciales y QR

| # | Tipo | Sev. | Hallazgo |
|---|---|---|---|
| G8 | FALLA | 🔴 | **La pantalla de Credenciales y QR daba error 500 («Error de base de datos»).** La BD local no tenía la migración `migracion_20261112_credenciales_qr.sql` (falta la columna `credencial_qr.codigo_qr` y la tabla `solicitud_regeneracion_qr`). El backend solo comprueba que exista la tabla `credencial_qr`, no sus columnas, así que el error no dice qué falta. **Se aplicó la migración** (es «segura»: solo agrega la columna, la tabla y reemplaza `sp_resolver_tacha`; antes se guardó un volcado de la base). Después de eso el módulo funcionó. Mejora sugerida: que `verificarInstalacion()` revise también las columnas, o que el script único y la migración se apliquen juntos. |
| C07-1 | PROG∉DIAG | 🟠 | Existe todo un flujo de **solicitud de regeneración de QR** (el docente pide un QR nuevo y el CEUNP aprueba o rechaza: `/api/credenciales/solicitar-regeneracion`, `/solicitudes/{id}/aprobar|rechazar`) y la tabla `solicitud_regeneracion_qr`. No aparece en el diagrama de colaboración CUS07 ni en el de clases. |
| C07-2 | NOTA | 🟢 | El control del diagrama se llama `EmitirConstancia` con el mensaje `guardarConstancia()`, pero lo que se emite es una credencial (constancia es otra cosa: la constancia de voto de CUS10). Conviene renombrarlo en el diagrama. |

Resultado: 30 fotochecks de miembro, 6 credenciales de personero y 953 pases de elector emitidos. Verificación de un pase válido → VALIDA; revocación de un pase con motivo → la verificación devuelve REVOCADA; reemisión → nuevo QR vigente; historial con emisor `JeremySuarez`. La página pública `/api/publico/credenciales/{código}` funciona con el código completo `SICEUNP|E|…` codificado en la URL.

### Simulación del día de la elección

1. ADMIN: `INSTALACION_CONTROL_HORARIO` y `SUFRAGIO_CONTROL_HORARIO` a 0 (con motivo; quedan en el historial).
2. CEUNP: `PATCH /api/procesos/1/estado` → VOTACION (ver C01-1: se aceptó sin mover fechas).
3. SQL: límite de inscripción = hace 2 h, inicio = hace 1 h, fin = hoy 23:59.

### CUS08 · Instalar mesa

Las 5 mesas quedaron INSTALADAS, con su Acta de Instalación. Mesa 001: presidenta y secretaria por QR del fotocheck, vocal titular **ausente**, primer suplente presente con DNI → asumió como VOCAL de forma automática (`rol_instalacion = VOCAL`). Un DNI que no coincide fue rechazado (RN30). Personeros `lpena` y `jlucano` registrados presentes en la 001, `lyarleque` y `mchero` en la 002. Material: los 6 ítems CONFORME y cédulas = electores de la mesa. Un presidente no puede ver ni operar otra mesa (403 «No es miembro de esta mesa»).

| # | Tipo | Sev. | Hallazgo |
|---|---|---|---|
| C08-1 | PROG∉DIAG | 🟠 | El diagrama CUS08 no incluye el registro de **personeros presentes** (`asistencia_personero_mesa`), ni el **reemplazante externo** (`reemplazo_mesa`), ni el registro de ausencia, ni la **declaración de mesa no instalada** y la **evaluación de nulidad** (RF58, RF60). Todo eso existe en el programa. |
| C08-2 | NOTA | 🟢 | El actor del diagrama es «Presidente de mesa», pero cualquier miembro de la mesa (y el CEUNP) puede registrar llegadas e instalar. |

### CUS09 y CUS10 · Verificar elector y emitir voto

Un terminal por mesa, conectado por la secretaria (el equipo recibe un secreto de dispositivo). Pruebas con el primer elector de la mesa 001:

| Prueba | Resultado |
|---|---|
| Verificar por QR | APTO, muestra datos para comparar con el DNI |
| La cabina pide su habilitación dos veces | La segunda vez da EN_USO: el token de un solo uso solo se entrega una vez. Hubo que **anular** la habilitación y **rehabilitar** al elector (RF66), y entonces votó. |
| Reusar el token después de votar | 403 «RF67: el terminal no tiene una habilitación vigente» |
| El mismo elector otra vez | «RN01: el elector ya votó. Se registró la incidencia» |
| Docente en LICENCIA | «RN30: no figura en el padrón del proceso» |
| Elector de otra mesa | «vota en la mesa 002» |
| Voto NULO desde la cabina | No admitido (RN25) |

| # | Tipo | Sev. | Hallazgo |
|---|---|---|---|
| C09-1 | PROG∉DIAG | 🟠 | El diagrama CUS09/10 no tiene el **terminal de votación como entidad** (`terminal_votacion`, `habilitacion_terminal` con token de un solo uso y secreto de dispositivo), ni las incidencias (`incidencia_mesa`: anular, rehabilitar, rechazo, ya votó). En el diagrama la verificación habilita directamente el terminal. |
| C09-2 | NOTA | 🟠 | La cabina tiene un límite de **600 peticiones por minuto por IP** (`LimitePeticionesFilter`). Cada voto usa 3 peticiones (estado, voto, liberar). Si todas las cabinas de un local salen por la misma IP (NAT), entre todas no pasan de unos 200 votos por minuto, y la que supera el límite recibe 429 «Espere un minuto» en medio de un voto. Durante la simulación ocurrió en la mesa 002: un elector quedó habilitado en la cabina sin que esta pudiera leer su habilitación, y hubo que reconectar el terminal para que votara. Conviene limitar por terminal y no por IP. |
| C09-3 | PROG∉DIAG | 🟢 | Reconectar un terminal rota su secreto y deja inservible el anterior. Está bien, pero no figura en ningún diagrama. |
| C09-4 | NOTA | 🟢 | Funciona bien: a una docente se le revocó el pase y se le emitió otro. Al verificarla con el QR nuevo pero confirmar la asistencia con el número de la credencial revocada, el sistema rechazó («El pase QR ya no es válido. Verifique al elector por su DNI»). En la simulación esa docente no votó y después recibió multa de omisa, lo que es coherente. |

Resultado de la votación: **638 de 953 electores votaron (66,95 %)**, por encima del quórum de 60 %.

| Mesa | Lista A | Lista B | Blanco | Total |
|---|---|---|---|---|
| 001 | 69 | 56 | 3 | 128 |
| 002 | 67 | 57 | 4 | 128 |
| 003 | 71 | 51 | 6 | 128 |
| 004 | 70 | 55 | 2 | 127 |
| 005 | 77 | 45 | 5 | 127 |
| **Total** | **354** | **264** | **20** | **638** |

La tabla `voto` no guarda al elector y redondea la hora a la hora en punto; en la bitácora, `EMITIR_VOTO` solo guarda el cargo. El secreto del voto se mantiene.

### CUS11 · Cerrar sufragio

Las 5 mesas: cerrar → marcar ausentes → acta de sufragio con cédulas no utilizadas, firmas de la lista física y personeros firmantes. Después del cierre la mesa rechaza verificar electores («La mesa está CERRADA») y sus terminales quedan deshabilitados. Ausentes marcados: 63, 63, 63, 64 y 62. Cada acta trae su token QR (se muestra una sola vez) y su huella SHA-256.

| # | Tipo | Sev. | Hallazgo |
|---|---|---|---|
| C11-1 | NOTA | 🟢 | El cierre funciona como dice el diagrama. El diagrama no refleja que el cierre también deshabilita los terminales de la mesa. |

### CUS12 · Escrutinio y conciliación

| Mesa | Qué se probó | Resultado |
|---|---|---|
| 001 | Impugnación de un personero de otra mesa | Rechazada: «RN24: solo impugna un personero presente en la mesa» |
| 001 | Impugnación de `lpena` (Lista A) a una cédula de la Lista B | Registrada como N.º 1 |
| 001 | Conteo manual sin la línea IMPUGNADO | Rechazado: «A4: los votos impugnados deben coincidir con las impugnaciones registradas» |
| 001 | Conteo A 69, B 55, blanco 3, nulo 0, impugnado 1 | Coincide con el digital |
| 003 | Primer conteo errado (A −1, nulo +1) | «A3: el conteo manual difiere del digital… recuente»; luego el conteo correcto pasó |
| todas | Acta de escrutinio y entrega al CEUNP | Emitidas, con cargo de entrega |

| # | Tipo | Sev. | Hallazgo |
|---|---|---|---|
| C12-1 | FALLA | 🟠 | **Cualquier texto en «observaciones» deja el acta de escrutinio como OBSERVADA (A5)**, aunque diga «Escrutinio sin incidencias». Una mesa OBSERVADA queda «POR_CALIFICAR» y bloquea el cómputo hasta que el CEUNP la califique con una resolución propia. En la simulación, 4 mesas necesitaron 4 resoluciones solo por haber escrito «sin incidencias». Sugerencia: separar el texto de observaciones de una casilla explícita «el acta tiene observaciones». |
| C12-2 | GUIA | 🟢 | La guía dice que la línea «Votos impugnados» la llena el sistema. Es la pantalla la que la llena; la API exige que venga en el conteo. |
| C12-3 | PROG∉DIAG | 🟢 | El diagrama CUS12 no tiene la conciliación de cédulas sobrantes o faltantes (`destruidas`, «prevalece la cédula física» RF84), que el programa sí pide. |

### CUS13 · Impugnaciones y apelaciones

Mesa: impugnación INFUNDADA por 3 a 0, la cédula va a la Lista B. `lpena` apeló. CEUNP: fallo 001-2026-CEUNP, CONFIRMADA (1 a favor de la apelación, 4 en contra), inapelable (RN36).

| # | Tipo | Sev. | Hallazgo |
|---|---|---|---|
| C13-1 | FALLA | 🟠 | Con la apelación todavía pendiente, el CEUNP pudo **concluir la votación** (el proceso pasó a CERRADO). El bloqueo recién aparece en el cómputo («RN32: mesa 001: impugnaciones pendientes»). No cambia el resultado, pero conviene avisarlo al concluir. |
| C13-2 | FALLA | 🟠 | **«Votos a favor / en contra» significa cosas distintas según la pantalla.** En el fallo de la apelación (CUS13) son votos a favor *de la apelación*: se confirmó con 1 a 4. En la resolución de nulidades (CUS15) son votos a favor *de la decisión*: declarar INFUNDADA con 1 a 4 se rechazó («RN36: la decisión requiere mayoría simple») y pasó con 4 a 1. La guía usa 1 / 4 en los dos casos. Conviene unificar el criterio y rotular el campo. |
| C13-3 | DIAG∉PROG | 🟢 | En el diagrama CUS13 solo registra la impugnación el personero; en el programa también la registra un miembro de mesa, y hay dos endpoints para lo mismo (`/api/escrutinio/mesas/{id}/impugnaciones` y `/api/impugnaciones/mesas/{id}/impugnaciones`). |

### CUS14 · Cómputo y proclamación

| Paso | Resultado |
|---|---|
| Sesión de cómputo | Instalada con 5 miembros y 4 personeros |
| Cómputo con la apelación pendiente | Bloqueado (RN32) |
| Acta de sufragio de la 001 marcada dudosa y comprobada con su QR real | «Acta auténtica» |
| Acta de escrutinio de la 003 marcada dudosa y comprobada con un QR equivocado | «Acta NO auténtica… solo procede declarar la nulidad de la mesa» |
| Calificar mesas 002, 004 y 005 | VÁLIDA, una resolución distinta por mesa (no admite repetir el número) |
| Mesa 003 | Solo admitió calificación NULIDAD → anulada con 010-2026-CEUNP |
| Cómputo oficial | 4 mesas computadas, 1 anulada. **Lista A 283 (57,06 % de los válidos), Lista B 213 (42,94 %), blanco 14, nulos 0.** Resultado VÁLIDO, Lista A ELEGIDA |
| Proclamación | RES-CEUNP-003-2026, credencial de la lista ganadora |
| Publicación | Portal público actualizado; todas las cuentas de miembros y personeros volvieron a DOCENTE |

| # | Tipo | Sev. | Hallazgo |
|---|---|---|---|
| C14-1 | FALLA | 🔴 | **Una sola lectura equivocada del QR anula la mesa sin vuelta atrás.** En la mesa 003 se comprobó el acta con un QR que no era el suyo (como si se hubiera leído la hoja de otra mesa): el sistema la declaró NO auténtica, no permite volver a comprobarla con el QR correcto («la autenticidad de esta acta ya fue comprobada») y solo admite calificar la mesa como NULIDAD. Así se perdieron 128 votos válidos. Debería permitir repetir la comprobación (dejando ambas lecturas en la bitácora) o pedir una segunda lectura antes de condenar el acta. |
| C14-2 | FALLA | 🟠 | Con la mesa 003 anulada, el portal muestra **participación 66,95 % (638 de 953)** junto a **510 votos emitidos**. La participación y el quórum cuentan a los electores de la mesa anulada; los votos no. Hay que decidir el criterio y explicarlo en pantalla. |
| C14-3 | PROG∉DIAG | 🟢 | Hay **dos endpoints de segunda vuelta** (`/api/computo/procesos/{id}/segunda-vuelta` y `/api/nulidades/procesos/{id}/segunda-vuelta`) y dos procedimientos (`sp_convocar_segunda_vuelta` y `sp_crear_segunda_vuelta`). El diagrama la pone en CUS15 y como alterno A2 en CUS14. |
| C14-4 | NOTA | 🟢 | Al pedir la segunda vuelta con una fecha fuera de los 15 días, el error es de plazo aunque la segunda vuelta no corresponda. Con fecha válida sí responde «RN33: ningún cargo requiere segunda vuelta». El orden de las validaciones confunde. |

### CUS15 · Nulidades

Nulidad parcial de la mesa 001 (ADMISION_INDEBIDA, de un personero de la Lista B): mientras estuvo pendiente, el cómputo se bloqueó («RF94: hay recursos de nulidad pendientes»). Se declaró INFUNDADA (002-2026-CEUNP). Nulidad total (INTIMIDACION, del personero general de la Lista B): INFUNDADA (011-2026-CEUNP). La nulidad de la mesa 003 vino de la calificación del cómputo (C14-1).

| # | Tipo | Sev. | Hallazgo |
|---|---|---|---|
| C15-1 | DIAG∉PROG | 🟢 | El diagrama CUS15 hace `anularMesa → actualizarEstado` directamente. En el programa primero se registra el recurso y después lo resuelve el Pleno con votación y número de resolución; la mesa también se puede anular desde la calificación del cómputo (CUS14), un camino que el diagrama no muestra. |

### CUS16 · Omisos y multas

| Concepto | Cantidad | Monto |
|---|---|---|
| OMISO_VOTACION (2,5 % de UIT S/ 5 150 = S/ 128,75) | 315 | S/ 40 556,25 |
| OMISO_MESA (3 % = S/ 154,50), vocal titular de la mesa 001 | 1 | S/ 154,50 |
| **Total** | **316** | **S/ 40 710,75** |

Los montos coinciden con el cálculo a mano (953 − 638 = 315 omisos). Justificar antes de la resolución: rechazado (RF106). Resolución 004-2026-CEUNP; volver a generar después: rechazado (RN35). Notificación de las 316 por correo institucional. Justificación por SALUD de la multa OMISO_MESA: ADMITIDA (005-2026-CEUNP). Pago de una multa con recibo REC-000123; un segundo pago se rechazó. La docente ve su multa PAGADA en «Mis multas».

| # | Tipo | Sev. | Hallazgo |
|---|---|---|---|
| C16-1 | NOTA | 🟢 | El diagrama CUS16 corregido ya incluye resolución, notificación y pago. No figura la regla de que la justificación solo procede después de la resolución (RF106). |

### CUS17 · Resultados y verificación de actas

Un docente consultó los resultados (FINALIZADO, VÁLIDA, 4 de 5 mesas). Verificó el Acta de Sufragio de la 001 con su token: AUTÉNTICA (huella guardada = huella recalculada). El portal público sin sesión (`/resultados`) muestra el proceso, la lista ganadora y las actas. Un personero hizo un **cotejo** del Acta de Escrutinio de la 001 anotando una cifra distinta: «1 de 10 cifras no coinciden», quedó reportado al CEUNP, que lo atendió como ACLARADA.

| # | Tipo | Sev. | Hallazgo |
|---|---|---|---|
| C17-1 | NOTA | 🟢 | Concuerda con el diagrama corregido (incluye `CotejoActa`). Las decisiones del cotejo son solo ACLARADA o FUNDADA; el diagrama no dice qué pasa con el resultado cuando el cotejo es FUNDADA. |

### CUS18 · Administración

Bloqueo tras 5 intentos fallidos (el 6.º devuelve 401 y la cuenta queda bloqueada 15 min) → desbloqueo. Restablecer clave sin valor → genera una provisional. Desactivar sin motivo → rechazado; con motivo → la cuenta no entra; reactivar. Actividad de la cuenta visible. Crear CEUNP con clave corta → rechazado; DOCENTE sin docente → rechazado. El ADMIN no puede desactivarse a sí mismo. Parámetros: `INSTALACION_CONTROL_HORARIO` vuelto a 1 y `SUFRAGIO_CONTROL_HORARIO` restaurado desde su historial; UIT negativa rechazada. Catálogo de cargos excluidos del sorteo: 9 cargos.

| # | Tipo | Sev. | Hallazgo |
|---|---|---|---|
| C18-1 | GUIA | 🟠 | **El respaldo no funciona en esta instalación** porque el backend se arrancó sin la variable `RESPALDO_CLAVE`: responde 503 «defina en el servidor la variable RESPALDO_CLAVE (al menos 16 caracteres)». El README sí la documenta; la guía de recorrido no la menciona y la da por disponible. |
| C18-2 | PROG∉DIAG | 🟢 | El ADMIN puede fijar la clave de otra cuenta (no solo generar una provisional); la cuenta queda obligada a cambiarla. No figura en el diagrama. |

### CUS19 · Bitácora

4 216 registros. Verificación de la cadena: «Bitácora íntegra: los 4 216 registros conservan su sello». Detalle de un registro en JSON. Exportación CSV (1,8 MB), que queda registrada como EXPORTAR_BITACORA. El CEUNP no tiene acceso (403).

| # | Tipo | Sev. | Hallazgo |
|---|---|---|---|
| C19-1 | FALLA | 🟢 | Tres acciones que se registran no están en el catálogo `bitacora_accion`: `CAMBIO_CLAVE` (15 registros, se muestra como «CAMBIO CLAVE»), `LOGIN_BLOQUEADO` y `LOGIN_INACTIVO`. Aparecen como módulo SIN_CLASIFICAR. |
| C19-2 | NOTA | 🟢 | En el catálogo, `LOGIN_SUCCESS` y `LOGIN_FAILED` están asociados a «CUS01»; iniciar sesión es CUS00. |
| C19-3 | NOTA | 🟢 | El resumen por usuario muestra el rol **actual** de la cuenta (la presidenta de mesa aparece como DOCENTE porque al publicar volvió a ese rol), no el rol con que hizo la acción. |

---

## 3. Resumen de prioridades

| Prioridad | Hallazgos |
|---|---|
| 🔴 Alta | C01-1 (se abre la votación sin respetar fechas), C14-1 (una lectura de QR errada anula la mesa sin vuelta atrás), G8 y C04-1 (la BD local no tenía la migración del 12/11: credenciales caídas y candidatos de una lista tachada que siguen bloqueando), G5 (la guía da el DNI como clave inicial) |
| 🟠 Media | C01-2, C03-1, C04-2, C06-1, C06-2, C07-1, C08-1, C09-1, C09-2, C12-1, C13-1, C13-2, C14-2, C18-1, G1, G6, G7 |
| 🟢 Baja | El resto (nombres de pantallas y controles, mensajes imprecisos, catálogo de la bitácora) |

## 4. Cambios hechos en la base durante el recorrido

No se borró nada. Quedó en la BD:

- Proceso 1 FINALIZADO con su elección completa: listas B y C, tacha, 5 mesas, 30 miembros, 6 personeros, 989 credenciales, 638 votos, actas, impugnación, 2 nulidades infundadas, mesa 003 anulada, cómputo, proclamación y 316 multas.
- Padrón del proceso regenerado de 85 a 953 electores.
- **Migración `migracion_20261112_credenciales_qr.sql` aplicada** (antes se guardó un volcado de la base en la carpeta temporal de la sesión).
- Claves de unos 25 docentes restablecidas por el ADMIN y cambiadas a una clave de prueba común, para operar sus cuentas (miembros de mesa, personeros, `jsuarez`, `lsilva`).
- Parámetros de horario: puestos a 0 durante la jornada y devueltos a 1.
- Fechas del proceso 1 movidas por SQL al día de hoy (paso que documenta la guía).

Para repetir la simulación con otro proceso hay que limpiar los datos electorales (`base-de-datos/02_limpiar_datos_electorales.sql`), que **borra** procesos, votos y actas. Se debe confirmar antes de hacerlo.
