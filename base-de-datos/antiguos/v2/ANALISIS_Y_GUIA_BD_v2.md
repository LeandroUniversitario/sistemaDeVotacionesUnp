# Base de datos v2 · Sistema de Elecciones Docentes UNP

Análisis del modelo anterior, mejoras aplicadas y guía de uso.
Motor: MariaDB 10.4+ (XAMPP / phpMyAdmin). Base: `elecciones_unp`.

> **Estado de prueba:** los scripts fueron revisados línea por línea, pero **no pudieron ejecutarse** en el entorno donde se escribieron (no había un servidor MariaDB disponible). La primera importación en tu phpMyAdmin es la prueba real: importa y ejecuta `CALL sp_demo_flujo_completo();`. Si aparece un error, el mensaje de phpMyAdmin indica el archivo y la línea.

## 1. Archivos

| Archivo | Contenido |
|---|---|
| `01_esquema.sql` | 27 tablas con claves, restricciones CHECK e índices. **Borra y recrea todo.** |
| `02_funciones_triggers.sql` | 4 funciones y 19 triggers |
| `03_vistas.sql` | 14 vistas de consulta y reportes |
| `04_procedimientos.sql` | 26 procedimientos (ciclo electoral completo) |
| `05_datos_iniciales.sql` | Parámetros, cargos excluidos, usuario `admin`, 14 facultades y sus departamentos |
| `06_demo_flujo_completo.sql` | Opcional: elección de prueba de punta a punta |
| `elecciones_unp_v2_COMPLETO.sql` | Los archivos 01 a 05 unidos, para importar de una sola vez |
| `diagrama_bd_v2.dbml` | Diagrama del modelo para dbdiagram.io |

### Instalación en phpMyAdmin

1. Exporta tu base actual (pestaña Exportar) por si quieres volver atrás.
2. Pestaña **Importar** → elige `elecciones_unp_v2_COMPLETO.sql` → Continuar.
3. Opcional: importa `06_demo_flujo_completo.sql` y en la pestaña SQL ejecuta `CALL sp_demo_flujo_completo();`
4. Usuario inicial: `admin` / `Admin2026*` (cámbiala al entrar).

## 2. Problemas encontrados en el modelo anterior

| # | Problema | Consecuencia | Solución en v2 |
|---|---|---|---|
| 1 | Tablas duplicadas `mesa_sufragio` y `padron_mesa` (creadas por Hibernate con FKs repetidas `proceso_id`/`id_proceso`) | Dos "mesas" y dos "padrones" distintos; las entidades Java ya apuntan a `mesa_electoral` y `padron_electoral` | Eliminadas |
| 2 | `docente.estado` no tenía `INACTIVO`, pero el enum Java sí | Error al guardar un docente inactivo | Agregado al ENUM |
| 3 | `MesaSufragio.java` tiene `estado`, `horaInstalacion`, `horaCierre`, `totalElectores` como `@Transient` | El estado de la mesa se perdía al reiniciar | Columnas reales en `mesa_electoral` |
| 4 | `voto.fecha_hora` y `padron_electoral.fecha_votacion` se guardaban al mismo segundo | Cruzando las dos tablas por hora se sabía por quién votó cada docente: **se rompía el secreto del voto** | Un trigger guarda en `voto` solo la hora (sin minutos ni segundos) |
| 5 | Nada impedía insertar un voto con el proceso cerrado, ni modificarlo o borrarlo | Violaba RN06 y RN26 | Triggers en `voto`: solo en VOTACION, y es inmutable |
| 6 | `voto.id_lista_elegida` podía ser una lista de otro cargo; `padron.id_cargo` podía ser de otro proceso | Datos incoherentes | Claves foráneas compuestas |
| 7 | No existía la tabla `multa` (RN35), aunque el frontend y el DBML antiguo la mencionan | Sin soporte para sanciones | Tabla `multa` + `sp_generar_multas` |
| 8 | No había dónde guardar el resultado oficial | El conteo se recalculaba cada vez (contra RN26) | Tabla `resultado_electoral` inmutable + estado del resultado en `cargo_electoral` |
| 9 | RN11 (un candidato en una sola lista) solo se validaba en Java | Se podía saltar insertando directo | Trigger `trg_candidato_bi` |
| 10 | `cargo_electoral.id_jurisdiccion` sin validación | Cargos apuntando a facultades inexistentes | Trigger + CHECK |
| 11 | `docente.id_facultad` podía no coincidir con la facultad de su departamento | Padrón de Decano incorrecto | Trigger que la sincroniza siempre |
| 12 | El sorteo de mesas estaba simulado en `SorteoController` | RF06 sin implementar | `sp_sortear_miembros_mesa` reproducible con semilla |
| 13 | El `emitir_voto_transaccional` descrito en la documentación estaba en sintaxis PostgreSQL y no existía en el `schema.sql` | No había voto transaccional | `sp_emitir_voto` |
| 14 | La bitácora "inmutable" se podía editar | Incumple el glosario | Triggers que bloquean UPDATE y DELETE |
| 15 | Faltaban los campos de transparencia (RN15), credenciales QR (RF51, RF56) y varios UNIQUE | — | Agregados |

