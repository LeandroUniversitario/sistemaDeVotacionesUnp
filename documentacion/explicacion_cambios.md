# 📋 Explicación Detallada de Cada Cambio Aplicado

Tras la auditoría cruzada del modelo, se aplicaron **6 correcciones** a los 4 archivos principales del proyecto. A continuación se explica cada una con su justificación técnica y de negocio.

---

## Cambio 1: Nueva tabla `cargo_excluido_sorteo`

**Archivos afectados:** `schema.sql`, `diagrama_er.puml`, `diagrama_bd.dbml`

**¿Qué se hizo?**
Se agregó una tabla nueva con 3 columnas:

```sql
CREATE TABLE cargo_excluido_sorteo (
    id_cargo_excluido SERIAL PRIMARY KEY,
    nombre_cargo VARCHAR(255) NOT NULL,  -- Ej: "Decano", "Jefe de Departamento"
    nivel VARCHAR(50) NOT NULL           -- Ej: "FACULTAD", "UNIVERSIDAD"
);
```

**¿Por qué?**
Cuando el sistema ejecuta el Sorteo de Mesas Electorales (UC7), necesita excluir a los docentes que ocupan cargos administrativos como Decano o Jefe de Departamento. **Antes**, la lista de qué cargos excluir estaba implícita en el código Java (hardcodeada). **Ahora**, el Comité Electoral puede editar esta tabla desde el sistema sin necesidad de un programador:

| Antes (Mal) | Después (Bien) |
|---|---|
| `if (cargo == "Decano" \|\| cargo == "Rector")` fijo en Java | `SELECT * FROM cargo_excluido_sorteo` dinámico desde la BD |

**Regla de negocio:** Si mañana la UNP decide que los "Coordinadores de Acreditación" tampoco pueden ser miembros de mesa, el Comité simplemente agrega una fila a esta tabla. Cero código nuevo.

---

## Cambio 2: Sincronización de atributos de la clase `Voto`

**Archivo afectado:** `diagrama_clases_diseno.puml`

**¿Qué se hizo?**
Se agregaron 2 atributos que ya existían en la BD pero faltaban en el diagrama de clases:

```diff
 class Voto {
     - id: int
+    - idCandidatoElegido: int
     - fechaHora: Date
+    - ipOrigen: String
 }
```

**¿Por qué?**
Un principio fundamental de RUP es la **trazabilidad**: cada atributo de una tabla en la BD debe poder rastrearse hasta una clase del diagrama de diseño, y viceversa. Si un jurado lee el diagrama de clases y ve que `Voto` solo tiene `id` y `fechaHora`, pero luego abre el SQL y ve `ip_origen` y `id_candidato_elegido`, va a preguntar *"¿de dónde salieron estos campos?"*. Con este cambio, ambos artefactos dicen exactamente lo mismo.

---

## Cambio 3: Unificación de nomenclatura (Clases ↔ BD)

**Archivo afectado:** `diagrama_clases_diseno.puml`

**¿Qué se hizo?**
Se renombraron 3 elementos para que coincidan con los nombres de las tablas SQL:

| Antes (Inconsistente) | Después (Unificado) | Razón |
|---|---|---|
| Clase `Candidatura` | Clase `Candidato` | La tabla SQL se llama `candidato` |
| Atributo `descripcion` en ProcesoElectoral | `nombre` | La columna SQL se llama `nombre` |
| Atributo `haVotado` en PadronElectoral | `yaVoto` | La columna SQL se llama `ya_voto` |

Además, se le agregaron a `PadronElectoral` los atributos que ya tenía la tabla en la BD:

```diff
 class PadronElectoral {
     - id: int
-    - haVotado: boolean
+    - habilitadoParaVotar: boolean
+    - yaVoto: boolean
+    - fechaFirmaDigital: Date
 }
```

**¿Por qué?**
Cuando un programador tome el diagrama de clases para escribir código Java, necesita que los nombres coincidan con los de la BD. Si la clase dice `haVotado` pero la columna dice `ya_voto`, el mapeo genera confusión y errores. Con la unificación, el paso de "diagrama → código → BD" es directo y sin ambigüedades.

---

## Cambio 4: Nueva tabla `constancia_voto` (Soporte para QR)

**Archivos afectados:** `schema.sql`, `diagrama_er.puml`, `diagrama_bd.dbml`, `diagrama_clases_diseno.puml`

**¿Qué se hizo?**
Se creó una tabla y clase nuevas para almacenar las constancias de votación con código QR:

```sql
CREATE TABLE constancia_voto (
    id_constancia SERIAL PRIMARY KEY,
    id_docente INT NOT NULL,       -- Aquí SÍ va el docente (dice "Juan votó", no dice por quién)
    id_cargo INT NOT NULL,         -- Para qué cargo votó
    token_qr VARCHAR(255) UNIQUE,  -- UUID único que se codifica en el QR
    fecha_emision TIMESTAMP,
    FOREIGN KEY (id_docente) REFERENCES docente(id_docente),
    FOREIGN KEY (id_cargo) REFERENCES cargo_electoral(id_cargo)
);
```

**¿Por qué?**
Habíamos acordado implementar códigos QR en el caso de uso UC11 (Descargar Constancia de Voto), pero no había ninguna tabla que almacenara el token de verificación. Sin esta tabla, el QR no tendría nada que verificar.

