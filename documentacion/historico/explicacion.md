Voy a recorrer el diagrama del proceso actual y contrastarlo con el diseño corregido para explicarte un caso completo: convocatoria, candidaturas, sorteo, votación, personeros, escrutinio, segunda vuelta y proclamación.

Read , lines 1 to 170
Completed with input: {
  "path": "C:\\Users\\lucan\\Documents\\Lucano\\UNP Ciclo VI\\Analisis y Diseño de Sistemas II\\SisElecciones\\Documentacion del sistema\\proceso_actual_papel_docentes_unp.puml",
  "view_range": [
    1,
    170
  ]
}

Read , lines 171 to 317
Completed with input: {
  "path": "C:\\Users\\lucan\\Documents\\Lucano\\UNP Ciclo VI\\Analisis y Diseño de Sistemas II\\SisElecciones\\Documentacion del sistema\\proceso_actual_papel_docentes_unp.puml",
  "view_range": [
    171,
    317
  ]
}

Read , lines 1 to 130
Completed with input: {
  "path": "C:\\Users\\lucan\\Documents\\Lucano\\UNP Ciclo VI\\Analisis y Diseño de Sistemas II\\SisElecciones\\Documentacion del sistema\\proceso_electoral_docentes_unp.puml",
  "view_range": [
    1,
    130
  ]
}

Read , lines 131 to 285
Completed with input: {
  "path": "C:\\Users\\lucan\\Documents\\Lucano\\UNP Ciclo VI\\Analisis y Diseño de Sistemas II\\SisElecciones\\Documentacion del sistema\\proceso_electoral_docentes_unp.puml",
  "view_range": [
    131,
    285
  ]
}

Sí. Te explico el proceso completo como funcionaría el sistema, usando el modelo corregido y los diagramas existentes. La idea documentada es un **proceso electoral docente híbrido**: se utiliza el sistema digital para controlar el padrón, validar la participación, registrar el voto y generar resultados, pero se conserva una **cédula física como respaldo electoral**.

> Importante: los porcentajes, plazos y reglas finales deben confirmarse con el reglamento vigente de la UNP. A continuación explico el comportamiento según lo documentado actualmente.

# 1. Actores principales

## Comité Electoral — CEUNP

Es el responsable de administrar todo el proceso:

- Crear el proceso electoral.
- Definir cronograma y cargos.
- Aprobar el padrón.
- Revisar listas y candidatos.
- Resolver tachas.
- Organizar sorteos.
- Generar mesas electorales.
- Resolver impugnaciones y nulidades.
- Consolidar resultados.
- Convocar una segunda vuelta si corresponde.
- Proclamar a la lista ganadora.

## Administrador del sistema

Tiene una función técnica:

- Registrar y actualizar docentes.
- Mantener facultades, departamentos y categorías.
- Crear usuarios.
- Importar información de Recursos Humanos.
- No debería aprobar candidaturas ni decidir resultados electorales.

## Docente elector

Puede:

- Consultar si está habilitado.
- Consultar su mesa.
- Emitir su voto.
- Recibir una constancia QR.
- Verificar posteriormente que su constancia sea válida.

## Lista electoral

Es la agrupación que participa en la elección. Por ejemplo:

```text
Lista A — Renovación Universitaria
Lista B — Unidad Docente
Lista C — Transformación UNP
```

Una lista puede contener varios candidatos, cada uno con un cargo dentro de ella.

## Candidato

Es el docente que integra una lista. Por ejemplo:

```text
Lista A
- Rector: Ana Torres
- Vicerrector Académico: Luis Pérez
- Vicerrector de Investigación: María Díaz
```

El elector vota por la **lista**, no por un candidato individual.

## Personero

Es el representante de una lista durante el proceso electoral. No administra el sistema ni puede modificar votos.

Puede existir como:

- Personero general.
- Personero alterno.
- Personero de mesa.

## Miembro de mesa

Es responsable de controlar el acto electoral en una mesa:

- Instalar la mesa.
- Verificar electores.
- Controlar el ingreso.
- Participar en el escrutinio.
- Registrar observaciones.
- Firmar las actas.

# 2. Ejemplo general de una elección

Supongamos que la universidad convoca a elecciones para elegir:

