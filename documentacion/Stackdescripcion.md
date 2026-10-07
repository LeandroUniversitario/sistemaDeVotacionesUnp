
## Base de datos creada en phpMyAdmin

El script crea la base:

```text
elecciones_unp
```

Y contiene 25 tablas, entre ellas:

```text
facultad
departamento
docente
proceso_electoral
cargo_electoral
lista_electoral
candidato
tacha
personero
padron_electoral
mesa_electoral
miembro_mesa
voto
acta_electoral
firma_acta
constancia_voto
observacion_electoral
impugnacion_electoral
usuario
sesion_activa
log_auditoria
```

La importación fue probada directamente contra el MariaDB de XAMPP y se verificó que las tablas fueron creadas correctamente.

Para importarlo manualmente:

1. Abre phpMyAdmin.
2. Entra a `http://localhost:8012/phpmyadmin`.
3. Selecciona **Importar**.
4. Elige `01_schema.sql`.
5. Presiona **Continuar**.

El script no modifica tus bases anteriores como `gestion_familiar`, `hotel` o `sistemabiblioteca`.

## Backend

El backend está preparado con:

```text
Java 21
Spring Boot 3.5
Spring Web
Spring Data JPA
Spring Security
MariaDB Driver
Maven
```

El endpoint inicial es:

```text
http://localhost:8080/api/health
```

Respuesta comprobada:

```json
{
  "status": "UP",
  "service": "elecciones-backend"
}
```

Para iniciarlo:

```powershell
cd "C:\Users\lucan\Documents\Lucano\UNP Ciclo VI\Analisis y Diseño de Sistemas II\SisElecciones\Sistema Elecciones UNP\backend"
mvn spring-boot:run
```

## Frontend

El frontend está preparado con:

```text
React
Vite
JavaScript
```

Para ejecutarlo:

```powershell
cd "C:\Users\lucan\Documents\Lucano\UNP Ciclo VI\Analisis y Diseño de Sistemas II\SisElecciones\Sistema Elecciones UNP\frontend"
npm install
npm run dev
```

La aplicación estará disponible normalmente en:

```text
http://localhost:5173
```

El frontend ya consulta:

```text
/api/health
```

para comprobar que el backend está funcionando.

También se ejecutó correctamente:

```text
npm run build
```

## ¿Procedimientos almacenados o lógica en Spring Boot?

Para este proyecto recomiendo una arquitectura híbrida, pero con la lógica principal en Spring Boot.

### Spring Boot debe encargarse de:

- Casos de uso.
- Validaciones.
- Roles y permisos.
- Autenticación.
- Registro de candidaturas.
- Tachas.
- Sorteos.
- Impugnaciones.
- Generación de constancias QR.
- Generación de actas.
- Reglas de segunda vuelta.
- Cálculo de resultados.
- Auditoría.
- Transacciones.

### MariaDB debe encargarse de:

- Guardar datos.
- Claves primarias.
- Claves foráneas.
- Restricciones `UNIQUE`.
- Índices.
- Tipos y estados.
- Integridad referencial.

## ¿Por qué no poner todo en procedimientos almacenados?

No recomiendo construir todo el sistema con procedimientos almacenados porque:

- La lógica queda escondida dentro de la base.
- Es más difícil realizar pruebas unitarias.
- Es más difícil mantener el proyecto.
- Las reglas de permisos quedan mezcladas con SQL.
- Se vuelve más complicado manejar errores.
- El backend queda muy dependiente de MariaDB.
- Las reglas de segunda vuelta, tachas y personeros son más claras en Java.

Por ejemplo, esta lógica debe estar en Spring Boot:

```text
verificar si el docente puede votar
obtener listas admitidas
validar la lista seleccionada
marcar participación
registrar voto anónimo
generar constancia
registrar auditoría
```

## ¿Dónde sí usar una operación crítica de base de datos?

La emisión del voto necesita consistencia para evitar doble votación.

La lógica conceptual es:

```text
BEGIN TRANSACTION

1. Bloquear el registro del padrón.
2. Verificar que ya_voto = false.
3. Cambiar ya_voto = true.
4. Insertar el voto anónimo.
5. Generar la constancia.
6. Confirmar transacción.

COMMIT
```

Si algo falla:

```text
ROLLBACK
```

En Spring Boot se puede manejar con:

```java
@Transactional
public ConstanciaVoto registrarVoto(...) {
    // validar padrón
    // marcar participación
    // guardar voto anónimo
    // generar constancia
}
```

Para el bloqueo se puede utilizar una consulta con bloqueo pesimista o una actualización condicional:

```sql
UPDATE padron_electoral
SET ya_voto = TRUE,
    fecha_votacion = CURRENT_TIMESTAMP
WHERE id_proceso = ?
  AND id_cargo = ?
  AND id_docente = ?
  AND habilitado_para_votar = TRUE
  AND ya_voto = FALSE;
```

Después Spring Boot verifica que se haya actualizado exactamente una fila.

## Recomendación final

La arquitectura debería quedar así:

```text
React
  |
  | HTTP/JSON
  v
Spring Boot REST API
  |
  | JPA / SQL parametrizado
  v
MariaDB
```

Y las responsabilidades:

```text
React:
    interfaz y experiencia de usuario

Spring Boot:
    reglas electorales, seguridad y transacciones

MariaDB:
    persistencia e integridad de datos
```

Lo que ya está creado es una base inicial. Todavía no implementé autenticación, entidades JPA ni los módulos electorales porque conviene avanzar en este orden:

1. Configurar conexión y entidades JPA.
2. Implementar autenticación y roles.
3. Implementar docentes y padrón.
4. Implementar procesos y cargos.
5. Implementar listas y candidatos.
6. Implementar personeros.
7. Implementar sorteo de mesas.
8. Implementar votación anónima.
9. Implementar QR.
10. Implementar actas, impugnaciones y resultados.