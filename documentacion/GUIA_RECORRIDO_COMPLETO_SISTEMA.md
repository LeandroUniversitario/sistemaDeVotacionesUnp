# Guía de recorrido completo · Sistema de Elecciones Docentes UNP

Recorrido de punta a punta del sistema tal como está implementado hoy (CUS00 a CUS21), con los pasos en pantalla y datos listos para copiar y pegar. Todos los docentes son los reales del archivo `base-de-datos/100 Docentes.xlsx`.

> **Actualizada el 20/11/2026** después del recorrido real con 1 100 docentes (ver `documentacion/HALLAZGOS_RECORRIDO_ELECCION_2026-11-20.md`). Cambios principales: la clave inicial de los docentes ya no es el DNI, el sorteo no es reproducible, la votación solo se abre el día del sufragio con la inscripción cerrada, y una lectura de QR equivocada ya no anula el acta.

La guía se armó leyendo el código actual del repositorio: menús de `frontend/src/pages/DashboardPage.jsx`, controles y validaciones de `backend/src/main/java/pe/unp/elecciones/electoral/**` y procedimientos de `base-de-datos/00_script_unico_elecciones_unp.sql`. Donde un resultado depende de un cálculo del sistema (sorteo, multas, porcentajes), se indica el valor esperado y cómo comprobarlo.

---

## 0. Antes de empezar

### 0.1 Resumen del escenario

| Dato | Valor |
|---|---|
| Proceso | Elección de Rector y Vicerrectores UNP 2027-2031 |
| Cargo | Rector y Vicerrectores (nivel UNIVERSIDAD, fórmula de 3) |
| Votan / postulan | Votan PRINCIPAL, ASOCIADO y AUXILIAR · Postulan solo PRINCIPAL |
| Quórum mínimo | **10 %** (para poder demostrarlo con 12 votos; el valor real del reglamento es 60 %) |
| Padrón | 85 electores (los 100 docentes menos 8 en LICENCIA y 7 SUSPENDIDOS) |
| Mesas | 1 mesa (Mesa 001, Biblioteca Central, 85 electores) |
| Listas | A «Integridad Universitaria», B «Renovación Académica», C «Unidad Docente» (la C cae por tacha) |
| Votos | 12: Lista A 7, Lista B 4, en blanco 1 |
| Resultado esperado | Lista A elegida con 63,64 % de los votos válidos; participación 14,12 % |

### 0.2 Cuentas que se usan

| Quién | Usuario | Contraseña inicial | Contraseña nueva (primer ingreso) | Rol final |
|---|---|---|---|---|
| Administrador | `admin` | `Admin2026*` | (no se pide) | ADMIN |
| Comité electoral | `ceunp` | `Ceunp2026` | `CeunpUNP2026` | CEUNP |
| Docentes importados | ver anexo (ej. `jsuarez`) | **clave provisional aleatoria** (CSV de la importación) o la que fije el ADMIN | `Docente2026` | DOCENTE |

Reglas del código que conviene saber:

- Al importar el Excel, cada docente recibe una cuenta: **usuario = inicial del primer nombre + primer apellido sin tildes** (`jsuarez`, `lpena`…). Si el usuario ya existe se agrega un número: `cbenites2`, `gipanaque2`, `cyovera2`, `dcherres2`, `esilva2`.
- **La contraseña inicial NO es el DNI** (auditoría A3): es una clave provisional aleatoria que se muestra una sola vez al terminar la importación y se descarga en CSV desde «Padrón electoral». Guarde ese CSV. Si lo perdió, el ADMIN restablece la clave de la cuenta en **Cuentas y roles → Restablecer contraseña** (puede escribir una clave provisional o dejar que el sistema genere una). En esta guía, donde dice «primer ingreso», use la clave provisional que corresponda.
- En el primer ingreso el docente **debe cambiar la contraseña** (mínimo 8 caracteres, distinta de la actual). Para la demo use `Docente2026` en todos.
- Las contraseñas que escribe el ADMIN para otras cuentas deben tener al menos 8 caracteres y combinar letras y números.
- Los roles cambian solos: al grabar el sorteo, los sorteados pasan de DOCENTE a **MIEMBRO_MESA**; al acreditar un personero pasa a **PERSONERO**; al publicar los resultados todos vuelven a DOCENTE. Si una cuenta tenía la sesión abierta, cierre sesión y vuelva a entrar para ver el menú del rol nuevo.

### 0.3 Docentes con un papel en el recorrido

| Papel | Docente | DNI | Usuario |
|---|---|---|---|
| Lista A · Rector | Juan Carlos Mendoza Pérez | `03681001` | `jmendoza` |
| Lista A · Vicerrectora Académica | Teresa de Jesus Gomez Sandoval | `03681029` | `tgomez` |
| Lista A · Vicerrector de Investigación | Ivan Danelgi Iman Agurto | `03681070` | `iiman` |
| Lista B · Rector | Luis Fernando Farfán Zapata | `03681008` | `lfarfan` |
| Lista B · Vicerrectora Académica | Rosa Elvira Espinoza Garcia | `03681035` | `respinoza` |
| Lista B · Vicerrector de Investigación | Gonzalo Nicolas Requena Tavara | `03681044` | `grequena` |
| Lista C · Rector (tachado) | Walter Enrique Zevallos Ramos | `03681026` | `wzevallos` |
| Lista C · Vicerrectora Académica | Katia Paola Roman Silva | `03681041` | `kroman` |
| Lista C · Vicerrector de Investigación | Nestor Daniel Silva Cherres | `03681077` | `nsilva` |
| Denunciante de la tacha · Personero GENERAL Lista A | Jeremy Aaron Suárez Taboada | `03681072` | `jsuarez` |
| Personero de MESA Lista A | Leandro Emmanuel Peña Ávila | `03681073` | `lpena` |
| Personero de MESA Lista B | Jean Carlos Lucano Zurita | `03681071` | `jlucano` |
| Presidenta de mesa (sorteo) | Giannina Maria Talledo Saavedra | `03681049` | `gtalledo` |
| Secretaria de mesa (sorteo) | Zoila Marina Chunga Dioses | `03681061` | `zchunga` |
| Vocal (sorteo, no asiste) | Carlos Alberto Benítes Juárez | `03681005` | `cbenites` |
| 1.er suplente (asume como vocal) | Cesar Augusto Coronado Talledo | `03681016` | `ccoronado` |
| 2.º suplente | Roxana Elizabeth Tavara Pasapera | `03681057` | `rtavara` |
| 3.er suplente | Fanny del Socorro Sullon Chero | `03681067` | `fsullon` |

> **Atención:** el sorteo ahora es de compromiso y revelación: el servidor genera un secreto, publica su compromiso (SHA-256) y la semilla final combina ese secreto con el aporte que escribe el CEUNP (`UNP-2026`). Por eso **los miembros de mesa cambian en cada base** y la tabla de abajo es solo un ejemplo. Use los nombres que muestre su pantalla y, para entrar con esas cuentas, restablezca su clave desde Cuentas y roles.

### 0.4 Preparar la base, el backend y el frontend

0. **Base que ya existía:** si no quiere borrar nada, actualice la estructura con `base-de-datos/actualizar_sin_borrar.sql` (no borra registros; incluye la migración de Credenciales QR del 12/11 y las correcciones del 20/11). Sin esa actualización la pantalla de Credenciales QR no abre.
1. Si tiene datos que quiere conservar, expórtelos antes. El script único **borra y vuelve a crear** la base `elecciones_unp`. En su base local hay ahora dos procesos (uno FINALIZADO y otro en INSCRIPCION); el sistema no permite convocar un proceso nuevo mientras haya otro en curso, por eso esta guía parte de una base limpia.
2. Cree la base desde cero (XAMPP encendido):

```bash
C:/xampp/mysql/bin/mysql.exe -u root < "base-de-datos/00_script_unico_elecciones_unp.sql"
```

   Resultado: 14 facultades, 44 departamentos, parámetros y el usuario `admin`. Todavía no hay docentes.

3. Levante el backend (puerto 8080):

```bash
cd backend && mvn spring-boot:run
```

4. Levante el frontend (puerto 5173):

```bash
cd frontend && npm install && npm run dev
```

5. Abra `http://localhost:5173`.

