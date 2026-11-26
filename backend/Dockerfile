# ===================================================
# Etapa 1: Compilación con Maven (usa caché de repo local si existe)
# Para modo OFFLINE: copiamos el repositorio Maven local al build
# ===================================================
FROM maven:3.9-eclipse-temurin-21-alpine AS build
WORKDIR /app

# Copiar el repositorio Maven local cacheado (generado por exportar-usb.ps1)
# Si no existe la carpeta .m2, Maven descargará dependencias normalmente (requiere internet)
COPY .m2 /root/.m2

# Copiar descriptor de dependencias y código fuente
COPY pom.xml .
COPY src ./src

# Compilar usando el caché local (-o = offline si el caché existe)
RUN mvn clean package -DskipTests -o 2>/dev/null || mvn clean package -DskipTests

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

# Puerto configurado por variable de entorno (por defecto 8080)
ENV PORT=8080
EXPOSE 8080

# Comando de inicio
ENTRYPOINT ["sh", "-c", "java -Dserver.port=${PORT} -Djava.security.egd=file:/dev/./urandom -jar app.jar"]

