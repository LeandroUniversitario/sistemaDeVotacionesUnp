# Resumen Ejecutivo de Cambios tras el Último Pull (23/11/2026)

Este documento detalla todas las modificaciones, nuevas funcionalidades, ajustes de base de datos, backend, frontend y artefactos RUP implementados en el repositorio del **Sistema de Elecciones UNP** tras el último `git pull` de la rama `main`.

---

## 1. Mapa General de Cambios

| # | Módulo / Componente | Caso de Uso | Tipo de Cambio | Archivos Principales |
|---|---------------------|-------------|----------------|----------------------|
| **1** | **Bitácora Electoral** | CUS19 | UI / UX | `PantallaBitacora.jsx`, `bitacora.css` |
| **2** | **Navegación CEUNP** | CUS09, CUS10 | UI / Accesibilidad | `DashboardPage.jsx` |
| **3** | **Padrón Docente Informática** | CUS02 | Base de Datos / Datos Reales | `actualizar_docentes_informatica.sql` |
| **4** | **Ponderación Estamentaria (Tercios)** | CUS14 | BD + Backend + Frontend + RUP | `15_ponderacion_tercios_ley30220.sql`, `Computo*.java`, `PantallaComputo.jsx`, `ActaComputo.js`, `diagrama_clases_diseno.puml`, `CUS14_Computar_Proclamar.md` |
| **5** | **Filtro de Docentes por Departamento** | CUS02, CUS18 | Frontend + Backend | `DocentesPage.jsx`, `DashboardPage.jsx`, `PadronPage.jsx`, `PantallaAdministrador.jsx`, `TeacherTable.jsx`, `PantallaMultas.jsx`, `AdministracionConsulta.java` |
| **6** | **Actualización de Diagramas DrawIO y PlantUML** | CUS02, CUS14, CUS18 | RUP / Modelado Arquitectónico | `.drawio` de clases, colaboración y secuencia + `.puml` de diseño y dominio |

---

## 2. Detalle de Cambios por Componente

### 2.1. Modal Emergente en Bitácora Electoral (`CUS19`)
* **Problema anterior:** Al presionar «Ver detalle» en un registro de la bitácora, la información se mostraba al pie de la tabla o requería scroll excesivo.
* **Solución implementada:**
  * Se diseñó un **modal emergente sobrepuesto (overlay centrado)** con fondo semitransparente oscuro (`backdrop-filter: blur(2px)`).
  * Visualización del payload en formato JSON formateado con resaltado de sintaxis, fecha/hora exacta, usuario, IP, módulo y acción.
  * Botones de acción: **"Copiar al portapapeles"** y **"Cerrar"** (o presionando la tecla `Escape`).
* **Archivos modificados:**
  * `frontend/src/pages/bitacora/PantallaBitacora.jsx`
  * `frontend/src/pages/bitacora/bitacora.css`

---

### 2.2. Accesos Rápidos para Simulación en Menú CEUNP (`CUS09`, `CUS10`)
* **Problema anterior:** Para simular la votación en una mesa, el usuario debía cerrar sesión y entrar con la cuenta del miembro de mesa sorteado para verificar electores o abrir la terminal de votación.
* **Solución implementada:**
  * Se habilitaron accesos directos en el menú lateral del rol **CEUNP**:
    * **"Verificar elector"** (`/verificar-elector`): Permite buscar docentes por DNI, escanear su credencial QR y habilitarlos para emitir el sufragio en la mesa.
    * **"Terminal de votación"** (`/terminal`): Permite simular el voto electrónico en la cédula digital.
* **Archivo modificado:**
  * `frontend/src/pages/DashboardPage.jsx`

---

