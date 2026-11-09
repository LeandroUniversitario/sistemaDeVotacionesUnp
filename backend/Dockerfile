# ===================================================
# Etapa 1: Compilación de la aplicación con Maven y JDK 21
# ===================================================
FROM maven:3.9-eclipse-temurin-21-alpine AS build
WORKDIR /app

# Copiar descriptor de dependencias
COPY pom.xml .

# Descargar dependencias para aprovechar la capa en caché
RUN mvn dependency:go-offline -B || true

# Copiar el código fuente y compilar
COPY src ./src
RUN mvn clean package -DskipTests

# ===================================================
# Etapa 2: Imagen final de ejecución ligera con JRE 21
# ===================================================
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Crear usuario sin privilegios por seguridad
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copiar el JAR compilado
COPY --from=build /app/target/*.jar app.jar

# Asignar propiedad y cambiar de usuario
RUN chown -R appuser:appgroup /app
USER appuser:appgroup

# Render asigna el puerto en la variable PORT (por defecto 8080)
ENV PORT=8080
EXPOSE 8080

# Comando de inicio con soporte de puerto dinámico
ENTRYPOINT ["sh", "-c", "java -Dserver.port=${PORT} -Djava.security.egd=file:/dev/./urandom -jar app.jar"]
