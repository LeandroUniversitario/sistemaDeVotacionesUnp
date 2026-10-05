# Análisis y Explicación de las 40 Reglas de Negocio (RN)
**Sistema de Elecciones Docentes - Universidad Nacional de Piura (UNP)**

Este documento traduce las normativas legales (Reglas de Negocio) del estatuto universitario a un lenguaje claro para entender cómo debe comportarse el software y el proceso administrativo.

---

### Fase 1: Padrón y Convocatoria (RN01 - RN05)

**RN01 | El voto es personal, obligatorio, directo y secreto, y solo vota quien figura en el padrón.**
*   *Qué significa:* El sistema no permite intermediarios ni revelar por quién votó un docente (anonimato garantizado en la BD). Además, si no estás en el padrón final generado, el sistema te bloquea el acceso.

**RN02 | Convocatoria con 30 a 45 días de anticipación y publicación oficial.**
*   *Qué significa:* Es un plazo administrativo. El CEUNP debe crear el `proceso_electoral` en el sistema al menos 30 días antes del día "D" para dar tiempo a inscripciones y tachas.

**RN03 | Votan docentes ordinarios remunerados; excluye licencias sin goce de haber.**
*   *Qué significa:* Cuando el sistema arma el padrón, ejecuta una consulta (SQL) a la tabla docente. Si el `estado` del docente es "Licencia sin goce", el algoritmo lo ignora y no lo habilita para votar.

**RN04 | Solo sufragan quienes figuran en el padrón aprobado.**
*   *Qué significa:* Es un candado estricto. El día de la elección, el sistema valida la entrada contra la tabla `padron_electoral`. No hay "inscripciones de último minuto" el día de la elección.

**RN05 | Identificación con DNI.**
*   *Qué significa:* Antes de darle el acceso al software en la cabina (generar la sesión activa), el Presidente de Mesa debe ver físicamente el DNI plástico del docente para evitar suplantaciones (Voto Electrónico Presencial).

---

### Fase 2: Operatividad de Mesas y Día de Elección (RN06 - RN08, RN19, RN29, RN30)

**RN06 | Sufragio de 9:00 a 15:00. Cierre de puertas a las 15:00.**
*   *Qué significa:* El software tiene un cronómetro ligado a `fecha_inicio` y `fecha_fin`. A las 15:00:00, el botón de "Emitir Voto" se desactiva para todos los que no estén ya logueados.

**RN07 | Instalación de mesas entre 9:00 y 12:00.**
*   *Qué significa:* Si a las 12:01 los miembros de mesa no han generado el "Acta de Instalación" en el sistema, esa mesa se marca como `NO_INSTALADA` y los docentes asignados a ella no podrán votar (se les reasigna o se anula esa mesa).

**RN08 | Sufragio en Biblioteca Central (parametrizable).**
*   *Qué significa:* La ubicación de las mesas no es estática. El sistema permite al administrador escribir la `ubicacion` (Ej. Biblioteca, Pabellón Central) al momento de generar el proceso.

**RN19 | Mesa con 3 titulares y 3 suplentes (irrenunciable).**
*   *Qué significa:* El algoritmo de sorteo del sistema SIEMPRE debe elegir exactamente a 6 docentes por mesa. No 5, no 7.

**RN29 | Atención preferente a vulnerables.**
*   *Qué significa:* Es una regla de logística física. Debe haber una computadora (Mesa) especial en el primer piso para que voten rápido personas mayores o embarazadas.

**RN30 | Bloqueo a suplantadores o no empadronados.**
*   *Qué significa:* Si alguien intenta usar un DNI falso o no está en el padrón, el sistema y la mesa lo rechazan. Es un control biométrico/físico previo al uso del software.

---

### Fase 3: Candidatos y Listas (Fórmulas) (RN09 - RN17, RN20, RN21)

**RN09 | Requisitos estrictos para Rector/Vicerrector.**
*   *Qué significa:* Validación legal. El CEUNP revisa manualmente si el candidato es Doctor, tiene 5 años de Principal, etc. En el sistema, esto se refleja marcando el `estado_validacion` como ADMITIDO o EXCLUIDO.

**RN10 | Listas en "Fórmula" (1 Rector + 2 Vicerrectores).**
*   *Qué significa:* En el sistema no inscribes personas sueltas. Inscribes una Lista (Ej. Lista Roja) y obligatoriamente le asignas 3 perfiles a 3 docentes distintos.

**RN11 | Un candidato no puede estar en dos listas.**
*   *Qué significa:* El software (backend) tiene una validación que bloquea la inscripción si detecta que el DNI del docente ya está matriculado en otra agrupación para esa misma elección.

**RN12 y RN13 | Inscripción en bloque y reemplazos condicionados.**
*   *Qué significa:* Si el CEUNP tacha al Rector de una lista, toda la lista se cae. El sistema permite cambiar de candidato (editar la lista) solo si la `fecha_actual` es menor a la fecha límite de inscripción.

