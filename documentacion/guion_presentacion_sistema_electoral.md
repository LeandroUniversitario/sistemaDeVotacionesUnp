# 🎤 GUIÓN DE PRESENTACIÓN
## Sistema de Control de Elecciones Universitarias — UNP
### Análisis y Diseño de Sistemas II | Ciclo VI

---

> **Instrucciones de uso:** El texto en *cursiva* es lo que DICES en voz alta. El texto en `[corchetes]` son acciones que realizas (pasar diapositiva, señalar el diagrama, etc).

---

## PARTE 1 — INTRODUCCIÓN Y CONTEXTO DEL NEGOCIO
**Duración estimada: ~3 minutos**

`[Portada o diapositiva inicial visible]`

*"Buenos días / buenas tardes. Mi nombre es [nombre] y hoy les presentaré el análisis y diseño del Sistema de Control de Elecciones Universitarias para la Universidad Nacional de Piura."*

*"Comenzamos con la pregunta más importante: ¿por qué se necesita este sistema?"*

*"Actualmente, el proceso electoral en la universidad se gestiona de manera manual o con herramientas que no garantizan ni la trazabilidad, ni la confidencialidad del voto, ni la imparcialidad del sorteo de mesas. Esto genera desconfianza entre la comunidad docente."*

*"Nuestro sistema busca digitalizar y automatizar todo el ciclo electoral universitario, desde la creación del proceso hasta la generación de actas oficiales, garantizando tres pilares fundamentales:"*

*"**Primero:** Transparencia total en el proceso. **Segundo:** Confidencialidad absoluta del voto. **Tercero:** Trazabilidad y auditabilidad de cada decisión."*

---

## PARTE 2 — ACTORES DEL SISTEMA (TRABAJADORES DEL NEGOCIO)
**Duración estimada: ~2 minutos**

*"El sistema involucra cuatro actores principales, a quienes en modelado de negocio llamamos Trabajadores del Negocio."*

*"El **Comité Electoral** es el actor central. Es el organismo que crea los procesos electorales, valida candidaturas, ejecuta los sorteos de mesa, resuelve impugnaciones y finalmente genera las actas con los resultados."*

*"El **Administrador del Sistema** se encarga exclusivamente de mantener el padrón docente actualizado. Es importante distinguirlo del Comité Electoral porque su rol es técnico, no político."*

*"El **Docente Elector** es cualquier docente habilitado para votar. Su única función en el sistema es emitir su voto por cada cargo en contienda."*

*"Y el **Docente Candidato** es quien se inscribe para postular a un cargo. A partir de su inscripción, queda automáticamente excluido del sorteo de mesas."*

---

## PARTE 3 — DIAGRAMA DE CASOS DE USO GENERAL
**Duración estimada: ~4 minutos**

`[Mostrar el diagrama diagrama_casos_uso_general]`

*"Este es el Diagrama de Casos de Uso General del sistema. Es el mapa funcional que describe todo lo que el sistema puede hacer y quién puede hacerlo."*

*"Aquí vemos los cuatro actores que acabo de mencionar interactuando con once casos de uso dentro del límite del sistema."*

*"Permítanme destacar las relaciones más importantes:"*

*"El **UC3 — Crear proceso electoral** tiene una relación de* `<<include>>` *con el **UC4 — Generar padrón electoral**. Esto significa que crear un proceso electoral SIEMPRE incluye automáticamente la generación del padrón. No puede existir un proceso sin su padrón."*

*"El **UC5 — Emitir voto** incluye el **UC10 — Validar habilitación**. Esto es crítico: antes de que un docente pueda votar, el sistema SIEMPRE verifica si está en el padrón y si ya votó. Este paso no es opcional."*

*"De igual manera, **UC1 — Inscribir candidatura** también incluye el **UC10 — Validar habilitación**, porque el sistema verifica que el candidato cumpla los requisitos de categoría docente antes de aceptar su postulación."*

