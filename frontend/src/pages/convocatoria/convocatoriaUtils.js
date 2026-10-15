/**
 * CUS01 · Utilidades de la PantallaConvocatoria (fechas del cronograma y reglas RN02).
 * Las mismas reglas las vuelve a validar el backend (RegistrarProceso.validarCronograma).
 */

export const DIAS_MIN = 30;
export const DIAS_MAX = 45;
const DIA_MS = 24 * 60 * 60 * 1000;

export const NIVELES = [
  { value: 'UNIVERSIDAD', label: 'Universidad' },
  { value: 'FACULTAD', label: 'Facultad' },
  { value: 'DEPARTAMENTO', label: 'Departamento académico' },
];

export const CATEGORIAS = ['PRINCIPAL', 'ASOCIADO', 'AUXILIAR'];

export const ESTADO_LABEL = {
  CREADO: 'Borrador',
  INSCRIPCION: 'Publicada · Inscripción',
  VOTACION: 'En votación',
  CERRADO: 'Cerrada',
  FINALIZADO: 'Finalizada',
  ANULADO: 'Anulada',
};

export const EMPTY_FORM = {
  nombre: '',
  quorumMinimo: '60',
  fechaConvocatoria: '',
  fechaLimiteInscripcion: '',
  diaSufragio: '',
  horaInicio: '09:00',
  horaFin: '15:00',
};

/** 'YYYY-MM-DD' de una fecha local. */
export function toIsoDate(date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

/** Fecha local a partir de 'YYYY-MM-DD' (sin desfase de zona horaria). */
export function parseDate(value) {
  if (!value) return null;
  const [y, m, d] = value.slice(0, 10).split('-').map(Number);
  return new Date(y, m - 1, d);
}

/** Fecha y hora local a partir de 'YYYY-MM-DDTHH:mm[:ss]'. */
export function parseDateTime(value) {
  if (!value) return null;
  const [fecha, hora = '00:00'] = value.split('T');
  const [h, min] = hora.split(':').map(Number);
  const d = parseDate(fecha);
  d.setHours(h, min, 0, 0);
  return d;
}

export function addDays(isoDate, days) {
  const d = parseDate(isoDate);
  d.setDate(d.getDate() + days);
  return toIsoDate(d);
}

export function daysBetween(fromIsoDate, toIsoDateValue) {
  const a = parseDate(fromIsoDate);
  const b = parseDate(toIsoDateValue);
  if (!a || !b) return null;
  return Math.round((b - a) / DIA_MS);
}

const fmtFecha = new Intl.DateTimeFormat('es-PE', { day: '2-digit', month: 'short', year: 'numeric' });
const fmtFechaHora = new Intl.DateTimeFormat('es-PE', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
const fmtHora = new Intl.DateTimeFormat('es-PE', { hour: '2-digit', minute: '2-digit' });

export function formatFecha(isoDate) {
  const d = parseDate(isoDate);
  return d ? fmtFecha.format(d) : '—';
}

export function formatFechaHora(isoDateTime) {
  const d = parseDateTime(isoDateTime);
  return d ? fmtFechaHora.format(d) : '—';
}

export function formatHora(isoDateTime) {
  const d = parseDateTime(isoDateTime);
  return d ? fmtHora.format(d) : '—';
}

/** Proceso del backend → valores del formulario. */
export function procesoToForm(proceso) {
  return {
    nombre: proceso.nombre ?? '',
    quorumMinimo: String(proceso.quorumMinimo ?? '60'),
    fechaConvocatoria: proceso.fechaConvocatoria ?? '',
    fechaLimiteInscripcion: proceso.fechaLimiteInscripcion ? proceso.fechaLimiteInscripcion.slice(0, 16) : '',
    diaSufragio: proceso.fechaInicio ? proceso.fechaInicio.slice(0, 10) : '',
    horaInicio: proceso.fechaInicio ? proceso.fechaInicio.slice(11, 16) : '09:00',
    horaFin: proceso.fechaFin ? proceso.fechaFin.slice(11, 16) : '15:00',
  };
}

/** Formulario → cuerpo JSON de DatosProceso (backend). */
export function formToPayload(form) {
  return {
    nombre: form.nombre.trim(),
    quorumMinimo: Number(form.quorumMinimo),
    fechaConvocatoria: form.fechaConvocatoria,
    fechaLimiteInscripcion: `${form.fechaLimiteInscripcion}:00`,
    fechaInicio: `${form.diaSufragio}T${form.horaInicio}:00`,
    fechaFin: `${form.diaSufragio}T${form.horaFin}:00`,
  };
}

/**
 * Validación en vivo del cronograma. Devuelve { errores: {campo: msg}, dias }.
 * Es una ayuda visual: la regla definitiva la aplica el backend.
 */
export function validarCronograma(form) {
  const errores = {};
  const dias = form.fechaConvocatoria && form.diaSufragio
    ? daysBetween(form.fechaConvocatoria, form.diaSufragio)
    : null;

  if (!form.nombre.trim()) errores.nombre = 'Ingrese el nombre del proceso.';
  const quorum = Number(form.quorumMinimo);
  if (form.quorumMinimo === '' || Number.isNaN(quorum) || quorum < 0 || quorum > 100) {
    errores.quorumMinimo = 'El quórum debe estar entre 0 y 100.';
  }
  if (!form.fechaConvocatoria) errores.fechaConvocatoria = 'Indique la fecha de convocatoria.';
  if (!form.diaSufragio) errores.diaSufragio = 'Indique el día del sufragio.';
  if (!form.fechaLimiteInscripcion) errores.fechaLimiteInscripcion = 'Indique el cierre de inscripción de listas.';

  if (form.diaSufragio && form.horaInicio && form.horaFin) {
    const inicio = parseDateTime(`${form.diaSufragio}T${form.horaInicio}`);
    const fin = parseDateTime(`${form.diaSufragio}T${form.horaFin}`);
    if (fin <= inicio) errores.horaFin = 'La hora de cierre debe ser posterior a la de inicio.';
    if (inicio <= new Date()) errores.diaSufragio = 'El sufragio debe ser en una fecha futura.';
  }
  if (dias !== null && (dias < DIAS_MIN || dias > DIAS_MAX)) {
    errores.fechaConvocatoria = `RN02: debe estar entre ${DIAS_MIN} y ${DIAS_MAX} días antes del sufragio (ahora: ${dias}).`;
  }
  if (form.fechaLimiteInscripcion && form.fechaConvocatoria && form.diaSufragio && form.horaInicio) {
    const limite = parseDateTime(form.fechaLimiteInscripcion);
    if (limite <= parseDate(form.fechaConvocatoria)) {
      errores.fechaLimiteInscripcion = 'Debe ser posterior a la convocatoria.';
    } else if (limite >= parseDateTime(`${form.diaSufragio}T${form.horaInicio}`)) {
      errores.fechaLimiteInscripcion = 'Debe ser anterior al inicio del sufragio.';
    }
  }
  return { errores, dias };
}

export function nombreCargo(cargo) {
  return cargo.jurisdiccion ? `${cargo.nombre} — ${cargo.jurisdiccion}` : cargo.nombre;
}
