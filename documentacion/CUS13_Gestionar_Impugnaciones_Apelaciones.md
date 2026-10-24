# CUS13 · Gestionar impugnaciones y apelaciones

**Actores:** Personero de mesa (impugna y apela), Presidente de mesa (registra la decisión de la mesa) y CEUNP (falla la apelación); ADMIN solo consulta · **Pantalla:** menú «Impugnaciones» (MIEMBRO_MESA), «Impugnar votos y apelar» (PERSONERO) e «Impugnaciones y apelaciones» (CEUNP y ADMIN)
**Caso de negocio:** CUN10 Resolver impugnaciones y nulidades (pasos 1 a 4; la nulidad es del CUS15) · **Módulo:** M11 (RF80 y RF81) · **Reglas:** RN23, RN24, RN36 · **Fuente:** tabla 21 y tablas 38 y 99 del informe v2.1
**Requiere:** sufragio cerrado (CUS11) y escrutinio de la mesa en curso (CUS12: cédulas contadas). El registro de la impugnación lo hace `sp_registrar_impugnacion`, que crea el CUS12.
**Instalación:** en una base ya creada, ejecutar `base-de-datos/12_impugnaciones_apelaciones.sql` después de `11_escrutinio_conciliacion.sql`. `00_script_unico_elecciones_unp.sql` (sección 5c) y `01_crear_base_de_datos.sql` (al final) ya lo incluyen y `02_limpiar_datos_electorales.sql` ya vacía `impugnacion_electoral`.

## Correspondencia con el diagrama de colaboración («Colaboration - Gestionar impugnaciones y apelaciones», `diagramas/Sistema De Elecciones.mdl`)

| Mensaje del diagrama | Frontend | Backend |
|---|---|---|
| 1 `ingresarImpugnacion(id_mesa, motivo)` | `PantallaImpugnaciones`: «Registrar impugnación» → personero, cargo y motivo → «Confirmar registro» | `POST /api/impugnaciones/mesas/{id}/impugnaciones` |
| 2 `registrarImpugnacion(datos)` | — | `RegistrarImpugnacion.registrarImpugnacion` |
| 3 `verificarAcreditacion(id_personero)` | — | `RegistrarImpugnacion.verificarAcreditacion`: personero acreditado y presente en la mesa (RN24) |
| 4 `insertar(id_personero, id_mesa, motivo)` | — | `sp_registrar_impugnacion` (CUS12) → `impugnacion_electoral` (PRESENTADA) |
| 5 `confirmarRegistro()` | Mensaje con el N.º y la fila nueva en la tabla (Por resolver en mesa) | La respuesta trae `idImpugnacion` y el detalle |
| 6 `registrarDecisionMesa(id_impugnacion, decision)` | Expediente → «Registrar decisión de la mesa»: fundada o infundada, votación de los miembros, opción de la cédula y fundamento → «Confirmar decisión» | `POST /api/impugnaciones/{id}/decision-mesa` |
| 7 `resolverEnMesa(datos)` | — | `ResolverImpugnacion.resolverEnMesa` → `sp_resolver_impugnacion_mesa` |
| 8 `actualizarDecisionMesa(decision)` | — | `decision_mesa`, `votos_mesa_*`, `opcion_mesa`, `estado = RESUELTA` |
| 9 `notificarDecision()` | Mensaje, tabla y expediente del personero (situación «Plazo de apelación» o «Firme») | La respuesta trae la impugnación y el detalle |
| 10 `[decision rechazada] apelarDecision(id_impugnacion)` | «Apelar ante el CEUNP» (solo si es infundada y dentro del plazo) → fundamento → «Confirmar apelación» | `POST /api/impugnaciones/{id}/apelacion` → `TramitarApelacion.apelarDecision` → `sp_apelar_impugnacion` |
| 11 `registrarFalloCEUNP(id_impugnacion, decision)` | Bandeja del CEUNP → «Tramitar» → «Registrar fallo del CEUNP»: confirmar o modificar, N.º de resolución, Pleno, votos, dirimente y opción final → «Confirmar fallo» | `POST /api/impugnaciones/{id}/fallo` |
| 12 `resolverApelacion(id_impugnacion, decision)` | — | `TramitarApelacion.resolverApelacion` → `sp_resolver_apelacion` |
| 13 `actualizarDecisionCEUNP(decision, 'RESUELTA')` | — | `decision_ceunp`, resolución, votación del Pleno, `opcion_final`, `estado = RESUELTA` |
| 14 `notificarFalloFinal()` | Mensaje, expediente con el fallo e «Imprimir constancia» (`ConstanciaImpugnacion.imprimirConstanciaImpugnacion`) | La respuesta trae la impugnación fallada |