**RN14 | Exclusión por mentir en hoja de vida.**
*   *Qué significa:* Si se descubre información falsa antes de los 5 días de la elección, el sistema permite al CEUNP expulsar al candidato (Cambiar estado a EXCLUIDO).

**RN15 y RN16 | Hojas de vida públicas e inmodificables.**
*   *Qué significa:* El sistema web tiene una sección pública "Portal de Transparencia" donde cualquier alumno o docente puede leer los PDFs de los candidatos aprobados. Nadie puede subir un nuevo PDF una vez cerrada la inscripción.

**RN17 | Restricciones de símbolos.**
*   *Qué significa:* No se pueden usar banderas ni fotos de personas como logo de la lista. Se valida manualmente por el CEUNP antes de subir el JPG/PNG al sistema.

**RN20 | Prohibición de miembros de mesa.**
*   *Qué significa:* El algoritmo que sortea las mesas tiene filtros `WHERE NOT IN`. Excluye automáticamente a autoridades, candidatos, personeros y familiares directos.

**RN21 | El personero no debe ser candidato ni autoridad.**
*   *Qué significa:* Al registrar un Personero, el sistema verifica que su DNI no esté en la tabla de candidatos ni de cargos administrativos.

---

### Fase 4: Escrutinio, Votación y Actas (RN18, RN22 - RN28, RN32)

**RN18 | Orden en cédula por sorteo.**
*   *Qué significa:* La pantalla táctil donde el docente vota no muestra las listas por orden alfabético. Las muestra según el número de `orden_cedula` que el CEUNP ingresó al sistema tras hacer el sorteo manual.

**RN22, RN23 y RN24 | Conducta y resolución en mesa.**
*   *Qué significa:* Reglas de comportamiento humano. Si hay pelea por si un voto es válido, deciden los 3 miembros de mesa. Solo los personeros pueden quejarse formalmente.

**RN25 | Votos Válidos, Nulos o Blancos.**
*   *Qué significa:* Como usamos voto electrónico, el sistema ELIMINA los votos Nulos (no puedes marcar mal en una pantalla). Solo existen votos válidos por una lista, o el botón de "Voto en Blanco".

**RN26 | Escrutinio irreversible y sin pausas.**
*   *Qué significa:* Una vez que se cierra la elección (15:00), el servidor calcula los resultados y no hay botón de "deshacer" o "recalcular". El cómputo es automático.

**RN27 | Cuadre de cédulas vs Electores.**
*   *Qué significa:* En el sistema electrónico esto es exacto. Si el padrón dice que entraron 100 docentes, la base de datos debe tener exactamente 100 registros en la tabla `voto`. El sistema garantiza que esto siempre cuadre.

**RN28 | Tres tipos de actas físicas y digitales.**
*   *Qué significa:* El sistema genera 3 PDFs (Instalación, Sufragio y Escrutinio) con firmas de los miembros y un Hash SHA-256 (QR) para garantizar que nadie falsifique el papel.

**RN32 | Cómputo final tras recibir actas.**
*   *Qué significa:* El panel principal del CEUNP no mostrará al ganador oficial hasta que todas las mesas hayan transmitido sus Actas de Escrutinio firmadas criptográficamente al servidor central.

---

### Fase 5: Resolución Final y Sanciones (RN31, RN33 - RN40)

**RN31 | Quórum mayor al 60%.**
*   *Qué significa:* El sistema calcula en vivo: `(Total_Votos / Total_Padron) * 100`. Si a las 15:00 no llega a >60%, el sistema declara la elección ANULADA automáticamente por falta de participación.

**RN33 | Segunda Vuelta (Balotaje).**
*   *Qué significa:* Si nadie supera el 50% de votos válidos, el sistema permite crear un nuevo `proceso_electoral` "Hijo" clonando el padrón original, y habilitando la votación solo para las 2 listas ganadoras.

**RN34 | Nulidad por causales.**
*   *Qué significa:* Si hay hackeos o incendios, el CEUNP puede presionar un botón de "Anular Proceso" en el sistema, lo cual cancela todos los datos emitidos y publica una notificación para SUNEDU.

**RN35 | Multas monetarias por inasistencia.**
*   *Qué significa:* El sistema ejecuta un proceso nocturno (Batch) finalizada la elección. Todos los que tengan `ya_voto = FALSE` reciben una multa en la base de datos equivalente al 2.5% de la UIT (3% si faltó a ser miembro de mesa).

**RN36, RN37, RN38, RN39, RN40 | Facultades del CEUNP.**
*   *Qué significa:* Son reglas puramente administrativas, humanas y legales. Indican los horarios de atención de la oficina física del Comité Electoral, cómo votan para tomar decisiones (mayoría simple) y su poder supremo para resolver vacíos legales. No requieren programación directa en el software.
