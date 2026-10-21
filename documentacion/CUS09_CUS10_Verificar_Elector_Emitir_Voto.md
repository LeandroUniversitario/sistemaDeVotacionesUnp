# CUS09 · Verificar elector y CUS10 · Emitir voto

**Actores:** miembro de mesa (CUS09), docente elector (CUS10) · **Requiere:** padrón y mesas (CUS02, CUS06), pase QR (CUS07, opcional), mesa INSTALADA (CUS08)
**Instalación:** en una base ya creada, ejecutar `base-de-datos/06_verificar_elector_emitir_voto.sql`. `01_crear_base_de_datos.sql` ya incluye la tabla y `02_limpiar_datos_electorales.sql` también la vacía.

## Flujo
1. El elector llega a su mesa. El miembro de mesa abre «Verificar elector», lee su **pase QR** (CUS07) o digita su **DNI**.
2. El sistema comprueba: mesa INSTALADA, proceso en VOTACION y dentro del horario (RN06, RN07), elector en el padrón de **esa** mesa (RN04; si es de otra mesa, la indica), habilitado y sin haber votado (RN01).
3. «Habilitar cabina de votación» registra una **autorización** (`autorizacion_voto`) que vence en `MINUTOS_AUTORIZACION_VOTO` (15 por defecto, en `parametro_global`). Si el elector se retira, la mesa la **anula** con un motivo.
4. En la cabina, el docente entra con su cuenta → «Emitir voto». Sin autorización vigente la cédula no aparece y el voto se rechaza (también en `POST /api/votos`).
5. La cédula muestra cada cargo pendiente con sus listas ADMITIDAS en el orden sorteado (RN18) y sus candidatos, más **voto en blanco**. El elector marca una opción por cargo, revisa y confirma.
6. Por cada cargo se llama a `sp_emitir_voto` (sin cambios): bloquea el padrón, marca que votó, inserta el voto **anónimo** y emite la constancia. Al terminar todos los cargos la autorización queda USADA.
7. Se muestra la **constancia** con un QR por cargo que apunta a `/api/publico/constancias/{token}` (prueba la participación, no el sentido del voto). Se puede imprimir.

## Correspondencia con secuencia_emitir_voto.puml
| Mensaje | Frontend | Backend |
|---|---|---|
| validarHabilitacion / verificarHabilitacion | `EmitirVotoPage` (estado del proceso) | `GET /api/sufragio/cedula` → `EmitirVoto.cedula` |
| obtenerListasAdmitidas / mostrarOpciones | cédula | `EmitirVoto.cargosConListas` |
| registrarVoto (transacción atómica) | «Confirmar y emitir voto» | `POST /api/sufragio/votar` → `sp_emitir_voto` por cargo |
| mostrarConstancia | `Constancia`, «Imprimir constancia» | tokens devueltos por `sp_emitir_voto` |

## Supuestos
- **Voto nulo:** no se ofrece. RN25 y `sp_emitir_voto` lo prohíben en el voto electrónico (un intento devuelve el error RN25). Se ofrece voto en blanco.
- La cabina es la sesión del propio docente (en la PC de la cabina o su dispositivo). El miembro de mesa nunca ve la cédula.
- Una cédula incluye todos los cargos pendientes del elector; hay que marcar uno por cargo.
- La autorización no guarda nada del sentido del voto; la tabla `voto` sigue sin referencias a docente.

## Endpoints
| Método | Ruta | Rol |
|---|---|---|
| GET | `/api/sufragio/mesas` | ADMIN, CEUNP, MIEMBRO_MESA (solo sus mesas) |
| GET | `/api/sufragio/mesas/{id}` (mesa, totales, padrón, autorizaciones) | ídem |
| POST | `/api/sufragio/mesas/{id}/verificar` `{dni}` o `{codigo}` | ídem |
| POST | `/api/sufragio/mesas/{id}/autorizaciones` `{idDocente, metodo, idCredencial}` | ídem |
| POST | `/api/sufragio/mesas/{id}/autorizaciones/{a}/anular` `{motivo}` | ídem |
| GET | `/api/sufragio/cedula` | DOCENTE, MIEMBRO_MESA, PERSONERO |
| POST | `/api/sufragio/votar` `{procesoId, votos:[{cargoId, tipo, listaId}]}` | ídem |

Bitácora: `VERIFICAR_ELECTOR`, `AUTORIZAR_VOTO`, `ANULAR_AUTORIZACION_VOTO` (y `EMITIR_VOTO` de `sp_emitir_voto`).

## Archivos
- BD: `base-de-datos/06_verificar_elector_emitir_voto.sql`
- Backend: `backend/src/main/java/pe/unp/elecciones/electoral/votacion/` (`VerificarElectorController`, `EmisionVotoController`, `VerificarElector`, `EmitirVoto`, `VotacionConsulta`, `VotacionDto`); `VotoController` exige la autorización
- Frontend: `frontend/src/pages/votacion/` (`VerificarElectorPage`, `EmitirVotoPage`, `votacion.css`); menús en `DashboardPage`

## Prueba rápida
1. Ejecutar `06_verificar_elector_emitir_voto.sql`. Tener un proceso en VOTACION con una mesa INSTALADA (CUS08).
2. Como miembro de mesa: «Verificar elector» → pestaña DNI → DNI de un elector de la mesa → «Habilitar cabina de votación».
3. Como ese docente: «Emitir voto» → marcar una lista o blanco → «Revisar mi voto» → «Confirmar y emitir voto» → constancia.
4. Volver a verificarlo en la mesa → «El elector ya votó». Votar sin pasar por la mesa → «No tiene la cabina habilitada».
