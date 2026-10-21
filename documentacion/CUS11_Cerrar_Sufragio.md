# CUS11 · Cerrar sufragio

**Actor:** Presidente de mesa (el CEUNP supervisa y también puede cerrar; ADMIN solo consulta) · **Pantalla:** menú «Cerrar sufragio» (MIEMBRO_MESA) y «Cierre del sufragio» (CEUNP)
**Caso de negocio:** CUN09 Realizar escrutinio y levantar actas (paso 1) · **Módulo:** M10 (RF74 a RF76) · **Reglas:** RN06, RN28 · **Fuente:** tabla 37 del informe v2.1
**Requiere:** mesa INSTALADA (CUS08) y el sufragio de CUS09/CUS10 (asistencia, habilitaciones de terminal y votos).
**Instalación:** en una base ya creada, ejecutar `base-de-datos/10_cerrar_sufragio.sql` (después de `09_instalacion_mesa.sql` y `06_verificar_elector_emitir_voto.sql`). `01_crear_base_de_datos.sql` ya lo incluye al final y `02_limpiar_datos_electorales.sql` vacía su tabla. Si se vuelve a ejecutar el script 06, hay que ejecutar otra vez el 10, porque el 10 redefine `sp_votar_habilitado` (flujo A1).

## Correspondencia con el diagrama de colaboración («Colaboracion - Cerrar Sufragio», `diagramas/Sistema De Elecciones.mdl`)

| Mensaje del diagrama | Frontend | Backend |
|---|---|---|
| 1 `solicitarCierre(id_mesa)` | `PantallaCierreSufragio`, paso 1: «Cerrar el sufragio» → «Confirmar cierre» | `POST /api/cierre/mesas/{id}/cerrar` |
| 2 `cerrarVotacion(id_mesa)` | — | `CerrarVotacion.cerrarVotacion` → `sp_cerrar_votacion` |
| 3 `actualizarEstado('CERRADA', hora_cierre)` | — | `sp_cerrar_votacion` → `mesa_electoral` (estado y hora de cierre), terminales deshabilitados y `cierre_mesa` |
| 4 `mostrarTotalVotantes(total)` | Indicadores «Votaron / No votaron» y datos del cierre | La respuesta trae `total` y el detalle |
| 5 `confirmarAusentes()` | Paso 2: lista de quienes no votaron → «Confirmar ausentes y marcar NO VOTÓ» | `POST /api/cierre/mesas/{id}/ausentes` |
| 6 `marcarAusentes(id_mesa)` | — | `MarcarAusentes.marcarAusentes` → `sp_marcar_ausentes` |
| 7 `actualizarNoVoto(id_mesa)` | — | `sp_marcar_ausentes` → `padron_electoral.no_voto` |
| 8 `mostrarListaNoVoto()` | Tabla con la marca NO VOTÓ e «Imprimir lista» (`ActaSufragio.imprimirListaNoVoto`) | `detalle.noVotaron` |
| 9 `ingresarObservaciones(cedulas_no_usadas, observaciones)` | Paso 3: cédulas no utilizadas, firmas de la lista física (A2), observaciones y personeros que firman | `POST /api/cierre/mesas/{id}/acta` |
| 10 `generarActa(datos)` | — | `GenerarActaSufragio.generarActa` → `sp_generar_acta_sufragio` |
| 11 `insertarActa('SUFRAGIO', hash, contenido)` | — | `sp_generar_acta_sufragio` → `sp_emitir_acta` → `acta_electoral` (huella SHA-256 y token del QR) |
| 12 `registrarFirmas(firmas)` | — | `sp_generar_acta_sufragio` → `firma_acta` |
| 13 `mostrarActaSufragio()` | `ActaVista`: datos, firmas, QR de verificación e «Imprimir acta» (`ActaSufragio.imprimirActaSufragio`) | La respuesta trae el acta y el token del QR, que se entrega una sola vez |

### Cambios que conviene hacer en el diagrama
- El mensaje 10 aparece escrito dos veces en el modelo («generarActa(datos)generarActa(datos)»). Debe quedar `generarActa(datos)`.
- El mensaje 9 debe incluir el conteo de firmas de la lista física, que pide el flujo A2: `ingresarObservaciones(cedulas_no_usadas, firmas_lista_fisica, observaciones)`.
- El mensaje 12 recibe las firmas del presidente y del secretario en funciones y de los personeros presentes que desean firmar (paso 7 de la tabla 37).
- La hora de cierre la registra el sistema en el mensaje 3 (`actualizarEstado('CERRADA', hora_cierre)`), no la escribe el presidente como dice el paso 5 de la tabla 37. Así no se puede poner una hora distinta de la real.

## Flujos alternos (tabla 37)
- **A1 · A las 15:00 aún hay electores votando (Art. 51a):** la mesa no se cierra mientras haya una habilitación de terminal pendiente. La pantalla muestra «Votando ahora» y el requisito sin cumplir. El elector que fue habilitado antes de la hora de cierre puede confirmar su voto después de esa hora (`sp_votar_habilitado` redefinido). Si el elector abandonó la cabina, la mesa anula la habilitación en «Verificar elector» (CUS10 A3) y luego cierra.
- **A2 · El total del sistema difiere del conteo de firmas de la lista física:** si se ingresa el conteo y no coincide con los votantes, la observación es obligatoria. El acta guarda el conteo y la diferencia.