```text
Rector
Vicerrector Académico
Vicerrector de Investigación
```

Se presentan tres listas:

```text
Lista A: Renovación Universitaria
Lista B: Unidad Docente
Lista C: Integración Académica
```

El padrón tiene:

```text
1,000 docentes habilitados
```

El requisito de participación mínima es:

```text
Más del 60 %
```

Por lo tanto, deben participar como mínimo más de 600 docentes.

# 3. Fase 1: convocatoria

El CEUNP crea el proceso electoral en el sistema:

```text
Nombre: Elecciones docentes UNP 2026
Fecha de inicio: 01/09/2026
Fecha de votación: 15/10/2026
Fecha de cierre: 15/10/2026
Tipo: Primera vuelta
Estado: Creado
Quórum mínimo: 60 %
```

El sistema registra el cronograma y publica la convocatoria en el portal institucional.

La convocatoria debe indicar:

- Cargos a elegir.
- Fechas.
- Plazos de inscripción.
- Periodo para presentar tachas.
- Fecha de votación.
- Horario de sufragio.
- Reglas de segunda vuelta.
- Requisitos de candidatos y electores.

# 4. Fase 2: generación del padrón

El sistema recibe la información de Recursos Humanos.

Ejemplo:

```text
Docente             Estado       Categoría       ¿Habilitado?
--------------------------------------------------------------
Ana Torres          Activa       Principal        Sí
Luis Pérez          Activo       Asociado         Sí
María Díaz          Licencia     Principal        No
Carlos Ruiz         Activo       Auxiliar         Sí
```

El sistema filtra:

- Docentes con vínculo vigente.
- Docentes con remuneración, según el requisito establecido.
- Docentes que no estén excluidos por licencia sin goce.
- Docentes que pertenezcan a las categorías permitidas.

La tabla `padron_electoral` registra la habilitación por:

```text
Proceso + Cargo + Docente
```

Por ejemplo:

```text
Proceso 1 + Cargo Rector + Docente Ana
Proceso 1 + Cargo Rector + Docente Luis
Proceso 1 + Cargo Rector + Docente Carlos
```

El sistema también mantiene:

```text
ya_voto = false
```

Al inicio todos los docentes habilitados tienen `ya_voto = false`.

# 5. Fase 3: inscripción de listas

Una lista presenta su inscripción mediante el sistema.

Ejemplo:

```text
Lista A: Renovación Universitaria
Símbolo: R
```

Sus candidatos:

```text
Cargo                         Candidato
-----------------------------------------
Rector                        Ana Torres
Vicerrector Académico         Luis Pérez
Vicerrector de Investigación  Carlos Ruiz
```

El sistema verifica:

- Que el candidato exista como docente.
- Que esté activo.
- Que pertenezca a la categoría permitida.
- Que no esté repetido en otra lista incompatible.
- Que no ocupe dos posiciones incompatibles.
- Que la lista tenga los cargos requeridos.
- Que los documentos estén completos.

La lista puede quedar en alguno de estos estados:

```text
INSCRITA
ADMITIDA
TACHADA
EXCLUIDA
```

Si falta información, el CEUNP puede declarar la solicitud inadmisible y dar un plazo para subsanar.

Si la lista corrige las observaciones, continúa el procedimiento.

Si no corrige dentro del plazo, puede declararse improcedente.

# 6. Fase 4: tachas

Una tacha es una denuncia formal contra un candidato.

Ejemplo:

> Un docente del padrón presenta una tacha contra el candidato Luis Pérez porque considera que no cumple una condición del reglamento.

El sistema registra:

```text
Docente denunciante
Candidato denunciado
Motivo
Fecha
Estado
```

La tacha puede tener estos estados:

```text
PENDIENTE
FUNDADA
INFUNDADA
```

## Si la tacha es infundada

El candidato continúa en la lista.

```text
Candidato: Luis Pérez
Resultado: mantiene su candidatura
```

## Si la tacha es fundada

El CEUNP excluye al candidato o aplica la consecuencia que corresponda.

```text
Candidato: Luis Pérez
Resultado: excluido
```

Dependiendo del reglamento, esto puede afectar a toda la lista o solamente a ese candidato.

Finalmente el CEUNP publica las listas oficiales admitidas.