**Consejo para la jornada:** la sesión se guarda en `sessionStorage`, que es independiente en cada pestaña. Puede tener a la presidenta de mesa en una pestaña, el terminal de votación en otra y al CEUNP en una tercera, cada una con su propio inicio de sesión.

---

## 1. CUS00 · Iniciar sesión

1. En `http://localhost:5173` escriba:
   - Usuario: `admin`
   - Contraseña: `Admin2026*`
2. Pulse **Ingresar al Sistema**. (El enlace «Consultar resultados y verificar actas» de esa pantalla abre el portal público sin iniciar sesión.) Entra al menú del ADMIN: Resumen, Cuentas y roles, Parámetros del sistema, Respaldo de la base, Padrón e importación, Excepciones Sorteo, Bitácora, Resultados y actas.

Pruebas de error (opcional):

- Usuario `admin`, contraseña `x` → «Credenciales incorrectas…».
- Tras **5** intentos fallidos la cuenta queda bloqueada **15 minutos** (parámetros `SEGURIDAD_INTENTOS_MAXIMOS` y `SEGURIDAD_BLOQUEO_MINUTOS`). Hágalo con una cuenta de docente, no con `admin`; se desbloquea en CUS18 (paso 25.3).

---

## 2. CUS18 · Preparar cuentas y parámetros (ADMIN)

### 2.1 Crear la cuenta del CEUNP

Menú **Cuentas y roles** → nueva cuenta:

| Campo | Valor |
|---|---|
| Usuario | `ceunp` |
| Rol | `CEUNP` |
| Docente asociado | (ninguno) |
| Contraseña | `Ceunp2026` |

El rol CEUNP no exige docente asociado; DOCENTE, PERSONERO y MIEMBRO_MESA sí.

### 2.2 Desactivar el control horario (solo para la demo)

Menú **Parámetros del sistema**, grupo JORNADA. Cambie y escriba un motivo:

| Parámetro | Valor nuevo | Motivo |
|---|---|---|
| `INSTALACION_CONTROL_HORARIO` | `0` | `Demostración: instalar la mesa a cualquier hora` |
| `SUFRAGIO_CONTROL_HORARIO` | `0` | `Demostración: cerrar el sufragio a cualquier hora` |

Hágalo **ahora**: los parámetros de la jornada quedan bloqueados mientras un proceso está en VOTACION. Sin esto la mesa solo se instala de 09:00 a 12:00 del día de la elección y el sufragio solo se cierra desde la hora de fin.

Deje como están: `UIT` = 5150.00, `MULTA_ELECTOR_OMISO_PCT` = 2.5, `MULTA_MIEMBRO_MESA_OMISO_PCT` = 3.0, `ELECTORES_POR_MESA` = 200.

---

## 3. CUS02 · Importar y depurar el padrón docente (ADMIN)

1. Menú **Padrón e importación** → **Subir padrón de docentes**.
2. Arrastre `base-de-datos/100 Docentes.xlsx` (máximo 5 MB, .xlsx o .csv). Si el archivo está abierto en Excel, ciérrelo antes.
3. Resultado esperado: «… 100 docentes nuevos, 0 actualizados». Se crean 100 cuentas de rol DOCENTE.
   - Los departamentos del Excel que no coinciden letra por letra se asignan por coincidencia parcial dentro de la facultad: «Arquitectura y Urbanismo» → Arquitectura, «Enfermería» → Enfermería Materno Perinatal, «Agronomía y Fitotecnia» → Agronomía y Fitotécnia.
4. **Continuar a depurar** → depurar. Resultado esperado: 85 habilitados y 15 inhabilitados (RN03: solo vota el docente ACTIVO).
   - LICENCIA (8): 03681002, 03681014, 03681027, 03681040, 03681053, 03681068, 03681084, 03681098.
   - SUSPENDIDO (7): 03681007, 03681021, 03681034, 03681048, 03681062, 03681078, 03681092.

El padrón **definitivo** del proceso se aprueba más adelante (paso 6), cuando ya exista la convocatoria.

---

## 4. CUS21 · Cambiar contraseña (primer ingreso de un docente)

1. Cierre sesión. Ingrese con:
   - Usuario: `jsuarez`
   - Contraseña: su clave provisional (del CSV de la importación o la que fijó el ADMIN)
2. El sistema abre la pantalla obligatoria de cambio de contraseña. Escriba la actual (la provisional) y la nueva `Docente2026` (dos veces).
3. Entra al menú del DOCENTE: Resumen, Listas postulantes, Mi pase de votación QR, Presentar tacha, Mis multas, Resultados y actas.

Repita este primer ingreso con cada docente cuando lo necesite (siempre: usuario del anexo, contraseña provisional, nueva = `Docente2026`). Para cambiar la contraseña de forma voluntaria después, use el engranaje → **Configuración de mi cuenta**.

Haga lo mismo con la cuenta del comité: usuario `ceunp`, contraseña `Ceunp2026`, nueva `CeunpUNP2026`.

---

## 5. CUS01 · Convocatoria y cronograma (CEUNP)

Ingrese como `ceunp` / `CeunpUNP2026`. Menú **Convocatoria y cronograma** → **Nueva convocatoria**.

### 5.1 Datos del proceso y cronograma

El sistema exige: convocatoria < límite de inscripción < inicio del sufragio < fin; inicio y fin el **mismo día**; el inicio en el futuro, y la convocatoria entre **30 y 45 días** antes del sufragio (RN02). Con fecha de hoy 01/11/2026:

| Campo | Valor |
|---|---|
| Nombre | `Elección de Rector y Vicerrectores UNP 2027-2031` |
| Fecha de convocatoria | `01/11/2026` |
| Límite de inscripción de listas | `20/11/2026 18:00` |
| Inicio del sufragio | `06/12/2026 08:00` |
| Fin del sufragio | `06/12/2026 15:00` |
| Quórum mínimo (%) | `10` |

Si lo hace otro día: convocatoria = hoy, sufragio = hoy + 35 días, límite de inscripción entre ambos.

### 5.2 Agregar el cargo

**Agregar cargo** → elija «Rector y Vicerrectores» (elección por fórmula completa, RN10):

| Campo | Valor |
|---|---|
| Nivel | UNIVERSIDAD |
| Categorías que votan | PRINCIPAL, ASOCIADO, AUXILIAR |
| Categorías que postulan | PRINCIPAL |

### 5.3 Publicar

**Revisar y publicar** → confirmar. El proceso pasa de CREADO a **INSCRIPCION** y el cronograma queda congelado. En una base nueva este es el proceso **id 1** (se usa en el paso 13).

---

## 6. CUS02 · Aprobar el padrón definitivo (CEUNP)

Menú **Padrón electoral** → paso 3 → elija el proceso → **aprobar**.

Requisitos que muestra la pantalla: proceso en CREADO o INSCRIPCION, con cargos, padrón depurado después de la última importación, sin mesas aún y con electores en cada cargo. Resultado esperado: «Padrón definitivo aprobado…: 85 electores con 85 registros de votación».

---

## 7. CUS03 · Inscripción de listas (CEUNP)

Menú **Inscripción de listas** → elija el proceso → **Inscribir lista**.

Requisitos que valida el sistema para cada candidato (RN09): docente ACTIVO y habilitado, categoría que puede postular (PRINCIPAL), grado **DOCTOR** y al menos **5 años** en la categoría, sin estar en otra lista, sin ser personero ni miembro de mesa. Al escribir el DNI aparece la lista de requisitos con OK / FALLA.

### Lista A

| Campo | Valor |
|---|---|
| Cargo | Rector y Vicerrectores |
| Nombre | `Lista A - Integridad Universitaria` |
| Símbolo | `Libro abierto azul` |
| Plan de gobierno | `https://unp.edu.pe/elecciones/2027/lista-a/plan.pdf` |

| Rol | DNI | Docente |
|---|---|---|
| Rector | `03681001` | Juan Carlos Mendoza Pérez (Doctor, Principal desde 2008) |
| Vicerrector Académico | `03681029` | Teresa de Jesus Gomez Sandoval (Doctor, Principal desde 2003) |
| Vicerrector de Investigación | `03681070` | Ivan Danelgi Iman Agurto (Doctor, Principal desde 2005) |

### Lista B

