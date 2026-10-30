# CUS02 · Gestionar padrón electoral e importación de docentes

**Actores:** Administrador (`ADMIN`) y Comité Electoral Universitario (`CEUNP`)  
**Pantallas:**
- Administrador: menú «Padrón e importación» (Vista *«Importación y creación de usuarios docentes»*)
- CEUNP: menú «Padrón electoral» (Vista *«Depurar y aprobar padrón definitivo»*)
- CEUNP: menú «Docentes» (Vista *«Gestión de docentes»*)  
**Resultado:** Cuentas de usuario docentes creadas/actualizadas en el sistema y filas consolidadas en `padron_electoral` para cada proceso comicial (RN04).

---

## 1. Alcance y Propósito del Módulo

El caso de uso CUS02 abarca dos fases operativas complementarias según el rol del usuario:

1. **Creación Masiva e Importación de Usuarios Docentes (Rol: Administrador):**
   - Carga masiva de docentes vía archivo Excel (`.xlsx`) o CSV.
   - Creación automática y actualización (UPSERT) de registros en la tabla `docente` y generación de sus cuentas de usuario iniciales con credenciales provisionales en la tabla `usuario`.
   - Consulta rápida de docentes ya registrados mediante la opción *«Omitir, ya están registrados»*.

2. **Depuración y Aprobación del Padrón Electoral (Rol: CEUNP):**
   - Ejecución del motor de reglas electorales (RN03, RN05) para determinar la habilitación de sufragio de cada docente.
   - Aprobación y congelamiento del padrón definitivo vinculado al proceso electoral activo (CUS01), alimentando la tabla `padron_electoral` (RF03).
   - Generación de la vista `v_padron_detalle` con asignación por cargo y posterior distribución en mesas (CUS06/CUS08).

3. **Mantenimiento y Ficha de Docentes (Rol: CEUNP / Admin):**
   - Vista **«Gestión de docentes»** para consulta detallada de la ficha académica y edición individual.
   - Asignación estricta de **Facultades** (14 facultades) y **Departamentos Académicos** (44 departamentos) sincronizados con el catálogo oficial de la base de datos de la UNP.

---

## 2. Correspondencia de Componentes y Flujos

| Mensaje / Acción | Frontend | Backend |
|---|---|---|
| **1. Carga de archivo** | `PadronPage.subirArchivoPadron` (Paso Carga / Admin) | `POST /api/padron/importar` (multipart `archivo`, solo `ADMIN`) |
| **2. Parseo y validación** | Notificación y resumen de filas | `ImportarDocentes.leerDatos` → `ImportacionDocenteService` |
| **3. Registro masivo** | Tabla de resultados (nuevos, actualizados, errores) | `ImportacionDocenteService.registrarMasivo` (UPSERT en `docente` y creación en `usuario`) |
| **4. Omitir carga** | Visualización directa de docentes registrados | `PadronPage` (modo Admin, consulta `/api/padron/depurado`) |
| **5. Depurar padrón** | `PadronPage.depurarPadron` (Paso Depuración / CEUNP) | `POST /api/padron/depurar` (`FiltrarHabilitados.procesarReglas`) |
| **6. Aplicar reglas** | Tarjetas de habilitados vs inhabilitados con filtros | `PadronConsulta.MOTIVO_SQL` (evalúa RN03, RN05, completitud) |
| **7. Actualizar habilitación** | Actualización reactiva del estado electoral | `FiltrarHabilitados.actualizarHabilitacion` (`docente.habilitado_para_votar`) |
| **8. Aprobar padrón** | Modal de confirmación por proceso electoral | `POST /api/padron/procesos/{id}/aprobar` (`AprobarPadron.generarDefinitivo`) |
| **9. Insertar definitivo** | Generación de registros para votación | `sp_generar_padron` → inserción en `padron_electoral` |
| **10. Exportar padrón** | Descarga de CSV del padrón definitivo por proceso | `PadronPage.exportarCsv` desde `v_padron_detalle` |
| **11. Ficha del docente** | Modal con datos completos académicos y electorales | `DocentesPage` (consume `/api/docentes`) |
| **12. Edición académica** | Selectores en cascada Facultad → Departamento | `PUT /api/docentes/{id}` (`ElectoralService.actualizarDocente`) |

