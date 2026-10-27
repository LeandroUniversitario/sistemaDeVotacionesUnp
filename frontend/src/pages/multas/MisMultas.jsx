import { useCallback, useEffect, useState } from 'react';
import { apiRequest } from '../../api/apiClient';
import MenuIcon from '../../components/MenuIcon';
import { fecha } from '../credenciales/LectorQR';
import { CAUSAL_DESCARGO, ESTADO_MULTA, MEDIO, MOTIVO, MOTIVO_BASE, ROL, soles } from './ReporteMultas';
import '../convocatoria/convocatoria.css';
import '../computo/computo.css';
import './multas.css';
import '../mesa/mesa-ejecutivo.css';

/**
 * CUS16 · Mis multas — el docente consulta las multas que el Pleno del CEUNP le determinó
 * (RF103, RF104), el plazo para justificarse (RF106) y el estado del descargo o del pago.
 * El docente no paga desde el sistema: lo hace en Tesorería (el sistema no cobra la multa).
 */

const CLASE = { PENDIENTE: 'creado', PAGADA: 'votacion', JUSTIFICADA: 'inscripcion', EXONERADA: 'inscripcion' };
const COLOR = { PENDIENTE: '#d97706', PAGADA: '#059669', JUSTIFICADA: '#2563eb', EXONERADA: '#64748b' };

export default function MisMultas({ onSessionExpired }) {
  const [multas, setMultas] = useState([]);
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState(null);

  const cargar = useCallback(async () => {
    setCargando(true);
    setError(null);
    try {
      setMultas(await apiRequest('/api/multas/mias'));
    } catch (e) {
      if (e.message === 'SESSION_EXPIRED') onSessionExpired?.();
      else setError(e.message);
    } finally {
      setCargando(false);
    }
  }, [onSessionExpired]);

  useEffect(() => { cargar(); }, [cargar]);

  if (cargando) return <div className="panel"><p className="muted">Cargando sus multas…</p></div>;

  const pendientes = multas.filter((m) => m.estadoPago === 'PENDIENTE');
  const deuda = pendientes.reduce((s, m) => s + Number(m.monto ?? 0), 0);

  return (
    <div className="cq-shell mu-shell mx">
      <section className="cq-resumen">
        <div className="cq-kpi" style={{ '--cq-color': pendientes.length ? '#d97706' : '#059669' }}>
          <span>Multas pendientes</span>
          <strong>{pendientes.length}<small> / {multas.length}</small></strong>
          <small>{pendientes.length ? 'Pague en Tesorería o presente su justificación' : 'No tiene multas por pagar'}</small>
        </div>
        <div className="cq-kpi" style={{ '--cq-color': '#e11d48' }}>
          <span>Monto pendiente</span>
          <strong>{soles(deuda)}</strong>
          <small>El sistema electoral no cobra la multa</small>
        </div>
        <div className="cq-kpi" style={{ '--cq-color': '#2563eb' }}>
          <span>Justificadas o exoneradas</span>
          <strong>{multas.filter((m) => ['JUSTIFICADA', 'EXONERADA'].includes(m.estadoPago)).length}</strong>
          <small>Resueltas por el Pleno del CEUNP</small>
        </div>
      </section>

      {error && <div className="alert error" role="status">{error}</div>}

      {multas.length === 0 && !error && (
        <div className="panel"><p className="empty-state">No tiene multas electorales. Gracias por votar y cumplir su función de miembro de mesa.</p></div>
      )}

      <div className="mu-mias">
        {multas.map((m) => {
          const vencido = m.limiteJustificacion && new Date(m.limiteJustificacion) < new Date();
          return (
            <div key={m.idMulta} className="panel mx-ficha mu-mia" style={{ '--mu-color': COLOR[m.estadoPago] }}>
              <div className="mx-ficha-top">
                <div>
                  <h3>{MOTIVO[m.motivo] ?? m.motivo} · {soles(m.monto)}</h3>
                  <p>{m.proceso} · {MOTIVO_BASE[m.motivo]}{m.numeroMesa ? ` · mesa ${m.numeroMesa}` : ''}{m.rolMesa ? ` (${ROL[m.rolMesa] ?? m.rolMesa} titular)` : ''}</p>
                </div>
                <span className={`cv-estado ${CLASE[m.estadoPago]}`}>{ESTADO_MULTA[m.estadoPago] ?? m.estadoPago}</span>
              </div>
              <dl className="mx-datos">
                <div><dt>Multa N.º</dt><dd>{String(m.idMulta).padStart(5, '0')}</dd></div>
                <div><dt>Cálculo</dt><dd>{Number(m.porcentajeUit).toFixed(1)} % de la UIT ({soles(m.uitReferencia)})</dd></div>
                <div><dt>Resolución</dt><dd>{m.resolucionMultas ?? '—'}{m.fechaResolucionMultas ? ` · ${fecha(m.fechaResolucionMultas)}` : ''}</dd></div>
                <div><dt>Notificada</dt><dd>{m.fechaNotificacion ? `${fecha(m.fechaNotificacion)} · ${MEDIO[m.medioNotificacion] ?? ''}` : 'Pendiente'}</dd></div>
              </dl>
              {m.estadoPago === 'PENDIENTE' && (
                <div className={`mx-mensaje ${vencido ? 'peligro' : 'info'}`} role="note">
                  <MenuIcon name={vencido ? 'alert' : 'info'} size={18} />
                  <div>
                    <p>{m.decisionDescargo === 'DENEGADA'
                      ? `Su justificación fue denegada por la Resolución ${m.resolucionDescargo}. La multa sigue pendiente de pago en Tesorería.`
                      : m.limiteJustificacion
                        ? vencido
                          ? `Venció el plazo para justificarse (${fecha(m.limiteJustificacion)}). Puede pagar la multa en Tesorería de la Universidad.`
                          : `Si tuvo un impedimento, presente su justificación con los documentos que la sustenten ante el CEUNP hasta el ${fecha(m.limiteJustificacion)} (Disp. Final 2.ª y 5.ª). El pago se realiza en Tesorería.`
                        : 'El plazo para justificarse corre desde que el CEUNP le notifique la multa.'}</p>
                  </div>
                </div>
              )}
              {m.estadoPago === 'PAGADA' && <p className="ig-texto">Pagada el {fecha(m.fechaPago)}{m.numeroRecibo ? ` con el recibo ${m.numeroRecibo}` : ''}.</p>}
              {['JUSTIFICADA', 'EXONERADA'].includes(m.estadoPago) && (
                <p className="ig-texto">{m.estadoPago === 'EXONERADA' ? 'Exonerada' : 'Justificación admitida'} por la Resolución {m.resolucionDescargo}{m.causalDescargo ? ` · ${CAUSAL_DESCARGO[m.causalDescargo] ?? m.causalDescargo}` : ''}. La multa no es exigible.</p>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
