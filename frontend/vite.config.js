import { networkInterfaces } from 'node:os';
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

/**
 * IPv4 de la PC en la red local (Wi-Fi o cable), para que los QR que se generan abriendo la app
 * en localhost se puedan escanear con un celular conectado a la misma red. Se descartan los
 * adaptadores virtuales más comunes (VirtualBox, VMware, WSL/Hyper-V, Docker).
 */
function ipRedLocal() {
  const virtual = /virtual|vmware|vbox|hyper-v|vethernet|wsl|docker|loopback|bluetooth/i;
  const candidatas = Object.entries(networkInterfaces())
    .filter(([nombre]) => !virtual.test(nombre))
    .flatMap(([, direcciones]) => direcciones ?? [])
    .filter((d) => d.family === 'IPv4' && !d.internal && !d.address.startsWith('169.254.'))
    .map((d) => d.address);
  const prioridad = (ip) => (ip.startsWith('192.168.') ? 0 : ip.startsWith('10.') ? 1 : 2);
  return candidatas.sort((a, b) => prioridad(a) - prioridad(b))[0] ?? '';
}

export default defineConfig(({ command }) => ({
  plugins: [react()],
  define: {
    // Solo en desarrollo: un build desplegado usa su propio dominio o VITE_URL_PUBLICA.
    __IP_RED_LOCAL__: JSON.stringify(command === 'serve' ? ipRedLocal() : ''),
  },
  server: {
    // Escucha también en la red local para que el celular abra la página del QR.
    host: true,
    port: 5173,
    proxy: {
      '/api': 'http://localhost:8080'
    }
  }
}));
