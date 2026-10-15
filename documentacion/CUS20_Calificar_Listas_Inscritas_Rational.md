# CUS20 · Calificar listas inscritas
*(en el diagrama de casos de uso general figura como «Validar candidaturas y listas»)*

Guía para dibujarlo a mano en **Rational Rose**: ficha del caso de uso, relaciones, clases de análisis, diagrama de colaboración y diagrama de secuencia. Los nombres de clases y mensajes siguen la misma convención de tus diagramas CUS01–CUS06.

> **Numeración:** propongo **CUS20** para no mover la numeración CUS01–CUS19. Por el flujo del proceso va entre CUS04 (Gestionar tachas) y CUS06 (Realizar sorteos); si prefieres, renómbralo **CUS04.1**.

---

## 1. Ficha del caso de uso

| Campo | Contenido |
|---|---|
| **Nombre** | Calificar listas inscritas |
| **Actor principal** | CEUNP |
| **Propósito** | Revisar el expediente de cada lista inscrita y declararla **ADMITIDA** o **EXCLUIDA**. Solo las listas admitidas entran a la cédula de votación. |
| **Precondiciones** | 1. Proceso en estado INSCRIPCION (CUS01). 2. Listas en estado INSCRITA con sus candidatos (CUS03). 3. Para admitir: sin tachas PENDIENTES contra sus candidatos (CUS04). |
| **Postcondiciones (admitir)** | Lista en estado ADMITIDA; sus candidatos PENDIENTES u OBSERVADOS pasan a APROBADO; la acción queda en la bitácora. |
| **Postcondiciones (excluir)** | Lista en estado EXCLUIDA con su motivo; todos sus candidatos pasan a EXCLUIDO; sale de la cédula; la acción queda en la bitácora. |
| **Reglas de negocio** | RN09 (requisitos de los candidatos, verificados por el CEUNP), RN10 (fórmula completa), RN12 (calificación de la fórmula completa en bloque), RN13 (después de la calificación la lista no admite cambios). |

### Flujo básico
1. El CEUNP selecciona el proceso electoral.
2. El sistema muestra las listas INSCRITAS de cada cargo con su expediente: candidatos y su rol, si la fórmula está completa (RN10), datos de RN09 (categoría, grado académico) y tachas pendientes o resueltas.
3. El CEUNP elige una lista y registra su decisión: **Admitir**.
4. El sistema verifica los requisitos: la lista sigue INSCRITA, el proceso está en INSCRIPCION, la fórmula está completa (RN10) y no hay tachas PENDIENTES.
5. El sistema aprueba a los candidatos, cambia la lista a ADMITIDA y registra la acción en la bitácora.
6. El sistema notifica el resultado y actualiza la vista de listas.

### Flujos alternos
- **A1 · Excluir la lista** (en el paso 3): el CEUNP elige **Excluir** e ingresa el motivo (obligatorio). El sistema excluye a todos los candidatos, cambia la lista a EXCLUIDA con el motivo y sigue en el paso 6.
- **A2 · Fórmula incompleta** (en el paso 4): el sistema rechaza la admisión e informa los roles que faltan (RN10). La lista sigue INSCRITA.
- **A3 · Tachas pendientes** (en el paso 4): el sistema rechaza la admisión e indica que primero deben resolverse en CUS04. La lista sigue INSCRITA.
- **A4 · Lista ya calificada o proceso fuera de INSCRIPCION** (en el paso 4): el sistema informa que la lista ya no puede calificarse.

---

## 2. Relaciones en el diagrama de casos de uso

| Elemento | Relación | Elemento | Nota para Rose |
|---|---|---|---|
| CEUNP (actor) | Asociación | Calificar listas inscritas | Línea simple actor–caso de uso |
| Excluir lista | `<<extend>>` → | Calificar listas inscritas | Punto de extensión: «decisión = excluir». Flecha punteada desde *Excluir lista* hacia *Calificar listas inscritas* |
| Calificar listas inscritas | `<<include>>` → | Verificar requisitos de la lista | Siempre se verifica RN10 y que no haya tachas pendientes. Flecha punteada hacia *Verificar requisitos de la lista* |
| Personero General (actor) | Asociación (secundario) | Calificar listas inscritas | Opcional: ya figura así en tu diagrama general (recibe la notificación de la calificación) |