# 7. Fase 5: función del personero

Esta es una parte importante.

El personero **no es un votante especial ni un administrador**. Su función es representar y vigilar los intereses de su lista.

## Tipos de personero

### Personero general

Representa a la lista ante el CEUNP durante todo el proceso.

Puede:

- Recibir comunicaciones.
- Participar en actos públicos.
- Observar sorteos.
- Recibir copias de actas.
- Presentar observaciones o recursos.
- Coordinar a los personeros de mesa.

### Personero alterno

Reemplaza al personero general cuando este no puede participar.

### Personero de mesa

Supervisa una mesa específica.

Puede:

- Estar presente durante la instalación.
- Observar el material electoral.
- Verificar que se cumplan las reglas.
- Observar el sufragio.
- Presenciar el escrutinio.
- Solicitar que se registre una observación.
- Impugnar un voto si considera que fue clasificado incorrectamente.
- Apelar una decisión de mesa, según el procedimiento establecido.
- Recibir copia o acceso al acta.

## Lo que el personero no puede hacer

El personero no puede:

- Votar en nombre de otra persona.
- Entrar a la cámara secreta con un elector.
- Ver la opción seleccionada por un docente.
- Modificar el padrón.
- Cambiar un resultado directamente.
- Eliminar votos.
- Acceder a la identidad relacionada con un voto.
- Escanear o utilizar el QR para conocer por quién votó alguien.

## Ejemplo durante el escrutinio

El presidente de mesa abre una cédula y la clasifica como voto nulo.

El personero de la Lista B considera que la marca sí es válida y dice:

> “Impugno la clasificación de esta cédula como nula.”

Entonces:

1. El miembro de mesa registra la impugnación.
2. Los miembros de mesa deliberan.
3. Votan o deciden según el reglamento.
4. La decisión se registra en el acta.
5. Si el personero no está conforme, puede apelar.
6. El CEUNP resuelve la apelación en segunda instancia, según el procedimiento.

# 8. Fase 6: sorteos

El sistema realiza dos sorteos diferentes.

## Sorteo del orden de las listas

Ejemplo:

```text
Número en la cédula
1 — Lista C
2 — Lista A
3 — Lista B
```

El sistema registra:

```text
Lista
Orden
Fecha
Semilla del sorteo
Participantes
```

La semilla permite demostrar posteriormente que el resultado no fue manipulado.

## Sorteo de miembros de mesa

Supongamos que se necesitan:

```text
3 titulares
3 suplentes
```

El sistema obtiene docentes elegibles y excluye:

- Candidatos.
- Personeros, si corresponde.
- Docentes con cargos administrativos excluidos.
- Personas con impedimentos.
- Docentes no habilitados.
- Docentes que no cumplen los criterios establecidos.

Ejemplo:

```text
Titular presidente:   Docente 101
Titular secretario:   Docente 205
Titular vocal:        Docente 310

Suplente 1:           Docente 411
Suplente 2:           Docente 502
Suplente 3:           Docente 618
```

El sistema guarda:

```text
Semilla del sorteo
Fecha
Mesa
Docentes seleccionados
Rol asignado
```

# 9. Fase 7: instalación de mesa

El día de la elección, los miembros de mesa reciben el material.

El sistema registra:

- Mesa.
- Lugar.
- Miembros.
- Hora de instalación.
- Acta de instalación.
- Material recibido.
- Incidencias.

El acta puede tener un QR para validar su autenticidad.

Si la mesa se instala correctamente, se habilita el sufragio.

Si no se instala dentro del horario permitido, el CEUNP debe evaluar la consecuencia:

- Mesa no instalada.
- Reprogramación.
- Nulidad de la mesa.
- Otra medida prevista por el reglamento.

# 10. Fase 8: llegada del elector

El docente llega a su mesa y presenta:

```text
DNI
QR o credencial de elector
```

El QR no contiene el voto. Sirve para identificar o localizar al elector dentro del padrón.

El miembro de mesa escanea el QR y compara los datos con el DNI.

El sistema consulta:

```text
¿El docente pertenece al padrón?
¿Está habilitado?
¿Ya votó?
¿Corresponde a esta mesa?
```

## Caso A: elector habilitado

El sistema responde:

