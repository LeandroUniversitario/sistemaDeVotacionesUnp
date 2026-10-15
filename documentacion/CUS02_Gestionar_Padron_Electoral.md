# CUS02 · Gestionar padrón electoral

**Actor:** CEUNP · **Pantalla:** menú «Padrón electoral» · **Resultado:** filas en `padron_electoral` para el proceso (RN04)

## Correspondencia con el diagrama de colaboración

| Mensaje del diagrama | Frontend (`PantallaPadron`) | Backend |
|---|---|---|
| 1 `subirArchivo(archivo)` | `PadronPage.subirArchivoPadron` (paso 1) | `POST /api/padron/importar` (multipart `archivo`) |
| 2 `leerDatos()` | — | `ImportarDocentes.leerDatos` → `ImportacionDocenteService.importarExcel/Csv` |
| 3 `registrarMasivo(datos)` | — | `ImportacionDocenteService.registrarMasivo` (UPSERT por DNI en `docente`) |
| 4 `mostrarImportados()` | resultado: nuevos / actualizados / filas con error | `ImportarDocentes.mostrarImportados` |
| 5 `depurarPadron()` | `PadronPage.depurarPadron` (paso 2) | `POST /api/padron/depurar` |
| 6 `procesarReglas()` | — | `FiltrarHabilitados.procesarReglas` |
| 7 `actualizarHabilitacion(estado)` | — | `FiltrarHabilitados.actualizarHabilitacion` (`docente.habilitado_para_votar`) |
| 8 `mostrarListaDepurada()` | tabla Habilitados / Inhabilitados con motivo | `FiltrarHabilitados.mostrarListaDepurada` |
| 9 `confirmarAprobacion(id_proceso)` | `PadronPage.confirmarAprobacion` (paso 3 + modal) | `POST /api/padron/procesos/{id}/aprobar` |
| 10 `generarDefinitivo(id_proceso)` | — | `AprobarPadron.generarDefinitivo` |
| 11 `insertar(id_proceso, id_docente)` | — | `AprobarPadron.insertar` → `sp_generar_padron` (`PadronElectoral`) |
| 12 `notificarExito()` | mensaje + padrón definitivo con búsqueda y exportación CSV | `AprobarPadron.notificarExito` |

## Archivos

- Backend: `backend/src/main/java/pe/unp/elecciones/electoral/padron/` (`PadronController`, `ImportarDocentes`, `FiltrarHabilitados`, `AprobarPadron`, `PadronConsulta`).
- `electoral/service/Bitacora.java`: registro en `log_auditoria` compartido por CUS01 y CUS02.
- Frontend: `frontend/src/pages/padron/` (`PadronPage.jsx`, `padron.css`). Reutiliza estilos de `convocatoria.css`.
- `DocentesPage.jsx`: se quitó la «aprobación» simulada (guardada en `localStorage`); ahora enlaza a esta pantalla.

## Endpoints (`hasAnyRole('ADMIN','CEUNP')`)

| Método | Ruta | Uso |
|---|---|---|
| GET | `/api/padron/resumen` | Totales de docentes, última importación y depuración |
| POST | `/api/padron/importar` | Importar Excel (.xlsx) o CSV |
| GET | `/api/padron/depurado` | Lista depurada sin volver a ejecutar las reglas |
| POST | `/api/padron/depurar` | Ejecutar reglas y actualizar habilitación |
| GET | `/api/padron/procesos` | Procesos con su estado de padrón |
| GET | `/api/padron/procesos/{id}` | Electores previstos / en padrón por cargo y requisitos |
| GET | `/api/padron/procesos/{id}/electores` | Padrón definitivo (`v_padron_detalle`) |
| POST | `/api/padron/procesos/{id}/aprobar` | Generar (o regenerar) el padrón definitivo |

## Reglas aplicadas

- **Depuración (`PadronConsulta.MOTIVO_SQL`):** RN03 solo votan docentes en estado ACTIVO; RN05 DNI de 8 dígitos; nombres, apellidos y dedicación completos. Quien no cumple queda con `habilitado_para_votar = 0` y se muestra el motivo.
- **Importación:** la facultad y el departamento deben existir (no se crean automáticamente).
- **Aprobación:** proceso en CREADO o INSCRIPCION, con cargos, depuración posterior a la última importación, sin mesas creadas y con al menos un elector por cargo.
- **Padrón por cargo (RF03):** cada cargo recibe a los docentes habilitados de su jurisdicción cuya categoría puede votar.
- **Regeneración:** permitida hasta que se crean las mesas (lo controla `sp_generar_padron`).
- **Bitácora:** `IMPORTAR_DOCENTES`, `DEPURAR_PADRON`, `GENERAR_PADRON`.

## Prueba rápida

1. CEUNP → «Padrón electoral» → subir `base-de-datos/100 Docentes.xlsx` (o «Omitir» si ya están cargados).
2. «Depurar padrón» → revisar la pestaña Inhabilitados.
3. «Continuar a aprobar» → elegir el proceso creado en CUS01 → «Aprobar padrón definitivo».
4. Revisar el padrón, filtrar por cargo y exportar CSV.