| Campo | Valor |
|---|---|
| Nombre | `Lista B - Renovación Académica` |
| Símbolo | `Antorcha verde` |
| Plan de gobierno | `https://unp.edu.pe/elecciones/2027/lista-b/plan.pdf` |

| Rol | DNI | Docente |
|---|---|---|
| Rector | `03681008` | Luis Fernando Farfán Zapata |
| Vicerrector Académico | `03681035` | Rosa Elvira Espinoza Garcia |
| Vicerrector de Investigación | `03681044` | Gonzalo Nicolas Requena Tavara |

### Lista C

| Campo | Valor |
|---|---|
| Nombre | `Lista C - Unidad Docente` |
| Símbolo | `Estrella dorada` |
| Plan de gobierno | `https://unp.edu.pe/elecciones/2027/lista-c/plan.pdf` |

| Rol | DNI | Docente |
|---|---|---|
| Rector | `03681026` | Walter Enrique Zevallos Ramos |
| Vicerrector Académico | `03681041` | Katia Paola Roman Silva |
| Vicerrector de Investigación | `03681077` | Nestor Daniel Silva Cherres |

La hoja de vida es opcional (ej. `https://unp.edu.pe/cv/03681001.pdf`).

### Pruebas de rechazo (opcional, en una vacante libre)

| DNI | Docente | Falla esperada |
|---|---|---|
| `03681004` | Ana Patricia Castro Silva | GRADO: es MAESTRO y se exige DOCTOR |
| `03681014` | Victor Hugo Navarro Sullón | ACTIVO: está en LICENCIA |
| `03681072` | Jeremy Aaron Suárez Taboada | CATEGORIA: es AUXILIAR |
| `03681001` (en la Lista B) | Juan Carlos Mendoza Pérez | RN11: ya está en la Lista A |

Los docentes (cualquier rol) ven las listas en **Listas postulantes**.

---

## 8. CUS04 · Tachas

### 8.1 Presentar la tacha (DOCENTE)

Ingrese como `jsuarez` / `Docente2026` → **Presentar tacha**:

| Campo | Valor |
|---|---|
| DNI del docente denunciante | `03681072` |
| Candidato a tachar | Walter Enrique Zevallos Ramos · Lista C (Rector) |
| Fundamento | `El candidato mantiene una sanción administrativa vigente impuesta por la Resolución Rectoral N.° 0915-2026-R, lo que le impide postular según el Reglamento de Elecciones.` |

La tacha solo se presenta en etapa de INSCRIPCION y dentro del plazo. En **Mis tachas** queda PENDIENTE.

### 8.2 Resolver la tacha (CEUNP)

`ceunp` → **Tachas** → bandeja «Pendientes» → abra la tacha:

| Campo | Valor |
|---|---|
| Fallo | Fundada |
| Fundamento de la resolución | `Se verificó en Secretaría General que la sanción se encuentra vigente. Se declara FUNDADA la tacha conforme al Reglamento de Elecciones.` |

Resultado: Zevallos queda EXCLUIDO y toda la **Lista C queda TACHADA** (RN12: la inscripción es en bloque). `jsuarez` ve el fallo en **Mis tachas**.

Una lista con tachas pendientes no se puede calificar; resuelva todas antes del paso 9.

---

## 9. CUS20 · Calificar listas inscritas (CEUNP)

**Inscripción de listas** → abra cada lista y califíquela:

- Lista A → **Admitir**.
- Lista B → **Admitir**.
- La Lista C ya está TACHADA y no se califica.

(Si prefiere probar el rechazo, puede excluir una lista; pide «Motivo de exclusión (obligatorio)». No lo haga en este recorrido.)

---

## 10. CUS06 · Sorteos (CEUNP)

Menú **Sorteos**, elija el proceso.

### 10.1 Orden de la cédula (pestaña de cédula)

En el cargo «Rector y Vicerrectores», semilla `CEDULA-2026` → sortear. El orden es ascendente por SHA-256(semilla | id de la lista). Resultado esperado: **1.º Lista A, 2.º Lista B**.

### 10.2 Conformar la mesa (pestaña de mesas)

| Campo | Valor |
|---|---|
| Electores por mesa (máximo) | `200` |
| Ubicación (RN08) | `Biblioteca Central` |

Resultado: **1 mesa (001)** con los 85 electores. Universo esperado: 85 habilitados, **6 impedidos** por RN20 (los candidatos de las listas A y B; los tres de la Lista C quedan EXCLUIDOS al caer la lista por la tacha, RN12), **79 elegibles**.

### 10.3 Sortear los miembros de mesa

1. Semilla del sorteo: `UNP-2026`.
2. **Vista previa** (no graba): muestra el universo de elegibles y el compromiso del sorteo, sin nombres (los nombres solo se conocen al sortear). Ejemplo de un resultado posible para la Mesa 001:

| Orden | Cargo | Docente | DNI | Usuario |
|---|---|---|---|---|
| 1 | Presidente | Giannina Maria Talledo Saavedra | `03681049` | `gtalledo` |
| 2 | Secretario | Zoila Marina Chunga Dioses | `03681061` | `zchunga` |
| 3 | Vocal | Carlos Alberto Benítes Juárez | `03681005` | `cbenites` |
| 4 | Suplente | Cesar Augusto Coronado Talledo | `03681016` | `ccoronado` |
| 5 | Suplente | Roxana Elizabeth Tavara Pasapera | `03681057` | `rtavara` |
| 6 | Suplente | Fanny del Socorro Sullon Chero | `03681067` | `fsullon` |

3. **Realizar el sorteo** → confirmar. Las 6 cuentas pasan a rol **MIEMBRO_MESA**. El cargo es irrenunciable: la mesa ya no se vuelve a sortear (RN19).

---

## 11. CUS05 · Acreditar personeros (CEUNP)

Menú **Personeros** → elija el proceso → elija la lista → **Solicitar acreditación** (escriba el DNI; se muestran los requisitos).

| Lista | DNI | Docente | Tipo | Mesa |
|---|---|---|---|---|
| Lista A | `03681072` | Jeremy Aaron Suárez Taboada | GENERAL | — |
| Lista A | `03681073` | Leandro Emmanuel Peña Ávila | MESA | 001 |
| Lista B | `03681071` | Jean Carlos Lucano Zurita | MESA | 001 |

Cada lista tiene un cupo GENERAL, uno ALTERNO y uno de MESA por mesa. Al acreditarse, la cuenta pasa a rol **PERSONERO**.

Pruebas de rechazo (opcional):

| DNI | Falla esperada |
|---|---|
| `03681049` (Giannina Talledo) | RN20: es miembro de mesa |
| `03681001` (Juan Carlos Mendoza) | RN21: es candidato |
| `03681002` (María Elena Ruiz) | No está ACTIVO (LICENCIA) |
| Segundo GENERAL en la Lista A | La lista ya tiene un personero GENERAL |
| Lista C | La lista está TACHADA y no acredita personeros |

---

## 12. CUS07 · Credenciales y códigos QR

### 12.1 Emisión por el CEUNP

`ceunp` → **Credenciales y QR**, elija el proceso. Hay tres pestañas: ELECTOR, MIEMBRO_MESA y PERSONERO.

1. **MIEMBRO_MESA**: emita los fotochecks de los 6 miembros (botón de emitir pendientes o seleccionándolos).
2. **PERSONERO**: emita las credenciales de `jsuarez`, `lpena` y `jlucano`.
3. **ELECTOR**: emita los pases de los electores que quiera (o todos los pendientes).

Pestañas **Verificar QR** (lee un código) e **Historial** (emisiones y revocaciones). Para revocar, pide un motivo, ej. `El titular reportó la pérdida del fotocheck`.

### 12.2 Vista del titular

- Docente: `kdioses` (DNI `03681074`, primer ingreso → `Docente2026`) → **Mi pase de votación QR** → genera y descarga su pase.
- Miembro de mesa: `gtalledo` → **Mi fotocheck de miembro (RF56)**.
- Personero: `lpena` → **Mi credencial de personero**.
- El QR abre `http://<host>:5173/credencial/<código>`, una página pública con los datos del titular.

---

## 13. Simular el día de la elección

La fecha del sufragio quedó 35 días en el futuro (RN02) y el sistema solo admite votos entre el inicio y el fin del sufragio. Para hacer la jornada hoy, mueva el cronograma a hoy y abra la votación.

