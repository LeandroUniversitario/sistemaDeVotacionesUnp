# Base de Datos · Sistema de Elecciones Docentes UNP

Guía rápida de scripts de base de datos para MariaDB / MySQL (XAMPP).

---

## 📁 Archivos Disponibles

| Archivo | Función | Cuándo usarlo |
|---|---|---|
| **`00_script_unico_elecciones_unp.sql`** | **Script único: toda la base en un solo archivo** | Instalar desde cero con la versión final de cada objeto (CUS07, CUS08, CUS09/CUS10, CUS11, CUS12, CUS13, CUS14, CUS15, CUS16, CUS17 y CUS18 incluidos): 54 tablas, 9 funciones, 77 triggers, 34 vistas, 77 procedimientos, parámetros, usuario admin, 14 facultades y 44 departamentos. Hace `DROP DATABASE` y no necesita ningún otro script. Al final trae, separada, la demo opcional (`CALL sp_demo_flujo_completo();`). |
| **`02_limpiar_datos_electorales.sql`** | **Limpiar / reiniciar datos de elecciones** | Vaciar votos, actas, padrón, mesas, listas y procesos electorales para iniciar una nueva elección limpia **sin borrar** facultades, departamentos, docentes registrados, usuarios, parámetros, su historial ni el registro de respaldos (CUS18). Solo borra las cuentas de los docentes de prueba de la demo. |
| **`03_demo_flujo_completo.sql`** | **Demostración de punta a punta** | Prueba automatizada del ciclo electoral (crea 60 docentes de prueba, convoca elección de Rector, sortea mesas, emite votos y computa resultados). |
| **`11_escrutinio_conciliacion.sql`** | **CUS12 · Realizar escrutinio y conciliar** | Solo si tu base ya existe sin CUS12: agrega `escrutinio_mesa`, `escrutinio_conteo`, la columna `impugnacion_electoral.id_cargo`, 5 triggers y los procedimientos `sp_contar_cedulas`, `sp_registrar_impugnacion`, `sp_registrar_conteo`, `sp_generar_acta_escrutinio` y `sp_registrar_entrega_actas`. No borra datos y se puede volver a ejecutar. `00` ya lo incluye. |
| **`12_impugnaciones_apelaciones.sql`** | **CUS13 · Gestionar impugnaciones y apelaciones** | Solo si tu base ya existe sin CUS13 (después del `11`): agrega a `impugnacion_electoral` la decisión de la mesa, la apelación y el fallo del CEUNP, 2 triggers, los procedimientos `sp_resolver_impugnacion_mesa`, `sp_apelar_impugnacion` y `sp_resolver_apelacion`, las vistas `v_impugnacion_efecto` y `v_impugnaciones_mesa_cargo` y los parámetros `IMPUGNACION_PLAZO_APELACION_HORAS` y `CEUNP_QUORUM_PLENO`. No borra datos y se puede volver a ejecutar. `00` ya lo incluye. |
| **`13_computo_proclamacion.sql`** | **CUS14 · Computar y proclamar resultados** | Solo si tu base ya existe sin CUS14 (después del `12`): agrega `computo_proceso`, `computo_personero`, `verificacion_acta`, `calificacion_mesa` y `proclamacion_cargo`, 9 triggers, las vistas `v_computo_actas`, `v_computo_mesas`, `v_computo_conteo_mesa`, `v_computo_resultados` y `v_portal_resultados`, los procedimientos `sp_instalar_sesion_computo`, `sp_registrar_personero_computo`, `sp_marcar_acta_dudosa`, `sp_comprobar_acta`, `sp_calificar_mesa`, `sp_ejecutar_computo`, `sp_proclamar_resultados`, `sp_publicar_resultados`, `sp_convocar_segunda_vuelta` y `sp_verificar_acta_computo`, y el parámetro `SEGUNDA_VUELTA_PLAZO_DIAS`. No borra datos y se puede volver a ejecutar. `00` ya lo incluye. |
| **`14_nulidades_segunda_vuelta.sql`** | **CUS15 · Gestionar nulidades y segunda vuelta** | Solo si tu base ya existe sin CUS15 (después del `13`): agrega `nulidad_electoral`, `nulidad_comunicacion` y `dirimencia_empate`, la función `fn_resolucion_en_uso`, 11 triggers (redefine `trg_proceso_bu` para la nulidad total de una elección computada y sin proclamar), las vistas `v_nulidades`, `v_portal_nulidades` y `v_segunda_vuelta_procesos`, los procedimientos `sp_registrar_nulidad`, `sp_resolver_nulidad`, `sp_registrar_comunicacion_nulidad`, `sp_dirimir_empate` y `sp_verificar_resolucion_nulidad`, y redefine `sp_crear_segunda_vuelta` para exigir el sorteo cuando hay empate por un cupo. No borra datos, no recrea la base y se puede volver a ejecutar. `00` ya lo incluye. |
| **`15_omisos_multas.sql`** | **CUS16 · Reportar omisos y multas** | Solo si tu base ya existe sin CUS16 (después del `14`): agrega a `multa` la mesa, el rol, la marca «asistió sin votar», la notificación, el recibo y los estados `JUSTIFICADA`; las tablas `reporte_multas` (resolución del Pleno con huella SHA-256 y QR) y `multa_justificacion` (justificación o exoneración); el parámetro `MULTA_PLAZO_JUSTIFICACION_DIAS`; redefine `fn_resolucion_en_uso`; 10 triggers; las vistas `v_omisos_proceso`, `v_reporte_gestion_mesas` (RF107) y `v_multas_detalle` (redefinida); los procedimientos `sp_emitir_resolucion_multas`, `sp_notificar_multas`, `sp_registrar_justificacion`, `sp_registrar_pago_multa` y `sp_verificar_resolucion_multas`, y redefine `sp_generar_multas` (no multa a electores de mesas no instaladas y se puede regenerar hasta la resolución) y `sp_actualizar_multa`. No borra datos, no recrea la base y se puede volver a ejecutar. `00` ya lo incluye. |
| **`16_resultados_verificacion.sql`** | **CUS17 · Consultar resultados y verificar actas** | Solo si tu base ya existe sin CUS17 (después del `15`): agrega `verificacion_documento` (registro de cada consulta por QR, código o huella: auténtica, alterada, anulada o no encontrada) y `cotejo_acta` (cotejo de las cifras del acta física con la digital y reporte de discrepancias al CEUNP), 4 triggers que las vuelven inalterables, la función `fn_resultados_disponibles` (RF99), las vistas `v_resultados_procesos`, `v_resultados_mesa`, `v_documentos_verificables` y `v_cotejos_acta`, y los procedimientos `sp_localizar_documento`, `sp_verificar_documento` (recalcula el SHA-256 de cualquier documento con QR), `sp_registrar_cotejo_acta` y `sp_atender_cotejo_acta`. No borra datos, no recrea la base y se puede volver a ejecutar. `00` ya lo incluye. |
| **`17_administracion_usuarios_parametros.sql`** | **CUS18 · Administrar usuarios y parámetros** | Solo si tu base ya existe sin CUS18 (después del `16`): agrega a `usuario` quién creó la cuenta, la fecha del último cambio y el motivo de su desactivación; las tablas `parametro_definicion` (grupo, tipo, rango, unidad, norma y bloqueo durante la votación de cada parámetro), `parametro_historial` (cada cambio con el valor anterior, el nuevo, el motivo y el usuario) y `respaldo_bd` (respaldos generados con su huella SHA-256); los parámetros `SEGURIDAD_INTENTOS_MAXIMOS`, `SEGURIDAD_BLOQUEO_MINUTOS` y `SEGURIDAD_PASSWORD_MIN`; las funciones `fn_jornada_en_curso`, `fn_validar_parametro` y `fn_error_docente_usuario`; 8 triggers (siempre queda un administrador activo, todo cambio de parámetro se valida y queda en el historial, historial y respaldos inalterables); las vistas `v_usuarios_admin`, `v_parametros_admin`, `v_parametro_historial` y `v_respaldos`, y los procedimientos `sp_validar_admin`, `sp_verificar_docente_usuario`, `sp_crear_usuario`, `sp_actualizar_usuario`, `sp_cambiar_estado_usuario`, `sp_restablecer_password`, `sp_desbloquear_usuario`, `sp_eliminar_usuario`, `sp_actualizar_parametro` y `sp_registrar_respaldo`. No borra datos, no recrea la base y se puede volver a ejecutar. `00` ya lo incluye. |
| **`100 Docentes.xlsx`** | **Plantilla Excel de docentes** | Archivo Excel para subir el padrón docente desde la interfaz web del sistema (módulo CUS02). |
| **`antiguos/`** | **Archivos históricos y respaldos** | Contiene versiones anteriores (v1, v2 modular, diagramas `.dbml`, `.mdl` y copias de seguridad). |

