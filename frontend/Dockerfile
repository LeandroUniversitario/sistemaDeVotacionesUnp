# ===================================================
# Etapa 1: Build del frontend con Node.js
# ===================================================
FROM node:20-alpine AS build
WORKDIR /app

# Copiar dependencias y descargar paquetes
COPY package.json package-lock.json* ./
RUN npm install --frozen-lockfile 2>/dev/null || npm install

# Copiar el resto del código y compilar
COPY . .
RUN npm run build

# ===================================================
# Etapa 2: Servir el build con Nginx (ultra-ligero)
# ===================================================
FROM nginx:alpine
WORKDIR /usr/share/nginx/html

# Limpiar contenido por defecto y copiar el build
RUN rm -rf ./*
COPY --from=build /app/dist .

# Config de Nginx para SPA (React Router): todas las rutas → index.html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
