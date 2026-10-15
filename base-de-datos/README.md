# Base de Datos · Sistema de Elecciones Docentes UNP

Guía rápida de scripts de base de datos para MariaDB / MySQL (XAMPP).

---

## 📁 Archivos Disponibles

| Archivo | Función | Cuándo usarlo |
|---|---|---|
| **`01_crear_base_de_datos.sql`** | **Crear base de datos completa desde cero** | Instalar por primera vez o reconstruir toda la BD (crea 27 tablas, 4 funciones, 19 triggers, 14 vistas, 26 procedimientos almacenados, parámetros, usuario admin, 14 facultades y 54 departamentos). |
| **`02_limpiar_datos_electorales.sql`** | **Limpiar / reiniciar datos de elecciones** | Vaciar votos, actas, padrón, mesas, listas y procesos electorales para iniciar una nueva elección limpia **sin borrar** facultades, departamentos, docentes registrados ni usuarios. |
| **`03_demo_flujo_completo.sql`** | **Demostración de punta a punta** | Prueba automatizada del ciclo electoral (crea 60 docentes de prueba, convoca elección de Rector, sortea mesas, emite votos y computa resultados). |
| **`04_credenciales_qr.sql`** | **Agregar la tabla de credenciales QR (CUS07)** | Solo si tu base se creó antes de CUS07: crea `credencial_qr` sin tocar los demás datos. Si importas `01_crear_base_de_datos.sql` de nuevo, ya la incluye. |
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