```text
Elector habilitado
Puede votar
```

Se registra la participación, pero no se almacena todavía la lista elegida relacionada con su identidad.

El docente pasa a la zona de votación.

## Caso B: elector ya votó

El sistema responde:

```text
No puede votar nuevamente
```

Se registra la incidencia.

## Caso C: elector no aparece en el padrón

El miembro de mesa no debe permitir el voto automáticamente.

Se registra:

```text
Elector no encontrado
DNI observado
Mesa incorrecta
```

La decisión final corresponde al procedimiento del CEUNP.

## Caso D: posible suplantación

Si el DNI no coincide con la identidad o existe una irregularidad:

```text
Se deniega el voto
Se registra la incidencia
Se informa al CEUNP
```

# 11. Fase 9: emisión del voto

El docente ve las listas admitidas para el cargo.

Ejemplo:

```text
1 — Lista C
2 — Lista A
3 — Lista B
```

Selecciona:

```text
Lista A
```

El sistema debe realizar dos operaciones coordinadas:

## Primera operación: registrar participación

Actualiza el padrón:

```text
ya_voto = true
fecha_votacion = fecha actual
```

## Segunda operación: registrar el voto

Guarda únicamente algo parecido a:

```text
id_proceso
id_cargo
id_lista_elegida
tipo_voto
fecha_hora
```

No guarda:

```text
id_docente
id_usuario
id_sesion
```

Por tanto, el voto se conserva de forma separada de la identidad.

## Cédula física

Si el sistema utiliza cédula física de respaldo:

1. El sistema genera o imprime la cédula.
2. El docente verifica que corresponda a su elección.
3. Deposita la cédula en el ánfora.
4. Firma o coloca su huella en el padrón, según el procedimiento.
5. El sistema genera la constancia QR.

La cédula física prevalece como respaldo si existe una diferencia entre el conteo digital y la revisión electoral física, conforme a la regla documentada.

# 12. La constancia QR

Después de votar, el sistema genera un token aleatorio.

El QR puede contener algo como:

```text
https://elecciones.unp.edu.pe/constancia/X7kP9...
```

La base de datos guarda únicamente el hash del token.

La constancia permite demostrar:

```text
Que el docente participó
En qué proceso
En qué cargo
En qué fecha
```

No debe mostrar:

```text
Por qué lista votó
Qué candidato eligió
El contenido de la cédula
```

# 13. Voto en blanco y voto nulo

El sistema debe distinguir tres situaciones.

## Voto válido

El elector selecciona una lista admitida.

```text
tipo_voto = VALIDO
id_lista_elegida = Lista A
```

## Voto en blanco

El elector no selecciona ninguna lista.

```text
tipo_voto = BLANCO
id_lista_elegida = NULL
```

## Voto nulo

La cédula tiene una marca incorrecta o una condición que invalida el voto.

```text
tipo_voto = NULO
id_lista_elegida = NULL
```

La diferencia es importante:

- Blanco: no se eligió una lista.
- Nulo: se intentó votar, pero la cédula no cumple la regla.

# 14. Fase 10: cierre del sufragio

A la hora establecida, por ejemplo:

```text
15:00
```

Se cierran las puertas.

Solo pueden votar quienes ya se encuentren dentro, según el reglamento.

El sistema:

- Cierra el registro de nuevos votos.
- Marca quiénes no votaron.
- Calcula cuántos electores participaron.
- Genera el acta de sufragio.
- Guarda la información de la mesa.

Ejemplo:

```text
Electores del padrón:       200
Electores que votaron:      132
Electores que no votaron:    68
Participación de la mesa:   66 %
```

# 15. Fase 11: escrutinio

Los miembros de mesa abren el ánfora.

Primero cuentan las cédulas y comparan:

```text
Cédulas encontradas
Electores registrados como votantes
```

Ejemplo:

```text
Electores registrados: 132
Cédulas encontradas:   132
Resultado: coincide
```

Si no coincide:

```text
Electores registrados: 132
Cédulas encontradas:   134
```

Se aplica el procedimiento del reglamento y se registra la observación.

Después se lee cada cédula en voz alta y se clasifica:

```text
Lista A: 48 votos
Lista B: 43 votos
Lista C: 35 votos
Blancos: 4 votos
Nulos: 2 votos
Total: 132 votos
```

