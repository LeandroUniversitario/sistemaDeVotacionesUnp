# 🔍 Análisis Cruzado: Documento Oficial vs Modelo Actual

Revisé minuciosamente el documento Word **"Documentacion_Sistema_Elecciones_Docentes_UNP.docx"** y lo contrasté con nuestros 4 artefactos técnicos (diagrama de clases, ER, DBML y SQL).

---

## 🔴 CRÍTICO: Conceptos del documento que NO están en nuestro modelo

### 1. El voto es por LISTA (Fórmula), no por candidato individual
- **Documento oficial (CUN03, Glosario):** *"Un candidato a Rector y dos a Vicerrectores que postulan juntos"* = Una **fórmula o lista**. El elector vota por la lista completa, no por personas sueltas.
- **Nuestro modelo actual:** La tabla `candidato` registra candidatos individuales y `voto.id_candidato_elegido` apunta a UN candidato.
- **Corrección necesaria:** Reemplazar/agregar una tabla `lista_electoral` (fórmula) que agrupe a los candidatos. El voto debe apuntar a `id_lista`, no a `id_candidato`.

### 2. Faltan las ACTAS electorales (Instalación, Sufragio, Escrutinio)
- **Documento oficial (CUN09, Glosario):** *"Conjunto de tres actas: instalación, sufragio y escrutinio. Se elaboran en tres ejemplares lacrados."* Además, el documento menciona la **huella de integridad (hash)** para validar que un acta no fue alterada.
- **Nuestro modelo actual:** No existe ninguna tabla ni clase para actas. Nuestro UC8 dice "Generar resultados y actas" pero no hay estructura de datos detrás.
- **Corrección necesaria:** Crear tabla `acta_electoral` con: `id_acta`, `id_mesa`, `tipo` (INSTALACION/SUFRAGIO/ESCRUTINIO), `contenido`, `hash_integridad`, `qr_verificacion`, `fecha`.

### 3. Faltan los PERSONEROS (Fiscalizadores de cada lista)
- **Documento oficial (CUN05, Art. 28-35):** Cada lista acredita un personero general, un alterno y personeros de mesa. Son actores clave del proceso.
- **Nuestro modelo actual:** No hay tabla ni clase para personeros.
- **Corrección necesaria:** Crear tabla `personero` con: `id_personero`, `id_lista`, `id_docente`, `tipo` (GENERAL/ALTERNO/MESA), `id_mesa` (nullable).

### 4. Falta el concepto de TACHA (diferente de Impugnación)
- **Documento oficial (CUN04):** Una tacha es un cuestionamiento **escrito** de un docente del padrón contra candidatos, **antes** de la elección. Es distinta de la impugnación (que ocurre durante el escrutinio).
- **Nuestro modelo actual:** Solo tenemos UC9 "Resolver impugnación". No hay tabla ni flujo para tachas.
- **Corrección necesaria:** Crear tabla `tacha` con: `id_tacha`, `id_docente_denunciante`, `id_candidato`, `motivo`, `estado` (PENDIENTE/FUNDADA/INFUNDADA), `fecha`.

### 5. Falta el QUÓRUM de participación (>60%)
- **Documento oficial (Glosario):** *"Participación mínima de más del 60% de los docentes del padrón para que la elección sea válida."*
- **Nuestro modelo actual:** No hay ningún campo ni lógica para verificar quórum.
- **Corrección necesaria:** Agregar campo `quorum_minimo` a `proceso_electoral` (ej: 60.0) y un SP o vista SQL que calcule el porcentaje de participación en tiempo real.

### 6. Falta la SEGUNDA VUELTA
- **Documento oficial (Glosario):** *"Nueva votación entre las dos listas más votadas si ninguna alcanza el mínimo legal."*
- **Nuestro modelo actual:** `proceso_electoral` no contempla este escenario.
- **Corrección necesaria:** Agregar campo `tipo` a `proceso_electoral` (PRIMERA_VUELTA / SEGUNDA_VUELTA) y `id_proceso_padre` (FK a sí misma) para vincular la segunda vuelta con la primera.

### 7. Falta el SORTEO DEL ORDEN de listas en la cédula
- **Documento oficial (CUN06):** *"El CEUNP sortea en acto público el orden de las listas en la cédula."*
- **Nuestro modelo actual:** La tabla `candidato` / lista no tiene campo `orden_cedula`.
- **Corrección necesaria:** Agregar `orden_cedula: INT` a la nueva tabla `lista_electoral`.

---

## 🟡 Inconsistencias de terminología (Alinear con el documento)

### 8. "Comité Electoral" → debe ser "CEUNP"
- **Documento oficial:** Siempre usa **CEUNP** (Comité Electoral de la Universidad Nacional de Piura).
- **Nuestro modelo:** Usamos "Comité Electoral" genérico en los diagramas de casos de uso.
- **Corrección:** Renombrar el actor a "CEUNP" en el diagrama de casos de uso para alinear con el documento oficial.

### 9. Los miembros de mesa son 3 titulares + 3 suplentes (no 5..8)
- **Documento oficial (CUN06):** *"Sortea tres titulares y tres suplentes por mesa"*.
- **Nuestro diagrama de clases:** `MesaElectoral "1" *-- "5..8" MiembroMesa`.
- **Corrección:** Cambiar la cardinalidad a `"6"` (3 titulares + 3 suplentes = 6 exactos).

### 10. "Inscribir candidatura" → debe ser "Inscribir lista de candidatos"
- **Documento oficial (CUN03):** El proceso registra **listas**, no candidatos sueltos.
- **Nuestro diagrama de casos de uso:** UC1 dice "Inscribir candidatura".
- **Corrección:** Renombrar a "Inscribir lista de candidatos".

---

## 🟢 Lo que nosotros agregamos y el documento NO contradice (Está bien)

### 11. LogAuditoria (IP separada del voto) ✅
El documento menciona "Bitácora de auditoría" en el glosario como *"Registro inmutable de las acciones realizadas en el sistema"*. Nuestra tabla `log_auditoria` cumple exactamente este requisito.

### 12. ConstanciaVoto con QR ✅
La decisión D06 del documento dice: *"El sistema debe emplear QR"*. Nuestra tabla `constancia_voto` con `token_qr` cumple con esto perfectamente.

---

## 📋 Plan de acción priorizado

| # | Prioridad | Cambio | Archivos afectados |
|---|---|---|---|
| 1 | 🔴 Crítico | Crear tabla/clase `lista_electoral` y cambiar `voto` para que apunte a lista | Todos |
| 2 | 🔴 Crítico | Crear tabla/clase `acta_electoral` con hash de integridad y QR | Todos |
| 3 | 🔴 Crítico | Crear tabla/clase `personero` | Todos |
| 4 | 🟡 Alto | Crear tabla/clase `tacha` | Todos |
| 5 | 🟡 Alto | Agregar quórum mínimo y tipo de vuelta a `proceso_electoral` | SQL, ER, DBML |
| 6 | 🟡 Alto | Agregar `orden_cedula` a la nueva tabla `lista_electoral` | SQL, ER, DBML |
| 7 | 🟡 Medio | Renombrar "Comité Electoral" → "CEUNP" en casos de uso | Casos de uso |
| 8 | 🟡 Medio | Corregir cardinalidad de MiembroMesa a 6 | Clases |
| 9 | 🟡 Medio | Renombrar UC1 a "Inscribir lista de candidatos" | Casos de uso |

> **¿Deseas que aplique TODOS estos cambios a los archivos?** Son cambios estructurales importantes que alinearán completamente tu modelo con el reglamento oficial de la UNP.
