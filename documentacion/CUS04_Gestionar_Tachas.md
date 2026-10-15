# CUS04 · Gestionar tachas

**Actores:** Docente elector (presenta la tacha) y CEUNP (la resuelve) · **Pantalla:** «Presentar tacha» (DOCENTE), «Tachas» (CEUNP), «Tachas e Impugnaciones» (PERSONERO) · **Requiere:** candidatos inscritos (CUS03) y proceso en INSCRIPCION

## Correspondencia con el diagrama de colaboración

| Mensaje del diagrama | Frontend (`PantallaTachas`) | Backend |
|---|---|---|
| 1 `ingresarTacha(id_candidato, motivo)` | `TachasGestionPage.ingresarTacha` (formulario del docente) | `POST /api/gestion-tachas` |
| 2 `enviarTacha(datos)` | — | `RegistrarTacha.enviarTacha` |
| 3 `insertar(id_denunciante, id_candidato, motivo)` | — | `RegistrarTacha.insertar` → `sp_presentar_tacha` (`Tacha`) |
| 4 `confirmarRecepcion()` | mensaje con el N.º de tacha + «Mis tachas» | `RegistrarTacha.confirmarRecepcion` |
| 5 `registrarResolucion(id_tacha, estado)` | `TachasGestionPage.registrarResolucion` (bandeja del CEUNP) | `POST /api/gestion-tachas/{id}/resolucion` |
| 6 `guardarResolucion(datos)` | — | `ResolverTacha.guardarResolucion` |
| 7 `actualizarEstado(estado, fecha_res)` | — | `sp_resolver_tacha` (`Tacha`) |
| 8 `actualizarValidacion('EXCLUIDO')` | — | `sp_resolver_tacha`, solo si es FUNDADA (`Candidato`) |
| 9 `notificarFallo()` | mensaje al CEUNP y fallo visible en «Mis tachas» del docente | `ResolverTacha.notificarFallo` |

## Archivos

- Backend: `backend/src/main/java/pe/unp/elecciones/electoral/tachas/` (`TachasController`, `RegistrarTacha`, `ResolverTacha`, `TachasConsulta`, `TachasDto`).
- Frontend: `frontend/src/pages/tachas/` (`TachasGestionPage.jsx`, `tachas.css`). Reemplaza a `TachasPage.jsx`.
- `DashboardPage.jsx`: el docente tiene la opción «Presentar tacha»; CEUNP y personero usan la misma pantalla.

## Endpoints (usuarios autenticados; los de resolución solo `ADMIN`/`CEUNP`)

| Método | Ruta | Uso |
|---|---|---|
| GET | `/api/gestion-tachas/procesos` | Procesos, si admiten tachas y cuántas hay pendientes |
| GET | `/api/gestion-tachas/procesos/{id}/candidatos` | Candidatos que aún pueden ser tachados |
| GET | `/api/gestion-tachas/procesos/{id}/tachas` | Bandeja del CEUNP (todas las tachas del proceso) |
| GET | `/api/gestion-tachas/mias` | Tachas presentadas por el docente de la sesión, con su fallo |
| POST | `/api/gestion-tachas` | Presentar tacha `{idCandidato, motivo, dniDenunciante?}` |
| POST | `/api/gestion-tachas/{id}/resolucion` | Resolver `{estado: FUNDADA \| INFUNDADA, resolucion}` |

## Reglas aplicadas

- Solo en etapa de INSCRIPCION; el denunciante debe ser docente ACTIVO; nadie se tacha a sí mismo (`sp_presentar_tacha`).
- El docente tacha **a su nombre**: el denunciante se toma de su sesión, no del formulario. Solo el CEUNP puede registrar una tacha a nombre de otro docente (recibida en mesa de partes) indicando su DNI.
- La tacha y la resolución deben estar fundamentadas por escrito (mínimo 20 caracteres).
- No se tacha a un candidato ya excluido ni a uno cuya lista ya está TACHADA o EXCLUIDA; tampoco se repite una tacha pendiente del mismo docente contra el mismo candidato.
- **FUNDADA:** el candidato pasa a EXCLUIDO y la lista entera a TACHADA, fuera de la cédula (RN12). La pantalla pide confirmación porque no se puede revertir.
- **INFUNDADA:** el candidato continúa.
- Una tacha resuelta no se vuelve a resolver.
- **Bitácora:** `PRESENTAR_TACHA` y `RESOLVER_TACHA` (desde los SP).

## Prueba rápida

1. Con un proceso en INSCRIPCION y candidatos inscritos (CUS03), ingresar con un usuario DOCENTE asociado a un docente activo.
2. «Presentar tacha» → elegir un candidato → escribir el fundamento → «Enviar tacha».
3. Ingresar como CEUNP → «Tachas» → bandeja «Pendientes» → abrir la tacha → elegir Fundada o Infundada → fundamentar → «Registrar resolución».
4. Volver como docente: en «Mis tachas» aparece el fallo. En «Inscripción de listas» la lista aparece TACHADA si la tacha fue fundada.