### 2.3. Plana Docente Oficial del Departamento de Informática (`CUS02`)
* **Problema anterior:** El departamento 38 (Ingeniería Informática) contenía 29 docentes genéricos o de relleno que no coincidían con la nómina real de la UNP.
* **Solución implementada:**
  * Se eliminaron los docentes anteriores y sus cuentas vinculadas en `usuario`.
  * Se insertaron los **17 docentes oficiales** del Departamento Académico de Ingeniería Informática (Facultad de Ingeniería Industrial):
    1. ALVARADO TABACCHI, JORGE (DNI 02606057 - Asociado TC)
    2. CORREA MOROCHO, REUCHER ANDRÉS (DNI 02715290 - Principal DE)
    3. CRIOLLO GONZALES, PEDRO ANTONIO (DNI 02817835 - Principal DE)
    4. CRUZ YARLEQUÉ, WILFREDO (DNI 02635949 - Principal DE)
    5. FIESTAS BANCAYÁN, HÉCTOR WILMER (DNI 02775932 - Principal DE)
    6. IMÁN AGURTO, IVÁN DANIEL (DNI 02867046 - Principal DE)
    7. IPANAQUE SILVA, ROLANDO ELÍAS (DNI 40682528 - Auxiliar TC)
    8. LIZANA PUELLES, ESTHER YOLANDA (DNI 02810146 - Asociado TC)
    9. NIMA RAMOS, JONATHAN DAVID (DNI 42627674 - Auxiliar TP)
    10. PUICÓN ZAPATA, HOOWER AUGUSTO (DNI 03691805 - Asociado TC)
    11. REQUENA FLORES, RIGO FÉLIX (DNI 41183188 - Auxiliar TC)
    12. SAAVEDRA ARANGO, MOISÉS DAVID (DNI 02852230 - Auxiliar TP)
    13. SAAVEDRA YARLEQUÉ, LUIS ARMANDO (DNI 02875150 - Principal DE)
    14. SANDOVAL RIVERA, ARTURO (DNI 02875151 - Principal DE)
    15. SANDOVAL RIVERA, JORGE LUIS (DNI 02882200 - Principal DE)
    16. SILVA MORE, CÉSAR (DNI 02888402 - Auxiliar TC)
    17. VALLE RÍOS, VÍCTOR HUGO (DNI 02882310 - Auxiliar TC)
  * Para cada uno se creó su usuario con rol `DOCENTE` y contraseña inicial `Docente2026`.
* **Archivo creado:**
  * `base-de-datos/actualizar_docentes_informatica.sql`

---

### 2.4. Ponderación Estamentaria por Tercios (Art. 66 y 71 Ley 30220) (`CUS14`)

Conforme a la Ley Universitaria N.º 30220, la elección de Decanos y Rector es **ponderada por estamentos**:
$$\text{Puntaje Ponderado Final}_i = \left( \%Docentes_i \times \frac{2}{3} \right) + \left( \%Estudiantes_i \times \frac{1}{3} \right)$$

Para evitar tener que registrar 15,000 cuentas de estudiantes individuales, se implementó el modelo real de la ONPE/CEUNP: **Consolidación agregada de votos de actas estudiantiles**.

#### A. Base de Datos (MySQL)
* **Nueva tabla `computo_estudiantil`:**
  Registra la cantidad total de votos válidos emitidos por los estudiantes para cada lista admitida.
* **Nuevas columnas en `resultado_electoral`:**
  * `votos_docentes`: Votos obtenidos en las urnas electrónicas de profesores.
  * `votos_estudiantes`: Votos obtenidos del estamento estudiantil.
  * `pct_docente`: Porcentaje relativo obtenido en docentes.
  * `pct_estudiante`: Porcentaje relativo obtenido en estudiantes.
  * `pct_ponderado`: Porcentaje final ponderado aplicando la regla $\frac{2}{3} + \frac{1}{3}$.
* **Procedimientos Almacenados:**
  * `sp_registrar_votos_estudiantiles`: Guarda los votos estudiantiles ingresados por el CEUNP.
  * `sp_obtener_votos_estudiantiles`: Recupera los votos estudiantiles registrados para el proceso.
  * `sp_ejecutar_computo`: Actualizado para calcular la ponderación automática y determinar la lista ganadora evaluando el quórum y el porcentaje ponderado (`pct_ponderado > porcentaje_minimo_victoria`). Si no hay votos estudiantiles registrados, opera transparentemente como elección docente pura.
* **Archivo de migración:**
  * `base-de-datos/15_ponderacion_tercios_ley30220.sql`