### Cambios que conviene hacer en el diagrama
- El mensaje 6 debe llevar la votación de los miembros, que exige RN23: `registrarDecisionMesa(id_impugnacion, decision, votos_favor, votos_contra, opcion)`.
- El mensaje 10 no llega a ningún control en el modelo. Debe ir de `PantallaImpugnaciones` a `TramitarApelacion` con un mensaje `elevarApelacion(id_impugnacion, fundamento)`.
- El mensaje 11 debe incluir los datos del Pleno que exige RN36: `registrarFalloCEUNP(id_impugnacion, decision, n_resolucion, miembros, votos, dirimente)`.
- Falta el mensaje que asigna la cédula a una opción (lista, blanco o nulo). Sin él, el CUS14 no puede computar el voto impugnado. Se resolvió con `opcion_mesa` y `opcion_final` y la vista `v_impugnacion_efecto`.

## Flujo
1. En el escrutinio (CUS12, paso 4), un personero presente en la mesa impugna una cédula. La registra el propio personero o, a su pedido, un miembro de la mesa. La cédula se cuenta como IMPUGNADA (CUS12 A4).
2. Los tres miembros en funciones votan. El presidente registra la decisión por mayoría simple: **fundada** (ACEPTADA) o **infundada** (RECHAZADA), y a qué opción va la cédula (una lista admitida del cargo, en blanco o nulo).
3. Si la mesa la declara infundada, un personero de la misma lista puede apelar dentro del plazo (`IMPUGNACION_PLAZO_APELACION_HORAS`, 24 h). Si es fundada o vence el plazo, la decisión queda firme.
4. El CEUNP resuelve la apelación en Pleno. **Confirma** la decisión de la mesa o la **modifica** y fija la opción final. El fallo es inapelable.

## Reglas
- **RN24:** impugna un personero acreditado y presente en la mesa (registró su llegada en la instalación, CUS08), mientras el escrutinio está en curso (antes del acta de escrutinio). Un personero impugna solo en su nombre.
- **RN23 · mesa:** votan los miembros en funciones (titulares, suplentes o reemplazantes). Los votos deben sumar los miembros en funciones, no puede haber empate y la decisión debe coincidir con la mayoría. Registra la decisión el presidente en funciones (si es un reemplazante sin cuenta, cualquier miembro presente). El fundamento es obligatorio.
- **RF81 · apelación:** solo se apela una decisión RECHAZADA, una sola vez, dentro del plazo. Apela un personero acreditado de la lista que impugnó, o el presidente la eleva a su pedido.
- **RN36 · CEUNP:** el Pleno resuelve con quórum (`CEUNP_QUORUM_PLENO`, 5). Los votos deben sumar los miembros presentes. En empate decide el voto dirimente del Presidente. CONFIRMADA exige mayoría en contra de la apelación y MODIFICADA mayoría a favor, con una opción final distinta de la que fijó la mesa. El número de resolución no se repite.
- **Inmutabilidad:** `trg_impugnacion_bu` impide cambiar los datos de origen, la decisión de la mesa fuera de la apelación, una apelación ya registrada y cualquier dato tras el fallo del CEUNP. `trg_impugnacion_bd` impide eliminar una impugnación resuelta.
- **Efecto en el cómputo (CUS14):** `v_impugnacion_efecto` da la situación (PENDIENTE_MESA, APELABLE, EN_APELACION, FIRME) y la opción vigente de cada cédula. Mientras la mesa no decide o hay apelación, la opción es IMPUGNADO. `v_impugnaciones_mesa_cargo` las agrupa por mesa, cargo y opción.

Para probar la apelación vencida, baje `IMPUGNACION_PLAZO_APELACION_HORAS` en Parámetros (0 = sin plazo).

## Endpoints (`/api/impugnaciones`)
| Método | Ruta | Rol |
|---|---|---|
| GET | `/procesos` | ADMIN, CEUNP |
| GET | `/mesas?procesoId=` · `/mesas/{id}` | ADMIN, CEUNP; MIEMBRO_MESA (su mesa); PERSONERO (las mesas que fiscaliza) |
| GET | `/bandeja?procesoId=` | ADMIN, CEUNP |
| GET | `/{id}` | Igual que `/mesas/{id}` |
| POST | `/mesas/{id}/impugnaciones` `{idPersonero, idCargo, motivo}` | PERSONERO presente, miembro de la mesa |
| POST | `/{id}/decision-mesa` `{decision, votosFavor, votosContra, opcion, idLista, fundamento}` | Presidente en funciones |
| POST | `/{id}/apelacion` `{idPersonero, fundamento}` | PERSONERO de la lista, presidente en funciones |
| POST | `/{id}/fallo` `{decision, numeroResolucion, miembrosPleno, votosFavor, votosContra, votoDirimente, opcion, idLista, fundamento}` | CEUNP |