---

## 3. Interfaces de Usuario y Refactorización Implementada

### A. Vista «Importación y creación de usuarios docentes» (`PadronPage.jsx` - Rol Administrador)
- **Ruta de acceso:** Menú lateral «Padrón e importación».
- **Encabezado:** Título institucional *«Importación y creación de usuarios docentes»* con subtítulo:  
  *«Importe el padrón de docentes para crear o actualizar masivamente sus cuentas de usuario en el sistema.»*
- **Estructura visual:**
  - Se eliminó el indicador de pasos numéricos y las tarjetas de métricas electorales (habilitados/inhabilitados) por corresponder exclusivamente a la fase comicial del CEUNP.
  - **Zona de carga principal:** Componente drag-and-drop compatible con `.xlsx`, `.xls` y `.csv`.
  - **Columnas esperadas:** Lista de verificación de campos requeridos (DNI, Nombres, Apellidos, Categoría, Dedicación, Estado, Facultad, Departamento).
  - **Acciones inferiores:** Botones *«Plantilla CSV»*, *«Omitir, ya están registrados»* y *«Subir archivo»*.
  - **Modo Omitir:** Al pulsar *«Omitir, ya están registrados»*, la interfaz presenta la tabla de **Docentes registrados** (DNI, Docente, Categoría, Dedicación, Facultad, Estado) con botón de retorno *«Subir nuevo padrón»*, sin forzar acciones de depuración electoral.
  - **Panel lateral:** Resumen de resultados en tiempo real (nuevos registrados, cuentas actualizadas, advertencias y detalle de errores).

### B. Vista «Padrón electoral» (`PadronPage.jsx` - Rol CEUNP)
- **Ruta de acceso:** Menú lateral «Padrón electoral».
- **Encabezado:** Título *«Padrón electoral»* con subtítulo explicativo:  
  *«Gestione el padrón electoral: aplique reglas de depuración y apruebe el padrón definitivo para cada proceso electoral.»*
- **Flujo comicial en 2 pasos:**
  1. **Paso 1: Depurar padrón:**
     - Tarjetas métricas: *Docentes registrados*, *Habilitados para votar*, *Inhabilitados*, *Última depuración*.
     - Botón principal *«Depurar padrón»* (ejecuta reglas de habilitación en base de datos).
     - Tabla clasificatoria con pestañas (Todos, Habilitados, Inhabilitados), buscador y etiquetas con el motivo exacto de inhabilitación (RN03: Licencia/Suspendido, RN05: DNI inválido, etc.).
     - Botón de navegación único: *«Continuar a aprobar»* (se retiró el botón redundante de volver a importar).
  2. **Paso 2: Aprobar padrón definitivo:**
     - Selector de proceso electoral activo (en estado `CREADO` o `INSCRIPCION`).
     - Lista de verificación de precondiciones (cargos definidos, depuración vigente, ausencia de mesas instaladas).
     - Botón *«Aprobar padrón definitivo»* que consolida los electores por cargo comicial.
     - Tabla del padrón definitivo con buscador, filtro por cargo comicial y botón *«Exportar CSV»*.

### C. Vista «Gestión de docentes» (`DocentesPage.jsx` - Rol CEUNP)
- **Ruta de acceso:** Menú lateral «Docentes».
- **Encabezado:** Título *«Gestión de docentes»* con subtítulo:  
  *«Administración y mantenimiento del padrón de docentes: consulta de datos académicos, edición de facultades, departamentos y estados de habilitación.»*