**Flujo completo:**
1. El docente vota → El Stored Procedure genera un `token_qr` (UUID aleatorio) y lo guarda aquí.
2. El sistema genera un PDF con un QR que codifica la URL: `sistema.unp.edu.pe/verificar/abc123-uuid`.
3. Cualquier persona escanea el QR → El sistema busca `WHERE token_qr = 'abc123-uuid'` → Responde: *"✅ Válido"*.

> **Nota de seguridad:** Esta tabla tiene FK a `Docente` (a diferencia de `Voto`). Esto es correcto porque la constancia solo certifica que el docente **participó**, jamás revela **por quién votó**.

---

## Cambio 5: Nuevas tablas `usuario` y `sesion_activa` (Autenticación)

**Archivos afectados:** `schema.sql`, `diagrama_er.puml`, `diagrama_bd.dbml`, `diagrama_clases_diseno.puml`

**¿Qué se hizo?**
Se crearon 2 tablas para el módulo de autenticación:

```sql
-- Quién puede entrar al sistema
CREATE TABLE usuario (
    id_usuario SERIAL PRIMARY KEY,
    id_docente INT,                    -- Nullable: Admin no es docente
    username VARCHAR(100) UNIQUE,
    password_hash VARCHAR(255),        -- Nunca texto plano
    rol VARCHAR(50),                   -- ADMIN, COMITE, DOCENTE
    FOREIGN KEY (id_docente) REFERENCES docente(id_docente)
);

-- Control de sesiones activas
CREATE TABLE sesion_activa (
    id_sesion SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL,
    token VARCHAR(255) UNIQUE,         -- JWT o token de sesión
    fecha_inicio TIMESTAMP,
    fecha_expiracion TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
);
```

**¿Por qué?**
El frontend tenía login con `admin / 123` hardcodeado en React, pero no existía ninguna tabla en la BD para respaldar esa autenticación en producción. Cada actor del sistema (Administrador, Comité Electoral, Docente Elector, Docente Candidato) necesita credenciales reales.

**Detalles de diseño importantes:**
- `id_docente` es **nullable** en la tabla `usuario` porque el Administrador del sistema no necesariamente es un docente (puede ser personal de TI).
- El campo `rol` permite que el backend determine qué pantallas y funciones mostrar a cada usuario (ej: un DOCENTE no puede ver el panel del Comité).
- `password_hash` almacena la contraseña encriptada (nunca texto plano). Se usará BCrypt o similar.

---

## Cambio 6: Mejora del Stored Procedure `emitir_voto_transaccional`

**Archivo afectado:** `schema.sql`

**¿Qué se hizo?**
Se agregaron 2 validaciones nuevas y se integró la generación automática de la constancia QR:

```diff
 -- ANTES: Solo verificaba si ya votó
 -- DESPUÉS: Verifica habilitación + doble voto + genera constancia

+    -- 1. Verificar si el docente está HABILITADO (NUEVO)
+    IF NOT EXISTS (
+        SELECT 1 FROM padron_electoral 
+        WHERE id_cargo = p_id_cargo 
+        AND id_docente = p_id_docente 
+        AND habilitado_para_votar = TRUE
+    ) THEN
+        RAISE EXCEPTION 'El docente no está habilitado para votar en este cargo.';
+    END IF;

     -- 2. Verificar si ya votó (ya existía)

     -- 3. Marcar como votado (ya existía)

     -- 4. Insertar voto anónimo (ya existía)

+    -- 5. Generar constancia de voto con QR (NUEVO)
+    INSERT INTO constancia_voto (id_docente, id_cargo, token_qr)
+    VALUES (p_id_docente, p_id_cargo, gen_random_uuid()::VARCHAR);
```

**¿Por qué?**
- **Validación de habilitación:** Antes, el SP solo verificaba `ya_voto = TRUE`. Pero si un docente fue **deshabilitado a última hora** (ej: el Comité descubrió que tiene una sanción), el campo `habilitado_para_votar` estaría en `FALSE`, y aun así el SP anterior lo hubiera dejado votar. Ahora PostgreSQL lo bloquea antes de que llegue a insertar nada.
- **Generación automática de constancia:** La constancia QR se crea dentro de la **misma transacción atómica** que el voto. Esto garantiza que si el voto se insertó correctamente, la constancia existe. Si algo falla, PostgreSQL hace `ROLLBACK` de todo (voto + constancia) y el sistema queda en estado consistente.

---

## Resumen Visual de Tablas (Antes vs Después)

| Antes (11 tablas) | Después (15 tablas) |
|---|---|
| facultad | facultad |
| departamento | departamento |
| docente | docente |
| cargo_admin | cargo_admin |
| | **cargo_excluido_sorteo** ← NUEVA |
| proceso_electoral | proceso_electoral |
| cargo_electoral | cargo_electoral |
| candidato | candidato |
| padron_electoral | padron_electoral |
| mesa_electoral | mesa_electoral |
| miembro_mesa | miembro_mesa |
| voto | voto |
| | **constancia_voto** ← NUEVA |
| | **usuario** ← NUEVA |
| | **sesion_activa** ← NUEVA |
