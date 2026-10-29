/**
 * Dirección base de los enlaces que van dentro de los QR (credenciales, actas, resoluciones).
 *
 * Un QR que apunta a localhost o 127.0.0.1 no abre nada en el celular que lo escanea:
 * esa dirección es el propio celular. Por eso, si la app se usa desde la misma PC del
 * servidor, el QR lleva la IP de la PC en la red local (Vite la detecta al arrancar).
 * Para un despliegue real se fija la dirección pública con VITE_URL_PUBLICA en frontend/.env.local.
 */
const LOCAL = /^(localhost|127\.\d+\.\d+\.\d+|\[::1\])$/i;

/* global __IP_RED_LOCAL__ */
const IP_RED_LOCAL = typeof __IP_RED_LOCAL__ === 'string' ? __IP_RED_LOCAL__ : '';

export function baseUrlPublica() {
  const configurada = import.meta.env.VITE_URL_PUBLICA;
  if (configurada) return configurada.replace(/\/+$/, '');
  const { protocol, hostname, port, origin } = window.location;
  if (LOCAL.test(hostname) && IP_RED_LOCAL) return `${protocol}//${IP_RED_LOCAL}${port ? `:${port}` : ''}`;
  return origin;
}

/** true si los QR quedarán apuntando a una dirección que un celular no puede abrir. */
export const qrSoloEnEstaPC = () => LOCAL.test(new URL(baseUrlPublica()).hostname);

export const urlPublica = (ruta) => `${baseUrlPublica()}${ruta}`;
