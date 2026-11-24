# Hallazgos del segundo recorrido completo de una elección · 24/11/2026

Segunda simulación de punta a punta, después del pull del 24/11 (ponderación estamentaria por tercios, filtro por departamento y los 17 docentes oficiales de Informática). Se operó el sistema real de la PC (backend :8080, frontend :5173, MariaDB 10.4 de XAMPP, base `elecciones_unp`) a través de la misma API que usa el frontend, con cuentas de cada rol.

Se tomó como base el informe anterior, `HALLAZGOS_RECORRIDO_ELECCION_2026-11-20.md`: la sección 4 indica qué hallazgos de ese día siguen pendientes y cuáles quedaron resueltos.

Se comparó contra:

- El diagrama de clases y los de colaboración y secuencia del repositorio (`diagramas/`), que son la versión del 24/11.
- Las copias de Drive, que son del **20/11** y no tienen los cambios de la ponderación (ver N10).
- `diagramas/diagrama_clases_diseno.puml`.

Tipos: **FALLA** (error o resultado incorrecto), **PROG∉DIAG** (está en el programa y no en los diagramas), **DIAG∉PROG** (está en los diagramas y no en el programa), **ENTORNO** (instalación o scripts), **NOTA**. Severidad: 🔴 alta · 🟠 media · 🟢 baja.

---

## 1. Preparación de la base

| Paso | Resultado |
|---|---|
| Copias de seguridad | `C:\xampp\mysql\backup_elecciones_unp_20261124_102054.sql` (antes de los scripts) y `..._105116_antes_limpieza.sql` (antes de la limpieza) |
| `15_ponderacion_tercios_ley30220.sql` | No corría en MariaDB; se corrigió y aplicó (ver N2) |
| `02_limpiar_datos_electorales.sql` | Ejecutado: se borró la elección anterior (proceso 1 FINALIZADO del 20/11) |
| `actualizar_docentes_informatica.sql` | Falló porque `constancia_pendiente` seguía apuntando a los docentes viejos (N9). Se borraron esas 6 filas huérfanas y el script corrió: 29 docentes viejos de Informática eliminados, 17 oficiales con su cuenta (`Docente2026`) |
| Excel | En `100 Docentes.xlsx` solo quedan los 17 de Informática (se quitaron 5 y se agregaron los 17). En los Excel de 700 y 1000 se quitaron 12 y 24 de Informática. La importación de `100 Docentes.xlsx` reconoció a los 112 por DNI, sin errores |
| Resultado | 1 088 docentes, 943 habilitados (65 en LICENCIA, 53 SUSPENDIDOS y 27 INACTIVOS). En Informática, solo los 17 oficiales |

## 2. Escenario simulado

| Dato | Valor |
|---|---|
| Proceso | Elección de Rector y Vicerrectores UNP 2027-2031, quórum 60 %, convocatoria 24/11, sufragio 29/12 (35 días, RN02) |
| Listas | A «Integridad Universitaria» (Correa Morocho, Gomez Sandoval, Imán Agurto) · B «Renovación Académica» (Farfán, Espinoza, Requena Tavara) · C «Unidad Docente», que cayó por tacha |
| Tacha | Presentada por Jorge Alvarado (Informática) contra Zevallos; FUNDADA, y la Lista C entera quedó TACHADA |
| Mesas | 5 mesas de unos 189 electores en Biblioteca Central, con 30 miembros sorteados |
| Personeros | 7, todos de Informática salvo Katia Roman (candidata de la Lista C tachada, acreditada en la Lista B) |
| Credenciales | 980 emitidas (943 pases, 30 fotochecks y 7 credenciales de personero); 1 regenerada a pedido de la docente |
| Jornada | Fechas movidas por SQL al día de hoy; votación abierta con el control horario **activo** |
| Votación | **661 de 943 (70,10 %)**, en 10 cabinas y 15 segundos, sin un solo error 429 |
| Votos docentes | Lista A 328 (52,48 %), Lista B 297 (47,52 %), en blanco 36, nulos 0 |
| Votos estudiantiles (registrados por el CEUNP) | Lista A 2 100 (42 %) y Lista B 2 900 (58 %) |
| **Resultado ponderado** | **Lista B 51,01 %, ELEGIDA** (47,52 × 2/3 + 58 × 1/3). Lista A 48,99 %. La ponderación cambió al ganador |
| Multas | 282 omisos × S/ 128,75 más 1 miembro de mesa × S/ 154,50 = **S/ 36 462,00** (cuadra con el cálculo a mano) |