## 3. Qué cambió en cada tabla

Se **conservan todos los nombres** de tablas y columnas que usa el backend. Las columnas nuevas son opcionales (NULL o con valor por defecto), así que las entidades JPA actuales siguen insertando sin cambios.

| Tabla | Cambios |
|---|---|
| `docente` | + `grado_academico`, `fecha_ingreso`, `fecha_categoria`, `email`, `fecha_registro`; estado `INACTIVO`; CHECK de DNI de 8 dígitos |
| `proceso_electoral` | + `fecha_convocatoria`, `fecha_limite_inscripcion`, `fecha_cierre_real`, `motivo_anulacion`; CHECK de fechas, quórum y coherencia de segunda vuelta |
| `cargo_electoral` | + `porcentaje_minimo_victoria` (50), `estado_resultado`, `id_lista_ganadora` |
| `cargo_categoria_permitida` | + `puede_votar`, `puede_postular` (RF03 completo) |
| `lista_electoral` | + `url_plan_gobierno`, `motivo_exclusion`; UNIQUE por nombre y por orden de cédula dentro del cargo |
| `candidato` | + `url_hoja_vida`, `motivo_exclusion` |
| `tacha` | + `resolucion`, `id_usuario_resuelve` |
| `mesa_electoral` | + `estado`, `hora_instalacion`, `hora_cierre`, `total_electores` |
| `miembro_mesa` | + `orden_sorteo`, `asistio`, `qr_credencial_hash`; un solo presidente, secretario y vocal por mesa |
| `personero` | + `qr_credencial_hash`; tipo MESA exige mesa |
| `padron_electoral` | + `id_mesa` (mesa asignada) |
| `voto` | + `id_mesa` (escrutinio por mesa) |
| `usuario` | + `intentos_fallidos`, `bloqueado_hasta`, `ultimo_acceso`, `fecha_creacion` |
| **Nuevas** | `resultado_electoral`, `multa` |
| **Eliminadas** | `mesa_sufragio`, `padron_mesa` |

## 4. Procedimientos almacenados

Todos abren su transacción, hacen ROLLBACK ante cualquier error y devuelven un mensaje que cita la regla de negocio incumplida.

| Etapa | Procedimiento | Qué hace |
|---|---|---|
| Proceso | `sp_crear_proceso` | Crea la convocatoria en CREADO |
| | `sp_agregar_cargo` | Agrega un cargo y sus categorías que votan y postulan |
| | `sp_cambiar_estado_proceso` | CREADO → INSCRIPCION → VOTACION → CERRADO, verificando requisitos |
| | `sp_anular_proceso` | Nulidad con motivo (RN34) |
| Listas | `sp_inscribir_lista`, `sp_inscribir_candidato` | Inscripción con plazo, categoría y jurisdicción |
| | `sp_validar_lista` | Admite o excluye la fórmula completa (RN12) |
| | `sp_presentar_tacha`, `sp_resolver_tacha` | Tacha fundada: excluye al candidato y cae la lista |
| | `sp_sortear_orden_cedula` | Orden de cédula por sorteo con semilla (RN18) |
| Padrón y mesas | `sp_generar_padron` | Padrón por cargo según estado, categoría y jurisdicción |
| | `sp_crear_mesas` | Crea mesas y reparte electores |
| | `sp_sortear_miembros_mesa`, `sp_sortear_todas_las_mesas` | 3 titulares + 3 suplentes, auditable |
| | `sp_registrar_asistencia_miembro` | Insumo de la multa por omisión |
| Elección | `sp_instalar_mesa` | Instala y emite el acta de instalación |
| | **`sp_emitir_voto`** | Marca el padrón, inserta el voto anónimo y emite la constancia en una sola transacción |
| | `sp_cerrar_mesa` | Actas de sufragio y escrutinio con SHA-256 |
| Resultados | `sp_computar_resultados` | Quórum, cuadre, ganador o segunda vuelta |
| | `sp_crear_segunda_vuelta` | Clona cargo, las 2 listas más votadas y el padrón |
| Sanciones | `sp_generar_multas`, `sp_actualizar_multa` | 2.5 % y 3 % de la UIT |
| Verificación | `sp_verificar_constancia`, `sp_verificar_acta` | Validación por token QR |
| Utilitarios | `sp_registrar_auditoria`, `sp_emitir_acta` | Uso interno |

### Ejemplo de uso

