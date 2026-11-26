const API_BASE_URL = (import.meta.env.VITE_API_URL || '').replace(/\/$/, '');

export function apiUrl(path) {
  if (!path || path.startsWith('http://') || path.startsWith('https://')) return path;
  return `${API_BASE_URL}${path.startsWith('/') ? path : `/${path}`}`;
}

/**
 * Cliente HTTP centralizado.
 * Agrega automáticamente el token JWT de sesión a cada petición
 * y maneja errores comunes (401, respuestas no-OK).
 *
 * @param {string} path    - Ruta del endpoint (ej: '/api/procesos')
 * @param {object} options - Opciones de fetch (method, body, headers...)
 * @returns {Promise<any>} - JSON de la respuesta, o null si es 204
 */
export async function apiRequest(path, options = {}) {
  const token = sessionStorage.getItem('accessToken');
  const headers = {
    ...(options.body ? { 'Content-Type': 'application/json' } : {}),
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...options.headers,
  };
  const response = await pedir(path, { ...options, headers });
  if (response.status === 401) {
    sessionStorage.removeItem('accessToken');
    throw new Error('SESSION_EXPIRED');
  }
  return leerRespuesta(response);
}

/**
 * Peticiones del equipo de la cabina (CUS10): sin sesión de persona, con el secreto de dispositivo
 * que se emitió al conectar el terminal. Un 401 significa que el equipo fue desconectado o reconectado
 * en otro lugar.
 */
export async function cabinaRequest(path, secreto, options = {}) {
  const headers = {
    ...(options.body ? { 'Content-Type': 'application/json' } : {}),
    'X-Terminal-Secreto': secreto,
    ...options.headers,
  };
  const response = await pedir(path, { ...options, headers });
  if (response.status === 401) throw new Error('TERMINAL_DESCONECTADO');
  return leerRespuesta(response);
}

/** fetch con un mensaje claro cuando el servidor no responde (backend apagado, sin red o sin proxy). */
export async function pedir(path, opciones) {
  try {
    return await fetch(apiUrl(path), opciones);
  } catch {
    throw new Error('No se pudo conectar con el servidor: verifique que el backend esté encendido (puerto 8080) y que tenga conexión a la red.');
  }
}

/** Mensaje específico cuando el backend no envía uno propio. */
export function mensajePorEstado(status) {
  switch (status) {
    case 400: return 'Los datos enviados no son válidos: revise los campos del formulario.';
    case 403: return 'Su perfil no tiene permiso para esta acción, o la acción no corresponde a su mesa o proceso.';
    case 404: return 'El registro solicitado no existe o ya fue eliminado: actualice la pantalla.';
    case 409: return 'La operación entra en conflicto con el estado actual (otro usuario pudo cambiarlo): actualice la pantalla e inténtelo de nuevo.';
    case 413: return 'El archivo o los datos enviados son demasiado grandes.';
    case 422: return 'La operación no cumple una regla del proceso electoral.';
    case 429: return 'Demasiadas solicitudes seguidas: espere unos segundos e inténtelo de nuevo.';
    case 502: case 503: case 504: return 'El servidor no está disponible en este momento: espere unos segundos e inténtelo de nuevo.';
    default: return status >= 500
      ? `Error interno del servidor (HTTP ${status}): revise la consola del backend; la operación no se completó.`
      : `No se pudo completar la operación (HTTP ${status}).`;
  }
}

async function leerRespuesta(response) {
  if (!response.ok) {
    let message = mensajePorEstado(response.status);
    try {
      const text = await response.text();
      if (text && text.trim()) {
        try {
          const data = JSON.parse(text);
          const propio = data.detail || data.message;
          // Spring devuelve «Forbidden», «Internal Server Error», etc. cuando no hay mensaje propio
          if (propio && propio !== data.error && !/^(No message available|Forbidden|Bad Request|Internal Server Error)$/i.test(propio)) {
            message = propio;
          }
        } catch {
          if (!/^\s*</.test(text)) message = text;   // no mostrar páginas HTML de error
        }
      }
    } catch {
      // La respuesta puede no tener cuerpo legible.
    }
    throw new Error(message);
  }
  if (response.status === 204) return null;
  const text = await response.text();
  if (!text || !text.trim()) return null;
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}