Todo lo demás se ejecutó: impugnación (mesa INFUNDADA 2 a 1 → apelación → CEUNP CONFIRMADA 001-2026-CEUNP), nulidad parcial de la mesa 002 INFUNDADA (002-2026-CEUNP), proclamación RES-CEUNP-003-2026, publicación, justificación por SALUD, pago, verificación de actas y respaldo cifrado de la base.

---

## 3. Hallazgos nuevos

### 🔴 Alta

| # | Tipo | Hallazgo | Evidencia |
|---|---|---|---|
| N1 | FALLA | **Con la ponderación, el portal público y el acta general de cómputo mezclan votos docentes y estudiantiles.** `sp_ejecutar_computo` guarda en `resultado_electoral.total_votos` la suma docentes + estudiantes. El portal (`/api/publico/procesos/1/resultados`) muestra a la Lista B con **3 197 votos** y a la A con **2 428**, junto a «votaron 661». Además, `porcentajeValidos` ya es el porcentaje ponderado y no se ve el desglose. En el Acta General (`computo_proceso.contenido_json`) el cargo dice **válidos 5 625 y emitidos 5 661** con 661 votantes. Es el documento oficial y no cuadra. La consulta pública no se actualizó con el pull (solo `ComputoConsulta` lee las columnas nuevas). | `GET /api/publico/procesos/1/resultados`; `JSON_EXTRACT(contenido_json,'$.cargos[0].validos')` = 5625 |
| N2 | ENTORNO | **`15_ponderacion_tercios_ley30220.sql` no corría en el MySQL de XAMPP (MariaDB 10.4) y al fallar borraba `sp_ejecutar_computo`.** Tenía 5 problemas: (1) no agregaba las 5 columnas que usa (`votos_docentes`, `votos_estudiantes`, `pct_docente`, `pct_estudiante`, `pct_ponderado`); (2) usaba `CAST(... AS JSON)` y (3) `RANDOM_BYTES`, que solo existen en MySQL 8; (4) cambiaba la estructura del JSON del acta (`personeros_presentes`, `mesas` plano, `token_qr` dentro del contenido), que `ActaComputo.js` no lee; (5) creaba el procedimiento con collation `general_ci` y el cómputo fallaba con «Illegal mix of collations». **Se corrigió en la copia local** (`ALTER ... ADD COLUMN IF NOT EXISTS`, el armado JSON original con `fn_bytes_aleatorios` y `SET NAMES utf8mb4_unicode_ci`); esa corrección está **sin commit**. | ejecución del script; prueba en una copia temporal de la base |
| N3 | ENTORNO | **El backend corría código viejo después del pull.** En `backend/target` había 292 archivos fechados el **27/12/2026** (en el futuro). Maven los veía más nuevos que el código y no recompilaba, así que `POST /api/computo/procesos/{id}/votos-estudiantiles` respondía 404. Se resolvió con `mvnw clean spring-boot:run`. Recomendación: después de cada pull, levantar con `clean`, y revisar por qué hay archivos con fecha futura (reloj de otra PC o sincronización de OneDrive). | `target/classes/.../ComputoController.class` con fecha 27/12/2026 |

### 🟠 Media