> **Nota:** Los scripts parciales (`01`, `04`–`10`) fueron eliminados porque su contenido ya está integrado en `00_script_unico_elecciones_unp.sql`.

---

## 🚀 Instrucciones de Uso

### Opción A: Desde phpMyAdmin
1. Abre [http://localhost/phpmyadmin](http://localhost/phpmyadmin).
2. Ve a la pestaña **Importar** (sin seleccionar ninguna base de datos).
3. Selecciona `00_script_unico_elecciones_unp.sql` y presiona **Continuar**.
4. Para reiniciar elecciones: selecciona la base `elecciones_unp`, importa `02_limpiar_datos_electorales.sql`.
5. Para ejecutar la demo: importa `03_demo_flujo_completo.sql` y luego en la pestaña SQL ejecuta:
   ```sql
   CALL sp_demo_flujo_completo();
   ```

---

### Opción B: Desde la Consola (CMD / PowerShell)

**Crear toda la base de datos de cero:**
```bash
mysql -u root < "base-de-datos/00_script_unico_elecciones_unp.sql"
```

**Limpiar datos electorales (conservando docentes y usuarios):**
```bash
mysql -u root elecciones_unp < "base-de-datos/02_limpiar_datos_electorales.sql"
```

**Ejecutar la demo electoral:**
```bash
mysql -u root elecciones_unp < "base-de-datos/03_demo_flujo_completo.sql"
mysql -u root elecciones_unp -e "CALL sp_demo_flujo_completo();"
```

---

## 🏛️ Organización Académica UNP (Departamentos vs Escuelas)

En el sistema universitario de la **Universidad Nacional de Piura (UNP)**:
- **Escuelas Profesionales (35):** Administran las carreras profesionales y planes de estudio de los estudiantes.
- **Departamentos Académicos (44):** Agrupan a los **profesionales docentes** según áreas del conocimiento y asignaturas afines (Ley Universitaria N° 30220).

Los docentes que votan o postulan en el sistema pertenecen a un **Departamento Académico**. Para permitir la importación masiva sin errores (ej. `100 Docentes.xlsx`), la base de datos incluye los **44 departamentos oficiales distribuidos en las 14 facultades**:

1. **Ciencias de la Salud (6):** Morfofisiología Humana; Clínico Quirúrgico; Salud Pública; Materno Infantil; Enfermería del Adulto; Enfermería Materno Perinatal *(más alias Enfermería)*.
2. **Agronomía (5):** Agronomía y Fitotecnia; Ingeniería Agrícola; Sanidad Vegetal; Suelos; Morfofisiología Vegetal.
3. **Ciencias (5):** Matemática; Física; Estadística; Ciencias Biológicas; Ingeniería Electrónica y Telecomunicaciones.
4. **Ingeniería Industrial (5):** Ingeniería Industrial; Ingeniería Informática; Agroindustria e Industrias Alimentarias; Investigación de Operaciones; Ingeniería Mecatrónica.
5. **Ingeniería de Minas (5):** Ingeniería de Minas; Ingeniería de Petróleo; Ingeniería Geológica; Ingeniería Química; Ingeniería Ambiental y Seguridad Industrial.
6. **Ciencias Contables y Financieras (3):** Contabilidad General; Contabilidad Aplicada; Finanzas, Tributación y Auditoría.
7. **Ciencias Sociales y Educación (3):** Educación; Ciencias de la Comunicación; Humanidades.
8. **Ciencias Administrativas (2):** Administración General; Administración Aplicada.
9. **Derecho y Ciencias Políticas (2):** Derecho; Ciencias Políticas.
10. **Ingeniería Civil (2):** Ingeniería Civil; Ingeniería Sanitaria y Medio Ambiente.
11. **Arquitectura y Urbanismo (2):** Arquitectura; Urbanismo *(más alias Arquitectura y Urbanismo)*.
12. **Zootecnia (2):** Producción Animal; Salud Animal.
13. **Economía (1):** Economía.
14. **Ingeniería Pesquera (1):** Ingeniería Pesquera.