```sql
CALL sp_crear_proceso('Elección de Rector 2026', '2026-11-20 09:00:00', '2026-11-20 15:00:00',
                      60.00, '2026-10-15', '2026-11-05 23:59:59', 1, @proceso);
CALL sp_agregar_cargo(@proceso, 'Rector y Vicerrectores', 'UNIVERSIDAD', NULL,
                      'PRINCIPAL,ASOCIADO,AUXILIAR', 'PRINCIPAL', @cargo);
CALL sp_cambiar_estado_proceso(@proceso, 'INSCRIPCION', 1);
-- ... listas, padrón, mesas y sorteos ...
CALL sp_emitir_voto(@proceso, @cargo, 15, 3, 'VALIDO', @token);   -- docente 15 vota por la lista 3
CALL sp_emitir_voto(@proceso, @cargo, 16, NULL, 'BLANCO', @token);
SELECT * FROM v_quorum_proceso WHERE id_proceso = @proceso;
```

### Cómo se audita el sorteo (RNF01)

El orden es el ascendente de `SHA2(CONCAT(semilla, '|', dni), 256)` entre los docentes elegibles. La semilla queda guardada en `mesa_electoral.semilla_sorteo` y en la bitácora. Ante una impugnación, cualquiera repite el cálculo y obtiene los mismos seis miembros.

## 5. Triggers

| Tabla | Regla que protege |
|---|---|
| `docente` | La facultad es la del departamento; quien no está ACTIVO no vota (RN03) |
| `proceso_electoral` | FINALIZADO y ANULADO son estados finales |
| `cargo_electoral` | La jurisdicción existe según el nivel |
| `candidato` | RN11; no es personero ni miembro de mesa |
| `personero` | RN21: no es candidato ni autoridad |
| `miembro_mesa` | RN20; una sola mesa por proceso |
| `padron_electoral` | No se "des-vota" ni se borra a quien votó; solo se marca en VOTACION |
| `voto` | Solo en VOTACION y por lista admitida; hora truncada; inmutable |
| `acta_electoral`, `resultado_electoral`, `log_auditoria` | Inmutables |

## 6. Vistas

`v_docente_detalle`, `v_padron_detalle`, `v_participacion_cargo`, `v_quorum_proceso` (y su alias `vista_quorum`), `v_resultados_cargo`, `v_cedula_votacion`, `v_candidatos_publicos`, `v_cuadre_votos`, `v_mesa_detalle`, `v_miembros_mesa`, `v_elegibles_sorteo`, `v_multas_detalle`, `v_tachas_detalle`.

`v_resultados_cargo` no devuelve filas mientras el proceso esté en VOTACION, para que nadie vea resultados parciales.

## 7. Ajustes necesarios en el backend

1. **`application.yml`**: cambia `ddl-auto: update` por `ddl-auto: none`. Con `update`, Hibernate vuelve a crear columnas y claves sobrantes (así nacieron las tablas duplicadas).
2. **`VotoService.registrarVoto`**: hoy inserta el voto sin marcar el padrón, así que un docente puede votar varias veces y el cuadre RN27 falla. Debe llamar a `sp_emitir_voto` (necesita el id del docente autenticado).
3. **`SorteoController`**: reemplazar la respuesta simulada por `sp_crear_mesas` y `sp_sortear_todas_las_mesas`.
4. **`MesaSufragio.java`**: quitar `@Transient` de `estado`, `horaInstalacion`, `horaCierre` y `totalElectores` y mapearlos a las columnas nuevas.
5. Los procedimientos abren su propia transacción. Llámalos desde métodos **sin** `@Transactional`, o el `START TRANSACTION` confirmará lo que el método tuviera pendiente.
6. Los triggers de `voto` rechazan inserciones si el proceso no está en VOTACION; es el comportamiento correcto, pero las pruebas manuales deben respetar el flujo de estados.

## 8. Decisiones que debes confirmar

| Tema | Lo que asumí | Por qué importa |
|---|---|---|
| Quórum (RN31) | Se evalúa **por cargo**; el proceso se anula solo si ningún cargo lo alcanza | Un Decano se elige con el padrón de su facultad, no con el de toda la universidad |
| Segunda vuelta (RN33) | Gana quien **supera** el 50 % de los votos válidos; el valor es editable por cargo | Para representantes ante órganos de gobierno el reglamento puede usar otra fórmula (lista incompleta, cifra repartidora) |
| Voto nulo (RN25) | `sp_emitir_voto` solo acepta VALIDO o BLANCO, como indica tu documento de reglas | El ENUM conserva `NULO` por compatibilidad con `TipoVoto.java` |
| UIT | Se mantuvo 5150.00, el valor que siembra tu `ParametrosController` | Ese monto corresponde a 2024; actualízalo en `parametro_global` |
| Familiares directos (RN20) | No se excluyen del sorteo | No existe información de parentesco en el modelo |
| Tacha fundada (RN12) | Cae toda la lista (estado TACHADA) | Si el reglamento permite reemplazar al candidato dentro del plazo, hay que agregar ese flujo |

## 9. Limitación conocida del secreto del voto

La hora del voto ya no permite el cruce, pero `voto.id_voto` sigue siendo autoincremental: quien tenga acceso directo a la base podría ordenar los votos por `id_voto` y el padrón por `fecha_votacion` y emparejarlos. La solución completa es que la clave de `voto` sea aleatoria (UUID), lo que obliga a cambiar `Voto.java`. Queda como siguiente paso recomendado.
