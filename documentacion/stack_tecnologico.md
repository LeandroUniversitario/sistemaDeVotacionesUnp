# Definición del Stack Tecnológico

Basado en la arquitectura N-Capas/MVC y los requerimientos del Sistema de Control de Elecciones (RUP), se ha definido el siguiente stack:

## 1. Backend (Lógica de Negocio y APIs)
- **Lenguaje:** Java 17+
- **Framework Core:** Spring Boot 3.x
- **Arquitectura Interna (MVC/N-Capas):**
  - **Boundary (Controladores REST):** Spring Web. Serán las interfaces que reciben las peticiones del frontend.
  - **Control (Servicios):** Clases Java con `@Service`. Aquí residirá la lógica estricta (ej. sorteo aleatorio de mesas).
  - **Entity (Dominio):** Clases Planas (POJOs) mapeadas a tablas con anotaciones JPA (`@Entity`).
  - **Repository (Acceso a Datos):** Interfaces de Spring Data JPA (`@Repository`).

## 2. Base de Datos (Persistencia)
- **Motor:** PostgreSQL
- **Conexión:** JDBC Driver nativo
- **Razón:** Estándar de la industria para sistemas transaccionales críticos (como el registro de votos). Garantiza máxima seguridad e integridad (propiedades ACID).

## 3. Frontend (Capa de Presentación Web)
- **Librería Core:** React.js
- **Herramienta de Build:** Vite (para un entorno de desarrollo ultrarrápido).
- **Estilos:** Vanilla CSS (Para control total del diseño visual, priorizando animaciones fluidas, glassmorphism y una estética universitaria muy moderna y premium).
- **Comunicación:** Llamadas asíncronas (`fetch` o Axios) consumiendo la API REST del backend.

## 4. Estructura de Directorios del Proyecto (Generada)
```text
sistemaVotaciones/
├── backend/                  # Proyecto Spring Boot (Lógica + Persistencia)
│   ├── pom.xml
│   └── src/main/java/com/unp/votaciones/
│       ├── boundary/         # REST Endpoints (EmisionVotoView, SorteoMesaView)
│       ├── control/          # Lógica de Negocio (VotacionController, SorteoMesaController)
│       ├── entity/           # Entidades (Docente, Voto, MesaElectoral)
│       └── repository/       # Interfaces Spring Data (DocenteRepository, VotoRepository)
├── frontend/                 # Proyecto React (Vistas interactivas)
│   ├── package.json
│   └── src/                  
└── diagramas/                # Modelos UML y de Arquitectura
```