## Base de datos (`12_impugnaciones_apelaciones.sql`)
- `impugnacion_electoral` + columnas de la decisión de la mesa (`votos_mesa_favor`, `votos_mesa_contra`, `opcion_mesa`, `id_lista_mesa`, `fundamento_mesa`, `fecha_decision_mesa`, `id_usuario_mesa`), de la apelación (`id_personero_apela`, `fundamento_apelacion`, `fecha_apelacion`, `id_usuario_apelacion`) y del fallo (`numero_resolucion` único, `miembros_pleno`, `votos_pleno_favor`, `votos_pleno_contra`, `voto_dirimente`, `opcion_final`, `id_lista_final`, `fundamento_ceunp`, `fecha_fallo`, `id_usuario_ceunp`). Los dominios de `decision_mesa`, `decision_ceunp` y `estado` son los del diccionario (tabla 99).
- `sp_resolver_impugnacion_mesa`, `sp_apelar_impugnacion` y `sp_resolver_apelacion`.
- Triggers `trg_impugnacion_bu` y `trg_impugnacion_bd`.
- Vistas `v_impugnacion_efecto` y `v_impugnaciones_mesa_cargo`.
- Parámetros `IMPUGNACION_PLAZO_APELACION_HORAS` y `CEUNP_QUORUM_PLENO`.
- Bitácora: `REGISTRAR_IMPUGNACION` (CUS12), `RESOLVER_IMPUGNACION_MESA`, `APELAR_IMPUGNACION` y `RESOLVER_APELACION`.

## Archivos
- Backend: `backend/src/main/java/pe/unp/elecciones/electoral/impugnaciones/` (`ImpugnacionesController`, `RegistrarImpugnacion`, `ResolverImpugnacion`, `TramitarApelacion`, `ImpugnacionesConsulta`, `ImpugnacionesDto`)
- Frontend: `frontend/src/pages/impugnaciones/` (`PantallaImpugnaciones.jsx`, `ConstanciaImpugnacion.js`, `impugnaciones.css`, con el estilo ejecutivo de `mesa/mesa-ejecutivo.css`). Menú en `DashboardPage.jsx` y botón «Impugnaciones del escrutinio» en «Mi Mesa de Sufragio».

## Botones de la pantalla
- **Todos:** «Actualizar», selección de mesa, «Ver / Tramitar» (abre el expediente con los cuatro pasos), «Imprimir constancia» e «Imprimir relación».
- **Personero:** «Registrar impugnación» (en su nombre) y «Apelar ante el CEUNP».
- **Presidente de mesa:** «Registrar impugnación» (a pedido de un personero), «Registrar decisión de la mesa» y «Apelar ante el CEUNP» (eleva la apelación del personero).
- **CEUNP:** pestañas «Bandeja del CEUNP» y «Por mesa de sufragio», filtros (apelaciones por resolver, por resolver en mesa, firmes, todas) y «Registrar fallo del CEUNP».
- Cada acción pide confirmación antes de enviarse («Confirmar registro», «Confirmar decisión», «Confirmar apelación», «Confirmar fallo»).

## Prueba rápida (verificada con MariaDB 10.11)
1. Ejecutar `12_impugnaciones_apelaciones.sql` (o crear la base con `00`). Tener una mesa CERRADA con el escrutinio iniciado (CUS12: «Contar cédulas») y personeros presentes (CUS08).
2. Personero: en «Impugnar votos y apelar», «Registrar impugnación» con el motivo. La cédula queda IMPUGNADA.
3. Presidente: en «Impugnaciones», «Tramitar» → «Registrar decisión de la mesa». Probar 1 a 2 con «Fundada»: el sistema rechaza la decisión porque no coincide con la mayoría. Registrar «Infundada» 1 a 2 y asignar la cédula a una lista.
4. Personero de la misma lista: «Apelar ante el CEUNP». Un personero de otra lista no puede apelar.
5. CEUNP: en la bandeja, «Tramitar» → «Registrar fallo». Con 4 miembros el sistema exige quórum. Con 3 a 3 pide el voto dirimente. Registrar «Modificar» con otra opción. Después ya no se puede cambiar (RN36).
6. «Imprimir constancia» muestra las cuatro instancias. `SELECT * FROM v_impugnacion_efecto` da la opción vigente para el cómputo.