- **Tabla general:** Listado paginado con búsqueda por nombre o DNI, filtros por categoría y estado, visualizando la Facultad debajo del nombre de cada docente.
- **Acciones de cabecera:** Botones *«＋ Nuevo docente»* y *«Gestionar padrón electoral →»*. Se eliminó el botón duplicado *«⬆ Importar Excel/CSV»*.
- **Modal «Ficha del docente» (Opción Ver):**
  - Cabecera con avatar estilizado con iniciales, nombre completo, DNI y badges de estado y habilitación para votar (*✓ Habilitado / ✕ Inhabilitado*).
  - Grilla simétrica de tarjetas de información:
    - **Facultad:** Nombre completo institucional (ej. *Facultad de Ingeniería Industrial*).
    - **Departamento Académico:** Nombre oficial (ej. *Ingeniería Informática*).
    - **Categoría:** *PRINCIPAL*, *ASOCIADO* o *AUXILIAR*.
    - **Dedicación:** Descripción legible (*Dedicación Exclusiva (DE)*, *Tiempo Completo (TC)*, *Tiempo Parcial (TP)*).
    - **Grado Académico:** *DOCTOR*, *MAGÍSTER*, *LICENCIADO*, etc.
    - **Correo Institucional:** Correo electrónico con enlace `mailto:`.
    - **Fecha de Ingreso:** Fecha de ingreso registrada en la UNP.
    - **ID Interno:** Identificador primario en la base de datos.
  - Botón de acceso directo a edición y botón de cierre en azul institucional.
- **Modal «Editar docente» y «Nuevo docente»:**
  - Selectores desplegables dinámicos en cascada para **Facultad** (14 opciones) y **Departamento Académico** (filtrado en tiempo real según la facultad seleccionada).
  - Eliminación de entradas numéricas manuales de IDs.
  - Validación de DNI de 8 dígitos y control de unicidad.

---

## 4. Catálogo Oficial de Facultades y Departamentos (`facultadesData.js`)

Para asegurar la integridad referencial con las tablas `facultad` y `departamento` de la base de datos MariaDB, el frontend cuenta con el módulo sincronizado:

- **14 Facultades Oficiales:**
  1. Facultad de Agronomía (ID: 1)
  2. Facultad de Arquitectura y Urbanismo (ID: 2)
  3. Facultad de Ciencias (ID: 3)
  4. Facultad de Ciencias Administrativas (ID: 4)
  5. Facultad de Ciencias Contables y Financieras (ID: 5)
  6. Facultad de Ciencias de la Salud (ID: 6)
  7. Facultad de Ciencias Sociales y Educación (ID: 7)
  8. Facultad de Derecho y Ciencias Políticas (ID: 8)
  9. Facultad de Economía (ID: 9)
  10. Facultad de Ingeniería Civil (ID: 10)
  11. Facultad de Ingeniería de Minas (ID: 11)
  12. Facultad de Ingeniería Industrial (ID: 12)
  13. Facultad de Ingeniería Pesquera (ID: 13)
  14. Facultad de Zootecnia (ID: 14)

- **44 Departamentos Académicos:** Mapeados exactamente con su `id_departamento`, `id_facultad` y nombre oficial.

---

## 5. Endpoints de la API REST

