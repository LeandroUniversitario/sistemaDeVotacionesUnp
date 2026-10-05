# 🔍 Auditoría del Modelo – Sistema de Elecciones UNP

Revisé cruzadamente los 4 artefactos principales:
- `diagrama_clases_diseno.puml` (Diseño OO)
- `diagrama_er.puml` (Modelo Lógico de BD)
- `diagrama_bd.dbml` (Modelo físico para Draw.io)
- `schema.sql` (Script DDL + Stored Procedure)

---

## 🔴 Inconsistencias entre artefactos (Hay que corregir)

### 1. Falta la tabla `cargo_excluido_sorteo` en la BD
- **Dónde existe:** En el Diagrama de Clases hay una clase `CargoExcluidoSorteo` con una nota que dice *"Catálogo editable por el Comité Electoral (no fijo en código)"*.
- **Dónde falta:** No existe en `schema.sql`, ni en `diagrama_er.puml`, ni en `diagrama_bd.dbml`.
- **Impacto:** Sin esta tabla, el sorteo de mesas tendría los cargos excluidos hardcodeados en Java, contradiciendo la regla de negocio que acordamos.
- **Corrección:** Agregar la tabla `cargo_excluido_sorteo` con columnas `id`, `nombre_cargo`, `nivel`.

### 2. La tabla `Voto` del DBML/SQL tiene `ip_origen`, pero la clase `Voto` del Diagrama de Clases no
- **En BD:** `voto` tiene `ip_origen VARCHAR`.
- **En Clases:** `Voto` solo tiene `id` y `fechaHora`.
- **Impacto:** Inconsistencia menor pero un jurado atento lo nota. Si decidimos que la BD robusta maneje todo, al menos debemos anotar el atributo en la clase para que haya trazabilidad.
- **Corrección:** Agregar `- ipOrigen: String` y `- idCandidatoElegido: int` a la clase `Voto`.

### 3. Discrepancia en el nombre de campos entre Diagrama de Clases y BD
| Concepto | Diagrama de Clases | BD (SQL/DBML) |
|---|---|---|
| Candidatura/Candidato | Clase `Candidatura` | Tabla `candidato` |
| Descripción del proceso | `descripcion: String` | `nombre: VARCHAR` |
| Ha votado | `haVotado: boolean` | `ya_voto: BOOLEAN` |
- **Impacto:** Confusión al momento de programar. Hay que unificar nomenclatura.
- **Corrección:** Alinear los nombres del Diagrama de Clases a los de la BD (que son más claros).

---

## 🟡 Lagunas lógicas de negocio (Casos no contemplados)

### 4. No hay tabla/entidad para la Constancia de Voto (QR)
- Acordamos implementar un código QR verificable en la constancia de voto (UC11).
- **Problema:** No hay ninguna tabla que almacene el token único de verificación.
- **Corrección:** Agregar tabla `constancia_voto` con:
  - `id_constancia` (PK)
  - `id_docente` (FK) — aquí sí va el docente, porque la constancia dice *"Juan sí votó"*, no dice *por quién*.
  - `id_cargo` (FK)
  - `token_qr` (UUID único para la URL de verificación)
  - `fecha_emision`

### 5. No hay mecanismo de autenticación en el modelo
- El login funciona con `admin / 123` en el frontend, pero no hay tabla `usuario` ni `sesion` en la BD.
- **Problema:** En producción, cada docente necesita credenciales. Además el Comité y el Admin son roles distintos.
- **Corrección:** Agregar tablas:
  - `usuario`: `id_usuario`, `id_docente (FK nullable)`, `username`, `password_hash`, `rol` (ADMIN, COMITE, DOCENTE)
  - `sesion_activa`: `id_sesion`, `id_usuario (FK)`, `token`, `fecha_inicio`, `fecha_expiracion`

---

## 🟢 Mejoras de seguridad y robustez (Opcionales pero valiosas)

### 6. El Stored Procedure `emitir_voto_transaccional` no verifica habilitación
- Actualmente solo verifica si `ya_voto = TRUE`.
- **Problema:** No valida si `habilitado_para_votar = TRUE`. Un docente deshabilitado (ej. suspendido a última hora) podría votar.
- **Corrección:** Agregar al SP:
```sql
IF NOT EXISTS (
    SELECT 1 FROM padron_electoral 
    WHERE id_cargo = p_id_cargo 
    AND id_docente = p_id_docente 
    AND habilitado_para_votar = TRUE
) THEN
    RAISE EXCEPTION 'El docente no está habilitado para votar en este cargo.';
END IF;
```

---

## ✅ Lo que está excelente (No tocar)

| Aspecto | Veredicto |
|---|---|
| Aislamiento del Voto (sin FK a Docente) | ✅ Perfecto |
| Padrón por Cargo (no global) | ✅ Perfecto |
| Jurisdicción en CargoElectoral | ✅ Perfecto |
| CargoAdministrativo con fechas de vigencia | ✅ Perfecto |
| Estado del Docente (ACTIVO/LICENCIA) | ✅ Perfecto |
| Transacción atómica en el SP | ✅ Perfecto |
| Relaciones y cardinalidades | ✅ Consistentes |

---

## Resumen de acción
| # | Prioridad | Acción |
|---|---|---|
| 1 | 🔴 Alta | Agregar tabla `cargo_excluido_sorteo` a BD |
| 2 | 🔴 Alta | Sincronizar atributos de `Voto` entre Clases y BD |
| 3 | 🟡 Media | Unificar nomenclatura Clases ↔ BD |
| 4 | 🟡 Media | Agregar tabla `constancia_voto` (soporte QR) |
| 5 | 🟡 Media | Agregar tablas `usuario` y `sesion_activa` |
| 6 | 🟢 Baja | Mejorar validación en el Stored Procedure |

> **¿Deseas que aplique todas estas correcciones a los archivos automáticamente?**