> En «Convocatoria y cronograma» el CEUNP tiene el botón **«Abrir la votación»** (`PATCH /api/procesos/{id}/estado`). Valida: plazo de inscripción **vencido**, que sea **el día del sufragio** y antes de la hora de fin (desde el 20/11/2026), padrón generado, cada cargo con al menos una lista ADMITIDA, orden de cédula sorteado y mesas con sus 6 miembros. Con `INSTALACION_CONTROL_HORARIO = 0` no se exige el día, pero sí el cierre de la inscripción. Por eso primero se mueven las fechas (paso 1) y después se abre la votación (paso 2).

**Paso 1 · mover las fechas** (en phpMyAdmin → SQL, o en consola):

```sql
USE elecciones_unp;
UPDATE proceso_electoral
   SET fecha_limite_inscripcion = NOW() - INTERVAL 2 HOUR,
       fecha_inicio             = NOW() - INTERVAL 1 HOUR,
       fecha_fin                = CONCAT(CURDATE(), ' 23:59:00')
 WHERE id_proceso = 1;
```

**Paso 2 · abrir la votación.** Opción A, por la API con la cuenta del CEUNP (queda en la bitácora con el usuario `ceunp`), en PowerShell:

```powershell
$t = (Invoke-RestMethod -Method Post -Uri http://localhost:8080/api/auth/login -ContentType 'application/json' -Body '{"username":"ceunp","password":"CeunpUNP2026"}').token
Invoke-RestMethod -Method Patch -Uri http://localhost:8080/api/procesos/1/estado -Headers @{ Authorization = "Bearer $t" } -ContentType 'application/json' -Body '{"estado":"VOTACION"}'
```

Opción B, por SQL:

```sql
CALL sp_cambiar_estado_proceso(1, 'VOTACION', NULL);
```

No haga la jornada cerca de la medianoche: el fin del sufragio queda a las 23:59 de hoy.

---

## 14. CUS08 · Instalar la mesa (MIEMBRO_MESA)

Pestaña 1: ingrese como `gtalledo` / `03681049` (primer ingreso → `Docente2026`). Menú **Instalar mesa** → Mesa 001.

**1. Conformación de la mesa** (tabla de miembros, «Con DNI»):

| Miembro | Acción | DNI |
|---|---|---|
| Giannina Talledo (Presidente) | Con DNI → Registrar (primero ella misma) | `03681049` |
| Zoila Chunga (Secretario) | Con DNI → Registrar | `03681061` |
| Carlos Benítes (Vocal) | **No asistió** | — |
| Cesar Coronado (Suplente 1) | Con DNI → Registrar | `03681016` |

El 1.er suplente presente **asume el cargo de vocal** de forma automática. Los otros dos suplentes se pueden dejar sin registrar. (Un reemplazante externo solo se admite si faltan titulares y suplentes.) Si el DNI no coincide, el sistema rechaza la llegada (RN30). También se puede leer el fotocheck QR con «Escanear credencial QR (RF56)».

**2. Credenciales de personeros** → **Continuar con personeros**:

| Personero | DNI |
|---|---|
| Leandro Peña (Lista A) | `03681073` |
| Jean Carlos Lucano (Lista B) | `03681071` |

Regístrelos como presentes. Esto es necesario para el paso 17: solo un personero presente en la mesa puede impugnar votos (RN24).

**3. Material electoral (RF57)**: marque todo como **Conforme**.

| Campo | Valor |
|---|---|
| Cantidad de cédulas recibidas (RF59) | `85` |
| El presidente firmó las cédulas en el reverso | ✔ |
| Observaciones de la instalación | `El vocal titular no se presentó; asume el primer suplente.` |

**4. Instalar la mesa** → confirmar. Mensaje: «Mesa instalada. Se emitió y firmó el Acta de Instalación; el sufragio está habilitado». Imprima o guarde el acta (trae QR y huella SHA-256).

Flujos alternos que existen (no se usan aquí): **Declarar no instalada** (pide motivo, RF58) y, para el CEUNP, **Evaluación de nulidad (RF60)** de una mesa no instalada.

---

## 15. CUS09 y CUS10 · Verificar elector y emitir el voto

### 15.1 Conectar el terminal de votación

Pestaña 2 (nueva pestaña en `http://localhost:5173`): ingrese como `zchunga` / `03681061` (primer ingreso → `Docente2026`). Menú **Terminal de votación** → **Conectar este equipo como terminal de votación** → Mesa 001.

### 15.2 Ciclo de cada elector

En la pestaña 1 (`gtalledo`) → **Verificar elector**:

1. **Identificar elector**: escriba el DNI (o escanee el pase QR).
2. **Comparar y confirmar**: revise nombre y foto y habilite al elector en el terminal libre.
3. En la pestaña 2 (terminal) el elector marca su opción → **Confirme su elección** → confirmar. Se imprime la cédula y aparece «Su voto fue registrado». Responda que la cédula salió bien.
4. (Opcional) En la pestaña 1, botón **Constancia** del elector.

Votos de la demo (12):

| # | DNI | Elector | Voto |
|---|---|---|---|
| 1 | `03681049` | Giannina Maria Talledo Saavedra | Lista A |
| 2 | `03681061` | Zoila Marina Chunga Dioses | Lista B |
| 3 | `03681016` | Cesar Augusto Coronado Talledo | Lista A |
| 4 | `03681072` | Jeremy Aaron Suárez Taboada | Lista A |
| 5 | `03681073` | Leandro Emmanuel Peña Ávila | Lista A |
| 6 | `03681071` | Jean Carlos Lucano Zurita | Lista B |
| 7 | `03681001` | Juan Carlos Mendoza Pérez | Lista A |
| 8 | `03681008` | Luis Fernando Farfán Zapata | Lista B |
| 9 | `03681074` | Karina Elizabeth Dioses Purizaca | Lista A |
| 10 | `03681045` | Yessica Yanet Sandoval Ipanaque | Lista B |
| 11 | `03681028` | Oscar Eduardo Saavedra Nole | Voto en blanco |
| 12 | `03681089` | Armando Jose Chero Pasapera | Lista A |

Totales: **Lista A 7, Lista B 4, en blanco 1**. El terminal no registra voto nulo (RN25).

Pruebas (opcional):

| DNI | Resultado esperado |
|---|---|
| `03681002` (María Elena Ruiz, LICENCIA) | NO_FIGURA: no está en el padrón. No vota. |
| `03681001` otra vez | YA_VOTO: el elector ya votó. Se registra la incidencia. |

En la misma pantalla están **Anular**, **Rehabilitar** y **Rechazo** (incidencias RF66) y el padrón de la mesa, que muestra quién votó, nunca por quién.

---

## 16. CUS11 · Cerrar el sufragio (MIEMBRO_MESA)

`gtalledo` → **Cerrar sufragio** → Mesa 001:

1. **Cerrar la votación** → confirmar (hábiles 85, votaron 12).
2. **Electores que no votaron (RF75)** → marcar los 73 como **NO VOTÓ** → confirmar. La marca no se puede quitar.
3. **Continuar con el acta** → Datos del acta de sufragio (RF76):

| Campo | Valor |
|---|---|
| Cédulas no utilizadas | `73` |
| Firmas en la lista física | `12` |
| Observaciones | `Sufragio sin incidencias; el vocal titular no se presentó.` |

4. Firman la presidenta, la secretaria y los personeros presentes. Se emite el **Acta de Sufragio** con QR (se muestra solo esta vez) y huella SHA-256. **Copie el token del QR** si quiere usarlo en el paso 23.

---

## 17. CUS12 · Escrutinio y conciliación (MIEMBRO_MESA)

`gtalledo` → **Realizar escrutinio** → Mesa 001.

1. **Contar las cédulas del ánfora** → cédulas contadas en el ánfora: `12` → continuar con el conteo.
2. **Votos impugnados (paso 4 · A4)** → registrar:

| Campo | Valor |
|---|---|
| Personero que impugna | Leandro Emmanuel Peña Ávila (Lista A) |
| Cargo de la cédula | Rector y Vicerrectores |
| Motivo | `La cédula de la Lista B tiene una marca adicional fuera del recuadro.` |

   La cédula se aparta y se cuenta como IMPUGNADA hasta que se resuelva.

3. **Conteo manual por lista (RF79)** (lo ingresa la secretaria o la presidenta):

