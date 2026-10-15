import {
  DIAS_MAX, DIAS_MIN, addDays, daysBetween, formatFecha, formatFechaHora, parseDate, parseDateTime,
} from './convocatoriaUtils';

/**
 * Línea de tiempo del cronograma electoral (CUS01).
 * Dibuja convocatoria → cierre de inscripción → sufragio a escala real de días
 * y sombrea la ventana válida de RN02 (30 a 45 días antes del sufragio).
 *
 * @param {{ cronograma: { fechaConvocatoria, fechaLimiteInscripcion, diaSufragio, horaInicio, horaFin } }} props
 */
export default function CronogramaTimeline({ cronograma }) {
  const { fechaConvocatoria, fechaLimiteInscripcion, diaSufragio, horaInicio, horaFin } = cronograma;

  if (!diaSufragio) {
    return (
      <div className="cv-timeline cv-timeline-empty">
        Indique el día del sufragio para ver el cronograma y la ventana de convocatoria (RN02).
      </div>
    );
  }

  const ventanaDesde = addDays(diaSufragio, -DIAS_MAX);
  const ventanaHasta = addDays(diaSufragio, -DIAS_MIN);
  const inicioEje = [ventanaDesde, fechaConvocatoria].filter(Boolean).sort()[0];
  const desde = parseDate(addDays(inicioEje, -3));
  const hasta = parseDate(addDays(diaSufragio, 4));
  const total = hasta - desde;
  const pos = (date) => `${Math.min(100, Math.max(0, ((date - desde) / total) * 100))}%`;

  const conv = parseDate(fechaConvocatoria);
  const limite = parseDateTime(fechaLimiteInscripcion);
  const sufragio = parseDate(diaSufragio);
  const dias = fechaConvocatoria ? daysBetween(fechaConvocatoria, diaSufragio) : null;
  const rn02Ok = dias !== null && dias >= DIAS_MIN && dias <= DIAS_MAX;

  const diasInscripcion = conv && limite ? Math.max(0, Math.round((limite - conv) / 86400000)) : null;
  const diasPreparacion = limite ? Math.max(0, Math.round((sufragio - parseDate(fechaLimiteInscripcion.slice(0, 10))) / 86400000)) : null;

  return (
    <div className="cv-timeline" aria-label="Cronograma del proceso electoral">
      <div className="cv-tl-track">
        <div
          className="cv-tl-window"
          style={{ left: pos(parseDate(ventanaDesde)), width: `calc(${pos(parseDate(ventanaHasta))} - ${pos(parseDate(ventanaDesde))})` }}
          title={`Ventana RN02: ${formatFecha(ventanaDesde)} – ${formatFecha(ventanaHasta)}`}
        >
          <span>Ventana RN02</span>
        </div>

        {conv && limite && limite > conv && (
          <div className="cv-tl-segment inscripcion" style={{ left: pos(conv), width: `calc(${pos(limite)} - ${pos(conv)})` }}>
            <span>Inscripción · {diasInscripcion} d</span>
          </div>
        )}
        {limite && sufragio > limite && (
          <div className="cv-tl-segment preparacion" style={{ left: pos(limite), width: `calc(${pos(sufragio)} - ${pos(limite)})` }}>
            <span>Tachas y preparación · {diasPreparacion} d</span>
          </div>
        )}

        {conv && <span className={`cv-tl-dot conv${rn02Ok ? '' : ' bad'}`} style={{ left: pos(conv) }} />}
        {limite && <span className="cv-tl-dot limite" style={{ left: pos(limite) }} />}
        <span className="cv-tl-dot sufragio" style={{ left: pos(sufragio) }} />
      </div>

      <ol className="cv-tl-legend">
        <li>
          <i className={`conv${rn02Ok ? '' : ' bad'}`} />
          <div>
            <strong>Convocatoria</strong>
            <span>{fechaConvocatoria ? formatFecha(fechaConvocatoria) : 'Sin fecha'}</span>
          </div>
        </li>
        <li>
          <i className="limite" />
          <div>
            <strong>Cierre de inscripción</strong>
            <span>{fechaLimiteInscripcion ? formatFechaHora(fechaLimiteInscripcion) : 'Sin fecha'}</span>
          </div>
        </li>
        <li>
          <i className="sufragio" />
          <div>
            <strong>Sufragio</strong>
            <span>{formatFecha(diaSufragio)} · {horaInicio}–{horaFin}</span>
          </div>
        </li>
        <li className={`cv-tl-rn02 ${dias === null ? '' : rn02Ok ? 'ok' : 'bad'}`}>
          <div>
            <strong>{dias === null ? '—' : `${dias} días`}</strong>
            <span>de anticipación (RN02: {DIAS_MIN}–{DIAS_MAX})</span>
          </div>
        </li>
      </ol>
    </div>
  );
}