*"Finalmente, el **UC11 — Descargar constancia de voto** tiene una relación de* `<<extend>>` *sobre UC5. Esto significa que es una funcionalidad opcional: después de votar, el docente PUEDE descargar su constancia, pero no está obligado a hacerlo."*

---

## PARTE 4 — REQUERIMIENTOS FUNCIONALES
**Duración estimada: ~3 minutos**

*"El sistema tiene diez requerimientos funcionales. Los agrupo por temática para facilitar su comprensión:"*

**Gestión del Padrón y del Proceso:**
*"**RF01** — Mantenimiento del padrón docente con datos completos: DNI, categoría y dedicación. **RF02** — Creación de procesos electorales con fechas y estados. **RF03** — Generación automática del padrón electoral por cargo, filtrando por categoría permitida."*

**Candidaturas:**
*"**RF04** — Inscripción de candidaturas por parte del docente candidato. **RF05** — Validación y aprobación de candidaturas por el Comité Electoral."*

**Votación:**
*"**RF06** — Emisión del voto con verificación previa de habilitación. **RF07** — El punto más sensible: el voto se almacena de forma completamente desvinculada del votante. Solo el padrón registra 'quién votó', y el repositorio de votos registra 'por quién se votó'. Nunca se cruza esta información en el esquema de base de datos."*

**Sorteo:**
*"**RF08** — Sorteo aleatorio de miembros de mesa. Este sorteo excluye a candidatos y a docentes con cargos administrativos de alto nivel, como decanos y directores. **RF09** — Este catálogo de exclusiones es editable por el Comité, no está fijo en el código."*

**Resultados:**
*"**RF10** — Generación de resultados y actas oficiales al cierre de la votación."*

---

## PARTE 5 — REQUERIMIENTOS NO FUNCIONALES
**Duración estimada: ~2 minutos**

*"Los requerimientos no funcionales definen la calidad del sistema, no solo lo que hace sino cómo lo hace."*

*"**RNF01 — Confidencialidad:** El voto es secreto por diseño de arquitectura. No existe ninguna consulta SQL posible que revele por quién votó un docente específico."*

*"**RNF02 — Auditabilidad del Sorteo:** El algoritmo de sorteo debe ser determinístico dado un valor semilla, y ese valor debe quedar en un log. Esto permite al Comité demostrar, si fuera impugnado, que el sorteo fue justo."*

*"**RNF03 — Accesibilidad:** El sistema opera desde un navegador web estándar, sin necesidad de instalar software adicional en los equipos de los docentes."*

*"**RNF04 — Concurrencia:** La arquitectura debe soportar que múltiples docentes voten simultáneamente sin que se produzcan inconsistencias, como que un mismo voto se registre dos veces."*

---

## PARTE 6 — DIAGRAMA DE SECUENCIA: EMITIR VOTO
**Duración estimada: ~4 minutos**

`[Mostrar el diagrama secuencia_emitir_voto]`

*"Este diagrama de secuencia muestra, paso a paso y en orden cronológico, cómo se ejecuta el caso de uso más importante del sistema: Emitir Voto."*

*"Observen los participantes en la parte superior: el Docente Elector, la vista EmisionVotoView en la capa de presentación, el VotacionController en la capa de lógica de negocio, y los dos repositorios de datos."*

*"El flujo comienza cuando el docente selecciona emitir voto para un cargo específico."*

*"La vista inmediatamente llama a* `validarHabilitacion(idDocente, idCargo)` *en el controlador. El controlador consulta al PadronElectoralRepository con* `verificarSiVoto()`. *Aquí el sistema toma una decisión:"*

*"En el fragmento **alt** — la rama de la izquierda — si el docente ya votó o no está habilitado, el sistema le muestra un mensaje de error y el flujo termina."*

*"En la rama de la derecha — el camino feliz — el controlador confirma que está habilitado, la vista muestra las candidaturas disponibles y el docente selecciona y confirma su voto."*