| Opción | Votos |
|---|---|
| Lista A | `7` |
| Lista B | `3` (la cuarta cédula de B está impugnada) |
| Votos en blanco | `1` |
| Votos nulos | `0` |
| Votos impugnados | `1` (lo llena el sistema) |

   La línea «Votos impugnados» la completa la pantalla; si usa la API, envíela también (`opcion: IMPUGNADO`). El sistema compara con el conteo digital y con los 12 electores que votaron. Debe indicar que coincide (las cédulas impugnadas faltan en su opción hasta resolverse). Si muestra «A3: el conteo manual difiere del digital», revise los números y regístrelos otra vez.

4. **Confirmar el escrutinio (RF85)**: marque a los personeros que firman y **deje vacías las observaciones si no hubo incidencias**: cualquier texto (incluso «sin incidencias») marca el acta como OBSERVADA y el CEUNP deberá calificar la mesa con una resolución antes del cómputo. Se emite el **Acta de Escrutinio** (QR + SHA-256).
5. **Entrega de actas y material al CEUNP (RF86, RF87)**:

| Campo | Valor |
|---|---|
| Recibe por el CEUNP | `Mg. Rosa Isabel Sullon Ipanaque - Secretaría del CEUNP` |
| Copias simples para personeros | `2` |
| Padrón de la mesa con la lista de firmas | ✔ |
| Material electoral | ✔ |
| Observación | `El ánfora se entrega lacrada.` |

El escrutinio es ininterrumpido e irreversible (RN26).

---

## 18. CUS13 · Impugnaciones y apelaciones

### 18.1 Decisión de la mesa (primera instancia, MIEMBRO_MESA)

`gtalledo` → **Impugnaciones** (o desde el escrutinio) → Impugnación N.º 1 → Decisión de la mesa (RN23):

| Campo | Valor |
|---|---|
| Miembros a favor de la impugnación | `0` |
| Miembros en contra | `3` |
| La cédula impugnada va a | Lista B |
| Fundamento | `La cédula lleva la firma del presidente y una sola marca dentro del recuadro de la Lista B; la marca adicional está fuera de la cédula. Es válida.` |

### 18.2 Apelación (PERSONERO)

Ingrese como `lpena` / `03681073` (primer ingreso → `Docente2026`). Menú **Impugnar votos y apelar** → la impugnación → Apelar la decisión de la mesa (RF81):

| Campo | Valor |
|---|---|
| Fundamento de la apelación | `La marca adicional no permite identificar con certeza la voluntad del elector; el voto debe declararse nulo.` |

El plazo para apelar es de 24 horas (`IMPUGNACION_PLAZO_APELACION_HORAS`). Mientras corre el plazo o la apelación está pendiente, el cómputo queda bloqueado.

### 18.3 Fallo del CEUNP (segunda y última instancia)

`ceunp` → **Impugnaciones y apelaciones** → bandeja → la apelación:

| Campo | Valor |
|---|---|
| N.º de resolución | `001-2026-CEUNP` |
| Miembros del Pleno presentes | `5` |
| Votos a favor de la apelación | `1` |
| Votos en contra | `4` |
| Opción final | Lista B (la misma que fijó la mesa) |
| Fundamento del fallo | `Revisada la cédula, la marca dentro del recuadro de la Lista B identifica la voluntad del elector (Art. 53). Se confirma la decisión de la mesa.` |

El fallo es inapelable (RN36). La cédula vuelve a Lista B: **Lista A 7, Lista B 4, en blanco 1**.

---

## 19. CUS14 (parte 1) · Concluir la votación (CEUNP)

`ceunp` → **Cómputo y proclamación** → elija el proceso → «La votación del proceso sigue abierta» → **Concluir la votación** → confirmar. El proceso pasa a **CERRADO**.

---

## 20. CUS15 · Nulidades (CEUNP)

La nulidad parcial solo se plantea con el proceso CERRADO y **antes del cómputo**, sobre una mesa que funcionó y cerró. En este recorrido se registra y se declara infundada, para no anular la única mesa.

`ceunp` → **Nulidades y segunda vuelta** → nulidad parcial:

| Campo | Valor |
|---|---|
| Mesa | 001 |
| Causal | `ADMISION_INDEBIDA` |
| Origen | Personero → Jean Carlos Lucano Zurita (Lista B) |
| Sustento | `Se habría admitido a votar a un elector sin verificar su DNI físico.` |
| Pruebas | `Declaración del personero de mesa de la Lista B.` |

Resolución:

| Campo | Valor |
|---|---|
| Decisión | INFUNDADA |
| N.º de resolución | `002-2026-CEUNP` |
| Miembros del Pleno | `5` |
| Votos a favor / en contra **de la decisión elegida** (INFUNDADA) | `4` / `1` |
| Fundamento | `El registro de asistencia muestra que los doce electores fueron identificados con DNI o QR; no se acredita la causal invocada.` |

Ojo con la diferencia: en el fallo de la apelación (paso 18.3) los votos son **a favor de la apelación**; en nulidades son **a favor de la decisión** que elige el Pleno.

Causales que acepta el sistema: parcial (Art. 64) `INSTALACION_IRREGULAR`, `FRAUDE_MESA`, `ADMISION_INDEBIDA`, `ACTA_NO_AUTENTICA`, `OTRA_CAUSAL`; total (Art. 65) `FRAUDE`, `COHECHO`, `SOBORNO`, `INTIMIDACION`, `VIOLENCIA`, `PARTICIPACION_INSUFICIENTE`. Una nulidad FUNDADA se comunica a `SUNEDU`, `ASAMBLEA_UNIVERSITARIA`, `CONSEJO_UNIVERSITARIO`, `PORTAL` o `EL_PERUANO`.

La segunda vuelta (RN33) no aplica aquí porque la Lista A supera el 50 % de los votos válidos.

---

## 21. CUS14 (parte 2) · Cómputo, proclamación y publicación (CEUNP)

`ceunp` → **Cómputo y proclamación**:

1. **Instalar la sesión de cómputo**:

| Campo | Valor |
|---|---|
| Lugar de la sesión | `Sala de sesiones del CEUNP - Pabellón Administrativo` |
| Miembros del CEUNP presentes | `5` (quórum `CEUNP_QUORUM_PLENO`) |
| Observaciones | `Sesión pública con presencia de personeros.` |

   Marque la asistencia de los personeros `jsuarez`, `lpena` y `jlucano`.

2. Revise las mesas y sus tres actas (instalación, sufragio, escrutinio). Marcar un acta como dudosa y comprobarla con su QR es opcional. Si al comprobarla el QR leído no corresponde pero el contenido está íntegro (huella SHA-256 correcta), aparece **«Volver a leer el QR»** para corregir la lectura; solo si el contenido fue alterado la mesa queda para nulidad.
3. **Cómputo oficial** → ejecutar. Resultado esperado:

| Dato | Valor |
|---|---|
| Electores hábiles | 85 |
| Votaron | 12 |
| Participación | 14,12 % (> quórum 10 %) |
| Lista A | 7 votos = 63,64 % de los válidos → **ELEGIDO** |
| Lista B | 4 votos = 36,36 % |
| En blanco | 1 |

   Con quórum 60 % el mismo cómputo daría SIN_QUORUM y la nulidad A1 (RN31).

4. **Proclamación de resultados**:

| Campo | Valor |
|---|---|
| N.º de resolución | `RES-CEUNP-003-2026` |
| Miembros del Pleno | `5` |
| Presidente del CEUNP que proclama | `Dr. Francisco Javier Seminario Pasapera` |
| Fundamento | `Realizado el cómputo general, la Lista A supera el 50 % de los votos válidos.` |

   La proclamación no se puede deshacer.

5. **Publicar** en el portal. Al publicar, las cuentas de los personeros y miembros de mesa **vuelven a rol DOCENTE**.

---

## 22. CUS16 · Omisos y multas (CEUNP)

`ceunp` → **Omisos y multas** → elija el proceso.

1. **Generar multas**. Resultado esperado (UIT S/ 5 150):

| Motivo | Cantidad | Monto unitario | Subtotal |
|---|---|---|---|
| OMISO_VOTACION (2,5 % UIT) | 73 | S/ 128,75 | S/ 9 398,75 |
| OMISO_MESA (3 % UIT, vocal titular Carlos Benítes) | 1 | S/ 154,50 | S/ 154,50 |
| **Total** | **74** | | **S/ 9 553,25** |

   Carlos Benítes tiene las dos multas: no instaló la mesa y no votó.

