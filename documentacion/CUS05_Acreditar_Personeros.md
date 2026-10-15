# CUS05 · Acreditar personeros

**Actor:** CEUNP · **Pantalla:** menú «Personeros» · **Requiere:** listas inscritas (CUS03); para personeros de mesa, mesas creadas (CUS06)

## Correspondencia con el diagrama de colaboración

| Mensaje del diagrama | Frontend (`PantallaPersoneros`) | Backend |
|---|---|---|
| 1 `solicitarAcreditacion(id_lista, dni)` | `PersonerosPage.solicitarAcreditacion` | `GET /api/personeros/listas/{id}/validar?dni=` |
| 2 `verificarRequisitos(dni)` | — | `ValidarPersonero.verificarRequisitos` |
| 3 `consultarDocente(dni)` | — | `ValidarPersonero.consultarDocente` (`docente`) |
| 4 `mostrarDatosPersonero(docente)` | ficha del docente + requisitos + cupos libres | `ValidarPersonero.mostrarDatosPersonero` |
| 5 `confirmarAcreditacion(tipo, id_mesa)` | elegir tipo (y mesa) → «Confirmar acreditación» | `POST /api/personeros/listas/{id}` |
| 6 `guardarAcreditacion(datos)` | — | `AcreditarPersonero.guardarAcreditacion` |
| 7 `insertar(id_lista, id_docente, tipo, estado)` | — | `AcreditarPersonero.insertar` (`Personero`, estado ACREDITADO) |
| 8 `notificarExito()` | mensaje + tabla de personeros actualizada | `AcreditarPersonero.notificarExito` |

## Archivos

- Backend: `backend/src/main/java/pe/unp/elecciones/electoral/personeros/` (`PersonerosController`, `ValidarPersonero`, `AcreditarPersonero`, `PersonerosConsulta`, `PersonerosDto`).
- Frontend: `frontend/src/pages/personeros/` (`PersonerosPage.jsx`, `personeros.css`). Reemplaza el texto de relleno que había en la sección «Personeros» del dashboard.

## Endpoints (`hasAnyRole('ADMIN','CEUNP')`)

| Método | Ruta | Uso |
|---|---|---|
| GET | `/api/personeros/procesos` | Procesos y si admiten acreditación |
| GET | `/api/personeros/procesos/{id}` | Mesas y listas del proceso con sus personeros |
| GET | `/api/personeros/listas/{id}/validar?dni=` | Requisitos del docente y cupos libres de la lista |
| POST | `/api/personeros/listas/{id}` | Acreditar `{idDocente, tipo: GENERAL \| ALTERNO \| MESA, idMesa?}` |
| POST | `/api/personeros/{id}/revocar` | Revocar `{motivo}` |

## Reglas aplicadas

- Se acredita con el proceso en INSCRIPCION o VOTACION y solo para listas INSCRITAS o ADMITIDAS (no TACHADAS ni EXCLUIDAS).
- Docente en estado ACTIVO.
- **RN21:** no puede ser candidato del proceso ni autoridad vigente (`cargo_admin` + `cargo_excluido_sorteo`). También lo valida `trg_personero_bi`.
- **RN20:** no puede ser miembro de mesa del proceso.
- Un docente representa a una sola lista en el proceso.
- **Cupos por lista:** un GENERAL, un ALTERNO y uno de MESA por cada mesa pendiente o instalada.
- El personero de MESA debe tener mesa y la mesa debe ser del mismo proceso (también lo valida el trigger).
- **Revocación:** queda el registro como REVOCADO, con el motivo en la bitácora; libera el cupo. Si después se vuelve a acreditar al mismo docente en la misma lista, se reactiva su registro.
- La credencial QR del personero (RF51) se genera en CUS07; al revocar se anula la que tuviera.
- **Bitácora:** `ACREDITAR_PERSONERO`, `REVOCAR_PERSONERO`.
- La cuenta de usuario con rol PERSONERO se crea aparte (CUS18 · Administrar usuarios).

## Prueba rápida

1. Con una lista inscrita (CUS03), ir a «Personeros» y elegir la lista.
2. Ingresar el DNI de un candidato → «No apto» por RN21.
3. Ingresar el DNI de otro docente → «Apto» → elegir «Personero general» → «Confirmar acreditación».
4. Con mesas creadas, acreditar un personero de mesa eligiendo la mesa.
5. Revocar una acreditación con su motivo y verificar que el cupo vuelve a quedar libre.
