# Diccionario de Términos y Actualización Arquitectónica
**Alineado al Reglamento de Elecciones UNP (RCU N° 0462-CU-2019)**

Este documento resume las actualizaciones estructurales que se aplicaron a la base de datos (`schema.sql`), los modelos UML y el Frontend para cumplir estrictamente con la normativa de la UNP.

---

## 1. Nuevos Conceptos y Términos (Glosario Electoral)

Durante el diseño inicial, modelamos el sistema pensando en candidatos individuales. Tras analizar el documento oficial, se introdujeron los siguientes términos obligatorios:

*   **Fórmula (o Lista Electoral):** En las elecciones de la UNP, no se vota por una persona suelta, sino por un equipo completo (ej. 1 Rector + 2 Vicerrectores). El voto del elector va hacia la lista completa.
*   **Tacha:** Es una impugnación o denuncia *escrita* que realiza un docente del padrón contra un candidato específico **antes** de la elección, indicando que no cumple los requisitos para postular.
*   **Personero:** Es el representante legal y fiscalizador de una Lista Electoral. Aseguran la transparencia. Existen personeros Generales, Alternos y de Mesa (estos últimos pueden impugnar votos el día de la elección).
*   **Quórum de Participación:** Para que las elecciones universitarias sean válidas, más del 60% del padrón electoral debe emitir su voto. 
*   **Actas Electorales (con Hash):** Cada mesa de votación debe generar 3 actas obligatorias: (1) Instalación, (2) Sufragio y (3) Escrutinio. Para asegurar que no sean alteradas, se les aplica un algoritmo matemático (Hash SHA-256).
*   **Segunda Vuelta:** Escenario automático que ocurre si ninguna de las Listas Electorales alcanza el mínimo de votos legales requeridos en la primera vuelta.

---

## 2. ¿Cómo impactaron estos términos en nuestro código?

Para que nuestro sistema informático soporte estas reglas, hicimos las siguientes modificaciones estructurales:

### A. Refactorización del Voto (De Candidato a Lista)
*   **Antes:** La tabla `voto` tenía la columna `id_candidato_elegido`.
*   **Ahora:** Creamos la tabla `lista_electoral`. La tabla `candidato` ahora pertenece a una lista (`id_lista`). Finalmente, la tabla `voto` se actualizó para tener `id_lista_elegida`. **El elector ya no vota por una persona, vota por una fórmula.**

### B. Módulo de Seguridad Legal (Tachas y Personeros)
*   Se creó la tabla `tacha` que conecta a un `docente_denunciante` con un `candidato` denunciado. Tiene estados como PENDIENTE, FUNDADA (el candidato queda fuera) e INFUNDADA.
*   Se creó la tabla `personero` que conecta a un `docente` con una `lista_electoral`.

### C. Módulo de Control de Resultados (Actas y Quórum)
*   Se creó la tabla `acta_electoral` vinculada a la tabla `mesa_electoral`. Tiene una columna vital llamada `hash_integridad` que almacenará el SHA-256 del contenido del acta. Si un hacker modifica el contenido de la base de datos, el Hash ya no coincidirá, detectando el fraude.
*   En `proceso_electoral` se agregó el campo `quorum_minimo` (por defecto 60.00).
*   **Innovación:** Se creó una **Vista en SQL (`vista_quorum`)** que calcula en tiempo real qué porcentaje de los docentes del padrón ya emitió su voto, permitiendo al CEUNP saber instantáneamente si la elección es válida.

### D. Estandarización de Terminología
*   En los diagramas de Casos de Uso, cambiamos el actor genérico "Comité Electoral" por **CEUNP** (Comité Electoral de la Universidad Nacional de Piura).
*   Corregimos la regla de la Mesa Electoral: El reglamento exige exactamente **6 miembros por mesa** (3 Titulares: Presidente, Secretario, Vocal + 3 Suplentes). El diagrama de clases ahora refleja esta cardinalidad estricta.

---

## 3. Resumen de Tablas Finales (20 tablas)

El sistema ahora se divide lógicamente en 4 módulos:

1.  **Padrón y Universidad (5):** `facultad`, `departamento`, `docente`, `cargo_admin`, `cargo_excluido_sorteo`.
2.  **Proceso Electoral (6):** `proceso_electoral`, `cargo_electoral`, `lista_electoral` (NUEVO), `candidato`, `tacha` (NUEVO), `personero` (NUEVO).
3.  **Control de Voto y Mesas (5):** `padron_electoral`, `mesa_electoral`, `miembro_mesa`, `voto` (MODIFICADO), `acta_electoral` (NUEVO).
4.  **Auditoría y Seguridad (4):** `log_auditoria`, `constancia_voto`, `usuario`, `sesion_activa`.

*Nota: La regla de oro del anonimato se mantiene intacta. La tabla `voto` y la tabla `docente` nunca se cruzan directamente en el esquema.*
