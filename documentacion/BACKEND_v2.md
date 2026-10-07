# Backend v2 · Integración con la base de datos v2

Cambios aplicados al backend Spring Boot para que use la base de datos de `base-de-datos/v2`.

> **Estado de prueba:** el código pasó una revisión de sintaxis con `javac`, pero **no se compiló con Maven ni se ejecutó** (el entorno donde se escribió no tenía acceso a las dependencias de Spring ni a un servidor MariaDB). El primer `mvn spring-boot:run` es la prueba real. Todos los cambios están sin confirmar en git: `git diff` los muestra y `git checkout -- backend` los deshace.

## 1. Cómo funciona ahora

- Las reglas críticas se ejecutan en **procedimientos almacenados**. El backend los invoca con `ProcedimientoDao` (JDBC).
- Los procedimientos abren su propia transacción, por eso los servicios nuevos **no llevan `@Transactional`**.
- Cuando un procedimiento o un trigger rechaza una operación, `ErrorBdHandler` devuelve HTTP 400 con el mensaje de la regla en el campo `detail` (por ejemplo `RN01: el docente ya voto por este cargo.`). El frontend ya lee ese campo.
- Hibernate ya no modifica el esquema (`ddl-auto: none`).

## 2. Archivos

| Archivo | Cambio |
|---|---|
| `application.yml` | `ddl-auto: none`; errores en formato Problem Details |
| `config/ErrorBdHandler.java` | **Nuevo.** Traduce errores de la base de datos a respuestas legibles |
| `config/SecurityConfig.java` | `/api/publico/**` sin inicio de sesión |
| `auth/UsuarioActual.java` | **Nuevo.** Obtiene el usuario y el docente de la sesión |
| `service/ProcedimientoDao.java` | **Nuevo.** Llama procedimientos y consulta vistas |
| `service/VotoService.java` | Reescrito: usa `sp_emitir_voto` |
| `service/SorteoService.java` | **Nuevo.** Padrón, mesas y sorteos reales |
| `service/MesaService.java` | Reescrito: instalar, cerrar, verificar elector, actas |
| `service/ProcesoService.java` | **Nuevo.** Estados, padrón, cómputo, segunda vuelta, multas |
| `service/ElectoralService.java` | Tachas con `sp_resolver_tacha`; bloqueo de cambios fuera de plazo; categorías con voto/postulación |
| `controller/VotoController.java`, `SorteoController.java`, `MesaController.java` | Reescritos |
| `controller/ProcesoController.java`, `PublicoController.java` | **Nuevos** |
| `controller/ImportacionDocenteController.java` | Importar padrón solo para ADMIN y CEUNP |
| `controller/AuditoriaController.java` | Lista de acciones según la bitácora real |
| `domain/MesaSufragio.java` | `estado`, horas y total de electores ya se guardan (antes `@Transient`) |
| `domain/CargoElectoral.java` | Expone `estadoResultado`, `idListaGanadora`, `porcentajeMinimoVictoria` |
| `domain/CategoriaPermitida.java` | `puedeVotar`, `puedePostular` |

## 3. Problemas corregidos

| Antes | Ahora |
|---|---|
| `POST /api/votos` insertaba el voto sin revisar el padrón: cualquiera votaba varias veces y sin estar empadronado | Vota el docente de la sesión, una vez por cargo, en una transacción |
| El sorteo devolvía una respuesta fija ("15 mesas", semilla inventada) | Sorteo real y reproducible con semilla |
| El frontend llamaba a `/api/mesas/{id}/instalar`, `/cerrar`, `/verificar-elector`, `/asistencia` y `/api/procesos/{id}/listas`, que no existían | Implementados |
| `GET /api/mesas` devolvía entidades con relaciones perezosas (falla al serializar) | Devuelve datos planos |
| Importar docentes no exigía rol | Solo ADMIN y CEUNP |
| Los mensajes de error no llegaban al frontend | Llegan en `detail` |
| Una tacha fundada solo excluía al candidato | También cae la lista (RN12) |
| Se podían agregar cargos, listas y candidatos con la votación en curso | Solo en CREADO o INSCRIPCION |

## 4. Endpoints

Los que ya existían en `ElectoralController` y `AuthController` no cambian de ruta.

### Proceso (ADMIN, CEUNP)

| Método y ruta | Cuerpo | Qué hace |
|---|---|---|
| `GET /api/procesos/{id}` | | Datos del proceso |
| `PATCH /api/procesos/{id}/estado` | `{"estado":"INSCRIPCION"}` | CREADO → INSCRIPCION → VOTACION → CERRADO |
| `POST /api/procesos/{id}/padron` | | Genera el padrón |
| `GET /api/procesos/{id}/padron` | | Lista el padrón |
| `GET /api/procesos/{id}/participacion` | | Quórum global, por cargo y cuadre de votos |
| `POST /api/listas/{id}/validar` | `{"admitir":true}` o `{"admitir":false,"motivo":"..."}` | Admite o excluye la lista |
| `POST /api/procesos/{id}/computo` | | Cómputo oficial (una sola vez) |
| `POST /api/procesos/{id}/segunda-vuelta` | `{"fechaInicio":"...","fechaFin":"..."}` | Crea la segunda vuelta |
| `POST /api/procesos/{id}/anular` | `{"motivo":"..."}` | Nulidad |
| `POST /api/procesos/{id}/multas` | | Genera multas |
| `GET /api/procesos/{id}/multas` | | Lista multas |
| `PATCH /api/multas/{id}` | `{"estadoPago":"PAGADA"}` | Pago o exoneración |