*"Ahora viene el momento más crítico, que quiero que observen con detalle:"*

*"El controlador abre una **transacción** y ejecuta DOS operaciones de forma atómica. Primero, llama a* `marcarComoVotado(idDocente, idCargo)` *en el PadronElectoralRepository — esto registra que Juan Pérez ya ejerció su derecho. Segundo, llama a* `guardarVoto(Voto)` *en el VotoRepository — esto guarda el voto anónimo por la candidata seleccionada."*

*"Observen la nota en el diagrama: 'El voto se guarda sin vínculo al idDocente'. Esto implementa el RNF01. Si la transacción falla a mitad, ambas operaciones se revierten, garantizando consistencia."*

---

## PARTE 7 — DIAGRAMA DE SECUENCIA: SORTEAR MESA ELECTORAL
**Duración estimada: ~4 minutos**

`[Mostrar el diagrama secuencia_sortear_mesa]`

*"Este diagrama muestra el proceso de sorteo de mesas electorales, que es ejecutado únicamente por el Comité Electoral."*

*"El flujo inicia cuando el Comité ingresa el identificador del proceso y el número de suplentes requeridos por mesa."*

*"El SorteoMesaController realiza entonces una secuencia de depuración del universo de docentes:"*

*"**Paso 1:** Consulta al DocenteRepository para obtener todos los docentes habilitados para ese proceso."*

*"**Paso 2:** Aplica el método* `excluirCargosAdministrativos()`. Aquí el sistema compara el cargo actual de cada docente — si lo tiene — con el catálogo de* `CargoExcluidoSorteo` *y verifica que el cargo esté vigente usando el método* `estaVigente()`. *Un docente que ya no es Decano puede volver a ser sorteado."*

*"**Paso 3:** Aplica el método* `excluirCandidatos()`. *Todo docente que haya inscrito una candidatura en ese proceso queda fuera del sorteo, garantizando que los miembros de mesa sean imparciales."*

*"Tras estos tres pasos, el controlador tiene el universo final de docentes sorteables."*

*"Luego entra al **loop**: por cada mesa electoral requerida, selecciona aleatoriamente tres titulares más los suplentes indicados, les asigna roles — Presidente, Secretario, Vocal — y les asigna tipo — Titular o Suplente — , crea el objeto* `MesaElectoral` *y lo persiste en el repositorio."*

*"Al finalizar todas las mesas, retorna la lista completa al Comité para su visualización."*

---

## PARTE 8 — DIAGRAMA DE CLASES DE DISEÑO
**Duración estimada: ~5 minutos**

`[Mostrar el diagrama diagrama_clases_diseno]`

*"Este es el Diagrama de Clases de Diseño. Es el mapa completo de la arquitectura interna del sistema, organizado en cuatro capas siguiendo el patrón MVC extendido con repositorios."*

**CAPA DE PRESENTACIÓN (Boundary):**
*"En la parte superior tenemos las vistas:* `EmisionVotoView` *y* `SorteoMesaView`. *Estas clases solo se encargan de mostrar información al usuario y capturar sus acciones. No contienen lógica de negocio."*

**CAPA DE LÓGICA DE NEGOCIO (Control):**
*"En el centro está el corazón del sistema: los controladores. El* `VotacionController` *tiene dos métodos principales: validar habilitación y registrar voto. El* `SorteoMesaController` *tiene el método público* `ejecutarSorteo` *y dos métodos privados — noten el signo menos — para las exclusiones, lo que encapsula esa lógica de depuración. El* `PadronController` *gestiona la generación del padrón."*

**CAPA DE ENTIDADES (Entity):**
*"Aquí están los objetos del dominio. Quiero destacar dos entidades clave:"*

*"La clase* `Voto` *— con solo dos atributos: id y fechaHora — es deliberadamente mínima. No tiene atributo de docente. Eso es intencional, es la implementación técnica del voto secreto."*