#### B. Backend (Spring Boot)
* **`ComputoDto.java`:** Nuevos registros `VotoEstudiantil` y `GuardarVotosEstudiantes`.
* **`ComputoController.java`:** Endpoint seguro `POST /api/computo/procesos/{id}/votos-estudiantiles` protegido para rol `CEUNP`.
* **`ComputarProclamar.java`:** Método `guardarVotosEstudiantiles` para invocar el procedimiento de registro de votos de alumnos.
* **`ComputoConsulta.java`:** Métodos actualizados para devolver el consolidado y los resultados con las columnas de porcentajes docentes, estudiantiles y ponderados.

#### C. Frontend (React)
* **`PantallaComputo.jsx`:**
  * **Pestaña Consolidación:** Añadida la columna con campos input para que el CEUNP ingrese los votos estudiantiles por lista, mostrando en vivo el `% Doc (2/3)`, `% Est (1/3)` y `% Ponderado`. Incluye el botón **"Guardar votos estudiantiles"**.
  * **Pestaña Cómputo Oficial:** La tabla de resultados oficiales desglosa claramente ambos estamentos y resalta a la lista ganadora según la ponderación legal.
* **`ActaComputo.js`:**
  * El **Acta General de Sufragios** (imprimible en PDF con huella SHA-256 y QR) incluye el fundamento de los Arts. 66 y 71 de la Ley 30220 y la tabla estamentaria ponderada completa.

#### D. Artefactos RUP y Diagramas
* **`documentacion/CUS14_Computar_Proclamar.md`:**
  * Documentada la **RN37 (Ponderación Estamentaria Ley 30220)**.
  * Documentado el requerimiento **RF100 (Consolidación de Votos Estudiantiles)**.
  * Actualizada la tabla de endpoints y tablas de base de datos.
* **`diagramas/diagrama_clases_diseno.puml`:**
  * Incorporadas las clases `ComputoResultadoView` (Boundary), `ComputarProclamarController` (Control), `ComputoEstudiantil` y `ResultadoElectoral` (Entity) y `ComputoRepository` (Repository).

---

## 3. Estado de Compilación y Validación

* **Backend Spring Boot:**
  * Ejecución: `.\mvnw.cmd test-compile -q`
  * Resultado: **BUILD SUCCESS** (0 errores de compilación, JDK 21).
* **Frontend Vite / React:**
  * Ejecución: `npm run build`
  * Resultado: **Construcción exitosa** en 7.39s (0 errores, 110 módulos empaquetados).
* **Base de Datos MySQL:**
  * Script `15_ponderacion_tercios_ley30220.sql` ejecutado y verificado en la base `elecciones_unp`.

---

## 4. Filtro de Docentes por Departamento Académico (Interfaces Admin y Generales)

Se implementó el filtro por **Departamento Académico** en todas las vistas y componentes donde se consultan o administran listas de docentes:

### 4.1. Interfaz de Gestión de Docentes (`DocentesPage.jsx`)
- **Filtro desplegable**: Se agregó un `<select>` de Departamento Académico que lista los 44 departamentos oficiales de la UNP (`DEPARTAMENTOS` de `facultadesData.js`).
- **Filtrado reactivo**: Permite filtrar instantáneamente docentes por departamento, categoría (`PRINCIPAL`, `ASOCIADO`, `AUXILIAR`), estado (`ACTIVO`, `LICENCIA`, etc.) y texto libre.
- **Visualización mejorada**: La columna "Docente" ahora muestra tanto la facultad como su departamento académico resaltado (`Facultad · Departamento`).
- **Botón Limpiar filtros**: Restablece todos los criterios activos con un solo clic.

### 4.2. Habilitación del Módulo en Vista Administrador (`DashboardPage.jsx`)
- Se incorporó la sección **"Docentes"** en el menú de navegación del Administrador (`MENU_POR_ROL.ADMIN` y `SECCIONES_EXTRA_ROL.ADMIN`).
- Se amplió `loadData()` para que el Administrador también cargue la lista completa de docentes y pueda gestionar y filtrar directamente desde su sesión.