| # | Tipo | Hallazgo | Evidencia |
|---|---|---|---|
| N4 | FALLA | Se registran **votos estudiantiles para una lista TACHADA** (Lista C, 100 votos). El cómputo la deja fuera porque solo une listas ADMITIDAS, pero el registro queda guardado y aparece en la respuesta. Debería exigirse lista ADMITIDA del cargo. | `POST /votos-estudiantiles` con `idLista: 3` → 200 |
| N5 | FALLA | Los votos estudiantiles se cargan **sin sustento**: solo se pide un número por lista, sin acta del estamento, número de resolución, total de votantes estudiantiles ni quórum estudiantil, y se pueden sobrescribir libremente hasta el cómputo. Para un tercio del resultado conviene pedir el documento de origen y registrar quién y cuándo lo cambió. | `ComputoDto.GuardarVotosEstudiantes` |
| N6 | FALLA | **El acta de sufragio acepta cédulas no utilizadas que no cuadran.** En la mesa 002 se registraron 64 no utilizadas con 130 votantes: 194, frente a 189 cédulas recibidas. Se firmó sin observación, ya no se puede corregir (RN28) y la conciliación del escrutinio tampoco lo detectó. Debería validar `votaron + no utilizadas = recibidas` o exigir una observación. | `cierre_mesa` de la mesa 2 |
| N7 | FALLA | **RN09 (antigüedad en la categoría) no se verifica cuando falta la fecha.** Correa Morocho e Imán Agurto no tienen `fecha_categoria` y se inscribieron con una ADVERTENCIA («el CEUNP lo verifica al calificar»), pero al calificar la lista se admitió sin pedir ninguna verificación y ambos quedaron APROBADO. Además, `actualizar_docentes_informatica.sql` y el Excel no traen `fecha_ingreso` ni `fecha_categoria` de los 17 oficiales: 6 son PRINCIPAL y DOCTOR y caen en ese caso. | `ValidarCandidato.java:205-207`; `POST /api/listas/1/validar` |
| N8 | DIAG∉PROG | El **ADMIN puede aprobar el padrón definitivo**; el diagrama CUS02 asigna esa acción solo al CEUNP. El controlador lo permite a los dos roles. | `POST /api/padron/procesos/1/aprobar` con `sim_admin` → 200 |
| N9 | ENTORNO | **`02_limpiar_datos_electorales.sql` no vacía 4 tablas:** `constancia_pendiente` (bloqueó el script de docentes con un error de clave foránea), `computo_estudiantil`, `solicitud_regeneracion_qr` y `sorteo_compromiso`. Después de una limpieza quedan filas que apuntan a procesos que ya no existen. | `grep` del script; error 1451 al borrar docentes |
| N10 | PROG∉DIAG | **El diagrama de clases no coincide con la base en la ponderación.** El diagrama tiene `resultado_electoral.factor_docente`, `factor_estudiante` y `porcentaje_ponderado`, y `computo_estudiantil.id_computo_estudiantil` como PK autoincremental; nada de eso existe en la base. La base tiene `pct_docente`, `pct_estudiante` y `pct_ponderado`, que no están en el diagrama, y en `computo_estudiantil` la PK es compuesta `(id_proceso, id_cargo, id_lista)`. También falta `credencial_qr.codigo_qr`. **Las copias de Drive son del 20/11** y no tienen ninguno de los cambios de la ponderación. | comparación automática de tablas y columnas con el drawio |
| N11 | PROG∉DIAG | Los diagramas de colaboración y de secuencia de CUS14 solo modelan `obtenerVotosEstudiantiles()` dentro del cómputo. **No modelan el registro de los votos estudiantiles por el CEUNP** (pestaña Consolidación, `registrarVotosEstudiantiles`, validaciones), que es un paso aparte y previo. | `CUS14_Computar_y_proclamar.drawio` (colaboración y secuencia) |
| N12 | NOTA | «Votos a favor / en contra» sigue significando cosas distintas en la API (pendiente C13-2). En la decisión de mesa de una impugnación (CUS13), «a favor» es a favor de **aceptar la impugnación**: para declararla INFUNDADA hubo que enviar 1 a favor y 2 en contra. En nulidades (CUS15) es a favor de **la decisión elegida**: INFUNDADA se aprueba con 4 a 1. Las pantallas lo rotulan desde el 20/11; la API no. | `decision-mesa` vs. `nulidades/{id}/resolucion` |

