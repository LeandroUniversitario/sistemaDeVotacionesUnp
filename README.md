# Sistema de Votaciones UNP

Sistema de Elecciones Docentes de la Universidad Nacional de Piura.

## Estructura del Proyecto

`
backend/          -> Spring Boot (Java 21, MariaDB, JWT)
frontend/         -> React + Vite
base-de-datos/    -> Scripts SQL y datos iniciales
diagramas/        -> Modelo Rational Rose (.mdl), diagramas de secuencia y colaboracion (.drawio) y diagramas PlantUML
documentacion/    -> Documentacion tecnica y de negocio
`

## Tecnologias

| Capa        | Tecnologia                          |
|-------------|-------------------------------------|
| Backend     | Java 21, Spring Boot 3.5.6, MariaDB |
| Seguridad   | Spring Security + JWT (JJWT 0.12.6) |
| Frontend    | React 19, Vite 7, CSS vanilla       |
| Base Datos  | MariaDB / MySQL (script unico)      |

## Inicio rapido

### 1. Base de datos
Ejecutar en MariaDB/MySQL:
- `base-de-datos/00_script_unico_elecciones_unp.sql` (crea la base completa: tablas, triggers, vistas, procedimientos y datos iniciales)
- `base-de-datos/02_limpiar_datos_electorales.sql` (limpia y reinicia datos electorales para una nueva elección)
- Usuario inicial: admin / Admin2026* (cambiar al ingresar)
- Guía: `base-de-datos/README.md` y `documentacion/BACKEND_v2.md`

### 2. Backend
```
cd backend
export JWT_SECRET=$(openssl rand -hex 32)      # obligatorio: sin él el backend no arranca
export RESPALDO_CLAVE='una-frase-larga-y-privada' # obligatorio para generar respaldos (mín. 16 caracteres)
mvn spring-boot:run
```
Servidor: http://localhost:8080

Variables de entorno:

| Variable | Obligatoria | Uso |
|----------|-------------|-----|
| `JWT_SECRET` | Sí | Firma de las sesiones. Al menos 32 bytes aleatorios; el valor de ejemplo que estuvo en el repositorio se rechaza. |
| `RESPALDO_CLAVE` | Para respaldos | Clave con la que se cifran los respaldos (AES-256-GCM). Guárdela fuera del servidor. |
| `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` | En producción | Conexión a MariaDB (por defecto `localhost`, `root`, sin clave). |

En producción use el perfil `prod` (`SPRING_PROFILES_ACTIVE=prod`): exige las variables de la base, respeta `X-Forwarded-For` detrás de un proxy con HTTPS y no devuelve trazas de error.

### 3. Frontend
```
cd frontend
npm install
npm run dev        # solo en este equipo (localhost)
npm run dev:red    # para abrir la cabina desde otro equipo de la red local
```
App: http://localhost:5173

### 4. Pruebas
```
cd backend
mvn test                                    # pruebas unitarias
ELECCIONES_DB_URL=jdbc:mariadb://localhost:3306/elecciones_unp \
DB_USERNAME=elecciones DB_PASSWORD=elecciones mvn test   # además, reglas contra la base
```

## Jornada electoral: la cabina de votación

La cabina ya no usa la sesión del miembro de mesa. El presidente de mesa entra en el equipo de la cabina,
abre «Terminal de votación» y lo conecta. El sistema guarda en ese navegador un secreto de dispositivo,
cierra la sesión del miembro y deja la pantalla en `/cabina`, sin menú. Desde ahí el elector solo puede
votar cuando la mesa lo habilita; nadie más puede leer el token del voto, ni siquiera con una sesión válida.
Para desconectar el equipo, vuelva a iniciar sesión y use «Desconectar» en «Terminal de votación».

## Abrir la votación

En «Convocatoria y cronograma», cuando el proceso está en INSCRIPCION, el CEUNP tiene el botón
«Abrir la votación». El sistema verifica padrón, listas admitidas, orden de cédula y mesas completas.

## Demostraciones con pocos votos

El quórum mínimo legal es 60 % (parámetro `QUORUM_MINIMO_LEGAL_PCT`). Para una demostración con pocos
electores, el ADMIN lo baja en «Configuración» antes de crear la convocatoria (el cambio queda en la bitácora).

## Restaurar un respaldo

Los respaldos se descargan como `.sql.enc`. Para descifrarlos:
```
RESPALDO_CLAVE='...' java -cp backend/target/elecciones-backend-0.0.1-SNAPSHOT.jar \
  -Dloader.main=pe.unp.elecciones.electoral.administracion.CifradoRespaldo \
  org.springframework.boot.loader.launch.PropertiesLauncher respaldo.sql.enc respaldo.sql
mysql -u root elecciones_unp < respaldo.sql
```

## Roles del sistema

| Rol           | Acceso                                         |
|---------------|------------------------------------------------|
| ADMIN         | Usuarios, parámetros, respaldos y bitácora (consulta los procesos, no los opera) |
| CEUNP         | Convocatoria, inscripción, tachas, sorteos, apertura de votación, supervisión de mesas, cómputo y proclamación |
| MIEMBRO_MESA  | Instalación, verificación de electores, terminal, cierre, escrutinio e impugnaciones de su mesa |
| PERSONERO     | Resumen, tachas y apelaciones                  |
| DOCENTE       | Pase QR, tachas, multas y resultados           |

Las cuentas de los docentes importados reciben una contraseña provisional aleatoria (se descarga en CSV
desde «Padrón electoral» justo después de importar) y deben cambiarla al primer ingreso.

## Equipo

- Leandro: https://github.com/LeandroUniversitario
- Lucanoxz: https://github.com/lucanoxz-alt

---
Universidad Nacional de Piura - Analisis y Diseno de Sistemas II - Ciclo VI