### Sorteos (ADMIN, CEUNP)

| Método y ruta | Qué hace |
|---|---|
| `POST /api/sorteos/generar-mesas?procesoId=1` | Genera padrón y mesas si faltan y sortea los miembros. Opcionales: `electoresPorMesa`, `ubicacion`, `semilla` |
| `POST /api/sorteos/orden-cedula?cargoId=1` | Sortea el orden de la cédula. Opcional: `semilla` |
| `GET /api/sorteos/elegibles?procesoId=1` | Docentes que pueden ser sorteados |

### Mesas (ADMIN, CEUNP, MIEMBRO_MESA)

Un miembro de mesa solo ve y opera su propia mesa.

| Método y ruta | Qué hace |
|---|---|
| `GET /api/mesas?procesoId=1` | Lista de mesas |
| `GET /api/mesas/{id}`, `/miembros`, `/actas` | Detalle, miembros y actas |
| `POST /api/mesas/{id}/instalar` | Instala y emite el acta de instalación |
| `POST /api/mesas/{id}/cerrar` | Cierra y emite actas de sufragio y escrutinio |
| `GET /api/mesas/{id}/verificar-elector?dni=...` | Comprueba que el DNI está en el padrón de la mesa |
| `POST /api/mesas/{id}/asistencia` | `{"dni":"..."}` Deja constancia de que el elector fue identificado |
| `POST /api/mesas/{id}/miembros/{idDocente}/asistencia` | `{"asistio":false}` Asistencia de un miembro (solo ADMIN, CEUNP) |

### Elector (cualquier usuario asociado a un docente)

| Método y ruta | Qué hace |
|---|---|
| `GET /api/procesos/{id}/listas` | Cédula: listas admitidas en el orden sorteado |
| `GET /api/votos/mis-cargos` | Cargos por los que puede votar y si ya votó |
| `POST /api/votos` | `{"procesoId":1,"cargoId":1,"tipo":"VALIDO","listaElegidaId":3}` o `{"tipo":"BLANCO"}`. Devuelve `tokenConstancia` |
| `GET /api/votos/mis-constancias` | Constancias de participación |
| `GET /api/multas/mias` | Multas del docente |
| `GET /api/procesos/{id}/resultados` | Resultados, solo después del cómputo |

### Público (sin inicio de sesión)

| Método y ruta | Qué hace |
|---|---|
| `GET /api/publico/constancias/{token}` | Verifica el QR de una constancia |
| `GET /api/publico/actas/{token}` | Verifica el QR de un acta y su integridad |
| `GET /api/publico/procesos/{id}/candidatos` | Portal de transparencia (RN15) |
| `GET /api/publico/procesos/{id}/resultados` | Resultados oficiales |

## 5. Orden de uso de una elección

1. `POST /api/procesos` y `POST /api/procesos/{id}/cargos` (ya existían).
2. `POST /api/cargos/{id}/categorias-permitidas`, listas y candidatos (ya existían).
3. `PATCH .../estado` → `INSCRIPCION`.
4. Tachas (ya existían) y `POST /api/listas/{id}/validar`.
5. `POST /api/sorteos/orden-cedula` por cada cargo.
6. `POST /api/sorteos/generar-mesas`.
7. `PATCH .../estado` → `VOTACION`.
8. Por mesa: `instalar`; los electores votan; `cerrar`.
9. `PATCH .../estado` → `CERRADO`, luego `POST .../computo`.
10. `POST .../multas` y, si corresponde, `POST .../segunda-vuelta`.

## 6. Pendiente en el frontend

El backend ya ofrece todo el ciclo, pero estas pantallas aún no lo usan:

- **Terminal de votación**: envía `procesoId` y `cargoId` fijos en 1. Debe tomar los cargos de `GET /api/votos/mis-cargos` y mostrar el `tokenConstancia` como QR.
- **Voto nulo**: la terminal ofrece la opción, pero el procedimiento la rechaza (RN25).
- **Panel del CEUNP**: faltan botones para cambiar el estado del proceso, validar listas, sortear la cédula, computar resultados, generar multas y crear la segunda vuelta.
- **Resultados y participación**: no hay pantalla que consuma `/participacion` ni `/resultados`.
- **QR del panel**: los códigos de fotocheck, personero y pase de votación se generan con el nombre de usuario, no con un token de la base de datos.

## 7. Limitaciones conocidas

- El inicio de sesión no escribe en la bitácora ni usa `intentos_fallidos` / `sesion_activa`.
- Listas, candidatos y tachas se siguen creando por JPA para no romper las pantallas actuales, que trabajan con el proceso en CREADO. Las reglas RN11, RN20 y RN21 las protegen los triggers.
- La bitácora que escriben los procedimientos no registra IP ni navegador.