### 🟢 Baja

| # | Tipo | Hallazgo |
|---|---|---|
| N13 | NOTA | *(Revisado: no es falla.)* `PRESENTAR_TACHA` deja `id_usuario` en NULL pero guarda al denunciante en `id_docente`, así que la bitácora sí dice quién la presentó. `EMITIR_VOTO` sin usuario es correcto, por el secreto del voto. |
| N14 | FALLA | `SOLICITAR_REGENERACION_QR` y `APROBAR_REGENERACION_QR` se registran pero no están en el catálogo `bitacora_accion`, así que aparecen sin clasificar. |
| N15 | NOTA | Un cargo con la lista «categorías que votan» vacía se graba como si votaran PRINCIPAL, ASOCIADO y AUXILIAR, sin avisar. |
| N16 | NOTA | Si un docente presenta una tacha escribiendo el DNI de otra persona, el sistema lo ignora y registra la tacha a nombre del usuario conectado (correcto), pero no avisa de la diferencia. |
| N17 | NOTA | Después de una lectura equivocada del QR en el cómputo, el mensaje sigue diciendo «Solo procede declarar la nulidad de la mesa», aunque ahora se permite volver a leer (corrección C14-1), y la relectura funcionó. |
| N18 | NOTA | La cabina entrega el token de habilitación una sola vez; si la pantalla se recarga, hay que anular y rehabilitar (solo el presidente puede hacerlo). Funciona como está diseñado, pero conviene explicarlo en la pantalla de la cabina. |

---

## 4. Estado de los hallazgos del 20/11 (comprobado hoy)

| Hallazgo | Estado | Cómo se comprobó |
|---|---|---|
| C01-1 abrir la votación sin respetar fechas | ✅ Resuelto | Rechazó con «RN05: el plazo de inscripción sigue abierto» |
| C04-1 / C05-1 / C06-3 candidatos de una lista tachada seguían PENDIENTE | ✅ Resuelto | Los 3 de la Lista C quedaron EXCLUIDO; 937 elegibles (943 − 6); Katia Roman acreditada como personero |
| G8 credenciales con error 500 | ✅ Resuelto | 980 credenciales emitidas, verificación, revocación y regeneración |
| C07-1 regeneración de QR | ✅ Funciona | La solicitud de la docente fue aprobada por el CEUNP y el QR anterior quedó REVOCADO (pero ver N14) |
| C09-2 límite de la cabina por IP | ✅ Resuelto | 661 votos en 10 cabinas sin un solo 429 |
| C13-1 concluir con una apelación pendiente | ✅ Resuelto | Ahora avisa: «hay 1 impugnación sin resolver o apelada» |
| C13-2 «a favor / en contra» | 🟡 Parcial | Rotulado en pantallas; la API sigue con dos criterios (N12) |
| C14-1 una lectura de QR errada anulaba la mesa | ✅ Resuelto | La relectura con el QR correcto dio «Acta auténtica» (mensaje por mejorar, N17) |
| C14-4 orden de validaciones de la segunda vuelta | ✅ Resuelto | Responde «RN33: ningún cargo requiere segunda vuelta» |
| C18-1 respaldo sin `RESPALDO_CLAVE` | ✅ Funciona | Respaldo cifrado AES-256 generado (60 tablas, 12 797 filas) |
| C19-1 acciones fuera del catálogo | 🟡 Parcial | `CAMBIO_CLAVE` y `LOGIN_*` ya están; faltan las de regeneración de QR (N14) |
| C12-1 cualquier observación deja el acta OBSERVADA | ➖ Sin cambio | Es la regla A5 decidida; no se escribió ninguna observación |
| C01-3, C04-3, C09-3, C13-3, C14-3, C15-1, C18-2, C19-3, G3/G4 | ⏳ Pendientes | No se volvieron a probar; siguen como en el informe anterior |

