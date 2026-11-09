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
  const response = await fetch(apiUrl(path), { ...options, headers });
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
  const response = await fetch(apiUrl(path), { ...options, headers });
  if (response.status === 401) throw new Error('TERMINAL_DESCONECTADO');
  return leerRespuesta(response);
}

async function leerRespuesta(response) {
  if (!response.ok) {
    let message = 'No se pudo completar la operación.';
    try {
      const text = await response.text();
      if (text && text.trim()) {
        try {
          const data = JSON.parse(text);
          message = data.detail || data.message || message;
        } catch {
          message = text;
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