## Reglas del cierre
- **Precondición:** proceso en VOTACION, mesa INSTALADA y es la hora de cierre del proceso (`fecha_fin`, las 15:00 según RN06), o ya votaron todos los electores hábiles de la mesa. Ningún elector puede estar votando (A1).
- **Paso 2:** al cerrar, la mesa pasa a CERRADA, ya no verifica electores (CUS09) y sus terminales quedan deshabilitados (`terminal_votacion.activo = 0`). El terminal muestra «Sufragio cerrado».
- **RF75:** se marca NO VOTÓ a cada elector hábil de la mesa que no votó. La lista distingue a quien no asistió de quien asistió y no votó (CUS10 A3, Disp. Final 5.ª). La marca no se puede quitar y quien la tiene ya no puede votar (trigger `trg_padron_no_voto_bu`).
- **RF76:** el acta guarda la hora de instalación y de cierre, los electores hábiles, los que votaron y los que no, las cédulas recibidas y no utilizadas (no más de las recibidas), la lista física, los miembros en funciones, la lista NO VOTÓ y las observaciones, con su huella SHA-256 y su QR. Firman el presidente y el secretario en funciones (titular, suplente o reemplazante) y los personeros presentes que lo deseen.
- **Actor:** entre los miembros cierra el **presidente en funciones**. Si la presidencia la ejerce un reemplazante sin cuenta, puede hacerlo cualquier miembro presente. El CEUNP siempre puede cerrar.
- Emitida el acta, el registro de cierre ya no cambia (`trg_cierre_bu`) y el acta solo se puede anular (RN28).

Para probar fuera de la hora de cierre, ponga `SUFRAGIO_CONTROL_HORARIO = 0` en Parámetros.

### Reemplaza al cierre anterior
`POST /api/mesas/{id}/cerrar` (que cerraba y emitía a la vez las actas de sufragio y de escrutinio con `sp_cerrar_mesa`) responde ahora 410 y remite a «Cerrar sufragio». El acta de escrutinio corresponde al CUS12. `sp_cerrar_mesa` se conserva solo para el script de demostración `03_demo_flujo_completo.sql`. En «Mi Mesa de Sufragio» el botón lleva a la nueva pantalla.

## Endpoints (`/api/cierre`)
| Método | Ruta | Rol |
|---|---|---|
| GET | `/procesos` | ADMIN, CEUNP |
| GET | `/mesas?procesoId=` · `/mesas/{id}` | ADMIN, CEUNP, MIEMBRO_MESA (solo su mesa) |
| POST | `/mesas/{id}/cerrar` | CEUNP, presidente en funciones |
| POST | `/mesas/{id}/ausentes` | CEUNP, presidente en funciones |
| POST | `/mesas/{id}/acta` `{cedulasNoUtilizadas, firmasListaFisica, observaciones, personeros:[idPersonero]}` | CEUNP, presidente en funciones |

## Base de datos (`10_cerrar_sufragio.sql`)
- `padron_electoral` + `no_voto` (marca NO VOTÓ, RF75).
- Tabla `cierre_mesa` (una fila por mesa): avance (`VOTACION_CERRADA`, `AUSENTES_MARCADOS`, `ACTA_EMITIDA`), hora de cierre, totales, cédulas, lista física, observaciones y acta.
- `sp_cerrar_votacion`, `sp_marcar_ausentes`, `sp_generar_acta_sufragio` y `sp_votar_habilitado` redefinido (A1).
- Triggers `trg_padron_no_voto_bu`, `trg_cierre_bu` y `trg_cierre_bd`.
- Parámetro `SUFRAGIO_CONTROL_HORARIO`.
- Bitácora: `CERRAR_SUFRAGIO`, `MARCAR_NO_VOTO` y `EMITIR_ACTA_SUFRAGIO`.

## Archivos
- Backend: `backend/src/main/java/pe/unp/elecciones/electoral/cierre/` (`CierreController`, `CerrarVotacion`, `MarcarAusentes`, `GenerarActaSufragio`, `CierreConsulta`, `CierreDto`)
- Frontend: `frontend/src/pages/cierre/` (`PantallaCierreSufragio.jsx`; `ActaSufragio.js`; `cierre.css`)

## Prueba rápida
1. Ejecutar `10_cerrar_sufragio.sql`. Tener una mesa INSTALADA (CUS08) con votos emitidos en el terminal (CUS09/CUS10). Antes de la hora de cierre, poner `SUFRAGIO_CONTROL_HORARIO = 0` o esperar a que voten todos.
2. Presidente: en «Cerrar sufragio», revisar los requisitos. Si un elector está votando, el cierre espera (A1).
3. Pulsar «Cerrar el sufragio» y confirmar. La mesa queda CERRADA, «Verificar elector» rechaza nuevos electores y el terminal muestra «Sufragio cerrado».
4. En el paso 2, revisar la lista y pulsar «Confirmar ausentes y marcar NO VOTÓ». Se puede imprimir la lista.
5. En el paso 3, indicar las cédulas no utilizadas. Para probar A2, ingresar un conteo de firmas distinto del sistema: la observación pasa a ser obligatoria. Marcar los personeros que firman y pulsar «Generar acta de sufragio».
6. Pulsar «Imprimir acta». El QR abre `/api/publico/actas/{token}`, que verifica la huella.
