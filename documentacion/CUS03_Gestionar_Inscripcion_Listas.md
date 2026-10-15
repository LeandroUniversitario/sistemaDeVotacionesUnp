# CUS03 · Gestionar inscripción de listas

**Actor:** Lista / Candidato (la registra el CEUNP) · **Pantalla:** menú «Inscripción de listas» · **Requiere:** proceso en INSCRIPCION (CUS01) y padrón de docentes depurado (CUS02)

## Correspondencia con el diagrama de colaboración

| Mensaje del diagrama | Frontend (`PantallaInscripcion`) | Backend |
|---|---|---|
| 1 `ingresarDatosLista(nombre, cargo)` | `InscripcionPage.ingresarDatosLista` | `POST /api/inscripcion/listas` |
| 2 `guardarLista(datos)` | — | `RegistrarDatosLista.guardarLista` |
| 3 `insertarLista(nombre, cargo)` | — | `RegistrarDatosLista.insertarLista` → `sp_inscribir_lista` (`ListaElectoral`) |
| 4 `mostrarConfirmacionLista()` | abre la lista con su fórmula vacía | `RegistrarDatosLista.mostrarConfirmacionLista` |
| 5 `buscarCandidato(dni, rol)` | `InscripcionPage.buscarCandidato` (espacio «Vacante» de un rol) | `GET /api/inscripcion/listas/{id}/validar?dni=&rol=` |
| 6 `comprobarRequisitos(dni)` | — | `ValidarCandidato.comprobarRequisitos` |
| 7 `consultarDocente(dni)` | — | `ValidarCandidato.consultarDocente` (`docente`) |
| 8 `mostrarDatosCandidato(docente)` | ficha del docente + lista de requisitos (Apto / No apto) | `ValidarCandidato.mostrarDatosCandidato` |
| 9 `confirmarCandidato()` | botón «Confirmar candidato» | `POST /api/inscripcion/listas/{id}/candidatos` |
| 10 `grabarCandidato(id_docente, rol)` | — | `AgregarCandidato.grabarCandidato` (vuelve a validar) |
| 11 `insertar(id_lista, id_docente, rol)` | — | `AgregarCandidato.insertar` → `sp_inscribir_candidato` (`Candidato`) |
| 12 `actualizarVistaListas()` | refresca cargos, listas y fórmula | `AgregarCandidato.actualizarVistaListas` |

## Archivos

- Backend: `backend/src/main/java/pe/unp/elecciones/electoral/inscripcion/` (`InscripcionController`, `RegistrarDatosLista`, `ValidarCandidato`, `AgregarCandidato`, `InscripcionConsulta`, `RolesCargo`, `InscripcionDto`).
- Frontend: `frontend/src/pages/inscripcion/` (`InscripcionPage.jsx`, `inscripcion.css`). Reemplaza a `CandidaturasPage.jsx` y `CandidateTable.jsx`, que insertaban con JPA sin pasar por las reglas de la BD.

## Endpoints (`hasAnyRole('ADMIN','CEUNP')`)

| Método | Ruta | Uso |
|---|---|---|
| GET | `/api/inscripcion/procesos` | Procesos con convocatoria publicada y estado del plazo |
| GET | `/api/inscripcion/procesos/{id}` | Cargos → listas → candidatos, roles faltantes de cada fórmula |
| POST | `/api/inscripcion/listas` | Inscribir lista `{idCargo, nombre, simbolo, urlPlanGobierno}` |
| DELETE | `/api/inscripcion/listas/{id}` | Retirar lista (INSCRITA, dentro del plazo, sin tachas ni personeros) |
| GET | `/api/inscripcion/listas/{id}/validar?dni=&rol=` | Requisitos del docente para ese rol |
| POST | `/api/inscripcion/listas/{id}/candidatos` | Inscribir candidato `{idDocente, rol, urlHojaVida}` |
| DELETE | `/api/inscripcion/candidatos/{id}` | Quitar candidato (RN13: reemplazos dentro del plazo) |

## Reglas aplicadas

- **RN10 · Fórmula:** Rector = Rector + Vicerrector Académico + Vicerrector de Investigación. Decano, Jefe de Departamento, Director de Posgrado y Director de Escuela: un titular. Otros cargos: «Titular». (`RolesCargo`)
- **RN12 / RN13:** solo se inscribe o modifica con el proceso en INSCRIPCION, antes de la fecha límite y mientras la lista esté INSCRITA (sin calificar).
- **RN09:** docente ACTIVO y habilitado en el padrón de docentes. Grado (Doctor; Doctor o Maestro para Decano) y antigüedad en la categoría (5 años; 3 para Decano): si el dato no está registrado se muestra como **advertencia** para que el CEUNP lo verifique al calificar; si está registrado y no cumple, bloquea.
- **RF03:** la categoría del docente debe poder postular al cargo (configurado en CUS01).
- **Jurisdicción:** para cargos de facultad o departamento, el candidato debe pertenecer a ella.
- **RN11:** un docente no puede estar en dos listas del mismo proceso.
- **RN20 / RN21:** no puede ser miembro de mesa ni personero en el mismo proceso.
- **RN17:** el nombre y el símbolo de la lista no se repiten dentro del cargo.
- Las mismas reglas se aplican dos veces: en `ValidarCandidato` (para avisar en pantalla) y en `sp_inscribir_candidato` + `trg_candidato_bi` (en la BD).
- **Bitácora:** `INSCRIBIR_LISTA`, `INSCRIBIR_CANDIDATO` (desde los SP), `RETIRAR_LISTA`, `QUITAR_CANDIDATO`.

## Prueba rápida

1. Tener un proceso publicado (CUS01) con el cargo «Rector» y el padrón de docentes depurado (CUS02).
2. «Inscripción de listas» → «Inscribir lista» → cargo Rector, nombre y símbolo.
3. En el espacio «Rector» → «Buscar candidato» → DNI de un docente PRINCIPAL → revisar los requisitos → «Confirmar candidato».
4. Probar un DNI de otra categoría o uno ya inscrito en otra lista: aparece «No apto» con el motivo.
5. Completar los tres roles: la lista muestra «Fórmula completa».
