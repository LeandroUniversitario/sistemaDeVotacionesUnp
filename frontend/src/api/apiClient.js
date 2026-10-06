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
  const response = await fetch(path, { ...options, headers });
  if (response.status === 401) {
    sessionStorage.removeItem('accessToken');
    throw new Error('SESSION_EXPIRED');
  }
  if (!response.ok) {
    let message = 'No se pudo completar la operación.';
    try {
      const data = await response.json();
      message = data.detail || data.message || message;
    } catch {
      // La respuesta puede no tener cuerpo JSON.
    }
    throw new Error(message);
  }
  return response.status === 204 ? null : response.json();
}
