# CUS01 · Gestionar convocatoria y cronograma

**Actor:** CEUNP · **Pantalla:** menú «Convocatoria y cronograma» · **Estado inicial → final:** (nuevo) → `CREADO` → `INSCRIPCION`

## Correspondencia con el diagrama de colaboración

| Mensaje del diagrama | Frontend (`PantallaConvocatoria`) | Backend |
|---|---|---|
| 1 `ingresarDatosProceso()` | `ConvocatoriaPage.ingresarDatosProceso` (paso 1) | `POST /api/convocatorias` |
| 2 `guardarProceso(datos)` | — | `RegistrarProceso.guardarProceso` |
| 3 `insertar(nombre, fechas, quorum)` | — | `RegistrarProceso.insertar` → `sp_crear_proceso` (entidad `ProcesoElectoral`) |
| 4 `mostrarConfirmacion()` | pasa al paso 2 con mensaje | `RegistrarProceso.mostrarConfirmacion` |
| 5 `ingresarCargo(nombre, nivel)` | `ConvocatoriaPage.ingresarCargo` (paso 2) | `POST /api/convocatorias/{id}/cargos` |
| 6 `guardarCargo(datos_cargo)` | — | `AgregarCargo.guardarCargo` |
| 7 `insertar(id_proceso, nombre, nivel)` | — | `AgregarCargo.insertar` → `sp_agregar_cargo` (entidad `CargoElectoral`) |
| 8 `actualizarListaCargos()` | refresca la lista de cargos | `AgregarCargo.actualizarListaCargos` |
| 9 `confirmarPublicacion()` | `ConvocatoriaPage.confirmarPublicacion` (paso 3 + modal) | `POST /api/convocatorias/{id}/publicar` |
| 10 `cambiarEstado(id_proceso, estado)` | — | `PublicarConvocatoria.cambiarEstado` |
| 11 `actualizarEstado(...)` | — | `PublicarConvocatoria.actualizarEstado` → `sp_cambiar_estado_proceso` |
| 12 `notificarPublicacion()` | banner «Convocatoria publicada» | `PublicarConvocatoria.notificarPublicacion` |

> **Nota sobre el diagrama:** el mensaje 11 dice `actualizarEstado('CREADO')`, pero el proceso ya nace en `CREADO` (mensaje 3). Publicar lo lleva a **`INSCRIPCION`**, que es lo que exige la máquina de estados de la BD (`CREADO > INSCRIPCION > VOTACION > CERRADO`). Se recomienda corregir la etiqueta a `actualizarEstado('INSCRIPCION')`.

## Archivos

- Backend: `backend/src/main/java/pe/unp/elecciones/electoral/convocatoria/`
  - `ConvocatoriaController` (endpoints), `RegistrarProceso`, `AgregarCargo`, `PublicarConvocatoria` (controles), `ConvocatoriaConsulta` (lecturas compartidas, requisitos y bitácora), `ConvocatoriaDto`.
  - `config/ValidacionHandler`: devuelve el mensaje de validación en `detail`.
  - `ProcedimientoDao.ejecutar(...)`: nuevo método para UPDATE/DELETE.
- Frontend: `frontend/src/pages/convocatoria/` (`ConvocatoriaPage.jsx`, `CronogramaTimeline.jsx`, `convocatoriaUtils.js`, `convocatoria.css`). Reemplaza a `CrearProcesoPage.jsx`.

## Endpoints (`hasAnyRole('ADMIN','CEUNP')`)

| Método | Ruta | Uso |
|---|---|---|
| GET | `/api/convocatorias` | Lista de convocatorias con nº de cargos |
| GET | `/api/convocatorias/catalogos` | `catalogo_cargo`, facultades, departamentos |
| GET | `/api/convocatorias/{id}` | Proceso + cargos + `editable` + `requisitos` para publicar |
| POST | `/api/convocatorias` | Registrar proceso con cronograma |
| PUT | `/api/convocatorias/{id}/cronograma` | Modificar cronograma (solo `CREADO`) |
| POST | `/api/convocatorias/{id}/cargos` | Agregar cargo `{nombre, nivel, idJurisdiccion, categoriasVotan[], categoriasPostulan[]}` |
| DELETE | `/api/convocatorias/{id}/cargos/{idCargo}` | Quitar cargo (solo `CREADO` y sin listas) |
| POST | `/api/convocatorias/{id}/publicar` | `CREADO → INSCRIPCION` |

## Reglas aplicadas

- **Cronograma:** convocatoria < cierre de inscripción < inicio del sufragio < fin; sufragio en una sola jornada y en fecha futura.
- **RN02:** entre la convocatoria y el día del sufragio debe haber de 30 a 45 días naturales.
- **RN06:** la pantalla propone 09:00–15:00 como horario del sufragio.
- **RN31:** quórum mínimo entre 0 y 100 % (por defecto 60).
- **RF03:** por cada cargo se registran las categorías que votan y las que pueden postular.
- **Exclusividad:** no se registra ni publica una convocatoria si ya hay otro proceso en `INSCRIPCION` o `VOTACION`.
- **Inmutabilidad:** después de publicar, el cronograma y los cargos quedan en solo lectura.
- **Bitácora:** `CREAR_PROCESO`, `ACTUALIZAR_CRONOGRAMA`, `AGREGAR_CARGO`, `QUITAR_CARGO`, `CAMBIO_ESTADO_PROCESO`, `PUBLICAR_CONVOCATORIA`.

## Prueba rápida

1. Ingresar como CEUNP → «Convocatoria y cronograma» → **Nueva**.
2. Escribir el nombre y pulsar **Sugerir fechas** (convocatoria hoy, cierre de inscripción a +20 días, sufragio a +40 días) → **Registrar proceso y continuar**.
3. Agregar «Rector» (Universidad) y «Decano» (elegir facultad).
4. **Continuar a publicar** → revisar la lista de requisitos → **Publicar convocatoria** → confirmar.
5. Verificar en la Bitácora (ADMIN) las acciones registradas.