El sistema registra el conteo de la mesa, pero el acta también contiene el resultado validado por los miembros de mesa.

# 16. Actas electorales

Cada mesa puede generar tres tipos de acta:

## Acta de instalación

Contiene:

- Mesa.
- Hora de instalación.
- Miembros presentes.
- Material recibido.
- Incidencias iniciales.
- Firmas.

## Acta de sufragio

Contiene:

- Total de electores.
- Total de personas que votaron.
- Total de ausentes.
- Incidencias.
- Firmas.

## Acta de escrutinio

Contiene:

- Votos por lista.
- Blancos.
- Nulos.
- Impugnaciones.
- Observaciones.
- Resultado final de la mesa.
- Firmas.

Cada acta tiene:

```text
Contenido
Hash SHA-256
Token QR
Estado
Firmas
```

El QR permite verificar que el acta no haya sido modificada.

# 17. Resultado de primera vuelta

Supongamos que participaron 700 de los 1,000 docentes.

```text
Participación: 700 / 1000 = 70 %
```

Como se supera el quórum mínimo del 60 %, la elección es válida.

Resultados:

```text
Lista A: 300 votos válidos
Lista B: 240 votos válidos
Lista C: 160 votos válidos

Votos válidos: 700
```

Supongamos que el reglamento exige obtener más del 50 % de los votos válidos para ganar directamente.

La mayoría absoluta sería:

```text
Más de 350 votos
```

Ninguna lista alcanza esa cantidad.

Resultado:

```text
No hay ganador directo
Pasan Lista A y Lista B
Lista C queda fuera de la segunda vuelta
```

# 18. ¿Cuándo hay segunda vuelta?

La segunda vuelta ocurre cuando:

1. Se alcanzó el quórum de participación.
2. La elección no fue anulada.
3. Ninguna lista alcanzó el mínimo legal para ganar en primera vuelta.
4. Se convoca a las dos listas con más votos.
5. Se realiza una nueva jornada electoral, según el plazo previsto.

En el ejemplo:

```text
Primera vuelta:
1. Lista A — 300 votos
2. Lista B — 240 votos
3. Lista C — 160 votos
```

Pasan:

```text
Lista A
Lista B
```

La segunda vuelta no incluye a la Lista C.

# 19. Cómo funciona la segunda vuelta

El sistema crea un nuevo proceso relacionado con el anterior:

```text
Proceso 1: Elecciones docentes 2026 — Primera vuelta
Proceso 2: Elecciones docentes 2026 — Segunda vuelta
```

El segundo proceso tiene:

```text
tipo = SEGUNDA_VUELTA
id_proceso_padre = Proceso 1
```

Se repiten las etapas necesarias:

- Publicación de la convocatoria.
- Actualización o confirmación del padrón.
- Preparación de las listas participantes.
- Sorteo o confirmación del orden.
- Instalación de mesas.
- Votación.
- Escrutinio.
- Actas.
- Cómputo final.

La segunda vuelta solamente permite votar entre las dos listas clasificadas.

Ejemplo:

```text
Lista A: Renovación Universitaria
Lista B: Unidad Docente
```

Resultados:

```text
Lista A: 390 votos válidos
Lista B: 350 votos válidos
Blancos: 20
Nulos: 10
```

Si la regla exige mayoría simple o 50 % más uno de los votos válidos, gana la Lista A.

El sistema registra:

```text
Lista ganadora: Lista A
Estado del proceso: FINALIZADO
Resultado: PROCLAMADA
```

# 20. Caso de segunda vuelta sin quórum

Supongamos que en la primera vuelta participaron 700 docentes, por lo que fue válida.

Pero en la segunda vuelta solamente participan 550 de los 1,000:

```text
550 / 1000 = 55 %
```

Si el reglamento exige nuevamente más del 60 %, la segunda vuelta podría declararse inválida o nula.

El sistema debe permitir registrar:

```text
Proceso de segunda vuelta:
Estado: ANULADO
Motivo: no se alcanzó el quórum
```

La acción posterior dependerá del reglamento:

- Nueva convocatoria.
- Nueva fecha.
- Declaración de vacancia.
- Otra decisión del CEUNP.