**Dependencias entre casos de uso** (precedencia del proceso; en Rose pueden ir como nota o como dependencia `<<precede>>`):
- *Gestionar inscripción de listas (CUS03)* precede a *Calificar listas inscritas*.
- *Gestionar tachas (CUS04)* precede a *Calificar listas inscritas* (las tachas deben estar resueltas).
- *Calificar listas inscritas* precede a *Realizar sorteos (CUS06)* (el orden de la cédula se sortea entre listas ADMITIDAS).

---

## 3. Clases de análisis

| Clase | Estereotipo | Responsabilidades (operaciones) |
|---|---|---|
| CEUNP | actor | — |
| PantallaCalificacion | boundary | `seleccionarProceso()`, `registrarCalificacion()`, `mostrarExpediente()`, `notificarCalificacion()` |
| RevisarExpediente | control | `obtenerListasInscritas(id_proceso)`, `mostrarExpediente(listas)` |
| CalificarLista | control | `calificarLista(id_lista, decision, motivo)`, `verificarRequisitos(id_lista)`, `notificarCalificacion()` |
| ListaElectoral | entity | `consultarListas(id_proceso, estado)`, `actualizarEstado(id_lista, estado, motivo)` |
| Candidato | entity | `consultarCandidatos(id_lista)`, `actualizarValidacion(id_lista, estado)` |
| Tacha | entity | `consultarTachasPendientes(id_lista)` |
| LogAuditoria | entity | `registrarAuditoria(accion)` |

---

## 4. Diagrama de colaboración

### 4.1 Objetos (instancias) a colocar
`: CEUNP` · `: PantallaCalificacion` · `: RevisarExpediente` · `: CalificarLista` · `: ListaElectoral` · `: Candidato` · `: Tacha` · `: LogAuditoria`

### 4.2 Enlaces (links) entre objetos
1. CEUNP — PantallaCalificacion
2. PantallaCalificacion — RevisarExpediente
3. RevisarExpediente — ListaElectoral
4. RevisarExpediente — Candidato
5. RevisarExpediente — Tacha
6. PantallaCalificacion — CalificarLista
7. CalificarLista — Candidato
8. CalificarLista — ListaElectoral
9. CalificarLista — Tacha
10. CalificarLista — LogAuditoria

### 4.3 Mensajes (en orden)

| N.º | Mensaje | Emisor → Receptor |
|---|---|---|
| 1 | `seleccionarProceso(id_proceso)` | CEUNP → PantallaCalificacion |
| 2 | `obtenerListasInscritas(id_proceso)` | PantallaCalificacion → RevisarExpediente |
| 3 | `consultarListas(id_proceso, 'INSCRITA')` | RevisarExpediente → ListaElectoral |
| 4 | `consultarCandidatos(id_lista)` | RevisarExpediente → Candidato |
| 5 | `consultarTachasPendientes(id_lista)` | RevisarExpediente → Tacha |
| 6 | `mostrarExpediente(listas)` | RevisarExpediente → PantallaCalificacion |
| 7 | `registrarCalificacion(id_lista, decision, motivo)` | CEUNP → PantallaCalificacion |
| 8 | `calificarLista(id_lista, decision, motivo)` | PantallaCalificacion → CalificarLista |
| 9 | `verificarRequisitos(id_lista)` | CalificarLista → Tacha |
| 10 | `actualizarValidacion(id_lista, estado)` | CalificarLista → Candidato |
| 11 | `actualizarEstado(id_lista, estado, motivo)` | CalificarLista → ListaElectoral |
| 12 | `registrarAuditoria(accion)` | CalificarLista → LogAuditoria |
| 13 | `notificarCalificacion()` | CalificarLista → PantallaCalificacion |

