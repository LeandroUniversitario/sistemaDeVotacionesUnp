/**
 * Convierte el tipo de proceso a una etiqueta legible en español.
 * @param {string} type - 'PRIMERA_VUELTA' | 'SEGUNDA_VUELTA'
 */
export function formatType(type) {
  return type === 'SEGUNDA_VUELTA' ? 'Segunda vuelta' : 'Primera vuelta';
}

/**
 * Formatea una fecha ISO a formato legible peruano (dd mmm yyyy, HH:mm).
 * @param {string} value - Cadena de fecha ISO
 */
export function formatDate(value) {
  if (!value) return '—';
  return new Intl.DateTimeFormat('es-PE', { dateStyle: 'medium', timeStyle: 'short' })
    .format(new Date(value));
}
