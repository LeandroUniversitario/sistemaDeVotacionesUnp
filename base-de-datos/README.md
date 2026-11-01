# Base de Datos · Sistema de Elecciones Docentes UNP

Guía rápida de scripts de base de datos para MariaDB / MySQL (XAMPP).

---

## 📁 Archivos Disponibles

| Archivo | Función | Cuándo usarlo |
|---|---|---|
| **`00_script_unico_elecciones_unp.sql`** | **Script único: toda la base en un solo archivo** | Instalar desde cero con la versión final de cada objeto (CUS07, CUS08, CUS09/CUS10, CUS11, CUS12, CUS13, CUS14, CUS15, CUS16, CUS17, CUS18 y CUS19 incluidos): 56 tablas, 10 funciones, 79 triggers, 35 vistas, 80 procedimientos, parámetros, usuario admin, 14 facultades y 44 departamentos. Hace `DROP DATABASE` y no necesita ningún otro script. Al final trae, separada, la demo opcional (`CALL sp_demo_flujo_completo();`). |
| **`02_limpiar_datos_electorales.sql`** | **Limpiar / reiniciar datos de elecciones** | Vaciar votos, actas, padrón, mesas, listas y procesos electorales para iniciar una nueva elección limpia **sin borrar** facultades, departamentos, docentes registrados, usuarios, parámetros, su historial, el registro de respaldos (CUS18) ni el catálogo de acciones de la bitácora (CUS19). Vacía la bitácora y reinicia su cadena de sellos con el registro `REINICIAR_BITACORA`. Solo borra las cuentas de los docentes de prueba de la demo. |
| **`100 Docentes.xlsx`** | **Plantilla Excel de docentes** | Archivo Excel para subir el padrón docente desde la interfaz web del sistema (módulo CUS02). |

> **Nota:** El proyecto usa una sola base de datos, creada con `00_script_unico_elecciones_unp.sql`. Los scripts parciales e incrementales (`01`, `03`–`18`) y la carpeta `antiguos/` se eliminaron porque su contenido ya está integrado en el script único (siguen disponibles en el historial de Git).

---

## 🚀 Instrucciones de Uso

### Opción A: Desde phpMyAdmin
1. Abre [http://localhost/phpmyadmin](http://localhost/phpmyadmin).
2. Ve a la pestaña **Importar** (sin seleccionar ninguna base de datos).
3. Selecciona `00_script_unico_elecciones_unp.sql` y presiona **Continuar**.
4. Para reiniciar elecciones: selecciona la base `elecciones_unp`, importa `02_limpiar_datos_electorales.sql`.
5. Para ejecutar la demo (ya la crea el script único), en la pestaña SQL ejecuta:
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