### 4.3. Padrón e Importación de Docentes (`PadronPage.jsx`)
- **Paso 2 ("Docentes registrados" para Admin / "Depurar padrón" para CEUNP)**:
  - Se agregó selector desplegable de departamento dinámico en la barra de herramientas (`.pd-toolbar`).
  - Filtrado en tiempo real cruzado con los estados de habilitación (`TODOS`, `HABILITADOS`, `INHABILITADOS`) y búsqueda por DNI/nombre.

### 4.4. Cuentas y Asignación de Roles (`PantallaAdministrador.jsx`)
- **Tabla de Cuentas y Roles**:
  - Se agregó filtro por departamento académico en la barra de filtros (`.mu-filtros`), permitiendo filtrar las cuentas de docentes por su departamento de adscripción.
  - La fila de cada cuenta ahora muestra `DNI · Facultad · Departamento`.
- **Selector de Docente para Creación/Edición de Cuentas (`SelectorDocente`)**:
  - Se incorporó un desplegable de departamento junto al buscador para localizar y asociar rápidamente docentes de un departamento específico al crear una cuenta.
- **Backend (`AdministracionConsulta.java`)**:
  - Se añadió `dp.nombre AS departamento` en la consulta `docentes()` con `LEFT JOIN departamento dp`.

### 4.5. Tabla Reutilizable de Docentes (`TeacherTable.jsx`)
- Se incorporó el filtro por departamento académico y la visualización de facultad y departamento en cada fila.

### 4.6. Reporte de Omisos y Multas (`PantallaMultas.jsx`)
- Se agregó el filtro por departamento académico en las pestañas de docentes omisos y multas generadas.

---

## 5. Actualización Integral de Diagramas (DrawIO y PlantUML)

Para mantener total coherencia entre el código implementado, la base de datos y la arquitectura RUP del proyecto, se modificaron y sincronizaron todos los diagramas afectados:

### 5.1. Diagrama de Clases UNP (`diagramas/clases_drawio/Diagrama de Clases UNP - relaciones y operaciones.drawio`)
1. **Entidad `resultado_electoral` (id `9wdsac9BY-kYzfjp-iKT-873`)**:
   - Se redimensionó la tabla para alojar los nuevos atributos y operaciones del cálculo ponderado (altura aumentada a 720px).
   - Se añadieron las columnas:
     - `votos_docentes INT NOT NULL DEFAULT 0`
     - `votos_estudiantes INT NOT NULL DEFAULT 0`
     - `factor_docente DECIMAL(5,4) NOT NULL DEFAULT 0.6667`
     - `factor_estudiante DECIMAL(5,4) NOT NULL DEFAULT 0.3333`
     - `porcentaje_ponderado DECIMAL(5,2) NULL`
   - Se agregaron las operaciones:
     - `+calcularPonderacionTercios(): void`
     - `+consolidarVotosEstudiantiles(): void`
2. **Nueva tabla `computo_estudiantil` (`tbl-computo-estudiantil`)**:
   - Ubicada en el módulo **M08 · Cómputo y proclamación** (`x="1020" y="6880" width="320" height="390"`).
   - Columnas: `id_computo_estudiantil (PK)`, `id_proceso (FK)`, `id_cargo (FK)`, `id_lista (FK)`, `votos_estudiantes`, `fecha_registro`.
   - Claves foráneas: `fk_cest_proceso`, `fk_cest_cargo`, `fk_cest_lista`.
   - Operaciones:
     - `+registrarVotosEstudiantiles(idProceso, votos): void`
     - `+obtenerPorProcesoCargo(idProceso, idCargo): List`
3. **Relación `computo_estudiantil` $\rightarrow$ `resultado_electoral` (`rel-cest-re`)**:
   - Conector de agregación con etiqueta `pondera (1/3)`.
4. **Reubicación de tablas adyacentes en M08**:
   - `dirimencia_empate` ajustada a `y="7330"`.
   - `calificacion_mesa` ajustada a `y="7990"`.
   - Contenedor del módulo **M08** ampliado a `height="2560.0"` evitando colisiones y manteniendo separación uniforme de 60px.
5. **Entidad `docente` (`9wdsac9BY-kYzfjp-iKT-27`)**:
   - Se añadió la operación `+filtrarPorDepartamento(idDepartamento): List<Docente>` (altura 930px).

