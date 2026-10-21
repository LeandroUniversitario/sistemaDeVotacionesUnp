# Base de Datos · Sistema de Elecciones Docentes UNP

Guía rápida de scripts de base de datos para MariaDB / MySQL (XAMPP).

---

## 📁 Archivos Disponibles

| Archivo | Función | Cuándo usarlo |
|---|---|---|
| **`00_script_unico_elecciones_unp.sql`** | **Script único: toda la base en un solo archivo** | Instalar desde cero con la versión final de cada objeto (CUS07, CUS08, CUS09/CUS10 y CUS11 incluidos): 37 tablas, 4 funciones, 29 triggers, 14 vistas, 34 procedimientos, parámetros, usuario admin, 14 facultades y 44 departamentos. Hace `DROP DATABASE` y no necesita ningún otro script. Al final trae, separada, la demo opcional (`CALL sp_demo_flujo_completo();`). |
| **`01_crear_base_de_datos.sql`** | **Crear base de datos completa desde cero** | Instalar por primera vez o reconstruir toda la BD (crea 27 tablas, 4 funciones, 19 triggers, 14 vistas, 26 procedimientos almacenados, parámetros, usuario admin, 14 facultades y los 44 departamentos académicos oficiales de la UNP). |
| **`02_limpiar_datos_electorales.sql`** | **Limpiar / reiniciar datos de elecciones** | Vaciar votos, actas, padrón, mesas, listas y procesos electorales para iniciar una nueva elección limpia **sin borrar** facultades, departamentos, docentes registrados ni usuarios. |
| **`03_demo_flujo_completo.sql`** | **Demostración de punta a punta** | Prueba automatizada del ciclo electoral (crea 60 docentes de prueba, convoca elección de Rector, sortea mesas, emite votos y computa resultados). |
| **`04_credenciales_qr.sql`** | **Agregar la tabla de credenciales QR (CUS07)** | Solo si tu base se creó antes de CUS07: crea `credencial_qr` sin tocar los demás datos. Si importas `01_crear_base_de_datos.sql` de nuevo, ya la incluye. |
| **`07_agregar_debe_cambiar_password.sql`** | **Primer inicio de sesión forzado** | Agrega la columna `debe_cambiar_password` a la tabla `usuario` para obligar a cambiar la contraseña temporal. |
| **`08_insertar_departamentos_academicos_unp.sql`** | **Padrón oficial de 44 Departamentos UNP** | Inserta / asegura los 44 departamentos académicos oficiales de la UNP en las 14 facultades para evitar errores al importar docentes en CUS02. |
| **`100 Docentes.xlsx`** | **Plantilla Excel de docentes** | Archivo Excel para subir el padrón docente desde la interfaz web del sistema (módulo CUS02). |
| **`antiguos/`** | **Archivos históricos y respaldos** | Contiene versiones anteriores (v1, v2 modular, diagramas `.dbml`, `.mdl` y copias de seguridad). |

---

## 🚀 Instrucciones de Uso

### Opción A: Desde phpMyAdmin
1. Abre [http://localhost/phpmyadmin](http://localhost/phpmyadmin).
2. Ve a la pestaña **Importar**.
3. Selecciona el archivo deseado:
   * Para crear todo de cero: elige `01_crear_base_de_datos.sql` y presiona **Continuar**.
   * Para reiniciar elecciones: elige `02_limpiar_datos_electorales.sql` y presiona **Continuar**.
   * Para ejecutar la demo: importa `03_demo_flujo_completo.sql` y luego en la pestaña SQL ejecuta:
     ```sql
     CALL sp_demo_flujo_completo();
     ```

---

### Opción B: Desde la Consola (CMD / PowerShell)

**Crear toda la base de datos de cero:**
```bash
mysql -u root < "base-de-datos/00_script_unico_elecciones_unp.sql"
# (equivalente anterior, por partes)
mysql -u root < "base-de-datos/01_crear_base_de_datos.sql"
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

**Actualizar departamentos académicos oficiales UNP (en BD existente):**
```bash
mysql -u root elecciones_unp < "base-de-datos/08_insertar_departamentos_academicos_unp.sql"
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