| Método | Ruta | Autorización | Propósito |
|---|---|---|---|
| `GET` | `/api/padron/resumen` | `ADMIN`, `CEUNP` | Métricas totales de docentes, fecha de última importación y depuración. |
| `POST` | `/api/padron/importar` | `ADMIN` | Subida y procesamiento de archivo Excel o CSV (UPSERT y cuentas). |
| `GET` | `/api/padron/depurado` | `ADMIN`, `CEUNP` | Consulta del padrón depurado con habilitación y motivo. |
| `POST` | `/api/padron/depurar` | `ADMIN`, `CEUNP` | Ejecución de las reglas de habilitación en base de datos. |
| `GET` | `/api/padron/procesos` | `ADMIN`, `CEUNP` | Listado de procesos electorales y estado de su padrón. |
| `GET` | `/api/padron/procesos/{id}` | `ADMIN`, `CEUNP` | Electores previstos vs aprobados por cargo y validación de requisitos. |
| `GET` | `/api/padron/procesos/{id}/electores` | `ADMIN`, `CEUNP` | Listado consolidado del padrón definitivo (`v_padron_detalle`). |
| `POST` | `/api/padron/procesos/{id}/aprobar` | `CEUNP` | Congelamiento y generación definitiva del padrón por proceso. |
| `GET` | `/api/docentes` | Autenticado | Listado general de docentes para el módulo de gestión. |
| `POST` | `/api/docentes` | `ADMIN`, `CEUNP` | Registro manual de un nuevo docente con facultad y departamento. |
| `PUT` | `/api/docentes/{id}` | `ADMIN`, `CEUNP` | Actualización de datos personales, académicos y adscripción de facultad/departamento. |
| `DELETE` | `/api/docentes/{id}` | `ADMIN`, `CEUNP` | Eliminación de docente (sujeta a restricciones de candidaturas activas). |

---

## 6. Reglas de Negocio Aplicadas

1. **RN03 (Condición del Docente):** Solo los docentes en estado `ACTIVO` obtienen `habilitado_para_votar = 1`. Los docentes en condición `LICENCIA`, `SUSPENDIDO` o `INACTIVO` quedan inhabilitados para votar, indicándose el motivo explícito.
2. **RN05 (Validación de Documento de Identidad):** El DNI debe ser estrictamente una cadena numérica de 8 dígitos.
3. **RN04 / RF03 (Padrón Electoral por Proceso y Cargo):** La aprobación consolida a los docentes habilitados pertenecientes a la jurisdicción del cargo (Universidad, Facultad o Departamento) cuya categoría esté habilitada para votar en dicho cargo.
4. **Regla de Integridad de Adscripción:** Ningún docente puede pertenecer a un departamento académico que no forme parte de la facultad asignada.
5. **Requisitos de Aprobación Definitiva:**
   - El proceso electoral debe encontrarse en estado `CREADO` o `INSCRIPCION`.
   - El proceso debe tener cargos comiciales configurados (CUS01).
   - El padrón debe haberse depurado con posterioridad a la última importación masiva realizada.
   - No deben existir mesas de sufragio creadas aún (la creación de mesas bloquea la regeneración del padrón).
   - Cada cargo comicial debe contar con al menos un elector previsto.
6. **Auditoría Centralizada:** Cada operación sensible (`IMPORTAR_DOCENTES`, `DEPURAR_PADRON`, `GENERAR_PADRON`, `CREAR_DOCENTE`, `EDITAR_DOCENTE`) registra automáticamente su evento en la tabla `log_auditoria` con usuario, fecha/hora y detalle JSON.

---

## 7. Verificación del Flujo de Trabajo

### Flujo Administrador (Creación masiva de cuentas):
1. Iniciar sesión como `admin` e ingresar al menú **«Padrón e importación»**.
2. Arrastrar el archivo `base-de-datos/100 Docentes.xlsx` o seleccionar la opción *«Omitir, ya están registrados»*.
3. Verificar en el panel lateral que se procesaron los registros y que se generaron las cuentas de acceso iniciales.

### Flujo CEUNP (Gestión académica y depuración electoral):
1. Iniciar sesión como `ceunp` e ingresar al menú **«Gestión de docentes»**:
   - Abrir la ficha de un docente para comprobar la visualización completa de Facultad y Departamento.
   - Editar un docente y comprobar los selectores en cascada Facultad → Departamento.
2. Ingresar al menú **«Padrón electoral»**:
   - En el paso de depuración, pulsar *«Depurar padrón»* y revisar los inhabilitados por RN03 o RN05.
   - Pulsar *«Continuar a aprobar»*, seleccionar la convocatoria vigente y pulsar *«Aprobar padrón definitivo»*.
   - Filtrar electores por cargo comicial y exportar el reporte en CSV.