### 5.2. Diagramas de Colaboración (Comunicación)
Archivos actualizados:
- `diagramas/colaboracion_drawio/CUS14_Computar_y_proclamar.drawio`
- `diagramas/colaboracion_drawio/TODOS_LOS_DIAGRAMAS_COLABORACION_UNP - corregido segun el sistema.drawio`
- `diagramas/colaboracion_drawio/TODOS_LOS_DIAGRAMAS_COLABORACION_UNP.drawio`

Modificaciones realizadas:
- Se incorporó la entidad `«entity» ComputoEstudiantil` (`p-ComputoEstudiantil`) en `(1280, 1840)` con su enlace `link-11` hacia `p-ComputarProclamar`.
- Se reordenó el flujo a **21 mensajes** secuenciales:
  - `7: consolidarVotosDocentes()` $\rightarrow$ `p-Voto`
  - `8: totalesDocentes` $\leftarrow$ `p-Voto`
  - `9: obtenerVotosEstudiantiles()` $\rightarrow$ `p-ComputoEstudiantil`
  - `10: votosEstudiantiles` $\leftarrow$ `p-ComputoEstudiantil`
  - `11: calcularParticipacion()` $\rightarrow$ `p-PadronElectoral`
  - `12: porcentajeParticipacion` $\leftarrow$ `p-PadronElectoral`
  - `13: validarQuorum()` $\rightarrow$ `p-ProcesoElectoral`
  - `14: quorumValidado` $\leftarrow$ `p-ProcesoElectoral`
  - `15: registrarComputoPonderado()` $\rightarrow$ `p-ResultadoElectoral`
  - `16: computoRegistrado` $\leftarrow$ `p-ResultadoElectoral`
  - `17: determinarGanador()` $\rightarrow$ `p-CargoElectoral`
  - `18: ganadorOSegundaVuelta` $\leftarrow$ `p-CargoElectoral`
  - `19: acreditarGanadora()` $\rightarrow$ `p-ListaElectoral`
  - `20: listaAcreditada` $\leftarrow$ `p-ListaElectoral`
  - `21: mostrarResultados()` $\leftarrow$ `p-ComputoResultado`

### 5.3. Diagramas de Secuencia
Archivos actualizados:
- `diagramas/secuencia_drawio/CUS14_Computar_y_proclamar.drawio`
- `diagramas/secuencia_drawio/TODOS_LOS_DIAGRAMAS_SECUENCIA_UNP.drawio`

Modificaciones realizadas:
- Se añadió la línea de vida y participante `part-ComputoEstudiantil` en `x="1400"` (eje en `x="1440"`).
- Se redistribuyeron los participantes subsiguientes (`PadronElectoral`, `ProcesoElectoral`, `ResultadoElectoral`, `CargoElectoral`, `ListaElectoral`) con espaciado regular de 220px hasta `x=2540`.
- Se implementaron los 21 mensajes síncronos y asíncronos reflejando la secuencia exacta de cómputo ponderado de tercios estamentarios.

### 5.4. Diagramas PlantUML (`.puml`)
- **`diagramas/diagrama_clases_diseno.puml`**:
  - Incorporadas las clases `ComputoEstudiantil` y `ResultadoElectoral` con atributos `votosDocentes`, `votosEstudiantes`, `pctDocente`, `pctEstudiante`, `pctPonderado`.
  - Agregado en `PadronController`: `+filtrarPorDepartamento(idDepartamento: Integer)`.
  - Agregado en `Docente`: atributo `idDepartamento: int` y métodos de búsqueda.
  - Agregado en `DocenteRepository`: `+listarDocentes(idDepartamento: Integer, busqueda: String)`.
  - Agregado en `ComputarProclamarController`: `+registrarVotosEstudiantiles()` y `+calcularPonderacionTercios()`.
- **`diagramas/diagrama_modelo_dominio_2_ejecucion.puml`**:
  - Se agregó la entidad `ComputoEstudiantil` y sus asociaciones `ComputoGeneral --> ComputoEstudiantil : consolida estudiantes (1/3)` y `ComputoGeneral --> ActaElectoral : consolida docentes (2/3)`.
  - Se añadió `departamentoAcadémico` a `Docente`.