2. **Emitir la resolución** (desde aquí las multas quedan fijas):

| Campo | Valor |
|---|---|
| N.º de resolución | `004-2026-CEUNP` |
| Miembros del Pleno | `5` |
| Fundamento | `Se determinan las multas a electores omisos y miembros de mesa inasistentes conforme al Art. 67 y 68 del Reglamento.` |

3. **Notificar**: medio `CORREO_INSTITUCIONAL`, documento `Oficio Múltiple N.° 010-2026-CEUNP`.
4. **Justificación** de la multa OMISO_MESA de Carlos Benítes (`03681005`):

| Campo | Valor |
|---|---|
| Tipo | JUSTIFICACION |
| Causal | SALUD |
| Sustento | `Presentó descanso médico por el día de la elección.` |
| Documento | `Certificado médico N.° 4521-2026` |
| Decisión | ADMITIDA |
| N.º de resolución | `005-2026-CEUNP` |
| Miembros del Pleno | `5` |
| Fundamento | `El certificado médico acredita el impedimento.` |

5. **Pago** de la multa OMISO_VOTACION de Roxana Tavara (`03681057`): recibo `REC-000123`, fecha de hoy, observación `Pago en Tesorería UNP`.

Vista del docente: `rtavara` (primer ingreso `03681057` → `Docente2026`) → **Mis multas**. Cada multa y resolución tiene QR de verificación pública.

Otras causales de justificación: `DUELO`, `COMISION_SERVICIO`, `LICENCIA`, `CASO_FORTUITO`, `FALLECIMIENTO`, `ERROR_PADRON`, `OTRA`.

---

## 23. CUS17 · Resultados y verificación de actas

1. Cualquier usuario → **Resultados y actas** (CEUNP: «Resultados y verificación de actas»): resultados por lista, participación y actas del proceso.
2. Verificar un acta: pegue el token del QR de un acta (por ejemplo el del Acta de Sufragio del paso 16) en la verificación. El sistema recalcula la huella SHA-256 y confirma que el acta es auténtica.
3. Portal público, sin iniciar sesión: `http://localhost:5173/resultados`. Los QR de las actas apuntan a `http://<host>:5173/verificar/<token>`.

---

## 24. CUS19 · Consultar la bitácora (ADMIN)

`admin` → **Bitácora**:

1. Filtre por usuario `ceunp` y un rango de fechas de hoy. Verá, entre otras: PUBLICAR_CONVOCATORIA, RESOLVER_TACHA, ACREDITAR_PERSONERO, SORTEO de mesas, PUBLICAR_RESULTADOS, GENERAR_MULTAS.
2. Filtre por usuario `admin`: IMPORTAR_DOCENTES, cambios de parámetros, LOGIN_SUCCESS y LOGIN_FAILED.
3. Abra un registro para ver su detalle.
4. **Verificar** la cadena de sellos: confirma que ningún registro fue alterado (la tabla es inmutable por triggers).
5. **Exportar** (máximo `BITACORA_EXPORTACION_MAX` = 20 000 registros).

La bitácora nunca guarda por quién votó cada elector.

---

## 25. CUS18 · Administración (cierre del recorrido, ADMIN)

1. **Respaldo de la base**: requiere arrancar el backend con la variable `RESPALDO_CLAVE` (al menos 16 caracteres; ver README), porque el archivo se cifra. Sin ella el sistema responde «defina en el servidor la variable RESPALDO_CLAVE». Generar respaldo con motivo `Respaldo posterior a la proclamación`, descargar el archivo y **verificar** su integridad (SHA-256). Se guarda en la carpeta `backend/respaldos`.
2. **Parámetros**: vuelva `INSTALACION_CONTROL_HORARIO` y `SUFRAGIO_CONTROL_HORARIO` a `1`. Cada parámetro guarda su historial y se puede restaurar.
3. **Cuentas y roles**: desbloquee la cuenta que bloqueó en CUS00, restablezca una contraseña, desactive una cuenta (pide motivo) y revise la actividad de un usuario.
4. **Excepciones Sorteo**: catálogo de cargos de autoridad que impiden ser miembro de mesa (RN20).

---

## 26. Volver a empezar

- Para repetir el recorrido con los mismos docentes y cuentas:

```bash
C:/xampp/mysql/bin/mysql.exe -u root elecciones_unp < "base-de-datos/02_limpiar_datos_electorales.sql"
```

  Borra procesos, listas, mesas, votos y actas, pero conserva docentes, usuarios y parámetros. Los roles y contraseñas que ya cambió se mantienen, y el sorteo puede variar si los roles no vuelven a DOCENTE.

- Para dejarlo todo como al inicio, vuelva a ejecutar el script único (paso 0.4) y reimporte el Excel.

---

## Anexo · Los 100 docentes del Excel

Usuario = el que crea la importación. Contraseña inicial = la provisional aleatoria del CSV de la importación (la columna DNI es solo el documento del docente). Solo los ACTIVO entran al padrón.