## 5. Lo que funcionó bien (sin hallazgos)

Las validaciones de la convocatoria (RN02, jornada única, límite de inscripción, un solo proceso en curso, cronograma congelado), RN09/RN10/RN11 y la categoría en la inscripción, la tacha y su resolución en bloque, el sorteo con compromiso y revelación, RN19/RN20/RN21 en personeros y miembros de mesa, la instalación con el control horario (ventana de 09:00 a 12:00, RN30 con DNI equivocado, suplente que asume como vocal, material obligatorio), la verificación del elector (QR revocado, otra mesa, no figura en el padrón, ya votó), RN25 (no hay voto nulo en la cabina), el cierre con RN06, el escrutinio (RN24, A4 y A3), la apelación inapelable (RN36), RF94 (nulidad pendiente que bloquea el cómputo), RN26 (cómputo y votos estudiantiles irreversibles), las multas (RF106, RN35) y la integridad de la bitácora (4 612 registros íntegros).

## 6. Cambios que quedaron en la base y en la PC

- Nueva elección completa en el proceso 1 (FINALIZADO, con la Lista B proclamada).
- Cuentas de prueba `sim_admin` (ADMIN) y `sim_ceunp` (CEUNP), creadas para operar sin las claves de `admin` y `JeremySuarez`. Se pueden desactivar desde Cuentas y roles.
- Las 31 cuentas de miembros de mesa y de Katia Roman tienen una clave de prueba, fijada por el ADMIN (CUS18) y cambiada en el primer ingreso (CUS21). Los 17 docentes de Informática volvieron a `Docente2026`.
- Fechas del proceso movidas por SQL al día de hoy (abrir la votación y cerrar la jornada), como indica la guía.
- `base-de-datos/15_ponderacion_tercios_ley30220.sql` corregido (N2) y los 3 Excel modificados: todo **sin commit**.

## 7. Prioridad sugerida para las mejoras

1. **N1**: separar votos docentes y estudiantiles en `resultado_electoral` (que `total_votos` vuelva a ser solo docentes) y actualizar el portal público y el Acta General.
2. **N2 y N3**: subir el script 15 corregido y documentar `mvnw clean` después de cada pull.
3. **N4 y N5**: validar la lista ADMITIDA y pedir sustento (acta y resolución) para los votos estudiantiles.
4. **N6**: cuadre de cédulas en el acta de sufragio.
5. **N7**: cargar `fecha_categoria` de los 17 docentes oficiales y bloquear o pedir confirmación al calificar cuando falte.
6. **N9**: completar `02_limpiar_datos_electorales.sql` con las 4 tablas.
7. **N10 y N11**: actualizar el diagrama de clases (columnas reales de la ponderación) y CUS14, y subir las versiones nuevas a Drive.
8. El resto (N8, N12-N18) y los pendientes del 20/11.

---

## 8. Correcciones hechas el 24/11/2026 (después del recorrido)

El profesor indicó que los votos estudiantiles se toman simplemente como un número por lista (sus actas son por mesa) y que el resultado es: % de votos docentes × 2/3 + % de votos estudiantiles × 1/3. Su ejemplo (docentes 46 y 43, estudiantes 553 y 631) da **50,03 % y 49,97 %**, que es exactamente la fórmula del sistema (34,46 + 15,57 y 32,21 + 17,76).