No conviene que el sistema invente automáticamente esa consecuencia; debe dejarla como una decisión del CEUNP.

# 21. Caso de elección anulada por una mesa

Supongamos que una mesa presenta una irregularidad grave:

```text
Mesa 4:
- Acta sin firmas suficientes.
- Diferencia no justificada entre cédulas y electores.
- Material electoral incompleto.
```

El CEUNP puede evaluar la nulidad de esa mesa.

El sistema registra:

```text
Mesa 4
Estado del acta: ANULADA
Motivo: irregularidad documentada
Resolución: archivo correspondiente
```

Luego el CEUNP determina si:

- Se repite la votación de esa mesa.
- Se excluyen sus resultados.
- La irregularidad afecta toda la elección.
- Se presenta un recurso.

# 22. Caso de impugnación de un voto

Durante el escrutinio:

```text
El presidente considera nula una cédula.
El personero de la Lista B la impugna.
```

Flujo:

1. Se detiene la clasificación definitiva de esa cédula.
2. Se registra la impugnación.
3. Los miembros de mesa revisan la cédula.
4. Se decide si es válida, blanca o nula.
5. La decisión se registra en el acta.
6. Si el personero apela, el CEUNP revisa el caso.
7. El resultado definitivo se utiliza para el cómputo.

# 23. Ejemplo completo de resultados

Supongamos:

```text
Padrón total: 1,000 docentes
Participación: 720 docentes
Quórum mínimo: 60 %
```

La elección es válida porque:

```text
720 / 1000 = 72 %
```

Conteo:

```text
Lista A: 310
Lista B: 250
Lista C: 120
Blancos: 25
Nulos: 15
Total: 720
```

Votos válidos:

```text
310 + 250 + 120 = 680
```

Para ganar directamente con más del 50 %:

```text
Más de 340 votos válidos
```

La Lista A tiene 310, por lo que no gana directamente.

Segunda vuelta:

```text
Lista A vs Lista B
```

Segunda vuelta:

```text
Lista A: 380
Lista B: 330
Blancos: 8
Nulos: 7
```

Votos válidos:

```text
710
```

La Lista A obtiene más votos que la Lista B y es proclamada ganadora, siempre que cumpla las condiciones legales de la segunda vuelta.

# 24. Qué hace el sistema y qué hacen las personas

## El sistema

- Valida datos.
- Consulta el padrón.
- Impide votar dos veces.
- Muestra las listas.
- Registra la participación.
- Registra el voto anónimo.
- Genera QR.
- Guarda actas.
- Calcula resultados.
- Detecta diferencias.
- Conserva auditoría.
- Publica resultados.

## El CEUNP

- Toma decisiones electorales.
- Aprueba listas.
- Resuelve tachas.
- Decide sobre nulidades.
- Resuelve apelaciones.
- Convoca segunda vuelta.
- Proclama ganadores.

## Los miembros de mesa

- Controlan la jornada.
- Verifican identidad.
- Custodian el material.
- Realizan el escrutinio.
- Firman actas.
- Registran observaciones.

## Los personeros

- Vigilan la elección en representación de su lista.
- Observan actos electorales.
- Solicitan que se registren incidencias.
- Impugnan votos.
- Apelan decisiones.
- Verifican las actas.
- No modifican resultados directamente.

# 25. Resumen del flujo completo

```text
1. Convocatoria
2. Creación del proceso
3. Importación y aprobación del padrón
4. Inscripción de listas
5. Evaluación de requisitos
6. Presentación y resolución de tachas
7. Publicación de listas oficiales
8. Acreditación de personeros
9. Sorteo del orden de listas
10. Sorteo de miembros de mesa
11. Instalación de mesas
12. Validación del elector
13. Emisión del voto
14. Generación de constancia QR
15. Cierre del sufragio
16. Conteo de cédulas
17. Escrutinio
18. Impugnaciones
19. Generación de actas QR
20. Cómputo general
21. Verificación del quórum
22. Proclamación o segunda vuelta
23. Publicación de resultados
```

El `diagrama del proceso con sistema y QR` representa precisamente esta versión digitalizada, mientras que el `diagrama del proceso actual en papel` sirve para mostrar qué problemas pretende resolver el sistema.