*"La clase* `CargoExcluidoSorteo` *es el catálogo editable por el Comité. La nota en el diagrama lo confirma: 'Catálogo editable por el Comité Electoral, no fijo en código'."*

**CAPA DE ACCESO A DATOS (Repository):**
*"En la base están las interfaces de repositorio. Son interfaces — no clases concretas — porque siguen el principio de inversión de dependencias. La implementación real puede ser con JDBC, JPA u otro ORM sin afectar la lógica de negocio."*

*"En cuanto a las relaciones, observen que* `ProcesoElectoral` *tiene composición — el diamante relleno — con* `Cargo` *y con* `MesaElectoral`. *Esto significa que si el proceso se elimina, sus cargos y mesas también desaparecen. En cambio,* `Docente` *tiene una asociación simple con* `Candidatura`, *porque el docente existe independientemente de si candidateo o no."*

*"Y la relación más importante del diagrama: entre* `Voto` *y* `Docente` *NO existe ninguna línea. Ese vacío es la garantía técnica del anonimato."*

---

## PARTE 9 — DIAGRAMA DE OBJETOS
**Duración estimada: ~3 minutos**

`[Mostrar el diagrama diagrama_objetos]`

*"El Diagrama de Objetos es una fotografía del sistema en un momento específico: las Elecciones Universitarias 2026, en su estado EN_CURSO."*

*"Este diagrama valida que el modelo de clases funciona con datos reales. Veamos los casos más ilustrativos:"*

*"**Caso 1 — María Gómez:** Es docente de categoría Principal, tiene una candidatura APROBADA para el cargo de Rector. En el diagrama, vemos el objeto* `candidaturaMaria` *apuntando a ella. María NO puede ser sorteada para mesa."*

*"**Caso 2 — Juan Pérez:** Es docente Principal, está en el padrón electoral (padronJuan) y el atributo* `haVotado = true` *indica que ya ejerció su voto. También es Presidente titular de la Mesa 10. Pero observen: el objeto* `votoAnonimo1` *que él generó NO tiene ninguna línea conectándolo directamente con* `docenteJuan`. *El voto existe, pero no tiene dueño."*

*"**Caso 3 — Pedro Ramírez:** Es docente Principal, pero actualmente ocupa el cargo de Decano de Facultad, vigente hasta 2028. El sistema contrasta ese cargo con el catálogo* `excluidoDecano` *y lo excluye del sorteo. La nota en el diagrama lo confirma: 'Pedro no puede ser sorteado'."*

---

## PARTE 10 — DIAGRAMA DE DESPLIEGUE
**Duración estimada: ~3 minutos**

`[Mostrar el diagrama diagrama_despliegue]`

*"El Diagrama de Despliegue muestra cómo se distribuye físicamente el sistema en la infraestructura."*

*"Tenemos tres nodos principales:"*

*"**Nodo 1 — Dispositivo del Usuario:** Es cualquier PC o móvil con un navegador web. El frontend puede ser una página HTML/CSS/JS tradicional o una Single Page Application. Esto cumple el RNF03 de accesibilidad desde navegador estándar."*

*"**Nodo 2 — Servidor de Aplicaciones:** Aquí reside la aplicación backend con arquitectura MVC: los Controladores, la Lógica de Negocio y la capa de Acceso a Datos. Puede ejecutarse en contenedores como Tomcat, Node.js o Gunicorn. La nota en el diagrama indica que es escalable para soportar votación concurrente, cumpliendo el RNF04."*

*"**Nodo 3 — Servidor de Base de Datos:** Un RDBMS relacional, PostgreSQL o MySQL, que aloja dos esquemas separados: el Esquema de Elecciones y el Esquema de Padrón. La separación de esquemas refuerza el aislamiento de datos."*

*"Las comunicaciones usan HTTPS con API REST entre el cliente y el servidor, y TCP/IP con un driver ORM entre el servidor y la base de datos."*

---