| Hallazgo | Corrección | Dónde |
|---|---|---|
| N1 | `total_votos` vuelve a ser **solo los votos docentes** de las mesas; el % que decide queda en `pct_ponderado` (= `porcentaje_validos`). El Acta General trae `validos` (docentes), `validos_estudiantes` y `ponderado`. La proclamación guarda los votos docentes. El portal, los resultados del docente y la pantalla de cómputo muestran el desglose y los **aportes ×2/3 y ×1/3** como en el ejemplo del profesor. La segunda vuelta y el desempate ordenan por el % ponderado. | `15_ponderacion_tercios_ley30220.sql` (`sp_ejecutar_computo`, `sp_dirimir_empate`, `sp_crear_segunda_vuelta`), `ProcesoService`, `ResultadosConsulta`, `NulidadesConsulta`, `PantallaComputo.jsx`, `ActaComputo.js`, `PantallaResultados.jsx` |
| N2 | Script 15 compatible con MariaDB 10.4 (columnas, JSON, aleatorio y collation) | `15_ponderacion_tercios_ley30220.sql` |
| N4, N5 | Votos estudiantiles solo para listas ADMITIDAS del cargo; cada registro o cambio queda en la bitácora (`REGISTRAR_VOTOS_ESTUDIANTILES`) | `sp_registrar_votos_estudiantiles` |
| N6 | El acta de sufragio exige que votantes + cédulas no utilizadas = cédulas recibidas, o una observación que explique la diferencia | `sp_generar_acta_sufragio` (script único, `actualizar_sin_borrar.sql` y `16_correcciones_recorrido_24_11.sql`) |
| N7 | Al admitir una lista con candidatos sin fecha de categoría, el sistema pide que el CEUNP confirme que verificó la antigüedad en el expediente | `ProcesoService.validarLista`, `ProcesoController`, `InscripcionPage.jsx` |
| N8 | El padrón definitivo lo aprueba solo el CEUNP | `PadronController` |
| N9 | La limpieza vacía también `constancia_pendiente`, `computo_estudiantil`, `solicitud_regeneracion_qr` y `sorteo_compromiso` | `02_limpiar_datos_electorales.sql` |
| N10, N11 | Diagrama de clases con las columnas reales (`pct_docente`, `pct_estudiante`, `pct_ponderado`, PK compuesta e `id_usuario` en `computo_estudiantil`); nota del paso de registro de votos estudiantiles en los diagramas de colaboración y secuencia de CUS14; `diagrama_clases_diseno.puml` | `diagramas/` |
| N14 | Catálogo de la bitácora con `SOLICITAR_/APROBAR_/RECHAZAR_REGENERACION_QR` y `REGISTRAR_VOTOS_ESTUDIANTILES` | script único, `actualizar_sin_borrar.sql`, script 16 |
| N17 | El mensaje tras un QR equivocado indica que se puede volver a leer | `VerificarActas.java` |

**Pruebas hechas sobre la base local:** se recalculó el cómputo del proceso 1 con los votos estudiantiles del ejemplo (553 y 631). Resultado: Lista A 52,48 % × 2/3 = 34,99 más 46,71 % × 1/3 = 15,57, total **50,56 %, ELEGIDA**; Lista B 31,68 + 17,76 = 49,44 %. `total_votos` = 328 y 297; el Acta General dice 625 válidos docentes, 1 184 estudiantiles y 661 emitidos; el portal muestra el desglose. También se probó: rechazo de votos para la lista TACHADA, registro en la bitácora, aprobación del padrón con ADMIN rechazada (403) y la regla de antigüedad. El backend y el frontend compilan.

**No probado de punta a punta:** la segunda vuelta y el desempate con ponderación (no hubo empate ni segunda vuelta en el escenario) y el cuadre de cédulas (necesita otra jornada).

**Pendiente:** N3 (fechas futuras en `backend/target`: levantar con `mvnw clean spring-boot:run`), N12 (criterio de «votos a favor» en la API), N15, N16, N18 y los pendientes del 20/11. Las copias de los diagramas en Drive siguen en la versión del 20/11; los archivos `TODOS_LOS_DIAGRAMAS_*` no se tocaron.

**Orden para instalar en otra PC:** `00_script_unico_elecciones_unp.sql` → `15_ponderacion_tercios_ley30220.sql` → `actualizar_docentes_informatica.sql`. En una base que ya existe: `actualizar_sin_borrar.sql` → `15_...` → `16_correcciones_recorrido_24_11.sql`.