**Notas para los mensajes:**
- Mensaje 9: verifica RN10 (fórmula completa) y que no haya tachas PENDIENTES. Si quieres mostrar las dos verificaciones, añade antes un mensaje reflexivo `verificarFormula(id_lista)` en CalificarLista (como `seleccionarSeisMiembros()` en tu CUS06).
- Mensaje 10: `estado` = APROBADO si se admite, EXCLUIDO si se excluye.
- Mensaje 11: `estado` = ADMITIDA o EXCLUIDA; `motivo` solo al excluir.

### 4.4 Esquema de ubicación sugerido (como en tus diagramas)

```
                       2: obtenerListasInscritas() ─▶  (RevisarExpediente) ── 3: consultarListas() ─▶ (ListaElectoral)
                       ◀─ 6: mostrarExpediente()            │  └─ 4: consultarCandidatos() ─▶ (Candidato)
 (CEUNP) ─1,7─▶ |(PantallaCalificacion)                     └──── 5: consultarTachasPendientes() ─▶ (Tacha)
                       8: calificarLista() ─▶  (CalificarLista) ── 9: verificarRequisitos() ─▶ (Tacha)
                       ◀─ 13: notificarCalificacion()       ├── 10: actualizarValidacion() ─▶ (Candidato)
                                                            ├── 11: actualizarEstado() ─▶ (ListaElectoral)
                                                            └── 12: registrarAuditoria() ─▶ (LogAuditoria)
```

---

## 5. Diagrama de secuencia

**Orden de las líneas de vida (de izquierda a derecha):**
`: CEUNP` · `: PantallaCalificacion` · `: RevisarExpediente` · `: CalificarLista` · `: ListaElectoral` · `: Candidato` · `: Tacha` · `: LogAuditoria`

| Paso | Desde | Hacia | Mensaje |
|---|---|---|---|
| 1 | CEUNP | PantallaCalificacion | seleccionarProceso(id_proceso) |
| 2 | PantallaCalificacion | RevisarExpediente | obtenerListasInscritas(id_proceso) |
| 3 | RevisarExpediente | ListaElectoral | consultarListas(id_proceso, 'INSCRITA') |
| 4 | RevisarExpediente | Candidato | consultarCandidatos(id_lista) |
| 5 | RevisarExpediente | Tacha | consultarTachasPendientes(id_lista) |
| 6 | RevisarExpediente | PantallaCalificacion | mostrarExpediente(listas) |
| 7 | CEUNP | PantallaCalificacion | registrarCalificacion(id_lista, decision, motivo) |
| 8 | PantallaCalificacion | CalificarLista | calificarLista(id_lista, decision, motivo) |
| 9 | CalificarLista | Tacha | verificarRequisitos(id_lista) |
| 10 | CalificarLista | Candidato | actualizarValidacion(id_lista, estado) |
| 11 | CalificarLista | ListaElectoral | actualizarEstado(id_lista, estado, motivo) |
| 12 | CalificarLista | LogAuditoria | registrarAuditoria(accion) |
| 13 | CalificarLista | PantallaCalificacion | notificarCalificacion() |

**Tip en Rose:** dibuja primero el diagrama de secuencia (Browse → Create → Sequence Diagram) y luego pulsa **F5** (Create Collaboration Diagram). Rose genera el de colaboración con los mismos objetos y mensajes numerados; solo te queda acomodar los objetos.

---

## 6. Correspondencia con la base de datos (para la implementación)

| Mensaje | Implementación prevista |
|---|---|
| 3, 4, 5 | Consultas a `lista_electoral` (estado INSCRITA), `candidato` + `docente`, `tacha` (estado PENDIENTE) |
| 9 | Fórmula completa según `RolesCargo` (RN10) y `COUNT(*)` de tachas PENDIENTES |
| 10, 11, 12 | `sp_validar_lista(id_lista, admitir, motivo, id_usuario)`: aprueba o excluye candidatos, cambia el estado de la lista y registra `VALIDAR_LISTA` en `log_auditoria` |

Referencia en PlantUML: `diagramas/colaboracion_calificar_listas.puml` y `diagramas/secuencia_calificar_listas.puml`.
