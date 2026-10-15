# CUS06 · Realizar sorteos

**Actor:** CEUNP · **Pantalla:** menú «Sorteos» · **Requiere:** padrón definitivo aprobado (CUS02); para la cédula, listas ADMITIDAS

## Correspondencia con el diagrama de colaboración (sorteo de miembros de mesa)

| Mensaje del diagrama | Frontend (`PantallaSorteoMesa`) | Backend |
|---|---|---|
| 1 `solicitarSorteo(id_proceso)` | `SorteoMesaPage.solicitarSorteo` (al elegir el proceso) | `GET /api/sorteo-mesas/procesos/{id}/elegibles` |
| 2 `obtenerUniverso()` | — | `FiltrarElegibles.obtenerUniverso` |
| 3 `consultarHabilitados()` | — | `FiltrarElegibles.consultarHabilitados` (padrón habilitado, `docente`) |
| 4 `excluirImpedidos()` | — | `FiltrarElegibles.excluirImpedidos` (`CargoExcluidoSorteo`, candidatos, personeros) |
| 5 `mostrarElegibles()` | habilitados / impedidos con motivo / elegibles por mesa | `FiltrarElegibles.mostrarElegibles` |
| 6 `ingresarSemilla(semilla)` | campo «Semilla del sorteo» (o «Generar aleatoria») | `POST …/vista-previa` y `POST …/sortear` `{semilla}` |
| 7 `generarAleatoriedad(semilla)` | — | `EjecutarSorteo.generarAleatoriedad` |
| `seleccionarSeisMiembros()` | vista previa por mesa | `EjecutarSorteo.seleccionarSeisMiembros` |
| 8 `guardarResultados(lista_sorteados)` | «Realizar sorteo» (con confirmación) | `GrabarMiembrosMesa.guardarResultados` |
| 9 `actualizarSemilla(semilla)` | — | `sp_sortear_todas_las_mesas` → `mesa_electoral.semilla_sorteo` |
| 10 `insertar(id_docente, rol, titular)` | — | `sp_sortear_todas_las_mesas` → `miembro_mesa` |
| 11 `registrarAuditoria(accion)` | — | `sp_sortear_todas_las_mesas` → `log_auditoria` (SORTEO_MESA, SORTEO_GENERAL_MESAS) |
| 12 `confirmarAsignacion()` | miembros por mesa + «Resultado verificado» | `GrabarMiembrosMesa.confirmarAsignacion` |

## Algoritmo (RNF01: auditable y reproducible)

1. Semilla de cada mesa = SHA-256(semilla base | número de mesa).
2. Los elegibles de la mesa se ordenan por SHA-256(semilla de la mesa | DNI).
3. Los 6 primeros: 1 Presidente, 2 Secretario, 3 Vocal (titulares) y 4–6 Suplentes (RN19).

`EjecutarSorteo` calcula ese orden en Java (vista previa) y `sp_sortear_miembros_mesa` lo hace en la BD al grabar. Después de grabar, `GrabarMiembrosMesa` compara uno a uno lo grabado con lo calculado: si coinciden, la pantalla muestra «Resultado verificado». Con la misma semilla cualquiera puede repetir el cálculo.

## Archivos

- Backend: `backend/src/main/java/pe/unp/elecciones/electoral/sorteo/` (`SorteoMesaController`, `FiltrarElegibles`, `EjecutarSorteo`, `GrabarMiembrosMesa`, `PreparacionSorteo`, `SorteoConsulta`, `SorteoDto`).
- Frontend: `frontend/src/pages/sorteo/` (`SorteoMesaPage.jsx`, `sorteo.css`). Reemplaza a `SorteosPage.jsx`.
- El `SorteoController`/`SorteoService` anterior (`/api/sorteos`) se mantiene, pero la pantalla ya no lo usa: regeneraba el padrón, que ahora pertenece a CUS02.

## Endpoints (`hasAnyRole('ADMIN','CEUNP')`)

| Método | Ruta | Uso |
|---|---|---|
| GET | `/api/sorteo-mesas/procesos` | Procesos |
| GET | `/api/sorteo-mesas/procesos/{id}` | Proceso, parámetros, mesas, miembros y cédula |
| POST | `/api/sorteo-mesas/procesos/{id}/mesas` | Conformar mesas `{electoresPorMesa, ubicacion}` (`sp_crear_mesas`) |
| GET | `/api/sorteo-mesas/procesos/{id}/elegibles` | Universo de elegibles e impedidos |
| POST | `/api/sorteo-mesas/procesos/{id}/vista-previa` | Calcula el sorteo sin grabar `{semilla}` |
| POST | `/api/sorteo-mesas/procesos/{id}/sortear` | Sortea y graba todas las mesas pendientes `{semilla}` |
| POST | `/api/sorteo-mesas/cargos/{id}/orden-cedula` | RN18: sortea el orden de las listas ADMITIDAS `{semilla}` |

## Reglas aplicadas

- Los sorteos se hacen con el proceso en CREADO o INSCRIPCION (antes de la votación).
- **RN20:** no entran al sorteo autoridades vigentes (cargos marcados en «Excepciones de sorteo»), candidatos ni personeros del proceso.
- **RN19:** 3 titulares y 3 suplentes por mesa. Cada mesa necesita al menos 6 elegibles (si no, no se sortea). Una mesa sorteada no se vuelve a sortear (cargo irrenunciable).
- Cada miembro sale de los electores asignados a su propia mesa.
- **RN18:** el orden de la cédula se sortea por cargo solo entre listas ADMITIDAS; puede repetirse mientras no empiece la votación (la semilla queda en la bitácora).
- **RN08:** la ubicación de las mesas se toma del parámetro `UBICACION_SUFRAGIO` si no se indica otra.

## Prueba rápida

1. Con el padrón aprobado (CUS02), ir a «Sorteos» → «Conformar mesas».
2. Revisar el universo de elegibles y los impedidos con su motivo.
3. Escribir una semilla (por ejemplo `LOTERIA-2026-10-15-48213`) → «Vista previa» → «Realizar sorteo».
4. Verificar que la pantalla muestre «Resultado verificado» y los mismos miembros que la vista previa.
5. Pestaña «Orden en la cédula» → «Sortear orden» en cada cargo con listas admitidas.