## PARTE 11 — REGLAS DE NEGOCIO TRANSVERSALES
**Duración estimada: ~2 minutos**

*"Antes de cerrar, quiero sintetizar las tres reglas de negocio más importantes que atraviesan todo el sistema:"*

*"**Regla 1 — Anonimato del Voto:** El esquema no almacena una relación persistente entre el docente y la lista elegida. El padrón registra la participación y la urna registra el voto de forma separada; los controles de acceso y auditoría deben impedir su correlación posterior."*

*"**Regla 2 — Exclusiones Parametrizables del Sorteo:** El catálogo de cargos excluidos no está quemado en el código. El Comité Electoral puede actualizarlo sin necesidad de modificar el sistema. Esto le da al sistema flexibilidad frente a cambios en el reglamento universitario."*

*"**Regla 3 — Consistencia Transaccional en la Votación:** Marcar al docente como votado y registrar el voto anónimo son dos operaciones que ocurren juntas o no ocurren. Si el sistema falla entre medio, ninguna de las dos se consolida."*

---

## PARTE 12 — CIERRE Y CONCLUSIONES
**Duración estimada: ~2 minutos**

*"Para concluir, el Sistema de Control de Elecciones Universitarias para la UNP representa una solución integral que:"*

*"**Primero**, digitaliza y automatiza todo el ciclo electoral: desde la creación del proceso hasta la generación de actas."*

*"**Segundo**, garantiza el voto secreto por diseño de arquitectura, no solo por política, sino como una imposibilidad técnica de violar la privacidad."*

*"**Tercero**, ofrece un sorteo auditable y transparente con exclusiones configurables sin tocar el código."*

*"**Cuarto**, está diseñado sobre una arquitectura en capas sólida — Presentación, Control, Entidad y Repositorio — que facilita el mantenimiento, las pruebas y la escalabilidad futura."*

*"El modelado realizado cubre los artefactos fundamentales del análisis y diseño: el modelo de negocio, los casos de uso, las secuencias de los procesos clave, el diseño de clases, los objetos en ejecución y la arquitectura de despliegue."*

*"Quedamos abiertos a sus preguntas."*

*"Muchas gracias."*

---

## 📋 RESUMEN RÁPIDO — ORDEN DE DIAGRAMAS

| # | Diagrama | Archivo | Qué explica |
|---|----------|---------|-------------|
| 1 | Casos de Uso General | `diagrama_casos_uso_general.puml` | Qué hace el sistema y quién lo usa |
| 2 | Secuencia: Emitir Voto | `secuencia_emitir_voto.puml` | Cómo funciona el voto secreto paso a paso |
| 3 | Secuencia: Sortear Mesa | `secuencia_sortear_mesa.puml` | Cómo se ejecuta el sorteo y sus exclusiones |
| 4 | Clases de Diseño | `diagrama_clases_diseno.puml` | Arquitectura interna completa (4 capas) |
| 5 | Objetos | `diagrama_objetos.puml` | Instancia real del sistema con datos concretos |
| 6 | Despliegue | `diagrama_despliegue.puml` | Infraestructura física del sistema |

---

## ⏱️ TIEMPO TOTAL ESTIMADO: ~32 minutos

| Parte | Tema | Tiempo |
|-------|------|--------|
| 1 | Introducción y contexto | 3 min |
| 2 | Actores del sistema | 2 min |
| 3 | Diagrama de Casos de Uso | 4 min |
| 4 | Requerimientos Funcionales | 3 min |
| 5 | Requerimientos No Funcionales | 2 min |
| 6 | Secuencia: Emitir Voto | 4 min |
| 7 | Secuencia: Sortear Mesa | 4 min |
| 8 | Diagrama de Clases | 5 min |
| 9 | Diagrama de Objetos | 3 min |
| 10 | Diagrama de Despliegue | 3 min |
| 11 | Reglas de Negocio | 2 min |
| 12 | Cierre | 2 min |