| DNI | Usuario | Docente | Categoría | Grado | Estado | Facultad / Departamento |
|---|---|---|---|---|---|---|
| `03681001` | `jmendoza` | Juan Carlos Mendoza Pérez | PRINCIPAL (DE) | DOCTOR | ACTIVO | Ingeniería Industrial / Ingeniería Informática |
| `03681002` | `mruiz` | María Elena Ruiz Delgado | ASOCIADO (TC) | DOCTOR | LICENCIA | Ciencias / Matemática |
| `03681003` | `jramos` | Jorge Luis Ramos Flores | AUXILIAR (TP) | MAESTRO | ACTIVO | Ciencias Administrativas / Administración General |
| `03681004` | `acastro` | Ana Patricia Castro Silva | PRINCIPAL (DE) | MAESTRO | ACTIVO | Ciencias Contables y Financieras / Contabilidad General |
| `03681005` | `cbenites` | Carlos Alberto Benítes Juárez | PRINCIPAL (DE) | MAESTRO | ACTIVO | Agronomía / Agronomía y Fitotecnia |
| `03681006` | `rsalazar` | Rosa María Salazar Vega | ASOCIADO (TC) | MAESTRO | ACTIVO | Ciencias de la Salud / Clínico Quirúrgico |
| `03681007` | `pmorales` | Pedro José Morales Prado | AUXILIAR (TP) | MAESTRO | SUSPENDIDO | Ingeniería de Minas / Ingeniería de Petróleo |
| `03681008` | `lfarfan` | Luis Fernando Farfán Zapata | PRINCIPAL (DE) | DOCTOR | ACTIVO | Derecho y Ciencias Políticas / Derecho |
| `03681009` | `calban` | Carmen Rosa Albán Peña | ASOCIADO (TC) | MAESTRO | ACTIVO | Economía / Economía |
| `03681010` | `mguerrero` | Miguel Ángel Guerrero Neira | AUXILIAR (TP) | MAESTRO | ACTIVO | Arquitectura y Urbanismo / Arquitectura y Urbanismo |
| `03681011` | `svilela` | Silvia Elizabeth Vilela Yamunaqué | PRINCIPAL (DE) | MAESTRO | ACTIVO | Ingeniería Civil / Ingeniería Civil |
| `03681012` | `rojeda` | Ricardo Manuel Ojeda Dioses | ASOCIADO (TC) | MAESTRO | ACTIVO | Zootecnia / Producción Animal |
| `03681013` | `dcalle` | Diana Marcela Calle Calle | AUXILIAR (TP) | MAESTRO | ACTIVO | Ingeniería Pesquera / Ingeniería Pesquera |
| `03681014` | `vnavarro` | Victor Hugo Navarro Sullón | PRINCIPAL (DE) | DOCTOR | LICENCIA | Ciencias Sociales y Educación / Educación |
| `03681015` | `pyarleque` | Patricia Janet Yarlequé Medina | ASOCIADO (TC) | MAESTRO | ACTIVO | Ingeniería Industrial / Ingeniería Industrial |
| `03681016` | `ccoronado` | Cesar Augusto Coronado Talledo | AUXILIAR (TP) | MAESTRO | ACTIVO | Ciencias / Física |
| `03681017` | `gipanaque` | Gladys Noemí Ipanaqué Chero | PRINCIPAL (DE) | DOCTOR | ACTIVO | Ciencias Administrativas / Administración Aplicada |
| `03681018` | `mtimana` | Manuel Jesús Timaná Vilchez | ASOCIADO (TC) | DOCTOR | ACTIVO | Ciencias Contables y Financieras / Finanzas, Tributación y Auditoría |
| `03681019` | `mvalladolid` | Mónica Isabel Valladolid Cherres | AUXILIAR (TP) | MAESTRO | ACTIVO | Agronomía / Sanidad Vegetal |
| `03681020` | `fseminario` | Francisco Javier Seminario Pasapera | PRINCIPAL (DE) | DOCTOR | ACTIVO | Ciencias de la Salud / Salud Pública |
| `03681021` | `schunga` | Sofia Beatriz Chunga Purizaca | ASOCIADO (TC) | MAESTRO | SUSPENDIDO | Ingeniería de Minas / Ingeniería Química |
| `03681022` | `greto` | Gabriel Antonio Reto Silva | AUXILIAR (TP) | MAESTRO | ACTIVO | Derecho y Ciencias Políticas / Ciencias Políticas |
| `03681023` | `vpazos` | Veronica Lucia Pazos Lazo | PRINCIPAL (DE) | DOCTOR | ACTIVO | Economía / Economía |
| `03681024` | `hpulache` | Hector Raul Pulache Cordova | ASOCIADO (TC) | MAESTRO | ACTIVO | Arquitectura y Urbanismo / Arquitectura y Urbanismo |
| `03681025` | `ncarhuapoma` | Nancy Yolanda Carhuapoma Yovera | AUXILIAR (TP) | MAESTRO | ACTIVO | Ingeniería Civil / Ingeniería Civil |
| `03681026` | `wzevallos` | Walter Enrique Zevallos Ramos | PRINCIPAL (DE) | DOCTOR | ACTIVO | Zootecnia / Salud Animal |
| `03681027` | `cpalacios` | Claudia Maria Palacios Tavara | ASOCIADO (TC) | MAESTRO | LICENCIA | Ingeniería Pesquera / Ingeniería Pesquera |
| `03681028` | `osaavedra` | Oscar Eduardo Saavedra Nole | AUXILIAR (TP) | MAESTRO | ACTIVO | Ciencias Sociales y Educación / Ciencias de la Comunicación |
| `03681029` | `tgomez` | Teresa de Jesus Gomez Sandoval | PRINCIPAL (DE) | DOCTOR | ACTIVO | Ingeniería Industrial / Investigación de Operaciones |
| `03681030` | `ragurto` | Roberto Carlos Agurto Iman | ASOCIADO (TC) | DOCTOR | ACTIVO | Ciencias / Estadística |
| `03681031` | `imontero` | Isabel Cristina Montero Riofrio | AUXILIAR (TP) | MAESTRO | ACTIVO | Ciencias Administrativas / Administración General |
| `03681032` | `jfiestas` | Julio Cesar Fiestas Chunga | PRINCIPAL (DE) | MAESTRO | ACTIVO | Ciencias Contables y Financieras / Contabilidad Aplicada |
| `03681033` | `kzapata` | Karen Lisseth Zapata Vilchez | ASOCIADO (TC) | MAESTRO | ACTIVO | Agronomía / Suelos |
| `03681034` | `asullon` | Alex Alexander Sullon Yovera | AUXILIAR (TP) | MAESTRO | SUSPENDIDO | Ciencias de la Salud / Enfermería |
| `03681035` | `respinoza` | Rosa Elvira Espinoza Garcia | PRINCIPAL (DE) | DOCTOR | ACTIVO | Ingeniería de Minas / Ingeniería de Minas |
| `03681036` | `mneyra` | Marcos Aurelio Neyra Cruz | ASOCIADO (TC) | MAESTRO | ACTIVO | Derecho y Ciencias Políticas / Derecho |
| `03681037` | `ldioses` | Lourdes del Pilar Dioses Morales | AUXILIAR (TP) | MAESTRO | ACTIVO | Economía / Economía |
| `03681038` | `acastillo` | Aldo Martin Castillo Cherres | PRINCIPAL (DE) | DOCTOR | ACTIVO | Arquitectura y Urbanismo / Arquitectura y Urbanismo |
| `03681039` | `brivas` | Brenda Vanessa Rivas Vite | ASOCIADO (TC) | DOCTOR | ACTIVO | Ingeniería Civil / Ingeniería Civil |
| `03681040` | `cbenites2` | Christian Joel Benites Yarleque | AUXILIAR (TP) | MAESTRO | LICENCIA | Zootecnia / Producción Animal |
| `03681041` | `kroman` | Katia Paola Roman Silva | PRINCIPAL (DE) | DOCTOR | ACTIVO | Ingeniería Pesquera / Ingeniería Pesquera |
| `03681042` | `dvilchez` | Daniel Omar Vilchez Chero | ASOCIADO (TC) | MAESTRO | ACTIVO | Ciencias Sociales y Educación / Ciencias Sociales |
| `03681043` | `apacherres` | Andrea Fabiana Pacherres Nole | AUXILIAR (TP) | MAESTRO | ACTIVO | Ingeniería Industrial / Agroindustria e Industrias Alimentarias |
| `03681044` | `grequena` | Gonzalo Nicolas Requena Tavara | PRINCIPAL (DE) | DOCTOR | ACTIVO | Ciencias / Ciencias Biológicas |
| `03681045` | `ysandoval` | Yessica Yanet Sandoval Ipanaque | ASOCIADO (TC) | MAESTRO | ACTIVO | Ciencias Administrativas / Administración Aplicada |
| `03681046` | `rcordova` | Ruben Dario Cordova Purizaca | AUXILIAR (TP) | MAESTRO | ACTIVO | Ciencias Contables y Financieras / Contabilidad General |
| `03681047` | `cprado` | Cecilia Ines Prado Valladares | PRINCIPAL (DE) | DOCTOR | ACTIVO | Agronomía / Ingeniería Agrícola |
| `03681048` | `egarcia` | Edwin David Garcia Palacios | ASOCIADO (TC) | MAESTRO | SUSPENDIDO | Ciencias de la Salud / Morfofisiología Humana |
| `03681049` | `gtalledo` | Giannina Maria Talledo Saavedra | AUXILIAR (TP) | MAESTRO | ACTIVO | Ingeniería de Minas / Ingeniería Geológica |
| `03681050` | `rvilela` | Raul Enrique Vilela Chunga | PRINCIPAL (DE) | DOCTOR | ACTIVO | Derecho y Ciencias Políticas / Derecho |
| `03681051` | `fcruz` | Fiorella Lizbeth Cruz Ramos | ASOCIADO (TC) | MAESTRO | ACTIVO | Economía / Economía |
| `03681052` | `hmorales` | Hernan Alonso Morales Yovera | AUXILIAR (TP) | MAESTRO | ACTIVO | Arquitectura y Urbanismo / Arquitectura y Urbanismo |
| `03681053` | `galba` | Giuliana Mercedes Alba Chunga | PRINCIPAL (DE) | DOCTOR | LICENCIA | Ingeniería Civil / Ingeniería Civil |
| `03681054` | `gnole` | Guillermo Andres Nole Farfan | ASOCIADO (TC) | MAESTRO | ACTIVO | Zootecnia / Salud Animal |
| `03681055` | `wpurizaca` | Wendy Katherine Purizaca Cherres | AUXILIAR (TP) | MAESTRO | ACTIVO | Ingeniería Pesquera / Ingeniería Pesquera |
| `03681056` | `ryamunaque` | Renato Stephano Yamunaque Silva | PRINCIPAL (DE) | DOCTOR | ACTIVO | Ciencias Sociales y Educación / Educación |
| `03681057` | `rtavara` | Roxana Elizabeth Tavara Pasapera | ASOCIADO (TC) | MAESTRO | ACTIVO | Ingeniería Industrial / Ingeniería Mecatrónica |
| `03681058` | `schero` | Sergio Mateo Chero Ipanaque | AUXILIAR (TP) | MAESTRO | ACTIVO | Ciencias / Ingeniería Electrónica y Telecomunicaciones |
| `03681059` | `tpurizaca` | Tatiana Soledad Purizaca Sullon | PRINCIPAL (DE) | DOCTOR | ACTIVO | Ciencias Administrativas / Administración General |
| `03681060` | `wvilchez` | Williams Steve Vilchez Yarleque | ASOCIADO (TC) | MAESTRO | ACTIVO | Ciencias Contables y Financieras / Finanzas, Tributación y Auditoría |
| `03681061` | `zchunga` | Zoila Marina Chunga Dioses | AUXILIAR (TP) | MAESTRO | ACTIVO | Agronomía / Morfofisiología Vegetal |
| `03681062` | `amorales` | Alvaro Rodrigo Morales Sullon | PRINCIPAL (DE) | DOCTOR | SUSPENDIDO | Ciencias de la Salud / Materno Infantil |
| `03681063` | `bfarfan` | Beatriz Alexandra Farfan Nole | ASOCIADO (TC) | MAESTRO | ACTIVO | Ingeniería de Minas / Ingeniería Ambiental y Seguridad Industrial |
| `03681064` | `cyovera` | Claudio Fernando Yovera Purizaca | AUXILIAR (TP) | MAESTRO | ACTIVO | Derecho y Ciencias Políticas / Ciencias Políticas |
| `03681065` | `dcherres` | Dora Alicia Cherres Silva | PRINCIPAL (DE) | MAESTRO | ACTIVO | Economía / Economía |
| `03681066` | `esilva` | Eduardo Felipe Silva Yamunaque | ASOCIADO (TC) | MAESTRO | ACTIVO | Arquitectura y Urbanismo / Arquitectura y Urbanismo |
| `03681067` | `fsullon` | Fanny del Socorro Sullon Chero | AUXILIAR (TP) | MAESTRO | ACTIVO | Ingeniería Civil / Ingeniería Civil |
| `03681068` | `gipanaque2` | Gustavo Adolfo Ipanaque Yarleque | PRINCIPAL (DE) | DOCTOR | LICENCIA | Zootecnia / Producción Animal |
| `03681069` | `hpasapera` | Helga Mariela Pasapera Tavara | ASOCIADO (TC) | MAESTRO | ACTIVO | Ingeniería Pesquera / Ingeniería Pesquera |
| `03681070` | `iiman` | Ivan Danelgi Iman Agurto | PRINCIPAL (DE) | DOCTOR | ACTIVO | Ingeniería Industrial / Ingeniería Informática |
| `03681071` | `jlucano` | Jean Carlos Lucano Zurita | ASOCIADO (TC) | DOCTOR | ACTIVO | Ingeniería Industrial / Ingeniería Informática |
| `03681072` | `jsuarez` | Jeremy Aaron Suárez Taboada | AUXILIAR (TP) | MAESTRO | ACTIVO | Ingeniería Industrial / Ingeniería Informática |
| `03681073` | `lpena` | Leandro Emmanuel Peña Ávila | AUXILIAR (TP) | MAESTRO | ACTIVO | Ingeniería Industrial / Ingeniería Informática |
| `03681074` | `kdioses` | Karina Elizabeth Dioses Purizaca | PRINCIPAL (DE) | DOCTOR | ACTIVO | Ciencias / Matemática |
| `03681075` | `lyarleque` | Luis Alberto Yarleque Sullon | ASOCIADO (TC) | MAESTRO | ACTIVO | Ciencias / Física |
| `03681076` | `mchero` | Martha Elena Chero Yovera | AUXILIAR (TP) | MAESTRO | ACTIVO | Ciencias / Estadística |
| `03681077` | `nsilva` | Nestor Daniel Silva Cherres | PRINCIPAL (DE) | DOCTOR | ACTIVO | Ciencias / Ciencias Biológicas |
| `03681078` | `oyamunaque` | Olga Lidia Yamunaque Pasapera | ASOCIADO (TC) | MAESTRO | SUSPENDIDO | Ciencias / Ingeniería Electrónica y Telecomunicaciones |
| `03681079` | `ptavara` | Pablo Antonio Tavara Chero | AUXILIAR (TP) | MAESTRO | ACTIVO | Ciencias Administrativas / Administración General |
| `03681080` | `rsullon` | Rosa Isabel Sullon Ipanaque | PRINCIPAL (DE) | DOCTOR | ACTIVO | Ciencias Administrativas / Administración Aplicada |
| `03681081` | `syovera` | Samuel Eduardo Yovera Silva | ASOCIADO (TC) | MAESTRO | ACTIVO | Ciencias Contables y Financieras / Contabilidad General |
| `03681082` | `tcherres` | Tania Maria Cherres Yamunaque | AUXILIAR (TP) | MAESTRO | ACTIVO | Ciencias Contables y Financieras / Contabilidad Aplicada |
| `03681083` | `upasapera` | Ulises Omar Pasapera Tavara | PRINCIPAL (DE) | MAESTRO | ACTIVO | Ciencias Contables y Financieras / Finanzas, Tributación y Auditoría |
| `03681084` | `vchero` | Vanessa Lisset Chero Sullon | ASOCIADO (TC) | MAESTRO | LICENCIA | Agronomía / Agronomía y Fitotecnia |
| `03681085` | `wipanaque` | Walter Javier Ipanaque Yovera | AUXILIAR (TP) | MAESTRO | ACTIVO | Agronomía / Ingeniería Agrícola |
| `03681086` | `xsilva` | Xavier Hernan Silva Cherres | PRINCIPAL (DE) | DOCTOR | ACTIVO | Agronomía / Sanidad Vegetal |
| `03681087` | `yyamunaque` | Yenny Patricia Yamunaque Tavara | ASOCIADO (TC) | DOCTOR | ACTIVO | Agronomía / Suelos |
| `03681088` | `ztavara` | Zoraida Beatri Tavara Sullon | AUXILIAR (TP) | MAESTRO | ACTIVO | Agronomía / Morfofisiología Vegetal |
| `03681089` | `achero` | Armando Jose Chero Pasapera | PRINCIPAL (DE) | DOCTOR | ACTIVO | Ciencias de la Salud / Materno Infantil |
| `03681090` | `bipanaque` | Blanca Rosa Ipanaque Tavara | ASOCIADO (TC) | MAESTRO | ACTIVO | Ciencias de la Salud / Morfofisiología Humana |
| `03681091` | `cyovera2` | Carlos Enrique Yovera Chero | AUXILIAR (TP) | MAESTRO | ACTIVO | Ciencias de la Salud / Clínico Quirúrgico |
| `03681092` | `dcherres2` | Doris Maria Cherres Ipanaque | PRINCIPAL (DE) | MAESTRO | SUSPENDIDO | Ciencias de la Salud / Salud Pública |
| `03681093` | `esilva2` | Ernesto Luis Silva Yovera | ASOCIADO (TC) | MAESTRO | ACTIVO | Ciencias de la Salud / Enfermería |
| `03681094` | `fyamunaque` | Fatima Soledad Yamunaque Cherres | AUXILIAR (TP) | MAESTRO | ACTIVO | Ingeniería de Minas / Ingeniería de Minas |
| `03681095` | `gtavara` | Guillermo Jose Tavara Silva | PRINCIPAL (DE) | MAESTRO | ACTIVO | Ingeniería de Minas / Ingeniería de Petróleo |
| `03681096` | `hsullon` | Hilda Elizabeth Sullon Yamunaque | ASOCIADO (TC) | DOCTOR | ACTIVO | Ingeniería de Minas / Ingeniería Geológica |
| `03681097` | `ipasapera` | Ivan Marcelino Pasapera Chero | AUXILIAR (TP) | MAESTRO | ACTIVO | Ingeniería de Minas / Ingeniería Química |
| `03681098` | `jchero` | Judith Noemi Chero Ipanaque | PRINCIPAL (DE) | MAESTRO | LICENCIA | Ingeniería de Minas / Ingeniería Ambiental y Seguridad Industrial |
| `03681099` | `kyovera` | Kevin Joel Yovera Tavara | ASOCIADO (TC) | MAESTRO | ACTIVO | Derecho y Ciencias Políticas / Derecho |
| `03681100` | `lsilva` | Laura Beatri Silva Sullon | AUXILIAR (TP) | MAESTRO | ACTIVO | Derecho y Ciencias Políticas / Ciencias Políticas |
