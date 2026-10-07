# Sistema de Votaciones UNP

Sistema de Elecciones Docentes de la Universidad Nacional de Piura.

## Estructura del Proyecto

`
backend/          -> Spring Boot (Java 21, MariaDB, JWT)
frontend/         -> React + Vite
base-de-datos/    -> Scripts SQL y datos iniciales
diagramas/        -> Diagramas PlantUML del sistema
documentacion/    -> Documentacion tecnica y de negocio
`

## Tecnologias

| Capa        | Tecnologia                          |
|-------------|-------------------------------------|
| Backend     | Java 21, Spring Boot 3.5.6, MariaDB |
| Seguridad   | Spring Security + JWT (JJWT 0.12.6) |
| Frontend    | React 18, Vite, CSS vanilla         |
| Base Datos  | MariaDB / MySQL (schema.sql)        |

## Inicio rapido

### 1. Base de datos
Ejecutar en MariaDB/MySQL:
- base-de-datos/schema.sql
- base-de-datos/InsertarFacultadesyDepartamentos.sql

### 2. Backend
`
cd backend
mvn spring-boot:run
Servidor: http://localhost:8080
`
Variables de entorno (opcionales):
- DB_URL=jdbc:mariadb://localhost:3306/elecciones_unp
- DB_USERNAME=root
- DB_PASSWORD=tu_password
- JWT_SECRET=secreto_de_al_menos_32_caracteres

### 3. Frontend
`
cd frontend
npm install
npm run dev
App: http://localhost:5173
`

## Roles del sistema

| Rol           | Acceso                                         |
|---------------|------------------------------------------------|
| ADMIN         | Gestion total: procesos, usuarios, parametros  |
| CEUNP         | Procesos, candidaturas, tachas, sorteos        |
| MIEMBRO_MESA  | Mesa de sufragio + terminal de votacion        |
| PERSONERO     | Resumen + tachas                               |
| DOCENTE       | Terminal de votacion                           |

## Equipo

- Leandro: https://github.com/LeandroUniversitario
- Lucanoxz: https://github.com/lucanoxz-alt

---
Universidad Nacional de Piura - Analisis y Diseno de Sistemas II - Ciclo VI
